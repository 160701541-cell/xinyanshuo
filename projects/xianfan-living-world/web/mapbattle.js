// 战斗直接长在天下地图上：坐标是世界米，不是另开一屏。
// 视野放大到 6 米/像素以内看得到每一个人、每一支箭；缩远了就聚成块并标人数。
import {createBattle,stepBattle,battleReport,WEAPONS,TROOPS} from './battle.js';

export const MAPBATTLE_VERSION='mapbattle-0.1.0';

const KEY='__mapBattle';
export function mapBattle(world){return world[KEY]||null;}

/** 在世界坐标 at 处摆开一场仗。左右编制不给就按当地规模给默认。 */
export function spawnMapBattle(world,opts={}){
 const seed=opts.seed||`${world.seed||'临安'}-${world.day||1}-${Math.round(opts.at?.x||0)}-${Math.round(opts.at?.y||0)}`;
 const b=createBattle({seed,width:opts.w||300,height:opts.h||180,
  left:opts.left||{units:[{troop:'infantry',count:180},{troop:'archer',count:60}]},
  right:opts.right||{units:[{troop:'swordsman',count:120},{troop:'cavalry',count:60}]}});
 const at=opts.at||{x:0,y:0};
 b.origin={x:Math.round(at.x-b.w/2),y:Math.round(at.y-b.h/2)};
 b.world=world;b.paused=false;b.speed=opts.speed||1;b.label=opts.label||'遭遇战';
 b.when={day:world.day||1,hour:world.hour||8};
 world[KEY]=b;
 return b;
}

/** 有仗就打，没仗返回 null；dt 是世界秒（受游戏内时间倍率影响） */
export function stepMapBattle(world,dt){
 const b=mapBattle(world);
 if(!b||b.paused||b.done)return b;
 const d=Math.min(0.2,Math.max(0,dt))*b.speed;
 if(d>0)stepBattle(b,d);
 return b;
}

export function mapBattleReport(world){
 const b=mapBattle(world);
 if(!b)return null;
 const r=battleReport(b);
 return {...r,label:b.label,at:{x:b.origin.x+b.w/2,y:b.origin.y+b.h/2},hour:b.when};
}

export function endMapBattle(world){if(world[KEY])world[KEY]=null;}

