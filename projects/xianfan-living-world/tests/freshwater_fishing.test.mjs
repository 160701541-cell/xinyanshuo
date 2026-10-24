import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {deployBasket,inspectWaterSite} from '../tools/freshwater_fishing.mjs';
import {verifyEvents,digest} from '../tools/campaign_guard.mjs';
const root=new URL('../campaigns/first-life/',import.meta.url);
const state=JSON.parse(readFileSync(new URL('game_state.json',root),'utf8'));
const events=readFileSync(new URL('events.jsonl',root),'utf8').trim().split('\n').map(JSON.parse);
test('this committed deployment is reflected by authoritative ledger',()=>{
 const latest=events.at(-1),water=state.ecology['shiqiao-outskirts-v1'].freshwater;
 assert.ok(latest.action==='deploy_fish_basket_in_shiqiao_bay');
 assert.equal(verifyEvents(events).last_hash,latest.hash);
 assert.equal(digest(state),latest.state_hash);
 assert.equal(water.installed_gear.length,1);
 assert.equal(water.installed_gear[0].catch_count,0);
 assert.equal(water.installed_gear[0].source_event_id,'EV000010');
 assert.ok(!state.inventory.some(i=>i.id==='woven_fish_basket'));
 assert.throws(()=>deployBasket(state,events),e=>e.code==='DUPLICATE_ACTION'||e.code==='NO_READY_BASKET');
});
test('river parameters are safe in the current authoritative location',()=>{
 const site=inspectWaterSite(state);
 assert.equal(site.depth_cm,48);
 assert.equal(site.flow_cm_per_s,12);
 assert.ok(site.safe_for_bank_installation);
});
test('fish population can be zero and never translates directly into instant catch',()=>{
 const water=state.ecology['shiqiao-outskirts-v1'].freshwater;
 for(const fish of water.stocks)assert.equal(fish.population,fish.initial_population);
 assert.equal(water.catch_events.length,0);
 assert.equal(water.installed_gear[0].status,'deployed_waiting');
});
