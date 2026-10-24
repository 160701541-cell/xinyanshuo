import {readFileSync} from 'node:fs';
import {digest,verifyEvents,countTurns} from './campaign_guard.mjs';
import {verifyNumericState} from './numeric_accounts.mjs';
const policy=JSON.parse(readFileSync(new URL('../data/county_market_v1.json',import.meta.url),'utf8'));
const NO=(code)=>{throw Object.assign(new Error(code),{code})};
const clock=s=>{const x=s.time.hour*60+s.time.minute;s.time.hour=Math.floor(x/60);s.time.minute=x%60;s.time.display='承平三年 · 第'+s.time.day+'日 · '+String(s.time.hour).padStart(2,'0')+':'+String(s.time.minute).padStart(2,'0')};
const tick=(s,n)=>{s.time.minute+=n;clock(s)};
const qty=(s,id)=>s.inventory.find(x=>x.id===id)?.quantity||0;
const debit=(s,id,n)=>{const i=s.inventory.find(x=>x.id===id);if(!i||i.quantity<n)NO('ITEM_NOT_OWNED');i.quantity-=n;s.inventory=s.inventory.filter(x=>x.quantity>0)};
const acquire=(s,id,n,source)=>{const item=s.inventory.find(x=>x.id===id);if(item)item.quantity+=n;else s.inventory.push({id,name:({fishing_line:'钓鱼线',fish_hook:'鱼钩',vegetable_seed_packet:'青菜种子包',radish_seed_packet:'萝卜种子包',maize_seed_packet:'玉米种子包'})[id]||id,quantity:n,category:'商品',equipped:false,source})};
export function transactCountyMarket(before,events){
 verifyEvents(events);verifyNumericState(before);
 if(digest(before)!==events.at(-1).state_hash||countTurns(events)!==11)NO('SAVE_NOT_AT_COUNTY');
 if(before.location_id!=='linan'||before.player.money<0)NO('NOT_IN_COUNTY');
 const s=structuredClone(before);
 if(s.economy?.markets?.linan)NO('REPEATED_MARKET_INTRO');
 const originalMoney=s.player.money,ledger=[],quotes=[],stalls={};
 for(const shop of policy.stalls){
  stalls[shop.id]={id:shop.id,name:shop.name,cash:shop.money,
   initial_cash:shop.money,stock:{...shop.stock},initial_stock:{...shop.stock},
   buy:{...shop.buy},sell:{...shop.sell},source_event_id:'EV000014'};
 }
 const transfer=(shop,id,kind,price)=>{
  if(kind==='sell'){
   if(qty(s,id)<1||shop.cash<price)return false;
   debit(s,id,1);shop.stock[id]=(shop.stock[id]||0)+1;
   shop.cash-=price;s.player.money+=price;
  }else{
   if(s.player.money<price||!shop.stock[id])return false;
   shop.stock[id]-=1;s.player.money-=price;shop.cash+=price;
   acquire(s,id,1,'shop:'+shop.id+'@EV000014');
  }
  ledger.push({from:kind==='sell'?'CFPLAYER00001':shop.id,to:kind==='sell'?shop.id:'CFPLAYER00001',
   item_id:id,quantity:1,copper:price,kind,shop_id:shop.id,
   player_balance_after:s.player.money,shop_balance_after:shop.cash});
  return true;
 };
 // User asks sale of a single plantain, two fishing implements and practical seeds;
 // let the user's budget determine which seeds can actually be obtained.
 const herbalist=stalls.HERB,gear=stalls.GEAR,seeds=stalls.SEEDS;
 const plantainSold=transfer(herbalist,'fresh_plantain','sell',herbalist.buy.fresh_plantain);
 const lineBought=transfer(gear,'fishing_line','buy',gear.sell.fishing_line);
 const hookBought=transfer(gear,'fish_hook','buy',gear.sell.fish_hook);
 const seedBought=transfer(seeds,'vegetable_seed_packet','buy',seeds.sell.vegetable_seed_packet);
 // For the requested vegetables, the cheapest suitable supplemental crop packet.
 const radishBought=transfer(seeds,'radish_seed_packet','buy',seeds.sell.radish_seed_packet);
 quotes.push({shop:'HERB',offers:{fresh_plantain:herbalist.buy.fresh_plantain},
   knowledge:[{plant:'车前草',identification:'叶片与穗状花序，药材出售前核对真伪'},{plant:'艾草',identification:'叶裂与特殊气味，防止误认'},{plant:'蒲公英',identification:'黄色花和乳白汁，注意形似植株'}],
   caution:'NPC口述辨认特征只是入门线索，不代表自行食用安全'});
 quotes.push({shop:'PRODUCE',requests:[{id:'field_hare',copper:7},{id:'leafy_vegetables',copper:3},{id:'river_fish',copper:3}],
   need:'只收来源清楚且新鲜的野味和蔬菜，不能保证长期固定收购'});
 quotes.push({shop:'GEAR',offers:{fishing_line:4,fish_hook:3}});
 quotes.push({shop:'SEEDS',offers:{vegetable_seed_packet:5,radish_seed_packet:3,maize_seed_packet:4}});
 s.economy=s.economy||{};
 s.economy.markets=s.economy.markets||{};
 s.economy.markets.linan={id:'linan',registered_by:'EV000014',stalls,quote_day:s.time.day};
 const initialTotal=originalMoney+policy.stalls.reduce((n,x)=>n+x.money,0);
 const finalTotal=s.player.money+Object.values(stalls).reduce((n,x)=>n+x.cash,0);
 if(finalTotal!==initialTotal)NO('MONEY_NOT_CONSERVED');
 if(!plantainSold)NO('UNSOLD_PLANTAIN');
 if(!lineBought||!hookBought)NO('GEAR_PURCHASE_FAILED');
 if(!seedBought||!radishBought)NO('SEED_PURCHASE_FAILED');
 if(s.player.stamina<5)NO('NOT_ENOUGH_ENERGY');
 s.player.stamina-=5;tick(s,65);
 s.position={x:220,y:490};s.current_location='临安县城·集市';s.sub_location='县城东市';
 s.fishing_requests.rod_pair.status='owned_fishing_line_1_hook_1; rod_blank_1; assemble_needed; second rod still missing';
 s.farming={...(s.farming||{}),seeds_owned:{vegetable_seed_packet:1,radish_seed_packet:1},
  fields_prepared:0,seed_origin:'linan-registered-vendor',note:'种子需返回家乡核实耕地使用权、土壤与季节后播种；不直接生成蔬菜'};
 s.last_event_id='EV000014';
 verifyNumericState(s);
 const event={seq:14,type:'turn_committed',turn_id:12,prev_hash:events.at(-1).hash,action:'county_market_herb_sale_fishing_supplies_and_seeds',
  rule_version:policy.version,account_register:{market:'linan',event_id:'EV000014',opening_accounts:policy.stalls.map(x=>({id:x.id,starting_copper:x.money,opening_stock:x.stock}))},
  shops:quotes,transactions:ledger,player_coins_before:originalMoney,player_coins_after:s.player.money,
  sum_shop_and_player_coins_before:initialTotal,sum_shop_and_player_coins_after:finalTotal,
  pending_npc_errand:'sister food delivery lacked explicit dialogue closure; home reunion is not proof of resolved question',
  second_basket_status:'still player-carried; player did not explicitly instruct a second deployment',
  elapsed_minutes:65,stamina_cost:5,
  state_hash:digest(s)};
 event.hash=digest(event);
 return {state:s,events:[...events,event],event,public:{
  sold:plantainSold,bought:{line:lineBought,hook:hookBought,vegetable_seeds:seedBought,radish_seeds:radishBought},
  money:s.player.money,transactions:ledger,quotes,at:s.time.display,stamina:s.player.stamina}};
}
