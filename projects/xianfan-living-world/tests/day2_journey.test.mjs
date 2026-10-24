import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {digest,verifyEvents,countTurns} from '../tools/campaign_guard.mjs';
import {calculateDay2Journey} from '../tools/day2_journey_turn.mjs';
const root=new URL('../campaigns/first-life/',import.meta.url);
const read=n=>JSON.parse(readFileSync(new URL(n,root),'utf8'));
const state=read('game_state.json');
const events=readFileSync(new URL('events.jsonl',root),'utf8').trim().split('\n').map(JSON.parse);
const index=read('campaign_index.json');

test('full first life remains hash-verifiable after crossing day boundary',()=>{
 assert.equal(verifyEvents(events).last_hash,index.last_event_hash);
 assert.equal(digest(state),events.at(-1).state_hash);
 assert.equal(index.full_state_sha256,digest(state));
 assert.equal(countTurns(events),index.turns_completed);
 assert.equal(index.turns_completed,11);
 assert.equal(state.time.day,2);
 assert.equal(state.time.hour,9);
 assert.equal(state.time.minute,4);
 assert.equal(state.location_id,'linan');
});

test('food consumption respects household property and integer grain remainders',()=>{
 const a=events.at(-1),total=a.receipts.filter(x=>x.quantity_millidou).reduce((n,x)=>n+x.quantity_millidou,0);
 assert.equal(a.after.grain_millidou,a.before.grain_millidou-total);
 assert.equal(total,108);
 assert.equal(state.family.grain_dou*1000+state.family.grain_remainder_millidou,a.after.grain_millidou);
 assert.equal(state.family.cash,42);
 assert.equal(state.player.money,12);
 assert.equal(state.player.hp,100);
});

test('registered wildlife stock not minted, wild animal trap empty this morning',()=>{
 const eco=state.ecology['shiqiao-outskirts-v1'];
 const hare=eco.animals.find(x=>x.id==='SH-HARE-01');
 const trap=eco.deployed_traps.find(x=>x.id==='TRAP-SHIQIAO-0001');
 assert.equal(hare.count+trap.captured_count,3);
 assert.equal(trap.captured_count,0);
 assert.equal(trap.capture_status,'checked_empty');
});

test('a trapped fish is NOT silently granted to player inventory',()=>{
 const water=state.ecology['shiqiao-outskirts-v1'].freshwater;
 const fish=water.stocks.find(x=>x.id==='small_cyprinid');
 const basket=water.installed_gear.find(x=>x.id==='GEAR-SH-RIVER-0001');
 assert.equal(fish.initial_population,fish.population+fish.harvested);
 assert.equal(fish.harvested,basket.catch_count);
 assert.equal(basket.catch_count,1);
 assert.ok(!state.inventory.some(x=>x.id==='fresh_small_fish'));
 assert.equal(water.catch_events.at(-1).checks.length,8);
});

test('cannot replay home and county sequence on a finished next-day save',()=>{
 const registry=read('npc_registry.json');
 assert.throws(()=>calculateDay2Journey(state,events,registry),e=>e.code==='INCORRECT_SCENE');
});
