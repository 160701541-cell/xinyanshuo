import {digest,verifyEvents} from './campaign_guard.mjs';
import {verifyNumericState} from './numeric_accounts.mjs';
export function makeRodBlank(state,events){
 verifyEvents(events);verifyNumericState(state);
 if(digest(state)!==events.at(-1).state_hash)throw Error('STALE_SAVE');
 if(state.location_id!=='shiqiao')throw Error('WRONG_REGION');
 const s=structuredClone(state),zone=s.ecology?.['shiqiao-outskirts-v1'];
 if(!zone)throw Error('NO_ECOLOGY');
 const wood=zone.nodes.find(n=>n.id==='SH-BRUSH-B'),fiber=zone.nodes.find(n=>n.id==='SH-FIBER-B');
 if(!wood||wood.quantity<1||!fiber||fiber.quantity<1)throw Error('MATERIAL_SHORTAGE');
 if(s.player.stamina<4)throw Error('STAMINA_LOW');
 if(events.some(e=>e.action==='craft_single_rod_blank'))throw Error('REPLAY');
 wood.quantity-=1;fiber.quantity-=1;
 const timeCost=30,old=s.time.hour*60+s.time.minute,next=old+timeCost;
 if(next>=1440)throw Error('DAY_TICK_UNAVAILABLE');
 s.time.hour=Math.floor(next/60);s.time.minute=next%60;
 s.time.display='承平三年 · 第'+s.time.day+'日 · '+String(s.time.hour).padStart(2,'0')+':'+String(s.time.minute).padStart(2,'0');
 s.player.stamina-=4;
 s.inventory.push({id:'rod_blank_wood_01',name:'未装线钩的简易竿坯',quantity:1,equipped:false,category:'渔具半成品',source:'SH-BRUSH-B(枝1)+SH-FIBER-B(纤维1)',usable_for_fishing:false});
 s.fishing_requests.rod_pair.craft_count=0;
 s.fishing_requests.rod_pair.rod_blanks_made=1;
 s.fishing_requests.rod_pair.status='one_blank_made_not_usable; second_pole_and_lines_hooks_missing';
 s.last_event_id='EV'+String(events.length+1).padStart(6,'0');
 const event={seq:events.length+1,prev_hash:events.at(-1).hash,type:'turn_committed',turn_id:events.filter(e=>e.type==='turn_committed').length+1,
 action:'craft_single_rod_blank',rule_version:'fishing-rod-blank-0.1.0',duration_minutes:timeCost,
 material_receipts:[{node:'SH-BRUSH-B',resource:'flexible_branch',quantity:1},{node:'SH-FIBER-B',resource:'bast_fiber',quantity:1}],
 output:{id:'rod_blank_wood_01',quantity:1,usable_for_fishing:false},stamina_cost:4,
 before:{time:state.time.display,stamina:state.player.stamina,money:state.player.money},
 after:{time:s.time.display,stamina:s.player.stamina,money:s.player.money},
 why_not_finished:'second flexible pole absent; fishing line and hooks not registered',
 state_hash:digest(s)};
 event.hash=digest(event);
 return{state:s,event,events:[...events,event]};
}