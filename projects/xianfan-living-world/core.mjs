/** 《仙凡共生》独立县城实验 v0.1. 纯规则核心，不依赖页面/AI模型。 */
export const VERSION = 'county-0.5';
export const POP_TARGET = 13680;
export const PLACES = [
  {id:'dongshi', name:'临安县·东市', type:'market',x:48,y:49,zone:'城郭', population:1160, detail:'商贩沿街摆摊，粮行、铁铺和客栈开在一起。',links:['xianya','xijie','minju','lianghang','tiepu','kezhan']},
  {id:'xianya',name:'临安县·县衙',type:'office',x:58,y:33,zone:'城郭',population:350,detail:'堂前铺着青砖，廊下张贴税榜与缉捕公文。',links:['dongshi','xijie','xianya_hou']},
  {id:'xijie',name:'临安县·西街',type:'street',x:31,y:42,zone:'城郭',population:980,detail:'木匠铺与旧宅挨在一起，沿河有渡口。',links:['dongshi','xianya','dukou']},
  {id:'minju',name:'临安县·南坊',type:'homes',x:49,y:68,zone:'城郭',population:1350,detail:'住宅院落、井台和私塾沿巷道排开。',links:['dongshi','nanmen']},
  {id:'lianghang',name:'福源粮行',type:'shop',x:56,y:52,zone:'城郭',population:400,detail:'米袋堆在木台上，门外悬着今日收购牌价。',links:['dongshi','lianghang_cang']},
  {id:'tiepu',name:'陈记铁铺',type:'shop',x:44,y:57,zone:'城郭',population:275,detail:'炉火正旺，伙计们轮班锻打农具。',links:['dongshi','tiepu_houyuan']},
  {id:'kezhan',name:'望江客栈',type:'inn',x:39,y:49,zone:'城郭',population:335,detail:'前堂摆着桌椅，二楼有四间客房。',links:['dongshi','kezhan2']},
  {id:'kezhan2',name:'望江客栈·客房',type:'room',x:40,y:46,zone:'城郭',population:0,detail:'楼道尽头悬着风灯，脚步声从楼下传来。',links:['kezhan','kezhan_chamber']},
  {id:'nanmen',name:'临安县·南门',type:'gate',x:48,y:84,zone:'城郭',population:400,detail:'城门下的差役盘查商队，城外是一条官道。',links:['minju','guanlu']},
  {id:'dukou',name:'西河渡口',type:'port',x:14,y:58,zone:'城郭',population:470,detail:'艄公候在栈桥边，船只运进盐与木材。',links:['xijie','hewan']},
  {id:'guanlu',name:'南郊官道',type:'road',x:49,y:92,zone:'郊外',population:750,detail:'车辙从田埂一直延伸向邻县。',links:['nanmen','shiqiao','songlin','liantang']},
  {id:'shiqiao',name:'石桥村',type:'village',x:65,y:88,zone:'乡村',population:1360,detail:'水车缓缓转动，农田分布在河流两侧。',links:['guanlu','qingxi']},
  {id:'songlin',name:'松林村',type:'village',x:78,y:65,zone:'乡村',population:1110,detail:'林边有炭窑和木棚，村民采集薪柴。',links:['guanlu','qingyun']},
  {id:'liantang',name:'莲塘村',type:'village',x:22,y:91,zone:'乡村',population:1250,detail:'村前有莲塘、菜田和小型稻田。',links:['guanlu','hewan']},
  {id:'hewan',name:'河湾村',type:'village',x:8,y:73,zone:'乡村',population:750,detail:'沿河渔户居住，雨季常有水患。',links:['dukou','liantang']},
  {id:'qingxi',name:'青溪村',type:'village',x:85,y:90,zone:'乡村',population:1200,detail:'这里出产稻米和竹器，通往山路。',links:['shiqiao','qingyun']},
  {id:'qingyun',name:'青云山·山门',type:'sect',x:91,y:20,zone:'山门',population:920,detail:'山道穿过云杉，石壁上刻着入山门规。',links:['songlin','qingxi','lingshan']},
  {id:'lingshan',name:'青云山·外门院',type:'sect',x:95,y:9,zone:'宗门',population:620,detail:'练功坪与药圃毗邻，门中执事正在清点灵草。',links:['qingyun','lingshan_yaopu']},
  {id:'tiepu_houyuan',name:'陈记铁铺·后院',type:'room',x:44,y:58,zone:'城郭',population:0,detail:'炉膛背后堆着木炭，隔门是师徒歇脚的小院。',links:['tiepu']},
  {id:'lianghang_cang',name:'福源粮行·后仓',type:'room',x:56,y:53,zone:'城郭',population:0,detail:'米袋按年份堆放，账册记着进出仓粮。',links:['lianghang']},
  {id:'xianya_hou',name:'临安县衙·内署',type:'room',x:58,y:32,zone:'城郭',population:0,detail:'屏风后是掌印签押处，卷宗整齐叠在桌边。',links:['xianya']},
  {id:'kezhan_chamber',name:'望江客栈·东厢客房',type:'room',x:40,y:47,zone:'城郭',population:0,detail:'一桌一榻，窗纸映出院内的树影。',links:['kezhan2']},
  {id:'lingshan_yaopu',name:'青云山·药圃',type:'room',x:95,y:10,zone:'宗门',population:0,detail:'药圃旁有小渠，外门弟子按时清点灵植。',links:['lingshan']}
];
// 这些场所人口是分布配额而非建筑室内容纳数；总量须严格由代码验证。
export const TOTAL_BY_PLACES = PLACES.reduce((n,p)=>n+p.population,0);
const SURNAMES='沈林陈王李赵张吴周徐唐秦叶谢陆方何苏顾许孙韩邵钱曹马郑杜白柳严蒋钟宁';
const FIRST='清云山河长安明远青宁若秋雨知行时序修文景松竹春雪思言有成平然泽照墨石舟田星澜';
const OCCUPATIONS=['农户','织工','木匠','铁匠','脚夫','商贩','船工','私塾先生','捕快','县吏','郎中','厨娘','矿工','修士','僧道'];
function hashString(s){let h=2166136261>>>0; for(const c of s) {h=Math.imul(h^c.charCodeAt(0),16777619)>>>0;}return h>>>0;}
export function mulberry32(seed){let t=seed>>>0;return ()=>{t=(t+0x6D2B79F5)|0;let n=Math.imul(t^t>>>15,1|t);n^=n+Math.imul(n^n>>>7,61|n);return ((n^n>>>14)>>>0)/4294967296;};}
export function deriveSeed(str){return hashString(String(str||'临安初雪'));}
function choose(r,a){return a[Math.floor(r()*a.length)];}
function personName(r){return choose(r,[...SURNAMES])+choose(r,[...FIRST])+(r()<.45?choose(r,[...FIRST]):'');}
function jobFor(place,r,age){if(age<15)return '孩童';if(age>63&&r()<.65)return '居家养老';if(place.type==='sect')return r()<.64?'修士':'宗门杂役';if(place.type==='office')return r()<.48?'县吏':r()<.75?'捕快':'杂役';if(['village','road'].includes(place.type))return choose(r,['农户','农户','农户','农户','织工','木匠','脚夫','郎中','商贩']);if(place.type==='port')return choose(r,['船工','渔户','脚夫','商贩']);if(place.type==='shop')return choose(r,['商贩','粮行伙计','铁匠','账房']);return choose(r,OCCUPATIONS);}
export function createWorld(seed='临安初雪'){
 const r=mulberry32(deriveSeed(seed));let id=0, hh=0;
 const people=[];const households=[];const placeInfo={};
 for(const p of PLACES){placeInfo[p.id]={name:p.name,population:0,granary:p.type==='village'?Math.floor(p.population*68):Math.floor(p.population*34),merchantGrain:p.id==='lianghang'?18000:p.id==='dongshi'?7000:0};let left=p.population;
   while(left>0){const familySize=Math.min(left,2+Math.floor(r()*5));const familyId='F'+String(++hh).padStart(6,'0');const members=[];
      for(let j=0;j<familySize;j++){const age=j===0?25+Math.floor(r()*49):j===1?18+Math.floor(r()*55):Math.floor(r()*76);
         const job=jobFor(p,r,age); const person={id:'N'+String(++id).padStart(6,'0'),name:personName(r),age,sex:r()<.5?'女':'男',job,home:p.id,location:p.id,household:familyId,wealth:Math.floor(12+r()*220),health:Math.floor(55+r()*46),traits:[choose(r,['谨慎','大胆','温厚','精明','执拗','随和']),choose(r,['重家','好学','求财','守礼','冒险','淡泊'])],root:job==='修士'||r()<.017,status:'alive',memory:[]};
         people.push(person);members.push(person.id);placeInfo[p.id].population++; }
      households.push({id:familyId,home:p.id,members,grain:Math.floor(familySize*(9+r()*16)),silver:Math.floor(r()*90)});left-=familySize;
   }
 }
 const world={schema:2,seed,day:1,hour:8,weather:'晴',price:12,treasury:120000,people,households,places:placeInfo,player:{name:'心魇说',place:'dongshi',role:'平民',silver:170,grain:0,spirit:90,contacts:[]},history:[],metrics:{born:0,died:0,marketTrade:0,totalHarvest:0,taxes:0}};
 note(world,'世界生成','临安县及周边开始独立运行。户籍 '+people.length+' 人，'+households.length+' 户。');return world;
}
export function note(w,type,message,meta={}){const ev={id:'E'+String(w.history.length+1).padStart(7,'0'),day:w.day,type,message,...meta};w.history.push(ev);if(w.history.length>900)w.history=w.history.slice(-900);return ev;}
export function aliveCount(w){return w.people.reduce((n,p)=>n+(p.status==='alive'?1:0),0);}
export function getPlace(id){return PLACES.find(p=>p.id===id);}
export function linked(a,b){return a===b||!!getPlace(a)?.links.includes(b);}
export function distance(a,b){const pa=getPlace(a),pb=getPlace(b);if(!pa||!pb)return Infinity;return Math.max(1,Math.round(Math.hypot(pa.x-pb.x,pa.y-pb.y)*1.7));}
// 不把御剑转换为连续的“房间挪动”，但需经过时间、灵力、地点约束。
export function travel(w,target,mode='foot'){
 const from=getPlace(w.player.place),dest=getPlace(target);if(!dest)return {ok:false,error:'未知地点'};
 if(target===from.id)return {ok:true,description:'你已在这里。'};
 if(mode==='foot'&&!linked(from.id,target))return {ok:false,error:'步行只能前往相邻地点；可在地图上查看连通道路。'};
 if(mode==='sword'&&w.player.role!=='修士')return {ok:false,error:'只有具有御剑能力的修士可进行御剑旅行。'};
 if(mode==='sword'&&(isInterior(from)||isInterior(dest)))return {ok:false,error:'不能在建筑内起飞或降落；请先前往街巷。'};
 const dist=distance(from.id,target);
 const minutes=mode==='sword'?Math.max(12,Math.ceil(dist/4)):(isInterior(from)||isInterior(dest)?3:(from.zone==='城郭'&&dest.zone==='城郭'?8:dist*13));
 const spirit=mode==='sword'?Math.max(4,Math.ceil(dist/7)):0;
 if(spirit>w.player.spirit)return {ok:false,error:'灵力不足，无法御剑抵达。'};
 w.player.spirit-=spirit;advanceClock(w,minutes);w.player.place=target;
 const msg=`你${mode==='sword'?'御剑穿云':'沿路步行'} ${dist} 里，耗时 ${minutes} 分钟，抵达${dest.name}。`;
 note(w,'行旅',msg,{from:from.id,to:target,mode,minutes,spirit});return {ok:true,description:msg,minutes,spirit};
}
export function advanceClock(w,minutes){w.hour+=minutes/60;while(w.hour>=24){w.hour-=24;simulateDay(w,1);}}
export function changeRole(w,role){if(!['平民','县吏','修士'].includes(role))return false;w.player.role=role;note(w,'人物',`演示身份切换：${role}（原型调试入口，正式版必须经过考试/任命/拜师流程）。`);return true;}
export function buyGrain(w,amount=3){if(!Number.isInteger(amount)||amount<=0||amount>99)return {ok:false,error:'无效数量'};
 const store=w.places.lianghang;const price=amount*w.price;
 if(w.player.place!=='lianghang')return {ok:false,error:'请先到东市粮行'};
 if(store.merchantGrain<amount)return {ok:false,error:'粮行缺粮'};
 if(w.player.silver<price)return {ok:false,error:'银钱不足'};
 w.player.silver-=price;w.player.grain+=amount;store.merchantGrain-=amount;w.metrics.marketTrade+=amount;
 note(w,'交易',`你在粮行花 ${price} 文买下 ${amount} 斗粮；粮行实存减少 ${amount} 斗。`);return {ok:true,price};
}
export function relief(w,amount=100){if(w.player.role!=='县吏')return {ok:false,error:'无县衙政务权限'};
 if(w.player.place!=='xianya')return {ok:false,error:'需亲至县衙签发赈济'};
 if(!Number.isInteger(amount)||amount<1||amount>1000)return {ok:false,error:'不合法的赈粮数量'};
 const warehouse=w.places.xianya;const cost=amount*2;
 if(warehouse.granary<amount)return {ok:false,error:'县仓不足，文书不能凭空增加粮食'};
 if(w.treasury<cost)return {ok:false,error:'县库不足'};
 warehouse.granary-=amount;w.places.minju.granary+=amount;w.treasury-=cost;
 note(w,'政务',`县衙调拨 ${amount} 斗粮至南坊赈济仓，县仓 -${amount}，南坊 +${amount}，县库 -${cost} 文。`);return {ok:true};
}
export function greet(w,npcId){const p=w.people.find(n=>n.id===npcId&&n.status==='alive');if(!p)return {ok:false,error:'此人不在世或不存在'};const current=apparentLocation(w,p);
 if(current!==w.player.place)return {ok:false,error:'对方现在不在你所在的场所'};
 const old=w.player.contacts.find(c=>c.id===npcId);if(!old){w.player.contacts.push({id:p.id,firstDay:w.day,firstPlace:w.player.place,lastDay:w.day,meetings:1});note(w,'相识',`你在${getPlace(w.player.place).name}与${p.name}（${p.id}）初次交谈。`);}
 else {old.meetings++;old.lastDay=w.day;note(w,'相识',`你与${p.name}再次打招呼。这只是交往经历，并不自动产生爱情或婚姻。`);}
 return {ok:true};}
