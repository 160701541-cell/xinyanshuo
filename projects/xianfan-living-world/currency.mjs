// 《仙凡共生》钱币：铜→银→金→灵石，百进制，但灵石不是钱。
// 世俗里灵石“有价无市”：不是没有，是修士不肯拿它换金银。只有官营钱庄肯兑，收 5% 手续费。
import {note} from './core.mjs';
import {ensureFin} from './units.mjs';

export const RATES={copper:1,silver:100,gold:10000,stone:1000000}; // 1 灵石 = 100 金 = 1 万银 = 100 万铜
export const BANK_FEE=.05;      // 官营钱庄兑换手续费
export const BANK_QUOTA=20;     // 每月可兑灵石上限（官庄库存有限）

export function ensureCurrency(w){
 if(!w.currency)w.currency={stones:4,month:1,bankQuota:BANK_QUOTA,coins:0};
 return w.currency;
}
export function fmtCoins(n){
 if(n>=RATES.gold)return `${(n/RATES.gold).toFixed(n%RATES.gold?2:0)} 金`;
 if(n>=RATES.silver)return `${(n/RATES.silver).toFixed(n%RATES.silver?2:0)} 银`;
 return `${Math.round(n)} 铜`;
}
/** 官府/钱庄换灵石：**只有这一条路**。铜文 → 灵石，扣 5% 手续费，且撞月额度。 */
export function buyStones(w,stones){
 const c=ensureCurrency(w);stones=Math.round(stones);
 if(stones<=0)return {ok:false,error:'数额无效'};
 if(stones>c.bankQuota)return {ok:false,error:`官庄本月仅能兑 ${c.bankQuota} 块灵石（库存与朝廷管制）`};
 const cost=Math.round(stones*RATES.stone*(1+BANK_FEE));
 ensureFin(w);const p=w.states.court;
 if(p.treasury<cost)return {ok:false,error:`府库不足：需 ${fmtCoins(cost)}（含 5% 手续费）`};
 p.treasury-=cost;c.bankQuota-=stones;c.stones+=stones;
 note(w,'钱庄',`官庄兑出 ${stones} 块灵石，收 ${fmtCoins(cost)}，手续费 ${Math.round(BANK_FEE*100)}%。`);
 return {ok:true,stones,cost,fee:Math.round(cost-stones*RATES.stone)};
}
export function sellStones(w,stones){
 return {ok:false,error:'灵石有价无市：修士不肯拿它换金银，官庄也不收——除非朝廷肯折价强征。'};
}
/** 每月初：官庄额度重置；若有灵脉在手，朝廷按月进灵石。 */
export function tickCurrency(w){
 const c=ensureCurrency(w);
 c.month++;
 c.bankQuota=BANK_QUOTA;
 const income=stoneIncome(w);
 c.stones+=income;
 return {stones:c.stones,income,quota:c.bankQuota};
}
export function stoneIncome(w){
 let n=0;
 for(const s of w.xian?.sects||[])if(s.patron==='court'&&!s.destroyed)n+=4;
 if(w.xian?.veinMine)n+=6;
 return n;
}
export function moneyReport(w){
 const c=ensureCurrency(w);
 ensureFin(w);
 return {stones:c.stones,coins:w.states.court.treasury,quota:c.bankQuota,
  stonePrice:Math.round(RATES.stone*(1+BANK_FEE)),
  income:stoneIncome(w),fee:BANK_FEE};
}
