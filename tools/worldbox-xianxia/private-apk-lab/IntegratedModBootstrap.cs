using System;
using System.IO;
using System.Reflection;
using System.Collections;
using UnityEngine;

namespace XianxiaMonoBridge {
// ONE legacy Mono NML path, deliberately no LemonLoader/IL2CPP NML mobile DLL.
public sealed class IntegratedModBootstrap : MonoBehaviour {
    bool attempted;
    float nextReport;
    int previousCount=-1;
    float previousStatus;
    static readonly System.Collections.Generic.HashSet<string> Resolving=new System.Collections.Generic.HashSet<string>();
    void Start(){
        AppDomain.CurrentDomain.AssemblyResolve+=Resolve;
        DiagnosticLog.Write("[XIANXIA-INTEGRATION] BOOTSTRAP_READY v16; waiting for original world initialization");
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
        if(!attempted){
            var gameLoaded=typeof(Config).GetField("game_loaded",BindingFlags.Static|BindingFlags.Public|BindingFlags.NonPublic);
            if(gameLoaded==null || !(bool)gameLoaded.GetValue(null))return;
            attempted=true;
            try{Boot();}catch(Exception e){DiagnosticLog.Write("[XIANXIA-INTEGRATION] NML_BOOT_FAILED "+e);}
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
            DiagnosticLog.Write("[XIANXIA-INTEGRATION] NML_ACTUALLY_LOADED_COUNT="+mods.Count);
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
        var type=assembly.GetType("NeoModLoader.WorldBoxMod",true);
        if(Resources.FindObjectsOfTypeAll(type).Length==0){
            var host=new GameObject("NeoModLoader");UnityEngine.Object.DontDestroyOnLoad(host);host.AddComponent(type);
        }
        DiagnosticLog.Write("[XIANXIA-INTEGRATION] NML_ENTRY_CREATED "+assembly.GetName().Version+"; mod initialization not yet confirmed");
    }
}
}
