// 《仙凡共生》建筑层：地图放大到 L0/L1 要看见“真的建筑”，而不是色块。
// 每栋房子都有院墙、主屋、厢房、门、井、树；每栋都能被画出来，也能挡人。
// 全部由种子确定性生成，改一个种子整座城会变，但同一存档永远一样。
import {CITY,STRUCTURES} from './overworld.js';
const deriveSeed=(str)=>{let h=2166136261;for(let i=0;i<str.length;i++){h^=str.charCodeAt(i);h=Math.imul(h,16777619);}return h>>>0;};

/** 统一的画风底色（画布与预览图共用同一组数值，避免两套美术）。 */
export const ART={
 roof:{official:'#6d6f73',temple:'#5d5a58',home:'#8a7d68',shop:'#7d6b52',thatch:'#a8905f'},
 wall:{rammed:'#b3a288',brick:'#9d8f7a',stone:'#8d8b83',plaster:'#cfc4ac'},
 ground:{street:'#c9bda0',yard:'#c0b394',field:'#9fae74',grass:'#a9b184'},
 accent:{eaves:'#5b5347',ridge:'#4b4539',door:'#6a4f38',well:'#7c8892',tree:'#5f7a52',stall:'#b0704f'},
 ink:'#4b4539',shadow:'rgba(60,52,40,.18)'
};

const R=(s)=>{let a=s>>>0;return()=>{a=(a+0x6D2B79F5)>>>0;let t=Math.imul(a^(a>>>15),1|a);t=(t+Math.imul(t^(t>>>7),61|t))^t;return((t^(t>>>14))>>>0)/4294967296;};};

/** 城市主街：十字大街 + 四条副街。宽都是米。 */
export const STREETS=[
 {id:'main-ns',x1:0,y1:-720,x2:0,y2:720,w:34,kind:'avenue'},
 {id:'main-ew',x1:-720,y1:0,x2:720,y2:0,w:26,kind:'avenue'},
 {id:'north-lane',x1:-720,y1:-380,x2:720,y2:-380,w:14,kind:'lane'},
 {id:'south-lane',x1:-720,y1:380,x2:720,y2:380,w:14,kind:'lane'},
 {id:'west-lane',x1:-380,y1:-720,x2:-380,y2:720,w:14,kind:'lane'},
 {id:'east-lane',x1:380,y1:-720,x2:380,y2:720,w:14,kind:'lane'},
 {id:'south-market',x1:-330,y1:120,x2:330,y2:120,w:12,kind:'market'}
];

const inRect=(p,b,m=0)=>p.x>=b.x-m&&p.x<=b.x+b.w+m&&p.y>=b.y-m&&p.y<=b.y+b.h+m;
const onStreet=(x,y,r=0)=>STREETS.some(s=>{
 const minX=Math.min(s.x1,s.x2)-s.w/2-r,maxX=Math.max(s.x1,s.x2)+s.w/2+r;
 const minY=Math.min(s.y1,s.y2)-s.w/2-r,maxY=Math.max(s.y1,s.y2)+s.w/2+r;
 return x>=minX&&x<=maxX&&y>=minY&&y<=maxY;
});

