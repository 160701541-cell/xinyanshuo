import test from 'node:test';
import assert from 'node:assert/strict';
import {generateWorld,generateRealm,realmView,domainShare,regionAt,realmReport,pickType,MORTAL_TYPES,XIAN_TYPES} from '../worldmap.mjs';

const world=generateWorld({grid:108});
const mortal=realmView(world,'mortal');
const xian=realmView(world,'cultivation');

test('一张世界图铺满：1296 块地覆盖 100%，两界交错不分图',()=>{
 const r=realmReport(world);
 assert.equal(r.regions,1296);
 assert.ok(r.coverage>0.995,`覆盖率 ${r.coverage}`);
 assert.equal(world.owner.length,108*108);
 assert.ok(world.owner.every(v=>Number.isInteger(v)&&v>=0&&v<1296));
 const share=domainShare(world);
 assert.ok(share.cultivation>.08&&share.cultivation<.35,`修仙界占比 ${share.cultivation}`);
 // 两界是同一张地图上的不同地块，视角只是留白，不是另一张图
 assert.equal(mortal.regions.length+xian.regions.length,1296);
 assert.ok(mortal.owner.some(v=>v<0)&&xian.owner.some(v=>v<0));
 assert.equal(mortal.owner.length,xian.owner.length);
 for(let i=0;i<world.owner.length;i++){
  const d=world.regions[world.owner[i]].domain;
  assert.ok(d==='mortal'?mortarOwnerOK(mortal,i):xianOwnerOK(xian,i));
 }
});
function mortarOwnerOK(m,i){return m.owner[i]>=0;}
function xianOwnerOK(x,i){return x.owner[i]>=0;}

test('两界同坐标：凡界地块只出凡界地类，修仙界地块只出仙界地类',()=>{
 assert.equal(mortal.extent,xian.extent);
 assert.ok(mortal.regions.every(r=>MORTAL_TYPES[r.type]),'凡界不得出现仙界地类');
 assert.ok(xian.regions.every(r=>XIAN_TYPES[r.type]),'修仙界不得出现凡界地类');
 const ids=new Set(mortal.regions.map(r=>r.id));
 assert.ok(xian.regions.every(r=>!ids.has(r.id)));
});

test('每块地都有数量：面积、储量、年出、危险度',()=>{
 for(const m of [world])for(const r of m.regions){
  assert.ok(r.areaKm2>0,`${r.name} 面积`);
  assert.ok(r.stock>=0);
  assert.ok(r.yearly>=0);
  assert.ok(r.danger>=0&&r.danger<=5);
  assert.ok(r.name.length>=2);
 }
});

test('同一坐标能查到地块，且结果可复现',()=>{
 const p={x:12_345,y:-67_890};
 assert.equal(regionAt(world,p).id,regionAt(world,p).id);
 const again=generateWorld({grid:108});
 assert.deepEqual(again.regions.map(r=>[r.id,r.type,r.x,r.y]),world.regions.map(r=>[r.id,r.type,r.x,r.y]));
 assert.equal(regionAt(world,{x:9e9,y:0}),null);
});

test('地类成片：相邻地块同类的比例明显高于随机撒花',()=>{
 const G=world.grid,owner=world.owner;
 let same=0,total=0;
 for(let j=0;j<G;j++)for(let i=0;i<G-1;i++){
  const a=world.regions[owner[j*G+i]].type,b=world.regions[owner[j*G+i+1]].type;
  total++;if(a===b)same++;
 }
 assert.ok(same/total>0.55,`相邻同类比例 ${(same/total).toFixed(2)}`);
});

test('地类规则：高山出山地、泽地出湖泊或泽薮、仙界灵气高处出灵脉',()=>{
 assert.equal(pickType('mortal',{e:.9,m:.5,w:.4}),'mountain');
 assert.equal(pickType('mortal',{e:.1,m:.8,w:.4}),'lake');
 assert.equal(pickType('mortal',{e:.1,m:.3,w:.4}),'marsh');
 assert.equal(pickType('xian',{e:.5,m:.3,w:.4,q:.8}),'lingmai');
 assert.equal(pickType('xian',{e:.9,m:.3,w:.4,q:.6}),'yaoshan');
});
