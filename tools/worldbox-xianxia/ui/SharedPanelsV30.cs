using System;
namespace XianxiaWorldBox {
    // Process-local state shared by the native Mono bridge and NML assembly.
    public static class SharedPanelsV30 {
        const string Key="xys.worldbox.active_panel.v30";
        const string NativeKey="xys.worldbox.native_menu.v30";
        public static string Active { get { return AppDomain.CurrentDomain.GetData(Key) as string ?? ""; } }
        public static bool NativeMenu { get { return object.Equals(AppDomain.CurrentDomain.GetData(NativeKey),true); } }
        public static void RegisterNativeMenu(){AppDomain.CurrentDomain.SetData(NativeKey,true);}
        public static void Show(string name){AppDomain.CurrentDomain.SetData(Key,name??"");}
        public static void Toggle(string name){Show(Active==name?"":name);}
        public static void Close(){Show("");}
    }
}
