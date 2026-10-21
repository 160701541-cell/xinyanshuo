import test from 'node:test';
import assert from 'node:assert/strict';
import {createWorld} from '../core.mjs';
import {ensureGeo} from '../overworld.mjs';
import {WAR_VERSION,KG_PER_DAN,ensureWar,levyCapacity,createArmy,armyNeeds,supplyDays,deliveredCostKg,consumeDay,battleDay,tickWarDay,warReport} from '../war.mjs';

const make=()=>{const w=createWorld('战事测试');ensureGeo(w);ensureWar(w);return w;};

test('百万大军的后勤账本对得上：日耗、携行、石数',()=>{
 const w=make();
 const a=createArmy(w,'court',{combat:180000});
 const need=armyNeeds(a);
 assert.ok(need.totalKg>900000,'72 万人一日口粮应接近千吨');
 assert.ok(Math.abs(need.dan*KG_PER_DAN-need.totalKg)<1e-6,'石与公斤必须能互相换算');
 assert.equal(Math.round(supplyDays(a)),5,'自带口粮上限 5 日，超过就得靠粮道');
 assert.equal(a.support,540000,'辅兵按 1:3 征发');
});

test('可动员上限来自人口，不是随便填；单靠大宁凑不齐百万战兵',()=>{
 const w=make();
 const cap=levyCapacity(w,'court');
 assert.equal(cap.combatMax,180000,'大宁 1200 万口 × 1.5%');
 assert.throws(()=>createArmy(w,'court',{combat:250000}),/兵力不足/);
 createArmy(w,'court',{combat:180000});
 assert.equal(levyCapacity(w,'court').combat,0,'已征满后不能再征');
});

test('粮道越远，运到前线要征的粮越多',()=>{
 const w=make();
 const a=createArmy(w,'folk',{combat:100000});
 const near=deliveredCostKg(a,0),far=deliveredCostKg(a,600000);
 assert.ok(Math.abs(near.delivered-near.rationale)<1e-6,'零距离只运口粮本身');
 assert.ok(far.delivered>near.delivered*3,'600 公里外要运三倍以上');
});

test('断粮会掉士气、跑人、战力折损，不是只弹一行字',()=>{
 const w=make();
 const a=createArmy(w,'court',{combat:100000});
 a.supplyKg=0;
 for(let i=0;i<7;i++)tickWarDay(w,{supplyLine:false});
 assert.equal(a.state,'断粮');
 assert.ok(a.morale<50,'断粮七日士气应明显下跌');
 assert.ok(a.losses.support>0,'民夫会先逃');
 assert.ok(a.combat<100000,'战兵也会散');
});

test('同等兵力的两支军对撞，双方伤亡接近（兰开斯特对称性）',()=>{
 const w=make();
 // 兵种不同就是对位不同：“同等兵力”要先同等编制，才谈得上对称
 const same={units:{inf:.6,arc:.2,cav:.15,heavy:.05}};
 const a=createArmy(w,'court',{combat:100000,x:0,y:0,...same});
 const b=createArmy(w,'folk',{combat:100000,x:100000,y:0,...same});
 for(let d=0;d<3;d++)battleDay(a,b,()=>.5);
 assert.ok(Math.abs(a.losses.combat-b.losses.combat)<a.losses.combat*.08,'对称推演不应差出一成');
 assert.ok(a.support<b.support+1,'辅兵也会随主力伤亡');
});

test('士气崩了就是溃散，之后不再计入可战之兵',()=>{
 const w=make();
 const a=createArmy(w,'court',{combat:100000,x:0,y:0});
 const b=createArmy(w,'folk',{combat:100000,x:0,y:0});
 a.morale=19;b.morale=90;
 tickWarDay(w,{supplyLine:true});
 assert.ok(a.routed,'士气低于 18 应判溃散');
 assert.equal(warReport(w).field.filter(x=>x.id===a.id).length,0,'溃散军不再出现在战报序列');
 assert.equal(warReport(w).armies,2,'但账本里仍留档，不抹掉历史');
});

test('战报里没有假数字：战兵+辅兵 = 账本总数',()=>{
 const w=make();
 createArmy(w,'court',{combat:50000,x:0,y:0});
 const r=warReport(w);
 const sum=r.field.reduce((n,x)=>n+x.combat+x.support,0);
 assert.equal(r.total,50000+150000);
 assert.equal(sum,r.total);
});