/** 世界米 → 屏幕，画在地图 canvas 上（pos 由调用方传入，遵循相机与缩放） */
export function drawMapBattle(b,ctx,pos,mpp,opts={}){
 if(!b||!b.origin)return;
 const {w:cw,h:ch}=b;
 const origin=b.origin;
 const px=v=>v/mpp;                       // 米 → 像素
 const SP=(x,y)=>pos({x:origin.x+x,y:origin.y+y});
 // 只在视野内画
 const c=pos({x:origin.x+cw/2,y:origin.y+ch/2});
 if(c.x<-400||c.y<-400||c.x>opts.cssW+400||c.y>opts.cssH+400)return;
 const detail=mpp<=0.9;                     // 0.9 米/像素以内逐人画；再远就是战场一团
 const side={left:'#3f6ea8',right:'#c0452e'};
 // 地面：被踩踏的战场
 const tl=SP(0,0),br=SP(cw,ch);
 ctx.fillStyle='rgba(112,92,58,.24)';ctx.fillRect(tl.x,tl.y,px(cw),px(ch));
 if(detail){
  // 尸体
  ctx.fillStyle='rgba(52,44,32,.62)';
  for(const cd of b.corpses){const p=SP(cd.x,cd.y);ctx.fillRect(p.x-1.5,p.y-1,3,2);}
 } else {
  // 尸体堆：按 40 米格聚合成块
  const cell=40,agg=new Map();
  for(const cd of b.corpses){const k=(Math.floor(cd.x/cell))+','+(Math.floor(cd.y/cell));agg.set(k,(agg.get(k)||0)+1);}
  ctx.fillStyle='rgba(52,44,32,.58)';
  for(const [k,n] of agg){const [gx,gy]=k.split(',').map(Number);const p=SP(gx*cell+cell/2,gy*cell+cell/2);ctx.fillRect(p.x-2,p.y-1.5,4,3);}
 }
 const baseBody=Math.max(1.4,Math.min(7,9/mpp));  // 小人像素高
 const baseStaff=Math.max(2,Math.min(14,20/mpp));// 武器长度
 if(detail){
  for(const s of b.soldiers){
   if(s.state==='dead')continue;
   const p=SP(s.x,s.y);
   // 将领与修士：小圆头像（描金边），一眼能在人堆里认出来
   if(s.isLeader||s.leader){
    const R=Math.max(8,Math.min(18,px(6)));
    ctx.beginPath();ctx.arc(p.x,p.y,R,0,6.283);
    ctx.fillStyle=side[s.side]||'#666';ctx.fill();
    ctx.lineWidth=2;ctx.strokeStyle='#e8cf8a';ctx.stroke();
    ctx.fillStyle='#f4ecd8';ctx.font=`${Math.round(R*1.1)}px sans-serif`;ctx.textAlign='center';ctx.textBaseline='middle';
    ctx.fillText((s.name||'将').slice(0,1),p.x,p.y+1);ctx.textAlign='left';
    if(mpp<1.4){ctx.fillStyle='rgba(24,22,18,.7)';ctx.fillText(s.name||'将',p.x+R+2,p.y-2);}
    continue;
   }
   if(s.troop==='monk'){
    const R=Math.max(3,Math.min(8,px(4)));
    ctx.beginPath();ctx.arc(p.x,p.y,R+2.5,0,6.283);ctx.strokeStyle='rgba(170,150,220,.55)';ctx.lineWidth=1.2;ctx.stroke();
    ctx.beginPath();ctx.arc(p.x,p.y,R,0,6.283);ctx.fillStyle='#9aa2cf';ctx.fill();continue;
   }
   // 兵种衣色来自 battle.mjs 的 TROOPS.color（v0.32 提饱和），阵营色只做底衬
   const many=TROOPS[s.troop]||{};
   const cloth=many.color||side[s.side]||'#666';
   const bsz=Math.max(1,s.size||many.size||1);       // 妖兽按体型放大
   const body=baseBody*bsz, staff=baseStaff*Math.min(2.2,bsz);
   ctx.fillStyle=side[s.side]||'#666';
   ctx.fillRect(p.x-body/2-0.6,p.y-body-0.6,body+1.2,body*1.5+1.2);
   ctx.fillStyle=cloth;
   ctx.fillRect(p.x-body/2,p.y-body,body,body*1.5); // 身
   ctx.fillStyle='#e8cfa6';ctx.fillRect(p.x-body/2.6,p.y-body*1.9,body/1.3,body/1.3); // 头
   const dx=Math.cos(s.face||0),dy=Math.sin(s.face||0);
   ctx.strokeStyle=s.weapon==='bow'||s.weapon==='crossbow'?'#8b6f45':'#c9ced6';
   ctx.lineWidth=Math.max(.7,body*.18);
   ctx.beginPath();ctx.moveTo(p.x+dx*body*.4,p.y-body*.6);ctx.lineTo(p.x+dx*staff,p.y-body*.6+dy*staff*.5);ctx.stroke();
  }
  // 箭矢与特效
  for(const a of b.arrows){const p=SP(a.x,a.y);ctx.strokeStyle='#e6e0c8';ctx.lineWidth=1;ctx.beginPath();ctx.moveTo(p.x,p.y);ctx.lineTo(p.x-Math.cos(a.angle||0)*3,p.y-Math.sin(a.angle||0)*3);ctx.stroke();}
  for(const e of b.effects){
   const p=SP(e.x,e.y),k=e.kind;
   if(k==='slash'){ctx.strokeStyle=`rgba(255,250,214,${Math.max(0,e.ttl/0.4)*.85})`;ctx.lineWidth=1.4;ctx.beginPath();ctx.arc(p.x,p.y,Math.max(2,px(9)),(e.angle||0)-.7,(e.angle||0)+.7);ctx.stroke();}
   else if(k==='blood'){ctx.fillStyle='rgba(150,44,38,.75)';ctx.fillRect(p.x-1,p.y-1,2,2);}
   else if(k==='spell'){const r=Math.max(3,px(e.r||18));ctx.strokeStyle='rgba(180,160,230,.6)';ctx.lineWidth=1.5;ctx.beginPath();ctx.arc(p.x,p.y,r,0,6.283);ctx.stroke();}
  }
 } else {
  // 缩远：一团一团，写人数
  const cell=22,agg=new Map();
  for(const s of b.soldiers){if(s.state==='dead')continue;const k=s.side+':'+(Math.floor(s.x/cell))+','+(Math.floor(s.y/cell));const a=agg.get(k)||{n:0,x:0,y:0,side:s.side};a.n++;a.x+=s.x;a.y+=s.y;agg.set(k,a);}
  for(const a of agg.values()){const p=SP(a.x/a.n,a.y/a.n);const r=Math.max(2.5,Math.sqrt(a.n)*1.6);
   ctx.fillStyle=side[a.side];ctx.globalAlpha=.85;ctx.beginPath();ctx.arc(p.x,p.y,r,0,6.283);ctx.fill();ctx.globalAlpha=1;}
 }
 // 战况条：贴在地图上的小字
 const rp=battleReport(b);
 if(mpp<40){
  ctx.fillStyle='rgba(24,22,18,.62)';
  const bw=px(cw),bh=Math.max(14,px(26));
  ctx.fillRect(tl.x,tl.y-bh-2,bw,bh+2);
  ctx.fillStyle='#e6dcc4';ctx.font=`${Math.max(9,Math.min(12,px(22)))}px sans-serif`;ctx.textBaseline='middle';
  const who=side=>rp.command[side].leaderless?'群龙无首':(rp.command[side].inCharge||'—');
  const extra=[];
  for(const sd of ['left','right']){
   const st=rp[sd];
   if(st.surrendered)extra.push(`${sd==='left'?'左':'右'}降 ${st.surrendered}`);
   if(st.routed)extra.push(`${sd==='left'?'左':'右'}溃 ${st.routed}`);
  }
  const phase=rp.mixed?'混战':`列阵${rp.mixedAt?'':''}`;
  const line=`${b.label} · ${phase} · 左 ${rp.left.alive}(${who('left')}) 右 ${rp.right.alive}(${who('right')})${extra.length?' · '+extra.join(' '):''}${rp.friendly?` · 误伤 ${rp.friendly}`:''}${b.done?' · 已分胜负':''}`;
  ctx.fillText(line,tl.x+4,tl.y-bh/2-1);
 }
}
