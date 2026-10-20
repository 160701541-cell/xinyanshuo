package com.xinyanshuo.zhiyin;

import android.content.Context;
import android.content.SharedPreferences;
import org.json.JSONObject;
import java.util.Calendar;

/**
 * Offline-first, deterministic needs + goal-driven scheduling.
 * Independent of any LLM: do not label these behaviours "AI reasoning".
 */
public final class LifeEngine {
  public static final String[] LABELS={"休息","睡觉","做饭","吃饭","洗漱","阅读","练习唱歌","弹琴","写日记","打扫房间","浇花","看风景","伸展运动","聊天"};
  public static final String[] ACTIONS={"REST","SLEEP","COOK","EAT","WASH","READ","PRACTICE","PIANO","WRITE","CLEAN","WATER","WINDOW","STRETCH","CHAT"};
  private final SharedPreferences pref;
  public float hunger=73,energy=83,hygiene=82,mood=77,social=68,skill=8;
  public long lastTick,lastDecision,until; public int sequence=0;
  public String action="REST", note="今天也想把生活过得认真一点。",goal="适应新家";
  public boolean mealReady=false;
  private boolean dirty=false;

  public LifeEngine(Context ctx){
    pref=ctx.getSharedPreferences("zhiyin_life_engine_v1",Context.MODE_PRIVATE);
    long now=System.currentTimeMillis();
    try{
      JSONObject j=new JSONObject(pref.getString("state","{}"));
      hunger=(float)j.optDouble("hunger",73);energy=(float)j.optDouble("energy",83);hygiene=(float)j.optDouble("hygiene",82);
      mood=(float)j.optDouble("mood",77);social=(float)j.optDouble("social",68);skill=(float)j.optDouble("skill",8);
      lastTick=j.optLong("lastTick",now);lastDecision=j.optLong("lastDecision",0);until=j.optLong("until",0);
      sequence=j.optInt("sequence",0);action=j.optString("action","REST");note=j.optString("note",note);
      goal=j.optString("goal",goal);mealReady=j.optBoolean("mealReady",false);
    }catch(Exception ignored){}
    if(lastTick>now){lastTick=now;}update(now);
  }
  public static float clamp(double v){return (float)Math.max(0,Math.min(100,v));}
  public String label(){for(int i=0;i<ACTIONS.length;i++)if(ACTIONS[i].equals(action))return LABELS[i];return "活动";}
  public float targetX(){
    switch(action){case "SLEEP":return .16f;case "COOK":case "EAT":return .82f;case "WASH":return .90f;
      case "READ":case "WRITE":return .69f;case "PIANO":case "PRACTICE":return .49f;
      case "WINDOW":return .27f;case "CLEAN":return .56f;case "WATER":return .93f;
      case "STRETCH":return .43f;case "CHAT":return .48f;default:return .53f;}
  }
  public float targetY(){
    switch(action){case "SLEEP":return .72f;case "COOK":case "EAT":return .64f;case "WASH":return .52f;
      case "READ":case "WRITE":return .63f;case "PIANO":case "PRACTICE":return .69f;
      case "WINDOW":return .47f;case "WATER":return .78f;default:return .73f;}
  }
  public void update(long now){
    if(now<=lastTick)return;
    double minutes=Math.min(24*60,(now-lastTick)/60000.0);
    if(minutes>0){
      hunger=clamp(hunger-minutes*0.18);
      hygiene=clamp(hygiene-minutes*0.13);
      social=clamp(social-minutes*0.08);
      energy=clamp(energy-minutes*("SLEEP".equals(action)?-0.70:0.17));
      mood=clamp(mood-minutes*0.045);
      switch(action){
        case "EAT":hunger=clamp(hunger+minutes*.9);break;
        case "WASH":hygiene=clamp(hygiene+minutes*1.2);break;
        case "REST":energy=clamp(energy+minutes*.35);break;
        case "PRACTICE":case "PIANO":skill=clamp(skill+minutes*.06);mood=clamp(mood+minutes*.15);break;
        case "READ":skill=clamp(skill+minutes*.024);break;
        case "CHAT":social=clamp(social+minutes*1);break;
        case "WATER":case "CLEAN":mood=clamp(mood+minutes*.1);break;
      }
    }
    lastTick=now;
    if(now>=until)decide(now);
    if(now-lastDecision>=20000L){save();lastDecision=now;}
  }
  private int hour(long t){Calendar c=Calendar.getInstance();c.setTimeInMillis(t);return c.get(Calendar.HOUR_OF_DAY);}
  private void decide(long now){
    String next;
    int h=hour(now);
    if(((h>=23||h<7)&&energy<97)||energy<19)next="SLEEP";
    else if(hunger<42)next=mealReady?"EAT":"COOK";
    else if(hygiene<32)next="WASH";
    else if(energy<38)next="REST";
    else {
      String[] morning={"WASH","STRETCH","WATER","READ","COOK","EAT"};
      String[] day={"READ","PRACTICE","PIANO","WRITE","WATER","CLEAN","WINDOW","STRETCH"};
      String[] night={"PIANO","PRACTICE","READ","WRITE","WINDOW","REST"};
      String[] possibilities=h<10?morning:(h<18?day:night);
      next=possibilities[sequence%possibilities.length];
      if("EAT".equals(next)&&!mealReady)next="COOK";
    }
    enter(next,now,false);
  }
  private void enter(String next,long now,boolean requested){
    if("COOK".equals(next))mealReady=true;
    if("EAT".equals(next)){hunger=clamp(hunger+36);mealReady=false;}
    if("WASH".equals(next))hygiene=clamp(hygiene+35);
    if("SLEEP".equals(next))energy=clamp(energy+8);
    if("PIANO".equals(next)||"PRACTICE".equals(next))skill=clamp(skill+.15);
    if("WATER".equals(next)||"WINDOW".equals(next))mood=clamp(mood+3);
    if("CHAT".equals(next)){social=clamp(social+8);mood=clamp(mood+1);}
    sequence++;action=next;lastDecision=now;
    long duration;
    if("SLEEP".equals(next))duration=90000L;
    else if("CHAT".equals(next))duration=48000L;
    else duration=36000L+(sequence%4)*17000L;
    until=now+duration;
    note=description(next,requested);save();
  }
  public String request(String next){
    boolean ok=false;for(String a:ACTIONS)if(a.equals(next))ok=true;
    if(!ok)throw new IllegalArgumentException("未知生活行为");
    enter(next,System.currentTimeMillis(),true);return note;
  }
  private String description(String a,boolean requested){
    String prefix=requested?"你邀请我一起":"我想";
    switch(a){
      case "SLEEP":return "有点困了，我去休息一会儿。";
      case "COOK":return prefix+"做点热乎的饭，待会儿再聊。";
      case "EAT":return "饭做好啦，先好好吃饭。";
      case "WASH":return "去洗漱整理一下，回来会更精神。";
      case "READ":return prefix+"读几页书，或许会遇见好故事。";
      case "PRACTICE":return prefix+"练练今天的音准，慢慢进步。";
      case "PIANO":return prefix+"弹一小段琴，听听心情。";
      case "WRITE":return "我要把今天重要的事记进日记。";
      case "CLEAN":return "房间整洁一点，住着才舒服。";
      case "WATER":return "窗边的植物该浇水了。";
      case "WINDOW":return "窗外的光很好看，我想看一会儿。";
      case "STRETCH":return "坐太久了，站起来伸伸懒腰。";
      case "CHAT":return "我在呢。你想聊今天的事，还是听一段故事？";
      default:return "先休息一下，等会儿继续生活。";
    }
  }
  public String summary(){
    return "正在"+label()+" · 饱腹 "+Math.round(hunger)+" · 精力 "+Math.round(energy)
      +" · 清洁 "+Math.round(hygiene)+" · 心情 "+Math.round(mood)
      +" · 社交 "+Math.round(social)+" · 音乐 "+Math.round(skill);
  }
  public void save(){
    try{
      JSONObject o=new JSONObject();
      o.put("hunger",hunger);o.put("energy",energy);o.put("hygiene",hygiene);
      o.put("mood",mood);o.put("social",social);o.put("skill",skill);
      o.put("lastTick",lastTick);o.put("lastDecision",lastDecision);o.put("until",until);
      o.put("sequence",sequence);o.put("action",action);o.put("note",note);o.put("goal",goal);o.put("mealReady",mealReady);
      pref.edit().putString("state",o.toString()).apply();
    }catch(Exception ignored){}
  }
}
