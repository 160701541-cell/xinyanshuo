using System;
using System.Collections;
using System.Collections.Generic;
using System.Reflection;
using System.Runtime.CompilerServices;
namespace XianxiaWorldBox.Economy {
 /// <summary>v0.36 read-only connection to REAL WorldBox 0.51.4 MapBox,
 /// Kingdom.cities, City.zones and TileZone.tiles. No fake border lengths,
 /// invented taxes, God powers, nor modification of vanilla save or inventory.</summary>
 public static class EconomyUnityAdapterV35 {
   const int MaxKingdoms=256,MaxCities=6000,MaxZones=200000;
   const BindingFlags F=BindingFlags.Public|BindingFlags.NonPublic|
     BindingFlags.Instance|BindingFlags.Static;
   public static readonly EconomyWorld Model=new EconomyWorld();
   public static string Status="WORLD_NOT_READY";
   public static int ObservedCities {get;private set;}
   public static int ObservedKingdoms {get;private set;}
   public static int ZonesCounted {get;private set;}
   public static int NativeStockCityCount {get;private set;}
   public static int TerritoryKnownKingdoms {get;private set;}
   public static string WorldMarker {get;private set;}="";
   public static string QaLastError {get;private set;}="";
   static object currentWorld;
   static DateTime next=DateTime.MinValue;
   static object Read(object instance,params string[] names) {
     if(instance==null)return null;
     Type type=instance as Type??instance.GetType();
     foreach(string name in names) {
       try {
         for(Type t=type;t!=null;t=t.BaseType){
           var field=t.GetField(name,F|BindingFlags.DeclaredOnly);
           if(field!=null)return field.GetValue(field.IsStatic?null:instance);
           var prop=t.GetProperty(name,F|BindingFlags.DeclaredOnly);
           if(prop!=null&&prop.GetIndexParameters().Length==0){
             var getter=prop.GetGetMethod(true);
             if(getter!=null)return getter.Invoke(getter.IsStatic?null:instance,null);
           }
         }
       }catch{ }
     }
     return null;
   }
   static IEnumerable Seq(object collection) {
     if(collection==null)return new object[0];
     return collection as IEnumerable??new object[0];
   }
   static IEnumerable ManagedItems(object manager) {
     object collection=Read(manager,"list","_list","_kingdoms");
     if(collection==null&&manager!=null){
       try{
         var m=manager.GetType().GetMethod("getSimpleList",F,null,Type.EmptyTypes,null);
         if(m!=null)collection=m.Invoke(manager,null);
       }catch{}
     }
     return Seq(collection);
   }
   static string Key(object entity) {
     // Game MetaObject.id is inherited, and CityData.cityID is also present.
     // GetType().GetField() alone misses some protected inherited fields.
     var data=Read(entity,"data");
     object value=Read(entity,"id","_id")??
       Read(data,"id","cityID","kingdomID","_id");
     return value==null?null:Convert.ToString(value);
   }
   static int NativeInteger(object entity,string name) {
     object value=Read(entity,name);
     if(value==null)return -1;
     return int.TryParse(Convert.ToString(value),out int result)&&result>=0
       ?result:-1;
   }
   static bool NativeStock(object city,District district) {
     int gold=NativeInteger(city,"amount_gold");
     int wood=NativeInteger(city,"amount_wood");
     int stone=NativeInteger(city,"amount_stone");
     int metals=NativeInteger(city,"amount_common_metals");
     if(gold<0||wood<0||stone<0||metals<0)return false;
     district.NativeGold=gold;
     district.NativeWood=wood;
     district.NativeStone=stone;
     district.NativeCommonMetals=metals;
     district.NativeResourcesObserved=true;
     return true;
   }
   static int ZonesArea(object city,HashSet<object> seen,out int zoneCount,
      out int borderLinks) {
     zoneCount=0;borderLinks=0;
     long area=0;
     foreach(object zone in Seq(Read(city,"zones"))) {
       if(zone==null||!seen.Add(zone))continue;
       zoneCount++;
       if(zoneCount>MaxZones)return -1;
       // Real 0.51.4 TileZone.tiles is WorldTile[], already owned by City.zones.
       var tiles=Read(zone,"tiles") as Array;
       if(tiles==null){return -1;}
       area+=tiles.Length;
       if(area>int.MaxValue)return -1;
       foreach(object adjacent in Seq(Read(zone,"neighbours_all","neighbours"))) {
         if(adjacent==null)continue;
         object neighborCity=Read(adjacent,"city");
         if(neighborCity!=null&&!object.ReferenceEquals(neighborCity,city))
           borderLinks++; // only a coarse zone adjacency counter
       }
     }
     return (int)area;
   }
   static string CityName(object city,string fallback) {
     object data=Read(city,"data");
     var native=Read(data,"cityName")??Read(city,"name");
     string value=native as string;
     return !string.IsNullOrWhiteSpace(value)?value:fallback;
   }
   static string KingdomName(object kingdom,string fallback) {
     var name=Read(kingdom,"name") as string??Read(Read(kingdom,"data"),"name") as string;
     return !string.IsNullOrWhiteSpace(name)?name:fallback;
   }
   public static int Snapshot(object mapbox) {
     if(mapbox==null){Status="WAIT_ACTUAL_WORLDBOX_MAPBOX";return 0;}
     // Different worlds on same phone must never share a model's stored
     // stock, city IDs or area. This reset cannot touch the game save.
     if(!object.ReferenceEquals(currentWorld,mapbox)) {
       Model.Districts.Clear();
       Model.NaturalNodes.Clear();
       Model.Recipes.Clear();
       Model.Learned.Clear();
       currentWorld=mapbox;
     }
     var manager=Read(mapbox,"kingdoms");
     if(manager==null){Status="WAIT_WORLDBOX_KINGDOM_MANAGER";return 0;}
     var active=new HashSet<string>(StringComparer.Ordinal);
     var dedupe=new HashSet<object>(ReferenceComparer.Instance);
     int observed=0,cities=0,allZones=0,knownAreas=0,nativeCities=0;
     foreach(object kingdom in ManagedItems(manager)){
       if(kingdom==null||observed>=MaxKingdoms||cities>=MaxCities)break;
       string key=Key(kingdom);
       if(string.IsNullOrWhiteSpace(key)||key.Length>96)continue;
       string id="wbx-kingdom:"+key;
       if(!Model.Districts.TryGetValue(id,out var parent)) {
         parent=new District(id,KingdomName(kingdom,"王国 "+key),DistrictTier.Kingdom,null,id);
         Model.AddDistrict(parent);
       }
       parent.Name=KingdomName(kingdom,parent.Name);
       active.Add(id);
       observed++;
       long total=0;
       bool complete=true;
       int children=0,kingdomZones=0,allLinks=0;
       foreach(object city in Seq(Read(kingdom,"cities"))){
         if(city==null||cities>=MaxCities)break;
         string cityKey=Key(city);
         if(string.IsNullOrWhiteSpace(cityKey)||cityKey.Length>96)continue;
         string childId="wbx-city:"+cityKey;
         // A WorldBox City is kept as a city/COUNTY bookkeeping proxy;
         // it is not yet an official historical county government.
         if(!Model.Districts.TryGetValue(childId,out var district)) {
           district=new District(childId,CityName(city,"城 "+cityKey),
             DistrictTier.County,id,id);
           Model.AddDistrict(district);
         }
         district.Name=CityName(city,district.Name);
         district.ParentId=id;
         district.KingdomId=id; // conquest reassignment, never duplicate city treasury
         district.NativeResourcesObserved=false;
         if(NativeStock(city,district))nativeCities++;
         int zones,links;
         int area=ZonesArea(city,dedupe,out zones,out links);
         allZones+=zones;kingdomZones+=zones;
         district.BorderZoneLinks=links;
         district.TerritoryTiles=area;
         if(area>=0)total+=area;
         else complete=false;
         allLinks+=links;
         cities++;children++;
         active.Add(childId);
       }
       parent.CityCount=children;
       parent.TerritoryTiles=complete&&children>0&&total<=int.MaxValue?(int)total:-1;
       parent.BorderZoneLinks=complete?allLinks:-1;
       if(parent.TerritoryTiles>=0)knownAreas++;
       int population=NativeInteger(kingdom,"population");
       if(population<0){
         try {
           var m=kingdom.GetType().GetMethod("getPopulationTotal",F,null,Type.EmptyTypes,null);
           if(m!=null)population=Convert.ToInt32(m.Invoke(kingdom,null));
         }catch{}
       }
       if(population>=0)parent.People=population;
     }
     // Removes records from destroyed cities, kingdoms or different maps.
     var stale=new List<string>();
     foreach(var pair in Model.Districts)
       if(!active.Contains(pair.Key))stale.Add(pair.Key);
     foreach(string id in stale)Model.Districts.Remove(id);
     ObservedKingdoms=observed;
     ObservedCities=cities;
     ZonesCounted=allZones;
     NativeStockCityCount=nativeCities;
     TerritoryKnownKingdoms=knownAreas;
     WorldMarker="WORLD_OBJECT_ID="+RuntimeHelpers.GetHashCode(mapbox);
     Status="REAL_WORLDBOX_KINGDOMS="+observed+
       " CITIES="+cities+" ZONES="+allZones+" AREAS="+knownAreas+
       " NATIVE_STOCK_CITIES="+nativeCities+
       "; true borders/palace/construction not yet device-verified";
     return observed;
   }
   sealed class ReferenceComparer:IEqualityComparer<object> {
     public static readonly ReferenceComparer Instance=new ReferenceComparer();
     public new bool Equals(object a,object b)=>object.ReferenceEquals(a,b);
     public int GetHashCode(object obj)=>RuntimeHelpers.GetHashCode(obj);
   }
   public static void Tick() {
     if(DateTime.UtcNow<next)return;
     next=DateTime.UtcNow.AddSeconds(10);
     try {
       object world=null;
       foreach(Assembly a in AppDomain.CurrentDomain.GetAssemblies())
         if(a.GetName().Name=="Assembly-CSharp"){
           // Verified against user-owned actual Mono 0.51.4:
           // World.world is static property of type MapBox and
           // MapBox.instance is static field; its kingdoms -> KingdomManager.
           var w=a.GetType("World",false);
           world=Read(w,"world")??Read(a.GetType("MapBox",false),"instance");
           break;
         }
       Snapshot(world);
       QaLastError="";
     }catch(Exception ex){
       QaLastError=ex.GetType().Name+": "+ex.Message;
       Status="ECONOMY_REAL_MAP_ADAPTER_ERROR "+QaLastError;
     }
   }
 }
}
