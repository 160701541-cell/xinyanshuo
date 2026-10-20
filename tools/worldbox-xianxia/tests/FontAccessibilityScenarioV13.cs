using System;
using UnityEngine;
using XianxiaWorldBox;
static class FontAccessibilityScenarioV13
{
    static void Check(bool condition,string reason)
    {
        if (!condition) throw new Exception("FONT_ACCESSIBILITY_FAIL: "+reason);
    }
    static int Main()
    {
        Check(!ModTextAccessibilityV13.GlobalEnabled,"other mod text must default OFF");
        Check(ModTextAccessibilityV13.Scale>=1.5f,"observer label defaults enlarged");
        GUI.skin = new GUISkin();
        GUIStyle btn=ModTextAccessibilityV13.ButtonStyle();
        GUIStyle label=ModTextAccessibilityV13.LabelStyle();
        Check(btn.fontSize>=24,"bigger button Chinese font");
        Check(label.wordWrap,"labels wrap for translated Chinese text");
        Check(btn.font!=null,"dynamic CJK fallback allocated");
        Check(!ModTextAccessibilityV13.Status.Contains("??"),"clear label");
        ModTextAccessibilityV13.ToggleGlobal();
        Check(ModTextAccessibilityV13.GlobalEnabled,"global accessibility toggle");
        ModTextAccessibilityV13.Tick();
        ModTextAccessibilityV13.CycleScale();
        Check(ModTextAccessibilityV13.Scale>=1f,"scale remains valid");
        ModTextAccessibilityV13.ToggleGlobal();
        Check(!ModTextAccessibilityV13.GlobalEnabled,"restore toggle");
        Check(ModTextAccessibilityV13.ModifiedCount==0,"reset tracked labels");
        ModTextAccessibilityV13.Shutdown();
        Console.WriteLine("PASS_FONT_ACCESSIBILITY_V13: large CJK controls, opt-in other-MOD adjustment, off/restore");
        return 0;
    }
}
