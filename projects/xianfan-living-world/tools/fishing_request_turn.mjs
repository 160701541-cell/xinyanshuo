import {createHash} from 'node:crypto';
import {digest,verifyEvents} from './campaign_guard.mjs';
import {verifyNumericState} from './numeric_accounts.mjs';
export const VERSION='fishing-request-0.1.0';
const id=n=>'EV'+String(n).padStart(6,'0');
const roll=(seed,key)=>Number(BigInt('0x'+createHash('sha256').update(seed+'|'+VERSION+'|'+key).digest('hex').slice(0,13))%100n);
const guard=(test,code)=>{if(!test)throw Object.assign(new Error(code),{code})};
export function requestFoodAndRods(original,events,registry){
 verifyEvents(events);verifyNumericState(original);
 guard(digest(original)===events.at(-1).state_hash,'STATE_HASH_CONFLICT');
 guard(original.last_event_id===id(events.length),'EVENT_ORDER_CONFLICT');
 guard(registry.npcs?.CFNPC00003?.sex==='女','SISTER_IDENTITY_CONFLICT');
 guard(!events.some(e=>e.action==='request_food_and_rod_pair'),'ACTION_REPLAY');
 const s=structuredClone(original),before={time:s.time.display,stamina:s.player.stamina,money:s.player.money};
 const sis=s.npc_schedules?.CFNPC00003;
 guard(!!sis,'SISTER_NOT_LOCATED');
 const temperament=registry.npcs.CFNPC00003.base_temperament.scores;
 const cooperate=roll(s.world_seed,'CFNPC00003|food-water-request|day'+s.time.day)<temperament.cooperation+12;
 // This action is the conversation and initiation only: physical round trip and supplies
 // must be resolved by future world-simulation events, not teleported into inventory.
 const duration_minutes=1,minutes=s.time.hour*60+s.time.minute+duration_minutes;
 s.time.hour=Math.floor(minutes/60);s.time.minute=minutes%60;
 s.time.display='承平三年 · 第'+s.time.day+'日 · '+String(s.time.hour).padStart(2,'0')+':'+String(s.time.minute).padStart(2,'0');
 s.npc_schedules.CFNPC00003={...sis,activity:cooperate?'walking_home_to_ask_for_food_and_water':'staying_near_creek',
  last_seen_location:cooperate?'离开村外荒沟，向钱家院落方向走去':'村外荒沟附近',
  updated_at:s.time.display,
  request:{food:'ask_household',water:'ask_household',delivery:'pending',ownership:'household_requires_agreement'},
  note:'尚未确定家庭现有可携带熟食或容器，禁止凭空登记'};
 s.fishing_requests={...(s.fishing_requests||{}),rod_pair:{
  target_count:2,craft_count:0,status:'pending_materials_and_validated_hook_line_recipe',
  expected_users:['CFPLAYER00001','CFNPC00003'],required:'杆材、可靠鱼线、鱼钩，须实物和工艺验证'
 },bait:{ground_grain:'proposed_only',rotten_meat:'proposed_only',worms:'proposed_only',insects:'proposed_only',frogs:'proposed_only',fry:'proposed_only',
  wine:'missing',corn:'missing',urine:'not_registered',status:'not_made',
  caution:'不能把臭味增强直接等同于必然增加捕获概率；腐败肉及尿液存在卫生风险'}};
 const seq=events.length+1;s.last_event_id=id(seq);
 const event={seq,type:'turn_committed',turn_id:events.filter(e=>e.type==='turn_committed').length+1,
  prev_hash:events.at(-1).hash,rule_version:VERSION,action:'request_food_and_rod_pair',
  intent:'妹妹先回家争取带食物和水；打算取鱼饵并各做一根鱼竿',
  npc_decision:{id:'CFNPC00003',agrees:cooperate,roll:roll(s.world_seed,'CFNPC00003|food-water-request|day'+s.time.day),cooperation:temperament.cooperation},
  costs:{minutes:duration_minutes,stamina:0,copper:0},crafted_rods:0,delivered_food:0,delivered_water:0,
  bait_prepared:false,material_status:'no_line_no_hook_no_corn_no_wine_registered',
  before,after:{time:s.time.display,stamina:s.player.stamina,money:s.player.money},
  state_hash:digest(s)};
 event.hash=digest(event);
 return{state:s,event,events:[...events,event],public:{sisterAgreed:cooperate,after:event.after}};
}