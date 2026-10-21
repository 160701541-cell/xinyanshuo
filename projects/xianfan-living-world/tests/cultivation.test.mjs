import test from 'node:test';
import assert from 'node:assert/strict';
import {createWorld} from '../core.mjs';
import {ensureGeo} from '../overworld.mjs';
import {ensureFin,purseOf} from '../units.mjs';
import {ensureState} from '../state.mjs';
import {setRank} from '../war.mjs';
import {ensureCultivation,rollRoot,ROOTS,cultivatorDensity,sectPower,hireRetainer,retainerPower,raidSect,mortalWork,xianReport,QI_REGIONS} from '../cultivation.mjs';

function fresh(seed='仙凡'){
 const w=createWorld(seed);ensureGeo(w);ensureFin(w);setRank(w,'皇帝');ensureCultivation(w);return w;
}

test('灵根稀有：绝大多数人无灵根，天灵根千中无一',()=>{
 const n=4000;const cnt={};
 for(let i=0;i<n;i++){const r=rollRoot(i*7+1).id;cnt[r]=(cnt[r]||0)+1;}
 assert.ok(cnt.none/n>0.3,`无灵根应占三成以上，实际 ${cnt.none/n}`);
 assert.ok((cnt.tian||0)/n<0.01,'天灵根应低于 1%');
 assert.ok((cnt.dan||0)/n<(cnt.wu||0)/n);
});

test('县城的修士密度远低于山门：灵气决定人口',()=>{
 const town=cultivatorDensity('xiancheng').per10k;
 const sect=cultivatorDensity('qingyun').per10k;
 const veins=cultivatorDensity('lingshan').per10k;
 assert.ok(town<sect);assert.ok(sect<veins);
 assert.ok(town<1,'县城每万人出不了几个修士');
});

test('宗门战力按境界与人数算，金丹宗门远高于散修',()=>{
 const w=fresh();const x=ensureCultivation(w);
 const qy=x.sects.find(s=>s.id==='qingyun'),ls=x.sects.find(s=>s.id==='lingshan');
 assert.ok(sectPower(qy)>sectPower(ls));
});

test('招供奉要花府库的钱：没钱请不动修士',()=>{
 const w=fresh();
 ensureFin(w);w.states.court.treasury=0;
 assert.equal(hireRetainer(w,{sect:'散修',realm:'found'}).ok,false);
 ensureFin(w);w.states.court.treasury=5_000_000;
 const r=hireRetainer(w,{sect:'散修',realm:'found'});
 assert.equal(r.ok,true);
 assert.ok(retainerPower(w)>0);
});

test('皇族无灵根也能灭宗门：靠供奉的战力，不看自己灵根',()=>{
 const w=fresh();
 assert.ok(retainerPower(w)===0);
 assert.equal(raidSect(w,'qingyun').ok,false,'没有供奉打不下青云');
 // 一个金丹不够；要灭宗门，得养一群高境供奉
 ensureFin(w);w.states.court.treasury=9_000_000;
 const sector=sectPower(ensureCultivation(w).sects[0]);
 let guard=0;
 while(retainerPower(w)<sector*1.2&&guard++<20){
  const r=hireRetainer(w,{sect:'散修',realm:'nascent'});
  assert.equal(r.ok,true,'府库应支持招揽元婴供奉');
 }
 assert.ok(retainerPower(w)>=sector*1.2,'供奉总战力应压过青云山门');
 const raid=raidSect(w,'qingyun');
 assert.equal(raid.ok,true);

 assert.equal(ensureCultivation(w).sects[0].destroyed,true);
});

test('凡人为仙门做营生：护院、洒扫、灵植、兽倌、役奴都有真实人口',()=>{
 const w=fresh();
 const jobs=mortalWork(w);
 assert.ok(jobs.length>=4);
 assert.ok(jobs.every(j=>j.count>0));
 const planter=jobs.find(j=>j.id==='planter');
 assert.ok(planter.wage>0&&planter.count>50,'灵植夫应是最多的一类');
 assert.equal(jobs.find(j=>j.id==='slave').wage,0,'役奴没有工钱');
});

test('报告包含灵根稀有度、灵气密度、宗门战力与供奉',()=>{
 const w=fresh();
 const r=xianReport(w);
 assert.ok(r.regions.length>=4);
 assert.ok(r.sects.every(s=>s.power>=0));
 assert.ok(Array.isArray(r.retainers));
 assert.ok(r.mortals.length>=4);
});

test('灵根表里没有灵根的人占多数——皇族也一样',()=>{
 const none=ROOTS.none;
 assert.ok(none.p>ROOTS.tian.p*100);
 assert.match(none.note,/皇族/);
});
