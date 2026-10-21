// 《仙凡共生》兵种与装备：战力不是标签，是 兵种×武器×甲胄×训练×战历×阵型×对位 的乘积。
// 纯逻辑，不碰 DOM。所有钱从国库出（w.treasury），所以经济决定你能养出什么兵。
import {FACTIONS,factionById,POPULATION} from './society.js';
import {note} from './core.js';

export const UNITS_VERSION='units-1.0.0';

export const ARMS={
 inf:{name:'步卒',base:1.00,horse:0,iron:.4,leather:.3,silver:3},
 arc:{name:'弓弩',base:1.15,horse:0,iron:.5,leather:.2,silver:4,ranged:true},
 cav:{name:'轻骑',base:1.35,horse:1,iron:.6,leather:.4,silver:8},
 heavy:{name:'重甲',base:1.30,horse:0,iron:1.6,leather:.2,silver:9},
 eng:{name:'工兵',base:0.70,horse:0,iron:.5,leather:.1,silver:4,siege:true},
 sword:{name:'剑修',base:2.20,horse:0,iron:.2,leather:.1,silver:12,qi:true}
};
export const WEAPONS=[
 {id:0,name:'木杆枪',m:1.00,cost:0,need:null},
 {id:1,name:'铁枪',m:1.12,cost:15,need:null},
 {id:2,name:'精钢枪/马槊',m:1.22,cost:40,need:'metallurgy'}
];
export const ARMORS=[
 {id:0,name:'无甲',m:1.00,cost:0,need:null},
 {id:1,name:'皮甲',m:1.08,cost:15,need:null},
 {id:2,name:'札甲',m:1.18,cost:40,need:'metallurgy'},
 {id:3,name:'铁浮屠',m:1.30,cost:90,need:'metallurgy'}
];
export const TECHS={
 metallurgy:{name:'冶金',cost:2400000,desc:'解锁札甲/铁浮屠/精钢兵器',effect:'armor2'},
 horse:{name:'马政',cost:3600000,desc:'骑兵占比上限 0.15→0.35',effect:'cav'},
 drill:{name:'操典',cost:1500000,desc:'全军训练 +15',effect:'train'},
 siege:{name:'器械',cost:2100000,desc:'攻城与工兵效能 +50%',effect:'siege'}
};
// 阵型：对位与兵种构成一起决定，单看阵型没有意义
export const FORMATIONS={
 line:{name:'横阵',atk:1.00,def:1.00,note:'中规中矩'},
 wedge:{name:'锋矢',atk:1.14,def:0.90,note:'突破强，两翼薄'},
 square:{name:'方圆',atk:0.92,def:1.18,note:'抗骑冲，推进慢'},
 crane:{name:'雁行',atk:1.05,def:0.95,note:'两翼包抄，中军弱'},
 loose:{name:'散阵',atk:0.95,def:1.08,note:'减箭伤，怕骑冲'}
};
// 对位：克制是乘数，不是一句“步兵克骑兵”
export const MATCHUP={
 inf:{cav:1.25,arc:0.85,heavy:0.85,sword:0.75},
 arc:{inf:1.10,cav:0.70,heavy:0.80,sword:0.80},
 cav:{arc:1.30,inf:0.80,heavy:0.85,sword:0.60},
 heavy:{inf:1.05,cav:1.10,arc:1.05,sword:0.85},
 eng:{inf:0.70,cav:0.60,arc:0.70,heavy:0.50,sword:0.50},
 sword:{inf:1.30,cav:1.20,arc:1.20,heavy:1.10,eng:1.50}
};
const TRAITS={
 court:{inf:.62,arc:.18,cav:.12,heavy:.08},
 merchant:{inf:.45,arc:.25,cav:.25,heavy:.05},
 folk:{inf:.75,arc:.15,cav:.05,heavy:.05},
 sect:{sword:.35,inf:.30,arc:.20,cav:.05,heavy:.10},
 guard:{inf:.25,arc:.10,cav:.30,heavy:.35}
};
export function compositionFor(faction){
 const t=TRAITS[faction]||TRAITS.folk;
 return {...t};
}
export function unitMen(army){
 const out={};
 for(const [arm,share] of Object.entries(army.units||{}))out[arm]=Math.round(army.combat*share);
 return out;
}
export function unitsReport(army){
 const men=unitMen(army);
 return Object.entries(men).filter(([,n])=>n>0).map(([arm,n])=>({arm,name:ARMS[arm]?.name||arm,men:n,share:+(n/Math.max(army.combat,1)*100).toFixed(0)}));
}
function gearOf(army){const g=army.gear||{armor:army.kit?.armor??0,weapon:army.kit?.weapon??0,share:0};return g;}
function weaponOf(army){const g=gearOf(army);return WEAPONS[Math.min(WEAPONS.length-1,g.weapon??0)];}
function armorOf(army){const g=gearOf(army);return ARMORS[Math.min(ARMORS.length-1,g.armor??0)];}
export function qOf(army,opponent=null){
 const g=gearOf(army),share=Math.min(1,Math.max(0,g.share??0));
 const wm=1+share*(weaponOf(army).m-1),am=1+share*(armorOf(army).m-1);
 const train=1+(army.train??30)/200;
 const xp=1+(army.experience??0)/300;
 const f=FORMATIONS[army.formation||'line']||FORMATIONS.line;
 const men=unitMen(army);
 const total=Math.max(army.combat,1);
 const oppArm=opponent?dominantArm(opponent):null;
 let sum=0;
 for(const [arm,n] of Object.entries(men)){
  const base=ARMS[arm]?.base??1;
  const ver=oppArm?(MATCHUP[arm]?.[oppArm]??1):1;
  sum+=base*ver*(n/total);
 }
 return sum*wm*am*train*xp*f.atk;
}
// 归一化：一支“新征步卒、木枪、无甲、训练 30、战历 0、横阵”的军 = 1.00
export const Q0=(()=>{
 let s=0;
 for(const [arm,share] of Object.entries(TRAITS.folk))s+=(ARMS[arm]?.base??1)*share;
 return s*WEAPONS[0].m*ARMORS[0].m*(1+30/200)*1*1;
})();
export function quality(army,opponent=null){return qOf(army,opponent)/Q0;}
export function dominantArm(army){
 const men=unitMen(army);let best=null,n=-1;
 for(const [arm,c] of Object.entries(men))if(c>n){n=c;best=arm;}
 return best;
}
// ---- 经济侧：装备、操练、科技都要花钱，国库不够就是不够 ----
export function ensureFin(w){
 w.states=w.states||{};
 for(const f of FACTIONS){
  if(!w.states[f.id])w.states[f.id]={treasury:Math.round((POPULATION[f.id]?.people||1000000)*.6)};
 }
 return w.states;
}
export function purseOf(w,faction){ensureFin(w);return w.states[faction]?.treasury??0;}
function purse(w,army){ensureFin(w);const f=army.faction||'folk';return w.states[f];}
export function equipCost(army,{armor=null,weapon=null,share=null}={}){
 const g=gearOf(army);
 const nextA=armor==null?(g.armor??0):armor;
 const nextW=weapon==null?(g.weapon??0):weapon;
 const target=share==null?Math.min(1,(g.share??0)+.25):share;
 const grow=Math.max(0,target-(g.share??0));
 const da=ARMORS[nextA].cost,dw=WEAPONS[nextW].cost;
 return Math.round(army.combat*grow*(da+dw));
}
/** 换装按“比例”付钱：先武装前军，后军仍是布衣——这就是经济对军队的限制。 */
export function equip(w,army,{armor=null,weapon=null,share=null}={}){
 const g=gearOf(army);
 const nextA=armor==null?(g.armor??0):armor;
 const nextW=weapon==null?(g.weapon??0):weapon;
 if(ARMORS[nextA].need&&!w.tech?.[ARMORS[nextA].need])return {ok:false,error:`未习「${TECHS[ARMORS[nextA].need].name}」，造不出${ARMORS[nextA].name}`};
 if(WEAPONS[nextW].need&&!w.tech?.[WEAPONS[nextW].need])return {ok:false,error:`未习「${TECHS[WEAPONS[nextW].need].name}」，打不出${WEAPONS[nextW].name}`};
 const target=share==null?Math.min(1,(g.share??0)+.25):Math.min(1,share);
 const cost=equipCost(army,{armor:nextA,weapon:nextW,share:target});
 const p=purse(w,army);
 if(p.treasury<cost)return {ok:false,error:`${factionById(army.faction)?.name||''}府库不足：需 ${cost.toLocaleString()} 文，库存 ${p.treasury.toLocaleString()} 文`};
 p.treasury-=cost;army.gear={armor:nextA,weapon:nextW,share:target};
 note(w,'军备',`${army.corps}换装：${ARMORS[nextA].name}+${WEAPONS[nextW].name}，覆盖 ${Math.round(target*100)}% 兵员，耗银 ${cost.toLocaleString()} 文。`);
 return {ok:true,cost,share:target};
}
export function drillCost(army,to=60){return Math.max(0,Math.round((to-(army.train??30))*(army.combat*.6)));}
export function drill(w,army,to=60){
 const cost=drillCost(army,to);
 if(cost<=0)return {ok:false,error:'训练已达标'};
 const p=purse(w,army);
 if(p.treasury<cost)return {ok:false,error:`府库不足：操练需 ${cost.toLocaleString()} 文，库存 ${p.treasury.toLocaleString()} 文`};
 p.treasury-=cost;army.train=to;
 note(w,'操练',`${army.corps}操练至 ${to}，耗银 ${cost.toLocaleString()} 文。`);
 return {ok:true,cost};
}
export function research(w,techId,arg_faction='court'){
 const t=TECHS[techId];if(!t)return {ok:false,error:'无此技艺'};
 if(w.tech?.[techId])return {ok:false,error:'已习得'};
 ensureFin(w);const p=w.states[arg_faction||'court'];
 if(p.treasury<t.cost)return {ok:false,error:`府库不足：需 ${t.cost.toLocaleString()} 文，库存 ${p.treasury.toLocaleString()} 文`};
 p.treasury-=t.cost;w.tech={...(w.tech||{}),[techId]:true};
 if(techId==='drill')for(const a of w.war?.armies||[])a.train=Math.min(100,(a.train??30)+15);
 note(w,'技艺',`习得「${t.name}」：${t.desc}。`);
 return {ok:true};
}
export function setFormation(w,army,id){
 if(!FORMATIONS[id])return {ok:false,error:'无此阵型'};
 army.formation=id;
 note(w,'军阵',`${army.corps}列${FORMATIONS[id].name}——${FORMATIONS[id].note}。`);
 return {ok:true};
}
export function armyDigest(army,opponent=null){
 return {corps:army.corps,arms:unitsReport(army),armor:armorOf(army).name,weapon:weaponOf(army).name,
  train:army.train??30,experience:army.experience??0,veteran:army.veteran??0,
  formation:FORMATIONS[army.formation||'line'].name,
  quality:+quality(army,opponent).toFixed(2)};
}
