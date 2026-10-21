// 道心与立场：业力只是账，道心才是别人眼里的你。
// - 魔修自己未必觉得有业，但"除魔卫道"的人不这么看；
// - 正道、魔道、中立、两面三刀，四种势力各有各的算法；
// - 误入歧途不是想干什么就干什么：你只能往同类那边靠。
export const DAO_VERSION='dao-0.1.0';

export const STANCES={
 righteous:{label:'正道',color:'#9fb6c8',bias:+1},
 demonic:{label:'魔道',color:'#b48c8c',bias:-1},
 neutral:{label:'中立',color:'#b9b394',bias:0},
 pragmatic:{label:'唯利',color:'#c8b487',bias:0}
};
export const TAGS={
 zealot:'除魔卫道',   // 见魔就砍，不讲价
 mercantile:'唯利是图', // 你有钱有货就跟你做买卖
 duplicitous:'两面三刀', // 当面称兄道弟，背后记你一笔
 hermit:'隐世不出',    // 不结盟也不敌对，除非你踩到门口
 demonic_pact:'魔道同盟',
};
/** 世界观尺度：修仙界横跨数国，不隶属任何一个王朝。 */
export const NATIONS=[
 {id:'daning',name:'大宁',cities:4,spanKm2:1_900_000,tier:'super',note:'超级大国，唯一能压住境内宗门'},
 {id:'xuanjing',name:'玄京',cities:2,spanKm2:820_000,tier:'kingdom'},
 {id:'yuejing',name:'越境',cities:2,spanKm2:640_000,tier:'kingdom'},
 {id:'xirong',name:'西戎',cities:1,spanKm2:1_300_000,tier:'tribe',note:'草原与荒漠，王朝号令不出三城'},
 {id:'yunli',name:'云离',cities:2,spanKm2:700_000,tier:'kingdom'},
 {id:'chixiao',name:'赤霄',cities:1,spanKm2:430_000,tier:'duchy'}
];
/** 门派只有门规与人员构成；道行是每个人自己的事。 */
export const SECTS=[
 {id:'qingyun',name:'青云仙门',stance:'righteous',tags:['zealot'],seat:'qingyun',reach:1,nation:'daning',power:6912,note:'境内第一正道，见魔必讨'},
 {id:'lingshan',name:'灵山药市',stance:'pragmatic',tags:['mercantile'],seat:'lingshan',reach:0,nation:'daning',power:1800,note:'谁的灵石都收'},
 {id:'xuanyin',name:'玄阴教',stance:'demonic',tags:['demonic_pact'],seat:'xuanjing',reach:2,nation:'xuanjing',power:9400,note:'横跨玄京、越境，专收"业力深重"之人'},
 {id:'wanjian',name:'万剑宗',stance:'righteous',tags:['zealot'],seat:'yuejing',reach:2,nation:'yuejing',power:8200,note:'剑修，除魔不问道理'},
 {id:'tianji',name:'天机阁',stance:'neutral',tags:['duplicitous'],seat:'daning',reach:3,nation:'daning',power:5200,note:'卖消息给两边，黑白通吃'},
 {id:'xuehe',name:'血河宗',stance:'demonic',tags:['demonic_pact'],seat:'xirong',reach:2,nation:'xirong',power:7600,note:'以血炼法，凡人视作天灾'},
 {id:'taixu',name:'太虚观',stance:'neutral',tags:['hermit'],seat:'yunli',reach:1,nation:'yunli',power:6100,note:'不涉外事，除非山门被踩'},
 {id:'chiyan',name:'赤炎谷',stance:'demonic',tags:['demonic_pact'],seat:'chixiao',reach:1,nation:'chixiao',power:4300,note:'西域魔道，与血河宗互为表里'},
 {id:'baihua',name:'百花谷',stance:'pragmatic',tags:['mercantile','duplicitous'],seat:'yunli',reach:1,nation:'yunli',power:2900,note:'丹药生意，跟谁都笑'},
 {id:'wudang',name:'武当别院',stance:'righteous',tags:[],seat:'daning',reach:0,nation:'daning',power:3500,note:'正统但不嗜杀，讲证据'},
 {id:'luofu',name:'罗浮剑派',stance:'neutral',tags:['hermit'],seat:'xuanjing',reach:1,nation:'xuanjing',power:4100,note:'只守自己那片山'},
 {id:'guixu',name:'归墟',stance:'demonic',tags:['demonic_pact'],seat:'xirong',reach:3,nation:'xirong',power:12000,note:'传说级，不露面，露面即灭门'}
];
export const sectById=id=>SECTS.find(s=>s.id===id)||null;
/** 势力的道行与立场是两回事：正道里有坏人，魔道里有好人。 */
export function moralityLabel(m){
 if(m>=45)return '端方';
 if(m>=15)return '有底线';
 if(m>-15)return '常人';
 if(m>-45)return '手段狠辣';
 return '恶名昭彰';
}

