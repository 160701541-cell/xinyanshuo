/**
 * 钱：铜钱（文）是唯一的最小单位。1 银 = 100 文，1 金 = 100 银 = 10,000 文。
 * 普通男工一个月 150–300 文，女工 120–220 文——所有价格都得按这把尺子重排。
 */
// 铜钱(文) → 银 → 金 → 下品灵石 → 中品 → 上品 → 极品，每级 100:1
// 铜钱(文) → 银 → 金：每级 100:1
// 金 → 下品灵石：100:1
// 下品 → 中品：1000:1
// 中品 → 上品：1000:1
// 极品是特例：1 颗极品 = 10000 中品（= 10 上品）
export const COIN = {wen: 1, silver: 100, gold: 10000};
COIN.stoneLow = COIN.gold * 100;          // 1,000,000 文
COIN.stoneMid = COIN.stoneLow * 1000;     // 1,000,000,000 文
COIN.stoneHigh = COIN.stoneMid * 1000;    // 1,000,000,000,000 文
COIN.stonePeak = COIN.stoneMid * 10000;   // 10,000,000,000,000 文
/** 旧代码里的 stone 指下品灵石 */
COIN.stone = COIN.stoneLow;

/** 把 {gold, silver, wen} 折算成文 */
export function toWen(v = {}) {
  if (typeof v === 'number') return Math.round(v);
  return Math.round((v.gold || 0) * COIN.gold + (v.silver || 0) * COIN.silver + (v.wen || 0));
}

/** 显示：按「金/银/文」下折；上了灵石就改用灵石，不堆一串文 */
export function fmt(wen) {
  const n = Math.max(0, Math.round(wen || 0));
  if (n >= COIN.stoneLow) {
    const tiers = [['stonePeak', '极品灵石'], ['stoneHigh', '上品灵石'], ['stoneMid', '中品灵石'], ['stoneLow', '下品灵石']];
    const [k, name] = tiers.find(([k]) => n >= COIN[k]);
    const v = n / COIN[k];
    return `${v >= 10 ? Math.round(v) : v.toFixed(1).replace(/\.0$/, '')} ${name}`;
  }
  const jin = Math.floor(n / COIN.gold);
  const yin = Math.floor((n % COIN.gold) / COIN.silver);
  const rest = n % COIN.silver;
  const parts = [];
  if (jin) parts.push(jin + ' 两金');
  if (yin) parts.push(yin + ' 两银');
  if (rest || !parts.length) parts.push(rest + ' 文');
  return parts.join(' ');
}

/** 老字段 silver 与新的 coin（文）互相同步，避免两套钱袋 */
export function ensureCoin(w) {
  const p = w.player;
  if (p.coin == null) p.coin = Math.round((p.silver || 0) * COIN.silver);
  return p.coin;
}

export function readCoin(w) { ensureCoin(w); return w.player.coin; }

export function spend(w, wen) {
  ensureCoin(w);
  if (w.player.coin < wen) return false;
  w.player.coin -= wen;
  w.player.silver = Math.floor(w.player.coin / COIN.silver);
  return true;
}

export function earn(w, wen) {
  ensureCoin(w);
  w.player.coin += wen;
  w.player.silver = Math.floor(w.player.coin / COIN.silver);
  return w.player.coin;
}

/** 月钱：男 150–300 文、女 120–220 文，按性别与手艺浮动 */
export function monthWage(sex = '男', skill = 0.5) {
  const base = sex === '女' ? 120 : 150;
  const span = sex === '女' ? 100 : 150;
  return Math.round(base + span * Math.max(0, Math.min(1, skill)));
}

/** 日薪按 25 个工日折算 */
export function dayWage(sex = '男', skill = 0.5) { return Math.max(1, Math.round(monthWage(sex, skill) / 25)); }
