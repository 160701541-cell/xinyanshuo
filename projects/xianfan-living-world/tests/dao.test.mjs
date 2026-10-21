import test from 'node:test';
import assert from 'node:assert/strict';
import {createWorld} from '../core.mjs';
import {ensureKarma,resolveKill} from '../karma.mjs';
import {ensureDao,shiftDao,attitudeOf,daoReport,seekAlly,SECTS,NATIONS,tieWith,taoLabel,recordDeed,deedScore,moralityLabel} from '../dao.mjs';

const mk=()=>{const w=createWorld('道心测试');ensureKarma(w);ensureDao(w);
 w.player.stats={level:1,realm:'炼气二层'};w.player.silver=1700;return w;};

test('魔修自己未必有业力，但除魔卫道的势力照样视你为敌',()=>{
 const w=mk();shiftDao(w,-70,'以血炼法');
 recordDeed(w,'innocent',4);          // 真做了事，不是只背了账
 const q=attitudeOf(w,'qingyun');
 assert.ok(q.hostile,`青云 ${q.score}`);
 assert.match(q.reason,/除魔卫道|看不上/);
});

test('魔道里有好人：归墟守着底线，你行得正它也认',()=>{
 const w=mk();recordDeed(w,'protect',8);recordDeed(w,'evil',4);   // 护人、除害
 const g=attitudeOf(w,'guixu');
 assert.ok(g.hostile===false,`归墟 ${g.score}`);
 assert.ok(g.score>-20,`归墟 ${g.score}`);
 assert.match(g.reason,/底线|汉子/);
});

test('正道里有坏人：万剑宗嘴上除魔，实际看你有没有钱和把柄',()=>{
 const w=mk();recordDeed(w,'innocent',3);w.player.silver=8000;   // 手上脏，但有钱
 const v=attitudeOf(w,'wanjian');
 assert.ok(v.masked,'万剑宗应被标为伪善');
 assert.ok(v.score>attitudeOf(w,'qingyun').score,'伪善势力反而比真正道更容易接纳你');
});

test('行径高于标签：同样业力，做过事与没做过事待遇不同',()=>{
 const clean=mk();const dirty=mk();
 shiftDao(clean,-50,'名声不好');shiftDao(dirty,-50,'名声不好');
 recordDeed(dirty,'innocent',5);
 assert.ok(deedScore(dirty)<deedScore(clean));
 assert.ok(attitudeOf(dirty,'wudang').score<attitudeOf(clean,'wudang').score);
});

test('业力只是账，道心才招人恨：业力低的魔道中人也被正道拒',()=>{
 const w=mk();shiftDao(w,-50,'结交魔道');
 const q=attitudeOf(w,'wanjian');
 assert.ok(q.score<0);
 assert.notEqual(q.label,'盟友');
});

test('杀魔道反而让正道亲近，杀无辜凡人让正道疏远',()=>{
 const a=mk();const b=mk();
 resolveKill(a,{target:{id:'m1',name:'恶霸',kind:'mortal',evil:true},reason:'bounty'});
 resolveKill(b,{target:{id:'m2',name:'村民',kind:'mortal'}});
 assert.ok(ensureDao(a).bias>ensureDao(b).bias,`${ensureDao(a).bias} vs ${ensureDao(b).bias}`);
 assert.ok(attitudeOf(a,'qingyun').score>attitudeOf(b,'qingyun').score);
});

test('近朱者赤：跟魔道结盟只能往魔道那边靠',()=>{
 const w=mk();shiftDao(w,20,'行侠');
 const before=ensureKarma(w).value;
 const r=seekAlly(w,'guixu');           // 守底线的魔道，不滥杀也不排外
 assert.ok(r.ok,r.error);
 assert.ok(ensureDao(w).bias<20,'结盟魔道要掉道心');
 assert.ok(r.note.includes('近墨者黑'));
});

test('正道死敌不能结盟（除魔卫道的不讲价）',()=>{
 const w=mk();shiftDao(w,-60,'乱杀修士');recordDeed(w,'innocent',6);
 const q=attitudeOf(w,'qingyun');
 assert.ok(q.hostile,`青云 ${q.score}`);
 const r=seekAlly(w,'qingyun');
 assert.equal(r.ok,false);
 assert.match(r.error,/死敌/);
});

test('两面派：明面称兄道弟，底细被捏住后翻脸',()=>{
 const w=mk();
 recordDeed(w,'innocent',6);
 const before=attitudeOf(w,'tianji');
 assert.match(before.reason,/当面|底细|嘴上/);
 ensureKarma(w).value=80;
 for(let i=0;i<40;i++)attitudeOf(w,'tianji');   // 业力重，把柄越积越多
 const after=attitudeOf(w,'tianji');
 assert.ok(ensureDao(w).exposure>60);
 assert.ok(after.score<before.score,`${before.score} → ${after.score}`);
});

test('唯利势力看钱不看道心',()=>{
 const poor=mk(),rich=mk();poor.player.silver=0;rich.player.silver=6000;
 assert.ok(attitudeOf(rich,'lingshan').score>attitudeOf(poor,'lingshan').score);
});

test('世界够大：修仙界横跨六国，十二个势力各有立场与标签，报告可直接给界面',()=>{
 assert.equal(NATIONS.length,6);
 assert.equal(SECTS.length,12);
 assert.ok(SECTS.some(s=>s.reach>=3),'要有横跨数国的势力');
 assert.ok(SECTS.every(s=>s.stance&&s.note));
 const rep=daoReport(mk());
 assert.ok(rep.label&&Array.isArray(rep.list)&&rep.list.length===12);
 assert.ok(rep.list.every(x=>typeof x.score==='number'));
 assert.equal(taoLabel(90),'道心通明');assert.equal(taoLabel(-90),'魔头');
});
