import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {join,dirname} from 'node:path';
const ROOT=join(dirname(new URL(import.meta.url).pathname),'..');
const html=readFileSync(join(ROOT,'web/index.html'),'utf8');
const htmlIds=new Set([...html.matchAll(/id="([^"]+)"/g)].map(m=>m[1]));
const asked=new Set();
const ctxStub=new Proxy({},{get:(t,k)=>{if(k in t)return t[k];return ()=>{};},set:(t,k,v)=>{t[k]=v;return true;}});
function el(id){return{id,textContent:'',innerHTML:'',hidden:false,style:{},dataset:{},classList:{add(){},remove(){},toggle(){}},
 onclick:null,addEventListener(){},removeEventListener(){},querySelector(){return null;},querySelectorAll(){return[];},
 getBoundingClientRect:()=>({width:390,height:640,left:0,top:0}),getContext:()=>ctxStub,setPointerCapture(){},
 transaction(){const tx={};const store={get(){const r={};later(()=>r.onsuccess?.());return r;},put(){later(()=>tx.oncomplete?.());return{};}};
  tx.objectStore=()=>store;return tx;},
 objectStore(){return {get(){const r={};later(()=>r.onsuccess?.());return r;},put(){later(()=>this.oncomplete?.());}};},
 appendChild(){},focus(){},click(){},getBoundingClientRect2:undefined};}
globalThis.document={getElementById(id){asked.add(id);return el(id);},querySelectorAll(){return[];},addEventListener(){},hidden:false,visibilityState:'visible'};
globalThis.window={devicePixelRatio:2,addEventListener(){},confirm:()=>false};
globalThis.requestAnimationFrame=()=>0;
const later=fn=>setTimeout(fn,0);
globalThis.indexedDB={open(){const db={createObjectStore(){return{};},transaction(){const tx={};const store={get(){const r={};later(()=>r.onsuccess?.());return r;},put(){later(()=>tx.oncomplete?.());}};tx.objectStore=()=>store;return tx;},objectStore(){return {get(){const r={};later(()=>r.onsuccess?.());return r;},put(){}};}};
 const req={result:db};later(()=>{req.onupgradeneeded?.();req.onsuccess?.();});return req;}};
globalThis.performance={now:()=>Date.now()};
test('v0.7 浏览器入口能在无 DOM 环境下完成初始化，且引用的元素都存在于 index.html',async()=>{
 await assert.doesNotReject(()=>import('../overworld-ui.mjs?smoke=1'));
 await new Promise(r=>setTimeout(r,200));
 const missing=[...asked].filter(id=>!htmlIds.has(id));
 assert.deepEqual(missing,[],`index.html 缺少元素：${missing.join(',')}`);
 for(const id of ['worldCanvas','place','time','realmButton','staminaBar','sheet','hpBar'])assert.ok(asked.has(id),`必须使用 ${id}`);
});
