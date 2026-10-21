/**
 * 家业：住哪儿、怎么盖房、怎么赚钱、怎么招人、怎么立宗、怎么称王。
 * 这一层的目的只有一个——把“活着 → 攒钱 → 有产 → 有人 → 有地 → 有名分”接成一条路。
 */
import {note, getPlace, shortestRoute, advanceClock, isInterior} from './core.mjs';

export const LIFE_VERSION = 'life-0.1.0';

/* ── 住处 ───────────────────────────────────────────── */
export const RENT = {inn: 30, room: 18, yard: 60};        // 银/月
export const HOUSE_PRICE = {room: 420, house: 1500, yard: 6000};

/** 玩家状态：core 里只有 player.stats 的一部分，缺的补齐 */
export function statsOf(w) {
  if (!w.player.stats) w.player.stats = {hp: 100, stamina: 100, maxHp: 100, maxStamina: 100, realm: '凡人', level: 1};
  const st = w.player.stats;
  if (st.hp == null) st.hp = 100;
  if (st.stamina == null) st.stamina = 100;
  return st;
}

export function ensureLife(w) {
  if (!w.life) w.life = {home: null, plots: [], built: [], job: null, daysWorked: 0, sect: null, realm: null, log: []};
  return w.life;
}

export function homeOf(w) { return ensureLife(w).home; }

/** 住客栈：按天付钱，睡一觉回体力与气血 */
export function stayInn(w, days = 1) {
  const cost = RENT.inn * days;
  if ((w.player.silver || 0) < cost) return {ok: false, reason: `住店要 ${cost} 银，你只有 ${w.player.silver} 银`};
  w.player.silver -= cost;
  const st = statsOf(w);
  st.hp = Math.min(100, st.hp + 45 * days);
  st.stamina = Math.min(100, st.stamina + 60 * days);
  advanceClock(w, 8 * 60 * days);
  note(w, '家业', `在客栈住了 ${days} 天，付 ${cost} 银`);
  return {ok: true, cost};
}

/** 买房：买下来才算有家，能存东西、能招人、能办事 */
export function buyHouse(w, kind = 'room') {
  ensureLife(w);
  const price = HOUSE_PRICE[kind];
  if (!price) return {ok: false, reason: '没有这种房子'};
  if (w.life.home) return {ok: false, reason: '你已经有宅子了'};
  if ((w.player.silver || 0) < price) return {ok: false, reason: `要 ${price} 银，你只有 ${w.player.silver} 银`};
  w.player.silver -= price;
  w.life.home = {kind, place: w.player.place, price, level: kind === 'yard' ? 3 : kind === 'house' ? 2 : 1, builtAt: w.day};
  w.player.home = w.player.place;
  note(w, '家业', `在${getPlace(w.player.place)?.name || '临安'}置下${kind === 'yard' ? '宅院' : kind === 'house' ? '一所瓦房' : '一间小屋'}`);
  return {ok: true, home: w.life.home};
}

/** 在自己的宅子上加盖：居住等级影响存物、招人与声望 */
export function upgradeHome(w) {
  ensureLife(w);
  const h = w.life.home;
  if (!h) return {ok: false, reason: '先有宅子才能加盖'};
  if (h.level >= 3) return {ok: false, reason: '已经是宅院了'};
  const cost = h.level === 1 ? 900 : 3600;
  if ((w.player.silver || 0) < cost) return {ok: false, reason: `要 ${cost} 银`};
  w.player.silver -= cost; h.level += 1;
  note(w, '家业', `宅子加盖到 ${h.level} 级`);
  return {ok: true, level: h.level};
}

/** 歇息：不出工也不花钱，养回体力；有宅子回得更多 */
export function restDay(w, days = 1) {
  ensureLife(w);
  const st = statsOf(w);
  const bonus = w.life.home ? 1.5 : 1;
  st.stamina = Math.min(100, st.stamina + 45 * days * bonus);
  st.hp = Math.min(100, st.hp + 20 * days * bonus);
  advanceClock(w, 12 * 60 * days);
  return {ok: true, stamina: Math.round(st.stamina)};
}

/* ── 打工与卖货 ─────────────────────────────────────── */
export const JOBS = {
  porter: {name: '脚夫', pay: 12, hours: 8, stamina: 18},
  clerk: {name: '账房', pay: 18, hours: 8, stamina: 6},
  guard: {name: '护院', pay: 25, hours: 10, stamina: 14},
  herb: {name: '采药', pay: 20, hours: 8, stamina: 22},
};

export function workDay(w, jobId = 'porter') {
  ensureLife(w);
  const j = JOBS[jobId];
  if (!j) return {ok: false, reason: '没有这份工'};
  const st = statsOf(w);
  if (st.stamina < j.stamina) return {ok: false, reason: '体力不够，先歇着'};
  st.stamina -= j.stamina;
  w.player.silver = (w.player.silver || 0) + j.pay;
  w.life.job = jobId; w.life.daysWorked += 1;
  advanceClock(w, j.hours * 60);
  if (w.life.daysWorked % 10 === 0) note(w, '家业', `做了 ${w.life.daysWorked} 天${j.name}，攒下 ${w.player.silver} 银`);
  return {ok: true, pay: j.pay, silver: w.player.silver};
}

