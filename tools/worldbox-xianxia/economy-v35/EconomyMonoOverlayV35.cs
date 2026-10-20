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
  static PropertyInfo width,height;
  static bool searched;
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
    if(active=="menu") {
     float mw=Math.Min(w-32*u,600*u);
     float mx=(w-mw)/2f,my=Math.Max(90*u,(h-450*u)/2f);
     // In original Mono Bridge last row is occupied only by map status.
     // Use a narrow tab at the left; don't obscure the default 4 functions.
     if(Button(mx+18*u,my+351*u,180*u,48*u,"钱粮·财政")){
       AppDomain.CurrentDomain.SetData(PanelKey,"economy");
     }
     return;
    }
    float pw=Math.Min(w-32*u,740*u),ph=Math.Min(h-32*u,560*u);
    float px=(w-pw)/2f,py=(h-ph)/2f;
    Box(px,py,pw,ph,"");
    Label(px+20*u,py+16*u,pw-40*u,48*u,"万界 · 钱粮财政 / 经济账簿 v0.35");
    Label(px+20*u,py+67*u,pw-40*u,84*u,
      "真实王国读取："+EconomyUnityAdapterV35.Model.Districts.Count+
      "；国界面积：待WorldBox领土采样\n铜钱=账本基准；白银1=1000铜，黄金1=100白银；灵石独立资源");
    Label(px+20*u,py+166*u,pw-40*u,70*u,
      EconomyUnityAdapterV35.Status+"\n国库和仓库存量绝不凭空增加；自然矿脉/农田资源与市场交易需实际世界绑定");
    int top=0;
    foreach(var kv in EconomyUnityAdapterV35.Model.Districts.OrderBy(x=>x.Key)) {
      if(top>=5)break;
      var d=kv.Value;
      Label(px+20*u,py+(245+43*top)*u,pw-40*u,42*u,
        d.Name+" / 人口 "+d.People+" / 国库铜钱 "+d.Stock.MoneyCopper+
        " / 土地面积 "+(d.TerritoryTiles<0?"待读取":d.TerritoryTiles+"格"));
      top++;
    }
    if(Button(px+20*u,py+ph-70*u,pw-40*u,56*u,"返回万界")){
      AppDomain.CurrentDomain.SetData(PanelKey,"menu");
    }
   }catch(Exception){} // no repeated popup/crash if Unity game API shifts
  }
 }
}
