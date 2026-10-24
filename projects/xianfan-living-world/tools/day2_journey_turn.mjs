import {createHash} from 'node:crypto';
import {readFileSync} from 'node:fs';
import {digest,verifyEvents,countTurns} from './campaign_guard.mjs';
import {verifyNumericState} from './numeric_accounts.mjs';
const cfg=JSON.parse(readFileSync(new URL('../data/day2_home_and_county_rules_v1.json',import.meta.url),'utf8'));
const err=(code,detail)=>{throw Object.assign(new Error(detail||code),{code})};
const roll=(seed,label,max)=>Number(BigInt('0x'+createHash('sha256').update(seed+'|'+cfg.version+'|'+label).digest('hex').slice(0,13))%BigInt(max));
const id=n=>'EV'+String(n).padStart(6,'0');
const abs=s=>(s.time.day-1)*1440+s.time.hour*60+s.time.minute;
const stamp=s=>{s.time.display='承平三年 · 第'+s.time.day+'日 · '+String(s.time.hour).padStart(2,'0')+':'+String(s.time.minute).padStart(2,'0')};
const advance=(s,n)=>{if(!Number.isSafeInteger(n)||n<0)err('BAD_MINUTES');const v=abs(s)+n;s.time.day=1+Math.floor(v/1440);s.time.hour=Math.floor(v%1440/60);s.time.minute=v%60;stamp(s)};
const at=(s,day,minutes)=>{if(abs(s)>=(day-1)*1440+minutes)err('CLOCK_ORDER');advance(s,(day-1)*1440+minutes-abs(s))};
const energy=(s,n)=>{if(s.player.stamina<n)err('STAMINA_INSUFFICIENT');s.player.stamina-=n};
const credit=(s,n)=>s.player.stamina=Math.min(s.player.max_stamina,s.player.stamina+n);
export function calculateDay2Journey(original,events,registry){
 verifyEvents(events);verifyNumericState(original);
 if(digest(original)!==events.at(-1)?.state_hash||original.last_event_id!==id(events.length))err('STALE_EVENT_STATE');
 if(countTurns(events)!==10||original.time.day!==1||original.time.hour!==16||original.time.minute!==18)err('INCORRECT_SCENE');
 if(registry.npcs?.CFNPC00002?.id!=='CFNPC00002'||registry.npcs?.CFNPC00003?.id!=='CFNPC00003')err('NPC_NOT_REGISTERED');
 const s=structuredClone(original),r=cfg,facts=[],receipts=[],start=abs(s);
 const originalGrain=s.family.grain_dou*1000+(s.family.grain_remainder_millidou||0);
 const family=s.family,zone=s.ecology?.['shiqiao-outskirts-v1'];
 if(!zone?.freshwater||!zone.deployed_traps?.length)err('TRAPS_NOT_REGISTERED');
 // Walk home using established player coordinates and village anchor; don't teleport.
 const home=s.places.find(x=>x.id==='shiqiao');
 if(!home)err('HOME_UNKNOWN');
 energy(s,r.night.home_walk_stamina);advance(s,r.night.home_walk_minutes);
 s.position={x:home.x,y:home.y};s.sub_location='石桥村·钱家院落';
 facts.push({stage:'arrive_home',at:s.time.display,walk_minutes:r.night.home_walk_minutes});
 // Sister has had hours to walk home independently; no retrospective invented delivery.
 const sister=s.npc_schedules.CFNPC00003;
 sister.activity='home_after_errand';sister.last_seen_location='石桥村·钱家院落';
 sister.request={...sister.request,delivery:'not_delivered_outdoors; reunited_at_home'};
 sister.updated_at=s.time.display;
 facts.push({stage:'sister_reunion',note:'妹妹已在家，之前未有户外送饭事实'});
 const motherConsentRoll=roll(s.world_seed,'CFNPC00002|family_dinner|day1',100);
 const dinnerConsent=motherConsentRoll<92;
 const fatherHomeRoll=roll(s.world_seed,'CFNPC00001|return_home|day1',100);
 s.npc_schedules.CFNPC00001={...s.npc_schedules.CFNPC00001,activity:fatherHomeRoll<90?'home_evening':'working_late',updated_at:s.time.display};
 const dinnerTotal=r.night.meal_grain_millidou_per_person*r.night.mealtime_household_size;
 if(dinnerConsent&&originalGrain<dinnerTotal)err('FAMILY_GRAIN_INSUFFICIENT');
 at(s,1,r.night.dinner_start_clock);
 if(dinnerConsent){
  const leftover=originalGrain-dinnerTotal;
  family.grain_dou=Math.floor(leftover/1000);family.grain_remainder_millidou=leftover%1000;
  receipts.push({type:'household_dinner',authorized_by:'CFNPC00002',decision_roll:motherConsentRoll,
   source:'CFFAM00001.household_grain',quantity_millidou:dinnerTotal,for_persons:r.night.mealtime_household_size,
   grain_before_millidou:originalGrain,grain_after_millidou:leftover});
  credit(s,r.night.meal_stamina_gain);
 }
 advance(s,r.night.dinner_minutes);
 facts.push({stage:'dinner',permitted:dinnerConsent,at:s.time.display});
 // Overnight sleep restores stamina by exact integer formula. Bed is preexisting household shelter.
 at(s,1,r.night.bed_start_clock);
 const bed=abs(s);
 const wake=1440+r.night.wake_clock;
 const slept=wake-bed;
 const recovered=Math.floor(slept/10)*r.night.sleep_stamina_per_10min;
 credit(s,recovered);
 advance(s,slept);
 facts.push({stage:'sleep',from:'day1 21:30',to:s.time.display,minutes:slept,stamina_recovered_eligible:recovered});
 // Breakfast household decision independent of player wealth. No invented separate cash transfer.
 const breakfastRoll=roll(s.world_seed,'CFNPC00002|family_breakfast|day2',100);
 const breakfastConsent=breakfastRoll<92;
 const breakfastTotal=r.morning.morning_food_millidou_per_person*r.night.mealtime_household_size;
 const beforeBreakfast=family.grain_dou*1000+(family.grain_remainder_millidou||0);
 if(breakfastConsent&&beforeBreakfast<breakfastTotal)err('BREAKFAST_GRAIN_INSUFFICIENT');
 if(breakfastConsent){
  const after=beforeBreakfast-breakfastTotal;
  family.grain_dou=Math.floor(after/1000);family.grain_remainder_millidou=after%1000;
  receipts.push({type:'household_breakfast',authorized_by:'CFNPC00002',decision_roll:breakfastRoll,
   source:'CFFAM00001.household_grain',quantity_millidou:breakfastTotal,
   grain_before_millidou:beforeBreakfast,grain_after_millidou:after});
  credit(s,r.night.meal_stamina_gain);
 }
 advance(s,r.morning.morning_food_minutes);
 facts.push({stage:'breakfast',permitted:breakfastConsent,at:s.time.display});
 // Morning inspect the existing snare. Count is an entity ledger, not an invented loot item.
 energy(s,r.morning.walk_trap_stamina);advance(s,r.morning.walk_trap_minutes);
 const trap=zone.deployed_traps.find(x=>x.id==='TRAP-SHIQIAO-0001');
 if(!trap)err('SNARE_MISSING');
 s.position={x:trap.x,y:trap.y};s.sub_location='村外·小兽道';
 energy(s,r.morning.inspect_trap_stamina);advance(s,r.morning.inspect_trap_minutes);
 const hares=zone.animals.find(x=>x.id==='SH-HARE-01');
 const snareRoll=roll(s.world_seed,'TRAP-SHIQIAO-0001|second-check|day2',100);
 const caught=!!hares&&hares.count>0&&snareRoll<r.morning.trap_check_chance_percent;
 if(caught){hares.count-=1;trap.captured_count=1;trap.capture_status='occupied_pending_handling';}
 else{trap.captured_count=0;trap.capture_status='checked_empty';}
 trap.last_checked_at=s.time.display;trap.last_observation_roll=snareRoll;
 facts.push({stage:'inspect_snare',at:s.time.display,roll:snareRoll,catch_count:caught?1:0,
  source_population_after:hares?.count??null});
 // Inspect fish basket at morning river, applying EVERY elapsed 120-min period exactly once.
 energy(s,r.morning.walk_river_stamina);advance(s,r.morning.walk_river_minutes);
 const river=zone.freshwater,gear=river.installed_gear.find(x=>x.id==='GEAR-SH-RIVER-0001');
 if(!gear||gear.owner!==s.player.id)err('FISH_GEAR_MISSING');
 s.position={x:gear.x,y:gear.y};s.sub_location='荒沟下游缓水湾';
 energy(s,r.morning.inspect_river_stamina);
 const fish=river.stocks.find(x=>x.id==='small_cyprinid');
 if(!fish)err('FISH_STOCK_MISSING');
 const previous=gear.checked_at_clock_minutes??gear.placed_clock_minutes;
 const cycleCount=Math.floor((abs(s)-previous)/r.morning.fish_cycle_minutes);
 if(cycleCount<1)err('FISH_INTERVAL_NOT_READY');
 const checks=[],maxHeld=2;
 for(let i=0;i<cycleCount;i++){
  const cycle=1+Math.floor((previous-gear.placed_clock_minutes)/r.morning.fish_cycle_minutes)+i;
  const random=roll(s.world_seed,gear.id+'|capture-cycle-'+cycle,100);
  const take=fish.population>0&&gear.catch_count<maxHeld&&random<r.morning.fish_check_chance_percent?1:0;
  if(take){fish.population--;fish.harvested++;gear.catch_count++;}
  checks.push({cycle,roll:random,caught:take});
 }
 gear.checked_at_clock_minutes=previous+cycleCount*r.morning.fish_cycle_minutes;
 gear.checked_at=s.time.display;gear.last_check_result=gear.catch_count?'fish_present':'empty';
 river.catch_events.push({event_id:id(events.length+1),gear_id:gear.id,checks,caught_total:checks.reduce((n,x)=>n+x.caught,0),
  fish_stock_after:fish.population,retained_in_gear:gear.catch_count});
 advance(s,r.morning.inspect_river_minutes);
 facts.push({stage:'inspect_fish_basket',at:s.time.display,catch_count:gear.catch_count,cycles:checks.length,
  fish_population_after:fish.population,inside_basket_not_inventory:true});
 // Forward move to the county: explicit travel expense, distance, clock. No fabricated vendor encounter.
 energy(s,r.county.walk_stamina);advance(s,r.county.walk_minutes);
 s.position={x:r.county.arrival_point.x,y:r.county.arrival_point.y};s.location_id='linan';
 s.current_location='临安县城·东门';s.sub_location=r.county.arrival_point.name;
 facts.push({stage:'arrive_county',at:s.time.display,location:s.current_location,
  market_price_status:'NOT_QUOTED',no_unverified_sale:true});
 const afterGrain=family.grain_dou*1000+(family.grain_remainder_millidou||0);
 receipts.push({type:'household_grain_conservation',before_millidou:originalGrain,after_millidou:afterGrain,
  consumed_millidou:originalGrain-afterGrain});
 s.npc_schedules.CFNPC00003={...sister,activity:'home_day2_morning',updated_at:s.time.display,last_seen_location:'石桥村·钱家院落',
  request:{...sister.request,delivery:'resolved_at_home'}};
 s.npc_schedules.CFNPC00002={...s.npc_schedules.CFNPC00002,activity:'household_cooking_and_chores',updated_at:s.time.display};
 s.last_event_id=id(events.length+1);
 verifyNumericState(s);
 const event={seq:events.length+1,prev_hash:events.at(-1).hash,type:'turn_committed',
  turn_id:countTurns(events)+1,action:'return_home_eat_sleep_inspect_traps_travel_county',
  rule_version:cfg.version,stages:facts,receipts,duration_minutes:abs(s)-start,
  mother_consent:{dinner:dinnerConsent,breakfast:breakfastConsent},
  traps:{snare:{roll:snareRoll,count:caught?1:0,hares_after:hares?.count??null},
    fish_basket:{checks,fish_in_gear:gear.catch_count,fish_stock_after:fish.population}},
  before:{time:original.time.display,day:original.time.day,hp:original.player.hp,stamina:original.player.stamina,
   money:original.player.money,grain_millidou:originalGrain},
  after:{time:s.time.display,day:s.time.day,hp:s.player.hp,stamina:s.player.stamina,
   money:s.player.money,grain_millidou:afterGrain},
  state_hash:digest(s)};
 event.hash=digest(event);
 return {state:s,event,events:[...events,event],result:{
  morning_day:s.time.day,time:s.time.display,location:s.current_location,stamina:s.player.stamina,
  mother_consent:event.mother_consent,snare:event.traps.snare,fish:event.traps.fish_basket,
  grain_millidou:afterGrain,history:facts}};
}
