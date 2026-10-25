import {createHash} from 'node:crypto';
const sha = x => createHash('sha256').update(x).digest('hex');
const integer = (x, min, max, name) => {
  if(!Number.isSafeInteger(x)||x<min||x>max) throw Error('INVALID_'+name);
  return x;
};
// CANDIDATE ONLY: no writes to authoritative save.
export function verifyRootReveal(commitment, reveal) {
  if(!/^[0-9a-f]{64}$/.test(commitment||'')) throw Error('INVALID_ROOT_COMMITMENT');
  if(typeof reveal!=='string'||!reveal.length) throw Error('MISSING_ROOT_REVEAL');
  if(sha(reveal)!==commitment) throw Error('ROOT_REVEAL_MISMATCH');
  return true;
}
export function simulateCultivationDays(input) {
  const {worldSeed,rootCommitment,rootReveal,manual,rootGrade,comprehension,startDay,days,householdGrainMillidou,playerStamina,sibling}=input;
  verifyRootReveal(rootCommitment,rootReveal);
  if(!manual?.authenticated||manual.id!=='weathered_qi_primer') throw Error('MANUAL_UNVERIFIED');
  if(typeof worldSeed!=='string'||!worldSeed.length) throw Error('MISSING_WORLD_SEED');
  integer(rootGrade,0,5,'ROOT_GRADE'); integer(comprehension,0,100,'COMPREHENSION');
  integer(startDay,1,100000,'DAY'); integer(days,1,30,'DAYS');
  integer(householdGrainMillidou,0,100000000,'GRAIN'); integer(playerStamina,0,100,'STAMINA');
  if(!sibling||typeof sibling!=='object') throw Error('NPC_DATA_MISSING');
  integer(sibling.comprehension,0,100,'NPC_COMPREHENSION');
  if(typeof sibling.consent!=='boolean') throw Error('NPC_CONSENT_MISSING');
  const dailyGrain=108; // EXPERIMENTAL: NOT YET APPROVED AS LIVE DAILY RATION.
  if(householdGrainMillidou<days*dailyGrain) throw Error('INSUFFICIENT_HOUSEHOLD_GRAIN');
  let grain=householdGrainMillidou,stamina=playerStamina,successDay=null;
  const ledger=[];
  for(let i=0;i<days;i++) {
    const day=startDay+i,before=grain;
    grain-=dailyGrain;
    stamina=Math.min(100,stamina+48); // EXPERIMENTAL REST CONSTANT.
    const chance=rootGrade===0?0:Math.min(850,rootGrade*65+Math.floor(comprehension*1.5));
    const roll=Number(BigInt('0x'+sha(worldSeed+'|cultivate|CFPLAYER00001|'+day+'|v1'))%1000n);
    const succeeds=successDay===null&&roll<chance;
    if(succeeds) successDay=day;
    ledger.push({day,grainBefore:before,grainConsumed:dailyGrain,grainAfter:grain,staminaAfterSleep:stamina,playerRoll:roll,playerChancePermille:chance,playerBreakthrough:succeeds,npcLearningStatus:sibling.consent?'STUDY_ONLY_NOT_ASSESSED':'DECLINED'});
    if(succeeds) break;
  }
  return {schema:'xianfan.cultivation.candidate.v1',authoritative:false,successDay,daysSimulated:ledger.length,ledger,grainRemaining:grain,warning:'Candidate calculation. Not a game save; requires confirmed manual, root reveal, daily simulation and NPC audits.'};
}
