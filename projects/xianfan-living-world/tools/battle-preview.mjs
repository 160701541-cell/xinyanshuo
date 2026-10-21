// 把战斗模拟跑到接敌时刻，导出快照给预览渲染用（与游戏内同一份 battle.mjs）
import {createBattle,stepBattle,battleReport,WEAPONS,TROOPS} from '../battle.mjs';
import {writeFileSync} from 'node:fs';
const b=createBattle({seed:'临安东郊',left:{units:[{troop:'infantry',count:180},{troop:'archer',count:60}]},
 right:{units:[{troop:'cavalry',count:70},{troop:'swordsman',count:120}]}});
let t=0;const marks=[];
while(!b.done&&t<70){
 stepBattle(b,0.05);t+=0.05;
 if(Math.abs(t-18)<0.03)marks.push({at:t,snap:b.soldiers.map(s=>({x:s.x,y:s.y,side:s.side,state:s.state,face:s.face,weapon:s.weapon})),fx:b.effects.slice(-40),arrows:b.arrows.slice(),corpses:b.corpses.length});
}
writeFileSync('/tmp/battle.json',JSON.stringify({
 w:b.w,h:b.h,t:b.t,report:battleReport(b),marks,
 soldiers:b.soldiers.map(s=>({x:s.x,y:s.y,side:s.side,state:s.state,face:s.face,weapon:s.weapon,troop:s.troop,morale:s.morale})),
 corpses:b.corpses,effects:b.effects.slice(-120),arrows:b.arrows,
 colors:Object.fromEntries(Object.entries(TROOPS).map(([k,v])=>[k,v.color]))
}));
console.log('t',b.t.toFixed(1),JSON.stringify(battleReport(b)));
