import {verifyEvents} from './campaign_guard.mjs';

const stop=(code,message)=>{throw Object.assign(new Error(message),{code});};
export const asUInt=(n,label,min=0)=>{
 if(!Number.isSafeInteger(n)||n<min)stop('BAD_NUMBER',`${label}必须是≥${min}的安全整数`);
 return n;
};
export function verifyNumericState(s){
 if(!s?.player?.id||!s?.family?.id)stop('MISSING_STATE','玩家或家庭权威档案缺失');
 for(const [k,n] of Object.entries({playerCopper:s.player.money,familyCopper:s.family.cash,familyGrain:s.family.grain_dou,HP:s.player.hp,maxHP:s.player.max_hp,stamina:s.player.stamina,maxStamina:s.player.max_stamina,EXP:s.player.exp}))asUInt(n,k);
 if(s.player.hp>s.player.max_hp||s.player.stamina>s.player.max_stamina)stop('VITALS_INVALID','生命或精力超出最大值');
 for(const o of s.inventory||[])asUInt(o.quantity,`物品${o.id}`);
 for(const [id,a] of Object.entries(s.economy?.accounts||{})){
  if(!a.source_event_id)stop('NO_PROVENANCE',`账户${id}没有来源事件`);
  for(const [asset,n] of Object.entries(a.balances||{}))asUInt(n,`${id}.${asset}`);
 }
 return true;
}
function wallet(s,id,asset){
 if(id===s.player.id){
  if(asset==='copper')return {get:()=>s.player.money,set:v=>s.player.money=v};
  if(asset==='grain_dou')return {get:()=>s.player.grain_dou??0,set:v=>s.player.grain_dou=v};
 }
 if(id===s.family.id){
  if(asset==='copper')return {get:()=>s.family.cash,set:v=>s.family.cash=v};
  if(asset==='grain_dou')return {get:()=>s.family.grain_dou,set:v=>s.family.grain_dou=v};
 }
 const a=s.economy?.accounts?.[id];
 if(a?.source_event_id&&Object.hasOwn(a.balances||{},asset))return {get:()=>a.balances[asset],set:v=>a.balances[asset]=v};
 stop('ACCOUNT_UNKNOWN',`未知账户${id}，不允许临时编造店铺金钱`);
}
export function transferLedger(s,a,events){
 const {from,to,asset,quantity,auth_id}=a;
 if(!['copper','grain_dou'].includes(asset))stop('UNKNOWN_ASSET','没有该资产的正式计量规则');
 asUInt(quantity,'转账金额',1);
 if(!from||!to||from===to)stop('BAD_TRANSFER','交易账户不合法');
 if(from!==s.player.id){
  const p=s.authorizations?.[auth_id];
  if(!p||p.from!==from||p.to!==to||p.asset!==asset||p.used||p.max_quantity<quantity||!p.source_event_id)stop('AUTH_REQUIRED','不能替NPC/家人擅自作主');
  if(!Array.isArray(events)||!events.some(e=>e.type==='npc_authorized_transfer'&&e.authorization_id===auth_id&&e.actor_id===from&&e.to===to&&e.asset===asset&&e.max_quantity>=quantity&&'EV'+String(e.seq).padStart(6,'0')===p.source_event_id))stop('AUTH_EVENT_NOT_FOUND','授权没有在真实事件账本中登记');
  verifyEvents(events);p.used=true;
 }
 const x=wallet(s,from,asset),y=wallet(s,to,asset),beforeX=asUInt(x.get(),'转出前余额'),beforeY=asUInt(y.get(),'转入前余额');
 if(beforeX<quantity)stop('INSUFFICIENT','真实库存不足');
 if(!Number.isSafeInteger(beforeY+quantity))stop('OVERFLOW','余额溢出');
 x.set(beforeX-quantity);y.set(beforeY+quantity);
 return {asset,from,to,quantity,before:{[from]:beforeX,[to]:beforeY},after:{[from]:beforeX-quantity,[to]:beforeY+quantity},balanced:beforeX+beforeY===beforeX-quantity+beforeY+quantity};
}
