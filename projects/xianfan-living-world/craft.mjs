/**
 * 妖兽材料的去处：皮甲、骨器、丹药、淬体、孵卵、驯崽。
 * 不收银子，收材料——这就是打妖兽的意义。
 */
export const CRAFT_VERSION = 'craft-0.1.0';

export const RECIPES = [
  { id: 'leather', name: '皮甲', cost: { hide: 2, sinew: 1 }, days: 2, make: { item: 'leather-armor', name: '皮甲', price: 90, armor: 4 } },
  { id: 'bonetool', name: '骨器', cost: { bone: 3 }, days: 1, make: { item: 'bone-tool', name: '骨器', price: 45, tool: 1 } },
  { id: 'pill', name: '妖丹丸', cost: { core: 1, herb: 2 }, days: 3, make: { item: 'pill', name: '妖丹丸', price: 320, practice: 60 } },
  { id: 'temp', name: '精血淬体', cost: { blood: 1, meat: 1 }, days: 1, make: { item: 'blood-tonic', name: '淬体液', price: 120, hp: 20 } },
  { id: 'scale', name: '鳞甲片', cost: { scale: 2 }, days: 2, make: { item: 'scale-plate', name: '鳞甲片', price: 160, armor: 7 } },
];

function bag(w) { return (w.player.bag = w.player.bag || []); }
function count(w, id) { return bag(w).filter(x => x.id === id).reduce((s, x) => s + x.count, 0); }
function take(w, id, n) {
  let left = n;
  for (const it of bag(w)) {
    if (it.id !== id || left <= 0) continue;
    const use = Math.min(it.count, left);
    it.count -= use; left -= use;
  }
  w.player.bag = bag(w).filter(x => x.count > 0);
}

export function canCraft(w, id) {
  const r = RECIPES.find(x => x.id === id);
  if (!r) return { ok: false, reason: '没有这个做法' };
  const lack = Object.entries(r.cost).filter(([k, n]) => count(w, k) < n).map(([k]) => k);
  return lack.length ? { ok: false, reason: `缺 ${lack.join('、')}`, lack } : { ok: true, recipe: r };
}

export function craft(w, id) {
  const check = canCraft(w, id);
  if (!check.ok) return check;
  const r = check.recipe;
  for (const [k, n] of Object.entries(r.cost)) take(w, k, n);
  bag(w).push({ id: r.make.item, name: r.make.name, count: 1, price: r.make.price });
  return { ok: true, made: r.make, days: r.days };
}

/** 兽卵：放三天，孵出来就是幼崽（也可能空壳） */
export function hatchEgg(w, seed = 'hatch') {
  const egg = bag(w).find(x => x.id === 'egg');
  if (!egg) return { ok: false, reason: '没有兽卵' };
  take(w, 'egg', 1);
  let h = 0;
  for (const ch of `${seed}${w.day}`) h = (h * 31 + ch.charCodeAt(0)) | 0;
  const lucky = ((h >>> 8) & 255) / 255;
  if (lucky < 0.18) return { ok: true, hatched: false, reason: '壳是空的' };
  bag(w).push({ id: 'cub', name: '幼崽', count: 1, price: 480 });
  return { ok: true, hatched: true, cub: '幼崽' };
}

/** 幼崽：养熟了是灵兽（只认一个主人），养不熟就跑 */
export function tameCub(w, seed = 'tame') {
  const cub = bag(w).find(x => x.id === 'cub');
  if (!cub) return { ok: false, reason: '没有幼崽' };
  take(w, 'cub', 1);
  let h = 0;
  for (const ch of `${seed}${w.day}`) h = (h * 31 + ch.charCodeAt(0)) | 0;
  if (((h >>> 7) & 255) / 255 < 0.35) return { ok: true, tamed: false, reason: '养不熟，跑了' };
  w.beasts = w.beasts || { pets: [] };
  w.beasts.pets.push({ name: '幼兽', grown: 0 });
  return { ok: true, tamed: true };
}
