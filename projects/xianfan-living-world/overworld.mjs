/** 仙凡共生 · v0.7 开放地理原型：米制唯一坐标、不因缩放切场景。 */
import {PLACES,deriveSeed,note,advanceClock,getPlace,apparentLocation,npcActivity} from './core.mjs';
export const MAP_VERSION='county-0.8.0';
export const WORLD_LIMIT=1_350_000;
// 城池：世俗城池看实力，修仙城池只有御城军可飞（见 flightRuleAt）。
export const CITIES=[
 {id:'linan',name:'临安县城',kind:'mortal',x:0,y:0,half:720,hold:'court'},
 {id:'qingyun',name:'青云山城',kind:'cultivation',x:11300,y:-7200,half:620,hold:'sect'},
 {id:'lingshan',name:'灵山药市',kind:'cultivation',x:12000,y:-8100,half:300,hold:'sect'},
];
export function cityAt(p){let best=null;for(const c of CITIES){const d=Math.hypot(p.x-c.x,p.y-c.y);if(d<=c.half*1.42&&(!best||d<best.d))best={...c,d};}return best;}
export const CITY={x:0,y:0,half:720,wall:24,gates:[{id:'north',x:0,y:-720},{id:'south',x:0,y:720},{id:'west',x:-720,y:0},{id:'east',x:720,y:0}]};
const county=[['dongshi',0,0],['xijie',-340,90],['minju',10,400],['nanmen',0,720],['guanlu',-500,2800],['dukou',-1400,500],['shiqiao',3600,4800],['songlin',6900,-3500],['liantang',-4100,5100],['hewan',-7400,1500],['qingxi',8500,6500],['qingyun',11300,-7200],['lingshan',12000,-8100],['xianya',-350,-420],['lianghang',370,210],['tiepu',300,260],['kezhan',260,-290],['tiepu_houyuan',300,260],['xianya_hou',-350,-420],['lianghang_cang',370,210],['kezhan2',260,-290],['kezhan_chamber',260,-290],['lingshan_yaopu',12000,-8100]];
export const PLACE_METERS=Object.fromEntries(county.map(([id,x,y])=>[id,{x,y}]));
const foreign=[
 ['ningjing','宁京 · 大宁皇城',-360000,-180000,'capital','大宁王朝','皇城、都城与朝廷（地理占位，未开放城内模拟）'],
 ['xuanjing','玄朔 · 北朔王庭',175000,-680000,'capital','北朔汗庭','草原王庭（地理占位）'],
 ['yuejing','越安 · 东越国都',730000,220000,'capital','东越','海贸大都（地理占位）'],
 ['xirong','朔边 · 西戎王城',-750000,100000,'capital','西戎','西陲高原（地理占位）'],
 ['yunli','云离 · 云离国都',190000,720000,'capital','云离','南方山国（地理占位）'],
 ['chixiao','赤霄剑宗',300000,-230000,'sect','赤霄剑宗','剑修仙门（宗门地理占位）'],
 ['tianji','天机观',-200000,380000,'sect','天机观','修行势力（地理占位）'],
 ['zhongzhou','中州皇道',-220000,-70000,'road','大宁王朝','帝都通衢（路线示意）'],
];
export const LANDMARKS=[
 ...county.filter(x=>!['_houyuan','_cang','_hou','chamber'].some(s=>x[0].includes(s))&&!['kezhan2'].includes(x[0])).map(([id,x,y])=>{const p=getPlace(id);return{id,x,y,name:p?.name||id,type:p?.type||'road',faction:id==='qingyun'||id==='lingshan'?'青云仙门':'大宁王朝',desc:p?.detail||'',active:true}}),
 ...foreign.map(([id,name,x,y,type,faction,desc])=>({id,name,x,y,type,faction,desc,active:false}))
];
export const STRUCTURES=[
 {id:'xianya',name:'临安县衙',x:-420,y:-530,w:150,h:145,door:{x:-345,y:-375},kind:'government',desc:'县丞、县吏和捕快在此办公。门口立有告示牌。'},
 {id:'tiepu',name:'陈记铁铺',x:225,y:175,w:145,h:145,door:{x:300,y:335},kind:'forge',desc:'临街炉火，后院堆着炭料与生铁。'},
 {id:'lianghang',name:'福源粮行',x:420,y:85,w:145,h:175,door:{x:405,y:210},kind:'grain',desc:'木架米袋和账簿，今日挂牌价随市场变动。'},
 {id:'kezhan',name:'望江客栈',x:155,y:-420,w:165,h:145,door:{x:235,y:-265},kind:'inn',desc:'两层客栈，门向十字街，后院可停商车。'},
 {id:'westhouse',name:'许家院',x:-570,y:140,w:135,h:155,door:{x:-420,y:215},kind:'home',desc:'民居院落，土墙围合，门开向街巷。'},
 {id:'southschool',name:'南坊私塾',x:-140,y:410,w:150,h:125,door:{x:-160,y:415},kind:'school',desc:'书声渐起，院中有一株百年槐树。'},
 {id:'westguard',name:'西门营房',x:-665,y:-195,w:140,h:100,door:{x:-510,y:-140},kind:'fort',desc:'值夜守兵轮换驻扎。'},
 {id:'songlinn',name:'松林村祠堂',x:6740,y:-3700,w:110,h:115,door:{x:6795,y:-3570},kind:'home',desc:'松林村族人修缮的祠堂，屋后紧邻炭窑。'},
 {id:'songlinwork',name:'松林村木坊',x:7100,y:-3415,w:120,h:95,door:{x:7160,y:-3305},kind:'forge',desc:'烧炭、木作与薪柴堆场。'},
];
// 城墙实体包含门洞，不允许靠近城墙任意穿越。
// 城区街巷两侧的真实房屋碰撞体；支持未来拆分为独立室内场景。
export const TOWN_HOUSES=(()=>{let out=[],id=0;for(let bx of [-630,-450,-190,90,350,560])for(let by of [-610,-350,-90,175,445]){if(Math.abs(bx)<115&&Math.abs(by)<120)continue;for(let k=0;k<2;k++){const s=deriveSeed(`house-${bx}-${by}-${k}`);const x=bx+(k%2)*65+(s%15),y=by+(Math.floor(k/2)*65)+(s%11);const b={id:'house_'+(++id),x,y,w:55+(s%8),h:60+(s%8),kind:'home',name:'民居院落'};
 if(!STRUCTURES.some(a=>x<a.x+a.w+12&&x+b.w+12>a.x&&y<a.y+a.h+12&&y+b.h+12>a.y)&&Math.abs(x)<640&&Math.abs(y)<640)out.push(b);}}return out;})();
