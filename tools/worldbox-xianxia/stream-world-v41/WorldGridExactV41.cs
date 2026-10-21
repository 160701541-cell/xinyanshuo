// WorldBox·万界仙侠 — original sparse streaming world-data prototype.
// NOT a replacement for WorldBox MapBox/WorldTile. Does not allocate 100M Unity tiles.
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Text;

namespace XianxiaWorldBox.HugeWorld
{
    public sealed class WorldGridExactV41 : IDisposable
    {
        public const int Width = 10000;
        public const int Height = 10000;
        public const int ChunkEdge = 128;
        public const int ChunksX = (Width + ChunkEdge - 1) / ChunkEdge;
        public const int ChunksY = (Height + ChunkEdge - 1) / ChunkEdge;
        public const long LogicalTileCount = (long)Width * Height;
        const int MaxPatchesPerChunk = ChunkEdge * ChunkEdge;
        const int FormatVersion = 1;
        static readonly byte[] Signature = Encoding.ASCII.GetBytes("WBX41TIL");
        readonly Dictionary<long,Chunk> cache = new Dictionary<long,Chunk>();
        readonly LinkedList<long> lru = new LinkedList<long>();
        readonly object gate = new object();
        readonly string folder;
        readonly int maxResident;
        readonly uint seed;
        public int ResidentChunkCount { get { lock(gate) return cache.Count; } }
        public int MaximumResidentChunks { get { return maxResident; } }
        public long ReadCount { get; private set; }
        public long EvictedChunks { get; private set; }
        public long WrittenChunks { get; private set; }
        public string Folder { get { return folder; } }
        sealed class Chunk
        {
            public int X,Y;
            public LinkedListNode<long> Node;
            public readonly Dictionary<int,byte> Changes = new Dictionary<int,byte>();
            public bool Dirty;
        }
        public WorldGridExactV41(string safeFolder, uint worldSeed, int maxResidentChunks = 12)
        {
            if(string.IsNullOrWhiteSpace(safeFolder))throw new ArgumentException("Storage folder required");
            if(maxResidentChunks < 1 || maxResidentChunks > 64)
                throw new ArgumentOutOfRangeException(nameof(maxResidentChunks));
            seed = worldSeed;
            maxResident = maxResidentChunks;
            folder = Path.GetFullPath(safeFolder);
            Directory.CreateDirectory(folder);
        }
        static void Check(int x,int y)
        {
            if(x < 0 || y < 0 || x >= Width || y >= Height)
                throw new ArgumentOutOfRangeException("World coordinates must be 0..9999");
        }
        static long Key(int chunkX, int chunkY)
        {
            return (long)chunkY * ChunksX + chunkX;
        }
        public static int EdgeWidth(int cx)
        {
            if(cx < 0 || cx >= ChunksX)throw new ArgumentOutOfRangeException(nameof(cx));
            return Math.Min(ChunkEdge,Width-cx*ChunkEdge);
        }
        public static int EdgeHeight(int cy)
        {
            if(cy < 0 || cy >= ChunksY)throw new ArgumentOutOfRangeException(nameof(cy));
            return Math.Min(ChunkEdge,Height-cy*ChunkEdge);
        }
        string ChunkPath(int cx,int cy)
        {
            return Path.Combine(folder,"c_"+cx.ToString("D3")+"_"+cy.ToString("D3")+".wbx");
        }
        // Coordinate-only hash, independent of iteration order and camera location.
        static ulong Mix(ulong x)
        {
            x ^= x >> 30;x *= 0xbf58476d1ce4e5b9UL;
            x ^= x >> 27;x *= 0x94d049bb133111ebUL;
            return x ^ (x >> 31);
        }
        public byte NaturalTile(int x,int y)
        {
            Check(x,y);
            unchecked
            {
                // 64x64-biome patches: far-away chunks can be summarized without full tiles.
                ulong regional=Mix((ulong)seed ^ ((ulong)(x>>6)*0x9e3779b97f4a7c15UL) ^
                    ((ulong)(y>>6)*0x632be59bd9b4e019UL));
                ulong micro=Mix(regional ^ ((ulong)x*0xbf58476d1ce4e5b9UL) ^ (ulong)y);
                int region=(int)(regional%100UL);
                if(region<17)return 0;  // water
                if(region<28)return 3;  // mountain/rock
                if(region<49)return 2;  // forest
                return (byte)((micro%13UL)==0 ? 4 : 1); // wetland/grass
            }
        }
        Chunk Get(int cx,int cy)
        {
            long key=Key(cx,cy);
            Chunk existing;
            if(cache.TryGetValue(key,out existing))
            {
                lru.Remove(existing.Node);
                lru.AddFirst(existing.Node);
                return existing;
            }
            if(cache.Count>=maxResident)
            {
                long last=lru.Last.Value;
                Chunk victim=cache[last];
                Flush(victim);
                cache.Remove(last);
                lru.RemoveLast();
                EvictedChunks++;
            }
            var created=new Chunk{X=cx,Y=cy};
            created.Node=lru.AddFirst(key);
            Load(created);
            cache.Add(key,created);
            return created;
        }
        public byte ReadTile(int x,int y)
        {
            Check(x,y);
            lock(gate)
            {
                var chunk=Get(x/ChunkEdge,y/ChunkEdge);
                byte saved;
                ReadCount++;
                int offset=(y%ChunkEdge)*ChunkEdge+x%ChunkEdge;
                return chunk.Changes.TryGetValue(offset,out saved)?saved:NaturalTile(x,y);
            }
        }
        public void WriteTile(int x,int y,byte kind)
        {
            Check(x,y);
            if(kind>4)throw new ArgumentOutOfRangeException(nameof(kind));
            lock(gate)
            {
                var chunk=Get(x/ChunkEdge,y/ChunkEdge);
                int offset=(y%ChunkEdge)*ChunkEdge+x%ChunkEdge;
                byte natural=NaturalTile(x,y),current;
                bool exists=chunk.Changes.TryGetValue(offset,out current);
                if((exists?current:natural)==kind)return;
                if(kind==natural)chunk.Changes.Remove(offset);
                else chunk.Changes[offset]=kind;
                chunk.Dirty=true;
            }
        }
        // Bounded diagnostic/LOD: only 256 samples requested, NEVER 100M allocations.
        public byte[] SampleOverview(int left,int top,int spanX,int spanY,int outputEdge=16)
        {
            if(outputEdge<1||outputEdge>64||spanX<1||spanY<1||
                left<0||top<0||left+spanX>Width||top+spanY>Height)
                throw new ArgumentOutOfRangeException("sample extent");
            var result=new byte[outputEdge*outputEdge];
            for(int y=0;y<outputEdge;y++)for(int x=0;x<outputEdge;x++)
            {
                int tx=left+(int)((long)spanX*(2*x+1)/(2*outputEdge));
                int ty=top+(int)((long)spanY*(2*y+1)/(2*outputEdge));
                result[y*outputEdge+x]=ReadTile(Math.Min(Width-1,tx),Math.Min(Height-1,ty));
            }
            return result;
        }
        static byte[] Serialize(Chunk c,uint worldSeed)
        {
            using(var body=new MemoryStream())
            {
                using(var bw=new BinaryWriter(body,Encoding.UTF8,true))
                {
                    bw.Write(Signature);bw.Write(FormatVersion);bw.Write(worldSeed);
                    bw.Write(c.X);bw.Write(c.Y);
                    bw.Write(c.Changes.Count);
                    foreach(var kv in c.Changes.OrderBy(item=>item.Key))
                    {
                        bw.Write((ushort)kv.Key);bw.Write(kv.Value);
                    }
                }
                byte[] raw=body.ToArray();
                byte[] checksum;
                using(var sha=SHA256.Create())checksum=sha.ComputeHash(raw);
                using(var final=new MemoryStream())
                {
                    final.Write(raw,0,raw.Length);
                    final.Write(checksum,0,checksum.Length);
                    return final.ToArray();
                }
            }
        }
        void Load(Chunk c)
        {
            string path=ChunkPath(c.X,c.Y);
            if(!File.Exists(path))return;
            byte[] data=File.ReadAllBytes(path);
            if(data.Length<8+5*4+32 || data.Length>8+5*4+3*MaxPatchesPerChunk+32)
                throw new InvalidDataException("Invalid world chunk length");
            var rawLen=data.Length-32;
            byte[] calculated;
            using(var sha=SHA256.Create())calculated=sha.ComputeHash(data,0,rawLen);
            for(int i=0;i<32;i++)if(data[rawLen+i]!=calculated[i])
                throw new InvalidDataException("World chunk checksum differs; preserve old save");
            using(var br=new BinaryReader(new MemoryStream(data,0,rawLen),Encoding.UTF8))
            {
                byte[] magic=br.ReadBytes(8);
                if(!magic.SequenceEqual(Signature)||br.ReadInt32()!=FormatVersion||
                    br.ReadUInt32()!=seed||br.ReadInt32()!=c.X||br.ReadInt32()!=c.Y)
                    throw new InvalidDataException("World seed/chunk version mismatch");
                int count=br.ReadInt32();
                if(count<0||count>MaxPatchesPerChunk||rawLen!=8+5*4+3*count)
                    throw new InvalidDataException("World chunk patch count invalid");
                for(int i=0;i<count;i++)
                {
                    int cell=br.ReadUInt16();byte value=br.ReadByte();
                    int localX=cell%ChunkEdge,localY=cell/ChunkEdge;
                    if(localX>=EdgeWidth(c.X)||localY>=EdgeHeight(c.Y)||value>4||
                        c.Changes.ContainsKey(cell))
                        throw new InvalidDataException("World chunk saved tile out of bounds");
                    c.Changes.Add(cell,value);
                }
            }
        }
        void Flush(Chunk c)
        {
            if(!c.Dirty)return;
            string path=ChunkPath(c.X,c.Y);
            string temporary=path+".tmp";
            byte[] data=Serialize(c,seed);
            try
            {
                using(var f=new FileStream(temporary,FileMode.Create,FileAccess.Write,FileShare.None))
                {
                    f.Write(data,0,data.Length);f.Flush(true);
                }
                if(File.Exists(path))
                {
                    // Atomic same-filesystem replacement: original survives interrupted writes.
                    File.Replace(temporary,path,null);
                }
                else File.Move(temporary,path);
                c.Dirty=false;WrittenChunks++;
            }
            finally {if(File.Exists(temporary))File.Delete(temporary);}
        }
        public void SaveDirty(int maxChunks=2)
        {
            if(maxChunks<1||maxChunks>64)throw new ArgumentOutOfRangeException(nameof(maxChunks));
            lock(gate)
            {
                int saved=0;
                foreach(var chunk in cache.Values)
                {
                    if(!chunk.Dirty)continue;
                    Flush(chunk);
                    if(++saved>=maxChunks)break;
                }
            }
        }
        public void Dispose()
        {
            lock(gate)
            {
                foreach(var chunk in cache.Values)Flush(chunk);
                cache.Clear();lru.Clear();
            }
        }
    }
}
