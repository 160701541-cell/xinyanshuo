import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {MATERIALS,WORLDX_COMMIT,promptFor} from './worldx_raw_materials_batch01.mjs';
test('WorldX material-only policy: exactly four independent raw surfaces',()=>{
 assert.deepEqual(MATERIALS.map(x=>x.id),['timber','cut_stone','mortar','roof_tile']);
 assert.equal(new Set(MATERIALS.map(x=>x.id)).size,4);
 assert.match(WORLDX_COMMIT,/^[a-f0-9]{40}$/);
 assert.ok(MATERIALS.every(x=>x.subject.length>25));
});
test('WorldX-native prompt-loader bridge forbids facade/HD2D building assets',()=>{
 const prompt=readFileSync(new URL('./worldx_raw_material_template.md',import.meta.url),'utf8');
 for(const keyword of ['{{materialID}}','{{userPrompt}}','{{additionalConstraints}}'])
   assert.ok(prompt.includes(keyword));
 const f=(name,obj)=>prompt.replace(/{{([a-zA-Z]+)}}/g,(_,k)=>obj[k]??'');
 const generated=promptFor(MATERIALS[0],f);
 assert.ok(generated.includes('无缝平铺'));
 assert.ok(generated.includes('不是建筑物'));
 assert.ok(generated.includes('90度'));
 assert.ok(!generated.includes('{{'));
});
test('real WorldX loader pinned and only material-image API output; no paid retry',()=>{
 const source=readFileSync(new URL('./worldx_raw_materials_batch01.mjs',import.meta.url),'utf8');
 assert.ok(source.includes('generators/map/src/utils/prompt-loader.mjs'));
 assert.ok(source.includes('loadPrompt'));
 assert.ok(source.includes('SILICONFLOW_API_KEY'));
 assert.ok(source.includes('NO automatic retry'));
 assert.ok(source.includes('not_finished_building:true,no_hd2d:true'));
 assert.ok(source.includes("status:'GENERATED_UNAPPROVED'"));
 assert.ok(!source.includes('workflow_dispatch'));
});
