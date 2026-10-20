package com.xinyanshuo.zhiyin;

import android.content.Context;
import android.content.SharedPreferences;
import org.json.JSONArray;
import org.json.JSONObject;
import java.util.*;

public final class Neighborhood {
  public static final class Person {
    public final String id,name,home,job,hobby,personality;
    public final int color;
    Person(String id,String name,String home,String job,String hobby,String personality,int color){
      this.id=id;this.name=name;this.home=home;this.job=job;this.hobby=hobby;this.personality=personality;this.color=color;
    }
  }
  public static final Person[] PEOPLE={
    new Person("zhiyin","知音","临河巷·三楼单间","咖啡馆服务员","唱歌、阅读、散步","细心、独立、有主见",0xFF7AB8AC),
    new Person("player","玩家","梧桐街·玩家公寓","自由选择","由玩家决定","由玩家决定",0xFFA9A5D6),
    new Person("qingyin","清音","艺文坊·琴房上层","声乐教师","钢琴、茶艺","认真、慢热",0xFFE5AD91),
    new Person("moran","墨染","旧街·书店楼上","书店店员","推理、读书","安静、善于观察",0xFF8D9AB5),
    new Person("ahe","阿禾","南市·合租小院","花店店员","园艺、摄影","开朗、热情",0xFFA7C986),
    new Person("ache","阿澈","江畔·青年公寓","配送员","骑行、吉他","健谈、正直",0xFFD6B38C)
  };
  private final SharedPreferences prefs;
  private final HashMap<String,Integer> affinity=new HashMap<>();
  private final HashMap<String,Integer> interactions=new HashMap<>();
  private final HashMap<String,Long> lastMeet=new HashMap<>();
  public Neighborhood(Context ctx){
    prefs=ctx.getSharedPreferences("zhiyin_neighborhood_v1",Context.MODE_PRIVATE);
    try{
      JSONObject raw=new JSONObject(prefs.getString("memory","{}"));
      for(Person person:PEOPLE){
        JSONObject j=raw.optJSONObject(person.id);
        if(j!=null){
          affinity.put(person.id,Math.max(0,Math.min(100,j.optInt("affinity",0))));
          interactions.put(person.id,Math.max(0,j.optInt("interactions",0)));
          lastMeet.put(person.id,j.optLong("lastMeet",0L));
        }
      }
    }catch(Exception ignored){}
  }
  public Person find(String id){
    for(Person p:PEOPLE)if(p.id.equals(id))return p;
    return PEOPLE[0];
  }
  public int closeness(String id){return affinity.getOrDefault(id,0);}
  public int count(String id){return interactions.getOrDefault(id,0);}
  public String tier(String id){
    int v=closeness(id);int n=count(id);
    if(v>=90&&n>=12)return "亲密伙伴";
    if(v>=75&&n>=8)return "很亲近";
    if(v>=40&&n>=5)return "好朋友";
    if(v>=15&&n>=2)return "逐渐熟悉";
    return "初识";
  }
  public boolean canExpressFeelings(String id){
    return !id.equals("player") && closeness(id)>=75 && count(id)>=8;
  }
  /**
   * Relationships require mutual, repeated and time-separated interactions:
   * clicking the same action rapidly cannot farm unlimited affection.
   */
  public String meet(String id,String activity){
    Person p=find(id);
    if(p.id.equals("player"))return "这是玩家自己的住处，你可以设定自己的日常生活。";
    long now=System.currentTimeMillis();
    long prev=lastMeet.getOrDefault(id,0L);
    int days=interactions.getOrDefault(id,0);
    if(now-prev<45*1000L)return p.name+"还在忙自己的事。相处需要时间，不能反复点几下就提高关系。";
    boolean hobbyMatch=activity.contains("音乐")&&p.hobby.contains("唱歌")
      ||activity.contains("读书")&&p.hobby.contains("读书")
      ||activity.contains("植物")&&p.hobby.contains("园艺");
    int gain=hobbyMatch?4:2;
    int previous=closeness(id);
    int target=Math.min(100,previous+gain);
    affinity.put(id,target);
    interactions.put(id,days+1);lastMeet.put(id,now);save();
    return "与"+p.name+"一起"+activity+"。TA有自己的生活："+
      p.job+"，爱好"+p.hobby+"。熟悉度 "+previous+" → "+target+
      "。当前关系："+tier(id)+"。";
  }
  private void save(){
    try{
      JSONObject root=new JSONObject();
      for(Person p:PEOPLE){
        JSONObject obj=new JSONObject();obj.put("affinity",closeness(p.id));
        obj.put("interactions",count(p.id));obj.put("lastMeet",lastMeet.getOrDefault(p.id,0L));
        root.put(p.id,obj);
      }
      prefs.edit().putString("memory",root.toString()).apply();
    }catch(Exception ignored){}
  }
  public String archive(){return prefs.getString("memory","{}");}
  public void restore(JSONObject raw){
    if(raw==null)return;
    affinity.clear();interactions.clear();lastMeet.clear();
    for(Person p:PEOPLE){
      JSONObject obj=raw.optJSONObject(p.id);
      if(obj==null)continue;
      affinity.put(p.id,Math.max(0,Math.min(100,obj.optInt("affinity",0))));
      interactions.put(p.id,Math.max(0,obj.optInt("interactions",0)));
      lastMeet.put(p.id,Math.max(0,obj.optLong("lastMeet",0L)));
    }
    save();
  }
}
