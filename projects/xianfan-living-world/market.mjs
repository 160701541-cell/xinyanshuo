// 《仙凡共生》市面与官产：价格由供需算，官营有收益也有民怨，府库不是无限口袋。
// 玩家不是在“看数值”，而是在“定税、开仓、禁榷、收购、修驿传”里选一个代价。
import {note} from './core.mjs';
import {ensureFin,purseOf} from './units.mjs';

export const MARKET_VERSION='market-1.0.0';
export const GOODS={
 grain:{name:'粮',base:12,elasticity:1.6,perCapita:.9,unit:'斗'},
 salt:{name:'盐',base:40,elasticity:1.2,perCapita:.03,unit:'斤'},
 iron:{name:'铁',base:30,elasticity:1.3,perCapita:.01,unit:'斤'},
 cloth:{name:'布',base:25,elasticity:1.1,perCapita:.02,unit:'匹'},
 tea:{name:'茶',base:35,elasticity:1.0,perCapita:.01,unit:'斤'}
};
const BAND=[.45,3.2];
const clamp=(v,a,b)=>Math.min(b,Math.max(a,v));

export function ensureMarket(w){
 if(!w.market){
  w.market={
   prices:Object.fromEntries(Object.entries(GOODS).map(([k,g])=>[k,g.base])),
   supply:Object.fromEntries(Object.entries(GOODS).map(([k])=>[k,1])),
   demand:Object.fromEntries(Object.entries(GOODS).map(([k])=>[k,1])),
   granary:Math.round((w.people?.length||13680)*3),
   taxRate:.10,corruption:.15,post:1,relief:0,unrest:12,
   monopoly:{salt:false,iron:false},log:[],day:0,famine:0
  };
 }
 return w.market;
}
function story(w,type,text){const m=ensureMarket(w);m.log.push({type,text,day:m.day});if(m.log.length>200)m.log=m.log.slice(-200);note(w,'市面',text);}

