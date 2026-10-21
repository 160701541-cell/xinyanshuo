import test from 'node:test';
import assert from 'node:assert/strict';
import {createWorld} from '../core.mjs';
import {ensureKarma,resolveKill} from '../karma.mjs';
import {ensureDao,shiftDao,attitudeOf,daoReport,seekAlly,SECTS,NATIONS,tieWith,taoLabel,recordDeed,deedScore,peopleOf,personAttitude,findPerson,attachPeople,peopleAt,helpPerson,bondBetween,homePlaceOf,whereOf} from '../dao.mjs';

const mk=()=>{const w=createWorld('道心测试');ensureKarma(w);ensureDao(w);
 w.player.stats={level:1,realm:'炼气二层'};w.player.silver=1700;return w;};

test('魔修自己未必有业力，但除魔卫道的势力照样视你为敌',()=>{
 const w=mk();shiftDao(w,-70,'以血炼法');
 recordDeed(w,'innocent',4);          // 真做了事，不是只背了账
 const q=attitudeOf(w,'qingyun');
 assert.ok(q.hostile,`青云 ${q.score}`);
 assert.match(q.reason,/除魔卫道|看不上/);
});

test('魔道里有好人：赤炎谷里也坐着行得正的修士，他按你的行径看你',()=>{
 const good=findPerson('good',{stance:'demonic'});
 assert.ok(good, '魔道宗门里应有道行高的弟子');
 assert.ok(good.morality>=40);
 const a=mk();recordDeed(a,'protect',6);recordDeed(a,'evil',3);
 const b=mk();recordDeed(b,'innocent',5);
 assert.ok(personAttitude(a,good).score>personAttitude(b,good).score,'同一个魔修，对善行与滥杀态度不同');
 assert.ok(personAttitude(b,good).score<0);
});

test('正道里有坏人：青云门下的方云，你越狠他越看你顺眼',()=>{
 const bad=findPerson('bad',{stance:'righteous'});
 assert.ok(bad&&bad.morality<=-40,'正道宗门里应有恶徒');
 const dirty=mk();recordDeed(dirty,'innocent',5);ensureKarma(dirty).value=60;
 const clean=mk();recordDeed(clean,'protect',8);
 assert.ok(personAttitude(dirty,bad).score>personAttitude(clean,bad).score);
});

test('门派本身不给你打善恶分：牌子只看名声与交情',()=>{
 const clean=mk();recordDeed(clean,'protect',8);
 const dirty=mk();recordDeed(dirty,'innocent',5);ensureKarma(dirty).value=60;
 // 同样是魔道，差别只来自业力/交情，不来自"你行善加分"
 const g1=attitudeOf(clean,'guixu').score,g2=attitudeOf(dirty,'guixu').score;
 assert.ok(Math.abs(g1-g2)<35,`归墟 ${g1} vs ${g2}，不该按善恶大起大落`);
 assert.equal(attitudeOf(clean,'qingyun').hostile,false);
 assert.ok(attitudeOf(dirty,'qingyun').score<attitudeOf(clean,'qingyun').score);
});

test('一个门派里的人可以差得很远',()=>{
 const ps=peopleOf('xuehe');
 assert.equal(ps.length,8);
 const ms=ps.map(p=>p.morality);
 assert.ok(Math.max(...ms)>0&&Math.min(...ms)<-50,'血河宗里既有狠人也有善人');
 assert.ok(ps.every(p=>p.name&&p.realm&&p.temper&&p.creed));
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

test('人在地图上有落脚点，白天出门夜里回去（确定性，不随刷新变）',()=>{
 const w=mk();const ps=attachPeople(w);
 assert.equal(ps.length,96);
 assert.equal(attachPeople(w).length,96,'重复接入不会翻倍');
 const homes=new Set(ps.map(p=>homePlaceOf(p)));
 assert.ok([...homes].every(h=>['qingyun','lingshan','kezhan','kezhan2','xijie','dongshi','nanmen'].includes(h)),[...homes].join(','));
 const market=peopleAt(w,'dongshi',10);
 assert.ok(market.length>0&&market.length<=24,`东市白天 ${market.length} 人`);
 assert.equal(peopleAt(w,'dongshi',10).length,peopleAt(w,'dongshi',10).length);
 // 同一个人的行踪两次调用一致
 const one=market[0];
 assert.equal(whereOf(one,10),whereOf(one,10));
});

test('帮过他一次，好感实打实地上来，态度跟着变',()=>{
 const w=mk();const p=findPerson('good',{stance:'demonic'});
 const before=personAttitude(w,p).score;
 const r=helpPerson(w,p.id);
 assert.ok(r.ok);
 assert.equal(r.person.bond,12);
 const after=personAttitude(w,r.person);
 assert.ok(after.score>before,`${before} → ${after.score}`);
 assert.match(after.reason,/帮过他/);
});

test('同门未必同心：善人与恶人在一个山门里互相看不顺眼',()=>{
 const good=findPerson('good',{stance:'demonic'});
 const sameSect=peopleOf(good.sectId).filter(p=>p.morality<=-25)[0];
 assert.ok(sameSect,'该门里应有狠角色');
 assert.ok(bondBetween(good,sameSect)<0);
});
