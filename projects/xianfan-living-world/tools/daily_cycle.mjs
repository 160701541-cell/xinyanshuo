// 《仙凡·苍岚》文字战役：跨日生活结算 v1
// numeric_engine.mjs 的 advance() 明确拒绝跨日（DAILY_SIM_NOT_IMPLEMENTED），
// 本模块就是补上那一段：睡眠、三餐、家庭粮账、每日天气、NPC 作息推演。
// 常量优先取自 data/day2_home_and_county_rules_v1.json；未定义项在此版本化声明。
import { createHash } from 'node:crypto';

export const DAILY_VERSION = 'daily-cycle-1.0.0';
const sha = x => createHash('sha256').update(x).digest('hex');
const round1 = x => Math.round(x*10)/10;

export const MILLIDOU_PER_DOU = 1000;                 // day2: grain_conversion_millidou_per_dou
export const SLEEP_STAMINA_PER_10MIN = 1;             // day2: sleep_stamina_per_10min
export const MEAL_STAMINA_GAIN = 4;                   // day2: meal_stamina_gain
export const REST_MERIDIAN_PER_HOUR = 2.2;            // cultivation.mjs: restMeridian()
export const MEALS = {                                // day2 已定义早晚；午饭沿用晚饭份量并在 v1 中声明
  breakfast:{ clock:390, minutes:15, millidouPerPerson:12, source:'day2.morning.morning_food_millidou_per_person' },
  lunch:    { clock:720, minutes:30, millidouPerPerson:15, source:'daily-cycle-v1 derived from meal_grain_millidou_per_person' },
  dinner:   { clock:1080, minutes:30, millidouPerPerson:15, source:'day2.night.meal_grain_millidou_per_person' }
};

const WEATHER_TABLE = ['晴','晴','晴','多云','多云','阴','小雨'];
export const dailyWeather = (seed, day) =>
  WEATHER_TABLE[Number(BigInt('0x'+sha(seed+'|weather|day'+day+'|v1')) % BigInt(WEATHER_TABLE.length))];

export const clockOf = t => (t.day-1)*1440 + t.hour*60 + t.minute;
export function stampOf(t) {
  const y = t.regnal_year===3 ? '三' : t.regnal_year;
  return '承平'+y+'年 · 第'+t.day+'日 · ' +
         String(t.hour).padStart(2,'0')+':'+String(t.minute).padStart(2,'0');
}
/** 推进世界时间；跨过几次日界由调用方显式补结算。 */
export function advanceTime(time, minutes) {
  if (!Number.isInteger(minutes) || minutes < 0) throw Error('INVALID_MINUTES');
  const startDay = time.day;
  const abs = clockOf(time) + minutes;
  const day = Math.floor(abs/1440) + 1;
  const rest = abs % 1440;
  time.day = day;
  time.hour = Math.floor(rest/60);
  time.minute = rest % 60;
  time.display = stampOf(time);
  const crossed = [];
  for (let d = startDay+1; d <= day; d++) crossed.push(d);
  return { crossed };
}

export function grainMillidou(family) {
  return (family.grain_dou||0) * MILLIDOU_PER_DOU + (family.grain_remainder_millidou||0);
}

export function debitGrain(family, millidou) {
  const total = grainMillidou(family) - millidou;
  if (total < 0) throw Error('INSUFFICIENT_HOUSEHOLD_GRAIN');
  family.grain_dou = Math.floor(total / MILLIDOU_PER_DOU);
  family.grain_remainder_millidou = total % MILLIDOU_PER_DOU;
  return total;
}

/** 一次进餐：从家庭粮账扣减，给玩家补精力。家人同吃同扣。 */
export function meal(state, kind, people) {
  const m = MEALS[kind];
  if (!m) throw Error('UNKNOWN_MEAL');
  const cup = people || 4;
  const millidou = m.millidouPerPerson * cup;
  const before = grainMillidou(state.family);
  debitGrain(state.family, millidou);
  const staminaBefore = state.player.stamina;
  state.player.stamina = Math.min(state.player.max_stamina, staminaBefore + MEAL_STAMINA_GAIN);
  advanceTime(state.time, m.minutes);
  return { kind, minutes:m.minutes, millidou_consumed:millidou, people:cup,
           grain_before:before, grain_after:grainMillidou(state.family),
           stamina_before:staminaBefore, stamina_after:state.player.stamina,
           rule:m.source };
}

/** 睡眠：补精力、清经脉负荷。入静不等于睡眠，两者不可互相顶替。 */
export function sleep(state, opts) {
  const untilClock = opts && opts.untilClock !== undefined ? opts.untilClock : 360;
  const now = clockOf(state.time);
  let minutes = untilClock - (now % 1440);
  if (minutes <= 0) minutes += 1440;
  const staminaBefore = state.player.stamina;
  const gain = Math.floor(minutes/10) * SLEEP_STAMINA_PER_10MIN;
  state.player.stamina = Math.min(state.player.max_stamina, staminaBefore + gain);
  const meridianBefore = state.practice ? state.practice.meridian : 0;
  const hours = round1(minutes/60);
  if (state.practice) state.practice.meridian = Math.max(0, round1(meridianBefore - hours*REST_MERIDIAN_PER_HOUR));
  const startDay = state.time.day;
  advanceTime(state.time, minutes);
  return { minutes, hours, stamina_before:staminaBefore, stamina_after:state.player.stamina,
           stamina_gain:state.player.stamina-staminaBefore,
           meridian_before:meridianBefore, meridian_after:state.practice ? state.practice.meridian : 0,
           woke_day:state.time.day, days_crossed:state.time.day-startDay };
}

/** 日界结算：天气按世界种子确定，不因玩家愿望改变。 */
export function dayRollover(state, day) {
  const weather = dailyWeather(state.world_seed, day);
  state.time.weather = weather;
  return { day, weather };
}

/** 家庭作息推演：家人按自己的生活节奏行动，与玩家是否在场无关。 */
export function householdRhythm(state, day) {
  const plan = {
    CFNPC00001: [{ at:'05:50', act:'挑担下田，秋后修渠' }, { at:'12:00', act:'田头吃干粮' },
                 { at:'18:20', act:'收工回家' }],
    CFNPC00002: [{ at:'05:30', act:'起灶、烧水、备早饭' }, { at:'09:00', act:'晒谷、择菜' },
                 { at:'17:00', act:'做晚饭' }, { at:'20:00', act:'缝补' }],
    CFNPC00003: [{ at:'06:00', act:'起床、帮母亲端饭' }, { at:'09:30', act:'去河边洗衣、挑水' },
                 { at:'15:00', act:'院内择菜、搓麻线' }, { at:'19:30', act:'听兄长说话' }]
  };
  return { day, plan, certainty:'inferred_from_household_rhythm',
           note:'按家庭分工推演，不等于玩家亲见；具体行为仍由 NPC 自行决定' };
}
