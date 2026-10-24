// System-wide public NPC biography index. No private thought/GM secrets here.
export const NPC_LIFE_VERSION='npc-life-1.0.0';
const fail=(code,message)=>{const e=new Error(message);e.code=code;throw e;};
const copy=o=>structuredClone(o);
export const PERSONALITY_AXIS=['curiosity','diligence','caution','sociability','cooperation','stress_tolerance'];
/** Stable game-model temperament scores, not observations of a real person.
 * FNV-1a seed -> 35..65 for each axis; no privileged or cinematic traits.
 * This contains no GM secrets such as undiscovered spiritual roots or plots.
 */
export function inherentTemperament(worldSeed,npcId){
 if(!worldSeed||!npcId)fail('TEMPERAMENT_SEED_MISSING','缺少年龄性格生成的世界种子或人物ID');
 const metrics={};
 for(const axis of PERSONALITY_AXIS){
  const str=worldSeed+'|NPC-BASE-TEMPERAMENT-v1|'+npcId+'|'+axis;
  let h=2166136261>>>0;
  for(const c of str)h=Math.imul(h^c.codePointAt(0),16777619)>>>0;
  metrics[axis]=35+(h%31);
 }
 return {version:'npc-base-temperament-v1',source:'deterministic_world_seed',scores:metrics,
   warning:'Generated base propensity, not a claim of player-observed behavior or guaranteed action'};
}

export function validateNpcRegistry(registry,state,events){
 if(registry.schema!=='xianfan.npc_life.v1'||registry.campaign_id!==state.campaign_id)fail('REGISTRY_WORLD','NPC注册表所属世界错误');
 const indexed=new Set((state.known_npcs||[]).map(n=>n.id));
 const eventIds=new Set((events||[]).map(e=>'EV'+String(e.seq).padStart(6,'0')));
 for(const [id,npc] of Object.entries(registry.npcs||{})){
  if(!indexed.has(id)||npc.id!==id||npc.campaign_id!==state.campaign_id)fail('NPC_NOT_IN_WORLD','档案人物不存在/跨世界');
  const identity=state.known_npcs.find(n=>n.id===id);
  for(const k of ['name','sex','age']){
    // If the original world archive has it, registry must never rewrite it.
    if(identity[k]!==undefined&&npc[k]!==identity[k])fail('NPC_IDENTITY_CONFLICT',id+' 身份属性被篡改: '+k);
  }
  if(JSON.stringify(npc.base_temperament)!==JSON.stringify(inherentTemperament(state.world_seed,id)))fail('PERSONALITY_DRIFT','人物基础性格模型被静默修改');
  if(!Array.isArray(npc.life_events))fail('MISSING_BIOGRAPHY','人物缺人生经历账');
  let last=0,seen=new Set();
  for(const fact of npc.life_events){
   if(!eventIds.has(fact.event_id))fail('EVENT_NOT_COMMITTED',id+' 人生经历没有真实事件');
   const seq=Number(fact.event_id.slice(2));
   if(seq<last||seen.has(fact.event_id+'|'+fact.tag))fail('BIO_ORDER','经历排序或重复');
   seen.add(fact.event_id+'|'+fact.tag);last=seq;
   if(!['known_fact','reported','inferred'].includes(fact.certainty))fail('FACT_UNVERIFIED','叙事事实级别非法');
  }
  if(npc.public_personality){
   const traits=npc.public_personality;
   for(const trait of traits){
    if(!trait.basis_event||!eventIds.has(trait.basis_event))fail('TRAIT_WITHOUT_EVIDENCE','性格标签缺事件依据');
    if(trait.kind!=='observed')fail('PRIVATE_TRAIT','公开GitHub不能伪造/泄漏NPC私密心理');
   }
  }
 }
 return {ok:true,characters:Object.keys(registry.npcs||{}).length,latest_event:events.at(-1)?.seq};
}

/** Create a public registry from committed world people without filling unknown traits. */
export function bootstrapNpcRegistry(state,events){
 if(!events?.length)fail('EVENTS_MISSING','缺少原始事件');
 const npcs={};
 for(const p of state.known_npcs||[]){
  if(npcs[p.id])fail('NPC_DUPLICATE',p.id);
  npcs[p.id]={
   id:p.id,campaign_id:state.campaign_id,name:p.name,sex:p.sex,age:p.age,
   residence:p.location_id||null,alive:p.alive,health:p.health??null,
   roles:[p.relation].filter(Boolean),born_at:null,kinship_origin:'已结算出生档案；血缘细节未登记',
   private_personality:'NOT_PUBLISHED',base_temperament:inherentTemperament(state.world_seed,p.id),public_personality:[],goals_observed:[],
   life_events:[],relationships:{},last_known_location:p.location_id||null,
   last_updated_event:'EV'+String(events.at(-1).seq).padStart(6,'0')
  };
 }
 return {schema:'xianfan.npc_life.v1',system_rule:NPC_LIFE_VERSION,
   campaign_id:state.campaign_id,source_of_truth:'game_state.json + events.jsonl',
   record_policy:'Public known and evidence-backed only; hidden character motives excluded',
   npcs};
}

export function appendLifeEvent(registry,{npc_id,event_id,tag,text,certainty='known_fact',location=null}){
 const result=copy(registry),npc=result.npcs?.[npc_id];
 if(!npc)fail('NPC_NOT_REGISTERED',npc_id);
 if(!/^EV\d{6}$/.test(event_id))fail('BAD_EVENT_ID',event_id);
 const record={event_id,tag,text,certainty,location};
 if(npc.life_events.some(r=>r.event_id===event_id&&r.tag===tag))return result;
 npc.life_events.push(record);
 npc.life_events.sort((a,b)=>Number(a.event_id.slice(2))-Number(b.event_id.slice(2)));
 npc.last_updated_event=event_id;
 return result;
}
export function observeTrait(registry,{npc_id,tag,event_id,description}){
 const result=copy(registry),npc=result.npcs?.[npc_id];
 if(!npc)fail('NPC_NOT_REGISTERED',npc_id);
 if(!/^EV\d{6}$/.test(event_id))fail('BAD_EVENT_ID',event_id);
 if(!npc.public_personality.some(x=>x.tag===tag&&x.basis_event===event_id))
  npc.public_personality.push({tag,kind:'observed',description,basis_event:event_id});
 return result;
}
