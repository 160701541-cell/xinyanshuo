// 个体士兵战斗：一群小人在打，不是一串数字在结算。
// - 每人有位置、血量、士气、武器、目标；
// - 武器有攻击距离与节奏：枪长、刀快、弓远、骑快、术有范围；
// - 命中会飞箭、溅血、倒地留尸、扬尘；
// - 伤亡与包围压士气，士气崩了整队溃逃。
export const FRIENDLY_FIRE=0.0005; // 混战中伤到自己人的概率（0.05%）
export const BATTLE_VERSION='battle-0.1.0';

function rng(seed){let a=seed>>>0||1;return()=>{a|=0;a=a+0x6D2B79F5|0;let t=Math.imul(a^a>>>15,1|a);t=t+Math.imul(t^t>>>7,61|t)^t;return((t^t>>>14)>>>0)/4294967296;};}
function hash(s){let h=2166136261;for(let i=0;i<s.length;i++){h^=s.charCodeAt(i);h=Math.imul(h,16777619);}return h>>>0;}

export const WEAPONS={
 spear:{name:'长枪',reach:2.8,dmg:11,rate:1.05,arc:22,style:'thrust'},
 sword:{name:'环首刀',reach:1.7,dmg:13,rate:1.5,arc:46,style:'slash'},
 shield:{name:'刀盾',reach:1.8,dmg:10,rate:1.35,armor:6,arc:40,style:'slash'},
 bow:{name:'猎弓',reach:120,ranged:true,dmg:9,rate:2.6,arc:0,style:'shot'},
 crossbow:{name:'弩',reach:150,ranged:true,dmg:12,rate:3.6,arc:0,style:'shot'},
 lance:{name:'长槊',reach:3.2,dmg:14,rate:1.6,mounted:true,arc:18,style:'thrust'},
 staff:{name:'桃木剑',reach:60,dmg:6,rate:2.0,arc:60,spell:true,radius:24}
};
export const TROOPS={
 // pierce 破甲（无视多少比例护甲）、block 盾挡概率、vsCavalry 对骑加成、steadiness 溃散时的定力
 infantry:{name:'步卒',weapon:'spear',hp:100,armor:2,speed:5.2,color:'#6f7f96',pierce:0.15,block:0,vsCavalry:1.55,steadiness:1.0},
 swordsman:{name:'刀手',weapon:'shield',hp:115,armor:5,speed:5.6,color:'#8a7a62',pierce:0.0,block:0.26,vsCavalry:1.15,steadiness:1.15},
 archer:{name:'弓手',weapon:'bow',hp:70,armor:0,speed:4.4,color:'#77835f',pierce:0.3,block:0,vsCavalry:0.9,steadiness:0.85},
 crossbow:{name:'弩手',weapon:'crossbow',hp:78,armor:1,speed:4.2,color:'#6b7358',pierce:0.45,block:0,vsCavalry:0.95,steadiness:0.9},
 cavalry:{name:'轻骑',weapon:'lance',hp:135,armor:3,speed:13.0,color:'#93705f',pierce:0.2,block:0.1,vsCavalry:0.8,steadiness:1.0,charge:1.5},
 monk:{name:'修士',weapon:'staff',hp:150,armor:2,speed:7.5,color:'#8b95c4',spirit:70,regen:2.4,spellCost:11,radius:16,pierce:0.6,block:0,vsCavalry:1.2,steadiness:1.25}
};
// 境界：人海能磨死炼气，磨不死金丹；突围的概率也跟着境界走
export const BATTLE_REALMS={
 1:{name:'炼气',spirit:50,regen:1.8,dmg:17,spellCost:11,surroundResist:0.0,escape:0.12},
 2:{name:'炼气二层',spirit:70,regen:2.4,dmg:20,spellCost:12,surroundResist:0.15,escape:0.22},
 3:{name:'炼气五层',spirit:95,regen:3.0,dmg:23,spellCost:15,surroundResist:0.32,escape:0.36},
 4:{name:'筑基',spirit:150,regen:4.2,dmg:30,spellCost:20,surroundResist:0.55,escape:0.58},
 5:{name:'金丹',spirit:260,regen:7.0,dmg:42,spellCost:28,surroundResist:0.78,escape:0.82}
};
export const FORMATIONS={
 line:{name:'横阵',colGap:3.0,rowGap:4.2},
 block:{name:'方阵',colGap:4.4,rowGap:4.4},
 wedge:{name:'楔形',colGap:3,rowGap:3,shape:'wedge'}
};

