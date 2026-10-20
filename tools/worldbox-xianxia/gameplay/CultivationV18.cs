using System;
using System.Collections.Generic;
using UnityEngine;

// Other-game WorldBox nonofficial derivative MOD experiment; NEVER Canglan.
// In-memory cultivation prototype: actors and their cultivation records are
// bound to the current WorldBox process only. No saves or original stats touched.
namespace XianxiaWorldBox
{
    public static class CultivationV18
    {
        public const int MaxActors = 256;
        public const float MinimumPulseSeconds = 2f;
        public static readonly string[] Realms = {
            "凡人","炼气一层","炼气二层","炼气三层",
            "炼气四层","炼气五层","炼气六层",
            "炼气七层","炼气八层","炼气九层",
            "炼气十层","炼气十一层","炼气十二层",
            "炼气十三层","筑基初期","筑基中期","筑基后期",
            "结丹初期","结丹中期","结丹后期",
            "元婴初期","元婴中期","元婴后期",
            "化神初期","化神中期","化神后期",
            "炼虚初期","炼虚中期","炼虚后期",
            "合体初期","合体中期","合体后期",
            "大乘","渡劫"
        };
        public sealed class Entry
        {
            public int RealmIndex;
            public long Qi;
            public int MeditationCount;
            public float LastPulse;
            public string Name;
            public string Summary
            {
                get {
                    int index=Math.Max(0,Math.Min(Realms.Length-1,RealmIndex));
                    return Realms[index]+" / 灵气："+Qi+" / 需要："+RequiredQi(index);
                }
            }
        }
        static readonly Dictionary<Actor,Entry> Books = new Dictionary<Actor,Entry>();
        public static int Count { get { return Books.Count; } }
        public static long RequiredQi(int realm)
        {
            if(realm>=Realms.Length-1)return 0;
            // Staged growth with slow late cultivation and safe long arithmetic.
            long baseRequired=24L+realm*realm*13L;
            int tier=realm<14?1:realm<17?3:realm<20?7:realm<23?16:realm<26?32:realm<29?64:128;
            return Math.Min(1000000000L,baseRequired*tier);
        }
        public static Entry Inspect(Actor actor)
        {
            if(actor==null||!actor.isAlive())return null;
            Entry state;
            return Books.TryGetValue(actor,out state)?state:null;
        }
        static Entry Bind(Actor actor)
        {
            Entry existing;
            if(Books.TryGetValue(actor,out existing))return existing;
            if(Books.Count>=MaxActors)Cleanup();
            if(Books.Count>=MaxActors)return null;
            existing=new Entry{RealmIndex=0,Qi=0,LastPulse=-10000f,
                Name=actor.getName()};
            Books.Add(actor,existing);
            return existing;
        }
        public static string Meditate(Actor actor,float now)
        {
            if(actor==null||!actor.isAlive())return "请先选择一名存活人物。";
            var record=Bind(actor);
            if(record==null)return "修士记录暂满，请稍后。";
            if(now-record.LastPulse<MinimumPulseSeconds)
                return "修炼间隔未结束。";
            if(record.RealmIndex>=Realms.Length-1)return "已至当前最高试验境界。";
            record.LastPulse=now;
            // Ambient Qi is an isolated game mechanic; no original actor stat edits.
            int advance=8+Math.Min(record.MeditationCount/15,15);
            record.MeditationCount++;
            record.Qi+=advance;
            long required=RequiredQi(record.RealmIndex);
            if(record.Qi>=required)
            {
                record.Qi-=required;
                record.RealmIndex++;
                string msg="突破："+record.Name+" → "+Realms[record.RealmIndex];
                Debug.Log("[XIANXIA-V18] "+msg);
                return msg;
            }
            return record.Name+" 吐纳灵气 +"+advance+"，"+record.Summary;
        }
        public static void Cleanup()
        {
            var dead=new List<Actor>();
            foreach(var item in Books)
                if(item.Key==null||!item.Key.isAlive())dead.Add(item.Key);
            foreach(var actor in dead)Books.Remove(actor);
        }
        public static void ResetOnWorldChange()
        {
            Books.Clear();
        }
    }
}
