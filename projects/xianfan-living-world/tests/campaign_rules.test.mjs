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
 for(const name of ['state_core.json','state_world.json','family.json','initial_rolls_public.json','campaign_index.json','events.jsonl','story_memory_public.json','game_state.json'])
   copyFileSync(join(source,name),join(dir,name));
 try{return fn(dir);}finally{rmSync(dir,{recursive:true,force:true});}
}
test('live first-life save verifies across any number of turns',()=>fixture(dir=>{
 const state=restore(dir),r=inspect(dir);
 assert.equal(state.player.id,'CFPLAYER00001');
 assert.equal(state.family.cash,42);
 assert.equal(r.full_state_verified,true);
 assert.equal(r.turns,r.index.turns_completed);
 assert.equal(r.events.length,Number(r.index.last_event.slice(2)));
 assert.equal(r.last_hash,r.events.at(-1).hash);
 assert.equal(r.events.at(-1).state_hash,digest(r.state));
}));
test('tampered event cannot pass chain',()=>fixture(dir=>{
 restore(dir);
 const lines=readFileSync(join(dir,'events.jsonl'),'utf8').trim().split('\\n').map(JSON.parse);
 lines[1].reason='altered';
 assert.throws(()=>verifyEvents(lines),/校验失败/);
}));
test('synthetic birth fixture creates ten-turn summary without erasing events',()=>fixture(dir=>{
 const initialFiles=['state_core.json','state_world.json','family.json','initial_rolls_public.json'].map(n=>JSON.parse(readFileSync(join(dir,n),'utf8')));
 const [core,world,family,rolls]=initialFiles;
 const state={...core,...world,family,initial_rolls_public:rolls};
 const events=readFileSync(join(dir,'events.jsonl'),'utf8').trim().split('\\n').map(JSON.parse).slice(0,2);
 const index=JSON.parse(readFileSync(join(dir,'campaign_index.json'),'utf8'));
 index.last_event='EV000002';index.last_event_hash=events.at(-1).hash;index.turns_completed=0;
 writeFileSync(join(dir,'game_state.json'),JSON.stringify(state));
 for(let i=1;i<=10;i++){
   const seq=events.length+1;
   state.last_event_id='EV'+String(seq).padStart(6,'0');
   const ev={seq,type:'turn_committed',turn_id:i,reason:'合成测试行动，不属于真实战役',
     summary:'第'+i+'次模拟行动',delta:{},prev_hash:events.at(-1).hash,state_hash:digest(state)};
   ev.hash=digest(ev);events.push(ev);
 }
 writeFileSync(join(dir,'game_state.json'),JSON.stringify(state));
 writeFileSync(join(dir,'events.jsonl'),events.map(x=>JSON.stringify(x)).join('\\n')+'\\n');
 index.last_event=state.last_event_id;index.last_event_hash=events.at(-1).hash;index.turns_completed=10;
 writeFileSync(join(dir,'campaign_index.json'),JSON.stringify(index));
 assert.equal(inspect(dir).turns,10);
 const cp=checkpoint(dir);
 assert.equal(cp.created,true);
 const note=JSON.parse(readFileSync(cp.file));
 assert.equal(note.confirmed_actions.length,10);
 assert.ok(note.open_threads.length>=2);
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
