import {readFileSync} from 'node:fs';
import {digest,verifyEvents,countTurns} from './campaign_guard.mjs';
import {verifyNumericState} from './numeric_accounts.mjs';
const shop=JSON.parse(readFileSync(new URL('../data/linan_bookshop_v1.json',import.meta.url),'utf8'));
export function seekManualAtBookshop(before,events){
 verifyEvents(events);verifyNumericState(before);
 if(digest(before)!==events.at(-1)?.state_hash||countTurns(events)!==13)throw Error('STATE_CHANGED');
 if(before.location_id!=='linan'||before.player.stamina<shop.stamina_cost)throw Error('LOCATION_OR_STAMINA');
 if(before.city_exploration?.bookshop_visit)throw Error('ALREADY_VISITED');
 const state=structuredClone(before);
 const elapsed=shop.walk_minutes+shop.ask_minutes,total=state.time.hour*60+state.time.minute+elapsed;
 if(total>=1440)throw Error('CROSS_DAY');
 state.time.hour=Math.floor(total/60);state.time.minute=total%60;
 state.time.display='承平三年 · 第'+state.time.day+'日 · '+String(state.time.hour).padStart(2,'0')+':'+String(state.time.minute).padStart(2,'0');
 state.player.stamina-=shop.stamina_cost;
 state.position={...shop.coords};state.current_location='临安县城·旧书铺';state.sub_location=shop.name;
 state.city_exploration.bookshop_visit={site_id:shop.site_id,at:state.time.display,
  finite_stock:{...shop.inventory},quotes:{...shop.price},
  genuine_cultivation_manual_available:shop.inventory.verified_cultivation_manual>0,
  ordinary_breathing_notes_not_cultivation:true,offer_to_purchase_genuine_manual_failed:true,
  merchant_response:'本铺没有可核验的入门修行功法；只有两文的凡俗调息册子。',
  no_purchase:true,merchants_met:'bookshop_vendor_identity_unknown'};
 state.last_event_id='EV'+String(events.length+1).padStart(6,'0');
 verifyNumericState(state);
 const event={seq:events.length+1,prev_hash:events.at(-1).hash,type:'turn_committed',
  turn_id:countTurns(events)+1,action:'seek_genuine_cultivation_manual_for_two_wen',
  rule_version:shop.version,site_id:shop.site_id,
  bookshop_stock:{...shop.inventory},quotes:{...shop.price},
  found_verified_manual:false,ordinary_book_offered:true,purchased:false,
  money_delta:0,items_gained:[],duration_minutes:elapsed,stamina_cost:shop.stamina_cost,
  before:{time:before.time.display,stamina:before.player.stamina,copper:before.player.money},
  after:{time:state.time.display,stamina:state.player.stamina,copper:state.player.money},
  state_hash:digest(state)};
 event.hash=digest(event);
 return{state,event,events:[...events,event]};
}