/** 一天的市面：供给看收成与驿传，需求看人口与价格；价格是供需的幂函数。 */
export function tickMarket(w,{weather=w.weather||'晴',harvest=1}={}){
 const m=ensureMarket(w);
 const pop=w.people?.length||13680;
 const wt=weather==='旱'?.72:weather==='涝'?.8:weather==='雨'?.94:1;
 const postK=1+((m.post??1)-1)*.2;
 const events=[];
 for(const [id,g] of Object.entries(GOODS)){
  const supply=Math.max(.12,harvest*wt*postK*(id==='grain'?1:.88));
  // 需求是价格的函数：价越高，买的人越少（带宽 0.5–1.5 防止爆走）
  const demand=Math.max(.12,Math.min(1.5,Math.pow(g.base/Math.max(m.prices[id],1),.8)));
  m.supply[id]=+supply.toFixed(3);m.demand[id]=+demand.toFixed(3);
  const target=g.base*Math.pow(demand/Math.max(supply,.01),g.elasticity);
  const next=(m.prices[id]??g.base)*.55+target*.45; // 缓慢收敛，不做秒级跳价
  m.prices[id]=+clamp(next,BAND[0]*g.base,BAND[1]*g.base).toFixed(1);
 }
 // 民怨：粮价、税、赈济与禁榷共同决定
 const grainIdx=m.prices.grain/GOODS.grain.base;
 m.unrest=clamp(m.unrest+(grainIdx-1)*20+(m.taxRate-.1)*140-(m.relief||0)*20+((m.monopoly.salt?3:0)+(m.monopoly.iron?3:0)),0,100);
 m.relief=0;
 // 官营收益与税入进府库（贪腐先抽一道）
 ensureFin(w);const p=w.states.court;
 const revenue=Math.round(m.taxRate*pop*10*(1-m.corruption)*(1-Math.max(0,m.unrest-50)/100));
 p.treasury+=revenue;
 const saltRev=m.monopoly.salt?Math.round(pop*2.2*(1-m.corruption)):0;
 const ironRev=m.monopoly.iron?Math.round(pop*1.6*(1-m.corruption)):0;
 p.treasury+=saltRev+ironRev;
 if(m.unrest>=70){m.famine++;const loss=Math.round(pop*.002*Math.min(3,m.famine));events.push({type:'流民',text:`民怨 ${Math.round(m.unrest)}，${loss} 户弃田出走，县境户口减损。`});}
 else m.famine=0;
 if(m.unrest>=85)events.push({type:'民变',text:'饥民聚于东市，差役弹压不住。'});
 if(grainIdx>=1.6)events.push({type:'粮价',text:`粮价涨到 ${m.prices.grain} 文/斗（基准 ${GOODS.grain.base}）。`});
 if(events.length)m.log.push(...events.map(e=>({...e,day:m.day})));
 m.day++;
 return {prices:{...m.prices},unrest:Math.round(m.unrest),revenue,events};
}
/** 开仓平粜：县仓出粮，市面供给上来，粮价与民怨一起降。 */
export function releaseGrain(w,dan){
 const m=ensureMarket(w);
 dan=Math.round(dan);
 if(dan<=0)return {ok:false,error:'数量无效'};
 if(m.granary<dan)return {ok:false,error:`县仓只有 ${m.granary} 斗`};
 m.granary-=dan;
 const relief=Math.min(6,dan/Math.max((w.people?.length||13680)*.2,1));
 m.relief=relief;m.unrest=clamp(m.unrest-relief*12,0,100);
 m.prices.grain=+Math.max(GOODS.grain.base*.5,m.prices.grain*(1-Math.min(.35,dan/20000))).toFixed(1);
 story(w,'平粜',`开仓 ${dan.toLocaleString()} 斗，粮价落至 ${m.prices.grain} 文，民怨稍缓。`);
 return {ok:true,granary:m.granary,price:m.prices.grain};
}
/** 官府收购：府库出钱把粮收进官仓，市面供给减少、价格上行——救荒的代价。 */
export function buyToGranary(w,dan){
 const m=ensureMarket(w);dan=Math.round(dan);
 if(dan<=0)return {ok:false,error:'数量无效'};
 const cost=Math.round(dan*m.prices.grain);
 ensureFin(w);const p=w.states.court;
 if(p.treasury<cost)return {ok:false,error:`府库不足：需 ${cost.toLocaleString()} 文`};
 p.treasury-=cost;m.granary+=dan;
 m.prices.grain=+(m.prices.grain*(1+Math.min(.25,dan/40000))).toFixed(1);
 story(w,'收购',`官府花 ${cost.toLocaleString()} 文收粮 ${dan.toLocaleString()} 斗，仓实而市价涨。`);
 return {ok:true,cost,granary:m.granary,price:m.prices.grain};
}
/** 定税：税率一动，府库与民怨同时动。 */
export function setTax(w,rate){
 if(!(rate>=0&&rate<=.35))return {ok:false,error:'税率须在 0–35%'};
 const m=ensureMarket(w);const before=m.taxRate;m.taxRate=rate;
 story(w,'税制',`田税自 ${Math.round(before*100)}% 改为 ${Math.round(rate*100)}%。`);
 return {ok:true,before,rate};
}
/** 禁榷：盐铁官营，进钱，但市价与民怨一起涨。 */
export function setMonopoly(w,good,on){
 const m=ensureMarket(w);
 if(!(good in m.monopoly))return {ok:false,error:'只可禁榷盐铁'};
 m.monopoly[good]=!!on;
 m.prices[good]=+(GOODS[good].base*(on?1.3:m.prices[good]/GOODS[good].base)).toFixed(1);
 story(w,'禁榷',`${GOODS[good].name}${on?'归官营':'弛禁'}，市价 ${m.prices[good]} 文。`);
 return {ok:true,monopoly:{...m.monopoly}};
}
/** 修驿传：花一次钱，长期抬供给、平物价。 */
export function buildPost(w){
 const m=ensureMarket(w);const cost=Math.round(300000*Math.max(1,m.post));
 ensureFin(w);const p=w.states.court;
 if(p.treasury<cost)return {ok:false,error:`府库不足：修驿传需 ${cost.toLocaleString()} 文`};
 p.treasury-=cost;m.post=+(m.post+.25).toFixed(2);
 story(w,'驿传',`增置驿马，转运效率 ${Math.round((m.post-1)*100)}%。`);
 return {ok:true,cost,post:m.post};
}
export function marketReport(w){
 const m=ensureMarket(w);
 return {day:m.day,unrest:Math.round(m.unrest),granary:m.granary,taxRate:m.taxRate,post:m.post,
  monopoly:{...m.monopoly},treasury:purseOf(w,'court'),
  goods:Object.entries(GOODS).map(([id,g])=>({id,name:g.name,price:m.prices[id],base:g.base,ratio:+(m.prices[id]/g.base).toFixed(2),unit:g.unit})),
  log:(m.log||[]).slice(-6).reverse()};
}
