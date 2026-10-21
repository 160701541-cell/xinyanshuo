/**
 * 建造 / 采集 / 合成树 / 科技树 / 兵种树 / 功法树 / 锻造。
 * 开局先砍十根木头、捡五十捆稻草，才有资格谈“盖房子”。
 */
import {note, advanceClock, getPlace} from './core.mjs';

export const BUILD_VERSION = 'build-0.1.0';

export const RES = {
  wood: {name: '木头', icon: '木'},
  straw: {name: '稻草', icon: '草'},
  stone: {name: '石头', icon: '石'},
  clay: {name: '黏土', icon: '土'},
  iron: {name: '生铁', icon: '铁'},
  hemp: {name: '麻', icon: '麻'},
  hide: {name: '兽皮', icon: '皮'},
};

export function ensureBuild(w) {
  if (!w.build) w.build = {res: {wood: 0, straw: 0, stone: 0, clay: 0, iron: 0, hemp: 0, hide: 0}, tech: {}, built: {}, log: []};
  for (const k of Object.keys(RES)) if (w.build.res[k] == null) w.build.res[k] = 0;
  return w.build;
}

export function resOf(w) { return ensureBuild(w).res; }

/* ── 采集：砍树、割草、采石、偷草、帮工换宿 ─────────────── */
export const GATHER = {
  wood: {name: '伐木', hours: 1.5, gain: 3, stamina: 8, need: '城外林地'},
  straw: {name: '割草', hours: 0.75, gain: 5, stamina: 5, need: '田间地头'},
  stone: {name: '采石', hours: 2, gain: 2, stamina: 12, need: '河滩'},
  clay: {name: '挖土', hours: 1.5, gain: 3, stamina: 10, need: '河边'},
};

export function gather(w, kind = 'wood') {
  const b = ensureBuild(w);
  const g = GATHER[kind];
  if (!g) return {ok: false, reason: '不会这门手艺'};
  const st = w.player.stats || (w.player.stats = {hp: 100, stamina: 100});
  if ((st.stamina ?? 100) < g.stamina) return {ok: false, reason: '体力不够，先歇'};
  st.stamina -= g.stamina;
  b.res[kind] += g.gain;
  advanceClock(w, g.hours * 60);
  return {ok: true, kind, gain: g.gain, total: b.res[kind]};
}

/** 偷草：来钱快，被抓要罚 */
export function stealStraw(w, seed = Math.random()) {
  const b = ensureBuild(w);
  if (seed < 0.4) {
    const fine = 20;
    w.player.silver = Math.max(0, (w.player.silver || 0) - fine);
    w.player.karma = (w.player.karma || 0) + 2;
    note(w, '建造', '偷草被田主抓住，罚了 20 银');
    return {ok: false, caught: true, reason: `被田主逮住，罚 ${fine} 银，业力 +2`};
  }
  b.res.straw += 12;
  advanceClock(w, 45);
  return {ok: true, gain: 12, total: b.res.straw};
}

/** 帮村长干活换一顿饭与一晚住宿：不留钱，但管饱、还能捎带几捆草 */
export function helpElder(w) {
  const b = ensureBuild(w);
  const st = w.player.stats || (w.player.stats = {hp: 100, stamina: 100});
  st.hp = Math.min(100, (st.hp ?? 100) + 30);
  st.stamina = Math.min(100, (st.stamina ?? 100) + 60);
  b.res.straw += 8;
  advanceClock(w, 6 * 60);
  note(w, '建造', '在村长家干了一天活，管饭管住，捎回 8 捆稻草');
  return {ok: true, straw: b.res.straw, stamina: Math.round(st.stamina), paid: 0};
}

/* ── 合成树 ─────────────────────────────────────────── */
export const RECIPES = [
  {id: 'rope', name: '草绳', in: {straw: 6}, out: {res: 'hemp', n: 2}, hours: 1},
  {id: 'plank', name: '木板', in: {wood: 3}, out: {res: 'plank', n: 2}, hours: 1.5},
  {id: 'brick', name: '土坯', in: {clay: 4, straw: 2}, out: {res: 'brick', n: 3}, hours: 2},
  {id: 'hut', name: '茅屋', in: {wood: 10, straw: 50}, out: {building: 'hut'}, hours: 6},
  {id: 'shed', name: '柴棚', in: {wood: 6, straw: 10}, out: {building: 'shed'}, hours: 3},
  {id: 'workbench', name: '工作台', in: {wood: 12, stone: 4}, out: {building: 'workbench'}, hours: 4, tech: 'craft:1'},
  {id: 'forge', name: '铁匠炉', in: {stone: 20, clay: 10, wood: 8}, out: {building: 'forge'}, hours: 8, tech: 'arms:1'},
  {id: 'field', name: '开一块田', in: {wood: 4, straw: 6}, out: {building: 'field'}, hours: 5, tech: 'farm:1'},
  {id: 'yard', name: '院墙', in: {stone: 30, wood: 10}, out: {building: 'yard'}, hours: 10, tech: 'fort:1'},
];

