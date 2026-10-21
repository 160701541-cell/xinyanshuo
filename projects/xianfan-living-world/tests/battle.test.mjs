import test from 'node:test';
import assert from 'node:assert/strict';
import {createBattle,stepBattle,battleReport,TROOPS,WEAPONS} from '../battle.mjs';
import {draftFromWorld} from '../battle-ui.mjs';

function run(seed,spec,maxT=180){
 const b=createBattle({seed,...spec});
 let t=0;while(!b.done&&t<maxT){stepBattle(b,0.1);t+=0.1;}
 return b;
}
const corps=(troop,count)=>({units:[{troop,count}]});

test('士兵是个体：每人有位置、血量、士气、武器与目标',()=>{
 const b=createBattle({seed:'个体',left:corps('infantry',60),right:corps('swordsman',40)});
 assert.equal(b.soldiers.length,100);
 const s=b.soldiers[0];
 for(const k of ['id','side','x','y','hp','maxHp','morale','weapon','state'])assert.ok(k in s,k);
 assert.equal(s.maxHp,TROOPS.infantry.hp);
});

test('同样的种子打两遍，结果一致（可回放）',()=>{
 const a=run('回放',{left:corps('infantry',80),right:corps('swordsman',60)});
 const c=run('回放',{left:corps('infantry',80),right:corps('swordsman',60)});
 const ra=battleReport(a),rc=battleReport(c);
 assert.equal(ra.left.dead,rc.left.dead);
 assert.equal(ra.right.dead,rc.right.dead);
 assert.equal(a.t,c.t);
});

test('武器有差别：同人数下长枪、弓、骑、修士互有胜负',()=>{
 const pairs=[['infantry','archer'],['cavalry','infantry'],['monk','swordsman']];
 for(const [x,y] of pairs){
  const b=run('兵器'+x+y,{left:corps(x,80),right:corps(y,80)});
  const r=battleReport(b);
  assert.ok(r.done,'应分出胜负');
  assert.notEqual(r.left.dead,r.right.dead,`${x} vs ${y} 不该打平`);
 }
});

test('打起来会产生刀光、箭矢、血与尸体',()=>{
 const b=createBattle({seed:'特效',left:corps('infantry',90),right:{units:[{troop:'archer',count:70}]}});
 let sawArrow=false,sawSlash=false,sawBlood=false;
 for(let i=0;i<400&&!b.done;i++){
  stepBattle(b,0.1);
  if(b.arrows.length)sawArrow=true;
  for(const e of b.effects){if(e.kind==='slash')sawSlash=true;if(e.kind==='blood')sawBlood=true;}
 }
 assert.ok(sawArrow,'弓手要射箭');
 assert.ok(sawSlash||sawBlood,'近战要有刀光或溅血');
 assert.ok(b.corpses.length>0,'死人有尸体');
});

test('士气崩了会溃散，并停止还手',()=>{
 const b=run('溃散',{left:corps('infantry',200),right:corps('archer',40)});
 const routed=b.soldiers.filter(s=>s.state==='rout');
 const r=battleReport(b);
 assert.ok(r.right.morale<20||routed.length>0,'弱势一方应溃');
 assert.ok(r.done,'应以一方溃散结束');
});

test('伤亡会计入战报，且不是零和',()=>{
 const b=run('战报',{left:corps('infantry',120),right:corps('swordsman',120)});
 const r=battleReport(b);
 assert.ok(r.left.dead>0&&r.right.dead>0);
 // 存活不再包含投降/溃逃的人，所以要用四段账核对
 assert.ok(r.left.alive+r.left.dead+r.left.surrendered+r.left.routed===r.left.start);
 assert.ok(r.left.lossRate>0&&r.right.lossRate>0);
 assert.ok(['left','right'].includes(r.winner));
});

test('从大地图能编出对局（没有军团时给默认编制）',()=>{
 const spec=draftFromWorld({});
 assert.ok(spec.left.units.length&&spec.right.units.length);
 assert.ok(spec.left.units[0].count>=60);
 const b=createBattle({seed:'draft',...spec});
 assert.ok(b.soldiers.length>100);
});
