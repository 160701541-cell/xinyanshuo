using System;
using System.Reflection;

namespace XianxiaWorldBox
{
    /// <summary>
    /// Fetch this MOD's own verified NML-localized UI keys without hard
    /// dependency on mobile NML versions that may expose a different API.
    /// BasicMod already implements ILocalizable; packaged Locales/cz.json
    /// and Locales/en.json should be auto-loaded by compatible NML.
    /// No game-owned locale key is fabricated or overwritten by this class.
    /// </summary>
    public static class OwnLocaleLabelsV25
    {
        const string Prefix="xinyanshuo.wb.";
        static Type type;
        static MethodInfo get;
        static bool resolved;

        public static string Get(string id,string fallbackChinese)
        {
            if(string.IsNullOrEmpty(id)||string.IsNullOrEmpty(fallbackChinese))
                return fallbackChinese;
            if(!resolved)
            {
                resolved=true;
                foreach(var assembly in AppDomain.CurrentDomain.GetAssemblies())
                {
                    try
                    {
                        type=assembly.GetType("NeoModLoader.General.LM",false);
                        if(type!=null)break;
                    }
                    catch { }
                }
                if(type!=null)
                    get=type.GetMethod("Get",BindingFlags.Public|BindingFlags.Static,
                        null,new[]{typeof(string)},null);
            }
            if(get!=null)
            {
                try
                {
                    string key=Prefix+id;
                    string text=get.Invoke(null,new object[]{key}) as string;
                    if(!string.IsNullOrEmpty(text)&&text!=key&&
                        !text.StartsWith("MISSING_LOCALE",StringComparison.OrdinalIgnoreCase))
                        return text;
                }
                catch { }
            }
            // All own UI must remain readable even when the NML JSON loader
            // is absent or the game is too old to support this API.
            return fallbackChinese;
        }
        public static void Reset()
        {
            type=null;get=null;resolved=false;
        }
    }
}
