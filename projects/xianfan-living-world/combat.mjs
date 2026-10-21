/**
 * 战力：一条公式算到底，界面上不再各处拍脑袋。
 * 战力 = 境界底数 × 层数 × 灵根 × 装备 × 状态 × 道心
 */
import {ROOTS} from './cultivation.mjs';
import {gradeOf} from './content/grades.mjs';

export const COMBAT_VERSION = 'combat-0.1.0';

/** 境界底数：凡人对炼气是 1:6，对化神是 1:1600，后期人类修士越强 */
export const REALM_BASE = {mortal: 10, qi: 60, found: 260, core: 1100, nascent: 4200, spirit: 16000};
export const REALM_ORDER = ['mortal', 'qi', 'found', 'core', 'nascent', 'spirit'];

/** 灵根对吐纳与战力的影响（同一境界下，天灵根约强 45%） */
export const ROOT_POWER = {tian: 1.45, dan: 1.32, shuang: 1.20, san: 1.10, si: 1.03, wu: 1.00, none: 0.55};

export function realmBase(realm) { return REALM_BASE[realm] ?? REALM_BASE.mortal; }

/** 层数：炼气 1–13 层，每层 +6% */
export function layerFactor(layer = 0) { return 1 + Math.max(0, Math.min(13, layer)) * 0.06; }

export function rootPower(rootId) { return ROOT_POWER[rootId] ?? 1; }

/** 装备：武器、护甲、法宝各按品阶乘数叠加，空手为 1 */
export function gearFactor(gear = {}) {
  const w = gear.weapon ? gradeOf(gear.weapon.grade).mult : 0;
  const a = gear.armor ? gradeOf(gear.armor.grade).mult : 0;
  const t = gear.talisman ? gradeOf(gear.talisman.grade).mult : 0;
  return 1 + w * 0.22 + a * 0.12 + t * 0.16;
}

/** 状态：气血、体力、伤势、士气（0–100），合起来最多打到 1.35，最低 0.25 */
export function stateFactor(s = {}) {
  const hp = (s.hp ?? 100) / 100, st = (s.stamina ?? 100) / 100;
  const morale = (s.morale ?? 70) / 100;
  const wound = s.wounded ? 0.75 : 1;
  return Math.max(0.25, Math.min(1.35, (0.45 + 0.35 * hp + 0.2 * st) * (0.8 + 0.3 * morale) * wound));
}

/** 道心：业力高会压战力（心魔），正道声望略加成 */
export function daoFactor(s = {}) {
  const karma = s.karma ?? 0;
  const bias = s.bias ?? 0;
  return Math.max(0.55, Math.min(1.2, 1 - Math.min(120, Math.max(0, karma)) / 400 + Math.max(0, bias) / 500));
}

/**
 * 完整战力。
 * @param {object} s {realm, layer, root, gear:{weapon,armor,talisman}, hp, stamina, morale, wounded, karma, bias, pill}
 */
export function power(s = {}) {
  const base = realmBase(s.realm);
  const parts = {
    base,
    layer: layerFactor(s.layer),
    root: rootPower(s.root),
    gear: gearFactor(s.gear),
    state: stateFactor(s),
    dao: daoFactor(s),
    pill: 1 + Math.min(0.5, (s.pill || 0) * 0.08),
  };
  const total = base * parts.layer * parts.root * parts.gear * parts.state * parts.dao * parts.pill;
  return {total: Math.round(total), parts, breakdown: explain(parts)};
}

export function explain(parts) {
  return [
    ['境界底数', Math.round(parts.base)],
    ['层数', parts.layer.toFixed(2)],
    ['灵根', parts.root.toFixed(2)],
    ['装备', parts.gear.toFixed(2)],
    ['状态', parts.state.toFixed(2)],
    ['道心', parts.dao.toFixed(2)],
    ['丹药', parts.pill.toFixed(2)],
  ];
}

/** 对比：高一个大境界，靠灵根与装备能不能补回来 */
export function compare(a, b) {
  const pa = power(a).total, pb = power(b).total;
  return {a: pa, b: pb, ratio: +(pa / Math.max(1, pb)).toFixed(2), winner: pa >= pb ? 'a' : 'b'};
}

/** 灵根表导出给原生端（同一份数据，不在 Java 里再抄一遍） */
export function rootTable() {
  return Object.entries(ROOTS).map(([id, r]) => ({
    id, name: r.name, p: r.p, speed: r.speed, power: ROOT_POWER[id] ?? 1, note: r.note || '',
  }));
}
