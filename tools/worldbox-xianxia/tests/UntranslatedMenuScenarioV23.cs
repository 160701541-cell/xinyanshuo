using System;
using System.IO;
using XianxiaWorldBox;

namespace UnityEngine
{
    public static class Application
    {
        public static string persistentDataPath=Path.Combine(Path.GetTempPath(),"wb-zh-audit-"+Guid.NewGuid().ToString("N"));
    }
}

class Program
{
    static void Assert(bool ok,string reason){if(!ok)throw new Exception(reason);}
    static void Main()
    {
        UntranslatedMenuAuditV23.Observe("Guild Hall");
        Assert(UntranslatedMenuAuditV23.Count==0,"Audit must be opt-in by default");
        Assert(UntranslatedMenuAuditV23.ExportLocalReport().Contains("请先主动开启"),"No silent report export");
        UntranslatedMenuAuditV23.SetEnabled(true);
        UntranslatedMenuAuditV23.Observe("Guild Hall");
        UntranslatedMenuAuditV23.Observe("Guild Hall");
        UntranslatedMenuAuditV23.Observe("myname@example.com");
        UntranslatedMenuAuditV23.Observe("Northridge123");
        UntranslatedMenuAuditV23.Observe("Settings");
        UntranslatedMenuAuditV23.Observe("皇宫");
        Assert(UntranslatedMenuAuditV23.Count==1,"Only one untranslated English menu candidate");
        string status=UntranslatedMenuAuditV23.ExportLocalReport();
        Assert(status.Contains("已将 1 条"),"Explicit local export count");
        string report=Path.Combine(UnityEngine.Application.persistentDataPath,
            "XianxiaModStaging","missing_chinese_ui_v23.txt");
        Assert(File.Exists(report),"Export only on explicit button");
        string text=File.ReadAllText(report);
        Assert(text.Contains("Guild Hall"),"Report includes untranslated term");
        Assert(!text.Contains("myname@example.com"),"Reject obvious personal address");
        UntranslatedMenuAuditV23.Clear();
        Assert(UntranslatedMenuAuditV23.Count==0,"Memory audit clear");
        UntranslatedMenuAuditV23.SetEnabled(false);
        Directory.Delete(UnityEngine.Application.persistentDataPath,true);
        Console.WriteLine("PASS_UNTRANSLATED_MENU_AUDIT_V23 opt-in and local-only with non-destructive export");
    }
}
