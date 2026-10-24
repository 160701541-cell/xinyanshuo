import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {trapEligibility,craftTrap,huntingStatus} from '../tools/hunting_engine.mjs';
import {calculateAction,commitPreview} from '../tools/numeric_engine.mjs';
import {digest} from '../tools/campaign_guard.mjs';

const base=new URL('../campaigns/first-life/',import.meta.url);
const read=n=>JSON.parse(readFileSync(new URL(n,base),'utf8'));
const initial={...read('state_core.json'),...read('state_world.json'),family:read('family.json'),initial_rolls_public:read('initial_rolls_public.json')};
const events=readFileSync(new URL('events.jsonl',base),'utf8').trim().split('\n').map(JSON.parse);
const config=JSON.parse(readFileSync(new URL('../data/hunting_rules_v1.json',import.meta.url),'utf8'));
const copy=x=>structuredClone(x);

test('read-only look-up: no existing prey or trap ingredients asserted',()=>{
 const before=JSON.stringify(initial),s=huntingStatus(initial);
 assert.equal(s.trap_recipe.can_craft,false);
 assert.equal(s.wildlife_registry_present,false);
 assert.equal(s.can_confirm_prey,false);
 assert.equal(s.trap_recipe.materials.length,3);
 assert.ok(s.trap_recipe.materials.every(x=>x.have===0));
 assert.equal(JSON.stringify(initial),before);
});
test('material shortage cannot build a free snare',()=>{
 const s=copy(initial);
 assert.throws(()=>calculateAction(s,{type:'craft_trap',recipe_id:'cord_snare'}),e=>e.code==='MATERIALS_MISSING');
 assert.deepEqual(s,initial);
});
test('only registered owned material is used; exact time and energy formula',()=>{
 const s=copy(initial),recipe=config.recipes.cord_snare;
 for(const req of recipe.requires)s.inventory.push({id:req.id,name:req.name,quantity:req.quantity,equipped:false});
 const p=calculateAction(s,{type:'craft_trap',recipe_id:'cord_snare'});
 assert.equal(p.state.player.stamina,100-recipe.stamina_cost);
 assert.equal(p.duration_minutes,recipe.time_minutes);
 assert.equal(p.state.time.hour,8);
 assert.equal(p.state.time.minute,recipe.time_minutes);
 assert.equal(p.state.inventory.find(x=>x.id==='cord_snare')?.quantity,1);
 assert.ok(recipe.requires.every(r=>!p.state.inventory.some(i=>i.id===r.id)));
 assert.equal(p.receipts[0].wildlife_added,0);
 assert.equal(p.receipts[0].spontaneous_loot,0);
 assert.equal(s.player.stamina,100);
 assert.ok(recipe.requires.every(r=>s.inventory.some(i=>i.id===r.id)));
});
test('crafting event is re-computed, and hashes are correctly chained',()=>{
 const s=copy(initial),recipe=config.recipes.cord_snare;
 for(const req of recipe.requires)s.inventory.push({id:req.id,quantity:req.quantity,equipped:false,name:req.name});
 // Test fixtures are synthetic. Commit must reject stale state against real EV000002.
 const p=calculateAction(s,{type:'craft_trap',recipe_id:'cord_snare'});
 assert.throws(()=>commitPreview(s,events,p),e=>e.code==='STATE_CHANGED');
 assert.equal(digest(initial),events.at(-1).state_hash);
});
test('repeated crafting without more materials is forbidden',()=>{
 const s=copy(initial);
 for(const r of config.recipes.cord_snare.requires)s.inventory.push({id:r.id,quantity:r.quantity});
 craftTrap(s);
 assert.throws(()=>craftTrap(s),e=>e.code==='MATERIALS_MISSING');
});
test('no spawn-from-nowhere and negative stock, zero stamina or unknown recipes',()=>{
 const s=copy(initial);
 assert.throws(()=>trapEligibility(s,'legendary_free_trap'),e=>e.code==='UNKNOWN_RECIPE');
 s.inventory.push({id:'flexible_branch',quantity:-1});
 assert.throws(()=>trapEligibility(s),e=>e.code==='INVALID_QUANTITY');
 s.inventory.pop();
 s.player.stamina=0;
 assert.equal(trapEligibility(s).can_craft,false);
});
