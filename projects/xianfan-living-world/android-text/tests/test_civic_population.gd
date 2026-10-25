extends SceneTree
var problems: Array[String]=[]

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, name: String) -> void:
    if not ok:
        problems.append(name)
        push_error("CIVIC POPULATION FAILURE: "+name)

func _all_coins(society: Dictionary) -> int:
    var total:=0
    for region in society.get("regions",{}).values():
        total+=int(region.get("treasury",0))
    for person in society.get("agents",{}).values():
        total+=int(person.get("coins",0))
    for person in society.get("civic_agents",{}).values():
        total+=int(person.get("coins",0))
    return total

func _run() -> void:
    var roles: Array[Dictionary]=XianfanCivicPopulation.job_catalog()
    check(roles.size()>=160,"at least 160 independently enumerated occupations")
    var sector_set: Dictionary={}
    var role_set: Dictionary={}
    for card in roles:
        sector_set[str(card["sector"])]=true
        role_set[str(card["job"])]=true
    check(role_set.size()==roles.size(),"all professions have unambiguous identities")
    check(sector_set.size()>=14,"at least 14 economic, administrative and spiritual sectors")
    var social: Dictionary=XianfanSocietySim.initial_state(0)
    check(social["agents"].size()==24,"prior 24 named NPCs retain persistent records")
    var population: Dictionary=social.get("civic_agents",{})
    check(population.size()==roles.size()*2,"each occupation has two individually named citizens")
    var names: Dictionary={}
    var ids: Dictionary={}
    var sectors: Dictionary={}
    var classes: Dictionary={}
    for who in population:
        var npc: Dictionary=population[who]
        names[who]=true
        ids[str(npc["id"])]=true
        sectors[str(npc["sector"])]=true
        classes[str(npc["standing"])]=true
        check(npc.has("faction") and npc.has("home") and npc.has("job"),
            "every registered citizen has organization, home and profession")
        check(str(npc.get("root",""))=="待鉴定","unverified cultivator has no invented spiritual breakthrough")
    check(names.size()==population.size() and ids.size()==population.size(),"stable unique name and person ID for each citizen")
    check(classes.size()>=6,"genuinely different social strata not merely different titles")
    check(sectors.has("修行外围") and sectors.has("官府军政"),"sect periphery and officials coexist with laypeople")
    check(XianfanCivicPopulation.roster(social,"官府军政",0,12)["size"]>=24,"official sector has real registered citizens")
    check(XianfanCivicPopulation.roster(social,"修行外围",0,12)["size"]>=24,"sect support careers are named without false cultivation")
    var first: Dictionary=XianfanCivicPopulation.roster(social,"",0,12)
    var second: Dictionary=XianfanCivicPopulation.roster(social,"",1,12)
    check(int(first["size"])==population.size() and second["entries"].size()>0,"paged registration browses entire population")

    var hardship: Dictionary=social.duplicate(true)
    var unemployed: Dictionary={}
    for n in hardship["civic_agents"].values():
        if str(n.get("job",""))=="无业人":
            unemployed=n
            break
    check(not unemployed.is_empty(),"named unemployed people are not classified as salaried servants")
    if not unemployed.is_empty():
        check(str(unemployed["standing"])=="失业居民","social status is separate from occupation")
        var region: Dictionary=hardship["regions"][str(unemployed["region"])]
        unemployed["coins"]=0
        unemployed["rations"]=0
        var before_reserve:=int(region["stock"]["粮"])
        var before_treasury:=int(region["treasury"])
        var credited:=XianfanCivicPopulation._produce(hardship,unemployed,3)
        check(not credited,"unemployed person cannot magically earn public wages")
        check(int(region["treasury"])==before_treasury,"unemployed work doesn't drain salaries")
        XianfanCivicPopulation._eat(hardship,unemployed,3)
        check(int(region["stock"]["粮"])==before_reserve-1,
            "public relief is a real debited food ration, not decorative storytelling")
        check(int(hardship.get("civic_relief",0))==1,"public granary relief recorded")
    var original_cash:=_all_coins(social)
    var a: Dictionary=social.duplicate(true)
    var other: Dictionary=social.duplicate(true)
    XianfanSocietySim.advance_to(a,12*24*60)
    XianfanSocietySim.advance_to(other,6*24*60)
    XianfanSocietySim.advance_to(other,12*24*60)
    check(JSON.stringify(a)==JSON.stringify(other),"daily cohort simulation exactly reproducible under chunked time")
    check(XianfanSocietySim.valid(a),"civic money/rations and ecological stock never become negative")
    check(_all_coins(a)==original_cash,"all citizens and treasuries conserve cash, no wage minting")
    check(int(a.get("civic_total_work",0))>100,"background residents actually perform time-limited daily work")
    check(int(a.get("civic_total_trade",0))>0,"citizens buy actual food against warehouse and treasury")
    var first_day: int=int(social.get("civic_last_day",0))
    check(int(a.get("civic_last_day",0))>first_day,"low-frequency population simulation advances independently")
    var old_citizen: Dictionary=population.values()[0]
    var exemplar:=str(old_citizen["name"])
    check(int(a["civic_agents"][exemplar]["work_done"])>0,"individual non-core citizen has real recorded work")
    check(int(a["civic_agents"][exemplar]["coins"])>=0,"civilian personal money is not a decorative string")
    check(a["civic_agents"][exemplar]["skills"].has(str(old_citizen["job"])),"profession progression lives in the citizen's record")
    var crowd:=XianfanCivicPopulation.nearby(a,"临安县城·东市",8)
    check(crowd.size()>4,"visible named traders/craftsmen present at real work locations")

    var world:=XianfanWorld.new()
    world.new_game()
    check(world.data.get("npc",{}).size()>=population.size()+24,"all registered people accessible through NPC UI identity layer")
    check(world.society_status().contains("多身份居民登记"),"world screen shows population sectors and roles")
    var civil_name: String=exemplar
    var citizen: Dictionary=world.data["npc"].get(civil_name,{})
    check(citizen.has("social_class") and citizen.has("faction"),"NPC popup access to social standing and faction")
    var loaded_citizens:=world.society_roster("",0)
    check(int(loaded_citizens.get("size",0))==population.size(),"world exposes real browsable citizen register")
    check(world.society_sectors().size()>=14,"all industry sectors reachable in Android roster menu")
    var ctx: Dictionary=world.ai_context(civil_name,"你今天做什么营生")
    check(ctx.get("npc",{}).has(civil_name),"local model receives a chosen person's exact factual identity")
    check(ctx.get("npc",{}).size()<=7,"336 citizens not blindly stuffed into 8B context")

    world.passive_time(720)
    world.passive_time(720)
    check(world.data["society"]["civic_last_day"]>=first_day,"game clock powers citizen life without player input")
    var record: Dictionary=world.data["society"]["civic_agents"][civil_name]
    check(int(record["coins"])>=0,"personal finances survived background time")
    world.save()
    var reopened:=XianfanWorld.new()
    check(reopened.data["society"]["civic_agents"].size()==population.size(),"all citizens survive save and reload")
    check(reopened.data["society"]["civic_agents"][civil_name]["id"]==record["id"],"independent identity stable across sessions")
    check(int(reopened.data["society"]["civic_agents"][civil_name]["work_done"])==int(record["work_done"]),
        "reopening doesn't reset simulated personal history")

    print("XIANFAN CIVIC POPULATION TESTS PASS" if problems.is_empty() else "XIANFAN CIVIC POPULATION TESTS FAILED")
    quit(0 if problems.is_empty() else 1)
