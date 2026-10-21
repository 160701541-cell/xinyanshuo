/** 仙凡共生 v0.6：连续米制地图客户端。缩放绝不修改玩家坐标。 */
import {createWorld,restoreWorld,saveableWorld,worldReport,simulateDay,note,getPlace,changeRole} from './core.mjs';
import {MAP_VERSION,WORLD_LIMIT,CITY,LANDMARKS,STRUCTURES,TOWN_HOUSES,WALLS,ROUTES,STREAMS,PLACE_METERS,ensureGeo,terrainHeight,dist,obstacleAt,beginJourney,stopJourney,advanceMap,enterStructure,exitStructure,placeAt,visibleActors,actorVisibility,openingStatus,canEnter,canFly,flightRuleAt,rest} from './overworld.mjs';
import {FACTIONS,factionById,territoryGrid,territoryBorderPaths,MAP_MODES,mapColor,reputation,standing,securityIndex,ITEMS,itemById,priceOf,inventory,buyItem,sellItem,canTradeHere,bagWeight,contractsFor,acceptContract,completeContract,societyReport} from './society.mjs';
import {SpriteBank,lookFor} from './sprites.mjs';
import {equip,drill,research,setFormation,FORMATIONS,TECHS,ARMS,unitsReport,purseOf,ensureFin} from './units.mjs';
import {ensureCurrency,tickCurrency,buyStones,moneyReport,fmtCoins} from './currency.mjs';
import {levySect,RETAINER_COST,ensureCultivation,xianReport,tickRetainers,resolveAssassination,assassinThreat,courtProtection,sectDefense,hireRetainer,raidSect,retainerPower,REALMS,cultivatorDensity} from './cultivation.mjs';
import {ensureState,tickState,reform,stateReport,LEVERS} from './state.mjs';
import {ensureCourt,tickCourt,issueOrder,talkTo,courtReport,parseDecree} from './court.mjs';
import {ensureMarket,tickMarket,marketReport,releaseGrain,buyToGranary,setTax,setMonopoly,buildPost,GOODS} from './market.mjs';
import {PeopleBank,dirFor,stepOf} from './people.mjs';
import {practice,breakLayer,breakRealm,restMeridian,practiceReport,detectRoot} from './cultivation.mjs';
import {runRules,ensureEngine} from './engine.mjs';
import {loadContent} from './content/index.mjs';
import {ensureFamily,familyReport,familyMembers,joinFamily,marry,conceive,candidatesFor,ageFamily,ageOf,ageLeft,rootOfPerson} from './family.mjs';
import {ensureCareer,joinPath,advance,canAdvance,recruitMen,recruitCapacity,openShop,sendCaravan,buyLand,tickCareer,recordBattle,careerReport,hireCultivator,PATHS,SHOP_KINDS,MEN_COST} from './careers.mjs';
import {ensureWar,levyCapacity,createArmy,warReport,tickWarDay,supplyDays,armyNeeds,deliveredCostKg,emblemOf,authorityReport,setRank,rankOf,rankInfo,takeCommand,joinArmy,issueDecree} from './war.mjs';
import {interiorAtlas} from './atlas.mjs';
import {classifyGesture,canSelect} from './gesture.mjs';
import {layoutTown,streetsFor,ART} from './buildings.mjs';
import {generateWorld,realmView,regionAt,realmReport,domainShare} from './worldmap.mjs';
import {spawnMapBattle,stepMapBattle,drawMapBattle,mapBattleReport,mapBattle,endMapBattle} from './mapbattle.mjs';
import {ensureDao,daoReport,attitudeOf,seekAlly,shiftDao,taoLabel,STANCES,TAGS,NATIONS,SECTS as DAO_SECTS,attachPeople,peopleAt,helpPerson,personAttitude} from './dao.mjs';
import {ensureKarma,killPreview,resolveKill,breakthroughChance,attemptBreakthrough,karmaTier,karmaReport,lootFor,JUSTIFY} from './karma.mjs';
const placeById=getPlace;
const $=id=>document.getElementById(id);
const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
const safe=s=>String(s??'').replace(/[&<>'"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','\'':'&#39;','"':'&quot;'}[c]));
let worldRealm='mortal',w,selected=null,camera={x:0,y:0,mpp:2.7},mapMode='terrain',sprites=null,peopleBank=null,clockMs=0,ctx,canvas,cssW=0,cssH=0,activeTab='map',pointer=new Map(),pinch=null,dragStart=null,gestureMoved=false,multiTouched=false,downAt=0,travelSpeed=30,savePending=0,noticeTimeout=0,paused=false;
const peopleCaches=new WeakMap();
const faces=['#537560','#95724d','#607d91','#8e715f','#855f67','#726b91'];
const currentTime=()=>{const m=Math.floor(w.hour*60);return `承平${3+Math.floor((w.day-1)/360)}年 · 第${(w.day-1)%360+1}日 · ${String(Math.floor(m/60)).padStart(2,'0')}:${String(m%60).padStart(2,'0')}`;};
let profileTimer=0;
function requestProfile(){if(profileTimer)return;profileTimer=setTimeout(()=>{profileTimer=0;if(w)profile();},90);}
function toast(t){$('toast').textContent=t;$('toast').classList.add('visible');clearTimeout(noticeTimeout);noticeTimeout=setTimeout(()=>$('toast').classList.remove('visible'),2900);}
function scheduleSave(){clearTimeout(savePending);savePending=setTimeout(()=>save().catch(console.warn),900);}
async function store(){return new Promise((ok,err)=>{let r=indexedDB.open('xianfan_county_offline',1);r.onupgradeneeded=()=>r.result.createObjectStore('worlds');r.onsuccess=()=>ok(r.result);r.onerror=()=>err(r.error);});}
async function save(){const db=await store();w.mapCamera={...camera};return new Promise((ok,err)=>{const tx=db.transaction('worlds','readwrite');tx.objectStore('worlds').put(saveableWorld(w),'current');tx.oncomplete=ok;tx.onerror=()=>err(tx.error);});}
async function load(){const db=await store();return new Promise((ok,err)=>{let r=db.transaction('worlds').objectStore('worlds').get('current');r.onsuccess=()=>ok(r.result);r.onerror=()=>err(r.error);});}
const pos=p=>({x:cssW/2+(p.x-camera.x)/camera.mpp,y:cssH/2+(p.y-camera.y)/camera.mpp});
const unpos=(x,y)=>({x:camera.x+(x-cssW/2)*camera.mpp,y:camera.y+(y-cssH/2)*camera.mpp});
const visible=p=>{const q=pos(p);return q.x>-60&&q.x<cssW+60&&q.y>-60&&q.y<cssH+60;};
const drawPath=(a,close=false)=>{if(!a.length)return;ctx.beginPath();let t=pos({x:a[0][0],y:a[0][1]});ctx.moveTo(t.x,t.y);for(let i=1;i<a.length;i++){t=pos({x:a[i][0],y:a[i][1]});ctx.lineTo(t.x,t.y);}if(close)ctx.closePath();};
const rect=(x,y,ww,hh,fill,stroke,sw=1)=>{const p=pos({x,y}),rw=ww/camera.mpp,rh=hh/camera.mpp;if(p.x>cssW+40||p.y>cssH+40||p.x+rw<-40||p.y+rh<-40)return;ctx.fillStyle=fill;ctx.fillRect(p.x,p.y,rw,rh);if(stroke){ctx.strokeStyle=stroke;ctx.lineWidth=sw;ctx.strokeRect(p.x,p.y,rw,rh);}};
const circle=(p,r,fill,stroke='',strokeWidth=1)=>{const s=pos(p);ctx.beginPath();ctx.arc(s.x,s.y,r,0,Math.PI*2);ctx.fillStyle=fill;ctx.fill();if(stroke){ctx.strokeStyle=stroke;ctx.lineWidth=strokeWidth;ctx.stroke();}};
function text(label,p,size=13,color='#263b33',weight=600,halo=true,align='center'){const q=pos(p);ctx.font=`${weight} ${size}px system-ui, sans-serif`;ctx.textAlign=align;ctx.textBaseline='middle';if(halo){ctx.lineWidth=3.5;ctx.strokeStyle='#faf5e6';ctx.strokeText(label,q.x,q.y);}ctx.fillStyle=color;ctx.fillText(label,q.x,q.y);}
function screenText(label,x,y,size=12,color='#334f40',weight=600){ctx.font=`${weight} ${size}px system-ui`;ctx.textBaseline='middle';ctx.textAlign='center';ctx.lineWidth=2;ctx.strokeStyle='#f5eddb';ctx.strokeText(label,x,y);ctx.fillStyle=color;ctx.fillText(label,x,y);}
const noise=(a,b)=>{let x=(Math.imul(Math.floor(a),374761393)+Math.imul(Math.floor(b),668265263)+987643211)>>>0;x=Math.imul(x^x>>>13,1274126177)>>>0;return ((x^x>>>16)>>>0)/4294967296;};
const hills=(x,y)=>Math.sin(x/52000)*Math.cos(y/74000)+Math.sin((x-y)/21000)*.5;
function drawGround(){ctx.fillStyle='#c8d2a4';ctx.fillRect(0,0,cssW,cssH);
 const step=camera.mpp>1500?45000:camera.mpp>100?9000:camera.mpp>16?900:camera.mpp>3?175:42;
 const min=unpos(-10,-10),max=unpos(cssW+10,cssH+10);const x0=Math.floor(min.x/step),x1=Math.ceil(max.x/step),y0=Math.floor(min.y/step),y1=Math.ceil(max.y/step);
 if((x1-x0)*(y1-y0)>80000)return;
 for(let a=x0;a<=x1;a++)for(let b=y0;b<=y1;b++){const x=a*step,y=b*step,z=terrainHeight(x,y),n=noise(a,b);
 const nearCity=Math.abs(x)<1300&&Math.abs(y)<1200;
 // v0.32 提色：海拔分四档，色相拉开（湿地青 → 平原嫩绿 → 丘陵黄绿 → 高地褐），不再是一片灰
 const shade=z>240?'#96a05e':z>160?'#b3bb5c':z>100?'#9fbb60':'#8fc09a';
 let color=nearCity?ART.ground.yard:shade;
 if(n<.11)color=nearCity?ART.ground.yard:'#a9c257';
 if(n>.93&&!nearCity)color='#77a95f';
 rect(x,y,step+1,step+1,color);
 if(camera.mpp<3&&n>.70){const s=pos({x:x+step/2,y:y+step/2});ctx.strokeStyle='rgba(58,96,52,.45)';ctx.lineWidth=1.4;ctx.beginPath();ctx.moveTo(s.x-2,s.y+2);ctx.lineTo(s.x,s.y-2);ctx.lineTo(s.x+3,s.y+1);ctx.stroke();}
 }
}
function drawPolitical(){if(camera.mpp<180||mapMode!=='terrain')return;
 const polys=[
 {name:'大宁王朝',fill:'rgba(209,207,165,.33)',points:[[-550000,-440000],[100000,-550000],[490000,-70000],[540000,340000],[-300000,490000],[-700000,140000]]},
 {name:'北朔汗庭',fill:'rgba(192,203,183,.42)',points:[[-400000,-1300000],[520000,-1300000],[630000,-650000],[80000,-470000],[-550000,-410000]]},
 {name:'东越',fill:'rgba(194,211,183,.4)',points:[[430000,-150000],[1300000,-180000],[1300000,630000],[440000,500000]]},
 {name:'西戎',fill:'rgba(210,189,154,.37)',points:[[-1350000,-390000],[-580000,-490000],[-610000,560000],[-1350000,700000]]},
 {name:'云离',fill:'rgba(166,195,181,.34)',points:[[-180000,400000],[450000,380000],[950000,1300000],[-500000,1300000]]}
 ];
 for(const f of polys){drawPath(f.points,true);ctx.fillStyle=f.fill;ctx.fill();ctx.strokeStyle='#8a806b';ctx.lineWidth=1.25;ctx.setLineDash([7,5]);ctx.stroke();ctx.setLineDash([]);let av={x:f.points.reduce((n,p)=>n+p[0],0)/f.points.length,y:f.points.reduce((n,p)=>n+p[1],0)/f.points.length};if(visible(av))text(f.name,av,15,'#5a5846',700);}
}
const factionFills={};
function fillOf(f,alpha){const key=f+alpha;if(!factionFills[key])factionFills[key]=hexA(factionById(f)?.color||'#e5dcc2',alpha);return factionFills[key];}
const hexA=(hex,a)=>{const n=parseInt(hex.slice(1),16);return `rgba(${(n>>16)&255},${(n>>8)&255},${n&255},${a})`;};
/** P 社式政治图层：先给领土烤一张一次性位图（双线性拉伸，边界不留锯齿），再叠界线。只读世界，不改状态。 */
let factionRaster=null;
function rasterOf(grid){
 const c=document.createElement('canvas');c.width=grid.n;c.height=grid.n;
 const cx=c.getContext('2d'),img=cx.createImageData(grid.n,grid.n);
 const pal=grid.ids.map(id=>{const hex=factionById(id)?.color||'#e5dcc2';return [parseInt(hex.slice(1,3),16),parseInt(hex.slice(3,5),16),parseInt(hex.slice(5,7),16)];});
 for(let i=0;i<grid.cells.length;i++){const rgb=pal[grid.cells[i]]||[229,220,194],o=i*4;img.data[o]=rgb[0];img.data[o+1]=rgb[1];img.data[o+2]=rgb[2];img.data[o+3]=232;}
 cx.putImageData(img,0,0);
 return c;
}
/** 整界版图：一次烤成 108×108 位图，缩到几十公里/像素时铺满全屏。凡界/仙界同尺寸、各一套地块。 */
let WORLD_MAP=null,worldRasterCache=null,cultMask=null,highlightCult=false;
function realmMap(){if(!WORLD_MAP)WORLD_MAP=generateWorld({grid:108});return WORLD_MAP;}
function realmRaster(){
 if(worldRasterCache)return worldRasterCache;
 const map=realmMap(),n=map.grid,c=document.createElement('canvas');
 c.width=n;c.height=n;const cx=c.getContext('2d'),img=cx.createImageData(n,n);
 const pal=map.regions.map(rg=>[parseInt(rg.color.slice(1,3),16),parseInt(rg.color.slice(3,5),16),parseInt(rg.color.slice(5,7),16)]);
 for(let i=0;i<map.owner.length;i++){const rgb=pal[map.owner[i]]||[214,204,176],o=i*4;
  img.data[o]=rgb[0];img.data[o+1]=rgb[1];img.data[o+2]=rgb[2];img.data[o+3]=255;}
 cx.putImageData(img,0,0);worldRasterCache=c;return c;}
