using System;
using System.Collections;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;

namespace XianxiaWorldBox
{
    /// <summary>
    /// Read-only discovery of live WorldBox locale keys followed by opt-in
    /// registration through the actual Android NeoModLoader LM API.
    /// NML's Simplified Chinese language code is "cz" (NOT "zh-CN").
    /// Registration only supplies translated keys the game actually exposes.
    /// It does not fabricate key names, patch assemblies or mutate saves.
    /// </summary>
    public static class NativeLocaleBridgeV23
    {
        const int MaxDictionaryRead=16000;
        const int MaxRegistrations=3000;
        public static int Seen { get; private set; }
        public static int Matched { get; private set; }
        public static int Registered { get; private set; }
        public static int SkippedExisting { get; private set; }
        public static bool Ready { get; private set; }
        public static string Status { get; private set; }="未扫描原版语言键；点击「登记原版中文」开始。";
        static Type managerType;
        static Type lmType;
        static object manager;

        static Type FindType(string qualifiedName)
        {
            foreach(var a in AppDomain.CurrentDomain.GetAssemblies())
            {
                try
                {
                    var t=a.GetType(qualifiedName,false);
                    if(t!=null)return t;
                }
                catch { }
            }
            return null;
        }

        static object Member(object obj,string name)
        {
            if(obj==null)return null;
            var type=obj.GetType();
            const BindingFlags f=BindingFlags.Instance|BindingFlags.Public|BindingFlags.NonPublic;
            var field=type.GetField(name,f);
            if(field!=null)return field.GetValue(obj);
            var prop=type.GetProperty(name,f);
            return prop!=null&&prop.GetIndexParameters().Length==0?prop.GetValue(obj,null):null;
        }

        static object StaticMember(Type type,string name)
        {
            if(type==null)return null;
            const BindingFlags f=BindingFlags.Static|BindingFlags.Public|BindingFlags.NonPublic;
            var field=type.GetField(name,f);
            if(field!=null)return field.GetValue(null);
            var prop=type.GetProperty(name,f);
            return prop!=null&&prop.GetIndexParameters().Length==0?prop.GetValue(null,null):null;
        }

        static MethodInfo StaticMethod(Type type,string name,params Type[] args)
        {
            if(type==null)return null;
            return type.GetMethod(name,BindingFlags.Static|BindingFlags.Public,null,args,null);
        }

        static bool Discover()
        {
            managerType=FindType("LocalizedTextManager");
            lmType=FindType("NeoModLoader.General.LM");
            manager=StaticMember(managerType,"instance");
            if(managerType==null||manager==null||lmType==null)
                return false;
            return StaticMethod(lmType,"Add",typeof(string),typeof(string),typeof(string))!=null;
        }

        static bool IsEnglishLike(string text)
        {
            if(string.IsNullOrEmpty(text)||text.Length>180)return false;
            // Don't turn already-localized (Chinese/other) text into an English guess.
            for(int i=0;i<text.Length;i++)
                if(text[i]>=0x4e00&&text[i]<=0x9fff)return false;
            return true;
        }

        public static string RegisterActualKeys()
        {
            Seen=0;Matched=0;Registered=0;SkippedExisting=0;Ready=false;
            try
            {
                if(!Discover())
                {
                    Status="原版本地化接口或NML语言接口不可用，保持原版，不修改存档。";
                    return Status;
                }
                object dictionary=Member(manager,"_localized_text");
                if(dictionary==null)
                {
                    Status="原版语言字典暂未加载；进入世界后重新尝试。";
                    return Status;
                }
                IEnumerable entries=dictionary as IEnumerable;
                if(entries==null)
                {
                    Status="当前安卓本地化字典无法安全枚举；未做修改。";
                    return Status;
                }
                MethodInfo add=StaticMethod(lmType,"Add",typeof(string),typeof(string),typeof(string));
                MethodInfo has=StaticMethod(lmType,"Has",typeof(string),typeof(string));
                int considered=0;
                foreach(object item in entries)
                {
                    if(item==null||++considered>MaxDictionaryRead)break;
                    // Mono IDictionary and IL2CPP KeyValuePair projection are both handled.
                    string key=null,original=null;
                    if(item is DictionaryEntry)
                    {
                        var pair=(DictionaryEntry)item;
                        key=pair.Key as string;
                        original=pair.Value as string;
                    }
                    else
                    {
                        key=Member(item,"Key") as string;
                        original=Member(item,"Value") as string;
                    }
                    if(string.IsNullOrEmpty(key)||key.Length>150||!IsEnglishLike(original))
                        continue;
                    Seen++;
                    string chinese=ChineseLocalizationV22.Translate(original);
                    if(chinese==original)chinese=ChineseLocalizationV22.Translate(key);
                    if(string.IsNullOrEmpty(chinese)||chinese==original||chinese==key)
                        continue;
                    Matched++;
                    // NML Has() tests the loader's own registry, not original assets.
                    if(has!=null&&(bool)has.Invoke(null,new object[]{key,"cz"}))
                    {
                        SkippedExisting++;
                        continue;
                    }
                    if(Registered>=MaxRegistrations)break;
                    add.Invoke(null,new object[]{"cz",key,chinese});
                    Registered++;
                }
                Ready=true;
                Status="实际语言键 "+Seen+" 项；匹配 "+Matched+" 项；登记简中 "+
                    Registered+" 项；已有译文跳过 "+SkippedExisting+
                    " 项。仅登记，不强制修改当前语言。";
                return Status;
            }
            catch(Exception e)
            {
                Ready=false;
                Status="原版语言键检查失败："+e.GetType().Name+"，可使用文字覆盖功能。";
                Debug.LogWarning("[XIANXIA-V23] LOCALE_SCAN "+e.GetType().Name);
                return Status;
            }
        }

        public static string ActivateChinese()
        {
            try
            {
                if(!Ready||manager==null||lmType==null)
                {
                    Status="请先登记原版语言键，确认本地化接口可用。";
                    return Status;
                }
                object language=Member(manager,"language");
                var languageId=language as string;
                if(languageId=="cz")
                {
                    // Apply NML-registered Chinese translations to the current locale.
                    var apply=StaticMethod(lmType,"ApplyLocale",typeof(string),typeof(bool));
                    if(apply==null)
                    {
                        Status="NML语言刷新接口不可用，请在游戏设置中手动切换简体中文。";
                        return Status;
                    }
                    apply.Invoke(null,new object[]{"cz",true});
                    Status="已刷新当前简体中文语言；请检查原版和MOD实际显示。";
                    return Status;
                }
                // The player must control their own language preference. Do not
                // call game setLanguage() because loader/version behavior is unverified.
                Status="已登记简体中文（cz）翻译。请到原版设置中选择简体中文，"+
                       "然后点击「刷新简中」。当前语言："+(languageId??"未知");
                return Status;
            }
            catch(Exception e)
            {
                Status="语言刷新失败："+e.GetType().Name+"；不会自动更改游戏语言。";
                Debug.LogWarning("[XIANXIA-V23] LOCALE_APPLY "+e.GetType().Name);
                return Status;
            }
        }
    }
}
