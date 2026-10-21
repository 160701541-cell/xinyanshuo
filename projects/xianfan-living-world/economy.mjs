/**
 * 银子在这个世界里干什么：养兵、雇人、买地、买粮、行贿、纳税、置装。
 * 修士那套（功法、丹药、阵法、灵兽）走灵石，银子买不到——只能通过官庄少量兑。
 */
export const ECON_VERSION = 'econ-0.1.0';

export const SILVER_USES = [
  { id: 'wage', name: '军饷', note: '养兵按月发钱，断饷就逃' },
  { id: 'hire', name: '雇人', note: '脚夫、护院、账房、匠人按日结' },
  { id: 'land', name: '置田', note: '每亩 18 银，田里有租子' },
  { id: 'grain', name: '籴粮', note: '灾年粮贵，囤粮是保命的本钱' },
  { id: 'bribe', name: '打点', note: '门子、书吏、巡检，一句话的事往往要银子' },
  { id: 'tax', name: '纳税', note: '田赋、商税、过关钱' },
  { id: 'gear', name: '置办', note: '皮甲、弓箭、刀剑、客栈住店' },
  { id: 'sect', name: '供奉', note: '供奉宗门只收灵石，银子递不进去' },
];

export function ensureEconomy(w) {
  w.economy = w.economy || { wages: 0, bribes: 0, hires: 0, log: [] };
  return w.economy;
}

/** 月饷：按在册兵数与客卿算 */
export function wageBill(w) {
  const men = w.player.men || 0;
  const retainers = (w.retainers || []).length;
  return Math.round(men * 2.2 + retainers * 40);
}

export function payWages(w) {
  const e = ensureEconomy(w);
  const due = wageBill(w);
  if (due <= 0) return { paid: 0, note: '无兵可养' };
  if ((w.player.silver || 0) < due) {
    // 断饷：兵会跑，名望掉
    const flee = Math.min(w.player.men || 0, Math.ceil(((w.player.men || 0) * 0.15)));
    w.player.men = Math.max(0, (w.player.men || 0) - flee);
    if (w.career) w.career.ranks = w.career.ranks;
    e.log.push({ day: w.day, kind: '欠饷', flee });
    return { paid: 0, short: due - (w.player.silver || 0), flee };
  }
  w.player.silver -= due;
  e.wages += due;
  return { paid: due };
}

/** 打点：给出去的钱按数量换人情，给太多反而被记一笔 */
export function bribe(w, amount, target = '门子') {
  const e = ensureEconomy(w);
  const a = Math.max(0, Math.round(amount));
  if ((w.player.silver || 0) < a) return { ok: false, reason: '银子不够' };
  w.player.silver -= a;
  e.bribes += a;
  const gain = a <= 0 ? 0 : Math.min(20, Math.round(Math.sqrt(a)));
  if (w.dao) w.dao.bias = Math.max(-100, Math.min(100, (w.dao.bias || 0) + 0));
  if (w.reputation) w.reputation.court = Math.min(100, (w.reputation.court || 0) + gain);
  e.log.push({ day: w.day, kind: '打点', target, amount: a, gain });
  return { ok: true, amount: a, gain, target };
}

/** 银子能买什么：修士的东西买不到，这是设计，不是缺功能 */
export function canBuyWithSilver(id) {
  const cultivatorOnly = ['stone', 'pill', 'talisman', 'sword', 'sect-favor'];
  return cultivatorOnly.includes(id) ? { ok: false, reason: '此物只收灵石' } : { ok: true };
}

export function silverReport(w) {
  const e = ensureEconomy(w);
  return {
    silver: w.player.silver || 0,
    wage: wageBill(w),
    men: w.player.men || 0,
    spent: { wages: e.wages, bribes: e.bribes, hires: e.hires },
    uses: SILVER_USES,
  };
}

/** 工钱：雇脚夫/护院这种按日结 */
export function hireGuild(w, kind = 'porter', days = 1) {
  const e = ensureEconomy(w);
  const rate = { porter: 3, guard: 9, clerk: 6, smith: 12 }[kind] || 3;
  const cost = rate * Math.max(1, days);
  if ((w.player.silver || 0) < cost) return { ok: false, reason: `要 ${cost} 银` };
  w.player.silver -= cost;
  e.hires += cost;
  return { ok: true, cost, kind, days };
}