export function ensureDao(w){
 if(!w.dao)w.dao={bias:0,exposure:0,ties:{},log:[],deeds:{protect:0,evil:0,innocent:0,cultivator:0}};
 if(!w.dao.deeds)w.dao.deeds={protect:0,evil:0,innocent:0,cultivator:0};
 return w.dao;
}
/** 你的行径账：立场可以装，做过的事装不了。 */
export function recordDeed(w,kind,n=1){
 const d=ensureDao(w);
 d.deeds[kind]=(d.deeds[kind]||0)+n;
 return d.deeds;
}
export function deedScore(w){
 const de=ensureDao(w).deeds;
 const raw=(de.protect||0)*6+(de.evil||0)*5-(de.innocent||0)*10-(de.cultivator||0)*1.5;
 return Math.max(-100,Math.min(100,Math.round(raw)));
}
/** 道心偏移：正 +，魔 −。杀凡人、结交魔道往下走；除害、护人往上走。 */
export function shiftDao(w,delta,reason){
 const d=ensureDao(w);
 d.bias=Math.max(-100,Math.min(100,d.bias+delta));
 d.log.push({day:w.day,delta,reason});if(d.log.length>60)d.log.shift();
 return d.bias;
}
export function taoLabel(bias){
 if(bias>=45)return '道心通明';
 if(bias>=15)return '正道中人';
 if(bias>-15)return '亦正亦邪';
 if(bias>-45)return '魔道中人';
 return '魔头';
}
export function tieWith(w,sectId,delta){
 const d=ensureDao(w);
 d.ties[sectId]=Math.max(-100,Math.min(100,(d.ties[sectId]||0)+delta));
 return d.ties[sectId];
}
/** 门派怎么看你：立场、交情、利害。**门派不给你打善恶分**——门里每个人自己会。 */
export function attitudeOf(w,sectOrId){
 const s=typeof sectOrId==='string'?sectById(sectOrId):sectOrId;
 const d=ensureDao(w);
 const k=w.karma?.value||0;
 const deeds=deedScore(w);
 const tie=d.ties[s.id]||0;
 let score=0;const why=[];
 if(s.stance==='demonic'){
  score+=k*0.28+tie*0.4;
  if(d.bias<-25){score+=10;why.push('魔道中人');}
  if(s.tags.includes('demonic_pact')){why.push('魔道同盟');}
  why.push('看交情与规矩，不问善恶');
 }else if(s.stance==='righteous'){
  score+=d.bias*0.5+tie*0.35-k*0.15+deeds*0.12;
  if(s.tags.includes('zealot')&&d.bias<-30){score-=35;why.push('门上写着除魔卫道');}
  why.push('讲名声，不讲你心里怎么想');
 }else if(s.tags.includes('mercantile')||s.stance==='pragmatic'){
  score+=tie*0.6+Math.min(20,(w.player.silver||0)/200);why.push('只看货与钱');
 }else{
  score+=d.bias*0.1+tie*0.5;
  if(s.tags.includes('hermit')){score=Math.min(score,10);why.push('隐世不出');}
 }
 score=Math.round(Math.max(-100,Math.min(100,score)));
 const label=score>=40?'盟友':score>=15?'亲近':score>=-15?'平常':score>=-40?'警惕':'死敌';
 return {id:s.id,name:s.name,stance:STANCES[s.stance].label,score,label,hostile:score<=-40,
  creed:s.creed||'',reason:why.join('、')||'无特别看法'};
}
export function daoReport(w){
 const good=findPerson('good',{stance:'demonic'}),bad=findPerson('bad',{stance:'righteous'});
 const list=SECTS.map(s=>attitudeOf(w,s)).sort((a,b)=>b.score-a.score);
 const d=ensureDao(w);
 return {bias:Math.round(d.bias),label:taoLabel(d.bias),exposure:Math.round(d.exposure),deeds:d.deeds,deedScore:deedScore(w),
  allies:list.filter(x=>x.score>=15),enemies:list.filter(x=>x.hostile),neutral:list.filter(x=>x.score>-15&&x.score<15),
  list,log:d.log.slice(-5).reverse(),
  notable:[good&&personAttitude(w,good),bad&&personAttitude(w,bad)].filter(Boolean)};
}
/** 结盟：只能跟愿意接纳你的势力结；正道见你业力重就拒。 */
export function seekAlly(w,sectId){
 const s=sectById(sectId);if(!s)return {ok:false,error:'无此势力'};
 const a=attitudeOf(w,s);
 if(a.hostile)return {ok:false,error:`${s.name}与你为死敌，不会听你说话`,attitude:a};
 if(a.score<0)return {ok:false,error:`${s.name}对你只有${a.label}，不够结盟`,attitude:a};
 tieWith(w,sectId,10);
 shiftDao(w,s.stance==='demonic'?-6:4,s.stance==='demonic'?`与${s.name}结盟`:`与${s.name}结交`);
 return {ok:true,attitude:attitudeOf(w,s),note:s.stance==='demonic'?'近墨者黑——正道那边已经有人记下你了':'正道记你一功'};
}