/** “只看仙域”用：凡界压暗，修仙界留亮。 */
function cultivationMask(map){
 const n=map.grid,c=document.createElement('canvas');c.width=n;c.height=n;
 const cx=c.getContext('2d'),img=cx.createImageData(n,n);
 for(let i=0;i<map.owner.length;i++){
  const r=map.regions[map.owner[i]],o=i*4;
  img.data[o]=24;img.data[o+1]=20;img.data[o+2]=30;
  img.data[o+3]=r.domain==='cultivation'?0:170;
 }
 cx.putImageData(img,0,0);return c;}
function drawWorldLayer(){
 if(camera.mpp<26)return;
 const map=realmMap(),ras=realmRaster();
 const a=pos({x:-map.extent,y:-map.extent}),b=pos({x:map.extent,y:map.extent});
 ctx.save();ctx.imageSmoothingEnabled=false;ctx.globalAlpha=.96;
 ctx.drawImage(ras,a.x,a.y,b.x-a.x,b.y-a.y);
 ctx.restore();
 if(highlightCult){
  if(!cultMask)cultMask=cultivationMask(map);
  ctx.save();ctx.globalAlpha=.62;ctx.imageSmoothingEnabled=false;
  ctx.drawImage(cultMask,a.x,a.y,b.x-a.x,b.y-a.y);ctx.restore();
 }
 if(camera.mpp>110){
  const size=clamp(900/(camera.mpp*.9),10,15);
  for(const rg of map.regions){
   if(rg.areaKm2<12000)continue;
   if(Math.abs(rg.x)>map.extent*0.94||Math.abs(rg.y)>map.extent*0.94)continue;
   if(!visible(rg))continue;
   if(!highlightCult||rg.domain==='cultivation')text(`${rg.name}·${rg.land}`,rg,size,rg.domain==='cultivation'?'#3f3a63':'#3b3528',520);
  }
  for(const c of LANDMARKS){if(!visible(c))continue;text(c.name,c,size+1.5,'#2f2a1e',760);}
 }
 if(!w)return;
 const here=regionAt(map,w.player.mapPos||{x:0,y:0});
 if(here&&camera.mpp>200){
  text(`${here.domain==='cultivation'?'修仙界':'凡界'} · ${here.name}`,{x:camera.x,y:camera.y-cssH*.5/camera.mpp+120},13,'#4a4130',800);
 }
}
function realmSheet(obj){
 const rg=obj.data;const realm=rg.domain==='cultivation'?'修仙界':'凡界';
 let title=rg.name,sub=`${rg.land} · ${realm} · ${rg.areaKm2}平方公里`;
 let body=`<p class="near">产出 ${rg.resource==='grain'?'粮':rg.resource==='timber'?'木':rg.resource==='qi'?'灵气':rg.resource==='herb'?'药':rg.resource==='beast'?'兽':rg.resource==='stone'?'石':rg.resource==='iron'?'铁':rg.resource==='salt'?'盐':rg.resource==='fish'?'鱼':rg.resource==='reed'?'苇':'杂'}：储量 ${Math.round(rg.stock)}，年出 ${rg.yearly}　危险 ${rg.danger}级</p>`;
 const here=w.player.mapPos||{x:0,y:0};
 body+=`<p class="near">距你 ${Math.round(Math.hypot(rg.x-here.x,rg.y-here.y)/1000)}公里 · 一块地约 ${Math.round(Math.sqrt(rg.areaKm2))}公里见方</p>`;
 const buttons=`<button data-action="gotoregion">朝这块地走</button><button data-action="closeregion" class="quiet">收起</button>`;
 return {kind:'region',data:rg,title,sub,body,buttons};
}
/** 两级领土位图：远场 12 公里（覆盖整张世界）、近场 2 公里（县域精细）。一次烤好，之后每帧只是两次 drawImage。 */
function factionRasterFor(){
 if(factionRaster)return factionRaster;
 const far=territoryGrid(12000,WORLD_LIMIT),near=territoryGrid();
 factionRaster={far,farCanvas:rasterOf(far),near,nearCanvas:rasterOf(near),
  farPaths:territoryBorderPaths(12000,WORLD_LIMIT),nearPaths:territoryBorderPaths()};
 return factionRaster;
}
function paintGrid(grid,canvas){
 const a=pos({x:grid.origin,y:grid.origin}),b=pos({x:grid.origin+grid.n*grid.step,y:grid.origin+grid.n*grid.step});
 ctx.drawImage(canvas,0,0,grid.n,grid.n,a.x,a.y,b.x-a.x,b.y-a.y);
}
/** 折线过中点画二次曲线：把 12 公里的锯齿边界揉成自然的海岸线。 */
function strokePaths(paths,width,alpha){
 ctx.strokeStyle=`rgba(58,62,46,${alpha})`;ctx.lineWidth=width;ctx.lineCap='round';ctx.lineJoin='round';
 for(const pts of paths){
  const first=pos({x:pts[0][0],y:pts[0][1]});
  ctx.beginPath();ctx.moveTo(first.x,first.y);
  for(let i=1;i<pts.length-1;i++){
   const c=pos({x:pts[i][0],y:pts[i][1]}),n=pos({x:pts[i+1][0],y:pts[i+1][1]});
   ctx.quadraticCurveTo(c.x,c.y,(c.x+n.x)/2,(c.y+n.y)/2);
  }
  const last=pos({x:pts[pts.length-1][0],y:pts[pts.length-1][1]});
  ctx.lineTo(last.x,last.y);
  ctx.stroke();
 }
}
function drawFactionLayer(){
 if(mapMode==='terrain')return;
 const min=unpos(-40,-40),max=unpos(cssW+40,cssH+40);
 if(mapMode!=='faction'){
  const inc=camera.mpp>1500?12000:camera.mpp>400?4000:camera.mpp>90?1200:300;
  const sx=Math.floor(min.x/inc)*inc,sy=Math.floor(min.y/inc)*inc;
  for(let x=sx;x<=max.x;x+=inc)for(let y=sy;y<=max.y;y+=inc){
   const fill=mapColor(w,mapMode,x+inc/2,y+inc/2);if(!fill)continue;
   const p=pos({x,y}),px=inc/camera.mpp;
   if(p.x>cssW||p.y>cssH||p.x+px<0||p.y+px<0)continue;
   ctx.fillStyle=fill;ctx.fillRect(p.x,p.y,px+1,px+1);
  }
  return;
 }
 const r=factionRasterFor();
 ctx.save();ctx.globalAlpha=.5;ctx.imageSmoothingEnabled=true;
 paintGrid(r.far,r.farCanvas);
 paintGrid(r.near,r.nearCanvas);
 ctx.restore();
 strokePaths(r.farPaths,Math.max(1,Math.min(2.5,900/camera.mpp)),.3);
 strokePaths(r.nearPaths,clamp(300/camera.mpp,1.2,4),.62);
 if(camera.mpp>700){
  for(const f of FACTIONS){const seat=LANDMARKS.find(l=>l.id===f.seat)||{x:0,y:0};if(visible(seat))text(f.name,seat,Math.min(26,Math.max(12,900/camera.mpp)),'#3d4437',800);}
 }
}
function securityLabel(){
 const s=securityIndex(w);return s>=70?'治安尚可':s>=45?'盗匪偶发':'盗匪横行';
}
/** 军团旗：一旗=一支军。旗形=国别，旗字=国徽，旗号=番号，旗色=国色。 */
function drawArmies(){
 if(!w.war)return;
 for(const a of w.war.armies){
  if(!visible(a))continue;
  const p=pos(a),big=a.combat+a.support,e=a.emblem||emblemOf(a.faction);
  const size=clamp(Math.sqrt(big)/24,14,52);
  if(a.goal){const g=pos(a.goal);ctx.setLineDash([7,7]);ctx.strokeStyle='rgba(126,52,40,.5)';ctx.lineWidth=1.5;ctx.beginPath();ctx.moveTo(p.x,p.y);ctx.lineTo(g.x,g.y);ctx.stroke();ctx.setLineDash([]);}
  const poleTop=p.y-size*1.95,fw=size*1.3,fh=size*.74;
  ctx.strokeStyle='#3a3226';ctx.lineWidth=Math.max(1.4,size*.06);ctx.beginPath();ctx.moveTo(p.x,p.y);ctx.lineTo(p.x,poleTop);ctx.stroke();
  const fill=a.routed?'#a8a294':e.color;
  ctx.beginPath();
  if(e.flag==='pennant'){ctx.moveTo(p.x,poleTop);ctx.lineTo(p.x+fw*1.35,poleTop+fh*.5);ctx.lineTo(p.x,poleTop+fh);}
  else if(e.flag==='swallow'){ctx.moveTo(p.x,poleTop);ctx.lineTo(p.x+fw,poleTop);ctx.lineTo(p.x+fw*.72,poleTop+fh*.5);ctx.lineTo(p.x+fw,poleTop+fh);ctx.lineTo(p.x,poleTop+fh);}
  else {ctx.rect(p.x,poleTop,fw,fh);}
  ctx.closePath();ctx.fillStyle=fill;ctx.fill();
  ctx.strokeStyle='rgba(40,34,26,.8)';ctx.lineWidth=Math.max(1,size*.04);ctx.stroke();
  // 边框纹样：双线/细饰/点/山形/云
  ctx.strokeStyle=e.ink;ctx.globalAlpha=.5;
  if(e.border==='double'){ctx.strokeRect(p.x+3,poleTop+3,Math.max(2,fw-6),Math.max(2,fh-6));}
  else if(e.border==='dot'){ctx.setLineDash([2,3]);ctx.strokeRect(p.x+3,poleTop+3,Math.max(2,fw-6),Math.max(2,fh-6));ctx.setLineDash([]);}
  else if(e.border==='chevron'){for(let i=1;i<3;i++){ctx.beginPath();ctx.moveTo(p.x+4,poleTop+fh*i/3);ctx.lineTo(p.x+fw*.55,poleTop+fh*(i/3+.12));ctx.stroke();}}
  else if(e.border==='cloud'){ctx.beginPath();ctx.arc(p.x+fw*.5,poleTop+fh*.55,Math.max(3,fh*.3),0,Math.PI*2);ctx.stroke();}
  else {ctx.beginPath();ctx.moveTo(p.x+3,poleTop+fh-4);ctx.lineTo(p.x+fw-4,poleTop+fh-4);ctx.stroke();}
  ctx.globalAlpha=1;
  // 国徽字：屏上一眼分国
  if(size>20){
   ctx.fillStyle=a.routed?'#5c5749':e.ink;ctx.textAlign='center';ctx.textBaseline='middle';
   ctx.font=`700 ${Math.round(fh*.62)}px "Noto Serif SC","Songti SC",serif`;
   ctx.fillText(e.glyph,p.x+fw*.42,poleTop+fh*.52);
  }
  if(camera.mpp<700)text(`${Math.max(1,Math.round(big/10000))}万`,{x:a.x,y:a.y},Math.min(18,Math.max(10,size*.36)),'#3b3226',700);
  if(camera.mpp<180&&size>22){screenText(`${a.corps.replace(/^.*·/,'')}·${a.commander}`,p.x,p.y+16,12);}
 }
}
function drawRelief(){if(camera.mpp>1500)return;const min=unpos(-20,-20),max=unpos(cssW+20,cssH+20);const inc=camera.mpp>80?15000:camera.mpp>10?3200:camera.mpp>2?400:160;
 let count=0;for(let x=Math.floor(min.x/inc)*inc;x<max.x;x+=inc)for(let y=Math.floor(min.y/inc)*inc;y<max.y;y+=inc){if(count++>8000)return;let z=terrainHeight(x,y);if(z<180)continue;const q=pos({x,y}),sz=Math.max(2,Math.min(21,inc/camera.mpp*.18));ctx.beginPath();ctx.moveTo(q.x-sz,q.y+sz*.8);ctx.lineTo(q.x,q.y-sz*.7);ctx.lineTo(q.x+sz,q.y+sz*.8);ctx.closePath();ctx.fillStyle=z>240?'rgba(120,104,64,.22)':'rgba(70,102,58,.16)';ctx.fill();}}