// NPC采用职业与居住地点驱动的作息；不假称它们已具备无限自主行动。
export function apparentLocation(w,p){if(p.status!=='alive')return null;
 const hour=w.hour;const hv=deriveSeed(p.id+'-'+Math.floor(w.day/6));
 if(hour<6||hour>=21)return p.home;
 if(['农户','渔户','船工'].includes(p.job))return p.home;
 if(p.job==='商贩'&&hour>=8&&hour<18)return 'dongshi';
 if(['粮行伙计','账房'].includes(p.job)&&hour>=8&&hour<18)return 'lianghang';
 if(p.job==='县吏'&&hour>=7&&hour<18)return 'xianya';
 if(p.job==='捕快'&&(hour>=7&&hour<20||hour<5&&deriveSeed(p.id)%15===0))return 'dongshi';
 if(['修士','宗门杂役'].includes(p.job))return p.home;
 if(['铁匠','木匠'].includes(p.job)&&hour>=8&&hour<18)return 'tiepu';
 if(p.job==='脚夫'&&hour>=6&&hour<20)return 'dongshi';
 if(p.job==='厨娘'&&hour>=9&&hour<19)return 'kezhan';
 if(p.home==='guanlu'&&hour>=8&&hour<=19)return hv%2?'nanmen':'guanlu';
 return p.home;
}
export function visiblePeople(w,limit=9){const seen=[];let start=(w.day*19+Math.floor(w.hour)*11)%w.people.length;
 for(let i=0;i<w.people.length&&seen.length<limit;i++) {const p=w.people[(start+i)%w.people.length];if(apparentLocation(w,p)===w.player.place)seen.push(p);}
 return seen;}
