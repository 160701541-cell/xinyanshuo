import {digest,verifyEvents} from './campaign_guard.mjs';
import {verifyNumericState,asUInt,transferLedger} from './numeric_accounts.mjs';
export {verifyNumericState} from './numeric_accounts.mjs';

export const NUMERIC_VERSION='number-authority-1.0.0';
export const RULES=Object.freeze({speech_chars_per_minute:90,rest_stamina_minutes_per_point:10,max_rest_minutes:480,max_wait_minutes:60,transfer_minutes:1});
const stop=(code,message)=>{throw Object.assign(new Error(message),{code});};
const clock=t=>{
 asUInt(t.day,'日期',1);asUInt(t.hour,'小时');asUInt(t.minute,'分钟');
 if(t.hour>=24||t.minute>=60)stop('BAD_TIME','非法时间');
 return (t.day-1)*1440+t.hour*60+t.minute;
};
function advance(s,delta){
 asUInt(delta,'行动时长');const old=clock(s.time),next=old+delta;
 if(Math.floor(old/1440)!==Math.floor(next/1440))stop('DAILY_SIM_NOT_IMPLEMENTED','跨日天气人口物价未接入真实日结算，禁止跳过');
 s.time.hour=Math.floor((next%1440)/60);s.time.minute=next%60;
 s.time.display=`承平${s.time.regnal_year===3?'三':s.time.regnal_year}年 · 第${s.time.day}日 · ${String(s.time.hour).padStart(2,'0')}:${String(s.time.minute).padStart(2,'0')}`;
}
const snapshot=s=>({time:clock(s.time),player_money:s.player.money,family_money:s.family.cash,family_grain:s.family.grain_dou,hp:s.player.hp,stamina:s.player.stamina});
export function calculateAction(original,action,events=[]){
 verifyNumericState(original);
 if(!action || !['speak','wait','rest','transfer'].includes(action.type))stop('RULE_NOT_IMPLEMENTED','该行为无权威计算公式，拒绝GM凭感觉增加数值');
 if(action.numeric_override!==undefined||action.force_success!==undefined)stop('GM_CHEAT','禁止GM指定计算结果');
 const s=structuredClone(original),before=snapshot(s),receipts=[];
 switch(action.type){
  case 'speak':{
   if(typeof action.text!=='string'||!action.text.trim())stop('NO_SPEECH','对话不能为空');
   if([...action.text].length>10000)stop('TOO_LONG','对话超限');
   advance(s,Math.max(1,Math.ceil([...action.text].length/RULES.speech_chars_per_minute)));break;
  }
  case 'wait':{
   asUInt(action.minutes,'等待分钟',1);
   if(action.minutes>RULES.max_wait_minutes)stop('TIME_LIMIT','缺少长时间结算逻辑');
   advance(s,action.minutes);break;
  }
  case 'rest':{
   asUInt(action.minutes,'休息分钟',1);
   if(action.minutes>RULES.max_rest_minutes)stop('REST_LIMIT','单次休息超上限');
   const gain=Math.floor(action.minutes/RULES.rest_stamina_minutes_per_point);
   s.player.stamina=Math.min(s.player.max_stamina,s.player.stamina+gain);
   advance(s,action.minutes);
   receipts.push({effect:'stamina',source:'rest',minutes:action.minutes,rate:RULES.rest_stamina_minutes_per_point,before:before.stamina,after:s.player.stamina});break;
  }
  case 'transfer':{
   receipts.push(transferLedger(s,action,events));advance(s,RULES.transfer_minutes);break;
  }
 }
 verifyNumericState(s);
 return {ok:true,rule_version:NUMERIC_VERSION,command:structuredClone(action),state:s,receipts,before,after:snapshot(s),duration_minutes:clock(s.time)-before.time,state_hash:digest(s)};
}
export function commitPreview(original,events,preview){
 if(!preview?.ok||!Array.isArray(events)||!events.length)stop('INVALID_COMMIT','结算前预览或事件记录缺失');
 verifyEvents(events);
 const last=events.at(-1);
 if(last.state_hash!==digest(original))stop('STATE_CHANGED','原状态与事件链不匹配');
 const computed=calculateAction(original,preview.command,events);
 if(preview.state_hash!==computed.state_hash)stop('PREVIEW_TAMPERED','预览结果被修改');
 const s=computed.state,seq=last.seq+1;s.last_event_id='EV'+String(seq).padStart(6,'0');
 const event={seq,type:'turn_committed',turn_id:events.filter(e=>e.type==='turn_committed').length+1,prev_hash:last.hash,rule_version:NUMERIC_VERSION,command:computed.command,receipts:computed.receipts,before:computed.before,after:computed.after,duration_minutes:computed.duration_minutes,state_hash:digest(s)};
 event.hash=digest(event);
 return {state:s,event,events:[...events,event]};
}
