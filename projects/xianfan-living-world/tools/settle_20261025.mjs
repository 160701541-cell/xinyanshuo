// 《仙凡·苍岚》第一世：第2日晚至第8日的补算结算
// 把上一任 GM 未落地的行动，按已提交的存档、事件链与版本化规则一次性算出并写回权威档案。
// 不修改任何既有事件；只追加 EV000017 起的新回合。
// 用法：node tools/settle_20261025.mjs <战役目录>
import { readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { digest, verifyEvents, countTurns, inspect, checkpoint } from './campaign_guard.mjs';
import { auditProposedTurn, reviewAtTurn } from './gm_quality_gate.mjs';
import * as C from './cultivation_intake.mjs';
import * as D from './daily_cycle.mjs';
import { inherentTemperament } from './npc_identity.mjs';

const root = process.argv[2];
if (!root) throw Error('缺战役目录');
const read = n => JSON.parse(readFileSync(join(root, n), 'utf8'));
const readLines = n => readFileSync(join(root, n), 'utf8').split(/\r?\n/).filter(Boolean).map(JSON.parse);

C.SELF_TEST();

const state = read('game_state.json');
const index = read('campaign_index.json');
const events = readLines('events.jsonl');
const memory = read('story_memory_public.json');
const registry = read('npc_registry.json');
const rolls = read('initial_rolls_public.json');

verifyEvents(events);
if (index.turns_completed !== countTurns(events)) throw Error('索引与事件轮数不符');
if (state.last_event_id !== index.last_event) throw Error('状态与索引事件不同步');
if (digest(state) !== index.full_state_sha256) throw Error('状态哈希与索引不符');
if (index.turns_completed !== 14) throw Error('本脚本只补算第14轮之后的交接缺口；当前 ' + index.turns_completed);

const SEED = state.world_seed;
const PC = 'CFPLAYER00001';
const r1 = x => Math.round(x * 10) / 10;

// ── 灵根承诺校验（私下）：承诺与揭示逐位吻合，否则中断，不许硬编 ──
const ROOT_ROLL = 2938;
const CHAR_SEED = SEED + '|玩家:心魇说|性别:男|年龄:16|开局序号:1';
C.verifyRootReveal(state.player.root_commitment_sha256, state.campaign_id + '|' + CHAR_SEED + '|' + ROOT_ROLL + '|四灵根');
// 四灵根 speed=1.0；玩家未检测，不得写入公开存档
// ── 功法真伪：按预先声明的分布掷骰，结果在第8日玩家自行查证前不落盘 ──
const AUTH = C.manualAuthenticity(SEED, 'weathered_qi_primer', 'CFNPC00008');

if (!state.practice) {
  state.practice = { rootId: null, layer: 0, progress: 0, meridian: 0, tested: false,
                     testedAt: null, manual_status: '尚未得到任何功法', intake_days: 0, log: [] };
}
state.practice.rootId = null;

const receiptsAll = [];
const snapshot = () => ({
  time: state.time.display, clock: D.clockOf(state.time),
  stamina: r1(state.player.stamina), copper: state.player.money, hp: state.player.hp,
  grain: D.grainMillidou(state.family),
  progress: state.practice.progress, meridian: state.practice.meridian, layer: state.practice.layer
});
const evId = n => 'EV' + String(n).padStart(6, '0');

function writeAll() {
  writeFileSync(join(root, 'game_state.json'), JSON.stringify(state, null, 2) + '\n');
  writeFileSync(join(root, 'events.jsonl'), events.map(e => JSON.stringify(e)).join('\n') + '\n');
  writeFileSync(join(root, 'campaign_index.json'), JSON.stringify(index, null, 2) + '\n');
}
const checkpoints = [];
function commit(action, meta, mutator) {
  const prev = JSON.parse(JSON.stringify(state));
  const prevSnap = snapshot();
  const receipts = [];
  const extra = mutator(receipts) || {};
  state.player.stamina = r1(state.player.stamina);
  const after = snapshot();
  if (state.player.stamina < 0) throw Error('STAMINA_NEGATIVE at ' + action);
  state.last_event_id = evId(events.length + 1);   // 先定事件号，再取状态哈希
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
    state_hash: digest(state)
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
      npc_used_hidden_player_info: false
    }
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
    const cp = checkpoint(root);
    const rv = reviewAtTurn(root);
    checkpoints.push({ turn: event.turn_id, checkpoint: cp, review: rv });
  }
  return event;
}
const waitTo = (clock, receipts, reason) => {
  const d = clock - (D.clockOf(state.time) % 1440);
  if (d > 0) { D.advanceTime(state.time, d); receipts.push({ effect: 'wait', minutes: d, reason }); }
};
const staminaOut = (minutes, rate, reason) => ({
  effect: 'stamina', reason, cost: r1(minutes / 60 * rate), minutes
});

// ══════════ 第2日 11:14 – 21:30 ══════════

