// 战斗画面：把 battle.mjs 的个体士兵画成人，把效果画成刀光、箭、血。
import {createBattle,stepBattle,battleReport,TROOPS,WEAPONS,FORMATIONS} from './battle.js';

const SIDE_COLOR={left:'#60728e',right:'#9a5a4c'};
export function createBattleView({canvas,hud,world,seed='临安东郊'}){
 const ctx=canvas.getContext('2d');
 let b=null,running=false,last=0,raf=0,dpr=1;
 const resize=()=>{
  const r=canvas.getBoundingClientRect();
  dpr=Math.min(2,globalThis.devicePixelRatio||1);
  canvas.width=Math.max(320,Math.round(r.width*dpr));
  canvas.height=Math.max(220,Math.round(r.height*dpr));
 };
 function begin(opts={}){
  resize();
  const spec=opts.battle||draftFromWorld(world);
  b=createBattle({seed:opts.seed||seed,...spec});
  running=true;last=0;loop();
  return b;
 }
 function loop(ts=0){
  if(!running||!b)return;
  const dt=last?Math.min(0.06,(ts-last)/1000):0.016;last=ts;
  stepBattle(b,dt*3);              // 三倍速，手机上不至于看半小时
  draw();updateHud();
  if(b.done){running=false;draw();updateHud();return;}
  raf=requestAnimationFrame(loop);
 }
 function pause(){running=false;cancelAnimationFrame(raf);}
 function resume(){if(!b||b.done)return;running=true;last=0;loop();}
 function stop(){pause();b=null;}
 function draw(){
  if(!b)return;
  const W=canvas.width/dpr,H=canvas.height/dpr;
  ctx.setTransform(dpr,0,0,dpr,0,0);
  const sx=W/b.w,sy=H/b.h;
  ctx.fillStyle='#626e4a';ctx.fillRect(0,0,W,H);
  // 地面斑驳
  ctx.fillStyle='rgba(80,90,58,.5)';
  for(let i=0;i<60;i++){const x=(i*97%W),y=(i*53%H);ctx.fillRect(x,y,3,2);}
  // 尸体
  for(const c of b.corpses){ctx.fillStyle='rgba(58,54,42,.85)';ctx.fillRect(c.x*sx-2,c.y*sy-1,5,2);}
  // 箭
  ctx.strokeStyle='#ece7cf';ctx.lineWidth=1;
  for(const a of b.arrows){const ang=Math.atan2(a.vy,a.vx);ctx.beginPath();ctx.moveTo(a.x*sx,a.y*sy);ctx.lineTo(a.x*sx-Math.cos(ang)*6,a.y*sy-Math.sin(ang)*6);ctx.stroke();}
  // 人
  for(const s of b.soldiers){
   if(s.state==='dead')continue;
   const x=s.x*sx,y=s.y*sy;
   const sway=s.state==='fight'?Math.sin(b.t*10+s.id)*1.2:0;
   ctx.fillStyle='rgba(40,38,30,.35)';ctx.beginPath();ctx.ellipse(x,y+3,3.2,1.6,0,0,6.283);ctx.fill();
   ctx.fillStyle=SIDE_COLOR[s.side]||'#7a8a70';
   ctx.fillRect(x-2,y-4+sway,4,7);                        // 身
   ctx.fillStyle='#e2ceb0';ctx.beginPath();ctx.arc(x,y-6+sway,1.9,0,6.283);ctx.fill();  // 头
   const f=s.face,dx=Math.cos(f),dy=Math.sin(f),wp=s.weapon;
   ctx.strokeStyle= wp==='staff'?'#a48ec6':(wp==='bow'||wp==='crossbow')?'#8a7048':'#cfd4dc';
   ctx.lineWidth=1.2;ctx.beginPath();
   if(wp==='spear'||wp==='lance'){ctx.moveTo(x+dx*2,y-2);ctx.lineTo(x+dx*11,y-6);}
   else if(wp==='staff'){ctx.moveTo(x+dx*2,y-3);ctx.lineTo(x+dx*8,y-9);}
   else if(wp==='bow'||wp==='crossbow'){ctx.arc(x+dx*3,y-4,3.2,Math.PI*0.7,Math.PI*2.3);}
   else{ctx.moveTo(x+dx*2,y-3);ctx.lineTo(x+dx*6,y-7);}
   ctx.stroke();
  }
  // 特效
  for(const e of b.effects){
   const age=(b.t-e.t)/e.ttl;
   if(age>1)continue;
   const x=e.x*sx,y=e.y*sy,al=1-age;
   if(e.kind==='slash'){
    const ang=e.angle||0,arc=(e.arc||40)*Math.PI/180,r=10;
    ctx.strokeStyle=`rgba(248,242,214,${.75*al})`;ctx.lineWidth=2;
    ctx.beginPath();ctx.arc(x,y,r,ang-arc/2,ang+arc/2);ctx.stroke();
   }else if(e.kind==='blood'){
    ctx.fillStyle=`rgba(150,40,36,${.8*al})`;
    for(let i=0;i<4;i++)ctx.fillRect(x+((i*7)%9)-4,y+((i*5)%7)-3,1.6,1.6);
   }else if(e.kind==='death'){
    ctx.strokeStyle=`rgba(120,110,90,${.5*al})`;ctx.beginPath();ctx.arc(x,y,5*(1+age),0,6.283);ctx.stroke();
   }else if(e.kind==='spell'){
    ctx.strokeStyle=`rgba(170,150,220,${.7*al})`;ctx.lineWidth=2;
    ctx.beginPath();ctx.arc(x,y,(e.r||20)/2*(0.6+age),0,6.283);ctx.stroke();
   }else if(e.kind==='shoot'){
    ctx.strokeStyle=`rgba(240,230,200,${.5*al})`;ctx.beginPath();ctx.moveTo(x,y);ctx.lineTo(x+Math.cos(e.angle||0)*8,y+Math.sin(e.angle||0)*8);ctx.stroke();
   }
  }
 }
 function updateHud(){
  if(!hud||!b)return;
  const r=battleReport(b);
  hud.innerHTML=`<strong>${b.done?(r.winner==='left'?'官军胜':'敌军胜'):'交战中'}</strong> · 第 ${Math.round(b.t)} 秒
   <br><small>左 ${r.left.alive}/${r.left.start}（亡 ${r.left.dead}，士气 ${r.left.morale}） · 右 ${r.right.alive}/${r.right.start}（亡 ${r.right.dead}，士气 ${r.right.morale}） · 尸 ${r.corpses}</small>`;
 }
 return {begin,pause,resume,stop,draw,updateHud,get battle(){return b;}};
}
/** 从大地图上的军团随手编一支出来；没有军团就用默认编制。 */
export function draftFromWorld(w){
 try{
  const armies=(w.war?.armies||[]).filter(a=>a.side==='court'&&a.alive!==0);
  const mine=armies[0];
  const n=mine?Math.max(60,Math.min(240,Math.round((mine.combat||600)/400))):180;
  return {left:{units:[{troop:'infantry',count:n},{troop:'archer',count:Math.round(n/3)}]},
   right:{units:[{troop:'swordsman',count:Math.round(n*0.7)},{troop:'cavalry',count:Math.round(n*0.35)}]}};
 }catch{return {left:{units:[{troop:'infantry',count:180}]},right:{units:[{troop:'swordsman',count:120}]}};}
}
export {WEAPONS,TROOPS,FORMATIONS};
