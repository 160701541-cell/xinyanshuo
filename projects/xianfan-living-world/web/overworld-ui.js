/** 仙凡共生 v0.6：连续米制地图客户端。缩放绝不修改玩家坐标。 */
import {createWorld,restoreWorld,saveableWorld,worldReport,simulateDay,note,getPlace,changeRole} from './core.js';
import {MAP_VERSION,WORLD_LIMIT,CITY,LANDMARKS,STRUCTURES,TOWN_HOUSES,WALLS,ROUTES,STREAMS,PLACE_METERS,ensureGeo,terrainHeight,dist,obstacleAt,beginJourney,stopJourney,advanceMap,enterStructure,exitStructure,placeAt} from './overworld.js';
import {interiorAtlas} from './atlas.js';
const $=id=>document.getElementById(id);
const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
const safe=s=>String(s??'').replace(/[&<>'"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','\'':'&#39;','"':'&quot;'}[c]));
let w,selected=null,camera={x:0,y:0,mpp:2.7},ctx,canvas,cssW=0,cssH=0,activeTab='map',pointer=new Map(),pinch=null,panMoved=false,dragStart=null,travelSpeed=30,savePending=0,noticeTimeout=0,paused=false;
const peopleCaches=new WeakMap();
const faces=['#537560','#95724d','#607d91','#8e715f','#855f67','#726b91'];
const currentTime=()=>{const m=Math.floor(w.hour*60);return `承平${3+Math.floor((w.day-1)/360)}年 · 第${(w.day-1)%360+1}日 · ${String(Math.floor(m/60)).padStart(2,'0')}:${String(m%60).padStart(2,'0')}`;};
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
function drawPolitical(){if(camera.mpp<180)return;
 const polys=[
 {name:'大宁王朝',fill:'rgba(209,207,165,.33)',points:[[-550000,-440000],[100000,-550000],[490000,-70000],[540000,340000],[-300000,490000],[-700000,140000]]},
 {name:'北朔汗庭',fill:'rgba(192,203,183,.42)',points:[[-400000,-1300000],[520000,-1300000],[630000,-650000],[80000,-470000],[-550000,-410000]]},
 {name:'东越',fill:'rgba(194,211,183,.4)',points:[[430000,-150000],[1300000,-180000],[1300000,630000],[440000,500000]]},
 {name:'西戎',fill:'rgba(210,189,154,.37)',points:[[-1350000,-390000],[-580000,-490000],[-610000,560000],[-1350000,700000]]},
 {name:'云离',fill:'rgba(166,195,181,.34)',points:[[-180000,400000],[450000,380000],[950000,1300000],[-500000,1300000]]}
 ];
 for(const f of polys){drawPath(f.points,true);ctx.fillStyle=f.fill;ctx.fill();ctx.strokeStyle='#8a806b';ctx.lineWidth=1.25;ctx.setLineDash([7,5]);ctx.stroke();ctx.setLineDash([]);let av={x:f.points.reduce((n,p)=>n+p[0],0)/f.points.length,y:f.points.reduce((n,p)=>n+p[1],0)/f.points.length};if(visible(av))text(f.name,av,15,'#5a5846',700);}
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
function drawAvatars(){if(camera.mpp>350)return;
 if(!peopleCaches.has(w))peopleCaches.set(w,new Map(w.people.map(p=>[p.id,p])));const lookup=peopleCaches.get(w);
 const visibleActors=(w.mapActors||[]).filter(a=>visible(a)).filter(a=>{const p=lookup.get(a.id);return p&&p.status==='alive'&&((w.hour>=6&&w.hour<21)||a.job==='捕快')});
 visibleActors.sort((a,b)=>Number(b.leader)-Number(a.leader)||dist(a,w.player.mapPos)-dist(b,w.player.mapPos));
 const taken=[],max=camera.mpp>60?6:camera.mpp>14?12:camera.mpp>3?20:150;
 for(const a of visibleActors){if(taken.length>=max)break;if(camera.mpp>22&&!a.leader)continue;
 const pp=pos(a);if(taken.some(q=>Math.hypot(q.x-pp.x,q.y-pp.y)<(camera.mpp>1.5?24:14)))continue;
 taken.push(pp);const person=lookup.get(a.id),s=a.leader?14:camera.mpp<1.3?11:10,fill=faces[Number(a.id.slice(-2))%faces.length];
 ctx.fillStyle='rgba(15,32,22,.16)';ctx.beginPath();ctx.ellipse(pp.x,pp.y+4,s+4,s*.5,0,0,Math.PI*2);ctx.fill();
 ctx.beginPath();ctx.arc(pp.x,pp.y,s,0,Math.PI*2);ctx.fillStyle=fill;ctx.fill();ctx.strokeStyle=a.leader?'#ebc777':'#fff2d7';ctx.lineWidth=a.leader?3:2;ctx.stroke();
 ctx.fillStyle='#fff9e4';ctx.font=`700 ${a.leader?11:10}px system-ui`;ctx.textAlign='center';ctx.textBaseline='middle';ctx.fillText(person.name.slice(-1),pp.x,pp.y);
 if((camera.mpp<.95)||(a.leader&&camera.mpp<2))screenText((a.title?a.title+' · ':'')+person.name,pp.x,pp.y-s-12,a.leader?12:11,a.leader?'#583f30':'#30503d');
 }
}
function drawPlayer(){const p=pos(w.player.mapPos);ctx.beginPath();ctx.arc(p.x,p.y,17,0,Math.PI*2);ctx.fillStyle='#153f34';ctx.fill();ctx.strokeStyle='#f4d07c';ctx.lineWidth=3.5;ctx.stroke();ctx.fillStyle='#fff4dc';ctx.font='bold 13px system-ui';ctx.textAlign='center';ctx.textBaseline='middle';ctx.fillText('我',p.x,p.y);ctx.fillStyle='#273f35';ctx.font='bold 12px system-ui';ctx.fillText('',p.x,p.y);}
function drawRoute(){const r=w.player.route;if(!r)return;const points=[w.player.mapPos,...r.path.slice(r.index+1)];drawPath(points.map(p=>[p.x,p.y]));ctx.strokeStyle='rgba(255,250,228,.8)';ctx.lineWidth=6;ctx.stroke();drawPath(points.map(p=>[p.x,p.y]));ctx.strokeStyle='#cc7c40';ctx.lineWidth=3;ctx.setLineDash([8,7]);ctx.stroke();ctx.setLineDash([]);circle(r.goal,6,'#b7653a','#fff0d7',2);}
function drawSelection(){if(!selected?.point)return;const p=pos(selected.point);ctx.beginPath();ctx.arc(p.x,p.y,24,0,Math.PI*2);ctx.strokeStyle='#bd713f';ctx.lineWidth=2.5;ctx.stroke();ctx.beginPath();ctx.moveTo(p.x-30,p.y);ctx.lineTo(p.x+30,p.y);ctx.moveTo(p.x,p.y-30);ctx.lineTo(p.x,p.y+30);ctx.stroke();}
function drawMap(){if(!ctx||!w)return;ctx.clearRect(0,0,cssW,cssH);drawGround();drawPolitical();drawRelief();drawWater();drawRoads();drawWall();drawBuildings();drawTowns();drawRoute();drawAvatars();drawPlayer();drawSelection();}
function profile(){const p=w.player,r=worldReport(w),place=placeAt(p.mapPos);
 $('name').textContent=p.name;$('place').textContent=p.indoor?(getPlace(p.indoor)?.name||'室内'):place.name;
 $('time').textContent=currentTime();$('population').textContent=`临安县及周边 ${r.population.toLocaleString('zh-CN')}人`;
 $('role').textContent=`${p.role} · ${p.stats.realm}`;
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
 let h='',title='',sub='',body='',buttons='';const player=w.player.mapPos;
 if(obj.kind==='structure'){let b=obj.data;title=b.name;sub=`${Math.round(dist(player,b.door))}米 · ${b.kind==='government'?'官署':b.kind==='home'?'民居':'工商建筑'}`;body=b.desc||'这座建筑暂未开放室内。';
 const near=w.mapActors.filter(a=>dist(a,{x:b.x,y:b.y})<220).slice(0,4);body+=`<p class="near">附近：${near.length?near.map(a=>safe((w.people.find(p=>p.id===a.id)?.name||'行人')+' · '+a.state)).join('、'):'暂未发现正在活动的人物'}</p>`;
 buttons=`<button data-action="go">沿路前往门口</button>${dist(player,b.door)<35&&getPlace(b.id)?'<button data-action="enter">从正门进入</button>':''}`;
 }else if(obj.kind==='landmark'){const b=obj.data;title=b.name;sub=b.faction+(b.active?' · 县域已开放':' · 地理预留区域');body=b.desc;
 buttons=b.active?'<button data-action="go">步行前往</button>':'<button disabled>本区域未开放</button>';
 }else if(obj.kind==='npc'){const a=obj.data,p=w.people.find(x=>x.id===a.id);title=p?.name||'人物';sub=(a.title||p?.job||'行人')+` · ${Math.round(dist(player,a))}米`;body=`当前活动：${a.state}。身份ID：${a.id}。此人物是世界人口档案中的真实ID，轨迹在可观察区域持续更新。`;buttons='<button data-action="go">走近此人</button>';
 }else{title='地面目标';sub=`距你 ${Math.round(dist(player,obj.point))}米 · 海拔 ${terrainHeight(obj.point.x,obj.point.y)}米`;body='这里是同一张连续地图上的一处地点。移动需要时间，障碍物和城墙不能穿过。';buttons='<button data-action="go">前往此处</button>';}
 h=`<div class="sheet-header"><div><small>${safe(sub)}</small><h3>${safe(title)}</h3></div><button class="quiet" id="closeSheet" aria-label="关闭地点卡片">✕</button></div><p>${safe(body).replace(/&lt;p class=&quot;near&quot;&gt;/,'<p class="near">').replace(/&lt;\/p&gt;/,'</p>')}</p><div class="sheet-actions">${buttons}</div>`;
 target.innerHTML=h;target.hidden=false;$('closeSheet').onclick=()=>showSheet(null);target.querySelector('[data-action="go"]')?.addEventListener('click',()=>goTarget());target.querySelector('[data-action="enter"]')?.addEventListener('click',()=>enter());
}
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
function hit(p){const scale=camera.mpp;const npcs=(w.mapActors||[]).filter(a=>dist(a,p)<Math.max(15,18*scale));npcs.sort((a,b)=>dist(a,p)-dist(b,p));if(npcs.length&&(scale<15||npcs[0].leader))return{kind:'npc',point:p,data:npcs[0]};
 // 建筑点击使用世界几何，不依赖HTML按钮位置。
 for(const b of STRUCTURES){if(p.x>b.x-16*scale&&p.x<b.x+b.w+16*scale&&p.y>b.y-16*scale&&p.y<b.y+b.h+16*scale){if(scale<25)return{kind:'structure',point:b.door,data:b};}}
 const lands=LANDMARKS.filter(l=>dist(l,p)<Math.max(40,20*scale)).sort((a,b)=>dist(a,p)-dist(b,p));if(lands.length)return{kind:'landmark',point:lands[0],data:lands[0]};
 return{kind:'ground',point:p};
}
function zoomAt(factor,screenX=cssW/2,screenY=cssH/2){const before=unpos(screenX,screenY);camera.mpp=clamp(camera.mpp*factor,.25,16000);const after=unpos(screenX,screenY);camera.x+=before.x-after.x;camera.y+=before.y-after.y;profile();scheduleSave();}
function updateCamera(old,newPt){camera.x-=(newPt.x-old.x)*camera.mpp;camera.y-=(newPt.y-old.y)*camera.mpp;}
function setupGestures(){canvas.addEventListener('pointerdown',e=>{if(e.button!==0)return;e.preventDefault();try{canvas.setPointerCapture(e.pointerId);}catch{}const pt=pointerPoint(e);pointer.set(e.pointerId,pt);if(pointer.size===1){dragStart=pt;panMoved=false;}else if(pointer.size===2){const a=[...pointer.values()];pinch={dist:Math.hypot(a[0].x-a[1].x,a[0].y-a[1].y)};panMoved=true;}});
 canvas.addEventListener('pointermove',e=>{if(!pointer.has(e.pointerId))return;e.preventDefault();const last=pointer.get(e.pointerId),now=pointerPoint(e);pointer.set(e.pointerId,now);if(pointer.size===2){let a=[...pointer.values()];const d=Math.hypot(a[0].x-a[1].x,a[0].y-a[1].y);const mid={x:(a[0].x+a[1].x)/2,y:(a[0].y+a[1].y)/2};if(pinch?.dist>3&&d>3)zoomAt(pinch.dist/d,mid.x,mid.y);pinch={dist:d};return;}
 if(pointer.size===1){if(dragStart&&Math.hypot(now.x-dragStart.x,now.y-dragStart.y)>9)panMoved=true;if(panMoved){updateCamera(last,now);profile();}}
 });
 const end=e=>{if(!pointer.has(e.pointerId))return;const last=pointer.get(e.pointerId),eligible=pointer.size===1&&!panMoved&&dragStart&&Math.hypot(last.x-dragStart.x,last.y-dragStart.y)<12;
 pointer.delete(e.pointerId);if(!pointer.size){pinch=null;dragStart=null;}if(eligible){const p=unpos(last.x,last.y);showSheet(hit(p));}};
 canvas.addEventListener('pointerup',end);canvas.addEventListener('pointercancel',e=>{pointer.delete(e.pointerId);panMoved=true;pinch=null;dragStart=null;});
 canvas.addEventListener('wheel',e=>{e.preventDefault();const p=pointerPoint(e);zoomAt(e.deltaY<0?.83:1.2,p.x,p.y);},{passive:false});
}
function otherPanels(panel){activeTab=panel;for(const n of document.querySelectorAll('[data-view]'))n.classList.toggle('selected',n.dataset.view===panel);
 $('canvasFrame').hidden=panel!=='map';$('records').hidden=panel==='map';$('sheet').hidden=true;if(panel==='map')return;
 const hist=w.history.slice(-25).reverse();let html=panel==='people'?`<h2>故人谱</h2><p>人物在地图上有位置，只有真正相遇后才记录在这里。</p>${w.player.contacts.map(c=>{const p=w.people.find(x=>x.id===c.id);return `<article class="entry">${safe(p?.name||c.id)} · ${safe(p?.job||'')} · 第${c.firstDay}天相识</article>`;}).join('')||'<p>尚无相识之人。</p>'}`:panel==='ledger'?`<h2>县治账本</h2><p>县城及周边有 ${worldReport(w).population} 位人口档案，经济仍采用县级结算，尚不是每人完整的AI模拟。</p><article class="entry">粮价：${w.price} 文/斗<br>县库：${w.treasury} 文<br>县境总粮：${worldReport(w).grain} 斗</article>`:`<h2>此世纪事</h2>${hist.map(e=>`<article class="entry"><small>第${e.day}日 · ${safe(e.type)}</small><p>${safe(e.message)}</p></article>`).join('')}`;
 $('records').innerHTML=html;}
function resize(){const r=canvas.getBoundingClientRect();cssW=Math.max(10,r.width);cssH=Math.max(10,r.height);const dpr=Math.min(2,window.devicePixelRatio||1);canvas.width=Math.round(cssW*dpr);canvas.height=Math.round(cssH*dpr);ctx=canvas.getContext('2d');ctx.setTransform(dpr,0,0,dpr,0,0);drawMap();}
function bind(){canvas=$('worldCanvas');setupGestures();$('zoomIn').onclick=()=>zoomAt(.72);$('zoomOut').onclick=()=>zoomAt(1/.72);$('locate').onclick=()=>{camera.x=w.player.mapPos.x;camera.y=w.player.mapPos.y;camera.mpp=Math.min(camera.mpp,4);profile();scheduleSave();};
 $('stop').onclick=()=>{stopJourney(w);profile();toast('你已停下，已经流逝的时间不会退回。');scheduleSave();};
 $('save').onclick=()=>save().then(()=>toast('存档已保存')).catch(()=>toast('存档保存失败'));
 $('fast').onclick=()=>{travelSpeed=travelSpeed===30?120:travelSpeed===120?1:30;$('fast').textContent=travelSpeed+'倍';toast('世界时间倍率 '+travelSpeed+'×');};
 $('realmButton').onclick=()=>toast('御剑需要境界和法器。此版本暂不提供调试瞬移技能。');
 $('advanceDay').onclick=()=>{if(w.player.route)return toast('行走中，请先停下');simulateDay(w,1);toast('世界推进一日');profile();scheduleSave();};
 $('newWorld').onclick=()=>{if(!confirm('确认创建新世界？当前存档将被新世界替换，原人物不会再次出现。'))return;w=createWorld('县境-'+Date.now());ensureGeo(w);camera={x:0,y:0,mpp:3};selected=null;showSheet(null);otherPanels('map');profile();scheduleSave();};
 for(const btn of document.querySelectorAll('[data-view]'))btn.onclick=()=>otherPanels(btn.dataset.view);
 window.addEventListener('resize',resize);document.addEventListener('visibilitychange',()=>{paused=document.hidden;if(paused)save().catch(()=>{});});
}
let stamp=0,profileStamp=0,saveStamp=0;
function animation(now){const dt=stamp?Math.min(.12,(now-stamp)/1000):0;stamp=now;if(!paused&&w&&dt>0){const old={...w.player.mapPos};const result=advanceMap(w,dt,travelSpeed);if(result.done){toast('到达目的地；移动时间已累计。');scheduleSave();}
 if(result.moved>0){ // 只有实际移动才更新场景名；缩放操作不写入位置。
 camera.x+=w.player.mapPos.x-old.x;camera.y+=w.player.mapPos.y-old.y;
 }
 if(now-profileStamp>260){profile();profileStamp=now;}
 if(now-saveStamp>15000){scheduleSave();saveStamp=now;}}
 if(w&&!$('canvasFrame').hidden)drawMap();requestAnimationFrame(animation);}
async function init(){try{const raw=await load();w=raw?restoreWorld(raw):createWorld();}catch(e){console.warn(e);w=createWorld();toast('旧存档暂时无法读取，当前为临时世界。');}
 ensureGeo(w);if(w.mapCamera&&Number.isFinite(w.mapCamera.mpp))camera={...w.mapCamera};else camera={...w.player.mapPos,mpp:3.2};
 bind();profile();otherPanels('map');resize();if(w.player.indoor)showIndoor();requestAnimationFrame(animation);}
init();
