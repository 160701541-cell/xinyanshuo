// 《仙凡共生》修仙层：灵根是天生的，资源是世袭的，修士是稀缺的。
// 县城灵气薄，一年也出不了几个修士；真正的修士聚在灵脉与山门。凡人不修仙，但整个仙门靠凡人伺候。
import {note} from './core.mjs';
import {ensureFin,purseOf} from './units.mjs';
import {ensureCurrency} from './currency.mjs';

export const CULTIVATION_VERSION='xian-1.0.0';
const mulberry=(seed)=>{let a=seed>>>0;return()=>{a=(a+0x6D2B79F5)>>>0;let t=Math.imul(a^(a>>>15),1|a);t=(t+Math.imul(t^(t>>>7),61|t))^t;return((t^(t>>>14))>>>0)/4294967296;};};

// 灵根：决定“能不能修、上限多高”，与努力关系不大
export const ROOTS={
 tian:{name:'天灵根',p:.0006,speed:5.0,note:'百年一见，宗门抢人'},
 dan:{name:'单灵根',p:.006,speed:3.0},
 shuang:{name:'双灵根',p:.03,speed:2.0},
 san:{name:'三灵根',p:.09,speed:1.4},
 si:{name:'四灵根',p:.18,speed:1.0},
 wu:{name:'五灵根',p:.32,speed:.7,note:'能修，但一辈子炼气'},
 none:{name:'无灵根',p:.3734,speed:0,note:'绝大多数人。皇族也不例外'}
};
export const REALMS=[
 {id:'qi',name:'炼气',power:4,tier:1},{id:'found',name:'筑基',power:28,tier:2},
 {id:'core',name:'金丹',power:180,tier:3},{id:'nascent',name:'元婴',power:1200,tier:4}
];
// 灵气浓度：世俗县城薄，灵脉与山门厚
export const QI_REGIONS={
 xiancheng:{name:'临安县城',qi:.18,note:'官府、市井与凡人，灵气稀薄'},
 songlin:{name:'松林村',qi:.26,note:'山脚薄灵'},
 qingyun:{name:'青云山门',qi:1.0,note:'灵脉所在，宗门根基'},
 lingshan:{name:'灵山',qi:1.35,note:'上品灵脉，散修与妖兽出没'}
};
// 凡人依附仙门的营生（不是“背景板”，是真实人口与工钱）
export const MORTAL_JOBS={
 guard:{name:'护院',wage:90,qi:.4,note:'给修仙家族看门'},
 cleaner:{name:'洒扫',wage:35,qi:.2},
 planter:{name:'灵植夫',wage:60,qi:.6,note:'伺候灵田，一株灵稻顶十亩凡田'},
 keeper:{name:'兽倌',wage:55,qi:.5,note:'喂灵兽，运气差会被吃'},
 slave:{name:'役奴',wage:0,qi:.1,note:'卖身的，不算工钱'}
};

