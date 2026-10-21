// 《仙凡共生》五道：军功、官身、商贾、仙途、乡望。
// 每一道都能走到顶，但每一道的“顶”不是同一种东西：
// 军功靠战功与人头，官身靠名声（也可以拿钱铺路），商贾靠本钱与周转，
// 仙途靠灵根与灵石，乡望靠田产与乡亲的口碑。规矩只有一条：**没有白拿的位置**。
import {note} from './core.mjs';
import {ensureCurrency,RATES} from './currency.mjs';
import {ensureCultivation,RETAINER_COST,ROOTS} from './cultivation.mjs';
import {purseOf} from './units.mjs';

export const CAREER_VERSION='career-1.0.0';
const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
const mulberry=(seed)=>{let a=seed>>>0;return()=>{a=(a+0x6D2B79F5)>>>0;let t=Math.imul(a^(a>>>15),1|a);t=(t+Math.imul(t^(t>>>7),61|t))^t;return((t^(t>>>14))>>>0)/4294967296;};};

/** 五道。need 是晋升门槛，pay 是要掏的钱（银），grant 是这个位置换来的东西。 */
export const PATHS={
 military:{name:'军功',color:'#a2503c',unit:'战功',
  ranks:[
   {id:'soldier',name:'小兵',need:{merit:0},pay:0,grant:'能上阵，也会死',cap:0},
   {id:'squad',name:'什长',need:{merit:30},pay:0,grant:'带十个人',cap:10},
   {id:'captain',name:'校尉',need:{merit:150,fame:10},pay:300,grant:'领一营，可自募私兵',cap:120},
   {id:'general',name:'将帅',need:{merit:600,fame:35},pay:800,grant:'统率一军，可点将',cap:800},
   {id:'grand',name:'大将军',need:{merit:2000,fame:80},pay:5000,grant:'天下兵马在你手里',cap:3000}
  ]},
 office:{name:'官身',color:'#4b6f8f',unit:'名望',
  ranks:[
   {id:'clerk',name:'书吏',need:{fame:0},pay:0,grant:'抄文书，认得衙门的路',cap:0},
   {id:'assistant',name:'县丞',need:{fame:15},pay:800,grant:'协理县政，能支使差役',cap:20},
   {id:'magistrate',name:'县令',need:{fame:45},pay:6000,grant:'一县之主，税赋与刑名都在你手里',cap:80},
   {id:'prefect',name:'郡守',need:{fame:90},pay:40000,grant:'数县听调，能举荐属官',cap:200},
   {id:'chancellor',name:'丞相',need:{fame:160},pay:200000,grant:'一人之下：国策由你拟，圣旨由你副署',cap:400}
  ]},
 merchant:{name:'商贾',color:'#b08a45',unit:'本钱',
  ranks:[
   {id:'hawker',name:'摊贩',need:{capital:0},pay:0,grant:'一副担子，赚个辛苦钱',cap:2},
   {id:'trader',name:'行商',need:{capital:400},pay:200,grant:'能押商队走邻县',cap:6},
   {id:'shopkeeper',name:'铺主',need:{capital:2500},pay:1200,grant:'有铺面，能囤货',cap:12},
   {id:'saltlord',name:'盐商',need:{capital:12000},pay:8000,grant:'盐引在手，官面上有人',cap:24},
   {id:'tycoon',name:'首富',need:{capital:60000},pay:50000,grant:'银号、船队、盐场：县里一半的货走你的路',cap:48}
  ]},
 xian:{name:'仙途',color:'#6f63a8',unit:'道行',
  ranks:[
   {id:'named',name:'记名弟子',need:{qi:0},pay:0,grant:'山门记得你的名字，没人在意',cap:0},
   {id:'outer',name:'外门',need:{qi:1,fame:10},pay:2000,grant:'能进藏经阁最外一重',cap:0},
   {id:'inner',name:'内门',need:{qi:2,fame:40},pay:12000,grant:'有洞府、有月例灵石',cap:0},
   {id:'elder',name:'执事',need:{qi:3,fame:80},pay:60000,grant:'管一峰杂务，能调动外门弟子',cap:0},
   {id:'nascent',name:'真人',need:{qi:4,fame:150},pay:200000,grant:'开山立派：你的话就是道统',cap:0}
  ]},
 folk:{name:'乡望',color:'#5f8a5a',unit:'田产',
  ranks:[
   {id:'tenant',name:'雇农',need:{land:0},pay:0,grant:'佃别人的田，交租',cap:0},
   {id:'owner',name:'自耕农',need:{land:20},pay:300,grant:'有二十亩自己的地',cap:0},
   {id:'head',name:'里正',need:{land:60,fame:20},pay:900,grant:'一里之事由你说话',cap:8},
   {id:'gentry',name:'乡绅',need:{land:200,fame:60},pay:8000,grant:'修桥铺路、养庄客，县里要听你的',cap:40},
   {id:'clan',name:'大族',need:{land:600,fame:130},pay:60000,grant:'一族几百口，婚丧嫁娶都摆得开',cap:120}
  ]}
};