function drawWater(){
 for(const river of STREAMS){
  drawPath(river);ctx.strokeStyle='#7f9c6c';ctx.lineWidth=clamp(116/camera.mpp,1,70);ctx.lineCap='round';ctx.lineJoin='round';ctx.stroke();
  drawPath(river);ctx.strokeStyle='#4f93b8';ctx.lineWidth=clamp(100/camera.mpp,1,60);ctx.stroke();
  drawPath(river);ctx.strokeStyle='#8fd0e0';ctx.lineWidth=clamp(28/camera.mpp,.5,10);ctx.stroke();
 }
}
/** 城外农田：按 175 米格子确定性地铺一层田块，把县城周边的原野画出来（只画不模拟）。 */
function drawFields(){
 if(camera.mpp>40||camera.mpp<.8)return;
 const min=unpos(-80,-80),max=unpos(cssW+80,cssH+80);
 const cell=175,colors=['#c6c84c','#b0c246','#d8c85e','#9fbe52'];
 const gx0=Math.floor(min.x/cell),gx1=Math.ceil(max.x/cell),gy0=Math.floor(min.y/cell),gy1=Math.ceil(max.y/cell);
 if((gx1-gx0)*(gy1-gy0)>4000)return;
 for(let gx=gx0;gx<=gx1;gx++)for(let gy=gy0;gy<=gy1;gy++){
  const x=gx*cell,y=gy*cell;
  if(Math.abs(x)<820&&Math.abs(y)<820)continue;          // 城内不铺田
  const n=noise(gx*7+3,gy*11+5);if(n>.46)continue;
  const z=terrainHeight(x,y);if(z>170)continue;           // 高处是山林
  if(Math.abs(x)<260&&Math.abs(y)<260)continue;
  const c=colors[Math.floor(n*40)%colors.length];
  const inset=6+((gx*13+gy*7)%10);
  rect(x+inset,y+inset,cell-inset*2,cell-inset*2,c);
  rect(x+inset,y+inset,cell-inset*2,2,'#8d9e3c',null,0);
 }
}
function drawRoads(){for(const seg of ROUTES){drawPath(seg);ctx.strokeStyle='#a8916a';ctx.lineWidth=clamp(24/camera.mpp,1,28);ctx.lineJoin='round';ctx.stroke();drawPath(seg);ctx.strokeStyle='#efe0b8';ctx.lineWidth=clamp(19/camera.mpp,.6,25);ctx.stroke();}
 if(camera.mpp>75)return;
 // 城区道路是连续的世界坐标，缩放不会切换到另一张图。
 ctx.lineCap='butt';for(const d of [-520,-260,0,260,520]){
 const a=[[-700,d],[700,d]],b=[[d,-700],[d,700]];
 for(const line of [a,b]){drawPath(line);ctx.strokeStyle='#c5bb9c';ctx.lineWidth=clamp(45/camera.mpp,1,65);ctx.stroke();drawPath(line);ctx.strokeStyle='#e7dec5';ctx.lineWidth=clamp(40/camera.mpp,.8,60);ctx.stroke();}}
 ctx.lineCap='round';}
function drawWall(){if(camera.mpp>40)return;for(const r of WALLS){rect(r.x,r.y,r.w,r.h,'#827e70','#e1c8a0',camera.mpp<8?1:0);}for(const g of CITY.gates){const s=pos(g),r=clamp(45/camera.mpp,2,65);ctx.strokeStyle='#614d3e';ctx.lineWidth=Math.max(1,6/camera.mpp);ctx.beginPath();ctx.arc(s.x,s.y,r,0,Math.PI*2);ctx.stroke();if(camera.mpp<8)screenText('城门',s.x,s.y-24,12);}}
const TOWN_LAYOUT=layoutTown('linan',STRUCTURES);
const TOWN_STREETS=streetsFor(STRUCTURES);
/** 街巷：先铺路，再铺房子；路面比地面亮一档，路口压深。 */
function drawStreets(){
 if(camera.mpp>600)return;
 for(const s of TOWN_STREETS){
  const a=pos({x:s.x1,y:s.y1}),b=pos({x:s.x2,y:s.y2});
  const w=Math.max(1.2,s.w/camera.mpp);
  ctx.lineCap='butt';ctx.strokeStyle=ART.ground.street;ctx.lineWidth=w;
  ctx.beginPath();ctx.moveTo(a.x,a.y);ctx.lineTo(b.x,b.y);ctx.stroke();
  if(camera.mpp<2.2&&w>6){ctx.strokeStyle='rgba(214,203,176,.85)';ctx.lineWidth=w-4;ctx.beginPath();ctx.moveTo(a.x,a.y);ctx.lineTo(b.x,b.y);ctx.stroke();}
 }
}
function roofFill(name){const t=ART.roof[name]||ART.roof.home;return t;}
function shade(hex,d){const n=parseInt(hex.slice(1),16);let r=(n>>16)+d,g=((n>>8)&255)+d,b=(n&255)+d;r=Math.max(0,Math.min(255,r));g=Math.max(0,Math.min(255,g));b=Math.max(0,Math.min(255,b));return `rgb(${r},${g},${b})`;}
/** 屋顶：双坡，脊线两侧明暗分开；檐口压深；瓦纹只在近景画。 */
function drawRoof(x,y,w,h,roof,ridgeNs,floors){
 const base=roofFill(roof),light=shade(base,9),dark=shade(base,-7),mid=ridgeNs?x+w/2:x;
 rect(x,y,w,h,dark,null,0);
 if(ridgeNs)rect(x,y,w/2,h,light,null,0);else rect(x,y,w,h/2,light,null,0);
 if(camera.mpp<16){
  const lw=Math.max(.6,1.4/camera.mpp);
  ctx.strokeStyle='rgba(58,52,42,.55)';ctx.lineWidth=lw;
  const a=pos({x:ridgeNs?x+w/2:x,y:ridgeNs?y:y+h/2}),b=pos({x:ridgeNs?x+w/2:x+w,y:ridgeNs?y+h:y+h/2});
  ctx.beginPath();ctx.moveTo(a.x,a.y);ctx.lineTo(b.x,b.y);ctx.stroke();
  if(camera.mpp<3.2){
   ctx.strokeStyle='rgba(45,40,32,.16)';ctx.lineWidth=1;
   const step=2.6;
   for(let gx=x+2;gx<x+w-1;gx+=step){const p1=pos({x:gx,y}),p2=pos({x:gx,y:y+h});ctx.beginPath();ctx.moveTo(p1.x,p1.y);ctx.lineTo(p2.x,p2.y);ctx.stroke();}
  }
 }
 rect(x,y,w,h,null,'#4b4539',Math.max(.4,1.2/camera.mpp));
 // 檐下阴影
 if(camera.mpp<12)rect(x+w*.04,y+h,w,w*.09,'rgba(60,52,40,.18)',null,0);
}
function drawPart(p){
 const {t}=p;const x=p.x,y=p.y,w=p.w||0,h=p.h||0;
 if(t==='yard'){rect(x,y,w,h,'#c9bda0',null,0);if(camera.mpp<3){ctx.strokeStyle='rgba(182,169,138,.5)';ctx.lineWidth=1;const step=6;for(let gy=y+3;gy<y+h-2;gy+=step){const a=pos({x:x+2,y:gy}),b=pos({x:x+w-2,y:gy});ctx.beginPath();ctx.moveTo(a.x,a.y);ctx.lineTo(b.x,b.y);ctx.stroke();}}}
 else if(t==='wall'){rect(x,y,w,h,ART.wall.rammed,ART.accent.roofEdge,Math.max(.4,1.2/camera.mpp));}
 else if(t==='house'||t==='wing'){if(camera.mpp>26){rect(x,y,w,h,roofFill(p.roof||'home'),'#6b6353',1);return;}drawRoof(x,y,w,h,p.roof||'home',(p.ridge||'ns')==='ns',p.floors);}
 else if(t==='gate'){rect(x,y,w,h,ART.accent.door,ART.accent.ridge,Math.max(.4,1/camera.mpp));}
 else if(t==='well'){const c=pos({x,y});ctx.beginPath();ctx.arc(c.x,c.y,Math.max(1.5,4/camera.mpp),0,Math.PI*2);ctx.fillStyle='#7c8892';ctx.fill();ctx.strokeStyle='#4b4539';ctx.lineWidth=1;ctx.stroke();}
 else if(t==='tree'){const c=pos({x,y});const rr=Math.max(2,(p.size||5)/camera.mpp*1.2);
  ctx.beginPath();ctx.ellipse(c.x+rr*.25,c.y+rr*.5,rr*.9,rr*.55,0,0,Math.PI*2);ctx.fillStyle='rgba(60,52,40,.22)';ctx.fill();
  ctx.beginPath();ctx.arc(c.x,c.y,rr,0,Math.PI*2);ctx.fillStyle=ART.accent.tree;ctx.fill();ctx.strokeStyle='#2f5c2c';ctx.lineWidth=1;ctx.stroke();
  if(camera.mpp<5){ctx.beginPath();ctx.arc(c.x-rr*.25,c.y-rr*.28,rr*.5,0,Math.PI*2);ctx.fillStyle=ART.accent.treeLight;ctx.fill();}}
 else if(t==='stall'){rect(x,y,w,h,ART.accent.stall,ART.accent.ridge,Math.max(.4,1/camera.mpp));}
 else if(t==='field'){rect(x,y,w,h,ART.ground.field,null,0);if(camera.mpp<6){ctx.strokeStyle='rgba(140,157,98,.9)';ctx.lineWidth=Math.max(1,1.5);for(let fx=x+2;fx<x+w;fx+=3){const a=pos({x:fx,y:y+2}),b=pos({x:fx,y:y+h-2});ctx.beginPath();ctx.moveTo(a.x,a.y);ctx.lineTo(b.x,b.y);ctx.stroke();}}}
 else if(t==='pond'){rect(x,y,w,h,'#5f9ec2','#3f7fa2',Math.max(.6,1.4/camera.mpp));}
}
function drawBuildings(){
 if(camera.mpp>120)return;
 const k=camera.mpp;
 for(const b of TOWN_LAYOUT){
  const p=pos({x:b.x,y:b.y});const bw=b.w/k,bh=b.h/k;
  if(p.x+bw<-30||p.y+bh<-30||p.x>cssW+30||p.y>cssH+30)continue;
  if(k>34){rect(b.x,b.y,b.w,b.h,b.kind==='garden'?ART.ground.field:(b.kind==='pond'?'#6fa3c0':roofFill(b.roof||'home')),null,0);continue;}
  if(k>2.4){ // 中景：一整栋压成一个屋顶块，保留院墙边
   rect(b.x,b.y,b.w,b.h,b.kind==='garden'?ART.ground.field:ART.wall.plaster,null,0);
   const house=b.parts.find(q=>q.t==='house');
   if(house)rect(house.x,house.y,house.w,house.h,roofFill(b.roof||house.roof||'home'),ART.accent.ridge,Math.max(.6,1/k));
   continue;
  }
  rect(b.x-2,b.y-2,b.w+4,b.h+4,'rgba(60,52,40,.10)',null,0);
  for(const part of b.parts)drawPart(part);
  if(b.public&&k<6){text(b.name,{x:b.x+b.w/2,y:b.y-8},11,'#3d3830',600,true);}
 }
}
function drawTowns(){for(const p of LANDMARKS){if(!visible(p))continue;if(camera.mpp>3500&&p.type!=='capital'&&p.type!=='sect')continue;
 if(camera.mpp>50&&p.active&&['market','street','homes','gate','shop','office','inn'].includes(p.type))continue;
 if(camera.mpp<5&&p.active&&p.type==='village'){// 村庄细部建筑图簇
 for(let i=0;i<14;i++){const s=noise(i, p.x/300+p.y/700);const x=p.x+(i%5-2)*70+s*9,y=p.y+(Math.floor(i/5)-1)*77+s*6;rect(x,y,35,42,'#c8a789','#947a57');}}
 const large=['capital','sect'].includes(p.type),r=large?11:p.active?8:7;
 circle(p,r,p.active?'#385e4d':'#866653','#f9edd4',2);
 if(p.type==='capital'){let s=pos(p);ctx.fillStyle='#f4e9cd';ctx.fillRect(s.x-8,s.y-13,16,10);ctx.strokeStyle='#735a40';ctx.strokeRect(s.x-8,s.y-13,16,10);}
 const title=p.name.replace(/^临安县·/,'').replace(/^青云山·/,'');const nameSize=large?13:camera.mpp>50?12:11;
 if(camera.mpp>200&&p.active&&p.id!=='songlin'&&p.id!=='qingyun')continue;
 if((camera.mpp<130||large) && !(camera.mpp<25&&['market','street','homes','shop','office','inn','gate'].includes(p.type)) )text(title,{x:p.x,y:p.y-(r*camera.mpp+Math.max(30,camera.mpp*9))},nameSize,large?'#5d4936':'#354f3c',large?750:600);
 }}
