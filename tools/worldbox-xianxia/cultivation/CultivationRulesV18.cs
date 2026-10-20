using System;

namespace XianxiaMonoBridge {
// Original portable rules. Canglan's world-clock/stress/material-conservation
// mechanics are reimplemented here; no Godot runtime or Canglan saves imported.
public sealed class CultivationState {
    public int Root,Layer,Herbs,Stones,Pills;
    public float Qi,Stress,LastTime,CraftAt;
    public bool Tested,Method,Training;
}
public static class CultivationRulesV18 {
    public const int MaxLayer=13,MaxStack=9999;
    public static uint Hash(string text){unchecked{uint h=2166136261;foreach(char c in text)h=(h^c)*16777619;return h;}}
    public static int BornRoot(string identity){uint h=Hash(identity);return h%5==0?0:1+(int)((h/5)%5);}
    public static int BreakthroughCost(int layer){return 60+Math.Max(0,layer)*70;}
    // WorldBox world seconds, not wall clock: pause produces no progression.
    public static void Advance(CultivationState s,float now){
        if(float.IsNaN(now)||float.IsInfinity(now))return;
        if(now<s.LastTime)return;
        float dt=Math.Max(0,now-s.LastTime);s.LastTime=now;
        if(s.CraftAt>0&&now>=s.CraftAt){s.Pills=Math.Min(MaxStack,s.Pills+1);s.CraftAt=0;}
        if(dt<=0)return;
        float years=dt/60f;
        if(s.Training&&s.Tested&&s.Method&&s.Root>0){
            // Stop at the stress threshold even when one tick spans many years.
            float active=Math.Min(years,Math.Max(0,(92-s.Stress)/1.5f));
            s.Qi=Math.Min(100000,s.Qi+active*22);
            s.Stress=Math.Min(100,s.Stress+active*1.5f);
            if(active<years||s.Stress>=92)s.Training=false;
            s.Stress=Math.Max(0,s.Stress-(years-active)*8);
        }else s.Stress=Math.Max(0,s.Stress-years*8);
    }
    public static string Breakthrough(CultivationState s){
        if(!s.Tested||s.Root==0||!s.Method)return "先检测灵根并获得功法";
        if(s.Layer>=MaxLayer)return "炼气十三层已满；筑基关口尚未接入";
        if(s.Stress>70)return "经脉负荷过高，请停止吐纳休息";
        int cost=BreakthroughCost(s.Layer);
        if(s.Qi<cost)return "修为不足，需要"+cost;
        s.Qi-=cost;s.Layer++;s.Stress=Math.Min(100,s.Stress+14);
        return "突破炼气"+s.Layer+"层";
    }
    public static string Craft(CultivationState s,float now){
        if(s.CraftAt>0)return "正在炼丹，请等待世界时间推进";
        if(s.Pills>=MaxStack)return "丹药已满";
        if(s.Layer<1||!s.Method)return "炼气一层并学会功法后才能炼丹";
        if(s.Herbs<3||s.Stones<1||s.Qi<10)return "需要灵草3、灵石1、修为10";
        s.Herbs-=3;s.Stones--;s.Qi-=10;s.CraftAt=now+30;
        return "开始炼制聚气丹：消耗材料，需半个世界年";
    }
    public static string TakePill(CultivationState s){
        if(!s.Tested||s.Root==0||!s.Method)return "没有灵根或功法，无法炼化丹药";
        if(s.Pills<=0)return "没有聚气丹，请先采集并炼制";
        if(s.Stress>85)return "经脉负荷过高，不能继续服丹";
        s.Pills--;s.Qi=Math.Min(100000,s.Qi+35);s.Stress=Math.Min(100,s.Stress+3);
        return "炼化聚气丹：修为+35，经脉负荷+3";
    }
}
}
