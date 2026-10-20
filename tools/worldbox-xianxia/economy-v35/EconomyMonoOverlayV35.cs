using System;
using System.Linq;
using System.Reflection;
namespace XianxiaWorldBox.Economy {
 // Draw inside the ALREADY EXISTING in-game Mono "万界" menu; not a new
 // giant unrelated panel. Native WorldBox sprite-category binding is handled
 // separately by EconomyVanillaTabsV35 (requires mobile NML runtime).
 public static class EconomyMonoOverlayV35 {
  const string PanelKey="xys.worldbox.active_panel.v30";
  static readonly BindingFlags F=BindingFlags.Public|BindingFlags.NonPublic|BindingFlags.Static;
  static Type gui,rect,scr,pixel;
  static MethodInfo btn,box,label,pixelDraw;
  static PropertyInfo width,height,depth;
  static bool searched;
  static int viewMode,page;
  static object MakeRect(float x,float y,float w,float h) {
   if(rect==null)return null;
   return Activator.CreateInstance(rect,new object[]{x,y,w,h});
  }
  static void Setup() {
   if(searched)return;
   searched=true;
   var loaded=AppDomain.CurrentDomain.GetAssemblies();
   gui=loaded.Select(a=>a.GetType("UnityEngine.GUI",false)).FirstOrDefault(t=>t!=null);
   rect=loaded.Select(a=>a.GetType("UnityEngine.Rect",false)).FirstOrDefault(t=>t!=null);
   scr=loaded.Select(a=>a.GetType("UnityEngine.Screen",false)).FirstOrDefault(t=>t!=null);
   pixel=loaded.Select(a=>a.GetType("XianxiaWorldBox.PixelFrameV30",false)).FirstOrDefault(t=>t!=null);
   if(gui==null||rect==null||scr==null)return;
   btn=gui.GetMethod("Button",F,null,new[]{rect,typeof(string)},null);
   label=gui.GetMethod("Label",F,null,new[]{rect,typeof(string)},null);
   box=gui.GetMethod("Box",F,null,new[]{rect,typeof(string)},null);
   width=scr.GetProperty("width",F);height=scr.GetProperty("height",F);
   depth=gui.GetProperty("depth",F);
   pixelDraw=pixel?.GetMethod("Draw",F,null,new[]{rect},null);
  }
  static bool Button(float x,float y,float w,float h,string text){
   if(btn==null)return false;
   return object.Equals(btn.Invoke(null,new[]{MakeRect(x,y,w,h),(object)text}),true);
  }
  static void Label(float x,float y,float w,float h,string text){
   if(label!=null)label.Invoke(null,new[]{MakeRect(x,y,w,h),(object)text});
  }
  static void Box(float x,float y,float w,float h,string title) {
   object r=MakeRect(x,y,w,h);
   if(pixelDraw!=null)pixelDraw.Invoke(null,new[]{r});
   else if(box!=null)box.Invoke(null,new[]{r,(object)title});
  }
  public static void Draw() {
   try{
    Setup();
    if(btn==null||width==null||height==null)return;
    string active=AppDomain.CurrentDomain.GetData(PanelKey) as string??"";
    if(active!="menu"&&active!="economy")return;
    float w=Convert.ToSingle(width.GetValue(null,null));
    float h=Convert.ToSingle(height.GetValue(null,null));
    float u=Math.Min(1.65f,Math.Max(.92f,h/720f));
    // IMGUI depth is global. Draw this panel above existing "万界" content,
    // even though our verified injection runs at the start of Overlay.OnGUI.
    object oldDepth=null;
    try {if(depth!=null&&depth.CanWrite){oldDepth=depth.GetValue(null,null);depth.SetValue(null,-80,null);}}catch{}
    try {
    if(active=="menu") {
     float mw=Math.Min(w-32*u,600*u);
     float mx=(w-mw)/2f,my=Math.Max(90*u,(h-450*u)/2f);
     // In original Mono Bridge last row is occupied only by map status.
     // Use a narrow tab at the left; don't obscure the default 4 functions.
     if(Button(mx+18*u,my+351*u,180*u,48*u,"钱粮·财政")){
       AppDomain.CurrentDomain.SetData(PanelKey,"economy");
       viewMode=0;page=0;
     }
     return;
    }
    float pw=Math.Min(w-32*u,740*u),ph=Math.Min(h-32*u,560*u);
    float px=(w-pw)/2f,py=(h-ph)/2f;
    Box(px,py,pw,ph,"");
    Label(px+20*u,py+10*u,pw-40*u,44*u,"万界 · 王朝与钱粮（真实世界取证 v0.36）");
    Label(px+20*u,py+51*u,pw-40*u,80*u,
      "原版真实国家 "+EconomyUnityAdapterV35.ObservedKingdoms+
      " / 城市 "+EconomyUnityAdapterV35.ObservedCities+
      " / 城区 "+EconomyUnityAdapterV35.ZonesCounted+
      " / 面积已量测国家 "+EconomyUnityAdapterV35.TerritoryKnownKingdoms+
      "\n原版村/县/州/郡官制未施行；灵石与新货币仍独立于原游戏。");
    if(Button(px+22*u,py+133*u,160*u,42*u,viewMode==0?"● 国家":"国家")){
      viewMode=0;page=0;
    }
    if(Button(px+189*u,py+133*u,160*u,42*u,viewMode==1?"● 城池":"城池")){
      viewMode=1;page=0;
    }
    Label(px+21*u,py+181*u,pw-42*u,54*u,
      "数据来源：World.world → MapBox.kingdoms → 城市/TileZone，\n"+
      "国库铜钱仅显示真实新账本余额（不会按原版金矿自动造币）。");
    var records=EconomyUnityAdapterV35.Model.Districts.Values
      .Where(d=>d.Tier==(viewMode==0?DistrictTier.Kingdom:DistrictTier.County))
      .OrderBy(d=>d.Id).ToList();
    const int perPage=5;
    int pageCount=Math.Max(1,(records.Count+perPage-1)/perPage);
    page=Math.Min(page,pageCount-1);
    for(int i=page*perPage;i<Math.Min(records.Count,(page+1)*perPage);i++) {
      int row=i%perPage;
      var d=records[i];
      string info=viewMode==0
        ?d.Name+" · "+d.CityCount+"城 · 人口 "+d.People+
           " · 已归属 "+(d.TerritoryTiles<0?"待量测":d.TerritoryTiles+"格")+
           " · 铜钱 "+d.Stock.MoneyCopper
        :d.Name+" · "+(d.TerritoryTiles<0?"未量测":d.TerritoryTiles+"格")+
           (d.NativeResourcesObserved
             ?" · 原版金"+d.NativeGold+" 木"+d.NativeWood+" 石"+d.NativeStone+" 铁"+d.NativeCommonMetals
             :" · 原版库存待读取");
      Label(px+21*u,py+(245+43*row)*u,pw-42*u,39*u,info);
    }
    if(Button(px+20*u,py+ph-119*u,104*u,40*u,"上一页"))page=Math.Max(0,page-1);
    Label(px+143*u,py+ph-119*u,250*u,40*u,
      "记录 "+records.Count+" / "+(page+1)+"/"+pageCount);
    if(Button(px+pw-142*u,py+ph-119*u,120*u,40*u,"下一页"))
      page=Math.Min(pageCount-1,page+1);
    if(Button(px+20*u,py+ph-70*u,pw-40*u,56*u,"返回万界")){
      AppDomain.CurrentDomain.SetData(PanelKey,"menu");
    }
    } finally {
      try {if(oldDepth!=null&&depth!=null)depth.SetValue(null,oldDepth,null);}catch{}
    }
   }catch(Exception){} // no repeated popup/crash if Unity game API shifts
  }
 }
}
