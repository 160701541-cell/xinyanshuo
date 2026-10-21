#!/usr/bin/env node
/**
 * 素材流水线（纯 SVG，零依赖、确定性、可整批重出）：
 *   小人 = 底衣层(族色×发式×体型) + 头饰层 + 持物层，运行时叠三层即可组合出上千种外观，
 *   但不产生上千个文件。物品同理，一件一个图标。
 * 用法：node tools/make-sprites.mjs   → assets/sprites/{people,hats,held,items}/*.svg + manifest.json
 */
import {mkdirSync,writeFileSync,readdirSync,unlinkSync} from 'node:fs';
import {join,dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
import {ITEMS} from '../society.mjs';

const ROOT=join(dirname(fileURLToPath(import.meta.url)),'..');
const OUT=join(ROOT,'assets','sprites');
const S_VERSION='sprites-0.2.0';
const W=32,H=44;

const PALETTES=[
 {id:'official',name:'官',robe:'#4a5a76',trim:'#c9b071',skin:'#e6c9a8',hair:'#26262b'},
 {id:'merchant',name:'商',robe:'#7d5a3a',trim:'#d8b06a',skin:'#e5c6a4',hair:'#2b241f'},
 {id:'farmer',name:'农',robe:'#6f7a52',trim:'#c6bda1',skin:'#e0c09a',hair:'#2a2622'},
 {id:'cultivator',name:'道',robe:'#7fa2b4',trim:'#e8eef0',skin:'#ead2b6',hair:'#1f2026'},
 {id:'guard',name:'军',robe:'#6a5f80',trim:'#b9a86a',skin:'#e3c5a2',hair:'#23202a'},
 {id:'wanderer',name:'流',robe:'#8a7a63',trim:'#cfc1a3',skin:'#dcbc96',hair:'#2d2620'},
 {id:'child',name:'童',robe:'#b08a6a',trim:'#f0dcc0',skin:'#f0d2b0',hair:'#332a24'},
 {id:'noble',name:'贵',robe:'#8d3b3b',trim:'#e0c47a',skin:'#eccdb0',hair:'#241f26'},
];
const HAIR=[{id:'bun',name:'髻'},{id:'topknot',name:'束发'},{id:'loose',name:'披发'},{id:'shaved',name:'僧'}];
const HATS=[{id:'none',name:'无'},{id:'scarf',name:'巾'},{id:'straw',name:'笠'},{id:'crown',name:'冠'}];
const HELD=[{id:'none',name:'空手'},{id:'sword',name:'剑'},{id:'basket',name:'篮'},{id:'staff',name:'杖'},{id:'book',name:'卷'}];
const SHAPE=[{id:'slim',name:'瘦'},{id:'stout',name:'壮'},{id:'small',name:'矮'}];

const wrap=inner=>`<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${inner}</svg>`;

function baseSvg(p,h,shape){
 const wide=shape==='stout'?1.18:shape==='small'?.9:1, scale=shape==='small'?.92:1, bodyW=13*wide, top=14*scale;
 return wrap(`<g transform="translate(16 42) scale(${scale}) translate(-16 -42)">
 <ellipse cx="16" cy="40.4" rx="9" ry="2.4" fill="#20201c" opacity=".18"/>
 <rect x="12.1" y="30" width="3" height="9" rx="1.3" fill="${p.robe}" opacity=".85"/>
 <rect x="16.6" y="30" width="3" height="9" rx="1.3" fill="${p.robe}" opacity=".85"/>
 <rect x="12.1" y="38" width="3" height="2" rx=".9" fill="#3b332a"/>
 <rect x="16.6" y="38" width="3" height="2" rx=".9" fill="#3b332a"/>
 <path d="M${(16-bodyW+2).toFixed(1)} 32 L${(16-bodyW).toFixed(1)} 20 Q16 ${top-2} ${(16+bodyW).toFixed(1)} 20 L${(16+bodyW-2).toFixed(1)} 32 Z" fill="${p.robe}"/>
 <path d="M${(16-bodyW+2).toFixed(1)} 30 L${(16+bodyW-2).toFixed(1)} 30 L${(16+bodyW-3).toFixed(1)} 33 L${(16-bodyW+3).toFixed(1)} 33 Z" fill="${p.trim}" opacity=".9"/>
 <rect x="14.4" y="19.5" width="3.2" height="12" fill="${p.trim}" opacity=".5"/>
 <circle cx="11.9" cy="27.4" r="2.7" fill="${p.robe}"/>
 <circle cx="20.1" cy="27.4" r="2.7" fill="${p.robe}"/>
 <circle cx="11.9" cy="29.4" r="1.6" fill="${p.skin}"/>
 <circle cx="20.1" cy="29.4" r="1.6" fill="${p.skin}"/>
 <circle cx="16" cy="12" r="6.4" fill="${p.skin}"/>
 <circle cx="13.7" cy="11.6" r=".72" fill="#2b2b31"/><circle cx="18.3" cy="11.6" r=".72" fill="#2b2b31"/>
 <path d="M13.4 15.2 Q16 16.7 18.6 15.2" stroke="#a4614f" stroke-width=".85" fill="none" stroke-linecap="round"/>
 ${h.id==='bun'?`<path d="M9.6 10.2 Q16 2.6 22.4 10.2 Q16 7 9.6 10.2" fill="${p.hair}"/><circle cx="16" cy="4.4" r="2.5" fill="${p.hair}"/>`:''}
 ${h.id==='topknot'?`<path d="M9.6 10.2 Q16 3.6 22.4 10.2 Q16 7.4 9.6 10.2" fill="${p.hair}"/><rect x="14.3" y="1.9" width="3.4" height="3.1" rx="1" fill="${p.hair}"/>`:''}
 ${h.id==='loose'?`<path d="M9.6 9.8 Q16 3.4 22.4 9.8 Q16 7.4 9.6 9.8" fill="${p.hair}"/><path d="M9.8 9.6 q-2 5.8 -.6 11.2 l2.8 .4 q-1.6 -5.8 .2 -11.2 Z" fill="${p.hair}"/><path d="M22.2 9.6 q2 5.8 .6 11.2 l-2.8 .4 q1.6 -5.8 -.2 -11.2 Z" fill="${p.hair}"/>`:''}
 ${h.id==='shaved'?`<path d="M10.4 9.8 Q16 6.4 21.6 9.8 Q16 8.2 10.4 9.8" fill="${p.hair}" opacity=".5"/>`:''}
</g>`);
}
function hatSvg(id,trim){
 if(id==='scarf')return wrap(`<path d="M8.8 9.4 Q16 4.2 23.2 9.4 Q16 7.4 8.8 9.4" fill="${trim}"/><path d="M8.8 9.4 Q6.2 13 8.2 16.6 L10.1 15.2 Q9 12.6 10.1 10.6 Z" fill="${trim}"/>`);
 if(id==='straw')return wrap(`<path d="M4.6 10.6 Q16 -1.6 27.4 10.6 Q16 8 4.6 10.6" fill="#c9a96b"/><path d="M12.8 3.4 Q16 .6 19.2 3.4 Z" fill="#b08c55"/><path d="M6 10.2 Q16 6.4 26 10.2" stroke="#9c7f4d" stroke-width=".8" fill="none"/>`);
 if(id==='crown')return wrap(`<rect x="12.4" y="1.2" width="7.2" height="3.8" rx="1" fill="${trim}" stroke="#9c7b3c" stroke-width=".5"/><rect x="15.4" y="-.9" width="1.2" height="2.4" fill="${trim}"/><rect x="12.8" y="2.2" width="6.4" height=".6" fill="#9c7b3c" opacity=".7"/>`);
 return wrap('');
}
function heldSvg(id,trim){
 if(id==='sword')return wrap(`<rect x="23.3" y="13.5" width="1.9" height="18.5" fill="#dfe4e9" stroke="#8b929a" stroke-width=".5"/><rect x="22.4" y="31.4" width="3.8" height="1.5" rx=".4" fill="${trim}"/><rect x="23.9" y="32.9" width=".8" height="4" fill="#6d4f30"/>`);
 if(id==='basket')return wrap(`<path d="M22.4 24 h6.8 l-1.3 6.4 h-4.2 Z" fill="#bd9a63" stroke="#8f7040" stroke-width=".55"/><path d="M23.3 24 q2.5 -3.4 5 0" stroke="#8f7040" stroke-width=".9" fill="none"/><path d="M23.4 26.6 h4.8" stroke="#8f7040" stroke-width=".5"/>`);
 if(id==='staff')return wrap(`<rect x="23.5" y="7.5" width="1.6" height="30.5" rx=".8" fill="#9a7a4e"/><circle cx="24.3" cy="7" r="2.1" fill="#c8b07a" stroke="#8a713f" stroke-width=".5"/>`);
 if(id==='book')return wrap(`<rect x="21.2" y="24.8" width="6.6" height="4.6" rx=".7" fill="#efe6d2" stroke="#b7a684" stroke-width=".55"/><rect x="22.1" y="26.1" width="4.8" height=".55" fill="#b7a684"/><rect x="22.1" y="27.4" width="4.8" height=".55" fill="#b7a684"/>`);
 return wrap('');
}
const ITEM_SHAPES={
 food:`<path d="M6 12 h20 l-2 14 h-16 Z" fill="#e2cd9d" stroke="#a98d5c" stroke-width="1.2"/><path d="M6 12 q10 -5 20 0" fill="none" stroke="#a98d5c" stroke-width="1.4"/>`,
 craft:`<path d="M5 16 h22 v10 h-22 Z" fill="#cbb287" stroke="#8f764c" stroke-width="1.3"/><path d="M5 21 h22" stroke="#8f764c" stroke-width="1.2"/>`,
 medicine:`<g transform="rotate(-24 16 20)"><rect x="8.5" y="16" width="15" height="8" rx="4" fill="#d8a7a0" stroke="#9a5f57" stroke-width="1.3"/><path d="M16 16 v8" stroke="#9a5f57" stroke-width="1.1"/></g>`,
 ritual:`<rect x="9" y="8" width="14" height="22" rx="1.5" fill="#e8d287" stroke="#a88c3f" stroke-width="1.3"/><path d="M12 13 h8 M12 18 h8 M12 23 h5" stroke="#a8642f" stroke-width="1.2"/>`,
 tool:`<rect x="7" y="22" width="12" height="4" rx="2" fill="#8a6a44"/><path d="M19 24 l7 -12 l3 2 l-7 12 Z" fill="#cfd4d8" stroke="#8b929a" stroke-width="1"/>`,
 weapon:`<rect x="15" y="4" width="2.6" height="18" fill="#dfe4e9" stroke="#8b929a" stroke-width=".8"/><rect x="11.6" y="21.6" width="9.4" height="2.2" fill="#b08a4e"/><rect x="14.4" y="23.8" width="3" height="6" rx="1.2" fill="#7a5a34"/>`,
};
const ITEM_TINT={food:'#e6d3a6',craft:'#cfb98f',medicine:'#d8a7a0',ritual:'#e8d287',tool:'#a98d5c',weapon:'#cdd3d8'};
const itemSvg=it=>`<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32"><rect width="32" height="32" rx="6" fill="${ITEM_TINT[it.kind]||'#d9c9a3'}" opacity=".22"/>${ITEM_SHAPES[it.kind]||ITEM_SHAPES.craft}</svg>`;

function reset(dir){mkdirSync(dir,{recursive:true});for(const f of readdirSync(dir))if(f.endsWith('.svg'))unlinkSync(join(dir,f));}
const dirs={people:join(OUT,'people'),hats:join(OUT,'hats'),held:join(OUT,'held'),items:join(OUT,'items')};
for(const d of Object.values(dirs))reset(d);

const manifest={version:S_VERSION,size:{w:W,h:H},palettes:PALETTES,hair:HAIR,hats:HATS,held:HELD,shapes:SHAPE,people:[],hatLayers:[],heldLayers:[],items:[]};
for(const p of PALETTES)for(const h of HAIR)for(const shape of SHAPE){
 const id=`${p.id}_${h.id}_${shape.id}`;
 writeFileSync(join(dirs.people,id+'.svg'),baseSvg(p,h,shape));
 manifest.people.push({id,file:`people/${id}.svg`,traits:{palette:p.id,hair:h.id,shape}});
}
for(const hat of HATS){
 const file=`hats/${hat.id}.svg`;
 writeFileSync(join(dirs.hats,hat.id+'.svg'),hatSvg(hat.id,'#d8c9a8'));
 manifest.hatLayers.push({id:hat.id,name:hat.name,file});
}
for(const h of HELD){
 const file=`held/${h.id}.svg`;
 writeFileSync(join(dirs.held,h.id+'.svg'),heldSvg(h.id,'#c9b071'));
 manifest.heldLayers.push({id:h.id,name:h.name,file});
}
for(const it of ITEMS){
 writeFileSync(join(dirs.items,it.id+'.svg'),itemSvg(it));
 manifest.items.push({id:it.id,name:it.name,kind:it.kind,kindLabel:it.kind,file:`items/${it.id}.svg`});
}
writeFileSync(join(OUT,'manifest.json'),JSON.stringify(manifest,null,1));
console.log(`sprites ${S_VERSION}: ${manifest.people.length} base + ${manifest.hatLayers.length} hats + ${manifest.heldLayers.length} held + ${manifest.items.length} items`);
