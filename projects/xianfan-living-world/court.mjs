// 《仙凡共生》朝堂：一句人话就是一道旨，旨意由手下执行，执行会打折。
// 规则：玩家不说“调用函数”，说“开仓放粮三千石”；系统解析意图，派给对的人，按他的能力与贪腐结算。
import {note} from './core.mjs';
import {ensureFin,purseOf} from './units.mjs';
import {ensureMarket,releaseGrain,buyToGranary,setTax,setMonopoly,buildPost,marketReport,GOODS} from './market.mjs';
import {ensureWar,createArmy,warReport,levyCapacity} from './war.mjs';
import {rankOf} from './war.mjs';

export const COURT_VERSION='court-1.0.0';

export const OFFICES={
 hubu:{name:'户部主事',role:'market',skill:72,corruption:.12,note:'掌钱粮市易，最懂价，也最会揩油'},
 xiancheng:{name:'县丞',role:'civil',skill:66,corruption:.08,note:'掌文书与差役，事情办得慢但不乱'},
 duwei:{name:'都尉',role:'army',skill:70,corruption:.15,note:'掌兵与征发，敢报大数'},
 zhanggui:{name:'商会掌柜',role:'merchant',skill:80,corruption:.05,note:'外面的人，办事快，价钱也明白'},
 xueguan:{name:'学宫祭酒',role:'tech',skill:75,corruption:.03,note:'掌技艺与典籍'},
 anchasi:{name:'按察司佥事',role:'censor',skill:64,corruption:0,note:'查账的人，谁都不喜欢他'}
};

