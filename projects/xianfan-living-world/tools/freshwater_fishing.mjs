import {createHash} from 'node:crypto';
import {readFileSync} from 'node:fs';
import {digest,verifyEvents} from './campaign_guard.mjs';
import {verifyNumericState} from './numeric_accounts.mjs';
const config=JSON.parse(readFileSync(new URL('../data/freshwater_habitat_v1.json',import.meta.url),'utf8'));
const err=(code,reason)=>{throw Object.assign(new Error(reason),{code});};
const rng=(seed,key,max)=>Number(BigInt('0x'+createHash('sha256').update(seed+'|freshwater-0.1.0|'+key).digest('hex').slice(0,13))%BigInt(max));
const clock=s=>(s.time.day-1)*1440+s.time.hour*60+s.time.minute;
const eventId=n=>'EV'+String(n).padStart(6,'0');
export function inspectWaterSite(s){
 const h=config.site,t=config.thresholds;
 const distance=Math.hypot(s.position.x-h.x,s.position.y-h.y);
 return {site_id:h.id,site_name:h.name,depth_cm:h.depth_cm,flow_cm_per_s:h.flow_cm_per_s,
  distance_from_player_m:Math.round(distance*100)/100,
  safe_for_bank_installation:h.depth_cm<=t.max_depth_cm&&h.flow_cm_per_s<=t.max_flow_cm_per_s&&h.human_path_distance_m>=t.min_path_clearance_m&&distance<=t.max_distance_m&&h.owner==='unclaimed_commons',
  note:'这些数值是游戏地块参数，不是现场真实水深或仪器测量'};
}
function initializeWaterEcology(s){
 const zone=s.ecology?.[config.region_id];
 if(!zone)err('NO_REGION','当前不是石桥村荒沟区');
 if(zone.freshwater)return zone.freshwater;
 const stocks=config.species.map(spec=>{
  const present=rng(s.world_seed,spec.id+'|population-present',100)<spec.spawn_chance_percent;
  const population=present?spec.min_population+rng(s.world_seed,spec.id+'|population-count',spec.extra_population_range):0;
  return {id:spec.id,name:spec.name,population,initial_population:population,harvested:0};
 });
 zone.freshwater={schema:config.schema,version:config.version,site:{...config.site},stocks,
  installed_gear:[],catch_events:[],last_population_tick:null,
  model:'world_seed + fixed habitat definitions; not spawned as a reward for player'};
 return zone.freshwater;
}
export function deployBasket(original,events){
 verifyNumericState(original);verifyEvents(events);
 if(!events.length||digest(original)!==events.at(-1).state_hash||original.last_event_id!==eventId(events.length))err('STATE_HASH','历史存档与账本不一致');
 if(original.ecology?.[config.region_id]===undefined)err('OUT_OF_REGION','未在可登记的河岸');
 if(events.some(e=>e.action==='deploy_fish_basket_in_shiqiao_bay'))err('DUPLICATE_ACTION','同一次放置已完成，不得刷出新鱼笼');
 const basket=original.inventory.find(i=>i.id==='woven_fish_basket'&&i.quantity>0);
 if(!basket||!basket.reinforcement||basket.reinforcement.layers<1)err('NO_READY_BASKET','没有完成加固的鱼笼');
 const site=inspectWaterSite(original);
 if(!site.safe_for_bank_installation)err('UNSAFE_SITE','当前地块不适宜布设');
 if(original.player.stamina<config.installation.stamina_cost)err('STAMINA_LOW','体力不足');
 const s=structuredClone(original),water=initializeWaterEcology(s);
 if(water.installed_gear.some(g=>g.id==='GEAR-SH-RIVER-0001'))err('GEAR_CONFLICT','地块已登记同编号鱼笼');
 const item=s.inventory.find(i=>i.id==='woven_fish_basket');
 item.quantity--;s.inventory=s.inventory.filter(i=>i.quantity>0);
 const start=clock(s);
 const now=start+config.installation.minutes;
 if(Math.floor(start/1440)!==Math.floor(now/1440))err('CROSS_DAY_NOT_SUPPORTED','需要真实跨日生态结算');
 s.time.hour=Math.floor(now%1440/60);s.time.minute=now%60;
 s.time.display='承平三年 · 第'+s.time.day+'日 · '+String(s.time.hour).padStart(2,'0')+':'+String(s.time.minute).padStart(2,'0');
 s.player.stamina-=config.installation.stamina_cost;
 const gear={id:'GEAR-SH-RIVER-0001',type:'woven_fish_basket',owner:s.player.id,
  site_id:config.site.id,x:config.site.x,y:config.site.y,
  source_event_id:eventId(events.length+1),placed_at:s.time.display,placed_clock_minutes:clock(s),
  reinforcement:{...basket.reinforcement},bait_id:null,anchor:config.site.structure_anchor,
  status:'deployed_waiting',catch_count:0,checked_at:null};
 water.installed_gear.push(gear);
 s.position={x:config.site.x,y:config.site.y};s.sub_location=config.site.name;
 s.last_event_id=eventId(events.length+1);
 verifyNumericState(s);
 const event={seq:events.length+1,type:'turn_committed',turn_id:events.filter(e=>e.type==='turn_committed').length+1,
  action:'deploy_fish_basket_in_shiqiao_bay',rule_version:config.version,prev_hash:events.at(-1).hash,
  duration_minutes:config.installation.minutes,stamina_cost:config.installation.stamina_cost,
  site:{site_id:site.site_id,depth_cm:site.depth_cm,flow_cm_per_s:site.flow_cm_per_s},
  inventory_debit:[{id:'woven_fish_basket',quantity:1}],installed_gear_id:gear.id,
  wildlife_initial_stock:water.stocks.map(({id,population})=>({id,population})),
  capture_status:'not_checked',catch_count:0,actual_automatic_capture:false,
  before:{time:original.time.display,stamina:original.player.stamina,copper:original.player.money},
  after:{time:s.time.display,stamina:s.player.stamina,copper:s.player.money},
  state_hash:digest(s)};
 event.hash=digest(event);
 return {state:s,event,events:[...events,event],public:{site,gear,stocks:water.stocks,after:event.after}};
}
