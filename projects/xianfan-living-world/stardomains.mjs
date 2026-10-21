/**
 * 星域：这个“世界”不是一块大陆，而是一颗和太阳差不多大的星球；
 * 星球之外还有别的星域，凡人过不去——要么化神以上自己横渡，要么造星舰。
 */
import {note} from './core.mjs';

export const STAR_VERSION = 'star-0.1.0';

/** 玄黄星：以太阳为参照的尺度 */
export const PLANET = {
  name: '玄黄',
  radiusKm: 696340,                 // 太阳半径
  circumferenceKm: Math.round(2 * Math.PI * 696340),
  surfaceKm2: Math.round(4 * Math.PI * 696340 * 696340),
  note: '一颗与太阳同量级的星球，临安县只是它表面的一粒尘。',
};

/** 星域：距离单位用万公里；跨星域靠虚空横渡，不靠走 */
export const DOMAINS = [
  {id:'xuanhuang', name:'玄黄星域', home:true, distWkm:0, qi:1.0, danger:0,
   note:'本域。灵气自星核涌出，修仙界与凡俗王朝共处一颗星。'},
  {id:'taiXu', name:'太虚星域', distWkm:1.42e9, qi:1.35, danger:0.18,
   note:'虚空最薄的一域，化神修士常在此试渡；星舰航线也在这里汇。'},
  {id:'chiXiao', name:'赤霄星域', distWkm:2.6e9, qi:0.9, danger:0.42,
   note:'恒星近邻，火灵之气暴烈，妖王成群，凡人舰队不敢深入。'},
  {id:'youDu', name:'幽都星域', distWkm:4.1e9, qi:0.7, danger:0.66,
   note:'光到不了的地方，魔道大宗盘踞；没有星舰只有死路。'},
  {id:'kunLun', name:'昆仑星域', distWkm:7.8e9, qi:1.6, danger:0.3,
   note:'古仙遗迹最多的一域，灵气浓到凝液，也最容易招来劫修。'},
  {id:'wuJin', name:'无尽星域', distWkm:1.6e10, qi:0.4, danger:0.85,
   note:'没有星图的地方，据说有比化神更高的东西在游。'},
];

/** 横渡所需：境界门槛（化神=第 4 阶以上）或一艘星舰 */
export const VOID_REALM = 5;                 // 0凡人 1炼气 2筑基 3金丹 4元婴 5化神：只有化神能肉身横渡
export const SHIP_COST = {stones: 900, silver: 2000000, years: 3};
export const VOID_COST = {perWkm: 1 / 4e7, minStones: 20}; // 每 4000 万公里耗 1 块灵石

export function ensureStar(w) {
  if (w.star) return w.star;
  w.star = {
    planet: PLANET,
    visited: ['xuanhuang'],
    ship: null,          // {built:true, name:'...', at:'xuanhuang'}
    log: [],
  };
  return w.star;
}

/** 化神以上：自己横渡；否则要有星舰 */
export function canVoidTravel(w) {
  ensureStar(w);
  const realm = realmLevel(w);
  if (realm >= VOID_REALM) return {ok: true, how: '横渡', reason: '境界足够，肉身过虚空'};
  if (w.star.ship && w.star.ship.built) return {ok: true, how: '星舰', reason: '乘星舰走航线'};
  return {ok: false, how: null,
    reason: `要去别的星域，要么元婴化神以上（你如今 ${realmName(realm)}），要么先造一艘星舰`};
}

/** 境界换算：本项目把 5 标为化神；没有修行档案时按凡人算 */
export function realmLevel(w) {
  if (typeof w.player?.realmLevel === 'number') return w.player.realmLevel;
  const p = w.practice;
  if (p && typeof p.layer === 'number') {
    if (p.realm === 'foundation') return 2;
    if (p.realm === 'core') return 3;
    if (p.realm === 'nascent') return 4;
    return 1;
  }
  return 0;
}

export function realmName(level) {
  return ['凡人', '炼气', '筑基', '金丹', '元婴', '化神'][Math.max(0, Math.min(5, level))];
}

export function travelCost(w, id) {
  const d = DOMAINS.find(x => x.id === id);
  if (!d || d.home) return {ok: false, reason: '你已经在玄黄了'};
  const gate = canVoidTravel(w);
  if (!gate.ok) return {ok: false, reason: gate.reason};
  const stones = Math.max(VOID_COST.minStones, Math.round(d.distWkm * VOID_COST.perWkm));
  const years = Math.max(1, Math.round(d.distWkm / 1.2e9));
  return {ok: true, how: gate.how, stones, years, domain: d, distanceKm: d.distWkm * 10000};
}

/** 横渡：消耗灵石与年岁，失败则折在虚空里 */
export function travelTo(w, id) {
  const c = travelCost(w, id);
  if (!c.ok) return c;
  const stones = w.player.stones || 0;
  const ship = c.how === '星舰';
  const need = ship ? Math.round(c.stones * 0.35) : c.stones;
  if (stones < need) return {ok: false, reason: `灵石不够：需 ${need} 块，你有 ${stones} 块`};
  w.player.stones = stones - need;
  const risk = c.domain.danger * (ship ? 0.55 : 1);
  const roll = mulberry(`${w.seed}:void:${id}:${w.day}`)();
  if (roll < risk * 0.35) {
    w.player.hp = Math.max(1, (w.player.hp || 100) - 60);
    return {ok: false, reason: `虚空遇劫，退回玄黄：${c.domain.name}看着凶险`, died: false};
  }
  ensureStar(w);
  if (!w.star.visited.includes(id)) w.star.visited.push(id);
  if (w.star.ship) w.star.ship.at = id;
  w.day += c.years * 360;
  note(w, '星域', `${c.how}渡虚空，${c.years} 年后抵达${c.domain.name}。`);
  return {ok: true, how: c.how, years: c.years, stones: need, domain: c.domain};
}

/** 造星舰：凡人也能去别的星域的唯一办法 */
export function buildShip(w, {stones = 0, silver = 0} = {}) {
  ensureStar(w);
  if (w.star.ship && w.star.ship.built) return {ok: false, reason: '已经有一艘了'};
  const have = (w.player.stones || 0), haveSilver = (w.player.silver || 0);
  if (stones < SHIP_COST.stones || silver < SHIP_COST.silver)
    return {ok: false, reason: `星舰要 ${SHIP_COST.stones} 块灵石与 ${SHIP_COST.silver} 银，分期慢慢来`};
  if (have < stones || haveSilver < silver) return {ok: false, reason: '家底不够付首付'};
  w.player.stones = have - stones;
  w.player.silver = haveSilver - silver;
  w.star.ship = {built: true, name: '玄黄一号', at: 'xuanhuang', years: SHIP_COST.years};
  note(w, '星域', '星舰「玄黄一号」下水。凡人也能过虚空了。');
  return {ok: true, ship: w.star.ship};
}

export function starReport(w) {
  ensureStar(w);
  const gate = canVoidTravel(w);
  return {
    planet: PLANET,
    gate,
    realm: realmName(realmLevel(w)),
    ship: w.star.ship,
    visited: w.star.visited,
    domains: DOMAINS.map(d => ({...d, cost: d.home ? null : travelCost(w, d.id)})),
  };
}

function mulberry(str) {
  let a = 2166136261;
  for (let i = 0; i < str.length; i++) { a ^= str.charCodeAt(i); a = Math.imul(a, 16777619); }
  return function () { a |= 0; a = a + 0x6D2B79F5 | 0; let t = Math.imul(a ^ a >>> 15, 1 | a); t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t; return ((t ^ t >>> 14) >>> 0) / 4294967296; };
}