export function ensureCultivation(w){
 if(!w.xian){
  const rng=mulberry(20261021);
  // 宗门的底气不只是人：护山大阵、符箓、丹药、灵兽都在算账
  const sects=[{id:'qingyun',name:'青云仙门',qi:1.0,disciples:64,realm:'core',patron:false,
                formation:.55,talismans:9,pills:24,beasts:5},
               {id:'lingshan',name:'灵山散修',qi:1.35,disciples:23,realm:'found',patron:false,
                formation:.18,talismans:2,pills:6,beasts:2}];
  w.xian={sects,retainers:[],patrons:{},mortals:{},day:0,log:[]};
  // 凡人依附人口：按县里宗门附近的聚落估
  w.xian.mortals={guard:24,cleaner:80,planter:140,keeper:36,slave:12};
 }
 return w.xian;
}
/** 抽一个凡人的灵根：绝大多数无灵根，天灵根几乎见不到。 */
export function rollRoot(seed){
 const r=mulberry(seed);
 let x=r();
 for(const [id,root] of Object.entries(ROOTS)){if(x<root.p)return {id,name:root.name,speed:root.speed,note:root.note||''};x-=root.p;}
 return {id:'none',name:'无灵根',speed:0,note:ROOTS.none.note};
}
/** 一个地方的修士密度：灵气越浓，出修士的概率越高；县城一年也未必有一个。 */
export function cultivatorDensity(regionId){
 const qi=QI_REGIONS[regionId]?.qi??.2;
 return {region:regionId,name:QI_REGIONS[regionId]?.name||regionId,qi,per10k:+(qi*qi*3).toFixed(3)};
}
export function sectPower(sect){
 const base=REALMS.find(r=>r.id===(sect.realm||'qi'))?.power??4;
 return Math.round(base*sect.disciples*.6);
}
/** 供奉的市价不是金银，是修炼资源：灵石、丹药、灵脉与功法。 */
export const RETAINER_COST={
 qi:{stones:0.2,pills:2,note:'炼气散修：给几块下品灵石就肯跑腿'},
 found:{stones:1,pills:6,note:'筑基：要灵石，也要丹药'},
 core:{stones:6,pills:24,note:'金丹：灵石是月供，不是一次性'},
 nascent:{stones:24,pills:80,note:'元婴：他看中的是皇朝的灵脉与丹药供给，不是你的钱'}
};
/** 招供奉：**不用铜钱**。谁提钱，元婴扭头就走——那太俗了。 */
export function hireRetainer(w,{sect='散修',realm='found',patron='court'}={}){
 const x=ensureCultivation(w);
 const tier=REALMS.find(r=>r.id===realm)||REALMS[1];
 const cost=RETAINER_COST[tier.id];
 const c=ensureCurrency(w);
 if(c.stones<cost.stones)return {ok:false,error:`灵石不足：${tier.name}供奉需 ${cost.stones} 块灵石（现有 ${c.stones}）。黄金他不要。`};
 c.stones-=cost.stones;
 const ret={id:'R'+(x.retainers.length+1),name:`${sect}·${tier.name}修士`,realm:tier.id,realmName:tier.name,
  power:tier.power,patron,loyalty:55,upkeep:cost.stones,pillUpkeep:cost.pills,paidOn:w.day};
 x.retainers.push(ret);
 note(w,'招揽',`以大宁灵脉与 ${cost.stones} 块灵石延请一位${tier.name}修士（${sect}）。他不动金银——他要的是修炼资源。`);
 return {ok:true,retainer:ret,price:cost.stones,currency:'灵石'};
}
/** 每月供养：灵石断了，供奉就走。忠诚不靠钱，靠“你养得起他”。 */
export function tickRetainers(w){
 const x=ensureCultivation(w),c=ensureCurrency(w);
 let left=0;
 for(const r of [...x.retainers]){
  if(w.day-r.paidOn<30)continue;
  if(c.stones>=r.upkeep){c.stones-=r.upkeep;r.paidOn=w.day;r.loyalty=Math.min(100,r.loyalty+4);}
  else {r.loyalty-=60;if(r.loyalty<=0){x.retainers.splice(x.retainers.indexOf(r),1);left++;
        note(w,'供奉出走',`灵石断供，${r.name} 收拾行囊走了。没有灵石，忠诚一文不值。`);}}
 }
 return {left,stones:c.stones};
}
export function sectDefense(sect){
 const base=sectPower(sect);
 return Math.round(base*(1+(sect.formation||0))+(sect.talismans||0)*20+(sect.beasts||0)*35);
}
/** 皇朝不是赤手空拳：禁宫大阵 + 护国供奉 + 亲军法师，都算在皇帝身上。 */
export function courtProtection(w){
 ensureCultivation(w);
 const guard=retainerPower(w,'court');
 const formation=420;      // 禁宫护国大阵：一名元婴强闯也要脱层皮
 return Math.round(guard+formation);
}
export function retainerPower(w,patron=null){
 const x=ensureCultivation(w);
 return x.retainers.filter(r=>!patron||r.patron===patron).reduce((n,r)=>n+r.power,0);
}
/** 灭门：不看你的灵根，看你请得起多少人、以及宗门的根基。 */
export function raidSect(w,sectId,{patron='court'}={}){
 const x=ensureCultivation(w);
 const sect=x.sects.find(s=>s.id===sectId);
 if(!sect)return {ok:false,error:'没有这个宗门'};
 if(!sect.patron){/* 可打 */}
 const mine=retainerPower(w,patron);
 const theirs=sectDefense(sect);
 if(mine<theirs*1.2)return {ok:false,error:`供奉战力 ${mine} 不足以撼动${sect.name}（${theirs}），需 ${Math.ceil(theirs*1.2)}`};
 sect.destroyed=true;sect.disciples=Math.round(sect.disciples*.2);
 sect.formation=0;sect.talismans=0;sect.beasts=0;
 note(w,'灭门',`${sect.name}山门被破：${mine} 对 ${theirs}（含护山大阵、符箓与灵兽），道众十不存二。灭门的是供奉，不是灵根。`);
 return {ok:true,power:mine,theirs};
}
/** 元婴能不能杀皇帝？能。但要看皇帝背后站着谁。 */
export function assassinThreat(w){
 const x=ensureCultivation(w);
 const hostile=x.sects.filter(s=>!s.destroyed&&s.patron!=='court');
 if(!hostile.length)return {threat:0,sect:null};
 const top=hostile.map(s=>({sect:s,power:sectDefense(s)})).sort((a,b)=>b.power-a.power)[0];
 return {threat:top.power,sect:top.sect};
}
/** 每月结算一次刺杀风险：单独一名元婴闯宫，对大阵+护国供奉。 */
export function resolveAssassination(w){
 const {threat,sect}=assassinThreat(w);
 const protect=courtProtection(w);
 if(!sect||threat<=0)return {died:false,reason:'无宗门敌意',threat,protect};
 if(threat>protect*1.5){
  const old=w.player.name;
  w.player.name=`${old}·太子`;
  w.states.court.corruption=Math.min(100,(w.states.court.corruption||0)+12);
  w.states.court.legitimacy=Math.max(0,(w.states.court.legitimacy??60)-15);
  ensureFin(w);w.states.court.treasury=Math.round(w.states.court.treasury*.4);
  note(w,'刺杀',`${sect.name}的元婴修士夜入禁宫，护国力量 ${protect} 挡不住 ${threat}；${old} 死于宫中，太子继位，府库被掠六成。`);
  return {died:true,threat,protect,sect:sect.name,heir:w.player.name};
 }
 if(threat>protect){
  note(w,'刺杀未遂',`${sect.name}刺客被禁宫大阵所阻（${threat} 对 ${protect}），皇帝重伤，朝野震动。`);
  w.states.court.legitimacy=Math.max(0,(w.states.court.legitimacy??60)-5);
  return {died:false,wounded:true,threat,protect,sect:sect.name};
 }
 note(w,'护卫',`${sect.name}遣人窥伺禁宫，见护国供奉 ${protect} 而退。`);
 return {died:false,threat,protect,sect:sect.name};
}
export function mortalWork(w){
 const x=ensureCultivation(w);
 return Object.entries(x.mortals).map(([id,n])=>({id,name:MORTAL_JOBS[id].name,count:n,wage:MORTAL_JOBS[id].wage,note:MORTAL_JOBS[id].note||''}));
}
export function xianReport(w){
 const x=ensureCultivation(w);
 return {regions:Object.entries(QI_REGIONS).map(([id,r])=>({id,...r,density:cultivatorDensity(id).per10k})),
  sects:x.sects.map(s=>({...s,power:sectPower(s)})),
  retainers:[...x.retainers],retainerPower:retainerPower(w),
  protection:courtProtection(w),
  mortals:mortalWork(w),log:(x.log||[]).slice(-5).reverse()};
}