/** 小人素材：底衣层 + 头饰层 + 持物层，三层同一画布对齐；缺素材时退回圆形标记。 */
function drawSprite(layers,x,y,h){
 const bank=sprites;const wpx=h*32/44;
 if(!bank||!layers||!layers.base){ctx.beginPath();ctx.arc(x,y,h*.36,0,Math.PI*2);ctx.fillStyle='#6d7f6a';ctx.fill();return false;}
 ctx.drawImage(layers.base,x-wpx/2,y-h+4,wpx,h);
 if(layers.hat)ctx.drawImage(layers.hat,x-wpx/2,y-h+4,wpx,h);
 if(layers.held)ctx.drawImage(layers.held,x-wpx/2,y-h+4,wpx,h);
 return true;
}
function drawAvatars(){if(camera.mpp>350)return;
 const people=new Map(w.people.map(p=>[p.id,p]));
 // 只画"世界认为他在那里"的人：位置与所在场所一致，室内与夜间居家者不在街上。
 const onMap=visibleActors(w).filter(a=>camera.mpp>22?a.leader:true).filter(a=>visible(a));
 onMap.sort((a,b)=>Number(b.leader)-Number(a.leader)||dist(a,w.player.mapPos)-dist(b,w.player.mapPos));
 const taken=[],max=camera.mpp>60?6:camera.mpp>14?12:camera.mpp>3?20:150;
 for(const a of onMap){if(taken.length>=max)break;
  const pp=pos(a);if(taken.some(q=>Math.hypot(q.x-pp.x,q.y-pp.y)<(camera.mpp>1.5?26:16)))continue;
  taken.push(pp);const person=people.get(a.id);if(!person)continue;
  const h=a.leader?30:camera.mpp<1.3?24:22;
  ctx.fillStyle='rgba(15,32,22,.16)';ctx.beginPath();ctx.ellipse(pp.x,pp.y+2,h*.26,h*.12,0,0,Math.PI*2);ctx.fill();
  // 将领与修士在世界图上是头像；其余是走路小人。
  let ok=false;
  if(a.leader&&peopleBank&&peopleBank.ready){
   const r=h*.62;
   ok=peopleBank.drawPortrait(ctx,person,pp.x,pp.y-h*.55,r);
   ctx.strokeStyle='#c8a34e';ctx.lineWidth=2.6;ctx.beginPath();ctx.arc(pp.x,pp.y-h*.55,r,0,Math.PI*2);ctx.stroke();
  }else if(peopleBank&&peopleBank.ready){
   const dir=dirFor(a.dx,a.dy,'down');const step=stepOf(!!(a.dx||a.dy),clockMs);
   ok=peopleBank.draw(ctx,person,pp.x,pp.y,h,dir,step);
  }
  if(!ok){
   const layers=sprites?sprites.layers(person):null;
   ok=drawSprite(layers,pp.x,pp.y,h);
   if(!ok){const fill=faces[Number(a.id.slice(-2))%faces.length];ctx.beginPath();ctx.arc(pp.x,pp.y-h*.3,h*.3,0,Math.PI*2);ctx.fillStyle=fill;ctx.fill();}
  }
  if((camera.mpp<.95)||(a.leader&&camera.mpp<2))screenText((a.title?a.title+' · ':'')+person.name+' · '+a.state,pp.x,pp.y+h*.22,a.leader?12:11,a.leader?'#583f30':'#30503d');
  if(selected?.kind==='npc'&&selected.data.id===a.id){ctx.strokeStyle='#bd713f';ctx.lineWidth=2.5;ctx.beginPath();ctx.arc(pp.x,pp.y-h*.4,h*.55,0,Math.PI*2);ctx.stroke();}
 }
}
function drawPlayer(){const p=pos(w.player.mapPos);
 const me={id:'player',job:w.player.role==='修士'?'修士':w.player.role,age:30,sex:'男',wealth:200};
 const look=sprites?sprites.layers(me):null;
 const h=32;
 ctx.fillStyle='rgba(21,63,52,.18)';ctx.beginPath();ctx.ellipse(p.x,p.y+2,10,4.4,0,0,Math.PI*2);ctx.fill();
 ctx.strokeStyle='#f4d07c';ctx.lineWidth=3;ctx.beginPath();ctx.arc(p.x,p.y-h*.42,h*.46,0,Math.PI*2);ctx.stroke();
 const moving=!!w.player.route;
 const okMe=peopleBank&&peopleBank.ready?peopleBank.draw(ctx,me,p.x,p.y,h,dirFor(w.player.dirX,w.player.dirY,'down'),stepOf(moving,clockMs)):false;
 if(!okMe&&!drawSprite(look,p.x,p.y,h)){ctx.beginPath();ctx.arc(p.x,p.y-h*.3,12,0,Math.PI*2);ctx.fillStyle='#153f34';ctx.fill();}
 screenText('我',p.x,p.y+8,11,'#3a2f1e',800);
}
function drawRoute(){const r=w.player.route;if(!r)return;const points=[w.player.mapPos,...r.path.slice(r.index+1)];drawPath(points.map(p=>[p.x,p.y]));ctx.strokeStyle='rgba(255,250,228,.8)';ctx.lineWidth=6;ctx.stroke();drawPath(points.map(p=>[p.x,p.y]));ctx.strokeStyle='#cc7c40';ctx.lineWidth=3;ctx.setLineDash([8,7]);ctx.stroke();ctx.setLineDash([]);circle(r.goal,6,'#b7653a','#fff0d7',2);}
function drawSelection(){if(!selected?.point)return;const p=pos(selected.point);ctx.beginPath();ctx.arc(p.x,p.y,24,0,Math.PI*2);ctx.strokeStyle='#bd713f';ctx.lineWidth=2.5;ctx.stroke();ctx.beginPath();ctx.moveTo(p.x-30,p.y);ctx.lineTo(p.x+30,p.y);ctx.moveTo(p.x,p.y-30);ctx.lineTo(p.x,p.y+30);ctx.stroke();}
function drawMap(){if(!ctx)return;ctx.clearRect(0,0,cssW,cssH);drawGround();if(camera.mpp>=26&&mapMode==='terrain'){drawWorldLayer();return;}drawFactionLayer();drawPolitical();drawRelief();drawFields();drawWater();drawRoads();drawStreets();drawWall();drawBuildings();drawTowns();drawRoute();drawArmies();drawAvatars();{const mb=mapBattle(w);if(mb)drawMapBattle(mb,ctx,pos,camera.mpp,{cssW,cssH});}drawPlayer();drawSelection();}
function profile(){const p=w.player,r=worldReport(w),place=placeAt(p.mapPos);
 $('name').textContent=p.name;$('place').textContent=p.indoor?(getPlace(p.indoor)?.name||'室内'):place.name;
 $('time').textContent=currentTime();$('population').textContent=`临安县及周边 ${r.population.toLocaleString('zh-CN')}人`;
 $('role').textContent=`${p.role} · ${p.stats.realm}`;
 const purse=$('purse');if(purse)purse.textContent=`银 ${p.silver??0} · 货 ${bagWeight(w)}斤`;
 $('hpBar').style.width=`${clamp(p.stats.hp/p.stats.maxHp*100,0,100)}%`;$('staminaBar').style.width=`${clamp(p.stats.stamina/p.stats.maxStamina*100,0,100)}%`;
 $('hpTxt').textContent=`${p.stats.hp}/${p.stats.maxHp}`;$('staminaTxt').textContent=`${Math.round(p.stats.stamina)}/${p.stats.maxStamina}`;
 $('position').textContent=`坐标 ${Math.round(p.mapPos.x)},${Math.round(p.mapPos.y)}m · 海拔 ${terrainHeight(p.mapPos.x,p.mapPos.y)}m`;
 $('speed').textContent=w.player.route?`行走中 · ${Math.round(w.player.route.covered)}/${Math.round(w.player.route.total)}m`:'未移动';
 $('mapScale').textContent=camera.mpp<1?`${Math.round(camera.mpp*100)}厘米/像素`:camera.mpp<1000?`${Math.round(camera.mpp)}米/像素`:`${(camera.mpp/1000).toFixed(1)}公里/像素`;
 $('travelMode').textContent='步行';$('travelMode').hidden=false;
 const kk=karmaReport(w);if($('karma')){$('karma').textContent=kk.value;$('karma').title=`${kk.tier}：突破成功率 ${Math.round(kk.breakthrough.chance*100)}%`;}
 $('realmButton').hidden=p.role!=='修士';
 $('stop').hidden=!w.player.route;
}
function showSheet(obj){selected=obj;const target=$('sheet');if(!obj){target.hidden=true;target.innerHTML='';return;}
 let title='',sub='',body='',buttons='';const player=w.player.mapPos;
 if(obj.kind==='structure'){const b=obj.data;const st=openingStatus(b.id,w.hour),perm=canEnter(w,b.id);
  const kindName={government:'官署',home:'民居',forge:'工坊',grain:'粮仓',inn:'客栈',school:'学塾',fort:'营署',sect:'宗门'}[b.kind]||'工商建筑';
  title=b.name;sub=`${Math.round(dist(player,b.door))}米 · ${kindName} · ${st.label}`;
  body=`${b.desc||'这座建筑暂未开放室内。'}
  <p class="near">通行：${perm.ok?'可入':safe(perm.reason)}</p>`;
  const near=visibleActors(w).filter(a=>dist(a,{x:b.x,y:b.y})<260).slice(0,4);
  body+=`<p class="near">门前可见：${near.length?near.map(a=>safe((w.people.find(p=>p.id===a.id)?.name||'行人')+'·'+a.state)).join('、'):'此刻无人'}</p>`;
  const canEnterNow=dist(player,b.door)<35&&getPlace(b.id)&&st.open&&perm.ok;
  buttons=`<button data-action="go">沿路前往门口</button>${canEnterNow?'<button data-action="enter">从正门进入</button>':''}${w.player.route?'<button data-action="stop" class="quiet">停下</button>':''}`;
 }else if(obj.kind==='landmark'){const b=obj.data;const st=openingStatus(b.id,w.hour);
  title=b.name;sub=`${escapeHtml(b.faction||'')}${b.active?' · 已开放':' · 地理预留'} · ${st.label}`;body=b.desc||'';
  const flyGate=canFly(w),zoneRule=flightRuleAt(w,{x:b.x,y:b.y});
  if(b.active&&!flyGate.ok)body+=`<p class="near">御剑：${safe(flyGate.reason)}</p>`;
  else if(b.active&&!zoneRule.ok)body+=`<p class="near">空域：${safe(zoneRule.reason)}</p>`;
  else if(b.active&&zoneRule.ok&&zoneRule.zone!=='野外空域')body+=`<p class="near">空域：${safe(zoneRule.zone)}，此处可起剑。</p>`;
  buttons=b.active?`<button data-action="go">步行前往</button>${flyGate.ok&&zoneRule.ok?'<button data-action="fly" class="quiet">御剑前往</button>':''}`:'<button disabled>本区域未开放</button>';
 }else if(obj.kind==='npc'){const a=obj.data,p=w.people.find(x=>x.id===a.id);const vis=actorVisibility(w,p);
  title=p?.name||'人物';sub=`${a.title||p?.job||'行人'} · ${Math.round(dist(player,a))}米 · ${a.state}`;
  body=`${vis.visible?`他/她此刻正在${placeById(vis.where)?.name||vis.where}（${vis.reason}）。`:`${vis.reason}，你现在看不到此人。`}
  此人物是世界人口档案中的真实ID，位置与行动来自同一套规则，不是随机刷新的装饰。`;
  buttons=`<button data-action="go">走近此人</button>`;
 }else{title='地面目标';sub=`距你 ${Math.round(dist(player,obj.point))}米 · 海拔 ${terrainHeight(obj.point.x,obj.point.y)}米`;body='这里是同一张连续地图上的一处地点。移动需要时间，河流、城墙与墙体不能穿过。';buttons=`<button data-action="go">前往此处</button><button data-action="rest" class="quiet">原地歇息一刻</button>`;}
 const h=`<div class="sheet-header"><div><small>${escapeHtml(sub)}</small><h3>${escapeHtml(title)}</h3></div><button class="quiet" id="closeSheet" aria-label="关闭地点卡片">✕</button></div><div class="sheet-body">${body}</div><div class="sheet-actions">${buttons}</div>`;
 target.innerHTML=h;target.hidden=false;$('closeSheet').onclick=()=>showSheet(null);
 target.querySelector('[data-action="go"]')?.addEventListener('click',()=>goTarget());
 target.querySelector('[data-action="enter"]')?.addEventListener('click',()=>enter());
 target.querySelector('[data-action="fly"]')?.addEventListener('click',()=>flyTarget());
 target.querySelector('[data-action="closeregion"]')?.addEventListener('click',()=>showSheet(null));
 target.querySelector('[data-action="gotoregion"]')?.addEventListener('click',()=>goTarget());
 target.querySelector('[data-action="stop"]')?.addEventListener('click',()=>{stopJourney(w);profile();scheduleSave();toast('你停下了。');});
}
const escapeHtml=s=>safe(s);
function flyTarget(){if(!selected)return;const goal=selected.kind==='structure'?selected.data.door:selected.kind==='npc'?{x:selected.data.x,y:selected.data.y}:selected.point;
 const r=beginFlight(w,goal,selected.data?.id||null);if(!r.ok)return toast(r.error);toast(`御剑而行 · 直线 ${Math.round(r.meters)} 米`);showSheet(null);profile();scheduleSave();}
