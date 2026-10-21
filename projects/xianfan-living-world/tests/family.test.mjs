import test from 'node:test';
import assert from 'node:assert/strict';
import {createWorld} from '../core.mjs';
import {ensureFamily,familyReport,familyMembers,joinFamily,marry,conceive,candidatesFor,ageFamily,ageOf,lifespanOf,rootOfPerson,inheritRoot} from '../family.mjs';

function folk(w, n = 2) {
  const out = w.people.filter(p => p.status === 'alive' && p.age >= 18 && p.age <= 32 && !p.root).slice(0, n);
  return out;
}

test('家族从世界里收真人，不是凭空造卡', () => {
  const w = createWorld('fam1');
  ensureFamily(w);
  const [a] = folk(w, 1);
  const r = joinFamily(w, a.id);
  assert.equal(r.ok, true);
  assert.equal(familyMembers(w).length, 1);
  assert.equal(familyReport(w).members, 1);
  // 同一个人不能入族两次
  assert.equal(joinFamily(w, a.id).ok, false);
});

test('联姻要求异性、成年、且双方未婚', () => {
  const w = createWorld('fam2');
  ensureFamily(w);
  const male = w.people.find(p => p.sex === '男' && p.age >= 18 && p.age <= 35);
  const female = w.people.find(p => p.sex === '女' && p.age >= 18 && p.age <= 35);
  joinFamily(w, male.id); joinFamily(w, female.id);
  assert.equal(marry(w, male.id, male.id).ok, false);
  const ok = marry(w, male.id, female.id);
  assert.equal(ok.ok, true);
  assert.equal(w.family.spouse[male.id], female.id);
  assert.equal(marry(w, male.id, female.id).ok, false);   // 不能重婚
});

test('生育要成过亲，孩子会进族谱并带上灵根', () => {
  const w = createWorld('fam3');
  ensureFamily(w);
  const male = w.people.find(p => p.sex === '男' && p.age >= 18 && p.age <= 35);
  const female = w.people.find(p => p.sex === '女' && p.age >= 18 && p.age <= 35);
  joinFamily(w, male.id); joinFamily(w, female.id);
  assert.equal(conceive(w, male.id, female.id).ok, false);  // 未婚先育，不成
  marry(w, male.id, female.id);
  const before = w.people.length;
  const r = conceive(w, male.id, female.id);
  assert.equal(r.ok, true);
  assert.equal(w.people.length, before + 1);
  assert.equal(r.child.age, 0);
  assert.ok(['none', 'wu', 'si', 'san', 'shuang', 'dan', 'tian'].includes(r.rootId));
  assert.equal(familyReport(w).members, 3);
});

test('两个凡人生不出灵根；修士父母有更大概率出好苗', () => {
  const w = createWorld('fam4');
  ensureFamily(w);
  const a = {id: 'X1', root: false, rootId: 'none'};
  const b = {id: 'X2', root: false, rootId: 'none'};
  assert.equal(inheritRoot(w, a, b), 'none');
  const c = {id: 'X3', root: true, rootId: 'san'};
  const d = {id: 'X4', root: true, rootId: 'shuang'};
  let better = 0;
  for (let i = 0; i < 40; i++) {
    // 每对夫妇各算一次：血脉抖动只看父母与次数，不因循环重复而固定
    const id = inheritRoot(w, {...c, id: 'X3-' + i}, {...d, id: 'X4-' + i});
    if (['san', 'shuang', 'dan', 'tian'].includes(id)) better++;
  }
  assert.ok(better > 20, `双修士应有至少一半几率不低于三灵根，实际 ${better}/40`);
});

test('寿元按境界给，过年会老会死', () => {
  const w = createWorld('fam5');
  ensureFamily(w);
  const [a] = folk(w, 1);
  joinFamily(w, a.id);
  const mortalSpan = lifespanOf(w, a);
  assert.ok(mortalSpan >= 50 && mortalSpan <= 75, `凡人寿元应在 50–75，实际 ${mortalSpan}`);
  const cultivator = {...a, id: 'Y1', realm: '筑基初期'};
  assert.ok(lifespanOf(w, cultivator) > mortalSpan);
  const age0 = ageOf(w, a);
  ageFamily(w, 10);
  assert.equal(ageOf(w, a), age0 + 10);
});

test('年景结算：族人越多口粮越重，田少就会卖地', () => {
  const w = createWorld('fam6');
  ensureFamily(w);
  for (const p of folk(w, 3)) joinFamily(w, p.id);
  w.family.estate.mu = 20;
  const r = ageFamily(w, 1);
  assert.equal(typeof r.income, 'number');
  ageFamily(w, 5);
  assert.ok(w.family.estate.silver >= 0, '族产不能为负');
  assert.ok(w.family.estate.mu >= 20, '卖地也不能低于 20 亩');
});
