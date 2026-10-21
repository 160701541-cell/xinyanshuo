/**
 * 妖兽身上的东西：尸体本身就是原料（皮、骨、肉、筋），
 * 往上才有妖丹、精血、兽卵与幼崽；境界越高，件数与品级越好。
 */
export const LOOT_VERSION = 'loot-0.1.0';

/** 材料：价（银/件）、重（斤）、用途 */
export const MATERIALS = {
  hide:   { name: '兽皮',   price: 6,   weight: 8,  use: '制甲、缝靴' },
  bone:   { name: '兽骨',   price: 3,   weight: 6,  use: '熬胶、制器' },
  meat:   { name: '兽肉',   price: 2,   weight: 12, use: '食用、腌制' },
  sinew:  { name: '兽筋',   price: 9,   weight: 1,  use: '弓弦、甲绦' },
  fang:   { name: '獠牙',   price: 12,  weight: 1,  use: '匕首、饰物' },
  scale:  { name: '鳞甲',   price: 15,  weight: 5,  use: '软甲、盾面' },
  gall:   { name: '蛇胆',   price: 22,  weight: 1,  use: '药引' },
  core:   { name: '妖丹',   price: 120, weight: 1,  use: '炼丹、布阵' },
  blood:  { name: '精血',   price: 60,  weight: 1,  use: '淬体、画符' },
  egg:    { name: '兽卵',   price: 260, weight: 3,  use: '孵化、驯养' },
  cub:    { name: '幼崽',   price: 480, weight: 10, use: '驯养、贩卖' },
};

/** 每个物种身上固定能出的东西 */
export const BODY_PARTS = {
  wolf:    ['hide', 'bone', 'meat', 'sinew', 'fang'],
  boar:    ['hide', 'bone', 'meat', 'fang'],
  ape:     ['hide', 'bone', 'meat'],
  serpent: ['scale', 'bone', 'meat', 'gall'],
  tiger:   ['hide', 'bone', 'meat', 'sinew', 'fang'],
};

export const CORE_QUALITY = ['下品', '中品', '上品', '极品'];
const REALM_NAME = ['凡兽', '妖兵', '妖将', '妖王'];

function hash2(a, b) {
  let h = Math.imul(a | 0, 374761393) ^ Math.imul(b | 0, 668265263);
  h = Math.imul(h ^ (h >>> 13), 1274126177);
  return ((h ^ (h >>> 16)) >>> 0) / 4294967296;
}

/**
 * 一头妖兽能掉什么。
 * 尸体材料一定出（件数随体型/境界），妖丹看境界与运气，精血 ≥ 妖兵，
 * 卵与幼崽只在妖将以上、且概率很低——这是稀有产出，不是批发。
 */
export function lootFor(beastId, realm = 0, { seed = 'loot', luck = 0 } = {}) {
  // 先把种子串揉成整数，避免不同种子撞出同一组随机数
  let base = 0;
  for (let i = 0; i < seed.length; i++) base = (Math.imul(base, 131) + seed.charCodeAt(i)) | 0;
  const r = (i) => hash2(base ^ Math.imul(i + 1, 2654435761), (realm + 1) * 101 + i * 17) + luck;
  const out = [];
  const parts = BODY_PARTS[beastId] || ['hide', 'bone'];
  const bulk = 1 + realm * 0.6;
  for (const id of parts) {
    const n = id === 'meat' ? Math.max(1, Math.round(bulk * 2)) : Math.max(1, Math.round(bulk));
    out.push({ id, ...MATERIALS[id], count: n });
  }
  // 妖丹：凡兽 6%，妖兵 18%，妖将 40%，妖王 65%；品级也跟着抬
  const coreChance = [0.06, 0.18, 0.40, 0.65][Math.min(3, realm)] || 0.06;
  if (r(1) < coreChance) {
    const q = Math.min(3, Math.floor(r(2) * (1.4 + realm * 0.9)));
    out.push({ id: 'core', ...MATERIALS.core, count: 1, quality: CORE_QUALITY[q], price: MATERIALS.core.price * (1 + q * 1.6) });
  }
  // 精血：妖兵起才有
  if (realm >= 1 && r(3) < 0.25 + realm * 0.15) {
    out.push({ id: 'blood', ...MATERIALS.blood, count: 1 + (realm >= 3 ? 1 : 0) });
  }
  // 卵 / 幼崽：妖将以上，且幼崽更稀有
  if (realm >= 2 && r(4) < 0.12 + realm * 0.05) {
    out.push({ id: 'egg', ...MATERIALS.egg, count: 1 });
  }
  if (realm >= 3 && r(5) < 0.14) {
    out.push({ id: 'cub', ...MATERIALS.cub, count: 1 });
  }
  return out;
}

/** 总价值（银）与总重量（斤） */
export function lootWorth(list) {
  return list.reduce((s, x) => s + x.price * x.count, 0);
}
export function lootWeight(list) {
  return list.reduce((s, x) => s + x.weight * x.count, 0);
}

/** 一句话战利品描述，给战报用 */
export function lootLine(list) {
  return list.map(x => `${x.name}${x.quality ? `(${x.quality})` : ''}×${x.count}`).join('、');
}
