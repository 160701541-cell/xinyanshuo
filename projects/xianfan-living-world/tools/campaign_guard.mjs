import {createHash} from 'node:crypto';
import {readFileSync,writeFileSync,mkdirSync,existsSync} from 'node:fs';
import {join} from 'node:path';

const hashString = value => createHash('sha256').update(value).digest('hex');
const canonical = obj => JSON.stringify(sort(obj));
function sort(obj) {
  if (Array.isArray(obj)) return obj.map(sort);
  if (obj && typeof obj === 'object')
    return Object.fromEntries(Object.keys(obj).sort().map(k => [k,sort(obj[k])]));
  return obj;
}
export const digest = obj => hashString(canonical(obj));

export function verifyEvents(events) {
  let prev = 'GENESIS';
  events.forEach((event,index) => {
    if (event.seq !== index+1 || event.prev_hash !== prev) throw Error('事件顺序/父哈希错误: '+(index+1));
    const {hash,...unsigned}=event;
    if (hash !== digest(unsigned)) throw Error('事件校验失败: '+(index+1));
    prev=hash;
  });
  return {events:events.length,last_hash:prev};
}
export function countTurns(events) {
  const rounds=events.filter(e=>e.type==='turn_committed');
  rounds.forEach((event,i)=>{
    if (event.turn_id !== i+1) throw Error('缺失/重复结算轮: '+(i+1));
  });
  return rounds.length;
}
export function inspect(root) {
  const index=JSON.parse(readFileSync(join(root,'campaign_index.json'),'utf8'));
  const events=readFileSync(join(root,'events.jsonl'),'utf8').split(/\r?\n/).filter(Boolean).map(JSON.parse);
  const check=verifyEvents(events),turns=countTurns(events);
  if (index.turns_completed!==turns) throw Error('索引轮数与事件账本不一致');
  if (index.last_event_hash!==check.last_hash) throw Error('索引最后哈希与事件不一致');
  if (index.last_event!==('EV'+String(events.length).padStart(6,'0'))) throw Error('索引事件编号不匹配');
  const statePath=join(root,'game_state.json');
  let state=null;
  if (existsSync(statePath)){
    state=JSON.parse(readFileSync(statePath,'utf8'));
    if (digest(state)!==events.at(-1).state_hash) throw Error('状态哈希与事件链不一致');
  }
  // 注意：verifyEvents 也返回一个名为 events 的计数字段，必须先铺底层再覆盖，否则 checkpoint/review 拿不到事件数组
  return {...check,index,events,state,turns,full_state_verified:!!state};
}
export function checkpoint(root) {
  const a=inspect(root);
  if (!a.state) return {created:false,reason:'缺完整权威状态，不能生成合格摘要'};
  if (a.turns===0 || a.turns%10!==0) return {created:false,next_at:Math.ceil((a.turns+1)/10)*10};
  const events=a.events.filter(e=>e.type==='turn_committed').slice(-10);
  const memory=JSON.parse(readFileSync(join(root,'story_memory_public.json'),'utf8'));
  const cp={
    schema:1,turn:a.turns,range:[a.turns-9,a.turns],
    event_ids:events.map(e=>'EV'+String(e.seq).padStart(6,'0')),
    event_hash:a.last_hash,state_hash:digest(a.state),
    time:a.state.time.display,location:a.state.current_location,
    player:{id:a.state.player.id,hp:a.state.player.hp,stamina:a.state.player.stamina,money:a.state.player.money,realm:a.state.player.realm},
    inventory:a.state.inventory,
    relevant_npcs:Object.values(memory.characters||{}).map(n=>({id:n.id,name:n.name,age:n.age,location:n.location_id,notes:n.narrative_notes||[]})),
    open_threads:memory.open_threads||[],
    confirmed_actions:events.map(e=>({turn:e.turn_id,event:'EV'+String(e.seq).padStart(6,'0'),summary:e.summary||e.reason||e.type})),
    caution:'摘要为检索索引；剧情事实以未删减原事件与已校验存档为准。'
  };
  const folder=join(root,'checkpoints');mkdirSync(folder,{recursive:true});
  const file=join(folder,'turn_'+String(a.turns).padStart(4,'0')+'.json');
  writeFileSync(file,JSON.stringify(cp,null,2)+'\n');
  return {created:true,file,turn:a.turns,event_hash:a.last_hash};
}
if (process.argv[1] && process.argv[1].endsWith('campaign_guard.mjs')){
  const root=process.argv[3]||new URL('../campaigns/first-life/',import.meta.url).pathname;
  try{console.log(JSON.stringify(process.argv[2]==='checkpoint'?checkpoint(root):inspect(root),null,2));}
  catch(e){console.error('BLOCKED:',e.message);process.exitCode=1;}
}
