import test from 'node:test';
import assert from 'node:assert/strict';
import {createWorld} from '../core.mjs';
import {ensureGeo} from '../overworld.mjs';
import {ensureWar,createArmy,emblemOf,EMBLEMS,rankOf,authorityReport,setRank,takeCommand,joinArmy,issueDecree,surviveRoll,battleDay,personalBattle} from '../war.mjs';

function fresh(seed='旗号'){
 const w=createWorld(seed);ensureGeo(w);ensureWar(w);return w;
}
const rngFrom=(seed)=>{let a=seed>>>0;return()=>{a=(a*1664525+1013904223)>>>0;return a/4294967296;};};

test('每支军有国别旗号与将领，番号不重复',()=>{
 const w=fresh();
 const a=createArmy(w,'court',{combat:20000});
 const b=createArmy(w,'court',{combat:20000});
 assert.ok(a.corps&&b.corps&&a.corps!==b.corps);
 assert.ok(a.commander&&b.commander);
 assert.equal(a.emblem.glyph,EMBLEMS.court.glyph);
 assert.notEqual(emblemOf('folk').color,emblemOf('sect').color);
 assert.notEqual(emblemOf('court').flag,emblemOf('folk').flag);
});

test('皇帝能下圣旨征兵，平民不能',()=>{
 const w=fresh();
 setRank(w,'平民');
 assert.equal(issueDecree(w,'levy',{combat:10000}).ok,false);
 setRank(w,'皇帝');
 const r=issueDecree(w,'levy',{combat:10000,faction:'court'});
 assert.equal(r.ok,true);
 assert.ok(r.army.combat===10000);
});

test('皇帝与将帅能领兵，小兵不能；小兵能上阵，皇帝不能',()=>{
 const w=fresh();
 const a=createArmy(w,'court',{combat:20000});
 setRank(w,'小兵');
 assert.equal(takeCommand(w,a.id).ok,false);
 assert.equal(joinArmy(w,a.id).ok,true);
 setRank(w,'皇帝');
 assert.equal(joinArmy(w,a.id).ok,false);
 assert.equal(takeCommand(w,a.id).ok,true);
 const caps=authorityReport(w);
 assert.equal(caps.find(c=>c.cap==='fight').allowed,false);
});

test('战历决定个人存活率：新兵远高于老兵的阵亡风险',()=>{
 const rate=(v)=>{let dead=0;for(let i=0;i<500;i++){if(!surviveRoll(v,rngFrom(i*7+1)).survives)dead++;}return dead/500;};
 const raw=rate(0),vet=rate(100);
 assert.ok(raw>vet+0.2,`新兵阵亡 ${raw} 应远高于老兵 ${vet}`);
 assert.ok(raw>0.4&&raw<0.65);
 assert.ok(vet<0.3);
});

test('老兵军打新兵军，新兵伤亡明显更大',()=>{
 const w=fresh();
 const vet=createArmy(w,'folk',{combat:100000,veteran:95,seed:5});
 const raw=createArmy(w,'court',{combat:100000,veteran:0,seed:5});
 for(let i=0;i<3;i++)battleDay(vet,raw,rngFrom(i+3));
 assert.ok(raw.losses.combat>vet.losses.combat*2,`新兵战损 ${raw.losses.combat} 应远大于老兵 ${vet.losses.combat}`);
});

test('打完仗活下来的人战历上涨',()=>{
 const w=fresh();
 const a=createArmy(w,'court',{combat:50000,veteran:10,seed:9});
 const b=createArmy(w,'folk',{combat:50000,veteran:10,seed:9});
 battleDay(a,b,rngFrom(4));
 assert.ok(a.veteran>10);
});

test('小兵在阵中可能战死，老兵更难死；阵亡会记入世界',()=>{
 const w=fresh();
 const a=createArmy(w,'court',{combat:50000,veteran:0,seed:2});
 setRank(w,'小兵');joinArmy(w,a.id);
 const r=personalBattle(w,a.id,rngFrom(12345));
 assert.equal(r.ok,true);
 assert.equal(typeof r.survives,'boolean');
 if(r.dead)assert.equal(w.player.dead,true);
});