// T15 街边买书
commit('buy_weathered_qi_primer_from_wayfarer', { rule: 'wayfarer-v1', place: '临安县城·旧书铺街口' },
  receipts => {
    state.known_npcs.push({ id: 'CFNPC00008', name: '钟时云', relation: '游方道人（未通名）',
      sex: '男', age: 40, location_id: 'linan', health: '正常', alive: true });
    state.player.money -= 2;
    state.inventory.push({ id: 'weathered_qi_primer', name: '《引气初篇》（残旧）', quantity: 1,
      equipped: false, category: '来历不明的册子',
      source: evId(events.length + 1) + ' 临安县城街边购入，2文',
      provenance: '卖方未出示来历；纸页焦黄、有虫蛀、末三页残缺；无门无派印记' });
    state.player.stamina -= 1;
    D.advanceTime(state.time, 9);
    receipts.push({ effect: 'money', from: PC, to: 'CFNPC00008', amount: 2,
                    reason: '残旧《引气初篇》书价', counter: 'watched_handed_over_2_wen' });
    receipts.push({ effect: 'item', add: 'weathered_qi_primer', quantity: 1, source: 'CFNPC00008' });
    receipts.push({ effect: 'stamina', reason: '街边交谈', cost: 1, minutes: 9 });
    return {
      items_gained: ['weathered_qi_primer'], money_delta: -2, money_sink: 'CFNPC00008',
      dialogue: [
        { who: '邋遢老道', text: '小兄弟，你要真功法？我这儿有一册。纸黄了，字还在。' },
        { who: '心魇说', text: '多少钱。' },
        { who: '邋遢老道', text: '两文。' },
        { who: '心魇说', text: '……两文？' },
        { who: '邋遢老道', text: '我卖两文，不卖别的。你要问我为什么这么贱，那是因为我懒得跟人解释。' },
        { who: '心魇说', text: '（把两文递过去，作揖）多谢道长。' },
        { who: '邋遢老道', text: '别谢。记着，日后好相见。' }
      ]
    };
  });

// T16 告别，走回石桥村
commit('farewell_wayfarer_and_walk_home', { rule: 'farewell-rule-v1', place: '临安县城 → 石桥村' },
  receipts => {
    const s0 = state.player.stamina;
    state.player.stamina -= 2;
    D.advanceTime(state.time, 9);
    state.player.stamina -= 17;
    D.advanceTime(state.time, 115);
    state.current_location = '石桥村·钱家院落';
    state.location_id = 'shiqiao';
    state.sub_location = '钱家院落';
    state.position = { x: 3600, y: 4800 };
    receipts.push({ effect: 'stamina', reason: '道别寒暄', before: s0, after: r1(s0 - 2), minutes: 9 });
    receipts.push({ effect: 'stamina', reason: '步行回乡', before: r1(s0 - 2), after: r1(s0 - 19), minutes: 115 });
    return {
      walk: { from: '临安县城·旧书铺街口', to: '石桥村·钱家院落', minutes: 115, stamina: 17 },
      dialogue: [{ who: '邋遢老道', text: '走吧走吧，别在这儿翻。回去再看。' }]
    };
  });

// T17 质问妹妹送饭失约
commit('ask_sister_about_missed_meal_delivery', { rule: 'npc-life-1.0.0', place: '石桥村·钱家院落' },
  receipts => {
    state.player.stamina -= 1;
    D.advanceTime(state.time, 10);
    state.npc_schedules['CFNPC00003'] = { ...state.npc_schedules['CFNPC00003'],
      last_seen_location: '石桥村·钱家院落', activity: 'household_chores_at_home',
      updated_at: state.time.display,
      delivery_obligation: 'answered_on_day2_afternoon',
      delivery_account: '被母亲叫去晒谷，回过神已近日落，怕挨骂没补送' };
    receipts.push({ effect: 'stamina', reason: '说话', cost: 1, minutes: 10 });
    return {
      npc_response: { id: 'CFNPC00003', name: '孙成明',
        decision: 'stayed_silent_then_deflected',
        basis: 'base_temperament caution=48 stress_tolerance=46 cooperation=58；有愧但更怕被当面质问',
        obligation_status: 'unperformed_then_explained_once' },
      dialogue: [
        { who: '心魇说', text: '那日晌午，你说回家取饭。我在荒沟等到日头偏西。' },
        { who: '孙成明', text: '（低头择菜，好一会儿才开口）娘让我晒谷。晒到后半晌，我回头一看，日头都斜了。' },
        { who: '心魇说', text: '那你就没去。' },
        { who: '孙成明', text: '我要是去了，你准要问东问西。我那时候不敢去。' },
        { who: '心魇说', text: '我不是要骂你。我是饿着等了一下午。' },
        { who: '孙成明', text: '……那你现在回来，是要骂还是不要骂？' },
        { who: '心魇说', text: '不要骂。下次你不去，提前说一句。' },
        { who: '孙成明', text: '（把菜梗掰得咔嚓响）知道了。你手里拿的什么？纸都黄了。' }
      ]
    };
  });

