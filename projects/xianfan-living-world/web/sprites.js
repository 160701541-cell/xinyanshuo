/** 素材选择层：只把人物档案映射到「底衣层/头饰层/持物层」，不生成新人物。纯函数，可测试。 */
import {deriveSeed} from './core.js';

export const PALETTE_BY_JOB=[
 [/修士|丹师|剑修|杂役/, 'cultivator'],
 [/县吏|捕快|衙役|书吏/, 'official'],
 [/商贩|账房|粮行伙计|掌柜|牙人/, 'merchant'],
 [/农户|织工|木匠|脚夫|郎中|船工|渔户|铁匠/, 'farmer'],
 [/孩童|学童/, 'child'],
 [/居家养老/, 'wanderer'],
];
export function paletteFor(p){
 if(!p)return 'wanderer';
 if(p.age<14)return 'child';
 if((p.wealth??0)>200)return 'noble';
 for(const [re,id] of PALETTE_BY_JOB)if(re.test(p.job||''))return id;
 if(p.role==='修士')return 'cultivator';
 return 'wanderer';
}
export const HAT_BY_PALETTE={official:'crown',merchant:'scarf',farmer:'straw',cultivator:'none',guard:'crown',wanderer:'none',child:'none',noble:'crown'};
export const HELD_BY_PALETTE={official:'book',merchant:'book',farmer:'basket',cultivator:'sword',guard:'sword',wanderer:'staff',child:'none',noble:'book'};
export function hairFor(p,palette){
 const seed=deriveSeed('hair-'+(p?.id||'x'));
 if(palette==='cultivator')return 'topknot';
 if(/僧|尼/.test(p?.job||''))return 'shaved';
 if(p?.sex==='女')return seed%3===0?'bun':'loose';
 return seed%5===0?'topknot':'bun';
}
export function shapeFor(p,palette){
 if(palette==='child')return 'small';
 if(/脚夫|木匠|铁匠|船工/.test(p?.job||''))return 'stout';
 return 'slim';
}
export function lookFor(p){
 const palette=paletteFor(p);
 return {palette,hair:hairFor(p,palette),hat:HAT_BY_PALETTE[palette]||'none',held:HELD_BY_PALETTE[palette]||'none',shape:shapeFor(p,palette)};
}
export const baseKey=l=>`${l.palette}_${l.hair}_${l.shape}`;

/** 浏览器侧缓存：加载 manifest 与三层图片，缺图时返回 null 让调用方退回圆形标记。 */
export class SpriteBank{
 constructor(base='sprites/'){this.base=base;this.ready=false;this.files=new Map();this.images=new Map();}
 async load(){
  try{
   const res=await fetch(this.base+'manifest.json');if(!res.ok)return false;
   const m=await res.json();
   for(const p of m.people)this.files.set(`base:${p.id}`,p.file);
   for(const h of m.hatLayers)this.files.set(`hat:${h.id}`,h.file);
   for(const h of m.heldLayers)this.files.set(`held:${h.id}`,h.file);
   for(const it of m.items)this.files.set(`item:${it.id}`,it.file);
   this.manifest=m;this.ready=true;return true;
  }catch{return false;}
 }
 image(kind,id){
  const key=`${kind}:${id}`;const file=this.files.get(key)||this.files.get(`${kind}:none`);
  if(!file)return null;
  let img=this.images.get(file);
  if(img)return img.complete&&img.naturalWidth?img:null;
  img=new Image();img.src=this.base+file;this.images.set(file,img);
  return null;
 }
 layers(p){
  const look=lookFor(p);
  return {look,base:this.image('base',baseKey(look)),hat:look.hat==='none'?null:this.image('hat',look.hat),held:look.held==='none'?null:this.image('held',look.held)};
 }
 item(id){return this.image('item',id);}
}
