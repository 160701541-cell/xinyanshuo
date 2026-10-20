// Nonofficial WorldBox 0.51.4 MOD: inserts native PowerButton icons in the
// original Nature / Drawing / Kingdom tabs when NML actually loads. No IMGUI
// top-level floating panels; never overwrites or replaces vanilla icons.
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using UnityEngine;
namespace XianxiaWorldBox {
 public static class EconomyVanillaTabsV35 {
  sealed class Entry {public string id,name,family,tab,icon;}
  static readonly Dictionary<string,List<Entry>> Contents=new Dictionary<string,List<Entry>>();
  static readonly string[] Families={"currency","spirit","ore","crop","herb",
    "forest","animal","material","product","governance"};
  static readonly string[] Tabs={"noosphere","nature","nature","nature","nature",
    "nature","nature","creation","creation","noosphere"};
  static readonly string[] Names={"铜银金与国库","灵石与灵晶","矿石矿脉","农田粮食","灵植与丹材",
    "木石土水","畜牧渔猎","建筑原材料","工商业产物","村县州郡国"};
  static readonly BindingFlags F=BindingFlags.Public|BindingFlags.NonPublic|BindingFlags.Static;
  static readonly Dictionary<string,Texture2D> Textures=new Dictionary<string,Texture2D>();
  static readonly HashSet<string> Installed=new HashSet<string>();
  static string root,opened="";
  static int page,readyCount;
  static float retryAt;
  public static string Status="等待原版分类栏";
  static string Folder {
   get {
    if(root!=null)return root;
    // ModDeployment places 'Mods/' next to Android/data/<package>/files.
    string basePath=Application.persistentDataPath;
    string parent=Path.GetDirectoryName(basePath);
    string candidate=Path.Combine(parent??basePath,"Mods/WorldBoxEconomy");
    if(File.Exists(Path.Combine(candidate,"resource_index.tsv")))return root=candidate;
    string other=Path.Combine(basePath,"Mods/WorldBoxEconomy");
    return root=File.Exists(Path.Combine(other,"resource_index.tsv"))?other:candidate;
   }
  }
  static bool LoadIndex() {
   if(Contents.Count>0)return true;
   string path=Path.Combine(Folder,"resource_index.tsv");
   if(!File.Exists(path))return false;
   var map=new Dictionary<string,List<Entry>>();
   try {
    var lines=File.ReadAllLines(path);
    if(lines.Length<40||lines.Length>3000)return false;
    foreach(string line in lines.Skip(1)) {
     var cols=line.Split('\t');
     if(cols.Length!=5||cols.Any(x=>x.IndexOf('\n')>=0))return false;
     if(!map.TryGetValue(cols[2],out var list))map.Add(cols[2],list=new List<Entry>());
     list.Add(new Entry{id=cols[0],name=cols[1],family=cols[2],tab=cols[3],icon=cols[4]});
    }
    foreach(var kv in map)Contents[kv.Key]=kv.Value;
    return true;
   }catch(Exception e) {Status="资源索引未就绪："+e.GetType().Name;return false;}
  }
  static Sprite Icon(string family) {
   if(!Contents.TryGetValue(family,out var list)||list.Count==0)return null;
   string image=Path.Combine(Folder,list[0].icon.Replace('/',Path.DirectorySeparatorChar));
   if(!File.Exists(image))return null;
   try {
    var texture=new Texture2D(32,32,TextureFormat.RGBA32,false);
    texture.filterMode=FilterMode.Point;
    var decoder=AppDomain.CurrentDomain.GetAssemblies()
      .Select(a=>a.GetType("UnityEngine.ImageConversion",false)).FirstOrDefault(t=>t!=null);
    var loader=decoder?.GetMethod("LoadImage",
      BindingFlags.Static|BindingFlags.Public,null,new[]{typeof(Texture2D),typeof(byte[]),typeof(bool)},null);
    if(loader==null||!(bool)loader.Invoke(null,new object[]{texture,File.ReadAllBytes(image),false}))
      return null;
    Textures[family]=texture;
    return Sprite.Create(texture,new Rect(0,0,32,32),new Vector2(.5f,.5f),100f);
   }catch(Exception e){Status="图标载入失败："+e.GetType().Name;return null;}
  }
  static void Open(string family) {
   opened=family;page=0;
   SharedPanelsV30.Show("economy");
  }
  static void Nature()=>Open("crop");
  static void Drawing()=>Open("material");
  static void Kingdoms()=>Open("currency");
  public static void Tick() {
   if(Time.unscaledTime<retryAt)return;
   retryAt=Time.unscaledTime+5f;
   if(Installed.Count==3)return;
   if(!LoadIndex()){Status="等待资源图标部署（v35）";root=null;return;}
   try {
    var nml=AppDomain.CurrentDomain.GetAssemblies()
      .Select(a=>a.GetType("NeoModLoader.General.PowerButtonCreator",false))
      .FirstOrDefault(t=>t!=null);
    if(nml==null) {Status="移动NML未加载：暂不能接入原版分类";return;}
    var getTab=nml.GetMethod("GetTab",F,null,new[]{typeof(string)},null);
    var creator=nml.GetMethods(F).FirstOrDefault(m=>m.Name=="CreateSimpleButton"&&
      m.GetParameters().Length==5);
    var add=nml.GetMethods(F).FirstOrDefault(m=>m.Name=="AddButtonToTab"&&
      m.GetParameters().Length==3);
    if(getTab==null||creator==null||add==null) {Status="NML原版按钮接口未匹配";return;}
    var delegateType=creator.GetParameters()[1].ParameterType;
    var parentType=creator.GetParameters()[3].ParameterType;
    var vector=creator.GetParameters()[4].ParameterType;
    string[] keys={"nature","creation","noosphere"};
    string[] families={"crop","material","currency"};
    string[] code={"Nature","Drawing","Kingdoms"};
    for(int i=0;i<keys.Length;i++){
     if(Installed.Contains(keys[i]))continue;
     object tab=getTab.Invoke(null,new object[]{keys[i]});
     if(tab==null)continue;
     Sprite sprite=Icon(families[i]);
     if(sprite==null){Status="本地像素图标缺失 "+families[i];continue;}
     MethodInfo method=typeof(EconomyVanillaTabsV35).GetMethod(code[i],F);
     var callback=Delegate.CreateDelegate(delegateType,method);
     object button=creator.Invoke(null,new object[]{"wbx_economy_"+keys[i],callback,
       sprite,null,Activator.CreateInstance(vector)});
     if(button==null)continue;
     add.Invoke(null,new object[]{button,tab,null});
     Installed.Add(keys[i]);
    }
    readyCount=Installed.Count;
    Status="原版分类图标 "+readyCount+"/3 （自然/制造/王国）；触摸查看资源目录";
   }catch(Exception e){Status="原版分类绑定失败："+e.GetType().Name;
     Debug.LogWarning("[WBX-ECONOMY-TABS] "+e);}
  }
  public static void Draw() {
   if(SharedPanelsV30.Active!="economy"||string.IsNullOrEmpty(opened))return;
   float scale=Mathf.Clamp(Screen.width/900f,.8f,1.4f);
   float w=Mathf.Min(Screen.width-28,740*scale),h=Mathf.Min(Screen.height-68,650*scale);
   Rect rect=new Rect((Screen.width-w)/2,(Screen.height-h)/2,w,h);
   PixelFrameV30.Draw(rect);
   GUIStyle btn=ModTextAccessibilityV13.ButtonStyle();
   GUIStyle label=ModTextAccessibilityV13.LabelStyle();
   if(GUI.Button(new Rect(rect.x+10,rect.y+8,110*scale,45*scale),"返回",btn)){
     SharedPanelsV30.Close();return;
   }
   var familyIndex=Array.IndexOf(Families,opened);
   string title=familyIndex>=0?Names[familyIndex]:"万界资源";
   GUI.Label(new Rect(rect.x+124*scale,rect.y+10,w-140*scale,43*scale),
     "万界·"+title+" | 当前仅资源索引，不代表NPC经济已上线",label);
   if(!Contents.TryGetValue(opened,out var goods))return;
   int perPage=20;
   int pages=(goods.Count+perPage-1)/perPage;
   for(int i=page*perPage;i<Math.Min(goods.Count,(page+1)*perPage);i++){
     int index=i%perPage,col=index%4,row=index/4;
     var item=goods[i];
     Rect cell=new Rect(rect.x+(12+col*178)*scale,rect.y+(74+row*88)*scale,173*scale,82*scale);
     GUI.Box(cell,"");
     if(!Textures.TryGetValue(item.id,out var tex)){
       string filename=Path.Combine(Folder,item.icon.Replace('/',Path.DirectorySeparatorChar));
       if(File.Exists(filename)) {
        try {
         tex=new Texture2D(32,32,TextureFormat.RGBA32,false);
         tex.filterMode=FilterMode.Point;
         var decoder=AppDomain.CurrentDomain.GetAssemblies()
           .Select(a=>a.GetType("UnityEngine.ImageConversion",false)).FirstOrDefault(t=>t!=null);
         var loader=decoder?.GetMethod("LoadImage",F,null,
           new[]{typeof(Texture2D),typeof(byte[]),typeof(bool)},null);
         if(loader!=null&&(bool)loader.Invoke(null,new object[]{tex,File.ReadAllBytes(filename),false}))
           Textures[item.id]=tex;
        }catch{}
       }
     }
     if(tex!=null)GUI.DrawTexture(new Rect(cell.x+8*scale,cell.y+9*scale,40*scale,40*scale),tex);
     GUI.Label(new Rect(cell.x+53*scale,cell.y+10*scale,118*scale,62*scale),item.name,label);
   }
   if(GUI.Button(new Rect(rect.x+15,rect.y+h-60*scale,140*scale,45*scale),"上一页",btn))
     page=Math.Max(0,page-1);
   GUI.Label(new Rect(rect.x+175*scale,rect.y+h-60*scale,240*scale,50*scale),
     "资源 "+goods.Count+" / 页 "+(page+1)+"/"+Math.Max(1,pages),label);
   if(GUI.Button(new Rect(rect.x+w-154*scale,rect.y+h-60*scale,140*scale,45*scale),"下一页",btn))
     page=Math.Min(Math.Max(0,pages-1),page+1);
  }
 }
}
