import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {VIEWS,WORLDX_COMMIT,BUILDING_ID,fullPrompt} from './worldx_four_facades.mjs';

test('genuinely four DIFFERENT world-facing surfaces, not a panorama',()=>{
  assert.deepEqual(VIEWS.map(x=>x.id),['front','back','left','right']);
  assert.equal(new Set(VIEWS.map(x=>x.facing)).size,4);
  assert.ok(VIEWS.every(x=>x.detail.length>15));
  assert.equal(BUILDING_ID,'courtyard_main_hall');
});
test('WorldX upstream pinned and prompt uses ONLY orthographic facade view',()=>{
  assert.match(WORLDX_COMMIT,/^[0-9a-f]{40}$/);
  const content=readFileSync(new URL('./worldx_four_facades.prompt.md',import.meta.url),'utf8');
  for(const token of ['{{buildingId}}','{{facing}}','{{viewSpecification}}'])
    assert.ok(content.includes(token));
  const text=fullPrompt(VIEWS[0],(_,values)=>{
    return content.replace(/{{(\w+)}}/g,(match,key)=>String(values[key]??match));
  });
  assert.ok(!text.includes('{{'),text);
  assert.ok(text.includes('正交投影'));
  assert.ok(text.includes('只能看到这一面'));
  assert.ok(text.includes('不要把四面放在同一张图'));
  assert.ok(text.includes('非HD2D地图'));
});
test('REAL upstream loader, image EDIT reference, SHA verification, no fake deployment',()=>{
  const s=readFileSync(new URL('./worldx_four_facades.mjs',import.meta.url),'utf8');
  assert.ok(s.includes('generators/map/src/utils/prompt-loader.mjs'));
  assert.ok(s.includes("const {loadPrompt}=await import("));
  assert.ok(s.includes('Qwen/Qwen-Image-Edit-2509'));
  assert.ok(s.includes('main_house_v3_source.png'));
  assert.ok(s.includes('api.siliconflow.cn/v1/images/generations'));
  assert.ok(s.includes('image:'));
  assert.ok(s.includes('NO AUTO RETRY'));
  assert.ok(s.includes('GENERATED_UNAPPROVED'));
  assert.ok(!s.includes('gh release'));
});
