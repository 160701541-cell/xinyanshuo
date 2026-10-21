// 10000x10000 bounded map browsing coordinates. The visible overview is a
// virtual data layer, NOT MapBox world tiles or the playable WorldBox surface.
using System;
namespace XianxiaWorldBox.HugeWorld {
 public sealed class WorldGridViewportV42 {
  public const int WorldEdge=10000;
  public const int Columns=16;
  public const int Rows=10;
  public int CenterX {get;private set;}=5000;
  public int CenterY {get;private set;}=5000;
  public int ZoomLevel {get;private set;}=0;
  public int Span {get {return new[]{10000,5000,2500,1000,500,160}[ZoomLevel];}}
  public int Left {get {return Math.Max(0,Math.Min(WorldEdge-Span,CenterX-Span/2));}}
  public int Top {get {return Math.Max(0,Math.Min(WorldEdge-Span,CenterY-Span/2));}}
  public string Status {get {return "10000×10000 数据地图｜中心 "+CenterX+","+CenterY+"｜缩放 "+ZoomLevel;}}
  public void SetZoom(int level) {ZoomLevel=Math.Max(0,Math.Min(5,level));Clamp();}
  public void Focus(int x,int y) {CenterX=x;CenterY=y;Clamp();}
  public void Pan(int dirX,int dirY) {
    int step=Math.Max(16,Span/3);
    Focus(CenterX+dirX*step,CenterY+dirY*step);
  }
  void Clamp() {
    CenterX=Math.Max(0,Math.Min(WorldEdge-1,CenterX));
    CenterY=Math.Max(0,Math.Min(WorldEdge-1,CenterY));
  }
  public int TileX(int column) {
    if(column<0||column>=Columns)throw new ArgumentOutOfRangeException(nameof(column));
    return Math.Min(WorldEdge-1,Left+(int)((long)Span*(2*column+1)/(2*Columns)));
  }
  public int TileY(int row) {
    if(row<0||row>=Rows)throw new ArgumentOutOfRangeException(nameof(row));
    return Math.Min(WorldEdge-1,Top+(int)((long)Span*(2*row+1)/(2*Rows)));
  }
  // Read at most 160 cells on interaction; no full-map enumeration or preallocation.
  public byte[] Sample(WorldGridExactV41 world) {
    if(world==null)throw new ArgumentNullException(nameof(world));
    byte[] sample=new byte[Columns*Rows];
    for(int row=0;row<Rows;row++)
      for(int col=0;col<Columns;col++)sample[row*Columns+col]=world.ReadTile(TileX(col),TileY(row));
    return sample;
  }
 }
}
