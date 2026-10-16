import {readFileSync, writeFileSync, mkdirSync, existsSync} from 'node:fs';
import {resolve} from 'node:path';
import {pathToFileURL} from 'node:url';
import {createHash} from 'node:crypto';
export const jobs = [
 {id:'courtyard_gate_closed', subject:'一座独立中国古代四合院院门，关闭的深棕双扇木门，青灰瓦小门楼，完整门框与石门槛；仅门两侧必要的短墙，不含院落、人物和植被'},
 {id:'village_stone_well', subject:'一口独立中国古代村落石井，灰石圆形井栏，深棕木架、辘轳、粗绳和一个木桶；绳子连接合理，井口透视正确；不含房屋、院落、人物和植被'}
];
export function makePrompt(job) {
 return `为《苍岚·人生世界》绘制独立游戏素材候选原图。唯一主体：${job.subject}。精细中国古风手绘国漫插画，灰青石材与瓦片、深棕木纹，低饱和自然色，温暖柔和日光从左上照射。35–45度斜俯视，同时可见正面与顶面，真实比例，细致线稿、清晰材质，无景深模糊。单一物件居中，完整轮廓，四周至少10%均匀浅灰留白，无背景风景、地面大阴影、文字、水印、UI、边框。禁止像素风、Q版、欧美奇幻、现代物品、塑料、写实3D截图、90度平面图、棋盘格伪透明。纯色背景供后续精修抠图，不声称透明完成。用户要求：{{userPrompt}}。附加约束：{{additionalConstraints}}`;
}
async function main() {
 const [upstream, dest] = process.argv.slice(2);
 if(!upstream || !dest) throw Error('Usage: node worldx_props_batch02.mjs WORLDX_ROOT OUTPUT_DIR');
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
  writeFileSync(out+'.json',JSON.stringify({id:job.id,batch:'worldx-props-batch02',model:'Kwai-Kolors/Kolors',pipeline:'WorldX native prompt loader + SiliconFlow',file:job.id+'.'+ext,sha256:createHash('sha256').update(bytes).digest('hex'),upstream_commit:'edb4976de5963457dfbf5d2171355270a4ca1e79',status:'GENERATED_UNAPPROVED',reference_conditioning:false,style_control:'text_only_requires_visual_review',transparency:'NOT_CLEANED',license_status:'PROVIDER_TERMS_REVIEW_REQUIRED',run_url:process.env.RUN_URL},null,2)+'\n');
  console.log('GENERATED_UNAPPROVED',job.id,bytes.length);
 }
 writeFileSync(template,original);
}
if(process.argv[1] && import.meta.url===pathToFileURL(resolve(process.argv[1])).href) main().catch(e=>{console.error(e.message);process.exitCode=1;});
