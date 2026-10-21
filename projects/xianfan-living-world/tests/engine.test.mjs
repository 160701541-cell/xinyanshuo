import test from 'node:test';
import assert from 'node:assert/strict';
import {createWorld} from '../core.mjs';
import {RULES, CARD_TEMPLATES, validateRule, checkCond, applyEffects, runRules, ensureEngine, registerRules, cardView} from '../engine.mjs';
import {loadContent} from '../content/index.mjs';
import {iconIdFor} from '../content/icons.mjs';

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
  const withPop = cardView(w, 'poi-place', {item: {name: '东市', type: 'market', population: 900, detail: '热闹'}, canGo: true});
  assert.ok(withPop.rows.some(r => r.label === '人口'));
  assert.ok(withPop.actions.some(a => a.id === 'go'), '有路可走时应出现前往按钮');
  assert.equal(cardView(w, 'nope'), null);
});

test('卡片自带图标：客栈出 inn，厨房出 kitchen，名字认不出就落 generic', async () => {
  const {createWorld} = await import('../core.mjs');
  const w = createWorld('icon');
  const inn = cardView(w, 'poi-structure', {item: {name: '望江客栈'}});
  assert.equal(inn.icon.id, 'inn');
  assert.equal(inn.icon.rows.length, 16, '图标是 16×16 的像素网格');
  assert.equal(cardView(w, 'poi-structure', {item: {name: '官厨'}}).icon.id, 'kitchen');
  assert.equal(cardView(w, 'poi-structure', {item: {name: '不知名的地方'}}).icon.id, 'generic');
});

test('人物卡按职业画头像，不是查建筑名', async () => {
  const {createWorld} = await import('../core.mjs');
  const w = createWorld('icon-person');
  const 商 = cardView(w, 'person-card', {item: {person: {job: '掌柜', sex: '男'}, name: '张三'}});
  const 农 = cardView(w, 'person-card', {item: {person: {job: '农夫', sex: '女'}, name: '李四'}});
  assert.equal(商.icon.rows.length, 16);
  assert.notEqual(商.icon.palette['1'], 农.icon.palette['1'], '不同职业衣色不同');
});

test('图标按整名优先、再按最长包含匹配，不会把“客栈掌柜”认成“栈”', () => {
  assert.equal(iconIdFor('客栈掌柜'), 'inn');
  assert.equal(iconIdFor('厨房后巷'), 'kitchen');
  assert.equal(iconIdFor(''), 'generic');
});

test('卡牌背景按名字出场景：客栈两层楼、厨房灶台、衙门堂屋', async () => {
  const {sceneIdFor, sceneFor, W, H} = await import('../content/scenes.mjs');
  assert.equal(sceneIdFor('望江客栈'), 'inn');
  assert.equal(sceneIdFor('官厨'), 'kitchen');
  assert.equal(sceneIdFor('临安县衙'), 'office');
  assert.equal(sceneIdFor('灵山药圃'), 'herb');
  assert.equal(sceneIdFor('莫名其妙的地方'), 'generic');
  const s = sceneFor('望江客栈');
  assert.equal(s.id, 'inn');
  assert.equal(s.rows.length, H);
  assert.equal(s.rows[0].split('\u0001').length, W);
});

test('卡片视图带 scene；人物卡不画场景，只给头像', async () => {
  const {createWorld} = await import('../core.mjs');
  const w = createWorld('scene-card');
  const inn = cardView(w, 'poi-structure', {item: {name: '望江客栈'}});
  assert.equal(inn.scene.id, 'inn');
  const person = cardView(w, 'person-card', {item: {person: {job: '厨娘', sex: '女'}, name: '阿绫'}});
  assert.equal(person.scene, null);
  assert.ok(person.icon.rows.length > 0);
});

test('场景不会因为名称里有“店”就都当成客栈：铁匠铺走 forge', async () => {
  const {sceneIdFor} = await import('../content/scenes.mjs');
  assert.equal(sceneIdFor('铁匠铺'), 'forge');
  assert.equal(sceneIdFor('渡口'), 'dock');
  assert.equal(sceneIdFor('南门'), 'gate');
  assert.equal(sceneIdFor('田畴'), 'field');
});