function goTarget(){if(!selected)return;const goal=selected.kind==='structure'?selected.data.door:selected.kind==='npc'?{x:selected.data.x,y:selected.data.y}:selected.kind==='region'?{x:selected.data.x,y:selected.data.y}:selected.point;
 if(selected.kind==='landmark'&&!selected.data.active)return toast('此区域尚未开放，暂无可运行的世界实体。');
 const r=beginJourney(w,goal,selected.data?.id||null);if(r.ok){toast(`开始步行 · 路线 ${Math.round(r.meters)} 米`);showSheet(null);scheduleSave();}else toast(r.error);
}
function enter(){const id=selected?.data?.id;let r=enterStructure(w,id);if(!r.ok)return toast(r.error);showSheet(null);showIndoor();scheduleSave();}
function showIndoor(){if(!w.player.indoor)return;const win=$('indoor'),svg=$('indoorMap'),place=getPlace(w.player.indoor);win.hidden=false;
 svg.innerHTML=interiorAtlas(w);$('indoorName').textContent=place?.name||'建筑室内';
 $('exitRoom').onclick=()=>{exitStructure(w);win.hidden=true;scheduleSave();profile();};
 svg.onclick=e=>{if(e.target.closest('[data-exit]')){$('exitRoom').click();}else if(e.target.closest('[data-npc]')){const id=e.target.closest('[data-npc]').dataset.npc;const p=w.people.find(x=>x.id===id);toast(`${p?.name||id} · ${p?.job||'人物'}`);}};
}
function pointerPoint(e){const rect=canvas.getBoundingClientRect();return{x:e.clientX-rect.left,y:e.clientY-rect.top};}
/** 命中判定在屏幕空间：手指抬起的位置必须落在标记 22px 以内，缩放与拖动不会命中任何地点。 */
function nearestScreenMarker(screenPt,worldPt){
 const cands=[];
 for(const a of visibleActors(w)){const p2=pos(a);cands.push({kind:'npc',data:a,screen:p2,d:Math.hypot(p2.x-screenPt.x,p2.y-screenPt.y)});}
 if(camera.mpp<35)for(const b of STRUCTURES){const p2=pos({x:b.x+b.w/2,y:b.y+b.h/2});cands.push({kind:'structure',data:b,screen:p2,point:b.door,d:Math.hypot(p2.x-screenPt.x,p2.y-screenPt.y)});}
 for(const l of LANDMARKS){if(!l.active)continue;const p2=pos(l);cands.push({kind:'landmark',data:l,screen:p2,d:Math.hypot(p2.x-screenPt.x,p2.y-screenPt.y)});}
 cands.sort((a,b)=>a.d-b.d);
 const best=cands[0];if(!best||best.d>22)return null;
 return{kind:best.kind,data:best.data,point:best.point||best.data.point||best.data};
}
function hitAt(screenPt,worldPt){return nearestScreenMarker(screenPt,worldPt);}
function zoomAt(factor,screenX=cssW/2,screenY=cssH/2,silent=false){const before=unpos(screenX,screenY);camera.mpp=clamp(camera.mpp*factor,.25,16000);const after=unpos(screenX,screenY);camera.x+=before.x-after.x;camera.y+=before.y-after.y;if(silent)requestProfile();else{profile();scheduleSave();}}
function updateCamera(old,newPt){camera.x-=(newPt.x-old.x)*camera.mpp;camera.y-=(newPt.y-old.y)*camera.mpp;}
function setupGestures(){
 // 手势判定的唯一准则：只有"单指按下后几乎没动、且全程没有第二根手指"才算点击。
 canvas.addEventListener('pointerdown',e=>{if(e.button!==0)return;e.preventDefault();try{canvas.setPointerCapture(e.pointerId);}catch{}
  const pt=pointerPoint(e);pointer.set(e.pointerId,pt);
  if(pointer.size===1){dragStart=pt;gestureMoved=false;multiTouched=false;downAt=performance.now();}
  else{multiTouched=true;gestureMoved=true;const a=[...pointer.values()];pinch={dist:Math.hypot(a[0].x-a[1].x,a[0].y-a[1].y),mid:{x:(a[0].x+a[1].x)/2,y:(a[0].y+a[1].y)/2}};}
 });
 canvas.addEventListener('pointermove',e=>{if(!pointer.has(e.pointerId))return;e.preventDefault();
  const last=pointer.get(e.pointerId),now=pointerPoint(e);pointer.set(e.pointerId,now);
  if(pointer.size>=2){multiTouched=true;gestureMoved=true;
   const a=[...pointer.values()];if(a.length<2)return;
   const d=Math.hypot(a[0].x-a[1].x,a[0].y-a[1].y);const mid={x:(a[0].x+a[1].x)/2,y:(a[0].y+a[1].y)/2};
   if(pinch&&pinch.dist>8&&d>8){zoomAt(pinch.dist/d,mid.x,mid.y,true);
    camera.x-=mid.x-pinch.mid.x;camera.y-=mid.y-pinch.mid.y;}// 双指按住不放时平移跟随，缩放不额外产生位移
   pinch={dist:d,mid};return;}
  if(dragStart&&Math.hypot(now.x-dragStart.x,now.y-dragStart.y)>8)gestureMoved=true;
  if(gestureMoved){const k=camera.mpp;camera.x-=(now.x-last.x)*k;camera.y-=(now.y-last.y)*k;requestProfile();}
 });
 const end=e=>{if(!pointer.has(e.pointerId))return;const last=pointer.get(e.pointerId);
  const single=pointer.size===1;pointer.delete(e.pointerId);
  const still=last&&dragStart?Math.hypot(last.x-dragStart.x,last.y-dragStart.y):99;
  const quick=performance.now()-downAt<600;
  const g=classifyGesture({pointers:pointer.size+(single?1:0),moved:gestureMoved,multiTouched,still,duration:performance.now()-downAt});
  const tap=canSelect(g)&&(single||pointer.size===0);
  if(!pointer.size){pinch=null;dragStart=null;multiTouched=false;gestureMoved=false;}
  if(tap){const p=unpos(last.x,last.y);
   if(camera.mpp>=26&&mapMode==='terrain'){const rg=regionAt(realmMap(),p);if(rg){showSheet(realmSheet({data:rg}));}else showSheet(null);return;}
   const h=hitAt(last,p);if(h)showSheet(h);else showSheet(null);}
 };
 canvas.addEventListener('pointerup',end);
 canvas.addEventListener('pointercancel',e=>{pointer.delete(e.pointerId);gestureMoved=true;multiTouched=true;pinch=null;dragStart=null;});
 canvas.addEventListener('wheel',e=>{e.preventDefault();const p=pointerPoint(e);zoomAt(e.deltaY<0?.83:1.2,p.x,p.y);},{passive:false});
 canvas.addEventListener('contextmenu',e=>e.preventDefault());
}
function itemIcon(id){const img=sprites?.item(id);return img?`<img src="${sprites.base+sprites.files.get('item:'+id)}" alt="${safe(itemById(id)?.name||'')}">`:'<span class="sw"></span>';}
function renderGoods(){
 const here=canTradeHere(w),place=placeById(w.player.place)?.name||'';
 const rows=ITEMS.map(it=>{
  const price=priceOf(w,it.id),have=inventory(w)[it.id]||0;
  return `<article class="shop-item">${itemIcon(it.id)}<div class="meta"><strong>${safe(it.name)}</strong><span>${price} 文/${safe(it.unit)} · 身带 ${have}</span></div>
  <button data-buy="${it.id}" ${here?'':'disabled'}>买1</button><button data-sell="${it.id}" ${here&&have>0?'':'disabled'}>卖1</button></article>`;
 }).join('');
 $('records').innerHTML=`<h2>物产与市价</h2><p>${here?`你正在${safe(place)}，可以议价。`:'这里不是市集——东市、粮行、铁铺一带才能买卖。'}</p>
 <article class="entry">银钱 ${w.player.silver??0} 两的铜钱数 · 负重 ${bagWeight(w)} 斤 · 米价 ${w.price} 文/斗</article>${rows}`;
}
function renderQuests(){
 const open=contractsFor(w),mine=w.player.contracts||[];
 const card=(c,accepted)=>`<article class="quest"><header><strong>${safe(c.title)}</strong><span class="tag">${safe(factionById(c.faction)?.name||'')}</span></header>
  <p>${safe(c.text)}</p><small>地点：${safe(placeById(c.target)?.name||c.target)} · 酬劳 ${c.pay} 文 · 第${c.expireDay}日过期</small><br>
  ${accepted?`<button data-complete="${c.id}">交差</button>`:`<button data-accept="${c.id}">接下</button>`}</article>`;
 $('records').innerHTML=`<h2>官府与商会的委托</h2><p>委托由当日世界状态生成，不是写死的任务表；同一天重开也只是同一批。</p>
 ${mine.map(c=>card(c,true)).join('')||''}${open.map(c=>card(c,false)).join('')||'<p>今日没有新的委托。</p>'}`;
}
function renderWar(){
 ensureWar(w);
 const r=warReport(w);
 const auth=authorityReport(w);
 const identity=`<article class="entry"><strong>你是：${safe(rankOf(w))}</strong><br><small>${safe(rankInfo(w).note)}</small><br>
  ${auth.map(a=>`<span class="tag">${a.allowed?'✔':'✖'} ${safe(a.label)}</span>`).join(' ')}<br>
  <small>身份是调试入口；正史里要考试、军功、世袭或禅位。</small><br>
  ${['皇帝','将帅','校尉','小兵','平民'].map(k=>`<button data-rank="${k}" ${k===rankOf(w)?'disabled':''}>${k}</button>`).join('')}</article>`;
 const rows=r.field.map(a=>{
  const cmd=canLead()?`<button data-lead="${a.id}">${w.war.command===a.id?'你已统领':'领兵'}</button>`:'';
  const join=`<button data-join="${a.id}">从军</button>`;
  return `<article class="war-row"><header><strong>${a.emblem?`<span class="glyph">${safe(a.emblem.glyph)}</span>`:''}${safe(a.corps)}</strong><span class="tag">${safe(factionById(a.faction)?.name||'')}</span></header>
  <p>将 ${safe(a.commander)} · 战历 ${a.veteran??0}（%越低越像炮灰）· 士气 ${a.morale} · ${safe(a.state)}</p>
  <p>战兵 ${a.combat.toLocaleString()} · 辅兵 ${a.support.toLocaleString()} · 战损 ${a.losses.combat.toLocaleString()}/${a.losses.support.toLocaleString()}</p>
  <small>日耗 ${(a.needKg/1000).toFixed(0)} 吨 · 自携粮 ${a.supplyDays} 日</small>
  <p class="arms">${(a.digest?.arms||[]).map(x=>`${x.name} ${x.share}%`).join(' · ')}</p>
  <p><small>${safe(a.digest?.armor||'')} · ${safe(a.digest?.weapon||'')} · 训练 ${a.digest?.train??30} · 阵 ${safe(a.digest?.formation||'横阵')} · 战力 ×${a.digest?.quality??1}</small></p>
  <p class="warbtns">
   <button data-gear="${a.id}:1:1">皮甲+铁枪</button>
   <button data-gear="${a.id}:2:1">札甲+铁枪</button>
   <button data-drill="${a.id}">操练至 60</button>
   ${Object.entries(FORMATIONS).map(([k,v])=>`<button data-form="${a.id}:${k}">${v.name}</button>`).join('')}
  </p><br>
  <button data-march="${a.id}">开赴县城</button><button data-return="${a.id}">回师</button>${cmd}${join}</article>`;
 }).join('')||'<p>天下暂无出征之军。</p>';
 const levy=FACTIONS.map(f=>{
  const c=levyCapacity(w,f.id);
  return `<article class="entry"><strong>${safe(f.name)}</strong> 可征 ${c.combat.toLocaleString()} 战兵（辅兵 ${Math.round(c.combat*3).toLocaleString()}）<br>
  <button data-levy="${f.id}" data-men="50000" ${c.combat>=50000?'':'disabled'}>征 5 万</button>
  <button data-levy="${f.id}" data-men="150000" ${c.combat>=150000?'':'disabled'}>征 15 万</button></article>`;
 }).join('');
 const log=(w.war.log||[]).slice(-10).reverse();
 $('records').innerHTML=`<h2>天下兵事 · 第 ${r.day} 日</h2>${identity}
 <p>屏上一面旗就是账本里一支军：旗形是国别，旗字是国徽，旗号是番号，旗色是国色。</p>
 <p>在册 〔${r.total.toLocaleString()}〕 人（战兵+辅兵），出征 ${r.armies} 军。</p>${rows}
 <h3>兵种与装备</h3><p>兵种配比由国情决定：乡野多步卒、商会多弓骑、御城重甲、青云出剑修。换装按比例付钱，先武装前军。</p>
 <p>科技：${Object.entries(TECHS).map(([k,t])=>{
  const own=!!w.tech?.[k];
  return `<button data-tech="${k}" ${own?'disabled':''}>${own?'已习':''}${t.name}（${(t.cost/10000).toFixed(0)}万）</button>`;
 }).join('')}</p>
 <p><small>大宁府库 ${(purseOf(w,'court')||0).toLocaleString()} 文 · 钱从府库出，不从天降</small></p>
 <h3>征发（需圣旨）</h3>${levy}<h3>战报</h3>${log.map(e=>`<article class="entry"><small>${safe(e.type)}</small> ${safe(e.text)}</article>`).join('')||'<p>尚未接战。</p>'}`;
}
function personLine(w,p){
 try{const a=personAttitude(w,p);return `${a.reason} → ${a.label}`;}catch{return p.temper||'';}
}
function canLead(){try{return !!rankInfo(w).lead;}catch{return false;}}
function handleRecordsClick(e){
 const t=e.target.closest('button');if(!t)return;
 if(t.dataset.buy){const r=buyItem(w,t.dataset.buy,1);toast(r.ok?`买下${itemById(t.dataset.buy).name}，花 ${r.cost} 文`:r.error);if(r.ok){profile();scheduleSave();renderGoods();}return;}
 if(t.dataset.sell){const r=sellItem(w,t.dataset.sell,1);toast(r.ok?`卖出，得 ${r.gain} 文`:r.error);if(r.ok){profile();scheduleSave();renderGoods();}return;}
 if(t.dataset.accept){const r=acceptContract(w,t.dataset.accept);toast(r.ok?`接下了「${r.contract.title}」`:r.error);if(r.ok){scheduleSave();renderQuests();}return;}
 if(t.dataset.levy){const men=Number(t.dataset.men)||50000;
  try{const a=createArmy(w,t.dataset.levy,{combat:men,seed:Date.now()%100000});note(w,'兵事',`${a.name}征发 ${men.toLocaleString()} 战兵、${a.support.toLocaleString()} 辅兵。`);toast(`${a.name}已集结，日耗 ${Math.round(armyNeeds(a).totalKg/1000)} 吨`);profile();scheduleSave();renderWar();}
  catch(err){toast(err.message);}return;}
 if(t.dataset.levy){const r=levySect(w,t.dataset.levy,4);
  toast(r.ok?`征得 ${r.stones} 块灵石，敌意升至 ${r.hostility}`:r.error);
  if(r.ok){scheduleSave();otherPanels('xian');}return;}
 if(t.dataset.buystone){const r=buyStones(w,+t.dataset.buystone);
  toast(r.ok?`兑得 ${r.stones} 块灵石，手续费 ${fmtCoins(r.fee)}`:r.error);
  if(r.ok){scheduleSave();otherPanels('xian');}return;}
 if(t.dataset.hire){const realm=t.dataset.hire;const r=hireRetainer(w,{sect:'散修',realm,patron:'court'});
  toast(r.ok?`招得${r.retainer.realmName}供奉，耗银 ${r.price.toLocaleString()} 文`:r.error);
  if(r.ok){scheduleSave();otherPanels('xian');}return;}
 if(t.dataset.detectroot){const r=detectRoot(w);toast(r.ok?`测出：${r.name}`:r.error);if(r.ok){profile();scheduleSave();otherPanels('xian');}return;}
 if(t.dataset.adopt){const ids=w.people.filter(p=>p.status==='alive'&&!familyMembers(w).some(m=>m.id===p.id)&&p.age>=16&&p.age<=40&&p.root).slice(0,1);
  if(!ids.length)return toast('城中暂无合适的散修可收');
  const r=joinFamily(w,ids[0].id,'收族');toast(r.ok?`${ids[0].name} 入族`:r.error);if(r.ok){scheduleSave();renderFamily();}return;}
 if(t.dataset.marry){const list=candidatesFor(w,t.dataset.marry);if(!list.length)return toast('没有合适的婚配人选');
  const best=list.sort((a,b)=>rootRank(w,b)-rootRank(w,a)||ageOf(w,a)-ageOf(w,b))[0];
  const r=marry(w,t.dataset.marry,best.id);toast(r.ok?`${r.a.name} 与 ${r.b.name} 成亲`:r.error);if(r.ok){scheduleSave();renderFamily();}return;}
 if(t.dataset.bear){const [a,b]=t.dataset.bear.split(':');const r=conceive(w,a,b);
  toast(r.ok?`${r.child.name} 出生（${r.rootId==='none'?'无灵根':'有灵根'}）`:r.error);if(r.ok){profile();scheduleSave();renderFamily();}return;}
 if(t.dataset.famyear){const y=Number(t.dataset.famyear)||1;const r=ageFamily(w,y);
  toast(`过 ${y} 年：${r.grew} 人长岁${r.died.length?`，${r.died.join('、')}故去`:''}，家业 ${r.income>=0?'+':''}${r.income} 银`);
  scheduleSave();renderFamily();return;}
 if(t.dataset.practice){const r=practice(w,+t.dataset.practice||1);
  toast(r.ok?`吐纳得修为 +${r.gain}（经脉 ${Math.round(r.meridian)}${r.overload?'·负荷偏高':''}）`:r.error);
  if(r.ok){profile();scheduleSave();otherPanels('xian');}return;}
 if(t.dataset.breaklayer){const r=breakLayer(w);toast(r.ok?`突破：${r.name}`:r.error);if(r.ok){profile();scheduleSave();otherPanels('xian');}return;}
 if(t.dataset.breakrealm){const r=breakRealm(w,{pill:false});toast(r.ok?'筑基成功':r.error);if(r.ok){profile();scheduleSave();}else{scheduleSave();otherPanels('xian');}return;}
 if(t.dataset.restmeridian){const r=restMeridian(w,8);toast(`歇了八个时辰，经脉负荷降到 ${Math.round(r.meridian)}`);profile();scheduleSave();otherPanels('xian');return;}
 if(t.dataset.help){const r=helpPerson(w,t.dataset.help);
  toast(r.ok?r.line:r.error);if(r.ok){profile();scheduleSave();otherPanels('xian');}return;}
 if(t.dataset.ally){const r=seekAlly(w,t.dataset.ally);toast(r.ok?`与${attitudeOf(w,t.dataset.ally).name}结交${r.note?`·${r.note}`:''}`:r.error);if(r.ok){profile();scheduleSave();otherPanels('xian');}return;}
 if(t.dataset.raid){const r=raidSect(w,t.dataset.raid);
  toast(r.ok?`山门已破（供奉 ${r.power} 对 ${r.theirs}）`:r.error);
  if(r.ok){scheduleSave();otherPanels('xian');}return;}
 if(t.dataset.reform){const [lever,opt]=t.dataset.reform.split(':');
  const r=reform(w,lever,opt);
  toast(r.ok?`改${LEVERS[lever].name}为${LEVERS[lever].options[opt]}${r.resistance?`（阻力 ${Math.round(r.resistance)}）`:''}`:r.error);
  if(r.ok){profile();scheduleSave();otherPanels('ledger');}return;}
 if(t.dataset.quick){const inp=$('decree');if(inp)inp.value=t.dataset.quick;return;}
 if(t.id==='decreeBtn'||t.dataset.decree){const inp=$('decree');const text=(inp?.value||'').trim();
  if(!text)return;
  const r=issueOrder(w,text);
  toast(r.ok?r.reply:r.error);if(r.ok){profile();scheduleSave();otherPanels('court');}return;}
 if(t.dataset.talk){const text=prompt('问什么？（粮价/府库/军情/贪墨/民怨）')||'近来如何';
  const r=talkTo(w,t.dataset.talk,text);toast(`${r.staff}：${r.say}`);return;}
 if(t.dataset.mkt){
  const k=t.dataset.mkt;
  const r=k==='release'?releaseGrain(w,2000):k==='buy'?buyToGranary(w,2000):
    k==='tax'?setTax(w,.18):k==='taxdown'?setTax(w,.08):
    k==='salt'?setMonopoly(w,'salt',!w.market.monopoly.salt):
    k==='post'?buildPost(w):{ok:false,error:'未知操作'};
  toast(r.ok?((k==='tax'||k==='taxdown')?'税率已改':k==='post'?'驿传已增置':'已下市令'):r.error);
  if(r.ok){profile();scheduleSave();otherPanels('ledger');}return;}
 if(t.dataset.gear){const [id,armor,weapon]=t.dataset.gear.split(':').map(Number);
  const a=w.war.armies.find(x=>x.id===id);if(!a)return;
  const r=equip(w,a,{armor,weapon,share:.5});
  toast(r.ok?`换装 ${Math.round((r.share||0)*100)}%，耗银 ${r.cost.toLocaleString()} 文`:r.error);
  if(r.ok){profile();scheduleSave();renderWar();}return;}
 if(t.dataset.drill){const a=w.war.armies.find(x=>x.id===Number(t.dataset.drill));if(!a)return;
  const r=drill(w,a,60);toast(r.ok?`操练至 60，耗银 ${r.cost.toLocaleString()} 文`:r.error);
  if(r.ok){scheduleSave();renderWar();}return;}
 if(t.dataset.form){const [id,form]=t.dataset.form.split(':');const a=w.war.armies.find(x=>x.id===Number(id));if(!a)return;
  const r=setFormation(w,a,form);toast(r.ok?`列${FORMATIONS[form].name}`:r.error);if(r.ok){scheduleSave();renderWar();}return;}
 if(t.dataset.tech){const r=research(w,t.dataset.tech,'court');toast(r.ok?'习得技艺':r.error);if(r.ok){scheduleSave();renderWar();}return;}
 if(t.dataset.rank){setRank(w,t.dataset.rank);toast(`身份：${t.dataset.rank}`);profile();scheduleSave();renderWar();return;}
 if(t.dataset.lead){const r=takeCommand(w,Number(t.dataset.lead));toast(r.ok?'你已接管这一军':r.error);scheduleSave();renderWar();return;}
 if(t.dataset.join){const r=joinArmy(w,Number(t.dataset.join));toast(r.ok?'你编入行伍，只是其中一人':r.error);scheduleSave();renderWar();return;}
 if(t.dataset.march){const a=w.war.armies.find(x=>x.id===Number(t.dataset.march));if(!a)return;a.goal={x:0,y:0};a.state='行军';toast(`${a.name}开拔，向县城行军`);scheduleSave();renderWar();return;}
 if(t.dataset.return){const a=w.war.armies.find(x=>x.id===Number(t.dataset.return));if(!a)return;const seat=LANDMARKS.find(l=>l.id===factionById(a.faction)?.seat);a.goal=seat?{x:seat.x,y:seat.y}:{x:a.x,y:a.y};a.state='行军';toast(`${a.name}回师`);scheduleSave();renderWar();return;}
 if(t.dataset.advance){const r=advance(w,t.dataset.advance);toast(r.ok?`升${r.rank}：${r.grant}`:r.error);if(r.ok){profile();scheduleSave();renderCareer();}return;}
 if(t.dataset.path&&PATHS[t.dataset.path]){const r=joinPath(w,t.dataset.path);toast(r.ok?`入${PATHS[t.dataset.path].name}，从「${r.rank.name}」做起`:r.error);if(r.ok){scheduleSave();renderCareer();}return;}
 if(t.dataset.recmode){const r=recruitMen(w,10);toast(r.ok?`募得 ${r.men} 名部曲（上限 ${r.cap}）`:r.error);if(r.ok){profile();scheduleSave();renderCareer();}return;}
 if(t.dataset.land){const r=buyLand(w,Number(t.dataset.land)||10);toast(r.ok?`买田 ${r.land} 亩`:r.error);if(r.ok){profile();scheduleSave();renderCareer();}return;}
 if(t.dataset.shop){const r=openShop(w,t.dataset.shop);toast(r.ok?`${r.shop.name}开张`:r.error);if(r.ok){scheduleSave();renderCareer();}return;}
 if(t.dataset.caravan){const r=sendCaravan(w,{qty:Number(t.dataset.caravan)||10,days:12});toast(r.ok?'商队已出发':r.error);if(r.ok){scheduleSave();renderCareer();}return;}
 if(t.dataset.hirec){const r=hireCultivator(w,{realm:t.dataset.hirec});toast(r.ok?`${r.retainer.name}入你门下`:r.error);if(r.ok){scheduleSave();renderCareer();}return;}
 if(t.dataset.careertick){const r=tickCareer(w);toast(r.skipped?'本月已结（未满三十日）':`结算：铺面 ${r.shops>=0?'+':''}${r.shops} 银，田租 +${r.land}，军饷 -${r.wage}`);if(!r.skipped){scheduleSave();renderCareer();}return;}
 if(t.dataset.complete){const r=completeContract(w,t.dataset.complete);toast(r.ok?`交差，得 ${r.pay} 文`:r.error);if(r.ok){profile();scheduleSave();renderQuests();}return;}
}

