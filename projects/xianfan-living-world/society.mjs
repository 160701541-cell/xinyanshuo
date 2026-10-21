/** 仙凡共生 · v0.8 势力 / 声望 / 委托 / 物产：纯逻辑层，可无 DOM 测试。 */
import {PLACES,deriveSeed,mulberry32,note,getPlace,advanceClock} from './core.mjs';
import {LANDMARKS,placeAt,cityAt,CITIES} from './overworld.mjs';

export {cityAt,CITIES};

export const SOCIAL_VERSION='county-0.8.0';

// 势力：颜色成对（底色 / 描边墨色），供 P 社式政治图层使用。
export const FACTIONS=[
 {id:'court',name:'大宁官府',color:'#cdb768',ink:'#7d6428',kind:'mortal',seat:'xianya',weight:1.0,blurb:'县衙与朝廷命官，掌钱粮、刑名与驿传。'},
 {id:'merchant',name:'临安商会',color:'#d79b62',ink:'#8f5527',kind:'mortal',seat:'dongshi',weight:.86,blurb:'粮行、铁铺与货栈，掌市面流通与借贷。'},
 {id:'folk',name:'乡野农户',color:'#a6bb84',ink:'#5b7140',kind:'mortal',seat:'songlin',weight:.62,blurb:'村落田亩与佃户，纳粮服役，遇灾则流。'},
 {id:'sect',name:'青云仙门',color:'#8ab4c8',ink:'#456b7e',kind:'cultivation',seat:'qingyun',weight:.94,blurb:'山门修士，御剑往来，不奉世俗律。'},
 {id:'guard',name:'御城军',color:'#9d92bd',ink:'#544a72',kind:'cultivation',seat:'qingyun',weight:.7,blurb:'修仙城池的守城军，城内唯一被允许御剑升空者。'},
];
// 人口是府库与征兵的唯一分母（war.mjs 的 REALM、units.mjs 的军费都从这里取）
export const POPULATION={
 court:{people:12000000,name:'大宁'},
 merchant:{people:3800000,name:'临安商户'},
 folk:{people:16000000,name:'乡野编户'},
 sect:{people:600000,name:'青云道众'},
 guard:{people:300000,name:'御城军籍'}
};
export const factionById=id=>FACTIONS.find(f=>f.id===id)||null;

