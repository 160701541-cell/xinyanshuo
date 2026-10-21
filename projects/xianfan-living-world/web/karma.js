// 业力：修仙之人不怕杀人，怕沾业。同是杀人，杀修士与杀凡人不是一回事。
// - 修士有掉落：灵石、丹药、法器，杀了是赚；
// - 凡人没有掉落，且杀之沾业最重，突破时业力会来索；
// - 有正当理由（亲眷/友人被杀、护人、自卫、该杀之人）则业力极轻，甚至除害反减。
import {shiftDao,recordDeed} from './dao.js';
export const KARMA_VERSION='karma-0.1.0';

export const JUSTIFY={
 selfDefense:{label:'自卫',weight:0},
 revengeKin:{label:'为亲眷报仇',weight:0},
 revengeFriend:{label:'为友人报仇',weight:0},
 protectOther:{label:'护住他人',weight:1},
 insult:{label:'受人欺辱',weight:1},
 duty:{label:'奉令执法',weight:0},
 bounty:{label:'此人该杀',weight:0}
};
export const EVIDENCE={
 anyMurder:{label:'杀人夺物',weight:14},
 mortalKill:{label:'伤及凡人',weight:9},
 witness:{label:'众目睽睽',weight:3},
 evildoer:{label:'除一恶人',weight:-3},
 kinOfCultivator:{label:'杀的是宗门弟子',weight:4}
};
export const KARMA_TIERS=[
 {min:120,id:'wrath',label:'天怒',color:'#8b3a3a',breakthrough:-.62,note:'劫气随身，突破时心魔先至'},
 {min:60,id:'deep',label:'业力深重',color:'#a4562f',breakthrough:-.42,note:'业障压顶，经脉滞涩'},
 {min:30,id:'bound',label:'业力缠身',color:'#b08334',breakthrough:-.24,note:'梦中多见亡者'},
 {min:10,id:'stain',label:'微染',color:'#8a8a4a',breakthrough:-.08,note:'尚不碍事'},
 {min:0,id:'clean',label:'清净',color:'#4f7a5a',breakthrough:0,note:'心无挂碍'}
];
const hash=(s)=>{let h=2166136261;for(let i=0;i<String(s).length;i++){h^=String(s).charCodeAt(i);h=Math.imul(h,16777619);}return h>>>0;};
const rndOf=(seed)=>{let a=hash(seed)>>>0;return()=>{a=(a+0x6D2B79F5)>>>0;let t=Math.imul(a^(a>>>15),1|a);t=(t+Math.imul(t^(t>>>7),61|t))^t;return((t^(t>>>14))>>>0)/4294967296;};};

