extends RefCounted
class_name XianfanSectLiving

# Independent bodily-life and food-production ledger for immortal + mortal
# sect residents. Default is full human metabolism, not automatic bigu.
# Real cultivation may reduce basic needs; pleasure dining stays optional.
const SCHEMA := 1
const RULES := "res://data/sect_living_v1.json"
const MORTAL_JOBS := ["灵田杂役","书阁抄录人","练功场杂役","丹房童子",
    "灵兽饲养人","灵植学徒","法器修缮人","外门膳房人","山门脚夫"]
const NOVICE_JOBS := ["寻仙少年","引气旁听生"]
const REQUIRES_FOUNDATION := 14
const PILL_DURATION := 3
const ART_SPIRIT_PER_DAY := 1

static func _init_person(person: Dictionary) -> void:
    if not person.has("diet_mode"): person["diet_mode"]="ordinary"
    if not person.has("bigu_until"): person["bigu_until"]=0
    if not person.has("bigu_art_verified"): person["bigu_art_verified"]=false
    if not person.has("spirit_power"): person["spirit_power"]=0
    if not person.has("physiology"):
        person["physiology"]={"toilet_need":0,"hygiene":100,"last_meal_day":0,
            "bigu_today":false,"last_hygiene_day":0}
    if not person.has("cuisine_morale"): person["cuisine_morale"]=0
    if not person.has("prefers_cuisine"):
        person["prefers_cuisine"]=str(person.get("id","")).sha256_text().substr(0,1) in ["0","3","6","9","c"]

static func migrate(society: Dictionary) -> bool:
    var c: Dictionary=society.get("cultivation_world",{})
    if c.is_empty(): return false
    var changed:=false
    if not c.has("daily_dining"):
        c["daily_dining"]={"rations":0,"mortal_meals":0,"bigu_days":0,
            "sanitation_days":0,"missed_meals":0,"delicacy_meals":0}
        changed=true
    if not c.has("sect_workforce"):
        c["sect_workforce"]={}
        changed=true
    var mountain: Dictionary=c["regions"]["青云山门"]
    var stock: Dictionary=mountain["stock"]
    for name in ["灵米","灵果","泉水","灵膳","辟谷丹"]:
        if not stock.has(name):
            stock[name]=0
            changed=true
    if not mountain.has("spirit_field"):
        mountain["spirit_field"]={"fertility":54,"cap":100,"planted":true}
        changed=true
    if not mountain.has("spirit_orchard"):
        mountain["spirit_orchard"]={"trees":3,"fruiting_interval":7}
        changed=true
    if not mountain.has("spring"):
        mountain["spring"]={"daily_flow":35,"capacity":120}
        changed=true
    if not mountain.has("latrines"):
        mountain["latrines"]=4
        changed=true
    for person in c.get("agents",{}).values():
        if not person.has("physiology"):
            _init_person(person)
            changed=true
    var roster: Dictionary=c["sect_workforce"]
    for person_name in society.get("civic_agents",{}):
        var person: Dictionary=society["civic_agents"][person_name]
        if str(person.get("sector",""))!="修行外围": continue
        var job:=str(person.get("job",""))
        if job not in MORTAL_JOBS and job not in NOVICE_JOBS: continue
        # Use persistent real civic IDs, never synthetic headcounts.
        if not roster.has(person_name):
            roster[person_name]={"id":str(person["id"]),"name":str(person_name),
                "contract":"外门预备" if job in NOVICE_JOBS else (
                    "山门役仆" if job=="外门膳房人" else "山门雇工"),
                "verified_root":false,"rank":"凡人/未引气",
                "employed":job in MORTAL_JOBS,"job":job}
            changed=true
        # An exterior visitor/aspirant still eats their OWN civilian rations.
        if job in MORTAL_JOBS and bool(roster[person_name].get("employed",false)):
            person["sect_boarding"]=true
            person["sect_contract"]=str(roster[person_name]["contract"])
            if not person.has("physiology"):
                _init_person(person)
                changed=true
    return changed

static func bigu_active(person: Dictionary, day: int) -> bool:
    if int(person.get("realm_level",0))<REQUIRES_FOUNDATION: return false
    if int(person.get("bigu_until",0))>=day: return true
    if str(person.get("diet_mode",""))=="art" and bool(person.get("bigu_art_verified",false)):
        if int(person.get("spirit_power",0))>=ART_SPIRIT_PER_DAY:
            person["spirit_power"]=int(person["spirit_power"])-ART_SPIRIT_PER_DAY
            return true
    if str(person.get("diet_mode",""))=="pill":
        var inventory: Dictionary=person.get("stock",{})
        if int(inventory.get("辟谷丹",0))>0:
            inventory["辟谷丹"]=int(inventory["辟谷丹"])-1
            person["bigu_until"]=day+PILL_DURATION-1
            return true
    return false

