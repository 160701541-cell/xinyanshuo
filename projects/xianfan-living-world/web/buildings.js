// 《仙凡共生》建筑层：地图放大要看见“真的建筑”，缩远要看见街坊。
// 房屋沿街生长、院墙围合、门朝巷、巷子有宽窄弯折；所有几何都确定性生成。
// 这里不 import overworld：布局所需的公共建筑由调用方传入，避免模块环。
import {STRUCTURES} from './overworld.js';

const deriveSeed=(str)=>{let h=2166136261;for(let i=0;i<str.length;i++){h^=str.charCodeAt(i);h=Math.imul(h,16777619);}return h>>>0;};
const R=(s)=>{let a=s>>>0;return()=>{a=(a+0x6D2B79F5)>>>0;let t=Math.imul(a^(a>>>15),1|a);t=(t+Math.imul(t^(t>>>7),61|t))^t;return((t^(t>>>14))>>>0)/4294967296;};};

/** 统一画风：画布与预览共用同一组数值，别搞两套美术。 */
/**
 * v0.32 提色：之前的色板全是低饱和的灰土色（#8a7d68 一类），
 * 缩远之后叠在一起就是“雾蒙蒙”，这不是没画清楚，是颜色本身太灰。
 * 这里整体抬高饱和、明确明暗层次：屋顶按用途分青瓦/灰瓦/木瓦/茅草，
 * 墙面白灰为主，地面有了草绿/田黄/路沙三个明确色相。
 */
export const ART={
 roof:{official:'#54687e',temple:'#565a68',home:'#8a6242',shop:'#a86c33',thatch:'#c99a45',warehouse:'#78684e'},
 wall:{rammed:'#c9b28e',brick:'#b89a76',stone:'#a5a49c',plaster:'#efe8d6'},
 ground:{street:'#d9c9a2',yard:'#d6c9a8',field:'#b3c14c',grass:'#9fbb60',mud:'#c2ab84'},
 accent:{eaves:'#4a4234',ridge:'#332e24',door:'#7a4f30',well:'#6f8b98',tree:'#3f7f3a',treeLight:'#6fa854',stall:'#c46436',roofEdge:'#7d6d50'},
 ink:'#3f3a2e'
};

function noise01(str,x){let h=2166136261;for(const c of String(str)+'|'+x){h^=c.charCodeAt(0);h=Math.imul(h,16777619);}return ((h>>>0)%1000)/1000;}

/** 街巷：两条大街直（官府定的），四条副街与市场巷带折点（人走出来的）。 */
export const STREETS=[
 {id:'main-ns',x1:0,y1:-720,x2:0,y2:720,w:34,kind:'avenue'},
 {id:'main-ew',x1:-720,y1:0,x2:720,y2:0,w:26,kind:'avenue'},
 {id:'north-lane',x1:-720,y1:-392,x2:-180,y2:-380,w:13,kind:'lane'},
 {id:'north-lane-b',x1:-180,y1:-380,x2:250,y2:-396,w:13,kind:'lane'},
 {id:'north-lane-c',x1:250,y1:-396,x2:720,y2:-384,w:13,kind:'lane'},
 {id:'south-lane',x1:-720,y1:386,x2:-120,y2:396,w:13,kind:'lane'},
 {id:'south-lane-b',x1:-120,y1:396,x2:330,y2:382,w:13,kind:'lane'},
 {id:'south-lane-c',x1:330,y1:382,x2:720,y2:392,w:13,kind:'lane'},
 {id:'west-lane',x1:-388,y1:-720,x2:-376,y2:-90,w:12,kind:'lane'},
 {id:'west-lane-b',x1:-376,y1:-90,x2:-392,y2:720,w:12,kind:'lane'},
 {id:'east-lane',x1:378,y1:-720,x2:390,y2:120,w:12,kind:'lane'},
 {id:'east-lane-b',x1:390,y1:120,x2:376,y2:720,w:12,kind:'lane'},
 {id:'market-alley',x1:-330,y1:126,x2:-40,y2:112,w:10,kind:'market'},
 {id:'market-alley-b',x1:-40,y1:112,x2:330,y2:130,w:10,kind:'market'}
];

