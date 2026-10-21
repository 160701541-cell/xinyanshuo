import test from 'node:test';
import assert from 'node:assert/strict';
import {power, realmBase, rootPower, gearFactor, stateFactor, daoFactor, compare, REALM_BASE} from '../combat.mjs';
import {GRADES, gradeOf, gradePrice, rollGrade} from '../content/grades.mjs';

test('品阶五级，乘数递增，极品是凡品的十一倍', () => {
  assert.equal(GRADES.length, 5);
  const mults = GRADES.map(g => g.mult);
  for (let i = 1; i < mults.length; i++) assert.ok(mults[i] > mults[i - 1]);
  assert.equal(gradeOf('peak').mult, 11);
  assert.equal(gradePrice(100, 'peak'), 1100);
});

test('品阶出货概率加起来是一，rollGrade 不会回空', () => {
  let acc = 0;
  for (const r of [0.1, 0.4, 0.7, 0.9, 0.99]) { const g = rollGrade(() => r); assert.ok(g); acc++; }
  assert.equal(acc, 5);
});

test('战力公式：境界是主项，灵根与装备能拉开同境界差距', () => {
  const base = {realm: 'qi', layer: 3, hp: 100, stamina: 100, morale: 70};
  const poor = power({...base, root: 'wu'}).total;
  const rich = power({...base, root: 'tian', gear: {weapon: {grade: 'high'}}}).total;
  assert.ok(rich > poor * 1.5, `同境界差距应超过 50%：${poor} → ${rich}`);
});

test('大境界压制：金丹空手也强过炼气十三层天骄', () => {
  const qi = power({realm: 'qi', layer: 13, root: 'tian', gear: {weapon: {grade: 'peak'}}}).total;
  const core = power({realm: 'core', layer: 0, root: 'wu'}).total;
  assert.ok(core > qi, `金丹 ${core} 应强于炼气 ${qi}`);
});

test('状态与业力会压战力，低到下限为止', () => {
  const full = power({realm: 'found', hp: 100, stamina: 100, morale: 90}).total;
  const hurt = power({realm: 'found', hp: 20, stamina: 10, morale: 20, wounded: true}).total;
  assert.ok(hurt < full * 0.6);
  const evil = power({realm: 'found', karma: 120, bias: 0}).total;
  assert.ok(evil < power({realm: 'found', karma: 0}).total);
});

test('分项系数都能单独取到，便于界面拆解', () => {
  assert.equal(realmBase('spirit'), REALM_BASE.spirit);
  assert.equal(rootPower('none'), 0.55);
  assert.ok(gearFactor({}) === 1);
  assert.ok(stateFactor({hp: 100, stamina: 100, morale: 100}) > 1);
  assert.equal(daoFactor({karma: 0, bias: 0}), 1);
});

test('compare 能给出双方战力与胜负', () => {
  const r = compare({realm: 'core'}, {realm: 'qi', layer: 5});
  assert.equal(r.winner, 'a');
  assert.ok(r.ratio > 1);
});
