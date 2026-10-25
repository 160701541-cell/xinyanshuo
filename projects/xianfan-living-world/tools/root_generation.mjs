// 出生抽签与灵根承诺的独立复现（照录 xianfan-canglan/create_character.py 的算法）
// 目的：检测台不能用"GM 记得的答案"自证，必须从 world_seed 重新算一遍，再拿承诺哈希对。
import { createHash } from 'node:crypto';

const ROOTS = [
  ['天灵根', 6], ['单灵根', 60], ['双灵根', 300], ['三灵根', 900],
  ['四灵根', 1800], ['五灵根', 3200], ['无灵根', 3734],
];

function draw(seed, label, upper) {
  const lim = (1n << 256n) / BigInt(upper) * BigInt(upper);
  for (let i = 0; ; i++) {
    const val = BigInt('0x' + createHash('sha256').update(`${seed}|${label}|${i}`).digest('hex'));
    if (val < lim) return Number(val % BigInt(upper));
  }
}

function weighted(seed, label, options) {
  const total = options.reduce((a, [, n]) => a + n, 0);
  const roll = draw(seed, label, total);
  let cursor = 0;
  for (const [name, n] of options) { cursor += n; if (roll < cursor) return { name, roll, total }; }
  throw Error('权重异常');
}

export function randomKeyOf(state) {
  const p = state.player;
  return `${state.world_seed}|玩家:${p.name}|性别:${p.sex}|年龄:${p.age}|开局序号:1`;
}

export function commitmentOf(campaignId, randomKey, roll, root) {
  return createHash('sha256').update(`${campaignId}|${randomKey}|${roll}|${root}`).digest('hex');
}

/** 从世界种子重新抽出灵根，并用存档里的承诺哈希校验；不符即报错。 */
export function revealRoot(state) {
  const key = randomKeyOf(state);
  const { name: root, roll } = weighted(key, 'root', ROOTS);
  const commitment = commitmentOf(state.campaign_id, key, roll, root);
  if (commitment !== state.player.root_commitment_sha256) {
    throw Error('ROOT_REVEAL_MISMATCH 重算的承诺哈希与存档不符');
  }
  return { root, roll, randomKey: key, commitment };
}

export const ROOT_TABLE = ROOTS;

export function selfTest() {
  const failed = [];
  const eq = (name, a, b) => { if (JSON.stringify(a) !== JSON.stringify(b)) failed.push(`${name}: ${a} != ${b}`); };
  eq('draw 上界', draw('t', 'x', 10) < 10, true);
  eq('draw 确定性', draw('t', 'x', 10), draw('t', 'x', 10));
  eq('weighted 落档', weighted('t', 'x', [['a', 1], ['b', 1]]).name !== undefined, true);
  eq('承诺可复算', commitmentOf('c', 'k', 7, '四灵根'),
     createHash('sha256').update('c|k|7|四灵根').digest('hex'));
  return { ok: failed.length === 0, failed };
}

// —— 照录 create_character.py 的姓名表 ——
export const SURNAMES = '沈林陈王李赵张吴周徐唐秦叶谢陆方何苏顾许孙韩邵钱曹马郑杜白柳严蒋钟宁';
export const GIVEN = '清云山河长安明远青宁若秋雨知行时序修文景松竹春雪思言有成平然泽照墨石舟田星澜';
export function npcName(seed, label) {
  return SURNAMES[draw(seed, label + '.surname', SURNAMES.length)]
       + GIVEN[draw(seed, label + '.given1', GIVEN.length)]
       + GIVEN[draw(seed, label + '.given2', GIVEN.length)];
}
export function npcAge(seed, label, base, span) { return base + draw(seed, label + '.age', span); }