/** 出身：五道并行。每一道都有“下一步要什么”，说清楚了才叫玩法，不然就是刷数值。 */
function renderCareer(){
 const r=careerReport(w);
 const sum=`<h2>出身与晋升</h2>
  <p>五道都能走到顶，但“顶”不是一回事：军功看战功与人头，官身看名望（也可以拿钱铺路），商贾看本钱与周转，仙途看灵根与灵石，乡望看田产与乡亲口碑。</p>
  <article class="entry">名望 <b>${r.fame}</b> · 战功 <b>${r.merit}</b> · 本钱 <b>${r.capital}</b> 银 · 田产 <b>${r.land}</b> 亩<br>
   私兵 <b>${r.men}</b>／上限 ${r.cap}（军饷 ${MEN_COST.upkeep} 银/人·月）· 铺面 ${r.shops} · 欠下人情债 <b>${r.debt}</b> 银
   ${r.top?'<br><b>你已在某一道登顶。</b>':''}</article>
  <p class="warbtns">${PATHLIST.map(p=>`<button data-path="${p.id}" ${w.career.ranks[p.id]>=0?'disabled':''}>入${safe(p.name)}</button>`).join('')}
   <button data-recmode="1">募兵 10 人（${10*(MEN_COST.enlist+MEN_COST.gear)} 银）</button>
   <button data-land="20">买田 20 亩（${20*18} 银）</button>
   <button data-careertick="1">结算本月</button></p>`;
 const cards=r.paths.map(p=>{
  const rows=p.next?`<small>下一步：${safe(p.next)} — 需 ${Object.entries(p.nextNeed||{}).map(([k,v])=>`${({merit:'战功',fame:'名望',capital:'本钱',land:'田产',qi:'道行'})[k]} ${v}`).join(' · ')||'无门槛'}</small>`:'<small>已登顶。</small>';
  return `<article class="entry" style="border-left:4px solid ${p.color}">
   <strong>${safe(p.name)} · ${safe(p.rank)}</strong> <span class="tag">${p.ready?'可晋升':'未达门槛'}</span><br>
   ${rows}<br><small>${safe(p.grant)}</small>
   ${p.ready?`<br><button data-advance="${p.id}">晋升${p.nextPay?`（付 ${p.nextPay} 银）`:''}</button>`:''}
   ${p.missing&&p.missing.length?`<br><small>还差：${p.missing.map(safe).join('、')}</small>`:''}
  </article>`;}).join('');
 const goods=`<h3>经商</h3><p class="warbtns">${Object.entries(SHOP_KINDS).map(([k,v])=>`<button data-shop="${k}">开${v.name}（${v.cost} 银）</button>`).join('')}
  ${[10,50,100].map(n=>`<button data-caravan="${n}">押商队 ${n} 担（约 ${n*26} 银）</button>`).join('')}</p>
  <h3>吐纳与突破</h3>${(()=>{const pr=practiceReport(w);
   return `<p>${safe(pr.root)} · <b>${safe(pr.layerName)}</b> · 修为 ${pr.progress}${pr.next?` / ${pr.next.need}`:''} · 经脉 ${pr.meridian}${pr.overloaded?'（已伤）':''}</p>
   <p class="warbtns"><button data-practice="1">吐纳一时辰</button><button data-practice="8">闭关八个时辰</button>
   <button data-breaklayer="1">突破下一层</button><button data-breakrealm="1">冲击筑基</button><button data-restmeridian="1">歇息养脉</button></p>`;})()}
  <h3>招揽修士（走灵石，不走金银）</h3><p class="warbtns">${['found','core'].map(id=>`<button data-hirec="${id}">聘${id==='found'?'筑基':'金丹'}客卿</button>`).join('')}</p>`;
 const log=r.log.length?r.log.map(l=>`<article class="entry"><small>第${l.day}日</small> ${safe(l.msg)}</article>`).join(''):'<p>还没有什么可记的。</p>';
 $('records').innerHTML=`${sum}${cards}<h3>营生</h3>${goods}<h3>履历</h3>${log}`;
}
const PATHLIST=[{id:'military',name:'军功'},{id:'office',name:'官身'},{id:'merchant',name:'商贾'},{id:'xian',name:'仙途'},{id:'folk',name:'乡望'}];