// T18 摊开残卷，兄妹认字
commit('open_and_read_weathered_primer', { rule: 'daily-cycle-1.0.0', place: '石桥村·钱家院落' },
  receipts => {
    state.player.stamina -= 2;
    D.advanceTime(state.time, 60);
    state.practice.manual_status = '已得一册残旧《引气初篇》，未经验看';
    state.practice.log.push({ day: state.time.day, msg: '通读《引气初篇》残卷一遍，试诵口诀' });
    state.npc_schedules['CFNPC00003'].interest = '跟着兄长认字、听修仙的事';
    receipts.push({ effect: 'stamina', reason: '静坐读书一小时', cost: 2, minutes: 60 });
    return {
      book_survey: { condition: '纸页焦黄发脆，右上角虫蛀，末三页参差，像是被撕掉',
        legible: '前半为吐纳口诀与行气路线，后半残缺',
        judgement_so_far: '读来通顺，暂无破绽；未逐字比对' },
      dialogue: [
        { who: '孙成明', text: '引气入丹田。丹田在哪儿？' },
        { who: '心魇说', text: '肚脐下面三寸。' },
        { who: '孙成明', text: '谁说的？' },
        { who: '心魇说', text: '书上写的。' },
        { who: '孙成明', text: '书上写的你就信。那书上还写什么？' },
        { who: '心魇说', text: '气行任脉，周天一匝，纳于丹田。' },
        { who: '孙成明', text: '任脉是哪儿？' },
        { who: '心魇说', text: '……我不知道。' }
      ]
    };
  });

// T19 第一次照书引气
commit('first_intake_attempt', { rule: 'cultivation-intake-1.0.0', place: '石桥村·钱家院落' },
  receipts => {
    const r = C.intake({ rootSpeed: 0, hours: 0.7, meridian: state.practice.meridian, stamina: state.player.stamina });
    state.player.stamina -= r.staminaCost + C.FAKE_MANUAL.extraStaminaPerHour * 0.7;
    state.practice.meridian = Math.min(100, r1(state.practice.meridian + C.FAKE_MANUAL.meridianPerHour * 0.7));
    D.advanceTime(state.time, 42);
    state.practice.meridian = C.restMeridian(state.practice.meridian, 0.4);
    receipts.push({ effect: 'intake', hours: 0.7, gain: 0,
      stamina_cost: r.staminaCost, fake_surcharge: r1(C.FAKE_MANUAL.extraStaminaPerHour * 0.7),
      note: '伪诀不产生修为：gain 恒为 0' });
    return { outcome: 'no_qi_sensation', progress_delta: 0,
      known_to_player: '只有腿麻和心跳，没有别人说的那股热流',
      dialogue: [
        { who: '心魇说', text: '（盘腿坐了一炷香，睁眼）什么都没摸到。' },
        { who: '孙成明', text: '我腿麻了。' },
        { who: '心魇说', text: '书上说头一回不容易，要练。' }
      ] };
  });

// T20 傍晚家务与晚饭
commit('evening_chores_then_dinner', { rule: 'daily-cycle-1.0.0', place: '石桥村·钱家院落' },
  receipts => {
    state.player.stamina -= 2; D.advanceTime(state.time, 63);
    receipts.push(staminaOut(63, 2, '挑水劈柴'));
    state.player.stamina -= 1; D.advanceTime(state.time, 40);
    receipts.push(staminaOut(40, 1.5, '默诵口诀'));
    const toDinner = 1080 - (D.clockOf(state.time) % 1440);
    if (toDinner > 0) { D.advanceTime(state.time, toDinner); receipts.push({ effect: 'wait', minutes: toDinner, reason: '等晚饭上桌' }); }
    const m = D.meal(state, 'dinner', 4);
    receipts.push({ effect: 'meal', ...m });
    state.npc_schedules['CFNPC00002'].activity = 'household_cooking_and_chores';
    state.npc_schedules['CFNPC00002'].updated_at = state.time.display;
    return {
      meal: m, household_grain_after_dou: state.family.grain_dou,
      dialogue: [
        { who: '郑舟清', text: '吃饭。今儿个锅里多添了半把米，你跑了县城一天。' },
        { who: '钱然泽', text: '（把碗往桌上一放）县城里那些摊子，有一样是你买的？' },
        { who: '心魇说', text: '买了本书。' },
        { who: '钱然泽', text: '书？你识字？' },
        { who: '心魇说', text: '……认得一些。' },
        { who: '钱然泽', text: '（没再问，低头扒饭）' }
      ]
    };
  });

