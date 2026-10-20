using System;
using System.Collections;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;

namespace XianxiaWorldBox
{
    /// <summary>
    /// Safe, reversible Chinese overlay for visible Unity UI.Text and TMP_Text.
    /// Not a complete game localization hook: only exact matching labels,
    /// and does not intercept Unity IMGUI or native WorldBox translation keys.
    /// </summary>
    public static class RuntimeChineseOverlayV22
    {
        sealed class Entry
        {
            public object Component;
            public PropertyInfo TextProperty;
            public string Original;
            public string Translation;
        }

        const int MaxTracked = 480;
        const int MaxSeenPerType = 1200;
        static readonly Dictionary<int, Entry> Patched = new Dictionary<int, Entry>();
        static readonly string[] TextTypes = {"UnityEngine.UI.Text","TMPro.TMP_Text"};
        static readonly string[] Assemblies = {"UnityEngine.UI","Unity.TextMeshPro"};
        static Type[] resolved;
        static float nextScan;
        static int scannedLast;
        static int translatedLast;
        static int visibleChinese,visibleLatin,visibleOther;
        static int failures;
        public static bool Enabled = true;
        public static int LiveTranslatedCount { get {return Patched.Count;} }
        public static int ScannedLast { get {return scannedLast;} }
        public static int TranslatedLast { get {return translatedLast;} }
        // Snapshot of currently active UI.Text/TMP labels only; no IMGUI,
        // sprite text, game save labels or per-page coverage claim.
        public static int VisibleChinese {get {return visibleChinese;}}
        public static int VisibleLatin {get {return visibleLatin;}}
        public static int VisibleOther {get {return visibleOther;}}
        public static string VisibleAudit
        {
            get {return "当前可见文本抽样：中文 "+visibleChinese+
                "，纯拉丁文字 "+visibleLatin+"，其他 "+visibleOther+
                "；不含IMGUI/自绘，不等于全量汉化率。";}
        }
        static void CountVisible(string value)
        {
            bool chinese=false,latin=false;
            if(string.IsNullOrEmpty(value))return;
            for(int i=0;i<value.Length&&i<180;i++)
            {
                char c=value[i];
                if(c>=0x3400&&c<=0x9fff)chinese=true;
                else if(c>='a'&&c<='z'||c>='A'&&c<='Z')latin=true;
            }
            if(chinese)visibleChinese++;
            else if(latin)visibleLatin++;
            else visibleOther++;
        }
        public static string Status
        {
            get {return "中文显示："+(Enabled?"开":"关")+
                    "，最近检查 "+scannedLast+" 项、命中 "+translatedLast+
                    " 项，当前接管 "+Patched.Count+" 项。";}
        }

        public static void SetEnabled(bool yes)
        {
            if(Enabled==yes)return;
            Enabled=yes;
            if(!yes)Restore();
            nextScan=0f;
        }
        public static void Tick()
        {
            if(!Enabled||Time.unscaledTime<nextScan)return;
            nextScan=Time.unscaledTime+5f;
            scannedLast=0;translatedLast=0;
            visibleChinese=0;visibleLatin=0;visibleOther=0;
            try
            {
                if(resolved==null)
                {
                    resolved=new Type[TextTypes.Length];
                    for(int i=0;i<TextTypes.Length;i++)resolved[i]=FindType(TextTypes[i],Assemblies[i]);
                }
                for(int i=0;i<resolved.Length;i++)ScanType(resolved[i]);
            }
            catch(Exception e)
            {
                failures++;
                if(failures<=3)Debug.LogWarning("[XIANXIA-ZH-V22] Scan "+e.GetType().Name);
                nextScan=Time.unscaledTime+20f;
            }
        }

