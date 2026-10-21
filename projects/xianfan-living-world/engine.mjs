// 内容引擎：把“事件/条件/后果”从一堆 if 里抽出来，做成可校验、可批量产出的数据。
// 一条规则 = {id, hook, when, then, once, cooldown, weight, tag}；新增玩法 = 加一条数据，不是加一段代码。
import {note} from './core.mjs';

export const ENGINE_VERSION = 'engine-0.1.0';

const pick = (w, path) => path.split('.').reduce((o, k) => (o == null ? undefined : o[k]), w);

export const OPS = {
  truthy: v => !!v,
  falsy: v => !v,
  eq: (a, b) => a === b,
  ne: (a, b) => a !== b,
  gte: (a, b) => Number(a) >= Number(b),
  lte: (a, b) => Number(a) <= Number(b),
  gt: (a, b) => Number(a) > Number(b),
  lt: (a, b) => Number(a) < Number(b),
  has: (a, b) => Array.isArray(a) && a.includes(b),
  includes: (a, b) => String(a ?? '').includes(String(b)),
  mod: (a, b) => Number(a) % Number(b) === 0
};

export const COND_KEYS = ['all', 'any', 'not', 'path', 'op', 'value'];

export function checkCond(w, cond, ctx = {}, local = false) {
  if (cond == null) return true;
  if (Array.isArray(cond)) return cond.every(c => checkCond(w, c, ctx, local));
  if (cond.all) return cond.all.every(c => checkCond(w, c, ctx, local));
  if (cond.any) return cond.any.some(c => checkCond(w, c, ctx, local));
  if (cond.not) return !checkCond(w, cond.not, ctx, local);
  const raw = String(cond.path || '');
  const v = local ? (raw.startsWith('ctx.') ? pick(ctx, raw.slice(4)) : pick(ctx, raw))
                  : (raw.startsWith('ctx.') ? pick(ctx, raw.slice(4)) : pick(w, raw));
  const op = cond.op || 'truthy';
  const fn = OPS[op];
  return fn ? !!fn(v, cond.value) : false;
}

const fill = (tpl, w, ctx) => String(tpl ?? '').replace(/\{\{(\w+)\}\}/g, (_, k) => {
  const v = k === 'player' ? w.player?.name : (ctx[k] ?? pick(w, k));
  return v == null ? '' : String(v);
});

function bump(w, path, by) {
  const ks = path.split('.');
  const last = ks.pop();
  let o = w;
  for (const k of ks) { if (o[k] == null) o[k] = {}; o = o[k]; }
  o[last] = Number(o[last] || 0) + Number(by || 0);
  return o[last];
}

/** 一条规则可以做多件事；return 出的事件会进纪事页。 */
export function applyEffects(w, effects, ctx = {}) {
  const done = [];
  for (const e of effects || []) {
    switch (e.do) {
      case 'add': bump(w, e.path, e.by); done.push(`${e.path} ${e.by > 0 ? '+' : ''}${e.by}`); break;
      case 'set': {
        const ks = e.path.split('.'); const last = ks.pop(); let o = w;
        for (const k of ks) { if (o[k] == null) o[k] = {}; o = o[k]; }
        o[last] = e.value; done.push(`${e.path}=${e.value}`); break;
      }
      case 'note': note(w, e.type || '事件', fill(e.text, w, ctx), e.meta || {}); done.push(fill(e.text, w, ctx)); break;
      case 'flag': w.engine.flags[e.key] = e.value ?? true; break;
      case 'unflag': delete w.engine.flags[e.key]; break;
      default: done.push(`unknown:${e.do}`);
    }
  }
  return done;
}

export function ensureEngine(w) {
  if (!w.engine || w.engine.version !== ENGINE_VERSION) {
    w.engine = {version: ENGINE_VERSION, flags: w.engine?.flags || {}, fired: {}, log: []};
  }
  return w.engine;
}