// T21 饭后教妹妹，书交她保管
const evTeach = commit('teach_sister_primer_basics', { rule: 'npc-life-1.0.0', place: '石桥村·钱家院落' },
  receipts => {
    state.player.stamina -= 2;
    D.advanceTime(state.time, 50);
    state.practice.manual_status = '暂交妹妹保管';
    state.npc_schedules['CFNPC00003'].activity = 'studying_primer_with_brother';
    state.npc_schedules['CFNPC00003'].updated_at = state.time.display;
    state.npc_schedules['CFNPC00003'].custody = 'weathered_qi_primer';
    receipts.push(staminaOut(50, 2.4, '讲解口诀'));
    return {
      teaching: { learner: 'CFNPC00003', consent: true,
        basis: '她主动要看册子，问得比兄长细',
        aptitude: 'NOT_ASSESSED',
        note: '她的灵根与悟性均未经验看，GM 不得凭空评定；此处只记录她读得进去、问得出问题' },
      custody: { holder: 'CFNPC00003', item: 'weathered_qi_primer', note: '收在她针线筐底下，用蓝布包着' },
      dialogue: [
        { who: '孙成明', text: '哥，这上头写"意守丹田"。意怎么守？我坐着的时候满脑子都是明早要不要去挑水。' },
        { who: '心魇说', text: '说是杂念起了就把它放掉。' },
        { who: '孙成明', text: '放掉是放到哪儿去？' },
        { who: '心魇说', text: '……书里没写。' },
        { who: '孙成明', text: '（把册子翻过来又翻过去）哥，这书后面少了三页。' },
        { who: '心魇说', text: '我知道。' },
        { who: '孙成明', text: '少了三页还练？' },
        { who: '心魇说', text: '先练前面这些。' }
      ]
    };
  });

// T22 夜间长坐
commit('night_intake_attempt', { rule: 'cultivation-intake-1.0.0', place: '石桥村·钱家院落' },
  receipts => {
    const r = C.intake({ rootSpeed: 0, hours: 1, meridian: state.practice.meridian, stamina: state.player.stamina });
    state.player.stamina -= r.staminaCost + C.FAKE_MANUAL.extraStaminaPerHour;
    state.practice.meridian = Math.min(100, r1(state.practice.meridian + C.FAKE_MANUAL.meridianPerHour));
    D.advanceTime(state.time, 60);
    receipts.push({ effect: 'intake', hours: 1, gain: 0, stamina_cost: r.staminaCost,
      fake_surcharge: C.FAKE_MANUAL.extraStaminaPerHour });
    return { outcome: 'no_qi_sensation', progress_delta: 0,
      known_to_player: '坐满一个时辰，膝盖发冷，气息只是寻常呼吸，没有书上说的"温热之气"' };
  });

// T23 睡觉到第3日
commit('sleep_to_day3_morning', { rule: 'daily-cycle-1.0.0', place: '石桥村·钱家院落' },
  receipts => {
    const s = D.sleep(state, { untilClock: 360 });
    receipts.push({ effect: 'sleep', ...s });
    const roll = D.dayRollover(state, state.time.day);
    receipts.push({ effect: 'day_rollover', ...roll });
    return { sleep: s, day_rollover: roll,
      note: '睡眠只补精力与经脉负荷，不产生修为；入静与睡眠是两回事' };
  });

