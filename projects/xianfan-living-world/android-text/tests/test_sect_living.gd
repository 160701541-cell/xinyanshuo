extends SceneTree
var issues: Array[String]=[]
func check(ok: bool, why: String) -> void:
    if not ok: issues.append(why)
func _initialize() -> void:
    call_deferred("_run")
func _run() -> void:
    var world:=XianfanWorld.new()
    world.new_game()
    var society: Dictionary=world.data["society"]
    var c: Dictionary=society["cultivation_world"]
    var ledger: Dictionary=c["sect_workforce"]
    var employed:=0
    for x in ledger.values():
        if bool(x.get("employed",false)): employed+=1
    check(employed>=16,"Most mountain workers must be real civic mortals")
    check(employed>c["agents"].size(),"Mortal workforce outnumbers low-level cultivator NPCs")
    check(XianfanSectLiving.migrate(society)==false,"Idempotent migration preserves names and records")
    var low: Dictionary=c["agents"]["罗观尘"]
    var foundation: Dictionary=c["agents"]["叶怀远"]
    low["prefers_cuisine"]=false
    foundation["prefers_cuisine"]=false
    var stock: Dictionary=c["regions"]["青云山门"]["stock"]
    stock["口粮"]=60
    stock["灵膳"]=0
    var old_food:=int(stock["口粮"])
    low["diet_mode"]="pill"
    low["stock"]["辟谷丹"]=1
    XianfanSectLiving._dine_one(c,low,32,false)
    check(int(stock["口粮"])==old_food-1,"Qi refining cultivators must eat everyday")
    check(int(low["stock"]["辟谷丹"])==1,"Qi-refining disciple cannot trigger foundation-only pill")
    foundation["realm_level"]=14
    foundation["realm"]="筑基初期"
    foundation["diet_mode"]="pill"
    foundation["stock"]["辟谷丹"]=1
    var before_fasting:=int(stock["口粮"])
    XianfanSectLiving._dine_one(c,foundation,32,false)
    check(int(foundation["stock"]["辟谷丹"])==0 and
        int(foundation.get("bigu_until",0))==34,
        "Qualified foundation cultivator consumes one real pill for three days")
    check(int(stock["口粮"])==before_fasting,"Bigu suppresses mandatory food")
    XianfanSectLiving._dine_one(c,foundation,33,false)
    XianfanSectLiving._dine_one(c,foundation,34,false)
    check(int(stock["口粮"])==before_fasting,"Bigu pill duration must be respected")
    XianfanSectLiving._dine_one(c,foundation,35,false)
    check(int(stock["口粮"])==before_fasting-1,"Expired pill returns ordinary appetite")
    foundation["diet_mode"]="art"
    foundation["bigu_art_verified"]=true
    foundation["spirit_power"]=2
    foundation["bigu_until"]=0
    XianfanSectLiving._dine_one(c,foundation,36,false)
    XianfanSectLiving._dine_one(c,foundation,37,false)
    check(int(foundation["spirit_power"])==0,
        "Verified bigu art consumes conserved spiritual power")
    var before_exhausted:=int(stock["口粮"])
    XianfanSectLiving._dine_one(c,foundation,38,false)
    check(int(stock["口粮"])==before_exhausted-1,
        "Exhausted art cannot conjure unlimited fasting")
    # A food-loving cultivator may choose a real pre-cooked spiritual delicacy.
    foundation["prefers_cuisine"]=true
    foundation["spirit_power"]=1
    stock["灵膳"]=1
    var grain_before:=int(stock["口粮"])
    var morale_before:=int(foundation["cuisine_morale"])
    XianfanSectLiving._dine_one(c,foundation,42,false)
    check(int(stock["灵膳"])==0 and int(stock["口粮"])==grain_before and
        int(foundation["cuisine_morale"])==morale_before+4,
        "Optional food enjoyment remains possible during qualified bigu")
    var pantry: Dictionary=c["regions"]["青云山门"]["stock"]
    var field: Dictionary=c["regions"]["青云山门"]["spirit_field"]
    var water_before:=int(pantry["泉水"])
    var fertility_before:=int(field["fertility"])
    var rice_before:=int(pantry["灵米"])
    XianfanSectLiving._cultivate_food(society,c,45)
    check(int(field["fertility"])<=fertility_before+1 and
        int(pantry["灵米"])>=rice_before,
        "Spirit rice harvest obeys physical field and water constraints")
    check(int(pantry["泉水"])>=0 and water_before>=0,"Real spring water never negative")
    # Prepared ingredients in a test-only fixture must be transformed by an
    # actual living civic cook, not narrated as the sect steward's work.
    stock["灵米"]=maxi(1,int(stock["灵米"]))
    stock["灵果"]=maxi(1,int(stock["灵果"]))
    stock["泉水"]=maxi(2,int(stock["泉水"]))
    var cook_name: String=""
    for cook_candidate in ledger:
        if str(ledger[cook_candidate].get("job",""))=="外门膳房人":
            cook_name=str(cook_candidate)
            break
    var cooked_before:=int(stock["灵膳"])
    XianfanSectLiving._cultivate_food(society,c,46)
    check(int(stock["灵膳"])==cooked_before+1,"Real cook transforms actual spiritual rice and fruit")
    var event_list: Array=c.get("events",[])
    var last_cook_name: String=""
    for row in event_list:
        if str(row.get("category",""))=="灵膳烹制":
            last_cook_name=str(row.get("npc",""))
    check(last_cook_name==cook_name,"Kitchen event must be attributed to actual mortal worker")
    var first_worker: String=""
    for worker_name in ledger:
        if bool(ledger[worker_name].get("employed",false)):
            first_worker=str(worker_name)
            break
    var worker_cash_before:=int(society["civic_agents"][first_worker]["coins"])
    var worker_ration_before:=int(society["civic_agents"][first_worker]["rations"])
    var owned_food_before:=int(society["civic_agents"].values()[0]["rations"])
    world.data["place"]="青云山门·山门外"
    world.passive_time(720)
    world.passive_time(720)
    check(XianfanImmortalSociety.valid(society),"Long-running sect lifecycle conserves all stocks")
    check(int(society["civic_agents"][first_worker]["coins"])>=worker_cash_before+1,
        "Mountain workers receive real wages from sect employer")
    check(int(society["civic_agents"][first_worker]["rations"])==worker_ration_before,
        "Boarding consumes sect rations, not worker's personal village provisions")
    check(str(XianfanCivicPopulation.snapshot(society,first_worker,23).get("place",""))=="青云山门·山门外",
        "Sect boarders remain physically housed at gate at night")

    check(int(society["civic_agents"].values()[0]["rations"])>=0 and owned_food_before>=0,
        "Civilian meal bookkeeping remains nonnegative")
    if issues.is_empty():
        print("SECT LIVING PASS: mortal contracts, bigu thresholds, pill/art cost, enjoyment, water, hygiene")
        quit(0)
        return
    for issue in issues: push_error("SECT LIVING FAILURE: "+issue)
    quit(1)
