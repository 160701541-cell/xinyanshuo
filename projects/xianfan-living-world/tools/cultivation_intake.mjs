// 《仙凡·苍岚》文字战役：引气入体判定 v1
// 数值常量逐项照录自 projects/xianfan-living-world/cultivation.mjs（CULTIVATION_VERSION xian-1.0.0），
// 不新增平衡数字，只把已有公式接到文字战役的时辰账本上。
// 规则声明见 data/cultivation_intake_v1.json。
import { createHash } from 'node:crypto';

export const INTAKE_VERSION = 'cultivation-intake-1.0.0';
const sha = x => createHash('sha256').update(x).digest('hex');

// —— 照录 cultivation.mjs:ROOTS ——
export const ROOT_SPEED = { tian:5.0, kong:4.2, shi:4.2, dan:3.0, shuang:2.0, san:1.4, si:1.0, wu:0.7, none:0 };
// —— 照录 cultivation.mjs:BARRIERS ——
export const BARRIERS = {
  1:{name:'炼气一层',need:40,meridian:6}, 2:{name:'炼气二层',need:70,meridian:8},
  3:{name:'炼气三层',need:110,meridian:10}, 4:{name:'炼气四层',need:160,meridian:12},
  5:{name:'炼气五层',need:220,meridian:14}, 6:{name:'炼气六层',need:300,meridian:16},
  7:{name:'炼气七层',need:400,meridian:19}, 8:{name:'炼气八层',need:520,meridian:22},
  9:{name:'炼气九层',need:680,meridian:25}, 10:{name:'炼气十层',need:880,meridian:28},
  11:{name:'炼气十一层',need:1120,meridian:31}, 12:{name:'炼气十二层',need:1420,meridian:35},
  13:{name:'炼气十三层',need:1780,meridian:39}
};
// —— 照录 cultivation.mjs:BREATHE ——
export const BREATHE = { staminaPerHour:1.4, baseGain:1, overloadPause:.75 };
export const REST_MERIDIAN_PER_HOUR = 2.2;   // 照录 restMeridian()
// 石桥村不在 QI_REGIONS 明列地，regionOfPlace() 默认落 xiancheng:.18
export const QI_XIANCHENG = 0.18;

const round1 = x => Math.round(x*10)/10;

/** 一次吐纳。公式与 cultivation.mjs:practice() 完全一致。 */
export function intake({ rootSpeed, qi=QI_XIANCHENG, hours, meridian=0, stamina }) {
  if (!Number.isFinite(hours) || hours<=0) throw Error('INVALID_HOURS');
  if (!Number.isFinite(rootSpeed) || rootSpeed<0) throw Error('INVALID_ROOT_SPEED');
  const cost = round1(BREATHE.staminaPerHour*hours);
  if (stamina < cost) throw Error('STAMINA_NOT_ENOUGH');
  const overload = meridian >= 60 ? BREATHE.overloadPause : 1;
  const gain = rootSpeed<=0 ? 0 : round1(BREATHE.baseGain*hours*rootSpeed*(1+qi)*overload);
  return { gain, meridianAfter: Math.min(100, round1(meridian + hours*1.6)),
           staminaCost: cost, overloaded: overload<1 };
}

/** 静养/睡眠清经脉负荷。照录 restMeridian() 的 2.2/小时。 */
export const restMeridian = (meridian, hours) =>
  Math.max(0, round1(meridian - hours*REST_MERIDIAN_PER_HOUR));

/** 层间小突破：够修为就上，不掷骰；经脉 >92 先歇。照录 breakLayer()。 */
export function tryBreakLayer({ layer, progress, meridian }) {
  const next = BARRIERS[layer+1];
  if (!next) return { ok:false, reason:'炼气已到顶' };
  if (progress < next.need) return { ok:false, reason:'修为不够', need:next.need, progress };
  if (meridian > 92) return { ok:false, reason:'经脉负荷过高，再冲会出事' };
  return { ok:true, layer:layer+1, name:next.name,
           progress: round1(progress - next.need),
           meridian: Math.min(100, round1(meridian + next.meridian*0.4)) };
}

/** 功法真伪：分布预先声明于 data/cultivation_intake_v1.json，掷骰只用世界种子。 */
export const AUTHENTICITY_BANDS = [
  { id:'genuine',  from:0,    to:2999, label:'真品·口诀完整、行气路线无误' },
  { id:'fragment', from:3000, to:6499, label:'残本·口诀缺关键环节，只能调息' },
  { id:'fake',     from:6500, to:9999, label:'伪本·拼凑伪诀，路线自相矛盾' }
];
export function manualAuthenticity(worldSeed, itemId, vendorId) {
  const roll = Number(BigInt('0x'+sha(worldSeed+'|manual-authenticity|'+itemId+'|'+vendorId+'|v1')) % 10000n);
  const band = AUTHENTICITY_BANDS.find(b => roll>=b.from && roll<=b.to);
  return { roll, band:band.id, label:band.label, formula:'SHA256(worldSeed|manual-authenticity|itemId|vendorId|v1) % 10000' };
}

/** 灵根承诺校验：reveal 由承诺生成协议原样重算。 */
export function verifyRootReveal(commitment, reveal) {
  if (!/^[0-9a-f]{64}$/.test(commitment||'')) throw Error('INVALID_ROOT_COMMITMENT');
  if (sha(reveal) !== commitment) throw Error('ROOT_REVEAL_MISMATCH');
  return true;
}

/** 伪诀副反应：久练伤神。不产生修为，只扣精力与经脉。 */
export const FAKE_MANUAL = { extraStaminaPerHour:0.6, meridianPerHour:0.8 };

export const SELF_TEST = () => {
  const r = intake({ rootSpeed:ROOT_SPEED.si, hours:2, meridian:0, stamina:80 });
  if (r.gain !== 2.4) throw Error('SELF_TEST_GAIN ' + r.gain);
  if (r.meridianAfter !== 3.2) throw Error('SELF_TEST_MERIDIAN');
  if (restMeridian(60, 8) !== 42.4) throw Error('SELF_TEST_REST');
  if (!tryBreakLayer({ layer:0, progress:40, meridian:0 }).ok) throw Error('SELF_TEST_BREAK');
  return true;
};