const PATH_IDS=['military','office','merchant','xian','folk'];
const rankIndexOf=(path,rankId)=>Math.max(0,PATHS[path].ranks.findIndex(r=>r.id===rankId));
const rankAt=(path,i)=>PATHS[path].ranks[clamp(i,0,4)];

export function ensureCareer(w){
 if(w.career)return w.career;
 w.career={path:null,ranks:{},fame:0,merit:0,capital:0,land:0,qi:0,
  men:0,menQuality:40,militia:0,retainers:0,shops:[],caravans:[],log:[],
  month:1,lastTick:w.day,wage:0,debt:0};
 for(const p of PATH_IDS)w.career.ranks[p]=-1;   // -1 = 未入道
 return w.career;
}
function pushLog(w,msg){const c=ensureCareer(w);c.log.unshift({day:w.day,month:c.month,msg});if(c.log.length>120)c.log.pop();}
function fame(w,delta){const c=ensureCareer(w);c.fame=clamp(c.fame+delta,-50,300);}
function merit(w,delta){const c=ensureCareer(w);c.merit=Math.max(0,c.merit+delta);}

/** 入道：先选一条路走到黑也可以，五条同时经营也可以——只是每一条都要钱和名声。 */
export function joinPath(w,path){
 const c=ensureCareer(w);
 if(!PATHS[path])return {ok:false,error:'无此出身'};
 if(c.ranks[path]>=0)return {ok:false,error:`你已是${PATHS[path].name}一道的${rankAt(path,c.ranks[path]).name}`};
 c.ranks[path]=0;c.path=c.path||path;
 if(path==='xian')c.qi=Math.max(c.qi,1);
 note(w,'出身',`你入了${PATHS[path].name}一道，从「${rankAt(path,0).name}」做起。`);
 pushLog(w,`入${PATHS[path].name}：${rankAt(path,0).name}`);
 return {ok:true,path,rank:rankAt(path,0)};
}

function meets(w,path,i){
 const c=ensureCareer(w),r=PATHS[path].ranks[i];
 const have={merit:c.merit,fame:c.fame,capital:c.capital,land:c.land,qi:c.qi};
 const miss=[];
 for(const [k,v] of Object.entries(r.need||{})){
  const cur=have[k]??0;
  if(cur<v)miss.push(`${({merit:'战功',fame:'名望',capital:'本钱',land:'田产',qi:'道行'})[k]} ${Math.floor(cur)}/${v}`);
 }
 return {ok:miss.length===0,miss,rank:r};
}