const inRect=(p,b,m=0)=>p.x>=b.x-m&&p.x<=b.x+b.w+m&&p.y>=b.y-m&&p.y<=b.y+b.h+m;
const nearStreet=(x,y,r,lanes=STREETS)=>lanes.some(s=>{
  const minX=Math.min(s.x1,s.x2)-s.w/2-r,maxX=Math.max(s.x1,s.x2)+s.w/2+r;
  const minY=Math.min(s.y1,s.y2)-s.w/2-r,maxY=Math.max(s.y1,s.y2)+s.w/2+r;
  // 斜街用线段距离判断
  const dx=s.x2-s.x1,dy=s.y2-s.y1,len2=dx*dx+dy*dy||1;
  const t=Math.max(0,Math.min(1,((x-s.x1)*dx+(y-s.y1)*dy)/len2));
  const px=s.x1+dx*t,py=s.y1+dy*t;
  return Math.hypot(x-px,y-py)<s.w/2+r&&x>=minX-40&&x<=maxX+40&&y>=minY-40&&y<=maxY+40;
});

/** 民居院落：院墙四段、主屋、厢房、院门、井/树；门永远朝街。 */
function compound(seed,x,y,w,h,kind='home',facing='south'){
 const r=R(seed);
 const roof=kind==='shop'?'shop':(r()<.32?'thatch':'home');
 const t=8;
 const parts=[{t:'wall',x:x,y:y,w:w,h:t},{t:'wall',x:x,y:y+h-t,w:w,h:t},
              {t:'wall',x:x,y:y,w:t,h:h},{t:'wall',x:x+w-t,y:y,w:t,h:h},
              {t:'yard',x:x+t,y:y+t,w:w-2*t,h:h-2*t}];
 const hw=w-20,hh=Math.round(h*.6);
 const hx=x+10,hy=facing==='north'?y+h-8-hh:y+t;
 parts.push({t:'house',x:hx,y:hy,w:hw,h:hh,roof,ridge:hw>=hh?'ew':'ns',floors:kind==='shop'?2:1});
 if(w>=86)parts.push({t:'wing',x:hx,y:facing==='north'?hy-4-Math.round(h*.2):hy+hh+4,w:Math.round(hw*.34),h:Math.round(h*.2),roof:'home',ridge:'ns'});
 const gy=facing==='north'?y:y+h-t-1;
 parts.push({t:'gate',x:x+w/2-13,y:gy,w:26,h:t+2});
 if(r()<.5)parts.push({t:'well',x:x+w*.3,y:y+h*(facing==='north'?.3:.72),size:4});
 if(r()<.66)parts.push({t:'tree',x:x+w*.74,y:y+h*(facing==='north'?.26:.74),size:5+(r()*2|0)});
 return {id:'',kind,x,y,w,h,parts,roof:roof==='thatch'?'thatch':'home'};
}

