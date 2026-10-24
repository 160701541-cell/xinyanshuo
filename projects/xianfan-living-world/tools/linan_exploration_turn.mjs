import {digest,verifyEvents,countTurns} from './campaign_guard.mjs';
import {verifyNumericState} from './numeric_accounts.mjs';
export const VERSION='linan-street-exploration-1.0.0';
export const CITY_BLOCKS=Object.freeze([
 {id:'LINAN-GOVT-STREET',name:'县衙前街',x:170,y:310,category:'administrative_street',visible:'道路向县衙方向延伸；衙门内部、当值官员身份尚未查明'},
 {id:'LINAN-ARTISAN-LANE',name:'匠人巷口',x:190,y:355,category:'workshops',visible:'有敲打木料的声响，远远能见到做活的棚屋；不自动假设有免费工具'},
 {id:'LINAN-NORTH-ALLEY',name:'北巷',x:208,y:385,category:'residential',visible:'临街院门与民居，院内不可擅闯'},
 {id:'LINAN-EAST-MARKET',name:'东市',x:220,y:490,category:'market',visible:'先前交易过的药材、渔具、菜肉与种子摊'},
]);
export function exploreCityStreets(before,events){
 verifyEvents(events);verifyNumericState(before);
 if(countTurns(events)!==12||events.at(-1)?.state_hash!==digest(before))throw Error('WRONG_CURRENT_SAVE');
 if(before.location_id!=='linan')throw Error('NOT_IN_CITY');
 if(before.city_exploration?.["day2-street-walk"])throw Error('REPLAY');
 const s=structuredClone(before);
 if(s.player.stamina<3)throw Error('LOW_STAMINA');
 const minutes=35,cost=3;
 const t=s.time.hour*60+s.time.minute+minutes;
 if(t>=1440)throw Error('CROSS_DAY_UNAVAILABLE');
 s.time.hour=Math.floor(t/60);s.time.minute=t%60;
 s.time.display='承平三年 · 第'+s.time.day+'日 · '+String(s.time.hour).padStart(2,'0')+':'+String(s.time.minute).padStart(2,'0');
 s.player.stamina-=cost;
 s.city_exploration=s.city_exploration||{};
 s.city_exploration["day2-street-walk"]={version:VERSION,from:'LINAN-EAST-MARKET',stopped_at:'LINAN-ARTISAN-LANE',
  seen:CITY_BLOCKS.filter(x=>x.id!=='LINAN-EAST-MARKET'),visited_day:s.time.day,
  time:s.time.display,access:'public streets only',trades:0,conversation_outcomes:0};
 s.current_location='临安县城·匠人巷口';s.sub_location='临安县城·匠人巷口';
 s.position={x:190,y:355};
 s.last_event_id='EV'+String(events.length+1).padStart(6,'0');
 verifyNumericState(s);
 const ev={seq:events.length+1,prev_hash:events.at(-1).hash,type:'turn_committed',
 turn_id:countTurns(events)+1,action:'walk_public_linan_streets',rule_version:VERSION,
 destination:'LINAN-ARTISAN-LANE',observed:CITY_BLOCKS.filter(x=>x.id!=='LINAN-EAST-MARKET').map(x=>({id:x.id,name:x.name,category:x.category,visible:x.visible})),
 before:{time:before.time.display,stamina:before.player.stamina,money:before.player.money},
 after:{time:s.time.display,stamina:s.player.stamina,money:s.player.money},cost:{minutes,stamina:cost},
 transactions:[],items_gained:[],secrets_revealed:[],state_hash:digest(s)};
 ev.hash=digest(ev);
 return{state:s,events:[...events,ev],event:ev};
}
