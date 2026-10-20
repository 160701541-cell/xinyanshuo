using System;
using System.Collections.Generic;
using XianxiaWorldBox.Economy;
public class FakeMapBox{
  public FakeKingdomManager kingdoms=new FakeKingdomManager();
}
public class FakeKingdomManager{
  public readonly List<FakeKingdom> list=new List<FakeKingdom>();
}
public class FakeKingdom{
  public long id;public string name;
  public readonly List<FakeCity> cities=new List<FakeCity>();
  public int fakePopulation=0;
  public int getPopulationTotal()=>fakePopulation;
}
public class FakeCityData{
  public long cityID;public string cityName;
}
public class FakeCity{
  public FakeCityData data=new FakeCityData();
  public readonly List<FakeZone> zones=new List<FakeZone>();
  public int amount_gold,amount_wood,amount_stone,amount_common_metals;
}
public class FakeZone{
  public FakeTile[] tiles;
  public FakeCity city;
  public FakeZone[] neighbours_all=new FakeZone[0];
}
public class FakeTile{
  public int x,y;
}
public static class RealWorldEconomyScenarioV36{
  static void Eq<T>(T a,T b,string label){
    if(!object.Equals(a,b))throw new Exception(label+": "+a+" != "+b);
  }
  static FakeCity NewCity(long id,string label,int tileCount,int gold=3){
    var c=new FakeCity{data=new FakeCityData{cityID=id,cityName=label},
      amount_gold=gold,amount_wood=7,amount_stone=5,amount_common_metals=2};
    var zone=new FakeZone{city=c,tiles=new FakeTile[tileCount]};
    for(int i=0;i<tileCount;i++)zone.tiles[i]=new FakeTile{x=i,y=3};
    c.zones.Add(zone);return c;
  }
  public static void Main(){
    var world=new FakeMapBox();
    var a=new FakeKingdom{id=11,name="天元王朝",fakePopulation=1800};
    var b=new FakeKingdom{id=12,name="玉阙国",fakePopulation=600};
    var market=NewCity(101,"青河县城",64,19);
    var field=NewCity(102,"石桥镇",32,7);
    var border=NewCity(201,"漠北城",16,4);
    a.cities.Add(market);a.cities.Add(field);b.cities.Add(border);
    world.kingdoms.list.Add(a);world.kingdoms.list.Add(b);
    Eq(EconomyUnityAdapterV35.Snapshot(world),2,"real world kingdoms");
    var m=EconomyUnityAdapterV35.Model;
    Eq(EconomyUnityAdapterV35.ObservedCities,3,"actual city count");
    Eq(EconomyUnityAdapterV35.ZonesCounted,3,"real TileZone objects");
    Eq(EconomyUnityAdapterV35.NativeStockCityCount,3,"true native stock read");
    Eq(m.Districts["wbx-kingdom:11"].TerritoryTiles,96,"area derived from original zones");
    Eq(m.Districts["wbx-kingdom:11"].CityCount,2,"town count not invented");
    Eq(m.Districts["wbx-kingdom:11"].People,1800,"Kingdom native population");
    Eq(m.Districts["wbx-city:101"].Name,"青河县城","CityData.cityName");
    Eq(m.Districts["wbx-city:101"].NativeGold,19,"WorldBox existing native gold");
    Eq(m.Districts["wbx-city:101"].NativeWood,7,"WorldBox existing wood");
    Eq(m.Districts["wbx-kingdom:11"].Stock.MoneyCopper,0L,
      "native gold not counted as minted copper fiat");
    m.Districts["wbx-city:101"].Stock.Add("wbx_rice",23);
    // City conquered; same city-owned local inventory should be carried
    // to the new kingdom without creating a duplicate district.
    a.cities.Remove(market);b.cities.Add(market);
    EconomyUnityAdapterV35.Snapshot(world);
    Eq(m.Districts["wbx-city:101"].KingdomId,"wbx-kingdom:12","city moved to conqueror");
    Eq(m.Districts["wbx-city:101"].Stock.Get("wbx_rice"),23L,
      "conquest does not mint or delete city material ledger");
    Eq(m.Districts["wbx-kingdom:11"].TerritoryTiles,32,"territory shrinks after conquest");
    Eq(m.Districts["wbx-kingdom:12"].TerritoryTiles,80,"new owner gets city zones");
    // Demolition/removal cleans bookkeeping, not base game save.
    b.cities.Remove(border);EconomyUnityAdapterV35.Snapshot(world);
    Eq(m.Districts.ContainsKey("wbx-city:201"),false,"deleted world city purged");
    // Switching WorldBox maps must clear old kingdom IDs and warehouses.
    var other=new FakeMapBox();
    var stranger=new FakeKingdom{id=33,name="新大陆"};
    stranger.cities.Add(NewCity(303,"初生村",8));
    other.kingdoms.list.Add(stranger);
    EconomyUnityAdapterV35.Snapshot(other);
    Eq(m.Districts.ContainsKey("wbx-city:101"),false,"prior world ledger removed");
    Eq(m.Districts["wbx-kingdom:33"].TerritoryTiles,8,"new world zone area real");
    Console.WriteLine("PASS_V36_REAL_0514_WORLD_COUNTRY_CITY_TERRITORY_NATIVE_STOCK_CONQUEST_RELOAD");
  }
}