/** 能不能升：门槛够不够、钱够不够，一句话说清。 */
export function canAdvance(w,path){
 const c=ensureCareer(w);
 if(c.ranks[path]<0)return {ok:false,error:`你还没入${PATHS[path].name}一道`,next:0};
 const i=c.ranks[path]+1;
 if(i>4)return {ok:false,error:`已是${PATHS[path].name}之顶`,next:4,top:true};
 const r=PATHS[path].ranks[i],m=meets(w,path,i);
 const silver=w.player.silver||0;
 const payOK=silver>=r.pay;
 return {ok:m.ok&&payOK,next:i,target:r,
  missing:[...m.miss,...(payOK?[]:[`银钱 ${Math.round(silver)}/${r.pay}`])],
  pay:r.pay,grant:r.grant};
}

export function advance(w,path){
 const c=ensureCareer(w);
 const chk=canAdvance(w,path);
 if(!chk.ok)return {ok:false,error:chk.missing?.length?`还差：${chk.missing.join('、')}`:chk.error};
 const r=chk.target;
 if(r.pay>0){w.player.silver-=r.pay;c.capital+=0;}
 c.ranks[path]=chk.next;c.path=c.path||path;
 fame(w,2);
 // 买来的位置要还人情：官身与军功到高位会欠下“人情债”
 if(r.pay>=3000&&(path==='office'||path==='military')){c.debt=(c.debt||0)+Math.round(r.pay*0.12);}
 note(w,'晋升',`${PATHS[path].name}：${r.name}。${r.grant}。`);
 pushLog(w,`升${r.name}（${r.grant}）`);
 return {ok:true,path,rank:r.name,index:chk.next,paid:r.pay};
}

/** 募兵：钱买的是“人+装备+军饷”，不是数字。上限由身份决定。 */
export const MEN_COST={enlist:14,gear:9,upkeep:2.2};
export function recruitCapacity(w){
 const c=ensureCareer(w);let cap=0;
 for(const p of PATH_IDS){if(c.ranks[p]<0)continue;cap=Math.max(cap,rankAt(p,c.ranks[p]).cap||0);}
 if(c.ranks.office>=3)cap+=Math.round(cap*0.3);
 return cap;
}
export function recruitMen(w,n=1){
 const c=ensureCareer(w);n=Math.floor(n);
 if(n<=0)return {ok:false,error:'数额无效'};
 const cap=recruitCapacity(w);
 if(c.men+n>cap)return {ok:false,error:`身份只养得起 ${cap} 名私兵（现有 ${c.men}）——再往上得先升身份`};
 const cost=Math.round(n*(MEN_COST.enlist+MEN_COST.gear));
 if((w.player.silver||0)<cost)return {ok:false,error:`募兵需 ${cost} 银，你有 ${Math.round(w.player.silver||0)}`};
 w.player.silver-=cost;c.men+=n;c.capital+=Math.round(cost*.3);
 note(w,'募兵',`募得 ${n} 名部曲，花费 ${cost} 银（募钱 ${MEN_COST.enlist} + 装备 ${MEN_COST.gear}）。`);
 return {ok:true,men:c.men,cost,cap};
}
export function dismissMen(w,n=1){
 const c=ensureCareer(w);n=Math.min(n,c.men);c.men-=n;fame(w,-1);
 return {ok:true,men:c.men};
}
/** 雇佣修士：走灵石，不走金银（见 cultivation.hireRetainer）。 */
export function hireCultivator(w,{realm='found',sect='散修'}={}){
 const x=ensureCultivation(w);
 const tier=clamp(({qi:1,found:2,core:3,nascent:4})[realm]||2,1,4)-1;
 const cost=RETAINER_COST[(['qi','found','core','nascent'])[tier]];
 const cur=ensureCurrency(w);
 if(cur.stones<cost.stones)return {ok:false,error:`灵石不足：需 ${cost.stones} 块（现有 ${cur.stones}）`};
 cur.stones-=cost.stones;
 const ret={id:'P'+(x.retainers.length+1),name:`${sect}·${['炼气','筑基','金丹','元婴'][tier]}修士`,
  realm:['qi','found','core','nascent'][tier],power:[4,28,180,1200][tier],loyalty:60,
  upkeep:cost.stones,paidOn:w.day,personal:true};
 (w.career.personal=x.retainers=x.retainers||[]).push(ret);
 note(w,'招揽',`以 ${cost.stones} 块灵石请动一位${ret.name}做你的私人客卿。`);
 return {ok:true,retainer:ret};
}

