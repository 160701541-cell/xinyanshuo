import {createHash} from 'node:crypto';
import {digest,verifyEvents} from './campaign_guard.mjs';
import {verifyNumericState} from './numeric_accounts.mjs';

export const FISHING_VERSION='fishbasket-0.1.0';
const fail=(code,message)=>{const e=new Error(message);e.code=code;throw e;};
const hash=(s)=>createHash('sha256').update(s).digest('hex');
const roll=(seed,label,n)=>Number(BigInt('0x'+hash(seed+'|fishbasket-0.1.0|'+label).slice(0,13))%BigInt(n));
const eventId=n=>'EV'+String(n).padStart(6,'0');
export const RECIPE=Object.freeze({id:'woven_fish_basket',name:'简易编织鱼笼',
 inputs:[{id:'flexible_branch',quantity:5},{id:'bast_fiber',quantity:4}],
 gather_minutes:25,weave_minutes:50,check_bank_minutes:15,
 stamina_gather:4,stamina_weave:6});
const addMinutes=(s,n)=>{
 const old=s.time.hour*60+s.time.minute,next=old+n;
 if(next>=24*60)fail('DAY_BOUNDARY','跨日未建立生态日结算');
 s.time.hour=Math.floor(next/60);s.time.minute=next%60;
 s.time.display='承平'+(s.time.regnal_year===3?'三':s.time.regnal_year)+'年 · 第'+s.time.day+'日 · '+String(s.time.hour).padStart(2,'0')+':'+String(s.time.minute).padStart(2,'0');
};
const debit=(nodes,id,quantity)=>{
 let rest=quantity;
 for(const node of nodes.filter(x=>x.resource===id)){
  const part=Math.min(node.quantity,rest);node.quantity-=part;rest-=part;if(!rest)break;
 }
 if(rest)fail('MATERIAL_SHORTAGE',id+'资源节点库存不足');
};
const put=(s,id,name,qty,category)=>{
 const item=s.inventory.find(x=>x.id===id);
 if(item)item.quantity+=qty;
 else s.inventory.push({id,name,quantity:qty,equipped:false,category,source:'craft:'+FISHING_VERSION});
};
export function executeFishBasketTurn(original,events){
 verifyEvents(events);verifyNumericState(original);
 if(digest(original)!==events.at(-1)?.state_hash||original.last_event_id!==eventId(events.length))
  fail('STALE_SAVE','权威档与哈希账本不一致');
 if(original.location_id!=='shiqiao'||!original.ecology?.['shiqiao-outskirts-v1'])
  fail('WRONG_REGION','当前不在已登记的荒沟与河岸生态区');
 if(original.player.stamina<RECIPE.stamina_gather+RECIPE.stamina_weave)
  fail('STAMINA_LOW','采集与编织所需精力不足');
 if(events.some(e=>e.action==='weave_fish_basket_sister_looks_for_loaches'))
  fail('ACTION_REPLAY','不能反复复制同一次捕鱼场景');
 const s=structuredClone(original),eco=s.ecology['shiqiao-outskirts-v1'],start=s.time.hour*60+s.time.minute;
 const receipts=[],observations=[];
 // Friend is entitled to say no. This decision derives from world seed + her stable ID.
 const sisterHere=s.npc_schedules?.CFNPC00003?.activity==='helping_sift_herbs';
 const sisterWilling=sisterHere&&roll(s.world_seed,'CFNPC00003|mudbank|day'+s.time.day,100)<78;
 observations.push({type:'sister_choice',npc_id:'CFNPC00003',invited:true,agreed:sisterWilling});
 // Request includes 'weave basket' and 'ask sister'; these are separable, and no loach is guaranteed.
 const stocks=RECIPE.inputs.map(r=>({id:r.id,needed:r.quantity,found:eco.nodes.filter(n=>n.resource===r.id).reduce((sum,n)=>sum+n.quantity,0)}));
 const enough=stocks.every(x=>x.found>=x.needed);
 if(enough){
  for(const r of RECIPE.inputs)debit(eco.nodes,r.id,r.quantity);
  addMinutes(s,RECIPE.gather_minutes+RECIPE.weave_minutes);
  s.player.stamina-=RECIPE.stamina_gather+RECIPE.stamina_weave;
  put(s,'woven_fish_basket','简易编织鱼笼',1,'渔具');
  receipts.push({type:'world_gather_and_craft',materials:RECIPE.inputs.map(r=>({...r})),
   ecology_zone:'shiqiao-outskirts-v1',product_id:'woven_fish_basket',product_quantity:1,
   material_origin:'registered_habitat_nodes',duration_minutes:75,stamina_cost:10});
  observations.push({type:'fishbasket_crafted',success:true});
 }else{
  addMinutes(s,10);
  s.player.stamina-=1;
  observations.push({type:'fishbasket_crafted',success:false,reason:'现有可验证材料库存不足',stocks});
 }
 // The sister may search plausible wet mud independently. There is currently NO registered
 // loach population or deterministic capture mechanics; do not produce an animal or money.
 if(sisterWilling){
  addMinutes(s,RECIPE.check_bank_minutes);
  s.npc_schedules.CFNPC00003={
    ...s.npc_schedules.CFNPC00003,activity:'examining_wet_mud_for_loach_signs',
    last_seen_location:'石桥村荒沟近水泥岸',updated_at:s.time.display,
    task_result:'searched_mudbank; no verified loach capture'};
  observations.push({type:'loach_search',npc_id:'CFNPC00003',searched:true,
   captured:0,capture_proven:false,note:'无泥鳅实体与捕获规则；没有任何已核验渔获'});
 }else observations.push({type:'loach_search',npc_id:'CFNPC00003',searched:false,
   note:'NPC未确认愿意挖泥鳅；不得强制其行为'});
 // Maize and alcohol were not in player inventory. Urine is not a game-economy item.
 // Preparing alcoholic/urine maize bait must not silently mint these missing ingredients.
 const corn=s.inventory.find(i=>i.id==='maize_kernel'&&i.quantity>0);
 const wine=s.inventory.find(i=>i.id==='alcohol'&&i.quantity>0);
 const baitReady=!!corn&&!!wine;
 observations.push({type:'bait_plan',corn_available:!!corn,alcohol_available:!!wine,
  status:baitReady?'UNIMPLEMENTED_RECIPE':'BLOCKED_MISSING_INGREDIENTS',
  note:'不自动生成玉米/酒，也不以人体排泄物保证诱鱼效果'});
 // Fish basket is carried, not deployed: safe watercourse and fish population remain unregistered.
 observations.push({type:'deployment',status:'not_deployed',
   note:'水域准入、鱼类实体及饵料效力未确认，不宣称鱼笼已捕到鱼'});
 verifyNumericState(s);
 const seq=events.length+1;s.last_event_id=eventId(seq);
 const event={seq,type:'turn_committed',turn_id:events.filter(e=>e.type==='turn_committed').length+1,
  prev_hash:events.at(-1).hash,rule_version:FISHING_VERSION,
  action:'weave_fish_basket_sister_looks_for_loaches',
  observations,receipts,duration_minutes:s.time.hour*60+s.time.minute-start,
  before:{time:original.time.display,stamina:original.player.stamina,money:original.player.money},
  after:{time:s.time.display,stamina:s.player.stamina,money:s.player.money},
  source_stock:stocks,bait_prepared:false,fish_caught:0,loach_caught:0,
  state_hash:digest(s)};
 event.hash=digest(event);
 return{state:s,event,events:[...events,event],public:{
  sisterWilling,crafted:enough,baitReady:false,fishCaught:0,loachCaught:0,
  observations,receipts,after:event.after}};
}
