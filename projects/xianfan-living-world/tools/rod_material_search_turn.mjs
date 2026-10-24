import {digest,verifyEvents} from './campaign_guard.mjs';
import {verifyNumericState} from './numeric_accounts.mjs';
export function seekRodMaterials(state,events){
 verifyEvents(events);verifyNumericState(state);
 if(digest(state)!==events.at(-1).state_hash)throw Error('HASH_MISMATCH');
 if(events.some(e=>e.action==='seek_rod_line_and_hook_materials_once'))throw Error('REPLAY');
 const s=structuredClone(state),nodes=s.ecology?.['shiqiao-outskirts-v1']?.nodes;
 if(!nodes)throw Error('UNKNOWN_TERRAIN');
 const fiber=nodes.find(x=>x.id==='SH-FIBER-B');
 if(!fiber||fiber.quantity<2)throw Error('NO_FIBER');
 if(s.player.stamina<4)throw Error('NO_STAMINA');
 fiber.quantity-=2;
 let item=s.inventory.find(x=>x.id==='bast_fiber');
 if(item)item.quantity+=2;
 else s.inventory.push({id:'bast_fiber',name:'野生植物纤维',quantity:2,equipped:false,category:'野外材料',source:'SH-FIBER-B'});
 const old=s.time.hour*60+s.time.minute,n=old+25;
 s.time.hour=Math.floor(n/60);s.time.minute=n%60;
 s.time.display='承平三年 · 第'+s.time.day+'日 · '+String(s.time.hour).padStart(2,'0')+':'+String(s.time.minute).padStart(2,'0');
 s.player.stamina-=4;
 s.last_event_id='EV'+String(events.length+1).padStart(6,'0');
 s.fishing_requests.rod_pair.status='one_blank_and_two_fibers; second_pole and durable line and hook absent';
 const event={seq:events.length+1,type:'turn_committed',turn_id:events.filter(e=>e.type==='turn_committed').length+1,prev_hash:events.at(-1).hash,
 action:'seek_rod_line_and_hook_materials_once',rule_version:'fishing-forage-0.1.0',duration_minutes:25,stamina_cost:4,
 receipts:[{kind:'harvest',from_node:'SH-FIBER-B',resource:'bast_fiber',quantity:2,remaining:fiber.quantity}],
 observations:['发现野生纤维材料','附近登记的两处灌木枝条已采尽','没有确切的鱼钩和结实鱼线来源'],
 outputs:{bast_fiber:2,hook:0,line:0,second_rod_blank:0},
 before:{time:state.time.display,stamina:state.player.stamina,copper:state.player.money},
 after:{time:s.time.display,stamina:s.player.stamina,copper:s.player.money},state_hash:digest(s)};
 event.hash=digest(event);
 return{state:s,event,events:[...events,event]};
}