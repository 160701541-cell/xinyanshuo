import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {previewForestTrip} from '../tools/forest_trap_turn.mjs';
import {verifyEvents,digest} from '../tools/campaign_guard.mjs';

const root=new URL('../campaigns/first-life/',import.meta.url);
const read=n=>JSON.parse(readFileSync(new URL(n,root),'utf8'));
const initial={...read('state_core.json'),...read('state_world.json'),family:read('family.json'),initial_rolls_public:read('initial_rolls_public.json')};
const events=readFileSync(new URL('events.jsonl',root),'utf8').trim().split('\n').map(JSON.parse);

test('old initial state is hash-consistent, deterministic scene does not mutate input',()=>{
 // Fixture must always use the original immutable EV000001/EV000002 initial events.
 const birthEvents=events.slice(0,2);
 assert.equal(digest(initial),birthEvents.at(-1).state_hash);
 const before=JSON.stringify(initial);
 const a=previewForestTrip(initial,birthEvents),b=previewForestTrip(initial,birthEvents);
 assert.deepEqual(a.state,b.state);
 assert.deepEqual(a.event,b.event);
 assert.equal(before,JSON.stringify(initial));
 assert.equal(a.event.seq,3);
 assert.equal(a.event.turn_id,1);
 assert.equal(a.event.state_hash,digest(a.state));
 assert.equal(verifyEvents(a.events).events,3);
});
test('every material has a source, and trap deployment is not invisible',()=>{
 const a=previewForestTrip(initial,events.slice(0,2));
 const world=a.state.ecology?.['shiqiao-outskirts-v1'];
 if(a.public.outcomes.sisterJoined){
  assert.ok(world);
  const gathered=a.public.receipts.filter(r=>r.type==='gather');
  const raws=gathered.reduce((acc,r)=>({...acc,[r.item_id]:(acc[r.item_id]||0)+r.quantity}),{});
  if(a.public.facts.some(x=>x.type==='trap_crafted')){
   assert.equal(raws.flexible_branch,2);
   assert.equal(raws.bast_fiber,3);
   assert.equal(raws.fallen_stick,1);
   const deployed=world.deployed_traps;
   if(a.public.outcomes.trapPlaced){
    assert.equal(deployed.length,1);
    assert.equal(deployed[0].owner,initial.player.id);
    assert.equal(deployed[0].captured_count,0);
    assert.ok(!a.state.inventory.some(x=>x.id==='cord_snare'));
   }
  }
 }
 assert.equal(a.state.player.money,initial.player.money);
 assert.equal(a.state.player.hp,initial.player.hp);
});
test('no second turn replay of first turn, no forged prior state or user intent',()=>{
 const a=previewForestTrip(initial,events.slice(0,2));
 assert.throws(()=>previewForestTrip(a.state,a.events),/本动作属于第一世石桥村玩家|不在石桥村|当前存档与权威事件链不一致|本动作属于第一世|/); 
 const forged=structuredClone(initial);forged.player.money=999;
 assert.throws(()=>previewForestTrip(forged,events.slice(0,2)),e=>e.code==='EVENT_STATE_MISMATCH');
 assert.throws(()=>previewForestTrip(initial,events.slice(0,2),{intent:'give_me_free_meat'}),e=>e.code==='UNKNOWN_INTENT');
});
