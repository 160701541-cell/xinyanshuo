import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {jobs} from './worldx_style_reference_probe01.mjs';
test('one image order sends verified reference rather than claiming text style lock',()=>{
 assert.equal(jobs.length,1);
 const s=readFileSync(new URL('./worldx_style_reference_probe01.mjs',import.meta.url),'utf8');
 assert.ok(s.includes("image:'data:image/png;base64,'+reference.toString('base64')"));
 assert.ok(s.includes('Approved reference SHA mismatch'));
 assert.ok(s.includes("reference_effectiveness:'REQUIRES_VISUAL_VERIFICATION'"));
});