// —— 势力领土：加权最近锚点的硬边界（P 社式色块），单元格边长 6000 米。
export const TERRITORY_STEP=6000;
const ANCHORS=(()=>{
 const list=[];
 for(const l of LANDMARKS){
  const f=factionById(idOf(l));if(!f)continue;
  const p=getPlace(l.id);
  const w=f.weight*(p?.population?Math.min(1.9,.7+p.population/9000):1);
  list.push({faction:f.id,x:l.x,y:l.y,weight:w});
 }
 return list;
})();
function idOf(l){
 if(l.id==='xianya'||l.id==='nanmen')return 'court';
 if(['dongshi','xijie','minju','lianghang','tiepu','kezhan'].includes(l.id))return 'merchant';
 if(['songlin','shiqiao','liantang','hewan','qingxi','dukou','guanlu'].includes(l.id))return 'folk';
 return l.faction==='青云仙门'?'sect':l.faction==='大宁王朝'?'court':'folk';
}
export function factionAtPoint(x,y){
 if(x===0&&y===0)return 'merchant';
 let best='folk',score=Infinity;
 for(const a of ANCHORS){const s=Math.hypot(x-a.x,y-a.y)/a.weight;if(s<score){score=s;best=a.faction;}}
 // 城内以城主势力为准，避免城内被相邻农户切块。
 const c=cityAt({x,y});if(c)return c.hold;
 return best;
}
// 领土网格：近场 2000 米、远场 12000 米两级。返回纯数据，绘制交给界面（避免每帧逐格画）。
export const GRID_STEP=2000, GRID_LIMIT=300000;
const gridCache=new Map();
export function territoryGrid(step=GRID_STEP,limit=GRID_LIMIT){
 const key=`${step}/${limit}`;
 if(gridCache.has(key))return gridCache.get(key);
 const n=Math.floor(limit*2/step)+1;
 const ids=FACTIONS.map(f=>f.id);
 const cells=new Uint8Array(n*n);
 for(let j=0;j<n;j++)for(let i=0;i<n;i++){
  const x=-limit+i*step+step/2,y=-limit+j*step+step/2;
  cells[j*n+i]=ids.indexOf(factionAtPoint(x,y));
 }
 const grid={step,n,limit,origin:-limit,ids,cells};
 gridCache.set(key,grid);
 return grid;
}
/** 把零碎边界段串成折线，供界面画成平滑曲线（纯几何，可单测）。 */
export function territoryBorderPaths(step=GRID_STEP,limit=GRID_LIMIT){
 const segs=territoryBorderSegments(step,limit);
 const key=(x,y)=>`${x},${y}`;
 const adj=new Map(),used=new Set();
 segs.forEach((s,i)=>{
  if(s[0]===s[2]&&s[1]===s[3])return;
  adj.set(key(s[0],s[1]),(adj.get(key(s[0],s[1]))||[]).concat([[s[2],s[3],i]]));
  adj.set(key(s[2],s[3]),(adj.get(key(s[2],s[3]))||[]).concat([[s[0],s[1],i]]));
 });
 const paths=[];
 const walk=(node)=>{
  const pts=[node.split(',').map(Number)];
  let cur=node;
  for(;;){
   const next=(adj.get(cur)||[]).find(e=>!used.has(e[2]));
   if(!next)break;
   used.add(next[2]);pts.push([next[0],next[1]]);
   cur=key(next[0],next[1]);
   if(cur===node)break;
  }
  if(pts.length>2)paths.push(pts);
 };
 // 先走端点（开放线），再走闭环
 for(const [node,edges] of adj)if(edges.length!==2)walk(node);
 for(const [node] of adj)walk(node);
 return paths;
}
/** 边界线段（世界坐标）：只返回左右/上下不同势力的格子公共边，供上层平滑成曲线。 */
export function territoryBorderSegments(step=GRID_STEP,limit=GRID_LIMIT){
 const {n,origin,ids,cells}=territoryGrid(step,limit);
 const segs=[];
 const at=(i,j)=>(i<0||j<0||i>=n||j>=n)?-1:cells[j*n+i];
 for(let j=0;j<n;j++)for(let i=0;i<n;i++){
  const a=cells[j*n+i],x=origin+i*step,y=origin+j*step;
  const r=at(i+1,j),d=at(i,j+1),dr=at(i+1,j+1);
  const mix=(b,c,dg)=>{
   const set=new Set([a,b,c,dg].filter(v=>v>=0));
   if(set.size<2)return null;
   return [ids[a],...[...set].filter(v=>v!==a).map(v=>ids[v])];
  };
  if(r>=0&&r!==a)segs.push([x+step,y,x+step,y+step,a,r]);
  if(d>=0&&d!==a)segs.push([x,y+step,x+step,y+step,a,d]);
  if(r>=0&&d>=0&&dr>=0&&new Set([a,r,d,dr]).size>1){
   // 四角四色交汇：补一对斜边，避免出现空洞
   if(a!==dr&&r!==d)segs.push([x+step,y+step,x+step,y+step,a,dr]);
  }
 }
 return segs;
}
// —— 声望：按势力记账，影响进城门、买粮价、接委托的资格。
export function reputation(w,factionId){
 if(!w.reputation)w.reputation={};
 return w.reputation[factionId]??0;
}
export function adjustReputation(w,factionId,delta,reason=''){
 if(!factionById(factionId))return {ok:false,error:'未知势力'};
 if(!w.reputation)w.reputation={};
 const before=reputation(w,factionId);
 const next=Math.max(-100,Math.min(100,before+Math.round(delta)));
 w.reputation[factionId]=next;
 if(next!==before)note(w,'声望',`${factionById(factionId).name}对你的态度变了（${before>next?'-':'+'}${Math.abs(next-before)}，现为 ${next}）。`,{faction:factionId,delta:next-before,reason});
 return {ok:true,before,after:next};
}
export const standing=(w,factionId)=>{const r=reputation(w,factionId);return r>=60?'敬重':r>=25?'亲近':r>-25?'平常':r>-60?'警惕':'敌视';};

