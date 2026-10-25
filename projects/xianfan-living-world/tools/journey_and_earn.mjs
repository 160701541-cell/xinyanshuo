// 路程、渔获与市场：把 data/road_travel_v1.json、data/fishing_v1.json、
// data/root_test_station_v1.json 的规则落成可执行代码。任何数字都必须从这里算出来。
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const HERE = dirname(fileURLToPath(import.meta.url));
const ROOT = join(HERE, '..');
const load = (p) => JSON.parse(readFileSync(join(ROOT, p), 'utf8'));

export const JOURNEY_VERSION = 'journey-earn-1.0.0';
export const ROAD = load('data/road_travel_v1.json');
export const FISH = load('data/fishing_v1.json');
export const STATION = load('data/root_test_station_v1.json');

export const WALK = { metersPerMinute: 52.17, staminaPerMinute: 0.1478 };
const settle2 = (m) => Math.round(m * 100) / 100;
const sha = (s) => createHash('sha256').update(String(s), 'utf8').digest('hex');
const rollOf = (...parts) => parseInt(sha(parts.join('|')).slice(0, 8), 16);

export function leg(id) {
  const l = ROAD.legs.find((x) => x.id === id);
  if (!l) throw new Error('没有这条路 ' + id);
  const minutes = Math.round(l.distance_m / (WALK.metersPerMinute * l.speed_factor));
  const stamina = settle2(minutes * WALK.staminaPerMinute);
  return { id: l.id, from: l.from, to: l.to, route: l.route, distance_m: l.distance_m, terrain: l.terrain, minutes, stamina };
}

export function route(ids) {
  const legs = ids.map(leg);
  return {
    legs,
    minutes: legs.reduce((a, b) => a + b.minutes, 0),
    stamina: settle2(legs.reduce((a, b) => a + b.stamina, 0)),
    distance_m: legs.reduce((a, b) => a + b.distance_m, 0),
  };
}

export function populationMorning(seed, dayNo, population) {
  const cap = FISH.river.capacity;
  const rec = FISH.river.recovery;
  if (population < 1) {
    const pct = rec.if_population_lt_1.immigration_percent;
    const r = rollOf(seed, 'river-immigration', 'day' + dayNo) % 100;
    if (r < pct) return { population: population + 1, immigrationRoll: r, immigrationPercent: pct, note: '河段里只剩这么点，上游游进来一条' };
    return { population, immigrationRoll: r, immigrationPercent: pct, note: '不到两条，自身繁育已断；上游也没游进来' };
  }
  if (population >= cap) return { population, note: '已满容量' };
  return { population: population + rec.if_population_gte_1.gain, note: '清晨回涨一条' };
}

export function cageCheck(seed, dayNo, weather, gearId, population) {
  if (population <= 0) return { caught: 0, minutes: FISH.cage.check_minutes, stamina: FISH.cage.check_stamina, reason: '河段里没有鱼' };
  const pct = FISH.cage.catch_percent_by_weather[weather] ?? 45;
  const r = rollOf(seed, 'cage-catch', 'day' + dayNo, gearId) % 100;
  return { caught: r < pct ? 1 : 0, roll: r, percent: pct, minutes: FISH.cage.check_minutes, stamina: FISH.cage.check_stamina };
}

export function rodHour(seed, dayNo, hourIndex, population) {
  if (population <= 0) return { caught: 0, minutes: 60, stamina: FISH.rod.stamina_per_hour, reason: '河段里没有鱼' };
  const r = rollOf(seed, 'rod-catch', 'day' + dayNo, 'h' + hourIndex) % 100;
  return { caught: r < FISH.rod.catch_percent_per_hour ? 1 : 0, roll: r,
           percent: FISH.rod.catch_percent_per_hour, minutes: 60, stamina: FISH.rod.stamina_per_hour };
}

export function stallCashToday(seed, dayNo, initialCash) {
  const base = initialCash + (rollOf(seed, 'stall-cash', 'day' + dayNo, 'PRODUCE') % 7) - 3;
  return Math.max(FISH.market.stall_cash_daily.floor, base);
}

export function sell(stall, item, qty, cashAvailable) {
  const price = FISH.market.buy_prices[item];
  if (!price) throw new Error('这个摊子不收 ' + item);
  const affordable = Math.floor(cashAvailable / price);
  const sold = Math.min(qty, affordable);
  return { sold, price, copper: sold * price, cashAfter: cashAvailable - sold * price, refused: qty - sold };
}

export function station(id) {
  const s = STATION.stations.find((x) => x.id === id);
  if (!s) throw new Error('没有这个检测台 ' + id);
  return s;
}

export function selfTest() {
  const a = [];
  const eq = (name, got, want) => { const ok = JSON.stringify(got) === JSON.stringify(want); a.push({ name, got, want, ok }); return ok; };
  const r1 = route(['shiqiao-linan', 'linan-qingyun']);
  eq('村到县城 115 分钟', r1.legs[0].minutes, 115);
  eq('村到县城 17 精力', r1.legs[0].stamina, 17);
  eq('村到青云合计分钟', r1.minutes, 472);
  eq('村到灵山合计分钟', route(['shiqiao-linan', 'linan-lingshan']).minutes, 504);
  eq('清晨回涨 4→5', populationMorning('s', 3, 4).population, 5);
  eq('满容不涨', populationMorning('s', 3, 5).population, 5);
  eq('还剩一条每天回涨', populationMorning('s', 3, 1).population, 2);
  eq('卖鱼只卖摊主收得起的量', sell('PRODUCE', 'river_fish', 10, 15).sold, 5);
  eq('摊主现钱不为负', sell('PRODUCE', 'river_fish', 10, 15).cashAfter, 0);
  eq('药市检测费 25 文', station('ST-LINGSHAN-01').fee_copper, 25);
  eq('山门检测费 30 文', station('ST-QINGYUN-01').fee_copper, 30);
  const bad = a.filter((x) => !x.ok);
  return { ok: bad.length === 0, total: a.length, failed: bad };
}

if (process.argv[1] && process.argv[1].endsWith('journey_and_earn.mjs')) {
  const r = selfTest();
  console.log(JSON.stringify(r, null, 1));
  process.exit(r.ok ? 0 : 1);
}
