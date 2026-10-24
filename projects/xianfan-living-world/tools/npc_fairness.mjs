import {createHash} from 'node:crypto';
const clamp=(x,a,b)=>Math.min(b,Math.max(a,x));
const rnd=s=>parseInt(createHash('sha256').update(String(s)).digest('hex').slice(0,12),16)/0x1000000000000;

/** Applies identical adjudication to humans and NPCs; no 'player' field or preferential bonuses. */
export function attempt({seed,turn,actor,target={},task='attempt',skill=0,difficulty=0,energy=1,tools=[],requiredTools=[],distance=0,maxReach=2,blocked=false,deterministic=false}){
  if(blocked||distance>maxReach) return {ok:false,status:'impossible',why:'不可到达或受现实阻挡',energyUsed:0};
  if(requiredTools.some(t=>!tools.includes(t)))return {ok:false,status:'impossible',why:'缺少必要工具',energyUsed:0};
  if(actor.stamina<energy)return {ok:false,status:'impossible',why:'体力不足',energyUsed:0};
  if(deterministic)return {ok:true,status:'completed',energyUsed:energy,roll:null};
  const resistance=target.resistance||0;
  const chance=clamp(.50+(skill-difficulty-resistance)*.055,.02,.98);
  const roll=rnd([seed,turn,actor.id,task,target.id||''].join('|'));
  return {ok:roll<chance,status:roll<chance?'completed':'failed',chance,roll,energyUsed:energy};
}

/** Pursuit must make sense for this specific NPC at this time. Re-evaluate continuously. */
export function pursuit({hasReason=false,knowsDirection=false,distance=0,range=180,stamina=100,injured=false,onDuty=false,inJurisdiction=true,minutesSpent=0,timeBudget=20,risk=0,reward=0,personality=0}={}){
  if(!hasReason)return {chase:false,why:'没有合理动机'};
  if(!knowsDirection)return {chase:false,why:'丢失目标行踪'};
  if(!inJurisdiction&&onDuty)return {chase:false,why:'已经离开执勤管辖区'};
  if(distance>range)return {chase:false,why:'距离超出搜索范围'};
  if(stamina<12)return {chase:false,why:'追击者体力不足'};
  if(minutesSpent>=timeBudget)return {chase:false,why:'时间预算耗尽'};
  if(injured&&risk>0)return {chase:false,why:'受伤后回避额外风险'};
  if(reward+personality-risk-(distance/range)*10<0)return {chase:false,why:'继续追击得不偿失'};
  return {chase:true,why:'有动机且有能力继续追击'};
}