function renderXian(){
 const r=xianReport(w);
 const qi=r.regions.map(g=>`${g.name} 灵气 ${g.qi}（每万人 ${g.density} 名修士）`).join(' · ');
 const sects=r.sects.map(sx=>`<article class="entry"><strong>${safe(sx.name)}</strong> · 道众 ${sx.disciples} · 战力 ${sx.power}${sx.destroyed?' · 已破':''}<br>
  <button data-raid="${sx.id}" ${sx.destroyed?'disabled':''}>遣供奉灭门</button></article>`).join('');
 const ret=r.retainers.length?r.retainers.map(x=>`<article class="entry">${safe(x.name)} · 战力 ${x.power} · 月俸 ${x.upkeep.toLocaleString()} 文</article>`).join(''):'<p>尚无供奉。灵根是天生的，供奉是钱买的。</p>';
 const jobs=r.mortals.map(j=>`${j.name} ${j.count} 人（月钱 ${j.wage} 文）`).join(' · ');
 const m=moneyReport(w);const threat=assassinThreat(w);const prot=courtProtection(w);
 const danger=threat.threat>prot*1.5?`<b style="color:#a33">危：${threat.sect.name} 的战力 ${threat.threat} 已超过护国力量的 1.5 倍——元婴夜入禁宫，皇帝会死。</b>`
   :threat.threat>prot?`<b>警：${threat.sect.name}（${threat.threat}）已能破宫，护国力量 ${prot} 不足。</b>`
   :`安：护国力量 ${prot}（禁宫大阵 420 + 供奉 ${prot-420}），${threat.sect?`可挡${threat.sect.name}（${threat.threat}）`:'无外敌'}`;
 const stoneBox=`<h3>灵石与钱庄</h3><article class="entry">灵石 <b>${m.stones}</b> 块 · 府库 ${fmtCoins(m.coins)} · 本月官庄剩 ${m.quota} 块<br>
  官庄收 5% 手续费，兑 1 块灵石需 ${fmtCoins(m.stonePrice)}；修士不肯拿灵石换金银，所以这条路人人都知道，但没人爱走。</article>
  <p class="warbtns">${[1,5,20].map(n=>`<button data-buystone="${n}">兑 ${n} 块灵石（${fmtCoins(m.stonePrice*n)}）</button>`).join('')}</p>
  <h3>征索</h3><p class="warbtns">${(ensureCultivation(w).sects||[]).filter(s=>!s.destroyed).map(s=>`<button data-levy="${s.id}">向${s.name}征 4 块灵石（敌意 +35）</button>`).join('')}</p>
  <h3>护国</h3><article class="entry">${danger}<br><small>护国力量 = 禁宫大阵 + 御用供奉；宗门战力 = 道众 × 境界 + 护山大阵 + 符箓 + 灵兽。</small></article>`;
 const k=karmaReport(w);const bt=k.breakthrough;
 const dr=daoReport(w);
 const stanceRows=dr.list.slice(0,8).map(x=>`<article class="entry"><strong>${safe(x.name)}</strong> <small>${safe(x.stance)}·${safe(x.creed||'')}</small> · ${x.label}（${x.score}）<br>
  <small>${safe(x.reason)}</small> ${x.hostile?'<small>死敌</small>':`<button data-ally="${x.id}">结交</button>`}</article>`).join('');
 const daoBox=`<h3>道心与立场</h3><article class="entry"><strong>${dr.label}</strong> · 道心 ${dr.bias>0?'+':''}${dr.bias} · 把柄 ${dr.exposure}
  <br><small>立场是它怎么说，道行是它怎么做：正道里也有手段狠辣的，魔道里也有守底线的。真正决定别人怎么看你的是<b>行径</b>（护人 ${dr.deeds.protect} · 除害 ${dr.deeds.evil} · 杀无辜 ${dr.deeds.innocent} · 杀修士 ${dr.deeds.cultivator}，行径分 ${dr.deedScore}）。</small><br>
  <small>修仙界横跨 ${NATIONS.length} 国，最大的宗门势力不在任何王朝治下。</small></article>
  <h3>街上的人</h3>${(()=>{const here=w.player.place;const folks=peopleAt(w,here);
   return folks.length?folks.slice(0,6).map(p=>`<article class="entry"><strong>${safe(p.name)}</strong> <small>${safe(p.sect)}·${safe(p.temper)}·${safe(p.realm)}</small>
   <br><small>${safe(personLine(w,p))}</small> <button data-help="${p.id}">相助</button></article>`).join(''):'<p>此地没有修士走动。</p>';})()}
  <h3>牌匾与人</h3>${(dr.notable||[]).map(p=>`<article class="entry"><strong>${safe(p.name)}</strong> <small>${safe(p.sect)}·${safe(p.temper)}（道行 ${p.morality}）</small><br>
  <small>${safe(p.reason)} → <strong>${p.label}</strong></small></article>`).join('')||'<p>尚无往来。</p>'}
  <small>门派牌匾只决定它怎么对外说话；门里坐着的人，各自有自己的道行。</small>
  <h3>诸方眼中</h3>${stanceRows}`;
 const karmaBox=`<h3>业力</h3><article class="entry"><strong>${k.tier}</strong> · 业力 ${k.value} · 突破成功率 ${Math.round(bt.chance*100)}%${bt.risk?` · <b style="color:#a33">${bt.risk}将临</b>`:''}<br>
  <small>${k.note}。杀修士沾业轻（同类相争，还有灵石丹药可捡），杀无辜凡人最重；有亲仇、护人、执法这等理由，则几乎不沾。</small><br>
  斩杀：修士 ${k.kills.cultivator} · 凡人 ${k.kills.mortal} · 其中师出有名 ${k.kills.justified} · 除害 ${k.kills.evildoer}
  ${k.recent.length?`<br><small>${k.recent.map(r=>`第${r.day}天 ${safe(r.name)}（${r.kind==='cultivator'?'修士':'凡人'}）业力${r.karma>=0?'+':''}${r.karma}${r.reason?`·${r.reason}`:''}`).join('<br>')}</small>`:''}</article>`;
 return `<h2>仙门</h2><p>灵气决定修士在哪儿；修炼资源决定修士替谁办事。县城灵气薄，一年也未必出一个筑基。</p>${daoBox}${karmaBox}${stoneBox}
 <article class="entry"><strong>灵气</strong><br>${qi}</article>
 <h3>宗门</h3>${sects}
 <h3>供奉（战力 ${r.retainerPower}）</h3>${ret}
 <p class="warbtns">${Object.entries(REALMS).map(([id,rl])=>`<button data-hire="${id}">招${rl.name}（${RETAINER_COST[id].stones} 灵石）</button>`).join('')}</p>
 <h3>凡人的营生</h3><article class="entry">${jobs}</article>
 <p><small>灭门不看你的灵根，看你能养几个供奉。役奴没有工钱——这一行从来没有工钱。</small></p>`;
}
function renderCourt(){
 const c=courtReport(w);
 return `<h2>朝堂</h2><p>你说话，手下办事。旨意按人办、按人打折：能力高的快，贪得多的少。</p>
 <article class="entry"><strong>颁旨</strong><br>
 <input id="decree" placeholder="例：开仓放粮三千石 / 加税 / 盐铁官营 / 修驿传 / 征发五万兵马" />
 <button id="decreeBtn">颁旨</button></article>
 <p class="warbtns">${['开仓放粮三千石','加税','减税','盐铁官营','修驿传','征发五万兵马'].map(x=>`<button data-quick="${x}">${x}</button>`).join('')}</p>
 ${c.staff.map(s=>`<article class="entry"><strong>${safe(s.name)}</strong> · 能力 ${s.skill} · 贪墨 ${s.corruption}% · 忠诚 ${s.loyalty}<br><small>${safe(s.busy)}</small><br>
  <button data-talk="${s.id}">问话</button></article>`).join('')}
 <h3>回话</h3>${(c.log||[]).map(e=>`<article class="entry">${safe(e.text)}</article>`).join('')||'<p>还没有回话。</p>'}`;
}
function renderLedger(){
 ensureFin(w);ensureMarket(w);const m=marketReport(w);
 const goods=m.goods.map(g=>`${g.name} ${g.price} 文/${g.unit}（${g.ratio>=1.4?'贵':g.ratio<=.7?'贱':'平'} ${(g.ratio*100).toFixed(0)}%）`).join(' · ');
 return `<h2>县治账本</h2>
 <p>县境有 ${worldReport(w).population} 人。物价、官仓与民怨是一个循环：粮价涨 → 民怨涨 → 税难收 → 府库空 → 军饷与赈济都拿不出。</p>
 <article class="entry"><strong>市面</strong><br>${goods}<br>民怨 ${m.unrest}/100 · 官仓 ${m.granary.toLocaleString()} 斗 · 税率 ${Math.round(m.taxRate*100)}% · 驿传 ${Math.round((m.post-1)*100)}% · 府库 ${m.treasury.toLocaleString()} 文</article>
 <p class="warbtns">
  <button data-mkt="release">开仓平粜 2000 斗</button>
  <button data-mkt="buy">官府收粮 2000 斗</button>
  <button data-mkt="tax">加税至 18%</button>
  <button data-mkt="taxdown">减税至 8%</button>
  <button data-mkt="salt">${m.monopoly.salt?'弛盐禁':'盐归官营'}</button>
  <button data-mkt="post">修驿传</button>
 </p>
 <p><small>盐铁禁榷进钱但抬价；开仓降粮价与民怨；加税立刻进府库、也在攒民变。钱不是天上掉的。</small></p>
 ${(m.log||[]).map(e=>`<article class="entry"><small>第${e.day}日 ${safe(e.type)}</small><p>${safe(e.text)}</p></article>`).join('')}
 ${renderInstitutions()}`;
}
function renderInstitutions(){
 const s=stateReport(w);
 const rows=Object.entries(s.levers).map(([id,l])=>`<article class="entry"><strong>${safe(l.name)}</strong>：${safe(l.label)}<br>
  ${l.options.map(([k,label])=>`<button data-reform="${id}:${k}" ${k===l.value?'disabled':''}>${safe(label)}</button>`).join('')}</article>`).join('');
 return `<h3>制度</h3>
 <p>制度决定贪腐与执行力，贪腐决定税能不能收上来，收不上来就赈不了灾、发不出饷。</p>
 <article class="entry">贪腐 ${s.corruption}% · 执行力 ${s.efficiency}% · 合法性 ${s.legitimacy}/100 · 改制阻力 ${s.resistance}<br>
 当前结局：<strong>${safe(s.outcome.name)}</strong>——${safe(s.outcome.desc)}</article>
 ${rows}`;
}
function rootRank(w,p){const order=['none','wu','si','san','shuang','dan','tian'];return Math.max(0,order.indexOf(rootOfPerson(w,p)));}

