package com.xinyanshuo.zhiyin;

import android.content.Context;
import android.content.SharedPreferences;
import org.json.JSONObject;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Locale;

/**
 * Scene-first companion life simulator v0.3.
 *
 * Purely deterministic behaviour planner, NOT an LLM and NOT a claim of sentience.
 * A task has real stages, travel, inventory use, need changes and completion,
 * with persistent state and bounded elapsed-time simulation.
 */
public final class LifeEngine {
  public static final String[] ACTIONS={"REST","SLEEP","SHOP","COOK","EAT","WASH","READ",
    "PRACTICE","PIANO","WRITE","CLEAN","WATER","WINDOW","STRETCH","CHAT","WORK"};
  public static final String[] LABELS={"休息","睡觉","补充食材","做饭","吃饭","洗漱","阅读",
    "练习唱歌","弹琴","写日记","打扫房间","浇花","看风景","伸展运动","聊天","咖啡馆打工"};

  private static final long MAX_OFFLINE_MS=2L*60L*60L*1000L;
  private static final int MAX_STEPS=720;
  private final SharedPreferences pref;
  private final ArrayList<String> queuedEvents=new ArrayList<>();

  // 'hunger' is satiety (0 means very hungry).
  public float hunger=50,energy=79,hygiene=78,mood=73,social=68,skill=8;
  public int pantry=5,meals=0,dirtyDishes=0,money=180,readPages=0,completedSongs=0;
  public int sequence=0,phase=0, completedTasks=0;
  public static final int WEEKLY_RENT=160;
  public int rentArrears=0,rentPaid=0,workShifts=0,lastShiftDay=-1;
  public long nextRentAt=0;
  public String employment="河畔咖啡馆 · 兼职店员";
  public String action="REST",note="正在认识这间新房子。",goal="照顾自己，慢慢练好唱歌";
  public long lastTick=0,phaseStarted=0,phaseEnds=0;
  public boolean mealReady=false,wasOffline=false;
  private String suspended="", suspendedActionNote="";

