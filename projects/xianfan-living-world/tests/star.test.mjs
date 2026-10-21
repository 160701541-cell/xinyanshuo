import test from 'node:test';
import assert from 'node:assert/strict';
import {createWorld} from '../core.mjs';
import {
  PLANET, DOMAINS, VOID_REALM, canVoidTravel, buildShip, travelTo, travelCost,
  starReport, ensureStar,
} from '../stardomains.mjs';

test('世界是一颗和太阳同量级的星球', () => {
  assert.ok(PLANET.radiusKm >= 600000, '半径应当接近太阳');
  assert.ok(PLANET.circumferenceKm > 4000000, '周长四百万公里以上');
});

test('凡人过不去虚空，化神可以，星舰也可以', () => {
  const w = createWorld('void');
  assert.equal(canVoidTravel(w).ok, false);
  w.player.realmLevel = VOID_REALM;
  assert.equal(canVoidTravel(w).ok, true);
  assert.equal(canVoidTravel(w).how, '横渡');

  const m = createWorld('ship');
  m.player.realmLevel = 0;
  m.player.stones = 2000; m.player.silver = 3000000;
  assert.equal(canVoidTravel(m).ok, false);
  assert.equal(buildShip(m, {stones: 900, silver: 2000000}).ok, true);
  assert.equal(canVoidTravel(m).ok, true);
  assert.equal(canVoidTravel(m).how, '星舰');
});

test('越远的星域越贵、越耗年岁', () => {
  const w = createWorld('cost');
  w.player.realmLevel = VOID_REALM;
  w.player.stones = 5000;
  const near = travelCost(w, 'taiXu');
  const far = travelCost(w, 'wuJin');
  assert.ok(near.ok && far.ok);
  assert.ok(far.stones > near.stones, '远的更贵');
  assert.ok(far.years > near.years, '远的更久');
});

test('横渡成功会记录去过的地方，并推进世界时间', () => {
  const w = createWorld('go');
  w.player.realmLevel = VOID_REALM;
  w.player.stones = 8000;
  const before = w.day;
  const r = travelTo(w, 'taiXu');
  assert.equal(r.ok, true);
  assert.ok(ensureStar(w).visited.includes('taiXu'));
  assert.ok(w.day > before);
});

test('灵石不够就过不去', () => {
  const w = createWorld('poor');
  w.player.realmLevel = VOID_REALM;
  w.player.stones = 1;
  const r = travelTo(w, 'kunLun');
  assert.equal(r.ok, false);
  assert.match(r.reason, /灵石不够/);
});

test('星域清单一共六域，含本域与五处外域', () => {
  const w = createWorld('list');
  const rep = starReport(w);
  assert.equal(rep.domains.length, 6);
  assert.equal(rep.domains.filter(d => d.home).length, 1);
  assert.equal(rep.realm, '凡人');
  assert.ok(DOMAINS.length >= 6);
});
