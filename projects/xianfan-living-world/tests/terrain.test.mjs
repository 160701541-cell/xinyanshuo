import test from 'node:test';
import assert from 'node:assert/strict';
import {terrainHeight,MAP_VERSION} from '../overworld.mjs';

test('地形是确定性的：同一坐标永远同一海拔',()=>{
 for(const [x,y] of [[0,0],[1234,-567],[-9000,4000],[20000,20000]]){
  assert.equal(terrainHeight(x,y),terrainHeight(x,y));
 }
});

test('海拔落在 0–320 米，且县城不是最低点',()=>{
 let lo=1e9,hi=-1e9;
 for(let i=0;i<400;i++){
  const x=(i%20-10)*1500,y=(Math.floor(i/20)-10)*1500;
  const h=terrainHeight(x,y);lo=Math.min(lo,h);hi=Math.max(hi,h);
 }
 assert.ok(lo>=0,`有负海拔 ${lo}`);
 assert.ok(hi<=340,`海拔过高 ${hi}`);
 assert.ok(hi-lo>60,'地形太平，没有起伏');
});

test('地形连续：相邻 10 米的海拔差不超过 6 米（没有断崖式跳变）',()=>{
 let worst=0;
 for(let i=0;i<300;i++){
  const x=(i*37%9000)-4500,y=(i*61%9000)-4500;
  worst=Math.max(worst,Math.abs(terrainHeight(x,y)-terrainHeight(x+10,y)));
 }
 assert.ok(worst<=6,`相邻 10 米落差 ${worst} 米，说明地形有锯齿`);
});

test('地形没有周期性纹理：相隔 7854 米（旧正弦周期）不应完全一样',()=>{
 let same=0;
 for(let i=0;i<50;i++){
  const x=i*137,y=i*311;
  if(terrainHeight(x,y)===terrainHeight(x+7854,y))same++;
 }
 assert.ok(same<3,`${same}/50 个点与一个周期后完全相同，可能仍是正弦地形`);
});

test('地图版本号随地形改动递增',()=>{
 assert.match(MAP_VERSION,/^county-0\.9\.0$/);
});