const EXTRA = ['plank', 'brick'];
export function resName(k) { return RES[k]?.name || ({plank: '木板', brick: '土坯'}[k] || k); }
export function resCount(w, k) {
  const b = ensureBuild(w);
  if (EXTRA.includes(k)) return b.built['_' + k] || 0;
  return b.res[k] || 0;
}
function addRes(w, k, n) {
  const b = ensureBuild(w);
  if (EXTRA.includes(k)) b.built['_' + k] = (b.built['_' + k] || 0) + n;
  else b.res[k] = (b.res[k] || 0) + n;
}

export function canCraft(w, id) {
  const r = RECIPES.find(x => x.id === id);
  if (!r) return {ok: false, reason: '没有这张图纸'};
  const have = w.build || ensureBuild(w);
  if (r.tech) {
    const [line, lv] = r.tech.split(':');
    if ((have.tech[line] || 0) < Number(lv)) return {ok: false, reason: `需要${TECH[line].name} ${lv} 级`};
  }
  const miss = Object.entries(r.in).filter(([k, n]) => resCount(w, k) < n)
    .map(([k, n]) => `${resName(k)} ${n - resCount(w, k)}`);
  if (miss.length) return {ok: false, reason: '还缺：' + miss.join('、')};
  return {ok: true, recipe: r};
}

export function craft(w, id) {
  const gate = canCraft(w, id);
  if (!gate.ok) return gate;
  const r = gate.recipe;
  for (const [k, n] of Object.entries(r.in)) addRes(w, k, -n);
  if (r.out.building) {
    w.build.built[r.out.building] = (w.build.built[r.out.building] || 0) + 1;
    note(w, '建造', `盖成${r.name}`);
  } else {
    addRes(w, r.out.res, r.out.n);
  }
  advanceClock(w, r.hours * 60);
  return {ok: true, name: r.name, out: r.out};
}

/* ── 科技树：国产科技影响产量、解锁配方与兵种 ─────────── */
export const TECH = {
  farm: {name: '农政', max: 5, cost: {silver: 200, straw: 20}, effect: '粮产 +12%/级、可开田'},
  fort: {name: '筑城', max: 5, cost: {silver: 300, stone: 30}, effect: '可修院墙、城墙耐久 +15%/级'},
  arms: {name: '军械', max: 5, cost: {silver: 350, iron: 10}, effect: '解锁兵种与铁器，杀伤 +10%/级'},
  alchemy: {name: '丹道', max: 5, cost: {silver: 400, straw: 10}, effect: '丹药成率 +8%/级'},
  array: {name: '阵法', max: 5, cost: {silver: 500, stone: 20}, effect: '护山阵强度 +20%/级'},
};

export function techLevel(w, line) { return (ensureBuild(w).tech[line] || 0); }

export function research(w, line) {
  const t = TECH[line];
  if (!t) return {ok: false, reason: '没有这条科技线'};
  const b = ensureBuild(w);
  const lv = b.tech[line] || 0;
  if (lv >= t.max) return {ok: false, reason: `${t.name}已到顶`};
  const cost = {};
  for (const [k, v] of Object.entries(t.cost)) cost[k] = Math.round(v * (lv + 1));
  if ((w.player.silver || 0) < (cost.silver || 0)) return {ok: false, reason: `银不够：要 ${cost.silver}`};
  for (const [k, v] of Object.entries(cost)) {
    if (k === 'silver') continue;
    if (resCount(w, k) < v) return {ok: false, reason: `缺${resName(k)} ${v - resCount(w, k)}`};
  }
  w.player.silver -= cost.silver || 0;
  for (const [k, v] of Object.entries(cost)) if (k !== 'silver') addRes(w, k, -v);
  b.tech[line] = lv + 1;
  note(w, '科技', `${t.name}提升到 ${lv + 1} 级`);
  return {ok: true, line, level: lv + 1};
}

/* ── 兵种树 ─────────────────────────────────────────── */
export const UNITS = [
  {id: 'militia', name: '乡勇', arms: 0, cost: {silver: 14}, power: 1.0},
  {id: 'spear', name: '长枪兵', arms: 1, cost: {silver: 40, wood: 4}, power: 1.5},
  {id: 'sword', name: '刀盾兵', arms: 2, cost: {silver: 70, iron: 3}, power: 2.2},
  {id: 'archer', name: '弓手', arms: 2, cost: {silver: 90, wood: 6, hemp: 4}, power: 2.6},
  {id: 'cavalry', name: '轻骑', arms: 4, cost: {silver: 320, iron: 8}, power: 4.2},
];

export function unitsOf(w) { return UNITS.filter(u => techLevel(w, 'arms') >= u.arms); }

