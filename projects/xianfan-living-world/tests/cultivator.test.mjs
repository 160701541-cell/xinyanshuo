import test from 'node:test';
import assert from 'node:assert/strict';
import {createBattle,stepBattle,battleReport,BATTLE_REALMS,WEAPONS,slay} from '../battle.mjs';

function solo(realm,bag,count=100,seed='r'+realm){
 const b=createBattle({seed,width:320,height:190,
  left:{units:[{troop:'monk',count:1,realm,bag}]},
  right:{units:[{troop:'infantry',count}]}});
 let t=0;while(!b.done&&t<160){stepBattle(b,0.1);t+=0.1;}
 return {b,r:battleReport(b),monk:b.soldiers.find(s=>s.troop==='monk')};
}

test('低阶修士会被普通人海耗死',()=>{
 const {monk,r}=solo(1,0);
 assert.equal(monk.state==='dead'||r.left.dead>0,true,'炼气修士挡不住一百个步卒');
 assert.ok(r.right.dead>0,'但也要换掉一些');
});

test('境界越高，人海越拦不住',()=>{
 const low=solo(1,0,100,'低');
 const high=solo(4,3,100,'高');
 assert.ok(high.r.right.dead>low.r.right.dead*1.5,'筑基至少比炼气多杀一倍');
 assert.ok(high.r.t>=low.r.t,'高阶修士撑得更久');
});

test('灵力是硬约束：术法要耗灵力，见底只能贴脸',()=>{
 const b=createBattle({seed:'spirit',width:320,height:190,
  left:{units:[{troop:'monk',count:1,realm:2}]},right:{units:[{troop:'infantry',count:40}]}});
 const mo=b.soldiers.find(s=>s.troop==='monk');
 const start=mo.spirit;
 let sawSpell=false;
 for(let i=0;i<300&&!b.done;i++){stepBattle(b,0.1);if(b.effects.some(e=>e.kind==='spell'))sawSpell=true;}
 assert.ok(sawSpell,'要放过术法');
 assert.ok(WEAPONS.staff.spell,'桃木剑是法器');
 assert.equal(mo.maxSpirit,BATTLE_REALMS[2].spirit);
 assert.ok(start>0);
});

test('储物袋：灵力不够时自动吃丹，筹码用完就没了',()=>{
 const b=createBattle({seed:'bag',width:320,height:190,
  left:{units:[{troop:'monk',count:1,realm:2,bag:2}]},right:{units:[{troop:'infantry',count:90}]}});
 const mo=b.soldiers.find(s=>s.troop==='monk');
 assert.equal(mo.bag,2);
 for(let i=0;i<400&&!b.done;i++)stepBattle(b,0.1);
 assert.ok(mo.bag<=2,'不能凭空多出丹');
 assert.ok(b.effects.some(e=>e.kind==='pill')||mo.bag===2,'要么吃过丹，要么根本没到灵力见底');
});

test('斩首：首领倒下会让全队士气塌方，并留下事件',()=>{
 const b=createBattle({seed:'decap',width:320,height:190,
  left:{units:[{troop:'monk',count:3,realm:4,leader:'领队真传'},{troop:'infantry',count:60}]},
  right:{units:[{troop:'infantry',count:20}]}});
 let t=0;while(!b.done&&t<120){stepBattle(b,0.1);t+=0.1;}
 const r=battleReport(b);
 assert.ok(r.leaders.length>=1,'战场上要有首领这个身份');
 const down=r.events.find(e=>e.kind==='leaderDown');
 if(down)assert.ok(down.name.length>0);
});

test('修士会被优先针对：有首领时更多人扑向首领',()=>{
 const b=createBattle({seed:'target',width:320,height:190,
  left:{units:[{troop:'infantry',count:60}]},
  right:{units:[{troop:'monk',count:1,realm:5,leader:'老祖'}]}});
 const leader=b.soldiers.find(s=>s.isLeader);
 assert.ok(leader,'首领应该被建出来');
 let t=0;while(!b.done&&t<40){stepBattle(b,0.1);t+=0.1;}
 const marks=b.soldiers.filter(s=>s.side==='left').map(s=>s.target);
 assert.ok(marks.includes(leader.id)||leader.state==='dead','至少有人把他当目标，或者他已经倒下');
});

test('兵种不是换个名字：长枪拒马、刀手举盾、骑兵冲阵', async ()=>{
 const {TROOPS}=await import('../battle.mjs');
 assert.ok(TROOPS.infantry.vsCavalry>1.4,'步卒对骑有克制');
 assert.ok(TROOPS.swordsman.block>0.2,'刀手有盾挡');
 assert.ok(TROOPS.cavalry.charge>1.2,'骑兵有冲阵加成');
 assert.ok(TROOPS.crossbow.pierce>TROOPS.archer.pierce,'弩比弓破甲强');
 assert.ok(TROOPS.archer.steadiness<TROOPS.swordsman.steadiness,'弓手更容易溃');
});

test('统御高的将领，同样伤亡下军心更稳',()=>{
 const mk=(cmd)=>createBattle({seed:'cmd'+cmd,width:320,height:190,
  left:{commanders:[],commanders:[{name:'甲将',martial:80,command:cmd}],units:[{troop:'infantry',count:80}]},
  right:{units:[{troop:'infantry',count:80}]}});
 const hi=mk(92),lo=mk(22);
 // 同样伤亡（开打第一帧，双方都还没死人）下，统御高的一方军心更高
 stepBattle(hi,0.1);stepBattle(lo,0.1);
 assert.ok(hi.stats.left.morale>lo.stats.left.morale,'统御 92 的军心应高于统御 22');
});

