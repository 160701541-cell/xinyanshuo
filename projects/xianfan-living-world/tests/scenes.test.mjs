import test from 'node:test';
import assert from 'node:assert/strict';


test('天光：日出日落之外没有日光，正午影子最短', async () => {
  const A = await import('../content/atmos.mjs');
  assert.equal(A.sunAt(12).day, true);
  assert.equal(A.sunAt(23).day, false);
  assert.ok(A.sunAt(12).elevation > A.sunAt(7).elevation);
  assert.ok(A.shadowOf(12).len < A.shadowOf(7).len, '正午影子更短');
  assert.equal(A.shadowOf(23).len, 0);
  assert.ok(A.sunAt(6).tint.a > A.sunAt(12).tint.a, '晨昏的暖色更重');
  assert.ok(A.sunAt(6).tint.r - A.sunAt(6).tint.b > A.sunAt(12).tint.r - A.sunAt(12).tint.b, '晨昏偏暖');
});

test('云影会飘，雨随天气变密', async () => {
  const A = await import('../content/atmos.mjs');
  const sum = (t) => {
    let s = 0;
    for (let x = -2000; x <= 2000; x += 200) for (let y = -2000; y <= 2000; y += 200) s += A.cloudShadowAt(x, y, t);
    return s;
  };
  assert.notEqual(sum(0), sum(90000), '云影应当随时间飘动');
  assert.ok(sum(0) > 0, '总得有几块云影，不然就是没有云');
  assert.ok(A.weatherFx('小雨').rain > A.weatherFx('阴').rain);
  assert.equal(A.weatherFx('晴').rain, 0);
  const rain = A.atmosphereOf({ hour: 9, weather: '小雨', seconds: 3000 }).rainDrops;
  assert.ok(rain.length > 50 && rain.length <= 160);
  assert.ok(rain.every(d => d.y >= 0 && d.y <= 1));
});