  public LifeEngine(Context ctx){
    pref=ctx.getSharedPreferences("zhiyin_life_engine_v1",Context.MODE_PRIVATE);
    long now=System.currentTimeMillis();
    try{
      JSONObject j=new JSONObject(pref.getString("state","{}"));
      hunger=clamp(j.optDouble("hunger",50));energy=clamp(j.optDouble("energy",79));
      hygiene=clamp(j.optDouble("hygiene",78));mood=clamp(j.optDouble("mood",73));
      social=clamp(j.optDouble("social",68));skill=clamp(j.optDouble("skill",8));
      pantry=Math.max(0,j.optInt("pantry",5));meals=Math.max(0,j.optInt("meals",0));
      dirtyDishes=Math.max(0,j.optInt("dirtyDishes",0));money=Math.max(0,j.optInt("money",180));
      readPages=Math.max(0,j.optInt("readPages",0));completedSongs=Math.max(0,j.optInt("completedSongs",0));
      action=j.optString("action","REST");if(index(action)<0)action="REST";
      phase=Math.max(0,j.optInt("phase",0));sequence=Math.max(0,j.optInt("sequence",0));
      completedTasks=Math.max(0,j.optInt("completedTasks",0));
      rentArrears=Math.max(0,j.optInt("rentArrears",0));
      rentPaid=Math.max(0,j.optInt("rentPaid",0));
      workShifts=Math.max(0,j.optInt("workShifts",0));
      lastShiftDay=j.optInt("lastShiftDay",-1);
      nextRentAt=j.optLong("nextRentAt",0);
      lastTick=j.optLong("lastTick",now);phaseStarted=j.optLong("phaseStarted",0);phaseEnds=j.optLong("phaseEnds",0);
      note=j.optString("note",note);goal=j.optString("goal",goal);
      suspended=j.optString("suspended","");suspendedActionNote=j.optString("suspendedActionNote","");
      // Migrate from v0.2 (old state had "until" but no phaseEnds).
      if(phaseEnds<=0){phaseEnds=j.optLong("until",0);}
      if(!"{}".equals(pref.getString("state","{}")) && j.has("mealReady") && !j.has("meals")){
        meals=j.optBoolean("mealReady",false)?1:0;
      }
    }catch(Exception ignored){}
    if(lastTick<=0||lastTick>now)lastTick=now;
    if(nextRentAt<=0)nextRentAt=now+7L*24L*3600L*1000L;
    if(phaseEnds<=0){startTask("REST",now,"她正在熟悉新房间。");}
    update(now);
  }
  public static float clamp(double n){return (float)Math.max(0,Math.min(100,n));}
  private int index(String a){for(int i=0;i<ACTIONS.length;i++)if(ACTIONS[i].equals(a))return i;return -1;}
  public String label(){int i=index(action);return i>=0?LABELS[i]:"活动";}
  public static int phaseCount(String action){return phases(action).length;}
  public String phaseName(){
    String[] phases=phases(action);
    return phases[Math.min(phase,phases.length-1)];
  }
  public float phaseProgress(long now){
    long span=Math.max(1,phaseEnds-phaseStarted);
    return clamp(100d*(now-phaseStarted)/span);
  }
  public float targetX(){
    switch(action){
      case "SLEEP":return .17f;
      case "SHOP":case "WORK":return .97f;
      case "COOK":case "EAT":return phase==0&&"COOK".equals(action)?.94f:.83f;
      case "WASH":return .95f;
      case "READ":case "WRITE":return .70f;
      case "PIANO":case "PRACTICE":return .50f;
      case "WINDOW":return .26f;
      case "CLEAN":return phase%2==0?.42f:.65f;
      case "WATER":return .93f;
      case "STRETCH":return .43f;
      case "CHAT":return .51f;
      default:return .54f;
    }
  }
  public float targetY(){
    switch(action){
      case "SLEEP":return .75f;
      case "SHOP":case "WORK":return .60f;
      case "COOK":case "EAT":return .64f;
      case "WASH":return .52f;
      case "READ":case "WRITE":return .68f;
      case "PIANO":case "PRACTICE":return .73f;
      case "WINDOW":return .48f;
      case "WATER":return .81f;
      case "CLEAN":return .77f;
      case "STRETCH":return .78f;
      default:return .76f;
    }
  }
  public String summary(){
    return "正在"+phaseName()+" | 饱腹"+Math.round(hunger)+" 精力"+Math.round(energy)+
      " 清洁"+Math.round(hygiene)+" 心情"+Math.round(mood)+" 社交"+Math.round(social)+
      " 音乐"+Math.round(skill)+" | 食材"+pantry+" 餐食"+meals+" 碗碟"+dirtyDishes+" 存款"+money+
      " 周租"+WEEKLY_RENT+" 欠租"+rentArrears+" 已打工"+workShifts+"班";
  }
  private static String[] phases(String a){
    switch(a){
      case "SLEEP":return new String[]{"走到床边","整理被褥","安静入睡","醒来整理"};
      case "SHOP":return new String[]{"检查食材","前往收货柜","取回新鲜食材","整理储物"};
      case "COOK":return new String[]{"取出食材","清洗食材","切菜备料","点火烹饪","盛菜装盘"};
      case "EAT":return new String[]{"摆放餐具","慢慢吃饭","收拾桌面"};
      case "WASH":return new String[]{"走到洗漱台","整理头发","洗净双手","擦干收拾"};
      case "READ":return new String[]{"选一本书","专心阅读","记下心得"};
      case "PRACTICE":return new String[]{"调整呼吸","练习音阶","完整唱一段","记录练习"};
      case "PIANO":return new String[]{"打开琴谱","缓缓弹奏","练习难点","合上琴谱"};
      case "WRITE":return new String[]{"整理今天的思绪","写下心情","收好日记"};
      case "CLEAN":return new String[]{"整理床铺","清扫地面","擦拭桌面","收拾工具"};
      case "WATER":return new String[]{"取水壶","给植物浇水","查看叶片","放回水壶"};
      case "WINDOW":return new String[]{"走近窗边","看云与树影","放松心情"};
      case "STRETCH":return new String[]{"舒展双臂","活动腰背","深呼吸"};
      case "CHAT":return new String[]{"走到你身边","认真听你说话","陪伴聊天"};
      case "WORK":return new String[]{"步行前往咖啡馆","签到换工作服","接待顾客与整理吧台","结班领工资","走路回出租屋"};
      default:return new String[]{"坐下休息","整理计划","静静放松"};
    }
  }
  private static int[] durations(String a){
    switch(a){
      case "SLEEP":return new int[]{5,7,68,5};
      case "SHOP":return new int[]{5,7,9,7};
      case "COOK":return new int[]{8,9,11,23,7};
      case "EAT":return new int[]{5,21,6};
      case "WASH":return new int[]{5,8,9,5};
      case "READ":return new int[]{6,26,7};
      case "PRACTICE":return new int[]{7,15,20,8};
      case "PIANO":return new int[]{7,22,12,6};
      case "WRITE":return new int[]{7,23,7};
      case "CLEAN":return new int[]{10,12,11,7};
      case "WATER":return new int[]{6,9,6,4};
      case "WINDOW":return new int[]{6,24,5};
      case "STRETCH":return new int[]{7,9,7};
      case "CHAT":return new int[]{3,13,20};
      case "WORK":return new int[]{7,12,31,8,7};
      default:return new int[]{5,12,9};
    }
  }
  public void update(long now){
    if(now<=lastTick)return;
    settleRent(now);
    long elapsed=now-lastTick;
    wasOffline=elapsed>MAX_OFFLINE_MS;
    // Avoid unbounded loops and unrealistic simulated years after a long absence.
    long from=wasOffline?now-MAX_OFFLINE_MS:lastTick;
    long cursor=from;
    int count=0;
    while(cursor<now && count<MAX_STEPS){
      if(phaseEnds<=cursor){
        advance(cursor);
        count++;continue;
      }
      long limit=Math.min(now,phaseEnds);
      double minutes=(limit-cursor)/60000d;
      decay(minutes);
      cursor=limit;
      if(cursor>=phaseEnds){advance(cursor);count++;}
    }
    if(count>=MAX_STEPS){
      phaseStarted=now;
      phaseEnds=now+durations(action)[Math.min(phase,durations(action).length-1)]*1000L;
      queuedEvents.add("生活记录：模拟步骤达到上限，已安全跳到当前时间，剩余时段不作虚构。");
    }
    if(wasOffline)queuedEvents.add("离线续接：超过两小时的区间已限制补算，避免错误生成大量虚构事件。");
    lastTick=now;
    save();
  }
  private void settleRent(long now){
    // Real calendar-based weekly rent; never makes up a salary for unattended days.
    int safety=0;
    while(nextRentAt<=now && safety++<12){
      rentArrears=Math.min(1000000,rentArrears+WEEKLY_RENT);
      nextRentAt+=7L*24L*3600L*1000L;
      queuedEvents.add("房租账单：临河巷单间10.24㎡，本周应付"+WEEKLY_RENT+"，待付"+rentArrears+"。");
    }
    if(safety>=12 && nextRentAt<=now){
      long missed=(now-nextRentAt)/(7L*24L*3600L*1000L)+1;
      rentArrears=(int)Math.min(1000000L,rentArrears+missed*WEEKLY_RENT);
      nextRentAt+=missed*7L*24L*3600L*1000L;
      queuedEvents.add("长时间离线：房租按照实日结算"+missed+"个账期；没有凭空补发收入。");
    }
    if(rentArrears>0 && money>=rentArrears){
      int due=rentArrears;money-=due;rentPaid+=due;rentArrears=0;
      queuedEvents.add("支付房租"+due+"；余额"+money+"。");
    }
  }
  private int todayKey(long when){
    Calendar cal=Calendar.getInstance();cal.setTimeInMillis(when);
    return cal.get(Calendar.YEAR)*400+cal.get(Calendar.DAY_OF_YEAR);
  }
  public long daysUntilRent(long now){
    return Math.max(0,(nextRentAt-now+86400000L-1)/86400000L);
  }
  private void decay(double min){
    if(min<=0)return;
    hunger=clamp(hunger-min*.28);
    energy=clamp(energy-min*("SLEEP".equals(action)?-1.15:.22));
    hygiene=clamp(hygiene-min*.12);social=clamp(social-min*.12);
    mood=clamp(mood-min*.08);
  }
  private void advance(long when){
    if(phaseEnds<=0){startTask("REST",when,"先休息一下");return;}
    if(phase<phases(action).length-1){
      phase++;beginPhase(when);return;
    }
    String finished=action;
    complete(finished);
    completedTasks++;
    queuedEvents.add("完成"+name(finished)+"；"+resultOf(finished));
    if(!suspended.isEmpty() && !"CHAT".equals(finished)){
      suspended="";
    }
    if("CHAT".equals(finished)&&!suspended.isEmpty()&&
      hunger>=24&&energy>=20){
      String returning=suspended;suspended="";startTask(returning,when,"聊天结束，继续之前的"+name(returning));
      return;
    }
    suspended="";
    choose(when);
  }
  private void complete(String a){
    switch(a){
      case "COOK":
        if(pantry>0){pantry--;meals=Math.min(40,meals+1);mood=clamp(mood+2);}break;
      case "SHOP":
        int count=Math.min(8,Math.max(0,money/4));
        pantry=Math.min(45,pantry+count);money-=4*count;break;
      case "EAT":
        if(meals>0){meals--;dirtyDishes++;hunger=clamp(hunger+48);mood=clamp(mood+4);}break;
      case "WASH":hygiene=clamp(hygiene+43);break;
      case "SLEEP":energy=clamp(energy+58);mood=clamp(mood+8);break;
      case "REST":energy=clamp(energy+14);break;
      case "READ":readPages+=9;skill=clamp(skill+0.6);mood=clamp(mood+3);break;
      case "PIANO":skill=clamp(skill+1.6);mood=clamp(mood+5);break;
      case "PRACTICE":completedSongs++;skill=clamp(skill+1.8);energy=clamp(energy-3);mood=clamp(mood+3);break;
      case "WRITE":mood=clamp(mood+5);social=clamp(social+2);break;
      case "CLEAN":dirtyDishes=Math.max(0,dirtyDishes-2);hygiene=clamp(hygiene+7);break;
      case "WATER":mood=clamp(mood+7);break;
      case "WINDOW":mood=clamp(mood+6);break;
      case "STRETCH":energy=clamp(energy+7);mood=clamp(mood+3);break;
      case "CHAT":social=clamp(social+19);mood=clamp(mood+6);break;
      case "WORK":
        int day=todayKey(System.currentTimeMillis());
        if(lastShiftDay!=day){
          lastShiftDay=day;
          workShifts++;money=Math.min(999999,money+64);
          energy=clamp(energy-13);hygiene=clamp(hygiene-7);
          mood=clamp(mood-3);
          queuedEvents.add("工资到账：咖啡馆兼职一班 +64，累计"+workShifts+"班。");
        }else queuedEvents.add("同一天重复班次仅体验工作流程，不重复发放工资。");
        if(rentArrears>0 && money>=rentArrears){
          int due=rentArrears;money-=due;rentPaid+=due;rentArrears=0;
          queuedEvents.add("到账后自动缴纳房租"+due+"，余额"+money+"。");
        }break;
    }
  }
  private String resultOf(String a){
    switch(a){
      case "COOK":return "餐食+"+(meals>0?1:0)+"，库存食材"+pantry;
      case "SHOP":return "食材"+pantry+"，金币"+money;
      case "EAT":return "饱腹"+Math.round(hunger);
      case "SLEEP":return "体力"+Math.round(energy);
      case "PRACTICE":return "已练习"+completedSongs+"次";
      case "PIANO":return "音乐熟练度"+Math.round(skill);
      case "READ":return "累计阅读"+readPages+"页";
      case "WORK":return "咖啡馆兼职"+workShifts+"班，存款"+money+"，房租欠款"+rentArrears;
      default:return "心情"+Math.round(mood);
    }
  }
  private String name(String a){int i=index(a);return i>=0?LABELS[i]:a;}
  private int clockHour(long when){
    Calendar c=Calendar.getInstance();c.setTimeInMillis(when);return c.get(Calendar.HOUR_OF_DAY);
  }
  private void choose(long when){
    int hour=clockHour(when);String selected;
    if((hour>=23||hour<7)&&energy<90)selected="SLEEP";
    else if(energy<19)selected="SLEEP";
    else if(hunger<54 && meals>0)selected="EAT";
    else if(hunger<54 && pantry>0)selected="COOK";
    else if(hunger<54 && money>=4)selected="SHOP";
    else if(hunger<54)selected=lastShiftDay!=todayKey(when)?"WORK":"REST";
    else if(hygiene<43)selected="WASH";
    else if(dirtyDishes>3)selected="CLEAN";
    else if(energy<39)selected="REST";
    else if(social<34)selected="CHAT";
    else if(pantry==0&&money>=4)selected="SHOP";
    else if(money<16&&lastShiftDay!=todayKey(when))selected="WORK";
    else if(hour>=8&&hour<18&&lastShiftDay!=todayKey(when)&&energy>=37&&hunger>=43)selected="WORK";
    else if(hour>=22&&energy<85)selected="SLEEP";
    else {
      String[] morning={"WASH","WATER","STRETCH","READ","WRITE","PIANO"};
      String[] daytime={"PRACTICE","READ","PIANO","CLEAN","WRITE","STRETCH","WATER","WINDOW"};
      String[] evening={"PIANO","PRACTICE","WRITE","READ","WINDOW","REST"};
      String[] pick=hour<10?morning:hour<18?daytime:evening;
      selected=pick[(sequence/3+completedTasks*7)%pick.length];
    }
    startTask(selected,when,"我想先"+name(selected)+"，之后再看看今天还需要做什么。");
  }
  private void startTask(String next,long when,String reason){
    if(index(next)<0)next="REST";
    action=next;phase=0;note=reason;
    beginPhase(when);
  }
  private void beginPhase(long when){
    phase=Math.max(0,Math.min(phase,phases(action).length-1));
    phaseStarted=when;
    int[] ds=durations(action);
    phaseEnds=when+ds[Math.min(phase,ds.length-1)]*1000L;
    note=phaseName()+"。";
    sequence++;
    queuedEvents.add("她开始"+name(action)+"："+phaseName()+"。");
  }
  public String request(String next){
    if(index(next)<0)throw new IllegalArgumentException("未知行为");
    long now=System.currentTimeMillis();update(now);
    // Never conjure food when the player requests an impossible action.
    if("COOK".equals(next)&&pantry==0)next=money>=4?"SHOP":lastShiftDay!=todayKey(now)?"WORK":"REST";
    if("EAT".equals(next)&&meals==0)next=pantry>0?"COOK":money>=4?"SHOP":lastShiftDay!=todayKey(now)?"WORK":"REST";
    if(!"CHAT".equals(action)&&"CHAT".equals(next))suspended=action;
    else if(!"CHAT".equals(next))suspended="";
    startTask(next,now,"你邀请她"+name(next));save();return note;
  }
  public ArrayList<String> drainEvents(){
    ArrayList<String> a=new ArrayList<>(queuedEvents);queuedEvents.clear();return a;
  }
  public String toJson(){
    try{
      JSONObject j=new JSONObject();
      j.put("hunger",hunger);j.put("energy",energy);j.put("hygiene",hygiene);
      j.put("mood",mood);j.put("social",social);j.put("skill",skill);
      j.put("pantry",pantry);j.put("meals",meals);j.put("dirtyDishes",dirtyDishes);
      j.put("money",money);j.put("readPages",readPages);j.put("completedSongs",completedSongs);
      j.put("sequence",sequence);j.put("phase",phase);j.put("completedTasks",completedTasks);
      j.put("rentArrears",rentArrears);j.put("rentPaid",rentPaid);j.put("workShifts",workShifts);
      j.put("lastShiftDay",lastShiftDay);j.put("nextRentAt",nextRentAt);
      j.put("action",action);j.put("note",note);j.put("goal",goal);j.put("suspended",suspended);
      j.put("suspendedActionNote",suspendedActionNote);
      j.put("lastTick",lastTick);j.put("phaseStarted",phaseStarted);j.put("phaseEnds",phaseEnds);
      return j.toString();
    }catch(Exception ex){throw new IllegalStateException(ex);}
  }
  public void save(){pref.edit().putString("state",toJson()).apply();}
}
