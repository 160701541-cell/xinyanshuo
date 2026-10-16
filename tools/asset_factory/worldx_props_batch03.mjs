import {readFileSync, writeFileSync, mkdirSync, existsSync} from 'node:fs';
import {resolve} from 'node:path';
import {pathToFileURL} from 'node:url';
import {createHash} from 'node:crypto';
export const jobs = [
  {
    "id": "alchemy_furnace",
    "subject": "一只中国古代修仙青铜三足炼丹炉，带完整炉盖、双耳、炉腹和三条炉足，铜绿与暗金纹样，炉体结构清楚"
  },
  {
    "id": "smith_workbench",
    "subject": "一张中国古代炼器木工作台，台面上一个铁砧、一把铁锤和一把夹钳，完整桌腿，深棕木纹与灰黑金属"
  },
  {
    "id": "herb_drying_rack",
    "subject": "一座中国古代木制晾药架，三层竹编浅筛托盘，少量整齐摊开的草药，独立架体和四脚完整"
  },
  {
    "id": "market_stall",
    "subject": "一座中国古代小型木集市摊位，浅米色布篷、木立柱、木柜台，台面少量竹篮，完整独立摊位"
  },
  {
    "id": "wood_handcart",
    "subject": "一辆中国古代空木推车，两个木轮、完整轮轴、木车斗与两根扶手，榫卯结构合理，深棕木纹"
  },
  {
    "id": "standing_lantern",
    "subject": "一盏中国古代独立落地灯笼，暗红纸灯罩、深棕木架、四方底座和细致骨架，灯内温暖光，无文字纹样"
  }
];
export function makePrompt(job) {
 return `单件游戏道具素材。${job.subject}。纯浅灰色空白背景，单一完整物件居中，四周留空，只有物件和空白底。高清中国古风手绘插画，细致线稿与木纹金属纹，青灰、深棕、低饱和自然配色，左上方暖日光。35–45度斜俯视可见顶面与正面，真实比例，清晰边界，无景深。不要院落、房屋、树木、山水、人物、地面铺装、文字、边框、像素风、Q版、3D截图。不是场景图，不是整套物件。{{userPrompt}}。{{additionalConstraints}}`;
}
async function main() {
 const [upstream, dest] = process.argv.slice(2);
 if(!upstream || !dest) throw Error('Usage: node worldx_props_batch03.mjs WORLDX_ROOT OUTPUT_DIR');
 mkdirSync(dest,{recursive:true});
 const template=resolve(upstream,'generators/map/prompts/step1-map-generation.md');
 const original=readFileSync(template,'utf8');
 if(!/90度|90°/.test(original)) throw Error('Unexpected upstream template');
 const {loadPrompt}=await import(pathToFileURL(resolve(upstream,'generators/map/src/utils/prompt-loader.mjs')));
 for(const job of jobs) {
  const out=resolve(dest,job.id);
  // Completed generations are never silently regenerated on workflow retries.
  if(existsSync(out+'.json') && (existsSync(out+'.png')||existsSync(out+'.jpg'))) {console.log('SKIP_EXISTING',job.id);continue;}
  if(!process.env.SILICONFLOW_API_KEY) throw Error('Missing SILICONFLOW_API_KEY; zero generation calls');
  writeFileSync(template,makePrompt(job));
  const prompt=loadPrompt('step1-map-generation.md',{userPrompt:job.subject,additionalConstraints:'单件完整轮廓，禁止其他物件遮挡，保持国风手绘质感。'});
  if(/\{\{/.test(prompt)) throw Error('Unresolved WorldX prompt');
  writeFileSync(out+'.prompt.txt',prompt);
  const ledger=out+'.request.json';
  if(existsSync(ledger)) throw Error('Prior unresolved request; inspect artifacts before retrying');
  writeFileSync(ledger,JSON.stringify({id:job.id,status:'REQUEST_STARTED',at:new Date().toISOString()}));
  const response=await fetch('https://api.siliconflow.cn/v1/images/generations',{
   method:'POST',headers:{Authorization:'Bearer '+process.env.SILICONFLOW_API_KEY,'Content-Type':'application/json'},
   body:JSON.stringify({model:'Kwai-Kolors/Kolors',prompt,image_size:'1024x1024',batch_size:1}),signal:AbortSignal.timeout(150000)});
  if(!response.ok) throw Error(`Generation ${job.id}: HTTP ${response.status}; no retry`);
  const url=(await response.json()).images?.[0]?.url;
  if(!url?.startsWith('https://')) throw Error('Missing HTTPS result');
  const image=await fetch(url,{signal:AbortSignal.timeout(90000)});
  if(!image.ok) throw Error('Image download failed; no generation retry');
  const bytes=Buffer.from(await image.arrayBuffer());
  const ext=bytes.subarray(0,8).toString('hex')==='89504e470d0a1a0a'?'png':bytes.subarray(0,3).toString('hex')==='ffd8ff'?'jpg':null;
  if(!ext||bytes.length<30000) throw Error('Invalid image payload');
  writeFileSync(out+'.'+ext,bytes);
  writeFileSync(out+'.json',JSON.stringify({id:job.id,batch:'worldx-props-batch03',model:'Kwai-Kolors/Kolors',pipeline:'WorldX native prompt loader + SiliconFlow',file:job.id+'.'+ext,sha256:createHash('sha256').update(bytes).digest('hex'),upstream_commit:'edb4976de5963457dfbf5d2171355270a4ca1e79',status:'GENERATED_UNAPPROVED',reference_conditioning:false,style_control:'text_only_requires_visual_review',transparency:'NOT_CLEANED',license_status:'PROVIDER_TERMS_REVIEW_REQUIRED',run_url:process.env.RUN_URL},null,2)+'\n');
  console.log('GENERATED_UNAPPROVED',job.id,bytes.length);
 }
 writeFileSync(template,original);
}
if(process.argv[1] && import.meta.url===pathToFileURL(resolve(process.argv[1])).href) main().catch(e=>{console.error(e.message);process.exitCode=1;});
