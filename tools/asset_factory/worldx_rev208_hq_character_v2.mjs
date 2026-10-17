// REV208 HQ-Art-Lock. One bounded WorldX/Kolors candidate, NOT a game GLB.
import {createHash} from 'node:crypto';
import {copyFileSync,existsSync,mkdirSync,readFileSync,writeFileSync} from 'node:fs';
import {dirname,join,resolve} from 'node:path';
import {pathToFileURL} from 'node:url';
export const WORLDX_COMMIT='edb4976de5963457dfbf5d2171355270a4ca1e79';
export const IMAGE_MODEL='Kwai-Kolors/Kolors';
export const TASK_ID='player_front_001';
export const MAX_GENERATIONS=1;
export const forbidden=[
 'low poly','low-poly','voxel','cube head','pixel art','western knight',
 'medieval european','wizard hat','modern short haircut','watermark'];
export const POSITIVE= [
 '《苍岚·人生世界》 国风修仙手游高精3D主角角色视觉母版',
 '一名成年中国男性修士，7.5至8头身，正常真实成年人五官与手脚',
 '全身从头到脚完全入画，清晰俊朗东方五官、自然眼睛眉毛、真实精细皮肤微纹理',
 '乌黑长发半束古代发髻，深青玉簪/小冠，垂到后肩的细发束，发丝有分组和光泽',
 '历史可信的古代中国交领长袍、深翠青绿织锦外衣、内穿象牙白麻丝中衣',
 '藏蓝色多层下裳、暗金纹样腰带、玉佩、真实织纹刺绣和衣服边缘针脚',
 '腰侧配一把中国修仙式古剑，剑柄/剑鞘用真实金属/木/丝束材质',
 '符合高品质3D角色资产设计，真实三维造型、复杂骨骼可绑定服装结构',
 '单个完整人物，正面全身站立，A-pose轻微展开双臂，正面正交镜头，不要其他角度人物',
 '中性灰背景，影棚中性柔光，脸、发、手、脚、武器轮廓清晰无遮挡',
 '超高精PBR/法线/粗糙度/织物纤维/微妙皮肤透光效果视觉参考',
 '墨绿、深翠绿、冷蓝与暖白明暗层次丰富，细节锐利非像素风',
 '统一国风修仙高品质3D手游美术角色设定母版，不是平面插画'
].join('，');
export const NEGATIVE=[
 '禁止低模低多边形及棱角切面','禁止方块头方块手','禁止欧美骑士装备与法师帽',
 '禁止现代短发','禁止Q版二头身','禁止像素游戏','禁止厚涂模糊平面动漫画风',
 '禁止大头稚嫩玩具比例','禁止彩色塑料单色衣服','禁止文字Logo乱码水印',
 '禁止人物多视图拼在一起','禁止多个角色','禁止透视截断脚和头',
 '禁止多余手指肢体及脸部畸形','禁止特效盖脸','禁止背景房屋/森林元素'
].join('；');
export function makeWorldxTemplate(){
 return [
 '# Canglan HQ3D v2 WorldX extension - one character source image, not 3D.',
 '# Only one portrait per request. Additional angles need reference conditioning and human review.',
 'User target: {{userPrompt}}',
 'Necessary negatives: {{additionalConstraints}}'
 ].join('\n')+'\n';
}
export function validateMetadata(m,data){
 const bytes=Buffer.from(data);
 const magic=bytes.subarray(0,8).toString('hex');
 const ext=magic==='89504e470d0a1a0a'?'png':magic.startsWith('ffd8ff')?'jpg':null;
 if(!ext||bytes.length<30_000||bytes.length>16_000_000)throw Error('Invalid bounded PNG/JPEG image payload');
 if(m.model!==IMAGE_MODEL||m.id!==TASK_ID||m.status!=='GENERATED_UNAPPROVED'||m.applied_to_game!==false)
   throw Error('Wrong task/model/source status');
 if(m.sha256!==createHash('sha256').update(bytes).digest('hex'))
   throw Error('SHA-256 source mismatch');
 return ext;
}
export async function produce(upstream,output){
 const folder=resolve(output);mkdirSync(folder,{recursive:true});
 const mpath=join(folder,TASK_ID+'.json');
 // No duplicate credits after partial timeout: examine ledger manually.
 const ledger=join(folder,TASK_ID+'.request.json');
 if(existsSync(mpath)){
   const saved=JSON.parse(readFileSync(mpath,'utf8'));
   const file=join(folder,saved.file||'');
   if(existsSync(file)){
     validateMetadata(saved,readFileSync(file));
     console.log('SKIP_EXISTING_VERIFIED_HQ_CANDIDATE',TASK_ID);return;
   }
   throw Error('Existing metadata missing image: HOLD, never silently retry.');
 }
 if(existsSync(ledger))throw Error('In-flight or failed prior request: manual review, NO charged retry');
 if(!process.env.SILICONFLOW_API_KEY)throw Error('BLOCKED_PROVIDER: official SiliconFlow key not available; NO billable calls');
 const loader=resolve(upstream,'generators/map/src/utils/prompt-loader.mjs');
 if(!existsSync(loader))throw Error('Exact pinned WorldX prompt loader missing');
 const custom=resolve(upstream,'generators/map/prompts/canglan-rev208-hq3d-front.md');
 writeFileSync(custom,makeWorldxTemplate());
 const {loadPrompt}=await import(pathToFileURL(loader));
 const prompt=loadPrompt('canglan-rev208-hq3d-front.md',{
   userPrompt:POSITIVE,additionalConstraints:NEGATIVE});
 if(prompt.includes('{{')||prompt.length<400)throw Error('Unexpanded WorldX template');
 writeFileSync(join(folder,TASK_ID+'.prompt.txt'),prompt);
 writeFileSync(ledger,JSON.stringify({schema:1,id:TASK_ID,status:'REQUEST_STARTED',
   created_at:new Date().toISOString(),model:IMAGE_MODEL,maximum_new_requests:1})+'\n');
 const response=await fetch('https://api.siliconflow.cn/v1/images/generations',{
   method:'POST',headers:{Authorization:'Bearer '+process.env.SILICONFLOW_API_KEY,
     'Content-Type':'application/json'},
   body:JSON.stringify({model:IMAGE_MODEL,prompt,image_size:'1024x1024',batch_size:1}),
   signal:AbortSignal.timeout(150000)});
 if(!response.ok)throw Error('PROVIDER_HTTP_'+response.status+' no retry');
 const url=(await response.json()).images?.[0]?.url;
 if(typeof url!=='string'||!url.startsWith('https://'))throw Error('Invalid provider HTTPS image URL');
 const img=await fetch(url,{signal:AbortSignal.timeout(90000)});
 if(!img.ok)throw Error('Downloaded result HTTP '+img.status);
 const bytes=Buffer.from(await img.arrayBuffer());
 const tmp={model:IMAGE_MODEL,id:TASK_ID,status:'GENERATED_UNAPPROVED',applied_to_game:false,
   sha256:createHash('sha256').update(bytes).digest('hex')};
 const ext=validateMetadata(tmp,bytes);
 writeFileSync(join(folder,TASK_ID+'.'+ext),bytes);
 const m={schema:1,id:TASK_ID,model:IMAGE_MODEL,source:'YGYOOO/WorldX actual pinned prompt loader',
   pinned_upstream_sha:WORLDX_COMMIT,prompt_format:'HQ3D v2 single full-body FRONT only',
   file:TASK_ID+'.'+ext,bytes:bytes.length,sha256:tmp.sha256,
   status:'GENERATED_UNAPPROVED',art_review:'PENDING_HUMAN',
   anatomical_qa:'PENDING_HUMAN',multi_view_consistency:'NOT_TESTED_ONE_VIEW_ONLY',
   actual_3d_glb:false,rigged:false,pbr_textures:false,licensed_for_game:'PENDING_PROVIDER_TERMS',
   applied_to_game:false,release_revision:null,run_url:process.env.RUN_URL||''};
 writeFileSync(mpath,JSON.stringify(m,null,2)+'\n');
 writeFileSync(ledger,JSON.stringify({id:TASK_ID,status:'COMPLETED',sha256:m.sha256})+'\n');
 console.log('PASS_REAL_WORLDX_HQ3D_V2_FRONT_CANDIDATE_CREATED_UNAPPROVED',m.sha256);
}
if(process.argv[1]&&import.meta.url===pathToFileURL(resolve(process.argv[1])).href){
 produce(process.argv[2],process.argv[3]).catch(e=>{
   console.error(String(e.message));process.exitCode=1;
 });
}
