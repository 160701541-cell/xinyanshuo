// Original Mono GameObject OnGUI hook: only an opt-in 160-cell preview over
// WorldBox's original game UI. Read-only; never promises 1e8 Unity WorldTiles.
using System;
using System.Linq;
using System.Reflection;
using System.Collections.Generic;
namespace XianxiaWorldBox.HugeWorld {
 public static class WorldGridGuiV42 {
  const string Menu="xys.worldbox.active_panel.v30";
  const BindingFlags F=BindingFlags.Public|BindingFlags.NonPublic|BindingFlags.Static|BindingFlags.Instance;
  static Type gui,rect,screen,color;static MethodInfo button,box,label;
  static PropertyInfo width,height,depth,guiColor;static bool initialized;
  static readonly WorldGridViewportV42 View=new WorldGridViewportV42();
  static byte[] sample;static int lastX=-1,lastY=-1,lastZoom=-1;
  static string lastStatus="";
  static readonly float[][] palette={
    new[]{.16f,.41f,.65f,1f}, // water
    new[]{.50f,.64f,.29f,1f}, // grass
    new[]{.13f,.36f,.24f,1f}, // forest
    new[]{.45f,.45f,.44f,1f}, // rocky mountains
    new[]{.20f,.53f,.48f,1f}  // wetland
  };
  static void Prepare(){
   if(initialized)return;
   initialized=true;
   var assemblies=AppDomain.CurrentDomain.GetAssemblies();
   gui=assemblies.Select(a=>a.GetType("UnityEngine.GUI",false)).FirstOrDefault(t=>t!=null);
   rect=assemblies.Select(a=>a.GetType("UnityEngine.Rect",false)).FirstOrDefault(t=>t!=null);
   screen=assemblies.Select(a=>a.GetType("UnityEngine.Screen",false)).FirstOrDefault(t=>t!=null);
   color=assemblies.Select(a=>a.GetType("UnityEngine.Color",false)).FirstOrDefault(t=>t!=null);
   if(gui==null||rect==null||screen==null)return;
   button=gui.GetMethod("Button",F,null,new[]{rect,typeof(string)},null);
   box=gui.GetMethod("Box",F,null,new[]{rect,typeof(string)},null);
   label=gui.GetMethod("Label",F,null,new[]{rect,typeof(string)},null);
   width=screen.GetProperty("width",F);height=screen.GetProperty("height",F);
   depth=gui.GetProperty("depth",F);guiColor=gui.GetProperty("color",F);
  }
  static object Area(float x,float y,float w,float h){return Activator.CreateInstance(rect,new object[]{x,y,w,h});}
  static bool Button(float x,float y,float w,float h,string title){
   return button!=null&&object.Equals(button.Invoke(null,new object[]{Area(x,y,w,h),title}),true);
  }
  static void Box(float x,float y,float w,float h,string title=""){
   box?.Invoke(null,new object[]{Area(x,y,w,h),title});
  }
  static void Label(float x,float y,float w,float h,string title){
   label?.Invoke(null,new object[]{Area(x,y,w,h),title});
  }
  static string ActualGameSize(){
   try {
    var assembly=AppDomain.CurrentDomain.GetAssemblies()
      .FirstOrDefault(a=>a.GetName().Name=="Assembly-CSharp");
    var map=assembly?.GetType("MapBox");
    if(map==null)return "原版地图尺寸：读取失败";
    var w=map.GetField("width",F),h=map.GetField("height",F);
    if(w==null||h==null)return "原版地图尺寸：暂无读数";
    string size=Convert.ToString(w.GetValue(null))+"×"+Convert.ToString(h.GetValue(null));
    return "原版实际地图："+size+"格";
   }catch{return "原版地图尺寸：待兼容";}
  }
  static void Preview(){
   var world=WorldGridStreamRuntimeV41.World;
   if(world==null){WorldGridStreamRuntimeV41.Tick();world=WorldGridStreamRuntimeV41.World;}
   if(world==null){sample=null;lastStatus=WorldGridStreamRuntimeV41.Status;return;}
   if(sample!=null&&lastX==View.Left&&lastY==View.Top&&lastZoom==View.ZoomLevel)return;
   try{sample=View.Sample(world);lastX=View.Left;lastY=View.Top;lastZoom=View.ZoomLevel;
    lastStatus="抽样 "+sample.Length+"格；内存区块 "+world.ResidentChunkCount+"/12";
   }catch(Exception e){sample=null;lastStatus="分区读取失败 "+e.GetType().Name;}
  }
  static void SetTint(byte biome){
   if(guiColor==null||color==null||biome>=palette.Length)return;
   try {var p=palette[biome];guiColor.SetValue(null,
     Activator.CreateInstance(color,new object[]{p[0],p[1],p[2],p[3]}),null);}catch{}
  }
  public static void Draw(){
   try {
    Prepare();if(button==null||width==null||height==null)return;
    string active=AppDomain.CurrentDomain.GetData(Menu) as string??"";
    if(active!="menu"&&active!="huge_world_preview")return;
    float sw=Convert.ToSingle(width.GetValue(null,null)),sh=Convert.ToSingle(height.GetValue(null,null));
    if(sw<320||sh<260)return;
    float u=Math.Max(.65f,Math.Min(1.30f,sh/780f));
    object previousDepth=null,previousColor=null;
    try{
     if(depth!=null&&depth.CanWrite){previousDepth=depth.GetValue(null,null);depth.SetValue(null,-95,null);}
     if(guiColor!=null)previousColor=guiColor.GetValue(null,null);
     if(active=="menu"){
      float mw=Math.Min(sw-32*u,600*u),mx=(sw-mw)/2f;
      float my=Math.Max(90*u,(sh-450*u)/2f);
      if(Button(mx+222*u,my+351*u,224*u,48*u,"世界分区图 · 10000")){
       AppDomain.CurrentDomain.SetData(Menu,"huge_world_preview");
       sample=null;
      }
      return;
     }
     float pw=Math.Min(sw-20*u,850*u),ph=Math.Min(sh-20*u,700*u);
     float px=(sw-pw)/2f,py=(sh-ph)/2f;
     Box(px,py,pw,ph);
     Label(px+15*u,py+12*u,pw-30*u,38*u,"万界 · 虚拟分区地图 10000×10000 [实验层]");
     Label(px+15*u,py+47*u,pw-30*u,30*u,ActualGameSize());
     Label(px+15*u,py+75*u,pw-30*u,32*u,"提醒：此图不是原版WorldBox可行动的一亿格地图");
     Preview();
     float mapX=px+15*u,mapY=py+115*u;
     float mapW=pw-170*u,mapH=ph-216*u;
     if(mapW<=80||mapH<=80)return;
     float cw=mapW/WorldGridViewportV42.Columns,ch=mapH/WorldGridViewportV42.Rows;
     if(sample!=null){
      for(int y=0;y<WorldGridViewportV42.Rows;y++)for(int x=0;x<WorldGridViewportV42.Columns;x++){
       int idx=y*WorldGridViewportV42.Columns+x;
       SetTint(sample[idx]);
       Box(mapX+x*cw,mapY+y*ch,cw+1,ch+1);
      }
      if(previousColor!=null&&guiColor!=null)guiColor.SetValue(null,previousColor,null);
     }
     float ctrl=px+pw-144*u;
     if(Button(ctrl,py+130*u,118*u,48*u,"北 ↑")){View.Pan(0,-1);sample=null;}
     if(Button(ctrl,py+187*u,118*u,48*u,"南 ↓")){View.Pan(0,1);sample=null;}
     if(Button(ctrl,py+244*u,56*u,48*u,"←")){View.Pan(-1,0);sample=null;}
     if(Button(ctrl+60*u,py+244*u,58*u,48*u,"→")){View.Pan(1,0);sample=null;}
     if(Button(ctrl,py+304*u,56*u,48*u,"＋")){View.SetZoom(View.ZoomLevel+1);sample=null;}
     if(Button(ctrl+60*u,py+304*u,58*u,48*u,"－")){View.SetZoom(View.ZoomLevel-1);sample=null;}
     if(Button(ctrl,py+365*u,118*u,48*u,"回世界中心")){View.Focus(5000,5000);sample=null;}
     Label(px+15*u,py+ph-98*u,pw-30*u,43*u,View.Status+" | "+lastStatus);
     if(Button(px+15*u,py+ph-54*u,pw-30*u,42*u,"关闭地图，返回原版世界"))
       AppDomain.CurrentDomain.SetData(Menu,"menu");
    }finally {
     if(previousColor!=null&&guiColor!=null)try{guiColor.SetValue(null,previousColor,null);}catch{}
     if(previousDepth!=null&&depth!=null)try{depth.SetValue(null,previousDepth,null);}catch{}
    }
   }catch(Exception){} // no crash-on-start from optional experimental overlay
  }
 }
}