let nextId=1;
function makeSide(def,side,w,h,rand){
 const f=FORMATIONS[def.formation||'block'];
 const soldiers=[];
 let row=0,col=0;const width=Math.min(40,Math.max(8,Math.round(Math.sqrt(def.count||120)*2.4)));
 for(const unit of def.units||[]){
  for(let i=0;i<unit.count;i++){
   const t=TROOPS[unit.troop]||TROOPS.infantry;
   const wp=WEAPONS[t.weapon];
   const wedge=def.formation==='wedge';
   const cols=wedge?4:width;
   if(col>=cols){col=0;row++;}
   const lane=(col-(cols-1)/2)*f.colGap;
   // 阵型以中线对称展开：第 0 排在最后，最后一排顶到前面
   const rows=Math.max(1,Math.ceil((def.count||1)/cols));
   const y0=h*0.5-(rows-1)*f.rowGap*0.5;
   const x=side==='left'?w*0.26+lane: w*0.74-lane;
   const y=y0+row*f.rowGap;
   const realmRank=unit.troop==='monk'?(unit.realm||2):0;
   const rl=realmRank?BATTLE_REALMS[realmRank]:null;
   const leader=false; // 真正的首领身份由指挥链绑定决定，不能整队都是将
   const bagCharges=unit.bag===undefined?(unit.troop==='monk'?Math.max(0,(realmRank||2)-1):0):unit.bag;
   const realmBulk=rl?1+0.32*(realmRank-1):1;
   const maxHp=Math.round(t.hp*(leader?2.2:1)*realmBulk);
   soldiers.push({id:nextId++,side,troop:unit.troop,weapon:t.weapon,rowY:y,
    x,y,hp:maxHp,maxHp,armor:(t.armor||0)+(wp.armor||0),
    morale:100,state:'advance',target:null,cool:rand()*0.5,
    face:side==='left'?0:Math.PI,phase:rand()*6.28,unit:unit.name||t.name,
    realm:realmRank||0,realmName:rl?rl.name:'',spirit:rl?rl.spirit:0,maxSpirit:rl?rl.spirit:0,
    bag:bagCharges,bagStart:bagCharges,leader,isLeader:leader,name:unit.leader||unit.name||''});
   col++;
  }
 }
 return soldiers;
}
function chainOf(def,side){
 // 指挥链：主将 → 副将 → 校尉。全死光就是群龙无首。
 const given=Array.isArray(def.commanders)?def.commanders:[];
 if(!given.length){
  const n=def.leader||null;
  given.push({name:n||(side==='left'?'主将':'主将'),martial:def.martial??58,command:def.command??60});
  if(def.deputies!==0){
   given.push({name:(n?n+'麾下副将':'副将'),martial:(def.martial??58)*0.68,command:(def.command??60)*0.72});
   given.push({name:'随军校尉',martial:(def.martial??58)*0.5,command:(def.command??60)*0.55});
  }
 }
 return given.map((c,i)=>({...c,rank:i,alive:true}));
}
export function createBattle({seed='battle',left={},right={},width=680,height=380}={}){
 const rand=rng(hash(String(seed)));
 nextId=1;
 const b={version:BATTLE_VERSION,seed:String(seed),w:width,h:height,t:0,day:0,
  sides:{left:{...left,formation:left.formation||'block'},right:{...right,formation:right.formation||'block'}},
  soldiers:[],effects:[],arrows:[],corpses:[],done:false,mixed:false,friendly:0,
  stats:{left:{start:0,dead:0,hp:0,morale:100},right:{start:0,dead:0,hp:0,morale:100}}};
 b.soldiers.push(...makeSide(b.sides.left,'left',width,height,rand));
 b.soldiers.push(...makeSide(b.sides.right,'right',width,height,rand));
 b.chain={left:chainOf(b.sides.left,'left'),right:chainOf(b.sides.right,'right')};
 b.command={left:0,right:0};
 // 把指挥链落到具体士兵身上：主将 → 副将 → 校尉，依次挂 isLeader/rankCmd
 for(const side of ['left','right']){
  const chain=b.chain[side];
  const mine=b.soldiers.filter(s=>s.side===side);
  // 将领站在后排：按离敌方阵线的远近排序，越远越可能是指挥
  const rear=mine.slice().sort((a,b)=>side==='left'?b.x-a.x:a.x-b.x);
  const explicit=rear.filter(s=>s.isLeader||s.leader);
  const picks=explicit.slice(0,chain.length);
  const boosted=new Set(picks.map(s=>s.id));
  while(picks.length<chain.length){const c=rear.find(s=>!picks.includes(s));if(!c)break;picks.push(c);}
  chain.forEach((c,i)=>{
   const s=picks[i];if(!s)return;
   s.isLeader=true;s.rankCmd=i;s.name=c.name;
   if(boosted.has(s.id)){s.maxHp=Math.round(s.maxHp*(i===0?2.0:1.35));s.hp=s.maxHp;}
   c.soldier=s.id;
  });
  b.command[side]=0;
 }
 b.stats.left.start=b.soldiers.filter(s=>s.side==='left').length;
 b.stats.right.start=b.soldiers.filter(s=>s.side==='right').length;
 b.rand=rand;
 return b;
}
function dist(a,b){return Math.hypot(a.x-b.x,a.y-b.y);}
function nearestEnemy(b,s){
 // 每条"阵线位置"只找最近的两个敌人，多了排队在外，避免一群人挤成一个点
 let best=null,bd=1e9,second=null,sd=1e9;
 for(const e of b.soldiers){
  if(e.side===s.side||e.state==='dead')continue;
  // 斩首：修士与骑兵更愿意扑对方首领，普通人也会朝旗号冲
  const champ=(e.isLeader||e.leader)?(s.troop==='monk'?46:(s.troop==='cavalry'?22:8)):0;
  const d=dist(s,e)+Math.abs((e.y%40)-(s.y%40))*0.35-champ;
  if(d<bd){second=best;sd=bd;best=e;bd=d;}
  else if(d<sd){second=e;sd=d;}
 }
 if(!best)return null;
 const taken=best.attackers|0;
 // 修士会被围：同一个修士身上能挂 6–11 把刀，普通兵只有 2 个人能并排砍
 const cap=2;
 return {enemy:taken<cap?best:(second||best),d:taken<cap?bd:sd};
}
function addEffect(b,kind,x,y,extra={}){
 const e={id:b.effects.length+1,kind,x,y,t:b.t,ttl:extra.ttl||0.45,...extra};
 b.effects.push(e);
 if(b.effects.length>600)b.effects.splice(0,b.effects.length-600);
 return e;
}
/** 推进 dt 秒。返回本帧产生的事件摘要。 */
/** 人与人之间要挤开：没有这一步，一群人就叠成一个点。 */
function separate(b){
 const cell=4,grid=new Map();
 for(const s of b.soldiers){
  if(s.state==='dead')continue;
  const k=(s.x/cell|0)+','+(s.y/cell|0);
  let a=grid.get(k);if(!a){a=[];grid.set(k,a);}a.push(s);
 }
 const push=3.2;
 for(const s of b.soldiers){
  if(s.state==='dead')continue;
  const cx=s.x/cell|0,cy=s.y/cell|0;
  for(let ix=-1;ix<=1;ix++)for(let iy=-1;iy<=1;iy++){
   const arr=grid.get((cx+ix)+','+(cy+iy));if(!arr)continue;
   for(const o of arr){
    if(o===s)continue;
    const dx=s.x-o.x,dy=s.y-o.y;const d2=dx*dx+dy*dy;
    if(d2>push*push||d2<1e-6)continue;
    const d=Math.sqrt(d2),f=(push-d)/d*0.5;
    s.x+=dx*f;s.y+=dy*f;o.x-=dx*f;o.y-=dy*f;
   }
  }
  s.x=Math.max(6,Math.min(b.w-6,s.x));s.y=Math.max(8,Math.min(b.h-8,s.y));
 }
}
export function stepBattle(b,dt=0.1){
 if(b.done)return {done:true};
 b.t+=dt;
 for(const s of b.soldiers)s.attackers=0;
 // 接战之前是行军队列，撞上以后才散成混战；误伤只在混战里发生
 if(!b.mixed){
  // 只有近身接战才算混战；弓弩在射程内就开火，不算
  const hit=b.soldiers.some(s=>s.state==='fight'&&!((WEAPONS[s.weapon]||{}).ranged||(WEAPONS[s.weapon]||{}).spell));
  if(hit){b.mixed=true;b.mixedAt=b.t;b.friendly=0;}
 }
 const events=[];
 for(const s of b.soldiers){
  if(s.state==='dead')continue;
  const t=TROOPS[s.troop]||TROOPS.infantry;
  const wp=WEAPONS[s.weapon];
  const near=nearestEnemy(b,s);
  if(!near){s.state='hold';continue;}
  const {enemy,d}=near;
  s.target=enemy.id;
  const reach=wp.spell?wp.reach:(wp.ranged?wp.reach:wp.reach*1.6);
  // 被围：身边敌人越多，越难走、越容易被打死
  if(s.troop==='monk'){
   const rl=BATTLE_REALMS[s.realm]||BATTLE_REALMS[1];
   let around=0;
   for(const e of b.soldiers){if(e.side!==s.side&&e.state!=='dead'&&dist(e,s)<16)around++;}
   s.surrounded=around;
   s.spirit=Math.min(s.maxSpirit,(s.spirit||0)+rl.regen*dt*(around>=6?0.45:1));
   // 丹药/符箓：灵力见底就吃一颗（储物袋里的存货）
   if(s.spirit<rl.spellCost&&s.bag>0){s.bag--;s.spirit=Math.min(s.maxSpirit,s.spirit+rl.spirit*0.7);
    addEffect(b,'pill',s.x,s.y-10,{ttl:.6,side:s.side});}
   // 快死了想走：境界越高越走得掉；被围得死就基本走不掉
   if(s.hp<s.maxHp*0.28&&s.state!=='fled'){
    const press=Math.min(1,around/7)*(1-rl.surroundResist);
    const p=rl.escape*(1-press);
    if(b.rand()<p*dt*2.2){s.state='fled';s.hp=0;b.fled=(b.fled||0)+1;
     addEffect(b,'escape',s.x,s.y,{ttl:.7,side:s.side});continue;}
   }
  }
  // 士气崩了就跑
  if(s.morale<18){s.state='rout';
   const dx=(s.x<enemy.x?-1:1)*t.speed*1.6*dt;
   s.x+= dx; s.face=dx>0?0:Math.PI; s.phase+=dt*10;
  }else if(d>reach){
   s.state='advance';
   // 阵列推进：只向"敌阵前沿"走，横向守自己的排位；这样两军是一道线撞一道线，不是所有人扑向一个点
   const dir=s.side==='left'?1:-1;
   const tx=enemy.x-dir*reach*0.85;
   // 行军时严格守排面（只朝正前方走，横排位置不动）；接战后排面散掉，各找各的空隙
   let ty;
   if(b.mixed){
    if(s.jy===undefined)s.jy=(b.rand()-0.5)*6;
    ty=s.rowY!==undefined?s.rowY*0.5+enemy.y*0.5+s.jy:enemy.y+s.jy;
   }else{
    ty=s.rowY!==undefined?s.rowY:enemy.y;
   }
   const vx=tx-s.x, vy=ty-s.y, vd=Math.hypot(vx,vy)||1;
   // 修士被围住就腾挪不开：人海能贴上来，这也是低阶修士会被磨死的原因
   const slow=s.troop==='monk'&&(s.surrounded||0)>=3?0.32:1;
   const k=Math.min(1,t.speed*slow*dt/vd);
   // 队列：横向只做微调，纵向才走得快
   const lax=b.mixed?1:0.25;
   s.x+=vx*k; s.y+=vy*k*lax;
   s.face=dir>0?0:Math.PI; s.phase+=dt*(b.mixed?8:5);
  }else{
   s.state='fight';
   enemy.attackers=(enemy.attackers|0)+1;
   s.face=Math.atan2(enemy.y-s.y,enemy.x-s.x);
   s.cool-=dt;
   if(s.cool<=0){
    s.cool=wp.rate;
    if(wp.ranged){
     const ang=Math.atan2(enemy.y-s.y,enemy.x-s.x);
     b.arrows.push({id:b.arrows.length+1,x:s.x,y:s.y,vx:Math.cos(ang)*160,vy:Math.sin(ang)*160,
      side:s.side,dmg:wp.dmg,t:0,life:1.6});
     addEffect(b,'shoot',s.x,s.y,{angle:ang,ttl:.2});
    }else if(wp.spell&&s.spirit>=(BATTLE_REALMS[s.realm]||BATTLE_REALMS[1]).spellCost){
     const rl=BATTLE_REALMS[s.realm]||BATTLE_REALMS[1];
     s.spirit-=rl.spellCost;
     addEffect(b,'spell',enemy.x,enemy.y,{r:wp.radius*2,ttl:.5});
     for(const e of b.soldiers){
      if(e.state==='dead')continue;
      const ffE=e.side===s.side&&b.mixed&&b.rand()<FRIENDLY_FIRE*0.5;
      if(e.side===s.side&&!ffE)continue;
      if(dist(e,enemy)<=wp.radius)damage(b,e,rl.dmg*(0.6+b.rand()*0.6),s,ffE?'friendly':'spell');
     }
    }else{
     const dry=s.troop==='monk'&&s.spirit<8?0.55:1;   // 灵力见底的修士，剑也软
     const ff=friendlyFire(b,s,reach*1.3);
     const victim=ff||enemy;
     const hit=damage(b,victim,wp.dmg*dry*(0.7+b.rand()*0.7),s,ff?'friendly':'melee');
     addEffect(b,'slash',(s.x+victim.x)/2,(s.y+victim.y)/2,
      {angle:s.face,arc:wp.arc,ttl:.28,side:s.side,weapon:s.weapon});
     if(hit)addEffect(b,'blood',victim.x,victim.y-6,{ttl:.5,side:s.side});
    }
   }
  }
 }
 separate(b);
 // 箭矢
 for(const a of b.arrows){
  a.t+=dt;a.x+=a.vx*dt;a.y+=a.vy*dt;a.vy+=40*dt;
  if(a.t>a.life){a.dead=true;addEffect(b,'arrowland',a.x,a.y,{ttl:1.2});continue;}
  for(const s of b.soldiers){
   if(s.side===a.side||s.state==='dead')continue;
   if(Math.abs(s.x-a.x)<4&&Math.abs(s.y-a.y)<8){
    damage(b,s,a.dmg,{side:a.side},'arrow');
    addEffect(b,'blood',s.x,s.y-4,{ttl:.4,side:a.side});
    a.dead=true;break;
   }
  }
 }
 b.arrows=b.arrows.filter(a=>!a.dead);
 // 士气与结算
 for(const side of ['left','right']){
  const mine=b.soldiers.filter(s=>s.side===side);
  const dead=mine.filter(s=>s.state==='dead').length;
  const alive=mine.length-dead;
  const ratio=mine.length?alive/mine.length:0;
  const st=b.stats[side];
  st.dead=dead;st.alive=alive;st.hp=Math.round(mine.reduce((a,s)=>a+Math.max(0,s.hp),0));
  const fatigue=b.t>50?Math.min(18,(b.t-50)*0.3):0;
  const cmd=commanderOf(b,side);
  // 统御高=军心稳；副将接手时按能力差扣一次；全死光=群龙无首，军心持续漏
  const cmdBonus=cmd?((cmd.command||50)-50)*0.16:0;
  const takeover=(b.takeoverHit&&b.takeoverHit[side])||0;
  const noLeader=st.leaderless?Math.min(46,18+(b.t-(st.noLeaderAt||b.t))*2.2):0;
  let morale=Math.round(Math.max(0,Math.min(100,100-dead*110/Math.max(1,mine.length)-fatigue+cmdBonus-takeover-noLeader)));
  // 对面只剩几个人时，再慌也不会崩：一个修士挡不住一百个人往前推
  const foeFighters=b.soldiers.filter(x=>x.side!==side&&!['dead','surrendered','fled','rout'].includes(x.state)).length;
  if(foeFighters<mine.length*0.12)morale=Math.max(morale,45);
  st.morale=morale;
  for(const s of mine){
   if(s.state==='dead')continue;
   // 个人士气向全队靠拢：溃了就跟着溃，稳住就慢慢收回来
   const gap=morale-s.morale;
   s.morale=Math.round(s.morale+ (Math.abs(gap)<2?gap:Math.sign(gap)*Math.min(Math.abs(gap),8)));
   if(s.morale<18)s.state='rout';
   else if(s.state==='rout'&&s.morale>40)s.state='advance';
   // 群龙无首 + 军心见底：有人丢下兵器投降，有人转身就跑
   // 只有在已经吃了亏、且对面还有人的时候，才会成建制投降；否则再慌也会硬着头皮打
   const lost=st.dead/Math.max(1,mine.length);
   const foes=b.soldiers.filter(x=>x.side!==side&&x.state!=='dead'&&x.state!=='surrendered'&&x.state!=='fled').length;
   // 对面只剩一个人时，没人会向他投降——人多的那边只会继续围殴
   const foeCredible=foes>=Math.max(2,mine.length*0.3);
   if(st.leaderless&&morale<=22&&lost>0.12&&foeCredible&&s.state!=='dead'){
    const steady=(TROOPS[s.troop]||{}).steadiness||1;
    s.state=b.rand()<0.55/steady?'surrendered':'fled';
    s.hp=Math.max(1,s.hp);
   }
  }
 }
 for(const side of ['left','right']){
  const st=b.stats[side];
  st.surrendered=b.soldiers.filter(s=>s.side===side&&s.state==='surrendered').length;
  st.routed=b.soldiers.filter(s=>s.side===side&&(s.state==='rout'||s.state==='fled')).length;
  st.alive=b.soldiers.filter(s=>s.side===side&&s.state!=='dead'&&s.state!=='surrendered'&&s.state!=='fled').length;
 }
 const fighting=side=>b.soldiers.filter(s=>s.side===side&&!['dead','surrendered','fled','rout'].includes(s.state)).length;
 b.stats.left.fighters=fighting('left');b.stats.right.fighters=fighting('right');
 const a=b.stats.left.fighters,c=b.stats.right.fighters;
 // 溃散不等于打赢：对面只剩几个人的时候，人多的那边会继续打，不会因为首领没了就整体跑光
 const leftGone=a===0||(b.stats.left.surrendered+b.stats.left.routed>=b.stats.left.start&&c>=b.stats.left.start*0.15);
 const rightGone=c===0||(b.stats.right.surrendered+b.stats.right.routed>=b.stats.right.start&&a>=b.stats.right.start*0.15);
 if(leftGone||rightGone||(b.stats.left.morale<10&&rightGone)||(b.stats.right.morale<10&&leftGone)){
  b.done=true;b.winner=rightGone?'left':leftGone?'right':(b.stats.left.morale>=b.stats.right.morale?'left':'right');
 }
 events.push({t:Math.round(b.t*10)/10,left:b.stats.left.alive,right:b.stats.right.alive,
  fx:b.effects.length,arrows:b.arrows.length});
 return events[events.length-1];
}
function commanderOf(b,side){
 const chain=b.chain[side];
 const cur=b.command[side]|0;
 return chain[cur]&&chain[cur].alive?chain[cur]:null;
}
function friendlyFire(b,attacker,reach=6){
 // 只有混战才误伤；规模越大越乱（0.05% 上限）
 if(!b.mixed)return null;
 const total=b.soldiers.length;
 const rate=FRIENDLY_FIRE*Math.min(1,total/600);
 if(b.rand()>=rate)return null;
 const allies=b.soldiers.filter(s=>s.side===attacker.side&&s.state!=='dead'&&s.state!=='fled'&&s.state!=='surrendered'&&s.id!==attacker.id&&dist(s,attacker)<=reach);
 if(!allies.length)return null;
 const victim=allies[Math.floor(b.rand()*allies.length)];
 b.friendly=(b.friendly||0)+1;
 addEffect(b,'friendly',victim.x,victim.y,{ttl:.5,side:victim.side});
 return victim;
}
function damage(b,target,amount,attacker,kind){
 if(target.state==='dead')return false;
 if(kind==='melee'||kind==='spell')b.attacks=(b.attacks||0)+1;
 if(kind==='friendly'){b.attacks=(b.attacks||0)+1;}
 const atk=attacker?TROOPS[attacker.troop]||{}:{};
 const def=TROOPS[target.troop]||{};
 const armor=(target.armor||0)*(1-(atk.pierce||0));
 // 境界越高，凡兵的刀越难落到要害上
 const realmGuard=target.realm?1-0.13*(target.realm-1):1;
 // 统御高的将领，同一把刀砍得更准
 const cmd=commanderOf(b,target.side==='left'?'right':'left');
 const cmdBonus=cmd?1+(cmd.martial||50)/500:1;
 // 盾手有概率架住
 if(def.block&&b.rand()<def.block){
  addEffect(b,'block',target.x,target.y,{ttl:.25,side:target.side});
  target.morale=Math.max(0,target.morale-1);
  return true;
 }
 // 克制：长枪拒马、骑兵冲阵、弓弩远程
 let counter=1;
 if(target.troop==='cavalry')counter*=atk.vsCavalry||1;
 if(atk.charge&&target.troop!=='cavalry'&&(attacker.state==='advance'))counter*=atk.charge;
 const dmg=Math.max(1,Math.round((amount*2*cmdBonus*counter-armor*1.6)*Math.max(0.35,realmGuard)));
 target.hp-=dmg;
 const drop=Math.min(6,Math.max(1,Math.round(dmg/12)));
 target.morale=Math.max(0,target.morale-drop*2);
 if(target.hp<=0){
  target.state='dead';target.hp=0;
  if(target.isLeader||target.leader){
   const st=target.side==='left'?b.stats.left:b.stats.right;
   const chain=b.chain[target.side];
   const rank=target.rankCmd|0;
   if(chain[rank])chain[rank].alive=false;
   b.events=b.events||[];
   b.events.push({t:+b.t.toFixed(1),kind:'leaderDown',side:target.side,name:target.name||'主将',rank});
   const next=chain.findIndex(c=>c.alive);
   if(next>=0){
    // 副将接手：能力差多少，军心就掉多少
    const prev=chain[rank],nw=chain[next];
    const gap=Math.max(0,(prev.command||50)-(nw.command||50))*0.5+Math.max(0,(prev.martial||50)-(nw.martial||50))*0.3;
    b.command[target.side]=next;
    b.takeoverHit=b.takeoverHit||{left:0,right:0};
    b.takeoverHit[target.side]=Math.min(30,gap);
    b.events.push({t:+b.t.toFixed(1),kind:'commandChange',side:target.side,from:prev.name,to:nw.name,gap:Math.round(gap)});
   }else{
    st.leaderless=true;st.noLeaderAt=b.t;
    b.events.push({t:+b.t.toFixed(1),kind:'leaderless',side:target.side});
   }
  }
  b.corpses.push({x:target.x,y:target.y,side:target.side,angle:target.face,t:b.t});
  if(b.corpses.length>400)b.corpses.shift();
  addEffect(b,'death',target.x,target.y,{ttl:.6,side:target.side});
 }
 return true;
}
// 剧情/刺杀用：直接点掉某个人（走正常的阵亡流程，会触发换将与群龙无首）
export function slay(b,id,{cause='slay'}={}){
 const s=b.soldiers.find(x=>x.id===id);
 if(!s||s.state==='dead')return false;
 return damage(b,s,99999,null,cause);
}
function commandLine(b,side){
 const chain=b.chain[side]||[];
 const cur=chain[b.command[side]|0];
 return {
  inCharge:cur&&cur.alive?cur.name:null,
  martial:cur&&cur.alive?Math.round(cur.martial||0):0,
  command:cur&&cur.alive?Math.round(cur.command||0):0,
  chain:chain.map(c=>({name:c.name,martial:Math.round(c.martial||0),command:Math.round(c.command||0),alive:c.alive})),
  leaderless:!!b.stats[side].leaderless,
  takeoverHit:Math.round((b.takeoverHit&&b.takeoverHit[side])||0)
 };
}
export function battleReport(b){
 const L=b.stats.left,R=b.stats.right;
 const leaders=b.soldiers.filter(s=>s.isLeader).map(s=>({side:s.side,name:s.name,state:s.state,hp:s.hp,maxHp:s.maxHp,realm:s.realmName}));
 const monks=b.soldiers.filter(s=>s.troop==='monk');
 return {t:Math.round(b.t*10)/10,done:b.done,winner:b.winner||null,
  left:{...L,lossRate:L.start?+(L.dead/L.start*100).toFixed(1):0},
  right:{...R,lossRate:R.start?+(R.dead/R.start*100).toFixed(1):0},
  corpses:b.corpses.length,effects:b.effects.length,fled:b.fled||0,
  mixed:!!b.mixed,mixedAt:b.mixedAt!=null?+b.mixedAt.toFixed(1):null,friendly:b.friendly||0,attacks:b.attacks||0,
  leaders,
  command:{left:commandLine(b,'left'),right:commandLine(b,'right')},
  monks:{total:monks.length,alive:monks.filter(s=>s.state!=='dead'&&s.state!=='fled').length,
   fled:monks.filter(s=>s.state==='fled').length,
   spentBag:monks.reduce((n,s)=>n+((s.bagStart||0)-(s.bag||0)),0)},
  events:b.events||[]};
}