/** 家族：人物卡 + 血脉 + 婚配生育 + 婚丧与年景。借的是结构，头像与素材还是我们自己的。 */
function renderFamily(){
 const r=familyReport(w);
 const cards=r.cards.map(c=>{
  const img=c.sex==='女'?'people/han_female.png':'people/han_male.png';
  const spouse=c.spouse?`<small>婚配：${safe(c.spouse)}</small>`:'<small>未娶未嫁</small>';
  const bear=c.spouse?`<button data-bear="${c.id}:${(w.family.spouse[c.id]||'')}">生育</button>`:'';
  const marryBtn=(!c.spouse&&c.age>=16&&c.age<=45)?`<button data-marry="${c.id}">说亲</button>`:'';
  return `<article class="fam-card">
   <img src="${img}" alt="">
   <div><strong>${safe(c.name)}</strong> <span class="tag">${safe(c.root)}</span><br>
   <small>${c.sex} · ${c.age} 岁 · 余寿 ${c.left} · ${safe(c.realm)}</small><br>${spouse}</div>
   <p>${marryBtn}${bear}</p></article>`;}).join('');
 const logs=r.log.length?r.log.map(l=>`<article class="entry"><small>第${l.day}日</small> ${safe(l.msg)}</article>`).join(''):'<p>族里还没有什么可记的事。</p>';
 $('records').innerHTML=`<h2>${safe(r.name)} · 第 ${r.generation} 代</h2>
  <p>族人 <b>${r.members}</b> 口（其中修士 ${r.cultivators} 人） · 声望 <b>${r.prestige}</b> · 田 ${r.estate.mu} 亩 · 族产 ${r.estate.silver} 银</p>
  <p class="warbtns"><button data-adopt="1">收一名散修入族</button><button data-famyear="1">过一年</button><button data-famyear="10">过十年</button></p>
  <p><small>血脉：孩子灵根从父母身上抽——双修士最容易出好苗子，两个凡人只会生凡人。</small></p>
  ${cards}<h3>族中记事</h3>${logs}`;
}

function otherPanels(panel){activeTab=panel;for(const n of document.querySelectorAll('[data-view]'))n.classList.toggle('selected',n.dataset.view===panel);
 $('canvasFrame').hidden=panel!=='map';$('records').hidden=panel==='map';$('sheet').hidden=true;
 if(panel==='map'){drawMap();return;}
 if(panel==='court')return renderCourt();
 if(panel==='xian')return renderXian();
 if(panel==='goods')return renderGoods();
 if(panel==='quests')return renderQuests();
 if(panel==='war')return renderWar();
 if(panel==='career')return renderCareer();
 if(panel==='family')return renderFamily();
 const hist=w.history.slice(-25).reverse();let html=panel==='people'?`<h2>故人谱</h2><p>人物在地图上有位置，只有真正相遇后才记录在这里。</p>${w.player.contacts.map(c=>{const p=w.people.find(x=>x.id===c.id);return `<article class="entry">${safe(p?.name||c.id)} · ${safe(p?.job||'')} · 第${c.firstDay}天相识</article>`;}).join('')||'<p>尚无相识之人。</p>'}`:panel==='ledger'?renderLedger():`<h2>此世纪事</h2>${hist.map(e=>`<article class="entry"><small>第${e.day}日 · ${safe(e.type)}</small><p>${safe(e.message)}</p></article>`).join('')}`;
 $('records').innerHTML=html;}
function resize(){const r=canvas.getBoundingClientRect();cssW=Math.max(10,r.width);cssH=Math.max(10,r.height);const dpr=Math.min(2,window.devicePixelRatio||1);canvas.width=Math.round(cssW*dpr);canvas.height=Math.round(cssH*dpr);ctx=canvas.getContext('2d');ctx.setTransform(dpr,0,0,dpr,0,0);drawMap();}
function updateLegend(){
 const el=$('legend');if(!el)return;
 if(mapMode==='terrain'){el.hidden=true;return;}
 el.hidden=false;
 const title=MAP_MODES.find(m=>m.id===mapMode)?.name||'';
 if(mapMode==='faction'){
  el.innerHTML=`<b>势力范围 · ${title}</b>`+FACTIONS.map(f=>{
   const seat=LANDMARKS.find(l=>l.id===f.seat);
   return `<div class="row"><span><i class="sw" style="background:${f.color}"></i>${safe(f.name)}</span><em>${standing(w,f.id)} ${reputation(w,f.id)}</em></div>`;
  }).join('');
  return;
 }
 if(mapMode==='population'){
  el.innerHTML=`<b>人口分布</b><div class="row"><span><i class="sw" style="background:#8d5a3c"></i>千人以上</span><em>县治、东市</em></div><div class="row"><span><i class="sw" style="background:#d19a63"></i>数百人</span><em>村落</em></div><div class="row"><span><i class="sw" style="background:#efd9b4"></i>零星</span><em>山道</em></div>`;
  return;
 }
 if(mapMode==='security'){
  const s=securityIndex(w);
  el.innerHTML=`<b>治安 · ${securityLabel()}（${s}）</b><div class="row"><span><i class="sw" style="background:#9cc49b"></i>安定</span><em>官府声望高</em></div><div class="row"><span><i class="sw" style="background:#d99a8b"></i>不靖</span><em>盗匪、流民事件多</em></div>`;
  return;
 }
 el.innerHTML=`<b>${title}</b><div class="row"><span><i class="sw" style="background:#8ab4c8"></i>宗门属地</span><em>外门不纳税</em></div><div class="row"><span><i class="sw" style="background:#cdb768"></i>官府属地</span><em>纳粮服役</em></div>`;
}
function setMapMode(mode){mapMode=MAP_MODES.some(m=>m.id===mode)?mode:'terrain';
 for(const b of document.querySelectorAll('[data-mode]'))b.classList.toggle('selected',b.dataset.mode===mapMode);
 updateLegend();drawMap();}
let lastWarDay=null;
/** 战争按“世界日”结算，不跟着帧走：暂停时仗不会偷偷打。 */
function tickWarIfDayChanged(){
 if(!w||!w.war)return;
 if(lastWarDay===null){lastWarDay=w.day;return;}
 if(w.day===lastWarDay)return;
 lastWarDay=w.day;
 if(w.state){w.state=ensureState(w);tickState(w);}
 if(w.market)tickMarket(w);
 if(w.currency){
  tickCurrency(w);tickRetainers(w);
  if(w.career)tickCareer(w);
  const a=resolveAssassination(w);
  if(a.died){toast(`皇帝死於${a.sect}刺客之手（${a.threat} 对 ${a.protect}），太子继位。`);if(activeTab==='xian')otherPanels('xian');}
  else if(a.wounded)toast(`${a.sect}刺客被禁宫所阻，皇帝重伤。`);
 }
 if(w.court){const k=tickCourt(w);for(const ev of k.events)note(w,'回话',ev.text);if(activeTab==='court')renderCourt();}
 const r=tickWarDay(w,{distanceToDepot:(a)=>Math.hypot(a.x-0,a.y-0)});
 if(r.events.length){if(activeTab==='war')renderWar();for(const ev of r.events.slice(-2))note(w,'兵事',ev.text);}
}
function bind(){canvas=$('worldCanvas');setupGestures();$('zoomIn').onclick=()=>zoomAt(.72);$('zoomOut').onclick=()=>zoomAt(1/.72);$('locate').onclick=()=>{camera.x=w.player.mapPos.x;camera.y=w.player.mapPos.y;camera.mpp=Math.min(camera.mpp,4);profile();scheduleSave();};
 $('stop').onclick=()=>{stopJourney(w);profile();toast('你已停下，已经流逝的时间不会退回。');scheduleSave();};
 $('save').onclick=()=>save().then(()=>toast('存档已保存')).catch(()=>toast('存档保存失败'));
 for(const b of document.querySelectorAll('[data-mode]'))b.onclick=()=>setMapMode(b.dataset.mode);
 for(const b of document.querySelectorAll('[data-realm]'))b.onclick=()=>{highlightCult=!highlightCult;for(const x of document.querySelectorAll('[data-realm]'))x.classList.toggle('selected',x.dataset.realm==='cultivation'&&highlightCult);showSheet(null);requestProfile();};
 const rec=$('records');if(rec)rec.onclick=handleRecordsClick;
 $('fast').onclick=()=>{travelSpeed=travelSpeed===30?120:travelSpeed===120?1:30;$('fast').textContent=travelSpeed+'倍';toast('世界时间倍率 '+travelSpeed+'×');};
 $('realmButton').onclick=()=>{const g=canFly(w);if(!g.ok)return toast(g.reason);if(!selected)return toast('先在地图上选择一个目的地，再御剑前往。');flyTarget();};
 $('advanceDay').onclick=()=>{if(w.player.route)return toast('行走中，请先停下');simulateDay(w,1);toast('世界推进一日');profile();scheduleSave();};
 $('newWorld').onclick=()=>{if(!confirm('确认创建新世界？当前存档将被新世界替换，原人物不会再次出现。'))return;w=createWorld('县境-'+Date.now());ensureGeo(w);camera={x:0,y:0,mpp:3};selected=null;showSheet(null);otherPanels('map');profile();scheduleSave();};
 for(const btn of document.querySelectorAll('[data-view]'))btn.onclick=()=>otherPanels(btn.dataset.view);
 const fb=$('fieldBattle');
 if(fb)fb.onclick=()=>{
  if(mapBattle(w)&&!mapBattle(w).done){endMapBattle(w);toast('收兵');}
  else{const at={x:w.player.mapPos.x+140,y:w.player.mapPos.y+(Math.random()*80-40)};spawnMapBattle(w,{at});toast('列阵开战：就在你眼前');}
  drawMap();
 };
 window.addEventListener('resize',resize);document.addEventListener('visibilitychange',()=>{paused=document.hidden;if(paused)save().catch(()=>{});});
}
let stamp=0,profileStamp=0,saveStamp=0;
let lastRuleDay=null;
/** 每天只跑一次；规则表在 content/ 里，加玩法不用改这里。 */
function runDailyRules(){
 if(lastRuleDay===w.day)return [];
 lastRuleDay=w.day;
 ensureEngine(w);
 const fired=runRules(w,'daily',{});
 if(fired.length)otherPanels(activeTab);
 return fired;
}
function runTravelRules(){
 ensureEngine(w);
 runRules(w,'travel',{mode:'foot'});
}
function animation(now){clockMs=now;const dt=stamp?Math.min(.12,(now-stamp)/1000):0;stamp=now;if(!paused&&w&&dt>0){const old={...w.player.mapPos};const result=advanceMap(w,dt,travelSpeed);tickWarIfDayChanged();const firedDays=runDailyRules();if(result.done){runTravelRules();toast('到达目的地；移动时间已累计。');scheduleSave();}
 if(result.moved>0){ // 只有实际移动才更新场景名；缩放操作不写入位置。
 camera.x+=w.player.mapPos.x-old.x;camera.y+=w.player.mapPos.y-old.y;
 }
 if(now-profileStamp>260){profile();profileStamp=now;}
 if(now-saveStamp>15000){scheduleSave();saveStamp=now;}}
 if(w){const mb=stepMapBattle(w,dt);if(mb&&mb.done&&!mb.reported){mb.reported=true;const r=mapBattleReport(w);const k=recordBattle(w,{kills:(r.left.dead||0)+(r.right.dead||0),won:(r.left.alive||0)>=(r.right.alive||0)});toast(`战罢：左亡 ${r.left.dead} 右亡 ${r.right.dead} · 战功 +${k.gain}`);scheduleSave();}}
 if(w&&!$('canvasFrame').hidden)drawMap();requestAnimationFrame(animation);}
async function init(){
 loadContent();try{const raw=await load();w=raw?restoreWorld(raw):createWorld();}catch(e){console.warn(e);w=createWorld();toast('旧存档暂时无法读取，当前为临时世界。');}
 sprites=new SpriteBank('sprites/');
 await sprites.load().catch(()=>false);
 peopleBank=new PeopleBank('');
 await peopleBank.load().catch(()=>false);
 ensureGeo(w);ensureCareer(w);if(w.mapCamera&&Number.isFinite(w.mapCamera.mpp))camera={...w.mapCamera};else camera={...w.player.mapPos,mpp:3.2};
 bind();profile();updateLegend();otherPanels('map');resize();if(w.player.indoor)showIndoor();requestAnimationFrame(animation);}
init();
