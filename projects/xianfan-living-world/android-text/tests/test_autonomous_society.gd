extends SceneTree
var problems: Array[String] = []
func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, name: String) -> void:
    if not ok:
        problems.append(name)
        push_error("SOCIETY TEST FAILURE: "+name)

func _sum_money(s: Dictionary) -> int:
    var sum:=0
    for region in s["regions"].values():
        sum+=int(region["treasury"])
    for actor in s["agents"].values():
        sum+=int(actor["coins"])
    for person in s.get("civic_agents",{}).values():
        sum+=int(person.get("coins",0))
    return sum

func _all_goods_positive(s: Dictionary) -> bool:
    if not XianfanSocietySim.valid(s): return false
    for region in s["regions"].values():
        for stock in region["stock"].values():
            if int(stock)<0: return false
        for wild in region["wild"].values():
            if int(wild)<0: return false
    return true

func _run() -> void:
    var game:=XianfanWorld.new()
    game.new_game()
    check(game.data.has("society"),"society exists in full native game state")
    var initial: Dictionary=game.data["society"].duplicate(true)
    check(initial["agents"].size()==24,"24 distinct named actors")
    check(game.data["npc"].has("赵阿禾"),"public NPC also integrated in registry")
    var first_money:=_sum_money(initial)
    var player_money:=int(game.data["money"])
    var player_items: Dictionary=game.data["items"].duplicate(true)
    var player_turn:=int(game.data["turn"])
    var base_hour:=int(game._clock()/60)
    var a:=initial.duplicate(true)
    var b:=initial.duplicate(true)
    var from_time:=int(game._clock())
    var final_minutes: int=(base_hour+81)*60
    XianfanSocietySim.advance_to(a,final_minutes)
    XianfanSocietySim.advance_to(b,(base_hour+23)*60)
    XianfanSocietySim.advance_to(b,(base_hour+50)*60)
    XianfanSocietySim.advance_to(b,final_minutes)
    check(JSON.stringify(a)==JSON.stringify(b),"determinism: same world across step grouping")
    check(_sum_money(a)==first_money,"money moves between actual NPCs and public treasury only")
    check(_all_goods_positive(a),"resources and NPC possessions remain nonnegative")
    check(int(a["total_steps"])>=81,"offscreen occupations run without player actions")
    check(int(a["total_production"])>0,"people create real supplies through labor")
    check(int(a["total_trades"])>0,"food trade occurs without player visits")
    check(int(a["total_consumption"])>0,"NPCs eat daily")
    check(int(a["total_wages"])>0,"services/workers are paid from treasury")
    check(a["agents"]["唐知行"]["work_done"]>0,"farmer has autonomous work")
    check(a["agents"]["严拱辰"]["work_done"]>0,"guard has autonomous duty")
    check(a["agents"]["石满仓"]["work_done"]>0,"fisher can work within natural limits")
    var old_wood:=int(initial["regions"]["村"]["wild"]["木林"])
    check(old_wood>0 and int(a["regions"]["村"]["wild"]["木林"])<=int(a["regions"]["村"]["cap"]["木林"]),"bounded forest regrowth")

    check(game.passive_time(120)==120,"real-time world clock moves the simulation forward")
    check(game._clock()==from_time+120,"clock moved by exactly two in-game hours")
    check(int(game.data["turn"])==player_turn,"background world time does not consume player turn")
    check(int(game.data["money"])==player_money,"society activity does not mint player's coins")
    check(game.data["items"]==player_items,"society does not fabricate items into backpack")
    check(game.data["society"]["last_hour"]==int(game._clock()/60),"society caught up to world hour")
    var status:=game.society_status()
    check(status.contains("24名持续演算"),"view reports real active NPC count")
    check(status.contains("公共钱库"),"economy ledger visible to user")

    game.data["place"]="临安县城·东市"
    var city: Dictionary=game.data["society"]["regions"]["城"]
    var balance: int=game.data["money"]+_sum_money(game.data["society"])
    var city_grain:=int(city["stock"]["粮"])
    var bought:=game.act("买粗粮")
    check(bought.contains("买下"),"player can buy real society food")
    check(game.data["items"].get("粗粮",0)>=1,"purchased food becomes a physical inventory item")
    check(int(city["stock"]["粮"])==city_grain-1,"market purchase decrements real public stock")
    check(int(game.data["money"])+_sum_money(game.data["society"])==balance,"player purchase conserves combined money")
    var fish_before:=int(city["stock"]["鱼"])
    var sold:=game.act("卖一条鱼")
    check(sold.contains("3文"),"player can sell real fish into society market")
    check(int(city["stock"]["鱼"])==fish_before+1,"sold fish enters shared city supply")
    check(int(game.data["money"])+_sum_money(game.data["society"])==balance,"player sale conserves money")
    var grain_before:=int(city["stock"]["粮"])
    var wage:=game.act("做零工")
    check(wage.contains("两文"),"player can work alongside NPCs for wages")
    check(int(city["stock"]["粮"])>=grain_before+2,"player labor produces accounted grain")
    check(int(game.data["money"])+_sum_money(game.data["society"])==balance,"paid labor transfers wages without minting money")

    var loaded:=XianfanWorld.new()
    check(int(loaded.data["society"]["last_hour"])==int(game.data["society"]["last_hour"]),"society hour persists through save")
    check(int(loaded.data["society"]["total_steps"])==int(game.data["society"]["total_steps"]),"NPC simulation outcomes persist through reload")
    var nearby: Array=XianfanSocietySim.near_people(a,"临安县城·东市")
    check(nearby.size()>0,"citizens have real market locations")
    for n in nearby:
        check(loaded.data["npc"].has(str(n["name"])),"every public actor has NPC ID and popup source")
    # No resource or money source is allowed other than bounded ecological
    # regrowth and founding initial reserves.
    var dry: Dictionary=a.duplicate(true)
    for key in dry["regions"]:
        dry["regions"][key]["treasury"]=0
    var money_before:=_sum_money(dry)
    XianfanSocietySim.advance_to(dry,final_minutes+720)
    check(_sum_money(dry)==money_before,"empty treasuries cannot create wages out of thin air")
    check(_all_goods_positive(dry),"shortage does not produce negative resources")

    print("XIANFAN AUTONOMOUS SOCIETY TESTS PASS" if problems.is_empty() else "XIANFAN AUTONOMOUS SOCIETY TESTS FAILED")
    quit(0 if problems.is_empty() else 1)
