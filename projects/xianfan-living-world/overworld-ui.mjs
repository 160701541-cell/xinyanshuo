/** 仙凡共生 v0.6：连续米制地图客户端。缩放绝不修改玩家坐标。 */
import {createWorld,restoreWorld,saveableWorld,worldReport,simulateDay,note,getPlace,changeRole} from './core.mjs';
import {MAP_VERSION,WORLD_LIMIT,CITY,LANDMARKS,STRUCTURES,TOWN_HOUSES,WALLS,ROUTES,STREAMS,PLACE_METERS,ensureGeo,terrainHeight,dist,obstacleAt,beginJourney,stopJourney,advanceMap,enterStructure,exitStructure,placeAt,visibleActors,actorVisibility,openingStatus,canEnter,canFly,flightRuleAt,rest} from './overworld.mjs';
import {FACTIONS,factionById,territoryGrid,territoryBorderPaths,MAP_MODES,mapColor,reputation,standing,securityIndex,ITEMS,itemById,priceOf,inventory,buyItem,sellItem,canTradeHere,bagWeight,contractsFor,acceptContract,completeContract,societyReport} from './society.mjs';
import {SpriteBank,lookFor} from './sprites.mjs';
import {ensureWar,levyCapacity,createArmy,warReport,tickWarDay,supplyDays,armyNeeds,deliveredCostKg,emblemOf,authorityReport,setRank,rankOf,rankInfo,takeCommand,joinArmy,issueDecree} from './war.mjs';
import {interiorAtlas} from './atlas.mjs';
import {classifyGesture,canSelect} from './gesture.mjs';
const placeById=getPlace;
const $=id=>document.getElementById(id);
const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
const safe=s=>String(s??'').replace(/[&<>'"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','\'':'&#39;','"':'&quot;'}[c]));
let w,selected=null,camera={x:0,y:0,mpp:2.7},mapMode='terrain',sprites=null,ctx,canvas,cssW=0,cssH=0,activeTab='map',pointer=new Map(),pinch=null,dragStart=null,gestureMoved=false,multiTouched=false,downAt=0,travelSpeed=30,savePending=0,noticeTimeout=0,paused=false;
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
function drawGround(){ctx.fillStyle='#dcdcc5';ctx.fillRect(0,0,cssW,cssH);
 const step=camera.mpp>1500?45000:camera.mpp>100?9000:camera.mpp>16?900:camera.mpp>3?175:42;
 const min=unpos(-10,-10),max=unpos(cssW+10,cssH+10);const x0=Math.floor(min.x/step),x1=Math.ceil(max.x/step),y0=Math.floor(min.y/step),y1=Math.ceil(max.y/step);
 if((x1-x0)*(y1-y0)>80000)return;
 for(let a=x0;a<=x1;a++)for(let b=y0;b<=y1;b++){const x=a*step,y=b*step,z=terrainHeight(x,y),n=noise(a,b);
 const nearCity=Math.abs(x)<1300&&Math.abs(y)<1200;
 const shade=z>240?'#c2c9a9':z>160?'#d9d9bb':z>100?'#d0dac0':'#bed4c7';
 let color=nearCity?'#ded9c4':shade;if(n<.11)color=nearCity?'#e3d5b4':'#c0cda3';if(n>.93&&!nearCity)color='#a9bfa2';
 rect(x,y,step+1,step+1,color);
 if(camera.mpp<3&&n>.70){const s=pos({x:x+step/2,y:y+step/2});ctx.strokeStyle='rgba(67,104,70,.35)';ctx.lineWidth=1.4;ctx.beginPath();ctx.moveTo(s.x-2,s.y+2);ctx.lineTo(s.x,s.y-2);ctx.lineTo(s.x+3,s.y+1);ctx.stroke();}
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
 let count=0;for(let x=Math.floor(min.x/inc)*inc;x<max.x;x+=inc)for(let y=Math.floor(min.y/inc)*inc;y<max.y;y+=inc){if(count++>8000)return;let z=terrainHeight(x,y);if(z<180)continue;const q=pos({x,y}),sz=Math.max(2,Math.min(21,inc/camera.mpp*.18));ctx.beginPath();ctx.moveTo(q.x-sz,q.y+sz*.8);ctx.lineTo(q.x,q.y-sz*.7);ctx.lineTo(q.x+sz,q.y+sz*.8);ctx.closePath();ctx.fillStyle=z>240?'rgba(103,114,102,.15)':'rgba(86,118,88,.10)';ctx.fill();}}
function drawWater(){for(const river of STREAMS){drawPath(river);ctx.strokeStyle='#7fa8a8';ctx.lineWidth=clamp(100/camera.mpp,1,60);ctx.lineCap='round';ctx.lineJoin='round';ctx.stroke();drawPath(river);ctx.strokeStyle='#c3ded1';ctx.lineWidth=clamp(25/camera.mpp,.5,9);ctx.stroke();}}
function drawRoads(){for(const seg of ROUTES){drawPath(seg);ctx.strokeStyle='#97896e';ctx.lineWidth=clamp(24/camera.mpp,1,28);ctx.lineJoin='round';ctx.stroke();drawPath(seg);ctx.strokeStyle='#e9dcbb';ctx.lineWidth=clamp(19/camera.mpp,.6,25);ctx.stroke();}
 if(camera.mpp>75)return;
 // 城区道路是连续的世界坐标，缩放不会切换到另一张图。
 ctx.lineCap='butt';for(const d of [-520,-260,0,260,520]){
 const a=[[-700,d],[700,d]],b=[[d,-700],[d,700]];
 for(const line of [a,b]){drawPath(line);ctx.strokeStyle='#c5bb9c';ctx.lineWidth=clamp(45/camera.mpp,1,65);ctx.stroke();drawPath(line);ctx.strokeStyle='#e7dec5';ctx.lineWidth=clamp(40/camera.mpp,.8,60);ctx.stroke();}}
 ctx.lineCap='round';}
function drawWall(){if(camera.mpp>40)return;for(const r of WALLS){rect(r.x,r.y,r.w,r.h,'#827e70','#e1c8a0',camera.mpp<8?1:0);}for(const g of CITY.gates){const s=pos(g),r=clamp(45/camera.mpp,2,65);ctx.strokeStyle='#614d3e';ctx.lineWidth=Math.max(1,6/camera.mpp);ctx.beginPath();ctx.arc(s.x,s.y,r,0,Math.PI*2);ctx.stroke();if(camera.mpp<8)screenText('城门',s.x,s.y-24,12);}}
function drawBuildings(){if(camera.mpp>35)return;for(const b of [...TOWN_HOUSES,...STRUCTURES]){
 const p=pos(b),width=b.w/camera.mpp,height=b.h/camera.mpp;if(p.x+width<0||p.y+height<0||p.x>cssW||p.y>cssH)continue;
 const isHouse=b.id.startsWith('house_'),outline='#756c57',colors={government:'#a99579',forge:'#a97856',grain:'#b9a172',inn:'#8c9580',home:'#a9a18b',school:'#a3b18d',fort:'#8c8d88'};
 rect(b.x,b.y,b.w,b.h,'#ede3cc',outline,clamp(3/camera.mpp,.5,3));rect(b.x+5,b.y+5,b.w-10,b.h-10,colors[b.kind]||'#aaa18a','#7b6d57',clamp(2/camera.mpp,.5,2));
 if(camera.mpp<8){const roof=pos({x:b.x+b.w/2,y:b.y+b.h/2});ctx.strokeStyle='rgba(240,226,186,.5)';ctx.lineWidth=1.5;ctx.beginPath();ctx.moveTo(p.x,p.y);ctx.lineTo(roof.x,roof.y);ctx.lineTo(p.x+width,p.y);ctx.stroke();ctx.beginPath();ctx.moveTo(p.x,p.y+height);ctx.lineTo(roof.x,roof.y);ctx.lineTo(p.x+width,p.y+height);ctx.stroke();}
 if(!isHouse&&camera.mpp<10){text(b.name,{x:b.x+b.w/2,y:b.y+b.h/2},camera.mpp<4?12:10,'#303c34',650);}
 if(b.door&&camera.mpp<12){circle(b.door,clamp(9/camera.mpp,3,10),'#6e513a','#f5e5be',2);if(camera.mpp<4)text('门', {x:b.door.x,y:b.door.y-22},10,'#2a4a36');}
 }}
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
  const layers=sprites?sprites.layers(person):null;
  ctx.fillStyle='rgba(15,32,22,.16)';ctx.beginPath();ctx.ellipse(pp.x,pp.y+2,h*.26,h*.12,0,0,Math.PI*2);ctx.fill();
  const ok=drawSprite(layers,pp.x,pp.y,h);
  if(!ok){const fill=faces[Number(a.id.slice(-2))%faces.length];ctx.beginPath();ctx.arc(pp.x,pp.y-h*.3,h*.3,0,Math.PI*2);ctx.fillStyle=fill;ctx.fill();}
  if(a.leader){ctx.strokeStyle='#c8a34e';ctx.lineWidth=2.4;ctx.beginPath();ctx.arc(pp.x,pp.y-h*.42,h*.42,0,Math.PI*2);ctx.stroke();}
  if((camera.mpp<.95)||(a.leader&&camera.mpp<2))screenText((a.title?a.title+' · ':'')+person.name+' · '+a.state,pp.x,pp.y+h*.22,a.leader?12:11,a.leader?'#583f30':'#30503d');
  if(selected?.kind==='npc'&&selected.data.id===a.id){ctx.strokeStyle='#bd713f';ctx.lineWidth=2.5;ctx.beginPath();ctx.arc(pp.x,pp.y-h*.4,h*.55,0,Math.PI*2);ctx.stroke();}
 }
}
function drawPlayer(){const p=pos(w.player.mapPos);
 const look=sprites?sprites.layers({id:'player',job:w.player.role==='修士'?'修士':w.player.role,age:30,sex:'男',wealth:200}):null;
 const h=32;
 ctx.fillStyle='rgba(21,63,52,.18)';ctx.beginPath();ctx.ellipse(p.x,p.y+2,10,4.4,0,0,Math.PI*2);ctx.fill();
 ctx.strokeStyle='#f4d07c';ctx.lineWidth=3;ctx.beginPath();ctx.arc(p.x,p.y-h*.42,h*.46,0,Math.PI*2);ctx.stroke();
 if(!drawSprite(look,p.x,p.y,h)){ctx.beginPath();ctx.arc(p.x,p.y-h*.3,12,0,Math.PI*2);ctx.fillStyle='#153f34';ctx.fill();}
 screenText('我',p.x,p.y+8,11,'#3a2f1e',800);
}
function drawRoute(){const r=w.player.route;if(!r)return;const points=[w.player.mapPos,...r.path.slice(r.index+1)];drawPath(points.map(p=>[p.x,p.y]));ctx.strokeStyle='rgba(255,250,228,.8)';ctx.lineWidth=6;ctx.stroke();drawPath(points.map(p=>[p.x,p.y]));ctx.strokeStyle='#cc7c40';ctx.lineWidth=3;ctx.setLineDash([8,7]);ctx.stroke();ctx.setLineDash([]);circle(r.goal,6,'#b7653a','#fff0d7',2);}
function drawSelection(){if(!selected?.point)return;const p=pos(selected.point);ctx.beginPath();ctx.arc(p.x,p.y,24,0,Math.PI*2);ctx.strokeStyle='#bd713f';ctx.lineWidth=2.5;ctx.stroke();ctx.beginPath();ctx.moveTo(p.x-30,p.y);ctx.lineTo(p.x+30,p.y);ctx.moveTo(p.x,p.y-30);ctx.lineTo(p.x,p.y+30);ctx.stroke();}
function drawMap(){if(!ctx||!w)return;ctx.clearRect(0,0,cssW,cssH);drawGround();drawFactionLayer();drawPolitical();drawRelief();drawWater();drawRoads();drawWall();drawBuildings();drawTowns();drawRoute();drawArmies();drawAvatars();drawPlayer();drawSelection();}
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
 target.querySelector('[data-action="stop"]')?.addEventListener('click',()=>{stopJourney(w);profile();scheduleSave();toast('你停下了。');});
}
const escapeHtml=s=>safe(s);
function flyTarget(){if(!selected)return;const goal=selected.kind==='structure'?selected.data.door:selected.kind==='npc'?{x:selected.data.x,y:selected.data.y}:selected.point;
 const r=beginFlight(w,goal,selected.data?.id||null);if(!r.ok)return toast(r.error);toast(`御剑而行 · 直线 ${Math.round(r.meters)} 米`);showSheet(null);profile();scheduleSave();}