export const WALLS=[
 ...[-720,720].flatMap(y=>[[-720,-62],[62,720]].map(([l,r])=>({x:l,y:y-13,w:r-l,h:26}))),
 ...[-720,720].flatMap(x=>[[-720,-62],[62,720]].map(([t,b])=>({x:x-13,y:t,w:26,h:b-t}))),
];
export const ROUTES=[
 [[0,0],[0,720],[-500,2800],[-1400,500]],
 [[-500,2800],[3600,4800],[8500,6500],[11300,-7200]],
 [[-500,2800],[-4100,5100],[-7400,1500],[-1400,500]],
 [[720,0],[3600,0],[6900,-3500],[11300,-7200],[12000,-8100]],
 [[0,-720],[0,-14000],[-360000,-180000]],
 [[6900,-3500],[8500,6500]],
];
export const STREAMS=[
 [[-12000,-3000],[-6600,-1700],[-3700,-650],[-1600,420],[-900,670],[-470,1060],[200,1660],[2150,3900],[6000,5750],[14000,12000]],
 [[-9500,12000],[-8100,7300],[-5600,4400],[-3700,2500],[-1600,420]],
];
export const RIVER_HALF_WIDTH=58;
const RIVER_CELL=20;
const riverCells=new Set();
const cellKey=(x,y)=>`${Math.round(x/RIVER_CELL)}:${Math.round(y/RIVER_CELL)}`;
function markDisc(set,x,y,r){const step=RIVER_CELL;for(let dx=-r;dx<=r;dx+=step)for(let dy=-r;dy<=r;dy+=step){if(dx*dx+dy*dy<=r*r)set.add(cellKey(x+dx,y+dy));}}
function clearDisc(set,x,y,r){const step=RIVER_CELL;for(let dx=-r;dx<=r;dx+=step)for(let dy=-r;dy<=r;dy+=step){if(dx*dx+dy*dy<=r*r)set.delete(cellKey(x+dx,y+dy));}}
for(const poly of STREAMS){for(let i=1;i<poly.length;i++){const[a,b]=[poly[i-1],poly[i]];const len=Math.hypot(b[0]-a[0],b[1]-a[1]);const steps=Math.max(1,Math.ceil(len/14));for(let s=0;s<=steps;s++){const t=s/steps;markDisc(riverCells,a[0]+(b[0]-a[0])*t,a[1]+(b[1]-a[1])*t,RIVER_HALF_WIDTH);}}}
/** 河流不可直接涉渡：只有桥梁或渡口所在的一段可以过河。 */
export function isRiver(p){return riverCells.has(cellKey(p.x,p.y));}
function segCross(p1,p2,p3,p4){const d=(p2.x-p1.x)*(p4.y-p3.y)-(p2.y-p1.y)*(p4.x-p3.x);if(Math.abs(d)<1e-9)return null;const u=((p3.x-p1.x)*(p4.y-p3.y)-(p3.y-p1.y)*(p4.x-p3.x))/d;const v=((p3.x-p1.x)*(p2.y-p1.y)-(p3.y-p1.y)*(p2.x-p1.x))/d;if(u<0||u>1||v<0||v>1)return null;return{x:p1.x+u*(p2.x-p1.x),y:p1.y+u*(p2.y-p1.y)};}
// 桥位由真实道路与河道的交点生成，不手画；渡口另作步行过河点。
export const BRIDGES=(()=>{const out=[];for(const road of ROUTES){for(let i=1;i<road.length;i++){const a={x:road[i-1][0],y:road[i-1][1]},b={x:road[i][0],y:road[i][1]};for(const poly of STREAMS){for(let j=1;j<poly.length;j++){const c={x:poly[j-1][0],y:poly[j-1][1]},d={x:poly[j][0],y:poly[j][1]};const hit=segCross(a,b,c,d);if(hit)out.push({x:Math.round(hit.x),y:Math.round(hit.y),name:'官道石桥'});}}}}
 const ferry=placeCoord('dukou');out.push({x:ferry.x,y:ferry.y,name:'西河渡口'});return out;})();
