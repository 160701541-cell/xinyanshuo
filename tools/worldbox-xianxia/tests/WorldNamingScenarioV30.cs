using System;
using System.Collections.Generic;
using XianxiaWorldBox;
class SavedData {
    public long id;
    readonly Dictionary<string,string> values=new Dictionary<string,string>();
    public void set(string key,string value){values[key]=value;}
    public void get(string key,out string value,string fallback){if(!values.TryGetValue(key,out value))value=fallback;}
}
class NamedEntity {
    public SavedData data=new SavedData{id=17};
    string name;
    public NamedEntity(string name){this.name=name;}
    public string getName(){return name;}
    public void setName(string value){name=value;}
}
class UnpersistableEntity {
    public object data=new object();
    string name="Kodana";
    public string getName(){return name;}
    public void setName(string value){name=value;}
}
static class WorldNamingScenarioV30 {
    static void Check(bool value,string why){if(!value)throw new Exception(why);}
    static int Main(){
        var actor=new NamedEntity("Kodana");
        Check(ChineseWorldNamesV30.Rename(actor,"人物"),"existing actor renamed via real setter");
        Check(!ChineseWorldNamesV30.NeedsChinese(actor.getName()),"Chinese actor name");
        Check(!ChineseWorldNamesV30.Rename(actor,"人物"),"idempotent");
        Check(ChineseWorldNamesV30.Restore(actor)&&actor.getName()=="Kodana","original name persisted and restored");
        var custom=new NamedEntity("心魇说");
        Check(!ChineseWorldNamesV30.Rename(custom,"人物")&&custom.getName()=="心魇说","Chinese custom name unchanged");
        var unsupported=new UnpersistableEntity();
        Check(!ChineseWorldNamesV30.Rename(unsupported,"人物")&&unsupported.getName()=="Kodana","missing persistence cannot mutate name");
        Check(ChineseWorldNamesV30.Generate("城池","17")==ChineseWorldNamesV30.Generate("城池","17"),"stable city");
        Check(ChineseWorldNamesV30.Generate("王朝","17").EndsWith("王朝"),"kingdom naming grammar");
        for(int i=0;i<5000;i++)foreach(string kind in new[]{"人物","城池","王朝"}){
            var name=ChineseWorldNamesV30.Generate(kind,i.ToString());
            Check(name.Length>=3&&!ChineseWorldNamesV30.NeedsChinese(name),"Chinese generated entity names");
        }
        SharedPanelsV30.Close();
        SharedPanelsV30.Show("cultivation");
        SharedPanelsV30.Show("settings");
        Check(SharedPanelsV30.Active=="settings","one active panel replaces previous");
        AppDomain.CurrentDomain.SetData("xys.worldbox.active_panel.v30","observer");
        Check(SharedPanelsV30.Active=="observer","shared process state across callers");
        SharedPanelsV30.Toggle("observer");
        Check(SharedPanelsV30.Active=="","toggle closes");
        SharedPanelsV30.RegisterNativeMenu();
        Check(SharedPanelsV30.NativeMenu,"single native toolbar ownership");
        Console.WriteLine("PASS_WORLD_NAMES_PANELS_V30: entity mutation, original backup, stable Chinese names, singleton panels");
        return 0;
    }
}
