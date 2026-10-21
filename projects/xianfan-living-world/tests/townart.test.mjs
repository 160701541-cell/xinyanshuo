import test from 'node:test';
import assert from 'node:assert/strict';
import {paintTown, gx, gy, CELL, EXTENT, PAL, TOWNART_VERSION} from '../content/townart.mjs';
import {layoutTown, streetsFor} from '../buildings.mjs';
import {STRUCTURES, STREAMS, CITY} from '../overworld.mjs';

const town = layoutTown('linan', STRUCTURES);
const streets = streetsFor(STRUCTURES);
const build = () => paintTown(town, {streets, streams: STREAMS, walls: {half: 750}, gates: CITY.gates});

test('像素城与卡牌同一套配方：固定版本与格宽', () => {
  assert.match(TOWNART_VERSION, /^townart-\d+\.\d+\.\d+$/);
  assert.equal(CELL, 4, '4 米一格');
  assert.equal(EXTENT, 840);
});

test('同一份郡县布局烘焙两次结果完全一致', () => {
  const a = build(), b = build();
  assert.equal(a.c.length, b.c.length);
  let diff = 0;
  for (let i = 0; i < a.c.length; i++) if (a.c[i] !== b.c[i]) diff++;
  assert.equal(diff, 0);
});

test('城墙、街道、屋顶都真的画在地图上', () => {
  const g = build();
  const mid = Math.round((2 * EXTENT) / CELL / 2);
  const half = Math.round(750 / CELL);
  assert.ok([PAL.cityWall, PAL.cityWallTop].includes(g.get(mid - half, mid - half)), '西北角应是城墙');
  assert.equal(g.get(mid, mid - half), PAL.cityWallTop, '城墙上应有垛口');
  // 南北大街中轴应有一条街面（允许被城门/院落打断，取 -400 米处）
  const road = g.get(gx(0), gy(-400));
  assert.ok([PAL.street, PAL.streetEdge, PAL.rut].includes(road), `街面没画出来：${road}`);
  const roofs = g.c.filter(c => [PAL.roofTile, PAL.thatch].includes(c)).length;
  assert.ok(roofs > 200, `屋顶太少：${roofs}`);
});

test('城外是田与草，不是城市路面', () => {
  const g = build();
  const far = g.c.slice(0, 2000);
  assert.ok(far.some(c => PAL.field.includes(c) || PAL.grass.includes(c)));
  assert.ok(!far.every(c => c === PAL.street));
});

test('院门/街树/水塘这些细节没有把格子写成 undefined', () => {
  const g = build();
  const bad = g.c.filter(c => typeof c !== 'string' || !c.startsWith('#')).length;
  assert.equal(bad, 0);
});

test('田园配色互不重复，避免整片糊成一个色', () => {
  assert.equal(new Set(PAL.grass).size, PAL.grass.length);
  assert.equal(new Set(PAL.field).size, PAL.field.length);
});