export function ensureCourt(w){
 if(!w.court){
  w.court={
   staff:Object.entries(OFFICES).map(([id,o],i)=>({id,name:o.name,role:o.role,skill:o.skill,corruption:o.corruption,
    loyalty:70+((i*7)%12),busy:null,note:o.note})),
   tasks:[],log:[],orderNo:0
  };
 }
 return w.court;
}
export function staffReport(w){
 const c=ensureCourt(w);
 return c.staff.map(s=>({id:s.id,name:s.name,role:s.role,skill:s.skill,corruption:Math.round(s.corruption*100),loyalty:s.loyalty,
  busy:s.busy?`${s.busy.label}（还剩 ${s.busy.days} 日）`:'待命',note:s.note}));
}
// ---- 一句人话 -> 一道旨 ----
const RULES=[
 {intent:'levy',re:/征(发|兵|军)|募兵|拉壮丁/,cap:'army'},
 {intent:'march',re:/(开拔|出征|进军|发兵)/,cap:'army'},
 {intent:'recall',re:/(回师|班师|撤军)/,cap:'army'},
 {intent:'release',re:/(开仓|放粮|平粜|赈济|救灾)/,cap:'market'},
 {intent:'buy',re:/(收粮|籴粮|收购|囤粮)/,cap:'market'},
 {intent:'taxUp',re:/(加税|增税|加赋|加征|增赋|加派)/,cap:'civil'},
 {intent:'taxDown',re:/(减税|免赋|蠲免)/,cap:'civil'},
 {intent:'monopoly',re:/(禁榷|专卖|官营|收归官|盐铁)/,cap:'market'},
 {intent:'post',re:/(驿传|驿站|修路|转运)/,cap:'civil'},
 {intent:'audit',re:/(查账|清查|巡查|按察)/,cap:'censor'},
 {intent:'tech',re:/(冶金|马政|操典|器械|研习|技艺)/,cap:'tech'}
];
export function parseDecree(text){
 const t=String(text||'');
 for(const r of RULES)if(r.re.test(t))return {intent:r.intent,cap:r.cap,text:t};
 return {intent:'talk',cap:null,text:t};
}
function qty(text,def=2000){
 const m=String(text).match(/([0-9０-９一二三四五六七八九十百千万]+)\s*(斗|石|万|人|千|百)?/);
 if(!m)return def;
 const n=(()=>{const raw=m[1];if(/^[0-9０-９]+$/.test(raw))return Number(raw);const map={一:1,二:2,三:3,四:4,五:5,六:6,七:7,八:8,九:9,十:10};
   if(map[raw])return map[raw];let v=0;if(raw.includes('万'))v+=10000*(map[raw[0]]||1);if(raw.includes('千'))v+=1000*(map[raw[0]]||1);return v||def;})();
 const unit=m[2]||'';
 if(unit==='石')return Math.round(n*10);
 return n;
}
// ---- 派活与执行 ----
export function issueOrder(w,text,{forced=null}={}){
 const c=ensureCourt(w);
 const rk=rankOf(w);
 if(rk==='平民')return {ok:false,error:'你不是官身，没有可派的差事——只能自己去买粮。'};
 const p=parseDecree(text);
 if(p.intent==='talk')return {ok:false,error:'这不是一道旨意，是句闲话。要办差，请说清“做什么、多少”。'};
 const staff=c.staff.find(s=>s.role===p.cap&&!s.busy)||c.staff.find(s=>!s.busy);
 if(!staff)return {ok:false,error:'手下都在办差，等他们回来。'};
 const days=p.intent==='levy'||p.intent==='march'?2:1;
 const task={id:++c.orderNo,intent:p.intent,text,staff:staff.id,days,args:{qty:qty(text)}};
 staff.busy={label:labelOf(p.intent),days};
 c.tasks.push(task);
 note(w,'旨意',`${w.player.name}命${staff.name}：${text}`);
 return {ok:true,task,staff:staff.name,eta:days,reply:`${staff.name}领旨：“${labelOf(p.intent)}，${days} 日内回话。”`};
}
function labelOf(intent){
 return ({levy:'征发',march:'开拔',recall:'回师',release:'开仓',buy:'收粮',taxUp:'加税',taxDown:'减税',monopoly:'禁榷',post:'修驿传',audit:'查账',tech:'研习'})[intent]||'办差';
}
/** 每过一天，手下把活干完——按 skill 与 corruption 打折。 */
export function tickCourt(w){
 const c=ensureCourt(w);const events=[];
 for(const t of c.tasks){
  const s=c.staff.find(x=>x.id===t.staff);
  const speed=1+(s.skill-60)/100;
  const need=Math.max(1,Math.ceil(t.days/speed));
  t.days=t.days; // 保留原值不动
  t.left=(t.left??t.days)-1;
  if(t.left>0)continue;
  if(s.busy)s.busy.days=Math.max(0,(s.busy.days??0)-1);
  const efficiency=Math.max(.4,Math.min(1,(s.skill/100)-(s.corruption)));
  const out=applyOrder(w,t,efficiency);
  if(s.busy&&s.busy.days<=0)s.busy=null;
  t.done=true;t.result=out;
  if(out?.text)events.push({type:'回话',text:`${s.name}：${out.text}`});
 }
 c.tasks=c.tasks.filter(t=>!t.done);
 for(const s of c.staff)if(s.busy&&s.busy.days<=0)s.busy=null;
 if(events.length)c.log.push(...events);
 if(c.log.length>120)c.log=c.log.slice(-120);
 return {events};
}
function applyOrder(w,t,eff){
 switch(t.intent){
  case 'release':{const dan=Math.round(t.args.qty*eff);const r=releaseGrain(w,dan);return {text:r.ok?`开仓 ${dan} 斗（折扣 ${Math.round(eff*100)}%），粮价 ${w.market.prices.grain} 文。`:r.error};}
  case 'buy':{const dan=Math.round(t.args.qty*eff);const r=buyToGranary(w,dan);return {text:r.ok?`收粮 ${dan} 斗，花 ${r.cost.toLocaleString()} 文。`:r.error};}
  case 'taxUp':{const r=setTax(w,Math.min(.35,+(w.market.taxRate+.05).toFixed(2)));return {text:r.ok?`税已加到 ${Math.round(w.market.taxRate*100)}%。`:'已到上限。'};}
  case 'taxDown':{const r=setTax(w,Math.max(.03,+(w.market.taxRate-.05).toFixed(2)));return {text:r.ok?`税减至 ${Math.round(w.market.taxRate*100)}%。`:'税率已到底。'};}
  case 'monopoly':{const on=!/弛|解/.test(t.text);setMonopoly(w,'salt',on);return {text:on?'盐归官营，盐价抬到 '+w.market.prices.salt+' 文。':'盐禁已弛。'};}
  case 'post':{const r=buildPost(w);return {text:r.ok?`驿站增置，转运 ${Math.round((w.market.post-1)*100)}%。`:r.error};}
  case 'levy':{const f='court';const cap=levyCapacity(w,f);const men=Math.min(Math.round(cap.combat*.5),Math.max(1000,Math.round(t.args.qty*eff)));
    try{const a=createArmy(w,f,{combat:men,seed:(w.court.orderNo||1)*13});return {text:`${a.corps}成军，战兵 ${a.combat.toLocaleString()}，以${a.commander}为将。`};}catch(e){return {text:e.message};}}
  case 'march':{const a=w.war?.armies.find(x=>!x.routed);if(!a)return {text:'无兵可发。'};a.goal={x:0,y:0};return {text:`${a.corps}开拔。`};}
  case 'recall':{const a=w.war?.armies.find(x=>!x.routed);if(!a)return {text:'无军可回。'};a.goal={x:0,y:0};return {text:`${a.corps}回师。`};}
  case 'audit':{ensureFin(w);const found=Math.round(purseOf(w,'court')*0.01*eff);w.states.court.treasury-=found;return {text:`查出亏空 ${found.toLocaleString()} 文，已封账。`};}
  default:return {text:'这差事办不了。'};
 }
}
// ---- 对话：手下不是按钮，是会说人话的人 ----
export function talkTo(w,staffName,text){
 const c=ensureCourt(w);
 const s=c.staff.find(x=>x.name===staffName||x.id===staffName)||c.staff[0];
 const t=String(text||'');
 const m=marketReport(w);
 const wr=w.war?warReport(w):null;
 if(/粮价|市面|物价/.test(t))return {staff:s.name,say:`今日粮价 ${m.goods[0].price} 文/斗（基准 ${GOODS.grain.base}），民怨 ${m.unrest}，官仓 ${m.granary} 斗。`};
 if(/钱|府库|国库|银/.test(t))return {staff:s.name,say:`府库现有 ${m.treasury.toLocaleString()} 文；本月税 ${Math.round(m.taxRate*100)}%，贪墨约 ${Math.round(s.corruption*100)}%。`};
 if(/兵|军|战/.test(t))return {staff:s.name,say:wr?`在册 ${wr.total.toLocaleString()} 人、${wr.armies} 军，第 ${wr.day} 日。`:'尚未有人马。'};
 if(/贪|亏空|查账/.test(t))return {staff:s.name,say:s.corruption===0?'我查别人，不查自己。':`账上总有些糊涂地方……大人若信我，就别细看。`};
 if(/民怨|流民|灾/.test(t))return {staff:s.name,say:`民怨 ${m.unrest}/100${m.unrest>=70?'，已有人弃田出走':''}。`};
 if(s.busy)return {staff:s.name,say:`我正在办《${s.busy.label}》，还剩 ${s.busy.days} 日。`};
 return {staff:s.name,say:`${s.note}。大人还有何吩咐？`};
}
export function courtReport(w){
 const c=ensureCourt(w);
 return {staff:staffReport(w),log:(c.log||[]).slice(-6).reverse(),busy:c.staff.filter(s=>s.busy).length};
}