export function trainUnit(w, id, n = 1) {
  const u = UNITS.find(x => x.id === id);
  if (!u) return {ok: false, reason: '没有这个兵种'};
  if (techLevel(w, 'arms') < u.arms) return {ok: false, reason: `需要军械 ${u.arms} 级`};
  const need = {};
  for (const [k, v] of Object.entries(u.cost)) need[k] = v * n;
  if ((w.player.silver || 0) < (need.silver || 0)) return {ok: false, reason: `银不够：要 ${need.silver}`};
  for (const [k, v] of Object.entries(need)) if (k !== 'silver' && resCount(w, k) < v) return {ok: false, reason: `缺${resName(k)}`};
  w.player.silver -= need.silver || 0;
  for (const [k, v] of Object.entries(need)) if (k !== 'silver') addRes(w, k, -v);
  w.player.units = w.player.units || {};
  w.player.units[id] = (w.player.units[id] || 0) + n;
  return {ok: true, unit: u, count: w.player.units[id]};
}

/* ── 功法树 ─────────────────────────────────────────── */
export const GONGFA = [
  {id: 'breath', name: '吐纳诀', realm: 0, stones: 0, gain: 1.0},
  {id: 'qi', name: '引气诀', realm: 1, stones: 2, gain: 1.3},
  {id: 'meridian', name: '通脉诀', realm: 1, stones: 6, gain: 1.6},
  {id: 'core', name: '凝元诀', realm: 2, stones: 20, gain: 2.1},
  {id: 'golden', name: '金丹诀', realm: 3, stones: 60, gain: 2.8},
];

export function learnGongfa(w, id) {
  const g = GONGFA.find(x => x.id === id);
  if (!g) return {ok: false, reason: '没有这门功法'};
  const b = ensureBuild(w);
  b.gongfa = b.gongfa || 'breath';
  if (g.id === b.gongfa) return {ok: false, reason: '已经在练了'};
  if ((w.player.realmLevel || 0) < g.realm) return {ok: false, reason: `境界不够（需 ${g.realm} 阶）`};
  if ((w.player.stones || 0) < g.stones) return {ok: false, reason: `要 ${g.stones} 块灵石`};
  w.player.stones -= g.stones;
  b.gongfa = g.id;
  return {ok: true, gongfa: g};
}

/* ── 锻造：武器与防具 ───────────────────────────────── */
export const FORGE = [
  {id: 'spear_i', name: '木枪', kind: 'weapon', grade: 'mortal', in: {wood: 4, hemp: 2}, hours: 2},
  {id: 'sword_i', name: '铁剑', kind: 'weapon', grade: 'low', in: {iron: 4, wood: 1}, hours: 4, tech: 'arms:2'},
  {id: 'bow_i', name: '猎弓', kind: 'weapon', grade: 'low', in: {wood: 6, hemp: 4}, hours: 5, tech: 'arms:2'},
  {id: 'armor_i', name: '皮甲', kind: 'armor', grade: 'low', in: {hide: 6, hemp: 3}, hours: 6, tech: 'arms:1'},
  {id: 'armor_ii', name: '铁札甲', kind: 'armor', grade: 'mid', in: {iron: 12, hide: 4}, hours: 12, tech: 'arms:3'},
];

export function forge(w, id) {
  const f = FORGE.find(x => x.id === id);
  if (!f) return {ok: false, reason: '没有这张图'};
  if (f.tech) {
    const [line, lv] = f.tech.split(':');
    if (techLevel(w, line) < Number(lv)) return {ok: false, reason: `需要${TECH[line].name} ${lv} 级`};
  }
  const miss = Object.entries(f.in).filter(([k, n]) => resCount(w, k) < n).map(([k, n]) => `${resName(k)} ${n - resCount(w, k)}`);
  if (miss.length) return {ok: false, reason: '还缺：' + miss.join('、')};
  for (const [k, n] of Object.entries(f.in)) addRes(w, k, -n);
  w.player.gear = w.player.gear || {};
  w.player.gear[f.kind] = {id: f.id, name: f.name, grade: f.grade};
  advanceClock(w, f.hours * 60);
  note(w, '锻造', `锻出${f.name}（${f.grade}）`);
  return {ok: true, gear: w.player.gear[f.kind]};
}

export function buildReport(w) {
  const b = ensureBuild(w);
  return {
    res: b.res, plank: b.built['_plank'] || 0, brick: b.built['_brick'] || 0,
    built: Object.entries(b.built).filter(([k]) => !k.startsWith('_')).map(([k, v]) => `${k}×${v}`),
    tech: Object.entries(TECH).map(([k, t]) => `${t.name}${b.tech[k] || 0}`).join(' '),
    gongfa: b.gongfa || '吐纳诀',
    gear: w.player.gear || {},
    units: w.player.units || {},
  };
}
