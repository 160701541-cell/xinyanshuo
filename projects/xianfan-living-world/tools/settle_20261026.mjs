// 《仙凡·苍岚》第一世：第8日午间至第20日的结算
// 玩家方向：攒一笔来回盘缠，去青云/灵山测灵根。
// 只追加 EV000032 起的新回合，不改动既有事件。
// 用法：node tools/settle_20261026.mjs <战役目录>
import { readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { digest, verifyEvents, countTurns, inspect, checkpoint } from './campaign_guard.mjs';
import { auditProposedTurn, reviewAtTurn } from './gm_quality_gate.mjs';
import * as D from './daily_cycle.mjs';
import * as J from './journey_and_earn.mjs';
import { inherentTemperament } from './npc_identity.mjs';

const root = process.argv[2];
if (!root) throw Error('缺战役目录');
const read = n => JSON.parse(readFileSync(join(root, n), 'utf8'));
const readLines = n => readFileSync(join(root, n), 'utf8').split(/\r?\n/).filter(Boolean).map(JSON.parse);

const st = J.selfTest();
if (!st.ok) throw Error('路程/渔猎规则自测失败 ' + JSON.stringify(st.failed));

const state = read('game_state.json');
const index = read('campaign_index.json');
const events = readLines('events.jsonl');
const memory = read('story_memory_public.json');
const registry = read('npc_registry.json');

verifyEvents(events);
if (index.turns_completed !== countTurns(events)) throw Error('索引与事件轮数不符');
if (state.last_event_id !== index.last_event) throw Error('状态与索引事件不同步');
if (digest(state) !== index.full_state_sha256) throw Error('状态哈希与索引不符');
if (index.turns_completed !== 29) throw Error('本脚本只接第29轮之后；当前 ' + index.turns_completed);

const SEED = state.world_seed;
const r1 = x => Math.round(x * 10) / 10;
const ECO = state.ecology['shiqiao-outskirts-v1'].freshwater;
const STOCK = ECO.stocks.find(s => s.id === 'small_cyprinid');
const GEAR_A = 'GEAR-SH-RIVER-0001';
const GEAR_B = 'GEAR-SH-RIVER-0002';

const receiptsAll = [];
const snapshot = () => ({
  time: state.time.display, clock: D.clockOf(state.time),
  stamina: r1(state.player.stamina), copper: state.player.money, hp: state.player.hp,
  grain: D.grainMillidou(state.family),
  progress: state.practice.progress, meridian: state.practice.meridian, layer: state.practice.layer,
  fish_stock: STOCK.population,
  fish_held: (state.inventory.find(i => i.id === 'river_fish') || { quantity: 0 }).quantity,
});
const evId = n => 'EV' + String(n).padStart(6, '0');
const writeAll = () => {
  writeFileSync(join(root, 'game_state.json'), JSON.stringify(state, null, 2) + '\n');
  writeFileSync(join(root, 'events.jsonl'), events.map(e => JSON.stringify(e)).join('\n') + '\n');
  writeFileSync(join(root, 'campaign_index.json'), JSON.stringify(index, null, 2) + '\n');
};
const checkpoints = [];
function commit(action, meta, mutator) {
  const prev = JSON.parse(JSON.stringify(state));
  const prevSnap = snapshot();
  const receipts = [];
  const extra = mutator(receipts) || {};
  state.player.stamina = r1(state.player.stamina);
  const after = snapshot();
  if (state.player.stamina < 0) throw Error('STAMINA_NEGATIVE at ' + action);
  state.last_event_id = evId(events.length + 1);
  const event = {
    seq: events.length + 1,
    prev_hash: events.at(-1).hash,
    type: 'turn_committed',
    turn_id: index.turns_completed + 1,
    action,
    rule_version: meta.rule,
    place: meta.place || state.current_location,
    duration_minutes: after.clock - prevSnap.clock,
    ...extra,
    receipts,
    before: { time: prevSnap.time, stamina: prevSnap.stamina, copper: prevSnap.copper,
              grain_millidou: prevSnap.grain, progress: prevSnap.progress, meridian: prevSnap.meridian },
    after: { time: after.time, stamina: after.stamina, copper: after.copper,
             grain_millidou: after.grain, progress: after.progress, meridian: after.meridian },
    state_hash: digest(state),
  };
  event.gm_audit = auditProposedTurn({
    before: prev, after: state,
    action: { kind: action, consumes_time: true },
    adjudication: {
      action_succeeded: extra.action_succeeded !== false,
      narrated_success: extra.narrated_success === true,
      money_source: extra.money_source || null,
      money_sink: extra.money_sink || null,
      special_player_bonus: false,
      forced_player_disaster: false,
      npc_used_hidden_player_info: false,
    },
  });
  if (!event.gm_audit.accepted) throw Error('GM门禁拒绝 ' + action + ': ' + JSON.stringify(event.gm_audit.issues));
  event.hash = digest(Object.fromEntries(Object.entries(event).filter(([k]) => k !== 'hash')));
  events.push(event);
  receiptsAll.push({ turn: event.turn_id, event_id: evId(event.seq), action,
                     before: event.before, after: event.after, receipts });
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
  if (event.turn_id % 10 === 0) {
    writeAll();
    checkpoints.push({ turn: event.turn_id, checkpoint: checkpoint(root), review: reviewAtTurn(root) });
  }
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
const item = id => state.inventory.find(i => i.id === id);
const addFish = n => { const it = item('river_fish'); it.quantity += n; return it.quantity; };
const dropFish = n => { const it = item('river_fish'); it.quantity -= n; if (it.quantity < 0) throw Error('鱼负数'); return it.quantity; };

function riverMorning(dayNo, receipts) {
  const rec = J.populationMorning(SEED, dayNo, STOCK.population);
  STOCK.population = rec.population;
  receipts.push({ effect: 'river_recovery', day: dayNo, population: STOCK.population, note: rec.note });
  return rec;
}
function checkGear(gearId, dayNo, receipts) {
  const r = J.cageCheck(SEED, dayNo, state.time.weather, gearId, STOCK.population);
  spendStamina(r.minutes, 10, receipts, '收笼 ' + gearId);
  if (r.caught) { STOCK.population -= 1; STOCK.harvested += 1; addFish(1); }
  const gear = ECO.installed_gear.find(g => g.id === gearId);
  if (gear) {
    gear.catch_count += r.caught;
    gear.checked_at = state.time.display;
    gear.last_check_result = r.caught ? 'removed_retained_fish' : 'empty';
  }
  receipts.push({ effect: 'cage_check', gear: gearId, weather: state.time.weather,
                  roll: r.roll, percent: r.percent, caught: r.caught,
                  population_after: STOCK.population, held_after: item('river_fish').quantity });
  return r;
}
function rodSession(dayNo, hours, receipts) {
  let caught = 0;
  for (let h = 0; h < hours; h++) {
    if (STOCK.population <= 0) { receipts.push({ effect: 'rod', hour: h, caught: 0, note: '河段里没鱼了' }); continue; }
    const r = J.rodHour(SEED, dayNo, h, STOCK.population);
    spendStamina(r.minutes, r.stamina, receipts, '下竿第 ' + (h + 1) + ' 个时辰');
    if (r.caught) { STOCK.population -= 1; STOCK.harvested += 1; addFish(1); }
    receipts.push({ effect: 'rod', hour: h, roll: r.roll, caught: r.caught, population_after: STOCK.population });
    caught += r.caught;
  }
  return caught;
}
function sellFish(qty, stall, receipts, note) {
  const cash = J.stallCashToday(SEED, state.time.day, 15);
  const res = J.sell(stall, 'river_fish', qty, cash);
  if (res.sold > 0) { dropFish(res.sold); state.player.money += res.copper; }
  receipts.push({ effect: 'sell', item: 'river_fish', wanted: qty, sold: res.sold, price: res.price,
                  copper: res.copper, stall_cash_before: cash, stall_cash_after: res.cashAfter,
                  refused: res.refused, note });
  return res;
}

function ruralDay(dayNo, opts = {}) {
  D.dayRollover(state, dayNo);
  commit('rural_morning_river_work', { rule: 'daily-cycle-1.0.0 + fishing-1.0.0' }, (rc) => {
    const meal = D.meal(state, 'breakfast', 4); rc.push({ effect: 'meal', ...meal });
    spendStamina(30, 4, rc, '挑水、扫院、喂鸡'); D.advanceTime(state.time, 30);
    spendStamina(12, 10, rc, '走河堤'); D.advanceTime(state.time, 12);
    riverMorning(dayNo, rc);
    const a = checkGear(GEAR_A, dayNo, rc); D.advanceTime(state.time, 12);
    const b = checkGear(GEAR_B, dayNo, rc); D.advanceTime(state.time, 12);
    const caught = rodSession(dayNo, 3, rc);
    spendStamina(12, 10, rc, '走回家'); D.advanceTime(state.time, 12);
    return { note: opts.morningNote || '天没亮透就下河，两只笼子挨个提起来看',
             cage_a: a.caught, cage_b: b.caught, rod_caught: caught };
  });
  commit('rural_field_and_evening_meal', { rule: 'daily-cycle-1.0.0' }, (rc) => {
    spendStamina(87, 6, rc, '自留地里除草、起垄'); D.advanceTime(state.time, 87);
    const lunch = D.meal(state, 'lunch', 4); rc.push({ effect: 'meal', ...lunch });
    spendStamina(240, 6, rc, '跟着父亲修渠、挑土'); D.advanceTime(state.time, 240);
    spendStamina(90, 2, rc, '劈柴、收拾农具'); D.advanceTime(state.time, 90);
    waitTo(1080, rc, '等晚饭');
    const dinner = D.meal(state, 'dinner', 4); rc.push({ effect: 'meal', ...dinner });
    return { note: opts.middayNote || '白天在地里，晚上回家吃饭' };
  });
  return commit('evening_and_sleep', { rule: 'daily-cycle-1.0.0' }, (rc) => {
    spendStamina(180, 1.33, rc, '晚上在家'); D.advanceTime(state.time, 180);
    const sle = D.sleep(state, { untilClock: 360 }); rc.push({ effect: 'sleep', ...sle });
    D.dayRollover(state, state.time.day);
    return { note: opts.nightNote || '熄灯睡了' };
  });
}
const sleepOnly = (note) => commit('sleep', { rule: 'daily-cycle-1.0.0' }, (rc) => {
  const sle = D.sleep(state, { untilClock: 360 }); rc.push({ effect: 'sleep', ...sle });
  D.dayRollover(state, state.time.day);
  return { note: note || '睡下' };
});

// ══ 第8日 12:30 起 ══
commit('tell_family_about_root_test', { rule: 'root-test-1.0.0' }, (rc) => {
  spendStamina(35, 3.4, rc, '坐在门槛上跟父母说这件事'); D.advanceTime(state.time, 35);
  rc.push({ effect: 'note', who: 'CFNPC00001', said: '测那玩意儿做什么？你爷爷种了一辈子地，没测过也活到七十三。' });
  rc.push({ effect: 'note', who: 'CFNPC00002', said: '要去也不是不行……可钱从哪儿来？家里这点钱留着过冬。' });
  rc.push({ effect: 'note', who: 'PC', said: '我自己攒。' });
  return { note: '跟父母摊开说了要去青云测灵根；父亲不认，母亲没拦也没应，只问钱从哪儿来' };
});
commit('afternoon_field_labor', { rule: 'day2-home-and-county-1.0' }, (rc) => {
  spendStamina(265, 6, rc, '下午下田'); D.advanceTime(state.time, 265);
  return { note: '下午没再多说，埋头干活；父亲也没再提' };
});
commit('dinner_and_sister_talk', { rule: 'daily-cycle-1.0.0' }, (rc) => {
  waitTo(1080, rc, '等晚饭');
  const dinner = D.meal(state, 'dinner', 4); rc.push({ effect: 'meal', ...dinner });
  spendStamina(180, 1.33, rc, '夜里在院子里坐着'); D.advanceTime(state.time, 180);
  rc.push({ effect: 'note', who: 'CFNPC00003', said: '哥，你要真去了，那本破册子我收着，等你回来烧了它。' });
  rc.push({ effect: 'note', who: 'CFNPC00003', said: '攒钱我能帮——河边那只笼子我去收，你下地。' });
  return { note: '晚饭桌上谁都没提测灵根的事；饭后妹妹在院里这样说' };
});
sleepOnly('回屋睡了');

// ══ 第9日 ══
ruralDay(9, { morningNote: '妹妹真来了河边，蹲在岸上看着笼子出水',
              nightNote: '把鱼养在水盆里，数了数，还嫌少' });

// ══ 第10日：第一次进城 ══
D.dayRollover(state, 10);
commit('walk_to_county_to_sell', { rule: 'road-travel-1.0.0' }, (rc) => {
  const meal = D.meal(state, 'breakfast', 4); rc.push({ effect: 'meal', ...meal });
  const r = J.leg('shiqiao-linan');
  spendStamina(r.minutes, J.WALK.staminaPerMinute * 60, rc, '走官道进城');
  D.advanceTime(state.time, r.minutes);
  return { note: '天刚亮就出门，鱼用湿草裹着提在手里', leg: r };
});
commit('sell_first_batch_at_produce_stall', { rule: 'fishing-1.0.0' }, (rc) => {
  spendStamina(30, 2, rc, '在市场里找摊子、讲价'); D.advanceTime(state.time, 30);
  const res = sellFish(item('river_fish').quantity, 'PRODUCE', rc, '菜肉摊老板挑了两条小的，说这季节鱼不肥');
  return { note: '第一次把攒的鱼换成铜钱', money_source: '卖出小河鱼', sold: res.sold, copper: res.copper };
});
commit('ask_about_qingyun_road', { rule: 'road-travel-1.0.0' }, (rc) => {
  spendStamina(80, 1.5, rc, '在街上问路、进旧书铺打听'); D.advanceTime(state.time, 80);
  rc.push({ effect: 'note', who: 'linan-street', said: '青云山门在东北，出北门走山道，脚程好的一天能到；到不了的半路有脚店，八文一晚。' });
  rc.push({ effect: 'note', who: 'linan-street', said: '测灵根先得掏钱，山门那边收三十文，叫过门钱。药市便宜五文，可路更远。' });
  return { note: '打听到：青云山门三十文，一天脚程；药市二十五文但更远；半路脚店八文一晚' };
});
commit('walk_home_from_county', { rule: 'road-travel-1.0.0' }, (rc) => {
  const r = J.leg('shiqiao-linan');
  spendStamina(r.minutes, J.WALK.staminaPerMinute * 60, rc, '走回石桥村');
  D.advanceTime(state.time, r.minutes);
  return { note: '带着空鱼篓走回来', leg: r };
});
commit('afternoon_chores_after_county', { rule: 'daily-cycle-1.0.0' }, (rc) => {
  const lunch = D.meal(state, 'lunch', 4); rc.push({ effect: 'meal', ...lunch });
  spendStamina(240, 6, rc, '补上上午欠的农活'); D.advanceTime(state.time, 240);
  spendStamina(60, 2, rc, '收拾'); D.advanceTime(state.time, 60);
  waitTo(1080, rc, '等晚饭');
  const dinner = D.meal(state, 'dinner', 4); rc.push({ effect: 'meal', ...dinner });
  return { note: '下午把上午欠的活补上' };
});
sleepOnly();

// ══ 第11-14日 ══
ruralDay(11, { morningNote: '妹妹抢先跑到下游看那只笼子，回来时袖子湿了半截' });
ruralDay(12, { morningNote: '下过一阵雨，河面起了泥色' });
ruralDay(13, { nightNote: '夜里在院里算账：一条鱼三文，来回脚程两趟，还差得远' });
ruralDay(14, { morningNote: '笼子里一只都没有，妹妹说水太凉了' });

// ══ 第15日：第二次进城 ══
D.dayRollover(state, 15);
commit('walk_to_county_second_trip', { rule: 'road-travel-1.0.0' }, (rc) => {
  const meal = D.meal(state, 'breakfast', 4); rc.push({ effect: 'meal', ...meal });
  const r = J.leg('shiqiao-linan');
  spendStamina(r.minutes, J.WALK.staminaPerMinute * 60, rc, '走官道进城');
  D.advanceTime(state.time, r.minutes);
  return { note: '第二次进城，篓子比上次沉一点', leg: r };
});
commit('sell_second_batch_at_produce_stall', { rule: 'fishing-1.0.0' }, (rc) => {
  spendStamina(30, 2, rc, '找摊子、讲价'); D.advanceTime(state.time, 30);
  const res = sellFish(item('river_fish').quantity, 'PRODUCE', rc, '还是那个摊子，老板认得他了');
  return { note: '第二次换钱', money_source: '卖出小河鱼', sold: res.sold, copper: res.copper };
});
commit('ask_about_wages_and_provisions', { rule: 'road-travel-1.0.0' }, (rc) => {
  spendStamina(45, 2, rc, '在粮行与码头问价'); D.advanceTime(state.time, 45);
  rc.push({ effect: 'note', who: 'linan-grain', said: '要出远门？路上买一份饼四文，自己带省一半。' });
  rc.push({ effect: 'note', who: 'linan-dock', said: '县城扛包一天两文，管一顿；想挣快的，去药市给灵植夫打下手，人家按月给，可先得走到那儿。' });
  return { note: '问到两条路：县城扛包一天两文；药市灵植夫按月给六十文，但要先走到' };
});
commit('walk_home_second_trip', { rule: 'road-travel-1.0.0' }, (rc) => {
  const r = J.leg('shiqiao-linan');
  spendStamina(r.minutes, J.WALK.staminaPerMinute * 60, rc, '走回石桥村');
  D.advanceTime(state.time, r.minutes);
  return { note: '回家', leg: r };
});
commit('afternoon_chores_second_trip', { rule: 'daily-cycle-1.0.0' }, (rc) => {
  const lunch = D.meal(state, 'lunch', 4); rc.push({ effect: 'meal', ...lunch });
  spendStamina(240, 6, rc, '下田'); D.advanceTime(state.time, 240);
  spendStamina(60, 2, rc, '收拾'); D.advanceTime(state.time, 60);
  waitTo(1080, rc, '等晚饭');
  const dinner = D.meal(state, 'dinner', 4); rc.push({ effect: 'meal', ...dinner });
  return { note: '下午下田' };
});
sleepOnly();

// ══ 第16-19日：连着四天，日子没什么不同 ══
ruralDay(16, { morningNote: '天没亮就起了，院里结着霜' });
ruralDay(17, { morningNote: '竿子换了根线，还是那根竿' });
ruralDay(18, { morningNote: '妹妹在岸上数：盆里已经四条了' });
ruralDay(19, { nightNote: '把铜钱倒在桌上数了三遍，二十文出头' });

// ══ 第20日：父亲松口 ══
D.dayRollover(state, 20);
commit('rural_morning_river_work', { rule: 'daily-cycle-1.0.0 + fishing-1.0.0' }, (rc) => {
  const meal = D.meal(state, 'breakfast', 4); rc.push({ effect: 'meal', ...meal });
  spendStamina(30, 4, rc, '挑水、扫院、喂鸡'); D.advanceTime(state.time, 30);
  spendStamina(12, 10, rc, '走河堤'); D.advanceTime(state.time, 12);
  riverMorning(20, rc);
  const a = checkGear(GEAR_A, 20, rc); D.advanceTime(state.time, 12);
  const b = checkGear(GEAR_B, 20, rc); D.advanceTime(state.time, 12);
  const caught = rodSession(20, 3, rc);
  spendStamina(12, 10, rc, '走回家'); D.advanceTime(state.time, 12);
  return { note: '照旧的一天', cage_a: a.caught, cage_b: b.caught, rod_caught: caught };
});
commit('field_labor_before_father_decides', { rule: 'daily-cycle-1.0.0' }, (rc) => {
  spendStamina(87, 6, rc, '自留地'); D.advanceTime(state.time, 87);
  const lunch = D.meal(state, 'lunch', 4); rc.push({ effect: 'meal', ...lunch });
  spendStamina(240, 6, rc, '修渠、挑土'); D.advanceTime(state.time, 240);
  spendStamina(90, 2, rc, '劈柴'); D.advanceTime(state.time, 90);
  waitTo(1080, rc, '等晚饭');
  return { note: '渠修到最后一段' };
});
commit('father_offers_part_of_household_cash', { rule: 'daily-cycle-1.0.0' }, (rc) => {
  const dinner = D.meal(state, 'dinner', 4); rc.push({ effect: 'meal', ...dinner });
  const before = state.family.cash;
  const give = 20;
  state.family.cash = before - give;
  state.player.money += give;
  rc.push({ effect: 'cash_transfer', from: 'CFFAM00001', to: 'PC', copper: give,
            household_cash_before: before, household_cash_after: state.family.cash,
            note: '父亲从家里现钱里数出二十文' });
  spendStamina(90, 1.33, rc, '在饭桌上把话说开'); D.advanceTime(state.time, 90);
  rc.push({ effect: 'note', who: 'CFNPC00001', said: '这钱不是给你玩的。你把这一个月的活都干完了，我看见了。' });
  rc.push({ effect: 'note', who: 'CFNPC00001', said: '但你得把话说清楚：测出来没那东西，回来就老老实实种地，别再买那些破册子。' });
  rc.push({ effect: 'note', who: 'CFNPC00002', said: '路上别赶夜路。' });
  rc.push({ effect: 'note', who: 'CFNPC00003', said: '哥，我陪你去。' });
  rc.push({ effect: 'note', who: 'CFNPC00001', said: '她不许去。一个丫头片子，走那么远的山路做什么。' });
  return { note: '晚饭桌上父亲数出二十文，把话说明：测不出就回来种地；妹妹要跟着，被父亲一口回绝',
           money_source: '家庭现金（父亲钱然泽）',
           dialogue_rejections: ['妹妹请求同去，被父亲当场驳回'] };
});
sleepOnly();

// ══ 第21-27日：河已经被捞空了，一天只能等一条 ══
const notes21 = [
  ['第21日：笼子提起来是空的，河底的石头都看清了',
   '第21日夜里：母亲说了一句"河里的鱼也是有数的"'],
  ['第22日：上游游进来一条，抓住的时候手都是抖的', null],
  ['第23日：还是只有一条。明白了，这条河一天只供得起一条', null],
  ['第24日：竿子收了，只剩笼子。守一天换三文，比什么都难看清楚', null],
  ['第25日：照旧一条', '第25日夜里：妹妹说，要是那条河会说话，肯定在骂你'],
  ['第26日：下了一天雨，只等到半条——其实是条小的，摊主未必肯收', null],
  ['第27日：攒到最后一个铜板，明天进城', '第27日夜里：把钱串好，数了两遍'],
];
for (const [idx, dayNo] of [21, 22, 23, 24, 25, 26, 27].entries()) {
  const [m, n] = notes21[idx];
  ruralDay(dayNo, { morningNote: m, nightNote: n || undefined });
}

// ══ 第28日：第三次进城，把最后一批换成钱 ══
D.dayRollover(state, 28);
commit('walk_to_county_final_batch', { rule: 'road-travel-1.0.0' }, (rc) => {
  const meal = D.meal(state, 'breakfast', 4); rc.push({ effect: 'meal', ...meal });
  const r = J.leg('shiqiao-linan');
  spendStamina(r.minutes, J.WALK.staminaPerMinute * 60, rc, '走官道进城');
  D.advanceTime(state.time, r.minutes);
  return { note: '最后一次进城，篓子最沉，人最轻', leg: r };
});
commit('sell_final_batch_at_produce_stall', { rule: 'fishing-1.0.0' }, (rc) => {
  spendStamina(30, 2, rc, '找摊子、讲价'); D.advanceTime(state.time, 30);
  const res = sellFish(item('river_fish').quantity, 'PRODUCE', rc, '老板说收不下这么多，只肯要五条，剩下的让他改日再说');
  return { note: '最后一次换钱，摊主现钱有限，没能全卖完', money_source: '卖出小河鱼',
           sold: res.sold, copper: res.copper, refused: res.refused };
});
commit('ask_about_departure_hour', { rule: 'road-travel-1.0.0' }, (rc) => {
  spendStamina(40, 2, rc, '在街口问走山道的门道'); D.advanceTime(state.time, 40);
  rc.push({ effect: 'note', who: 'linan-street', said: '走山道要赶早。天不亮出门，到山脚正好天黑，睡一觉第二天上山门。' });
  rc.push({ effect: 'note', who: 'linan-street', said: '干粮自己带，别在路上买。山道上没人家，饿了没处寻。' });
  return { note: '问清出发的时辰与干粮的事' };
});
commit('walk_home_final_batch', { rule: 'road-travel-1.0.0' }, (rc) => {
  const r = J.leg('shiqiao-linan');
  spendStamina(r.minutes, J.WALK.staminaPerMinute * 60, rc, '走回石桥村');
  D.advanceTime(state.time, r.minutes);
  return { note: '回家', leg: r };
});
commit('tell_family_departure_is_set', { rule: 'daily-cycle-1.0.0' }, (rc) => {
  const lunch = D.meal(state, 'lunch', 4); rc.push({ effect: 'meal', ...lunch });
  spendStamina(210, 6, rc, '把地里的活提前做完'); D.advanceTime(state.time, 210);
  spendStamina(60, 2, rc, '收拾行装'); D.advanceTime(state.time, 60);
  waitTo(1080, rc, '等晚饭');
  const dinner = D.meal(state, 'dinner', 4); rc.push({ effect: 'meal', ...dinner });
  spendStamina(120, 1.33, rc, '饭桌上把日子定下来'); D.advanceTime(state.time, 120);
  rc.push({ effect: 'note', who: 'PC', said: '明天天亮前走。盘缠够了。' });
  rc.push({ effect: 'note', who: 'CFNPC00002', said: '饼我给你烙上，路上别省。' });
  rc.push({ effect: 'note', who: 'CFNPC00003', said: '哥，我送你去村口。' });
  rc.push({ effect: 'note', who: 'CFNPC00001', said: '送到村口就回来。别的事，等他回来再说。' });
  return { note: '晚饭桌上定了日子：第29日天亮前动身，去青云山门测灵根',
           decision: 'departure_set_for_day_29_before_dawn',
           sister_request: '只准送到村口' };
});
sleepOnly('躺下，听着院外的风声');
writeAll();
console.log(JSON.stringify({ stage: 'day28', money: state.player.money, fish: item('river_fish').quantity,
  stock: STOCK.population, harvested: STOCK.harvested, turns: index.turns_completed,
  time: state.time.display, household_cash: state.family.cash }, null, 1));
