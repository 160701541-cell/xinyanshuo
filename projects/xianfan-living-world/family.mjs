// 家族：借鉴《修仙家族模拟器》的路子，但只借结构——族人卡、血脉遗传、婚配生育、寿元与家业，
// 素材仍用我们自己的 CC0 头像与小人。所有数值都可回放：只吃 world.seed 与成员 id。
import {ROOTS, rollRoot} from './cultivation.mjs';

export const FAMILY_VERSION = 'family-0.1.0';

// 寿元按境界给：凡人一世六十上下，炼气能活到一百一，筑基一百八，金丹三百二。
export const LIFESPAN = {mortal: 62, qi: 110, found: 180, core: 320, nascent: 600};

const TIER_ORDER = ['none', 'wu', 'si', 'san', 'shuang', 'dan', 'tian'];
const tierOf = id => Math.max(0, TIER_ORDER.indexOf(id));
const idOfTier = t => TIER_ORDER[Math.max(0, Math.min(TIER_ORDER.length - 1, t))];

const SURNAMES = ['谢', '柳', '苏', '沈', '陆', '顾', '裴', '崔', '韩', '温'];
const GIVEN = ['清和', '云舟', '听雪', '长晏', '知微', '问渠', '松寒', '照野', '衔月', '渡川', '见山', '怀瑾'];

function rngOf(seed) {
  let a = 2166136261 >>> 0;
  const s = String(seed);
  for (let i = 0; i < s.length; i++) { a ^= s.charCodeAt(i); a = Math.imul(a, 16777619) >>> 0; }
  return function () {
    a ^= a << 13; a >>>= 0; a ^= a >>> 17; a ^= a << 5; a >>>= 0;
    return a / 4294967296;
  };
}

export function ensureFamily(w) {
  if (w.family && w.family.version === FAMILY_VERSION) return w.family;
  const r = rngOf('family:' + w.seed);
  const surname = SURNAMES[Math.floor(r() * SURNAMES.length)];
  w.family = {
    version: FAMILY_VERSION,
    surname,
    name: surname + '氏',
    founded: w.day,
    generation: 1,
    prestige: 0,
    estate: {mu: 80, stones: 0, silver: 0},
    members: [],
    spouse: {},
    parents: {},
    born: {},
    died: [],
    log: []
  };
  return w.family;
}

function log(w, msg) {
  const f = ensureFamily(w);
  f.log.push({day: w.day, msg});
  if (f.log.length > 300) f.log.shift();
}

/** 把世界里的真人收进族里。 */
export function joinFamily(w, personId, reason = '收族') {
  const f = ensureFamily(w);
  const p = w.people.find(x => x.id === personId);
  if (!p) return {ok: false, error: '没有这个人'};
  if (p.status !== 'alive') return {ok: false, error: '人已不在'};
  if (f.members.includes(personId)) return {ok: false, error: '已经是族人了'};
  f.members.push(personId);
  log(w, `${p.name} 入${f.name}（${reason}）`);
  return {ok: true, person: p};
}

export function familyMembers(w) {
  const f = ensureFamily(w);
  return f.members
    .map(id => w.people.find(p => p.id === id))
    .filter(p => p && p.status === 'alive');
}

/** 灵根：NPC 身上可能还没有，第一次问时按 id 定死，之后不再变。 */
export function rootOfPerson(w, p) {
  if (!p.rootId) {
    const rolled = rollRoot('root:' + w.seed + ':' + p.id);
    p.rootId = p.root === false && rolled.id !== 'none' ? 'none' : rolled.id;
  }
  return p.rootId;
}

export function realmKeyOf(p) {
  const r = String(p.realm || '');
  if (r.includes('金丹')) return 'core';
  if (r.includes('筑基')) return 'found';
  if (r.includes('炼气') || r.includes('修士')) return 'qi';
  return 'mortal';
}

export function lifespanOf(w, p) {
  const base = LIFESPAN[realmKeyOf(p)];
  const r = rngOf('life:' + w.seed + ':' + p.id);
  return Math.round(base + (r() - 0.5) * (base * 0.18));
}

export function ageOf(w, p) {
  // 年龄只在岁末推进；这里按世界天数换算，避免读档后年龄漂移。
  return p.age + Math.floor((w.day - (p.bornDay ?? w.day)) / 360);
}

export function ageLeft(w, p) {
  return Math.max(0, lifespanOf(w, p) - ageOf(w, p));
}

/** 联姻候选：族里未婚的、性别相反、十六到四十五岁。 */
export function candidatesFor(w, personId) {
  const f = ensureFamily(w);
  const me = w.people.find(p => p.id === personId);
  if (!me) return [];
  return familyMembers(w).filter(p =>
    p.id !== personId && !f.spouse[p.id] && p.sex !== me.sex && ageOf(w, p) >= 16 && ageOf(w, p) <= 45
  );
}

export function marry(w, aId, bId) {
  const f = ensureFamily(w);
  const a = w.people.find(p => p.id === aId), b = w.people.find(p => p.id === bId);
  if (!a || !b) return {ok: false, error: '人不在了'};
  if (a.sex === b.sex) return {ok: false, error: '同姓不婚，同性别也不成'};
  if (f.spouse[aId] || f.spouse[bId]) return {ok: false, error: '已经成过亲了'};
  if (ageOf(w, a) < 16 || ageOf(w, b) < 16) return {ok: false, error: '年纪还小'};
  f.spouse[aId] = bId; f.spouse[bId] = aId;
  if (!f.members.includes(aId)) f.members.push(aId);
  if (!f.members.includes(bId)) f.members.push(bId);
  f.prestige += 2;
  log(w, `${a.name} 与 ${b.name} 成亲`);
  return {ok: true, a, b};
}

