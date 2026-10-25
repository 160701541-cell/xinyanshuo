// 把第104-114回合（出发→测灵根→回家）落到公开档案，并做完整性校验。
// 用法：node tools/sync_archive_departure.mjs <战役目录>
import { readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { digest, verifyEvents, countTurns, inspect } from './campaign_guard.mjs';
import { validateNpcRegistry, inherentTemperament } from './npc_identity.mjs';

const root = process.argv[2];
if (!root) throw Error('缺战役目录');
const read = n => JSON.parse(readFileSync(join(root, n), 'utf8'));
const lines = n => readFileSync(join(root, n), 'utf8').split(/\r?\n/).filter(Boolean).map(JSON.parse);

const state = read('game_state.json');
const index = read('campaign_index.json');
const events = lines('events.jsonl');
const memory = read('story_memory_public.json');
const registry = read('npc_registry.json');

verifyEvents(events);
if (index.turns_completed !== countTurns(events)) throw Error('轮数不符');
if (index.turns_completed !== 114) throw Error('本脚本只接第114轮；当前 ' + index.turns_completed);
if (digest(state) !== index.full_state_sha256) throw Error('状态哈希不符');
if (state.player.root_status === '未检测') throw Error('灵根还没测，不能写公开档案');
if (index.roots_hidden !== false) throw Error('roots_hidden 应已置 false');

const evOf = action => {
  const e = events.find(x => x.action === action);
  if (!e) throw Error('找不到事件 ' + action);
  return 'EV' + String(e.seq).padStart(6, '0');
};

// ── 索引 ──
index.next_checkpoint_turn = 120;
index.sync_status = 'PENDING_GITHUB';
index.root_status_public = state.player.root_status;
index.root_test_result = {
  root: state.player.root_status,
  root_roll_0_9999: state.practice.root_roll_public,
  root_id: state.practice.rootId,
  commitment_sha256: state.practice.verified_by_commitment,
  station: 'ST-QINGYUN-01',
  tested_at: state.practice.testedAt,
  fee_copper: 30,
  method: '从 world_seed 重新抽签，与存档 root_commitment_sha256 逐位比对一致后才写入',
  one_time_only: true,
};
index.journey_status = {
  goal: '去青云山门·测灵台测灵根',
  stage: '已完成：第29日出发、当日测出结果、第30日回到家',
  copper_held: state.player.money,
  spent: { test_fee_copper: 30, lodge_copper: 8 },
  outcome: '四灵根（可修行，根骨驳杂、凝气慢）',
};
index.next_action_hint = '灵根已知，但没有可用的引气法门——那本《引气初篇》是伪的';
index.manual_status = '手里那本《引气初篇》已判为伪本，不再照练；灵根已测，缺的是真正的入门功法';

// ── 剧情记忆 ──
memory.scene = {
  id: 'SCENE0033',
  place: '石桥村·钱家院落',
  time: state.time.display,
  awaiting: '灵根测出来了，可手里的功法是假的；下一步要么找真法门，要么先去山门谋个差事',
  facts: [
    '第29日天亮前出门，妹妹孙成明送到村口，母亲郑舟清烙了饼；父亲钱然泽站在门口没出来。',
    '当日走官道到临安、再走北上山道，共 472 分钟到青云山门，交 30 文过门钱，当晚测灵根。',
    '测灵台结果：四灵根。测灵台执事沈澜清说"能练，练得慢"，并把名字记进了名册。',
    '结果不是谁记得的答案：由 world_seed 重新抽签得到 2938 号，与存档里的承诺哈希逐位一致后才写入公开档案。',
    '一次定终身，往后不再测第二回。',
    '当晚住山脚脚店 8 文；第30日原路走回，傍晚到家，把结果原原本本说了一遍——父亲问"还得练"，母亲问钱。',
    '手边剩 15 文。境界仍是凡人，一天都没真正引过气。',
  ],
};
const closeThread = (id, status) => { const t = memory.open_threads.find(x => x.id === id); if (t) t.status = status; };
closeThread('T0017', '已解决：第29日在青云山门测出四灵根，公开名册有名');
closeThread('T0018', '已完成：攒到 53 文，花掉 38 文，剩 15 文');
closeThread('T0019', '已完成：第29日出走、当日测完、第30日回家');
memory.open_threads = memory.open_threads.filter(t => t.id !== 'T0020' && t.id !== 'T0021');
memory.open_threads.push(
  { id: 'T0020', title: '真正的入门功法', status: '手里的《引气初篇》是拼凑伪诀，灵根已测却无经可依；山门、药市或别处或另有路子', source: evOf('root_test_at_qingyun_station'), certainty: '未解决' },
  { id: 'T0021', title: '那二十文', status: '父亲从家里过冬钱里支的，测出四灵根也不算"有功"，这笔账还悬着', source: evOf('report_result_to_the_family'), certainty: '未解决' },
);
memory.characters['CFNPC00001'].narrative_notes.push('儿子回来只说"四灵根"，他抓住的是"还得练"三个字——地里的活不会等人');
memory.characters['CFNPC00002'].narrative_notes.push('先问钱花完了没有；听说剩十五文，没再说话');
memory.characters['CFNPC00003'].narrative_notes.push('送到村口；等哥哥回来，头一句问的是"四样色是不是比别人多"');
memory.characters['CFNPC00009'] = {
  id: 'CFNPC00009', name: '沈澜清', relation: '青云山门测灵台执事', sex: '男',
  age: state.known_npcs.find(n => n.id === 'CFNPC00009').age,
  location_id: 'qingyun', alive: true, health: '正常',
  narrative_notes: ['照章办事，收三十文、测一次、记一笔', '话说得直："四种。杂的。""能练，练得慢。"'],
};
memory.state_checkpoint = {
  last_event_id: index.last_event,
  last_event_hash: index.last_event_hash,
  state_sha256: digest(state),
  time: state.time.display,
  location_id: state.location_id,
  player_id: state.player.id,
  hp: state.player.hp,
  stamina: state.player.stamina,
  money: state.player.money,
  root_status: state.player.root_status,
};

// ── NPC 档案 ──
const N = registry.npcs;
const clerk = state.known_npcs.find(n => n.id === 'CFNPC00009');
N['CFNPC00009'] = {
  id: 'CFNPC00009', campaign_id: state.campaign_id, name: clerk.name, sex: clerk.sex, age: clerk.age,
  residence: 'qingyun',
  roles: ['青云山门·测灵台执事'],
  base_temperament: inherentTemperament(state.world_seed, 'CFNPC00009'),
  public_personality: [
    { tag: 'follows_the_register', kind: 'observed',
      description: '先说要钱、说要上名册，再谈测什么', basis_event: evOf('queue_and_pay_at_test_station') },
    { tag: 'blunt_about_results', kind: 'observed',
      description: '报结果只有两个字四个字，不哄人也不劝人', basis_event: evOf('root_test_at_qingyun_station') },
  ],
  life_events: [
    { event_id: evOf('queue_and_pay_at_test_station'), tag: 'took_the_fee_and_explained_the_rule', certainty: 'known_fact',
      text: '收下三十文过门钱，说明"测一回三十文，测过上了册子，往后不再测第二回"', location: '青云山门·测灵台' },
    { event_id: evOf('root_test_at_qingyun_station'), tag: 'reported_four_root', certainty: 'known_fact',
      text: '测出四灵根，只说"四种。杂的。""能练，练得慢。"，把心魇说的名字记进名册', location: '青云山门·测灵台' },
  ],
  relationships: { 'CFPLAYER00001': '名册上添的一笔' },
  last_known_location: 'qingyun',
  last_updated_event: evOf('root_test_at_qingyun_station'),
};

N['CFNPC00001'].life_events.push(
  { event_id: evOf('leave_before_dawn'), tag: 'stayed_at_the_door', certainty: 'known_fact',
    text: '儿子出门时没送出门口，只站在门里说"送到村口就回来"', location: '石桥村·钱家院落' },
  { event_id: evOf('report_result_to_the_family'), tag: 'heard_four_root_and_asked_about_practice', certainty: 'known_fact',
    text: '听到"四灵根"只抓住一句"还得练"，意思是地里的活不会等人', location: '石桥村·钱家院落' },
);
N['CFNPC00001'].last_updated_event = evOf('report_result_to_the_family');

N['CFNPC00002'].life_events.push(
  { event_id: evOf('leave_before_dawn'), tag: 'baked_bread_before_dawn', certainty: 'known_fact',
    text: '天没亮就烙了饼塞进包袱，说"冷了也别扔"', location: '石桥村·钱家院落' },
  { event_id: evOf('report_result_to_the_family'), tag: 'asked_about_the_money_first', certainty: 'known_fact',
    text: '儿子回来先问钱花完了没有；听说剩十五文，没再说话', location: '石桥村·钱家院落' },
);
N['CFNPC00002'].last_updated_event = evOf('report_result_to_the_family');

N['CFNPC00003'].life_events.push(
  { event_id: evOf('leave_before_dawn'), tag: 'escorted_to_the_village_gate', certainty: 'known_fact',
    text: '天没亮送哥哥到村口', location: '石桥村·村口' },
  { event_id: evOf('report_result_to_the_family'), tag: 'asked_whether_four_colors_means_more', certainty: 'known_fact',
    text: '头一句问"四样色，是不是比别人多"', location: '石桥村·钱家院落' },
);
N['CFNPC00003'].last_updated_event = evOf('report_result_to_the_family');

const v = validateNpcRegistry(registry, state, events);
if (!v.ok) throw Error('NPC 档案校验失败: ' + JSON.stringify(v.issues));

writeFileSync(join(root, 'campaign_index.json'), JSON.stringify(index, null, 2) + '\n');
writeFileSync(join(root, 'story_memory_public.json'), JSON.stringify(memory, null, 2) + '\n');
writeFileSync(join(root, 'npc_registry.json'), JSON.stringify(registry, null, 2) + '\n');

const final = inspect(root);
console.log(JSON.stringify({
  ok: true,
  npc: { ok: v.ok, characters: v.characters, latest_event: v.latest_event },
  turns: final.turns, last_event: index.last_event,
  full_state_verified: final.full_state_verified,
  time: state.time.display, money: state.player.money,
  root: state.player.root_status, root_roll: state.practice.root_roll_public,
  roots_hidden: index.roots_hidden,
}, null, 1));