/** 公共建筑：按 STRUCTURES 的口径给形制；县衙三进、客栈两层、粮行带仓、铁铺带棚。 */
function publicBuilding(s){
 const {x,y,w,h}=s;const parts=[{t:'yard',x:x+3,y:y+3,w:w-6,h:h-6}];
 if(s.kind==='government'){
  parts.push({t:'house',x:x+10,y:y+10,w:w-20,h:Math.round(h*.4),roof:'official',ridge:'ew'});
  parts.push({t:'house',x:x+22,y:y+Math.round(h*.54),w:w-44,h:Math.round(h*.3),roof:'official',ridge:'ew'});
  parts.push({t:'gate',x:x+w/2-14,y:y+h-10,w:28,h:10});
  parts.push({t:'tree',x:x+16,y:y+h*.5,size:6});
 }else if(s.kind==='inn'){
  parts.push({t:'house',x:x+8,y:y+8,w:Math.round(w*.6),h:h-16,roof:'shop',floors:2,ridge:'ns'});
  parts.push({t:'house',x:x+Math.round(w*.65),y:y+8,w:Math.round(w*.27),h:Math.round(h*.5),roof:'shop'});
  parts.push({t:'gate',x:x+12,y:y+h-9,w:16,h:9});
  parts.push({t:'stall',x:x+Math.round(w*.62),y:y+h-26,w:26,h:12});
 }else if(s.kind==='forge'){
  parts.push({t:'house',x:x+8,y:y+8,w:w-16,h:Math.round(h*.55),roof:'shop',ridge:'ns'});
  parts.push({t:'stall',x:x+10,y:y+h-40,w:30,h:14});
  parts.push({t:'tree',x:x+w-18,y:y+h-20,size:5});
 }else if(s.kind==='grain'){
  parts.push({t:'house',x:x+8,y:y+8,w:w-16,h:Math.round(h*.6),roof:'shop',ridge:'ew'});
  parts.push({t:'stall',x:x+12,y:y+h-46,w:w-24,h:16});
 }else if(s.kind==='school'){
  parts.push({t:'house',x:x+10,y:y+10,w:w-20,h:Math.round(h*.55),roof:'official',ridge:'ew'});
  parts.push({t:'tree',x:x+w-22,y:y+h-22,size:8});
  parts.push({t:'gate',x:x+w/2-10,y:y+h-9,w:20,h:9});
 }else if(s.kind==='fort'){
  parts.push({t:'house',x:x+8,y:y+8,w:w-16,h:h-16,roof:'official',ridge:'ns'});
 }else{
  parts.push({t:'house',x:x+8,y:y+8,w:w-16,h:Math.round(h*.6),roof:'home',ridge:'ew'});
  parts.push({t:'tree',x:x+w*.5,y:y+h-18,size:6});
 }
 const ROOFNAME={government:'official',inn:'shop',forge:'shop',grain:'shop',school:'official',fort:'official',home:'home'};
 return {id:s.id,kind:s.kind,name:s.name,x,y,w,h,parts,roof:ROOFNAME[s.kind]||'home',public:true,door:s.door};
}

