using System;
using System.IO;
using XianxiaWorldBox.HugeWorld;
public static class WorldGridSaveScopeTestsV45
{
    static void Check(bool ok,string reason){if(!ok)throw new Exception(reason);}
    static void Reject(Action work,string reason)
    {
        try{work();}catch(ArgumentException){return;}catch(InvalidOperationException){return;}
        throw new Exception("Must reject "+reason);
    }
    public static void Main()
    {
        string root=Path.Combine(Path.GetTempPath(),"wbx_scope_v45_"+Guid.NewGuid().ToString("N"));
        try
        {
            Check(WorldGridSaveScopeV45.SafeSaveKey("original-game-save-A")==
                  WorldGridSaveScopeV45.SafeSaveKey("original-game-save-A"),"deterministic");
            Check(WorldGridSaveScopeV45.SafeSaveKey("original-game-save-A")!=
                  WorldGridSaveScopeV45.SafeSaveKey("original-game-save-B"),"different save IDs");
            Reject(()=>WorldGridSaveScopeV45.SafeSaveKey("../\nsecret"),"control chars");
            Reject(()=>WorldGridSaveScopeV45.SafeSaveKey(""),"no identity");
            byte savedA,savedB;
            using(var scope=new WorldGridSaveScopeV45(root,4))
            {
                var first=scope.BindAuthoritativeSave("save-A",123);
                Check(scope.BoundToNamedSave,"explicit save binding");
                savedA=(byte)((first.NaturalTile(9999,9999)+1)%5);
                first.WriteTile(9999,9999,savedA);
                Check(scope.BindAuthoritativeSave("save-A",123)==first,"same ID returns same instance");
                Reject(()=>scope.BindAuthoritativeSave("save-A",777),"same ID with changed seed");
                var second=scope.BindAuthoritativeSave("save-B",456);
                Check(!Object.ReferenceEquals(first,second),"switch must close previous world");
                Check(second.ReadTile(9999,9999)==second.NaturalTile(9999,9999),
                    "different save must not read previous changes");
                savedB=(byte)((second.NaturalTile(9999,9999)+2)%5);
                second.WriteTile(9999,9999,savedB);
                Check(scope.BindAuthoritativeSave("save-A",123).ReadTile(9999,9999)==savedA,
                    "original save persisted after switch");
                Check(scope.BindAuthoritativeSave("save-B",456).ReadTile(9999,9999)==savedB,
                    "second save persists independently");
                scope.Unbind();
                Check(!scope.BoundToNamedSave && scope.World==null,"session can unbind");
            }
            using(var restarted=new WorldGridSaveScopeV45(root,4))
            {
                Check(restarted.BindAuthoritativeSave("save-A",123).ReadTile(9999,9999)==savedA,
                    "A survives process restart");
                Check(restarted.BindAuthoritativeSave("save-B",456).ReadTile(9999,9999)==savedB,
                    "B survives process restart");
                var rootDirs=Directory.GetDirectories(Path.Combine(root,"XianxiaVirtual10000_v45"));
                Check(rootDirs.Length==2,"only two hashed world folders created");
                foreach(var folder in rootDirs)
                    Check(Path.GetFileName(folder).StartsWith("w_") && 
                          !folder.Contains("save-A") && !folder.Contains("save-B"),
                          "private hashed ID, not raw world name");
            }
            Console.WriteLine("PASS_V45_WORLD_SAVE_SCOPE independent world seeds, 10000x10000 edges, restart, no cross-save bleed");
        }
        finally { if(Directory.Exists(root))Directory.Delete(root,true); }
    }
}
