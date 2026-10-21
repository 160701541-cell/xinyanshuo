using System;
using System.IO;
using XianxiaWorldBox.HugeWorld;
public static class WorldGridViewportTestsV42 {
 static void Check(bool condition,string message) {if(!condition)throw new Exception(message);}
 public static void Main() {
  var v=new WorldGridViewportV42();
  Check(v.Span==10000&&v.Left==0&&v.Top==0,"entire 10k overview visible initially");
  v.Focus(-999,999999);
  Check(v.CenterX==0&&v.CenterY==9999,"panning clamped into exact grid");
  v.SetZoom(999);
  Check(v.ZoomLevel==5&&v.Span==160,"max zoom bounded");
  v.Focus(9999,9999);
  Check(v.Left==9840&&v.Top==9840,"last edge tile accessible without off-by-one");
  Check(v.TileX(WorldGridViewportV42.Columns-1)<10000 &&
        v.TileY(WorldGridViewportV42.Rows-1)<10000,"last sampled tile within range");
  v.Pan(1,1);
  Check(v.CenterX==9999&&v.CenterY==9999,"edge panning cannot go out of bounds");
  var root=Path.Combine(Path.GetTempPath(),"wbx42_view_"+Guid.NewGuid().ToString("N"));
  try {
   using(var world=new WorldGridExactV41(root,3412,5)) {
    var sampled=v.Sample(world);
    Check(sampled.Length==160,"sampling exactly 160 cells, never allocates 100 million");
    Check(world.ResidentChunkCount<=5,"view respects bounded in-memory chunks");
    foreach(var type in sampled)Check(type<=4,"terrain category in range");
    Check(world.ReadCount==160,"one sparse tile read per viewport sample");
   }
  }finally {if(Directory.Exists(root))Directory.Delete(root,true);}
  Console.WriteLine("PASS_V42_INTERACTIVE_10000_VIEWPORT_160_TILES_EDGE_ZOOM_BUDGET");
 }
}