static func _log_event(c: Dictionary, actor: Dictionary, day: int, kind: String, detail: String) -> void:
    XianfanImmortalSociety._record(c,actor,day,kind,detail)

static func _cultivate_food(society: Dictionary, c: Dictionary, day: int) -> void:
    var region: Dictionary=c["regions"]["青云山门"]
    var stock: Dictionary=region["stock"]
    var spring: Dictionary=region["spring"]
    stock["泉水"]=mini(int(spring["capacity"]),int(stock["泉水"])+int(spring["daily_flow"]))
    var field: Dictionary=region["spirit_field"]
    field["fertility"]=mini(int(field["cap"]),int(field["fertility"])+1)
    var people: Dictionary=c["agents"]
    if day%3==0 and bool(field["planted"]) and int(field["fertility"])>=3 and int(stock["泉水"])>=2:
        var farmer: Dictionary=people.get("谷若竹",{})
        if bool(farmer.get("alive",false)):
            field["fertility"]=int(field["fertility"])-3
            stock["泉水"]=int(stock["泉水"])-2
            stock["灵米"]=int(stock["灵米"])+2
            _log_event(c,farmer,day,"灵田农事",
                "灵田实耗3份地力与2份泉水，经灵植夫劳作收得2份灵米。")
    if day%int(region["spirit_orchard"]["fruiting_interval"])==0:
        var trees:=int(region["spirit_orchard"].get("trees",0))
        if trees>0:
            stock["灵果"]=int(stock["灵果"])+mini(trees,2)
            var grower: Dictionary=people.get("谷若竹",{})
            if bool(grower.get("alive",false)):
                _log_event(c,grower,day,"灵果采收",
                    "山门有%d株已登记果树成熟，其中采得%d枚灵果入库。" % [trees,mini(trees,2)])
    var chef: Dictionary={}
    for worker_name in c.get("sect_workforce",{}):
        var contract: Dictionary=c["sect_workforce"][worker_name]
        if str(contract.get("job",""))!="外门膳房人" or not bool(contract.get("employed",false)): continue
        var cook: Dictionary=society.get("civic_agents",{}).get(worker_name,{})
        if bool(cook.get("alive",false)):
            chef=cook
            break
    if not chef.is_empty() and int(stock["灵米"])>=1 and int(stock["灵果"])>=1 and int(stock["泉水"])>=1:
        stock["灵米"]=int(stock["灵米"])-1
        stock["灵果"]=int(stock["灵果"])-1
        stock["泉水"]=int(stock["泉水"])-1
        stock["灵膳"]=int(stock["灵膳"])+1
        chef["place"]="青云山门·山门外"
        _log_event(c,chef,day,"灵膳烹制",
            "膳房实耗1份灵米、1枚灵果、1份泉水，亲手做出1份灵米灵果羹并入厨房库存。")

static func _sanitation(c: Dictionary, person: Dictionary, day: int) -> void:
    var physiology: Dictionary=person["physiology"]
    if int(physiology.get("toilet_need",0))<=0: return
    var mountain: Dictionary=c["regions"]["青云山门"]
    var stock: Dictionary=mountain["stock"]
    if int(mountain["latrines"])>0 and int(stock["泉水"])>=1:
        stock["泉水"]=int(stock["泉水"])-1
        physiology["toilet_need"]=0
        physiology["last_hygiene_day"]=day
        physiology["hygiene"]=mini(100,int(physiology["hygiene"])+3)
        c["daily_dining"]["sanitation_days"]=int(c["daily_dining"]["sanitation_days"])+1
    else:
        physiology["hygiene"]=maxi(0,int(physiology["hygiene"])-12)

