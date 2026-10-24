import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';

const rules=JSON.parse(readFileSync(new URL('../data/unified_world_rules_v1.json',import.meta.url),'utf8'));
const canon=readFileSync(new URL('../docs/UNIFIED_WORLD_CANON_V1.md',import.meta.url),'utf8');

test('canon schema and engineering boundaries',()=>{
  assert.equal(rules.schema,'xianfan.worldcanon.v1');
  assert.equal(rules.independence.main_godot,false);
  assert.equal(rules.independence.worldbox_mod,false);
  assert.equal(rules.independence.android_ota,false);
  assert.equal(rules.technical_status.runtime_integration,false);
  assert.equal(rules.technical_status.android_test,false);
});
test('population does not blend projects',()=>{
  assert.equal(rules.sample_populations.xianfan_local.initial,13680);
  assert.equal(rules.sample_populations.canglan_godot.initial,5000);
  assert.equal(rules.sample_populations.canglan_godot.must_not_merge,true);
  assert.equal(rules.sample_populations.national_population.value,null);
});
test('world layers distinguish implemented from planned',()=>{
  assert.deepEqual(rules.world_layers.map(x=>x.id),['mortal','pocket','spirit','immortal','nether']);
  for(const w of rules.world_layers.slice(1))assert.ok(['design','future'].includes(w.status));
});
test('unique stable geography in metres',()=>{
  assert.equal(rules.geo.unit,'m');
  const anchors=rules.geo.anchors;
  assert.equal(new Set(anchors.map(v=>v.id)).size,anchors.length);
  for(const p of anchors){assert.ok(Number.isFinite(p.x)&&Number.isFinite(p.y));assert.ok(p.name);}
  assert.deepEqual(anchors.find(v=>v.id==='shiqiao'),{id:'shiqiao',name:'石桥村',x:3600,y:4800});
});
test('ordered human cultivation and nonlevel ascension',()=>{
  const levels=rules.cultivation.spirit_path;
  assert.equal(levels.length,9);
  assert.deepEqual(levels.map(x=>x.tier),[0,1,2,3,4,5,6,7,8]);
  assert.equal(levels[1].levels,13);
  assert.equal(rules.cultivation.ascension.not_rank,true);
  assert.equal(rules.cultivation.hide_root_until_test,true);
  assert.equal(rules.cultivation.root_generated_once_at_birth,true);
  assert.ok(rules.cultivation.physical_path.length>=8);
});
test('player checkpoint fixed and NPCs preserve IDs',()=>{
  const p=rules.text_campaign;
  assert.equal(p.player.age,16);
  assert.equal(p.player.sex,'男');
  assert.equal(p.player.root_public,'未检测');
  assert.equal(p.initial_time.hour,8);
  assert.equal(p.player_turns_settled,0);
  assert.equal(p.family.members.length,3);
  assert.equal(new Set(p.family.members.map(x=>x.id)).size,3);
  assert.equal(p.family.not_player_property,true);
});
test('canon explicitly separates known game from speculative upper worlds',()=>{
  assert.match(canon,/尚未实现/);
  assert.match(canon,/玩家知识≠主持人全局真相/);
  assert.match(canon,/50,000/);
  assert.match(canon,/13,680/);
  assert.match(canon,/凡人修仙传/);
});
