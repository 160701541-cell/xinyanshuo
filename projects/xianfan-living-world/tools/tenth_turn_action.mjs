import {createHash} from 'node:crypto';
import {digest,verifyEvents} from './campaign_guard.mjs';
import {verifyNumericState} from './numeric_accounts.mjs';
import rules from '../data/branch_search_v1.json' with {type:'json'};
const check=(p,code)=>{if(!p)throw Object.assign(new Error(code),{code})};
const roll=(seed,key,max)=>Number(BigInt('0x'+createHash('sha256').update(seed+'|tenth-turn-v1|'+key).digest('hex').slice(0,13))%BigInt(max));
const advance=(s,n)=>{const minutes=s.time.hour*60+s.time.minute+n;check(minutes<1440,'NO_DAY_TICK');s.time.hour=Math.floor(minutes/60);s.time.minute=minutes%60;s.time.display='承平三年 · 第'+s.time.day+'日 · '+String(s.time.hour).padStart(2,'0')+':'+String(s.time.minute).padStart(2,'0')};
export function runTenthTurn(original,events){
 verifyEvents(events);verifyNumericState(original);
 check(digest(original)===events.at(-1)?.state_hash,'STALE_STATE');
 check(events.filter(x=>x.type==='turn_committed').length===9,'NOT_TENTH_TURN');
 check(!original.ecology['shiqiao-outskirts-v1'].branch_expansion,'SITE_REUSED');
 const s=structuredClone(original),eco=s.ecology['shiqiao-outskirts-v1'],receipts=[],facts=[];
 check(s.player.stamina>=13,'NO_ENERGY');
 const available=roll(s.world_seed,rules.node+'|present',100)<rules.availability_percent;
 const quantity=available?rules.quantity_min+roll(s.world_seed,rules.node+'|quantity',rules.quantity_extra):0;
 eco.branch_expansion={version:rules.version,nodes:[{id:rules.node,name:rules.location,resource:rules.resource,initial_quantity:quantity,quantity,origin:'seeded-world-node'}]};
 advance(s,rules.search_minutes);s.player.stamina-=rules.search_energy;
 facts.push({action:'search',node:rules.node,available:quantity});
 if(quantity>0){
  eco.branch_expansion.nodes[0].quantity--;
  const stack=s.inventory.find(x=>x.id==='flexible_branch');
  if(stack)stack.quantity++;
  else s.inventory.push({id:'flexible_branch',name:'韧枝',quantity:1,source:rules.node,category:'野外材料'});
  receipts.push({type:'gather',source:rules.node,resource:'flexible_branch',quantity:1});
 }
 const branch=s.inventory.find(x=>x.id==='flexible_branch'),fiber=s.inventory.find(x=>x.id==='bast_fiber');
 const finished=(branch?.quantity??0)>=5&&(fiber?.quantity??0)>=4;
 if(finished){
  branch.quantity-=5;fiber.quantity-=4;s.inventory=s.inventory.filter(x=>x.quantity>0);
  advance(s,50);s.player.stamina-=6;
  s.inventory.push({id:'woven_fish_basket',name:'简易编织鱼笼',quantity:1,category:'渔具',equipped:false,source:'EV000012',reinforcement:null});
  receipts.push({type:'craft',inputs:[{id:'flexible_branch',quantity:5},{id:'bast_fiber',quantity:4}],output:{id:'woven_fish_basket',quantity:1}});
 }
 facts.push({action:'craft_new_basket',completed:finished});
 advance(s,15);s.player.stamina-=2;
 const setup=eco.deployed_traps.find(x=>x.id==='TRAP-SHIQIAO-0001');
 check(!!setup,'MISSING_EXISTING_OBJECT');
 const wildlife=eco.animals.find(x=>x.id==='SH-HARE-01');
 const number=roll(s.world_seed,'TRAP-SHIQIAO-0001|first-check',100);
 const recorded=!!wildlife&&wildlife.count>0&&number<24;
 if(recorded){wildlife.count--;setup.captured_count=1;setup.capture_status='occupied_pending_handling';}
 else setup.capture_status='checked_empty';
 setup.last_checked_at=s.time.display;
 setup.last_observation_roll=number;
 facts.push({action:'check_existing_object',object_id:setup.id,observed_count:recorded?1:0,roll:number});
 s.position={x:setup.x,y:setup.y};s.sub_location:'石桥村外·草丛兽道';
 s.last_event_id='EV'+String(events.length+1).padStart(6,'0');
 const event={seq:events.length+1,prev_hash:events.at(-1).hash,type:'turn_committed',turn_id:10,action:'forage_finish_basket_then_check_existing_object',
  rule_version:'tenth-turn-1.0.0',facts,receipts,minutes:35+(finished?50:0)+15,
  before:{time:original.time.display,stamina:original.player.stamina,money:original.player.money},
  after:{time:s.time.display,stamina:s.player.stamina,money:s.player.money},state_hash:digest(s)};
 event.hash=digest(event);
 return {state:s,event,events:[...events,event],result:{found_branch:quantity>0,basket_finished:finished,object_result:setup.capture_status,roll:number,time:s.time.display,stamina:s.player.stamina}};
}