export function simulateDay(w,days=1){if(!Number.isInteger(days)||days<1||days>3600)throw new Error('一次推进天数应为1..3600');
 for(let step=0;step<days;step++){
  w.day++;const r=mulberry32(deriveSeed(w.seed+'#'+w.day));
  w.weather=choose(r,['晴','晴','多云','阴','小雨','晴','小雨','大风']);
  const season=Math.floor((w.day%360)/90);const harvestSeason=season===1||season===2;const rainfall=w.weather==='小雨'?1.1:w.weather==='大风'?.82:1;
  const fields=PLACES.filter(p=>p.type==='village'||p.type==='road');const farmers=w.people.filter(p=>p.status==='alive'&&['农户','渔户'].includes(p.job)).length;
  const seasonalYield=[.3,2.0,9.2,0][season];const yieldGrain=Math.round(farmers*seasonalYield*rainfall);
  const grainProduce=Math.max(0,yieldGrain);w.metrics.totalHarvest+=grainProduce;
  for(const place of fields){const share=grainProduce*(place.population/fields.reduce((n,p)=>n+p.population,0));w.places[place.id].granary+=Math.round(share);}
  const alive=aliveCount(w);const dailyNeed=Math.round(alive*.67);
  const pooled=PLACES.reduce((n,p)=>n+w.places[p.id].granary,0);let remains=Math.min(dailyNeed,pooled);
  // 各仓库按库存比例分摊消费；不可透支，缺粮会提高物价并进入历史。
  if(pooled>0){let consumed=0;const stocks=PLACES.filter(p=>w.places[p.id].granary>0);
   for(let j=0;j<stocks.length;j++){const place=stocks[j];const take=j===stocks.length-1?remains-consumed:Math.min(w.places[place.id].granary,Math.floor(remains*w.places[place.id].granary/pooled));w.places[place.id].granary-=take;consumed+=take;}}
  const shortage=Math.max(0,dailyNeed-remains);
  const tax= Math.round(farmers*(harvestSeason?1.1:.3));w.treasury+=tax;w.metrics.taxes+=tax;
  w.price=Math.max(5,Math.min(80,Math.round(w.price*(shortage>0?1.036:1-(harvestSeason?.0013:.0001))+(r()-.5)*1.3)));
  // 人口采用个体死亡与出生，使用固定seed确保同世界同指令路径可回放。
  const deaths=[];for(const p of w.people){if(p.status!=='alive')continue;
    if(w.day%360===0)p.age++;
    const risk=p.age>75?.00012+(p.age-75)*.000055:p.age<2?.00005:.000009;
    if(r()<risk){p.status='dead';deaths.push(p);w.places[p.home].population--;w.metrics.died++;}}
  for(const p of deaths.slice(0,3))note(w,'生死',`${p.name}（${p.id}）于${getPlace(p.home).name}离世，享年${p.age}岁。`,{npc:p.id});
  // 年内有生育率但不按固定剧情挑选主人公。首次原型只纳入成人家庭新增出生。
  const births=Math.floor(alive*.000055+(r()<.65?1:0));
  for(let j=0;j<births;j++){
    const family=choose(r,w.households);const home=family.home;
    const child={id:'N'+String(w.people.length+1).padStart(6,'0'),name:personName(r),age:0,sex:r()<.5?'女':'男',job:'孩童',home,location:home,household:family.id,wealth:0,health:85,traits:[choose(r,['谨慎','大胆','温厚','精明','执拗','随和'])],root:r()<.017,status:'alive',memory:[]};
    w.people.push(child);family.members.push(child.id);w.places[home].population++;w.metrics.born++;
    if(r()<.12)note(w,'生死',`${getPlace(home).name}一户人家添了新生儿。`,{npc:child.id});
  }
  if(w.day%30===0)note(w,'月报',`县境户籍存活 ${aliveCount(w).toLocaleString('zh-CN')} 人，粮价 ${w.price} 文/斗，县库 ${w.treasury.toLocaleString('zh-CN')} 文。`);
  if(shortage>0&&w.day%5===0)note(w,'民生',`县境今日粮食短缺约 ${shortage} 斗，市价上涨。`);
  if(w.day%90===0)note(w,'节气',`季节更替，${harvestSeason?'田亩进入丰收或盛长阶段。':'农户调整耕作与仓储计划。'}`);
 }
 return {day:w.day,alive:aliveCount(w),price:w.price};
}
export function worldReport(w){return {day:w.day,population:aliveCount(w),households:w.households.length,places:PLACES.length,grain:PLACES.reduce((n,p)=>n+w.places[p.id].granary+w.places[p.id].merchantGrain,0),treasury:w.treasury,price:w.price,contacts:w.player.contacts.length};}
export function validateWorld(w){const errs=[];const ids=new Set();for(const p of w.people){if(ids.has(p.id))errs.push('重复NPC ID '+p.id);ids.add(p.id);if(!getPlace(p.home))errs.push('未知居住地点 '+p.id);if(p.wealth<0)errs.push('负财富 '+p.id);}
 if(Object.values(w.places).some(p=>p.granary<0||p.merchantGrain<0))errs.push('库存负值');
 if(w.player.silver<0||w.player.grain<0||w.treasury<0)errs.push('货币/粮食负值');
 const actual=Object.fromEntries(PLACES.map(p=>[p.id,0]));for(const p of w.people)if(p.status==='alive')actual[p.home]++;
 for(const place of PLACES)if(actual[place.id]!==w.places[place.id].population)errs.push('人口账本不一致：'+place.id);
 return errs;
}
export function saveableWorld(w){return JSON.stringify(w);}
export function restoreWorld(raw){const w=JSON.parse(raw);if(![1,2].includes(w.schema)||!Array.isArray(w.people)||!w.player)throw new Error('不兼容的存档');
 if(w.schema===1){for(const p of PLACES){if(!w.places[p.id])w.places[p.id]={name:p.name,population:0,granary:0,merchantGrain:0};}w.schema=2;} const err=validateWorld(w);if(err.length)throw new Error('存档一致性检查失败: '+err.slice(0,3).join(','));return w;}


