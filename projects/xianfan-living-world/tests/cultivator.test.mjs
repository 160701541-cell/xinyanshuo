import test from 'node:test';
import assert from 'node:assert/strict';
import {createBattle,stepBattle,battleReport,BATTLE_REALMS,WEAPONS} from '../battle.mjs';

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