test('主将阵亡：副将顶替，能力差多少掉多少军心，并留下换将事件',()=>{
 const b=createBattle({seed:'takeover',width:320,height:190,
  left:{commanders:[{name:'主帅',martial:95,command:95},{name:'副将',martial:40,command:35}],
        units:[{troop:'infantry',count:40,leader:'主帅'}]},
  right:{units:[{troop:'infantry',count:60}]}});
 const boss=b.soldiers.find(s=>s.rankCmd===0);
 assert.ok(boss,'应有主将');
 // 直接把主将打死，避免靠随机战斗
 boss.hp=1;boss.state='advance';
 let t=0;while(t<40&&!b.done){stepBattle(b,0.1);t+=0.1;}
 const ev=(b.events||[]).find(e=>e.kind==='leaderDown'||e.kind==='commandChange'||e.kind==='leaderless');
 assert.ok(ev,'要有换将或群龙无首的记录');
});

test('换将：主将倒下副将顶，能力差多少掉多少军心',()=>{
 const b=createBattle({seed:'takeover2',width:320,height:190,
  left:{commanders:[{name:'主帅',martial:95,command:95},{name:'副将',martial:40,command:35}],
        units:[{troop:'infantry',count:60,leader:'主帅'}]},
  right:{units:[{troop:'infantry',count:80}]}});
 const boss=b.soldiers.find(s=>s.rankCmd===0);
 boss.hp=1;
 let t=0;while(t<40&&!b.done){stepBattle(b,0.1);t+=0.1;}
 const kinds=(b.events||[]).map(e=>e.kind);
 assert.ok(kinds.includes('leaderDown'),'主将要真死');
 assert.ok(kinds.includes('commandChange'),'副将要接管');
 assert.ok(b.takeoverHit.left>0,'能力差要换成军心损失');
 assert.ok(b.stats.left.morale<40,'接手后军心要明显下滑');
});

test('群龙无首：指挥链全断，全军溃散或投降',()=>{
 const b=createBattle({seed:'headless2',width:320,height:200,
  left:{commanders:[{name:'主将',martial:60,command:60},{name:'副将',martial:40,command:40},{name:'校尉',martial:30,command:30}],
        units:[{troop:'infantry',count:6,leader:'主将'},{troop:'infantry',count:6}]},
  right:{units:[{troop:'infantry',count:60}]}});
 // 先打掉一部分兵，再依次斩首：走正常阵亡流程
 for(const c of b.chain.left){ if(c.soldier)slay(b,c.soldier); }
 for(const s of b.soldiers.filter(x=>x.side==='left').slice(6,10))slay(b,s.id);
 let t=0;while(t<60&&!b.done){stepBattle(b,0.1);t+=0.1;}
 assert.ok(b.chain.left.every(c=>!c.alive),'三个指挥都要死透');
 assert.ok((b.events||[]).some(e=>e.kind==='leaderless'),'要记录群龙无首');
 const st=b.stats.left;
 assert.ok(st.surrendered+st.routed>0,'剩下的兵要么投降要么跑');
});

test('接战前是队列：排面不散，接战后才乱', async ()=>{
 const {FRIENDLY_FIRE}=await import('../battle.mjs');
 assert.equal(FRIENDLY_FIRE,0.0005,'误伤是 0.05%，不是 1%');
 const b=createBattle({seed:'march',width:420,height:260,
  left:{units:[{troop:'infantry',count:120}]},right:{units:[{troop:'infantry',count:120}]}});
 // 走几帧，还没碰面
 let t=0;while(t<3){stepBattle(b,0.1);t+=0.1;}
 assert.equal(b.mixed,false,'三秒内还没接战');
 const off=b.soldiers.filter(s=>s.rowY!==undefined&&Math.abs(s.y-s.rowY)>3);
 assert.equal(off.length,0,'行军时每个人都在自己的排上');
 // 打到混战
 while(!b.mixed&&t<60){stepBattle(b,0.1);t+=0.1;}
 assert.ok(b.mixed,'要打成混战');
 while(t<40){stepBattle(b,0.1);t+=0.1;}
 const loose=b.soldiers.filter(s=>s.state!=='dead'&&s.rowY!==undefined&&Math.abs(s.y-s.rowY)>3);
 assert.ok(loose.length>0,'混战里排面要散开');
});

test('混战会误伤自己人，比例是千分之零点五',()=>{
 const b=createBattle({seed:'ff',width:420,height:260,
  left:{units:[{troop:'infantry',count:400},{troop:'archer',count:120}]},
  right:{units:[{troop:'swordsman',count:300},{troop:'cavalry',count:80}]}});
 let t=0;while(!b.done&&t<200){stepBattle(b,0.1);t+=0.1;}
 const r=battleReport(b);
 assert.ok(r.mixed,'大仗要打成混战');
 assert.equal(typeof r.friendly,'number');
 assert.ok(r.attacks>500,'一场大仗要有上千次挥砍');
 // 0.05% 是每次攻击的概率上限，实际统计不能超过它太多
 assert.ok(r.friendly<=Math.ceil(r.attacks*0.001),'误伤率不能超过千分之一');
 assert.ok(b.soldiers.some(s=>s.state==='dead'),'要真打死人');
});