// ══════════ 第3日：整日任务 ══════════
commit('day3_river_work_rod_sowing_and_intake', { rule: 'daily-cycle-1.0.0', place: '石桥村·荒沟下游缓水湾' },
  receipts => {
    const b = D.meal(state, 'breakfast', 4); receipts.push({ effect: 'meal', ...b });

    state.player.stamina -= 2; D.advanceTime(state.time, 12);
    receipts.push(staminaOut(12, 10, '走到荒沟下游缓水湾'));
    state.current_location = '石桥村·荒沟下游缓水湾';
    state.sub_location = '荒沟下游缓水湾';
    state.position = { x: 3867, y: 5009 };

    // 收第一只鱼笼
    state.player.stamina -= 2; D.advanceTime(state.time, 12);
    const fresh = state.ecology['shiqiao-outskirts-v1'].freshwater;
    const gear = fresh.installed_gear.find(g => g.id === 'GEAR-SH-RIVER-0001');
    const caught = gear.catch_count;
    gear.catch_count = 0; gear.status = 'deployed_waiting';
    gear.checked_at = state.time.display; gear.checked_at_clock_minutes = D.clockOf(state.time);
    gear.last_check_result = 'removed_retained_fish';
    const fish = state.inventory.find(i => i.id === 'river_fish');
    if (fish) fish.quantity += caught;
    else state.inventory.push({ id: 'river_fish', name: '小河鱼', quantity: caught,
      category: '渔获', equipped: false, source: evId(events.length + 1) + ' 鱼笼取回' });
    receipts.push({ effect: 'item', add: 'river_fish', quantity: caught, source: 'GEAR-SH-RIVER-0001' });
    receipts.push(staminaOut(12, 10, '收笼'));

    // 布第二只鱼笼
    state.player.stamina -= 2; D.advanceTime(state.time, 15);
    const basket = state.inventory.find(i => i.id === 'woven_fish_basket');
    basket.quantity -= 1;
    fresh.installed_gear.push({
      id: 'GEAR-SH-RIVER-0002', type: 'woven_fish_basket', owner: PC,
      site_id: 'SH-RIVER-01', x: 3950, y: 5038,
      source_event_id: evId(events.length + 1),
      placed_at: state.time.display, placed_clock_minutes: D.clockOf(state.time),
      reinforcement: { version: 'fishbasket-weave-0.1.0', lashing: 'plant_fiber', layers: 1,
                       quality: 'reinforced_handwoven', source_event_id: 'EV000009' },
      bait_id: null, anchor: 'downstream_reed_bank', status: 'deployed_waiting',
      catch_count: 0, checked_at: null, checked_at_clock_minutes: null, last_check_result: null });
    receipts.push({ effect: 'item', remove: 'woven_fish_basket', quantity: 1, sink: 'GEAR-SH-RIVER-0002' });
    receipts.push(staminaOut(15, 8, '布第二只鱼笼'));

    // 组装简易手竿
    state.player.stamina -= 2; D.advanceTime(state.time, 20);
    for (const id of ['rod_blank_wood_01', 'fishing_line', 'fish_hook']) {
      state.inventory.find(i => i.id === id).quantity -= 1;
    }
    state.inventory.push({ id: 'simple_fishing_rod', name: '简易手竿（竿坯+线+钩）', quantity: 1,
      equipped: false, category: '渔具', usable_for_fishing: true,
      source: evId(events.length + 1) + ' 河岸现场组装' });
    state.fishing_requests.rod_pair.craft_count = 1;
    state.fishing_requests.rod_pair.status = 'simple_rod_assembled_1; second rod still missing';
    receipts.push({ effect: 'item', add: 'simple_fishing_rod', quantity: 1,
      consumed: ['rod_blank_wood_01', 'fishing_line', 'fish_hook'] });
    receipts.push(staminaOut(20, 6, '缠线装钩'));

    // 回家播种
    state.player.stamina -= 2; D.advanceTime(state.time, 12);
    state.player.stamina -= 3; D.advanceTime(state.time, 30);
    state.inventory.find(i => i.id === 'vegetable_seed_packet').quantity -= 1;
    state.farming.fields_prepared = 1;
    state.farming.planted = [{ crop: '青菜', plot: '钱家自留地', planted_at: state.time.display,
      seed_source: 'linan-registered-vendor', status: 'sown', note: '按农时需月余方可采收' }];
    state.farming.seeds_owned.vegetable_seed_packet = 0;
    receipts.push({ effect: 'item', remove: 'vegetable_seed_packet', quantity: 1, sink: '钱家自留地' });
    receipts.push({ effect: 'stamina', reason: '翻土播种', cost: 3, minutes: 30 });
    receipts.push(staminaOut(12, 10, '走回院子'));
    state.current_location = '石桥村·钱家院落';
    state.sub_location = '钱家院落';

    const toLunch = 720 - (D.clockOf(state.time) % 1440);
    if (toLunch > 0) { D.advanceTime(state.time, toLunch); receipts.push({ effect: 'wait', minutes: toLunch, reason: '等午饭' }); }
    const l = D.meal(state, 'lunch', 4); receipts.push({ effect: 'meal', ...l });

    const p1 = C.intake({ rootSpeed: 0, hours: 2, meridian: state.practice.meridian, stamina: state.player.stamina });
    state.player.stamina -= p1.staminaCost + C.FAKE_MANUAL.extraStaminaPerHour * 2;
    state.practice.meridian = Math.min(100, r1(state.practice.meridian + C.FAKE_MANUAL.meridianPerHour * 2));
    D.advanceTime(state.time, 120);
    receipts.push({ effect: 'intake', hours: 2, gain: 0, phase: 'afternoon' });

    const toDinner = 1080 - (D.clockOf(state.time) % 1440);
    if (toDinner > 0) { D.advanceTime(state.time, toDinner); receipts.push({ effect: 'wait', minutes: toDinner, reason: '午后杂事与等晚饭' }); }
    const dn = D.meal(state, 'dinner', 4); receipts.push({ effect: 'meal', ...dn });

    const p2 = C.intake({ rootSpeed: 0, hours: 1, meridian: state.practice.meridian, stamina: state.player.stamina });
    state.player.stamina -= p2.staminaCost + C.FAKE_MANUAL.extraStaminaPerHour;
    state.practice.meridian = Math.min(100, r1(state.practice.meridian + C.FAKE_MANUAL.meridianPerHour));
    D.advanceTime(state.time, 60);
    receipts.push({ effect: 'intake', hours: 1, gain: 0, phase: 'night' });

    const s = D.sleep(state, { untilClock: 360 });
    receipts.push({ effect: 'sleep', ...s });
    const roll = D.dayRollover(state, state.time.day);
    receipts.push({ effect: 'day_rollover', ...roll });
    state.practice.intake_days += 1;

    return {
      day_summary: { day: 3, river_work: true, fish_taken: caught,
        second_basket_deployed: 'GEAR-SH-RIVER-0002', rod_assembled: 'simple_fishing_rod',
        sowing: '钱家自留地·青菜一畦', intake_hours: 3, intake_gain: 0 },
      day_rollover: roll,
      dialogue: [
        { who: '孙成明', text: '第二只笼子放那么远？' },
        { who: '心魇说', text: '芦苇那边水缓，鱼好停。' },
        { who: '孙成明', text: '你别又忘了收。' }
      ]
    };
  });

