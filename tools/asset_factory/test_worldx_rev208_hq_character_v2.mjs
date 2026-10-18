import test from 'node:test';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {IMAGE_MODEL,MAX_GENERATIONS,NEGATIVE,POSITIVE,TASK_ID,makeWorldxTemplate,validateMetadata} from './worldx_rev208_hq_character_v2.mjs';

test('ONE generated result only; no bulk paid trials or retry loops',()=>{
 assert.equal(MAX_GENERATIONS,1);
 assert.equal(TASK_ID,'player_front_001');
 assert.equal(IMAGE_MODEL,'Kwai-Kolors/Kolors');
});
test('Chinese adult, traditional hair and robes, detailed readable hero reference',()=>{
 for(const phrase of ['成年中国男性','发髻','玉簪','中国','织纹','皮肤','单个完整人物','正面全身','高精','A-pose']){
  assert.ok(POSITIVE.includes(phrase),phrase);
 }
 for(const phrase of ['禁止低模','禁止欧美骑士','禁止多余手指','禁止文字','禁止多个角色','禁止现代短发']){
  assert.ok(NEGATIVE.includes(phrase),phrase);
 }
});
test('WorldX prompt extension has both variables and no 90-degree HD2D map prompt',()=>{
 const str=makeWorldxTemplate();
 assert.ok(str.includes('{{userPrompt}}')&&str.includes('{{additionalConstraints}}'));
 assert.ok(!str.includes('90度')&&!str.includes('城镇全景')&&!str.includes('四合院整图'));
});
test('generated assets stay UNAPPROVED until real GLB import and art review',()=>{
 const b=Buffer.concat([Buffer.from('89504e470d0a1a0a','hex'),Buffer.alloc(30000)]);
 const meta={model:IMAGE_MODEL,id:TASK_ID,status:'GENERATED_UNAPPROVED',applied_to_game:false,
 sha256:createHash('sha256').update(b).digest('hex')};
 assert.equal(validateMetadata(meta,b),'png');
 assert.throws(()=>validateMetadata({...meta,status:'PASSED'},b));
 assert.throws(()=>validateMetadata({...meta,applied_to_game:true},b));
 assert.throws(()=>validateMetadata({...meta,sha256:'bad'},b));
 assert.throws(()=>validateMetadata(meta,Buffer.alloc(500)));
});