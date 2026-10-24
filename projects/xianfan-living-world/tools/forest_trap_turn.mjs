import {createHash} from 'node:crypto';
import {digest,verifyEvents} from './campaign_guard.mjs';
import {calculateAction,verifyNumericState} from './numeric_engine.mjs';
import {trapEligibility} from './hunting_engine.mjs';

export const FOREST_TURN_VERSION='forest-trap-0.1.0';
const sha=(s)=>createHash('sha256').update(s).digest('hex');
const roll=(seed,key,n)=>Number(BigInt('0x'+sha(seed+'|forest-trap-v1|'+key).slice(0,13))%BigInt(n));
const BLOCK=(code,detail)=>{const e=new Error(detail);e.code=code;throw e;};
const now=(s)=>((s.time.day-1)*24+s.time.hour)*60+s.time.minute;
const assertBefore=(s,events)=>{
 verifyEvents(events);
 if(events.at(-1).state_hash!==digest(s))BLOCK('EVENT_STATE_MISMATCH','当前存档与权威事件链不一致');
 if(s.last_event_id!=='EV'+String(events.length).padStart(6,'0'))BLOCK('EVENT_SEQUENCE','最新事件ID错误');
 if(s.player.id!=='CFPLAYER00001'||s.family.id!=='CFFAM00001')BLOCK('UNEXPECTED_ACTOR','本动作属于第一世石桥村玩家');
 if(s.location_id!=='shiqiao')BLOCK('WRONG_PLACE','不在石桥村');
 verifyNumericState(s);
};
const stockKey='shiqiao-outskirts-v1';
function spawnEcology(s){
 const specs=[
  {id:'SH-BRUSH-A',name:'村南路外灌木带',dx:130,dy:96,resource:'flexible_branch',range:5,base:2},
  {id:'SH-BRUSH-B',name:'田埂外矮树丛',dx:177,dy:115,resource:'flexible_branch',range:4,base:1},
  {id:'SH-FIBER-A',name:'荒沟边的纤维草带',dx:205,dy:139,resource:'bast_fiber',range:6,base:3},
  {id:'SH-FIBER-B',name:'河侧芦草丛',dx:239,dy:161,resource:'bast_fiber',range:5,base:2},
  {id:'SH-FALLEN-A',name:'荒坡枯枝地',dx:158,dy:199,resource:'fallen_stick',range:3,base:1}
 ];
 const nodes=specs.map(v=>({
  id:v.id,name:v.name,x:s.position.x+v.dx,y:s.position.y+v.dy,
  resource:v.resource,quantity:v.base+roll(s.world_seed,v.id,v.range),
  rights:'uncultivated_commons',kind:'wild_growth',seed_origin:s.world_seed
 }));
 const animalSpecies='field_hare';
 const group=roll(s.world_seed,'SH-HARE-PACK',4);
 const animals=group===0?[]:[{id:'SH-HARE-01',species:animalSpecies,name:'田野兔群',count:group,zone:stockKey,
  route:['SH-HARE-TRAIL-A'],last_checked_day:s.time.day}];
 const trail={id:'SH-HARE-TRAIL-A',kind:'animal_path',name:'荒沟与低矮草丛间的小兽道',
  x:s.position.x+253,y:s.position.y+191,dist_from_human_road_m:75,
  track_score:roll(s.world_seed,'SH-TRAIL-SIGNS',5)+group*2,owner:null};
 return {version:'shiqiao-ecology-v1',seed:s.world_seed,location_id:s.location_id,
  nodes,animals,trails:[trail],deployed_traps:[],generated_from:'predeclared world-seed + region templates'};
}
function deductNode(world,item,n){
 const selected=world.nodes.filter(x=>x.resource===item);
 if(selected.reduce((a,v)=>a+v.quantity,0)<n)return false;
 let left=n;
 for(const node of selected){
  const take=Math.min(left,node.quantity);left-=take;node.quantity-=take;if(!left)break;
 }
 return true;
}
function receive(s,id,name,qty,sourceId){
 if(!Number.isSafeInteger(qty)||qty<=0)BLOCK('INVALID_GATHER','采集数量非法');
 const found=s.inventory.find(i=>i.id===id);
 if(found)found.quantity+=qty;
 else s.inventory.push({id,name,quantity:qty,equipped:false,category:'自然材料',source:'world_node:'+sourceId});
}
function elapse(s,minutes){const p=calculateAction(s,{type:'wait',minutes});s.time=p.state.time;return s;}
function spend(s,n,label){
 if(!Number.isSafeInteger(n)||n<0||s.player.stamina<n)BLOCK('EXHAUSTED',label+'精力不足');
 s.player.stamina-=n;
}
function publicProfile(s){
 const name=s.known_npcs.find(n=>n.id==='CFNPC00003');
 if(!name||!name.alive)return false;
 return true;
}
export function previewForestTrip(original,events,{intent='call_sister_collect_craft_track_deploy'}={}){
 assertBefore(original,events);
 if(intent!=='call_sister_collect_craft_track_deploy')BLOCK('UNKNOWN_INTENT','未登记的玩家行动');
 if(events.some(e=>e.action==='call_sister_collect_craft_track_deploy'))BLOCK('SCENE_REPLAY','这次采集行动已经记录，不能重复生成相同材料与陷阱ID');
 let s=structuredClone(original);const start=now(s),facts=[],receipts=[];
 // 1. Calling is a valid attempt; hearing and agreeing are independent NPC outcomes.
 const speak=calculateAction(s,{type:'speak',text:'成明，你在吗？我们去村外寻些枝条和草，试试做套小兽的绳套。'});
 Object.assign(s,speak.state);
 facts.push({type:'speech',text:'玩家呼唤孙成明，邀请她收集材料、制作绳套。'});
 const sisterPresent=publicProfile(s)&&roll(s.world_seed,'CFNPC00003|day1|morning-near-house',10)<8;
 let sisterJoined=false;
 if(sisterPresent){
  // Hunger/chores impose a small, bounded delay even if she is willing.
  s=elapse(s,3);
  sisterJoined=roll(s.world_seed,'CFNPC00003|day1|hunting-cooperate',10)<7;
  facts.push({type:'npc_response',npc_id:'CFNPC00003',
    decision:sisterJoined?'agrees_after_breakfast_note':'declines_due_to_household_work',
    reasons:sisterJoined?['亲属合作','可帮助取草料','没有强制任务']:['家务与个人安排','可自主拒绝']});
 }else facts.push({type:'npc_response',npc_id:'CFNPC00003',decision:'not_within_hearing',reasons:['家庭成员精确位置原未登记','不捏造回应']});
 if(!sisterJoined){
  facts.push({type:'stopped',reason:'妹妹未同意或未听见；不替玩家决定独自前往。'});
  return wrap(s,original,events,start,facts,receipts,{sisterPresent,sisterJoined,trapPlaced:false});
 }
 // 2. World ecology is generated once with a stable world seed and persisted. 
 if(!s.ecology)s.ecology={};
 if(!s.ecology[stockKey]){
  s.ecology[stockKey]=spawnEcology(s);
  facts.push({type:'ecology_initialized',zone:stockKey,
    note:'同一世界种子生成固定野外材料节点与动物存量，并非根据玩家需要免费发材料'});
 }
 let world=s.ecology[stockKey];
 if(!s.npc_schedules)s.npc_schedules={};
 s.npc_schedules.CFNPC00003={last_seen_location:'石桥村村外荒沟附近',activity:'cooperating_foraging',
   updated_at:s.time.display,interest:'尝试学习普通小兽绳套'};
 s=elapse(s,48);
 spend(s,6,'采集');
 const targets=[['flexible_branch',2],['bast_fiber',3],['fallen_stick',1]];
 const lacking=targets.filter(([item,q])=>world.nodes.filter(n=>n.resource===item).reduce((sum,n)=>sum+n.quantity,0)<q);
 if(lacking.length){
  facts.push({type:'forage_result',status:'insufficient',missing:lacking,elapsed:48,
    note:'不能保证固定生境拥有足量原料，且没有编造收获'});
  return wrap(s,original,events,start,facts,receipts,{sisterPresent,sisterJoined,trapPlaced:false});
 }
 for(const [id,q] of targets){
  if(!deductNode(world,id,q))BLOCK('NODE_LEDGER_CONFLICT','自然节点库存不足');
  receive(s,id,({flexible_branch:'韧枝',bast_fiber:'草皮纤维',fallen_stick:'落枝'}[id]),q,'shiqiao-outskirts-v1');
  receipts.push({type:'gather',from_node_zone:stockKey,item_id:id,quantity:q,source:'wild_growth_commons'});
 }
 // 3. Process harvested materials. Existing trap recipe already requires cord and peg.
 s=elapse(s,12);spend(s,2,'搓绳');
 let fibers=s.inventory.find(i=>i.id==='bast_fiber');
 fibers.quantity-=3;
 s.inventory=s.inventory.filter(i=>i.quantity>0);
 receive(s,'plant_cord','植物绳',1,'crafted:bast_fiber:3');
 receipts.push({type:'craft_intermediate',inputs:[{id:'bast_fiber',quantity:3}],outputs:[{id:'plant_cord',quantity:1}],minutes:12,stamina:2});
 s=elapse(s,10);spend(s,2,'削制木桩');
 let stick=s.inventory.find(i=>i.id==='fallen_stick');
 stick.quantity--;s.inventory=s.inventory.filter(i=>i.quantity>0);
 receive(s,'wooden_peg','小木桩',1,'crafted:fallen_stick:1');
 receipts.push({type:'craft_intermediate',inputs:[{id:'fallen_stick',quantity:1}],outputs:[{id:'wooden_peg',quantity:1}],minutes:10,stamina:2});
 if(!trapEligibility(s).can_craft)BLOCK('TRAP_NOT_READY','真实配方材料不足');
 const crafted=calculateAction(s,{type:'craft_trap',recipe_id:'cord_snare'});s=crafted.state;world=s.ecology[stockKey];
 receipts.push(...crafted.receipts);
 facts.push({type:'trap_crafted',count:1,name:'简易小兽绳套',materials:'全部来自固定自然节点并已扣除'});
 // 4. Tracking depends on actually registered animals and deterministic detection.
 s=elapse(s,28);spend(s,4,'搜迹');
 const trail=world.trails[0],animal=world.animals.find(a=>a.route.includes(trail.id));
 s.position={x:trail.x,y:trail.y};s.sub_location='村外荒沟·矮草丛边';
 const signRoll=roll(s.world_seed,'CFPLAYER00001|day1|trail-search',10);
 const signs=!!animal&&animal.count>0&&signRoll+trail.track_score>=8;
 facts.push({type:'track_search',trail_id:trail.id,animal_registered:!!animal,
    detected:signs,check_roll:signRoll,track_score:trail.track_score,
    note:signs?'只辨认到小兽踩踏与啃咬迹象，尚未看见猎物':'未发现足够可靠的小兽通行痕迹'});
 if(signs){
  if(trail.dist_from_human_road_m<30)BLOCK('HUMAN_PATH','禁止在村民日常行走道路附近设绳套');
  if(!s.inventory.some(i=>i.id==='cord_snare'&&i.quantity>0))BLOCK('TRAP_NOT_OWNED','陷阱库存不足');
  s=elapse(s,12);spend(s,2,'安置绳套');
  let item=s.inventory.find(i=>i.id==='cord_snare');item.quantity--;s.inventory=s.inventory.filter(i=>i.quantity>0);
  world.deployed_traps.push({id:'TRAP-SHIQIAO-0001',type:'cord_snare',owner:s.player.id,trail_id:trail.id,
    x:trail.x,y:trail.y,set_day:s.time.day,set_time:s.time.display,
    capture_status:'unset_until_animal_tick',captured_count:0});
  receipts.push({type:'deploy_trap',source_inventory:'cord_snare',quantity:1,
    destination_id:'TRAP-SHIQIAO-0001',trail_id:trail.id});
  facts.push({type:'trap_deployed',trap_id:'TRAP-SHIQIAO-0001',
    note:'布置成功不等于猎获，后续动物行为和触发条件尚需独立结算'});
 }
 if(signs && world.deployed_traps.length!==1)BLOCK('TRAP_NOT_PERSISTED','陷阱未真正落入世界存档');
 s.npc_schedules.CFNPC00003.updated_at=s.time.display;
 s.npc_schedules.CFNPC00003.activity='with_player_by_bushes';
 return wrap(s,original,events,start,facts,receipts,
   {sisterPresent,sisterJoined,signsDetected:signs,animalRegistered:!!animal,
    trapPlaced:signs,trapId:signs?'TRAP-SHIQIAO-0001':null});
}
function wrap(state,original,events,start,facts,receipts,outcomes){
 verifyNumericState(state);
 const serial=events.length+1;
 state.last_event_id='EV'+String(serial).padStart(6,'0');
 const prev=events.at(-1);
 const event={seq:serial,type:'turn_committed',turn_id:events.filter(e=>e.type==='turn_committed').length+1,
  prev_hash:prev.hash,rule_version:FOREST_TURN_VERSION,action:'call_sister_collect_craft_track_deploy',
  duration_minutes:now(state)-start,facts,receipts,outcomes,
  before:{clock:original.time.display,stamina:original.player.stamina,money:original.player.money},
  after:{clock:state.time.display,stamina:state.player.stamina,money:state.player.money},
  state_hash:digest(state)};
 event.hash=digest(event);
 return {state,event,events:[...events,event],public:{facts,receipts,outcomes,after:event.after,duration_minutes:event.duration_minutes},
  verification:{previous_event_hash:prev.hash,event_hash:event.hash,state_hash:event.state_hash}};
}
