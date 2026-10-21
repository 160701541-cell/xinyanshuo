/** 《仙凡共生》v0.4：可通行道路图与地图空间。以真实格点而非标签模拟步行。 */
import {note, advanceClock, getPlace, navigate, linked, shortestRoute, apparentLocation, npcActivity, deriveSeed} from './core.js';
export const STREET_LIMITS={x0:250,y0:240,x1:735,y1:790};
export const R_VERTICAL=[280,340,390,480,530,570,690];
export const R_HORIZONTAL=[270,370,430,490,550,610,740];
const GRID=10;
const V=new Set(R_VERTICAL),H=new Set(R_HORIZONTAL);
const inLimit=(x,y)=>x>=250&&x<=730&&y>=240&&y<=790;
export const streetWalkable=(x,y)=>inLimit(x,y)&&x%GRID===0&&y%GRID===0&&(V.has(x)||H.has(y));
const key=(x,y)=>`${x}:${y}`;
export const BUILDINGS=[
 {id:'kezhan',name:'望江客栈',x:404,y:388,w:59,h:64,door:[480,430],theme:'inn'},
 {id:'tiepu',name:'陈记铁铺',x:406,y:498,w:59,h:70,door:[480,550],theme:'smith'},
 {id:'lianghang',name:'福源粮行',x:591,y:508,w:82,h:82,door:[570,550],theme:'grain'},
 {id:'xianya',name:'临安县衙',x:590,y:290,w:83,h:59,door:[570,370],theme:'office'},
];
export const ROADS=[
 ...R_VERTICAL.map(x=>({x1:x,y1:240,x2:x,y2:790,name:'南北街巷'})),
 ...R_HORIZONTAL.map(y=>({x1:250,y1:y,x2:730,y2:y,name:'东西街巷'})),
];
export const YARDS=[
 {name:'永和药铺',x:293,y:393,w:39,h:59},
 {name:'沈家宅院',x:409,y:295,w:49,h:50},
 {name:'张氏布庄',x:594,y:394,w:60,h:66},
 {name:'茶肆',x:293,y:518,w:36,h:63},
 {name:'旧书院',x:587,y:628,w:79,h:68},
 {name:'市井院落',x:412,y:635,w:48,h:60},
 {name:'民居',x:299,y:640,w:31,h:65},
];
export function getRoadPosition(w){const p=w.player.roadPos;return p&&streetWalkable(p.x,p.y)?p:{x:480,y:490};}
export function nearestRoad(x,y){let best=null,score=Infinity;for(const x0 of R_VERTICAL){const xx=x0,yy=Math.max(240,Math.min(790,Math.round(y/GRID)*GRID));const d=Math.hypot(x-xx,y-yy);if(d<score){best={x:xx,y:yy};score=d;}}
 for(const y0 of R_HORIZONTAL){const yy=y0,xx=Math.max(250,Math.min(730,Math.round(x/GRID)*GRID));const d=Math.hypot(x-xx,y-yy);if(d<score){best={x:xx,y:yy};score=d;}}
 return best;
}
export function roadPath(start,end){const a=nearestRoad(start.x,start.y),b=nearestRoad(end.x,end.y);const from=key(a.x,a.y),to=key(b.x,b.y);if(from===to)return [a];const queue=[a],visited=new Set([from]),parent=new Map();let found=false;
 for(let head=0;head<queue.length;head++) {const p=queue[head],k=key(p.x,p.y);if(k===to){found=true;break;}
 for(const [dx,dy] of [[10,0],[-10,0],[0,10],[0,-10]]){const x=p.x+dx,y=p.y+dy,j=key(x,y);if(!visited.has(j)&&streetWalkable(x,y)){visited.add(j);parent.set(j,k);queue.push({x,y});}}
 }if(!found)return null;const out=[];for(let cur=to;cur;cur=parent.get(cur)){const [x,y]=cur.split(':').map(Number);out.push({x,y});if(cur===from)break;}return out.reverse();}