// ══════════ 第4–6日：逐日收敛 ══════════
function routineDay(dayNo, intakeHours) {
  return commit('day' + dayNo + '_routine_and_intake', { rule: 'daily-cycle-1.0.0' },
    receipts => {
      const b = D.meal(state, 'breakfast', 4); receipts.push({ effect: 'meal', ...b });
      const half = intakeHours / 2;
      let p = C.intake({ rootSpeed: 0, hours: half, meridian: state.practice.meridian, stamina: state.player.stamina });
      state.player.stamina -= p.staminaCost + C.FAKE_MANUAL.extraStaminaPerHour * half;
      state.practice.meridian = Math.min(100, r1(state.practice.meridian + C.FAKE_MANUAL.meridianPerHour * half));
      D.advanceTime(state.time, half * 60);
      receipts.push({ effect: 'intake', hours: half, gain: 0, phase: 'morning' });

      waitTo(720, receipts, '上午余下的杂事');
      const l = D.meal(state, 'lunch', 4); receipts.push({ effect: 'meal', ...l });

      state.player.stamina -= 4; D.advanceTime(state.time, 150);
      receipts.push(staminaOut(150, 1.6, '农活与杂事'));

      p = C.intake({ rootSpeed: 0, hours: half, meridian: state.practice.meridian, stamina: state.player.stamina });
      state.player.stamina -= p.staminaCost + C.FAKE_MANUAL.extraStaminaPerHour * half;
      state.practice.meridian = Math.min(100, r1(state.practice.meridian + C.FAKE_MANUAL.meridianPerHour * half));
      D.advanceTime(state.time, half * 60);
      receipts.push({ effect: 'intake', hours: half, gain: 0, phase: 'evening' });

      const toDinner = 1080 - (D.clockOf(state.time) % 1440);
      if (toDinner > 0) { D.advanceTime(state.time, toDinner); receipts.push({ effect: 'wait', minutes: toDinner, reason: '等晚饭' }); }
      const dn = D.meal(state, 'dinner', 4); receipts.push({ effect: 'meal', ...dn });

      const s = D.sleep(state, { untilClock: 360 });
      receipts.push({ effect: 'sleep', ...s });
      const roll = D.dayRollover(state, state.time.day);
      receipts.push({ effect: 'day_rollover', ...roll });
      state.practice.intake_days += 1;

      return {
        day_summary: { day: dayNo, intake_hours: intakeHours, intake_gain: 0,
          sister_status: dayNo >= 5 ? '头晕、胸闷，已叫停' : '照练，未见异样' },
        day_rollover: roll,
        dialogue: dayNo === 5 ? [
          { who: '孙成明', text: '哥，我一坐下去就头晕。今早起来胸口还闷得慌。' },
          { who: '心魇说', text: '你怎么坐的？' },
          { who: '孙成明', text: '就照书上那样，气往下沉。沉到一半就恶心。' },
          { who: '心魇说', text: '……你先别练了。' },
          { who: '孙成明', text: '不练就不练。反正我也没觉出什么气来。' }
        ] : []
      };
    });
}
routineDay(4, 3);
const evDay5 = routineDay(5, 3);
routineDay(6, 3);

// ══════════ 第7日：最后一次尝试 + 逐字比对 ══════════
const evCompare = commit('day7_final_attempt_and_textual_comparison', { rule: 'cultivation-intake-1.0.0' },
  receipts => {
    const b = D.meal(state, 'breakfast', 4); receipts.push({ effect: 'meal', ...b });
    const p = C.intake({ rootSpeed: 0, hours: 1, meridian: state.practice.meridian, stamina: state.player.stamina });
    state.player.stamina -= p.staminaCost + C.FAKE_MANUAL.extraStaminaPerHour;
    state.practice.meridian = Math.min(100, r1(state.practice.meridian + C.FAKE_MANUAL.meridianPerHour));
    D.advanceTime(state.time, 60);
    receipts.push({ effect: 'intake', hours: 1, gain: 0, phase: 'last_attempt' });
    state.practice.intake_days += 1;

    waitTo(720, receipts, '上午把册子从头到尾再顺一遍');
    const l = D.meal(state, 'lunch', 4); receipts.push({ effect: 'meal', ...l });

    state.player.stamina -= 2; D.advanceTime(state.time, 90);
    receipts.push({ effect: 'stamina', reason: '逐字比对前后口诀', cost: 2, minutes: 90 });

    const toDinner = 1080 - (D.clockOf(state.time) % 1440);
    if (toDinner > 0) { D.advanceTime(state.time, toDinner); receipts.push({ effect: 'wait', minutes: toDinner, reason: '反复翻看，等晚饭' }); }
    const dn = D.meal(state, 'dinner', 4); receipts.push({ effect: 'meal', ...dn });
    const s = D.sleep(state, { untilClock: 360 });
    receipts.push({ effect: 'sleep', ...s });
    const roll = D.dayRollover(state, state.time.day);
    receipts.push({ effect: 'day_rollover', ...roll });

    return {
      intake_days_total: state.practice.intake_days,
      total_progress: state.practice.progress,
      findings: [
        '前半写"气行任脉，自下而上，周天一匝"；中段却写"气自督脉上行，逆走三关"',
        '前半写"九九八十一天方见初效"；同页边角批注写"三十六日可成"',
        '最要紧的收气归丹田一节，恰在被撕掉的末三页'
      ],
      conclusion_by_player: '册子前后自相矛盾，收束功夫又缺页；照它练了六日，一丝气感也无',
      day_rollover: roll
    };
  });