/** 地图即场景：街道上的建筑入口、屋内房间与人物共用真实拓扑。 */
export function isInterior(place){return !!place&&['shop','inn','room'].includes(place.type);}
export function shortestRoute(from,to){
 if(!getPlace(from)||!getPlace(to))return null;
 const queue=[[from]],seen=new Set([from]);
 for(let i=0;i<queue.length;i++){
   const path=queue[i],last=path[path.length-1];
   if(last===to)return path;
   for(const next of getPlace(last).links){if(!seen.has(next)){seen.add(next);queue.push([...path,next]);}}
 }
 return null;
}
/** 一次地图点击可自动经过多个连续出口；导航不是读一页点一次。 */
export function navigate(w,to,mode='foot'){
 if(to===w.player.place)return {ok:true,description:'你就在这里。',path:[to]};
 const route=shortestRoute(w.player.place,to);
 if(!route)return {ok:false,error:'目前没有通往该处的道路。'};
 if(mode==='sword'){
   const origin=getPlace(w.player.place),dest=getPlace(to);
   if(isInterior(origin)||isInterior(dest))return {ok:false,error:'御剑只能从室外起飞，并在室外降落。进入建筑请用步行。'};
   const r=travel(w,to,'sword');return {...r,path:[origin.id,to]};
 }
 // 预检全程路径完整后才移动；每一段均通过权威 travel() 时钟和事件系统。
 for(let i=1;i<route.length;i++)if(!linked(route[i-1],route[i]))return {ok:false,error:'道路连接发生变化。'};
 let minutes=0;
 for(const next of route.slice(1)){const result=travel(w,next,'foot');if(!result.ok)return result;minutes+=result.minutes||0;}
 return {ok:true,path:route,minutes,description:`沿途经过 ${Math.max(0,route.length-2)} 处场所，抵达${getPlace(to).name}，用时${minutes}分钟。`};
}
export function npcActivity(w,p){
 const h=w.hour;
 if(h<6||h>=21)return '在家休息';
 if(p.job==='捕快')return h<18?'巡街执勤':'下值归家';
 if(p.job==='县吏')return h<18?'办理公文':'下值归家';
 if(p.job==='铁匠')return h<18?'敲打铁器':'整理工具';
 if(p.job==='粮行伙计')return h<18?'核对粮袋':'收拾铺面';
 if(p.job==='商贩')return h<18?'叫卖货品':'整理货担';
 if(p.job==='农户')return h<18?'料理田地':'歇息';
 if(p.job==='修士')return '修习吐纳';
 if(p.job==='厨娘')return '准备吃食';
 if(p.job==='脚夫')return '搬运货物';
 return h>=18?'准备归家':'忙着自己的事务';
}
export function sceneActors(w,place=w.player.place,limit=11){
 const actors=[];
 // 与 actual apparentLocation 完全一致，不独立生成人物装饰。
 const start=(w.day*19+Math.floor(w.hour)*11)%w.people.length;
 for(let i=0;i<w.people.length&&actors.length<limit;i++){
   const p=w.people[(start+i)%w.people.length];
   if(apparentLocation(w,p)===place)actors.push(p);
 }
 return actors;
}
export function scenery(w,placeId=w.player.place){
 const here=getPlace(placeId);if(!here)return null;
 const exits=here.links.map((id,i)=>{
   const target=getPlace(id);let position;
   if(isInterior(here))position=[[50,6],[87,48],[14,50],[51,87],[31,16],[70,84]][i%6];
   else if(here.id==='dongshi')position=({xianya:[69,11],xijie:[8,46],minju:[45,90],lianghang:[75,50],tiepu:[30,65],kezhan:[21,22]})[id]||[54,12];
   else position=[[50,9],[90,45],[53,88],[9,52],[27,21],[72,73]][i%6];
   return {id, name:target?.name.replace(/^临安县·/,'').replace(/^青云山·/,'').replace(/^望江客栈·/,'')||id,kind:isInterior(target)?'door':'route',x:position[0],y:position[1]};
 });
 const props={
 dongshi:[['青石街道',51,50],['茶棚',18,68],['货摊',65,74],['告示牌',81,22]],
 tiepu:[['火炉',47,38],['铁砧',63,53],['农具架',29,67]],
 tiepu_houyuan:[['炭堆',30,36],['水缸',67,65]],
 lianghang:[['米袋',32,49],['柜台',62,58],['今日粮价',72,25]],
 lianghang_cang:[['堆粮',41,43],['账簿',68,65]],
 kezhan:[['桌案',25,60],['酒柜',66,42]],
 xianya:[['堂案',50,26],['告状鼓',25,69],['文书柜',72,65]],
 xianya_hou:[['公文',50,42],['印匣',71,68]],
 kezhan2:[['走廊',50,51],['灯笼',75,40]],
 kezhan_chamber:[['卧榻',43,56],['书桌',70,45]]
 };
 return {place:here,exits,props:(props[here.id]||[['道路',50,51],['树木',24,32],['行旅',72,70]]).map(([name,x,y])=>({name,x,y}))};
}
