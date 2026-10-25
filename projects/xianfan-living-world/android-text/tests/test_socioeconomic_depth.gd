extends SceneTree

var problems: Array[String] = []
func _initialize() -> void:
    call_deferred("_run")

func check(condition: bool, why: String) -> void:
    if not condition:
        problems.append(why)
        push_error("SOCIAL DEPTH TEST FAILURE: "+why)

func _total_cash(sim: Dictionary) -> int:
    var sum:=0
    for r in sim["regions"].values():
        sum+=int(r["treasury"])
    for npc in sim["agents"].values():
        sum+=int(npc["coins"])
    return sum

func _run() -> void:
    var society: Dictionary=XianfanSocietySim.initial_state(0)
    check(society["agents"].size()==24,"24 named people are present")
    check(society["households"].size()>3,"independent co-resident households present")
    var money:=_total_cash(society)
    var quote:=XianfanSocietySim.regional_price(society,"城","粮")
    check(quote==2,"normal city grain price remains two copper")
    var high: Dictionary=society.duplicate(true)
    high["regions"]["城"]["stock"]["粮"]=1
    check(XianfanSocietySim.regional_price(high,"城","粮")>quote,"scarce grain becomes dearer")
    high["regions"]["城"]["stock"]["粮"]=1500
    check(XianfanSocietySim.regional_price(high,"城","粮")<quote,"abundant grain becomes cheaper")
    var young: Array=society["households"]["村-同户01"]
    var needy: Dictionary=society["agents"][young[0]]
    var donor: Dictionary=society["agents"][young[1]]
    needy["rations"]=0
    donor["rations"]=4
    XianfanSocietySim._family_support(society,19)
    check(int(needy["rations"])==1 and int(donor["rations"])==3,
        "family help physically transfers one ration without creating goods")
    check(int(society["family_support_count"])>0,"mutual aid is logged")
    check(_total_cash(society)==money,"family action preserves money")
    var caravan: Dictionary=society["caravans"][0]
    var first_qty:=int(society["regions"]["村"]["stock"]["鱼"])
    XianfanSocietySim.advance_to(society,8*60)
    check(str(caravan["state"])=="road" and int(caravan["qty"])>0,
        "porters carry accounted stock at 8 AM")
    var shipped:=int(caravan["qty"])
    check(int(society["regions"]["村"]["stock"]["鱼"])==first_qty-shipped,
        "source warehouse was debited on departure")
    check(int(society["agents"]["孟远川"]["cargo"]["鱼"])==shipped,
        "cargo belongs to real NPC")
    check(str(society["agents"]["孟远川"]["place"])=="临安官道",
        "porter visible on road")
    var before_money:=_total_cash(society)
    XianfanSocietySim.advance_to(society,16*60)
    check(str(caravan["state"])=="idle" and int(caravan["qty"])==0,
        "delivery is completed at recorded arrival time")
    check(int(society["agents"]["孟远川"]["cargo"]["鱼"])==0,
        "delivery removes carried cargo")
    check(int(society["caravan_trades"])>0,"completed caravan transaction recorded")
    check(_total_cash(society)==before_money,
        "money transferred between treasuries, not created")
    check(XianfanSocietySim.valid(society),"regional stocks and cargo remain valid")
    var exhausted: Dictionary=XianfanSocietySim.initial_state(0)
    exhausted["regions"]["城"]["treasury"]=12
    XianfanSocietySim.advance_to(exhausted,8*60)
    var trip: Dictionary=exhausted["caravans"][0]
    check(str(trip["state"])=="road","low treasury initially allows shipment")
    exhausted["regions"]["城"]["treasury"]=0
    exhausted["regions"]["城"]["stock"]["粮"]=0  # no chance of NPC food purchases replenishing buyer cash before arrival
    XianfanSocietySim.advance_to(exhausted,16*60)
    check(str(trip["state"])=="returning","buyer default starts physical return")
    check(int(trip["qty"])>0,"goods are not destroyed by failed trade")
    XianfanSocietySim.advance_to(exhausted,24*60)
    check(str(trip["state"])=="idle" and int(trip["qty"])==0,
        "returned goods unloaded in starting village")
    check(int(exhausted["agents"]["孟远川"]["cargo"]["鱼"])==0,
        "no imaginary inventory remains after failed contract")
    check(XianfanSocietySim.valid(exhausted),"default never creates negative resources")
    var paused: Dictionary=society.duplicate(true)
    var chunked: Dictionary=society.duplicate(true)
    XianfanSocietySim.advance_to(paused,12*24*60)
    XianfanSocietySim.advance_to(chunked,7*24*60)
    XianfanSocietySim.advance_to(chunked,12*24*60)
    check(JSON.stringify(paused)==JSON.stringify(chunked),"offline catch-up deterministic including trade/relationships")
    check(XianfanSocietySim.valid(paused),"multiple days of trading never overdraft")
    check(_total_cash(paused)==money,"zero-money-creation holds across twelve days")
    var world:=XianfanWorld.new()
    world.new_game()
    var start_hour:=int(world._clock())
    var walk:=world.act("去村口")
    check(walk.contains("街口"),"player can physically visit village social market")
    check(str(world.data["place"])=="石桥村·街口","visit moves to actual market place")
    check(world._clock()-start_hour==12,"short village walk costs 12 minutes, not intercity travel")
    var prices:=world.act("查看物价")
    check(prices.contains("实时牌价"),"player can inspect real local demand and supply prices")
    var face:=world.act("问赵阿禾最近忙什么")
    check(not face.contains("暂不支持"),"player may speak with a public farmer by name")
    check(world.last_channel=="对话","public NPC conversation appears in conversation channel")
    var retreat:=world.act("回家")
    check(str(world.data["place"])=="石桥村·家中","player returns home")
    check(retreat.contains("家中"),"return trip is local")
    var before: int=world.data["npc"].size()
    world.passive_time(720)
    world.passive_time(720)
    var dossier: Dictionary={}
    for n in world.npcs_status():
        if str(n["name"])=="孟远川": dossier=n
    check(world.data["npc"].size()>=before,"social registry persists after clock advances")
    check(dossier.has("household") and dossier.has("cargo"),"NPC popup source includes family and business ledger")
    var smart: Dictionary=world.ai_context("孟远川","今天运了什么货")
    check(smart.get("npc",{}).has("孟远川"),"model gets current true character facts")
    check(smart.get("npc",{}).size()<=7,"context excludes irrelevant NPCs")
    check(smart.has("market_prices"),"model knows real supply-backed prices")
    check(smart.has("society_events"),"model knows actual trade outcomes")
    print("XIANFAN SOCIAL DEPTH TESTS PASS" if problems.is_empty() else "XIANFAN SOCIAL DEPTH TESTS FAILED")
    quit(0 if problems.is_empty() else 1)
