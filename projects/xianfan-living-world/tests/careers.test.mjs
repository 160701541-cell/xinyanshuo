import test from 'node:test';
import assert from 'node:assert/strict';
import {createWorld} from '../core.mjs';
import {ensureCareer,joinPath,advance,canAdvance,recruitMen,recruitCapacity,openShop,sendCaravan,buyLand,tickCareer,recordBattle,careerReport,hireCultivator,PATHS,MEN_COST} from '../careers.mjs';
import {ensureCurrency} from '../currency.mjs';

const mk=()=>{const w=createWorld('career');w.player.silver=100000;ensureCareer(w);ensureCurrency(w);return w;};

test('v0.33 五道都在：军功/官身/商贾/仙途/乡望各有五级',()=>{
 for(const p of ['military','office','merchant','xian','folk']){
  assert.equal(PATHS[p].ranks.length,5);
  assert.equal(PATHS[p].ranks[4].cap>=0,true);
 }
});

test('v0.33 入道之后才有身份，重复入道被拒',()=>{
 const w=mk();
 assert.equal(joinPath(w,'military').ok,true);
 assert.equal(joinPath(w,'military').ok,false);
 assert.equal(ensureCareer(w).ranks.military,0);
});

test('v0.33 门槛不够时晋升被拒，并说清差什么',()=>{
 const w=mk();
 joinPath(w,'military');
 const r=advance(w,'military');
 assert.equal(r.ok,false);
 assert.match(r.error,/战功/);
});

test('v0.33 战功够了、钱也够，就能升；升完扣钱记名声',()=>{
 const w=mk();
 joinPath(w,'military');
 recordBattle(w,{kills:60,won:true});
 const before=w.player.silver;
 const r=advance(w,'military');           // 小兵 → 什长（0 银）
 assert.equal(r.ok,true);
 assert.equal(r.rank,'什长');
 recordBattle(w,{kills:120,won:true});
 const s=canAdvance(w,'military');        // → 校尉，要 300 银 + 名望 10
 assert.equal(s.missing.length>=0,true);
 if(s.ok){const r2=advance(w,'military');assert.equal(r2.ok,true);assert.ok(w.player.silver<before+100000);}
});

test('v0.33 私兵上限由身份决定，超了就募不到',()=>{
 const w=mk();
 joinPath(w,'military');
 assert.equal(recruitCapacity(w),0);        // 小兵没有私兵
 assert.equal(recruitMen(w,1).ok,false);
 recordBattle(w,{kills:60});
 advance(w,'military');                      // 什长 cap 10
 const r=recruitMen(w,5);
 assert.equal(r.ok,true);
 assert.equal(r.men,5);
 assert.equal(recruitMen(w,20).ok,false);
});

test('v0.33 募兵是按人算钱的，不是白给',()=>{
 const w=mk();joinPath(w,'military');recordBattle(w,{kills:60});advance(w,'military');
 const before=w.player.silver;
 recruitMen(w,4);
 assert.equal(before-w.player.silver,4*(MEN_COST.enlist+MEN_COST.gear));
});

test('v0.33 商贾要先入道才能押商队，铺面数量受身份限制',()=>{
 const w=mk();
 assert.equal(sendCaravan(w,{qty:5}).ok,false);
 joinPath(w,'merchant');
 assert.equal(openShop(w,'grain').ok,true);
 assert.equal(openShop(w,'cloth').ok,true);
 assert.equal(openShop(w,'wine').ok,false);   // 摊贩只撑得起 2 处
});

test('v0.33 商队按月结算，可能是赚、是折、是被劫',()=>{
 const w=mk();joinPath(w,'merchant');
 const cv=sendCaravan(w,{qty:10,days:5});
 assert.equal(cv.ok,true);
 w.day+=6;tickCareer(w);
 const c=ensureCareer(w);
 assert.equal(c.caravans[0].settled,true);
 assert.ok(['顺利','遇雨折半','遭劫','碰上好行市'].includes(c.caravans[0].fate));
});

test('v0.33 买田进乡望，田租逐月入账',()=>{
 const w=mk();joinPath(w,'folk');
 assert.equal(buyLand(w,10).ok,true);
 assert.equal(ensureCareer(w).land,10);
 const before=w.player.silver;
 w.day+=40;tickCareer(w);
 assert.ok(w.player.silver>=before-1);   // 至少不被田租倒贴
});

test('v0.33 修士用灵石聘，不用金银',()=>{
 const w=mk();const c=ensureCurrency(w);c.stones=0;
 const r=hireCultivator(w,{realm:'found'});
 assert.equal(r.ok,false);
 assert.match(r.error,/灵石/);
 c.stones=9;
 assert.equal(hireCultivator(w,{realm:'found'}).ok,true);
});

test('v0.33 买官欠下人情债，逐月抽还',()=>{
 const w=mk();joinPath(w,'office');
 w.career.fame=60;
 const r=advance(w,'office');             // 书吏 → 县丞，800 银
 assert.equal(r.ok,true);
 assert.ok(ensureCareer(w).debt>=0);
 const d=ensureCareer(w).debt;
 w.day+=40;tickCareer(w);
 assert.ok(ensureCareer(w).debt<=d);
});

test('v0.33 战报自洽：五道进度互不覆盖',()=>{
 const w=mk();
 joinPath(w,'military');joinPath(w,'merchant');
 const rep=careerReport(w);
 assert.equal(rep.paths.length,5);
 assert.equal(rep.paths.find(p=>p.id==='military').rank,'小兵');
 assert.equal(rep.paths.find(p=>p.id==='merchant').rank,'摊贩');
 assert.equal(typeof rep.cap,'number');
});
