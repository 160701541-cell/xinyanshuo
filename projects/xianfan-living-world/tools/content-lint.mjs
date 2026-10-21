#!/usr/bin/env node
// 内容流水线：校验 → 试跑 → 出清单。加一条规则后跑这个，错在数据里就当场报出来。
import {writeFileSync} from 'node:fs';
import {createWorld} from '../core.mjs';
import {RULES, CARD_TEMPLATES, validateRule, runRules} from '../engine.mjs';
import {loadContent} from '../content/index.mjs';

const errors = [];
loadContent();

for (const r of RULES) errors.push(...validateRule(r));
if (!RULES.length) errors.push('没有任何规则——content/ 没被载入');
if (!CARD_TEMPLATES.size) errors.push('没有任何卡片模板');

// 试跑：连过 180 天，日/旅/杀三个钩子都打一遍，看有没有炸
const w = createWorld('lint');
let fired = 0;
try {
  for (let d = 0; d < 180; d++) {
    w.day += 1;
    fired += runRules(w, 'daily', {}).length;
    if (d % 30 === 0) fired += runRules(w, 'travel', {mode: 'foot'}).length;
    if (d % 45 === 0) { w.karma = {value: 70}; fired += runRules(w, 'kill', {}).length; }
  }
} catch (e) {
  errors.push('试跑抛错：' + e.message);
}

const hooks = [...new Set(RULES.map(r => r.hook))];
const lines = [];
lines.push('# 内容清单（自动生成）', '');
lines.push(`> 由 \`node tools/content-lint.mjs\` 生成，别手改。引擎 ${RULES.length} 条规则、${CARD_TEMPLATES.size} 张卡片模板。`, '');
lines.push('| 规则 | 钩子 | 分类 | 频率 | 触发条件 | 后果 |', '|---|---|---|---|---|---|');
const condText = c => {
  if (!c) return '—';
  if (Array.isArray(c)) return c.map(condText).join(' 且 ');
  if (c.all) return c.all.map(condText).join(' 且 ');
  if (c.any) return '(' + c.any.map(condText).join(' 或 ') + ')';
  if (c.not) return '非(' + condText(c.not) + ')';
  return `${c.path} ${c.op || 'truthy'}${c.value !== undefined ? ' ' + JSON.stringify(c.value) : ''}`;
};
const effText = e => ({add: `${e.path} ${e.by > 0 ? '+' : ''}${e.by}`, set: `${e.path}=${e.value}`, note: `记「${e.type || '事件'}」`, flag: `标记 ${e.key}`, unflag: `清除 ${e.key}`}[e.do] || e.do);
for (const r of RULES) {
  lines.push(`| ${r.id} | ${r.hook} | ${r.tag || '—'} | ${r.once ? '一生一次' : r.cooldown ? `冷却 ${r.cooldown} 天` : '随时'} | ${condText(r.when)} | ${(r.then || []).map(effText).join('；')} |`);
}
lines.push('', '## 卡片模板', '');
for (const c of CARD_TEMPLATES.values()) {
  lines.push(`- **${c.id}**（${c.kind}）：字段 ${c.fields.map(f => f.label).join('、')}；动作 ${(c.actions || []).map(a => a.label).join('、') || '无'}`);
}

if (errors.length) {
  console.error('内容校验失败：\n- ' + errors.join('\n- '));
  process.exit(1);
}
writeFileSync(new URL('../docs/33_内容清单.md', import.meta.url), lines.join('\n') + '\n');
console.log(`内容校验通过：${RULES.length} 条规则 / ${CARD_TEMPLATES.size} 张卡片 / 钩子 ${hooks.join(',')} / 试跑 180 天触发 ${fired} 次`);
