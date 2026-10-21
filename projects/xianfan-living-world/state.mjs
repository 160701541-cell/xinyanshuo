// 《仙凡共生》制度：政策不是按钮，是一组会互相牵制的杠杆；改制有阻力，效果有滞后。
// 一条因果：制度 → 贪腐/执行力 → 税收与赈济 → 民怨 → 治安/兵源 → 结局。
import {note} from './core.mjs';
import {ensureFin,purseOf} from './units.mjs';

export const STATE_VERSION='state-1.0.0';

export const LEVERS={
 antiCorruption:{
  name:'监察',options:{none:'不设监察',censor:'设按察司',strict:'按察+连坐'},def:'censor',
  effects:{none:{corruption:.10,legitimacy:-4},censor:{corruption:-.05,efficiency:.04},strict:{corruption:-.12,efficiency:.06,legitimacy:-3,resistance:8}}
 },
 law:{
  name:'律法',options:{loose:'宽简',code:'律令',harsh:'严刑'},def:'code',
  effects:{loose:{efficiency:-.04,legitimacy:4,unrest:-2},code:{efficiency:.02,legitimacy:2},harsh:{efficiency:.05,unrest:4,legitimacy:-6,resistance:5}}
 },
 exams:{
  name:'选官',options:{patronage:'察举',exam:'科举',heredity:'世袭'},def:'patronage',
  effects:{patronage:{corruption:.05,efficiency:-.03},exam:{corruption:-.06,efficiency:.05,legitimacy:3,resistance:6},heredity:{corruption:.08,efficiency:-.02,resistance:4}}
 },
 land:{
  name:'田制',options:{private:'私田',equal:'均田',state:'官田'},def:'private',
  effects:{private:{revenue:.06,unrest:1},equal:{unrest:-4,revenue:-.04,resistance:7},state:{corruption:.06,revenue:.03,resistance:3}}
 },
 military:{
  name:'军制',options:{levy:'征兵',professional:'募兵',garrison:'军户'},def:'levy',
  effects:{levy:{armyQuality:-.04,mobilize:.02},professional:{armyQuality:.08,revenue:-.06,resistance:2},garrison:{armyQuality:.02,mobilize:-.02,corruption:.03}}
 },
 tax:{
  name:'税制',options:{light:'轻赋',standard:'常赋',heavy:'重赋'},def:'standard',
  effects:{light:{unrest:-3,revenue:-.08},standard:{},heavy:{revenue:.10,unrest:5,legitimacy:-3}}
 }
};