static func _dine_one(c: Dictionary, person: Dictionary, day: int, is_worker: bool) -> void:
    var region: Dictionary=c["regions"]["青云山门"]
    var stock: Dictionary=region["stock"]
    _init_person(person)
    var physiology: Dictionary=person["physiology"]
    # Workers and low-level cultivators always have normal needs.
    var fasting:=false if is_worker else bigu_active(person,day)
    physiology["bigu_today"]=fasting
    var ate:=false
    # Enjoyment is elective: fasting is not losing one's sense of taste.
    if bool(person.get("prefers_cuisine",false)) and day%7==0 and int(stock["灵膳"])>0:
        stock["灵膳"]=int(stock["灵膳"])-1
        person["cuisine_morale"]=mini(100,int(person.get("cuisine_morale",0))+4)
        c["daily_dining"]["delicacy_meals"]=int(c["daily_dining"]["delicacy_meals"])+1
        ate=true
        if not is_worker:
            _log_event(c,person,day,"品灵膳","自愿享用山门厨房已制成的1份灵米灵果羹；辟谷并不禁止口腹之乐。")
    if fasting:
        c["daily_dining"]["bigu_days"]=int(c["daily_dining"]["bigu_days"])+1
    elif not ate:
        if int(stock["口粮"])>0:
            stock["口粮"]=int(stock["口粮"])-1
            c["total_meals"]=int(c["total_meals"])+1
            c["daily_dining"]["mortal_meals"]=int(c["daily_dining"]["mortal_meals"])+1
            ate=true
        else:
            person["health"]=maxi(0,int(person.get("health",100))-2)
            person["energy"]=maxi(0,int(person.get("energy",80))-8)
            c["daily_dining"]["missed_meals"]=int(c["daily_dining"]["missed_meals"])+1
            person["wish"]="先求温饱，暂缓耗力气的修行"
    if ate:
        physiology["last_meal_day"]=day
        physiology["toilet_need"]=int(physiology["toilet_need"])+1
        _sanitation(c,person,day)
    else:
        # Previously accumulated bodily needs do not disappear merely because
        # the person fasted today.
        _sanitation(c,person,day)
    if int(person["health"])<=0 and bool(person.get("alive",true)):
        person["alive"]=false
        if not is_worker:
            _log_event(c,person,day,"死亡","长期缺粮且无有效辟谷手段，健康归零；真实死亡，停止修炼劳动。")

static func settle(society: Dictionary, c: Dictionary, day: int) -> void:
    migrate(society)
    _cultivate_food(society,c,day)
    for person in c["agents"].values():
        if not bool(person.get("alive",true)) or str(person["station"])!="青云山门": continue
        _dine_one(c,person,day,false)
    for worker_name in c["sect_workforce"]:
        var contract: Dictionary=c["sect_workforce"][worker_name]
        if not bool(contract.get("employed",false)): continue
        var worker: Dictionary=society["civic_agents"].get(worker_name,{})
        if worker.is_empty() or not bool(worker.get("alive",true)): continue
        # A real contracted workday creates a wage liability owed by this sect,
        # never by the village public purse. Wage arrears and resignation persist.
        var mountain: Dictionary=c["regions"]["青云山门"]
        var pay:=mini(1,int(mountain["copper"]))
        mountain["copper"]=int(mountain["copper"])-pay
        worker["coins"]=int(worker["coins"])+pay
        worker["work_done"]=int(worker.get("work_done",0))+1
        society["civic_total_work"]=int(society.get("civic_total_work",0))+1
        var skills: Dictionary=worker.get("skills",{})
        var skill:=str(worker.get("job","役仆"))
        skills[skill]=int(skills.get(skill,0))+1
        worker["skills"]=skills
        if pay<1:
            contract["wage_arrears"]=int(contract.get("wage_arrears",0))+1
            contract["unpaid_days"]=int(contract.get("unpaid_days",0))+1
            if int(contract["unpaid_days"])>=7:
                contract["employed"]=false
                worker["sect_boarding"]=false
                worker["sect_contract"]="因连续欠薪离开山门"
                var steward: Dictionary=c["agents"].get("叶怀远",{})
                if not steward.is_empty():
                    _log_event(c,steward,day,"雇工离职",
                        "%s连续7个工作日未得到工资，已结束山门服务并退出供膳名单。" % str(worker["name"]))
        else:
            contract["unpaid_days"]=0
        _dine_one(c,worker,day,true)

static func needs_report(society: Dictionary) -> String:
    var c: Dictionary=society.get("cultivation_world",{})
    if c.is_empty(): return ""
    var employed:=0
    var apprentices:=0
    var arrears:=0
    for contract in c.get("sect_workforce",{}).values():
        arrears+=int(contract.get("wage_arrears",0))
        if bool(contract.get("employed",false)): employed+=1
        else: apprentices+=1
    var stats: Dictionary=c.get("daily_dining",{})
    var region: Dictionary=c["regions"]["青云山门"]
    var stock: Dictionary=region["stock"]
    return "【仙凡衣食】山门具名凡人雇工/役仆%d人、求道见习%d人；炼气及未辟谷者仍需饮食、起居与卫生。\n口粮库存%d份，已供给普通餐食%d人日，合格辟谷%d人日，灵膳尝鲜%d份。\n灵田米%d份、灵果%d枚、已制灵膳%d份、泉水%d份，累计欠薪%d文，实际膳房及卫生用水均记账。" % [
        employed,apprentices,int(stock["口粮"]),int(stats.get("mortal_meals",0)),
        int(stats.get("bigu_days",0)),int(stats.get("delicacy_meals",0)),
        int(stock["灵米"]),int(stock["灵果"]),int(stock["灵膳"]),int(stock["泉水"]),arrears]