// ── 人：道行挂在每个修士身上，不挂在门派牌匾上 ────────────────────────────
/** 门派的牌匾只说明它自称什么；这门里坐着什么人，是另一回事。 */
export const SECT_CREED={
 qingyun:'见魔必讨，护境内凡人',lingshan:'灵石到账，不问来路',xuanyin:'弱肉强食，但护自己人',
 wanjian:'剑出无回，除魔不问道理',tianji:'消息无价，两边都卖',xuehe:'血炼通天，凡人如畜',
 taixu:'不涉外事，守山自足',chiyan:'强者为尊，烧杀由心',baihua:'和气生财，谁的钱都收',
 wudang:'讲证据，不嗜杀',luofu:'只守自己那片山',guixu:'不滥杀、守契、杀该杀之人'};
const SUR='沈林陈王李赵张吴周徐唐秦叶谢陆方何苏顾许孙韩邵钱曹马郑杜白柳严蒋钟宁楚燕';
const GIVEN='玄清虚明尘霜寒松云溪鹤青云岚墨白归远长夜孤鸿临川照影无咎守一知白';
function hashStr(s){let h=2166136261;for(let i=0;i<s.length;i++){h^=s.charCodeAt(i);h=Math.imul(h,16777619)}return h>>>0;}
function rngOf(seed){let a=hashStr(seed)||1;return()=>{a|=0;a=a+0x6D2B79F5|0;let t=Math.imul(a^a>>>15,1|a);t=t+Math.imul(t^t>>>7,61|t)^t;return((t^t>>>14)>>>0)/4294967296;};}
const REALM_LABEL=['炼气三层','炼气七层','筑基初期','筑基后期','金丹初期','金丹后期'];
/** 一个门派常驻的八个人（确定性生成）：名字、境界、道行、脾气。 */
export function peopleOf(sectId){
 const s=sectById(sectId);if(!s)return [];
 const r=rngOf('people:'+sectId);
 const out=[];
 for(let i=0;i<8;i++){
  // 魔道里三成是好人，正道里两成是坏人——牌匾不决定人
  let m;
  if(s.stance==='demonic')m=r()<.30?45+Math.floor(r()*45):-85+Math.floor(r()*65);
  else if(s.stance==='righteous')m=r()<.22?-60+Math.floor(r()*45):10+Math.floor(r()*60);
  else m=-30+Math.floor(r()*70);
  const name=SUR[Math.floor(r()*SUR.length)]+GIVEN[Math.floor(r()*GIVEN.length)]+(r()<.5?GIVEN[Math.floor(r()*GIVEN.length)]:'');
  out.push({id:`${sectId}-p${i}`,name,sect:s.name,sectId:sectId,stance:s.stance,
   realm:REALM_LABEL[Math.floor(r()*REALM_LABEL.length)],morality:m,
   temper:m>=45?'端方':m>=15?'有底线':m>-15?'常人':m>-45?'手段狠辣':'恶名昭彰',
   creed:SECT_CREED[sectId]||''});
 }
 return out;
}
/** 这个人怎么看你：看的是他自己的道行，不是门派的牌子。 */
export function personAttitude(w,person){
 const d=ensureDao(w);const deeds=deedScore(w);const k=w.karma?.value||0;
 const m=person.morality;let score=0;const why=[];
 const live=attachPeople(w).find(x=>x.id===person.id);
 const bond=live?.bond||0;
 if(m>=25){score+=deeds*0.7+d.bias*0.1;if(deeds<-25)why.push('他看不惯你做的事');if(deeds>25)why.push('他敬你为人');}
 else if(m<=-25){score+=-deeds*0.5+k*0.2;if(deeds<-10)why.push('他觉得你够狠');if(deeds>25)why.push('他觉得你假清高');}
 else{score+=d.bias*0.2;why.push('他不太关心你');}
 if(bond){score+=bond*0.6;why.push(bond>0?'记着你帮过他':'记着旧怨');}
 score=Math.round(Math.max(-100,Math.min(100,score)));
 const label=score>=40?'同道':score>=15?'客气':score>=-15?'无感':score>=-40?'不喜':'仇视';
 return {id:person.id,name:person.name,sect:person.sect,realm:person.realm,morality:m,
  temper:person.temper,score,label,reason:why.join('、')||'无感'};
}
/** 找一个"牌匾与人不一样"的修士：align='good' 找恶门里的善人，'bad' 找善门里的恶人。 */
export function findPerson(align,sect=null){
 const o=typeof sect==='string'?{sectId:sect}:(sect||{});
 let ids=o.sectId?[o.sectId]:SECTS.map(s=>s.id);
 if(o.stance)ids=ids.filter(id=>sectById(id).stance===o.stance);
 const pool=ids.flatMap(id=>peopleOf(id));
 if(align==='good')return pool.filter(p=>p.morality>=40).sort((a,b)=>b.morality-a.morality)[0]||null;
 if(align==='bad')return pool.filter(p=>p.morality<=-40).sort((a,b)=>a.morality-b.morality)[0]||null;
 return pool[0]||null;
}

