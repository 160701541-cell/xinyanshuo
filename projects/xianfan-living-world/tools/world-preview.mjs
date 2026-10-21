// 生成整界版图预览：一界铺满 1296 块，森林/山脉只作为一个带面积与出产的地块。
// node tools/world-preview.mjs   → docs/preview/world-<realm>.svg
import fs from 'node:fs';
import {generateRealm} from '../worldmap.mjs';

const EXTENT=1_350_000, GRID=216, S=1000, PX=S/(EXTENT*2);
const [realm]=process.argv.slice(2);
const realms=realm?[realm]:['mortal','xian'];
for(const r of realms){
 const lines=[];
 const g=generateRealm({realm:r,grid:GRID});
 const byId=g.regions; // owner 里存的是 1 起的下标

 const f=(v)=>v.toFixed(1);
 lines.push(`<svg xmlns="http://www.w3.org/2000/svg" width="${S}" height="${S}" viewBox="0 0 ${S} ${S}">`);
 lines.push(`<rect width="${S}" height="${S}" fill="#e9e2c8"/>`);
 const cw=EXTENT*2/GRID;
 for(let j=0;j<GRID;j++)for(let i=0;i<GRID;i++){
  const v=g.owner[j*GRID+i];
  if(!v)continue;
  const rg=byId[v-1];
  const px=(i+0.5)*cw-EXTENT, py=(j+0.5)*cw-EXTENT;
  lines.push(`<rect x="${f((px+EXTENT)*PX-cw*PX/2)}" y="${f((py+EXTENT)*PX-cw*PX/2)}" width="${f(cw*PX+0.4)}" height="${f(cw*PX+0.4)}" fill="${rg.color}"/>`);
 }
 // 州县与宗门标记
 for(const c of [['临安县城',0,0,'#7a5a48'],...(r==='xian'?[['青云山城',11_300,-7_200,'#4a6a80'],['灵山药市',12_000,-8_100,'#4a6a80']]:[])]){
  const x=(c[1]+EXTENT)*PX,y=(c[2]+EXTENT)*PX;
  lines.push(`<circle cx="${f(x)}" cy="${f(y)}" r="3.4" fill="${c[3]}" stroke="#fff8e8" stroke-width="1.4"/>`);
  lines.push(`<text x="${f(x+6)}" y="${f(y+3.5)}" font-size="11" fill="#3a3326" paint-order="stroke" stroke="#f6efdc" stroke-width="2.6">${c[0]}</text>`);
 }
 // 大地块名字：取面积最大的 18 块
 const big=[...g.regions].sort((a,b)=>b.areaKm2-a.areaKm2).slice(0,16);
 for(const rg of big){
  const x=(rg.x+EXTENT)*PX,y=(rg.y+EXTENT)*PX;
  if(y<66||y>S-70||x<70||x>S-70)continue;
  lines.push(`<text x="${f(x)}" y="${f(y)}" font-size="10.5" text-anchor="middle" fill="#38301f" paint-order="stroke" stroke="#f6efdc" stroke-width="2.4">${rg.name}</text>`);
 }
 // 标题与统计
 lines.push(`<rect x="0" y="0" width="${S}" height="44" fill="#f6efdc" fill-opacity=".86"/>`);
 lines.push(`<text x="14" y="20" font-size="16" fill="#2e281c">${r==='mortal'?'凡界·大宁王畿':'仙界·青云山脉'}　2700 × 2700 公里</text>`);
 lines.push(`<text x="14" y="37" font-size="11" fill="#5a5040">${g.regions.length} 块地铺满　·　${(g.totalKm2/10000).toFixed(0)} 万平方公里</text>`);
 // 图例
 const byLand=new Map();
 for(const rg of g.regions){const c=byLand.get(rg.land)||{land:rg.land,color:rg.color,count:0,areaKm2:0};c.count++;c.areaKm2+=rg.areaKm2;byLand.set(rg.land,c);}
 const kinds=[...byLand.values()].sort((a,b)=>b.areaKm2-a.areaKm2);
 lines.push(`<rect x="14" y="${S-24-kinds.length*17-10}" width="176" height="${kinds.length*17+16}" fill="#f6efdc" fill-opacity=".9"/>`);
 kinds.forEach((k,i)=>{
  const y=S-24-(kinds.length-i)*17;
  lines.push(`<rect x="22" y="${y}" width="12" height="10" fill="${k.color}"/>`);
  lines.push(`<text x="40" y="${y+9}" font-size="10.5" fill="#3a3326">${k.land}　${k.count}块</text>`);
 });
 lines.push('</svg>');
 fs.writeFileSync(`docs/preview/world-${r}.svg`,lines.join('\n'));
 console.log(`wrote world-${r}.svg`,lines.length);
}
function cellsLedger(g,byId){
 const by=new Map();
 for(let i=0;i<g.owner.length;i++){
  const v=g.owner[i];if(!v)continue;
  const id=byId[v-1].id;
  let c=by.get(id);if(!c){c={...byId[v-1],count:0,areaKm2:0};by.set(id,c);}
  c.count++;
 }
 return [...by.values()];
}
