import {VERSION,PLACES,createWorld,getPlace,sceneActors,npcActivity,scenery,worldReport,simulateDay,navigate,travel,changeRole,buyGrain,relief,greet,saveableWorld,restoreWorld,isInterior,shortestRoute} from './core.js';
const $=id=>document.getElementById(id);
const E=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const fmt=n=>Math.round(n).toLocaleString('zh-CN');
const monthNames=['正月','二月','三月','四月','五月','六月','七月','八月','九月','十月','冬月','腊月'];
const title=p=>p.name.replace('临安县·','').replace('青云山·','');
const kind={street:'街道',market:'街市',office:'县衙',homes:'里坊',shop:'商铺',inn:'客栈',room:'室内',gate:'城门',port:'渡口',road:'官道',village:'村落',sect:'宗门'};
let state, tab='scene', mapScale='near', mode='foot', selectedNpc=null, selectedPlace=null, toastTimer, saveTimer, tempWorld=false;
function clock(){const n=state.day-1;return `承平${Math.floor(n/360)+3}年 · ${monthNames[Math.floor((n%360)/30)]}${n%30+1}日 · ${Math.floor(state.hour)}时`;}
function toast(msg){const node=$('notice');node.textContent=msg;node.classList.add('show');clearTimeout(toastTimer);toastTimer=setTimeout(()=>node.classList.remove('show'),3500);}
function queueSave(){if(tempWorld)return;clearTimeout(saveTimer);saveTimer=setTimeout(()=>persist(state).catch(console.warn),500);}
function render(){const p=getPlace(state.player.place),stats=worldReport(state);if(!p)return;
 $('regionTrail').innerHTML=`<button type="button" class="trail" data-world>大宁 / 青州 / 临安县</button><span aria-hidden="true">›</span><strong>${E(title(p))}</strong>`;
 $('sceneHeading').innerHTML=`<div class="location-kicker">${mapScale==='county'?'县域总图 / 可点选目的地':'当前场景 / '+E(kind[p.type])}</div><h1>${E(p.name)}</h1><p>${E(clock())} · ${E(state.weather)}</p>`;
 $('countyFacts').innerHTML=`<span>县境 <b>${fmt(stats.population)} 人</b></span><span>粮价 <b>${fmt(stats.price)} 文/斗</b></span><span>身份 <b>${E(state.player.role)}</b></span>`;
 $('tabs').querySelectorAll('button').forEach(b=>{const active=b.dataset.tab===tab;b.classList.toggle('active',active);b.setAttribute('aria-current',active?'page':'false');});
 $('scope').hidden=tab!=='scene';$('scope').textContent=mapScale==='county'?'返回当前场景':'查看县域';
 $('content').innerHTML=({scene:sceneView,people:relationsView,office:officeView,history:historyView})[tab]();
 $('travelFoot').classList.toggle('chosen',mode==='foot');$('travelSword').classList.toggle('chosen',mode==='sword');
 bindContent();}
