import {readFileSync, writeFileSync, mkdirSync, existsSync} from 'node:fs';
import {resolve} from 'node:path';
import {pathToFileURL} from 'node:url';
import {createHash} from 'node:crypto';
export const jobs = [{id:"main_house_extract02",subject:"原图中央上半部最大的正房，包括青灰瓦主屋顶、下层屋檐、前立面木门柱廊、完整台基和正前方短石阶"}];
export function makePrompt(job) {
 return `对输入图片做建筑提取编辑，不要重新设计画风。提取${job.subject}，把这栋正房放在纯浅灰背景上。保留原图正房屋顶形状、青灰瓦片排布、深棕木构、灰白墙、石阶、原始细腻国风绘画笔触、光照方向和相机角度。删去左右厢房、院墙院门、树木、远景、庭院地面和字样。不可把正房换成另一座房子，不要增加新院落，不要改成水墨线描、素描、水彩纸、写实3D或摄影。主体完整，边缘清楚，所有檐角和底座在画面内，四周留空。不补画被遮住的背面；遮挡缺失部分以待审核候选处理。{{userPrompt}}。{{additionalConstraints}}`;
}
async function main() {
 const [upstream, dest] = process.argv.slice(2);
 if(!upstream || !dest) throw Error('Usage: node worldx_props_reference_extract02.mjs WORLDX_ROOT OUTPUT_DIR');
 mkdirSync(dest,{recursive:true});
 const referenceFile=resolve('game-source/apk176-ota177-candidate/hd2d/courtyard/main_house_v3_source.png');
 const reference=readFileSync(referenceFile);
 const referenceSha=createHash('sha256').update(reference).digest('hex');
 if(referenceSha!=='44d116addb17c5aa5a1f6c7edc85d44132fefdc0eb52ae422b63cc0b71060e3f') throw Error('Approved reference SHA mismatch');
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
   body:JSON.stringify({model:'Qwen/Qwen-Image-Edit-2509',prompt,batch_size:1,image:'data:image/png;base64,'+reference.toString('base64'),seed:160716,num_inference_steps:30,cfg:4,negative_prompt:'摄影,产品渲染,塑料,正面立视图,像素风,Q版,文字,整座院落,多栋建筑,树木'}),signal:AbortSignal.timeout(150000)});
  if(!response.ok) throw Error(`Generation ${job.id}: HTTP ${response.status}; no retry`);
  const url=(await response.json()).images?.[0]?.url;
  if(!url?.startsWith('https://')) throw Error('Missing HTTPS result');
  const image=await fetch(url,{signal:AbortSignal.timeout(90000)});
  if(!image.ok) throw Error('Image download failed; no generation retry');
  const bytes=Buffer.from(await image.arrayBuffer());
  const ext=bytes.subarray(0,8).toString('hex')==='89504e470d0a1a0a'?'png':bytes.subarray(0,3).toString('hex')==='ffd8ff'?'jpg':null;
  if(!ext||bytes.length<30000) throw Error('Invalid image payload');
  writeFileSync(out+'.'+ext,bytes);
  writeFileSync(out+'.json',JSON.stringify({id:job.id,batch:'worldx-props-reference_extract02',model:'Qwen/Qwen-Image-Edit-2509',pipeline:'WorldX native prompt loader + SiliconFlow',file:job.id+'.'+ext,sha256:createHash('sha256').update(bytes).digest('hex'),upstream_commit:'edb4976de5963457dfbf5d2171355270a4ca1e79',status:'GENERATED_UNAPPROVED',reference_image_sent:true,reference_sha256:referenceSha,reference_effectiveness:'REQUIRES_VISUAL_VERIFICATION',style_control:'source_image_extraction_edit_NOT_style_approved',transparency:'NOT_CLEANED',license_status:'PROVIDER_TERMS_REVIEW_REQUIRED',run_url:process.env.RUN_URL},null,2)+'\n');
  console.log('GENERATED_UNAPPROVED',job.id,bytes.length);
 }
 writeFileSync(template,original);
}
if(process.argv[1] && import.meta.url===pathToFileURL(resolve(process.argv[1])).href) main().catch(e=>{console.error(e.message);process.exitCode=1;});
