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

test('凡人过不去虚空，化神才行；凡人练不出星舰', () => {
  const w = createWorld('void');
  assert.equal(canVoidTravel(w).ok, false);
  assert.match(canVoidTravel(w).reason, /凡人/);
  w.player.realmLevel = VOID_REALM;
  assert.equal(canVoidTravel(w).ok, true);
  assert.equal(canVoidTravel(w).how, '横渡');

  const m = createWorld('ship');
  m.player.realmLevel = 0;
  assert.equal(canVoidTravel(m).ok, false);
  assert.equal(buildShip(m).ok, false, '没有化神押船，星舰不成立');
  m.player.realmLevel = VOID_REALM;
  assert.equal(buildShip(m).ok, true);
});

test('凡人一生绕不过这颗星：脚程远小于周长', () => {
  const w = createWorld('foot');
  const rep = starReport(w);
  assert.ok(rep.mortal.km < PLANET.circumferenceKm, '凡人一辈子走不完一圈');
  assert.ok(rep.mortal.laps < 0.5);
  assert.ok(rep.mortal.countries > 10 && rep.mortal.countries < 2000, '一生能走访几十到上千个八百里小国');
});

test('越远的星域越贵、越耗年岁', () => {
  const w = createWorld('cost');
  w.player.realmLevel = VOID_REALM;
  w.player.stones = 300000;
  const near = travelCost(w, 'taiXu');
  const far = travelCost(w, 'wuJin');
  assert.ok(near.ok && far.ok);
  assert.ok(far.stones > near.stones, '远的更贵');
  assert.ok(far.years > near.years, '远的更久');
});

test('横渡成功会记录去过的地方，并推进世界时间', () => {
  const w = createWorld('go');
  w.player.realmLevel = VOID_REALM;
  w.player.stones = 300000;
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
