using System;
using System.Linq;
using System.Reflection;

// Original WorldBox Mono 0.51.4 user-owned lab only; does not mutate any
// existing world, save, NPC, paid capability or Canglan project.
// This helper is injected into the EXISTING WorldBox Mono bridge Update loop.
// Unavailability of a compatible API fails closed; runtime device pending.
namespace XianxiaWorldBox
{
    public static class MapPresetBridgeV32
    {
        public const string Id="xianxia_extreme_32";
        public const int Chunks=32;
        public const int Tiles=2048;
        static readonly BindingFlags F=BindingFlags.Public|BindingFlags.NonPublic|
            BindingFlags.Static|BindingFlags.Instance;
        static DateTime retryAt=DateTime.MinValue;
        static bool logged;
        public static bool Ready {get;private set;}
        public static string Status {get;private set;}="等待游戏新建世界地图列表";
        static object Member(object instance,string key)
        {
            if(instance==null)return null;
            Type type=instance is Type?(Type)instance:instance.GetType();
            FieldInfo field=type.GetField(key,F);
            if(field!=null)return field.GetValue(field.IsStatic?null:instance);
            PropertyInfo prop=type.GetProperty(key,F);
            if(prop==null||prop.GetIndexParameters().Length!=0)return null;
            MethodInfo getter=prop.GetGetMethod(true);
            return getter==null?null:prop.GetValue(getter.IsStatic?null:instance,null);
        }
        static bool Set(object instance,string name,object value)
        {
            if(instance==null)return false;
            Type type=instance.GetType();
            FieldInfo field=type.GetField(name,F);
            if(field!=null&&!field.IsInitOnly) {
                field.SetValue(field.IsStatic?null:instance,Convert.ChangeType(value,field.FieldType));
                return true;
            }
            PropertyInfo prop=type.GetProperty(name,F);
            if(prop==null||!prop.CanWrite||prop.GetIndexParameters().Length!=0)return false;
            prop.SetValue(instance,Convert.ChangeType(value,prop.PropertyType),null);
            return true;
        }
        static string[] Sizes(Type sizeLibrary)
        {
            MethodInfo method=sizeLibrary.GetMethod("getSizes",F,null,Type.EmptyTypes,null);
            if(method==null)return null;
            return method.Invoke(null,null) as string[];
        }
        public static string TryRegister(Assembly game)
        {
            if(game==null)return Status="WORLD_SIZE_NOT_READY missing Assembly-CSharp";
            Type manager=game.GetType("AssetManager"), size=game.GetType("MapSizeAsset");
            Type library=game.GetType("MapSizeLibrary");
            if(manager==null||size==null||library==null)
                return Status="WORLD_SIZE_INCOMPATIBLE map size API unavailable";
            object lib=Member(manager,"map_sizes");
            if(lib==null)return Status="WORLD_SIZE_NOT_READY AssetManager.map_sizes";
            // Actual user-owned WorldBox 0.51.4 MapSizeLibrary has NO
            // 'titanic' instance field. It stores vanilla presets in
            // inherited AssetLibrary<MapSizeAsset>.get("titanic").
            // The former Member(lib,"titanic") always failed before add().
            var lookup=lib.GetType().GetMethods(F).FirstOrDefault(m=>m.Name=="get"&&
                m.GetParameters().Length==1&&m.GetParameters()[0].ParameterType==typeof(string));
            if(lookup==null)return Status="WORLD_SIZE_INCOMPATIBLE AssetLibrary.get(string) absent";
            object vanilla=lookup.Invoke(lib,new object[]{"titanic"});
            if(vanilla==null)return Status="WORLD_SIZE_NOT_READY vanilla Titanic asset absent";
            object preset=lookup.Invoke(lib,new object[]{Id});
            if(preset==null)
            {
                preset=Activator.CreateInstance(size);
                if(preset==null||!Set(preset,"id",Id)||!Set(preset,"size",Chunks))
                    return Status="WORLD_SIZE_INCOMPATIBLE preset fields";
                object icon=Member(vanilla,"path_icon");
                if(icon!=null)Set(preset,"path_icon",icon);
                try{Set(preset,"show_warning",true);}catch{/* optional */}
                var add=lib.GetType().GetMethods(F).FirstOrDefault(m=>m.Name=="add"&&
                    m.GetParameters().Length==1&&m.GetParameters()[0].ParameterType.IsAssignableFrom(size));
                if(add==null)return Status="WORLD_SIZE_INCOMPATIBLE add(MapSizeAsset)";
                add.Invoke(lib,new[]{preset});
                if(lookup!=null)
                {
                    var registered=lookup.Invoke(lib,new object[]{Id});
                    if(registered==null)return Status="WORLD_SIZE_UNCONFIRMED size registration";
                }
            }
            object stored=Member(preset,"size");
            if(stored==null||Convert.ToInt32(stored)!=Chunks)
                return Status="WORLD_SIZE_CONFLICT preset exists with another chunk count";
            string[] visible=Sizes(library);
            if(visible==null)return Status="WORLD_SIZE_NOT_READY getSizes() is not string[]";
            if(!visible.Contains(Id))
            {
                // Real 0.51.4 MapSizeLibrary.linkAssets initializes its UI
                // list by convertToOldFormat() -> _mapSizes from 'list'.
                // Reuse that SAME native list rebuilder after registering
                // the asset, rather than maintain an unrelated guessed list.
                // A user-installed other map MOD is preserved by the list.
                MethodInfo rebuild=library.GetMethod("convertToOldFormat",F,
                    null,Type.EmptyTypes,null);
                if(rebuild!=null)
                {
                    rebuild.Invoke(rebuild.IsStatic?null:lib,null);
                    string[] built=Sizes(library);
                    if(built!=null&&built.Contains(Id))
                    {
                        visible=built;
                    }
                }
            }
            if(!visible.Contains(Id))
            {
                FieldInfo cache=library.GetField("_mapSizes",F);
                object owner=cache!=null&&cache.IsStatic?null:lib;
                if(cache==null||cache.IsInitOnly||cache.FieldType!=typeof(string[]) ||
                   visible.Length==0||visible.Length>128 ||
                   !(cache.GetValue(owner) is string[]))return Status="WORLD_SIZE_NOT_READY UI cache";
                string[] old=(string[])cache.GetValue(owner);
                string vanillaId=Convert.ToString(Member(vanilla,"id"));
                if(string.IsNullOrEmpty(vanillaId)||!visible.Contains(vanillaId)||
                    !old.SequenceEqual(visible))
                    return Status="WORLD_SIZE_NOT_READY UI list mismatch";
                string[] next=new string[old.Length+1];
                Array.Copy(old,next,old.Length);
                next[old.Length]=Id;
                bool confirmed=false;
                try{
                    cache.SetValue(owner,next);
                    string[] live=Sizes(library);
                    confirmed=live!=null&&live.Contains(Id);
                }finally{
                    if(!confirmed)cache.SetValue(owner,old);
                }
                if(!confirmed)return Status="WORLD_SIZE_UNCONFIRMED UI cache reverted";
            }
            Ready=true;
            return Status="WORLD_SIZE_PRESET_READY 2048x2048 new world list="+
                Sizes(library).Length+"; real generation/save still untested";
        }
        static void Log(string message)
        {
            try {
                foreach(Assembly assembly in AppDomain.CurrentDomain.GetAssemblies()){
                    Type debug=assembly.GetType("UnityEngine.Debug",false);
                    MethodInfo log=debug==null?null:debug.GetMethod("Log",F,null,new[]{typeof(object)},null);
                    if(log!=null){log.Invoke(null,new object[]{"[WANJIE-MAP-V32] "+message});return;}
                }
            }catch{}
        }
        public static void Tick()
        {
            if(Ready)return;
            DateTime now=DateTime.UtcNow;
            if(now<retryAt)return;
            retryAt=now.AddSeconds(5);
            try{
                Assembly game=null;
                foreach(Assembly a in AppDomain.CurrentDomain.GetAssemblies())
                    if(a.GetName().Name=="Assembly-CSharp"){game=a;break;}
                string result=TryRegister(game);
                if(!logged||Ready){Log(result);logged=true;}
            }catch(Exception ex){
                Status="WORLD_SIZE_ERROR "+ex.GetType().Name;
                if(!logged){Log(Status);logged=true;}
            }
        }
    }
}
