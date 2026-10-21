// 《仙凡共生》世界版图：整张地图都要有东西，但不必每处都画细。
// 做法是：每个地块就是"圈一块地"——一个名字、一种地类、一个面积、一份储量/年出。
// 凡界与仙界尺寸相同，各自一套地块，互不重叠地铺满整张图。
const mulberry=(seed)=>{let a=seed>>>0;return()=>{a=(a+0x6D2B79F5)>>>0;let t=Math.imul(a^(a>>>15),1|a);t=(t+Math.imul(t^(t>>>7),61|t))^t;return((t^(t>>>14))>>>0)/4294967296;};};
const hash=(str)=>{let h=2166136261;for(let i=0;i<str.length;i++){h^=str.charCodeAt(i);h=Math.imul(h,16777619);}return h>>>0;};

/** 凡界地类：每种都有颜色、单位面积储量、危险度。 */
export const MORTAL_TYPES={
 plain:{name:'平野',color:'#c9c79a',res:'grain',per:1.1,danger:0},
 farm:{name:'田畴',color:'#d8c98c',res:'grain',per:3.4,danger:0},
 hill:{name:'丘陵',color:'#b7bd8c',res:'fuel',per:1.6,danger:0},
 forest:{name:'森林',color:'#7f9a68',res:'timber',per:2.6,danger:1},
 bamboo:{name:'竹林',color:'#93ab72',res:'bamboo',per:2.1,danger:1},
 marsh:{name:'泽薮',color:'#8fa894',res:'reed',per:1.4,danger:2},
 mountain:{name:'山地',color:'#9a9484',res:'stone',per:2.2,danger:2},
 desert:{name:'荒碛',color:'#cfc09a',res:'salt',per:.4,danger:3},
 lake:{name:'湖泊',color:'#8fb6bd',res:'fish',per:2.8,danger:1},
 mine:{name:'矿脉',color:'#8d7f77',res:'iron',per:1.9,danger:2},
 pasture:{name:'牧场',color:'#bcc58f',res:'beast',per:1.2,danger:1},
 salt:{name:'盐场',color:'#d9d3bb',res:'salt',per:2.6,danger:1}
};
/** 仙界地类：灵脉、药山、妖兽域、秘境古墟。 */
export const XIAN_TYPES={
 lingmai:{name:'灵脉',color:'#8fb0c8',res:'qi',per:1.0,danger:2},
 yaoshan:{name:'药山',color:'#93b98d',res:'herb',per:1.8,danger:2},
 yaodao:{name:'妖兽域',color:'#b48f8f',res:'beast',per:1.3,danger:4},
 mijing:{name:'秘境古墟',color:'#a79ac6',res:'relic',per:.7,danger:5},
 spring:{name:'灵泉',color:'#93c7c9',res:'water',per:1.2,danger:1},
 wasteland:{name:'荒原',color:'#b9b394',res:'stone',per:.6,danger:2},
 sects:{name:'宗门领地',color:'#c2b48f',res:'grain',per:.9,danger:0}
};
export const NAME_A=['青','落','黑','白','赤','长','幽','寒','望','归','浮','断','云','石','柳','雁','龙','鹿','杏','枫'];
export const NAME_B=['风','霞','水','石','松','岭','溪','川','原','谷','汀','塘','坡','坪','滩','坳','泉','潭','林','崖'];

/** 平滑值噪声：让相邻地块倾向同一种地类，而不是撒花。 */
const lattice=(seed)=>{const a=new Float32Array(4096);const r=mulberry(hash(seed));for(let i=0;i<4096;i++)a[i]=r();return a;};
const smooth=t=>t*t*(3-2*t);
function noise2(tab,x,y){
 const xi=Math.floor(x),yi=Math.floor(y),xf=smooth(x-xi),yf=smooth(y-yi);
 const h=(i,j)=>{const k=((i*73856093)^(j*19349663))&4095;return tab[k<0?k+4096:k];};
 const a=h(xi,yi),b=h(xi+1,yi),c=h(xi,yi+1),d=h(xi+1,yi+1);
 return (a*(1-xf)+b*xf)*(1-yf)+(c*(1-xf)+d*xf)*yf;
}
function field(tab,x,y,scale){return noise2(tab,x/scale,y/scale)*.65+noise2(tab,x/scale*3.1+77,y/scale*3.1+31)*.35;}

/** 用抖动网格撒种，再由最近种决定归属：整张图被无缝铺满。 */
export function generateRealm({realm='mortal',seed='临安',extent=1_350_000,sides=36,grid=54}={}){
 if(realm==='world')return generateWorld({seed,extent,sides,grid});
 return realmView(generateWorld({seed,extent,sides,grid}),realm);
}

/** 同一张世界图：凡界与修仙界交错在同一片地面上，不分成两张图。
 *  灵气浓的地方才成修仙界（灵脉、药山、妖兽域），其余是凡界的县、田、山林。 */
