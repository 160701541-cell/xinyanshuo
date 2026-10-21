import test from 'node:test';
import assert from 'node:assert/strict';
import {layoutTown,layoutVillage,townReport,buildingAt,blockedByBuildings,STREETS,streetsFor,ART} from '../buildings.mjs';
import {STRUCTURES} from '../overworld.mjs';

const town=layoutTown();

test('县城建筑确定性：同一份存档两次生成完全一致',()=>{
 const a=layoutTown(),b=layoutTown();
 assert.deepEqual(a.map(x=>x.id+':'+x.x+','+x.y),b.map(x=>x.id+':'+x.x+','+x.y));
});

test('建筑都有院落、屋与门，且落在城墙以内',()=>{
 assert.ok(town.length>=80);
 for(const b of town.filter(x=>!x.public&&(x.kind==='home'||x.kind==='shop'))){
  assert.ok(Math.abs(b.x+b.w/2)<=710,`${b.id} 出城`);
  assert.ok(Math.abs(b.y+b.h/2)<=710,`${b.id} 出城`);
  if(b.public)continue;
  const kinds=b.parts.map(p=>p.t);
  assert.ok(kinds.includes('house'),`${b.id} 没有主屋`);
  assert.ok(kinds.includes('gate'),`${b.id} 没有院门`);
  assert.ok(kinds.filter(k=>k==='wall').length>=4,`${b.id} 院墙不完整`);
 }
});

test('民居之间不重叠（8 米防火间距）',()=>{
 const houses=town.filter(b=>!b.public&&b.kind==='home');
 for(let i=0;i<houses.length;i++)for(let j=i+1;j<houses.length;j++){
  const a=houses[i],b=houses[j];
  const overlap=a.x<b.x+b.w&&a.x+a.w>b.x&&a.y<b.y+b.h&&a.y+a.h>b.y;
  assert.ok(!overlap,`${a.id} 与 ${b.id} 重叠`);
 }
});

test('街巷整条可走：沿每条街采样，不被院墙与屋顶挡住',()=>{
 for(const s of streetsFor(STRUCTURES)){
  const len=Math.hypot(s.x2-s.x1,s.y2-s.y1);
  for(let t=0;t<=1;t+=10/len){
   const p={x:s.x1+(s.x2-s.x1)*t,y:s.y1+(s.y2-s.y1)*t};
   assert.ok(!blockedByBuildings(town,p,0),`${s.id} 在 (${p.x.toFixed(0)},${p.y.toFixed(0)}) 被建筑挡住`);
  }
 }
});

test('院墙挡人、院门能过',()=>{
 const b=town.find(x=>x.kind==='home'&&!x.public);
 const gate=b.parts.find(p=>p.t==='gate');
 const gateMid={x:gate.x+gate.w/2,y:gate.y+gate.h/2};
 assert.equal(blockedByBuildings(town,gateMid),false,'门口应当能进');
 const wall=b.parts.find(p=>p.t==='wall'&&p.h>=b.h-1);   // 竖着的侧墙，避开门洞
 const wallMid={x:wall.x+wall.w/2,y:wall.y+3};
 assert.equal(blockedByBuildings(town,wallMid),true,'墙上不可走');
 const house=b.parts.find(p=>p.t==='house');
 assert.equal(blockedByBuildings(town,{x:house.x+house.w/2,y:house.y+house.h/2}),true,'屋顶不可走');
});

test('城里既有民居也有集市、菜地与水塘——不是清一色',()=>{
 const r=townReport(town);
 assert.ok(r.houses>=60);
 assert.ok(r.publics>=6);
 assert.ok(town.some(b=>b.kind==='garden'));
 assert.ok(town.some(b=>b.kind==='pond'));
 assert.ok(town.some(b=>b.kind==='shop'));
});

test('村落按路散开，没有城墙也不重叠',()=>{
 const v=layoutVillage();
 assert.ok(v.length>=10);
 for(let i=0;i<v.length;i++)for(let j=i+1;j<v.length;j++){
  const a=v[i],b=v[j];
  assert.ok(!(a.x<b.x+b.w&&a.x+a.w>b.x&&a.y<b.y+b.h&&a.y+a.h>b.y),`${a.id} 与 ${b.id} 重叠`);
 }
});

test('建筑层有统一画风色板与命中测试',()=>{
 assert.ok(ART.roof.home&&ART.wall.rammed&&ART.ink);
 const b=town.find(x=>x.public);
 const hit=buildingAt(town,{x:b.x+2,y:b.y+2});
 assert.equal(hit.id,b.id);
 assert.equal(buildingAt(town,{x:999999,y:999999}),null);
});