function at(name,x,y,cls,attrs='',label=''){return `<button type="button" class="point ${cls}" style="--x:${x}%;--y:${y}%" ${attrs}><span class="point-name">${E(name)}</span>${label?`<small>${E(label)}</small>`:''}</button>`;}
function zoneBoard(){const s=scenery(state),p=s.place;
 const links=s.exits.map(link=>at(link.name,link.x,link.y,link.kind,`data-goto="${E(link.id)}"`,link.kind==='door'?'进入 ↗':'前往 ↗')).join('');
 const items=s.props.map(prop=>`<span class="prop" style="--x:${prop.x}%;--y:${prop.y}%">${E(prop.name)}</span>`).join('');
 const citizens=sceneActors(state,p.id,10);const positions=[[44,28],[62,35],[53,63],[28,46],[73,55],[38,74],[61,79],[48,44],[20,30],[76,32]];
 const nps=citizens.map((npc,i)=>{let [x,y]=positions[i];return at(npc.name,x,y,'actor'+(selectedNpc===npc.id?' selected':''),`data-npc="${E(npc.id)}"`,`◦ ${npcActivity(state,npc)}`);}).join('');
 const description=`<div class="scene-story"><span class="scene-summary-label">所见</span>${E(p.detail)}</div>`;
 const board=`<div class="scene-board ${isInterior(p)?'indoor':''} ${p.type==='market'?'market':''}" aria-label="${E(p.name)}可交互场景地图"><div class="scene-road" aria-hidden="true"></div>${items}${links}${nps}<div class="player-mark" title="你的位置"><span>我</span></div><div class="compass">北 ↑</div></div>`;
 const info=selectedNpc?personPanel(citizens.find(n=>n.id===selectedNpc)):selectedPlace?placePanel(getPlace(selectedPlace)):defaultPanel(p,citizens);
 return `${description}<div class="play-field">${board}<aside class="scene-inspector" aria-label="场景详情">${info}</aside></div><div class="scene-footnote">地图上的建筑、道路和人物均可点击。点建筑即进入室内，人物只会出现在其当前所在的场所。</div>`;
}
function defaultPanel(place,visible){return `<div class="inspector-eyebrow">当前场所</div><h2>${E(title(place))}</h2><div class="inspector-type">${E(kind[place.type])}</div><p>${E(place.detail)}</p><div class="inspector-divider"></div><p class="muted">看见 ${visible.length} 名人物（场景最多展示10人）</p><p class="muted">点人物查看身份与行为；点建筑或出口直接移动，无需在多个菜单间切换。</p>${place.id==='lianghang'?`<div class="trade"><b>福源粮行</b><p>现粮 ${fmt(state.places.lianghang.merchantGrain)} 斗 · 今日粮价 ${state.price} 文/斗</p><button class="primary" id="buy3">购买三斗粮</button></div>`:''}${place.id==='xianya'?`<div class="trade"><b>县衙事务</b><p>县仓 ${fmt(state.places.xianya.granary)} 斗 · 县库 ${fmt(state.treasury)} 文</p><button class="primary" id="relief" ${state.player.role==='县吏'?'':'disabled'}>调拨100斗赈粮</button></div>`:''}`;}
function personPanel(n){if(!n)return `<h2>人物已离开</h2><p>此人已经不在当前场景。</p><button class="text-action" data-reset>返回场景</button>`;
 const met=state.player.contacts.find(c=>c.id===n.id);return `<div class="inspector-eyebrow">所见人物 / ${E(n.id)}</div><h2>${E(n.name)}</h2><div class="inspector-type">${E(n.job)} · ${n.age} 岁</div><p class="doing"><i></i>${E(npcActivity(state,n))}</p><dl><dt>住处</dt><dd>${E(title(getPlace(n.home)))}</dd><dt>可见气质</dt><dd>${E(n.traits.join('、'))}</dd><dt>你与此人</dt><dd>${met?`初遇第 ${met.firstDay} 日 · 共见 ${met.meetings} 次`:'尚未相识'}</dd></dl><button class="primary" id="greetNpc" data-id="${E(n.id)}">与${E(n.name)}交谈</button><button class="text-action" data-reset>返回场景</button><p class="small muted">交谈不会自动增加好感或产生恋爱关系。</p>`;}
