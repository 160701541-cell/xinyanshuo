extends RefCounted
class_name XianfanImmortalSociety
# 仙凡同一条世界时钟：宗门人员是有UID、地点、库存、职业和记忆的实体。
# Existing player's undisclosed root, the forged manual and old NPCs are NOT
# rolled again or modified. These are additional world-generated characters.
const SCHEMA := 1
const LAYERS := [40,70,110,160,220,300,400,520,680,880,1120,1420,1780]
const ROOT_SPEED := {"天灵根":5.0,"单灵根":3.0,"双灵根":2.0,
    "三灵根":1.4,"四灵根":1.0,"五灵根":0.7}
# [name,job,root,seeded_level,station,character,priority]
const PEOPLE := [
    ["谷若竹","灵植夫","四灵根",1,"青云山门","谨慎耐心，珍惜每一株药苗","养活灵田"],
    ["罗观尘","外门弟子","三灵根",2,"青云山门","争强好胜，不愿靠人情换资源","凭本事求进境"],
    ["许晚照","丹房学徒","双灵根",1,"青云山门","精确执拗，炼制失败也认真记账","弄懂丹方"],
    ["宋微霜","制符学徒","三灵根",1,"青云山门","少言敏锐，最怕有人偷换符纸","学会可靠的护身符"],
    ["石砚安","巡山弟子","五灵根",1,"青云山门","直率守责，对来路不明的访客保持警惕","守住山道"],
    ["叶怀远","山门执事","双灵根",3,"青云山门","守旧而公正，不肯破坏山规","确保弟子平安"],
    ["荀小青","灵兽饲养人","五灵根",0,"青云山门","温和倔强，视灵兽为需照顾的生命","照顾好灵兽"],
    ["方照水","矿脉勘探者","四灵根",1,"青云山门","心思细密，不肯夸大矿脉产量","摸清矿石来源"],
    ["顾云野","游历散修","三灵根",1,"临安县城","生性疏朗，遇事先问交换是否公平","凭游历攒下修行资粮"],
    ["花拾月","灵材商贩","四灵根",1,"临安县城","算账精细，却愿意照顾穷苦学徒","靠真实买卖立足"],
    ["祝三元","行脚采药人","五灵根",0,"临安县城","怕惹是非，辨药却极仔细","攒齐测灵路费"],
    ["阮清和","护送修士","双灵根",2,"临安县城","讲信用，有同门也未必偏袒","做完这趟护送"]
]
static func _realm(level: int) -> String:
    if level<=0: return "修行预备"
    return "炼气%d层" % level

static func _place(person: Dictionary, hour: int) -> String:
    # Both sites already exist in the current map. No off-map conversation.
    var home:=str(person["home"])
    if hour%24>=7 and hour%24<=18: return str(person["work_place"])
    return home

static func initialize(society: Dictionary, start_minute: int) -> bool:
    if society.has("cultivation_world"):
        return false
    var formed: Dictionary={
        "schema":SCHEMA,"last_day":int(start_minute/1440)+1,
        "regions":{
            "青云山门":{"qi_density":1.0,"wild":{"灵草":22,"灵矿露头":8,"野生灵兽":5},
                "cap":{"灵草":60,"灵矿露头":20,"野生灵兽":12},
                "stock":{"灵草":4,"灵矿石":2,"丹药":0,"符箓":1,"灵兽饲料":12},
                "guard":4,"hazard":2},
            "临安县城":{"qi_density":0.18,"wild":{"灵草":4,"灵矿露头":1,"野生灵兽":0},
                "cap":{"灵草":9,"灵矿露头":3,"野生灵兽":0},
                "stock":{"灵草":0,"灵矿石":0,"丹药":0,"符箓":0,"灵兽饲料":0},
                "guard":0,"hazard":0}
        },
        "agents":{},"events":[],"total_practice":0,
        "total_herbs":0,"total_ore":0,"total_pills":0,"total_talismans":0
    }
    var people: Dictionary=formed["agents"]
    for i in range(PEOPLE.size()):
        var row: Array=PEOPLE[i]
        var name:=str(row[0])
        var origin:=str(row[4])
        var place: String="青云山门·山门外" if origin=="青云山门" else "临安县城·东市"
        var level:=int(row[3])
        people[name]={
            "id":"CULT%06d" % (i+1),"name":name,"job":str(row[1]),
            "root":str(row[2]),"root_verified":true,
            "verified_manual":true,"realm_level":level,"realm":_realm(level),
            "progress":0.0,"meridian_load":0.0,
            "age":19+(i*7)%35,"alive":true,"health":100,"energy":85,
            "station":origin,"faction":"青云仙门" if origin=="青云山门" else "散修",
            "home":place,"work_place":place,"place":place,
            "activity":"打理本职","trait":str(row[5]),"wish":str(row[6]),
            "stock":{},"skills":{str(row[1]):0},"biography":[],
            "registered_day":int(start_minute/1440)+1,
            "standing":"山门修士" if origin=="青云山门" else "行脚修士",
            "cultivation_member":true}
    society["cultivation_world"]=formed
    return true

