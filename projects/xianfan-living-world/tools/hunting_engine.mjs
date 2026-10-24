import {readFileSync} from 'node:fs';

const cfg=JSON.parse(readFileSync(new URL('../data/hunting_rules_v1.json',import.meta.url),'utf8'));
const stop=(code,message)=>{throw Object.assign(new Error(message),{code});};
const validQty=(n)=>Number.isSafeInteger(n)&&n>=0;

export function trapEligibility(state,recipeId='cord_snare'){
 const recipe=cfg.recipes[recipeId];
 if(!recipe)stop('UNKNOWN_RECIPE','未登记的陷阱图纸，不能临时发明配方');
 const bag=state?.inventory||[];
 if(!Array.isArray(bag))stop('INVALID_INVENTORY','背包结构不是清单');
 const missing=recipe.requires.map(req=>{
  const stack=bag.filter(x=>x.id===req.id);
  const have=stack.reduce((sum,x)=>{if(!validQty(x.quantity))stop('INVALID_QUANTITY','材料数量非法');return sum+x.quantity;},0);
  return {id:req.id,name:req.name,need:req.quantity,have,missing:Math.max(0,req.quantity-have)};
 });
 const stamina=state?.player?.stamina;
 if(!validQty(stamina))stop('INVALID_STAMINA','精力未建档');
 return {
  recipe_id:recipeId,name:recipe.name,
  materials:missing,
  enough_materials:missing.every(x=>x.missing===0),
  stamina_required:recipe.stamina_cost,stamina_available:stamina,
  duration_minutes:recipe.time_minutes,
  can_craft:missing.every(x=>x.missing===0)&&stamina>=recipe.stamina_cost,
  can_hunt_now:false,
  hunt_status:'本战役尚未建立野生动物实体与栖息地数据，不能认定有可追踪猎物',
  location:state.current_location
 };
}

/** Changes only the supplied mutable, already-copied state. Called by the signed numeric turn engine. */
export function craftTrap(state,recipeId='cord_snare'){
 const p=trapEligibility(state,recipeId);
 if(!p.enough_materials)stop('MATERIALS_MISSING','缺少已登记的实际材料');
 if(!p.can_craft)stop('STAMINA_INSUFFICIENT','精力不足，无法完成制作');
 const recipe=cfg.recipes[recipeId];
 for(const req of recipe.requires){
  let n=req.quantity;
  for(const stack of state.inventory.filter(x=>x.id===req.id)){
   const take=Math.min(n,stack.quantity);stack.quantity-=take;n-=take;
   if(n===0)break;
  }
  if(n!==0)stop('LEDGER_CONFLICT','材料不足，未成功结算');
 }
 state.inventory=state.inventory.filter(x=>x.quantity>0);
 const product=state.inventory.find(x=>x.id===recipe.produces.id);
 if(product){
  if(!validQty(product.quantity)||!Number.isSafeInteger(product.quantity+recipe.produces.quantity))stop('STACK_OVERFLOW','背包数量溢出');
  product.quantity+=recipe.produces.quantity;
 }else state.inventory.push({id:recipe.produces.id,name:recipe.produces.name,quantity:recipe.produces.quantity,equipped:false,category:'陷阱工具',source:'craft:'+recipeId});
 state.player.stamina-=recipe.stamina_cost;
 return {kind:'trap_crafted',recipe:recipeId,inputs:recipe.requires.map(r=>({id:r.id,quantity:r.quantity})),
 outputs:[recipe.produces],stamina_cost:recipe.stamina_cost,duration_minutes:recipe.time_minutes,
 wildlife_added:0,spontaneous_loot:0};
}

/** A description of available actions, not a wildlife spawn or a time-consuming search. */
export function huntingStatus(state){
 const recipe=trapEligibility(state,'cord_snare');
 const registered=state?.hunting?.wildlife||{};
 return {
  location:state.current_location,
  trap_recipe:recipe,
  wildlife_registry_present:typeof state.hunting?.wildlife==='object'&&state.hunting?.wildlife!==null,
  registered_wildlife_instances:Object.keys(registered).length,
  can_confirm_prey:false,
  wildlife_is_unknown_not_zero:'未登记的野生动物不能当作已经确认不存在；也不能凭空视为存在',
  no_turn_advanced:true
 };
}
