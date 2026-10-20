using System;
using System.Collections.Generic;
using XianxiaWorldBox;

namespace UnityEngine
{
    public class Application {public static string persistentDataPath="/tmp/worldbox-zh-v23-tests";}
    public static class Debug {public static void LogWarning(object msg){}}
}
public class LocalizedTextManager
{
    public static LocalizedTextManager instance=new LocalizedTextManager();
    public string language="en";
    public Dictionary<string,string> _localized_text=new Dictionary<string,string>();
}
namespace NeoModLoader.General
{
    public static class LM
    {
        public static readonly Dictionary<string, Dictionary<string,string>> locales =
            new Dictionary<string, Dictionary<string,string>>();
        public static int applyCount;
        public static bool Has(string key,string lang)
        {
            Dictionary<string,string> dict;
            return locales.TryGetValue(lang,out dict)&&dict.ContainsKey(key);
        }
        public static void Add(string language,string key,string text)
        {
            Dictionary<string,string> dict;
            if(!locales.TryGetValue(language,out dict))
            {
                dict=new Dictionary<string,string>();
                locales[language]=dict;
            }
            dict[key]=text;
        }
        public static void ApplyLocale(string lang,bool update)
        {
            applyCount++;
            var local=LocalizedTextManager.instance;
            foreach(var pair in locales[lang])local._localized_text[pair.Key]=pair.Value;
        }
    }
}
class Program
{
    static void Assert(bool value,string reason){if(!value)throw new Exception(reason);}
    static void Main()
    {
        var data=LocalizedTextManager.instance;
        data._localized_text["kingdoms_tab"]="Kingdoms";
        data._localized_text["population_text"]="Population";
        data._localized_text["mod_menu"]="Mod Manager";
        data._localized_text["wars_tab"]="War";
        data._localized_text["royal_person"]="Northridge";
        data._localized_text["city_original_zh"]="王国";
        NeoModLoader.General.LM.Add("cz","wars_tab","战事（其他MOD）");
        string info=NativeLocaleBridgeV23.RegisterActualKeys();
        Assert(NativeLocaleBridgeV23.Ready,"real instance and LM API detected");
        Assert(NativeLocaleBridgeV23.Seen==5,"5 English values scanned, existing native Chinese skipped");
        Assert(NativeLocaleBridgeV23.Matched==4,"4 known labels recognized");
        Assert(NativeLocaleBridgeV23.Registered==3,"3 new labels registered");
        Assert(NativeLocaleBridgeV23.SkippedExisting==1,"do not replace other MOD cz translations");
        Assert(NeoModLoader.General.LM.locales["cz"]["kingdoms_tab"]=="王国列表","real locale key chosen, not guessed");
        Assert(NeoModLoader.General.LM.locales["cz"]["mod_menu"]=="模组管理器","real third-party MOD locale key");
        Assert(!NeoModLoader.General.LM.locales["cz"].ContainsKey("royal_person"),"do not translate names");
        Assert(data.language=="en"&&data._localized_text["kingdoms_tab"]=="Kingdoms","registration must not change player locale");
        Assert(NativeLocaleBridgeV23.ActivateChinese().Contains("请到原版设置中"),"English user is prompted to switch");
        Assert(NeoModLoader.General.LM.applyCount==0,"no unrequested locale switch");
        data.language="cz";
        Assert(NativeLocaleBridgeV23.ActivateChinese().Contains("已刷新"),"refresh existing Chinese language");
        Assert(NeoModLoader.General.LM.applyCount==1,"call native LM.ApplyLocale exactly once");
        Assert(data._localized_text["kingdoms_tab"]=="王国列表","native label was applied");
        Assert(data._localized_text["wars_tab"]=="战事（其他MOD）","other mod translation not erased");
        Assert(ChineseLocalizationV22.Translate("Royal Palace")=="皇宫","large menu glossary works");
        Assert(ChineseLocalizationV22.Translate("Main Menu")=="主菜单","menu glossary works");
        Assert(ChineseLocalizationV22.Translate("Northridge")=="Northridge","unknown names unchanged");
        Console.WriteLine("PASS_NATIVE_LOCALE_V23 real key lookup + NML LM cz registry and non-destructive refresh");
    }
}