/** 把行囊里用不上的东西卖成钱（妖兽材料、多余符箓） */
export function sellGoods(w, itemId, count = 1) {
  const bag = w.player.bag || (w.player.bag = {});
  const have = bag[itemId] || 0;
  if (have < count) return {ok: false, reason: '行囊里没有这么多'};
  const base = (w.itemPrice && w.itemPrice[itemId]) || 20;
  const gain = Math.round(base * 0.6 * count);       // 变卖只值六成
  bag[itemId] = have - count;
  if (!bag[itemId]) delete bag[itemId];
  w.player.silver = (w.player.silver || 0) + gain;
  return {ok: true, gain, silver: w.player.silver};
}

/* ── 招人 ───────────────────────────────────────────── */
export function recruitCap(w) {
  ensureLife(w);
  const lvl = w.life.home?.level || 0;
  return lvl === 0 ? 2 : lvl === 1 ? 6 : lvl === 2 ? 14 : 30;
}

export function hire(w, n = 1, kind = '护院') {
  ensureLife(w);
  const cap = recruitCap(w);
  if ((w.player.men || 0) + n > cap) return {ok: false, reason: `住处只养得起 ${cap} 人，先置宅或加盖`};
  const cost = n * 45;                                // 安家费
  if ((w.player.silver || 0) < cost) return {ok: false, reason: `招 ${n} 人要 ${cost} 银`};
  w.player.silver -= cost;
  w.player.men = (w.player.men || 0) + n;
  w.player.retainers = w.player.retainers || [];
  for (let i = 0; i < n; i++) w.player.retainers.push({kind, since: w.day, loyalty: 60});
  note(w, '家业', `招了 ${n} 名${kind}`);
  return {ok: true, men: w.player.men};
}

/* ── 立宗 ───────────────────────────────────────────── */
export const SECT_FOUND = {silver: 3000, stones: 50, minRealm: 2, land: 'lingshan'};

export function foundSect(w, name = '青云别院') {
  ensureLife(w);
  if (w.life.sect) return {ok: false, reason: '你已经有一处山门'};
  const realm = w.player.realmLevel ?? 0;
  if (realm < SECT_FOUND.minRealm) return {ok: false, reason: '筑基以上才配开山立派'};
  if ((w.player.silver || 0) < SECT_FOUND.silver) return {ok: false, reason: `开山要 ${SECT_FOUND.silver} 银`};
  if ((w.player.stones || 0) < SECT_FOUND.stones) return {ok: false, reason: `要 ${SECT_FOUND.stones} 块下品灵石布护山大阵`};
  w.player.silver -= SECT_FOUND.silver;
  w.player.stones -= SECT_FOUND.stones;
  w.life.sect = {name, since: w.day, disciples: 0, stones: 0, hall: 1};
  note(w, '家业', `在灵山开辟山门，立「${name}」`);
  return {ok: true, sect: w.life.sect};
}

export function takeDisciple(w, n = 1) {
  ensureLife(w);
  const s = w.life.sect;
  if (!s) return {ok: false, reason: '还没有山门'};
  const cost = n * 120;
  if ((w.player.silver || 0) < cost) return {ok: false, reason: `收徒要置办行头，每人 120 银`};
  w.player.silver -= cost;
  s.disciples += n;
  note(w, '家业', `收 ${n} 名弟子入门`);
  return {ok: true, disciples: s.disciples};
}

/* ── 自立为王 ───────────────────────────────────────── */
export const THRONE = {officeRank: 2, men: 60, fame: 120, silver: 20000, place: 'xianya'};

export function canTakeThrone(w) {
  ensureLife(w);
  const c = w.career || {};
  const rank = c.ranks?.office ?? -1;
  const miss = [];
  if (rank < THRONE.officeRank) miss.push('先做到县令');
  if ((w.player.men || 0) < THRONE.men) miss.push(`至少 ${THRONE.men} 兵`);
  if ((c.fame || 0) < THRONE.fame) miss.push(`名望 ${THRONE.fame}`);
  if ((w.player.silver || 0) < THRONE.silver) miss.push(`${THRONE.silver} 银`);
  return miss.length ? {ok: false, reason: '还差：' + miss.join('、')} : {ok: true};
}

export function takeThrone(w, title = '临安王') {
  const gate = canTakeThrone(w);
  if (!gate.ok) return gate;
  ensureLife(w);
  w.player.silver -= THRONE.silver;
  w.life.realm = {title, since: w.day, taxes: 0, loyalty: 60};
  note(w, '家业', `于临安县衙称「${title}」，自立一方`);
  return {ok: true, realm: w.life.realm};
}

/** 家业月结：房租、雇工开销、地盘税收 */
export function tickLife(w, days = 30) {
  ensureLife(w);
  const l = w.life;
  const out = {income: 0, cost: 0};
  if (l.home) { cost += 0; }
  if (l.realm) { const tax = Math.round((w.people?.length || 13000) * 0.02 * days / 30); out.income += tax; l.realm.taxes += tax; }
  if (l.sect) { const dues = l.disciples * 3; out.income += dues; }
  out.cost += (w.player.men || 0) * 2.2 * (days / 30);
  w.player.silver = Math.round((w.player.silver || 0) + out.income - out.cost);
  return out;
}

export function lifeReport(w) {
  ensureLife(w);
  const l = w.life;
  return {
    home: l.home, men: w.player.men || 0, cap: recruitCap(w), silver: w.player.silver || 0,
    stones: w.player.stones || 0, job: l.job, daysWorked: l.daysWorked,
    sect: l.sect, realm: l.realm,
    next: l.sect ? '带弟子、收灵石' : l.realm ? '治县' : canTakeThrone(w).ok ? '可称王' : '攒钱置宅',
  };
}
