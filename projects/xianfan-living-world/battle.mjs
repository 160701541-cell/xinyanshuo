// 个体士兵战斗：一群小人在打，不是一串数字在结算。
// - 每人有位置、血量、士气、武器、目标；
// - 武器有攻击距离与节奏：枪长、刀快、弓远、骑快、术有范围；
// - 命中会飞箭、溅血、倒地留尸、扬尘；
// - 伤亡与包围压士气，士气崩了整队溃逃。
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
 infantry:{name:'步卒',weapon:'spear',hp:100,armor:2,speed:5.2,color:'#6f7f96'},
 swordsman:{name:'刀手',weapon:'shield',hp:110,armor:4,speed:5.6,color:'#8a7a62'},
 archer:{name:'弓手',weapon:'bow',hp:70,armor:0,speed:4.4,color:'#77835f'},
 crossbow:{name:'弩手',weapon:'crossbow',hp:75,armor:1,speed:4.2,color:'#6b7358'},
 cavalry:{name:'轻骑',weapon:'lance',hp:130,armor:3,speed:13.0,color:'#93705f'},
 monk:{name:'修士',weapon:'staff',hp:150,armor:2,speed:7.5,color:'#8b95c4',spirit:70,regen:2.4,spellCost:11,radius:16}
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
   const leader=!!unit.leader;
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
export function createBattle({seed='battle',left={},right={},width=680,height=380}={}){
 const rand=rng(hash(String(seed)));
 nextId=1;
 const b={version:BATTLE_VERSION,seed:String(seed),w:width,h:height,t:0,day:0,
  sides:{left:{...left,formation:left.formation||'block'},right:{...right,formation:right.formation||'block'}},
  soldiers:[],effects:[],arrows:[],corpses:[],done:false,
  stats:{left:{start:0,dead:0,hp:0,morale:100},right:{start:0,dead:0,hp:0,morale:100}}};
 b.soldiers.push(...makeSide(b.sides.left,'left',width,height,rand));
 b.soldiers.push(...makeSide(b.sides.right,'right',width,height,rand));
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
 return {enemy:taken<2?best:(second||best),d:taken<2?bd:sd};
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
   const ty=s.rowY!==undefined?(s.rowY*0.75+enemy.y*0.25):enemy.y;
   const vx=tx-s.x, vy=ty-s.y, vd=Math.hypot(vx,vy)||1;
   const k=Math.min(1,t.speed*dt/vd);
   s.x+=vx*k; s.y+=vy*k;
   s.face=dir>0?0:Math.PI; s.phase+=dt*8;
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
      if(e.side===s.side||e.state==='dead')continue;
      if(dist(e,enemy)<=wp.radius)damage(b,e,rl.dmg*(0.6+b.rand()*0.6),s,'spell');
     }
    }else{
     const dry=s.troop==='monk'&&s.spirit<8?0.55:1;   // 灵力见底的修士，剑也软
     const hit=damage(b,enemy,wp.dmg*dry*(0.7+b.rand()*0.7),s,'melee');
     addEffect(b,'slash',(s.x+enemy.x)/2,(s.y+enemy.y)/2,
      {angle:s.face,arc:wp.arc,ttl:.28,side:s.side,weapon:s.weapon});
     if(hit)addEffect(b,'blood',enemy.x,enemy.y-6,{ttl:.5,side:s.side});
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
  const leaderHit=(side==='left'?b.stats.left:b.stats.right).leaderDown?22:0;
  const morale=Math.round(Math.max(0,Math.min(100,100-dead*110/Math.max(1,mine.length)-fatigue-leaderHit)));
  st.morale=morale;
  for(const s of mine){
   if(s.state==='dead')continue;
   // 个人士气向全队靠拢：溃了就跟着溃，稳住就慢慢收回来
   const gap=morale-s.morale;
   s.morale=Math.round(s.morale+ (Math.abs(gap)<2?gap:Math.sign(gap)*Math.min(Math.abs(gap),8)));
   if(s.morale<18)s.state='rout';
   else if(s.state==='rout'&&s.morale>40)s.state='advance';
  }
 }
 const a=b.stats.left.alive||0,c=b.stats.right.alive||0;
 if(a===0||c===0||b.stats.left.morale<10||b.stats.right.morale<10){
  b.done=true;b.winner=c===0?'left':a===0?'right':(b.stats.left.morale>=b.stats.right.morale?'left':'right');
 }
 events.push({t:Math.round(b.t*10)/10,left:b.stats.left.alive,right:b.stats.right.alive,
  fx:b.effects.length,arrows:b.arrows.length});
 return events[events.length-1];
}
function damage(b,target,amount,attacker,kind){
 if(target.state==='dead')return false;
 const armor=target.armor||0;
 // 境界越高，凡兵的刀越难落到要害上
 const realmGuard=target.realm?1-0.13*(target.realm-1):1;
 const dmg=Math.max(1,Math.round((amount*2-armor*1.6)*Math.max(0.35,realmGuard)));
 target.hp-=dmg;
 const drop=Math.min(6,Math.max(1,Math.round(dmg/12)));
 target.morale=Math.max(0,target.morale-drop*2);
 if(target.hp<=0){
  target.state='dead';target.hp=0;
  // 首领一倒，全军士气跟着塌
  if(target.isLeader||target.leader){
   const st=target.side==='left'?b.stats.left:b.stats.right;
   st.leaderDown=true;b.events=b.events||[];
   b.events.push({t:+b.t.toFixed(1),kind:'leaderDown',side:target.side,name:target.name||'主将'});
  }
  b.corpses.push({x:target.x,y:target.y,side:target.side,angle:target.face,t:b.t});
  if(b.corpses.length>400)b.corpses.shift();
  addEffect(b,'death',target.x,target.y,{ttl:.6,side:target.side});
 }
 return true;
}
export function battleReport(b){
 const L=b.stats.left,R=b.stats.right;
 const leaders=b.soldiers.filter(s=>s.isLeader).map(s=>({side:s.side,name:s.name,state:s.state,hp:s.hp,maxHp:s.maxHp,realm:s.realmName}));
 const monks=b.soldiers.filter(s=>s.troop==='monk');
 return {t:Math.round(b.t*10)/10,done:b.done,winner:b.winner||null,
  left:{...L,lossRate:L.start?+(L.dead/L.start*100).toFixed(1):0},
  right:{...R,lossRate:R.start?+(R.dead/R.start*100).toFixed(1):0},
  corpses:b.corpses.length,effects:b.effects.length,fled:b.fled||0,
  leaders,
  monks:{total:monks.length,alive:monks.filter(s=>s.state!=='dead'&&s.state!=='fled').length,
   fled:monks.filter(s=>s.state==='fled').length,
   spentBag:monks.reduce((n,s)=>n+((s.bagStart||0)-(s.bag||0)),0)},
  events:b.events||[]};
}
