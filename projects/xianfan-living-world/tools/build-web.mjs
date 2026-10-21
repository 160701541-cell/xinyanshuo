#!/usr/bin/env node
/** 把 .mjs 源码发布为 web/ 下的浏览器模块，并校验没有残留 .mjs 导入。漂移即报错。 */
import {readFileSync,writeFileSync,mkdirSync} from 'node:fs';
import {join,dirname} from 'node:path';
const ROOT=join(dirname(new URL(import.meta.url).pathname),'..');
const FILES=['core','spatial','overworld','atlas','gesture','overworld-ui'];
const OUT=join(ROOT,'web');mkdirSync(OUT,{recursive:true});
let bad=0;
for(const name of FILES){
 const src=readFileSync(join(ROOT,name+'.mjs'),'utf8');
 const out=src.replace(/from '\.\/([a-z0-9-]+)\.mjs'/g,"from './$1.js'");
 if(/\.mjs'/.test(out)){console.error(`[build-web] ${name}.mjs 仍残留 .mjs 导入`);bad++;}
 writeFileSync(join(OUT,name+'.js'),out);
 console.log(`[build-web] ${name}.mjs -> web/${name}.js (${out.length} bytes)`);
}
process.exit(bad?1:0);
