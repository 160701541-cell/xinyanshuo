// Nonofficial WorldBox 0.51.4 personal MOD. Pure deterministic economy rules;
// uses no Canglan game code/save. Does not claim to render country borders.
using System;
using System.Collections.Generic;
using System.Linq;
namespace XianxiaWorldBox.Economy {
 public enum DistrictTier {Village, Township, County, Prefecture, Commandery, Kingdom}
 public enum SocietyJob {Farmer, Merchant, Miner, Artisan, Soldier, Official, Scholar,
   Physician, Fisher, Woodcutter, Alchemist, TalismanMaker, Cultivator, Caravan}
 public sealed class WbLedger {
   public readonly Dictionary<string,long> Stock=new Dictionary<string,long>(StringComparer.Ordinal);
   public long MoneyCopper;
   public long Get(string id)=>Stock.TryGetValue(id,out var value)?value:0L;
   public void Add(string id,long count){
     if(string.IsNullOrEmpty(id)||count<0||count>100000000)throw new ArgumentException("invalid stock");
     long sum=checked(Get(id)+count);
     Stock[id]=sum;
   }
   public void Take(string id,long count) {
     if(count<0||count>Get(id))throw new InvalidOperationException("insufficient "+id);
     Stock[id]=Get(id)-count;
   }
   public void TakeMoney(long amount) {
     if(amount<0||MoneyCopper<amount)throw new InvalidOperationException("insufficient money");
     MoneyCopper-=amount;
   }
   public void ReceiveMoney(long amount) {
     if(amount<0)throw new ArgumentOutOfRangeException(nameof(amount));
     MoneyCopper=checked(MoneyCopper+amount);
   }
 }
 public sealed class District {
   public readonly string Id,Name;
   public readonly DistrictTier Tier;
   public string ParentId;
   public int People;
   public int TerritoryTiles=-1; // unknown until sampled actual WorldBox map
   public string KingdomId;        // from original WorldBox id, not fabricated borders
   public readonly WbLedger Stock=new WbLedger();
   public District(string id,string name,DistrictTier tier,string parentId,string kingdomId) {
     if(string.IsNullOrWhiteSpace(id))throw new ArgumentException("district identity");
     Id=id;Name=name;Tier=tier;ParentId=parentId;KingdomId=kingdomId;
   }
 }
 public sealed class Recipe {
   public string Id;
   public int Minutes,Workers=1;
   public string Job,Research,Workshop;
   public readonly Dictionary<string,long> Inputs=new Dictionary<string,long>();
   public readonly Dictionary<string,long> Outputs=new Dictionary<string,long>();
 }
 public sealed class NaturalNode {
   public string Id,Resource,Biome;
   public int X,Y,Capacity,Remaining,RegrowthDays;
   public long NextRegrowthDay;
 }
 public sealed class EconomyWorld {
   public const long CopperPerSilver=1000L,SilverPerGold=100L;
   public readonly Dictionary<string,District> Districts=new Dictionary<string,District>(StringComparer.Ordinal);
   public readonly Dictionary<string,Recipe> Recipes=new Dictionary<string,Recipe>(StringComparer.Ordinal);
   public readonly Dictionary<string,NaturalNode> NaturalNodes=new Dictionary<string,NaturalNode>(StringComparer.Ordinal);
   public readonly HashSet<string> Learned=new HashSet<string>(StringComparer.Ordinal);
   public readonly Dictionary<SocietyJob,int> Labor=new Dictionary<SocietyJob,int>();
   public long GameDay;
   public static long MonetaryValue(long copper,long silver,long gold) {
     if(copper<0||silver<0||gold<0)throw new ArgumentOutOfRangeException("currency");
     return checked(checked(copper+silver*CopperPerSilver)+gold*CopperPerSilver*SilverPerGold);
   }
   public void AddDistrict(District district) {
     if(Districts.ContainsKey(district.Id))throw new InvalidOperationException("duplicate district id");
     if(district.ParentId!=null) {
       if(!Districts.TryGetValue(district.ParentId,out var p))throw new InvalidOperationException("parent not registered");
       if((int)district.Tier>=(int)p.Tier || !string.Equals(p.KingdomId,district.KingdomId,StringComparison.Ordinal))
         throw new InvalidOperationException("administrative hierarchy invalid");
     }
     Districts.Add(district.Id,district);
   }
   public void AddRecipe(Recipe recipe){
     if(recipe==null||string.IsNullOrEmpty(recipe.Id)||recipe.Inputs.Count==0||recipe.Outputs.Count==0||
        recipe.Minutes<1||recipe.Workers<1||Recipes.ContainsKey(recipe.Id))
       throw new ArgumentException("invalid recipe");
     if(recipe.Inputs.Any(p=>p.Value<=0)||recipe.Outputs.Any(p=>p.Value<=0))
       throw new ArgumentException("negative production amount");
     Recipes.Add(recipe.Id,recipe);
   }
   public void Build(string districtId,string recipeId,int workers,int minutes){
     var district=Districts[districtId];var recipe=Recipes[recipeId];
     if(!string.IsNullOrEmpty(recipe.Research)&&!Learned.Contains(recipe.Research))
       throw new InvalidOperationException("research locked");
     if(workers<recipe.Workers||minutes<recipe.Minutes)
       throw new InvalidOperationException("labor shortage");
     foreach(var need in recipe.Inputs)
       if(district.Stock.Get(need.Key)<need.Value)throw new InvalidOperationException("not enough "+need.Key);
     // Atomic after all validated; outputs cannot mint raw materials without inputs.
     foreach(var need in recipe.Inputs)district.Stock.Take(need.Key,need.Value);
     foreach(var produced in recipe.Outputs)district.Stock.Add(produced.Key,produced.Value);
   }
   public void TransferStock(string fromId,string toId,string item,long amount){
     if(amount<=0||fromId==toId)throw new ArgumentException("invalid item transfer");
     var from=Districts[fromId].Stock;var to=Districts[toId].Stock;
     if(from.Get(item)<amount||to.Get(item)>long.MaxValue-amount)
       throw new InvalidOperationException("invalid stock transfer");
     from.Take(item,amount);to.Add(item,amount);
   }
   public void Trade(string sellerId,string buyerId,string item,long units,long unitPriceCopper) {
     if(units<=0||unitPriceCopper<0||sellerId==buyerId)throw new ArgumentException("bad trade");
     long price=checked(units*unitPriceCopper);
     var a=Districts[sellerId].Stock;var b=Districts[buyerId].Stock;
     if(a.Get(item)<units||b.MoneyCopper<price||
        a.MoneyCopper>long.MaxValue-price||b.Get(item)>long.MaxValue-units)
       throw new InvalidOperationException("trade insufficient funds/items");
     a.Take(item,units);b.Add(item,units);
     b.TakeMoney(price);a.ReceiveMoney(price);
   }
   public void Tax(string subjectId,string treasuryId,long amount){
     if(amount<0||subjectId==treasuryId)throw new ArgumentException("bad tax");
     var citizen=Districts[subjectId].Stock;var treasury=Districts[treasuryId].Stock;
     if(citizen.MoneyCopper<amount||treasury.MoneyCopper>long.MaxValue-amount)
       throw new InvalidOperationException("tax unavailable");
     citizen.TakeMoney(amount);treasury.ReceiveMoney(amount);
   }
   public void Payroll(string treasuryId,string soldiersId,long amount) {
     Tax(treasuryId,soldiersId,amount); // transfer; never mint army wages
   }
   public void RegisterNode(NaturalNode n) {
     if(n==null||string.IsNullOrEmpty(n.Id)||n.Capacity<1||n.Remaining<0||
        n.Remaining>n.Capacity||n.RegrowthDays<0||NaturalNodes.ContainsKey(n.Id))
       throw new ArgumentException("invalid natural source");
     NaturalNodes.Add(n.Id,n);
   }
   public void Gather(string nodeId,string destinationDistrict,int count){
     if(count<=0)throw new ArgumentException("must gather");
     var n=NaturalNodes[nodeId];
     if(n.Remaining<count)throw new InvalidOperationException("node exhausted");
     n.Remaining-=count;
     Districts[destinationDistrict].Stock.Add(n.Resource,count);
   }
   public void AdvanceDays(long days) {
     if(days<0||days>10000)throw new ArgumentOutOfRangeException("world day advance");
     GameDay=checked(GameDay+days);
     foreach(var n in NaturalNodes.Values) {
       if(n.RegrowthDays==0||GameDay<n.NextRegrowthDay||n.Remaining>=n.Capacity)continue;
       long cycles=1+(GameDay-n.NextRegrowthDay)/n.RegrowthDays;
       n.Remaining=(int)Math.Min(n.Capacity,checked((long)n.Remaining+cycles));
       n.NextRegrowthDay=checked(n.NextRegrowthDay+cycles*n.RegrowthDays);
     }
   }
   // Actual realm border only from original map tile ownership. No guessed lines.
   public static bool IsBorder(string[,] owner,int x,int y) {
     int w=owner.GetLength(0),h=owner.GetLength(1);
     if(x<0||y<0||x>=w||y>=h)return false;
     string k=owner[x,y];
     if(string.IsNullOrEmpty(k))return false;
     return x==0||y==0||x==w-1||y==h-1||
        owner[x-1,y]!=k||owner[x+1,y]!=k||owner[x,y-1]!=k||owner[x,y+1]!=k;
   }
   public static Dictionary<string,int> Areas(string[,] owners){
     var result=new Dictionary<string,int>(StringComparer.Ordinal);
     for(int y=0;y<owners.GetLength(1);y++)
       for(int x=0;x<owners.GetLength(0);x++){
         string id=owners[x,y];if(string.IsNullOrEmpty(id))continue;
         result[id]=result.TryGetValue(id,out var n)?n+1:1;
       }
     return result;
   }
 }
}
