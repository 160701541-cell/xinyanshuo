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
        static DateTime next=DateTime.MinValue;
        public static string Status="10000x10000虚拟区块层等待启动（不是Unity地图）";
        public static WorldGridExactV41 World { get { return world; } }
        public static long LogicalTileCount { get { return WorldGridExactV41.LogicalTileCount; } }
        public static int MemoryBudgetChunks { get { return 12; } }
        public static void Tick()
        {
            DateTime now=DateTime.UtcNow;
            if(now<next)return;
            next=now.AddSeconds(10);
            try
            {
                if(world==null)
                {
                    var game=AppDomain.CurrentDomain.GetAssemblies();
                    string storage=null;
                    foreach(var assembly in game)
                    {
                        var app=assembly.GetType("UnityEngine.Application",false);
                        var persistent=app?.GetProperty("persistentDataPath",BindingFlags.Public|BindingFlags.Static);
                        if(persistent!=null)
                        {
                            storage=persistent.GetValue(null,null) as string;
                            if(!string.IsNullOrEmpty(storage))break;
                        }
                    }
                    if(string.IsNullOrEmpty(storage))
                    {
                        Status="V41_WAIT_ANDROID_APPLICATION_PATH";
                        return;
                    }
                    // Keep world data in application-specific writable path, never private keys or original saves.
                    world=new WorldGridExactV41(Path.Combine(storage,"XianxiaVirtual10000_v41"),0x51A41207,12);
                }
                // Tiny, bounded preview sample; no 100M GameObject allocation.
                byte[] sample=world.SampleOverview(0,0,10000,10000,8);
                world.SaveDirty(1);
                Status="V41_VIRTUAL_GRID_READY 10000x10000, chunks="+
                    (WorldGridExactV41.ChunksX*WorldGridExactV41.ChunksY)+
                    " cache="+world.ResidentChunkCount+"/12 sample="+sample.Length+
                    " | NOT_CONNECTED_TO_MAPBOX";
            }
            catch(Exception e){Status="V41_VIRTUAL_GRID_ERROR "+e.GetType().Name;}
        }
    }
}
