import test from 'node:test';
import assert from 'node:assert/strict';
import {sheetFor,dirFor,rowOf,stepOf,WALK_DIRS,SHEETS,PORTRAITS} from '../people.mjs';
import {createWorld} from '../core.mjs';
import {ensurePractice,practice,breakLayer,breakRealm,restMeridian,practiceReport,BARRIERS,LAYERS} from '../cultivation.mjs';

test('v0.34 小人走图沿用已验的 CC0 素材，按职业选图', () => {
  assert.equal(Object.keys(SHEETS).length, 4);
  assert.equal(sheetFor({job: '捕快'}), 'hero');
  assert.equal(sheetFor({job: '商贩'}), 'merchant');
  assert.equal(sheetFor({job: '农户'}), 'farmer');
  assert.equal(sheetFor({job: '修士'}), 'woodsman');
  assert.equal(sheetFor({job: '不明职业'}), 'woodsman');
  assert.ok(PORTRAITS.male && PORTRAITS.female);
});

test('v0.34 朝向与走路帧：四向、三帧循环', () => {
  assert.deepEqual(WALK_DIRS, ['down', 'left', 'right', 'up']);
  assert.equal(dirFor(-1, 0), 'left');
  assert.equal(dirFor(0, -2), 'up');
  assert.equal(dirFor(0.2, 0.9), 'down');
  assert.equal(dirFor(0, 0, 'left'), 'left');
  assert.equal(rowOf('up'), 3);
  assert.deepEqual([0, 170, 340, 510].map(t => stepOf(true, t)), [0, 1, 2, 0]);
  assert.equal(stepOf(false, 999), 1);
});

test('v0.34 吐纳：灵根决定速度，没灵根一点都进不去', () => {
  const w = createWorld('吐纳');
  w.player.place = 'qingyun';
  ensurePractice(w);
  w.practice.rootId = 'none';
  assert.equal(practice(w, 1).ok, false);
  w.practice.rootId = 'san';
  const r = practice(w, 1);
  assert.ok(r.ok && r.gain > 0);
  assert.ok(r.progress > 0);
});

test('v0.34 灵气密度影响收益：灵山快过县城', () => {
  const a = createWorld('密度a'); a.player.root = 'san'; a.player.place = 'lingshan';
  const b = createWorld('密度b'); b.player.root = 'san'; b.player.place = 'xiancheng';
  ensurePractice(a); ensurePractice(b);
  const ga = practice(a, 4).gain, gb = practice(b, 4).gain;
  assert.ok(ga > gb, `灵山 ${ga} 应快过县城 ${gb}`);
});

test('v0.34 经脉堵死必须歇息，不能无限刷', () => {
  const w = createWorld('经脉'); w.player.root = 'tian'; w.player.place = 'lingshan';
  ensurePractice(w);
  for (let i = 0; i < 80; i++) practice(w, 1);
  assert.ok(w.practice.meridian >= 100);
  const blocked = practice(w, 1);
  assert.equal(blocked.ok, false);
  assert.match(blocked.error, /经脉/);
  const r = restMeridian(w, 10);
  assert.ok(r.meridian < 100);
});

test('v0.34 层间突破要够修为，筑基要炼满十三层', () => {
  const w = createWorld('突破'); w.player.root = 'tian'; w.player.place = 'lingshan';
  ensurePractice(w);
  w.practice.progress = BARRIERS[1].need - 1;
  assert.equal(breakLayer(w).ok, false);
  w.practice.progress = BARRIERS[1].need;
  const ok = breakLayer(w);
  assert.ok(ok.ok);
  assert.equal(ok.name, '炼气一层');
  assert.equal(breakRealm(w).ok, false);
  assert.equal(LAYERS, 13);
});

test('v0.34 十三层阶梯是名词表、每层要求递增', () => {
  const needs = Object.values(BARRIERS).map(b => b.need);
  for (let i = 1; i < needs.length; i++) assert.ok(needs[i] > needs[i - 1]);
  assert.equal(BARRIERS[LAYERS].name, '炼气十三层');
  const w = createWorld('报告'); w.player.root = 'si';
  ensurePractice(w);
  const r = practiceReport(w);
  assert.equal(r.layerName, '凡人');
  assert.equal(r.root, '四灵根');
});
