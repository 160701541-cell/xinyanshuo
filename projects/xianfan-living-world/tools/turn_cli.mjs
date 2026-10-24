import {readFileSync,writeFileSync,copyFileSync,renameSync,mkdirSync,rmSync,mkdtempSync,existsSync} from 'node:fs';
import {join} from 'node:path';
import {restore} from './restore_campaign.mjs';
import {inspect,digest,checkpoint} from './campaign_guard.mjs';
import {reviewAtTurn} from './gm_quality_gate.mjs';
import {calculateAction,commitPreview} from './numeric_engine.mjs';
import {auditProposedTurn} from './gm_quality_gate.mjs';

const die=s=>{throw Error(s)};
export function processTurn(root,command,save=false){
 const source=restore(root),before=inspect(root);
 if(!before.full_state_verified)die('读取权威状态失败');
 const preview=calculateAction(source,command,before.events);
 if(!save)return {preview:true,rule:preview.rule_version,after:preview.after,receipts:preview.receipts,duration:preview.duration_minutes};
 const result=commitPreview(source,before.events,preview);
 const audit=auditProposedTurn({before:source,after:result.state,action:{kind:command.type,consumes_time:true},adjudication:{action_succeeded:true,narrated_success:false,money_source:result.receipts.find(r=>r.to===source.player.id),money_sink:result.receipts.find(r=>r.from===source.player.id)}});
 if(!audit.accepted)die('GM质量门禁失败: '+JSON.stringify(audit.issues));
 result.event.gm_audit=audit;
 result.event.hash=digest(Object.fromEntries(Object.entries(result.event).filter(([k])=>k!=='hash')));
 const index=structuredClone(before.index);
 index.last_event='EV'+String(result.event.seq).padStart(6,'0');
 index.last_event_hash=result.event.hash;
 index.full_state_sha256=digest(result.state);
 index.turns_completed=result.event.turn_id;
 index.time=result.state.time.display;
 index.player={...index.player,hp:result.state.player.hp,stamina:result.state.player.stamina,copper:result.state.player.money};
 index.family={...index.family,cash:result.state.family.cash,grain_dou:result.state.family.grain_dou};
 index.sync_status='PENDING_GITHUB';
 const outputs={'game_state.json':JSON.stringify(result.state,null,2)+'\n','events.jsonl':result.events.map(e=>JSON.stringify(e)).join('\n')+'\n','campaign_index.json':JSON.stringify(index,null,2)+'\n'};
 const stage=mkdtempSync(join(root,'.turn-stage-'));
 try{
  for(const [name,content] of Object.entries(outputs))writeFileSync(join(stage,name),content);
  const staged=inspect(stage);
  if(staged.turns!==index.turns_completed)die('提交前回合数不符');
  const lock=join(root,'.turn-lock');
  mkdirSync(lock);
  try{
   for(const name of Object.keys(outputs))if(existsSync(join(root,name)))copyFileSync(join(root,name),join(stage,name+'.before'));
   try{for(const name of Object.keys(outputs))renameSync(join(stage,name),join(root,name));}
   catch(error){for(const name of Object.keys(outputs))if(existsSync(join(stage,name+'.before')))copyFileSync(join(stage,name+'.before'),join(root,name));throw error;}
  }finally{rmSync(lock,{recursive:true,force:true});}
  inspect(root);
  // Keep the original event ledger intact; summaries are additional derived indexes.
  const memory_checkpoint=index.turns_completed%10===0?checkpoint(root):{created:false};
  const gm_review=index.turns_completed%10===0?reviewAtTurn(root):{created:false};
  return {ok:true,event_id:index.last_event,turn:index.turns_completed,after:preview.after,receipts:preview.receipts,gm_audit:audit.checks,memory_checkpoint,gm_review,github_sync:'PENDING_GITHUB'};
 }finally{rmSync(stage,{recursive:true,force:true});}
}
if(process.argv[1]?.endsWith('turn_cli.mjs')){
 try{
  const command=JSON.parse(readFileSync(process.argv[3],'utf8'));
  const root=process.argv[4]||new URL('../campaigns/first-life/',import.meta.url).pathname;
  console.log(JSON.stringify(processTurn(root,command,process.argv[2]==='commit'),null,2));
 }catch(e){console.error('BLOCKED',e.message);process.exitCode=1;}
}
