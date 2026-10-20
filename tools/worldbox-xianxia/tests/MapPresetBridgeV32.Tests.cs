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
  // Actual legacy WorldBox 0.51.4 exposes get("titanic") and 'list', NOT
  // a fake MapSizeLibrary.titanic field used by the earlier faulty test.
  public static string[] _mapSizes={"tiny","small","standard","large","huge",
    "gigantic","titanic","max"};
  readonly Dictionary<string,MapSizeAsset> all=new Dictionary<string,MapSizeAsset>();
  readonly List<MapSizeAsset> list=new List<MapSizeAsset>();
  public MapSizeLibrary(){
    foreach(var name in _mapSizes) {
      var entry=new MapSizeAsset{id=name,size=8,path_icon="base"};
      all.Add(name,entry);list.Add(entry);
    }
  }
  public static string[] getSizes(){return _mapSizes;}
  public MapSizeAsset get(string key){return all.TryGetValue(key,out var o)?o:null;}
  public void add(MapSizeAsset item){
    if(all.ContainsKey(item.id))throw new Exception("duplicate registered");
    all[item.id]=item;list.Add(item);
  }
  public void convertToOldFormat(){
    _mapSizes=list.ConvertAll(x=>x.id).ToArray();
  }
}
public static class AssetManager{
  public static MapSizeLibrary map_sizes=new MapSizeLibrary();
}
public static class Program{
  static void Assert(bool test,string cause){if(!test)throw new Exception(cause);}
  public static void Main(){
    var asm=Assembly.GetExecutingAssembly();
    Assert(MapSizeLibrary.getSizes().Length==8,"screenshot bug reproduces 8 original presets");
    Assert(typeof(MapSizeLibrary).GetField("titanic")==null,
      "never claim the original 0.51.4 has a fake titanic instance field");
    var result=MapPresetBridgeV32.TryRegister(asm);
    Assert(MapPresetBridgeV32.Ready,result);
    Assert(result.Contains("WORLD_SIZE_PRESET_READY"),result);
    Assert(AssetManager.map_sizes.get("xianxia_extreme_32")?.size==32,"actual game library entry 32 chunks");
    Assert(Array.Exists(MapSizeLibrary.getSizes(),x=>x=="xianxia_extreme_32"),"visible new world sizes actual cache");
    Assert(AssetManager.map_sizes.get("xianxia_extreme_50")?.size==50,"new 50x50 chunk entry");
    Assert(Array.Exists(MapSizeLibrary.getSizes(),x=>x=="xianxia_extreme_50"),
        "new 50x50 preset visible in native world list");
    Assert(AssetManager.map_sizes.get("xianxia_extreme_100")?.size==100,
      "new 100x100 chunk preset registered in actual size list");
    Assert(Array.Exists(MapSizeLibrary.getSizes(),x=>x=="xianxia_extreme_100"),
      "new eleventh 6400-square preset visible");
    Assert(MapSizeLibrary.getSizes().Length==11,"8 vanilla + 32x32 + 50x50 + 100x100");
    string again=MapPresetBridgeV32.TryRegister(asm);
    Assert(again.Contains("READY")&&MapSizeLibrary.getSizes().Length==11,"repeat has no duplicate");
    Assert(MapSizeLibrary.getSizes()[6]=="titanic","vanilla map size still exists");
    Assert(MapPresetBridgeV32.Tiles==2048,"keep previously confirmed preset");
    Assert(MapPresetBridgeV32.FiftyChunks==50,"50 chunks");
    Assert(MapPresetBridgeV32.FiftyTiles==3200,"50 chunks x 64 = 3200 tiles");
    Assert(MapPresetBridgeV32.HundredChunks==100,"100x100 chunks");
    Assert(MapPresetBridgeV32.HundredTiles==6400,"100 chunks x 64 = 6400 tiles");
    Console.WriteLine("PASS_REALISTIC_0514_MAP_UI_REBUILD 8 -> 11; 100x100 chunks; original list preserved; device pending");
  }
}
