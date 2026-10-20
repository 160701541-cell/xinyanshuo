using System;
using XianxiaWorldBox;
static class CultivationScenarioV18
{
    static void Check(bool condition,string text)
    {
        if(!condition) throw new Exception("CULTIVATION_TEST_FAILED: "+text);
    }
    static int Main()
    {
        CultivationV18.ResetOnWorldChange();
        Check(CultivationV18.Count==0,"empty world starts empty");
        Check(CultivationV18.Realms.Length>=30,"full realm-stage table");
        Check(CultivationV18.Meditate(null,0).Contains("选择"),"null actor is ignored");
        var first=new Actor();
        var second=new Actor();
        string started=CultivationV18.Meditate(first,0);
        Check(started.Contains("灵气"),"meditation earns qi");
        var record=CultivationV18.Inspect(first);
        Check(record!=null&&record.Qi==8,"first meditation creates bounded actor record");
        Check(CultivationV18.Meditate(first,1).Contains("间隔"),"two second real-time cooldown");
        Check(record.Qi==8,"cooldown does not add qi");
        for(int step=1;step<=8;step++)CultivationV18.Meditate(first,step*3);
        Check(record.RealmIndex>=1,"realm breakthrough happens after enough qi");
        Check(CultivationV18.Realms[record.RealmIndex].StartsWith("炼气"),"breakthrough begins at Qi Refining");
        CultivationV18.Meditate(second,0);
        Check(CultivationV18.Count==2,"actors retain distinct cultivation progress");
        Check(CultivationV18.Inspect(second).RealmIndex==0,"second actor realm independent");
        Check(CultivationV18.RequiredQi(CultivationV18.Realms.Length-1)==0,"final-stage bounds");
        CultivationV18.ResetOnWorldChange();
        Check(CultivationV18.Count==0,"world change clears ephemeral session state");
        Console.WriteLine("PASS_CULTIVATION_V18: actor qi, cooldown, breakthrough, separation, session reset");
        return 0;
    }
}
