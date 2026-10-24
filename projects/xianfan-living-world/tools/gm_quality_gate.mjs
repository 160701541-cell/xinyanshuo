import {readFileSync,writeFileSync,mkdirSync,existsSync} from 'node:fs';
import {join} from 'node:path';
import {inspect} from './campaign_guard.mjs';

export const FIELDS=[
 'story_consistency','actor_symmetry','causality','resource_conservation',
 'npc_knowledge','pursuit_motivation','memory_continuity','save_integrity'
];
const RESULT=['PASS','FAIL','NOT_CHECKED'];
const round2=x=>Number.isFinite(x)?Math.round(x*100)/100:null;
const minutes=t=>{
 if(!t || !Number.isFinite(t.day) || !Number.isFinite(t.hour))return null;
 return t.day*1440+t.hour*60+(t.minute||0);
};
const val=(x,k)=>x&&typeof x==='object'?x[k]:undefined;

/** Minimal mechanical checks, not a substitute for a fair-minded narrative review.
 * Missing evidence is NOT_CHECKED, never PASS. Does not mutate the world.
 */
export function auditProposedTurn({before,after,action,adjudication}={}){
 const checks=Object.fromEntries(FIELDS.map(k=>[k,'NOT_CHECKED']));
 const issues=[];
 const fail=(field,code,why)=>{checks[field]='FAIL';issues.push({code,field,why})};
 if(!before||!after||!action||!adjudication)
   return {checks,issues:[{code:'MISSING_EVIDENCE',why:'缺少前后状态、玩家指令或裁判证据'}],accepted:false};
 const prev=minutes(before.time),next=minutes(after.time);
 if(prev===null||next===null)issues.push({code:'TIME_MISSING',why:'时间字段未完整填写'});
 else if(next<prev)fail('causality','TIME_REVERSED','世界时间倒退');
 else if(next===prev && action.consumes_time===true)fail('causality','TIME_NOT_PAID','已执行的耗时行动未扣时间');
 else checks.causality='PASS';
 if(before.player?.id!==after.player?.id)fail('memory_continuity','PLAYER_CHANGED','玩家永久ID被修改');
 else checks.memory_continuity='PASS';
 for(const n of ['money','hp','stamina']){
  const x=val(after.player,n);
  if(!Number.isFinite(x)||x<0)fail('resource_conservation','INVALID_'+n.toUpperCase(),n+' 非法或缺失');
 }
 for(const [n,m] of [['hp','max_hp'],['stamina','max_stamina']])
  if(Number(after.player?.[n])>Number(after.player?.[m]))
   fail('resource_conservation','OVER_MAX_'+n.toUpperCase(),n+'超过最大值');
 for(const item of after.inventory||[])
  if(!Number.isInteger(item.quantity)||item.quantity<0)
   fail('resource_conservation','INVALID_ITEM_QUANTITY','背包含非法数量');
 const moneyDiff=(after.player?.money||0)-(before.player?.money||0);
 if(moneyDiff>0 && !adjudication.money_source)
   fail('resource_conservation','MONEY_NO_SOURCE','金钱增加但缺少来源凭证');
 if(moneyDiff<0 && !adjudication.money_sink)
   fail('resource_conservation','MONEY_NO_SINK','金钱扣除但未记入支付对象/花费');
 if(checks.resource_conservation!=='FAIL')checks.resource_conservation='PASS';
 if(action.kind==='pursuit'){
   const p=adjudication.pursuit;
   if(!p||!p.hasReason||!p.knowsDirection)
    fail('pursuit_motivation','PURSUIT_WITHOUT_BASIS','追击缺乏动机或目标位置线索');
   else if(p.chase===true && (p.stamina<12||p.minutesSpent>=p.timeBudget||(p.onDuty&&!p.inJurisdiction)||p.distance>p.range))
    fail('pursuit_motivation','PURSUIT_EXCEEDED_LIMIT','追击忽略体力、时限、职责或距离');
   else checks.pursuit_motivation='PASS';
 }
 if(adjudication.special_player_bonus||adjudication.forced_player_disaster)
   fail('actor_symmetry','PROTAGONIST_EXCEPTION','主角特权或刻意针对');
 if(adjudication.npc_used_hidden_player_info)
   fail('npc_knowledge','NPC_OMNISCIENCE','NPC使用了无法获得的玩家隐私信息');
 if(adjudication.narrated_success && adjudication.action_succeeded!==true)
   fail('story_consistency','NARRATIVE_OUTRUNS_RULES','旁白宣布成功但规则未结算成功');
 if(checks.story_consistency==='NOT_CHECKED' && typeof adjudication.narrated_success==='boolean' && typeof adjudication.action_succeeded==='boolean')
   checks.story_consistency='PASS';
 const accepted=issues.length===0;
 return {checks,issues,accepted,summary:accepted?'结构性硬条件未检出异常；未检查项目仍需人工核查。':'存在硬性冲突，禁止提交为成功结算。'};
}

/** Audit ONLY committed events. No hidden secrets are written to this public review. */
export function reviewAtTurn(root){
 const info=inspect(root),turn=info.turns;
 if(turn<10||turn%10!==0)return {created:false,next_at:(Math.floor(turn/10)+1)*10};
 const turns=info.events.filter(e=>e.type==='turn_committed').slice(-10);
 const scores=Object.fromEntries(FIELDS.map(k=>[k,{PASS:0,FAIL:0,NOT_CHECKED:0}]));
 const problems=[];
 for(const event of turns){
  for(const key of FIELDS){
   const status=event.gm_audit?.checks?.[key];
   const norm=RESULT.includes(status)?status:'NOT_CHECKED';
   scores[key][norm]++;
  }
  if(event.gm_audit?.issues?.length)
   problems.push({event_id:'EV'+String(event.seq).padStart(6,'0'),issues:event.gm_audit.issues});
 }
 const report={
  schema:1,protocol:'GM-QA-001',kind:'narrative_and_rules_review',
  at_turn:turn,range:[turn-9,turn],event_hash:info.last_hash,
  source_event_ids:turns.map(e=>'EV'+String(e.seq).padStart(6,'0')),
  evidence:scores,issues:problems,
  next_work:problems.length?'先修证据支持的FAIL，再补缺失测试':'补齐NOT_CHECKED的验证证据；避免虚报全PASS',
  constraint:'只有十回合已提交事件可产生评审；不能修改过去事件或世界数值。'
 };
 const folder=join(root,'gm_reviews');mkdirSync(folder,{recursive:true});
 const dest=join(folder,'review_'+String(turn).padStart(4,'0')+'.json');
 const out=JSON.stringify(report,null,2)+'\n';
 if(existsSync(dest)){
  if(readFileSync(dest,'utf8')!==out)throw Error('历史GM复盘存在冲突，拒绝覆盖');
  return {created:false,exists:true,turn,report_path:dest};
 }
 writeFileSync(dest,out);
 return {created:true,turn,report_path:dest,issues:problems.length};
}
if(process.argv[1]?.endsWith('gm_quality_gate.mjs')){
 try{
  const root=process.argv[3]||new URL('../campaigns/first-life/',import.meta.url).pathname;
  console.log(JSON.stringify(reviewAtTurn(root),null,2));
 }catch(err){console.error('BLOCKED:',err.message);process.exitCode=1;}
}
