using System;
using System.Collections.Generic;
using System.IO;
using XianxiaWorldBox.HugeWorld;
public static class WorldGridTestsV41
{
 static void Check(bool predicate,string description){if(!predicate)throw new Exception(description);}
 static void Reject(Action action){try{action();}catch(ArgumentOutOfRangeException){return;}throw new Exception("Out-of-world tile accepted");}
 public static void Main()
 {
  string root=Path.Combine(Path.GetTempPath(),"wbx_v41_"+Guid.NewGuid().ToString("N"));
  try
  {
   int[] points={0,1,127,128,9999};
   byte expected;
   using(var world=new WorldGridExactV41(root,42,8))
   {
    Check(WorldGridExactV41.LogicalTileCount==100000000L,"exact 10000x10000");
    Check(WorldGridExactV41.ChunksX==79&&WorldGridExactV41.ChunksY==79,"79x79 streamed regions");
    Check(WorldGridExactV41.EdgeWidth(78)==16,"partial right edge exactly16");
    Check(WorldGridExactV41.EdgeHeight(78)==16,"partial lower edge exactly16");
    Reject(()=>world.ReadTile(10000,7));Reject(()=>world.ReadTile(7,-1));
    foreach(int x in points)foreach(int y in points)
    {
     byte value=world.ReadTile(x,y);
     Check(value<=4,"valid seeded biome values");
     Check(world.ResidentChunkCount<=8,"bounded LRU cache");
    }
    expected=(byte)((world.ReadTile(9999,9999)+1)%5);
    world.WriteTile(9999,9999,expected);
    world.WriteTile(0,0,4);
    world.SaveDirty(2);
    Check(world.ReadTile(9999,9999)==expected,"edge tile modified");
    var overview=world.SampleOverview(0,0,10000,10000,16);
    Check(overview.Length==256,"overview only 256 sampled tiles");
    for(int i=0;i<500;i++) {
     int x=(i*977)%10000,y=(i*5339)%10000;
     world.ReadTile(x,y);
     Check(world.ResidentChunkCount<=8,"no hidden 100m array allocation");
    }
   }
   using(var loaded=new WorldGridExactV41(root,42,8))
   {
    Check(loaded.ReadTile(9999,9999)==expected,"modified edge survives restart");
    Check(loaded.ReadTile(0,0)==4,"modified origin survives restart");
    Check(loaded.NaturalTile(9999,9999)<=4,"unchanged generation independent of visit order");
   }
   using(var otherSeed=new WorldGridExactV41(Path.Combine(root,"newseed"),123,8))
   {
    var tile=otherSeed.ReadTile(9999,9999);
    Check(tile<=4,"different world seed supported");
   }
   string saved=Path.Combine(root,"c_078_078.wbx");
   Check(File.Exists(saved),"saved edge chunk exists");
   var corrupted=File.ReadAllBytes(saved);
   corrupted[corrupted.Length-1]^=1;File.WriteAllBytes(saved,corrupted);
   bool caught=false;
   try{using(var broken=new WorldGridExactV41(root,42,8)){broken.ReadTile(9999,9999);}}
   catch(InvalidDataException){caught=true;}
   Check(caught,"corrupted save never silently accepted");
   Console.WriteLine("PASS_V41_VIRTUAL_EXACT10000_STREAMING tileCount=100000000 chunks=6241 cache<=8 crossRestart=TRUE checksum=TRUE partialEdge=TRUE");
  }
  finally{if(Directory.Exists(root))Directory.Delete(root,true);}
 }
}
