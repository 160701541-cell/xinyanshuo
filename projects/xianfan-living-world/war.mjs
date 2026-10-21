// 《仙凡共生》战争与后勤：百万规模的账本推演。纯逻辑，不碰 DOM，可回放。
// 设计原则：屏幕上的旗不是装饰品，它对应这里的 men 数字；数字对不上，界面就不许显示。
import {FACTIONS,factionById} from './society.mjs';
import {note} from './core.mjs';

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

export const EMBLEMS={
 court:{glyph:'宁',color:'#cbb089',ink:'#5c4526',flag:'swallow',border:'double',motto:'承天'},
 merchant:{glyph:'贝',color:'#c07a5c',ink:'#6b3a26',flag:'rect',border:'trim',motto:'通利'},
 folk:{glyph:'禾',color:'#8aa07a',ink:'#41563c',flag:'pennant',border:'dot',motto:'耕战'},
 sect:{glyph:'剑',color:'#6f9aa5',ink:'#2f5461',flag:'swallow',border:'cloud',motto:'问道'},
 guard:{glyph:'甲',color:'#8b7fa6',ink:'#443a5e',flag:'rect',border:'chevron',motto:'守城'}
};
export function emblemOf(faction){return EMBLEMS[faction]||{glyph:'军',color:'#9a927f',ink:'#3d382d',flag:'rect',border:'trim',motto:''};}
const CORPS_CN=['一','二','三','四','五','六','七','八','九','十','十一','十二'];
const GENERAL_SURNAME=['李','王','赵','陈','周','吴','孙','郑','裴','崔'];
const GENERAL_GIVEN=['承业','景行','仲武','德昭','士衡','元朗','子昂','文远'];
function generalName(w,faction,n){
 const r=mulberry(w.seed.length*97+n*31+(faction?faction.length:0));
 const s=GENERAL_SURNAME[Math.floor(r()*GENERAL_SURNAME.length)];
 const g=GENERAL_GIVEN[Math.floor(r()*GENERAL_GIVEN.length)];
 return `${s}${g}`;
}

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
export function createArmy(w,faction,{combat=100000,support=null,x=null,y=null,name=null,seed=1,commander=null,veteran=null}={}){
 ensureWar(w);
 const cap=levyCapacity(w,faction);
 if(combat<=0)throw new Error('兵力必须为正');
 if(combat>cap.combat)throw new Error(`兵力不足：${factionById(faction)?.name||faction} 最多还能征 ${cap.combat.toLocaleString()} 战兵`);
 const sup=support==null?Math.round(combat*MOBILIZE.supportPerCombat):support;
 const seat=SEAT[faction]||{x:0,y:0};
 const corpsNo=(w.war.corpsNo=(w.war.corpsNo||0)+1);
 const corps=`${factionById(faction)?.name||faction}·第${CORPS_CN[corpsNo-1]||corpsNo}镇`;
 const army={id:w.war.nextId++,faction,corpsNo,corps,name:name||corps,
  commander:commander||generalName(w,faction,corpsNo),veteran:veteran??8,
  combat,support:sup,x:x??seat.x,y:y??seat.y,goal:null,
  morale:80,state:'集',routed:false,seed,days:0,emblem:emblemOf(faction),
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
export function veteranFactor(a){return .75+Math.min(1,Math.max(0,(a.veteran??0)/100))*.5;}
export function lossFactor(a){return 1.25-Math.min(1,Math.max(0,(a.veteran??0)/100))*.5;}
function warPower(a){
 const morale=clamp(a.morale,0,100)/100;
 const fed=a.state==='断粮'||a.state==='断粮行军'?.45:1;
 const supportScale=1+Math.min(a.support,Math.max(a.combat,1))/Math.max(a.combat,1)*.08;
 return veteranFactor(a)*a.combat*morale*fed*supportScale;
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
 const rawA=b.combat*intensity*(pb/Math.max(pa,1)),rawB=a.combat*intensity*(pa/Math.max(pb,1));
 // 新兵先死：训练与战历决定谁被消耗。老兵的伤亡乘数更低，新兵更高。
 const lossA=Math.min(Math.round(a.combat*.18),Math.round(rawA*lossFactor(a)));
 const lossB=Math.min(Math.round(b.combat*.18),Math.round(rawB*lossFactor(b)));
 // 辅兵不是数字背景：主力崩了，民夫先散，伤亡按战兵的 35% 计。
 const supA=Math.floor(lossA*.35),supB=Math.floor(lossB*.35);
 a.combat-=lossA;b.combat-=lossB;a.losses.combat+=lossA;b.losses.combat+=lossB;
 a.support=Math.max(0,a.support-supA);b.support=Math.max(0,b.support-supB);
 a.losses.support+=supA;b.losses.support+=supB;
 a.morale=clamp(a.morale-(lossA/Math.max(a.combat+lossA,1))*90+(rng()-.5)*2,0,100);
 b.morale=clamp(b.morale-(lossB/Math.max(b.combat+lossB,1))*90+(rng()-.5)*2,0,100);
 a.battles++;b.battles++;a.veteran=Math.min(100,(a.veteran??0)+3);b.veteran=Math.min(100,(b.veteran??0)+3);
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
  // 你本人若在军中，这一仗要过你自己的生死关
  for(const a of [A,B]){
   if(w.player.army===a.id&&!w.player.dead&&w.player.rank!=='皇帝'&&w.player.rank!=='将帅'){
    const risk=personalBattle(w,a.id,mulberry(a.seed+w.day*31));
    events.push({type:'身死',text:risk.dead?`你在${a.corps}中阵亡。`:`你在${a.corps}中活了下来（战历 ${risk.veteran}）。`});
   }
  }
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
  field:war.armies.filter(a=>!a.routed).map(a=>({id:a.id,name:a.corps||a.name,corps:a.corps,commander:a.commander,veteran:a.veteran??0,emblem:a.emblem||emblemOf(a.faction),losses:{...a.losses},faction:a.faction,combat:a.combat,support:a.support,morale:Math.round(a.morale),state:a.state,supplyDays:+supplyDays(a).toFixed(1),needKg:Math.round(armyNeeds(a).totalKg)}))};
}

// ---------------------------------------------------------------------------
// 身份与权限：皇帝不亲自指挥小兵，小兵也调不动军队
// ---------------------------------------------------------------------------
export const RANKS={
 '皇帝':{decree:true,appoint:true,lead:true,fight:false,note:'下圣旨、点将挂帅；但不会亲自带一个什去冲阵'},
 '将帅':{decree:false,appoint:true,lead:true,fight:false,note:'统领一军，行军布阵由你；国策不归你'},
 '校尉':{decree:false,appoint:false,lead:true,fight:true,note:'领一营，可上阵'},
 '什长':{decree:false,appoint:false,lead:false,fight:true,note:'带十个人，还是会被砍'},
 '小兵':{decree:false,appoint:false,lead:false,fight:true,note:'听令，活着'},
 '平民':{decree:false,appoint:false,lead:false,fight:false,note:'不在军中'}
};
export function rankOf(w){return w.player.rank||'平民';}
export function rankInfo(w){return RANKS[rankOf(w)]||RANKS['平民'];}
export function canDo(w,cap){return !!rankInfo(w)[cap];}
export function setRank(w,rank){
 if(!RANKS[rank])return false;
 w.player.rank=rank;
 note(w,'身份',`身份切换：${rank}——${RANKS[rank].note}`);
 return true;
}
export function authorityReport(w){
 const info=rankInfo(w);
 return ['decree','appoint','lead','fight'].map(cap=>({cap,label:({decree:'下圣旨',appoint:'点将',lead:'领兵出战',fight:'亲自上阵'})[cap],allowed:!!info[cap],why:info[cap]?'':`${rankOf(w)}无权${({decree:'下圣旨',appoint:'点将',lead:'领兵',fight:'上阵'})[cap]}`}));
}
export function issueDecree(w,kind,arg={}){
 if(!canDo(w,'decree'))return {ok:false,error:`${rankOf(w)}无权下圣旨——${rankInfo(w).note}`};
 ensureWar(w);
 if(kind==='levy'){
  w.player.decreeCount=(w.player.decreeCount||0)+1;
  const a=createArmy(w,arg.faction||'court',{combat:arg.combat||100000,seed:w.player.decreeCount*17,veteran:arg.veteran});
  note(w,'圣旨',`${w.player.name}下旨：${factionById(a.faction)?.name}征 ${a.combat.toLocaleString()} 战兵，编为${a.corps}，以${a.commander}为将。`);
  return {ok:true,army:a};
 }
 if(kind==='march'){
  const a=w.war.armies.find(x=>x.id===arg.armyId&&!x.routed);if(!a)return {ok:false,error:'无此军'};
  a.goal=arg.goal||{x:0,y:0};
  note(w,'圣旨',`${a.corps}奉旨开拔。`);
  return {ok:true,army:a};
 }
 if(kind==='recall'){
  for(const a of w.war.armies)a.goal={...SEAT[a.faction]};
  note(w,'圣旨','诏令诸军回师。');return {ok:true};
 }
 return {ok:false,error:'未知旨意'};
}
export function takeCommand(w,armyId){
 if(!canDo(w,'lead'))return {ok:false,error:`${rankOf(w)}不能领兵：${rankInfo(w).note}`};
 const a=(w.war?.armies||[]).find(x=>x.id===armyId&&!x.routed);
 if(!a)return {ok:false,error:'没有这支军'};
 w.war.command=a.id;a.commander=w.player.name;a.ledByPlayer=true;
 note(w,'军情',`${w.player.name}接管${a.corps}（${a.commander}）；此后行军布阵由你决断。`);
 return {ok:true,army:a};
}
export function joinArmy(w,armyId){
 if(!canDo(w,'fight'))return {ok:false,error:`${rankOf(w)}不上阵：${rankInfo(w).note}`};
 const a=(w.war?.armies||[]).find(x=>x.id===armyId&&!x.routed);
 if(!a)return {ok:false,error:'没有这支军'};
 w.player.army=a.id;w.player.rank=w.player.rank==='皇帝'?'皇帝':(w.player.rank||'小兵');
 note(w,'从军',`你编入${a.corps}，名下战兵 ${a.combat.toLocaleString()}；你只是其中一人。`);
 return {ok:true,army:a};
}
// 个人存活：不是“士兵”这个抽象概念，而是战历决定的概率
export function surviveRoll(veteran,rng=mulberry(7)){
 const v=clamp(veteran??0,0,100);
 const p=.42+v/100*.5; // 新兵 42%，百战老兵 92%
 const roll=rng();
 return {survives:roll<p,p,roll};
}
export function personalBattle(w,armyId,rng=mulberry(11)){
 const a=(w.war?.armies||[]).find(x=>x.id===armyId);
 if(!a)return {ok:false,error:'没有这支军'};
 const v=a.veteran??0;const r=surviveRoll(v,rng);
 if(!r.survives){w.player.dead=true;w.player.deathCause=`${a.corps}溃阵`;note(w,'阵亡',`你在${a.corps}中阵亡。战历 ${v} 的老兵也没能活着走出这一阵。`);return {ok:true,...r,dead:true};}
 a.veteran=Math.min(100,v+4);
 w.player.veteran=Math.min(100,(w.player.veteran||0)+4);
 note(w,'战历',`你从${a.corps}的乱军里活下来；战历 ${a.veteran}（越高越难死，也越能打）。`);
 return {ok:true,...r,dead:false,veteran:a.veteran};
}
