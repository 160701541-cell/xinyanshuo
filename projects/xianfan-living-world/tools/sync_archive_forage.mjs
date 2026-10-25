// 把第115-149回合（村外采药十六天）落到公开档案。用法：node tools/sync_archive_forage.mjs <战役目录>
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
if (index.turns_completed !== 149) throw Error('本脚本只接第149轮；当前 ' + index.turns_completed);
if (digest(state) !== index.full_state_sha256) throw Error('状态哈希不符');

const evOf = a => { const e = events.find(x => x.action === a); if (!e) throw Error('找不到 ' + a); return 'EV' + String(e.seq).padStart(6, '0'); };
const EV_ASK = evOf('ask_around_about_herb_gathering');
const EV_SELL = evOf('sell_herbs_at_linan_stall');
const EV_BUYER = evOf('meet_an_itinerant_herb_buyer');
const herbs = state.inventory.filter(i => i.category === '药材' && i.quantity > 0).map(i => `${i.name}×${i.quantity}`).join('、');

index.next_checkpoint_turn = 150;
index.sync_status = 'PENDING_GITHUB';
index.forage_status = {
  ...index.forage_status,
  days_worked: 16,
  sites: ['SH-SLOPE-N-01', 'SH-RIVER-BEND-01', 'SH-WOODS-E-01'],
  earned: { total_copper: 80, from_linan_stall: 20, from_itinerant_buyer: 60 },
  unsold_stock: herbs,
  conclusion: '村外三处只出凡草，灵草十不存一；县城药材摊一天收不下多少，灵草还被压到六折',
};
index.money_status = {
  held: state.player.money,
  household_cash: state.family.cash,
  qi_primer_price_copper: 200,
  gap_to_qi_primer: 200 - state.player.money,
  note: '正本《引气初篇》二百文一块灵石，散修货栈还有残篇八十文（真假难辨）',
};

memory.scene = {
  id: 'SCENE0034',
  place: '石桥村·钱家院落',
  time: state.time.display,
  awaiting: '采了十六天药，攒到九十五文；正本功法要二百文，还差一半。凡草卖不动，灵草只有灵山那边认价',
  facts: [
    '第31日向母亲和隔壁婶子问清了村外三处采药去处：村北乱石坡、溪湾湿滩、东边杂木林，每处一天只能采一趟。',
    '第31日至第46日，每天三处轮着走，凡草收了一大堆，灵草只出了三株。',
    '第39日进城卖药，西市药材摊当日只有二十文现钱，八份凡草卖了二十文，剩下的被退回来。',
    '第46日在西市遇见跑灵山药市的收药散修，三株灵草按八五折卖了六十文。',
    '那散修说：县城摊子不识灵草；灵山按株论价，比县城多两成；灵田边角有主，偷采罚的钱够买半本功法。',
    '也是他说的价：药市《引气初篇》正本两百文一块灵石，验册五文，残篇八十文。',
    '手边九十五文，凡草还剩一堆卖不动。钱袋里的钱差不多还差一半。',
  ],
};
const closeT = (id, status) => { const t = memory.open_threads.find(x => x.id === id); if (t) t.status = status; };
closeT('T0020', '部分进展：已知道正本《引气初篇》二百文、残篇八十文、验册五文；尚买不起，也尚未见到实物');
closeT('T0021', '仍悬着：那二十文是家里过冬钱，采药赚的还没还上');
memory.open_threads = memory.open_threads.filter(t => t.id !== 'T0022');
memory.open_threads.push({
  id: 'T0022', title: '还差一百零五文',
  status: '村外采药一天最多十文上下，凡草县城摊收不下；灵草要灵山那边才认价',
  source: EV_BUYER, certainty: '未解决',
});
memory.characters['CFNPC00002'].narrative_notes.push('把自家老人采药的门道指给了儿子，同时说了实话：好药都长在别人圈起来的地里');
memory.characters['CFNPC00003'].narrative_notes.push('要跟哥哥去采药，被"爹说过"挡回去；后来常蹲在院子里帮着分拣');
const buyer = state.known_npcs.find(n => n.id === 'CFNPC00010');
if (buyer) {
  memory.characters['CFNPC00010'] = {
    id: 'CFNPC00010', name: buyer.name, relation: '跑灵山药市的收药散修', sex: buyer.sex,
    age: buyer.age, location_id: 'linan', alive: true, health: '正常',
    narrative_notes: ['十天半月往灵山跑一趟，收灵草转手', '话里带着数："灵田边角有主，罚的钱够你买半本功法。"'],
  };
}
memory.state_checkpoint = {
  last_event_id: index.last_event, last_event_hash: index.last_event_hash,
  state_sha256: digest(state), time: state.time.display, location_id: state.location_id,
  player_id: state.player.id, hp: state.player.hp, stamina: state.player.stamina,
  money: state.player.money, root_status: state.player.root_status,
};

if (buyer) {
  registry.npcs['CFNPC00010'] = {
    id: 'CFNPC00010', campaign_id: state.campaign_id, name: buyer.name, sex: buyer.sex, age: buyer.age,
    residence: 'linan',
    roles: ['跑灵山药市的收药散修'],
    base_temperament: inherentTemperament(state.world_seed, 'CFNPC00010'),
    public_personality: [
      { tag: 'prices_by_the_plant', kind: 'observed',
        description: '开口先说价钱和去处，不说客套话', basis_event: EV_BUYER },
      { tag: 'warns_about_boundaries', kind: 'observed',
        description: '主动提醒灵田有主、偷采重罚', basis_event: EV_BUYER },
    ],
    life_events: [
      { event_id: EV_BUYER, tag: 'bought_three_spirit_herbs', certainty: 'known_fact',
        text: '按八五折收下三株灵草，付六十文，并说明县城摊子不识灵草、灵山按株论价多两成', location: '临安县城·西市' },
    ],
    relationships: { 'CFPLAYER00001': '第一次打交道的卖药人' },
    last_known_location: 'linan',
    last_updated_event: EV_BUYER,
  };
}

registry.npcs['CFNPC00002'].life_events.push(
  { event_id: EV_ASK, tag: 'told_where_the_herbs_grow', certainty: 'known_fact',
    text: '把北坡、溪湾、东头林子三处采药去处指给儿子，并说好药都长在人家圈起来的地里', location: '石桥村·钱家院落' });
registry.npcs['CFNPC00002'].last_updated_event = EV_ASK;

registry.npcs['CFNPC00003'].life_events.push(
  { event_id: EV_ASK, tag: 'asked_to_come_along', certainty: 'known_fact',
    text: '说认草比哥哥快，要跟去采药，被"爹说过"挡回', location: '石桥村·钱家院落' });
registry.npcs['CFNPC00003'].last_updated_event = EV_ASK;

const v = validateNpcRegistry(registry, state, events);
if (!v.ok) throw Error('NPC 档案校验失败: ' + JSON.stringify(v.issues));

writeFileSync(join(root, 'campaign_index.json'), JSON.stringify(index, null, 2) + '\n');
writeFileSync(join(root, 'story_memory_public.json'), JSON.stringify(memory, null, 2) + '\n');
writeFileSync(join(root, 'npc_registry.json'), JSON.stringify(registry, null, 2) + '\n');

const final = inspect(root);
console.log(JSON.stringify({
  ok: true, npc: { ok: v.ok, characters: v.characters, latest: v.latest_event },
  turns: final.turns, last: index.last_event, verified: final.full_state_verified,
  money: state.player.money, time: state.time.display,
}, null, 1));
