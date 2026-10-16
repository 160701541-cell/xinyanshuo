import {createHash} from 'node:crypto';
import {readFileSync,writeFileSync,mkdirSync,existsSync,copyFileSync} from 'node:fs';
import {resolve,join} from 'node:path';
import {pathToFileURL} from 'node:url';

// WorldX EXTENSION (its upstream generates map/character art, not native PBR).
// We reuse WorldX's actual pinned prompt-loader for only reusable MATERIAL maps.
// IMPORTANT: cannot "draw a finished building" or generate HD2D backdrops.
export const WORLDX_COMMIT='edb4976de5963457dfbf5d2171355270a4ca1e79';
export const MATERIALS=[
 {id:'timber',subject:'天然深棕榫卯木材的细密纵向木纹，少量年轮木纤维，哑光手绘木色，均匀分布，无单根木梁物体'},
 {id:'cut_stone',subject:'中国古建筑灰色打磨石材的连续细密石肌和细微颗粒，青灰暖灰调，哑光无大块深裂缝，无单独巨石'},
 {id:'mortar',subject:'古代白灰黄土混合抹面灰泥的细腻粉化表面，淡米灰色、微细抹刀痕，无完整墙体'},
 {id:'roof_tile',subject:'古代中国黛青色烧制陶瓦表面与连续重复瓦楞纹，微妙瓦片阴影、青灰青蓝瓦釉质感，无建筑轮廓'}
];
export function promptFor(job,loadPrompt){
  return loadPrompt('canglan-material-tile.md',{
    userPrompt:job.subject,
    materialID:job.id,
    additionalConstraints:'STRICT tileable seamless albedo. Only surface detail; no individual object, no building, no panel UI or watermark.'});
}
function isDone(dir,job){
  const f=join(dir,job.id+'.json');
  if(!existsSync(f))return false;
  const m=JSON.parse(readFileSync(f,'utf8'));
  return m.status==='GENERATED_UNAPPROVED'&&m.material_id===job.id&&
    existsSync(join(dir,m.file))&&
    createHash('sha256').update(readFileSync(join(dir,m.file))).digest('hex')===m.sha256;
}
async function main(){
  const [upstreamDir,outputDir]=process.argv.slice(2);
  if(!upstreamDir||!outputDir)throw new Error('Usage: node worldx_raw_materials_batch01.mjs WORLDX_ROOT OUTPUT_DIR');
  const out=resolve(outputDir);
  const upstream=resolve(upstreamDir);
  const loaderFile=resolve(upstream,'generators/map/src/utils/prompt-loader.mjs');
  const template=resolve('tools/asset_factory/worldx_raw_material_template.md');
  if(!existsSync(loaderFile)||!existsSync(template))throw new Error('WorldX pinned prompt loader not found; no calls');
  mkdirSync(out,{recursive:true});
  const upstreamTemplate=resolve(upstream,'generators/map/prompts/canglan-material-tile.md');
  copyFileSync(template,upstreamTemplate); // Add extension, DO NOT modify native WorldX map prompt.
  const {loadPrompt}=await import(pathToFileURL(loaderFile));
  for(const job of MATERIALS){
    if(isDone(out,job)){console.log('SKIP_REAL_EXISTING_MATERIAL',job.id);continue;}
    const ledger=join(out,job.id+'.request.json');
    if(existsSync(ledger))throw new Error('Prior failed/uncertain paid request '+job.id+' exists. Inspect; NO automatic retry.');
    if(!process.env.SILICONFLOW_API_KEY)throw new Error('SILICONFLOW_API_KEY not injected; no billable calls');
    const prompt=promptFor(job,loadPrompt);
    if(prompt.includes('{{'))throw new Error('Material prompt missing vars: '+job.id);
    writeFileSync(join(out,job.id+'.prompt.txt'),prompt);
    writeFileSync(ledger,JSON.stringify({material_id:job.id,status:'REQUEST_STARTED',at:new Date().toISOString()})+'\n');
    const response=await fetch('https://api.siliconflow.cn/v1/images/generations',{
      method:'POST',headers:{Authorization:'Bearer '+process.env.SILICONFLOW_API_KEY,
        'Content-Type':'application/json'},
      body:JSON.stringify({model:'Kwai-Kolors/Kolors',prompt,image_size:'1024x1024',batch_size:1}),
      signal:AbortSignal.timeout(150000)});
    if(!response.ok)throw new Error('Material '+job.id+' API HTTP '+response.status+'; no retry');
    const result=await response.json();
    const url=result.images?.[0]?.url;
    if(typeof url!=='string'||!url.startsWith('https://'))throw new Error('Missing image URL '+job.id);
    const image=await fetch(url,{signal:AbortSignal.timeout(90000)});
    if(!image.ok)throw new Error('Image download '+job.id+' HTTP '+image.status);
    const data=Buffer.from(await image.arrayBuffer());
    const magic=data.subarray(0,8).toString('hex');
    const ext=magic==='89504e470d0a1a0a'?'png':magic.startsWith('ffd8ff')?'jpg':null;
    if(!ext||data.length<30000||data.length>20_000_000)throw new Error('Invalid image '+job.id);
    writeFileSync(join(out,job.id+'.'+ext),data);
    const sha256=createHash('sha256').update(data).digest('hex');
    const meta={schema:1,material_id:job.id,source:'YGYOOO/WorldX extension',
      worldx_commit:WORLDX_COMMIT,
      pipeline:'actual WorldX source prompt loader + SiliconFlow image model',
      model:'Kwai-Kolors/Kolors',kind:'reusable_seamless_surface_albedo_CANDIDATE',
      file:job.id+'.'+ext,sha256,bytes:data.length,license:'provider_terms_review_needed',
      status:'GENERATED_UNAPPROVED',
      seamless:'REQUIRES_EDGE_QA',style:'REQUIRES_ART_QA',
      uniform_scale:'REQUIRES_ART_QA',no_watermark:'REQUIRES_VISUAL_QA',
      not_finished_building:true,no_hd2d:true,
      applied_to_game:false,run_url:process.env.RUN_URL||''};
    writeFileSync(join(out,job.id+'.json'),JSON.stringify(meta,null,2)+'\n');
    writeFileSync(ledger,JSON.stringify({material_id:job.id,status:'COMPLETED',sha256})+'\n');
    console.log('GENERATED_REAL_WORLDX_MATERIAL_UNAPPROVED',job.id,data.length,sha256);
  }
  const maps={};
  for(const job of MATERIALS){
    if(!isDone(out,job))throw new Error('Incomplete material batch: '+job.id);
    const d=JSON.parse(readFileSync(join(out,job.id+'.json'),'utf8'));
    maps[job.id]={file:d.file,sha256:d.sha256};
  }
  writeFileSync(join(out,'materials.json'),JSON.stringify({
    schema:1,source:'WorldX extension',art_status:'PENDING_VISUAL_APPROVAL',
    asset_type:'raw_reusable_material_texture_not_building',materials:maps},null,2)+'\n');
  console.log('PASS_WORLDX_MATERIAL_GENERATION_FOUR_CANDIDATES_NOT_GAME_APPROVED');
}
if(process.argv[1]&&import.meta.url===pathToFileURL(resolve(process.argv[1])).href)
  main().catch(err=>{console.error(err.message);process.exitCode=1});