/** 经商：开铺。铺面每月给钱，也会遇上盗匪、水旱、官面上的“打点”。 */
export const SHOP_KINDS={
 grain:{name:'粮铺',cost:1500,base:180,risk:.12,note:'薄利、稳，遇上灾年能翻倍'},
 cloth:{name:'布庄',cost:2200,base:260,risk:.16,note:'看天时，换季最好卖'},
 herb:{name:'药铺',cost:3000,base:340,risk:.22,note:'药材贵，赔起来也快'},
 wine:{name:'酒肆',cost:2600,base:300,risk:.10,note:'人来人往，消息最灵'}
};
export function openShop(w,kind='grain',placeId='dongshi'){
 const c=ensureCareer(w),k=SHOP_KINDS[kind];
 if(!k)return {ok:false,error:'无此营生'};
 const rank=c.ranks.merchant;
 if(c.shops.filter(s=>!s.closed).length>=(rankAt('merchant',rank).cap||0))
  return {ok:false,error:`你的商贾身份只撑得起 ${rankAt('merchant',rank).cap} 处铺面`};
 if((w.player.silver||0)<k.cost)return {ok:false,error:`开${k.name}需 ${k.cost} 银`};
 w.player.silver-=k.cost;
 const shop={id:'S'+(c.shops.length+1),kind,name:k.name,place:placeId,base:k.base,risk:k.risk,openedOn:w.day,closed:false};
 c.shops.push(shop);c.capital+=k.cost;
 note(w,'经商',`在${placeId==='dongshi'?'东市':'临安'}盘下${k.name}，本钱 ${k.cost} 银。${k.note}`);
 return {ok:true,shop};
}
/** 押商队：赚差价，也可能折在路上。 */
export function sendCaravan(w,{goods='cloth',qty=10,days=12}={}){
 const c=ensureCareer(w);
 if(c.ranks.merchant<0)return {ok:false,error:'还没入商贾一道'};
 const unit=goods==='cloth'?26:goods==='herb'?18:goods==='wine'?21:9;
 const cost=qty*unit;
 if((w.player.silver||0)<cost)return {ok:false,error:`这批货要 ${cost} 银`};
 w.player.silver-=cost;
 const cv={id:'C'+(c.caravans.length+1),goods,qty,cost,sentOn:w.day,days,settled:false};
 c.caravans.push(cv);
 note(w,'行商',`押 ${qty} 担${goods==='cloth'?'布':goods}出县，本钱 ${cost} 银，约 ${days} 日往返。`);
 return {ok:true,caravan:cv};
}
function settleCaravans(w){
 const c=ensureCareer(w);
 for(const cv of c.caravans){
  if(cv.settled||w.day-cv.sentOn<cv.days)continue;
  cv.settled=true;
  const rng=mulberry((w.seed||1)+cv.sentOn*31+cv.qty);
  const peril=rng();
  let profit;
  if(peril<.10){profit=-cv.cost;cv.fate='遭劫';}
  else if(peril<.22){profit=Math.round(cv.cost*.12);cv.fate='遇雨折半';}
  else {profit=Math.round(cv.cost*(0.28+rng()*0.42));cv.fate=peril>.9?'碰上好行市':'顺利';}
  w.player.silver+=Math.max(0,cv.cost+profit);
  if(profit>0){c.capital+=Math.round(profit*.5);fame(w,1);}
  else fame(w,-1);
  note(w,'行商',`商队${cv.fate}：本 ${cv.cost} 银，${profit>=0?'净赚':'净亏'} ${Math.abs(profit)} 银。`);
 }
}

