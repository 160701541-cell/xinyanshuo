import test from 'node:test';
import assert from 'node:assert/strict';
import {createWorld,changeRole} from '../core.mjs';
import {ensureGeo,visibleActors,actorVisibility,apparentLocation,isRiver,BRIDGES,dist,PLACE_METERS,obstacleAt,canFly,beginFlight,beginJourney,stopJourney,advanceMap,rest,openingStatus,enterStructure,STRUCTURES} from '../overworld.mjs';
import {classifyGesture,canSelect} from '../gesture.mjs';
const make=(seed='v07')=>ensureGeo(createWorld(seed));

test('v0.7 夜间街上不出现居家人物，白天可见者的位置与其所在场所一致',()=>{
 const w=make();
 w.hour=2;const night=visibleActors(w);
 assert.ok(night.every(a=>a.state==='巡夜'),'深夜只有巡夜者可见');
 w.hour=10;const noon=visibleActors(w);
 assert.ok(noon.length>0);
 for(const a of noon){const p=w.people.find(q=>q.id===a.id);assert.equal(a.where,apparentLocation(w,p));}
});

test('v0.7 地图上的人物必须来自人口档案',()=>{
 const w=make();w.hour=10;const ids=new Set(w.people.map(q=>q.id));
 assert.ok(visibleActors(w).every(a=>ids.has(a.id)));
 for(const a of w.mapActors){const p=w.people.find(q=>q.id===a.id);assert.ok(p);actorVisibility(w,p);}
});

test('v0.7 河面阻断通行，桥与渡口可以过河',()=>{
 const w=make();assert.ok(BRIDGES.length>0);assert.equal(obstacleAt(BRIDGES[0]),null);
 let blocked=false;
 for(let k=0;k<400;k++){const p={x:-6000+k*30,y:BRIDGES[0].y+260};if(isRiver(p)&&obstacleAt(p)==='河流'){blocked=true;break;}}
 assert.ok(blocked,'河面必须阻挡');
});

test('v0.7 打烊的商店不允许进入，客栈通宵',()=>{
 const w=make();const shop=STRUCTURES.find(s=>s.id==='lianghang');
 w.hour=23;assert.equal(openingStatus('lianghang',w.hour).open,false);
 w.player.mapPos={...shop.door};assert.equal(enterStructure(w,'lianghang').ok,false);
 w.hour=10;assert.equal(openingStatus('lianghang',w.hour).open,true);
 assert.equal(openingStatus('kezhan',23).open,true);
});

test('v0.7 御剑需要身份、灵力与可落脚点',()=>{
 const w=make();
 assert.equal(canFly(w).ok,false);
 assert.equal(beginFlight(w,PLACE_METERS.qingyun).ok,false);
 changeRole(w,'修士');
 // 城内禁飞：世俗城池需筑基以上，炼气修士在临安城里起不了剑。
 assert.equal(canFly(w).ok,false);
 w.player.mapPos={x:0,y:4200};// 出城到官道
 assert.equal(canFly(w).ok,true);
 const spirit=w.player.spirit;const r=beginFlight(w,PLACE_METERS.songlin,'songlin');
 assert.equal(r.ok,true,r.error);assert.ok(w.player.spirit<spirit);
 const before={...w.player.mapPos};advanceMap(w,.12,30);
 assert.ok(dist(w.player.mapPos,before)>0);
});

test('v0.7 行走消耗体力，歇息恢复体力且世界时间照常流逝',()=>{
 const w=make();const st=w.player.stats;st.stamina=100;
 assert.equal(beginJourney(w,{x:0,y:400}).ok,true);
 for(let i=0;i<8;i++)advanceMap(w,.12,30);
 assert.ok(st.stamina<100);
 stopJourney(w);const hour=w.hour;assert.equal(rest(w,30).ok,true);
 assert.ok(w.hour>hour);assert.ok(st.stamina>0);
});

test('v0.7 手势：拖动、双指、长按都不会被判为点击',()=>{
 assert.equal(classifyGesture({pointers:1,moved:false,multiTouched:false,still:3,duration:120}),'tap');
 assert.equal(canSelect('tap'),true);
 assert.equal(classifyGesture({pointers:1,moved:true,multiTouched:false,still:40,duration:120}),'pan');
 assert.equal(classifyGesture({pointers:2,moved:false,multiTouched:true,still:0,duration:120}),'pinch');
 assert.equal(classifyGesture({pointers:1,moved:false,multiTouched:false,still:2,duration:900}),'longpress');
 for(const g of ['pan','pinch','longpress'])assert.equal(canSelect(g),false);
});

test('v0.7 途中相遇记录的对象必须已在人口档案内',()=>{
 const w=make();w.hour=10;const ids=new Set(w.people.map(p=>p.id));
 assert.equal(beginJourney(w,{x:0,y:400}).ok,true);
 for(let i=0;i<40;i++){const t=advanceMap(w,.12,30);for(const e of t.encounters||[])assert.ok(ids.has(e.id));}
});
