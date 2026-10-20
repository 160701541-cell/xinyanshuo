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

        static IEnumerable<object> WalkPairs(object dictionary)
        {
            if(dictionary is IEnumerable)
            {
                foreach(object pair in (IEnumerable)dictionary)yield return pair;
                yield break;
            }
            // Android IL2CPP projected generic dictionaries may implement
            // Il2CppSystem.IEnumerable instead of System.Collections.IEnumerable.
            var method=dictionary.GetType().GetMethod("GetEnumerator",Type.EmptyTypes);
            if(method==null)yield break;
            object iterator=method.Invoke(dictionary,null);
            if(iterator==null)yield break;
            var next=iterator.GetType().GetMethod("MoveNext",Type.EmptyTypes);
            if(next==null)yield break;
            int count=0;
            try
            {
                while(count++<MaxDictionaryRead && Convert.ToBoolean(next.Invoke(iterator,null)))
                    yield return Member(iterator,"Current");
            }
            finally
            {
                var d=iterator as IDisposable;
                if(d!=null)d.Dispose();
            }
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
                if(!(dictionary is IEnumerable)&&dictionary.GetType().GetMethod("GetEnumerator",Type.EmptyTypes)==null)
                {
                    Status="当前安卓本地化字典无法安全枚举；未做修改。";
                    return Status;
                }
                // WorldBox's own 0.51.4 APK already ships locales/cz.
                // The live dictionary loaded in "en" is NOT proof a key is
                // untranslated in "cz". Registering guesses now would shadow
                // official native translations after the language changes.
                string active=Convert.ToString(Member(manager,"language"))??"未知";
                if(active!="cz")
                {
                    Status="当前原版语言为 "+active+
                        "。先切到原版简体中文再补译；不覆盖未知原生中文。";
                    return Status;
                }
                MethodInfo add=StaticMethod(lmType,"Add",typeof(string),typeof(string),typeof(string));
                MethodInfo has=StaticMethod(lmType,"Has",typeof(string),typeof(string));
                int considered=0;
                foreach(object item in WalkPairs(dictionary))
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
                        object k=Member(item,"Key"),v=Member(item,"Value");
                        key=k==null?null:Convert.ToString(k);
                        original=v==null?null:Convert.ToString(v);
                    }
                    if(string.IsNullOrEmpty(key)||key.Length>150||!IsEnglishLike(original))
                        continue;
                    // A native Chinese value is authoritative; do not use an
                    // English fallback guessed from this key to replace it.
                    if(ContainsChinese(original))continue;
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


        /// <summary>
        /// Explicit, bounded, read-only audit of the *active* game string table.
        /// This never logs/persists personal names, game text or locale keys.
        /// The counts are not a percentage of complete menu localization.
        /// </summary>
        public static string VerifyCurrentLocale()
        {
            try
            {
                Type native=FindType("LocalizedTextManager");
                object live=StaticMember(native,"instance");
                if(live==null)return "原版语言管理器尚未就绪；未做修改。";
                string code=Convert.ToString(Member(live,"language"))??"未知";
                object table=Member(live,"_localized_text");
                if(table==null)return "原版语言码 "+code+"；语言字典尚未载入。";
                if(!(table is IEnumerable)&&table.GetType().GetMethod("GetEnumerator",Type.EmptyTypes)==null)
                    return "原版语言码 "+code+"；本机无法枚举字典，不报完成。";
                int seen=0,han=0,latin=0,other=0;
                long start=DateTime.UtcNow.Ticks;
                bool capped=false;
                foreach(object entry in WalkPairs(table))
                {
                    if(seen>=2000 || DateTime.UtcNow.Ticks-start>150*TimeSpan.TicksPerMillisecond)
                    {
                        capped=true;break;
                    }
                    if(entry==null)continue;
                    object value=entry is DictionaryEntry?((DictionaryEntry)entry).Value:Member(entry,"Value");
                    string text=value==null?null:Convert.ToString(value);
                    if(string.IsNullOrEmpty(text))continue;
                    seen++;
                    if(ContainsChinese(text)){han++;continue;}
                    bool eng=false;
                    for(int i=0;i<text.Length&&i<512;i++)
                    {
                        char c=text[i];
                        if(c>='a'&&c<='z'||c>='A'&&c<='Z'){eng=true;break;}
                    }
                    if(eng)latin++;else other++;
                }
                return "原版语言码 "+code+"；实际文本抽样 "+seen+
                    "项（含汉字"+han+"／拉丁字母"+latin+"／其他"+other+"）"+
                    (capped?"，已限额截断":"")+
                    "。仅运行时诊断，非全量汉化完成率。";
            }
            catch(Exception e)
            {
                return "实际简中核验失败："+e.GetType().Name+"；不代表汉化完成。";
            }
        }

        public static bool LastPackOk {get;private set;}

        /// <summary>
        /// NML supports registering exact, existing or third-party MOD locale keys.
        /// This does not infer keys from English UI text. Imported strings are
        /// user-supplied; loaded only on explicit UI action.
        /// </summary>
        public static string RegisterExplicitKeys(IDictionary<string,string> translations)
        {
            LastPackOk=false;
            if(translations==null||translations.Count==0)
                return "中文键值包为空；未登记。";
            try
            {
                if(!Discover())
                    return "原版语言/NML接口不可用，无法登记自定义翻译键。";
                var add=StaticMethod(lmType,"Add",typeof(string),typeof(string),typeof(string));
                var has=StaticMethod(lmType,"Has",typeof(string),typeof(string));
                if(add==null||has==null)
                    return "NML语言接口不支持安全检测翻译冲突；未登记。";
                string current=Convert.ToString(Member(manager,"language"));
                object raw=Member(manager,"_localized_text");
                // We check game-native Chinese values separately because LM.Has
                // only reflects MOD-registered translations, not vanilla locales.
                var readable=raw as IDictionary;
                int registered=0,existing=0,native=0,errors=0;
                foreach(var pair in translations)
                {
                    if(pair.Key==null||pair.Value==null)continue;
                    if((bool)has.Invoke(null,new object[]{pair.Key,"cz"}))
                    {
                        existing++;continue;
                    }
                    if(current=="cz" && readable!=null && readable.Contains(pair.Key))
                    {
                        string currentValue=Convert.ToString(readable[pair.Key]);
                        if(ContainsChinese(currentValue)){native++;continue;}
                    }
                    try
                    {
                        add.Invoke(null,new object[]{"cz",pair.Key,pair.Value});
                        registered++;
                    }
                    catch {errors++;break;}
                }
                LastPackOk=errors==0;
                if(LastPackOk)Ready=true;
                return "已登记 "+registered+" 条，跳过其他MOD已有 "+existing+
                    " 条、原生简中已有 "+native+" 条"+
                    (errors==0?"。":"，部分登记失败，需检查日志。");
            }
            catch(Exception e)
            {
                return "翻译包注册失败："+e.GetType().Name+"；未改变世界存档。";
            }
        }

        static bool ContainsChinese(string value)
        {
            if(string.IsNullOrEmpty(value))return false;
            foreach(char c in value)
                if(c>=0x3400&&c<=0x9fff)return true;
            return false;
        }

        /// <summary>
        /// Explicit player-requested language switch. Verifies the exact public
        /// WorldBox manager method before invoking; never runs automatically.
        /// </summary>
        public static string SwitchToChineseByUserTap()
        {
            try
            {
                if(!Discover())return "无法检测原版语言管理器；没有修改当前语言。";
                MethodInfo change=managerType.GetMethod("setLanguage",
                    BindingFlags.Instance|BindingFlags.Public,null,
                    new[]{typeof(string)},null);
                if(change==null)
                    return "当前版本没有可确认的简中切换接口；未更改设置。";
                change.Invoke(manager,new object[]{"cz"});
                // Original game is responsible for remembering this explicit choice.
                // NML setLanguagePostfix should apply previously registered locales.
                // An invoked method is not evidence of a completed locale switch.
                string active=Convert.ToString(Member(manager,"language"))??"未知";
                if(active!="cz")
                    return "已请求切换简中，但原版语言码仍为 "+active+"，结果未确认。";
                return "已请求切换，原版语言码已显示cz；还需逐页实机汉化验收。";
            }
            catch(Exception e)
            {
                return "语言切换失败："+e.GetType().Name+"；可返回原版语言设置。";
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
