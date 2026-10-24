import test from 'node:test';
import assert from 'node:assert/strict';
import {mkdtempSync,readFileSync,writeFileSync,copyFileSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {restore} from '../tools/restore_campaign.mjs';
import {inspect,countTurns,verifyEvents,digest,checkpoint} from '../tools/campaign_guard.mjs';
import {attempt,pursuit} from '../tools/npc_fairness.mjs';

const source=new URL('../campaigns/first-life/',import.meta.url).pathname;
function fixture(fn){
 const dir=mkdtempSync(join(tmpdir(),'xianfan-qa-'));
 for(const name of ['state_core.json','state_world.json','family.json','initial_rolls_public.json','campaign_index.json','events.jsonl','story_memory_public.json'])
   copyFileSync(join(source,name),join(dir,name));
 try{return fn(dir);}finally{rmSync(dir,{recursive:true,force:true});}
}
test('real first-life story save reconstructs and verifies',()=>fixture(dir=>{
 const w=restore(dir),r=inspect(dir);
 assert.equal(w.player.age,16);
 assert.equal(w.player.money,12);
 assert.equal(w.family.cash,42);
 assert.equal(r.full_state_verified,true);
 assert.equal(r.turns,0);
 assert.equal(r.events,2);
 assert.equal(r.last_hash,'a74cf0a99c6cef1a4d019787bbf4eb457781f94346d420196c443be1c411fc69');
 assert.equal(checkpoint(dir).created,false);
}));
test('tampered event cannot pass chain',()=>fixture(dir=>{
 restore(dir);
 let lines=readFileSync(join(dir,'events.jsonl'),'utf8').trim().split('\n').map(JSON.parse);
 lines[1].reason='altered';
 assert.throws(()=>verifyEvents(lines),/校验失败/);
}));
test('every 10 actual turns creates one summary without deleting events',()=>fixture(dir=>{
 const state=restore(dir),events=readFileSync(join(dir,'events.jsonl'),'utf8').trim().split('\n').map(JSON.parse);
 for(let i=1;i<=10;i++){
   const seq=events.length+1;
   state.last_event_id='EV'+String(seq).padStart(6,'0');
   const event={seq,type:'turn_committed',turn_id:i,reason:'合成测试行动，不属于真实战役',summary:'第'+i+'次模拟行动',delta:{},prev_hash:events.at(-1).hash,state_hash:digest(state)};
   event.hash=digest(event);
   events.push(event);
 }
 writeFileSync(join(dir,'game_state.json'),JSON.stringify(state));
 writeFileSync(join(dir,'events.jsonl'),events.map(x=>JSON.stringify(x)).join('\n')+'\n');
 const index=JSON.parse(readFileSync(join(dir,'campaign_index.json')));
 index.last_event=state.last_event_id;index.last_event_hash=events.at(-1).hash;index.turns_completed=10;
 writeFileSync(join(dir,'campaign_index.json'),JSON.stringify(index));
 assert.equal(inspect(dir).turns,10);
 const cp=checkpoint(dir);
 assert.equal(cp.created,true);
 const note=JSON.parse(readFileSync(cp.file));
 assert.equal(note.confirmed_actions.length,10);
 assert.equal(note.open_threads.length,2);
 assert.equal(note.relevant_npcs.length,3);
 assert.equal(events.length,12);
}));
test('no protagonist privilege; physical limits and bounded hostility',()=>{
 const a={id:'NPC009',stamina:40};
 const x={seed:'s',turn:1,actor:a,task:'attack',skill:4,difficulty:6,energy:2};
 assert.deepEqual(attempt(x),attempt({...x,actor:{...a,designation:'player'}}));
 assert.equal(attempt({...x,distance:60,maxReach:3}).status,'impossible');
 assert.equal(attempt({...x,requiredTools:['bow'],tools:[]}).status,'impossible');
 assert.equal(attempt({...x,actor:{...a,stamina:0}}).status,'impossible');
 assert.equal(pursuit({hasReason:false}).chase,false);
 assert.equal(pursuit({hasReason:true,knowsDirection:false}).chase,false);
 assert.equal(pursuit({hasReason:true,knowsDirection:true,distance:1000}).chase,false);
 assert.equal(pursuit({hasReason:true,knowsDirection:true,minutesSpent:50}).chase,false);
 assert.equal(pursuit({hasReason:true,knowsDirection:true,onDuty:true,inJurisdiction:false}).chase,false);
 assert.equal(pursuit({hasReason:true,knowsDirection:true,reward:20,distance:10}).chase,true);
});