export function districtFor(p){if(p.x<385)return 'xijie';if(p.y>610)return 'minju';return 'dongshi';}
export function walkRoad(w,target){if(!['dongshi','xijie','minju','xianya','nanmen'].includes(w.player.place))return {ok:false,error:'请先离开建筑或回到临安县城。'};
 const start=getRoadPosition(w),end=nearestRoad(target.x,target.y),path=roadPath(start,end);if(!path)return {ok:false,error:'当前位置与目标道路尚未连通'};
 const distance=(path.length-1)*10,minutes=Math.max(0,Math.ceil(distance/65));
 if(minutes)advanceClock(w,minutes);w.player.roadPos=end;w.player.place=districtFor(end);
 if(path.length>1)note(w,'街巷行走',`你沿街走过 ${distance} 步距，抵达${getPlace(w.player.place)?.name||'县城'}，用时${minutes}分钟。`,{from:start,to:end,minutes});
 return {ok:true,path,minutes,description:path.length>1?`沿道路走了${distance}步距，用时${minutes}分钟。`:'你已站在这段道路上。'};
}
export function enterStreetBuilding(w,id){const b=BUILDINGS.find(x=>x.id===id);if(!b)return {ok:false,error:'建筑入口尚未开放'};
 if(!['dongshi','xijie','minju','xianya','nanmen'].includes(w.player.place))return {ok:false,error:'请先离开当前建筑'};
 const walked=walkRoad(w,{x:b.door[0],y:b.door[1]});if(!walked.ok)return walked;
 const indoors=navigate(w,id,'foot');if(!indoors.ok)return indoors;
 w.player.roadPos={x:b.door[0],y:b.door[1]};return {ok:true,description:`沿街走到${b.name}门前，推门进入。`,path:walked.path};
}
function shortestRouteSafe(a,b){return shortestRoute(a,b);}
export function exitStreetBuilding(w){const candidates=BUILDINGS.map(b=>({b,route:(w.player.place===b.id?[b.id]:null)}));
 for(const c of candidates)if(!c.route){c.route=shortestRouteSafe(w.player.place,c.b.id);}
 const selected=candidates.filter(c=>c.route&&c.route.every(id=>id===c.b.id||['room','shop','inn'].includes(getPlace(id)?.type))).sort((a,b)=>a.route.length-b.route.length)[0];
 const b=selected?.b;
 if(!b)return {ok:false,error:'找不到通往街道的出口'};
 const indoors=navigate(w,b.id,'foot');if(!indoors.ok)return indoors;
 const out=navigate(w,'dongshi','foot');if(!out.ok)return out;
 w.player.roadPos={x:b.door[0],y:b.door[1]};w.player.place=districtFor(w.player.roadPos);return {ok:true,description:`你从${b.name}走回街道。`};
}
// 街头只呈现确实处于开放空间且执行户外行为的人；睡觉中的居民不会被显示在路上。
export function isOutdoorWorking(w,p){const h=w.hour;if(p.status!=='alive')return false;
 if(p.job==='捕快')return h>=7&&h<20||((h<5||h>=21)&&deriveSeed(p.id)%15===0);
 if(p.job==='商贩')return h>=7&&h<19;
 if(p.job==='脚夫')return h>=6&&h<20;
 if(p.job==='船工')return h>=6&&h<18;
 return false;
}
export function outdoorActors(w,limit=12){let active=[];if(w.hour<5||w.hour>=21)limit=Math.min(limit,2);const i=(w.day*43+Math.floor(w.hour)*61)%w.people.length;
 for(let j=0;j<w.people.length&&active.length<limit;j++){const p=w.people[(i+j)%w.people.length];if(!isOutdoorWorking(w,p))continue;const loc=apparentLocation(w,p);if(loc!=='dongshi'&&loc!=='xijie'&&loc!=='dukou'&&p.job!=='捕快')continue;
 const options=[{x:390,y:430},{x:480,y:410},{x:570,y:490},{x:390,y:490},{x:480,y:550},{x:530,y:610},{x:570,y:550},{x:690,y:430},{x:390,y:610},{x:480,y:740},{x:570,y:370},{x:530,y:430}];
 const slot=(deriveSeed(p.id+'#'+Math.floor(w.hour/2))+Math.floor(w.day/3))%options.length;
 if(active.some(a=>Math.hypot(a.x-options[slot].x,a.y-options[slot].y)<16))continue;
 const action=p.job==='捕快'?(w.hour>=20||w.hour<5?'值夜巡更':'巡街查访'):p.job==='商贩'?'沿街叫卖':p.job==='脚夫'?'挑担赶路':'运货过街';
 active.push({person:p,...options[slot],action});}
 return active;
}

