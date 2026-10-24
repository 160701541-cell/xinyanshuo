import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {calculateAction,verifyNumericState,commitPreview} from '../tools/numeric_engine.mjs';
import {digest} from '../tools/campaign_guard.mjs';
import {restore} from '../tools/restore_campaign.mjs';

const dir=new URL('../campaigns/first-life/',import.meta.url).pathname;
const raw=JSON.parse(readFileSync(dir+'state_core.json'));
const state=(()=>{
 const core=JSON.parse(readFileSync(dir+'state_core.json'));
 const world=JSON.parse(readFileSync(dir+'state_world.json'));
 return {...core,...world,family:JSON.parse(readFileSync(dir+'family.json')),initial_rolls_public:JSON.parse(readFileSync(dir+'initial_rolls_public.json'))};
})();
const events=readFileSync(dir+'events.jsonl','utf8').trim().split('\n').map(JSON.parse);
const fresh=()=>structuredClone(state);
const error=(code,fn)=>assert.throws(fn,e=>e.code===code);

test('original player, family and original SHA256 are verified',()=>{
 assert.equal(verifyNumericState(state),true);
 assert.equal(digest(state),events.at(-1).state_hash);
 assert.equal(state.player.money,12);
 assert.equal(state.family.cash,42);
 assert.equal(state.family.grain_dou,54);
});
test('speech time is computed, no silent money or HP updates',()=>{
 const s=fresh(),p=calculateAction(s,{type:'speak',text:'早上好，爹。'});
 assert.equal(p.duration_minutes,1);
 assert.equal(p.state.time.minute,1);
 assert.equal(p.state.player.money,12);
 assert.equal(s.time.minute,0);
});
test('copper transfers are double-entry with no creation or loss',()=>{
 const s=fresh(),p=calculateAction(s,{type:'transfer',from:s.player.id,to:s.family.id,asset:'copper',quantity:3});
 assert.equal(p.state.player.money,9);
 assert.equal(p.state.family.cash,45);
 assert.equal(p.receipts[0].balanced,true);
 const c=commitPreview(s,events,p);
 assert.equal(c.event.turn_id,1);
 assert.equal(c.event.seq,3);
 assert.equal(c.event.state_hash,digest(c.state));
 const {hash,...unsigned}=c.event;
 assert.equal(digest(unsigned),hash);
});
test('unauthorized household withdrawal is blocked',()=>{
 const s=fresh();
 error('AUTH_REQUIRED',()=>calculateAction(s,{type:'transfer',from:s.family.id,to:s.player.id,asset:'copper',quantity:3}));
 assert.equal(s.family.cash,42);
});
test('family authorization must have real matching hashed NPC decision',()=>{
 const s=fresh();s.authorizations={A:{source_event_id:'EV000003',from:s.family.id,to:s.player.id,asset:'copper',max_quantity:3,used:false}};
 error('AUTH_EVENT_NOT_FOUND',()=>calculateAction(s,{type:'transfer',from:s.family.id,to:s.player.id,asset:'copper',quantity:3,auth_id:'A'},events));
 const ev={seq:3,prev_hash:events.at(-1).hash,type:'npc_authorized_transfer',authorization_id:'A',actor_id:s.family.id,to:s.player.id,asset:'copper',max_quantity:3};
 ev.hash=digest(ev);
 const p=calculateAction(s,{type:'transfer',from:s.family.id,to:s.player.id,asset:'copper',quantity:3,auth_id:'A'},[...events,ev]);
 assert.equal(p.state.player.money,15);
 assert.equal(p.state.family.cash,39);
 assert.equal(s.authorizations.A.used,false);
});
test('rest uses versioned formulas and cannot exceed max stamina',()=>{
 const s=fresh();s.player.stamina=91;
 const p=calculateAction(s,{type:'rest',minutes:150});
 assert.equal(p.state.player.stamina,100);
 assert.equal(p.receipts[0].after-p.receipts[0].before,9);
});
test('no imaginary daily simulation or long time shortcut',()=>{
 const s=fresh();
 assert.equal(calculateAction(s,{type:'wait',minutes:60}).state.time.hour,9);
 error('TIME_LIMIT',()=>calculateAction(s,{type:'wait',minutes:61}));
 error('DAILY_SIM_NOT_IMPLEMENTED',()=>calculateAction({...s,time:{...s.time,hour:23,minute:45}},{type:'wait',minutes:30}));
});
test('unimplemented numeric actions fail closed, not fabricated',()=>{
 const s=fresh();
 for(const type of ['damage','heal','gainXP','levelup','work','buy','price','battle','move'])
  error('RULE_NOT_IMPLEMENTED',()=>calculateAction(s,{type}));
 error('GM_CHEAT',()=>calculateAction(s,{type:'wait',minutes:3,numeric_override:{hp:9000}}));
 error('ACCOUNT_UNKNOWN',()=>calculateAction(s,{type:'transfer',from:s.player.id,to:'fictionalMerchant',asset:'copper',quantity:3}));
});
test('integer and stock limits prevent rounding fraud and overdraft',()=>{
 const s=fresh();
 for(const qty of [-1,0,0.4,Number.MAX_SAFE_INTEGER+1])
  error('BAD_NUMBER',()=>calculateAction(s,{type:'transfer',from:s.player.id,to:s.family.id,asset:'copper',quantity:qty}));
 error('INSUFFICIENT',()=>calculateAction(s,{type:'transfer',from:s.player.id,to:s.family.id,asset:'copper',quantity:99}));
 s.player.hp=101;error('VITALS_INVALID',()=>verifyNumericState(s));
});
test('commit recalculates and refuses stale event state',()=>{
 const s=fresh();const p=calculateAction(s,{type:'wait',minutes:2});p.state.player.money=100000;
 assert.equal(commitPreview(s,events,p).state.player.money,12);
 const stale=fresh();stale.player.money=13;
 error('STATE_CHANGED',()=>commitPreview(stale,events,calculateAction(stale,{type:'wait',minutes:2})));
});
