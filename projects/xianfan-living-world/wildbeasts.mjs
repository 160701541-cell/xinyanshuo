/**
 * 野外的妖兽：巢穴、出没、袭村、讨伐。
 * 它们不在战斗里凭空出现，而是先在地图上有个窝，再出去咬人。
 */
import {BEASTS, beastById, beastAt, sizeAt} from './content/beasts.mjs';
import {lootFor, lootLine, lootWorth} from './content/loot.mjs';

export const WILD_VERSION = 'wild-0.1.0';
export const DEN_COUNT = 9;

function hash(s) {
  let h = 2166136261;
  for (let i = 0; i < s.length; i++) { h ^= s.charCodeAt(i); h = Math.imul(h, 16777619); }
  return (h >>> 0) / 4294967296;
}

const DEN_SPOTS = [
  { name: '松林深处', x: 9200, y: 6100 }, { name: '黑水潭', x: -12400, y: 7600 },
  { name: '断魂谷', x: 15800, y: -4300 }, { name: '青云后山', x: 10800, y: -6900 },
  { name: '蛇盘岭', x: -7600, y: -9200 }, { name: '铁背洞', x: 4300, y: 11200 },
  { name: '白毛崖', x: -15200, y: -3100 }, { name: '赤鳞涧', x: 18200, y: 8800 },
  { name: '王巢', x: 21200, y: -12000 },
];

/** 妖兽巢穴：位置固定、种类与境界由地名与种子决定，可回放 */
export function ensureWild(w) {
  if (w.wild) return w.wild;
  const dens = DEN_SPOTS.map((spot, i) => {
    const r = hash(`${w.seed}:den:${i}:kind`);
    const b = BEASTS[Math.min(BEASTS.length - 1, Math.floor(r * BEASTS.length))];
    // 越靠近深处，境界越高
    const realm = Math.min(3, Math.floor(hash(`${w.seed}:den:${i}:realm`) * 2) + (i >= 7 ? 1 : 0) + (i === 8 ? 1 : 0));
    const id = `den-${i}`;
    return {
      id, name: spot.name, x: spot.x, y: spot.y,
      beastId: b.id, realm, count: 2 + Math.floor(hash(id + w.seed) * 4),
      alive: true, lastRaid: -999, kills: 0, note: b.note,
    };
  });
  w.wild = { dens, log: [], raids: 0, slain: 0 };
  return w.wild;
}

export function densOf(w) { return ensureWild(w).dens.filter(d => d.alive); }

/** 一头巢穴里的妖兽大致有多强 */
export function denInfo(w, id) {
  const d = densOf(w).find(x => x.id === id);
  if (!d) return null;
  const b = beastById(d.beastId);
  const one = beastAt(d.beastId, d.realm);
  return { ...d, beast: b.name, meters: sizeAt(d.beastId, d.realm), hp: one.hp, dmg: one.dmg, move: one.move.name, size: one.size };
}

/** 每 6 个世界小时跑一次：妖兽出没，可能下山咬人 */
export function tickWild(w, hours = 1) {
  const wild = ensureWild(w);
  const events = [];
  for (const d of wild.dens) {
    if (!d.alive) continue;
    const roll = hash(`${w.seed}:${w.day}:${d.id}:${Math.floor(w.hour)}`);
    // 每头妖兽每天找食的概率，境界越高越敢下山
    if (d.lastRaid !== w.day && roll < 0.06 + d.realm * 0.02) {
      d.lastRaid = w.day;
      wild.raids++;
      const victim = ['松林村', '石桥村', '莲塘村', '河湾村', '青溪村'][Math.floor(roll * 900) % 5];
      const lost = 1 + Math.floor(roll * 3);
      events.push({ kind: 'raid', den: d.id, place: victim, lost, text: `${d.name}的${beastById(d.beastId).name}下山，${victim}丢了 ${lost} 头牲口` });
    }
  }
  wild.log.push(...events);
  if (wild.log.length > 200) wild.log.splice(0, wild.log.length - 200);
  return events;
}

/** 讨伐：把巢穴里的妖兽拉进一场战斗（地图上的那场），赢了拿材料 */
/** 出兵前先看：够不够打 */
export function huntPreview(w, id) {
  const d = denInfo(w, id);
  if (!d) return null;
  const one = beastAt(d.beastId, d.realm);
  const party = (w.player.men || 0) * 2.6 + (w.player.stats?.hp || 40) * 0.8;
  const pack = d.count * one.hp * 0.05 + one.dmg * 0.3;
  return { ...d, party: Math.round(party), pack: Math.round(pack), odds: +(party / Math.max(1, pack)).toFixed(2) };
}

export function huntDen(w, id, seed = 'hunt') {
  const wild = ensureWild(w);
  const d = denInfo(w, id);
  if (!d) return { ok: false, reason: '巢穴已空' };
  const one = beastAt(d.beastId, d.realm);
  // 不真的跑战斗时，用战力对比判断胜负（战斗模块另行接管时的口径一致）
  const party = (w.player.men || 0) * 2.6 + (w.player.stats?.hp || 40) * 0.8;
  const pack = d.count * one.hp * 0.05 + one.dmg * 0.3;
  const r = hash(`${seed}:${w.day}:${id}`);
  const win = party * (0.85 + r * 0.3) > pack;
  if (!win) {
    const hurt = Math.round(one.dmg * (0.5 + r));
    if (w.player.stats) w.player.stats.hp = Math.max(1, w.player.stats.hp - hurt);
    return { ok: false, win: false, hurt, reason: `打不过，被撕伤 ${hurt} 点气血` };
  }
  d.alive = false;
  wild.slain += d.count;
  const loot = [];
  for (let i = 0; i < d.count; i++) {
    for (const it of lootFor(d.beastId, d.realm, {seed: `${seed}:${id}:${i}`})) {
      const hit = loot.find(x => x.id === it.id && x.quality === it.quality);
      if (hit) hit.count += it.count; else loot.push({...it});
    }
  }
  w.player.bag = w.player.bag || [];
  for (const it of loot) {
    const hit = w.player.bag.find(x => x.id === it.id && x.quality === it.quality);
    if (hit) hit.count += it.count; else w.player.bag.push({...it});
  }
  return { ok: true, win: true, killed: d.count, loot, line: lootLine(loot), worth: lootWorth(loot) };
}

export function wildReport(w) {
  const wild = ensureWild(w);
  return {
    dens: wild.dens.map(d => ({ ...d, info: d.alive ? denInfo(w, d.id) : null })),
    alive: wild.dens.filter(d => d.alive).length,
    slain: wild.slain, raids: wild.raids,
    log: wild.log.slice(-8),
  };
}
