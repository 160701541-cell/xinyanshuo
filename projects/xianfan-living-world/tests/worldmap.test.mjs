import test from 'node:test';
import assert from 'node:assert/strict';
import {generateRealm,regionAt,realmReport,pickType,MORTAL_TYPES,XIAN_TYPES} from '../worldmap.mjs';

const mortal=generateRealm({realm:'mortal',grid:108});
const xian=generateRealm({realm:'xian',grid:108});

test('整界铺满：1296 块地覆盖 100%，没有空白',()=>{
 for(const m of [mortal,xian]){
  const r=realmReport(m);
  assert.equal(r.regions,1296);
  assert.ok(r.coverage>0.995,`覆盖率 ${r.coverage}`);
  assert.equal(m.owner.length,108*108);
  assert.ok(m.owner.every(v=>Number.isInteger(v)&&v>=0&&v<1296));
 }
});

test('凡界与仙界同样大，但地块各自一套',()=>{
 assert.equal(mortal.extent,xian.extent);
 assert.equal(mortal.totalKm2,xian.totalKm2);
 const names=new Set(mortal.regions.map(r=>r.id));
 assert.ok(xian.regions.every(r=>!names.has(r.id)));
 assert.ok(mortal.regions.every(r=>MORTAL_TYPES[r.type]),'凡界不得出现仙界地类');
 assert.ok(xian.regions.every(r=>XIAN_TYPES[r.type]),'仙界不得出现凡界地类');
});

test('每块地都有数量：面积、储量、年出、危险度',()=>{
 for(const m of [mortal,xian])for(const r of m.regions){
  assert.ok(r.areaKm2>0,`${r.name} 面积`);
  assert.ok(r.stock>=0);
  assert.ok(r.yearly>=0);
  assert.ok(r.danger>=0&&r.danger<=5);
  assert.ok(r.name.length>=2);
 }
});

test('同一坐标能查到地块，且结果可复现',()=>{
 const p={x:12_345,y:-67_890};
 assert.equal(regionAt(mortal,p).id,regionAt(mortal,p).id);
 const again=generateRealm({realm:'mortal',grid:108});
 assert.deepEqual(again.regions.map(r=>[r.id,r.type,r.x,r.y]),mortal.regions.map(r=>[r.id,r.type,r.x,r.y]));
 assert.equal(regionAt(mortal,{x:9e9,y:0}),null);
});

test('地类成片：相邻地块同类的比例明显高于随机撒花',()=>{
 const G=mortal.grid,owner=mortal.owner;
 let same=0,total=0;
 for(let j=0;j<G;j++)for(let i=0;i<G-1;i++){
  const a=mortal.regions[owner[j*G+i]].type,b=mortal.regions[owner[j*G+i+1]].type;
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
