using System;
using System.Collections.Generic;
using System.IO;
using XianxiaWorldBox;

namespace UnityEngine
{
    public class GameObject { public bool activeInHierarchy {get;set;}=true; }
    public class UIObject { public GameObject gameObject {get;}=new GameObject(); public string text {get;set;} }
    public class Time { public static float unscaledTime; }
    public class Application { public static string persistentDataPath=Path.Combine(Path.GetTempPath(),"worldbox-locale-v22-qa"); }
    public class Debug { public static void LogWarning(object msg) {} }
    public class Resources
    {
        public static readonly List<object> Items=new List<object>();
        public static object[] FindObjectsOfTypeAll(Type t)
        {
            var found=new List<object>();
            foreach(var o in Items)if(t.IsInstanceOfType(o))found.Add(o);
            return found.ToArray();
        }
    }
}
namespace UnityEngine.UI {public sealed class Text : UnityEngine.UIObject{}}
namespace TMPro {public sealed class TMP_Text : UnityEngine.UIObject{}}

class Program
{
    static void Assert(bool yes,string message){if(!yes)throw new Exception(message);}
    static void Main()
    {
        var kingdoms=new UnityEngine.UI.Text{text="Kingdoms"};
        var war=new TMPro.TMP_Text{text="War"};
        var mod=new TMPro.TMP_Text{text="Mod Manager"};
        var numeric=new TMPro.TMP_Text{text="Population: 1,200"};
        var name=new UnityEngine.UI.Text{text="Northridge"};
        var hidden=new UnityEngine.UI.Text{text="Settings"};
        hidden.gameObject.activeInHierarchy=false;
        UnityEngine.Resources.Items.AddRange(new object[]{kingdoms,war,mod,numeric,name,hidden});
        UnityEngine.Time.unscaledTime=10f;
        RuntimeChineseOverlayV22.Tick();
        Assert(kingdoms.text=="王国列表","vanilla UI text translation");
        Assert(war.text=="战争","TMPro game label");
        Assert(mod.text=="模组管理器","other-MOD text");
        Assert(numeric.text=="人口：1,200","dynamic numeric kingdom population status");
        Assert(ChineseLocalizationV22.Translate("Kingdom: Arthen")=="Kingdom: Arthen","generated kingdom name unchanged");
        Assert(name.text=="Northridge","unknown dynamic name must not be mangled");
        Assert(hidden.text=="Settings","inactive labels must remain");
        Assert(RuntimeChineseOverlayV22.LiveTranslatedCount==4,"tracked count");
        war.text="World";
        UnityEngine.Time.unscaledTime=20f;
        RuntimeChineseOverlayV22.Tick();
        Assert(war.text=="世界","react to game-created dynamic labels");
        RuntimeChineseOverlayV22.SetEnabled(false);
        Assert(kingdoms.text=="Kingdoms"&&war.text=="World"&&mod.text=="Mod Manager"&&numeric.text=="Population: 1,200",
          "disable must restore only MOD-owned overlays without reversing game updates");
        string folder=Path.Combine(UnityEngine.Application.persistentDataPath,"XianxiaModStaging");
        Directory.CreateDirectory(folder);
        File.WriteAllText(Path.Combine(folder,"zh_cn_overrides.txt"),"Kingdoms=诸侯王国\n");
        string status=ChineseLocalizationV22.LoadUserTranslations();
        Assert(status.Contains("1 条"),"load custom translations");
        RuntimeChineseOverlayV22.SetEnabled(true);
        UnityEngine.Time.unscaledTime=31f;
        RuntimeChineseOverlayV22.Tick();
        Assert(kingdoms.text=="诸侯王国","private override takes precedence");
        RuntimeChineseOverlayV22.Shutdown();
        Assert(kingdoms.text=="Kingdoms","shutdown restores original");
        Directory.Delete(UnityEngine.Application.persistentDataPath,true);
        Console.WriteLine("PASS_RUNTIME_CHINESE_V22 C# actual UI Text/TMP behavior and safe restore");
    }
}