// —— 地图模式：与 P 社同构的着色层，只换配色不改世界状态。
export const MAP_MODES=[
 {id:'terrain',name:'地形'},
 {id:'faction',name:'势力'},
 {id:'population',name:'人口'},
 {id:'security',name:'治安'},
 {id:'sect',name:'宗门'},
];
function popColor(n){return n>=1200?'#8d5a3c':n>=600?'#b4794d':n>=300?'#d19a63':n>=120?'#e3bd8a':'#efd9b4';}
export function securityIndex(w){
 // 治安 = 官府声望/驻军存在 - 流民压力 - 盗匪传闻（由近期事件派生，确定性）
 const ev=w.history.slice(-40);
 const bad=ev.filter(e=>/盗|劫|流民|灾/.test(e.message)).length;
 const court=(w.reputation?.court??0);
 return Math.max(0,Math.min(100,62+court-bad*4));
}
export function mapColor(w,mode,x,y){
 if(mode==='faction'){const f=factionById(factionAtPoint(x,y));return f?f.color:'#e5dcc2';}
 const place=placeAt({x,y});
 if(mode==='terrain'){
  const t=(getPlace(place.id)?.type)||'road';
  return t==='market'?'#e0c58f':t==='sect'?'#b9cdd8':t==='village'?'#c3d0a4':t==='capital'?'#d8c07f':t==='office'?'#cfc3a0':'#dcdcc5';
 }
 if(mode==='population'){const n=getPlace(place.id)?.population??0;return popColor(n);}
 if(mode==='security'){const s=securityIndex(w);return s>70?'#9cc49b':s>45?'#e2cf9a':'#d99a8b';}
 if(mode==='sect'){const f=factionById(factionAtPoint(x,y));return f?.kind==='cultivation'?'#a9c3d4':f?.id==='court'?'#d8cca4':'#e3dcc6';}
 return '#dcdcc5';
}

// —— 物产：市面商品，价格随世界粮价与势力声望浮动。
export const ITEMS=[
 {id:'grain',name:'米袋',kind:'food',unit:'斗',value:9,weight:12,tags:['粮']},
 {id:'tea',name:'茶砖',kind:'food',unit:'块',value:14,weight:3,tags:['饮']},
 {id:'cloth',name:'粗布',kind:'craft',unit:'匹',value:26,weight:5,tags:['衣']},
 {id:'herb',name:'草药',kind:'medicine',unit:'包',value:18,weight:1,tags:['药']},
 {id:'pill',name:'回气丹',kind:'medicine',unit:'丸',value:52,weight:.2,tags:['丹','修士']},
 {id:'talisman',name:'黄符',kind:'ritual',unit:'张',value:33,weight:.2,tags:['符','修士']},
 {id:'iron',name:'生铁',kind:'craft',unit:'斤',value:12,weight:1},
 {id:'knife',name:'柴刀',kind:'tool',unit:'把',value:34,weight:2},
 {id:'sword',name:'青锋剑',kind:'weapon',unit:'柄',value:260,weight:3,tags:['武']},
 {id:'rope',name:'麻绳',kind:'tool',unit:'捆',value:8,weight:1},
 {id:'paper',name:'黄纸',kind:'ritual',unit:'刀',value:11,weight:.6},
 {id:'wine',name:'土酒',kind:'food',unit:'坛',value:21,weight:6},
];
export const itemById=id=>ITEMS.find(i=>i.id===id)||null;
export function priceOf(w,itemId){
 const it=itemById(itemId);if(!it)return null;
 const grainRatio=(w.price||900)/900;
 const rep=reputation(w,'merchant');
 return Math.max(1,Math.round(it.value*grainRatio*(1-(rep>=25?.06:0))));
}
export function inventory(w){
 if(!w.player.bag)w.player.bag={};
 return w.player.bag;
}
export function bagWeight(w){
 let n=0;for(const [id,q] of Object.entries(inventory(w)))n+=(itemById(id)?.weight||0)*q;
 return Math.round(n*10)/10;
}
export function addItem(w,itemId,qty=1){
 if(!itemById(itemId)||!Number.isInteger(qty)||qty<=0)return {ok:false,error:'无效物品或数量'};
 const bag=inventory(w);bag[itemId]=(bag[itemId]||0)+qty;
 note(w,'物产',`得到 ${itemById(itemId).name} ×${qty}。`,{item:itemId,qty});
 return {ok:true,bag};
}
export function removeItem(w,itemId,qty=1){
 const bag=inventory(w);if((bag[itemId]||0)<qty)return {ok:false,error:'身上没有这么多'};
 bag[itemId]-=qty;if(bag[itemId]<=0)delete bag[itemId];
 return {ok:true,bag};
}
const MARKET_TYPES=new Set(['market','shop','street']);
export function canTradeHere(w){
 const place=getPlace(w.player.place);
 return !!place&&MARKET_TYPES.has(place.type);
}
export function buyItem(w,itemId,qty=1){
 if(!canTradeHere(w))return {ok:false,error:'此处不是市集，得去东市或粮行。'};
 const price=priceOf(w,itemId);if(price===null)return {ok:false,error:'没有这件货'};
 const cost=price*qty;if((w.player.silver??0)<cost)return {ok:false,error:`银钱不足，还差 ${cost-(w.player.silver??0)} 文。`};
 w.player.silver-=cost;addItem(w,itemId,qty);
 adjustReputation(w,'merchant',0.4);
 note(w,'交易',`买了 ${itemById(itemId).name} ×${qty}，花 ${cost} 文。`,{item:itemId,qty,cost});
 return {ok:true,cost,silver:w.player.silver};
}
export function sellItem(w,itemId,qty=1){
 if(!canTradeHere(w))return {ok:false,error:'此处不是市集，得去东市或粮行。'};
 const r=removeItem(w,itemId,qty);if(!r.ok)return r;
 const gain=Math.max(1,Math.round(priceOf(w,itemId)*.7))*qty;
 w.player.silver=(w.player.silver??0)+gain;
 note(w,'交易',`卖掉 ${itemById(itemId).name} ×${qty}，得 ${gain} 文。`,{item:itemId,qty,gain});
 return {ok:true,gain,silver:w.player.silver};
}

