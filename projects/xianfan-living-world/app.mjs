import {VERSION,PLACES,createWorld,getPlace,sceneActors,npcActivity,scenery,worldReport,simulateDay,navigate,travel,changeRole,buyGrain,relief,greet,saveableWorld,restoreWorld,isInterior,shortestRoute} from './core.mjs';
import {BUILDINGS,YARDS,ROADS,nearestRoad,getRoadPosition,walkRoad,enterStreetBuilding,exitStreetBuilding,outdoorActors,roadPath,occupantsAt,beginRoadJourney,tickRoadJourney,visualRoadPosition,cancelRoadJourney,beginRegionJourney,tickRegionJourney,regionJourneyPosition,cancelRegionJourney} from './spatial.mjs';
import {streetAtlas,countyAtlas,provinceAtlas,worldAtlas,interiorAtlas} from './atlas.mjs';
const $=x=>document.getElementById(x),safe=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const fmt=n=>Math.round(n).toLocaleString('zh-CN'),MONTHS=['正月','二月','三月','四月','五月','六月','七月','八月','九月','十月','冬月','腊月'];
const label=x=>x.replace(/^临安县·/,'').replace(/^青云山·/,'').replace(/^望江客栈·/,'');
let world,tab='scene',scope='street',mode='foot',selection=null,panning=false,tempWorld=false, saveTimer=0,toastTimer=0,lastPath=[],inspectMap=false,animationStamp=0,playerDrawOrigin=null;
const moving=()=>!!(world?.player.journey||world?.player.regionJourney);
const showInterior=()=>indoors()&&!inspectMap;
const LEVELS=['world','province','county','street'];
const names={world:'天下',province:'青州',county:'临安县',street:'街巷'};
const extent={world:5200,province:2800,county:1150,street:570};
const cameras={street:{x:480,y:500},county:{x:500,y:500},province:{x:500,y:500},world:{x:500,y:500}};
const isBuilding=id=>BUILDINGS.some(b=>b.id===id);
const indoors=()=>isInterior(getPlace(world.player.place))||isBuilding(world.player.place)||world.player.place==='kezhan2';
const isCity=id=>['dongshi','xijie','minju','xianya','nanmen'].includes(id);
const dateLabel=()=>{const d=world.day-1;return `承平${Math.floor(d/360)+3}年 · ${MONTHS[Math.floor((d%360)/30)]}${d%30+1}日 · ${String(Math.floor(world.hour)).padStart(2,'0')}:${String(Math.floor((world.hour%1)*60)).padStart(2,'0')}`;};
function notice(s){let e=$('notice');e.textContent=s;e.classList.add('show');clearTimeout(toastTimer);toastTimer=setTimeout(()=>e.classList.remove('show'),2800);}
function scheduleSave(){if(tempWorld)return;clearTimeout(saveTimer);saveTimer=setTimeout(()=>persist(world).catch(console.warn),600);}
function render(){if(!world)return;const p=getPlace(world.player.place);const count=worldReport(world);
 $('regionTrail').innerHTML=`<button data-scope="world">天下</button><span>/</span><button data-scope="province">大宁·青州</button><span>/</span><button data-scope="county">临安县</button><span>/</span><strong>${safe(label(p.name))}</strong>`;
 $('sceneHeading').innerHTML=`<h1>${safe(showInterior()?p.name:'临安县 · '+label(p.name))}</h1><p><span id="gameClock">${safe(dateLabel())}</span> · ${safe(world.weather)} · ${safe(world.player.role)}</p>`;
 $('countyFacts').innerHTML=`<span>县境 <b>${fmt(count.population)}人</b></span><span>本县在册 <b>${fmt(count.households)}户</b></span><span>粮价 <b>${count.price}文/斗</b></span><span>人物所在 <b>${safe(label(p.name))}</b></span>`;
 $('scope').textContent=showInterior()?'查看世界地图':indoors()?'返回室内':scope==='street'?'查看县域':'回到街巷';
 $('tabs').querySelectorAll('button').forEach(b=>b.classList.toggle('active',b.dataset.tab===tab));
 $('travelFoot').classList.toggle('chosen',mode==='foot');$('travelSword').classList.toggle('chosen',mode==='sword');
 $('content').innerHTML=tab==='scene'?mapView():tab==='people'?peopleView():tab==='office'?officeView():historyView();
 document.querySelectorAll('[data-scope]').forEach(b=>b.addEventListener('click',()=>setScope(b.dataset.scope)));
 if(tab==='scene')wireMap();else wireRecords();
}
function svgMarkup(){if(showInterior())return interiorAtlas(world);if(scope==='street')return streetAtlas(world);if(scope==='county')return countyAtlas(world);if(scope==='province')return provinceAtlas(world);return worldAtlas(world);}
function mapView(){const inside=showInterior();return `<div class="game-map" id="mapContainer" aria-label="${inside?'建筑室内空间':'可平移缩放的山河地图'}">
 <svg id="mapSvg" viewBox="0 0 1000 1000" preserveAspectRatio="xMidYMid meet" role="img" aria-label="点击地物选择目的地，点击道路行走">${svgMarkup()}</svg>
 <div class="map-topline"><div class="map-crumb">${inside?`<button data-exit="1">‹ 返回街巷</button><button aria-current="true">室内</button>`:LEVELS.map(l=>`<button data-level="${l}" aria-current="${l===scope}">${names[l]}</button>`).join('')}</div><div class="scale-controls"><button id="zoomOut" aria-label="缩小地图">−</button><button id="zoomIn" aria-label="放大地图">＋</button></div></div>
 <div class="map-bottom"><div class="coordinates" id="mapCoords">${inside?'室内格局 / 门道相连':scope==='street'?'临安街巷 · 点击道路移动':scope==='county'?'县境实图 / 点击地名查看详情':scope==='province'?'青州山川与交通 / 滑动查看':'天下山河 / 放大逐级展开'}</div><button class="center-btn" id="centerMe" type="button">⌖ 定位</button></div>
 ${selection?`<aside class="poi-sheet" id="poiSheet" role="dialog" aria-label="地图地点详情">${selectionPanel()}</aside>`:''}
 ${moving()?`<div class="journey-hud" id="journeyHud"><div class="journey-head"><strong>行进中 · 时间持续流逝</strong><span id="journeyProgress">0%</span></div><div class="progress-track"><i id="progressFill"></i></div><button type="button" id="stopTravel">停止行进</button></div>`:''}
 </div><div class="map-tip"><span>${inside?'点击门、房间或人物查看':scope==='street'?'建筑先查看再前往；沿路移动非瞬移':'缩放自动切换地图层级；未开放地区不虚构人口'}</span><span>${mode==='foot'?'步行':'御剑'}</span></div>`;}
