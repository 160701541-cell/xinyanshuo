// 《仙凡·苍岚》第一世：第31日起，散修路线第一段——在石桥村周边采药换钱。
// 用法：node tools/settle_forage.mjs <战役目录>
import { readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { digest, verifyEvents, countTurns, inspect, checkpoint } from './campaign_guard.mjs';
import { auditProposedTurn, reviewAtTurn } from './gm_quality_gate.mjs';
import * as D from './daily_cycle.mjs';
import * as J from './journey_and_earn.mjs';
import * as H from './herb_forage.mjs';
import { npcName, npcAge, randomKeyOf } from './root_generation.mjs';

const root = process.argv[2];
if (!root) throw Error('缺战役目录');
const read = n => JSON.parse(readFileSync(join(root, n), 'utf8'));
const readLines = n => readFileSync(join(root, n), 'utf8').split(/\r?\n/).filter(Boolean).map(JSON.parse);

const st = H.selfTest(); if (!st.ok) throw Error('采药规则自测失败 ' + JSON.stringify(st.failed));
const jst = J.selfTest(); if (!jst.ok) throw Error('路程规则自测失败 ' + JSON.stringify(jst.failed));

const state = read('game_state.json');
const index = read('campaign_index.json');
const events = readLines('events.jsonl');

verifyEvents(events);
if (index.turns_completed !== countTurns(events)) throw Error('索引与事件轮数不符');
if (state.last_event_id !== index.last_event) throw Error('状态与索引事件不同步');
if (digest(state) !== index.full_state_sha256) throw Error('状态哈希与索引不符');
if (index.turns_completed !== 114) throw Error('本脚本只接第114轮之后；当前 ' + index.turns_completed);

const SEED = state.world_seed;
const r1 = x => Math.round(x * 10) / 10;
const money = n => (state.player.money = r1(state.player.money + n));
const snapshot = () => ({
  time: state.time.display, clock: D.clockOf(state.time),
  stamina: r1(state.player.stamina), copper: state.player.money, hp: state.player.hp,
  grain: D.grainMillidou(state.family),
  progress: state.practice.progress, meridian: state.practice.meridian, layer: state.practice.layer,
});
const evId = n => 'EV' + String(n).padStart(6, '0');
const writeAll = () => {
  writeFileSync(join(root, 'game_state.json'), JSON.stringify(state, null, 2) + '\n');
  writeFileSync(join(root, 'events.jsonl'), events.map(e => JSON.stringify(e)).join('\n') + '\n');
  writeFileSync(join(root, 'campaign_index.json'), JSON.stringify(index, null, 2) + '\n');
};
function commit(action, meta, mutator) {
  const prev = JSON.parse(JSON.stringify(state));
  const prevSnap = snapshot();
  const receipts = [];
  const extra = mutator(receipts) || {};
  state.player.stamina = r1(state.player.stamina);
  const after = snapshot();
  if (state.player.stamina < 0) throw Error('STAMINA_NEGATIVE at ' + action + ' ' + state.player.stamina);
  if (state.player.money < 0) throw Error('MONEY_NEGATIVE at ' + action);
  state.last_event_id = evId(events.length + 1);
  const event = {
    seq: events.length + 1, prev_hash: events.at(-1).hash, type: 'turn_committed',
    turn_id: index.turns_completed + 1, action, rule_version: meta.rule,
    place: meta.place || state.current_location,
    duration_minutes: after.clock - prevSnap.clock,
    ...extra, receipts,
    before: { time: prevSnap.time, stamina: prevSnap.stamina, copper: prevSnap.copper,
              grain_millidou: prevSnap.grain, progress: prevSnap.progress, meridian: prevSnap.meridian },
    after: { time: after.time, stamina: after.stamina, copper: after.copper,
             grain_millidou: after.grain, progress: after.progress, meridian: after.meridian },
    state_hash: digest(state),
  };
  event.gm_audit = auditProposedTurn({
    before: prev, after: state, action: { kind: action, consumes_time: true },
    adjudication: {
      action_succeeded: extra.action_succeeded !== false,
      narrated_success: extra.narrated_success === true,
      money_source: extra.money_source || null, money_sink: extra.money_sink || null,
      special_player_bonus: false, forced_player_disaster: false, npc_used_hidden_player_info: false,
    },
  });
  if (!event.gm_audit.accepted) throw Error('GM门禁拒绝 ' + action + ': ' + JSON.stringify(event.gm_audit.issues));
  event.hash = digest(Object.fromEntries(Object.entries(event).filter(([k]) => k !== 'hash')));
  events.push(event);
  index.turns_completed = event.turn_id;
  index.last_event = evId(event.seq);
  index.last_event_hash = event.hash;
  index.full_state_sha256 = digest(state);
  index.time = state.time.display;
  index.location = state.current_location;
  index.player = { ...index.player, hp: state.player.hp, stamina: state.player.stamina,
                   copper: state.player.money, realm: state.player.realm, root: state.player.root_status };
  index.family = { ...index.family, cash: state.family.cash, grain_dou: state.family.grain_dou,
                   grain_remainder_millidou: state.family.grain_remainder_millidou };
  index.sync_status = 'PENDING_GITHUB';
  index.last_action = action;
  if (event.turn_id % 10 === 0) { writeAll(); checkpoint(root); reviewAtTurn(root); console.log('checkpoint', event.turn_id); }
  return event;
}
const nowClock = () => D.clockOf(state.time) % 1440;
const waitTo = (clock, receipts, reason) => {
  const d = clock - nowClock();
  if (d > 0) { D.advanceTime(state.time, d); receipts.push({ effect: 'wait', minutes: d, reason }); }
};
const spendStamina = (minutes, rate, receipts, reason) => {
  const cost = r1(minutes / 60 * rate);
  state.player.stamina -= cost;
  receipts.push({ effect: 'stamina', reason, cost, minutes });
  return cost;
};
const WALK_RATE = J.WALK.staminaPerMinute * 60;

// 药草库存
const addHerb = (h, receipts) => {
  const it = state.inventory.find(i => i.id === h.id);
  if (it) it.quantity += 1;
  else state.inventory.push({ id: h.id, name: h.name, quantity: 1, equipped: false, category: '药材', source: '自己在村外采的' });
  receipts.push({ effect: 'herb_gained', id: h.id, name: h.name, tier: h.tier, price_copper: h.price_copper });
};
const herbStock = () => state.inventory.filter(i => i.category === '药材' && i.quantity > 0);

// ── 第31日：先摸路子 ──
commit('ask_around_about_herb_gathering', { rule: 'herb-forage-1.0.0' }, (rc) => {
  D.dayRollover(state, 31);
  const bf = D.meal(state, 'breakfast', 4); rc.push({ effect: 'meal', ...bf });
  spendStamina(50, 2.4, rc, '蹲在灶边跟母亲和隔壁婶子问话'); D.advanceTime(state.time, 50);
  rc.push({ effect: 'note', who: 'CFNPC00002', said: '采药？你太爷爷干过。北坡、溪湾、东头林子，三处轮着走，一天能跑完。' });
  rc.push({ effect: 'note', who: 'CFNPC00002', said: '别指望发家。好药都长在人家圈起来的地里，剩下的都是不值钱的。' });
  rc.push({ effect: 'note', who: 'CFNPC00003', said: '哥我跟你去，我认草比你快。' });
  rc.push({ effect: 'note', who: 'PC', said: '你在家。爹说过。' });
  index.forage_status = { discovered_sites: H.SITES.map(s => s.id), learned_from: 'CFNPC00002', day: 31 };
  return { note: '从母亲和婶子那儿问清了村外三处采药的去处' };
});

// ── 采药日 ──
const forageDay = (dayNo, note) => commit('gather_herbs_in_the_outskirts', { rule: 'herb-forage-1.0.0' }, (rc) => {
  D.dayRollover(state, dayNo);
  const bf = D.meal(state, 'breakfast', 4); rc.push({ effect: 'meal', ...bf });
  spendStamina(15, 2.4, rc, '收拾背篓、吃早饭'); D.advanceTime(state.time, 15);
  let found = 0, spirit = 0;
  for (const s of H.SITES) {
    spendStamina(s.walk_minutes, WALK_RATE, rc, '走到' + s.name); D.advanceTime(state.time, s.walk_minutes);
    const res = H.forageRoll(SEED, s.id, dayNo);
    spendStamina(s.search_minutes, s.search_stamina / s.search_minutes * 60, rc, '在' + s.name + '翻找'); D.advanceTime(state.time, s.search_minutes);
    rc.push({ effect: 'forage', site: s.id, site_name: s.name, roll: res.roll, band: res.band, found: res.items.map(i => i.name) });
    for (const h of res.items) { addHerb(h, rc); found++; if (h.tier !== 'mortal') spirit++; }
  }
  spendStamina(20, WALK_RATE, rc, '背着篓子回家'); D.advanceTime(state.time, 20);
  const lunch = D.meal(state, 'lunch', 4); rc.push({ effect: 'meal', ...lunch });
  spendStamina(60, 2.4, rc, '把药材摊在院里晾，捡去杂质'); D.advanceTime(state.time, 60);
  return { note: note || `在村外三处采了一趟，得 ${found} 份药材，其中 ${spirit} 份带灵气`, herbs_found: found, spirit_found: spirit };
});

const evening = (dayNo, note) => commit('supper_and_sleep', { rule: 'daily-cycle-1.0.0' }, (rc) => {
  waitTo(1080, rc, '等晚饭');
  const dinner = D.meal(state, 'dinner', 4); rc.push({ effect: 'meal', ...dinner });
  const sle = D.sleep(state, { untilClock: 360 }); rc.push({ effect: 'sleep', ...sle });
  D.dayRollover(state, dayNo + 1);
  return { note: note || '吃过晚饭就睡了' };
});

// 第31日下午第一次下地
commit('first_herb_gathering_afternoon', { rule: 'herb-forage-1.0.0' }, (rc) => {
  const s = H.site('SH-SLOPE-N-01');
  spendStamina(s.walk_minutes, WALK_RATE, rc, '走到' + s.name); D.advanceTime(state.time, s.walk_minutes);
  const res = H.forageRoll(SEED, s.id, 31);
  spendStamina(s.search_minutes, s.search_stamina / s.search_minutes * 60, rc, '在乱石坡翻找'); D.advanceTime(state.time, s.search_minutes);
  rc.push({ effect: 'forage', site: s.id, site_name: s.name, roll: res.roll, band: res.band, found: res.items.map(i => i.name) });
  for (const h of res.items) addHerb(h, rc);
  spendStamina(s.walk_minutes, WALK_RATE, rc, '走回家'); D.advanceTime(state.time, s.walk_minutes);
  return { note: '下午先去北坡试了一趟', herbs_found: res.items.length };
});
evening(31, '第一天尝到了味道：弯腰三百次，换来一把草根');

// ── 第32-38日：天天采 ──
for (let d = 32; d <= 38; d++) { forageDay(d); evening(d); }

// ── 第39日：进城卖 ──
const sellToLinanStall = (dayNo) => commit('sell_herbs_at_linan_stall', { rule: 'herb-forage-1.0.0' }, (rc) => {
  D.dayRollover(state, dayNo);
  const bf = D.meal(state, 'breakfast', 4); rc.push({ effect: 'meal', ...bf });
  spendStamina(15, 2.4, rc, '装篓、出门'); D.advanceTime(state.time, 15);
  const l = J.leg('shiqiao-linan');
  spendStamina(l.minutes, WALK_RATE, rc, '走官道进城'); D.advanceTime(state.time, l.minutes);
  state.current_location = '临安县城·西市'; state.location_id = 'linan'; state.position = { x: 0, y: 0 };
  const stallCash = J.stallCashToday(SEED, dayNo, 18);
  // 把库存摊平成一株一份，按座位顺序卖，直到摊主的钱花光
  const flat = [];
  for (const it of herbStock()) {
    const tier = H.HERBS.mortal.some(x => x.id === it.id) ? 'mortal'
      : H.HERBS.spirit.some(x => x.id === it.id) ? 'spirit' : 'rare';
    const base = H.HERBS[tier].find(x => x.id === it.id).price_copper;
    const factor = tier === 'mortal' ? 1 : H.MARKET.linan_herb_stall.spirit_price_factor;
    for (let k = 0; k < it.quantity; k++) flat.push({ id: it.id, tier, paid: Math.floor(base * factor), base });
  }
  let budget = stallCash, sold = [];
  for (const it of flat) { if (it.paid > budget) break; budget -= it.paid; sold.push(it); }
  const paid = stallCash - budget;
  for (const it of sold) { const inv = state.inventory.find(i => i.id === it.id); if (inv) inv.quantity -= 1; }
  money(paid);
  rc.push({ effect: 'sale', venue: 'linan_herb_stall', offered: flat.reduce((a, x) => a + x.paid, 0),
            paid, stall_cash: stallCash, sold: sold.length, left: flat.length - sold.length });
  spendStamina(20, 2.4, rc, '讨价还价'); D.advanceTime(state.time, 20);
  rc.push({ effect: 'note', who: 'stall_keeper', said: '你这篓子我一天也卖不完。剩下的拿回去，明天再来。' });
  return { note: '把凡草卖给西市药材摊，摊主只收得下这么多', action_succeeded: true,
           money_source: '卖出药材 ' + sold.length + ' 份（临安西市药材摊，当日现钱 ' + stallCash + ' 文）' };
});

const walkHome = (dayNo) => commit('walk_home_from_linan', { rule: 'road-travel-1.0.0' }, (rc) => {
  const l = J.leg('shiqiao-linan');
  spendStamina(l.minutes, WALK_RATE, rc, '走回石桥村'); D.advanceTime(state.time, l.minutes);
  state.current_location = '石桥村·钱家院落'; state.location_id = 'shiqiao'; state.position = { x: 3867, y: 5009 };
  return { note: '天黑前回到家' };
});

sellToLinanStall(39);
walkHome(39);
evening(39, '钱袋沉了一点，可灵草一斤也没卖上价 —— 摊主压根不认灵气');

// ── 第40-45日：再采六天 ──
for (let d = 40; d <= 45; d++) { forageDay(d); evening(d); }

// ── 第46日：碰到收药的散修，把灵草按高价出手 ──
commit('meet_an_itinerant_herb_buyer', { rule: 'herb-forage-1.0.0' }, (rc) => {
  D.dayRollover(state, 46);
  const bf = D.meal(state, 'breakfast', 4); rc.push({ effect: 'meal', ...bf });
  spendStamina(15, 2.4, rc, '装篓、出门'); D.advanceTime(state.time, 15);
  const l = J.leg('shiqiao-linan');
  spendStamina(l.minutes, WALK_RATE, rc, '走官道进城'); D.advanceTime(state.time, l.minutes);
  state.current_location = '临安县城·西市'; state.location_id = 'linan'; state.position = { x: 0, y: 0 };
  const key = randomKeyOf(state);
  if (!state.known_npcs.some(n => n.id === 'CFNPC00010')) {
    const npc = { id: 'CFNPC00010', name: npcName(key, 'herb-buyer.linan'),
      relation: '跑灵山药市的收药散修', sex: '男', age: npcAge(key, 'herb-buyer.linan', 30, 16),
      location_id: 'linan', health: '正常', alive: true };
    state.known_npcs.push(npc); rc.push({ effect: 'known_npc', ...npc });
  }
  const buyer = state.known_npcs.find(n => n.id === 'CFNPC00010');
  spendStamina(40, 2.4, rc, '蹲在摊子边上等收药的人'); D.advanceTime(state.time, 40);
  const flat = [];
  for (const it of herbStock()) {
    const sp = H.HERBS.spirit.find(x => x.id === it.id) || H.HERBS.rare.find(x => x.id === it.id);
    if (!sp) continue;
    const tier = H.HERBS.spirit.some(x => x.id === it.id) ? 'spirit' : 'rare';
    const paid = Math.floor(sp.price_copper * 0.85);
    for (let k = 0; k < it.quantity; k++) flat.push({ id: it.id, tier, paid });
  }
  let budget = 200, sold = [];
  for (const it of flat) { if (it.paid > budget) break; budget -= it.paid; sold.push(it); }
  const paidTotal = 200 - budget;
  for (const it of sold) { const inv = state.inventory.find(i => i.id === it.id); if (inv) inv.quantity -= 1; }
  money(paidTotal);
  rc.push({ effect: 'sale', venue: 'itinerant_buyer', sold: sold.length,
            paid: paidTotal, offered: flat.reduce((x, y) => x + y.paid, 0), buyer: 'CFNPC00010' });
  spendStamina(30, 2.4, rc, '跟他说话'); D.advanceTime(state.time, 30);
  rc.push({ effect: 'note', who: 'CFNPC00010', said: '灵草我收。县城那摊子不识货，你卖给他等于白送。' });
  rc.push({ effect: 'note', who: 'CFNPC00010', said: '我十天半月往灵山跑一趟。那边按株论价，比你在这儿多两成。' });
  rc.push({ effect: 'note', who: 'PC', said: '灵山那边自己采不行？' });
  rc.push({ effect: 'note', who: 'CFNPC00010', said: '灵田边角有主。偷采抓着了，罚的钱够你买半本功法。' });
  rc.push({ effect: 'note', who: 'CFNPC00010', said: '药市上《引气初篇》正本两百文，一块灵石。你手上多少？' });
  rc.push({ effect: 'note', who: 'PC', said: '……不够。' });
  index.forage_status = { ...index.forage_status, met_buyer: 'CFNPC00010', day: 46,
    known_prices: { qi_primer_genuine_copper: 200, appraisal_copper: 5, low_grade_stone_copper: 200 } };
  return { note: '在西市碰上一个跑灵山药市的收药散修，灵草按八五折出手', action_succeeded: true,
           money_source: '卖灵草给收药散修 ' + buyer.name + '（八五折，' + paidTotal + ' 文）' };
});
walkHome(46);
evening(46, '知道了正本功法的价钱：两百文。袋里的钱差不多还差一半');

writeAll();
const final = inspect(root);
const herbs = herbStock().map(i => `${i.name}×${i.quantity}`).join('、') || '无';
console.log(JSON.stringify({
  turns: final.turns, last_event: index.last_event, verified: final.full_state_verified,
  time: state.time.display, money: state.player.money, stamina: state.player.stamina,
  herbs_left: herbs, grain: D.grainMillidou(state.family), npcs: state.known_npcs.length,
}, null, 1));