function goTarget(){if(!selected)return;const goal=selected.kind==='structure'?selected.data.door:selected.kind==='npc'?{x:selected.data.x,y:selected.data.y}:selected.point;
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
  if(tap){const p=unpos(last.x,last.y);const h=hitAt(last,p);if(h)showSheet(h);else showSheet(null);}
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
  <small>日耗 ${(a.needKg/1000).toFixed(0)} 吨 · 自携粮 ${a.supplyDays} 日</small><br>
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
 <h3>征发（需圣旨）</h3>${levy}<h3>战报</h3>${log.map(e=>`<article class="entry"><small>${safe(e.type)}</small> ${safe(e.text)}</article>`).join('')||'<p>尚未接战。</p>'}`;
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
 if(t.dataset.rank){setRank(w,t.dataset.rank);toast(`身份：${t.dataset.rank}`);profile();scheduleSave();renderWar();return;}
 if(t.dataset.lead){const r=takeCommand(w,Number(t.dataset.lead));toast(r.ok?'你已接管这一军':r.error);scheduleSave();renderWar();return;}
 if(t.dataset.join){const r=joinArmy(w,Number(t.dataset.join));toast(r.ok?'你编入行伍，只是其中一人':r.error);scheduleSave();renderWar();return;}
 if(t.dataset.march){const a=w.war.armies.find(x=>x.id===Number(t.dataset.march));if(!a)return;a.goal={x:0,y:0};a.state='行军';toast(`${a.name}开拔，向县城行军`);scheduleSave();renderWar();return;}
 if(t.dataset.return){const a=w.war.armies.find(x=>x.id===Number(t.dataset.return));if(!a)return;const seat=LANDMARKS.find(l=>l.id===factionById(a.faction)?.seat);a.goal=seat?{x:seat.x,y:seat.y}:{x:a.x,y:a.y};a.state='行军';toast(`${a.name}回师`);scheduleSave();renderWar();return;}
 if(t.dataset.complete){const r=completeContract(w,t.dataset.complete);toast(r.ok?`交差，得 ${r.pay} 文`:r.error);if(r.ok){profile();scheduleSave();renderQuests();}return;}
}
function otherPanels(panel){activeTab=panel;for(const n of document.querySelectorAll('[data-view]'))n.classList.toggle('selected',n.dataset.view===panel);
 $('canvasFrame').hidden=panel!=='map';$('records').hidden=panel==='map';$('sheet').hidden=true;if(panel==='map'){drawMap();return;}
 if(panel==='goods')return renderGoods();
 if(panel==='quests')return renderQuests();
 if(panel==='war')return renderWar();
 const hist=w.history.slice(-25).reverse();let html=panel==='people'?`<h2>故人谱</h2><p>人物在地图上有位置，只有真正相遇后才记录在这里。</p>${w.player.contacts.map(c=>{const p=w.people.find(x=>x.id===c.id);return `<article class="entry">${safe(p?.name||c.id)} · ${safe(p?.job||'')} · 第${c.firstDay}天相识</article>`;}).join('')||'<p>尚无相识之人。</p>'}`:panel==='ledger'?`<h2>县治账本</h2><p>县城及周边有 ${worldReport(w).population} 位人口档案，经济仍采用县级结算，尚不是每人完整的AI模拟。</p><article class="entry">粮价：${w.price} 文/斗<br>县库：${w.treasury} 文<br>县境总粮：${worldReport(w).grain} 斗</article>`:`<h2>此世纪事</h2>${hist.map(e=>`<article class="entry"><small>第${e.day}日 · ${safe(e.type)}</small><p>${safe(e.message)}</p></article>`).join('')}`;
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
 const r=tickWarDay(w,{distanceToDepot:(a)=>Math.hypot(a.x-0,a.y-0)});
 if(r.events.length){if(activeTab==='war')renderWar();for(const ev of r.events.slice(-2))note(w,'兵事',ev.text);}
}
function bind(){canvas=$('worldCanvas');setupGestures();$('zoomIn').onclick=()=>zoomAt(.72);$('zoomOut').onclick=()=>zoomAt(1/.72);$('locate').onclick=()=>{camera.x=w.player.mapPos.x;camera.y=w.player.mapPos.y;camera.mpp=Math.min(camera.mpp,4);profile();scheduleSave();};
 $('stop').onclick=()=>{stopJourney(w);profile();toast('你已停下，已经流逝的时间不会退回。');scheduleSave();};
 $('save').onclick=()=>save().then(()=>toast('存档已保存')).catch(()=>toast('存档保存失败'));
 for(const b of document.querySelectorAll('[data-mode]'))b.onclick=()=>setMapMode(b.dataset.mode);
 const rec=$('records');if(rec)rec.onclick=handleRecordsClick;
 $('fast').onclick=()=>{travelSpeed=travelSpeed===30?120:travelSpeed===120?1:30;$('fast').textContent=travelSpeed+'倍';toast('世界时间倍率 '+travelSpeed+'×');};
 $('realmButton').onclick=()=>{const g=canFly(w);if(!g.ok)return toast(g.reason);if(!selected)return toast('先在地图上选择一个目的地，再御剑前往。');flyTarget();};
 $('advanceDay').onclick=()=>{if(w.player.route)return toast('行走中，请先停下');simulateDay(w,1);toast('世界推进一日');profile();scheduleSave();};
 $('newWorld').onclick=()=>{if(!confirm('确认创建新世界？当前存档将被新世界替换，原人物不会再次出现。'))return;w=createWorld('县境-'+Date.now());ensureGeo(w);camera={x:0,y:0,mpp:3};selected=null;showSheet(null);otherPanels('map');profile();scheduleSave();};
 for(const btn of document.querySelectorAll('[data-view]'))btn.onclick=()=>otherPanels(btn.dataset.view);
 window.addEventListener('resize',resize);document.addEventListener('visibilitychange',()=>{paused=document.hidden;if(paused)save().catch(()=>{});});
}
let stamp=0,profileStamp=0,saveStamp=0;
function animation(now){const dt=stamp?Math.min(.12,(now-stamp)/1000):0;stamp=now;if(!paused&&w&&dt>0){const old={...w.player.mapPos};const result=advanceMap(w,dt,travelSpeed);tickWarIfDayChanged();if(result.done){toast('到达目的地；移动时间已累计。');scheduleSave();}
 if(result.moved>0){ // 只有实际移动才更新场景名；缩放操作不写入位置。
 camera.x+=w.player.mapPos.x-old.x;camera.y+=w.player.mapPos.y-old.y;
 }
 if(now-profileStamp>260){profile();profileStamp=now;}
 if(now-saveStamp>15000){scheduleSave();saveStamp=now;}}
 if(w&&!$('canvasFrame').hidden)drawMap();requestAnimationFrame(animation);}
async function init(){try{const raw=await load();w=raw?restoreWorld(raw):createWorld();}catch(e){console.warn(e);w=createWorld();toast('旧存档暂时无法读取，当前为临时世界。');}
 sprites=new SpriteBank('sprites/');
 await sprites.load().catch(()=>false);
 ensureGeo(w);if(w.mapCamera&&Number.isFinite(w.mapCamera.mpp))camera={...w.mapCamera};else camera={...w.player.mapPos,mpp:3.2};
 bind();profile();updateLegend();otherPanels('map');resize();if(w.player.indoor)showIndoor();requestAnimationFrame(animation);}
init();
