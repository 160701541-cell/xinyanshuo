// 生成县城地图预览（SVG）：直接吃 buildings.mjs 的真实布局，保证预览与游戏同源。
// 用法：node tools/town-preview.mjs [输出.svg]   （有 rsvg-convert 时可再转 PNG）
import fs from 'node:fs';
import {layoutTown,streetsFor,ART} from '../buildings.mjs';
import {STRUCTURES} from '../overworld.mjs';

const town=layoutTown('linan',STRUCTURES);
const STREETS=streetsFor(STRUCTURES);
const S=0.78, OX=830, OY=830;             // 0.78 px/米，画 1660 米见方
const W=Math.round(1660*S), H=W;
const px=x=>(OX+x)*S*1.0/1.0, py=y=>(OY+y)*S;
const P=(x,y)=>`${(px(x)).toFixed(1)},${(py(y)).toFixed(1)}`;
const box=(x,y,w,h)=>`${(px(x)).toFixed(1)},${(py(y)).toFixed(1)} ${(w*S).toFixed(1)},${(h*S).toFixed(1)}`;
const shade=(hex,d)=>{const n=parseInt(hex.slice(1),16);const c=[(n>>16)+d,((n>>8)&255)+d,(n&255)+d].map(v=>Math.max(0,Math.min(255,v))|0);return `rgb(${c[0]},${c[1]},${c[2]})`;};
const roofC={official:'#6d6f73',temple:'#5d5a58',home:'#8a7d68',shop:'#7d6b52',thatch:'#a8905f'};
const out=[];
out.push(`<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">`);
out.push(`<rect width="${W}" height="${H}" fill="#a3ab80"/>`);
// 细密地纹
out.push(`<defs><pattern id="grass" width="9" height="9" patternUnits="userSpaceOnUse"><path d="M0 4.5h9M4.5 0v9" stroke="#9ba377" stroke-width="0.7"/></pattern></defs>`);
out.push(`<rect width="${W}" height="${H}" fill="url(#grass)" opacity=".5"/>`);
// 街巷
for(const s of STREETS){
 const w=Math.max(2,s.w*S);
 out.push(`<line x1="${px(s.x1)}" y1="${py(s.y1)}" x2="${px(s.x2)}" y2="${py(s.y2)}" stroke="#cbbfa2" stroke-width="${w}" stroke-linecap="butt"/>`);
 out.push(`<line x1="${px(s.x1)}" y1="${py(s.y1)}" x2="${px(s.x2)}" y2="${py(s.y2)}" stroke="#d6cbb0" stroke-width="${Math.max(1,w-3)}" stroke-linecap="butt"/>`);
}
// 城墙与垛口
const C=720;
out.push(`<rect x="${px(-C)}" y="${py(-C)}" width="${2*C*S}" height="${2*C*S}" fill="none" stroke="#968f80" stroke-width="${26*S}"/>`);
out.push(`<rect x="${px(-C)}" y="${py(-C)}" width="${2*C*S}" height="${2*C*S}" fill="none" stroke="#c6bda6" stroke-width="1.5"/>`);
for(let t=-700;t<=700;t+=34){
 out.push(`<rect x="${px(t)-3}" y="${py(-C)-5}" width="6" height="10" fill="#968f80"/>`);
 out.push(`<rect x="${px(t)-3}" y="${py(C)-5}" width="6" height="10" fill="#968f80"/>`);
 out.push(`<rect x="${px(-C)-5}" y="${py(t)-3}" width="10" height="6" fill="#968f80"/>`);
 out.push(`<rect x="${px(C)-5}" y="${py(t)-3}" width="10" height="6" fill="#968f80"/>`);
}
for(const g of [[0,-720],[0,720],[-720,0],[720,0]])
 out.push(`<rect x="${px(g[0])-11*S}" y="${py(g[1])-7*S}" width="${22*S}" height="${14*S}" fill="#cbbfa2" stroke="#968f80" stroke-width="2"/>`);