/** 民居院落：院墙围合，主屋在后，门朝街，院里一口井或一棵树。 */
function compound(seed,x,y,w,h,kind='home'){
 const r=R(seed);
 const roof=kind==='shop'?'shop':(r()<.3?'thatch':'home');
 const t=8; // 院墙厚
 const parts=[];
 parts.push({t:'wall',x: x,y: y,w: w,h: t});
 parts.push({t:'wall',x: x,y: y+h-t,w: w,h: t});
 parts.push({t:'wall',x: x,y: y,w: t,h: h});
 parts.push({t:'wall',x: x+w-t,y: y,w: t,h: h});
 parts.push({t:'yard',x:x+t,y:y+t,w:w-t*2,h:h-t*2});
 const hw=w-20,hh=Math.round(h*.62);
 parts.push({t:'house',x:x+12,y:y+t, w:hw,h:hh,roof,floors:kind==='shop'?2:1,ridge:(hw>=hh?'ew':'ns')});
 if(w>=88)parts.push({t:'wing',x:x+16,y:y+t+hh+4,w:Math.round(hw*.34),h:Math.round(h*.22),roof:'home',ridge:'ns'});
 if(w>=104)parts.push({t:'wing',x:x+w-12-Math.round(hw*.3),y:y+t+hh+5,w:Math.round(hw*.3),h:Math.round(h*.22),roof:'home',ridge:'ns'});
 parts.push({t:'gate',x:x+w/2-13,y:y+h-t-1,w:26,h:t+2});
 if(r()<.5)parts.push({t:'well',x:x+w*.3,y:y+h*.74,size:4});
 if(r()<.62)parts.push({t:'tree',x:x+w*.74,y:y+h*.76,size:5+(r()*2|0)});
 return {id:'',kind,x,y,w,h,parts,roof:roof==='thatch'?'thatch':'home'};
}
/** 公共建筑：按 STRUCTURES 的占地生成更具体的形制。 */
function publicBuilding(s){
 const {x,y,w,h}=s;const parts=[{t:'yard',x:x+3,y:y+3,w:w-6,h:h-6}];
 if(s.kind==='government'){
  parts.push({t:'house',x:x+10,y:y+10,w:w-20,h:Math.round(h*.42),roof:'official',ridge:'ew'});
  parts.push({t:'house',x:x+22,y:y+Math.round(h*.55),w:w-44,h:Math.round(h*.3),roof:'official',ridge:'ew'});
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

/** 生成整座县城的建筑：按“里坊”分块排布，每坊里房屋成排、门朝街、留出菜地与空地。 */
export function layoutTown(seedStr='linan'){
 const out=[];const r=R(deriveSeed('town-'+seedStr));
 let id=0;
 for(const s of STRUCTURES)out.push({...publicBuilding(s),id:'B'+(++id)});
 // 里坊边界：由街巷切出的十六块地
 const xs=[-720,-380,0,380,720],ys=[-720,-380,0,380,720];
 for(let bi=0;bi<4;bi++)for(let bj=0;bj<4;bj++){
  const bx0=xs[bi]+28,bx1=xs[bi+1]-28,by0=ys[bj]+30,by1=ys[bj+1]-30;
  const bw=bx1-bx0,bh=by1-by0;
  if(bw<120||bh<120)continue;
  const rows=Math.max(1,Math.floor(bh/96)),cols=Math.max(1,Math.floor(bw/104));
  for(let c=0;c<cols;c++)for(let rw=0;rw<rows;rw++){
   const cellW=bw/cols,cellH=bh/rows;
   const jx=(r()-.5)*10,jy=(r()-.5)*8;
   const w=72+Math.floor(r()*22),h=68+Math.floor(r()*20);
   const x=Math.round(bx0+c*cellW+(cellW-w)/2+jx),y=Math.round(by0+rw*cellH+(cellH-h)/2+jy);
   // 空地：约 12% 的地块留作菜地或水塘，城才不像棋盘
   const skip=r();
   if(skip<.06){out.push({id:'G'+(++id),kind:'garden',x,y,w,h,parts:[{t:'field',x,y,w,h}],roof:'grass'});continue;}
   if(skip<.09){out.push({id:'P'+(++id),kind:'pond',x,y,w,h,parts:[{t:'pond',x:x+6,y:y+6,w:w-12,h:h-12}],roof:'water'});continue;}
   const hit=out.some(b=>x<b.x+b.w+6&&x+w+6>b.x&&y<b.y+b.h+6&&y+h+6>b.y);
   if(hit)continue;
   if(Math.abs(x+w/2)>700||Math.abs(y+h/2)>700)continue;
   const kind=r()<.16?'shop':'home';
   out.push({...compound(deriveSeed(`c-${bi}-${bj}-${c}-${rw}`),x,y,w,h,kind),id:'B'+(++id)});
  }
 }
 // 行道树：主街两侧，每 90 米一株，给街道一点生气
 for(let y=-660;y<=660;y+=90){
  if(Math.abs(y)<40||Math.abs(y)>660)continue;
  out.push({id:'T'+y,kind:'street-tree',x:26,y,w:10,h:10,parts:[{t:'tree',x:26,y,size:6}],roof:'none'});
  out.push({id:'T2'+y,kind:'street-tree',x:-36,y,w:10,h:10,parts:[{t:'tree',x:-36,y,size:5}],roof:'none'});
 }
 return out;
}

/** 村落：散落十几户 + 祠堂 + 木坊，没有城墙，房子沿路排。 */
export function layoutVillage(seedStr='songlin',cx=6900,cy=-3500){
 const out=[];const r=R(deriveSeed('vill-'+seedStr));let id=0;
 for(const s of STRUCTURES)if(s.id.startsWith('songlin'))out.push({...publicBuilding(s),id:'V'+(++id)});
 for(let i=0;i<16;i++){
  const ang=(i/16)*Math.PI*2,dist=90+r()*160;
  const x=Math.round(cx+Math.cos(ang)*dist),y=Math.round(cy+Math.sin(ang)*dist);
  const w=70+Math.floor(r()*16),h=66+Math.floor(r()*14);
  if(out.some(b=>x<b.x+b.w+14&&x+w+14>b.x&&y<b.y+b.h+14&&y+h+14>b.y))continue;
  out.push({...compound(deriveSeed(`v-${i}`),x,y,w,h,r()<.3?'shop':'home'),id:'V'+(++id)});
 }
 return out;
}

export function buildingAt(buildings,p,margin=0){
 return buildings.find(b=>inRect(p,b,margin))||null;
}
export function townReport(town){
 const houses=town.filter(b=>!b.public).length,publics=town.filter(b=>b.public).length;
 const roofs={};for(const b of town)roofs[b.roof||'home']=(roofs[b.roof||'home']||0)+1;
 return {total:town.length,houses,publics,roofs,streets:STREETS.length};
}
