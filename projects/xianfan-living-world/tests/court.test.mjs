import test from 'node:test';
import assert from 'node:assert/strict';
import {createWorld} from '../core.mjs';
import {ensureGeo} from '../overworld.mjs';
import {ensureFin,purseOf} from '../units.mjs';
import {ensureMarket,marketReport} from '../market.mjs';
import {setRank,ensureWar} from '../war.mjs';
import {ensureCourt,parseDecree,issueOrder,tickCourt,talkTo,courtReport} from '../court.mjs';

function fresh(seed='朝堂'){
 const w=createWorld(seed);ensureGeo(w);ensureFin(w);ensureMarket(w);ensureWar(w);ensureCourt(w);return w;
}

test('一句人话能解析成旨意：开仓/征发/加税/闲聊分得开',()=>{
 assert.equal(parseDecree('开仓放粮三千石').intent,'release');
 assert.equal(parseDecree('传旨，征发五万兵马').intent,'levy');
 assert.equal(parseDecree('把盐铁收归官营').intent,'monopoly');
 assert.equal(parseDecree('加征赋税').intent,'taxUp');
 assert.equal(parseDecree('今天天气不错').intent,'talk');
});

test('平民没有资格颁旨，皇帝可以',()=>{
 const w=fresh();
 setRank(w,'平民');
 assert.equal(issueOrder(w,'开仓放粮三千石').ok,false);
 setRank(w,'皇帝');
 const r=issueOrder(w,'开仓放粮三千石');
 assert.equal(r.ok,true);
 assert.ok(r.reply.includes('领旨'));
 assert.ok(r.staff.length>0);
});

test('旨意要有人办、要花时间，办完才生效',()=>{
 const w=fresh();
 setRank(w,'皇帝');
 const g0=w.market.granary;
 const r=issueOrder(w,'开仓放粮三千石');
 assert.ok(w.court.tasks.length===1);
 assert.ok(w.market.granary===g0,'领旨当日还没动仓');
 let guard=0;
 while(w.court.tasks.length&&guard++<6)tickCourt(w);
 assert.ok(w.court.tasks.length===0);
 assert.ok(w.market.granary<g0,'开仓后官仓应减少');
 assert.match(w.history.at(-1).message,/开仓/);
 assert.ok(courtReport(w).staff.some(s=>s.busy==='待命'));
});

test('能力与贪墨决定折扣：同一条旨，不同人办结果不同',()=>{
 const w=fresh();
 setRank(w,'皇帝');
 issueOrder(w,'开仓放粮三千石');
 let guard=0;while(w.court.tasks.length&&guard++<6)tickCourt(w);
 const used=(w.court.log||[]).at(-1)?.text||'';
 assert.match(used,/折扣/);
 const m=/折扣 (\d+)%/.exec(used);
 assert.ok(m&&Number(m[1])>=40&&Number(m[1])<=100);
});

test('手下会说人话，而且答的是真实数字',()=>{
 const w=fresh();
 const a=talkTo(w,'户部主事','现在粮价多少');
 assert.match(a.say,/粮价/);
 assert.ok(a.say.includes(String(w.market.prices.grain)));
 const b=talkTo(w,'户部主事','府库还有多少钱');
 assert.ok(b.say.includes(purseOf(w,'court').toLocaleString()));
 const c=talkTo(w,'按察司佥事','查查有没有贪墨');
 assert.match(c.say,/账|贪|查/);
});

test('征发旨意真的会生成一支军',()=>{
 const w=fresh();
 setRank(w,'皇帝');
 issueOrder(w,'征发五万兵马');
 let guard=0;while(w.court.tasks.length&&guard++<8)tickCourt(w);
 assert.ok((w.war?.armies||[]).length>=1,'应有一支军');
 assert.ok(w.war.armies[0].combat>0);
});

test('办差期间手下忙碌，不可再接新旨（除非有人空闲）',()=>{
 const w=fresh();
 setRank(w,'皇帝');
 issueOrder(w,'开仓放粮三千石');
 const busy=w.court.staff.filter(s=>s.busy).length;
 assert.ok(busy>=1);
 const r=issueOrder(w,'加税');
 assert.equal(r.ok,true,'还有别人可以办');
});
