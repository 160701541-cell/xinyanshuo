using System;
using System.Collections.Generic;

// WorldBox external third-party MOD laboratory. NOT the original Canglan game.
// Standalone deterministic world-domain logic: adapters may render/bind it to
// WorldBox assets, but no vanilla race/species or save values are modified here.
namespace XianxiaWorldBox
{
    public enum MortalSociety { HumanDynasty, MountainSect, CityCultivatorClan }
    public enum SpiritOrigin { OrdinaryBeast, AwakeningBeast, DemonBeast, TamedSpiritBeast }
    public enum TravelMode { Walking, BodyFlight, SwordFlight, SpiritBoat }
    public enum FormationState { Dormant, Guarding, Broken }

    public static class XianxiaWorldRulesV19
    {
        public const int FoundationRealmIndex = 14; // CultivationV18: 筑基初期
        public const int QiPerSecondBodyFlight = 3;
        public const int QiPerSecondSwordFlight = 2;
        public const int SpiritStonesPerMinuteBoat = 1;
        public static bool CanFly(int realmIndex) { return realmIndex >= FoundationRealmIndex; }
        public static bool ValidSectLocation(bool mountain, int height, bool summit)
        { return mountain && (summit || height >= 65); }
        public static bool ValidClanLocation(bool nearMortalCity, int distanceInTiles)
        { return nearMortalCity && distanceInTiles >= 2 && distanceInTiles <= 48; }
        public static string ReinterpretFantasyRace(string original)
        {
            // Human remains human; fantasy populations become named traditions,
            // not a destructive rewrite of vanilla race data.
            if (original == "human") return "凡俗人族";
            if (original == "elf") return "青木灵裔";
            if (original == "dwarf") return "地脉工族";
            if (original == "orc") return "荒原战裔";
            return "未知族裔";
        }
    }

    public sealed class SpiritBeastRecordV19
    {
        public SpiritOrigin Origin = SpiritOrigin.OrdinaryBeast;
        public int CultivationProgress;
        public int Affinity;
        public bool Hostile;
        public int OwnerId = -1;
        public bool TryAwaken(int seed, int chancePerTenThousand = 12)
        {
            if(Origin != SpiritOrigin.OrdinaryBeast) return false;
            if(chancePerTenThousand<0||chancePerTenThousand>10000)
                throw new ArgumentOutOfRangeException("chancePerTenThousand");
            if(seed<0)seed=-(seed+1);
            int roll=seed%10000;
            if(roll>=chancePerTenThousand)return false;
            Origin=SpiritOrigin.AwakeningBeast;
            return true;
        }
        public void Practice(int qi)
        {
            if(Origin==SpiritOrigin.OrdinaryBeast||qi<=0)return;
            CultivationProgress=Math.Min(1000000,CultivationProgress+qi);
            if(CultivationProgress>=100&&Origin==SpiritOrigin.AwakeningBeast)
            { Origin=SpiritOrigin.DemonBeast; Hostile=true; }
        }
        public bool Tame(int ownerId,int harmony)
        {
            if(ownerId<0||harmony<65||Origin!=SpiritOrigin.DemonBeast)return false;
            Origin=SpiritOrigin.TamedSpiritBeast;
            OwnerId=ownerId; Hostile=false;Affinity=harmony;
            return true;
        }
    }

    public sealed class FlightRecordV19
    {
        public TravelMode Mode=TravelMode.Walking;
        public int Qi;
        public int SpiritStones;
        public int Speed { get {
            if(Mode==TravelMode.BodyFlight)return 7;
            if(Mode==TravelMode.SwordFlight)return 13;
            if(Mode==TravelMode.SpiritBoat)return 17;
            return 3;
        }}
        public bool Start(TravelMode mode,int realmIndex)
        {
            if(mode==TravelMode.Walking){Mode=mode;return true;}
            if(mode!=TravelMode.SpiritBoat && !XianxiaWorldRulesV19.CanFly(realmIndex))return false;
            if(mode==TravelMode.SpiritBoat && SpiritStones<=0)return false;
            if(mode!=TravelMode.SpiritBoat && Qi<=0)return false;
            Mode=mode;return true;
        }
        public bool TickSeconds(int seconds)
        {
            if(seconds<0||seconds>3600)throw new ArgumentOutOfRangeException("seconds");
            if(Mode==TravelMode.Walking)return true;
            int rate=Mode==TravelMode.BodyFlight ?
                XianxiaWorldRulesV19.QiPerSecondBodyFlight:
                XianxiaWorldRulesV19.QiPerSecondSwordFlight;
            if(Mode==TravelMode.SpiritBoat)
            {
                int spend=(seconds+59)/60*XianxiaWorldRulesV19.SpiritStonesPerMinuteBoat;
                if(spend>SpiritStones){Mode=TravelMode.Walking;return false;}
                SpiritStones-=spend;return true;
            }
            long cost=(long)seconds*rate;
            if(cost>Qi){Qi=0;Mode=TravelMode.Walking;return false;}
            Qi-=(int)cost;return true;
        }
    }

    public sealed class MountainSectV19
    {
        public int Elevation;
        public bool Mountain, Summit;
        public int SpiritStoneBank;
        public int FormationIntegrity=100;
        public FormationState Formation=FormationState.Dormant;
        public bool CanEstablish() {return XianxiaWorldRulesV19.ValidSectLocation(Mountain,Elevation,Summit);}
        public bool ActivateFormation(int initialCost=3)
        {
            if(!CanEstablish()||initialCost<1||SpiritStoneBank<initialCost||
               FormationIntegrity<=0)return false;
            SpiritStoneBank-=initialCost;Formation=FormationState.Guarding;return true;
        }
        public bool AbsorbAttack(int attack)
        {
            if(attack<0)throw new ArgumentOutOfRangeException("attack");
            if(Formation!=FormationState.Guarding)return false;
            FormationIntegrity=Math.Max(0,FormationIntegrity-Math.Max(1,attack/2));
            if(FormationIntegrity==0)Formation=FormationState.Broken;
            return true;
        }
        public void Recharge(int stones)
        {
            if(stones<1||SpiritStoneBank<stones) return;
            SpiritStoneBank-=stones;
            FormationIntegrity=Math.Min(100,FormationIntegrity+stones*8);
            if(FormationIntegrity>0 && Formation==FormationState.Broken)
                Formation=FormationState.Dormant; // reactivation costs stones
        }
    }

    public sealed class CityProtectorClanV19
    {
        public int DistanceToCity;
        public bool NearMortalCity;
        public int ProtectionScore;
        public bool CanEstablish()
        {return XianxiaWorldRulesV19.ValidClanLocation(NearMortalCity,DistanceToCity);}
        public int Defend(int attack)
        { return CanEstablish()?Math.Max(0,attack-ProtectionScore):attack; }
    }
}
