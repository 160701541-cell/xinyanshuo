import {readFileSync, writeFileSync, mkdirSync, existsSync} from 'node:fs';
import {resolve} from 'node:path';
import {pathToFileURL} from 'node:url';
import {createHash} from 'node:crypto';
export const jobs = [{id:"courtyard_side_wing_reference",subject:"一栋独立的中国古代院落厢房，单层青灰瓦硬山顶、深棕木柱门窗、灰白墙和石台基，完整屋顶及四周轮廓"}];
export function makePrompt(job) {
 return `以输入参考图作为绘画风格和机位依据，只提取它的细腻国风手绘笔触、青灰瓦片、深棕木构、灰白墙体、暖光和柔和低饱和自然色。不照搬整个四合院布局。绘制${job.subject}。保持参考图斜俯视的视角，可见顶面正面侧面，细密瓦片和木梁线条，温润古朴，非产品摄影，非塑料3D模型。只要单栋厢房居中，完整轮廓，四周留浅灰空白。无树木、其他建筑、完整院落、人物和文字。{{userPrompt}}。{{additionalConstraints}}`;
}
async function main() {
 const [upstream, dest] = process.argv.slice(2);
 if(!upstream || !dest) throw Error('Usage: node worldx_props_style_reference_probe01.mjs WORLDX_ROOT OUTPUT_DIR');
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
   body:JSON.stringify({model:'Kwai-Kolors/Kolors',prompt,image_size:'1024x1024',batch_size:1,image:'data:image/png;base64,'+reference.toString('base64'),seed:160716,num_inference_steps:30,guidance_scale:7.5,negative_prompt:'摄影,产品渲染,塑料,正面立视图,像素风,Q版,文字,整座院落,多栋建筑,树木'}),signal:AbortSignal.timeout(150000)});
  if(!response.ok) throw Error(`Generation ${job.id}: HTTP ${response.status}; no retry`);
  const url=(await response.json()).images?.[0]?.url;
  if(!url?.startsWith('https://')) throw Error('Missing HTTPS result');
  const image=await fetch(url,{signal:AbortSignal.timeout(90000)});
  if(!image.ok) throw Error('Image download failed; no generation retry');
  const bytes=Buffer.from(await image.arrayBuffer());
  const ext=bytes.subarray(0,8).toString('hex')==='89504e470d0a1a0a'?'png':bytes.subarray(0,3).toString('hex')==='ffd8ff'?'jpg':null;
  if(!ext||bytes.length<30000) throw Error('Invalid image payload');
  writeFileSync(out+'.'+ext,bytes);
  writeFileSync(out+'.json',JSON.stringify({id:job.id,batch:'worldx-props-style_reference_probe01',model:'Kwai-Kolors/Kolors',pipeline:'WorldX native prompt loader + SiliconFlow',file:job.id+'.'+ext,sha256:createHash('sha256').update(bytes).digest('hex'),upstream_commit:'edb4976de5963457dfbf5d2171355270a4ca1e79',status:'GENERATED_UNAPPROVED',reference_image_sent:true,reference_sha256:referenceSha,reference_effectiveness:'REQUIRES_VISUAL_VERIFICATION',style_control:'reference_input_plus_text_NOT_style_approved',transparency:'NOT_CLEANED',license_status:'PROVIDER_TERMS_REVIEW_REQUIRED',run_url:process.env.RUN_URL},null,2)+'\n');
  console.log('GENERATED_UNAPPROVED',job.id,bytes.length);
 }
 writeFileSync(template,original);
}
if(process.argv[1] && import.meta.url===pathToFileURL(resolve(process.argv[1])).href) main().catch(e=>{console.error(e.message);process.exitCode=1;});
