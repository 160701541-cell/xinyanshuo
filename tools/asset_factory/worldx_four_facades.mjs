import {createHash} from 'node:crypto';
import {readFileSync, writeFileSync, mkdirSync, existsSync, copyFileSync} from 'node:fs';
import {resolve, dirname, join} from 'node:path';
import {pathToFileURL} from 'node:url';

// A four-ORTHOGRAPHIC-facade extension around the actual upstream WorldX
// prompt-loader. WorldX's stock map generator only makes a TOP-DOWN 2D map,
// so we must not falsely claim it natively produces 3D meshes or four views.
export const WORLDX_COMMIT='edb4976de5963457dfbf5d2171355270a4ca1e79';
export const BUILDING_ID='courtyard_main_hall';
export const VIEWS=[
 {id:'front',facing:'正面（南侧，Z正方向）',detail:'正中两扇木门，两侧窗棂对称，门窗底部统一在灰石台基以上。'},
 {id:'back',facing:'背面（北侧，Z负方向）',detail:'背墙不画任何正门，允许两扇简单小窗，檐高与正面完全相同。'},
 {id:'left',facing:'左侧立面（西侧，X负方向）',detail:'可见左右相同侧墙高度与屋檐，只有两扇侧窗，不画正房大门。'},
 {id:'right',facing:'右侧立面（东侧，X正方向）',detail:'与左侧等高的对称长侧墙，两扇侧窗，不画正房大门。'},
];
export const REFERENCE=resolve('game-source/apk176-ota177-candidate/hd2d/courtyard/main_house_v3_source.png');
export const TEMPLATE=resolve('tools/asset_factory/worldx_four_facades.prompt.md');
const REF_SHA='44d116addb17c5aa5a1f6c7edc85d44132fefdc0eb52ae422b63cc0b71060e3f';

export function fullPrompt(view,loader){
  const data={buildingId:BUILDING_ID,facing:view.facing,viewSpecification:view.detail,
    extraConstraints:'每一张单独输出一个方向，不要把四面放在同一张图里。'
  };
  const p=loader('canglan-four-facades.md',data);
  if(p.includes('{{'))throw new Error('WorldX four-face template unresolved variables');
  return p;
}

export function isComplete(out,id){
  const metaPath=join(out,id+'.json');
  if(!existsSync(metaPath))return false;
  const meta=JSON.parse(readFileSync(metaPath,'utf8'));
  if(meta.status!=='GENERATED_UNAPPROVED'||meta.source!=='WorldX')return false;
  const img=join(out,meta.file);
  return existsSync(img) &&
    createHash('sha256').update(readFileSync(img)).digest('hex')===meta.sha256;
}

