import test from 'node:test';
import assert from 'node:assert/strict';
import {jobs,makePrompt} from './worldx_props_batch02.mjs';
test('bounded batch has distinct isolated props and substitutes upstream style',()=>{
 assert.equal(jobs.length,2);
 assert.equal(new Set(jobs.map(x=>x.id)).size,2);
 for(const job of jobs){
  assert.match(job.id,/^[a-z_]+$/);
  const prompt=makePrompt(job);
  assert.ok(prompt.includes(job.subject));
  assert.ok(prompt.includes('35–45度'));
  assert.ok(prompt.includes('纯色背景供后续精修抠图'));
 }
});