// ── 人在地图上有位置、有作息、也有来往 ──────────────────────────────────
/** 每个修士挂在某个门派的落脚点上；没有山门的就在县城或药市。 */
const LODGINGS=['kezhan','kezhan2','xijie','dongshi','nanmen'];
export function homePlaceOf(person){
 const s=sectById(person.sectId);
 if(!s)return 'dongshi';
 if(s.seat==='qingyun'||s.seat==='lingshan')return s.seat;      // 县境内的山门
 return LODGINGS[hashStr('home:'+person.id)%LODGINGS.length];   // 外来的分散住下
}
/** 作息：白天在落脚点或下山采买，夜里回山门/客房。 */
export function whereOf(person,hour=12){
 const home=homePlaceOf(person);
 if(hour<6||hour>=21)return home;
 // 白天一部分人下山采买，其余留在落脚点；按人定死，不随刷新变
 // 修士不是都下山赶集：采药的进山、巡山的绕峰、游历的下山见世面、坐镇的不出洞府。
 // 各自按 id 定死，刷新与读档都不变，方便玩家记住“谁在哪儿”。
 const role=hashStr('role:'+person.id)%100;
 const style=role<30?'采药':role<55?'巡山':role<85?'游历':'坐镇';
 const spots=style==='采药'?['lingshan','songlin']:style==='巡山'?['qingyun','lingshan']:
             style==='游历'?['dongshi','xijie','nanmen','kezhan']:[home];
 const out=spots[hashStr('biz:'+person.id)%spots.length];
 const goesOut=style!=='坐镇'&&hashStr('out:'+person.id)%100<70;   // 坐镇的不出门，其余七成有行迹
 const business=hour>=8&&hour<17;
 return business&&goesOut?out:home;
}
/** 把门派里的人落到世界里一次，之后他们有自己的行迹与交情。 */
export function attachPeople(w){
 const d=ensureDao(w);
 if(d.people)return d.people;
 d.people=[];
 for(const s of SECTS){
  for(const p of peopleOf(s.id)){
   d.people.push({...p,home:homePlaceOf(p),bond:0,met:0,helped:0});
  }
 }
 return d.people;
}
export function peopleAt(w,placeId,hour=null){
 const h=hour??w.hour;
 return attachPeople(w).filter(p=>whereOf(p,h)===placeId);
}
/** 帮过他一次：好感实打实地上来，之后他替你说话。 */
export function helpPerson(w,personId){
 const p=attachPeople(w).find(x=>x.id===personId);
 if(!p)return {ok:false,error:'没有这个人'};
 p.helped++;p.bond=Math.max(-100,Math.min(100,p.bond+12));
 recordDeed(w,'protect');
 const line=p.morality>=25?`${p.name}记下这份情。`:`${p.name}笑了一下：「有点意思。」`;
 return {ok:true,person:p,line};
}
/** 同门之间的亲疏：同门未必同心，仇怨与交情都是预先长出来的。 */
export function bondBetween(personA,personB){
 if(personA.sectId!==personB.sectId)return 0;
 const h=hashStr('bond:'+[personA.id,personB.id].sort().join('|'));
 const r=(h%200)/100-1;
 if(personA.morality>=25&&personB.morality<=-25)return -0.8;
 if(personA.morality<=-25&&personB.morality>=25)return -0.8;
 return Math.round(r*0.6*100)/100;
}
