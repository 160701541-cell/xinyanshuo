// Pure transaction preview; never directly alters the authoritative save.
export function adjudicateWayfarerPurchase(state,offer,consent) {
 const fail=c=>{throw Error(c)};
 if(!state?.player||!state.time||!Array.isArray(state.inventory))fail('BAD_STATE');
 if(state.player.id!=='CFPLAYER00001'||state.time.day!==2||state.time.hour!==11||state.time.minute!==14||state.current_location!=='linan')fail('SCENE_CHANGED');
 if(offer?.vendor_id!=='CFNPC00008'||offer.item_id!=='weathered_qi_primer'||offer.available!==1||offer.price!==2||offer.authenticity!=='unknown')fail('INVALID_OFFER');
 if(!consent?.encounterConfirmed||!consent?.sellerAgrees)fail('NPC_CONSENT_REQUIRED');
 if(state.player.money<2)fail('INSUFFICIENT_FUNDS');
 if(state.inventory.some(x=>x.id==='weathered_qi_primer'))fail('ITEM_ALREADY_OWNED');
 if(state.economy?.wayfarers?.CFNPC00008)fail('VENDOR_EXISTING_ACCOUNT');
 const s=JSON.parse(JSON.stringify(state)),before=s.player.money;
 s.player.money-=2;
 s.inventory.push({id:'weathered_qi_primer',name:'《引气初篇》',category:'书籍',quantity:1,authenticity:'unknown',source:'CFNPC00008'});
 s.economy ??={};s.economy.wayfarers ??={};
 s.economy.wayfarers.CFNPC00008={id:'CFNPC00008',opening_cash:0,cash:2,opening_stock:{weathered_qi_primer:1},stock:{weathered_qi_primer:0},identity:'unverified_wayfarer'};
 s.time.minute=23;s.time.display='承平三年 · 第2日 · 11:23';
 return {authoritative:false,after:s,receipt:{from:'CFPLAYER00001',to:'CFNPC00008',item_id:'weathered_qi_primer',count:1,wen:2,buyer_cash_before:before,buyer_cash_after:0,seller_cash_before:0,seller_cash_after:2,stock_before:1,stock_after:0,minutes:9,authenticity:'unknown'}};
}