async function generateOne(view,{out,reference,refSha,loader}){
  if(isComplete(out,view.id)){
    console.log('SKIP_VERIFIED_EXISTING_WORLDX_SIDE',view.id);
    return;
  }
  const ledger=join(out,view.id+'.request.json');
  if(existsSync(ledger)){
    // NEVER replay an uncertain paid edit request. Keep the partial batch.
    throw new Error('Prior attempted request for '+view.id+' is recorded; manual inspection required; NO AUTO RETRY');
  }
  const apiKey=process.env.SILICONFLOW_API_KEY||'';
  if(!apiKey)throw new Error('SILICONFLOW_API_KEY missing in public workflow; zero generation calls');
  const prompt=fullPrompt(view,loader);
  writeFileSync(join(out,view.id+'.prompt.txt'),prompt);
  writeFileSync(ledger,JSON.stringify({id:view.id,status:'REQUEST_STARTED',
    at:new Date().toISOString(),source:BUILDING_ID,model:'Qwen/Qwen-Image-Edit-2509'},null,2)+'\n');
  const response=await fetch('https://api.siliconflow.cn/v1/images/generations',{
    method:'POST',
    headers:{Authorization:'Bearer '+apiKey,'Content-Type':'application/json'},
    body:JSON.stringify({model:'Qwen/Qwen-Image-Edit-2509',prompt,batch_size:1,
      image:'data:image/png;base64,'+reference.toString('base64'),
      seed:160716,num_inference_steps:30,cfg:4,
      negative_prompt:'全景院落,鸟瞰,俯视,斜视,室内,背景,四视图拼版,多个房屋,树木,天空,标注,字样,水印,AI生成,景深,摄影,3D渲染'}),
    signal:AbortSignal.timeout(150000)
  });
  if(!response.ok)throw new Error('WorldX image-edit request for '+view.id+' failed: HTTP '+response.status);
  const result=await response.json();
  const url=result.images?.[0]?.url;
  if(typeof url!=='string'||!url.startsWith('https://'))throw new Error('WorldX provider missing HTTPS image URL for '+view.id);
  const imgResponse=await fetch(url,{signal:AbortSignal.timeout(90000)});
  if(!imgResponse.ok)throw new Error('WorldX image fetch for '+view.id+' HTTP '+imgResponse.status);
  const bytes=Buffer.from(await imgResponse.arrayBuffer());
  const sig=bytes.subarray(0,8).toString('hex');
  const ext=sig==='89504e470d0a1a0a'?'png':sig.startsWith('ffd8ff')?'jpg':null;
  if(!ext||bytes.length<25000||bytes.length>18_000_000)throw new Error('Invalid WorldX image for '+view.id);
  const filename=view.id+'.'+ext;
  writeFileSync(join(out,filename),bytes);
  const meta={schema:1,id:view.id,building_id:BUILDING_ID,source:'WorldX',
    pipeline:'YGYOOO/WorldX actual prompt-loader + public GitHub SiliconFlow image edit API',
    worldx_commit:WORLDX_COMMIT,model:'Qwen/Qwen-Image-Edit-2509',file:filename,
    sha256:createHash('sha256').update(bytes).digest('hex'),bytes:bytes.length,
    reference_sha256:refSha,reference_file:'main_house_v3_source.png',
    reference_conditioned:true,source_art_approved:false,
    status:'GENERATED_UNAPPROVED',semantic_four_side_match:'REQUIRES_VISUAL_QA',
    material_status:'NOT_READY_FOR_OFFICIAL_OTA',no_text_watermark:'NOT_VISUALLY_VERIFIED',
    side:view.id,art_id:BUILDING_ID,run_url:process.env.RUN_URL||''};
  writeFileSync(join(out,view.id+'.json'),JSON.stringify(meta,null,2)+'\n');
  writeFileSync(ledger,JSON.stringify({id:view.id,status:'RESPONSE_VERIFIED',
    completed_at:new Date().toISOString(),sha256:meta.sha256},null,2)+'\n');
  console.log('GENERATED_WORLDX_FACADE_UNAPPROVED',view.id,bytes.length,meta.sha256);
}

async function main(){
  const [worldxRoot,dest]=process.argv.slice(2);
  if(!worldxRoot||!dest)throw new Error('Usage: node worldx_four_facades.mjs WORLDX_UPSTREAM_PATH OUTPUT_DIR');
  const out=resolve(dest);
  mkdirSync(out,{recursive:true});
  const b=readFileSync(REFERENCE);
  const refSha=createHash('sha256').update(b).digest('hex');
  if(refSha!==REF_SHA)throw new Error('Approved Canglan style reference SHA mismatch; no paid calls');
  const from=resolve(worldxRoot,'generators/map/src/utils/prompt-loader.mjs');
  const upstreamTemplateDir=resolve(worldxRoot,'generators/map/prompts');
  const customTemplate=resolve(upstreamTemplateDir,'canglan-four-facades.md');
  if(!existsSync(from)||!existsSync(upstreamTemplateDir))throw new Error('Real YGYOOO WorldX installation missing');
  // Extend WorldX without destroying or replacing its original 90-degree MAP prompt.
  copyFileSync(TEMPLATE,customTemplate);
  const {loadPrompt}=await import(pathToFileURL(from));
  for(const view of VIEWS){
    await generateOne(view,{out,reference:b,refSha,loader:loadPrompt});
  }
  if(!VIEWS.every(v=>isComplete(out,v.id)))throw new Error('Batch incomplete; no game import');
  const facing={};
  for(const view of VIEWS){
    const data=JSON.parse(readFileSync(join(out,view.id+'.json'),'utf8'));
    facing[view.id]={file:data.file,sha256:data.sha256};
  }
  writeFileSync(join(out,'facades.json'),JSON.stringify({
    schema:1,building_id:BUILDING_ID,source:'WorldX',art_status:'GENERATED_UNAPPROVED',
    axes:'front=+Z,back=-Z,left=-X,right=+X',
    dimensions_meters:{width:10,depth:7,wall_height:4},
    user_goal:'four orthographic wall textures on real 3D walls; not HD2D scene',
    identical_building_across_views:'PENDING_VISUAL_APPROVAL',
    reference_sha256:refSha,materials:facing},null,2)+'\n');
  console.log('PASS_WORLDX_4_ACTUAL_FACADE_FILES_RECORDED_NOT_APPROVED');
}
if(process.argv[1]&&import.meta.url===pathToFileURL(resolve(process.argv[1])).href){
  main().catch(e=>{console.error(e.message);process.exitCode=1});
}
