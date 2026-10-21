/**
 * 妖兽：个头比人大一圈，力气体型大约是寻常甲士的四倍；
 * 但妖兽靠血脉，境界越高涨得越慢；人修靠功法、法宝、丹药，越往后拉得越开。
 */
export const BEAST_VERSION = 'beast-0.1.0';
export const HUMAN_HEIGHT = 1.72;                 // 米

export const REALM_STEPS = ['凡人', '炼气', '筑基', '金丹', '元婴', '化神'];

export const BEASTS = [
  { id: 'wolf',    name: '青鬃狼', size: 2.1, tier: 0, base: 4.0, speed: 11.0, note: '成群，专咬落单的' },
  { id: 'boar',    name: '铁背豕', size: 2.8, tier: 0, base: 4.4, speed: 8.0,  note: '皮糙肉厚，冲起来不拐弯' },
  { id: 'ape',     name: '白毛猿', size: 3.1, tier: 1, base: 6.0, speed: 9.5,  note: '会扔石头，也懂围人' },
  { id: 'serpent', name: '赤鳞蟒', size: 3.6, tier: 2, base: 9.0, speed: 7.0,  note: '一口能吞下整匹马' },
  { id: 'tiger',   name: '山君',   size: 4.2, tier: 3, base: 13.0, speed: 12.0, note: '山中称王，寻常修士不敢单独招惹' },
];

export function beastById(id) { return BEASTS.find(b => b.id === id) || null; }
export function beastByName(name) { return BEASTS.find(b => b.name === name || (name || '').includes(b.name)) || null; }

/** 妖兽随境界的增长：1.32^tier，越往上越慢 */
export function beastGrowth(tier = 0) { return Math.pow(1.32, tier); }

/** 人修随境界的增长：2.2^tier，越往上越快 */
export function cultivatorGrowth(realm = 0) { return Math.pow(2.2, realm); }

/** 一头妖兽对「寻常甲士」的战力（甲士 = 1.0） */
export function beastScore(id, realm = 0) {
  const b = beastById(id);
  if (!b) return 0;
  return +(b.base * beastGrowth(realm)).toFixed(2);
}

/** 一名人修对「寻常甲士」的战力 */
export function cultivatorScore(realm = 0) {
  return +cultivatorGrowth(realm).toFixed(2);
}

/** 同一境界下，妖兽 / 人修 的战力比；>1 妖兽强，<1 人修强 */
export function versusAt(realm = 0) {
  const beast = beastScore('wolf', realm);
  const man = cultivatorScore(realm);
  return { realm: REALM_STEPS[realm] || `第${realm}境`, beast, man, ratio: +(beast / man).toFixed(2) };
}

/** 渲染用：相对人高（人 = 1） */
export function sizeRatio(id) {
  const b = beastById(id);
  return b ? +(b.size / HUMAN_HEIGHT).toFixed(2) : 1;
}

/** 招式：境界越高，能用的招式越多、越狠 */
export const MOVES = {
  wolf:   [{id:'rend',name:'裂风爪',realm:3,mult:2.0,area:1},{id:'bite',name:'撕咬',realm:0,mult:1.0,area:0},{id:'pounce',name:'扑击',realm:1,mult:1.5,area:1},{id:'howl',name:'狼嚎',realm:2,mult:0.6,area:4,fear:true}],
  boar:   [{id:'ruin',name:'山崩撞',realm:3,mult:2.2,area:2},{id:'charge',name:'冲撞',realm:0,mult:1.1,area:0},{id:'tusk',name:'獠牙挑',realm:1,mult:1.6,area:0},{id:'quake',name:'践地',realm:2,mult:0.9,area:3}],
  ape:    [{id:'hurl',name:'掷峰',realm:3,mult:2.1,area:2},{id:'fist',name:'双拳砸',realm:0,mult:1.1,area:0},{id:'throw',name:'掷石',realm:1,mult:1.2,area:1},{id:'roar',name:'猿啸',realm:2,mult:0.7,area:4,fear:true}],
  serpent:[{id:'wrap',name:'缠绕',realm:0,mult:1.2,area:0},{id:'venom',name:'毒息',realm:1,mult:1.0,area:2},{id:'swallow',name:'吞咬',realm:3,mult:2.4,area:0}],
  tiger:  [{id:'claw',name:'扑剪',realm:0,mult:1.2,area:0},{id:'tailsweep',name:'尾扫',realm:1,mult:0.9,area:2},{id:'roar',name:'虎啸',realm:2,mult:0.8,area:4,fear:true},{id:'king',name:'山君临世',realm:3,mult:2.2,area:3}],
};

/** 体型随境界变大：每境 +18%，凡兽 2.1 米，妖王能到三米多 */
export function sizeAt(id, realm = 0) {
  const b = beastById(id);
  if (!b) return 0;
  return +(b.size * Math.pow(1.18, realm)).toFixed(2);
}

/** 境界越高解锁越多招式 */
export function movesAt(id, realm = 0) {
  return (MOVES[id] || []).filter(m => m.realm <= realm).sort((a, b) => a.realm - b.realm || a.mult - b.mult);
}

/** 一场战斗里它最狠的那一招 */
export function bestMove(id, realm = 0) {
  const list = movesAt(id, realm);
  if (!list.length) return null;
  // 取境界最高、威力最大的那一招
  return list.slice().sort((a, b) => b.realm - a.realm || b.mult - a.mult)[0];
}

/** 某境界下的完整妖兽：体型、血、伤、招式都在这里 */
export function beastAt(id, realm = 0) {
  const b = beastById(id);
  if (!b) return null;
  const f = asFighter(id);
  const move = bestMove(id, realm);
  const mult = move ? move.mult : 1;
  return {
    ...f,
    id: b.id, name: b.name,
    size: +(sizeAt(id, realm) / HUMAN_HEIGHT).toFixed(2),
    meters: sizeAt(id, realm),
    hp: Math.round(f.hp * Math.pow(1.45, realm)),
    dmg: Math.round(f.dmg * Math.pow(1.5, realm) * (0.85 + mult * 0.15)),
    move,
    moves: movesAt(id, realm),
    realm,
  };
}

/** 给战斗用的属性：血、伤害都是甲士的四倍上下 */
export const SOLDIER_REF = { hp: 100, dmg: 11 };
export function asFighter(id) {
  const b = beastById(id);
  if (!b) return null;
  return {
    id: b.id, name: b.name, size: sizeRatio(id),
    hp: Math.round(SOLDIER_REF.hp * b.base),
    dmg: Math.round(SOLDIER_REF.dmg * b.base * 0.85),
    speed: b.speed,
  };
}
