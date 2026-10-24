import {createHash} from 'node:crypto';
import {digest,verifyEvents} from './campaign_guard.mjs';
import {verifyNumericState} from './numeric_accounts.mjs';
import rules from '../data/branch_search_v1.json' with {type:'json'};

function chance(seed,key,limit){
 const hex=createHash('sha256').update(seed+'|tenth-turn-v1|'+key).digest('hex');
 return Number(BigInt('0x'+hex.slice(0,13))%BigInt(limit));
}
function clock(state,minutes){
 const n=state.time.hour*60+state.time.minute+minutes;
 if(n>=1440) throw Error('CROSS_DAY_NOT_SUPPORTED');
 state.time.hour=Math.floor(n/60);
 state.time.minute=n%60;
 state.time.display='承平三年 · 第'+state.time.day+'日 · '+String(state.time.hour).padStart(2,'0')+':'+String(state.time.minute).padStart(2,'0');
}
export function runTenthTurn(original,events){
 verifyEvents(events);verifyNumericState(original);
 if(digest(original)!==events.at(-1).state_hash)throw Error('STALE_STATE');
 if(events.filter(x=>x.type==='turn_committed').length!==9)throw Error('WRONG_TURN');
 const s=structuredClone(original),zone=s.ecology['shiqiao-outskirts-v1'];
 if(zone.branch_expansion)throw Error('SITE_ALREADY_SCOUTED');
 if(s.player.stamina<13)throw Error('NOT_ENOUGH_ENERGY');
 const available=chance(s.world_seed,rules.node+'|present',100)<rules.availability_percent;
 const n=available?rules.quantity_min+chance(s.world_seed,rules.node+'|quantity',rules.quantity_extra):0;
 zone.branch_expansion={version:rules.version,nodes:[{id:rules.node,name:rules.location,resource:rules.resource,initial_quantity:n,quantity:n}]};
 const facts=[],receipts=[];
 clock(s,35);s.player.stamina-=5;
 facts.push({stage:'scout',quantity_discovered:n});
 if(n>0){
  zone.branch_expansion.nodes[0].quantity--;
  const branches=s.inventory.find(x=>x.id==='flexible_branch');
  if(branches)branches.quantity+=1;
  else s.inventory.push({id:'flexible_branch',name:'韧枝',quantity:1,source:rules.node});
  receipts.push({stage:'harvest',source:rules.node,id:'flexible_branch',quantity:1});
 }
 const branch=s.inventory.find(x=>x.id==='flexible_branch');
 const fiber=s.inventory.find(x=>x.id==='bast_fiber');
 const finished=(branch?.quantity??0)>=5 && (fiber?.quantity??0)>=4;
 if(finished){
  branch.quantity-=5;fiber.quantity-=4;
  s.inventory=s.inventory.filter(x=>x.quantity>0);
  clock(s,50);s.player.stamina-=6;
  s.inventory.push({id:'woven_fish_basket',name:'简易编织鱼笼',quantity:1,category:'渔具',source:'EV000012',equipped:false});
  receipts.push({stage:'craft',inputs:[{id:'flexible_branch',quantity:5},{id:'bast_fiber',quantity:4}],output:{id:'woven_fish_basket',quantity:1}});
 }
 facts.push({stage:'weave',finished});
 clock(s,15);s.player.stamina-=2;
 const obj=zone.deployed_traps.find(x=>x.id==='TRAP-SHIQIAO-0001');
 if(!obj)throw Error('MISSING_OBJECT');
 const group=zone.animals.find(x=>x.id==='SH-HARE-01');
 const score=chance(s.world_seed,obj.id+'|first-check',100);
 const observed=!!group && group.count>0 && score<24;
 if(observed){group.count--;obj.captured_count=1;obj.capture_status='occupied_pending_handling';}
 else obj.capture_status='checked_empty';
 obj.last_checked_at=s.time.display;obj.last_observation_roll=score;
 facts.push({stage:'inspect',object_id:obj.id,observed:observed?1:0,score});
 s.position={x:obj.x,y:obj.y};s.sub_location='石桥村外·草丛兽道';
 s.last_event_id='EV'+String(events.length+1).padStart(6,'0');
 verifyNumericState(s);
 const event={seq:events.length+1,prev_hash:events.at(-1).hash,type:'turn_committed',
 turn_id:10,action:'seek_branch_weave_basket_and_inspect',rule_version:'tenth-turn-v1',
 facts,receipts,duration_minutes:35+(finished?50:0)+15,
 before:{time:original.time.display,stamina:original.player.stamina,money:original.player.money},
 after:{time:s.time.display,stamina:s.player.stamina,money:s.player.money},
 state_hash:digest(s)};
 event.hash=digest(event);
 return {state:s,event,events:[...events,event],result:{branch_found:n>0,quantity:n,finished,observed,score,time:s.time.display,stamina:s.player.stamina}};
}
