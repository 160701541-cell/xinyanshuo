// 《仙凡·苍岚》第一世：第29日天亮前出发 → 青云山门测灵根 → 第30日回家
// 用法：node tools/settle_departure.mjs <战役目录>
import { readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { digest, verifyEvents, countTurns, inspect, checkpoint } from './campaign_guard.mjs';
import { auditProposedTurn, reviewAtTurn } from './gm_quality_gate.mjs';
import * as D from './daily_cycle.mjs';
import * as J from './journey_and_earn.mjs';
import { revealRoot, randomKeyOf, npcName, npcAge, selfTest as rootSelfTest } from './root_generation.mjs';

const root = process.argv[2];
if (!root) throw Error('缺战役目录');
const read = n => JSON.parse(readFileSync(join(root, n), 'utf8'));
const readLines = n => readFileSync(join(root, n), 'utf8').split(/\r?\n/).filter(Boolean).map(JSON.parse);

const st = J.selfTest();
if (!st.ok) throw Error('路程规则自测失败 ' + JSON.stringify(st.failed));
const rt = rootSelfTest();
if (!rt.ok) throw Error('抽签复现自测失败 ' + JSON.stringify(rt.failed));

const state = read('game_state.json');
const index = read('campaign_index.json');
const events = readLines('events.jsonl');

verifyEvents(events);
if (index.turns_completed !== countTurns(events)) throw Error('索引与事件轮数不符');
if (state.last_event_id !== index.last_event) throw Error('状态与索引事件不同步');
if (digest(state) !== index.full_state_sha256) throw Error('状态哈希与索引不符');
if (index.turns_completed !== 103) throw Error('本脚本只接第103轮之后；当前 ' + index.turns_completed);
if (state.player.root_status !== '未检测') throw Error('灵根已是公开状态，不能重复检测');

const money = n => (state.player.money = Math.round((state.player.money - n) * 10) / 10);
const r1 = x => Math.round(x * 10) / 10;
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
  if (state.player.stamina < 0) throw Error('STAMINA_NEGATIVE at ' + action);
  if (state.player.money < 0) throw Error('MONEY_NEGATIVE at ' + action);
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
    checkpoint(root); reviewAtTurn(root);
    console.log('checkpoint at turn', event.turn_id);
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
const leg = id => J.leg(id);

// ══ 第29日 06:00，天没亮 ══
const day29 = D.dayRollover(state, 29);
console.log('第29日 天气', state.time.weather);

commit('leave_before_dawn', { rule: 'road-travel-1.0.0', place: '石桥村·钱家院落' }, (rc) => {
  const bf = D.meal(state, 'breakfast', 4); rc.push({ effect: 'meal', ...bf });
  spendStamina(25, 2.4, rc, '摸黑穿衣、捆行装、吃早饭'); D.advanceTime(state.time, 25);
  state.inventory.push({ id: 'dry_provisions', name: '烙饼（母亲给的干粮）', quantity: 1,
                         equipped: false, category: '食物', source: '第29日出门前母亲郑舟清烙的' });
  rc.push({ effect: 'note', who: 'CFNPC00003', said: '哥，我送你去村口。' });
  rc.push({ effect: 'note', who: 'CFNPC00001', said: '送到村口就回来。' });
  rc.push({ effect: 'note', who: 'CFNPC00002', said: '饼在包袱里，冷了也别扔。' });
  state.current_location = '石桥村·村口';
  return { note: '天没亮出门，妹妹送到村口，父亲站在门口没出来' };
});

commit('walk_to_linan', { rule: 'road-travel-1.0.0', place: '临安县城·南街' }, (rc) => {
  const r = leg('shiqiao-linan');
  spendStamina(r.minutes, J.WALK.staminaPerMinute * 60, rc, '走官道到临安');
  D.advanceTime(state.time, r.minutes);
  state.current_location = '临安县城·南街';
  state.location_id = 'linan'; state.position = { x: 0, y: 0 };
  return { note: '官道上全是赶早的人，挑担的、推车的', leg_id: 'shiqiao-linan', minutes: r.minutes };
});

commit('walk_mountain_road_to_qingyun_gate', { rule: 'road-travel-1.0.0', place: '青云山门·山脚' }, (rc) => {
  const r = leg('linan-qingyun');
  spendStamina(r.minutes, J.WALK.staminaPerMinute * 60, rc, '走北上的山道');
  D.advanceTime(state.time, r.minutes);
  const prov = state.inventory.find(i => i.id === 'dry_provisions');
  if (prov) { prov.quantity = 0; rc.push({ effect: 'use_item', item: 'dry_provisions', qty: 1, reason: '半山腰就着溪水吃了一张饼' }); }
  state.current_location = '青云山门·山脚';
  state.location_id = 'qingyun'; state.position = { x: 11300, y: -7200 };
  return { note: '山道一路往上，走到后半程腿是木的', leg_id: 'linan-qingyun', minutes: r.minutes,
           weather: state.time.weather,
           note2: '路上遇着两个下山采买的杂役，说山门午后还开着测灵台' };
});

commit('queue_and_pay_at_test_station', { rule: 'root-test-1.0.0', place: '青云山门·测灵台' }, (rc) => {
  state.current_location = '青云山门·测灵台';
  spendStamina(15, 2.4, rc, '问路、找测灵台'); D.advanceTime(state.time, 15);
  const stn = J.station('ST-QINGYUN-01');
  money(stn.fee_copper);
  rc.push({ effect: 'money', delta: -stn.fee_copper, reason: '过门钱' });
  spendStamina(stn.queue_minutes, 2.4, rc, '排在队伍里'); D.advanceTime(state.time, stn.queue_minutes);
  if (!state.known_npcs.some(n => n.id === 'CFNPC00009')) {
    const clerk = { id: 'CFNPC00009', name: npcName(randomKeyOf(state), 'clerk.qingyun-station'),
      relation: '青云山门测灵台执事', sex: '男',
      age: npcAge(randomKeyOf(state), 'clerk.qingyun-station', 42, 18),
      location_id: 'qingyun', health: '正常', alive: true };
    state.known_npcs.push(clerk);
    rc.push({ effect: 'known_npc', ...clerk });
  }
  rc.push({ effect: 'note', who: 'CFNPC00009', said: '测一回三十文，测过就上了册子，往后不再测第二回。' });
  rc.push({ effect: 'note', who: 'PC', said: '知道。' });
  return { note: '交了三十文过门钱，排在第七个', money_sink: '青云山门·测灵台过门钱',
           station: 'ST-QINGYUN-01', fee: stn.fee_copper };
});

// ══ 测灵根本身：结果只能从 world_seed 重算，不能由 GM 指定 ══
const reveal = revealRoot(state);
commit('root_test_at_qingyun_station', { rule: 'root-test-1.0.0', place: '青云山门·测灵台' }, (rc) => {
  const stn = J.station('ST-QINGYUN-01');
  spendStamina(stn.test_minutes, 2.4, rc, '把手按在测灵石上'); D.advanceTime(state.time, stn.test_minutes);
  state.player.root_status = reveal.root;
  state.practice.tested = true;
  state.practice.testedAt = state.time.display;
  state.practice.rootId = reveal.root === '四灵根' ? 'si'
    : { '天灵根':'tian','单灵根':'dan','双灵根':'shuang','三灵根':'san','五灵根':'wu','无灵根':'none' }[reveal.root];
  state.practice.root_roll_public = reveal.roll;
  state.practice.verified_by_commitment = reveal.commitment;
  index.roots_hidden = false;
  state.reference = { ...(state.reference || {}), root_revealed_at: state.time.display,
                      root_reveal_method: 'SHA256(campaign_id|random_key|roll|root) 与存档承诺哈希一致' };
  rc.push({ effect: 'note', who: 'CFNPC00009', said: '四种。杂的。' });
  rc.push({ effect: 'note', who: 'PC', said: '……四种是什么意思？' });
  rc.push({ effect: 'note', who: 'CFNPC00009', said: '意思是能练，练得慢。上上等的测出来是一种色，你这石头一亮，四样都往外冒。' });
  rc.push({ effect: 'note', who: 'CFNPC00009', said: '记你叫心魇说，石桥村人。名册上添一笔，往后哪条路自己挑。' });
  rc.push({ effect: 'root_test', result: reveal.root, roll: reveal.roll,
            commitment_sha256: reveal.commitment, verified: true });
  return { note: '测灵台给出结果：四灵根', action_succeeded: true,
           root: reveal.root, root_roll: reveal.roll,
           root_commitment_sha256: reveal.commitment,
           verify: '重算的承诺哈希与游戏状态中的 root_commitment_sha256 一致',
           interpretation: '可修行，但根骨驳杂、凝气慢' };
});

commit('lodge_and_dinner_at_qingyun', { rule: 'root-travel-1.0.0', place: '青云山城·脚店' }, (rc) => {
  spendStamina(30, 2.4, rc, '下山到山脚脚店'); D.advanceTime(state.time, 30);
  money(8);
  rc.push({ effect: 'money', delta: -8, reason: '脚店房钱（含一顿糙饭）' });
  spendStamina(60, 2.4, rc, '吃那顿糙饭'); D.advanceTime(state.time, 60);
  state.player.stamina = Math.min(state.player.max_stamina, state.player.stamina + 4);
  rc.push({ effect: 'stamina_recover', gain: 4, reason: '一顿糙饭' });
  state.current_location = '青云山城·脚店';
  waitTo(1260, rc, '坐在门槛上发愣，天黑了');
  return { note: '住进山脚脚店，八文，含一顿糙饭', money_sink: '青云山城·脚店房钱' };
});

commit('sleep_at_qingyun_inn', { rule: 'daily-cycle-1.0.0', place: '青云山城·脚店' }, (rc) => {
  const sle = D.sleep(state, { untilClock: 360 }); rc.push({ effect: 'sleep', ...sle });
  D.dayRollover(state, 30);
  return { note: '在脚店睡了一夜；睡前把那块石头的样子来回想了几遍' };
});

// ══ 第30日：回家 ══
console.log('第30日 天气', state.time.weather);
commit('walk_back_mountain_road', { rule: 'road-travel-1.0.0', place: '临安县城·南街' }, (rc) => {
  const prov = state.inventory.find(i => i.id === 'dry_provisions');
  if (prov) prov.quantity = 1;
  rc.push({ effect: 'use_item', item: 'dry_provisions', qty: 1, reason: '临走前又要了一张饼路上吃' });
  spendStamina(15, 2.4, rc, '收拾行装、上路'); D.advanceTime(state.time, 15);
  const r = leg('linan-qingyun');
  spendStamina(r.minutes, J.WALK.staminaPerMinute * 60, rc, '走山道回临安');
  D.advanceTime(state.time, r.minutes);
  state.current_location = '临安县城·南街';
  state.location_id = 'linan'; state.position = { x: 0, y: 0 };
  return { note: '下山比上山快不了多少，膝盖发软', leg_id: 'linan-qingyun', minutes: r.minutes };
});

commit('walk_home_from_linan', { rule: 'road-travel-1.0.0', place: '石桥村·钱家院落' }, (rc) => {
  const r = leg('shiqiao-linan');
  spendStamina(r.minutes, J.WALK.staminaPerMinute * 60, rc, '走回石桥村');
  D.advanceTime(state.time, r.minutes);
  state.current_location = '石桥村·钱家院落';
  state.location_id = 'shiqiao'; state.position = { x: 3867, y: 5009 };
  return { note: '回到村口的时候，日头刚偏西', leg_id: 'shiqiao-linan', minutes: r.minutes };
});

commit('report_result_to_the_family', { rule: 'daily-cycle-1.0.0', place: '石桥村·钱家院落' }, (rc) => {
  spendStamina(45, 2.4, rc, '被母亲按在凳子上灌了一碗水'); D.advanceTime(state.time, 45);
  waitTo(1080, rc, '等晚饭');
  const dinner = D.meal(state, 'dinner', 4); rc.push({ effect: 'meal', ...dinner });
  spendStamina(120, 1.2, rc, '饭桌上把结果说出来'); D.advanceTime(state.time, 120);
  rc.push({ effect: 'note', who: 'PC', said: '四灵根。测灵台的人说，能练，练得慢。' });
  rc.push({ effect: 'note', who: 'CFNPC00001', said: '能练？那不就是还得练。' });
  rc.push({ effect: 'note', who: 'CFNPC00002', said: '钱花完了没有？' });
  rc.push({ effect: 'note', who: 'PC', said: '还剩十五文。' });
  rc.push({ effect: 'note', who: 'CFNPC00003', said: '四样色，是不是比别人多？' });
  rc.push({ effect: 'note', who: 'PC', said: '是多。多不一定好。' });
  return { note: '把测出来的东西原原本本说了一遍；父亲问的是"还得练"，母亲问的是钱' };
});

commit('sleep', { rule: 'daily-cycle-1.0.0', place: '石桥村·钱家院落' }, (rc) => {
  const sle = D.sleep(state, { untilClock: 360 }); rc.push({ effect: 'sleep', ...sle });
  D.dayRollover(state, 31);
  return { note: '睡了。名册上添了一笔，地里还是那些活' };
});

writeAll();
const final = inspect(root);
console.log(JSON.stringify({
  turns: final.turns, last_event: index.last_event,
  time: state.time.display, location: state.current_location,
  money: state.player.money, stamina: state.player.stamina,
  root: state.player.root_status, root_roll: state.practice.root_roll_public,
  root_id: state.practice.rootId, tested: state.practice.tested,
  roots_hidden: index.roots_hidden, grain: D.grainMillidou(state.family),
}, null, 1));