function commonTerrain(){let fields='';for(let x=5;x<1000;x+=82)for(let y=10;y<1000;y+=89){if((x*7+y*9)%11<4){fields+=`<rect class="farmland" x="${x}" y="${y}" width="68" height="77" rx="4" opacity=".25"/>`;}}
 return `<rect x="-2000" y="-2000" width="5000" height="5000" fill="#dce0d0"/>${fields}<path class="water" d="M 0 480 C 95 570 163 350 230 460 S 370 720 470 910 S 710 890 940 1100"/>`;
}
function streetMap(){const lines=ROADS.map(r=>`<line x1="${r.x1}" y1="${r.y1}" x2="${r.x2}" y2="${r.y2}"/>`).join('');
 const roads=`<g class="road-edge" stroke-width="25">${lines}</g><g class="road-fill" stroke-width="20">${lines}</g><g class="road-axis">${lines}</g><g>${ROADS.map(r=>`<line class="road-target" data-road="1" x1="${r.x1}" y1="${r.y1}" x2="${r.x2}" y2="${r.y2}"/>`).join('')}</g>`;
 const cityWall=`<rect x="241" y="235" width="497" height="562" rx="10" fill="none" stroke="#939481" stroke-width="13" stroke-dasharray="130 22" opacity=".65" pointer-events="none"/>`;
 const yards=YARDS.map((b,i)=>`<g><rect class="yard" x="${b.x}" y="${b.y}" width="${b.w}" height="${b.h}" rx="3"/><rect x="${b.x+6}" y="${b.y+6}" width="${b.w-12}" height="${b.h-12}" fill="${i%2?'#d7c9ad':'#bcbfab'}" stroke="#87947b" stroke-width="1.5"/><text class="map-label small" x="${b.x+b.w/2}" y="${b.y+b.h/2+3}" text-anchor="middle">${safe(b.name)}</text></g>`).join('');
 const buildings=BUILDINGS.map(b=>`<g data-building="${b.id}" role="button" tabindex="0" aria-label="进入${safe(b.name)}"><rect class="building" x="${b.x}" y="${b.y}" width="${b.w}" height="${b.h}" rx="2"/><path class="building-roof" d="M${b.x+4},${b.y+5} L${b.x+b.w-4},${b.y+5} L${b.x+b.w-4},${b.y+b.h-5} L${b.x+4},${b.y+b.h-5}Z"/><rect x="${b.x+13}" y="${b.y+10}" width="${Math.max(12,b.w-26)}" height="${Math.max(12,b.h-20)}" fill="#e2d8be" stroke="#afa68f" stroke-width="2" pointer-events="none"/><text class="map-label" text-anchor="middle" x="${b.x+b.w/2}" y="${b.y+b.h/2+3}">${safe(b.name.replace('临安县',''))}</text><circle cx="${b.door[0]}" cy="${b.door[1]}" r="9" fill="#b59d71" stroke="#f8f0d3" stroke-width="2" pointer-events="none"/></g>`).join('');
 const npcs=outdoorActors(world,10).map(n=>`<g data-npc="${n.person.id}" role="button" tabindex="0"><circle class="actor-dot" cx="${n.x}" cy="${n.y}" r="9"/><text class="actor-name" text-anchor="middle" x="${n.x}" y="${n.y-13}">${safe(n.person.name)} · ${safe(n.action)}</text></g>`).join('');
 const pos=getRoadPosition(world);const route=lastPath?.length>1?`<polyline class="walk-path" points="${lastPath.map(p=>p.x+','+p.y).join(' ')}"/>`:'';
 const marker=`<g><circle class="player-ring" cx="${pos.x}" cy="${pos.y}" r="11"/><path class="player-arrow" d="M${pos.x-5} ${pos.y+5} L${pos.x} ${pos.y-6} L${pos.x+5} ${pos.y+5}Z"/></g>`;
 return `<g>${commonTerrain()}${cityWall}${roads}${yards}${buildings}<text class="road-names" x="484" y="475" text-anchor="middle">东市·十字街</text><text class="road-names" x="283" y="354" text-anchor="middle">西坊</text><text class="road-names" x="484" y="725" text-anchor="middle">南街</text>${route}${npcs}${marker}</g>`;
}
function countyMap(){const nodes=PLACES.filter(p=>p.population>0&&!['lianghang','tiepu','kezhan','xianya','dongshi','xijie','minju','nanmen'].includes(p.id));const seen=new Set(),links=[];
 for(const p of nodes)for(const id of p.links){const other=nodes.find(x=>x.id===id);if(!other)continue;const k=[id,p.id].sort().join('~');if(seen.has(k))continue;seen.add(k);links.push(`<line class="region-route" x1="${p.x*10}" y1="${p.y*10}" x2="${other.x*10}" y2="${other.y*10}"/>`)}
 const pins=nodes.map(p=>`<g data-place="${p.id}" role="button" tabindex="0"><circle class="regional-marker ${p.id===world.player.place?'active':''}" cx="${p.x*10}" cy="${p.y*10}" r="12"/><text class="regional-label" x="${p.x*10+16}" y="${p.y*10-14}">${safe(label(p.name))}</text></g>`).join('');
 return `${commonTerrain()}<path d="M320 260 L750 260 L750 800 L320 800Z" fill="#d2d9be" stroke="#a8ae99" stroke-width="4"/><g>${links.join('')}</g><g data-city="1"><rect x="380" y="380" width="255" height="235" fill="#f0e9d2" stroke="#9a917b" stroke-width="5" rx="10"/><text x="500" y="500" text-anchor="middle" class="area-text" font-size="22">临安城郭</text><text x="500" y="530" text-anchor="middle" class="map-proviso">点此放大街道</text></g><g>${pins}</g><g data-city="1"><rect x="425" y="542" width="150" height="43" fill="transparent"/></g>`;
}
function provinceMap(){return `<rect x="-1700" y="-1700" width="4400" height="4400" fill="#d5ded2"/><path class="coast" d="M-1200 -200 Q-800 -1300 80 -950 Q780 -1120 1500 -450 L1680 740 Q1220 1360 340 1510 Q-680 1370 -1210 700Z"/><path class="water" d="M-500 300 Q90 -100 560 490 T1380 500"/><path class="mountain" d="M120 -330 L410 -800 L700 -340Z"/><path class="mountain" d="M700 950 L880 610 L1000 960Z"/><text class="area-text" x="430" y="-380">大宁 · 青州</text><text class="map-proviso" x="-350" y="-100">周边州郡：区域规则尚未实现</text><g data-to-county="1" role="button"><circle class="regional-marker active" cx="500" cy="500" r="42"/><text class="regional-label" x="565" y="500">临安县 · 你在此处</text></g>`;}
function worldMap(){return `<rect x="-3600" y="-3500" width="7400" height="7200" fill="#bed3d0"/><path class="coast" d="M-2750 -750 L-1950 -2100 L-450 -2400 L780 -1460 L1600 -760 L1940 900 L1120 2260 L-400 2450 L-1890 1740Z"/><path class="coast" d="M2700 -2200 L3300 -1800 L3420 -400 L2860 400 L2400 -800Z"/><text x="-700" y="-850" class="area-text" font-size="70">大宁王朝</text><text x="-2900" y="-100" class="map-proviso">天下总览仅为地理层级演示；未探索的大地暂无人物与城池模拟</text><g data-to-province="1" role="button"><circle class="regional-marker active" cx="500" cy="500" r="110"/><text class="regional-label" font-size="38" x="650" y="480">青州 · 临安县</text><text x="650" y="540" class="regional-label">玩家所在</text></g>`;}
function indoorMap(){const p=getPlace(world.player.place),s=scenery(world),people=sceneActors(world,p.id,7).filter(n=>{const h=world.hour;return h>=6&&h<21&&['铁匠','粮行伙计','县吏','修士','宗门杂役','账房','厨娘','脚夫','商贩','捕快'].includes(n.job)});
 const props=s.props.slice(0,5).map((x,i)=>{const spots=[[140,200],[360,270],[165,410],[365,485],[300,350]];const [px,py]=spots[i];return `<g><rect class="indoor-prop" x="${px-35}" y="${py-23}" rx="3" width="70" height="46"/><text class="indoor-label" text-anchor="middle" x="${px}" y="${py+4}">${safe(x.name)}</text></g>`;}).join('');
 const rooms=s.exits.filter(x=>isInterior(getPlace(x.id))||x.id.includes('hou')||x.id.includes('yaopu')).map((door,i)=>{const x=i%2===0?90:320,y= i<2?545:370;return `<g data-goto="${door.id}" role="button"><rect class="indoor-room" x="${x}" y="${y}" width="102" height="58" rx="2"/><text class="indoor-label" x="${x+51}" y="${y+29}" text-anchor="middle">${safe(door.name)}</text><text class="indoor-label" x="${x+51}" y="${y+48}" text-anchor="middle">进入 ›</text></g>`;}).join('');
 const npcs=people.map((n,i)=>{const x= 116+(i%3)*135,y=315+Math.floor(i/3)*70;return `<g data-npc="${n.id}" role="button"><circle class="indoor-actor" cx="${x}" cy="${y}" r="14"/><text class="indoor-person" text-anchor="middle" x="${x}" y="${y-22}">${safe(n.name)}</text><text class="indoor-label" text-anchor="middle" x="${x}" y="${y+30}">${safe(npcActivity(world,n))}</text></g>`}).join('');
 return `<rect x="0" y="0" width="500" height="650" fill="#e0e4d4"/><rect class="indoor-floor" x="40" y="72" width="420" height="536" rx="2"/><path class="indoor-wall" d="M40 72 H460 V608 H40 V72"/><path d="M196 608 H300" stroke="#f3e6cd" stroke-width="13"/><g data-exit="1" role="button"><rect class="indoor-door" x="196" y="580" width="106" height="49" rx="6"/><text class="indoor-label" text-anchor="middle" x="249" y="610" fill="#fff">出门 · 返回街道</text></g><text class="indoor-name" text-anchor="middle" x="250" y="123">${safe(p.name)}</text>${props}${rooms}${npcs}<text class="indoor-label" x="250" y="157" text-anchor="middle">内屋、家具、人物各有位置；当前精度仍为原型</text>`;
}
function selectionPanel(){if(!selection)return '';
 if(selection.kind==='npc'){const n=world.people.find(x=>x.id===selection.id);if(!n)return '<p>人物不在这里了。</p>';const activity=selection.activity||npcActivity(world,n);const known=world.player.contacts.some(c=>c.id===n.id);
 return `<div class="poi-eyebrow">人物 · ${safe(n.id)}</div><div class="poi-header"><h2>${safe(n.name)}</h2><button data-clear="1" aria-label="关闭">✕</button></div><p>${n.age}岁 / ${safe(n.job)} · ${safe(activity)}</p><p>家乡：${safe(getPlace(n.home)?.name||'不详')} · ${known?'曾经相识':'尚未相识'}</p><div class="poi-actions"><button class="primary" id="talkNpc" data-id="${n.id}">上前交谈</button></div>`;}
 if(selection.kind==='city')return `<div class="poi-eyebrow">县城 / 城池与道路相连</div><div class="poi-header"><h2>临安城郭</h2><button data-clear="1" aria-label="关闭">✕</button></div><p>临安县治所。城墙、城门、县衙、街巷与宅院相互连通；四级地图可进入街区。</p><p>县境人口 ${fmt(worldReport(world).population)}；已有街区和4处可进入建筑。</p><div class="poi-actions"><button class="primary" id="inspectSelected" data-level="street">查看街巷 / 城防</button></div>`;
 if(selection.kind==='region')return `<div class="poi-eyebrow">大宁 · 山河总图</div><div class="poi-header"><h2>${selection.id==='province'?'青州':'临安县'}</h2><button data-clear="1" aria-label="关闭">✕</button></div><p>地势、河流、官道、县治与青云宗门同一地理结构。其他地区仍为未开放地理种子。</p><div class="poi-actions"><button class="primary" id="inspectSelected" data-level="${selection.id==='province'?'province':'county'}">放大查看</button></div>`;
 const p=getPlace(selection.id);if(!p)return '';
 const isBuilding=selection.kind==='building';let people=occupantsAt(world,p.id,4),list=people.length?people.map(n=>`${safe(n.name)}（${safe(npcActivity(world,n))}）`).join('、'):'当前没有可确认的在场值勤人员';
 const building=BUILDINGS.find(b=>b.id===p.id);const travelTime=building?Math.ceil(Math.max(0,(roadPath(getRoadPosition(world),{x:building.door[0],y:building.door[1]})?.length||1)-1)*10/65):null;
 return `<div class="poi-eyebrow">${isBuilding?'建筑 / 可进入':'地图地点 / 行旅'}</div><div class="poi-header"><h2>${safe(p.name)}</h2><button data-clear="1" aria-label="关闭">✕</button></div><p>${safe(p.detail)}</p>
 <p><strong>当前所见：</strong>${list}</p>
 <p class="poi-meta">${isBuilding?'入口可达 · '+travelTime+'分钟步行路程':'行政或自然地理节点 · 依路网计算旅行耗时'}</p>
 <div class="poi-actions">${isBuilding?`<button class="primary" id="enterSelected" data-id="${p.id}">步行前往 / 进入</button>`:`<button class="primary" id="goSelected" data-id="${p.id}">${mode==='sword'?'御剑前往':'沿官道前往'}</button>`}<button data-clear="1">取消</button></div>`;
}
function center(){if(showInterior())return;let p=visualRoadPosition(world);const cam=cameras[scope];if(scope==='street'){cam.x=p.x;cam.y=p.y;}else if(scope==='county'){if(isCity(world.player.place)){cam.x=500;cam.y=520;}else {let l=getPlace(world.player.place);cam.x=l.x*10;cam.y=l.y*10;}}else{cam.x=500;cam.y=500;}setView();}
function setView(){let svg=$('mapSvg'),box=$('mapContainer');if(!svg||!box||showInterior())return;let b=box.getBoundingClientRect(),height=extent[scope],width=height*b.width/b.height,cam=cameras[scope];svg.setAttribute('viewBox',`${(cam.x-width/2).toFixed(1)} ${(cam.y-height/2).toFixed(1)} ${width.toFixed(1)} ${height.toFixed(1)}`);}
function viewWorldCoords(evt){let svg=$('mapSvg');if(!svg)return null;const r=svg.getBoundingClientRect(),v=svg.viewBox.baseVal;return {x:v.x+(evt.clientX-r.left)/r.width*v.width,y:v.y+(evt.clientY-r.top)/r.height*v.height};}
function setScope(level){tab='scene';if(!LEVELS.includes(level))level='street';
 if(indoors())inspectMap=true;
 scope=level;selection=null;render();center();}
