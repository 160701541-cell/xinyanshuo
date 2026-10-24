import {createHash} from 'node:crypto';
import {readFileSync} from 'node:fs';
import {digest,verifyEvents} from './campaign_guard.mjs';
import {calculateAction,verifyNumericState} from './numeric_engine.mjs';
const cfg=JSON.parse(readFileSync(new URL('../data/medicinal_foraging_rules_v1.json',import.meta.url),'utf8'));
export const BOTANY_VERSION=cfg.version;
const fail=(code,message)=>{const e=new Error(message);e.code=code;throw e;};
const draw=(seed,id,max)=>{
 if(!Number.isInteger(max)||max<1)fail('RNG_RANGE','Invalid random range');
 const hex=createHash('sha256').update(seed+'|botany-v1|'+id).digest('hex');
 return Number(BigInt('0x'+hex.slice(0,13))%BigInt(max));
};
const clock=s=>(s.time.day-1)*1440+s.time.hour*60+s.time.minute;

export function ensureBotany(s){
 const biome=s.ecology?.['shiqiao-outskirts-v1'];
 if(!biome||biome.location_id!=='shiqiao')fail('BIOME_MISSING','所在区域没有可验证的生态地块');
 if(!biome.botany){
  biome.botany={
   schema:'botany-zone-1',spawn_seed:s.world_seed,
   generated_from:'world_seed + static habitat templates only; independent of player intent',
   nodes:cfg.habitats.map(h=>{
    const exists=draw(s.world_seed,h.id+'|spawn',100)<h.spawn_out_of_100;
    const quantity=exists?h.base+draw(s.world_seed,h.id+'|count',h.extra_max):0;
    return {id:h.id,name:h.name,resource:h.species,x:h.x,y:h.y,
      quantity,initial_quantity:quantity,rights:h.rights,growth_stage:'mature',version:cfg.version};
   }),history:[]
  };
 }
 return biome.botany;
}
export function previewHerbForage(original,events,options={}){
 if(options.action && options.action!=='forage_medicinal_herbs')fail('ACTION_UNKNOWN','不同的玩家意图不能混用本规则');
 verifyEvents(events);verifyNumericState(original);
 if(digest(original)!==events.at(-1)?.state_hash)fail('STATE_MISMATCH','上次事件与存档不一致');
 if(original.last_event_id!=='EV'+String(events.length).padStart(6,'0'))fail('EVENT_MISMATCH','事件ID不连续');
 if(original.location_id!=='shiqiao'||!original.ecology?.['shiqiao-outskirts-v1'])fail('WRONG_REGION','没有抵达已登记的荒沟生态区');
 if(original.player.stamina<cfg.search_rules.stamina)fail('STAMINA_INSUFFICIENT','体力不够继续搜寻');
 const s=structuredClone(original),before={time:s.time.display,stamina:s.player.stamina,hp:s.player.hp,money:s.player.money},start=clock(s);
 const botany=ensureBotany(s),observed=[],receipts=[],narrative=[];
 const sister=!!s.known_npcs?.find(n=>n.id==='CFNPC00003'&&n.alive) &&
  s.npc_schedules?.CFNPC00003?.activity==='with_player_by_bushes';
 const sisterHelps=sister&&draw(s.world_seed,'CFNPC00003|herb-forage|day'+s.time.day,10)<8;
 narrative.push({type:'sister_decision',npc_id:'CFNPC00003',present:sister,helps:sisterHelps,
    note:sisterHelps?'自愿在荒沟一带协助辨认并整理采下的普通野草':'决定暂时休息或不协助本轮采药；仍有自主权'});
 const startPos={...s.position};
 for(const h of cfg.habitats){
  const node=botany.nodes.find(n=>n.id===h.id);
  const distance=Math.hypot(node.x-startPos.x,node.y-startPos.y);
  if(distance>cfg.search_rules.max_search_distance_m)continue;
  if(node.quantity<=0)continue;
  const p=cfg.plants[node.resource];
  if(p.recognition==='requires_cultivator_or_appraiser'){
   observed.push({node_id:node.id,kind:'unknown_unharvested',x:node.x,y:node.y,
     note:'植物外观异常但未鉴定，禁止直接认定灵草或采走'});
   continue;
  }
  if(p.recognition==='unknown'){
   observed.push({node_id:node.id,kind:'unidentified_unharvested',x:node.x,y:node.y,
     note:'外形未确认，避免误采有毒或受保护根茎'});
   continue;
  }
  const picked=Math.min(h.harvest_cap, node.quantity,cfg.search_rules.max_collect_per_species);
  if(!picked)continue;
  node.quantity-=picked;
  let stack=s.inventory.find(it=>it.id===p.item_id);
  if(stack)stack.quantity+=picked;
  else s.inventory.push({id:p.item_id,name:p.item_name,quantity:picked,category:'鲜采普通草药',
    source:'wild_botany:'+node.id,equipped:false,valuation_wen:null,identification:'unverified_market_grade'});
  observed.push({node_id:node.id,kind:'ordinary_herb_collected',species:p.name,quantity:picked,
    x:node.x,y:node.y});
  receipts.push({type:'wild_harvest',source_node:node.id,resource:p.item_id,quantity:picked,
    node_remaining:node.quantity,unit_price_wen:null,market_quote:'NOT_QUOTED'});
  botany.history.push({event_id:'EV'+String(events.length+1).padStart(6,'0'),node_id:node.id,
    resource:p.item_id,quantity:picked,owner:s.player.id});
 }
 // This single 55 minute search includes local wandering, examination and harvest.
 const time=calculateAction(s,{type:'wait',minutes:cfg.search_rules.minutes});
 s.time=time.state.time;
 s.player.stamina-=cfg.search_rules.stamina;
 narrative.push({type:'search_completed',species_count:receipts.length,known_sale_price:false});
 if(s.npc_schedules?.CFNPC00003 && sister){
  s.npc_schedules.CFNPC00003.updated_at=s.time.display;
  s.npc_schedules.CFNPC00003.activity=sisterHelps?'helping_sift_herbs':'resting_nearby';
 }
 // Don't tick wildlife or claim the snare's outcome: it has no implemented capture engine.
 const trap=s.ecology['shiqiao-outskirts-v1'].deployed_traps?.find(t=>t.owner===s.player.id);
 if(trap)trap.capture_status='pending_animal_simulation';
 verifyNumericState(s);
 const seq=events.length+1;
 s.last_event_id='EV'+String(seq).padStart(6,'0');
 const event={seq,type:'turn_committed',turn_id:events.filter(e=>e.type==='turn_committed').length+1,
  prev_hash:events.at(-1).hash,rule_version:cfg.version,
  action:'forage_medicinal_herbs',duration_minutes:clock(s)-start,
  observations:observed,narrative,receipts,
  before,after:{time:s.time.display,stamina:s.player.stamina,hp:s.player.hp,money:s.player.money},
  prices_status:'UNKNOWN_NOT_QUOTED',trap_status:'NOT_CHECKED',
  state_hash:digest(s)};
 event.hash=digest(event);
 return {state:s,event,events:[...events,event],public:{
   npc_sex:s.known_npcs.find(n=>n.id==='CFNPC00003').sex,
   sister_helps:sisterHelps,observations:observed,receipts,
   before,after:event.after,duration_minutes:event.duration_minutes,
   sale_price:'未询价',spirit_plant:'没有确认可采的灵植',trap:'未检查'}};
}