function roof(x,y,w,h,name,ridgeNs){
 const base=roofC[name]||roofC.home, light=shade(base,9), dark=shade(base,-7);
 out.push(`<rect x="${px(x)+2}" y="${py(y)+3}" width="${w*S}" height="${h*S}" fill="rgba(60,52,40,.20)"/>`);
 out.push(`<rect x="${px(x)}" y="${py(y)}" width="${w*S}" height="${h*S}" fill="${dark}" stroke="#4b4539" stroke-width="1.1"/>`);
 if(ridgeNs)out.push(`<rect x="${px(x)}" y="${py(y)}" width="${w*S/2}" height="${h*S}" fill="${light}"/>`);
 else out.push(`<rect x="${px(x)}" y="${py(y)}" width="${w*S}" height="${h*S/2}" fill="${light}"/>`);
 const lw=0.9;
 if(ridgeNs)out.push(`<line x1="${px(x+w/2)}" y1="${py(y)}" x2="${px(x+w/2)}" y2="${py(y+h)}" stroke="#3f3a30" stroke-width="${lw}"/>`);
 else out.push(`<line x1="${px(x)}" y1="${py(y+h/2)}" x2="${px(x+w)}" y2="${py(y+h/2)}" stroke="#3f3a30" stroke-width="${lw}"/>`);
 out.push(`<rect x="${px(x)}" y="${py(y+h-1.6)}" width="${w*S}" height="${1.6*S}" fill="rgba(60,52,40,.22)"/>`);
 out.push(`<rect x="${px(x)+1}" y="${py(y)+1}" width="${w*S-2}" height="${h*S-2}" fill="none" stroke="rgba(46,42,34,.45)" stroke-width="1.2"/>`);
}
function part(p){
 const t=p.t,x=p.x,y=p.y,w=p.w||0,h=p.h||0;
 if(t==='yard')out.push(`<rect x="${px(x)}" y="${py(y)}" width="${w*S}" height="${h*S}" fill="#cbbfa0"/>`);
 else if(t==='wall')out.push(`<rect x="${px(x)}" y="${py(y)}" width="${w*S}" height="${h*S}" fill="#a68f70" stroke="#78664f" stroke-width="0.8"/>`);
 else if(t==='house'||t==='wing'){out.push(`<rect x="${px(x)-1.5}" y="${py(y)-1.5}" width="${w*S+3}" height="${h*S+3}" fill="#96876e"/>`);roof(x,y,w,h,p.roof||'home',(p.ridge||'ns')==='ns');}
 else if(t==='gate')out.push(`<rect x="${px(x)}" y="${py(y)}" width="${w*S}" height="${h*S}" fill="#6a4f38" stroke="#4b4539" stroke-width="0.8"/>`);
 else if(t==='well')out.push(`<circle cx="${px(x)}" cy="${py(y)}" r="${3.2*S+1.6}" fill="#7c8892" stroke="#4b4539" stroke-width="0.8"/>`);
 else if(t==='tree'){const r=(p.size||5)*S*1.15;
  out.push(`<ellipse cx="${px(x)+r*.3}" cy="${py(y)+r*.55}" rx="${r*.9}" ry="${r*.55}" fill="rgba(60,52,40,.22)"/>`);
  out.push(`<circle cx="${px(x)}" cy="${py(y)}" r="${r}" fill="#688458" stroke="#46583a" stroke-width="0.8"/>`);
  out.push(`<circle cx="${px(x)-r*.25}" cy="${py(y)-r*.28}" r="${r*.5}" fill="#7e9a68"/>`);}
 else if(t==='stall')out.push(`<rect x="${px(x)}" y="${py(y)}" width="${w*S}" height="${h*S}" fill="#b0704f" stroke="#4b4539" stroke-width="0.8"/>`);
 else if(t==='field'){out.push(`<rect x="${px(x)}" y="${py(y)}" width="${w*S}" height="${h*S}" fill="#9fae74"/>`);
  for(let fx=x+2;fx<x+w;fx+=3.2)out.push(`<line x1="${px(fx)}" y1="${py(y+2)}" x2="${px(fx)}" y2="${py(y+h-2)}" stroke="#8c9d62" stroke-width="0.9"/>`);}
 else if(t==='pond'){out.push(`<ellipse cx="${px(x+w/2)}" cy="${py(y+h/2)}" rx="${w*S/2}" ry="${h*S/2}" fill="#7ea0a6" stroke="#608890" stroke-width="1.2"/>`);}
}
for(const b of [...town].sort((a,b)=>a.y+a.h*.75-(b.y+b.h*.75))){
 if(b.kind==='street-tree'){for(const p of b.parts)part(p);continue;}
 for(const p of b.parts)part(p);
}
out.push('</svg>');
const file=process.argv[2]||'docs/preview/town-preview.svg';
fs.writeFileSync(file,out.join('\n'));
console.log(`wrote ${file}: ${town.length} buildings, ${W}x${H}`);
