// 把第29-103回合的公开档案（索引、剧情记忆、NPC 档案）同步到权威状态，并做完整性校验。
// 用法：node tools/sync_archive_20261026.mjs <战役目录>
import { readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { digest, verifyEvents, countTurns, inspect } from './campaign_guard.mjs';
import { validateNpcRegistry } from './npc_identity.mjs';

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
if (index.turns_completed !== 103) throw Error('本脚本只接第103轮；当前 ' + index.turns_completed);
if (digest(state) !== index.full_state_sha256) throw Error('状态哈希不符');

const evOf = action => {
  const e = events.find(x => x.action === action);
  if (!e) throw Error('找不到事件 ' + action);
  return 'EV' + String(e.seq).padStart(6, '0');
};

// ── 索引 ──
index.next_checkpoint_turn = 110;
index.sync_status = 'PENDING_GITHUB';
index.fishing_status = '河道 SH-RIVER-01 被抽空过：累计捕走 15 条，现存 0；一天只回涨一条，靠河攒不出大钱';
index.market_price_status = '临安菜肉摊收购价：小河鱼 3 文/条（摊主当日现钱有限，一次收不下太多）；青菜 3 文/斤；野兔 7 文';
index.sister_errand = '第2日送饭失约已当面问清；此后她帮着看下游那只笼子；出发事宜她只被允许送到村口';
index.manual_status = '手里那本《引气初篇》已判为伪本，不再照练；灵根仍未检测';
index.journey_status = {
  goal: '去青云山门·测灵台测灵根',
  stage: '盘缠已备，定在第29日天亮前动身',
  copper_held: state.player.money,
  fish_held_unsold: (state.inventory.find(i => i.id === 'river_fish') || { quantity: 0 }).quantity,
  planned_cost: { test_fee_copper: 30, lodging_per_night_copper: 8, nights_planned: 2, total_known: 46 },
  provisions: '自家烙饼带上，不在路上买',
  household_cash: state.family.cash,
  rule_files: ['data/root_test_station_v1.json', 'data/road_travel_v1.json', 'data/fishing_v1.json']
};
index.next_action_hint = '第29日天亮前出门，走官道到临安，再沿山道北上青云山门';

// ── 剧情记忆 ──
memory.scene = {
  id: 'SCENE0032',
  place: '石桥村·钱家院落',
  time: state.time.display,
  awaiting: '天亮前动身去青云山门测灵根；盘缠已备，路还没走',
  facts: [
    '第8日中午起，心魇说把测灵根的事跟父母摊开说了：父亲钱然泽不认，认为种地不需要测；母亲郑舟清没拦，只问钱从哪儿来。',
    '第9至第27日，他天天清晨下河收笼、下竿三个时辰，白天照旧下田；三次进城卖鱼（第10、15、28日），铜钱从 0 攒到 53 文。',
    '河段被抽空过：累计捕走 15 条，水面一度一条不剩；此后一天只回涨一条，靠河攒不出大钱。',
    '第20日晚饭时父亲从家里现钱里数出 20 文给他（家中共 42 文，给完剩 22 文），条件是"测不出东西就回来老老实实种地，别再买破册子"。',
    '妹妹孙成明主动要求同去，被父亲当场驳回，只准送到村口；母亲答应给他烙饼带上路。',
    '第28日在临安打听到：青云山门测灵根收 30 文过门钱，单程山道约八个时辰，半路脚店 8 文一晚；干粮要自己带，山道上没人家。',
    '第28日晚饭桌上定了日子：第29日天亮前出门。手边 53 文，还剩下 4 条鱼没卖掉。',
  ],
};
const closeThread = (id, status) => { const t = memory.open_threads.find(x => x.id === id); if (t) t.status = status; };
closeThread('T0015', '两只笼子还在河里用着，但河已被抽空，一天只回涨一条');
closeThread('T0017', '已有下一步：攒够盘缠，去青云山门测灵根（一次定终身）');
memory.open_threads = memory.open_threads.filter(t => t.id !== 'T0018' && t.id !== 'T0019');
memory.open_threads.push(
  { id: 'T0018', title: '攒盘缠', status: '已攒到 53 文：其中 20 文是父亲给的，其余三十三文是一条一条鱼换来的', source: evOf('tell_family_departure_is_set'), certainty: '已结算事件' },
  { id: 'T0019', title: '青云山门测灵根', status: '定在第29日天亮前动身，未曾去过的路，费用与结果都还没有落地', source: evOf('tell_family_departure_is_set'), certainty: '已定日程，未执行' },
);
memory.characters['CFNPC00001'].narrative_notes = [
  '认为种地不需要测什么灵根，起初一口回绝',
  '看了儿子一个月的早出晚归，第20日从家里现钱里数出二十文，附了条件：测不出就回来种地',
  '不许女儿跟着走远路，只准送到村口',
];
memory.characters['CFNPC00002'].narrative_notes = [
  '没拦，也没答应，只问钱从哪儿来',
  '第28日答应给儿子烙饼带上路，叮嘱别省、别赶夜路',
];
memory.characters['CFNPC00003'].narrative_notes = [
  '第2日送饭失约，被问起时承认怕挨骂没补送',
  '主动提出帮着收河边的笼子，一天天跟着跑',
  '要求陪兄长去青云，被父亲驳回，只准送到村口',
];
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
N['CFNPC00001'].life_events.push(
  { event_id: evOf('tell_family_about_root_test'), tag: 'rejected_root_test_idea', certainty: 'known_fact',
    text: '听儿子说要去测灵根，当面不认：种了一辈子地没测过也活到七十三', location: '石桥村·钱家院落' },
  { event_id: evOf('father_offers_part_of_household_cash'), tag: 'gave_twenty_wen_with_a_condition', certainty: 'known_fact',
    text: '看了儿子一个月的早出晚归，从家里现钱里数出二十文，条件是测不出就回来种地', location: '石桥村·钱家院落' },
  { event_id: evOf('tell_family_departure_is_set'), tag: 'forbade_daughter_from_going', certainty: 'known_fact',
    text: '不许女儿跟去青云，只准送到村口', location: '石桥村·钱家院落' },
);
N['CFNPC00001'].public_personality.push(
  { tag: 'does_not_believe_in_root_testing', kind: 'observed',
    description: '认为测灵根是城里人骗钱的由头，种地不需要', basis_event: evOf('tell_family_about_root_test') },
  { tag: 'pays_only_after_seeing_effort', kind: 'observed',
    description: '不肯凭一句话掏钱，看了整月的劳作才从家里现钱里拿二十文', basis_event: evOf('father_offers_part_of_household_cash') },
);
N['CFNPC00001'].last_updated_event = evOf('tell_family_departure_is_set');

N['CFNPC00002'].life_events.push(
  { event_id: evOf('tell_family_about_root_test'), tag: 'asked_where_the_money_comes_from', certainty: 'known_fact',
    text: '没拦也没答应，只问钱从哪儿来，说家里那点钱留着过冬', location: '石桥村·钱家院落' },
  { event_id: evOf('tell_family_departure_is_set'), tag: 'promised_to_bake_bread_for_the_road', certainty: 'known_fact',
    text: '答应给儿子烙饼带上路，叮嘱路上别省、别赶夜路', location: '石桥村·钱家院落' },
);
N['CFNPC00002'].last_updated_event = evOf('tell_family_departure_is_set');

N['CFNPC00003'].life_events.push(
  { event_id: evOf('dinner_and_sister_talk'), tag: 'offered_to_help_with_the_cages', certainty: 'known_fact',
    text: '提出帮着收河边的笼子，让兄长腾出手下地', location: '石桥村·钱家院落' },
  { event_id: evOf('father_offers_part_of_household_cash'), tag: 'asked_to_come_along_and_was_refused', certainty: 'known_fact',
    text: '当场要求陪兄长同去青云，被父亲一口回绝', location: '石桥村·钱家院落' },
  { event_id: evOf('tell_family_departure_is_set'), tag: 'allowed_to_escort_to_the_village_gate_only', certainty: 'known_fact',
    text: '只被允许送到村口', location: '石桥村·钱家院落' },
);
N['CFNPC00003'].last_updated_event = evOf('tell_family_departure_is_set');

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
  time: state.time.display, money: state.player.money, household_cash: state.family.cash,
  root_status: state.player.root_status,
}, null, 1));