static func valid(society: Dictionary) -> bool:
    var c: Dictionary=society.get("cultivation_world",{})
    if int(c.get("schema",0))!=SCHEMA: return false
    for place in c.get("regions",{}).values():
        if not (place is Dictionary): return false
        for key in ["wild","stock","cap"]:
            var source: Dictionary=place.get(key,{})
            for value in source.values():
                if int(value)<0: return false
    for p in c.get("agents",{}).values():
        if not (p is Dictionary): return false
        if int(p.get("realm_level",-1))<0 or int(p.get("realm_level",-1))>13: return false
        if str(p.get("root","")) not in ROOT_SPEED: return false
    return true

static func _record(c: Dictionary, person: Dictionary, day: int, kind: String, detail: String) -> void:
    var entry: Dictionary={
        "uid":"IMM-"+str(person["id"])+"-"+str(day)+"-"+kind,
        "day":day,"npc":str(person["name"]),"npc_id":str(person["id"]),
        "place":str(person.get("place","")),"category":kind,
        "detail":detail,"source":"immortal_rules","confidence":"rule_confirmed"}
    var log: Array=c["events"]
    log.append(entry)
    var biography: Array=person["biography"]
    biography.append(entry.duplicate(true))
    # History is append-only in the independent world fact sidecar; main save
    # keeps only a bounded recent view so 30-day offline catch-up does not bloat.
    if biography.size()>128: biography=biography.slice(-128)
    person["biography"]=biography

static func _regenerate(region: Dictionary, day: int, mountain: bool) -> void:
    var wild: Dictionary=region["wild"]
    var cap: Dictionary=region["cap"]
    wild["灵草"]=mini(int(cap["灵草"]),int(wild["灵草"])+(2 if mountain else (1 if day%4==0 else 0)))
    # Renewal is wild geological/ecological world generation, not free ore in
    # a sect/player bag. Mining still consumes a real ore-outcrop unit.
    if day%9==0:
        wild["灵矿露头"]=mini(int(cap["灵矿露头"]),int(wild["灵矿露头"])+1)
    if mountain and day%16==0:
        wild["野生灵兽"]=mini(int(cap["野生灵兽"]),int(wild["野生灵兽"])+1)

static func _work(c: Dictionary, person: Dictionary, day: int) -> void:
    var zone: Dictionary=c["regions"][str(person["station"])]
    var wild: Dictionary=zone["wild"]
    var stock: Dictionary=zone["stock"]
    var job:=str(person["job"])
    var done:=false
    if job in ["灵植夫","行脚采药人","游历散修"]:
        if int(wild["灵草"])>=1:
            wild["灵草"]=int(wild["灵草"])-1
            stock["灵草"]=int(stock["灵草"])+1
            c["total_herbs"]=int(c["total_herbs"])+1
            done=true
            _record(c,person,day,"采药","在%s实际采集1份灵草，野生灵草减少1，库内灵草增加1。" % str(person["station"]))
    elif job=="矿脉勘探者":
        if int(wild["灵矿露头"])>=1:
            wild["灵矿露头"]=int(wild["灵矿露头"])-1
            stock["灵矿石"]=int(stock["灵矿石"])+1
            c["total_ore"]=int(c["total_ore"])+1
            done=true
            _record(c,person,day,"采矿","在青云山门开采1份已生成的灵矿露头，矿点减少1，库存灵矿石增加1。")
    elif job=="丹房学徒":
        if int(stock["灵草"])>=3 and int(stock["灵矿石"])>=1:
            stock["灵草"]=int(stock["灵草"])-3
            stock["灵矿石"]=int(stock["灵矿石"])-1
            stock["丹药"]=int(stock["丹药"])+1
            c["total_pills"]=int(c["total_pills"])+1
            done=true
            _record(c,person,day,"炼丹","按丹方耗去3份灵草与1份灵矿石，炼得1枚基础丹药并入山门库。")
    elif job=="制符学徒":
        if int(stock["灵草"])>=1 and int(stock["灵矿石"])>=1:
            stock["灵草"]=int(stock["灵草"])-1
            stock["灵矿石"]=int(stock["灵矿石"])-1
            stock["符箓"]=int(stock["符箓"])+1
            c["total_talismans"]=int(c["total_talismans"])+1
            done=true
            _record(c,person,day,"制符","实耗1份灵草与1份灵矿石，制作并登记1张基础符箓。")
    elif job=="灵兽饲养人":
        if int(stock["灵兽饲料"])>=1:
            stock["灵兽饲料"]=int(stock["灵兽饲料"])-1
            done=true
            _record(c,person,day,"饲灵兽","实际耗去山门库存1份灵兽饲料；未凭空增生灵兽。")
    elif job=="巡山弟子":
        var earlier:=int(zone["hazard"])
        zone["hazard"]=maxi(0,earlier-1)
        done=true
        if earlier>0:
            _record(c,person,day,"巡山","巡察青云山门辖区，使警戒风险从%d降至%d。" % [earlier,int(zone["hazard"])])
    elif job in ["山门执事","护送修士","灵材商贩"]:
        done=true # Obligations and travel are real; no unfunded goods.
    if done:
        var skills: Dictionary=person["skills"]
        skills[job]=int(skills.get(job,0))+1

