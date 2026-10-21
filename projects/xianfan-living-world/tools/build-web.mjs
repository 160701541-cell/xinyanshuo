#!/usr/bin/env node
/** 把 .mjs 源码发布为 web/ 下的浏览器模块，并校验没有残留 .mjs 导入。漂移即报错。 */
import {readFileSync,writeFileSync,mkdirSync,copyFileSync,readdirSync} from 'node:fs';
import {join,dirname} from 'node:path';
const ROOT=join(dirname(new URL(import.meta.url).pathname),'..');
const FILES=['core','spatial','society','sprites','war','units','overworld','atlas','gesture','overworld-ui'];
const OUT=join(ROOT,'web');mkdirSync(OUT,{recursive:true});
let bad=0;
for(const name of FILES){
 const src=readFileSync(join(ROOT,name+'.mjs'),'utf8');
 const out=src.replace(/from '\.\/([a-z0-9-]+)\.mjs'/g,"from './$1.js'");
 if(/\.mjs'/.test(out)){console.error(`[build-web] ${name}.mjs 仍残留 .mjs 导入`);bad++;}
 writeFileSync(join(OUT,name+'.js'),out);
 console.log(`[build-web] ${name}.mjs -> web/${name}.js (${out.length} bytes)`);
}
// 页面与样式同样是产物：源文件在根目录，构建时复制，避免只改 web/ 造成的漂移。
for(const [from,to] of [['overworld.html','index.html'],['overworld.css','overworld.css']]){
 const text=readFileSync(join(ROOT,from),'utf8');
 if(/\.mjs["']/.test(text)){console.error(`[build-web] ${from} 仍引用 .mjs`);bad++;}
 writeFileSync(join(OUT,to),to==='index.html'?text.replace('<script type="module" src="overworld-ui.js">','<script type="module" src="overworld-ui.js">'):text);
 console.log(`[build-web] ${from} -> web/${to}`);
}
// 素材：整批复制到 web/sprites/，页面用相对路径取用。
mkdirSync(join(OUT,'sprites'),{recursive:true});
const copyTree=(from,to)=>{mkdirSync(to,{recursive:true});for(const e of readdirSync(from,{withFileTypes:true})){const a=join(from,e.name),b=join(to,e.name);if(e.isDirectory())copyTree(a,b);else copyFileSync(a,b);}};
copyTree(join(ROOT,'assets','sprites'),join(OUT,'sprites'));
console.log('[build-web] assets/sprites -> web/sprites');
process.exit(bad?1:0);