/** 血脉：孩子灵根从父母身上抽，双修士最容易出好苗子。 */
export function inheritRoot(w, a, b) {
  const r = rngOf('child:' + w.seed + ':' + a.id + ':' + b.id + ':' + (w.family?.born[a.id + b.id] ?? 0));
  const ta = tierOf(rootOfPerson(w, a)), tb = tierOf(rootOfPerson(w, b));
  const best = Math.max(ta, tb);
  if (best === 0) return 'none';                       // 两个凡人生不出灵根
  const roll = r();
  if (roll < 0.18) return idOfTier(best + 1);           // 青出于蓝
  if (roll < 0.62) return idOfTier(best);               // 随父母里强的那个
  if (roll < 0.88) return idOfTier(best - 1);
  return 'none';
}

export function conceive(w, aId, bId) {
  const f = ensureFamily(w);
  const a = w.people.find(p => p.id === aId), b = w.people.find(p => p.id === bId);
  if (!a || !b) return {ok: false, error: '人不在了'};
  if (f.spouse[aId] !== bId) return {ok: false, error: '没有成亲，不能生育'};
  const mother = a.sex === '女' ? a : b;
  if (ageOf(w, mother) < 16 || ageOf(w, mother) > 45) return {ok: false, error: '年纪不适合生育'};
  const key = aId + bId;
  f.born[key] = (f.born[key] || 0) + 1;
  const r = rngOf('born:' + w.seed + ':' + key + ':' + f.born[key]);
  const sex = r() < 0.5 ? '女' : '男';
  const rootId = inheritRoot(w, a, b);
  const id = 'N' + String(w.people.length + 1).padStart(6, '0');
  // 名字不重：同代重名就顺延到下一个字，族谱里不会出现两个“崔知微”
  const used = new Set(w.people.filter(p => p.status === 'alive').map(p => p.name));
  let given = '';
  for (let i = 0; i < GIVEN.length; i++) {
    const g = GIVEN[(Math.floor(r() * GIVEN.length) + i) % GIVEN.length];
    if (!used.has(f.surname + g)) { given = g; break; }
  }
  const child = {
    id,
    name: f.surname + (given || GIVEN[Math.floor(r() * GIVEN.length)] + '儿'),
    age: 0,
    bornDay: w.day,
    sex,
    job: '孩童',
    home: mother.home,
    location: mother.home,
    household: mother.household,
    wealth: 0,
    health: 85,
    traits: ['年幼'],
    root: rootId !== 'none',
    rootId,
    status: 'alive',
    memory: []
  };
  w.people.push(child);
  const place = w.places[child.home];
  if (place) place.population += 1;
  f.members.push(id);
  f.parents[id] = [aId, bId];
  f.prestige += rootId === 'none' ? 0 : 4;
  log(w, `${mother.name} 生下一${sex === '女' ? '女' : '子'} ${child.name}（${ROOTS[rootId].name}）`);
  return {ok: true, child, rootId};
}

/** 过年：族人长一岁，寿元到了就走，家业跟着结算。 */
export function ageFamily(w, years = 1) {
  const f = ensureFamily(w);
  const out = {died: [], grew: 0, income: 0};
  for (const p of familyMembers(w)) {
    p.age += years;
    out.grew += 1;
    if (p.age >= lifespanOf(w, p)) {
      p.status = 'dead';
      p.deathDay = w.day;
      f.died.push({id: p.id, name: p.name, age: p.age, day: w.day});
      log(w, `${p.name} 享年 ${p.age}`);
      out.died.push(p.name);
    }
  }
  // 家业：田亩与在族修士的产出，扣族中老小的口粮
  const mu = f.estate.mu;
  const earn = Math.round(mu * 0.6 + familyMembers(w).filter(p => p.root).length * 12);
  const upkeep = Math.round(familyMembers(w).length * 3);
  out.income = earn - upkeep;
  f.estate.silver += out.income;
  if (f.estate.silver < 0) { f.estate.mu = Math.max(20, f.estate.mu - 5); f.estate.silver = 0; }
  for (const p of familyMembers(w)) if (p.root && p.realm) f.prestige += 1;
  w.family.generation = Math.max(f.generation, 1 + Math.max(0, ...familyMembers(w).map(p => (f.parents[p.id] ? 1 : 0))));
  return out;
}

export function familyReport(w) {
  const f = ensureFamily(w);
  const members = familyMembers(w);
  const cultivators = members.filter(p => p.root).length;
  return {
    version: FAMILY_VERSION,
    name: f.name,
    generation: f.generation,
    prestige: f.prestige,
    members: members.length,
    cultivators,
    estate: {...f.estate},
    cards: members.slice(0, 24).map(p => ({
      id: p.id, name: p.name, sex: p.sex, age: ageOf(w, p), left: ageLeft(w, p),
      root: ROOTS[rootOfPerson(w, p)].name, realm: p.realm || '凡人',
      spouse: f.spouse[p.id] ? (w.people.find(x => x.id === f.spouse[p.id]) || {}).name || '' : ''
    })),
    log: f.log.slice(-12)
  };
}
