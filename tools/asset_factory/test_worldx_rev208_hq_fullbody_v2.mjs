import test from 'node:test';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {IMAGE_MODEL,MAX_GENERATIONS,POSITIVE,NEGATIVE,TASK_ID,validateMetadata} from './worldx_rev208_hq_character_fullbody_v2.mjs';
test('full-length source attempt is a NEW single candidate, not a rerun of old portrait',()=>{
 assert.equal(TASK_ID,'player_full_body_002');
 assert.equal(MAX_GENERATIONS,1);
 assert.equal(IMAGE_MODEL,'Kwai-Kolors/Kolors');
});
test('no headshot or cropped hem acceptable; 3:4 portrait full body with substantial negative space',()=>{
 for (const term of ['65–72%','靴子','12%','全身','正面正交','半身像']){
  assert.ok(POSITIVE.includes(term)||NEGATIVE.includes(term),term);
 }
 assert.ok(NEGATIVE.includes('严禁肖像特写'));
});
test('candidate cannot change itself into a Godot GLB nor pass art QA',()=>{
 const bytes=Buffer.concat([Buffer.from('89504e470d0a1a0a','hex'),Buffer.alloc(40000)]);
 const meta={model:IMAGE_MODEL,id:TASK_ID,status:'GENERATED_UNAPPROVED',applied_to_game:false,
 sha256:createHash('sha256').update(bytes).digest('hex')};
 assert.equal(validateMetadata(meta,bytes),'png');
 assert.throws(()=>validateMetadata({...meta,applied_to_game:true},bytes));
 assert.throws(()=>validateMetadata({...meta,status:'ART_APPROVED'},bytes));
});