function autoScopeFromScale(){if(showInterior())return;const idx=LEVELS.indexOf(scope),value=extent[scope];
 const inward=scope==='world'&&value<2900||scope==='province'&&value<1450||scope==='county'&&value<690;
 const outward=scope==='province'&&value>3700||scope==='county'&&value>2150||scope==='street'&&value>800;
 if(inward&&idx<3){scope=LEVELS[idx+1];selection=null;render();center();}
 else if(outward&&idx>0){scope=LEVELS[idx-1];selection=null;render();center();}}
function goLevel(dir){if(showInterior()){if(dir>0){inspectMap=true;scope='street';render();center();}else notice('室内场景已是最细级别');return;}
 const idx=LEVELS.indexOf(scope),v=extent[scope];
 if(dir>0){if(scope==='street'){extent.street=Math.max(185,v*.67);setView();return;}
   if((scope==='world'&&v>3200)||(scope==='province'&&v>1550)||(scope==='county'&&v>800))extent[scope]=v*.72;
   else {const next=LEVELS[Math.min(3,idx+1)];scope=next;extent[next]=Math.min(extent[next],next==='street'?650:next==='county'?1350:2700);selection=null;render();center();return;}
 }else {if(scope==='world'){extent.world=Math.min(8500,v*1.36);setView();return;}
   if((scope==='street'&&v<650)||(scope==='county'&&v<1800)||(scope==='province'&&v<3200))extent[scope]=v*1.36;
   else {const next=LEVELS[Math.max(0,idx-1)];scope=next;selection=null;render();center();return;}}
 setView();updateMapZoomText();}
