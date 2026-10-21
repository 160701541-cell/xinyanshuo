// 《仙凡共生》战争与后勤：百万规模的账本推演。纯逻辑，不碰 DOM，可回放。
// 设计原则：屏幕上的旗不是装饰品，它对应这里的 men 数字；数字对不上，界面就不许显示。
import {FACTIONS,factionById} from './society.js';

export const WAR_VERSION='war-0.1.0';
/** 1 石 = 60 公斤（书中简化为 120 斤，未按明代 94 公斤换算）。 */
export const KG_PER_DAN=60;
/** 每人每日口粮：战兵 1.4kg，辅兵 1.0kg，驮畜每匹 5kg；每 20 人摊 1 匹驮畜。 */
export const RATION={combat:1.4,support:1.0,beast:5.0};
export const BEASTS_PER=20;
/** 可动员：战兵取人口的 1.5%，辅兵按 1:3 征发（历史常例，不是随手写的比例）。 */
export const MOBILIZE={combatRatio:.015,supportPerCombat:3};
/** 一支军最多自带 5 日份口粮；超过就必须靠粮道，运得越远损耗越大。 */
export const CARRY_DAYS=5;
export const TRANSPORT_LOSS_PER_100KM=.35;
/** 断粮每日士气惩罚与逃兵率。 */
export const HUNGER={morale:-8,desert:.03};

const SEAT={court:{x:0,y:0},merchant:{x:0,y:0},folk:{x:6900,y:-3500},sect:{x:11300,y:-7200},guard:{x:11300,y:-7200}};

/** 各国/各势力的户籍人口。县域 13680 人只是这张表里的一粒沙。 */
export const REALM={
 court:{people:12000000,name:'大宁',note:'户籍在册的编户齐民'},
 merchant:{people:3800000,name:'临安商户',note:'商籍与附籍，粮在手里但人不归县衙'},
 folk:{people:16000000,name:'乡野编户',note:'天下大多数人口在此，税重、分散、难征'},
 sect:{people:600000,name:'青云道众',note:'道士、道童与依附的山民'},
 guard:{people:300000,name:'御城军籍',note:'军户世代当兵，不事农桑'}
};

const mulberry=(seed)=>{let a=seed>>>0;return()=>{a=(a+0x6D2B79F5)>>>0;let t=Math.imul(a^(a>>>15),1|a);t=(t+Math.imul(t^(t>>>7),61|t))^t;return((t^(t>>>14))>>>0)/4294967296;};};
const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));

