import test from 'node:test';
import assert from 'node:assert/strict';
import {jobs,makePrompt} from './worldx_props_batch03.mjs';
test('six unique single-object orders retain isolated art constraints',()=>{
 assert.equal(jobs.length,6);assert.equal(new Set(jobs.map(j=>j.id)).size,6);
 for(const j of jobs){assert.match(j.id,/^[a-z_]+$/);const p=makePrompt(j);assert.ok(p.includes(j.subject));assert.ok(p.includes('纯浅灰色空白背景'));assert.ok(p.includes('35–45度'));}
});
