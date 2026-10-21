import test from 'node:test';
import assert from 'node:assert/strict';
import {ITEM_IDS, itemIcon, itemIconId, itemArtSVG, ITEM_VERSION} from '../content/itemart.mjs';

test('十四种物品都有图标，尺寸统一 24 格', () => {
  assert.equal(ITEM_IDS.length, 14);
  for (const id of ITEM_IDS) {
    const icon = itemIcon(id);
    assert.equal(icon.w, 24, `${id} 宽`);
    assert.ok(icon.rows.length >= 14, `${id} 太矮`);
    assert.ok(icon.rows.every(r => r.length <= 24), `${id} 行超宽`);
  }
});

test('中文名能对上图标：妖丹/精血/兽皮/兽骨/朱果/素酒/黄纸', () => {
  assert.equal(itemIconId('妖丹（下品）'), 'core');
  assert.equal(itemIconId('精血'), 'pill');
  assert.equal(itemIconId('妖皮'), 'skin');
  assert.equal(itemIconId('妖骨'), 'bone');
  assert.equal(itemIconId('朱果'), 'herb');
  assert.equal(itemIconId('素酒'), 'water');
  assert.equal(itemIconId('黄纸'), 'talisman');
});

test('认不出的东西不报错，落到干粮图', () => {
  assert.equal(itemIconId('莫名其妙的东西'), 'grain');
  assert.equal(itemIcon('') .rows.length >= 14, true);
});

test('SVG 带调色板与描边，不是空白', () => {
  const svg = itemArtSVG('blade', 96);
  assert.ok(svg.startsWith('<svg'));
  assert.ok(svg.includes('<rect'));
  assert.ok((svg.match(/#[0-9a-f]{6}/g) || []).length > 2);
  assert.equal(ITEM_VERSION, 'itemart-0.2.0');
});