/** 室内入口与道路相接，不再让常规navigate()给已走到门口的人二次计算八分钟旅行。 */
function passBuildingDoor(w,building){
  if(!linked(w.player.place,building.id))return {ok:false,error:'建筑入口与此街巷不连通'};
  advanceClock(w,.5);w.player.place=building.id;
  note(w,'场景',`你经过${building.name}门口，推门进入内堂。`,{building:building.id});
  return {ok:true,arrived:true,buildingId:building.id};
}
/** v0.5 逐帧行程：世界时钟随位移持续前进，而非点击后一次性结算。 */
export function beginRoadJourney(w,target,opts={}){
 if (!['dongshi','xijie','minju','xianya','nanmen'].includes(w.player.place))return {ok:false,error:'当前不在街道；请先出门。'};
 if (w.player.journey)return {ok:false,error:'正在移动，请先停止现有行程。'};
 let building=null,destination=target;
 if (opts.buildingId){building=BUILDINGS.find(b=>b.id===opts.buildingId);if(!building)return {ok:false,error:'找不到该建筑入口'};destination={x:building.door[0],y:building.door[1]};}
 const start=getRoadPosition(w),end=nearestRoad(destination.x,destination.y),path=roadPath(start,end);
 if (!path)return {ok:false,error:'此路尚未连通'};
 if (path.length===1){if(building){return passBuildingDoor(w,building);}return {ok:true,arrived:true};}
 const distance=(path.length-1)*10;
 // 步行约每65地图单位/游戏分钟，演示加速映射：约每秒走72单位。
 const durationSeconds=Math.max(0.35,distance/72);
 w.player.journey={path,elapsedSeconds:0,durationSeconds,worldMinutes:distance/65,from:start,to:end,buildingId:building?.id||null};
 return {ok:true,arrived:false,distance,durationSeconds,worldMinutes:distance/65};
}
export function visualRoadPosition(w){const j=w.player.journey;if(!j)return getRoadPosition(w);
 const rate=Math.max(0,Math.min(1,j.elapsedSeconds/j.durationSeconds)),offset=rate*(j.path.length-1),i=Math.min(j.path.length-2,Math.floor(offset)),t=offset-i;
 const a=j.path[i],b=j.path[i+1];return {x:a.x+(b.x-a.x)*t,y:a.y+(b.y-a.y)*t};
}
export function tickRoadJourney(w,seconds){const j=w.player.journey;
 if(!j)return {ok:false,error:'没有正在进行的行程'};
 if(!Number.isFinite(seconds)||seconds<0)throw new Error('时间增量必须非负且有限');
 const dt=Math.min(seconds,Math.max(0,j.durationSeconds-j.elapsedSeconds));
 if(dt<=0)return {ok:true,arrived:false,position:visualRoadPosition(w)};
 j.elapsedSeconds+=dt;
 advanceClock(w,j.worldMinutes*dt/j.durationSeconds);
 const pos=visualRoadPosition(w);
 // 每跨过一个格点，就保存真实已走到的格点。不会提前传送至终点。
 const index=Math.floor((j.elapsedSeconds/j.durationSeconds)*(j.path.length-1));
 w.player.roadPos={...j.path[index]};
 if(j.elapsedSeconds+1e-7<j.durationSeconds)return {ok:true,arrived:false,position:pos,progress:j.elapsedSeconds/j.durationSeconds};
 w.player.roadPos={...j.to};w.player.place=districtFor(j.to);delete w.player.journey;
 note(w,'行旅',`沿道路行走 ${(j.path.length-1)*10} 地图单位，实际历时 ${j.worldMinutes.toFixed(1)} 分钟。`,{from:j.from,to:j.to,minutes:j.worldMinutes});
 if(j.buildingId){const building=BUILDINGS.find(b=>b.id===j.buildingId);const result=passBuildingDoor(w,building);if(!result.ok)return {ok:false,arrived:true,error:result.error};}
 return {ok:true,arrived:true,buildingId:j.buildingId,position:{...j.to},progress:1};
}
export function cancelRoadJourney(w){const j=w.player.journey;if(!j)return false;
 w.player.roadPos=nearestRoad(visualRoadPosition(w).x,visualRoadPosition(w).y);
 w.player.place=districtFor(w.player.roadPos);delete w.player.journey;
 note(w,'行旅','你在途中停下脚步，行程已消耗的时间不会退回。');return true;
}
/** 地图景物的行为必须与当前世界时间/地点一致，不将居家NPC画在街道。 */
export function occupantsAt(w,placeId,limit=5){const out=[];for(const p of w.people){if(p.status!=='alive'||apparentLocation(w,p)!==placeId)continue;
 if(['tiepu','lianghang','xianya','kezhan'].includes(placeId)){
   const jobs={tiepu:['铁匠','木匠'],lianghang:['粮行伙计','账房'],xianya:['县吏','捕快'],kezhan:['厨娘','商贩']};
   if(!jobs[placeId].includes(p.job)||w.hour<6||w.hour>=20)continue;
 }
 out.push(p);if(out.length>=limit)break;}return out;
}

