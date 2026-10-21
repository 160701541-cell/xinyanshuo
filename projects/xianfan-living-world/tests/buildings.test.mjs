import test from 'node:test';
import assert from 'node:assert/strict';
import {layoutTown,layoutVillage,townReport,buildingAt,STREETS,ART} from '../buildings.mjs';

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

test('街巷不被房屋占住：主街中线是空的',()=>{
 for(const s of STREETS){
  const mid={x:(s.x1+s.x2)/2,y:(s.y1+s.y2)/2};
  const hit=town.find(b=>!b.public&&mid.x>b.x&&mid.x<b.x+b.w&&mid.y>b.y&&mid.y<b.y+b.h);
  assert.ok(!hit,`${s.id} 被 ${hit?.id} 占了`);
 }
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