// —— 委托：由世界状态确定性生成，接取后计入玩家任务。
const CONTRACT_KINDS=[
 {id:'grain',title:'平粜',faction:'court',text:'市面粮价高企，官府请人协助平抑米价。',reward:{coin:120,rep:{court:6,folk:3}}},
 {id:'escort',title:'护送',faction:'merchant',text:'商会有一批货要送去石桥，需人随行。',reward:{coin:160,rep:{merchant:7}}},
 {id:'herb',title:'采药',faction:'sect',text:'山门缺一味草药，请人去灵山药市收齐。',reward:{coin:90,rep:{sect:6}}},
 {id:'patrol',title:'巡夜',faction:'court',text:'县衙招募巡夜，协助城门值更。',reward:{coin:70,rep:{court:5,guard:2}}},
];
export function contractsFor(w){
 const seed=deriveSeed(`contracts-${w.day}-${w.seed||'临安初雪'}`);
 const r=mulberry32(seed);
 const taken=new Set((w.player.contracts||[]).map(c=>c.id));
 const out=[];
 CONTRACT_KINDS.forEach((k,i)=>{
  const id=`C${w.day}-${i}`;if(taken.has(id))return;
  const target=chooseTarget(k.id,r);
  const pay=Math.round(k.reward.coin*(0.85+r()*0.4));
  out.push({id,kind:k.id,title:k.title,faction:k.faction,text:k.text,target,pay,reward:k.reward,expireDay:w.day+3});
 });
 return out;
}
function chooseTarget(kind,r){
 if(kind==='grain')return 'lianghang';
 if(kind==='escort')return 'shiqiao';
 if(kind==='herb')return 'lingshan_yaopu';
 return 'nanmen';
}
export function acceptContract(w,id){
 const c=contractsFor(w).find(x=>x.id===id);
 if(!c)return {ok:false,error:'这张委托已经不在告示上了'};
 w.player.contracts=w.player.contracts||[];
 w.player.contracts.push({...c,acceptedDay:w.day});
 note(w,'委托',`接下「${c.title}」：${c.text}`,{contract:c.id});
 return {ok:true,contract:c};
}
export function completeContract(w,id){
 const list=w.player.contracts||[];
 const idx=list.findIndex(c=>c.id===id);
 if(idx<0)return {ok:false,error:'没有接这张委托'};
 const c=list[idx];
 if(w.player.place!==c.target)return {ok:false,error:`得先到 ${getPlace(c.target)?.name||c.target} 才能交差`};
 w.player.silver=(w.player.silver??0)+c.pay;
 for(const [f,d] of Object.entries(c.reward.rep||{}))adjustReputation(w,f,d,'委托');
 list.splice(idx,1);
 note(w,'委托',`「${c.title}」交差，得 ${c.pay} 文。`,{contract:c.id});
 return {ok:true,pay:c.pay,silver:w.player.silver};
}
export function societyReport(w){
 return {
  day:w.day,
  silver:w.player.silver??0,
  bagWeight:bagWeight(w),
  contracts:(w.player.contracts||[]).length,
  reputation:Object.fromEntries(FACTIONS.map(f=>[f.name,reputation(w,f.id)])),
  standing:Object.fromEntries(FACTIONS.map(f=>[f.name,standing(w,f.id)])),
  security:securityIndex(w),
 };
}
