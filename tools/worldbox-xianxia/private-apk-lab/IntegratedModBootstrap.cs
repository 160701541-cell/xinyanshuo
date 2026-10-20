using System;
using System.IO;
using System.Reflection;
using System.Collections;
using UnityEngine;

namespace XianxiaMonoBridge {
// ONE legacy Mono NML path, deliberately no LemonLoader/IL2CPP NML mobile DLL.
public sealed class IntegratedModBootstrap : MonoBehaviour {
    public static string Status="MOD：等待世界初始化（0/2）";
    public static void ConfigureMobileConsole(){
        if(Application.platform!=RuntimePlatform.Android)return;
        foreach(string name in new[]{"show_console_on_start","show_console_on_error","disable_loading_logs"}){
            var f=typeof(Config).GetField(name,BindingFlags.Static|BindingFlags.Public|BindingFlags.NonPublic);
            if(f!=null&&f.FieldType==typeof(bool))f.SetValue(null,name=="disable_loading_logs");
        }
    }
    bool consoleClosed;
    float nextConsoleCheck;
    bool attempted;
    float nextReport;
    int previousCount=-1;
    float previousStatus;
    static readonly System.Collections.Generic.HashSet<string> Resolving=new System.Collections.Generic.HashSet<string>();
    void Start(){
        AppDomain.CurrentDomain.AssemblyResolve+=Resolve;
        DiagnosticLog.Write("[XIANXIA-INTEGRATION] BOOTSTRAP_READY v18; waiting for original world initialization");
    }
    static Assembly Resolve(object sender,ResolveEventArgs args){
        string name=new AssemblyName(args.Name).Name;
        lock(Resolving){if(!Resolving.Add(name))return null;}
        try{
            foreach(Assembly loaded in AppDomain.CurrentDomain.GetAssemblies())
                if(loaded.GetName().Name==name)return loaded;
            string root=Application.persistentDataPath;
            foreach(string dir in new[]{Path.Combine(root,"mods/NML/Assemblies"),Path.Combine(root,"mono"),Path.Combine(root,"mods")}){
                string path=Path.Combine(dir,name+".dll");
                if(File.Exists(path))return Assembly.LoadFrom(path);
            }
            return null;
        }catch(Exception e){DiagnosticLog.Write("ASSEMBLY_RESOLVE_FAILED "+name+" "+e);return null;}
        finally{lock(Resolving){Resolving.Remove(name);}}
    }
    void Update(){
        // Initialization tasks can restore debug defaults. Repeat only during
        // startup, then hide the loading console once; leave manual toggles alone.
        if(!consoleClosed&&Time.unscaledTime>=nextConsoleCheck){
            nextConsoleCheck=Time.unscaledTime+1f;
            ConfigureMobileConsole();
            if(Config.game_loaded&&!SmoothLoader.isLoading()){
                try{
                    object map=MapBox.instance;
                    var field=typeof(MapBox).GetField("console",BindingFlags.Instance|BindingFlags.Public|BindingFlags.NonPublic);
                    object console=field==null?null:field.GetValue(map);
                    var hide=console==null?null:console.GetType().GetMethod("Hide",BindingFlags.Instance|BindingFlags.Public|BindingFlags.NonPublic,null,Type.EmptyTypes,null);
                    if(hide!=null){hide.Invoke(console,null);consoleClosed=true;DiagnosticLog.Write("STARTUP_CONSOLE_CLOSED; errors remain in session.log");}
                }catch(Exception e){DiagnosticLog.Write("CONSOLE_CLOSE_FAILED "+e.GetType().Name);consoleClosed=true;}
            }
        }
        if(!attempted){
            var gameLoaded=typeof(Config).GetField("game_loaded",BindingFlags.Static|BindingFlags.Public|BindingFlags.NonPublic);
            if(gameLoaded==null || !(bool)gameLoaded.GetValue(null))return;
            attempted=true;
            try{Boot();}catch(Exception e){Status="MOD启动失败："+e.GetType().Name+"，请复制日志";DiagnosticLog.Write("[XIANXIA-INTEGRATION] NML_BOOT_FAILED "+e);}
        }
        if(Time.unscaledTime<nextReport)return;
        nextReport=Time.unscaledTime+5f;
        try{
            Assembly nml=null;
            foreach(var a in AppDomain.CurrentDomain.GetAssemblies())if(a.GetName().Name=="NeoModLoader"){nml=a;break;}
            var entry=nml==null?null:nml.GetType("NeoModLoader.WorldBoxMod");
            var list=entry==null?null:entry.GetField("LoadedMods",BindingFlags.Public|BindingFlags.Static);
            var mods=list==null?null:list.GetValue(null) as IList;
            if(mods==null)return;
            if(mods.Count==previousCount && Time.unscaledTime-previousStatus<20f)return;
            previousCount=mods.Count;
            previousStatus=Time.unscaledTime;
            string names="";
            foreach(var mod in mods)names+=(names.Length>0?"、":"")+mod.GetType().Name;
            Status="MOD已注册："+mods.Count+"/2"+(names.Length>0?"\n"+names:"（尚未加载成功，请复制日志）");
            DiagnosticLog.Write("[XIANXIA-INTEGRATION] NML_ACTUALLY_LOADED_COUNT="+mods.Count);
            foreach(var component in Resources.FindObjectsOfTypeAll(entry)){
                foreach(string name in new[]{"initialized","initialized_successfully"}){
                    var flag=entry.GetField(name,BindingFlags.NonPublic|BindingFlags.Instance);
                    DiagnosticLog.Write("[XIANXIA-INTEGRATION] NML_STAGE "+name+"="+(flag==null?"missing":Convert.ToString(flag.GetValue(component))));
                }
            }
            foreach(var mod in mods){
                try{DiagnosticLog.Write("[XIANXIA-INTEGRATION] LOADED_ENTRY "+mod.GetType().FullName);}
                catch(Exception e){DiagnosticLog.Write("MOD_STATUS_ERROR "+e.GetType().Name);}
            }
            var states=entry.GetField("AllRecognizedMods",BindingFlags.NonPublic|BindingFlags.Static);
            var recognized=states==null?null:states.GetValue(null) as IDictionary;
            if(recognized!=null)foreach(DictionaryEntry state in recognized){
                var key=state.Key;var uid=key.GetType().GetProperty("UID");
                var fail=key.GetType().GetField("FailReason");
                DiagnosticLog.Write("[XIANXIA-INTEGRATION] MOD_STATE "+(uid==null?key:uid.GetValue(key,null))+"="+state.Value+
                    " reason="+(fail==null?"":Convert.ToString(fail.GetValue(key))));
            }
        }catch(Exception e){DiagnosticLog.Write("NML_STATUS_FAILED "+e.GetType().Name);}
    }
    void Boot(){
        string path=Path.Combine(Application.persistentDataPath,"mods/NeoModLoader.dll");
        Status="MOD：正在启动NeoModLoader（0/2）";
        DiagnosticLog.Write("[XIANXIA-INTEGRATION] BOOT_BEGIN loader="+path);
        if(!File.Exists(path))throw new FileNotFoundException("Automatic MOD payload missing",path);
        // Prevent a second native ModLoader pass after we instantiate its standard NML entry.
        foreach(var item in Resources.FindObjectsOfTypeAll(typeof(ModLoader))){
            var field=typeof(ModLoader).GetField("initialized",BindingFlags.Instance|BindingFlags.Public|BindingFlags.NonPublic);
            if(field!=null)field.SetValue(item,true);
            var behaviour=item as Behaviour;if(behaviour!=null)behaviour.enabled=false;
        }
        var experimental=typeof(Config).GetField("experimental_mode",BindingFlags.Static|BindingFlags.Public|BindingFlags.NonPublic);
        if(experimental!=null)experimental.SetValue(null,true);
        var assembly=Assembly.LoadFrom(path);
        DiagnosticLog.Write("[XIANXIA-INTEGRATION] NML_ASSEMBLY_LOADED from="+assembly.Location);
        var type=assembly.GetType("NeoModLoader.WorldBoxMod",true);
        if(Resources.FindObjectsOfTypeAll(type).Length==0){
            var host=new GameObject("NeoModLoader");UnityEngine.Object.DontDestroyOnLoad(host);host.AddComponent(type);
        }
        DiagnosticLog.Write("[XIANXIA-INTEGRATION] NML_ENTRY_CREATED "+assembly.GetName().Version+"; mod initialization not yet confirmed");
    }
}
}
