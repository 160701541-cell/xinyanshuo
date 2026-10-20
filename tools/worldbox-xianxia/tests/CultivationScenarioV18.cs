using System;
using XianxiaMonoBridge;
class CultivationScenarioV18 {
    static void Check(bool b,string name){if(!b)throw new Exception(name);}
    static void Main(){
        var s=new CultivationState{Root=2,Tested=true,Method=true,Training=true,LastTime=100};
        CultivationRulesV18.Advance(s,100);Check(s.Qi==0,"Paused world must not create progress");
        CultivationRulesV18.Advance(s,160);Check(s.Qi>0&&s.Stress>0,"World time must advance cultivation");
        float qi=s.Qi;CultivationRulesV18.Advance(s,140);Check(s.Qi==qi,"Loading older time must not create progress");
        CultivationRulesV18.Advance(s,160);Check(s.Qi==qi,"Clock rewind cannot duplicate already earned progress");
        s.Qi=100;s.Herbs=2;s.Stones=1;s.Layer=1;
        CultivationRulesV18.Craft(s,140);Check(s.Qi==100&&s.Herbs==2&&s.Stones==1&&s.CraftAt==0,"Failed recipe must preserve every input");
        s.Herbs=3;CultivationRulesV18.Craft(s,140);
        Check(s.Herbs==0&&s.Stones==0&&s.Qi==90&&s.Pills==0,"Crafting consumes inputs before delayed output");
        CultivationRulesV18.Craft(s,140);Check(s.Qi==90,"Cannot double charge a pending craft");
        s.Training=false;CultivationRulesV18.Advance(s,169);Check(s.Pills==0,"Output cannot appear early");
        CultivationRulesV18.Advance(s,170);CultivationRulesV18.Advance(s,170);Check(s.Pills==1&&s.CraftAt==0,"Output delivered exactly once");
        CultivationRulesV18.TakePill(s);Check(s.Pills==0&&s.Qi==125,"Pill must be consumed for effect");
        CultivationRulesV18.TakePill(s);Check(s.Pills==0&&s.Qi==125,"Cannot consume nonexistent items");
        s.Layer=13;s.Qi=10000;CultivationRulesV18.Breakthrough(s);Check(s.Layer==13&&s.Qi==10000,"Unimplemented foundation gate must remain closed");
        s.Layer=1;s.Stress=90;CultivationRulesV18.Breakthrough(s);Check(s.Layer==1&&s.Qi==10000,"High stress blocks breakthrough without charging");
        s.Stress=91;s.Training=true;CultivationRulesV18.Advance(s,170+6000);Check(!s.Training&&s.Qi<10040,"Long fast-forward cannot bypass stress limit");
        s.Root=0;s.Training=true;qi=s.Qi;CultivationRulesV18.Advance(s,7000);Check(s.Qi==qi,"Mortals cannot generate cultivation progress");
        Console.WriteLine("PASS_V18_REAL_CLOCK_MATERIAL_CONSERVATION_STRESS_AND_CLOSED_GATES");
    }
}
