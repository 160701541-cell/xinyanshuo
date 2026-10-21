import test from 'node:test';
import assert from 'node:assert/strict';
import {createWorld} from '../core.mjs';
import {readCoin} from '../money.mjs';
import {
  ensureLife, statsOf, stayInn, workDay, buyHouse, upgradeHome, hire, recruitCap,
  foundSect, takeDisciple, canTakeThrone, takeThrone, lifeReport, sellGoods, restDay,
} from '../life.mjs';

test('开局睡客栈：付钱、回体力、推进时间', () => {
  const w = createWorld('inn');
  statsOf(w).stamina = 30;
  const r = stayInn(w, 1);
  assert.equal(r.ok, true);
  assert.equal(w.player.coin, 16980);
  assert.ok(statsOf(w).stamina > 60);
});

test('打工能挣钱，体力不够就干不了', () => {
  const w = createWorld('work');
  const before = readCoin(w);
  const r = workDay(w, 'clerk');
  assert.equal(r.ok, true);
  assert.equal(readCoin(w), before + 10);
  statsOf(w).stamina = 1;
  assert.equal(workDay(w, 'guard').ok, false);
});

test('先有宅子才养得起人，招人有人数上限', () => {
  const w = createWorld('home');
  w.player.coin = 500000;
  assert.equal(recruitCap(w), 2);
  assert.equal(buyHouse(w, 'room').ok, true);
  assert.equal(recruitCap(w), 6);
  assert.equal(hire(w, 7).ok, false);
  assert.equal(hire(w, 3).ok, true);
  assert.equal(w.player.men, 3);
});

test('加盖宅子提高上限，最多三级', () => {
  const w = createWorld('up');
  w.player.coin = 2000000;
  buyHouse(w, 'room');
  assert.equal(upgradeHome(w).ok, true);
  assert.equal(upgradeHome(w).ok, true);
  assert.equal(upgradeHome(w).ok, false);
  assert.equal(recruitCap(w), 30);
});

test('立宗要筑基、银钱、灵石三样齐；缺一样都报出来', () => {
  const w = createWorld('sect');
  ensureLife(w);
  assert.match(foundSect(w, '听雪宗').reason, /筑基/);
  w.player.realmLevel = 2;
  assert.match(foundSect(w, '听雪宗').reason, /开山要/);
  w.player.coin = 80000;
  assert.match(foundSect(w, '听雪宗').reason, /灵石/);
  w.player.stones = 60;
  assert.equal(foundSect(w, '听雪宗').ok, true);
  assert.equal(takeDisciple(w, 2).disciples, 2);
});

test('称王要县令位份、六十兵、名望、两万银', () => {
  const w = createWorld('throne');
  ensureLife(w);
  assert.match(canTakeThrone(w).reason, /县令/);
  w.career = {ranks: {office: 2}, fame: 200};
  w.player.men = 60; w.player.coin = 300000;
  assert.equal(canTakeThrone(w).ok, true);
  assert.equal(takeThrone(w, '临安王').ok, true);
  assert.equal(lifeReport(w).realm.title, '临安王');
});

test('卖东西只值六成，行囊会扣数', () => {
  const w = createWorld('sell');
  w.player.bag = {妖丹: 2};
  w.itemPrice = {妖丹: 120};
  const r = sellGoods(w, '妖丹', 1);
  assert.equal(r.ok, true);
  assert.equal(r.gain, 72);
  assert.equal(w.player.bag['妖丹'], 1);
});

test('歇息能回体力，有宅子回得更快', () => {
  const w = createWorld('rest');
  ensureLife(w);
  statsOf(w).stamina = 0;
  restDay(w, 1);
  const street = statsOf(w).stamina;
  statsOf(w).stamina = 0;
  w.player.coin = 500000;
  buyHouse(w, 'room');
  restDay(w, 1);
  assert.ok(statsOf(w).stamina > street, '自家歇息应比睡街边快');
});
