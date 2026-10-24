// Prevent GM from erasing accepted requests or silently assuming a newly crafted object is installed.
export const CONTINUITY_VERSION='intent-obligations-1.0.0';
const err=(code)=>{throw Object.assign(new Error(code),{code})};
export function pendingObligations(events,state){
 const obligations=[];
 const request=events.find(e=>e.action==='request_food_and_rod_pair');
 if(request?.npc_decision?.agrees){
  const deliveries=events.filter(e=>e.action==='confirmed_delivered_food_water'&&e.npc_id==='CFNPC00003');
  const explanation=events.filter(e=>e.action==='sister_explains_undelivered_food_water');
  if(!deliveries.length&&!explanation.length)obligations.push({
   id:'OBLIGATION_FOOD_WATER_001',actor_id:'CFNPC00003',source:'EV000006',
   state:'response_or_explanation_due',event_sequence:[request.seq],
   known:'同意回家取食物水，但没有出门交付的事件，也缺当晚明确解释。不能擅自补写理由。'
  });
 }
 const item=state.inventory?.find(x=>x.id==='woven_fish_basket'&&x.source==='EV000012'&&x.quantity>0);
 const installations=state.ecology?.['shiqiao-outskirts-v1']?.freshwater?.installed_gear||[];
 if(item&&!installations.some(x=>x.source_event_id==='EV000012'))
  obligations.push({id:'OBLIGATION_BASKET_002',actor_id:state.player.id,source:'EV000012',
   state:'requires_explicit_deployment_action_at_water',
   known:'第二只鱼笼仍在背包；制作≠部署，玩家目前在县城，不能远程放笼。'});
 return obligations;
}
export function assertNarrativeContinuity(events,state,text){
 const issues=pendingObligations(events,state);
 if(issues.some(x=>x.id==='OBLIGATION_FOOD_WATER_001')&&/成明已经送.*(?:饭|水)|中午.*送饭成功/.test(text))err('FABRICATED_DELIVERY');
 if(issues.some(x=>x.id==='OBLIGATION_BASKET_002')&&/两只鱼笼都.*(?:河里|已放)|第二只鱼笼已.*入水/.test(text))err('FABRICATED_DEPLOYMENT');
 return {ok:true,outstanding:issues};
}
