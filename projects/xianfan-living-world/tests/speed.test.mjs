import test from 'node:test';
import assert from 'node:assert/strict';
import {speedOf, speedReport, BAG_SLOTS, bagSlots, addToBag, tidyBag, BASE_SPEED} from '../speed.mjs';

const mk = (p = {}) => ({player: {realmLevel: 0, bag: {}, ...p}});

test('凡人空手 1.35 米/秒，走官道 2.16', () => {
  assert.equal(speedOf(mk()).speed, BASE_SPEED);
  assert.equal(speedOf(mk({onRoad: true})).speed, 2.16);
});

test('境界、靴子、轻功是乘区叠加', () => {
  const a = speedOf(mk({realmLevel: 4})).speed;       // 1.2
  const b = speedOf(mk({realmLevel: 4, gear: {boots: 0.1}})).speed;
  const c = speedOf(mk({realmLevel: 4, gear: {boots: 0.1}, martial: 0.2})).speed;
  assert.ok(a > BASE_SPEED && b > a && c > b);
});

test('翅膀、坐骑、载具、符箓各算各的乘区', () => {
  const plain = speedOf(mk()).speed;
  assert.equal(speedOf(mk({wings: true})).speed, +(plain * 1.9).toFixed(2));
  assert.equal(speedOf(mk({mount: true})).speed, +(plain * 1.4).toFixed(2));
  assert.equal(speedOf(mk({vehicle: 'sword'})).speed, +(plain * 2.4).toFixed(2));
  assert.equal(speedOf(mk({buffs: {godspeed: 1}})).speed, +(plain * 1.25).toFixed(2));
});

test('超格才罚速度，不超不罚', () => {
  const full = mk({bag: {grain: BAG_SLOTS}});
  assert.equal(bagSlots(full).full, true);
  assert.equal(speedOf(full).speed, BASE_SPEED);
  const over = mk({bag: {grain: BAG_SLOTS + 2}});
  assert.ok(speedOf(over).speed < BASE_SPEED);
});

test('行囊一件一格，满了装不下', () => {
  const w = mk();
  assert.equal(addToBag(w, 'grain', BAG_SLOTS).ok, true);
  assert.equal(addToBag(w, 'meat', 1).ok, false);
});

test('一键整理：同 id 合并、按件数降序', () => {
  const w = mk({bag: {'grain|mortal': 2, grain: 3, meat: 1}});
  const bag = tidyBag(w);
  assert.equal(bag.grain, 5);
  assert.deepEqual(Object.keys(bag), ['grain', 'meat']);
});

test('速度报告把每一项都写出来', () => {
  const s = speedReport(mk({onRoad: true, mount: true}));
  assert.match(s, /官道 ×1\.6/);
  assert.match(s, /坐骑 ×1\.4/);
});
