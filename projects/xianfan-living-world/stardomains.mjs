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

/** 星域：距离用「光年」。跨星域不是走的路，是横渡虚空——银河到仙女系那种量级 */
export const DOMAINS = [
  {id:'xuanhuang', name:'玄黄星域', home:true, ly:0, qi:1.0, danger:0,
   note:'本域。灵气自星核涌出，修仙界与凡俗王朝共处一颗星。'},
  {id:'taiXu', name:'太虚星域', ly:24000, qi:1.35, danger:0.18,
   note:'本星系臂内侧，化神修士常在此试渡，是最近的邻域。'},
  {id:'chiXiao', name:'赤霄星域', ly:86000, qi:0.9, danger:0.42,
   note:'跨过整条旋臂才到，火灵之气暴烈，妖王成群。'},
  {id:'youDu', name:'幽都星域', ly:1200000, qi:0.7, danger:0.66,
   note:'光要走上百万年，魔道大宗盘踞其间。'},
  {id:'kunLun', name:'昆仑星域', ly:2000000, qi:1.6, danger:0.3,
   note:'古仙遗迹最多的一域，灵气浓到凝液。'},
  {id:'wuJin', name:'无尽星域', ly:2540000, qi:0.4, danger:0.85,
   note:'与仙女座同量级，没有星图，据说有比化神更高的东西在游。'},
];

/** 横渡所需：境界门槛（化神=第 4 阶以上）或一艘星舰 */
export const VOID_REALM = 5;                 // 只有化神以上能横渡虚空；凡人、炼气、元婴都不行
export const VOID_STONES = 100000;           // 十万下品灵石起步，不收银钱
export const VOID_YEARS_PER_LY = 1 / 1200;   // 1200 光年/年：化神也得走上几十年
export const MORTAL_KM_PER_DAY = 30;         // 凡人一生脚程：每日 30 公里
export const MORTAL_YEARS = 60;

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

/** 化神以上：肉身横渡；其余境界连门槛都摸不到 */
export function canVoidTravel(w) {
  ensureStar(w);
  const realm = realmLevel(w);
  if (realm >= VOID_REALM) return {ok: true, how: '横渡', reason: '化神以上，肉身可渡虚空'};
  return {ok: false, how: null,
    reason: `跨星域是银河到仙女座那种距离，${realmName(realm)}连门都摸不到；至少化神以上才谈得上横渡`};
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
  const stones = VOID_STONES + Math.round(d.ly / 40);        // 越远越贵，基数是十万
  const years = Math.max(20, Math.round(d.ly * VOID_YEARS_PER_LY));
  return {ok: true, how: gate.how, stones, years, domain: d, lightYears: d.ly};
}

/** 横渡：消耗灵石与年岁，失败则折在虚空里 */
export function travelTo(w, id) {
  const c = travelCost(w, id);
  if (!c.ok) return c;
  const stones = w.player.stones || 0;
  const need = c.stones;
  if (stones < need) return {ok: false, reason: `下品灵石不够：需 ${need.toLocaleString()} 块，你有 ${stones.toLocaleString()} 块`};
  w.player.stones = stones - need;
  const risk = c.domain.danger;
  const roll = mulberry(`${w.seed}:void:${id}:${w.day}`)();
  if (roll < risk * 0.35) {
    w.player.hp = Math.max(1, (w.player.hp || 100) - 60);
    return {ok: false, reason: `虚空遇劫，退回玄黄：${c.domain.name}看着凶险`, died: false};
  }
  ensureStar(w);
  if (!w.star.visited.includes(id)) w.star.visited.push(id);
  w.day += c.years * 360;
  note(w, '星域', `${c.how}渡虚空，${c.years} 年后抵达${c.domain.name}。`);
  return {ok: true, how: c.how, years: c.years, stones: need, domain: c.domain};
}

/** 星舰：宗门造的渡船，但船上仍要化神押船；凡人有船也开不动虚空 */
export function buildShip(w) {
  ensureStar(w);
  const realm = realmLevel(w);
  if (realm < VOID_REALM) return {ok: false, reason: '星舰没有化神押船，开进虚空就是一口活棺材'};
  if (w.star.ship) return {ok: false, reason: '已经有一艘了'};
  w.star.ship = {built: true, name: '玄黄一号', at: 'xuanhuang'};
  note(w, '星域', '星舰「玄黄一号」下水，由化神押船。');
  return {ok: true, ship: w.star.ship};
}

/** 凡人脚程：一辈子能走多远，这是“走不出这颗星”的硬数字 */
export function mortalRange() {
  const km = MORTAL_KM_PER_DAY * 365 * MORTAL_YEARS;
  return {
    km,
    laps: +(km / PLANET.circumferenceKm).toFixed(3),
    countries: Math.round(km / 800),          // 以八百里见方的小国估
    note: `凡人一生约 ${MORTAL_YEARS} 年、日行 ${MORTAL_KM_PER_DAY} 公里，总计 ${Math.round(km / 1000)} 万公里不到：走不完这颗星，更出不了星域。`,
  };
}

export function starReport(w) {
  ensureStar(w);
  const gate = canVoidTravel(w);
  return {
    planet: PLANET,
    gate,
    mortal: mortalRange(),
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