for(const b of BRIDGES)clearDisc(riverCells,b.x,b.y,105);
// 桥梁/渡口把河道切开，但桥梁半径之外的河面仍然阻挡。

export const dist=(a,b)=>Math.hypot(a.x-b.x,a.y-b.y);
const clamp=(x,l,h)=>Math.max(l,Math.min(h,x));
export const isCity=p=>Math.abs(p.x)<=740&&Math.abs(p.y)<=740;
const inRect=(p,b,pad=0)=>p.x>b.x-pad&&p.x<b.x+b.w+pad&&p.y>b.y-pad&&p.y<b.y+b.h+pad;
function crossRiver(p){const k=(p.x+9000)/3000;const streamY=-2000+1700*Math.sin(k*.45)+p.x*.18;return Math.abs(p.y-streamY)<32&&Math.abs(p.x)>1100;}
export function obstacleAt(p){if(!Number.isFinite(p.x)||!Number.isFinite(p.y))return '越界';if(Math.abs(p.x)>WORLD_LIMIT||Math.abs(p.y)>WORLD_LIMIT)return '世界边缘';
 if(STRUCTURES.some(b=>inRect(p,b,7))||TOWN_HOUSES.some(b=>inRect(p,b,4)))return '建筑墙体';if(WALLS.some(b=>inRect(p,b,6)))return '城墙';
 if(isRiver(p))return '河流';
 return null;
}
/** 城门洞是唯一可穿过城墙的通道；返回是否处于门洞内。 */
export function gateAt(p){return CITY.gates.find(g=>dist(p,g)<=52)||null;}
// 道路、桥梁、玩家均使用同一地图坐标；碰撞只允许走门洞（无穿墙）。
export function terrainHeight(x,y){const a=Math.sin(x/1250)*Math.cos(y/900),b=Math.sin((x+y)/2300),c=Math.cos(x/390+y/670);return Math.round(135+90*a+65*b+22*c);}
export function placeAt(p){let best={name:'郊野',id:'guanlu',d:Infinity};for(const l of LANDMARKS){if(!l.active||['room','shop','inn','office'].includes(l.type))continue;let d=dist(p,l);if(d<best.d)best={name:l.name,id:l.id,d};}return best;}
export function placeCoord(id){return PLACE_METERS[id]||{x:0,y:0};}
export function ensureGeo(w){if(!w.player.mapPos){const base=placeCoord(w.player.place);w.player.mapPos={x:base.x,y:base.y};if(w.player.place==='dongshi')w.player.mapPos={x:0,y:0};}
 if(!w.player.stats)w.player.stats={hp:100,maxHp:100,stamina:100,maxStamina:100,realm:'凡人',level:1};
 if(!Number.isFinite(w.player.mapPos.x)||!Number.isFinite(w.player.mapPos.y))w.player.mapPos={x:0,y:0};
 if(!w.mapActors)w.mapActors=makeActors(w);return w;
}
export function actorOrigin(p){if(p.home==='dongshi')return{x:170,y:10};if(p.home==='xijie')return{x:-385,y:70};if(p.home==='minju')return{x:55,y:400};if(p.home==='xianya')return{x:-350,y:-310};if(p.home==='songlin')return{x:6900,y:-3500};if(p.home==='qingyun')return{x:11300,y:-7200};if(p.home==='lingshan')return{x:12000,y:-8100};if(p.home==='shiqiao')return{x:3600,y:4800};if(p.home==='liantang')return{x:-4100,y:5100};if(p.home==='hewan')return{x:-7400,y:1500};if(p.home==='qingxi')return{x:8500,y:6500};return{x:0,y:0};}
export function makeActors(w){const selected=[];const count={};for(const p of w.people){if(p.status!=='alive')continue;const home=p.home;const allowed=['songlin','shiqiao','liantang','hewan','qingxi','dongshi','xijie','minju','xianya','qingyun','lingshan'];if(!allowed.includes(home))continue;
 const q=count[home]||0;if(q>=(['dongshi','xijie','minju','xianya'].includes(home)?5:8))continue;const s=deriveSeed(w.seed+p.id);const local=actorOrigin(p);
 let x=local.x+(s%180)-90,y=local.y+(Math.floor(s/233)%180)-90;
 if(isCity(local)&&obstacleAt({x,y})){x=25+(s%180);y=70+Math.floor(s/140)%160;}
 selected.push({id:p.id,x,y,homeX:x,homeY:y,targetX:x,targetY:y,speed:0.95+(s%60)/100,job:p.job,leader:false,state:'在家',cooldown:0});count[home]=q+1;
 }
 // 领导人物来自真实NPC表，而非另建一份影子人名录。
 const factions=[['县令','xianya',{x:-330,y:-345}],['巡检','xianya',{x:-340,y:-330}],['松林里正','songlin',{x:6900,y:-3500}],['青云宗执事','qingyun',{x:11300,y:-7200}]];
 for(const [role,home,point] of factions){const p=w.people.find(q=>q.status==='alive'&&q.home===home&&!selected.some(a=>a.id===q.id))||w.people.find(q=>q.status==='alive'&&q.home===home);if(!p)continue;const actor=selected.find(a=>a.id===p.id);if(actor){actor.leader=true;actor.title=role;}else selected.push({id:p.id,x:point.x,y:point.y,homeX:point.x,homeY:point.y,targetX:point.x,targetY:point.y,speed:1.1,job:p.job,leader:true,title:role,state:'巡视',cooldown:50});}
 return selected;
}
const peopleCaches=new WeakMap();
export function tickActors(w,elapsedWorldSeconds){ensureGeo(w);if(!peopleCaches.has(w))peopleCaches.set(w,new Map(w.people.map(p=>[p.id,p])));const people=peopleCaches.get(w);const step=Math.min(elapsedWorldSeconds,300);
 for(const a of w.mapActors){const p=people.get(a.id);if(!p||p.status!=='alive')continue;
 a.cooldown=(a.cooldown??0)-step;
 if(a.cooldown<=0){const base={x:a.homeX,y:a.homeY},h=w.hour,s=deriveSeed(w.seed+a.id+':'+w.day+':'+Math.floor(h*4));const active=h>=6&&h<20;
 if(active){let dx=((s%1001)-500)/5,dy=((Math.floor(s/201)%1001)-500)/5;
 const next={x:base.x+dx,y:base.y+dy};if(obstacleAt(next)){dx=-dx;dy=-dy;}a.targetX=base.x+dx;a.targetY=base.y+dy;a.state=a.leader?'巡察辖地':p.job==='农户'?'去田间劳作':p.job==='铁匠'?'去工坊':p.job==='商贩'?'赶集':'沿路行走';
 }else{a.targetX=a.homeX;a.targetY=a.homeY;a.state='归家';}
 a.cooldown=140+s%120;
 }
 const t={x:a.targetX,y:a.targetY}, d=dist(a,t);if(d>0){const travel=Math.min(d,a.speed*step);const n={x:a.x+(a.targetX-a.x)/d*travel,y:a.y+(a.targetY-a.y)/d*travel};if(!obstacleAt(n)){a.x=n.x;a.y=n.y;}else{a.targetX=a.x;a.targetY=a.y;a.cooldown=30;}}
 }
}
// A* 寻路只在局部细网格展开；长距离分割到公共道路上的里程碑，避免对整片天下逐米开数组。
function astar(start,goal,step=20,maxNodes=12500){const src={x:Math.round(start.x/step),y:Math.round(start.y/step)},dst={x:Math.round(goal.x/step),y:Math.round(goal.y/step)};
 // 精确的门口可能不落在20米整格上；先找与实体目标可直连的可通行栅格。
 // 末端的真实目标不在格点时，使用实际米制点验证最后一小段。
 const rawStart={x:start.x,y:start.y},rawGoal={x:goal.x,y:goal.y};
 const findSnap=(v,real)=>{const a={x:Math.round(v.x/step),y:Math.round(v.y/step)};let cand=null;for(let r=0;r<6;r++){for(let dx=-r;dx<=r;dx++)for(let dy=-r;dy<=r;dy++){if(Math.max(Math.abs(dx),Math.abs(dy))!==r)continue;let p={x:(a.x+dx)*step,y:(a.y+dy)*step};if(obstacleAt(p)||!segmentOK(p,real))continue;let d=dist(p,real);if(!cand||d<cand.d)cand={p:{x:a.x+dx,y:a.y+dy},d};}if(cand)return cand.p;}return a;};
 Object.assign(src,findSnap(start,rawStart));Object.assign(dst,findSnap(goal,rawGoal));
 const key=(p)=>p.x+','+p.y;const sk=key(src),dk=key(dst), queue=[{...src,g:0,f:dist(src,dst)}],seen=new Map([[sk,0]]),back=new Map(),done=new Set();let loop=0;
 while(queue.length&&loop++<maxNodes){let best=0;for(let i=1;i<queue.length;i++)if(queue[i].f<queue[best].f)best=i;const a=queue.splice(best,1)[0],id=key(a);if(done.has(id))continue;done.add(id);if(id===dk){let path=[];for(let k=id;k;){const[t,u]=k.split(',').map(Number);path.push({x:t*step,y:u*step});k=back.get(k);}path.reverse();return path;}
 for(const[dx,dy]of [[1,0],[-1,0],[0,1],[0,-1],[1,1],[1,-1],[-1,1],[-1,-1]]){const b={x:a.x+dx,y:a.y+dy}, k=key(b),meter={x:b.x*step,y:b.y*step};if(done.has(k)||obstacleAt(meter))continue;
 if(dx&&dy&&(obstacleAt({x:b.x*step,y:a.y*step})||obstacleAt({x:a.x*step,y:b.y*step})))continue;
 const g=a.g+Math.hypot(dx,dy),old=seen.get(k);if(old===undefined||g<old){seen.set(k,g);back.set(k,id);queue.push({...b,g,f:g+dist(b,dst)});}}
 }return null;
}
function segmentOK(a,b){const d=dist(a,b);for(let u=0;u<=d;u+=Math.min(10,d/5||1)){const t=d?u/d:1,p={x:a.x+(b.x-a.x)*t,y:a.y+(b.y-a.y)*t};if(obstacleAt(p))return false;}return !obstacleAt(b);}
function simplify(points){const ans=[points[0]];for(let i=1;i<points.length;){let j=points.length-1;for(;j>i;j--)if(segmentOK(points[i-1],points[j]))break;ans.push(points[j]);i=j+1;}return ans;}
export function localPath(a,b){if(obstacleAt(b))return {ok:false,error:`目的地被${obstacleAt(b)}阻挡，请选择道路或入口。`};if(dist(a,b)<2)return {ok:true,path:[a,b],meters:0};if(segmentOK(a,b))return {ok:true,path:[a,b],meters:dist(a,b)};
 const points=astar(a,b,20);if(!points)return {ok:false,error:'道路不通，可能被城墙或建筑阻挡；请从城门或建筑大门通过。'};const joined=[a,...points.slice(1,-1),b];const path=simplify(joined);
 return {ok:true,path,meters:path.reduce((n,p,i)=>i?n+dist(p,path[i-1]):0,0)};
}
const pathGraph=()=>{let nodes=[];let index=new Map(), edges=new Map();const id=p=>`${Math.round(p[0])}:${Math.round(p[1])}`;for(const poly of ROUTES){for(let i=0;i<poly.length;i++){const point=poly[i],k=id(point);if(!index.has(k)){index.set(k,nodes.length);nodes.push({x:point[0],y:point[1]});edges.set(index.get(k),[]);}if(i){const a=index.get(id(poly[i-1])),b=index.get(k),cost=dist(nodes[a],nodes[b]);edges.get(a).push({node:b,cost});edges.get(b).push({node:a,cost});}}}return{nodes,edges};};
const GRAPH=pathGraph();
function dijkstra(startIndex,endIndex){let q=[{n:startIndex,d:0}],cost=new Map([[startIndex,0]]),parent=new Map();while(q.length){q.sort((a,b)=>a.d-b.d);const a=q.shift();if(a.n===endIndex)break;if(a.d!==cost.get(a.n))continue;for(const e of GRAPH.edges.get(a.n)||[]){const nd=a.d+e.cost;if(nd<(cost.get(e.node)??Infinity)){cost.set(e.node,nd);parent.set(e.node,a.n);q.push({n:e.node,d:nd});}}}if(!cost.has(endIndex))return null;const result=[];for(let k=endIndex;k!==undefined;k=parent.get(k))result.unshift(GRAPH.nodes[k]);return result;}
export function journeyPath(a,b){if(dist(a,b)<1550)return localPath(a,b);const {nodes}=GRAPH;const nearest=p=>nodes.map((v,i)=>({i,d:dist(p,v)})).sort((x,y)=>x.d-y.d).slice(0,5);
 let best=null;
 for(const u of nearest(a))for(const v of nearest(b)){const mid=dijkstra(u.i,v.i);if(!mid)continue;const route=[a,...mid,b];const cost=route.reduce((n,p,i)=>i?n+dist(p,route[i-1]):0,0);if(!best||cost<best.cost)best={path:route,cost};}
 if(!best)return {ok:false,error:'道路网络尚未连通'};
 // 近端路径要能从城门走，不能以一条线穿墙；允许分段为局部A*。
 let path=[a];for(let i=1;i<best.path.length;i++){let x=best.path[i-1],y=best.path[i];const d=dist(x,y);if(d<1700){const seg=localPath(x,y);if(!seg.ok)return seg;path.push(...seg.path.slice(1));}else{if(!segmentOK(x,y)&& (isCity(x)||isCity(y)))return {ok:false,error:'需要通过城门或山道绕行，尚无安全路径'};path.push(y);}}
 return {ok:true,path,meters:path.reduce((n,p,i)=>i?n+dist(p,path[i-1]):0,0)};
}
export function beginJourney(w,goal,selectionId=null){ensureGeo(w);if(w.player.route)return {ok:false,error:'正在行走，先取消现有路线'};
 const start={...w.player.mapPos};const target={x:goal.x,y:goal.y};const p=journeyPath(start,target);if(!p.ok)return p;
 const arr=p.path.map(pt=>({...pt}));w.player.route={path:arr,index:0,progress:0,total:p.meters,covered:0,goal:target,selectionId};return{ok:true,meters:p.meters};
}
/** 御剑：直线飞行，无视地面障碍但有灵力成本；落点必须是可站立的地面。 */
export function beginFlight(w,goal,selectionId=null){ensureGeo(w);if(w.player.route)return{ok:false,error:'正在行走，先取消现有路线'};
 const gate=canFly(w);if(!gate.ok)return gate;
 if(obstacleAt(goal))return{ok:false,error:`落点无法落脚：${obstacleAt(goal)}`};
 const dest=flightRuleAt(w,goal);if(!dest.ok)return{ok:false,error:dest.reason};
 const crossed=flightBlockedBetween(w,w.player.mapPos,goal);if(crossed)return{ok:false,error:crossed.reason};
 const start={...w.player.mapPos},meters=dist(start,goal);const cost=meters*.005;
 if((w.player.spirit??0)<cost)return{ok:false,error:`灵力不足：此程需 ${Math.ceil(cost)} 点，现有 ${Math.floor(w.player.spirit??0)} 点。`};
 w.player.spirit=Math.max(0,(w.player.spirit??0)-cost);
 w.player.route={path:[start,{x:goal.x,y:goal.y}],index:0,progress:0,total:meters,covered:0,goal:{x:goal.x,y:goal.y},selectionId,fly:true,seen:[]};
 return{ok:true,meters};
}
export function stopJourney(w){ensureGeo(w);if(!w.player.route)return false;delete w.player.route;return true;}
/** 体力参与速度，但不会凭空瞬移：走不动就只能慢走，时间照常流逝。 */
export function walkSpeedFactor(w){const s=w.player.stats?.stamina??100;if(s<=0)return .6;if(s<20)return .8;return 1;}
export function staminaCost(meters){return meters/9;}
export function advanceMap(w,realSeconds,speed=30){ensureGeo(w);let dt=clamp(realSeconds,0,.12);const worldSeconds=dt*speed;
 if(worldSeconds<=0)return{moved:0};advanceClock(w,worldSeconds/60);tickActors(w,worldSeconds);
 let moved=0,done=false;const encounters=[];const r=w.player.route;
 if(r){const gain=r.fly?1.45*7.5:1.45*walkSpeedFactor(w);let remaining=worldSeconds*gain;while(remaining>0&&r.index<r.path.length-1){let a=r.path[r.index],b=r.path[r.index+1],length=dist(a,b),left=length-r.progress,step=Math.min(remaining,left);r.progress+=step;r.covered+=step;remaining-=step;moved+=step;
 const t=length?Math.min(1,r.progress/length):1;w.player.mapPos={x:a.x+(b.x-a.x)*t,y:a.y+(b.y-a.y)*t};
 if(left-step<.001){r.index++;r.progress=0;}}
 // 途中真实遇见仍在街上的人：不生成假人物，只读取世界已有的活动者。空中不记录地面相遇。
 if(!r.fly){r.seen=r.seen||[];
 for(const a of w.mapActors){if(r.seen.includes(a.id))continue;if(dist(a,w.player.mapPos)>24)continue;const p=w.people.find(q=>q.id===a.id);if(!p||p.status!=='alive')continue;const vis=actorVisibility(w,p);if(!vis.visible)continue;
  r.seen.push(a.id);encounters.push({id:a.id,name:p.name,state:vis.reason});note(w,'相遇',`路上遇见${p.name}（${p.job}·${vis.reason}）。`,{npc:p.id});}}
 if(!r.fly)w.player.stats.stamina=Math.max(0,(w.player.stats.stamina??100)-staminaCost(moved));
 if(r.index>=r.path.length-1){w.player.mapPos={...r.goal};delete w.player.route;done=true;w.player.place=placeAt(w.player.mapPos).id;note(w,'行旅',`到达${selectionIdName(r.selectionId)||'目的地'}；实际行走${r.total.toFixed(0)}米。`,{meters:r.total});}
 }else{w.player.stats.stamina=Math.min(w.player.stats.maxStamina,(w.player.stats.stamina??100)+worldSeconds*.22);}
 return{moved,done,position:{...w.player.mapPos},encounters};
}
/** 原地歇息：只恢复体力，世界时间照常流动。 */
export function rest(w,minutes=30){if(w.player.route)return{ok:false,error:'行走中无法歇息'};advanceClock(w,minutes);const st=w.player.stats;st.stamina=Math.min(st.maxStamina,st.stamina+minutes*.5);st.hp=Math.min(st.maxHp,st.hp+Math.min(6,minutes*.05));note(w,'歇息',`你在原地歇了${minutes}分钟，体力恢复。`,{minutes});return{ok:true,minutes};}
function selectionIdName(id){return LANDMARKS.find(x=>x.id===id)?.name||STRUCTURES.find(x=>x.id===id)?.name||'';}

