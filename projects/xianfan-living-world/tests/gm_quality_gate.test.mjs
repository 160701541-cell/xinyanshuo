import test from 'node:test';
import assert from 'node:assert/strict';
import {auditProposedTurn,reviewAtTurn,FIELDS} from '../tools/gm_quality_gate.mjs';

const base=()=>({
 before:{time:{day:1,hour:8,minute:0},player:{id:'CFPLAYER00001',money:12,hp:100,max_hp:100,stamina:100,max_stamina:100},inventory:[]},
 after:{time:{day:1,hour:8,minute:5},player:{id:'CFPLAYER00001',money:12,hp:100,max_hp:100,stamina:99,max_stamina:100},inventory:[]},
 action:{kind:'walk',consumes_time:true},
 adjudication:{narrated_success:true,action_succeeded:true}
});
test('only audited evidence is PASS; untested fairness stays NOT_CHECKED',()=>{
 const a=auditProposedTurn(base());
 assert.equal(a.accepted,true);
 assert.equal(a.checks.causality,'PASS');
 assert.equal(a.checks.actor_symmetry,'NOT_CHECKED');
 assert.equal(a.checks.npc_knowledge,'NOT_CHECKED');
 assert.equal(Object.keys(a.checks).length,FIELDS.length);
});
test('cannot add money without provenance',()=>{
 const a=base();a.after.player.money=100;
 const r=auditProposedTurn(a);
 assert.equal(r.accepted,false);
 assert.ok(r.issues.some(x=>x.code==='MONEY_NO_SOURCE'));
});
test('cannot spend without destination or forge a winning narrative',()=>{
 const a=base();a.after.player.money=7;
 a.adjudication.narrated_success=true;a.adjudication.action_succeeded=false;
 const r=auditProposedTurn(a);
 assert.equal(r.checks.story_consistency,'FAIL');
 assert.ok(r.issues.some(x=>x.code==='MONEY_NO_SINK'));
});
test('time, identity and vital ranges are protected',()=>{
 const a=base();a.after.time.hour=7;a.after.player.id='CFPLAYER00099';
 a.after.player.hp=101;
 const r=auditProposedTurn(a);
 assert.equal(r.accepted,false);
 assert.equal(r.checks.causality,'FAIL');
 assert.equal(r.checks.memory_continuity,'FAIL');
 assert.equal(r.checks.resource_conservation,'FAIL');
});
test('finite pursuit refuses implausible infinite chasing',()=>{
 const a=base();a.action={kind:'pursuit',consumes_time:true};
 a.adjudication.pursuit={hasReason:true,knowsDirection:true,chase:true,stamina:4,minutesSpent:60,timeBudget:15,distance:200,range:100,onDuty:true,inJurisdiction:false};
 const r=auditProposedTurn(a);
 assert.equal(r.checks.pursuit_motivation,'FAIL');
 assert.equal(r.accepted,false);
});
test('protagonist privilege and NPC omniscience are rejected',()=>{
 const a=base();a.adjudication.special_player_bonus=true;a.adjudication.npc_used_hidden_player_info=true;
 const r=auditProposedTurn(a);
 assert.equal(r.checks.actor_symmetry,'FAIL');
 assert.equal(r.checks.npc_knowledge,'FAIL');
});
test('missing evidence is never incorrectly called PASS',()=>{
 const r=auditProposedTurn({});
 assert.equal(r.accepted,false);
 for(const key of FIELDS)assert.equal(r.checks[key],'NOT_CHECKED');
});
