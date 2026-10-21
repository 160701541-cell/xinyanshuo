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

export function ensureDao(w){
 if(!w.dao)w.dao={bias:0,exposure:0,ties:{},log:[]};
 return w.dao;
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
/** 你在某个势力眼里是什么人：这一条就是"近朱者赤，近墨者黑"。 */
export function attitudeOf(w,sectOrId){
 const s=typeof sectOrId==='string'?sectById(sectOrId):sectOrId;
 const d=ensureDao(w);
 const k=w.karma?.value||0;
 const tie=d.ties[s.id]||0;
 let score=0,why=[];
 if(s.stance==='righteous'){
  score+=d.bias*0.8;
  score-=k*0.35;                                  // 业力重，正道看你就是魔
  if(k>=30){score-=15;why.push('业力缠身');}
  if(s.tags.includes('zealot')&&d.bias<-25){score-=25;why.push('除魔卫道，见你即斩');}
  if(tie>0){score+=tie*.3;why.push('有旧交');}
 }else if(s.stance==='demonic'){
  score-=d.bias*0.6;
  score+=k*0.25;                                  // 魔道反而喜欢手上脏的
  if(d.bias<-25){score+=20;why.push('同道中人');}
  if(s.tags.includes('demonic_pact')){score+=15;why.push('魔道同盟');}
  if(tie>0){score+=tie*.4;why.push('有过往');}
 }else if(s.tags.includes('mercantile')||s.stance==='pragmatic'){
  score+=tie*.6;
  score+=Math.min(20,(w.player.silver||0)/200);   // 唯利：你有钱就好说话
  why.push('只看货与钱');
 }else{
  score+=d.bias*0.1+ (tie*.5);
  if(s.tags.includes('hermit')){score=Math.min(score,10);why.push('隐世不出');}
 }
 if(s.tags.includes('duplicitous')){
  // 两面三刀：明面客气，暗地看你有没有利用价值与把柄
  d.exposure=Math.max(0,Math.min(100,d.exposure+(k>40?2:0)));
  if(d.exposure>60){score-=25;why.push('你的底细已被捏住');}
  else why.push('当面称兄道弟');
 }
 score=Math.round(Math.max(-100,Math.min(100,score)));
 const label=score>=40?'盟友':score>=15?'亲近':score>=-15?'平常':score>=-40?'警惕':'死敌';
 return {id:s.id,name:s.name,stance:STANCES[s.stance].label,score,label,
  hostile:score<=-40,reason:why.join('、')||'无特别看法'};
}
export function daoReport(w){
 const list=SECTS.map(s=>attitudeOf(w,s)).sort((a,b)=>b.score-a.score);
 const d=ensureDao(w);
 return {bias:Math.round(d.bias),label:taoLabel(d.bias),exposure:Math.round(d.exposure),
  allies:list.filter(x=>x.score>=15),enemies:list.filter(x=>x.hostile),neutral:list.filter(x=>x.score>-15&&x.score<15),
  list,log:d.log.slice(-5).reverse()};
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