/* ---------- 权限：能力由规则判定，界面只负责显示结果 ---------- */
export const PERMISSIONS={
 xianya_hou:{roles:['县吏'],reason:'内署是掌印签押处，只有本县吏员可入。'},
 lingshan_yaopu:{roles:['修士'],reason:'药圃属外门禁地，需有修士名籍。'},
 kezhan_chamber:{roles:['平民','县吏','修士'],reason:'客房需先向掌柜付钱开房。',requires:'inn-stay'},
};
export const REALM_NAMES={1:'凡人',2:'炼气二层',3:'炼气五层',4:'筑基初期',5:'筑基后期',6:'金丹'};
export function isGuard(w){return (w.player.titles||[]).includes('御城军')||w.player.faction==='guard';}
/** 空域规则：野地不限；修仙城池唯御城军可飞；世俗城池按实力（筑基以上）放行。 */
export function flightRuleAt(w,p){
 const c=cityAt(p);
 if(!c)return{ok:true,zone:'野外空域'};
 if(c.kind==='cultivation'&&!isGuard(w))return{ok:false,zone:c.name,reason:`${c.name}为修仙城池，城内上空禁飞；唯御城军可御剑巡城。`};
 const level=w.player.stats?.level??1;
 if(c.kind==='mortal'&&level<4)return{ok:false,zone:c.name,reason:`${c.name}是世俗城池，不设明令禁飞，但${REALM_NAMES[level]||'凡人'}的实力压不住城隍阵，需筑基以上。`};
 return{ok:true,zone:c.name};
}
function segmentHitsCity(a,b,c){
 const vx=b.x-a.x,vy=b.y-a.y,len2=vx*vx+vy*vy||1;
 let t=((c.x-a.x)*vx+(c.y-a.y)*vy)/len2;t=Math.max(0,Math.min(1,t));
 const px=a.x+vx*t,py=a.y+vy*t;
 return Math.hypot(px-c.x,py-c.y)<=c.half*1.42;
}
export function flightBlockedBetween(w,a,b){
 for(const c of CITIES){if(!segmentHitsCity(a,b,c))continue;const probe={x:c.x,y:c.y};const r=flightRuleAt(w,probe);if(!r.ok)return r;}
 return null;
}
export function canFly(w){const p=w.player;if(p.role!=='修士')return{ok:false,reason:'平民没有御剑之能，需拜师并筑基后方可飞行。'};
 if((p.stats?.level??1)<2)return{ok:false,reason:'境界不足：御剑需炼气二层以上。'};
 if((p.spirit??0)<12)return{ok:false,reason:'灵力不足，无法御剑。'};
 if(p.indoor)return{ok:false,reason:'室内不能起剑，请先出门。'};
 const here=flightRuleAt(w,p.mapPos||{x:0,y:0});if(!here.ok)return{ok:false,reason:here.reason};
 return{ok:true};}