// ══════════ 第8日：判定 ══════════
commit('day8_conclude_manual_is_unusable', { rule: 'cultivation-intake-1.0.0' },
  receipts => {
    const b = D.meal(state, 'breakfast', 4); receipts.push({ effect: 'meal', ...b });
    state.player.stamina -= 1; D.advanceTime(state.time, 60);
    receipts.push({ effect: 'stamina', reason: '反复翻看，与村里塾师问答', cost: 1, minutes: 60 });
    state.practice.manual_status = '判定为拼凑伪诀，不能引气';
    state.practice.log.push({ day: state.time.day, msg: '判定《引气初篇》为伪本，停止照练' });
    waitTo(720, receipts, '上午与塾师问答、反复翻看');
    const l = D.meal(state, 'lunch', 4); receipts.push({ effect: 'meal', ...l });
    return {
      verdict: { manual: 'weathered_qi_primer',
        authenticity_roll: AUTH.roll, authenticity_band: AUTH.band, authenticity_label: AUTH.label,
        formula: AUTH.formula,
        evidence: '六日实证零气感 + 前后口诀三处硬矛盾 + 关键收功页缺失',
        public_conclusion: '这本册子是拼凑伪诀，练不出气；买书的两文收不回来' },
      realm_unchanged: '凡人（未修行）',
      known_to_player: '修仙这条路没有断，但这本书是死路；他还不知道自己是什么灵根，县里也没处可测',
      sister_status: { id: 'CFNPC00003', condition: '停练后两日头晕消退', lost: '六日工夫' },
      dialogue: [
        { who: '孙成明', text: '那两文钱……' },
        { who: '心魇说', text: '没了。' },
        { who: '孙成明', text: '（把蓝布包着的册子递回来）还练吗？' },
        { who: '心魇说', text: '不练了。留着，别再翻。' }
      ]
    };
  });

// ══════════ 写盘 ══════════
writeAll();

memory.scene = {
  id: 'SCENE' + String(events.length).padStart(4, '0'),
  place: state.current_location,
  time: state.time.display,
  awaiting: '是否带着这条线索另寻门路：灵山或青云山城的灵根检测台、别的修士，或先攒家底',
  facts: [
    '承平三年第2日下午，心魇说在临安街边以2文向一名邋遢游方道人买下残旧《引气初篇》。',
    '当日13:27回到石桥村家中；与妹妹孙成明就前一日送饭失约谈过一次，她承认被叫去晒谷、怕挨骂没补送。',
    '第2日夜至第7日，兄妹二人照册吐纳六日，零气感；孙成明第5日头晕胸闷，已被叫停。',
    '第3日收回鱼笼鱼1条、布下第二只鱼笼、现场组装简易手竿、在自家自留地播下青菜一畦。',
    '第7日逐字比对，发现前后口诀三处硬矛盾，收气归丹田一节缺失。',
    '第8日判定该册为拼凑伪诀，不能引气；两文无法追回。境界仍为凡人，灵根仍未检测。'
  ]
};
memory.state_checkpoint = {
  last_event_id: index.last_event, last_event_hash: index.last_event_hash,
  state_sha256: index.full_state_sha256, time: state.time.display,
  location_id: state.location_id, player_id: PC, hp: state.player.hp,
  stamina: state.player.stamina, money: state.player.money, root_status: state.player.root_status
};
const closeIds = ['T0003', 'T0004', 'T0007', 'T0009', 'T0010', 'T0011', 'T0012', 'T0013'];
memory.open_threads = memory.open_threads.filter(t => !closeIds.includes(t.id));
for (const t of memory.open_threads) {
  if (t.id === 'T0006') { t.status = '已当面问过：她承认被叫去晒谷，怕挨骂未补送'; t.certainty = '已结算'; }
  if (t.id === 'T0005') { t.status = '鱼笼已布两只（GEAR-SH-RIVER-0001/0002）；仍缺玉米与酒作诱饵'; }
}
memory.open_threads.push(
  { id: 'T0014', title: '二文一场空：功法真伪', status: '判定《引气初篇》为伪本，已停止照练', source: index.last_event, certainty: '已结算（六日实证 + 文本比对）' },
  { id: 'T0015', title: '第二只鱼笼与简易手竿', status: 'GEAR-SH-RIVER-0002 布于下游芦苇滩；简易手竿已成，尚未下竿', source: 'day3_river_work_rod_sowing_and_intake', certainty: '已提交事件' },
  { id: 'T0016', title: '青菜已播种', status: '钱家自留地播青菜一畦，月余后或有收成', source: 'day3_river_work_rod_sowing_and_intake', certainty: '已提交事件' },
  { id: 'T0017', title: '灵根与真正的引气法门', status: '本人仍不知有无灵根；县城无检测台，灵山与青云山城才有', source: index.last_event, certainty: '未解决' }
);
memory.characters['CFNPC00008'] = {
  id: 'CFNPC00008', name: '钟时云', relation: '游方道人（未向玩家通名）', sex: '男', age: 40,
  narrative_notes: ['第2日在临安街边以2文卖出残旧《引气初篇》',
                    '留下一句"日后好相见"便走，未解释去处与来历'],
  location_id: 'linan', alive: true, health: '正常'
};
writeFileSync(join(root, 'story_memory_public.json'), JSON.stringify(memory, null, 2) + '\n');