export function ensureWar(w){
 if(!w.war)w.war={schema:WAR_VERSION,day:0,armies:[],log:[],nextId:1};
 return w.war;
}
/** 该势力还能再征多少战兵（已出征的）与辅兵上限。 */
export function levyCapacity(w,faction){
 ensureWar(w);
 const r=REALM[faction];if(!r)return{combat:0,support:0,total:0};
 const combatMax=Math.floor(r.people*MOBILIZE.combatRatio);
 const used=w.war.armies.filter(a=>a.faction===faction&&!a.routed).reduce((n,a)=>n+a.combat,0);
 const combat=Math.max(0,combatMax-used);
 return{combat,support:combat*MOBILIZE.supportPerCombat,combatMax,total:combat+combat*MOBILIZE.supportPerCombat};
}
export function armyNeeds(a){
 const beast=Math.ceil((a.combat+a.support)/BEASTS_PER);
 const rationKg=a.combat*RATION.combat+a.support*RATION.support;
 const beastKg=beast*RATION.beast;
 const totalKg=rationKg+beastKg;
 return{beast,rationKg,beastKg,totalKg,dan:totalKg/KG_PER_DAN,beastPerDay:beast};
}
export function createArmy(w,faction,{combat=100000,support=null,x=null,y=null,name=null,seed=1}={}){
 ensureWar(w);
 const cap=levyCapacity(w,faction);
 if(combat<=0)throw new Error('兵力必须为正');
 if(combat>cap.combat)throw new Error(`兵力不足：${factionById(faction)?.name||faction} 最多还能征 ${cap.combat.toLocaleString()} 战兵`);
 const sup=support==null?Math.round(combat*MOBILIZE.supportPerCombat):support;
 const seat=SEAT[faction]||{x:0,y:0};
 const army={id:w.war.nextId++,faction,name:name||`${factionById(faction)?.name||faction}军`,
  combat,support:sup,x:x??seat.x,y:y??seat.y,goal:null,
  morale:80,state:'集',routed:false,seed,days:0,
  losses:{combat:0,support:0},battles:0};
 army.supplyKg=armyNeeds(army).totalKg*CARRY_DAYS;
 w.war.armies.push(army);
 return army;
}
export function supplyDays(a){const n=armyNeeds(a).totalKg;return n>0?a.supplyKg/n:0;}
/** 粮道：运到前线的实际征粮量 = 口粮 × (1 + 距离损耗)。距离用米。 */
export function deliveredCostKg(a,distanceMeters){
 const need=armyNeeds(a).totalKg;
 const loss=1+(distanceMeters/100000)*TRANSPORT_LOSS_PER_100KM;
 return{rationale:need,delivered:need*loss,loss};
}
function moveToward(a,dtDays){
 if(!a.goal)return;
 const dx=a.goal.x-a.x,dy=a.goal.y-a.y,d=Math.hypot(dx,dy);
 if(d<1){a.goal=null;a.state='驻';return;}
 const starved=a.state==='断粮';
 const kmPerDay=(starved?12:22)*(a.combat+a.support>500000?.8:1);
 const step=Math.min(d,kmPerDay*1000*dtDays);
 a.x+=dx/d*step;a.y+=dy/d*step;
 if(step>=d){a.x=a.goal.x;a.y=a.goal.y;a.goal=null;a.state='驻';}
 else a.state=starved?'断粮行军':'行军';
}
function warPower(a){
 const morale=clamp(a.morale,0,100)/100;
 const fed=a.state==='断粮'||a.state==='断粮行军'?.45:1;
 const supportScale=1+Math.min(a.support,Math.max(a.combat,1))/Math.max(a.combat,1)*.08;
 return a.combat*morale*fed*supportScale;
}
/** 一天的后勤结算：吃粮、断粮掉士气、逃兵。返回事件。 */
export function consumeDay(a){
 const need=armyNeeds(a).totalKg;
 const events=[];
 if(a.supplyKg>=need){a.supplyKg-=need;if(a.state==='断粮'||a.state==='断粮行军')a.state='驻';}
 else{
  a.supplyKg=0;
  const wasFed=a.state!=='断粮'&&a.state!=='断粮行军';
  a.state=a.goal?'断粮行军':'断粮';
  a.morale=clamp(a.morale+HUNGER.morale,0,100);
  const desertSupport=Math.floor(a.support*HUNGER.desert);
  const desertCombat=Math.floor(a.combat*HUNGER.desert*.35);
  a.support-=desertSupport;a.combat-=desertCombat;
  a.losses.support+=desertSupport;a.losses.combat+=desertCombat;
  if(wasFed)events.push({type:'断粮',text:`${a.name}断粮，当日逃散 ${(desertSupport+desertCombat).toLocaleString()} 人。`});
 }
 a.days++;
 return events;
}
/** 两支军相遇：兰开斯特线性律 + 士气与补给修正，逐日推演。 */
export function battleDay(a,b,rng=mulberry(1)){
 const pa=warPower(a),pb=warPower(b);
 const intensity=.06;
 const lossA=Math.min(a.combat,Math.round(b.combat*intensity*(pb/Math.max(pa,1))));
 const lossB=Math.min(b.combat,Math.round(a.combat*intensity*(pa/Math.max(pb,1))));
 // 辅兵不是数字背景：主力崩了，民夫先散，伤亡按战兵的 35% 计。
 const supA=Math.floor(lossA*.35),supB=Math.floor(lossB*.35);
 a.combat-=lossA;b.combat-=lossB;a.losses.combat+=lossA;b.losses.combat+=lossB;
 a.support=Math.max(0,a.support-supA);b.support=Math.max(0,b.support-supB);
 a.losses.support+=supA;b.losses.support+=supB;
 a.morale=clamp(a.morale-(lossA/Math.max(a.combat+lossA,1))*90+(rng()-.5)*2,0,100);
 b.morale=clamp(b.morale-(lossB/Math.max(b.combat+lossB,1))*90+(rng()-.5)*2,0,100);
 a.battles++;b.battles++;
 return{lossA,lossB};
}
function routArmy(a){if(a.routed)return; a.routed=true;a.state='溃散';a.goal=null;}
/** 推演一天：行军、补给、相遇开战、崩溃判负。 */
export function tickWarDay(w,{distanceToDepot=(a)=>0,supplyLine=true}={}){
 const war=ensureWar(w);const events=[];
 for(const a of war.armies){
  if(a.routed)continue;
  moveToward(a,1);
  if(!a.goal||!supplyLine)events.push(...consumeDay(a));
  else{
   // 行军日靠粮道：就地补满（有粮道才算补上，断粮则进断粮态）
   const {delivered}=deliveredCostKg(a,distanceToDepot(a));
   a.supplyKg=Math.min(armyNeeds(a).totalKg*CARRY_DAYS,a.supplyKg+delivered);
   events.push(...consumeDay(a));
  }
  if(a.morale<=0||a.combat<=0)routArmy(a);
 }
 // 相遇：不同势力、距离 8 公里内且都没溃散
 for(let i=0;i<war.armies.length;i++)for(let j=i+1;j<war.armies.length;j++){
  const A=war.armies[i],B=war.armies[j];
  if(A.routed||B.routed||A.faction===B.faction)continue;
  if(Math.hypot(A.x-B.x,A.y-B.y)>8000)continue;
  const rng=mulberry(A.seed*7919+B.seed*104729+war.day);
  const {lossA,lossB}=battleDay(A,B,rng);
  A.state='战';B.state='战';
  events.push({type:'战斗',text:`${A.name}与${B.name}交兵：${lossA.toLocaleString()} 对 ${lossB.toLocaleString()} 人。`});
  if(A.morale<=18)routArmy(A);
  if(B.morale<=18)routArmy(B);
 }
 war.day++;
 if(events.length)war.log.push(...events.slice(-12));
 if(war.log.length>200)war.log=war.log.slice(-200);
 return{day:war.day,events};
}
export function warReport(w){
 const war=ensureWar(w);
 const total=war.armies.reduce((n,a)=>n+a.combat+a.support,0);
 return{day:war.day,armies:war.armies.length,total,
  field:war.armies.filter(a=>!a.routed).map(a=>({id:a.id,name:a.name,faction:a.faction,combat:a.combat,support:a.support,morale:Math.round(a.morale),state:a.state,supplyDays:+supplyDays(a).toFixed(1),needKg:Math.round(armyNeeds(a).totalKg)}))};
}
