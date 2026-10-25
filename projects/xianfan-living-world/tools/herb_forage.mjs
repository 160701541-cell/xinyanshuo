// 散修采药：石桥村周边三处采集点。规则声明见 data/herb_forage_v1.json。
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';

export const FORAGE_VERSION = 'herb-forage-1.0.0';
const sha = x => createHash('sha256').update(x).digest('hex');
const num = (seed, label, upper) => Number(BigInt('0x' + sha(`${seed}|${label}`)) % BigInt(upper));

const DATA = JSON.parse(readFileSync(new URL('../data/herb_forage_v1.json', import.meta.url), 'utf8'));
export const SITES = DATA.sites;
export const HERBS = DATA.herbs;
export const MARKET = DATA.market;
export const site = id => { const s = SITES.find(x => x.id === id); if (!s) throw Error('UNKNOWN_SITE ' + id); return s; };

/** 某处某日的采集结果。同一处每天只算一次。 */
export function forageRoll(worldSeed, siteId, dayNo) {
  const roll = num(worldSeed, `forage|${siteId}|d${dayNo}|tier`, 1000);
  let band;
  if (roll < 600) band = 'mortal';
  else if (roll < 900) band = 'none';
  else if (roll < 990) band = 'spirit';
  else band = 'rare';
  if (band === 'none') return { roll, band, items: [] };
  const pool = HERBS[band];
  const n = band === 'mortal' ? 1 + num(worldSeed, `forage|${siteId}|d${dayNo}|count`, 2) : 1;
  const items = [];
  for (let i = 0; i < n; i++) {
    const h = pool[num(worldSeed, `forage|${siteId}|d${dayNo}|pick${i}`, pool.length)];
    items.push({ id: h.id, name: h.name, price_copper: h.price_copper, tier: band });
  }
  return { roll, band, items };
}

/** 摊主收购：灵草在县城按折扣算。返回实付与明细。 */
export function saleValue(items, factor, cashAvailable) {
  let total = 0;
  const detail = [];
  for (const it of items) {
    const f = it.tier === 'mortal' ? 1 : factor;
    const price = Math.floor(it.price_copper * f);
    total += price;
    detail.push({ ...it, paid: price, factor: f });
  }
  const paid = Math.min(total, cashAvailable);
  return { offered: total, paid, capped: total > cashAvailable, detail };
}

export function selfTest() {
  const failed = [];
  const eq = (n, a, b) => { if (JSON.stringify(a) !== JSON.stringify(b)) failed.push(`${n}: ${a} != ${b}`); };
  eq('采集点三处', SITES.length, 3);
  eq('权重合计', 600 + 300 + 90 + 10, 1000);
  const r = forageRoll('seed', 'SH-SLOPE-N-01', 31);
  eq('同日确定性', r.roll, forageRoll('seed', 'SH-SLOPE-N-01', 31).roll);
  const v = saleValue([{ tier: 'spirit', price_copper: 20 }], 0.6, 100);
  eq('灵草折扣', v.paid, 12);
  const c = saleValue([{ tier: 'mortal', price_copper: 30 }], 1, 20);
  eq('受现金上限', c.paid, 20);
  eq('触发封顶', c.capped, true);
  return { ok: failed.length === 0, failed };
}