function updateMapZoomText(){const el=$('mapCoords');if(el&&scope==='world')el.textContent='天下总图：继续放大可进入州县';}
function beginTravelToPlace(id){if(moving()){notice('正在移动，请先停止当前行程');return;}
 const r=beginRegionJourney(world,id,mode);if(!r.ok){notice(r.error);return;}
 selection=null;lastPath=[];render();if(r.arrived)notice('你已经在这里。');else notice(`开始${mode==='foot'?'步行':'御剑'}，路途中的每一分钟都在推进世界。`);scheduleSave();}
function beginTravelToBuilding(id){if(moving()){notice('请先停止当前行程');return;}
 if(indoors()&&!inspectMap){notice('请先出门');return;}
 if(indoors()&&inspectMap){notice('当前在建筑内，请先返回室内出门');return;}
 const r=beginRoadJourney(world,{x:0,y:0},{buildingId:id});if(!r.ok){notice(r.error);return;}
 selection=null;render();if(r.arrived){inspectMap=false;notice('你进入了'+getPlace(id).name);}else notice('正沿着街道向'+getPlace(id).name+'行进');scheduleSave();}
function interactMap(e){if(moving()){notice('行进中；可以点击「停止行进」');return;}
 const obj=e.target.closest?.('[data-building],[data-npc],[data-place],[data-city],[data-to-county],[data-to-province],[data-goto],[data-exit]');
 if(obj){const d=obj.dataset;
  if(d.npc){const p=world.people.find(x=>x.id===d.npc);selection={kind:'npc',id:d.npc,activity:outdoorActors(world,25).find(x=>x.person.id===d.npc)?.action||npcActivity(world,p)};render();return;}
  if(d.building){selection={kind:'building',id:d.building};render();return;}
  if(d.place){selection={kind:'place',id:d.place};render();return;}
  if(d.city){selection={kind:'city'};render();return;}
  if(d.toCounty){selection={kind:'region',id:'county'};render();return;}
  if(d.toProvince){selection={kind:'region',id:'province'};render();return;}
  if(d.goto){const r=navigate(world,d.goto,'foot');if(r.ok){selection=null;render();scheduleSave();}notice(r.ok?r.description:r.error);return;}
  if(d.exit){const r=exitStreetBuilding(world);if(r.ok){inspectMap=false;selection=null;render();center();scheduleSave();}notice(r.ok?r.description:r.error);return;}
 }
 if(scope==='street'&&!showInterior()){
  if(indoors()){notice('你正在建筑内，只能查看地图。请先返回室内出门');return;}
  const p=viewWorldCoords(e),road=nearestRoad(p.x,p.y);if(Math.hypot(p.x-road.x,p.y-road.y)>25){notice('这里没有可通行道路，先点道路或建筑');return;}
  const r=beginRoadJourney(world,road);if(r.ok){selection=null;render();if(r.arrived)notice('你就在这里。');else notice('开始行走，沿途持续计算世界时间');scheduleSave();}else notice(r.error);
 }
}
function wireMap(){const map=$('mapSvg');if(!map)return;
 if(!showInterior())setView();else map.setAttribute('viewBox','0 0 500 650');
 const fingers=new Map();let begin=null,shifted=false,pinchStart=null,originTarget=null;
 map.addEventListener('pointerdown',e=>{if(e.button!==0)return;map.setPointerCapture(e.pointerId);fingers.set(e.pointerId,{x:e.clientX,y:e.clientY});if(fingers.size===1){begin={x:e.clientX,y:e.clientY};shifted=false;originTarget=e.target;}else{shifted=true;const vals=[...fingers.values()];pinchStart=Math.hypot(vals[0].x-vals[1].x,vals[0].y-vals[1].y);}});
 map.addEventListener('pointermove',e=>{if(!fingers.has(e.pointerId))return;let prev=fingers.get(e.pointerId);fingers.set(e.pointerId,{x:e.clientX,y:e.clientY});if(showInterior())return;
 if(fingers.size>=2){let vals=[...fingers.values()];let distance=Math.hypot(vals[0].x-vals[1].x,vals[0].y-vals[1].y);if(pinchStart&&distance>0){const factor=pinchStart/distance;extent[scope]=Math.max(scope==='street'?170:500,Math.min(scope==='world'?8500:scope==='street'?980:4000,extent[scope]*factor));pinchStart=distance;setView();}return;}
 if(!begin)return;let dx=e.clientX-prev.x,dy=e.clientY-prev.y;if(Math.hypot(e.clientX-begin.x,e.clientY-begin.y)>8)shifted=true;if(shifted){let r=map.getBoundingClientRect(),v=map.viewBox.baseVal;const cam=cameras[scope];cam.x-=dx/r.width*v.width;cam.y-=dy/r.height*v.height;setView();}});
 map.addEventListener('pointerup',e=>{const allow=fingers.size===1&&!shifted&&begin&&Math.hypot(e.clientX-begin.x,e.clientY-begin.y)<10;fingers.delete(e.pointerId);if(!fingers.size){begin=null;pinchStart=null;}if(allow)interactMap({target:originTarget,clientX:e.clientX,clientY:e.clientY});else if(!fingers.size)autoScopeFromScale();});
 map.addEventListener('pointercancel',e=>{fingers.delete(e.pointerId);begin=null;pinchStart=null;});
 map.addEventListener('wheel',e=>{if(showInterior())return;e.preventDefault();const factor=e.deltaY>0?1.18:.84;extent[scope]=Math.max(scope==='street'?170:500,Math.min(scope==='world'?8500:scope==='street'?980:4000,extent[scope]*factor));setView();autoScopeFromScale();},{passive:false});
 map.addEventListener('keydown',e=>{if((e.key==='Enter'||e.key===' ')&&e.target?.dataset){e.preventDefault();interactMap({target:e.target});}});
 document.querySelectorAll('[data-level]').forEach(b=>b.onclick=()=>setScope(b.dataset.level));
 document.querySelectorAll('[data-exit]').forEach(b=>b.onclick=()=>{const result=exitStreetBuilding(world);if(result.ok){scope='street';selection=null;render();center();scheduleSave();}notice(result.ok?result.description:result.error);});
 $('zoomOut').onclick=()=>goLevel(-1);$('zoomIn').onclick=()=>goLevel(1);$('centerMe').onclick=()=>{if(showInterior())notice('当前位于建筑内部。');else center();};
 $('enterSelected')?.addEventListener('click',e=>beginTravelToBuilding(e.currentTarget.dataset.id));
 $('goSelected')?.addEventListener('click',e=>beginTravelToPlace(e.currentTarget.dataset.id));
 $('inspectSelected')?.addEventListener('click',e=>setScope(e.currentTarget.dataset.level));
 $('talkNpc')?.addEventListener('click',e=>{let id=e.currentTarget.dataset.id,p=world.people.find(n=>n.id===id);const actor=outdoorActors(world,50).find(n=>n.person.id===id);if(actor&&!indoors()&&Math.hypot(actor.x-getRoadPosition(world).x,actor.y-getRoadPosition(world).y)>45){notice('请先走到此人附近，再与他交谈。');return;}let r=greet(world,id);notice(r.ok?`你和${p?.name}交谈了。这段相识被记入故人谱。`:r.error);if(r.ok){render();scheduleSave();}});
 document.querySelectorAll('[data-clear]').forEach(b=>b.addEventListener('click',()=>{selection=null;render();}));
 $('stopTravel')?.addEventListener('click',()=>{const result=world.player.journey?cancelRoadJourney(world):cancelRegionJourney(world);if(result){selection=null;render();scheduleSave();notice('已停下。已经流逝的时间不回退。');}});
}
function peopleView(){const arr=world.player.contacts.slice(-50).reverse();return `<section class="document-pane"><div class="eyebrow">凡有相遇，必有时地</div><h2>故人谱</h2><p>不再罗列地图上所有人物。只有你实际认识过的人，才进入这份故人记录。</p>${arr.length?arr.map(c=>{let p=world.people.find(n=>n.id===c.id);return p?`<div class="record"><strong>${safe(p.name)}</strong><small>${safe(p.job)} · ${p.age}岁 · ${safe(c.id)} · 初遇第${c.firstDay}天，${safe(label(getPlace(c.firstPlace).name))} · 见面${c.meetings}次</small></div>`:''}).join(''):'<div class="record">目前还没有认识的人。先去街头与真正正在活动的人交谈。</div>'}</section>`;}
function officeView(){const r=worldReport(world);return `<section class="document-pane"><div class="eyebrow">民生账本 / 真实可核对</div><h2>临安县治</h2><p>人口为真实存档实体记录，农业与财政仍是区域级原型；暂不声称万余人独立自主谋生。</p><div class="ledger"><span>在世居民</span><b>${fmt(r.population)}人</b><span>登记户籍</span><b>${fmt(r.households)}户</b><span>县境总粮</span><b>${fmt(r.grain)}斗</b><span>牌价</span><b>${r.price}文/斗</b><span>县库</span><b>${fmt(r.treasury)}文</b></div><h3>开发调试身份</h3><div class="inline-actions">${['平民','县吏','修士'].map(role=>`<button data-role="${role}" aria-pressed="${role===world.player.role}">${role}</button>`).join('')}</div></section>`;}
function historyView(){return `<section class="document-pane"><div class="eyebrow">真实模拟事件，而非预设主线</div><h2>此世纪事</h2>${world.history.slice(-50).reverse().map(e=>`<div class="chronicle"><span>第${e.day}日 · ${safe(e.type)}</span><p>${safe(e.message)}</p></div>`).join('')}</section>`;}
function wireRecords(){document.querySelectorAll('[data-role]').forEach(b=>b.addEventListener('click',()=>{changeRole(world,b.dataset.role);render();scheduleSave();}));}
async function db(){return await new Promise((resolve,reject)=>{const req=indexedDB.open('xianfan_county_offline',1);req.onupgradeneeded=()=>req.result.createObjectStore('worlds');req.onsuccess=()=>resolve(req.result);req.onerror=()=>reject(req.error);});}
async function persist(w){const conn=await db();return await new Promise((ok,bad)=>{const tx=conn.transaction('worlds','readwrite');tx.objectStore('worlds').put(saveableWorld(w),'current');tx.oncomplete=ok;tx.onerror=()=>bad(tx.error);});}
async function recover(){const conn=await db();return await new Promise((ok,bad)=>{const tx=conn.transaction('worlds','readonly');const req=tx.objectStore('worlds').get('current');req.onsuccess=()=>ok(req.result||null);req.onerror=()=>bad(req.error);});}
async function boot(){try{let raw=await recover();world=raw?restoreWorld(raw):createWorld();}catch(e){console.warn(e);world=createWorld();tempWorld=true;notice('原存档读取异常：当前临时世界不会自动覆盖旧存档');}if(!world.player.roadPos)world.player.roadPos={x:480,y:490};
 if(!isCity(world.player.place)&&!indoors())scope='county';render();}