export function ensureState(w){
 if(!w.state){
  w.state={
   levers:Object.fromEntries(Object.entries(LEVERS).map(([k,v])=>[k,v.def])),
   corruption:.16,efficiency:.62,legitimacy:62,resistance:10,
   reforms:[],log:[],day:0,outcome:'苟安'
  };
 }
 return w.state;
}
export function targetStats(w){
 const s=ensureState(w);
 let corruption=.18,efficiency=.60,legitimacy=60,revenue=1,unrest=0,army=0,mobilize=0,resistance=0;
 for(const [k,lever] of Object.entries(LEVERS)){
  const eff=lever.effects[s.levers[k]]||{};
  corruption+=eff.corruption||0;efficiency+=eff.efficiency||0;legitimacy+=eff.legitimacy||0;
  revenue+=eff.revenue||0;unrest+=eff.unrest||0;army+=eff.armyQuality||0;mobilize+=eff.mobilize||0;resistance+=eff.resistance||0;
 }
 corruption=Math.max(0,Math.min(.6,corruption));
 efficiency=Math.max(.25,Math.min(.95,efficiency));
 legitimacy=Math.max(0,Math.min(100,legitimacy));
 return {corruption,efficiency,legitimacy,revenue,unrest,army,mobilize,resistance};
}
/** 改制：动一条杠杆，得罪一批人；阻力高就要付时间与合法性。 */
export function reform(w,leverId,optionId){
 const s=ensureState(w);
 const lever=LEVERS[leverId];
 if(!lever)return {ok:false,error:'没有这一条制度'};
 if(!(optionId in lever.options))return {ok:false,error:'没有这个选项'};
 if(s.levers[leverId]===optionId)return {ok:false,error:'已是此制'};
 if((w.player?.rank||'平民')==='平民')return {ok:false,error:'平民改不了制度'};
 const before=s.levers[leverId];
 s.levers[leverId]=optionId;
 const t=targetStats(w);
 if(t.resistance>0){s.resistance=Math.min(100,s.resistance+t.resistance);s.legitimacy=Math.max(0,s.legitimacy-t.resistance*.6);}
 s.reforms.push({day:s.day,lever:leverId,from:before,to:optionId,resistance:t.resistance});
 note(w,'改制',`${lever.name}：${lever.options[before]} → ${lever.options[optionId]}${t.resistance>0?`（阻力 ${Math.round(t.resistance)}）`:''}。`);
 return {ok:true,resistance:t.resistance,before,after:optionId};
}
/** 每天：贪腐与效率缓慢靠近制度的“目标值”，民怨拉低合法性，阻力慢慢消。 */
export function tickState(w){
 const s=ensureState(w);const t=targetStats(w);
 s.corruption+= (t.corruption-s.corruption)*.18;
 s.efficiency+= (t.efficiency-s.efficiency)*.18;
 s.legitimacy+= (t.legitimacy-s.legitimacy)*.12;
 const unrest=w.market?.unrest??0;
 s.legitimacy=Math.max(0,Math.min(100,s.legitimacy-unrest*.02+(unrest<25?.4:0)));
 s.resistance=Math.max(0,s.resistance-Math.max(0,s.resistance*.08));
 s.day++;
 s.outcome=outcomeOf(w).name;
 // 制度反哺市面：贪腐抽税，效率抬供给
 if(w.market){w.market.corruption=s.corruption;w.market.post=(w.market.post||1)*(1+t.efficiency*.02);}
 return {corruption:+s.corruption.toFixed(3),efficiency:+s.efficiency.toFixed(3),legitimacy:Math.round(s.legitimacy),outcome:s.outcome};
}
export function outcomeOf(w){
 const s=ensureState(w);const unrest=w.market?.unrest??0;
 const treasury=purseOf(w,'court');
 if(unrest>=85)return {id:'revolt',name:'民变',desc:'饥民聚啸，官军哗散，县城易主。'};
 if(s.corruption>=.35&&unrest>=50)return {id:'rot',name:'腐败崩解',desc:'吏治烂到根，税征不上来，兵拿不到饷。'};
 if(s.legitimacy>=80&&s.corruption<=.10&&unrest<=20&&treasury>0)return {id:'golden',name:'盛世',desc:'仓廪实、狱讼平、赋入足，四境无盗。'};
 if(s.legitimacy>=65&&s.corruption<=.16)return {id:'revival',name:'中兴',desc:'纲纪粗立，赋役可办，民间元气渐复。'};
 if(treasury<0)return {id:'default',name:'府库崩溃',desc:'官仓与库银两头皆空。'};
 return {id:'survive',name:'苟安',desc:'不上不下：盗匪偶发，吏胥仍捞，日子还能过。'};
}
export function stateReport(w){
 const s=ensureState(w);const t=targetStats(w);
 return {day:s.day,levers:Object.fromEntries(Object.entries(LEVERS).map(([k,v])=>[k,{name:v.name,value:s.levers[k],label:v.options[s.levers[k]],options:Object.entries(v.options)}])),
  corruption:Math.round(s.corruption*100),efficiency:Math.round(s.efficiency*100),legitimacy:Math.round(s.legitimacy),resistance:Math.round(s.resistance),
  target:{corruption:Math.round(t.corruption*100),efficiency:Math.round(t.efficiency*100),legitimacy:Math.round(t.legitimacy)},
  outcome:outcomeOf(w),log:(s.log||[]).slice(-6)};
}