export const DOMAIN_QI=0.68;
export function generateWorld({seed='临安',extent=1_350_000,sides=36,grid=54}={}){
 const rnd=mulberry(hash('world:'+seed));
 const step=(extent*2)/sides;
 const tabA=lattice('elev:'+seed),tabB=lattice('moist:'+seed),tabC=lattice('wild:'+seed),tabD=lattice('qi:'+seed);
 const seeds=[];
 for(let j=0;j<sides;j++)for(let i=0;i<sides;i++){
  const x=-extent+step*(i+.5)+(rnd()-.5)*step*.8;
  const y=-extent+step*(j+.5)+(rnd()-.5)*step*.8;
  const e=field(tabA,x,y,420000),m=field(tabB,x,y,360000),w=field(tabC,x,y,300000),q=field(tabD,x,y,380000);
  const domain=q>=DOMAIN_QI?'cultivation':'mortal';
  const type=pickType(domain==='cultivation'?'xian':'mortal',{e,m,w,q});
  const name=NAME_A[(rnd()*NAME_A.length)|0]+NAME_B[(rnd()*NAME_B.length)|0]+suffixOf(type);
  seeds.push({id:`world-${i}-${j}`,x:Math.round(x),y:Math.round(y),type,name,domain,
   e:Math.round(e*100)/100,m:Math.round(m*100)/100,qi:Math.round(q*100)/100});
 }
 const G=grid,cellArea=Math.pow((extent*2)/G/1000,2);
 const owner=new Int16Array(G*G);
 for(let gj=0;gj<G;gj++)for(let gi=0;gi<G;gi++){
  const x=-extent+(gi+.5)*((extent*2)/G),y=-extent+(gj+.5)*((extent*2)/G);
  let best=0,bd=Infinity;
  for(let k=0;k<seeds.length;k++){const d=(seeds[k].x-x)**2+(seeds[k].y-y)**2;if(d<bd){bd=d;best=k;}}
  owner[gj*G+gi]=best;
 }
 const areas=new Float64Array(seeds.length);
 for(let c=0;c<owner.length;c++)areas[owner[c]]+=cellArea;
 const regions=seeds.map((s,k)=>{
  const t=(s.domain==='cultivation'?XIAN_TYPES:MORTAL_TYPES)[s.type];
  const area=Math.max(1,Math.round(areas[k]));
  return {...s,realm:s.domain,land:t.name,color:t.color,areaKm2:area,
   resource:t.res,stock:Math.round(area*t.per*100)/100,
   yearly:Math.round(area*t.per),danger:t.danger,county:null};
 });
 return {realm:'world',seed,extent,sides,regions,owner,grid:G,cellArea,
  totalKm2:Math.round(Math.pow((extent*2)/1000,2))};
}

/** 从同一张世界图里取一界的视角：坐标不动，只把另一界的地块留白。 */
export function realmView(world,domain){
 const keep=world.regions.filter(r=>r.domain===domain);
 const pos=new Map(keep.map((r,i)=>[r.id,i]));
 const owner=new Int16Array(world.owner.length);
 let covered=0;
 for(let i=0;i<world.owner.length;i++){
  const r=world.regions[world.owner[i]];
  const k=r&&r.domain===domain?pos.get(r.id):undefined;
  if(k===undefined){owner[i]=-1;continue;}
  owner[i]=k;covered++;
 }
 return {realm:domain,seed:world.seed,extent:world.extent,sides:world.sides,
  grid:world.grid,cellArea:world.cellArea,regions:keep,owner,
  totalKm2:world.totalKm2,coverage:covered/world.owner.length};
}
export function domainShare(world){
 let cult=0;for(const r of world.regions)if(r.domain==='cultivation')cult++;
 return {cultivation:cult/world.regions.length,mortal:1-cult/world.regions.length};
}

/** 某个坐标落在哪块地。 */
export function regionAt(map,p){
 const {extent,grid}=map;
 const gi=Math.floor((p.x+extent)/((extent*2)/grid)),gj=Math.floor((p.y+extent)/((extent*2)/grid));
 if(gi<0||gj<0||gi>=grid||gj>=grid)return null;
 return map.regions[map.owner[gj*grid+gi]]||null;
}
/** 统计：地类数量、面积、储量总和。 */
export function realmReport(map){
 const byType={};
 for(const r of map.regions){
  if(!byType[r.land])byType[r.land]={count:0,areaKm2:0,yearly:0,danger:0};
  const b=byType[r.land];b.count++;b.areaKm2+=r.areaKm2;b.yearly+=r.yearly;b.danger=Math.max(b.danger,r.danger);
 }
 return {realm:map.realm,totalKm2:map.totalKm2,regions:map.regions.length,
  coverage:Math.min(1,map.regions.reduce((n,r)=>n+r.areaKm2,0)/map.totalKm2),byType};
}

/** 地类由高程/湿润/蛮荒三个场决定：相邻地块成片，而不是随机撒花。 */
export function pickType(realm,{e,m,w,q=0}){
 if(realm==='mortal'){
  if(e>.80)return 'mountain';
  if(e>.66)return e>.72&&m<.42?'mine':'hill';
  if(e<.20)return m>.52?'lake':'marsh';
  if(m<.26)return e>.5?'desert':(w>.7?'mine':'plain');
  if(m<.42)return w>.62?'pasture':'plain';
  if(m<.58)return e<.5?'farm':(w>.66?'bamboo':'pasture');
  if(m<.74)return w>.62?'bamboo':'forest';
  if(m<.86)return 'forest';
  return w>.7?'marsh':'forest';
 }
 // 仙界：灵气是底子，地类是灵气浓度、地势与蛮荒三个场叠出来的
 if(w>.88&&q>.62)return 'mijing';
 if(e>.70)return 'yaoshan';
 if(w>.62)return 'yaodao';
 if(m>.58)return 'spring';
 if(q>.76)return 'lingmai';
 if(e<.30)return 'wasteland';
 if(w>.46)return 'sects';
 return 'lingmai';
}
const suffixOf=type=>type==='lake'||type==='spring'?'湖':(type==='mountain'||type==='yaoshan'?'山':type==='forest'||type==='bamboo'?'林':'');
