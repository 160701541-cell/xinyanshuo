// 对白：先用"槽位 + 性格"拼，接得上本地模型就替换其中一句
export const DIALOGUE_VERSION = 'dialogue-0.1.0';

export const TONES = {
  warm: ['你来得巧，','正好，','哎呀，'],
  cold: ['……','嗯。','有事？'],
  sly: ['嘿嘿，','哟，','这话得小声说，'],
  plain: ['我说，','那什么，','听我说，'],
};

export const REASONS = ['官府的粮价又涨了','东市来了几车蜀锦','药圃的灵草要收了','城外的路被水冲了','衙门在查流民','山里的妖物又下山了'];

/** NPC 的一句闲话：性格 + 身份 + 当下情形，纯确定性（同 seed 同一句） */
export function smallTalk(npc, ctx = {}) {
  const tone = TONES[npc.tone] || TONES.plain;
  const head = tone[Math.abs(hash(npc.name || 'x')) % tone.length];
  const reason = ctx.reason || REASONS[Math.abs(hash((npc.name || '') + (ctx.day || 0))) % REASONS.length];
  const job = npc.job ? `我这${npc.job}的，` : '';
  const where = ctx.place ? `在${ctx.place}，` : '';
  return `${head}${where}${job}${reason}。`;
}

/** 问路：给方向与距离，走街串巷的口吻 */
export function askWay(npc, target, distanceM) {
  const d = distanceM < 200 ? '拐两个弯就到' : distanceM < 800 ? '走一段就到' : '还有段路';
  const name = typeof target === 'string' ? target : (target && target.name) || '那儿';
  return `${(TONES[npc.tone] || TONES.plain)[0]}去${name}？${d}，往${compass(npc, target)}边。`;
}

function compass(npc, target) {
  const dx = (target.x || 0) - (npc.x || 0), dy = (target.y || 0) - (npc.y || 0);
  if (Math.abs(dx) > Math.abs(dy)) return dx > 0 ? '东' : '西';
  return dy > 0 ? '南' : '北';
}

function hash(s) {
  let h = 2166136261;
  for (let i = 0; i < s.length; i++) { h ^= s.charCodeAt(i); h = Math.imul(h, 16777619); }
  return h | 0;
}

/**
 * 可插拔：给了 adapter（本地模型 / 远端）就用它，失败回落到模板。
 * adapter: async ({prompt, persona}) => string
 */
export async function reply(npc, playerLine, ctx = {}, adapter = null) {
  if (adapter) {
    try {
      const text = await adapter({prompt: playerLine, persona: npc, ctx});
      if (typeof text === 'string' && text.trim()) return {text: text.trim(), source: 'model'};
    } catch (e) { /* 模型不可用就走模板 */ }
  }
  return {text: smallTalk(npc, ctx), source: 'template'};
}