/** 跑某个钩子下的全部规则；once 与 cooldown 在这里统一管，玩法不用自己记。 */
export function runRules(w, hook, ctx = {}) {
  ensureEngine(w);
  const e = w.engine;
  const fired = [];
  for (const r of RULES) {
    if (r.hook !== hook) continue;
    const key = r.id;
    if (r.once && e.fired[key]) continue;
    const last = e.fired[key]?.day;
    if (r.cooldown && last != null && w.day - last < r.cooldown) continue;
    if (!checkCond(w, r.when, ctx)) continue;
    applyEffects(w, r.then, ctx);
    e.fired[key] = {day: w.day, times: (e.fired[key]?.times || 0) + 1};
    fired.push(r.id);
    e.log.push({day: w.day, id: r.id, hook});
    if (e.log.length > 400) e.log.shift();
    if (fired.length >= 6) break;      // 一天最多爆六个事件，免得刷屏
  }
  return fired;
}

export function validateRule(r) {
  const errs = [];
  if (!r || typeof r !== 'object') return ['规则不是对象'];
  if (!r.id) errs.push('缺 id');
  if (!r.hook) errs.push(`${r.id}: 缺 hook`);
  if (!Array.isArray(r.then) || !r.then.length) errs.push(`${r.id}: then 必须是数组且有内容`);
  for (const e of r.then || []) {
    if (!['add', 'set', 'note', 'flag', 'unflag'].includes(e.do)) errs.push(`${r.id}: 未知效果 ${e.do}`);
    if ((e.do === 'add' || e.do === 'set') && !e.path) errs.push(`${r.id}: ${e.do} 缺 path`);
  }
  const walk = (c) => {
    if (!c || typeof c !== 'object') { errs.push(`${r.id}: 条件不是对象`); return; }
    if (Array.isArray(c)) return c.forEach(walk);
    if (c.all) return c.all.forEach(walk);
    if (c.any) return c.any.forEach(walk);
    if (c.not) return walk(c.not);
    if (c.path && c.op && !OPS[c.op]) errs.push(`${r.id}: 未知运算符 ${c.op}`);
  };
  if (r.when) walk(r.when);
  return errs;
}

export const RULES = [];
export const CARD_TEMPLATES = new Map();

export function defineCards(list) {
  for (const c of list) {
    const errs = [];
    if (!c.id) errs.push('卡片缺 id');
    if (!c.kind) errs.push(`${c.id}: 缺 kind`);
    if (!Array.isArray(c.fields) || !c.fields.length) errs.push(`${c.id}: 缺 fields`);
    for (const f of c.fields || []) if (!f.key) errs.push(`${c.id}: 字段缺 key`);
    if (errs.length) throw new Error('卡片校验失败：' + errs.join('; '));
    CARD_TEMPLATES.set(c.id, c);
  }
  return CARD_TEMPLATES;
}

/** 按模板可见字段算出要显示的行，界面不用自己挑字段。 */
export function cardView(w, tplId, ctx = {}) {
  const t = CARD_TEMPLATES.get(tplId);
  if (!t) return null;
  const local = {...ctx, ...(ctx.item || {})};
  const rows = t.fields
    .filter(f => !f.when || checkCond(w, f.when, local, true))
    .map(f => ({label: f.label, value: local[f.key] ?? ''}))
    .filter(r => r.value !== '' && r.value != null);
  const actions = (t.actions || []).filter(a => !a.when || checkCond(w, a.when, local, true)).map(a => ({id: a.id, label: a.label}));
  return {id: t.id, kind: t.kind, rows, actions};
}

export function registerRules(list) {
  for (const r of list) {
    const errs = validateRule(r);
    if (errs.length) throw new Error('规则校验失败：' + errs.join('; '));
    if (!RULES.some(x => x.id === r.id)) RULES.push(r);   // 幂等：重复装载同一张表不会翻倍
  }
  return RULES;
}