/** 县城：先放公共建筑，再沿街两排院落，块心留菜地/水塘/空地。 */
/** 巷子遇到衙门客栈要绕：把街道按公共建筑切成几段，而不是搬走建筑。 */
export function streetsFor(structures=[]){
 const publicRects=structures.map(s=>({x:s.x-3,y:s.y-3,w:s.w+6,h:s.h+6}));
 const out=[];
 for(const st of STREETS){
  const dx=st.x2-st.x1,dy=st.y2-st.y1,len=Math.hypot(dx,dy)||1;
  const inside=[];
  for(let d=0;d<=len;d+=8){
   const t=d/len,x=st.x1+dx*t,y=st.y1+dy*t;
   if(publicRects.some(r=>x>=r.x&&x<=r.x+r.w&&y>=r.y&&y<=r.y+r.h))inside.push(d);
  }
  if(!inside.length){out.push(st);continue;}
  const merged=[];let a=inside[0],b=a;
  for(const d of inside.slice(1)){if(d-b<=9)b=d;else{merged.push([a,b]);a=d;b=d;}}
  merged.push([a,b]);
  let from=0;
  for(const [a2,b2] of merged){
   if(a2-from>26){const t1=from/len,t2=a2/len;
    out.push({...st,id:st.id+'-'+out.length,x1:st.x1+dx*t1,y1:st.y1+dy*t1,x2:st.x1+dx*t2,y2:st.y1+dy*t2});}
   from=b2;
  }
  if(len-from>26){const t1=from/len;
   out.push({...st,id:st.id+'-'+out.length,x1:st.x1+dx*t1,y1:st.y1+dy*t1,x2:st.x2,y2:st.y2});}
 }
 return out;
}
/** 县城：先放公共建筑，再沿街两排院落，块心留菜地/水塘/空地。 */
/** 公共建筑压到任何一条街就往旁边让：官府客栈也不能把路堵死。 */
function avoidStreets(s){
 let {x,y,w,h}=s;
 for(const st of STREETS){
  if(Math.abs(st.x1-st.x2)<=Math.abs(st.y1-st.y2)){    // 南北向街（含微折）
   const c=(st.x1+st.x2)/2,half=st.w/2+2;
   if(x<c+half&&x+w>c-half){
    if(x+w-c<c-x)w=Math.max(60,c-half-x);
    else{const nx=c+half;w=Math.max(60,x+w-nx);x=nx;}
   }
  }else{                                              // 东西向街（含微折）
   const c=(st.y1+st.y2)/2,half=st.w/2+2;
   if(y<c+half&&y+h>c-half){
    if(y+h-c<c-y)h=Math.max(60,c-half-y);
    else{const ny=c+half;h=Math.max(60,y+h-ny);y=ny;}
   }
  }
 }
 return {...s,x,y,w,h};
}
/** 县城：先放公共建筑，再沿街两排院落，块心留菜地/水塘/空地。 */
/** 公共建筑若压到主街，就往里收一点：官府不能占着官道。 */
function avoidMainStreets(s){
 let {x,y,w,h}=s;
 const nx=-17,px=17,ny=-13,py=13;      // 南北大街半宽 17，东西大街半宽 13
 if(x<px&&x+w>nx){                     // 与南北大街相交
  if(x+w-px<nx-x){w=Math.max(70,nx-x);}    // 收东边，收到大街西沿
  else{x=px;w=Math.max(70,x+w-px);}        // 收西边，从大街东沿起
 }
 if(y<py&&y+h>ny){
  if(y+h-py<ny-y){h=Math.max(70,ny-y);}
  else{y=py;h=Math.max(70,y+h-py);}
 }
 return {...s,x,y,w,h};
}
export function layoutTown(seedStr='linan',structures=STRUCTURES){
 const out=[];const r=R(deriveSeed('town-'+seedStr));let id=0;
 for(const s of structures)out.push({...publicBuilding(s),id:'B'+(++id)});
 const free=(x,y,w,h,pad)=>!out.some(b=>x<b.x+b.w+pad&&x+w+pad>b.x&&y<b.y+b.h+pad&&y+h+pad>b.y);
 const lanes=streetsFor(structures);
 const xs=[-720,-388,0,378,720],ys=[-720,-386,0,386,720];
 let k=0;
 for(let bi=0;bi<4;bi++)for(let bj=0;bj<4;bj++){
  const bx0=xs[bi]+26,bx1=xs[bi+1]-26,by0=ys[bj]+24,by1=ys[bj+1]-24;
  if(bx1-bx0<110||by1-by0<110)continue;
  // 块内排数按进深定：一进两排不够密，三排更像县城
  const rows=Math.max(2,Math.min(3,Math.round((by1-by0)/128)));
  for(let rw=0;rw<rows;rw++){
   const side=rw===0?'north':rw===rows-1?'south':'mid';
   const rowY=by0+(by1-by0)*(rw+.5)/rows;
   let x=bx0+4+Math.floor(r()*10);
   while(x<bx1-66){
    const w=66+Math.floor(r()*24),h=60+Math.floor(r()*22);
    const setback=4+Math.floor(r()*8);
    const y=side==='north'?by0+setback:side==='south'?by1-setback-h:Math.round(rowY-h/2);
    if(y+h>by1-3||y<by0+3){x+=w+8;continue;}
    if(nearStreet(x,y,9,lanes)||nearStreet(x+w,y,9,lanes)||nearStreet(x+w/2,y,9,lanes)||nearStreet(x,y+h,9,lanes)||nearStreet(x+w,y+h,9,lanes)||nearStreet(x+w/2,y+h,9,lanes)){x+=w+10;continue;}
    if(!free(x,y,w,h,5)){x+=w+7;continue;}
    const roll=r();
    if(roll<.06)out.push({id:'G'+(++id),kind:'garden',x,y,w,h,parts:[{t:'field',x,y,w,h}],roof:'grass'});
    else if(roll<.09)out.push({id:'P'+(++id),kind:'pond',x,y,w,h,parts:[{t:'pond',x:x+6,y:y+6,w:w-12,h:h-12}],roof:'water'});
    else{
     const seedStr=deriveSeed(`c${k++}`);
     const c=compound(seedStr,x,y,w,h,r()<.2?'shop':'home',side==='north'?'north':'south');
     // 屋面分材：青瓦给殷实人家，木瓦与茅草给寻常人家，粮行仓房用灰瓦
     const pick=noise01(seedStr,'roof');
     if(c.roof==='home')c.roof=pick<.34?'official':pick<.74?'home':'thatch';
     out.push({...c,id:'B'+(++id)});
    }
    x+=w+5+Math.floor(r()*7);
   }
  }
 }
 // 行道树：沿两条大街
 for(let y=-660;y<=660;y+=90){
  if(Math.abs(y)<40)continue;
  out.push({id:'T'+y,kind:'street-tree',x:26,y,w:10,h:10,parts:[{t:'tree',x:26,y,size:6}],roof:'none'});
  out.push({id:'T2'+y,kind:'street-tree',x:-36,y,w:10,h:10,parts:[{t:'tree',x:-36,y,size:5}],roof:'none'});
 }
 return out;
}

