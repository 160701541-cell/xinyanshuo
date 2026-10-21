import test from 'node:test';
import assert from 'node:assert/strict';
import {createWorld,changeRole} from '../core.mjs';
import {ensureGeo,canFly,flightRuleAt,flightBlockedBetween} from '../overworld.mjs';
import {FACTIONS,factionAtPoint,territoryGrid,territoryBorderSegments,factionById,reputation,adjustReputation,standing,ITEMS,priceOf,buyItem,sellItem,addItem,inventory,bagWeight,contractsFor,acceptContract,completeContract,societyReport,cityAt} from '../society.mjs';
import {lookFor,paletteFor} from '../sprites.mjs';

const make=()=>{const w=createWorld('测试县');ensureGeo(w);w.player.silver=500;w.player.place='dongshi';w.player.mapPos={x:0,y:0};return w;};

test('势力领土是确定性的，且城内有城主势力',()=>{
 const a=territoryGrid(),b=territoryGrid();
 assert.equal(a.cells.length,b.cells.length);
 assert.deepEqual([...a.cells],[...b.cells],'同一份数据必须可复现');
 assert.ok(territoryBorderSegments().length>0,'势力之间必须画得出界线');
 assert.equal(factionAtPoint(0,0),'merchant','东市属商会');
 assert.equal(factionAtPoint(6900,-3500),'folk','松林村属乡野');
 assert.equal(factionAtPoint(11300,-7200),'sect','青云山城属宗门');
 assert.ok(FACTIONS.every(f=>factionById(f.id)));
 assert.equal(cityAt({x:0,y:0}).kind,'mortal');
 assert.equal(cityAt({x:11300,y:-7200}).kind,'cultivation');
});

test('空域规则：世俗城池按实力，修仙城池唯御城军',()=>{
 const w=make();changeRole(w,'修士');
 // 炼气修士在临安县城内禁飞
 let r=flightRuleAt(w,{x:0,y:0});
 assert.equal(r.ok,false);assert.match(r.reason,/筑基/);
 // 城外不限
 assert.equal(flightRuleAt(w,{x:0,y:9000}).ok,true);
 // 修为到筑基，世俗城池放行
 w.player.stats.level=4;assert.equal(flightRuleAt(w,{x:0,y:0}).ok,true);
 // 修仙城池仍然是禁飞区
 w.player.stats.level=6;assert.equal(flightRuleAt(w,{x:11300,y:-7200}).ok,false);
 // 御城军可飞
 w.player.titles=['御城军'];assert.equal(flightRuleAt(w,{x:11300,y:-7200}).ok,true);
 assert.equal(canFly(w).ok,true);
 // 飞越禁飞城池的航线要被拦下
 const cross=flightBlockedBetween(w,{x:11000,y:-7000},{x:12000,y:-8100});
 assert.equal(cross,null,'御城军可飞越自家山城');
 w.player.titles=[];w.player.stats.level=4;
 assert.ok(flightBlockedBetween(w,{x:11000,y:-7000},{x:12000,y:-8100}));
});

test('买卖与负重：市集才能交易，钱不够会拒绝',()=>{
 const w=make();
 const price=priceOf(w,'grain');assert.ok(price>0);
 assert.ok(buyItem(w,'grain',2).ok);
 assert.equal(inventory(w).grain,2);
 assert.ok(bagWeight(w)>0);
 const poor=make();poor.player.silver=1;
 assert.equal(buyItem(poor,'sword',1).ok,false);
 const away=make();away.player.place='songlin';
 assert.match(buyItem(away,'grain',1).error,/市集/);
 assert.ok(sellItem(w,'grain',1).ok);
 assert.equal(inventory(w).grain,1);
});

test('委托：当日确定、接取后到地点才能交差',()=>{
 const w=make();
 const list=contractsFor(w);assert.ok(list.length>=3);
 assert.deepEqual(contractsFor(w).map(c=>c.id),list.map(c=>c.id),'同一天委托列表稳定');
 const c=list[0];
 assert.ok(acceptContract(w,c.id).ok);
 assert.equal(completeContract(w,c.id).ok,false,'不在委托地点不能交差');
 w.player.place=c.target;
 const before=w.player.silver;
 const done=completeContract(w,c.id);
 assert.ok(done.ok);assert.ok(w.player.silver>before);
 assert.equal((w.player.contracts||[]).length,0);
});

test('声望有边界且影响商人报价',()=>{
 const w=make();
 adjustReputation(w,'merchant',30);
 assert.equal(reputation(w,'merchant'),30);
 assert.equal(standing(w,'merchant'),'亲近');
 adjustReputation(w,'merchant',200);
 assert.ok(reputation(w,'merchant')<=100);
 adjustReputation(w,'merchant',-500);
 assert.ok(reputation(w,'merchant')>=-100);
});

test('小人素材按身份选层，且同一个人永远同一套衣服',()=>{
 const w=createWorld('测试县');
 const jobs=['修士','县吏','农人','孩童','商人'];
 for(const job of jobs){const p={id:'N'+job,job,age:30,sex:'男',wealth:20};assert.ok(paletteFor(p));}
 const p=w.people[0];
 assert.deepEqual(lookFor(p),lookFor(p));
 const keys=new Set(w.people.slice(0,200).map(x=>{const l=lookFor(x);return `${l.palette}_${l.hair}_${l.hat}_${l.held}_${l.shape}`;}));
 assert.ok(keys.size>1,'不同身份应产生不同外观');
});
