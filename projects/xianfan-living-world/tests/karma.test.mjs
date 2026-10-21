import test from 'node:test';
import assert from 'node:assert/strict';
import {createWorld} from '../core.mjs';
import {ensureKarma,killPreview,resolveKill,breakthroughChance,attemptBreakthrough,karmaTier,karmaReport,lootFor,ensureKarma as ek} from '../karma.mjs';

const mk=()=>{const w=createWorld('业力测试');ensureKarma(w);w.player.stats=w.player.stats||{level:1,realm:'炼气二层'};return w;};

test('无故杀凡人业力重，杀修士轻：一刀之差至少三倍',()=>{
 const w=mk();
 const mortal=killPreview(w,{target:{id:'m1',name:'村民甲',kind:'mortal'}});
 const cult=killPreview(w,{target:{id:'c1',name:'散修乙',kind:'cultivator',realm:'qi'}});
 assert.ok(mortal.karma>=9,`杀凡人 ${mortal.karma}`);
 assert.ok(cult.karma<=4,`杀修士 ${cult.karma}`);
 assert.ok(mortal.karma>=cult.karma*3);
});

test('有正当理由杀凡人几乎不沾业：为亲眷报仇为 0 或更低',()=>{
 const w=mk();
 const r=killPreview(w,{target:{id:'m2',name:'仇家',kind:'mortal'},reason:'revengeKin'});
 assert.ok(r.karma<=1,`业力 ${r.karma}`);
 assert.equal(r.justified,true);
});

test('杀该杀的凡人是除害，业力反减',()=>{
 const w=mk();
 const r=killPreview(w,{target:{id:'m3',name:'通缉犯',kind:'mortal',evil:true},reason:'bounty'});
 assert.ok(r.karma<0,`业力 ${r.karma}`);
});

test('修士有掉落，凡人只有几串钱',()=>{
 const a=lootFor({id:'c9',kind:'cultivator',realm:'found'},'s1');
 const b=lootFor({id:'m9',kind:'mortal'},'s2');
 assert.ok(a.stones>0&&a.worth>0);
 assert.ok((b.copper||0)>0&&b.stones===undefined);
});

test('业力堆到高段会压低突破成功率，并附带心魔/天劫风险',()=>{
 const w=mk();
 const low=breakthroughChance(w,.6);
 ensureKarma(w).value=140;
 const high=breakthroughChance(w,.6);
 assert.ok(high.chance<low.chance*.6,`${low.chance} → ${high.chance}`);
 assert.equal(high.risk,'天劫');
 assert.equal(karmaTier(140).id,'wrath');
});

test('突破失败会再加业力，形成越怕越难的闭环',()=>{
 const w=mk();
 ensureKarma(w).value=130;
 const before=ensureKarma(w).value;
 let fails=0;
 for(let i=0;i<40;i++){const r=attemptBreakthrough(w,.2);if(!r.ok)fails++;}
 assert.ok(fails>5,'高业力下应当常常失败');
 assert.ok(ensureKarma(w).value>before,'失败要留下业力');
});

test('结算真的记账：掉落进包、官府通缉、宗门记仇',()=>{
 const w=mk();w.sectRelations={qingyun:0};
 const r=resolveKill(w,{target:{id:'c2',name:'青云弟子',kind:'cultivator',realm:'found',sectId:'qingyun'}});
 assert.ok(r.ok);
 assert.ok(w.player.killLoot.stones>0);
 assert.ok(w.sectRelations.qingyun<0);
 const r2=resolveKill(w,{target:{id:'m4',name:'路人',kind:'mortal'},witnesses:3});
 assert.ok(r2.wanted>=1);
 assert.ok(w.player.wanted>=1);
 assert.ok(ensureKarma(w).value>=10);
});

test('报告能直接给界面用：段位、杀人数、突破概率都在',()=>{
 const w=mk();
 resolveKill(w,{target:{id:'m5',name:'甲',kind:'mortal'},reason:'revengeKin'});
 const rep=karmaReport(w);
 assert.ok(rep.tier&&rep.note);
 assert.equal(rep.kills.mortal,1);
 assert.equal(rep.kills.justified,1);
 assert.ok(rep.breakthrough.chance>0);
});
