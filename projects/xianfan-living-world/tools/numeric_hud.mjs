import {digest,verifyEvents} from './campaign_guard.mjs';
import {verifyNumericState} from './numeric_engine.mjs';

/** A read-only view. Missing numbers remain null, never hallucinated defaults. */
export function numericHud(state,events){
 if(!Array.isArray(events)||events.length===0)throw Error('MISSING_EVENT_LEDGER');
 verifyEvents(events);verifyNumericState(state);
 if(digest(state)!==events.at(-1).state_hash)throw Error('HUD_STATE_HASH_MISMATCH');
 const p=state.player,f=state.family;
 const turns=events.filter(e=>e.type==='turn_committed').length;
 return Object.freeze({
  campaign_id:state.campaign_id,rule:'authoritative_state_only',
  location:state.current_location,time:state.time.display,
  player:{id:p.id,name:p.name,age:p.age,sex:p.sex,realm:p.realm,root:p.root_status,
    hp:p.hp,max_hp:p.max_hp,stamina:p.stamina,max_stamina:p.max_stamina,
    money_wen:p.money,exp:p.exp,spirit:p.spirit??null,strength:p.strength??null},
  family:{id:f.id,cash_wen:f.cash,grain_dou:f.grain_dou},
  backpack:(state.inventory||[]).map(i=>({id:i.id,name:i.name,quantity:i.quantity,equipped:i.equipped})),
  event_id:state.last_event_id,event_hash:events.at(-1).hash,turns_committed:turns,
  unknown_value_display:'未建档'
 });
}
