import {digest,verifyEvents} from './campaign_guard.mjs';
import {verifyNumericState} from './numeric_accounts.mjs';
export function continueWeavingBasket(original,events){
 verifyEvents(events);verifyNumericState(original);
 if(digest(original)!==events.at(-1).state_hash)throw Error('STATE_MISMATCH');
 if(events.some(e=>e.action==='reinforce_existing_fish_basket_once'))throw Error('REPLAY');
 const s=structuredClone(original),fiber=s.inventory.find(x=>x.id==='bast_fiber'),basket=s.inventory.find(x=>x.id==='woven_fish_basket');
 if(!basket||basket.quantity<1)throw Error('NO_BASKET');
 if(!fiber||fiber.quantity<2)throw Error('FIBER_SHORTAGE');
 if(s.player.stamina<3)throw Error('STAMINA_LOW');
 fiber.quantity-=2;s.inventory=s.inventory.filter(x=>x.quantity>0);
 basket.reinforcement={version:'fishbasket-weave-0.1.0',lashing:'plant_fiber',layers:1,quality:'reinforced_handwoven',
 source_event_id:'EV'+String(events.length+1).padStart(6,'0')};
 const start=s.time.hour*60+s.time.minute,after=start+20;
 if(after>=1440)throw Error('DAILY_TICK_MISSING');
 s.time.hour=Math.floor(after/60);s.time.minute=after%60;
 s.time.display='承平三年 · 第'+s.time.day+'日 · '+String(s.time.hour).padStart(2,'0')+':'+String(s.time.minute).padStart(2,'0');
 s.player.stamina-=3;s.last_event_id='EV'+String(events.length+1).padStart(6,'0');
 const event={seq:events.length+1,prev_hash:events.at(-1).hash,type:'turn_committed',
 turn_id:events.filter(e=>e.type==='turn_committed').length+1,action:'reinforce_existing_fish_basket_once',
 rule_version:'fishbasket-weave-0.1.0',duration_minutes:20,stamina_cost:3,
 receipts:[{type:'craft_improvement',from_inventory:{id:'bast_fiber',quantity:2},to_existing_item:'woven_fish_basket',quantity_delta:0,reinforcement_layers_added:1}],
 fish_caught:0,basket_deployed:false,
 before:{time:original.time.display,stamina:original.player.stamina,money:original.player.money},
 after:{time:s.time.display,stamina:s.player.stamina,money:s.player.money},state_hash:digest(s)};
 event.hash=digest(event);
 return {state:s,event,events:[...events,event]};
}