function placePanel(p){if(!p)return defaultPanel(getPlace(state.player.place),[]);const route=shortestRoute(state.player.place,p.id);return `<div class="inspector-eyebrow">地图地点</div><h2>${E(p.name)}</h2><div class="inspector-type">${E(kind[p.type])}</div><p>${E(p.detail)}</p><p class="muted">${route?`步行连通 ${route.length-1} 段路程`:'尚无已知道路'}</p><button class="primary" id="navigateChosen" data-id="${E(p.id)}">${mode==='sword'?'御剑前往':'沿路前往'}</button><button class="text-action" data-reset>收起</button>`;}
function countyMap(){const nodes=PLACES.filter(x=>!isInterior(x)&&x.population>0&&x.id!=='xianya');
 const lines=[],seen=new Set();for(const a of nodes)for(const id of a.links){const b=getPlace(id);if(!b||!nodes.includes(b))continue;const key=[a.id,b.id].sort().join(':');if(seen.has(key))continue;seen.add(key);lines.push(`<line x1="${a.x}" y1="${a.y}" x2="${b.x}" y2="${b.y}" />`);}
 const elements=nodes.map(n=>at(n.name.replace('临安县·','').replace('青云山·',''),n.x,n.y,`county-pin ${n.id===state.player.place?'here':''}`,`data-pick="${E(n.id)}"`,kind[n.type])).join('');
 return `<div class="scene-story"><span class="scene-summary-label">县志地理</span>城郭、乡村、官道与青云山互相连通。县域图也是同一个世界，点选地点可沿道路自动前往；返回街巷后可直接进入建筑。</div><div class="play-field"><div class="scene-board county-board" aria-label="临安县区域地图"><svg class="region-lines" viewBox="0 0 100 100" preserveAspectRatio="none">${lines.join('')}</svg><div class="river"></div>${elements}<span class="map-legend">▥ 县郭　♧ 乡村　△ 宗门</span></div><aside class="scene-inspector">${selectedPlace?placePanel(getPlace(selectedPlace)):`<div class="inspector-eyebrow">临安县 / 县域总览</div><h2>山河与街巷</h2><p>当前身处 ${E(getPlace(state.player.place).name)}。</p><p>步行遵守道路连接、经过时间；御剑需要修士身份及灵力，并且只能室外起降。</p><button class="primary" id="backNear">返回所在场景</button>`}</aside></div>`;
}
function sceneView(){return mapScale==='county'?countyMap():zoneBoard();}
function relationsView(){const contacts=state.player.contacts.slice().reverse().slice(0,20);return `<section class="document-pane"><div class="eyebrow">人物 · 你实际认识过的人</div><h2>故人簿</h2><p>场景里的陌生人不会先出现在人物列表里。你曾经遇见并交谈过的人，才进入故人簿。</p>${contacts.length?contacts.map(c=>{const n=state.people.find(x=>x.id===c.id);if(!n)return '';return `<div class="record"><strong>${E(n.name)}</strong><small>${E(n.job)} / ${E(c.id)} · 第 ${c.firstDay} 日相识于 ${E(title(getPlace(c.firstPlace)))}</small><span>相逢 ${c.meetings} 次 · ${n.status==='alive'?'在世':'已故'}</span></div>`;}).join(''):'<div class="empty-note">尚无故人。进入场景，点击真实在场的NPC并与其交谈。</div>'}</section>`;}
function officeView(){const r=worldReport(state);return `<section class="document-pane"><div class="eyebrow">县治 · 演示政务</div><h2>临安县账簿</h2><p>目前为简化地区经济，不代表万余人都已具备完整自主生产和贸易。</p><div class="ledger"><span>户籍人口</span><b>${fmt(r.population)}人</b><span>县境总粮</span><b>${fmt(r.grain)}斗</b><span>粮市牌价</span><b>${r.price}文/斗</b><span>县库</span><b>${fmt(state.treasury)}文</b></div><h3>身份调试</h3><p>以下是临时测试身份，不代表已经有真实的官员晋升流程。</p><div class="inline-actions">${['平民','县吏','修士'].map(role=>`<button class="secondary role" data-role="${role}" ${state.player.role===role?'aria-pressed="true"':''}>${role}</button>`).join('')}</div><h3>各地人口</h3>${PLACES.filter(p=>p.population>0).map(p=>`<div class="record compact"><strong>${E(title(p))}</strong><small>${fmt(state.places[p.id].population)}人</small></div>`).join('')}</section>`;}
function historyView(){return `<section class="document-pane"><div class="eyebrow">县志 · 非预设剧情</div><h2>此世纪事</h2><p>只记录已经由游戏规则实际发生的事件，未完成的社会模拟不伪装为传奇故事。</p>${state.history.slice(-60).reverse().map(ev=>`<div class="chronicle"><span>第${ev.day}日 · ${E(ev.type)}</span><p>${E(ev.message)}</p></div>`).join('')}</section>`;}
function bindContent(){document.querySelectorAll('[data-goto]').forEach(b=>b.addEventListener('click',()=>go(b.dataset.goto,'foot')));
 document.querySelectorAll('[data-npc]').forEach(b=>b.addEventListener('click',()=>{selectedNpc=b.dataset.npc;selectedPlace=null;render();}));
 document.querySelectorAll('[data-pick]').forEach(b=>b.addEventListener('click',()=>{selectedPlace=b.dataset.pick;selectedNpc=null;render();}));
 document.querySelectorAll('[data-reset]').forEach(b=>b.addEventListener('click',()=>{selectedNpc=null;selectedPlace=null;render();}));
 document.querySelectorAll('[data-world]').forEach(b=>b.addEventListener('click',()=>{tab='scene';mapScale='county';render();}));
 document.querySelectorAll('.role').forEach(b=>b.addEventListener('click',()=>{changeRole(state,b.dataset.role);render();queueSave();}));
 $('greetNpc')?.addEventListener('click',e=>act(greet(state,e.currentTarget.dataset.id),'已记下这次见面。'));
 $('navigateChosen')?.addEventListener('click',e=>go(e.currentTarget.dataset.id,mode));
 $('backNear')?.addEventListener('click',()=>{mapScale='near';selectedPlace=null;render();});
 $('buy3')?.addEventListener('click',()=>act(buyGrain(state,3),'购买了三斗粮，粮行实际库存减少。'));
 $('relief')?.addEventListener('click',()=>act(relief(state,100),'县仓与县库已扣账，赈粮进入南坊。'));
}
function act(result,ok){toast(result.ok?ok:result.error);render();if(result.ok)queueSave();}
function go(id,forceMode=mode){let result=navigate(state,id,forceMode);if(result.ok){selectedNpc=null;selectedPlace=null;tab='scene';mapScale='near';}toast(result.ok?result.description:result.error);render();if(result.ok)queueSave();}
async function db(){return new Promise((resolve,reject)=>{const req=indexedDB.open('xianfan_county_offline',1);req.onupgradeneeded=()=>req.result.createObjectStore('worlds');req.onsuccess=()=>resolve(req.result);req.onerror=()=>reject(req.error);});}
async function persist(w){const database=await db();return new Promise((resolve,reject)=>{const tx=database.transaction('worlds','readwrite');tx.objectStore('worlds').put(saveableWorld(w),'current');tx.oncomplete=resolve;tx.onerror=()=>reject(tx.error);});}
async function recover(){const database=await db();return new Promise((resolve,reject)=>{const tx=database.transaction('worlds','readonly');const req=tx.objectStore('worlds').get('current');req.onsuccess=()=>resolve(req.result||null);req.onerror=()=>reject(req.error);});}
async function boot(){try{const raw=await recover();state=raw?restoreWorld(raw):createWorld();}catch(e){console.warn('存档读取失败',e);state=createWorld();tempWorld=true;toast('旧存档读取异常，进入临时世界；旧数据未覆盖。');}render();}
$('tabs').querySelectorAll('button').forEach(b=>b.addEventListener('click',()=>{tab=b.dataset.tab;selectedNpc=null;render();}));
$('scope').onclick=()=>{tab='scene';mapScale=mapScale==='near'?'county':'near';selectedPlace=null;render();};
$('travelFoot').onclick=()=>{mode='foot';toast('步行模式：点地点可以自动循路。');render();};
$('travelSword').onclick=()=>{mode='sword';tab='scene';mapScale='county';toast('御剑模式：室外起降，消耗灵力。');render();};
$('nextDay').onclick=()=>{simulateDay(state,1);selectedNpc=null;render();queueSave();toast('新的一天，县城照常运转。');};
$('nextMonth').onclick=()=>{simulateDay(state,30);selectedNpc=null;render();queueSave();toast('三十日过去，查看县志所记的变化。');};
$('save').onclick=async()=>{try{await persist(state);tempWorld=false;toast('已保存到本机存档。');}catch(e){toast('存档失败：设备存储不可用。');console.error(e)}};
$('restart').onclick=()=>{const seed=prompt('新世界种子（覆盖当前未保存进度）',`临安-${Date.now()}`);if(seed===null)return;state=createWorld(seed);tempWorld=true;tab='scene';mapScale='near';selectedNpc=null;selectedPlace=null;render();toast('新的世界已开始。旧存档在手动保存前不会覆盖。');};
document.addEventListener('visibilitychange',()=>{if(document.visibilityState==='hidden'&&state&&!tempWorld){clearTimeout(saveTimer);persist(state).catch(console.warn);}});
boot();