        static Type FindType(string fullName,string assembly)
        {
            var type=Type.GetType(fullName+", "+assembly,false);
            if(type!=null)return type;
            foreach(var a in AppDomain.CurrentDomain.GetAssemblies())
            {
                try {type=a.GetType(fullName,false);if(type!=null)return type;}
                catch { }
            }
            return null;
        }
        static IEnumerable FindTextComponents(Type type)
        {
            foreach(var method in typeof(Resources).GetMethods(BindingFlags.Public|BindingFlags.Static))
            {
                if(method.Name!="FindObjectsOfTypeAll"||method.IsGenericMethodDefinition)continue;
                var ps=method.GetParameters();
                if(ps.Length!=1)continue;
                object requested=null;
                if(ps[0].ParameterType==typeof(Type))requested=type;
                else if(ps[0].ParameterType.FullName=="Il2CppSystem.Type")
                {
                    Type bridge=Type.GetType("Il2CppInterop.Runtime.Il2CppType, Il2CppInterop.Runtime",false);
                    if(bridge==null)continue;
                    foreach(var convert in bridge.GetMethods(BindingFlags.Public|BindingFlags.Static))
                    {
                        if(convert.Name!="Of"||!convert.IsGenericMethodDefinition||
                            convert.GetGenericArguments().Length!=1||convert.GetParameters().Length!=0)continue;
                        try {requested=convert.MakeGenericMethod(type).Invoke(null,null);break;}
                        catch { }
                    }
                }
                if(requested==null)continue;
                try {return method.Invoke(null,new[]{requested}) as IEnumerable;}
                catch { }
            }
            return null;
        }
        static bool IsActive(object component)
        {
            try
            {
                var p=component.GetType().GetProperty("gameObject",BindingFlags.Public|BindingFlags.Instance);
                object go=p==null?null:p.GetValue(component,null);
                if(go==null)return false;
                var active=go.GetType().GetProperty("activeInHierarchy",BindingFlags.Public|BindingFlags.Instance);
                return active==null||Convert.ToBoolean(active.GetValue(go,null));
            }
            catch {return false;}
        }
        static void ScanType(Type type)
        {
            if(type==null)return;
            PropertyInfo text=type.GetProperty("text",BindingFlags.Public|BindingFlags.Instance);
            if(text==null||!text.CanRead||!text.CanWrite||text.PropertyType!=typeof(string))return;
            var components=FindTextComponents(type);
            if(components==null)return;
            int seen=0;
            foreach(object component in components)
            {
                if(component==null||++seen>MaxSeenPerType)break;
                if(!IsActive(component))continue;
                scannedLast++;
                try
                {
                    string current=text.GetValue(component,null) as string;
                    if(string.IsNullOrEmpty(current)||current.Length>180)continue;
                    int key=component.GetHashCode();
                    Entry known;
                    if(Patched.TryGetValue(key,out known))
                    {
                        // Do not hijack dynamically changing labels, timers, etc.
                        if(!object.ReferenceEquals(known.Component,component)||
                            current!=known.Translation)
                            Patched.Remove(key);
                        else
                        {
                            CountVisible(current);
                            continue;
                        }
                    }
                    if(Patched.Count>=MaxTracked){CountVisible(current);continue;}
                    string chinese=ChineseLocalizationV22.Translate(current);
                    if(chinese==current||string.IsNullOrEmpty(chinese))
                    {
                        CountVisible(current);
                        UntranslatedMenuAuditV23.Observe(current);
                        continue;
                    }
                    text.SetValue(component,chinese,null);
                    CountVisible(chinese);
                    Patched[key]=new Entry {
                        Component=component,TextProperty=text,
                        Original=current,Translation=chinese
                    };
                    translatedLast++;
                }
                catch { /* One incompatible foreign MOD component must not crash game. */ }
            }
        }
        public static void Restore()
        {
            foreach(var item in Patched.Values)
            {
                try
                {
                    // Only restore our own exact overlay; never overwrite text
                    // that WorldBox or another MOD has since updated.
                    object current=item.TextProperty.GetValue(item.Component,null);
                    if(current is string&&((string)current)==item.Translation)
                        item.TextProperty.SetValue(item.Component,item.Original,null);
                }
                catch { }
            }
            Patched.Clear();scannedLast=0;translatedLast=0;
            visibleChinese=0;visibleLatin=0;visibleOther=0;
        }
        public static void Shutdown()
        {
            Restore();resolved=null;nextScan=0f;Enabled=true;
        }
    }
}
