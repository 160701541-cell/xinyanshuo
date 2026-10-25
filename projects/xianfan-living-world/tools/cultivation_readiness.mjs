// Pure, conservative readiness audit. Does not mutate authoritative state.
export function auditCultivationReadiness({state,index,manualEvidence=null,rootEvidence=null,dailyRule=null,npcRule=null,routeRule=null,tradeRule=null}) {
  if(!state||!index||!state.player||!state.time) throw Error('SAVE_DATA_MISSING');
  if(index.last_event!==(state.last_event_id||'') ) throw Error('EVENT_INDEX_STATE_MISMATCH');
  if(state.player.id!=='CFPLAYER00001') throw Error('PLAYER_ID_MISMATCH');
  const blockers=[];
  const demand=(condition,code,why)=>{if(!condition)blockers.push({code,why});};
  const inventory=state.inventory||[];
  const ownsManual=inventory.some(x=>x.id==='weathered_qi_primer'&&x.quantity>=1);
  demand(!!tradeRule?.registeredVendor&&!!tradeRule?.balancedTransfer&&!!tradeRule?.registeredStock,'TRADE_NOT_IMPLEMENTED','必须登记游方道士的身份、库存与2文双向转移');
  demand(ownsManual,'MANUAL_NOT_OWNED','权威背包尚无《引气初篇》');
  demand(!!manualEvidence?.authenticated&&manualEvidence?.id==='weathered_qi_primer','MANUAL_AUTHENTICITY_UNKNOWN','旧书籍未通过有来源的鉴定');
  demand(!!routeRule?.travel&&!!routeRule?.time&&!!routeRule?.stamina,'RETURN_HOME_RULE_MISSING','县城返乡的路径、时间与精力必须有证据');
  demand(!!dailyRule?.dayBoundary&&!!dailyRule?.foodSource&&!!dailyRule?.sleep&&!!dailyRule?.ecology&&!!dailyRule?.npcContinuity,'CROSS_DAY_RULES_MISSING','需实现跨日饮食睡眠、生态及NPC日程');
  demand(!!rootEvidence?.matchesOriginalCommitment&&!!rootEvidence?.generationProtocolVerified,'ROOT_REVEAL_NOT_VERIFIED','必须使用原开局承诺及其原始生成算法，禁止另抽');
  demand(!!npcRule?.autonomousChoices&&!!npcRule?.knowledgeVisibility,'NPC_RULE_MISSING','NPC必须独立做决定并区分可见信息');
  return {schema:'xianfan.cultivation.readiness.v1',authoritative:false,lastEvent:index.last_event,at:state.time.display,ready:blockers.length===0,blockers,allowSaveMutation:false};
}
