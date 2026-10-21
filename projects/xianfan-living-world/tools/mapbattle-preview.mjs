// 把"地图上的战斗"导成快照：坐标是世界米，预览按 1.28 像素/米叠到县城图上
import {spawnMapBattle,stepMapBattle,mapBattleReport,drawMapBattle} from '../mapbattle.mjs';
import {writeFileSync} from 'node:fs';
const w={seed:'临安',day:21,hour:17};
const b=spawnMapBattle(w,{at:{x:150,y:-60},label:'东市外遭遇战',
 left:{units:[{troop:'monk',count:2,realm:3,bag:2,leader:'玄阳子'},{troop:'infantry',count:120},{troop:'archer',count:40}]},
 right:{units:[{troop:'swordsman',count:80},{troop:'cavalry',count:40}]}});
let t=0;
while(t<26){stepMapBattle(w,0.1);t+=0.1;}
writeFileSync('/tmp/mapbattle.json',JSON.stringify({
 w:b.w,h:b.h,origin:b.origin,t:b.t,label:b.label,
 soldiers:b.soldiers.map(s=>({x:s.x,y:s.y,side:s.side,state:s.state,face:s.face,weapon:s.weapon,troop:s.troop,isLeader:!!s.isLeader,name:s.name,realmName:s.realmName})),
 corpses:b.corpses,arrows:b.arrows,effects:b.effects.slice(-160),
 report:mapBattleReport(w)}));
console.log('ok t',b.t.toFixed(1),JSON.stringify(mapBattleReport(w).left));
