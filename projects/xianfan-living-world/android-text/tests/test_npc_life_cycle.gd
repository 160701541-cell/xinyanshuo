extends SceneTree
var errors: Array[String]=[]

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, label: String) -> void:
    if not ok:
        errors.append(label)
        push_error("LIFECYCLE TEST FAILURE: "+label)

func all_coins(sim: Dictionary) -> int:
    var value:=0
    for region in sim["regions"].values():
        value+=int(region["treasury"])
    for actor in sim["agents"].values():
        value+=int(actor["coins"])
    for person in sim.get("civic_agents",{}).values():
        value+=int(person.get("coins",0))
    return value

func _run() -> void:
    var state: Dictionary=XianfanSocietySim.initial_state(0)
    var initial: Dictionary=state.duplicate(true)
    var student: Dictionary=state["agents"]["顾朝闻"]
    check(student["job"]=="学徒","genuine apprentice has own job")
    check(int(student["training"])==0,"apprenticeship begins at zero actual hours")
    var started_cash:=all_coins(state)
    XianfanSocietySim.advance_to(state,30*24*60)
    check(str(student.get("mentor",""))=="孔铁山","apprentice finds same-village skilled craftsperson")
    check(int(student.get("training",0))>=24,"apprenticeship requires 24 valid supervised work shifts")
    check(str(student["job"])=="匠人","apprentice may actually change career")
    check(int(state["career_changes"])>=1,"career changes are tracked")
    check(int(student.get("skills",{}).get("匠人",0))>=24,"new career grounded in accumulated training")
    check(state.get("chronicle",[]).size()>0,"long-term milestones persist")
    var was_taught:=false
    for entry in state.get("chronicle",[]):
        if str(entry.get("npc",""))=="顾朝闻" and str(entry.get("category",""))=="出师":
            was_taught=true
    check(was_taught,"career milestone has actual identity and time")
    check(XianfanSocietySim.valid(state),"career switch cannot break conservation ledger")
    check(all_coins(state)==started_cash,"skill progression and wages conserve copper")

    var aged: Dictionary=initial.duplicate(true)
    var farmer: Dictionary=aged["agents"]["唐知行"]
    var age0:=int(farmer["age"])
    farmer["age_anchor_day"]=-359
    farmer["life_span"]=99
    XianfanSocietySim.advance_to(aged,20*60)
    check(int(farmer["age"])==age0+1,"NPC grows older as independent world clock advances")
    check(int(farmer["age_anchor_day"])==1,"one-year age cursor prevents repeated aging")

    var dying: Dictionary=initial.duplicate(true)
    var deceased: Dictionary=dying["agents"]["唐知行"]
    var group: Array=dying["households"][str(deceased["household"])]
    var heir_name: String=""
    for who in group:
        if str(who)!=str(deceased["name"]):
            heir_name=str(who)
            break
    check(not heir_name.is_empty(),"at least one co-resident inheritor")
    var heir: Dictionary=dying["agents"][heir_name]
    var funds_before:=all_coins(dying)
    deceased["health"]=0
    deceased["coins"]=41
    deceased["rations"]=9
    var prior_heir_money:=int(heir["coins"])
    var prior_heir_food:=int(heir["rations"])
    # Force hour-20 lifecycle without simulating other household activities,
    # so exact inheritance can be isolated from NPC meals/wages.
    XianfanSocietySim._daily_lifecycle(dying,20)
    check(not bool(deceased.get("alive",true)),"irreversible NPC death recorded")
    check(str(deceased["place"])=="故人名录","deceased no longer works at former locations")
    check(int(deceased["coins"])==0 and int(deceased["rations"])==0,"dead body retains no spendable assets")
    check(int(heir["coins"])==prior_heir_money+41,"actual currency transferred to surviving co-resident")
    check(int(heir["rations"])==prior_heir_food+9,"actual food transferred to heir")
    check(dying.get("deaths",0)==1,"death accounted exactly once")
    var last_death: Dictionary=deceased["biography"].back()
    check(str(last_death["category"])=="死亡","death event preserved in person's original biography")
    check(XianfanSocietySim.near_people(dying,str(deceased["home"])).filter(
        func(n): return str(n.get("name",""))=="唐知行").size()==0,"dead NPC never appears as living")
    check(all_coins(dying)==funds_before+41-int(initial["agents"]["唐知行"]["coins"]),
        "death moves only preexisting cash; correction matches test top-up")
    XianfanSocietySim._daily_lifecycle(dying,44)
    check(int(dying["deaths"])==1,"cannot die again tomorrow")
    check(XianfanSocietySim.valid(dying),"inheritance leaves a valid ledger")

    var one: Dictionary=initial.duplicate(true)
    var another: Dictionary=initial.duplicate(true)
    XianfanSocietySim.advance_to(one,42*24*60)
    XianfanSocietySim.advance_to(another,13*24*60)
    XianfanSocietySim.advance_to(another,42*24*60)
    check(JSON.stringify(one)==JSON.stringify(another),"deterministic professional life under offline catch-up")

    var world:=XianfanWorld.new()
    world.new_game()
    var citizen: Dictionary=world.data["society"]["agents"]["赵阿禾"]
    citizen["health"]=0
    var needed_hour:=world._clock()
    XianfanSocietySim._daily_lifecycle(world.data["society"],int(needed_hour/60))
    world._sync_society_people()
    world._archive_society_milestones()
    check(not bool(world.data["npc"]["赵阿禾"].get("alive",true)),"main NPC registry reflects authentic death")
    check(str(world.record_ai_dialogue("赵阿禾","你还好吗？","我在这里","local-gguf")).contains("离世"),
        "AI is barred from simulating live speech from the deceased")
    var memory: Array=world.memory_store.read_all("赵阿禾")
    var found_end:=false
    for entry in memory:
        if str(entry.get("goal",""))=="死亡" and str(entry.get("type",""))=="life":
            found_end=true
    check(found_end,"death milestone mirrored into durable per-person local memory")
    world.save()
    var reopened:=XianfanWorld.new()
    check(not bool(reopened.data["npc"]["赵阿禾"].get("alive",true)),
        "NPC death survives reopening the same game save")
    check(reopened.memory_store.read_all("赵阿禾").size()==memory.size(),
        "resume does not duplicate permanent biography records")

    print("XIANFAN NPC LIFE CYCLE TESTS PASS" if errors.is_empty() else "XIANFAN NPC LIFE CYCLE TESTS FAILED")
    quit(0 if errors.is_empty() else 1)
