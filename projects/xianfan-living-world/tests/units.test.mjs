import test from 'node:test';
import assert from 'node:assert/strict';
import {createWorld} from '../core.mjs';
import {ensureGeo} from '../overworld.mjs';
import {ensureWar,createArmy,battleDay} from '../war.mjs';
import {quality,equip,equipCost,drill,drillCost,research,setFormation,purseOf,compositionFor,unitsReport,ARMS,MATCHUP,ensureFin} from '../units.mjs';

function fresh(seed='兵种'){
 const w=createWorld(seed);ensureGeo(w);ensureWar(w);ensureFin(w);return w;
}
const rngFrom=(seed)=>{let a=seed>>>0;return()=>{a=(a*1664525+1013904223)>>>0;return a/4294967296;};};

test('五国兵种构成不同，且各兵种人数与总兵力一致',()=>{
 const w=fresh();
 for(const f of ['court','merchant','folk','sect','guard']){
  const a=createArmy(w,f,{combat:3000});
  const rep=unitsReport(a);
  const sum=rep.reduce((n,x)=>n+x.men,0);
  assert.ok(Math.abs(sum-a.combat)<=rep.length,'兵种人数之和应等于总兵力');
  assert.ok(rep.length>=3);
 }
 const sect=createArmy(w,'sect',{combat:3000});
 assert.ok(unitsReport(sect).some(x=>x.arm==='sword'),'青云应有剑修');
});

test('对位克制是乘数：枪兵克骑兵，骑兵克弓弩',()=>{
 assert.ok(MATCHUP.inf.cav>1);
 assert.ok(MATCHUP.cav.arc>1);
 assert.ok(MATCHUP.arc.cav<1);
 const w=fresh();
 const spear=createArmy(w,'folk',{combat:3000,units:{inf:1}});
 const horse=createArmy(w,'guard',{combat:3000,units:{cav:1}});
 const horseVsSpear=quality(horse,spear);
 const spearVsHorse=quality(spear,horse);
 assert.ok(spearVsHorse>quality(spear,null),'步兵遇到骑兵更“值钱”');
 assert.ok(horseVsSpear<quality(horse,null),'骑兵遇到步兵更吃亏');
});

test('没有冶金就造不出札甲：科技是装备的前置',()=>{
 const w=fresh();
 const a=createArmy(w,'court',{combat:10000});
 const r=equip(w,a,{armor:2,share:.3});
 assert.equal(r.ok,false);
 assert.match(r.error,/冶金/);
 assert.equal(research(w,'metallurgy').ok,true);
 assert.equal(equip(w,a,{armor:2,share:.3}).ok,true);
});

test('经济限制真实存在：府库不够就换不了装、练不了兵',()=>{
 const w=fresh();
 const b=createArmy(w,'court',{combat:20000});
 research(w,'metallurgy');
 const a=createArmy(w,'court',{combat:160000}); // 全员铁甲超出府库承受
 assert.equal(equip(w,a,{armor:3,share:1}).ok,false);
 ensureFin(w);w.states.court.treasury=0;
 assert.equal(drill(w,b,60).ok,false);
});

test('换装按比例提升质量，且花的钱等于人数×比例×单价',()=>{
 const w=fresh();
 const a=createArmy(w,'court',{combat:10000});
 const before=quality(a);
 research(w,'metallurgy');
 const cost=equipCost(a,{armor:2,weapon:1,share:.5});
 const r=equip(w,a,{armor:2,weapon:1,share:.5});
 assert.equal(r.ok,true);assert.equal(r.cost,cost);
 assert.ok(quality(a)>before);
});

test('训练与战历、阵型都进战力；阵型是有代价的',()=>{
 const w=fresh();
 const a=createArmy(w,'court',{combat:20000});
 const base=quality(a);
 drill(w,a,60);
 assert.ok(quality(a)>base);
 const before=quality(a);
 setFormation(w,a,'wedge');
 assert.ok(quality(a)>before,'锋矢攻击更高');
 setFormation(w,a,'square');
 assert.ok(quality(a)<before,'方圆攻击更低');
});

test('阵型与兵种对位影响实战伤亡',()=>{
 const w=fresh();
 const a=createArmy(w,'guard',{combat:4000,seed:3});
 const b=createArmy(w,'folk',{combat:4000,seed:9});
 a.train=80;b.train=30;
 for(let i=0;i<2;i++)battleDay(a,b,rngFrom(i+1));
 assert.ok(a.losses.combat<b.losses.combat,'训练与甲骑更好的御城军伤亡应更少');
});
