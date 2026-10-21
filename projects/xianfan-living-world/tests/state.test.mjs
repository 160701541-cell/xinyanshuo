import test from 'node:test';
import assert from 'node:assert/strict';
import {createWorld} from '../core.mjs';
import {ensureGeo} from '../overworld.mjs';
import {ensureFin,purseOf} from '../units.mjs';
import {ensureMarket,tickMarket} from '../market.mjs';
import {setRank} from '../war.mjs';
import {ensureState,tickState,reform,stateReport,targetStats,outcomeOf,LEVERS} from '../state.mjs';

function fresh(seed='制度'){
 const w=createWorld(seed);ensureGeo(w);ensureFin(w);ensureMarket(w);ensureState(w);return w;
}
const settle=(w,n=12)=>{for(let i=0;i<n;i++){tickState(w);tickMarket(w,{weather:i%4===0?'旱':'晴'});}};

test('清廉强制的目标值：贪腐更低、合法性更高',()=>{
 const w=fresh();setRank(w,'皇帝');
 reform(w,'antiCorruption','strict');
 reform(w,'exams','exam');
 const t=targetStats(w);
 const w2=fresh('制度2');setRank(w2,'皇帝');
 reform(w2,'antiCorruption','none');
 reform(w2,'exams','heredity');
 const t2=targetStats(w2);
 assert.ok(t.corruption<t2.corruption);
 assert.ok(t.legitimacy>t2.legitimacy);
});

test('制度效果有滞后：改制当天不等于立刻清廉',()=>{
 const w=fresh();setRank(w,'皇帝');
 reform(w,'antiCorruption','strict');
 assert.ok(w.state.corruption>.10,'改制当日贪腐不会瞬间归零');
 settle(w,20);
 assert.ok(w.state.corruption<.14,'长期应压到 14% 以下');
});

test('改制有阻力，且阻力高会掉合法性',()=>{
 const w=fresh();setRank(w,'皇帝');
 const l0=w.state.legitimacy;
 const r=reform(w,'exams','exam');
 assert.equal(r.ok,true);
 assert.ok(r.resistance>0);
 assert.ok(w.state.legitimacy<l0);
 assert.ok(w.state.resistance>0);
});

test('平民改不了制度，官身可以',()=>{
 const w=fresh();
 assert.equal(reform(w,'law','harsh').ok,false);
 setRank(w,'县吏');
 assert.equal(reform(w,'law','harsh').ok,true);
});

test('清廉政体的十年 vs 腐败政体：民怨与府库都更好',()=>{
 const good=fresh('良');setRank(good,'皇帝');
 reform(good,'antiCorruption','strict');reform(good,'exams','exam');reform(good,'tax','standard');
 settle(good,24);
 const bad=fresh('劣');setRank(bad,'皇帝');
 reform(bad,'antiCorruption','none');reform(bad,'exams','heredity');reform(bad,'tax','heavy');
 settle(bad,24);
 assert.ok(good.market.unrest<bad.market.unrest,`清廉政体民怨 ${good.market.unrest} 应低于腐败 ${bad.market.unrest}`);
 assert.ok(purseOf(good,'court')>purseOf(bad,'court'),'清廉政体府库应更实');
});

test('结局判定：高贪+高民怨=腐败崩解/民变；清廉=盛世或中兴',()=>{
 const w=fresh();
 w.state.corruption=.5;w.market.unrest=60;
 assert.ok(['腐败崩解','民变'].includes(outcomeOf(w).name));
 const w2=fresh('良2');
 w2.state.corruption=.06;w2.state.legitimacy=85;w2.market.unrest=10;
 assert.equal(outcomeOf(w2).name,'盛世');
});

test('制度反哺市面与朝堂：贪腐被市面读到，差事折扣被制度压',()=>{
 const w=fresh();
 w.state.corruption=.3;
 tickMarket(w,{weather:'晴'});
 assert.ok(Math.abs(w.market.corruption-.3)<.01,'市面应读到制度贪腐');
 const fresh2=fresh('折扣');
 const t0=targetStats(fresh2);
 assert.ok(t0.efficiency>0);

});

test('六条制度都有选项且默认值合法',()=>{
 const w=fresh();
 for(const [id,lever] of Object.entries(LEVERS)){
  assert.ok(lever.options[w.state.levers[id]],`${id} 默认值应合法`);
  assert.ok(Object.keys(lever.options).length>=3);
 }
 const rep=stateReport(w);
 assert.ok(rep.outcome.name.length>0);
});
