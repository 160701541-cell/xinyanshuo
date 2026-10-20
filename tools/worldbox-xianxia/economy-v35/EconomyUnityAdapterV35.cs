using System;
using System.Collections;
using System.Collections.Generic;
using System.Reflection;
namespace XianxiaWorldBox.Economy {
 // Read-only WorldBox gameplay adapter: actual existing kingdom IDs ONLY.
 // Does not create fictional cities, change kingdom borders or mint treasury.
 public static class EconomyUnityAdapterV35 {
   static readonly BindingFlags Flags=BindingFlags.Public|BindingFlags.NonPublic|
       BindingFlags.Instance|BindingFlags.Static;
   public static readonly EconomyWorld Model=new EconomyWorld();
   public static string Status="WORLD_NOT_READY";
   static DateTime next=DateTime.MinValue;
   static object Member(object obj,params string[] names) {
     if(obj==null)return null;
     var t=obj as Type??obj.GetType();
     foreach(string name in names){
       try{
         var f=t.GetField(name,Flags);
         if(f!=null)return f.GetValue(f.IsStatic?null:obj);
         var p=t.GetProperty(name,Flags);
         if(p!=null&&p.GetIndexParameters().Length==0){
           var getter=p.GetGetMethod(true);
           if(getter!=null)return getter.Invoke(getter.IsStatic?null:obj,null);
         }
       }catch{} // Field absent on some WorldBox 0.51.x builds
     }
     return null;
   }
   static IEnumerable List(object lib) {
     if(lib==null)return new object[0];
     object x=Member(lib,"list","_list","_kingdoms");
     if(x==null) {
       var m=lib.GetType().GetMethod("getSimpleList",Flags,null,Type.EmptyTypes,null);
       if(m!=null)try{x=m.Invoke(lib,null);}catch{}
     }
     return x as IEnumerable??new object[0];
   }
   public static int Snapshot(object actualWorld) {
     if(actualWorld==null){Status="WAIT_REAL_WORLDBOX_WORLD";return 0;}
     object library=Member(actualWorld,"kingdoms");
     int observed=0;
     foreach(object kingdom in List(library)){
       if(kingdom==null)continue;
       object id=Member(kingdom,"id","kingdom_id","getID");
       if(id==null)continue;
       string key=id.ToString();
       if(string.IsNullOrEmpty(key)||key.Length>96)continue;
       string index="wbx-kingdom:"+key;
       if(!Model.Districts.TryGetValue(index,out var district)){
         object name=Member(kingdom,"name","kingdom_name","data");
         string title=name is string?(string)name:"王国 "+key;
         district=new District(index,title,DistrictTier.Kingdom,null,index);
         Model.AddDistrict(district);
       }
       // A WorldBox territory area exists only if tile ownership has
       // actually been read. Do not claim country area from kingdom count.
       var population=Member(kingdom,"population","total_population");
       if(population!=null && int.TryParse(population.ToString(),out var people) && people>=0)
         district.People=people;
       observed++;
       if(observed>=256)break; // preserve phone frame budget
     }
     Status="REAL_KINGDOMS="+observed+" ECONOMY_RECORDS="+Model.Districts.Count+
       " BANK_STOCK_NOT_MINTED; BORDER_AREA_PENDING";
     return observed;
   }
   public static void Tick() {
     if(DateTime.UtcNow<next)return;
     next=DateTime.UtcNow.AddSeconds(10);
     try{
       object world=null;
       foreach(Assembly assembly in AppDomain.CurrentDomain.GetAssemblies())
         if(assembly.GetName().Name=="Assembly-CSharp") {
           var type=assembly.GetType("World",false);
           world=Member(type,"world");
           break;
         }
       Snapshot(world);
     }catch(Exception e){Status="ECONOMY_GAME_ADAPTER_FAILED "+e.GetType().Name;}
   }
 }
}
