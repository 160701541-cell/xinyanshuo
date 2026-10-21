// WorldBox·万界仙侠 independently owned sidecar data only.
// Every real WorldBox save MUST use a unique authoritative save ID.
// No original game .wld/.save files are read, rewritten or deleted.
using System;
using System.IO;
using System.Text;
using System.Security.Cryptography;
namespace XianxiaWorldBox.HugeWorld
{
    public sealed class WorldGridSaveScopeV45 : IDisposable
    {
        readonly string root;
        readonly int limit;
        WorldGridExactV41 current;
        string activeKey;
        public WorldGridExactV41 World { get { return current; } }
        public string WorldHash { get { return activeKey; } }
        public bool BoundToNamedSave { get { return activeKey!=null; } }

        public WorldGridSaveScopeV45(string privateAppData, int cacheLimit=12)
        {
            if(string.IsNullOrWhiteSpace(privateAppData))
                throw new ArgumentException("App-owned storage required");
            if(cacheLimit<1||cacheLimit>64)
                throw new ArgumentOutOfRangeException(nameof(cacheLimit));
            root=Path.Combine(Path.GetFullPath(privateAppData),"XianxiaVirtual10000_v45");
            limit=cacheLimit;
        }
        // A human-facing WorldBox world NAME, kingdom name or screen title is
        // NOT a reliable save identifier. Caller must pass the stable original
        // save-slot GUID/ID discovered from the real game API.
        public static string SafeSaveKey(string authoritativeId)
        {
            if(string.IsNullOrWhiteSpace(authoritativeId)||authoritativeId.Length>192)
                throw new ArgumentException("Stable WorldBox save ID required");
            foreach(char ch in authoritativeId)
                if(char.IsControl(ch))
                    throw new ArgumentException("Control character in world ID");
            byte[] id=Encoding.UTF8.GetBytes("WorldBoxSaveV45:"+authoritativeId);
            byte[] hash;
            using(var sha=SHA256.Create())hash=sha.ComputeHash(id);
            var hex=new StringBuilder(32);
            for(int i=0;i<16;i++)hex.Append(hash[i].ToString("x2"));
            return "w_"+hex;
        }
        public WorldGridExactV41 BindAuthoritativeSave(string saveId,uint gameWorldSeed)
        {
            string key=SafeSaveKey(saveId);
            if(current!=null&&key==activeKey)return current;
            // Flush old WORLD before switching; if disk fails old remains active.
            if(current!=null)current.Dispose();
            current=null;
            activeKey=null;
            string folder=Path.Combine(root,key);
            current=new WorldGridExactV41(folder,gameWorldSeed,limit);
            activeKey=key;
            return current;
        }
        public void Unbind()
        {
            if(current!=null)current.Dispose();
            current=null;
            activeKey=null;
        }
        public void Dispose(){Unbind();}
    }
}
