import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {previewHerbForage} from '../tools/medicinal_foraging_turn.mjs';
import {digest,verifyEvents} from '../tools/campaign_guard.mjs';
import {bootstrapNpcRegistry,appendLifeEvent,observeTrait,validateNpcRegistry} from '../tools/npc_identity.mjs';

const dir=new URL('../campaigns/first-life/',import.meta.url);
const state=JSON.parse(readFileSync(new URL('game_state.json',dir),'utf8'));
const events=readFileSync(new URL('events.jsonl',dir),'utf8').trim().split('\n').map(JSON.parse);
const cp=x=>structuredClone(x);

test('NPC records reproduce known sex and do not invent birth years',()=>{
 const r=bootstrapNpcRegistry(state,events);
 assert.equal(r.npcs.CFNPC00003.sex,'女');
 assert.equal(r.npcs.CFNPC00003.age,16);
 assert.equal(r.npcs.CFNPC00003.born_at,null);
 assert.equal(r.npcs.CFNPC00003.public_personality.length,0);
 assert.equal(validateNpcRegistry(r,state,events).ok,true);
});

test('only event-confirmed public life experience can be appended',()=>{
 let r=bootstrapNpcRegistry(state,events);
 r=appendLifeEvent(r,{npc_id:'CFNPC00003',event_id:'EV000003',tag:'joined_foraging',text:'结伴采集',certainty:'known_fact'});
 r=observeTrait(r,{npc_id:'CFNPC00003',event_id:'EV000003',tag:'cooperative',description:'这次愿意帮忙'});
 assert.equal(validateNpcRegistry(r,state,events).ok,true);
 assert.throws(()=>validateNpcRegistry(appendLifeEvent(r,{npc_id:'CFNPC00003',event_id:'EV099999',tag:'future_secret',text:'无依据未来经历'}),state,events), e=>e.code==='EVENT_NOT_COMMITTED');
});

test('wild herbal forage is deterministic, not a request-sensitive jackpot',()=>{
 const birth=JSON.stringify(state);
 const a=previewHerbForage(state,events),b=previewHerbForage(state,events);
 assert.deepEqual(a.event,b.event);
 assert.deepEqual(a.state,b.state);
 assert.equal(JSON.stringify(state),birth);
 assert.equal(a.event.seq,events.length+1);
 assert.equal(a.event.state_hash,digest(a.state));
 assert.equal(verifyEvents(a.events).events,events.length+1);
 assert.equal(a.state.player.money,state.player.money);
 assert.equal(a.state.family.cash,state.family.cash);
 assert.equal(a.state.player.hp,state.player.hp);
 assert.equal(a.state.player.stamina,state.player.stamina-7);
 assert.equal(a.event.duration_minutes,55);
 assert.equal(a.event.prices_status,'UNKNOWN_NOT_QUOTED');
 assert.equal(a.event.trap_status,'NOT_CHECKED');
 const zone=a.state.ecology['shiqiao-outskirts-v1'].botany;
 for(const r of a.public.receipts){
  const n=zone.nodes.find(n=>n.id===r.source_node);
  assert.equal(n.quantity,n.initial_quantity-r.quantity);
  assert.equal(r.unit_price_wen,null);
 }
});

test('does not forge high value spirit herbs, silver or sale prices',()=>{
 const a=previewHerbForage(state,events);
 assert.ok(!a.public.receipts.some(x=>x.resource==='unidentified_spirit_shoot'));
 assert.equal(a.public.sale_price,'未询价');
 assert.ok(!a.public.receipts.some(x=>Number.isFinite(x.unit_price_wen)));
});

test('no entity transposition across world or protagonist',()=>{
 let bad=cp(state);bad.player.money=300;
 assert.throws(()=>previewHerbForage(bad,events),e=>e.code==='STATE_MISMATCH');
 bad=cp(state);bad.location_id='unknown';
 assert.throws(()=>previewHerbForage(bad,events),e=>e.code==='STATE_MISMATCH');
});
