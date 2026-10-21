import test from 'node:test';
import assert from 'node:assert/strict';
import {createWorld} from '../core.mjs';
import {ensureGeo} from '../overworld.mjs';
import {ensureFin,purseOf} from '../units.mjs';
import {ensureMarket,tickMarket,marketReport,releaseGrain,buyToGranary,setTax,setMonopoly,buildPost,GOODS} from '../market.mjs';

function fresh(seed='市面'){
 const w=createWorld(seed);ensureGeo(w);ensureFin(w);ensureMarket(w);return w;
}

test('旱年粮价上行、民怨跟着涨；风调雨顺时回落到基准附近',()=>{
 const w=fresh();
 for(let i=0;i<8;i++)tickMarket(w,{weather:'旱'});
 const dry=w.market.prices.grain;
 const w2=fresh('市面2');
 for(let i=0;i<12;i++)tickMarket(w2,{weather:'晴'});
 assert.ok(dry>w2.market.prices.grain,'旱年粮价应更贵');
 assert.ok(w2.market.prices.grain<GOODS.grain.base*1.5,'常年粮价不应离谱');
});

test('开仓平粜：官仓减、粮价落、民怨降',()=>{
 const w=fresh();
 for(let i=0;i<5;i++)tickMarket(w,{weather:'旱'});
 const before={granary:w.market.granary,price:w.market.prices.grain,unrest:w.market.unrest};
 const r=releaseGrain(w,3000);
 assert.equal(r.ok,true);
 assert.ok(w.market.granary<before.granary);
 assert.ok(w.market.prices.grain<before.price);
 assert.ok(w.market.unrest<before.unrest);
});

test('官府收购：府库出钱、官仓变实、市价上行',()=>{
 const w=fresh();
 for(let i=0;i<4;i++)tickMarket(w,{weather:'晴'});
 const t0=purseOf(w,'court'),p0=w.market.prices.grain,g0=w.market.granary;
 const r=buyToGranary(w,2000);
 assert.equal(r.ok,true);
 assert.ok(purseOf(w,'court')<t0);
 assert.ok(w.market.granary>g0);
 assert.ok(w.market.prices.grain>p0);
});

test('加税立刻进府库，也在攒民怨',()=>{
 const w=fresh();
 const t0=purseOf(w,'court');
 const u0=w.market.unrest;
 setTax(w,.25);
 tickMarket(w,{weather:'晴'});
 tickMarket(w,{weather:'晴'});
 assert.ok(purseOf(w,'court')>t0);
 assert.ok(w.market.unrest>u0);
 assert.equal(setTax(w,.9).ok,false);
});

test('盐铁禁榷：进钱、抬价、抬民怨',()=>{
 const w=fresh();
 tickMarket(w,{weather:'晴'});
 const p0=w.market.prices.salt,u0=w.market.unrest;
 setMonopoly(w,'salt',true);
 assert.ok(w.market.prices.salt>p0);
 const t0=purseOf(w,'court');
 tickMarket(w,{weather:'晴'});
 assert.ok(purseOf(w,'court')>t0,'禁榷应有收益');
 assert.ok(w.market.unrest>u0);
 assert.equal(setMonopoly(w,'grain',true).ok,false);
});

test('修驿传花府库、升供给效率；府库不足时拒绝',()=>{
 const w=fresh();
 const r=buildPost(w);
 assert.equal(r.ok,true);
 assert.ok(w.market.post>1);
 ensureFin(w);w.states.court.treasury=0;
 assert.equal(buildPost(w).ok,false);
});

test('民怨过线会出走流民，并在日志里留下记录',()=>{
 const w=fresh();
 w.market.unrest=95;setTax(w,.3);
 tickMarket(w,{weather:'旱'});
 const m=marketReport(w);
 assert.ok(m.unrest>=70);
 assert.ok((w.market.log||[]).some(e=>e.type==='流民'||e.type==='民变'));
});
