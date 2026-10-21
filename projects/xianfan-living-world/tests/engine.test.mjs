import test from 'node:test';
import assert from 'node:assert/strict';
import {createWorld} from '../core.mjs';
import {RULES, CARD_TEMPLATES, validateRule, checkCond, applyEffects, runRules, ensureEngine, registerRules, cardView} from '../engine.mjs';
import {loadContent} from '../content/index.mjs';

loadContent();

test('内容表全量校验通过，且没有重复 id', () => {
  const errs = [];
  for (const r of RULES) errs.push(...validateRule(r));
  assert.deepEqual(errs, []);
  assert.equal(new Set(RULES.map(r => r.id)).size, RULES.length);
  assert.ok(RULES.length >= 8, `规则太少：${RULES.length}`);
  assert.ok(CARD_TEMPLATES.size >= 2);
});

test('未知运算符与未知效果会被校验拦下', () => {
  assert.ok(validateRule({id: 'x', hook: 'daily', when: {path: 'day', op: 'nope'}, then: [{do: 'note', text: 'x'}]}).length);
  assert.ok(validateRule({id: 'y', hook: 'daily', then: [{do: 'boom'}]}).length);
  assert.ok(validateRule({id: 'z', hook: 'daily', then: []}).length);
});

test('条件组合：all / any / not / 数值比较', () => {
  const w = createWorld('cond');
  w.day = 10; w.price = 30;
  assert.equal(checkCond(w, {path: 'day', op: 'gte', value: 5}), true);
  assert.equal(checkCond(w, {all: [{path: 'day', op: 'gte', value: 5}, {path: 'price', op: 'gt', value: 100}]}), false);
  assert.equal(checkCond(w, {any: [{path: 'day', op: 'lt', value: 5}, {path: 'price', op: 'gt', value: 20}]}), true);
  assert.equal(checkCond(w, {not: {path: 'day', op: 'gte', value: 5}}), false);
});

test('效果：加减、赋值、记事模板、标记', () => {
  const w = createWorld('eff');
  ensureEngine(w);
  const before = w.player.silver;
  applyEffects(w, [{do: 'add', path: 'player.silver', by: -7}, {do: 'note', type: '测试', text: '{{player}} 花了七文'}]);
  assert.equal(w.player.silver, before - 7);
  assert.equal(w.history.at(-1).message, `${w.player.name} 花了七文`);
  applyEffects(w, [{do: 'flag', key: 'tested', value: true}]);
  assert.equal(w.engine.flags.tested, true);
});

test('once 只触发一次，cooldown 到日子才再触发', () => {
  registerRules([
    {id: 'test-once', hook: 'daily', once: true, when: {path: 'day', op: 'gte', value: 1}, then: [{do: 'add', path: 'player.grain', by: 1}]},
    {id: 'test-cool', hook: 'daily', cooldown: 5, when: {path: 'day', op: 'gte', value: 1}, then: [{do: 'add', path: 'player.grain', by: 10}]}
  ]);
  const w = createWorld('once'); ensureEngine(w); w.day = 1;
  runRules(w, 'daily', {});
  const g1 = w.player.grain;
  w.day = 2; runRules(w, 'daily', {});
  assert.equal(w.player.grain, g1, 'once 不该再触发；cooldown 未到也不该触发');
  w.day = 7; runRules(w, 'daily', {});
  assert.equal(w.player.grain, g1 + 10);
});

test('钩子各管各的：旅行钩子不在日循环里触发', () => {
  const w = createWorld('hook'); ensureEngine(w); w.day = 5;
  const before = w.history.length;
  runRules(w, 'travel', {mode: 'foot'});
  assert.ok(w.history.length > before, '旅行钩子应当记事');
  const ids = w.engine.log.map(l => l.id);
  assert.ok(ids.includes('encounter-travel'));
  assert.ok(!ids.includes('market-fair'), 'daily 规则不该被 travel 钩子带起来');
});

test('卡片模板按条件出字段，界面不用自己挑', () => {
  const w = createWorld('card');
  const noPop = cardView(w, 'poi-place', {item: {name: '空屋', type: 'homes', population: 0, detail: '没人'}});
  assert.ok(!noPop.rows.some(r => r.label === '人口'));
  const withPop = cardView(w, 'poi-place', {item: {name: '东市', type: 'market', population: 900, detail: '热闹'}, reachable: true});
  assert.ok(withPop.rows.some(r => r.label === '人口'));
  assert.deepEqual(withPop.actions.map(a => a.id), ['goto']);
  assert.equal(cardView(w, 'nope'), null);
});
