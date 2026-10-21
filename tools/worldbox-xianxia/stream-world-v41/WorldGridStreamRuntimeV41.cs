// Hosted through the already-installed WorldBox owned Mono helper Tick() hook.
// This is an independent 10k x 10k virtual layer. It does NOT enlarge Unity MapBox.
using System;
using System.IO;
using System.Reflection;
using XianxiaWorldBox.HugeWorld;
namespace XianxiaWorldBox.HugeWorld
{
    public static class WorldGridStreamRuntimeV41
    {
        static WorldGridExactV41 world;
        static WorldGridSaveScopeV45 saveScope;
        static string runtimeFolder;
        static string previewSessionFolder;
        public static bool BoundToRealSave { get { return saveScope!=null&&saveScope.BoundToNamedSave; } }
        static DateTime next=DateTime.MinValue;
        public static string Status="10000x10000虚拟区块层等待启动（不是Unity地图）";
        public static WorldGridExactV41 World { get { return world; } }
        public static long LogicalTileCount { get { return WorldGridExactV41.LogicalTileCount; } }
        public static int MemoryBudgetChunks { get { return 12; } }
        // Must be called ONLY after retrieving a stable unique WorldBox
        // save-slot ID from a verified game API. A visible kingdom or world
        // NAME cannot be substituted; no auto-guessing to avoid save leakage.
        public static bool BindAuthoritativeWorldSave(string saveId,uint seed)
        {
            try
            {
                string path=FindAppStorage();
                if(string.IsNullOrEmpty(path))
                {
                    Status="V45_SAVE_BIND_WAIT_ANDROID_PATH";return false;
                }
                if(saveScope==null)saveScope=new WorldGridSaveScopeV45(path,12);
                if(world!=null&&!saveScope.BoundToNamedSave)
                {
                    world.Dispose();world=null;
                }
                world=saveScope.BindAuthoritativeSave(saveId,seed);
                Status="V45_SAVE_SCOPED "+saveScope.WorldHash+
                    " 10000x10000 (NOT_CONNECTED_TO_MAPBOX)";
                return true;
            }
            catch(Exception e){Status="V45_SAVE_BIND_ERROR "+e.GetType().Name;return false;}
        }
        static string FindAppStorage()
        {
            if(!string.IsNullOrEmpty(runtimeFolder))return runtimeFolder;
            foreach(var assembly in AppDomain.CurrentDomain.GetAssemblies())
            {
                var app=assembly.GetType("UnityEngine.Application",false);
                var persistent=app?.GetProperty("persistentDataPath",BindingFlags.Public|BindingFlags.Static);
                if(persistent==null)continue;
                var result=persistent.GetValue(null,null) as string;
                if(!string.IsNullOrEmpty(result))return runtimeFolder=result;
            }
            return null;
        }
        public static void Tick()
        {
            DateTime now=DateTime.UtcNow;
            if(now<next)return;
            next=now.AddSeconds(10);
            try
            {
                if(world==null)
                {
                    string storage=FindAppStorage();
                    if(string.IsNullOrEmpty(storage))
                    {
                        Status="V41_WAIT_ANDROID_APPLICATION_PATH";
                        return;
                    }
                    // Unbound preview gets a fresh session-only namespace.
                    // It must NEVER reuse the old global v41 folder across saves.
                    if(previewSessionFolder==null)
                        previewSessionFolder=Path.Combine(storage,"XianxiaVirtual10000_v45",
                            "transient-"+Guid.NewGuid().ToString("N"));
                    world=new WorldGridExactV41(previewSessionFolder,0x51A41207,12);
                }
                // Tiny, bounded preview sample; no 100M GameObject allocation.
                byte[] sample=world.SampleOverview(0,0,10000,10000,8);
                world.SaveDirty(1);
                Status="V41_VIRTUAL_GRID_READY 10000x10000, chunks="+
                    (WorldGridExactV41.ChunksX*WorldGridExactV41.ChunksY)+
                    " cache="+world.ResidentChunkCount+"/12 sample="+sample.Length+
                    (BoundToRealSave?" | SAVE_ID_BOUND":" | TRANSIENT_PREVIEW_UNBOUND")+
                    " | NOT_CONNECTED_TO_MAPBOX";
            }
            catch(Exception e){Status="V41_VIRTUAL_GRID_ERROR "+e.GetType().Name;}
        }
    }
}