/** 县域跨村镇/御剑旅程：同一世界时钟在每次动画帧内推进。 */
export function beginRegionJourney(w,target,mode='foot'){
 if(w.player.journey||w.player.regionJourney)return {ok:false,error:'请先停止当前行程'};
 const from=getPlace(w.player.place),to=getPlace(target);
 if(!from||!to)return {ok:false,error:'未知位置'};
 if(['room','shop','inn'].includes(from.type)||['room','shop','inn'].includes(to.type))return {ok:false,error:'区域旅行请先离开建筑，前往城门或官道'};
 if(mode==='sword'&&w.player.role!=='修士')return {ok:false,error:'御剑需要修士身份'};
 const route=mode==='sword'?[from.id,to.id]:shortestRoute(from.id,to.id);
 if(!route)return {ok:false,error:'官道尚未连通'};
 if(route.length<=1)return {ok:true,arrived:true};
 let minutes=0;const legs=[];
 for(let i=1;i<route.length;i++){
   const a=getPlace(route[i-1]),b=getPlace(route[i]);
   let d=Math.max(1,Math.hypot(a.x-b.x,a.y-b.y));
   let m=mode==='sword'?Math.max(2,d*.6):Math.max(4,d*7);
   legs.push({from:a.id,to:b.id,start:minutes,end:minutes+m});minutes+=m;
 }
 const spirit=mode==='sword'?Math.ceil(minutes/9):0;
 if(spirit>w.player.spirit)return {ok:false,error:'灵力不足'};
 const durationSeconds=Math.max(1,Math.min(15,minutes/95));
 w.player.regionJourney={route,mode,legs,minutes,spirit,charged:0,elapsedSeconds:0,durationSeconds,target};
 return {ok:true,arrived:false,minutes,durationSeconds};
}
export function regionJourneyPosition(w){const j=w.player.regionJourney;if(!j){const p=getPlace(w.player.place);return p?{x:p.x*10,y:p.y*10}:null;}
 const elapsed=j.minutes*Math.min(1,j.elapsedSeconds/j.durationSeconds);
 const leg=j.legs.find(l=>elapsed<=l.end)||j.legs.at(-1);
 const a=getPlace(leg.from),b=getPlace(leg.to),f=Math.max(0,Math.min(1,(elapsed-leg.start)/(leg.end-leg.start)));
 return {x:(a.x+(b.x-a.x)*f)*10,y:(a.y+(b.y-a.y)*f)*10};
}
export function tickRegionJourney(w,seconds){const j=w.player.regionJourney;if(!j)return {ok:false,error:'没有县域旅程'};
 if(!Number.isFinite(seconds)||seconds<0)throw new Error('时间增量非法');
 const dt=Math.min(seconds,Math.max(0,j.durationSeconds-j.elapsedSeconds));
 if(dt<=0)return {ok:true,arrived:false,position:regionJourneyPosition(w)};
 j.elapsedSeconds+=dt;advanceClock(w,j.minutes*dt/j.durationSeconds);
 // 灵力随飞行进程消耗，中止旅程已消耗部分不返还。
 const spent=Math.floor(j.spirit*j.elapsedSeconds/j.durationSeconds);
 w.player.spirit-=Math.max(0,spent-j.charged);j.charged=spent;
 const position=regionJourneyPosition(w);
 if(j.elapsedSeconds+1e-7<j.durationSeconds)return {ok:true,arrived:false,progress:j.elapsedSeconds/j.durationSeconds,position};
 w.player.place=j.target;delete w.player.regionJourney;
 note(w,'行旅',`${j.mode==='sword'?'御剑':'沿官道'}到达${getPlace(j.target).name}，沿途经过${j.route.length-2}处，游戏时间流逝${j.minutes.toFixed(1)}分钟。`);
 return {ok:true,arrived:true,position,progress:1};
}
export function cancelRegionJourney(w){const j=w.player.regionJourney;if(!j)return false;
 const spentM=j.minutes*j.elapsedSeconds/j.durationSeconds;
 let reached=j.route[0];for(const leg of j.legs)if(spentM>=leg.end)reached=leg.to;
 w.player.place=reached;delete w.player.regionJourney;
 note(w,'行旅',`途中停下，停留在${getPlace(reached).name}，已流逝的时间与消耗不可返还。`);return true;
}
