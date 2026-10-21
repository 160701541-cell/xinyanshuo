import test from 'node:test';
import assert from 'node:assert/strict';
import {createWorld} from '../core.mjs';
import {
  ensureBuild, gather, helpElder, stealStraw, craft, canCraft, research, techLevel,
  trainUnit, unitsOf, learnGongfa, forge, buildReport, resOf, TECH,
} from '../build.mjs';

test('开局靠砍树割草攒够茅屋的材料', () => {
  const w = createWorld('hut');
  ensureBuild(w);
  w.player.stats = {hp: 100, stamina: 100};
  // 砍四趟木头（12），帮村长打四次短工（8 稻/次）+ 割草
  for (let i = 0; i < 4; i++) { w.player.stats.stamina = 100; gather(w, 'wood'); }
  for (let i = 0; i < 5; i++) { helpElder(w); }
  for (let i = 0; i < 2; i++) { w.player.stats.stamina = 100; gather(w, 'straw'); }
  assert.ok(resOf(w).wood >= 10, '木头要够 10');
  assert.ok(resOf(w).straw >= 50, '稻草要够 50');
  const r = craft(w, 'hut');
  assert.equal(r.ok, true, r.reason);
  assert.equal(buildReport(w).built.includes('hut×1'), true);
});

test('体力不够砍不动树', () => {
  const w = createWorld('tired');
  ensureBuild(w);
  w.player.stats = {hp: 100, stamina: 5};
  assert.equal(gather(w, 'wood').ok, false);
});

test('偷草有风险：被抓罚钱加业力，得手则进十二捆', () => {
  const w = createWorld('steal');
  ensureBuild(w);
  const caught = stealStraw(w, 0.1);
  assert.equal(caught.caught, true);
  assert.ok(w.player.silver < 170);
  const ok = stealStraw(w, 0.9);
  assert.equal(ok.ok, true);
  assert.equal(resOf(w).straw, 12);
});

test('帮工不管钱，但管饭、回体力、捎稻草', () => {
  const w = createWorld('help');
  ensureBuild(w);
  w.player.stats = {hp: 40, stamina: 10};
  const r = helpElder(w);
  assert.equal(r.paid, 0);
  assert.ok(w.player.stats.stamina > 60);
  assert.equal(resOf(w).straw, 8);
});

test('科技树按等级解锁配方，兵种树跟军械走', () => {
  const w = createWorld('tech');
  ensureBuild(w);
  assert.equal(canCraft(w, 'forge').ok, false, '没军械 1 级不能修铁匠炉');
  w.player.coin = 600000; w.player.silver = 6000;
  w.build.res.stone = 100; w.build.res.iron = 60; w.build.res.clay = 40; w.build.res.wood = 40;
  assert.equal(research(w, 'arms').ok, true);
  assert.equal(techLevel(w, 'arms'), 1);
  assert.equal(trainUnit(w, 'sword', 1).ok, false, '刀盾要军械 2 级');
  assert.equal(research(w, 'arms').ok, true);
  assert.equal(canCraft(w, 'forge').ok, true);
  const units = unitsOf(w).map(u => u.id);
  assert.ok(units.includes('sword'));
  assert.equal(trainUnit(w, 'spear', 1).ok, true);
});

test('功法树限境界与灵石，锻造限科技与材料', () => {
  const w = createWorld('gf');
  ensureBuild(w);
  assert.match(learnGongfa(w, 'core').reason, /境界/);
  w.player.realmLevel = 2; w.player.stones = 30;
  assert.equal(learnGongfa(w, 'core').ok, true);
  w.build.tech.arms = 2; w.build.res.iron = 10; w.build.res.wood = 10;
  const f = forge(w, 'sword_i');
  assert.equal(f.ok, true, f.reason);
  assert.equal(f.gear.grade, 'low');
});
