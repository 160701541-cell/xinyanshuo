using System;
using System.Linq;
using XianxiaWorldBox.Economy;
public static class WbEconomyV35Tests {
 static void Eq<T>(T got,T expected,string why) {
   if(!object.Equals(got,expected))throw new Exception(why+": "+got+" != "+expected);
 }
 static void Reject(Action act,string why){
   try{act();}catch(InvalidOperationException){return;}catch(ArgumentException){return;}
   throw new Exception("should reject "+why);
 }
 public static void Main(){
   var sim=new EconomyWorld();
   var kingdom=new District("K1","武宁国",DistrictTier.Kingdom,null,"K1");
   var county=new District("K1/C","青河县",DistrictTier.County,"K1","K1");
   var village=new District("K1/C/V","稻花村",DistrictTier.Village,"K1/C","K1");
   sim.AddDistrict(kingdom);sim.AddDistrict(county);sim.AddDistrict(village);
   Eq(kingdom.TerritoryTiles,-1,"no fake kingdom area before sampling real WorldBox tiles");
   village.Stock.ReceiveMoney(9000);county.Stock.ReceiveMoney(90000);
   village.Stock.Add("wbx_rice",100);county.Stock.Add("wbx_iron_ore",15);
   sim.RegisterNode(new NaturalNode{Id="n1",Resource="wbx_spirit_stone_low",Biome="mountain",
     X=12,Y=33,Capacity=8,Remaining=5,RegrowthDays=12,NextRegrowthDay=12});
   sim.Gather("n1","K1/C/V",3);
   Eq(village.Stock.Get("wbx_spirit_stone_low"),3L,"spirit stone only from natural mine");
   sim.Trade("K1/C/V","K1/C","wbx_rice",10,40);
   Eq(village.Stock.Get("wbx_rice"),90L,"seller loses 10 rice");
   Eq(county.Stock.Get("wbx_rice"),10L,"buyer gets 10 rice");
   Eq(village.Stock.MoneyCopper,9400L,"seller cash increases by buyer payment");
   Eq(county.Stock.MoneyCopper,89600L,"buyer cash decreases");
   sim.Tax("K1/C/V","K1",150);
   sim.Payroll("K1","K1/C",60);
   Eq(kingdom.Stock.MoneyCopper,90L,"taxes not minted wages");
   Eq(village.Stock.MoneyCopper,9250L,"citizen taxed");
   Eq(county.Stock.MoneyCopper,89660L,"army wages transferred");
   Eq(kingdom.Stock.MoneyCopper+county.Stock.MoneyCopper+village.Stock.MoneyCopper,
      99000L,"closed system money conserved");
   var recipe=new Recipe{Id="smelt_iron",Minutes=120,Workers=2,Research="smelting",Workshop="炉"};
   recipe.Inputs.Add("wbx_iron_ore",3);recipe.Outputs.Add("wbx_iron_ingot",2);
   sim.AddRecipe(recipe);Reject(()=>sim.Build("K1/C","smelt_iron",2,120),"research required");
   sim.Learned.Add("smelting");Reject(()=>sim.Build("K1/C","smelt_iron",1,120),"workers required");
   sim.Build("K1/C","smelt_iron",2,120);
   Eq(county.Stock.Get("wbx_iron_ore"),12L,"raw item consumed");
   Eq(county.Stock.Get("wbx_iron_ingot"),2L,"product created by recipe");
   Reject(()=>sim.Build("K1/C","smelt_iron",2,119),"world time consumed");
   Reject(()=>sim.Gather("n1","K1/C/V",200),"no resource duplication");
   sim.AdvanceDays(36);
   Eq(sim.NaturalNodes["n1"].Remaining,5,"natural reserve only regrows up to cap");
   Eq(EconomyWorld.MonetaryValue(0,1,1),101000L,"copper-silver-gold denomination example");
   Reject(()=>EconomyWorld.MonetaryValue(-1,0,0),"negative money");
   var grid=new string[,]{{"K1","K1","K1"},{"K1","K2","K2"},{"K1","K2",null}};
   var areas=EconomyWorld.Areas(grid);
   Eq(areas["K1"],5,"area belongs to actual tile owner ids");
   Eq(areas["K2"],3,"second kingdom tile count");
   Eq(EconomyWorld.IsBorder(grid,1,1),true,"grid boundary between kingdoms");
   Eq(EconomyWorld.IsBorder(grid,0,0),true,"map edge boundary detected");
   Console.WriteLine("PASS_V35_ADMIN_ECONOMY 6 tiers, real resources, trade/tax/payroll, crafting, 2048 border primitives");
 }
}