export function canEnter(w,placeId){const rule=PERMISSIONS[placeId];if(!rule)return{ok:true};
 if(rule.roles.includes(w.player.role))return{ok:true};
 return{ok:false,reason:rule.reason};}
/** 营业/开放状态来自场所类型与当前时刻，不靠 UI 假装。 */
export function openingStatus(placeId,hour){
 const p=getPlace(placeId);if(!p)return{open:false,label:'未知'};
 const t=p.type;
 if(['room'].includes(t))return{open:true,label:'可入（需房门钥匙或房客身份）'};
 if(t==='shop')return hour>=8&&hour<18?{open:true,label:'营业 08:00–18:00'}:{open:false,label:'已打烊（营业 08:00–18:00）'};
 if(t==='office')return hour>=7&&hour<18?{open:true,label:'办公 07:00–18:00'}:{open:false,label:'已下值（办公 07:00–18:00）'};
 if(t==='inn')return{open:true,label:'通宵营业，前堂有人值守'};
 if(t==='market')return hour>=6&&hour<20?{open:true,label:'集市 06:00–20:00'}:{open:false,label:'夜市散尽（集市 06:00–20:00）'};
 if(t==='gate')return{open:true,label:'城门全天有差役把守'};
 if(t==='sect')return{open:true,label:'山门有执事守门'};
 return{open:true,label:'可通行'};
}
/* ---------- 人物呈现：显示的位置必须等于世界认定其所在的位置 ---------- */
const OUTDOOR_TYPES=new Set(['market','street','homes','gate','road','village','port','sect','office','shop','inn']);
export function actorVisibility(w,p){
 if(!p||p.status!=='alive')return{visible:false,where:null,reason:'不在世'};
 const where=apparentLocation(w,p);if(!where)return{visible:false,where:null,reason:'不可见'};
 const place=getPlace(where);if(!place)return{visible:false,where,reason:'地点未知'};
 const night=w.hour<6||w.hour>=21;
 if(night)return p.job==='捕快'?{visible:true,where,reason:'巡夜'}:{visible:false,where,reason:'在家休息'};
 if(!OUTDOOR_TYPES.has(place.type))return{visible:false,where,reason:'在室内'};
 if(p.job==='修士'||p.job==='宗门杂役')return{visible:where==='qingyun',where,reason:npcActivity(w,p)};
 return{visible:true,where,reason:npcActivity(w,p)};
}
export function visibleActors(w,limit=999){ensureGeo(w);const out=[];
 for(const a of w.mapActors){const p=w.people.find(q=>q.id===a.id);const v=actorVisibility(w,p);if(v.visible)out.push({...a,where:v.where,state:v.reason});if(out.length>=limit)break;}
 return out;}
export function enterStructure(w,id){ensureGeo(w);const b=STRUCTURES.find(q=>q.id===id);if(!b)return{ok:false,error:'此建筑目前不能进入'};
 const perm=canEnter(w,id);if(!perm.ok)return{ok:false,error:perm.reason};
 if(dist(w.player.mapPos,b.door)>35)return{ok:false,error:'请先走到门前（距离小于35米）'};
 if(!getPlace(id))return{ok:false,error:'此建筑内部尚未开放'};
 const gate=openingStatus(id,w.hour);if(!gate.open)return{ok:false,error:gate.label};
 w.player.indoor=id;w.player.place=id;note(w,'场景',`你从${b.name}正门进入。`);return{ok:true};
}
export function exitStructure(w){ensureGeo(w);let b=STRUCTURES.find(q=>q.id===w.player.indoor);if(!b)return{ok:false,error:'你现在不在可出入的建筑内'};w.player.mapPos={...b.door};delete w.player.indoor;w.player.place=placeAt(w.player.mapPos).id;return{ok:true};}
export function isMarkerAccessible(l){return !!l.active;}
export {apparentLocation,npcActivity};