$('tabs').querySelectorAll('button').forEach(b=>b.onclick=()=>{tab=b.dataset.tab;selection=null;render();});
$('scope').onclick=()=>{if(indoors()){inspectMap=!inspectMap;render();if(inspectMap)center();return;}setScope(scope==='street'?'county':'street');};
$('travelFoot').onclick=()=>{mode='foot';notice('步行：点地图任意道路，按连通路网行走。');render();};
$('travelSword').onclick=()=>{mode='sword';notice('御剑在县域图选择目的地，沿途时间和灵力持续消耗。');if(!indoors())scope='county';render();center();};
$('nextDay').onclick=()=>{if(moving())return notice('请先完成或停止行程，再加速世界时间。');simulateDay(world,1);selection=null;lastPath=[];render();scheduleSave();notice('一天过去，街上人物的作息已改变。');};
$('nextMonth').onclick=()=>{if(moving())return notice('请先完成或停止行程，再加速世界时间。');simulateDay(world,30);selection=null;lastPath=[];render();scheduleSave();notice('三十日过去。查看人口、粮价与历史变化。');};
$('save').onclick=async()=>{try{await persist(world);tempWorld=false;notice('存档已保存。');}catch(e){notice('保存失败：设备存储暂不可用');}};
$('restart').onclick=()=>{if(moving())return notice('行程尚未结束，先停止行进。');const seed=prompt('新世界种子（新世界生成后只有手动保存才会覆盖旧存档）',`临安-${Date.now()}`);if(seed===null)return;world=createWorld(seed);world.player.roadPos={x:480,y:490};tempWorld=true;selection=null;lastPath=[];tab='scene';scope='street';render();notice('全新世界已生成。');};
document.addEventListener('visibilitychange',()=>{if(document.visibilityState==='hidden'&&world&&!tempWorld){clearTimeout(saveTimer);persist(world).catch(console.warn);}});
window.addEventListener('resize',()=>{if(tab==='scene')setView();});
boot();

