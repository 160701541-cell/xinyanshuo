using System;
using System.Collections.Generic;
using System.IO;
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
    public bool simulateIgnoredSwitch;
    public void setLanguage(string id){if(!simulateIgnoredSwitch)language=id;}
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
        public static string Get(string key)
        {
            Dictionary<string,string> localized;
            string value;
            if(locales.TryGetValue(LocalizedTextManager.instance.language,out localized)
                &&localized.TryGetValue(key,out value))return value;
            return key;
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
        string measured=NativeLocaleBridgeV23.VerifyCurrentLocale();
        Assert(measured.Contains("原版语言码 en"),"must report live original language");
        Assert(measured.Contains("实际文本抽样 6项"),"read actual game strings");
        Assert(measured.Contains("含汉字1／拉丁字母5"),"no fake locale completion rate");
        Assert(measured.Contains("非全量汉化完成率"),"must not label sample as coverage");
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
        // Private direct key packs cover untranslated third-party MOD keys
        // even when the vanilla language currently shows Chinese values.
        string folder=Path.Combine(UnityEngine.Application.persistentDataPath,"XianxiaModStaging");
        Directory.CreateDirectory(folder);
        string pack=Path.Combine(folder,"zh_cn_keymap_v24.txt");
        File.WriteAllText(pack,"new_mod_tab=仙途菜单"+Environment.NewLine+"mod_menu=不应覆盖已有汉化"+Environment.NewLine);
        string imported=ChineseKeyPackV24.ImportPrivatePack();
        Console.WriteLine("PRIVATE_PACK_DIAG "+imported+" count="+ChineseKeyPackV24.KeyCount);
        Assert(ChineseKeyPackV24.KeyCount==2,"load direct locale-key pack");
        Assert(NativeLocaleBridgeV23.LastPackOk,"accepted pack");
        Assert(NeoModLoader.General.LM.locales["cz"]["new_mod_tab"]=="仙途菜单","foreign MOD direct key registered");
        Assert(NeoModLoader.General.LM.locales["cz"]["mod_menu"]=="模组管理器","existing NML translation never overwritten");

        // Entire invalid pack must be rejected before any NML writes.
        File.WriteAllText(pack,"safe_entry=好"+Environment.NewLine+"unsafe$key=非法"+Environment.NewLine);
        string rejected=ChineseKeyPackV24.ImportPrivatePack();
        Assert(rejected.Contains("非法键"),"invalid direct key pack rejected");
        Assert(!NeoModLoader.General.LM.locales["cz"].ContainsKey("safe_entry"),"invalid pack atomic validation");
        data.language="en";
        data.simulateIgnoredSwitch=true;
        string failedSwitch=NativeLocaleBridgeV23.SwitchToChineseByUserTap();
        Assert(failedSwitch.Contains("未确认")&&data.language=="en",
            "native method returning without switching must NOT count as successful Chinese");
        data.simulateIgnoredSwitch=false;
        string switchResult=NativeLocaleBridgeV23.SwitchToChineseByUserTap();
        Assert(switchResult.Contains("已请求切换")&&data.language=="cz","user-tap switch to vanilla Chinese");
        OwnLocaleLabelsV25.Reset();
        NeoModLoader.General.LM.Add("cz","xinyanshuo.wb.mod_manager","模拟NML中文包载入");
        Assert(OwnLocaleLabelsV25.Get("mod_manager","中文模组管理器")=="模拟NML中文包载入",
            "actual own NML locale entry must be used when loaded");
        Assert(OwnLocaleLabelsV25.Get("not_in_pack","中文回退")=="中文回退",
            "unknown NML locale key must fall back to readable Chinese");
        OwnLocaleLabelsV25.Reset();
        Directory.Delete(UnityEngine.Application.persistentDataPath,true);
        Console.WriteLine("PASS_NATIVE_LOCALE_V23 real key lookup + NML LM cz registry and non-destructive refresh");
    }
}
