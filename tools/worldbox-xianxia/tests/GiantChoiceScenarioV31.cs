using System;
using System.Collections.Generic;
using XianxiaWorldBox;
public class MapSizeAsset {
    public string id,path_icon;
    public int size;
    public bool show_warning;
    public string getLocaleID(){return "actual_runtime_size_key_"+id;}
}
public class MapSizeLibrary {
    static string[] _mapSizes={"titanic"};
    readonly Dictionary<string,MapSizeAsset> entries=new Dictionary<string,MapSizeAsset>();
    public MapSizeAsset titanic=new MapSizeAsset{id="titanic",size=8,path_icon="vanilla-icon"};
    public MapSizeLibrary(){entries.Add("titanic",titanic);}
    public void add(MapSizeAsset asset){entries.Add(asset.id,asset);}
    public MapSizeAsset get(string id){MapSizeAsset value;return entries.TryGetValue(id,out value)?value:null;}
    public static string[] getSizes(){return _mapSizes;}
    public int Count {get{return entries.Count;}}
}
public static class AssetManager {public static MapSizeLibrary map_sizes=new MapSizeLibrary();}
namespace NeoModLoader.General {
    public static class LM {
        public static readonly Dictionary<string,string> Labels=new Dictionary<string,string>();
        public static void AddToCurrentLocale(string key,string value){Labels[key]=value;}
    }
}
static class GiantChoiceScenarioV31 {
    static void Check(bool yes,string why){if(!yes)throw new Exception(why);}
    static int Main(){
        MapBox.width=448;MapBox.height=448;
        var before=MapSizeLibrary.getSizes();
        Check(before.Length==1,"baseline cached choice");
        string report=GiantMapOptionsV11.EnsureExtremeChoice();
        Check(GiantMapOptionsV11.ExtremeRegistered,"asset registered");
        Check(GiantMapOptionsV11.ExtremeChoiceReady,"UI choice list verified separately");
        Check(Array.IndexOf(MapSizeLibrary.getSizes(),"xianxia_extreme_32")>=0,"cached UI list refreshed");
        Check(AssetManager.map_sizes.get("xianxia_extreme_32").size==32,"32 chunk candidate");
        Check(MapBox.width==448&&MapBox.height==448,"no existing world resized or generated");
        GiantMapOptionsV11.EnsureExtremeChoice();
        Check(AssetManager.map_sizes.Count==2&&MapSizeLibrary.getSizes().Length==2,"idempotent no duplicate");
        Check(GiantMapOptionsV11.ExtremeLabelReady,"Chinese size label registered using runtime locale ID");
        Check(NeoModLoader.General.LM.Labels["actual_runtime_size_key_xianxia_extreme_32"].Contains("2048"),"not guessing locale keys");
        Check(GiantMapOptionsV11.DiagnoseActualWorld().Contains("WORLD_SIZE_DIFFERENT"),"registration cannot fake world generation");
        Console.WriteLine("PASS_GIANT_CHOICE_V31: registry + UI cache + Chinese locale + idempotence; no world mutation");
        return 0;
    }
}