const wayfarer = state.known_npcs.find(n => n.id === 'CFNPC00008');
registry.npcs['CFNPC00008'] = {
  id: 'CFNPC00008', campaign_id: state.campaign_id, name: wayfarer.name, sex: '男', age: 40,
  residence: '游方（无固定居所）', alive: true, health: '正常', roles: ['游方道人'],
  born_at: null, kinship_origin: '来历未告，与钱家无亲',
  base_temperament: inherentTemperament(state.world_seed, 'CFNPC00008'),
  public_personality: [
    { tag: 'refuses_to_explain_price', kind: 'observed', description: '被追问为何只卖两文，只说自己懒得解释', basis_event: evId(17) },
    { tag: 'leaves_abruptly', kind: 'observed', description: '收了钱就让人走，不附赠任何保证', basis_event: evId(17) }
  ],
  goals_observed: [],
  life_events: [
    { event_id: evId(17), tag: 'sold_weathered_primer_for_two_wen', certainty: 'known_fact',
      text: '在临安街边以两文卖出残旧《引气初篇》，未说明来历', location: '临安县城·旧书铺街口' },
    { event_id: evId(18), tag: 'parted_with_promise_to_meet_again', certainty: 'known_fact',
      text: '留下一句"日后好相见"便离去，去向不明', location: '临安县城' }
  ],
  relationships: {}, last_known_location: '临安县城（去向不明）', last_updated_event: evId(18)
};
registry.npcs['CFNPC00003'].life_events.push(
  { event_id: evId(19), tag: 'answered_missed_delivery', certainty: 'known_fact',
    text: '承认当日被母亲叫去晒谷，怕被质问而未补送饭食', location: '石桥村·钱家院落' },
  { event_id: evId(evTeach.seq), tag: 'received_primer_custody', certainty: 'known_fact',
    text: '接过残旧《引气初篇》代为保管，收在针线筐下', location: '石桥村·钱家院落' },
  { event_id: evId(evDay5.seq), tag: 'intake_side_effect', certainty: 'known_fact',
    text: '照册吐纳数日后头晕胸闷，被兄长叫停', location: '石桥村·钱家院落' }
);
registry.npcs['CFNPC00001'].life_events.push(
  { event_id: evId(22), tag: 'asked_about_county_purchases', certainty: 'known_fact',
    text: '晚饭时问起县城摊子上有没有买东西；听说买了书，只问了一句识不识字便低头吃饭', location: '石桥村·钱家院落' }
);
registry.npcs['CFNPC00001'].last_updated_event = evId(22);
registry.npcs['CFNPC00003'].last_updated_event = index.last_event;
writeFileSync(join(root, 'npc_registry.json'), JSON.stringify(registry, null, 2) + '\n');

index.manual_status = '手里这本《引气初篇》已判为伪本（练不出气，两文已花）；县城旧书铺无真功法可核验';
index.next_checkpoint_turn = 30;
index.sister_errand = '已当面问过：她承认被母亲叫去晒谷，怕挨骂没有补送';
index.fishing_status = 'GEAR-SH-RIVER-0001 已收（本轮取回小河鱼1条）；GEAR-SH-RIVER-0002 已布于下游芦苇滩；简易手竿已成，尚未下竿';
index.second_basket_status = 'deployed_at_SHIPPED_done';
index.second_basket_status = 'deployed';
index.trap_status = '村外绳套第二日查看为空，未再布设';
index.market_price_status = '临安县城市价：小河鱼/青菜/野兔收购价已问；尚未再交易';
const mem = index.turns_completed % 10 === 0 ? checkpoint(root) : { created: false };
const review = index.turns_completed % 10 === 0 ? reviewAtTurn(root) : { created: false };
const final = inspect(root);

console.log(JSON.stringify({
  ok: true,
  authenticity: { roll: AUTH.roll, band: AUTH.band },
  turns: final.turns, last_event: index.last_event, last_hash: index.last_event_hash,
  full_state_verified: final.full_state_verified,
  time: state.time.display,
  player: { stamina: state.player.stamina, money: state.player.money,
            realm: state.player.realm, hp: state.player.hp },
  progress: state.practice.progress, layer: state.practice.layer,
  meridian: state.practice.meridian,
  grain: { dou: state.family.grain_dou, millidou: D.grainMillidou(state.family) },
  checkpoint: mem, review, checkpoints,
  ledger: receiptsAll
}, null, 2));
