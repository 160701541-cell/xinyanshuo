import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {jobs} from './worldx_reference_extract02.mjs';
test('one source edit uses correct model request without unsupported resolution',()=>{
 assert.equal(jobs.length,1);
 const s=readFileSync(new URL('./worldx_reference_extract02.mjs',import.meta.url),'utf8');
 assert.ok(s.includes("model:'Qwen/Qwen-Image-Edit-2509',prompt,batch_size:1"));
 assert.ok(!s.includes("image_size:"));
 assert.ok(s.includes("image:'data:image/png;base64,'+reference.toString('base64')"));
 assert.ok(s.includes('Approved reference SHA mismatch'));
});
