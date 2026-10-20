using System;
using System.Reflection;
using System.Collections.Generic;
using XianxiaWorldBox;

public class MapSizeAsset{
  public string id;
  public int size;
  public bool show_warning;
  public string path_icon;
}
public class MapSizeLibrary{
  public MapSizeAsset titanic=new MapSizeAsset{id="titanic",size=8,path_icon="base"};
  public static string[] _mapSizes={"titanic"};
  readonly Dictionary<string,MapSizeAsset> all=new Dictionary<string,MapSizeAsset>();
  public MapSizeLibrary(){all["titanic"]=titanic;}
  public static string[] getSizes(){return _mapSizes;}
  public MapSizeAsset get(string key){return all.TryGetValue(key,out var o)?o:null;}
  public void add(MapSizeAsset item){if(all.ContainsKey(item.id))throw new Exception("duplicate registered");all[item.id]=item;}
}
public static class AssetManager{
  public static MapSizeLibrary map_sizes=new MapSizeLibrary();
}
public static class Program{
  static void Assert(bool test,string cause){if(!test)throw new Exception(cause);}
  public static void Main(){
    var asm=Assembly.GetExecutingAssembly();
    var result=MapPresetBridgeV32.TryRegister(asm);
    Assert(MapPresetBridgeV32.Ready,result);
    Assert(result.Contains("WORLD_SIZE_PRESET_READY"),result);
    Assert(AssetManager.map_sizes.get("xianxia_extreme_32")?.size==32,"actual game library entry 32 chunks");
    Assert(Array.Exists(MapSizeLibrary.getSizes(),x=>x=="xianxia_extreme_32"),"visible new world sizes actual cache");
    Assert(MapSizeLibrary.getSizes().Length==2,"must preserve Titanic");
    string again=MapPresetBridgeV32.TryRegister(asm);
    Assert(again.Contains("READY")&&MapSizeLibrary.getSizes().Length==2,"repeat has no duplicate");
    Assert(MapSizeLibrary.getSizes()[0]=="titanic","vanilla map size still exists");
    Assert(MapPresetBridgeV32.Tiles==2048,"2048x2048 grid candidate");
    Console.WriteLine("PASS_2048_MAP_REGISTER_VISIBLE_LIST without generating a real world; device pending");
  }
}
