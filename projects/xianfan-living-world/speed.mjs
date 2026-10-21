// 移速完整公式：所有加成都是乘区，最终写清每一项的来处
export const SPEED_VERSION = 'speed-0.1.0';

export const BASE_SPEED = 1.35;          // 米/秒，凡人空手
export const BAG_SLOTS = 24;             // 行囊格数（一件一格）

/** 各来源的倍率；未拥有的给 0 加成，不参与乘法 */
export function speedTerms(w) {
  const p = w.player || {};
  const bag = p.bag || {};
  const slots = Object.values(bag).reduce((n, c) => n + c, 0);
  const cap = BAG_SLOTS + (p.bagBonus || 0);
  const over = Math.max(0, slots - cap);

  const realmLevel = p.realmLevel || 0;
  const boots = p.gear && p.gear.boots ? p.gear.boots : 0;      // 靴子百分比
  const wings = p.wings ? 1.9 : 1;                              // 风雷翅
  const talisman = p.buffs && p.buffs.godspeed > 0 ? 1.25 : 1;   // 神行符
  const mount = p.mount ? 1.4 : 1;                               // 坐骑
  const vehicle = p.vehicle === 'sword' ? 2.4 : p.vehicle === 'boat' ? 2.0 : 1;
  const martial = p.martial ? 1 + p.martial : 1;                 // 轻功/身法
  const road = p.onRoad ? 1.6 : 1;
  const load = over > 0 ? 1 / (1 + 0.2 * over) : 1;              // 超格才罚

  return [
    {id: 'base', name: '脚力', mul: 1, note: `${BASE_SPEED} 米/秒`},
    {id: 'realm', name: '境界', mul: +(1 + realmLevel * 0.05).toFixed(3), note: realmLevel ? `筑基以上肉身轻` : '凡人'},
    {id: 'boots', name: '靴子', mul: +(1 + boots).toFixed(3), note: boots ? `+${Math.round(boots * 100)}%` : '没有'},
    {id: 'wings', name: '风雷翅', mul: wings, note: wings > 1 ? '双翅展开' : '无'},
    {id: 'talisman', name: '神行符', mul: talisman, note: talisman > 1 ? '符力未散' : '无'},
    {id: 'mount', name: '坐骑', mul: mount, note: mount > 1 ? '马' : '步行'},
    {id: 'vehicle', name: '载具', mul: vehicle, note: p.vehicle === 'sword' ? '御飞剑' : p.vehicle === 'boat' ? '飞舟' : '无'},
    {id: 'martial', name: '轻功', mul: +martial.toFixed(3), note: p.martial ? `身法 +${Math.round(p.martial * 100)}%` : '不会'},
    {id: 'road', name: '官道', mul: road, note: road > 1 ? '走在官道上' : '野地'},
    {id: 'load', name: '负重', mul: +load.toFixed(3), note: over > 0 ? `超 ${over} 格` : `${slots}/${cap} 格`},
  ];
}

export function speedOf(w) {
  const terms = speedTerms(w);
  const mul = terms.reduce((m, t) => m * t.mul, 1);
  return {speed: +(BASE_SPEED * mul).toFixed(2), mul: +mul.toFixed(3), terms};
}

export function speedReport(w) {
  const r = speedOf(w);
  const lines = r.terms.filter(t => t.mul !== 1).map(t => `${t.name} ×${t.mul}`);
  return `${r.speed} 米/秒（${r.mul}×）${lines.length ? '：' + lines.join(' · ') : ''}`;
}

/** 行囊：一件一格，满了就装不下 */
export function bagSlots(w) {
  const bag = (w.player && w.player.bag) || {};
  const slots = Object.values(bag).reduce((n, c) => n + c, 0);
  const cap = BAG_SLOTS + ((w.player && w.player.bagBonus) || 0);
  return {slots, cap, full: slots >= cap};
}

export function addToBag(w, id, n = 1) {
  w.player.bag = w.player.bag || {};
  const b = bagSlots(w);
  if (b.slots + n > b.cap) return {ok: false, reason: `行囊只剩 ${b.cap - b.slots} 格`, bag: b};
  w.player.bag[id] = (w.player.bag[id] || 0) + n;
  return {ok: true, bag: bagSlots(w)};
}

/** 一键整理：按 id 归类、同 id 合并，件数降序 */
export function tidyBag(w) {
  const bag = (w.player && w.player.bag) || {};
  const merged = {};
  for (const [k, v] of Object.entries(bag)) {
    const id = k.split('|')[0];
    merged[id] = (merged[id] || 0) + v;
  }
  w.player.bag = Object.fromEntries(Object.entries(merged).filter(([, v]) => v > 0).sort((a, b) => b[1] - a[1]));
  return w.player.bag;
}
