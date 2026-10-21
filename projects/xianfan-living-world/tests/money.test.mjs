import test from 'node:test';
import assert from 'node:assert/strict';
import {COIN, fmt, monthWage, dayWage, ensureCoin, spend, earn} from '../money.mjs';
import {createWorld} from '../core.mjs';

test('七级钱币：文→银→金→下品各百进，下品→中品→上品千进，极品一万中品', () => {
  assert.equal(COIN.silver / COIN.wen, 100);
  assert.equal(COIN.gold / COIN.silver, 100);
  assert.equal(COIN.stoneLow / COIN.gold, 100);
  assert.equal(COIN.stoneMid / COIN.stoneLow, 1000);
  assert.equal(COIN.stoneHigh / COIN.stoneMid, 1000);
  assert.equal(COIN.stonePeak / COIN.stoneMid, 10000);
  assert.equal(COIN.stonePeak / COIN.stoneHigh, 10);
});

test('月钱与日薪落在 150–300 / 120–220 文之间', () => {
  assert.equal(monthWage('男', 0), 150);
  assert.equal(monthWage('男', 1), 300);
  assert.equal(monthWage('女', 0), 120);
  assert.equal(monthWage('女', 1), 220);
  assert.equal(dayWage('男', 0.5), 9);
});

test('钱袋从旧 silver 迁移，且花出去会同步两套字段', () => {
  const w = createWorld('coin');
  w.player.silver = 3;
  assert.equal(ensureCoin(w), 300);
  assert.equal(spend(w, 120), true);
  assert.equal(w.player.coin, 180);
  assert.equal(w.player.silver, 1);
  earn(w, 20);
  assert.equal(w.player.coin, 200);
});

test('金额显示按档位折行，不堆一串文', () => {
  assert.equal(fmt(7), '7 文');
  assert.equal(fmt(250), '2 两银 50 文');
  assert.equal(fmt(12345), '1 两金 23 两银 45 文');
  assert.match(fmt(1e6), /下品灵石/);
  assert.match(fmt(1e9), /中品灵石/);
  assert.match(fmt(1e13), /极品灵石/);
});