export function ensureKarma(w){
 if(!w.karma)w.karma={value:0,kills:{cultivator:0,mortal:0,justified:0,evildoer:0},records:[]};
 return w.karma;
}
export function karmaTier(v){
 for(const t of KARMA_TIERS)if(v>=t.min)return t;
 return KARMA_TIERS[KARMA_TIERS.length-1];
}
/** 掉落：修士身上有货，凡人身上只有几串钱。 */
export function lootFor(target,seed){
 const r=rndOf(seed||String(target?.id||target?.name||'x'));
 if(target?.kind==='cultivator'){
  const realm=target.realm||'qi';
  const mult={qi:1,found:3,core:9,nascent:24}[realm]||1;
  const stones=Math.round((2+r()*6)*mult);
  const pills=r()<.35?1+Math.round(r()):0;
  const tools=r()<.18?1:0;
  const talismans=r()<.25?1:0;
  return {stones,pills,tools,talismans,worth:Math.round(stones*100*1)};
 }
 return {copper:Math.round(5+r()*30),worth:0};
}
/** 先算账，不动世界：这一刀砍下去会怎样。 */
export function killPreview(w,{target,reason,evidences=[],witnesses=0}={}){
 if(!target||!target.kind)return {ok:false,error:'没有目标'};
 const ev=new Set(evidences);
 const just=reason&&JUSTIFY[reason]?reason:null;
 if(witnesses>0)ev.add('witness');
 if(target.sectId)ev.add('kinOfCultivator');
 let karma;
 if(target.kind==='cultivator'){
  // 同类相争，天不忌；抢的是资源，沾的业轻
  karma=(target.evil?-1:2)+(target.sectId?2:0);
 }else{
  // 凡人没有掉落：无故杀之最重；有理由则不沾；该杀之人反而是除害
  if(target.evil)karma=-3;
  else if(just)karma=1;
  else karma=14;
 }
 if(ev.has('witness')&&!just&&!target.evil)karma+=3;
 karma=Math.round(karma);
 const loot=lootFor(target);
 const sectHostility=target.sectId?Math.round(12+(target.kind==='cultivator'?8:0)):0;
 const wanted=target.kind==='mortal'&&!target.evil&&!just?(witnesses>0?2:1):0;
 const tierAfter=karmaTier(ensureKarma(w).value+Math.max(0,karma));
 return {ok:true,karma,loot,sectHostility,wanted,justified:!!just,
  reason:just?JUSTIFY[just].label:null,tierAfter:tierAfter.id,tierLabel:tierAfter.label};
}
/** 真砍：业力、掉落、官府、宗门一起记账。 */
export function resolveKill(w,opts={}){
 const p=killPreview(w,opts);
 if(!p.ok)return p;
 const k=ensureKarma(w);
 k.value=Math.max(0,k.value+Math.max(0,p.karma));
 if(p.karma<0)k.value=Math.max(0,k.value+p.karma);
 const t=opts.target;
 k.kills[t.kind]+=1;
 if(p.justified)k.kills.justified+=1;
 if(t.evil)k.kills.evildoer+=1;
 k.records.push({day:w.day,hour:w.hour,name:t.name||t.id,kind:t.kind,karma:p.karma,reason:p.reason});
 if(k.records.length>120)k.records.shift();
 // 掉落进包（灵石记在府库/私囊的灵石面额上，凡人只掉铜钱）
 const drops=[];
 if(t.kind==='cultivator'){
  if(p.loot.stones)drops.push(`灵石 ${p.loot.stones}`);
  if(p.loot.pills)drops.push(`丹药 ${p.loot.pills}`);
  if(p.loot.tools)drops.push(`法器 ${p.loot.tools}`);
  if(p.loot.talismans)drops.push(`符箓 ${p.loot.talismans}`);
  w.player.killLoot=w.player.killLoot||{stones:0,pills:0,tools:0,talismans:0};
  w.player.killLoot.stones+=p.loot.stones;
  w.player.killLoot.pills+=p.loot.pills;
  w.player.killLoot.tools+=p.loot.tools;
  w.player.killLoot.talismans+=p.loot.talismans;
 }else if(p.loot.copper){
  drops.push(`铜钱 ${p.loot.copper}`);
  w.player.copper=(w.player.copper||0)+p.loot.copper;
 }
 if(p.sectHostility&&w.sectRelations&&t.sectId)w.sectRelations[t.sectId]=(w.sectRelations[t.sectId]||0)-p.sectHostility;
 if(p.wanted)w.player.wanted=Math.max(w.player.wanted||0,p.wanted);
 // 道心跟着走：误入歧途不是想干什么就干什么，是身边的人开始换
 const dshift=t.kind==='cultivator'?(p.justified?0:-1):(t.evil?4:(p.justified?0:-8));
 if(dshift)shiftDao(w,dshift,p.justified?`处置${t.name||''}`:`杀${t.name||''}`);
 // 行径账：立场可以装，做过的事装不了
 if(t.kind==='cultivator')recordDeed(w,'cultivator');
 else if(t.evil)recordDeed(w,'evil');
 else if(!p.justified)recordDeed(w,'innocent');
 const dmg=p.tierAfter==='clean'?'':`　${karmaTier(k.value).note}`;
 return {...p,drops,karmaAfter:k.value,tierLabel:karmaTier(k.value).label,summary:`杀${t.kind==='cultivator'?'修士':'凡人'}${t.name||''}：业力${p.karma>=0?'+':''}${p.karma}${dmg}`};
}
/** 突破：业力越高，越难过关。 */
export function breakthroughChance(w,base=.55){
 const k=ensureKarma(w),t=karmaTier(k.value);
 const chance=Math.max(.02,Math.min(.95,base*(1+t.breakthrough)));
 return {chance,base,penalty:t.breakthrough,tier:t.id,tierLabel:t.label,
  risk:k.value>=120?'天劫':k.value>=60?'心魔':null};
}
export function attemptBreakthrough(w,base=.55){
 const r=breakthroughChance(w,base),roll=rndOf(`bt-${w.seed}-${w.day}-${w.player.stats?.level||1}`)();
 const ok=roll<r.chance;
 if(!ok&&r.tier!=='clean')ensureKarma(w).value=Math.min(400,ensureKarma(w).value+6);
 return {ok,roll:Math.round(roll*100)/100,chance:Math.round(r.chance*100)/100,tier:r.tierLabel,risk:r.risk,
  text:ok?`冲关成功（${Math.round(r.chance*100)}%）`:`冲关失败，业力又重了一分（成功率 ${Math.round(r.chance*100)}%）`};
}
export function karmaReport(w){
 const k=ensureKarma(w),t=karmaTier(k.value),b=breakthroughChance(w);
 return {value:k.value,tier:t.label,tierId:t.id,note:t.note,kills:k.kills,
  breakthrough:b,recent:k.records.slice(-5).reverse()};
}