// 不因用户点地图就一次结算到达；每帧更新实际行进位置与世界时钟。
let lastAnimationTime=0,lastAutoSaveTick=0;
function animateWorld(now){const frame=lastAnimationTime?Math.max(0,Math.min(.12,(now-lastAnimationTime)/1000)):0;lastAnimationTime=now;
 if(world&&moving()&&frame>0){const region=!!world.player.regionJourney;
   const state=region?tickRegionJourney(world,frame):tickRoadJourney(world,frame);
   const el=$('gameClock');if(el)el.textContent=dateLabel();
   const j=world.player.regionJourney||world.player.journey;
   const rate=j?Math.min(1,j.elapsedSeconds/j.durationSeconds):1;
   if($('progressFill'))$('progressFill').style.width=(rate*100).toFixed(1)+'%';
   if($('journeyProgress'))$('journeyProgress').textContent=Math.floor(rate*100)+'%';
   const mark=$(region?'playerMarkerCounty':'playerMarker');
   const pos=region?regionJourneyPosition(world):visualRoadPosition(world);
   if(mark&&pos){let dx=pos.x-Number(mark.dataset.mapX||0),dy=pos.y-Number(mark.dataset.mapY||0);mark.setAttribute('transform',`translate(${dx} ${dy})`);}
   if(state.arrived){if(state.buildingId)inspectMap=false;else if(region){scope=isCity(world.player.place)?'street':'county';}
     render();center();scheduleSave();notice(state.buildingId?'已从入口进入建筑':'你已抵达目的地。');}
   else if(now-lastAutoSaveTick>2200){scheduleSave();lastAutoSaveTick=now;}
 }
 requestAnimationFrame(animateWorld);
}
requestAnimationFrame(animateWorld);
