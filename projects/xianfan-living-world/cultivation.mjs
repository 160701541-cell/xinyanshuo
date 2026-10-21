// 《仙凡共生》修仙层：灵根是天生的，资源是世袭的，修士是稀缺的。
// 县城灵气薄，一年也出不了几个修士；真正的修士聚在灵脉与山门。凡人不修仙，但整个仙门靠凡人伺候。
import {note} from './core.mjs';
import {ensureFin,purseOf} from './units.mjs';

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
  const sects=[{id:'qingyun',name:'青云仙门',qi:1.0,disciples:64,realm:'core',patron:false},
               {id:'lingshan',name:'灵山散修',qi:1.35,disciples:23,realm:'found',patron:false}];
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
/** 皇族无灵根也能灭宗门：靠的是养的供奉，不是自己的灵根。 */
export function hireRetainer(w,{sect='散修',realm='found',patron='court'}={}){
 const x=ensureCultivation(w);
 const tier=REALMS.find(r=>r.id===realm)||REALMS[1];
 const price=Math.round(tier.power*300);
 ensureFin(w);const p=w.states[patron]||w.states.court;
 if(p.treasury<price)return {ok:false,error:`${patron==='court'?'大宁府库':'该势力'}不足：供奉 ${tier.name} 需 ${price.toLocaleString()} 文`};
 p.treasury-=price;
 const ret={id:'R'+(x.retainers.length+1),name:`${sect}·${tier.name}修士`,realm:tier.id,realmName:tier.name,power:tier.power,patron,loyalty:60,upkeep:Math.round(price*.12)};
 x.retainers.push(ret);
 note(w,'招揽',`以 ${price.toLocaleString()} 文供养一位${tier.name}修士（${sect}）；他不种田、不当兵，只听灵石的话。`);
 return {ok:true,retainer:ret,price};
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
 const theirs=sectPower(sect);
 if(mine<theirs*1.2)return {ok:false,error:`供奉战力 ${mine} 不足以撼动${sect.name}（${theirs}），需 ${Math.ceil(theirs*1.2)}`};
 sect.destroyed=true;sect.disciples=Math.round(sect.disciples*.2);
 note(w,'灭门',`${sect.name}山门被破：${mine} 对 ${theirs}，道众十不存二。灭门的是供奉，不是灵根。`);
 return {ok:true,power:mine,theirs};
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
  mortals:mortalWork(w),log:(x.log||[]).slice(-5).reverse()};
}
