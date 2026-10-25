extends SceneTree
var errors: Array[String]=[]
func check(ok: bool, msg: String) -> void:
    if not ok: errors.append(msg)
func _initialize() -> void:
    call_deferred("_go")
func _go() -> void:
    var game:=XianfanWorld.new()
    game.new_game()
    var root_hash:=str(game.data["root_commitment"])
    var original_player_items: Dictionary=game.data["items"].duplicate(true)
    var society: Dictionary=game.data["society"]
    var immortal: Dictionary=society.get("cultivation_world",{})
    check(XianfanImmortalSociety.valid(society),"New immortal society must have valid nonnegative resources")
    check(immortal.get("agents",{}).size()==12,"Twelve seeded autonomous cultivator and apprentice identities")
    check(str(game.data["root"])=="未检测" and str(game.data["root_commitment"])==root_hash,
        "Existing player root must never be rerolled or leaked")
    var example: Dictionary=immortal["agents"]["罗观尘"]
    check(str(example.get("root",""))=="三灵根" and bool(example.get("root_verified",false)),
        "Cultivator root comes from its own registered prior testing, not the player's secret roll")
    check(int(example["realm_level"])==2,"Initial realm must be grounded in world generation")
    check(game.data["npc"].has("罗观尘"),"Cultivators integrated into NPC registry with real IDs")
    game.data["place"]="青云山门·山门外"
    game.data["minute"]=480
    var money_before:=int(game.data["money"])
    var sect_treasury_before:=int(immortal["regions"]["青云山门"]["copper"])
    var stamina_before:=int(game.data["stamina"])
    var work_result:=game.act("做山门杂役")
    check(work_result.contains("2文"),"An actual local sect job returns an audited result")
    check(int(game.data["money"])==money_before+2 and
        int(immortal["regions"]["青云山门"]["copper"])==sect_treasury_before-2,
        "Mortal player wage must transfer actual coins, never mint money")
    check(int(game.data["stamina"])==stamina_before-5,"Work must cost player stamina")
    check(game.at_same_place("罗观尘"),"Cultivator can only speak when actually at same place")
    var answer: Dictionary=game.authored_dialogue("罗观尘","你是什么灵根？")
    check(bool(answer.get("covered",false)) and str(answer.get("reply","")).contains("三灵根"),
        "Private verified NPC root must be answered from its real record, not invented by 8B")
    var reply: Dictionary=game.authored_dialogue("罗观尘","丹药材料从哪里来？")
    check(bool(reply.get("covered",false)) and str(reply.get("voice",""))=="cultivator",
        "Cultivation topics must have a distinct sect disciple voice")
    var start_day:=int(game.data["day"])
    var before_practice:=int(immortal["total_practice"])
    var stock: Dictionary=immortal["regions"]["青云山门"]["stock"]
    var made_pills:=int(immortal["total_pills"])
    game.passive_time(720)
    game.passive_time(720)
    check(int(game.data["day"])==start_day+1,"World progresses exactly one day across two offline batches")
    check(int(immortal["total_practice"])>before_practice,
        "NPCs should meditate autonomously while player is doing nothing")
    check(int(immortal["total_pills"])>=made_pills,
        "Real alchemy yields no negative product")
    check(XianfanImmortalSociety.valid(society),"Alchemy, ore and harvest preserve nonnegative stocks")
    check(str(game.data["root_commitment"])==root_hash and game.data["items"]==original_player_items,
        "Background cultivation cannot grant the player a new root, items or free spiritual resources")
    var already:=XianfanImmortalSociety.advance_to(society,game._clock())
    check(already==0,"Replaying same day must not duplicate sect production or practice")
    var original_level:=int(example["realm_level"])
    example["root_verified"]=false
    example["progress"]=999999.0
    example["energy"]=100
    game.passive_time(720)
    game.passive_time(720)
    check(int(example["realm_level"])==original_level,
        "Unverified root disallows fabricated breakthroughs regardless of accumulated experience")
    check(game.world_chronicle!=null and game.world_chronicle.number_of_facts()>0,
        "Sect production and practice must leave durable independently indexed fact records")
    check(int(immortal["total_food_bought"])>0,"Real food purchased from town")
    var shipments: Array=immortal.get("shipments",[])
    check(shipments.size()>0,"Goods must remain in transit during delivery")
    if not shipments.is_empty():
        var record: Dictionary=shipments.back()
        var carrier:=str(record.get("courier",""))
        check(society["civic_agents"].has(carrier),"Registered porter employed")
        game.passive_time(120)
        check(str(game.data["npc"].get(carrier,{}).get("place",""))=="临安官道","Porter uses road")
        game.passive_time(600)
        game.passive_time(720)
        check(immortal.get("shipments",[]).is_empty(),"Delivery must complete after transit")
    var review:=game.immortal_status()
    check(review.contains("灵草") and review.contains("丹药") and review.contains("风险"),
        "Location-locked report displays rule-authenticated immortal economy")
    game.data["place"]="石桥村·家中"
    check(not game.immortal_status().contains("基础丹药"),
        "Player at home cannot inspect privileged sect stock across the county")
    check(not game.at_same_place("罗观尘"),"No remote direct chat")
    if errors.is_empty():
        print("IMMORTAL SOCIETY TESTS PASS: autonomous practice, conservation, verified roots, location and provenance")
        quit(0)
    else:
        for error in errors: push_error("IMMORTAL SOCIETY FAILURE: "+error)
        quit(1)