static func _practice(c: Dictionary, person: Dictionary, day: int) -> void:
    if not bool(person.get("root_verified",false)) or not bool(person.get("verified_manual",false)): return
    var root_name:=str(person.get("root",""))
    if not ROOT_SPEED.has(root_name) or int(person["realm_level"])>=13: return
    if int(person["energy"])<30: return
    var zone: Dictionary=c["regions"][str(person["station"])]
    var gain: float=2.0*float(ROOT_SPEED[root_name])*(1.0+float(zone["qi_density"]))
    var load: float=float(person["meridian_load"])
    if load>=60.0: gain*=0.75
    person["progress"]=float(person["progress"])+gain
    person["energy"]=maxi(0,int(person["energy"])-4)
    person["meridian_load"]=minf(100.0,load+3.2)
    c["total_practice"]=int(c["total_practice"])+1
    var level:=int(person["realm_level"])
    if load>92.0 or float(person["meridian_load"])>92.0: return
    if float(person["progress"])<float(LAYERS[level]): return
    person["progress"]=float(person["progress"])-float(LAYERS[level])
    person["realm_level"]=level+1
    person["realm"]=_realm(level+1)
    _record(c,person,day,"炼气进阶","核实灵根与真功法后，积累足够修为且经脉负荷合格，由%s进至%s；不是玩家获得修为。" % [_realm(level),_realm(level+1)])

static func advance_to(society: Dictionary, target_minute: int) -> int:
    var c: Dictionary=society.get("cultivation_world",{})
    if int(c.get("schema",0))!=SCHEMA or not valid(society): return 0
    var day:=int(target_minute/1440)+1
    var cursor:=int(c.get("last_day",day))
    if day<=cursor: return 0
    while cursor<day:
        cursor+=1
        _regenerate(c["regions"]["青云山门"],cursor,true)
        _regenerate(c["regions"]["临安县城"],cursor,false)
        # Threat is a scalar generated from ecology, not an imaginary attack.
        if cursor%6==0 and int(c["regions"]["青云山门"]["wild"]["野生灵兽"])>4:
            c["regions"]["青云山门"]["hazard"]=mini(20,int(c["regions"]["青云山门"]["hazard"])+1)
        for name in c["agents"]:
            var person: Dictionary=c["agents"][name]
            if not bool(person.get("alive",true)): continue
            person["energy"]=mini(100,int(person["energy"])+8)
            person["meridian_load"]=maxf(0.0,float(person["meridian_load"])-6.0)
            _work(c,person,cursor)
            _practice(c,person,cursor)
            if cursor%360==0:
                person["age"]=int(person["age"])+1
        c["last_day"]=cursor
    return day-int(society["cultivation_world"].get("last_day",day)) # Caller uses state advancement, not this return.

static func snapshot(society: Dictionary, name: String, hour: int) -> Dictionary:
    var record: Dictionary=society.get("cultivation_world",{}).get("agents",{}).get(name,{})
    if record.is_empty(): return {}
    var person:=record.duplicate(true)
    person["place"]=_place(record,hour)
    var hour_of_day:=hour%24
    person["activity"]="正在%s" % str(record["job"]) if hour_of_day>=7 and hour_of_day<=18 else "回到落脚处歇息"
    person["mood"]="专注" if hour_of_day>=7 and hour_of_day<=18 else "平静"
    return person

static func report(society: Dictionary) -> String:
    var c: Dictionary=society.get("cultivation_world",{})
    if c.is_empty(): return "修仙社会层未建档。"
    var mountain: Dictionary=c["regions"]["青云山门"]
    var stock: Dictionary=mountain["stock"]
    var wild: Dictionary=mountain["wild"]
    return "【仙门·已模拟样本】%d名具名修士/学徒；已结算吐纳%d人日\n青云库存：灵草%d、灵矿石%d、基础丹药%d、符箓%d、灵兽饲料%d\n自然资源：野生灵草%d、灵矿露头%d、野生灵兽%d；风险指标%d\n所有原料均有来源，不能据此推算天下宗门全部产能。" % [
        c["agents"].size(),int(c["total_practice"]),int(stock["灵草"]),
        int(stock["灵矿石"]),int(stock["丹药"]),int(stock["符箓"]),
        int(stock["灵兽饲料"]),int(wild["灵草"]),int(wild["灵矿露头"]),
        int(wild["野生灵兽"]),int(mountain["hazard"])]