/** 买田：乡望一道的根本，也是收租的来源。 */
export const LAND_COST=18; // 每亩
export function buyLand(w,mu=10){
 const c=ensureCareer(w);mu=Math.floor(mu);
 const cost=mu*LAND_COST;
 if((w.player.silver||0)<cost)return {ok:false,error:`买 ${mu} 亩需 ${cost} 银`};
 w.player.silver-=cost;c.land+=mu;
 note(w,'置产',`买田 ${mu} 亩，花 ${cost} 银。`);
 return {ok:true,land:c.land,cost};
}
/** 逐月结算：军饷、铺面、田租、人情债。按月不按日是怕它变成流水账。 */
export function tickCareer(w){
 const c=ensureCareer(w);
 settleCaravans(w);                       // 商队到日子就结，不必等月底
 if(w.day-c.lastTick<30)return {skipped:true};
 c.lastTick=w.day;c.month++;
 const rng=mulberry((w.seed||1)+c.month*977);
 const pay={wage:0,shops:0,land:0,debt:0};
 // 私兵军饷：养兵是纯消耗，且会拖累名望（兵过境如梳）
 pay.wage=Math.round(c.men*MEN_COST.upkeep);
 if(c.men>0)fame(w,-1);
 // 铺面
 for(const s of c.shops){
  if(s.closed)continue;
  const bad=rng()<s.risk, good=rng()<.25;
  let inc=Math.round(s.base*(0.7+rng()*0.6));
  if(bad)inc=-Math.round(s.base*0.6);
  if(good)inc=Math.round(inc*1.6);
  pay.shops+=inc;
  if(bad)note(w,'经营',`${s.name}本月不顺（${['盗匪','雨水','官面上的打点'][Math.floor(rng()*3)]}），亏 ${Math.abs(inc)} 银。`);
 }
 // 田租：每亩每月约 1.2 银，灾年减半
 if(c.land>0){
  const harvest=rng()<.15?0.5:1;
  pay.land=Math.round(c.land*1.2*harvest);
 }
 // 人情债：买来的官要还，逐月抽一成名声与银钱
 if((c.debt||0)>0){
  pay.debt=Math.round(c.debt*0.1);c.debt-=pay.debt;
 }
 const net=pay.shops+pay.land-pay.wage-pay.debt;
 w.player.silver=Math.max(0,Math.round((w.player.silver||0)+net));
 // 本钱随经营增长：这是商贾一道的“实力”，不是虚数
 if(net>0)c.capital+=Math.round(net*0.6);
 if(c.men>0&&w.player.silver<0)w.player.silver=0;
 return {month:c.month,...pay};
}

/** 战功：打完一仗按杀敌与危险记。 */
export function recordBattle(w,{kills=0,side='left',won=true}={}){
 const c=ensureCareer(w);
 const gain=Math.round(kills*0.8+(won?12:2));
 merit(w,gain);fame(w,won?3:-1);

 note(w,'战功',`此役斩 ${kills}，记战功 ${gain}${won?'，军中传名':'，败军之将不言勇'}。`);
 return {merit:c.merit,gain};
}

export function careerReport(w){
 const c=ensureCareer(w);
 const paths=PATH_IDS.map(p=>{
  const i=c.ranks[p],r=rankAt(p,i),next=i<4?rankAt(p,i+1):null;
  const chk=i<4?canAdvance(w,p):{ok:false,missing:[]};
  return {id:p,name:PATHS[p].name,color:PATHS[p].color,index:i,rank:r.name,
   cap:r.cap,grant:r.grant,next:next&&next.name,nextNeed:next?next.need:null,nextPay:next?next.pay:0,
   ready:!!chk.ok,missing:chk.missing||[]};
 });
 const best=paths.slice().sort((a,b)=>b.index-a.index)[0];
 return {fame:Math.round(c.fame),merit:Math.round(c.merit),land:c.land,capital:Math.round(c.capital),
  men:c.men,cap:recruitCapacity(w),silver:Math.round(w.player.silver||0),
  shops:c.shops.filter(s=>!s.closed).length,debt:Math.round(c.debt||0),month:c.month,
  paths,top:best&&best.index>=4,log:c.log.slice(0,8)};
}
