using System;
using XianxiaWorldBox;
static class WorldRulesScenarioV19
{
 static void Assert(bool cond,string reason)
 {if(!cond)throw new Exception("WORLD_RULES_V19_FAIL "+reason);}
 static int Main()
 {
  Assert(XianxiaWorldRulesV19.ReinterpretFantasyRace("human")=="凡俗人族","humans preserved");
  Assert(XianxiaWorldRulesV19.ReinterpretFantasyRace("elf")=="青木灵裔","elves renamed not deleted");
  Assert(!XianxiaWorldRulesV19.CanFly(13),"no flight for Qi refining");
  Assert(XianxiaWorldRulesV19.CanFly(14),"foundation-body-flight");
  var flight=new FlightRecordV19{Qi=120};
  Assert(!flight.Start(TravelMode.SwordFlight,13),"cannot bypass foundation");
  Assert(flight.Start(TravelMode.BodyFlight,14),"body-flight started");
  Assert(flight.TickSeconds(10)&&flight.Qi==90,"body flight spends qi");
  Assert(flight.Start(TravelMode.SwordFlight,14)&&flight.Speed>7,"faster sword flight");
  Assert(flight.TickSeconds(10)&&flight.Qi==70,"sword flight spends less qi");
  Assert(flight.Start(TravelMode.SpiritBoat,0)==false,"boat needs spirit stones");
  flight.SpiritStones=5;
  Assert(flight.Start(TravelMode.SpiritBoat,0),"boat no personal cultivation requirement");
  int before=flight.Qi;
  Assert(flight.TickSeconds(60)&&flight.Qi==before&&flight.SpiritStones==4,"boat uses stone not personal qi");
  var beast=new SpiritBeastRecordV19();
  Assert(!beast.TryAwaken(9999),"rare awakening");
  Assert(beast.TryAwaken(0),"rare awakening at selected probability");
  beast.Practice(100);
  Assert(beast.Origin==SpiritOrigin.DemonBeast,"awakened beast becomes demon beast");
  Assert(!beast.Tame(7,64),"must develop affinity");
  Assert(beast.Tame(7,80)&&!beast.Hostile,"spirit beast contract");
  var sect=new MountainSectV19{Mountain=true,Summit=true,SpiritStoneBank=10};
  Assert(sect.CanEstablish()&&sect.ActivateFormation(),"mountain formation");
  Assert(sect.SpiritStoneBank==7,"formation activation costs stones");
  Assert(sect.AbsorbAttack(240)&&sect.Formation==FormationState.Broken,"formation breaks under assault");
  sect.Recharge(5);
  Assert(sect.Formation==FormationState.Dormant,"recharging requires reactivation");
  var clan=new CityProtectorClanV19{NearMortalCity=true,DistanceToCity=8,ProtectionScore=50};
  Assert(clan.CanEstablish()&&clan.Defend(80)==30,"city clan protects mortal dynasty");
  Assert(!XianxiaWorldRulesV19.ValidSectLocation(false,1,false),"sect needs mountain");
  Console.WriteLine("PASS_WORLD_RULES_V19 mortal dynasties, animal cultivation, spirit stones, sect formations");
  return 0;
 }
}