/** 村落：沿一条土路散开，门朝路，没有城墙。 */
export function layoutVillage(seedStr='songlin',cx=6900,cy=-3500,structures=STRUCTURES){
 const out=[];const r=R(deriveSeed('vill-'+seedStr));let id=0;
 for(const s of structures)if(s.id.startsWith('songlin'))out.push({...publicBuilding(s),id:'V'+(++id)});
 const free=(x,y,w,h,pad)=>!out.some(b=>x<b.x+b.w+pad&&x+w+pad>b.x&&y<b.y+b.h+pad&&y+h+pad>b.y);
 let x=cx-420,y=cy-60;
 while(x<cx+380){
  const w=64+Math.floor(r()*26),h=60+Math.floor(r()*20);
  const dy=(r()-.5)*70,side=r()<.5?'south':'north';
  const by=side==='south'?y+dy+14:y+dy-h-14;
  if(free(x,by,w,h,12))out.push({...compound(deriveSeed(`v${x}`),x,by,w,h,r()<.25?'shop':'home',side==='south'?'south':'north'),id:'V'+(++id)});
  x+=w+18+Math.floor(r()*26);
 }
 return out;
}

// ---------- 碰撞 ----------
const _cache=new WeakMap();
function collisionSet(town){
 let c=_cache.get(town);
 if(c)return c;
 const blockers=[],gates=[];
 for(const b of town){
  if(b.kind==='garden'||b.kind==='street-tree')continue;
  for(const p of b.parts){
   if(p.t==='house'||p.t==='wing'||p.t==='stall'||p.t==='wall')blockers.push(p);
   if(p.t==='gate')gates.push(p);
   if(p.t==='pond')blockers.push(p);
  }
 }
 c={blockers,gates};_cache.set(town,c);return c;
}
/** 这个点能不能过：院墙与屋顶挡人，院门能过；院子能进（门开着才算，这里默认通）。 */
export function blockedByBuildings(town,p,pad=0){
 if(!town)return false;
 const {blockers,gates}=collisionSet(town);
 if(gates.some(g=>inRect(p,g,pad)))return false;
 return blockers.some(b=>inRect(p,b,pad));
}
export function buildingAt(buildings,p,margin=0){return buildings.find(b=>inRect(p,b,margin))||null;}
export function townReport(town){
 const houses=town.filter(b=>!b.public&&(b.kind==='home'||b.kind==='shop')).length;
 const publics=town.filter(b=>b.public).length;
 const roofs={};for(const b of town)roofs[b.roof||'home']=(roofs[b.roof||'home']||0)+1;
 return {total:town.length,houses,publics,roofs,streets:STREETS.length,blockers:collisionSet(town).blockers.length};
}
