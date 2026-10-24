import {createHash} from 'node:crypto';
import {readFileSync} from 'node:fs';
import {digest,verifyEvents} from './campaign_guard.mjs';
import {verifyNumericState} from './numeric_accounts.mjs';
const cfg=JSON.parse(readFileSync(new URL('../data/new_basket_scouting_v1.json',import.meta.url),'utf8'));
const rng=(seed,label,max)=>Number(BigInt('0x'+createHash('sha256').update(seed+'|'+cfg.version+'|'+label).digest('hex').slice(0,13))%BigInt(max));
const stop=(code)=>{throw Object.assign(new Error(code),{code});};
const nextTime=(s,minutes)=>{
 const total=s.time.hour*60+s.time.minute+minutes;
 if(total>=1440)stop('CROSS_DAY_NOT_IMPLEMENTED');
 s.time.hour=Math.floor(total/60);s.time.minute=total%60;
 s.time.display='承平三年 · 第'+s.time.day+'日 · '+String(s.time.hour).padStart(2,'0')+':'+String(s.time.minute).padStart(2,'0');
};
const total=(arr,id)=>arr.filter(x=>x.resource===id).reduce((n,x)=>n+x.quantity,0);
function take(arr,id,n){
 let remains=n;for(const item of arr.filter(x=>x.resource===id)){
  const step=Math.min(remains,item.quantity);item.quantity-=step;remains-=step;if(!remains)break;
 }
 if(remains)stop('STOCK_NOT_ENOUGH');
}
export function scoutAndMakeNewBasket(original,events){
 verifyEvents(events);verifyNumericState(original);
 if(digest(original)!==events.at(-1)?.state_hash)stop('HASH_CONFLICT');
 if(events.some(e=>e.action==='scout_downstream_and_try_second_fish_basket'))stop('ACTION_REPLAY');
 const s=structuredClone(original),zone=s.ecology?.['shiqiao-outskirts-v1'];
 if(!zone?.freshwater?.site||!zone.freshwater.installed_gear?.length)stop('RIVER_AREA_MISSING');
 if(s.player.stamina<cfg.forage.search_stamina)stop('STAMINA_LOW');
 const before={time:s.time.display,stamina:s.player.stamina,money:s.player.money};
 if(!zone.basket_scouting){
  zone.basket_scouting={version:cfg.version,seed:s.world_seed,
   nodes:cfg.sites.map(site=>{
    const present=rng(s.world_seed,site.id+'|exists',100)<site.spawn_percent;
    return{id:site.id,name:site.name,resource:site.resource,x:site.x,y:site.y,
      initial_quantity:present?site.base+rng(s.world_seed,site.id+'|stock',site.extra):0,
      quantity:present?site.base+rng(s.world_seed,site.id+'|stock',site.extra):0,
      owner:'unclaimed_commons'};
   })};
 }
 const nodes=zone.basket_scouting.nodes;
 const discovered=nodes.map(x=>({id:x.id,resource:x.resource,stock:x.quantity}));
 nextTime(s,cfg.forage.search_minutes);s.player.stamina-=cfg.forage.search_stamina;
 // Can only harvest enough for exactly one basket and store the provenance in the event.
 const recipe=cfg.recipe.requires;
 const missing=recipe.map(x=>({id:x.id,needed:x.quantity,available:total(nodes,x.id)}));
 let completed=false;
 const sources=[];
 if(missing.every(x=>x.available>=x.needed)&&s.player.stamina>=cfg.recipe.craft_stamina){
  for(const req of recipe){take(nodes,req.id,req.quantity);sources.push({resource:req.id,quantity:req.quantity});}
  nextTime(s,cfg.recipe.craft_minutes);s.player.stamina-=cfg.recipe.craft_stamina;
  const held=s.inventory.find(x=>x.id===cfg.recipe.product);
  if(held)held.quantity++;
  else s.inventory.push({id:cfg.recipe.product,name:'简易编织鱼笼',quantity:1,equipped:false,category:'渔具',
    source:'basket_scouting_habitat:'+cfg.version,reinforcement:null});
  completed=true;
 }else{
  // No gift materials and no fabricated second basket if this location lacks plants.
  for(const node of nodes){
   const q=node.quantity;
   if(!q)continue;
   node.quantity=0;
   const item=s.inventory.find(x=>x.id===node.resource);
   if(item)item.quantity+=q;
   else s.inventory.push({id:node.resource,name:node.resource==='flexible_branch'?'韧枝':'植物纤维',
     quantity:q,category:'野外材料',equipped:false,source:'scout:'+node.id});
   sources.push({resource:node.resource,quantity:q,node_id:node.id,stored_in_inventory:true});
  }
 }
 if(s.fishing_requests?.rod_pair)s.fishing_requests.rod_pair.note='本次在下游搜索鱼笼材料，不是制作鱼竿；旧鱼竿仍未完成';
 s.last_event_id='EV'+String(events.length+1).padStart(6,'0');
 const event={seq:events.length+1,prev_hash:events.at(-1).hash,type:'turn_committed',turn_id:events.filter(e=>e.type==='turn_committed').length+1,
  action:'scout_downstream_and_try_second_fish_basket',rule_version:cfg.version,
  discovered,material_receipts:sources,recipe_requirements:recipe,basket_crafted:completed,
  duration_minutes:cfg.forage.search_minutes+(completed?cfg.recipe.craft_minutes:0),
  stamina_cost:cfg.forage.search_stamina+(completed?cfg.recipe.craft_stamina:0),
  fish_caught:0,fish_population_changed:false,
  before,after:{time:s.time.display,stamina:s.player.stamina,money:s.player.money},state_hash:digest(s)};
 event.hash=digest(event);return{state:s,event,events:[...events,event],public:{completed,discovered,sources,after:event.after}};
}
