extends RefCounted
class_name XianfanSocietySim

# Deterministic hourly society simulation. The player is not an input to any
# production, trade or NPC timetable. Every transaction checks stock and cash.
# This is a 24-agent vertical slice, NOT a simulation of all county residents.
const VERSION := 1
const PEOPLE := [
    ["唐知行","农夫","石桥村","耕耘稳重"],["赵阿禾","农夫","石桥村","热爱乡土"],
    ["周二郎","农夫","石桥村","沉默寡言"],["方春秀","农夫","石桥村","勤勉细心"],
    ["石满仓","渔夫","石桥村","谨慎知水"],["叶小篙","渔夫","石桥村","爱听故事"],
    ["吕木成","樵夫","石桥村","惜木守林"],["柏青娘","樵夫","石桥村","粗中有细"],
    ["林寻药","采药人","石桥村","善辨百草"],["蒲青禾","采药人","石桥村","爱护山野"],
    ["孔铁山","匠人","石桥村","专心工艺"],["霍阿芒","匠人","石桥村","喜爱雕刻"],
    ["钱德厚","商贩","石桥村","擅长算账"],["柳素云","商贩","石桥村","为人热络"],
    ["孟远川","脚夫","石桥村","熟悉官道"],["秦九山","脚夫","临安县城","守信用"],
    ["陆怀书","教书人","石桥村","耐心好学"],["顾朝闻","学徒","石桥村","好奇心强"],
    ["严拱辰","巡卒","临安县城","重视规矩"],["裴正安","巡卒","石桥村","忠于职守"],
    ["沈妙手","医者","临安县城","谨慎行医"],["谢白芷","医者","石桥村","关心贫弱"],
    ["宋九成","商贩","临安县城","精于交易"],["鲁星河","匠人","临安县城","喜欢钻研"]
]
const JOB_WAGE := {"农夫":1,"渔夫":1,"樵夫":1,"采药人":1,"匠人":2,
    "商贩":1,"脚夫":1,"教书人":1,"学徒":0,"巡卒":2,"医者":2}
const EVENT_LIMIT := 100

static func _zone(affiliation: String) -> String:
    return "村" if affiliation=="石桥村" else "城"

static func _home(affiliation: String) -> String:
    return "石桥村·街口" if affiliation=="石桥村" else "临安县城·南巷"

static func initial_state(absolute_minute: int) -> Dictionary:
    var society: Dictionary={
        "schema":VERSION,"last_hour":int(absolute_minute/60),
        "regions":{
            "村":{"stock":{"粮":220,"木":26,"鱼":6,"药":7,"器":4},
                "wild":{"肥力":120,"木林":28,"野鱼":15,"野药":15},
                "cap":{"肥力":180,"木林":45,"野鱼":30,"野药":35},
                "treasury":340,"population_aggregate":1100},
            "城":{"stock":{"粮":460,"木":90,"鱼":22,"药":50,"器":45},
                "wild":{"肥力":190,"木林":60,"野鱼":22,"野药":38},
                "cap":{"肥力":240,"木林":80,"野鱼":40,"野药":60},
                "treasury":980,"population_aggregate":18000}
        },
        "agents":{},"events":[],"daily":{},"total_production":0,"total_trades":0,
        "total_consumption":0,"total_wages":0,"total_steps":0
    }
    var idx:=0
    for row in PEOPLE:
        var name:=str(row[0])
        var job:=str(row[1])
        var origin:=str(row[2])
        society["agents"][name]={
            "id":"CFNPC%05d"%(1001+idx),"name":name,"age":18+(idx*11)%41,
            "job":job,"home":_home(origin),"origin":origin,
            "place":_home(origin),"activity":"在家歇息","mood":"平静",
            "trait":str(row[3]),"wish":"凭本事把日子过好",
            "coins":5+idx%4,"rations":2,"energy":70+idx%12,
            "health":100,"hunger":0,"work_done":0,"social":{},
            "cargo":{},"last_hour":int(absolute_minute/60)
        }
        idx+=1
    return society

static func valid(society: Dictionary) -> bool:
    if int(society.get("schema",0))!=VERSION: return false
    if not society.has("regions") or not society.has("agents"): return false
    var regions: Dictionary=society["regions"]
    var people: Dictionary=society["agents"]
    for region in regions.values():
        var part: Dictionary=region
        if int(part.get("treasury",-1))<0: return false
        var stock: Dictionary=part.get("stock",{})
        var wild: Dictionary=part.get("wild",{})
        for amount in stock.values():
            if int(amount)<0: return false
        for amount in wild.values():
            if int(amount)<0: return false
    for agent in people.values():
        var npc: Dictionary=agent
        if int(npc.get("coins",-1))<0 or int(npc.get("rations",-1))<0: return false
        if int(npc.get("health",-1))<0 or int(npc.get("energy",-1))<0: return false
    return true

static func _event(society: Dictionary, hour: int, who: String, action: String) -> void:
    var records: Array=society.get("events",[])
    records.append({"day":int(hour/24)+1,"hour":hour%24,"npc":who,"detail":action})
    if records.size()>EVENT_LIMIT: records.pop_front()
    society["events"]=records

static func _wild_grow(society: Dictionary, absolute_hour: int) -> void:
    for region_key in society["regions"]:
        var region: Dictionary=society["regions"][region_key]
        var wild: Dictionary=region["wild"]
        var cap: Dictionary=region["cap"]
        for key in ["肥力","木林","野鱼","野药"]:
            var growth:=2 if key=="肥力" else 1
            wild[key]=mini(int(cap[key]),int(wild[key])+growth)
    var day:=int(absolute_hour/24)+1
    _event(society,absolute_hour,"自然生态","土壤恢复、林木更新、鱼群迁入；恢复量受上限限制。")
    society["daily"][str(day)]={"production":0,"trades":0,"consumption":0,"wages":0}

static func _grant_pay(society: Dictionary, npc: Dictionary, region: Dictionary, hour: int) -> void:
    var wage:=int(JOB_WAGE.get(str(npc["job"]),0))
    if wage<=0 or int(region["treasury"])<wage: return
    region["treasury"]=int(region["treasury"])-wage
    npc["coins"]=int(npc["coins"])+wage
    society["total_wages"]=int(society["total_wages"])+wage
    var day: Dictionary=society["daily"].get(str(int(hour/24)+1),{})
    day["wages"]=int(day.get("wages",0))+wage

static func _produce(society: Dictionary, npc: Dictionary, region: Dictionary, hour: int) -> void:
    var job:=str(npc["job"])
    var wild: Dictionary=region["wild"]
    var stock: Dictionary=region["stock"]
    var made:=false
    if job=="农夫" and int(wild["肥力"])>=2:
        wild["肥力"]=int(wild["肥力"])-2
        stock["粮"]=int(stock["粮"])+2
        made=true
    elif job=="渔夫" and int(wild["野鱼"])>=1:
        wild["野鱼"]=int(wild["野鱼"])-1
        stock["鱼"]=int(stock["鱼"])+1
        made=true
    elif job=="樵夫" and int(wild["木林"])>=1:
        wild["木林"]=int(wild["木林"])-1
        stock["木"]=int(stock["木"])+1
        made=true
    elif job=="采药人" and int(wild["野药"])>=1:
        wild["野药"]=int(wild["野药"])-1
        stock["药"]=int(stock["药"])+1
        made=true
    elif job=="匠人" and int(stock["木"])>=2:
        stock["木"]=int(stock["木"])-2
        stock["器"]=int(stock["器"])+1
        made=true
    elif job=="医者" and int(stock["药"])>=1 and int(npc["energy"])<85:
        stock["药"]=int(stock["药"])-1
        npc["energy"]=mini(100,int(npc["energy"])+8)
        made=true
    elif job in ["巡卒","教书人","脚夫","商贩","学徒"]:
        made=true  # service work may earn salary; does not create goods.
    if made:
        npc["work_done"]=int(npc["work_done"])+1
        society["total_production"]=int(society["total_production"])+1 if job in ["农夫","渔夫","樵夫","采药人","匠人"] else 0
        var day: Dictionary=society["daily"].get(str(int(hour/24)+1),{})
        if job in ["农夫","渔夫","樵夫","采药人","匠人"]:
            day["production"]=int(day.get("production",0))+1
        _grant_pay(society,npc,region,hour)

static func _purchase(society: Dictionary, npc: Dictionary, region: Dictionary, hour: int) -> void:
    if int(npc["rations"])>=2 or int(npc["coins"])<2 or int(region["stock"]["粮"])<2: return
    npc["coins"]=int(npc["coins"])-2
    region["treasury"]=int(region["treasury"])+2
    region["stock"]["粮"]=int(region["stock"]["粮"])-2
    npc["rations"]=int(npc["rations"])+2
    society["total_trades"]=int(society["total_trades"])+1
    var day: Dictionary=society["daily"].get(str(int(hour/24)+1),{})
    day["trades"]=int(day.get("trades",0))+1
    if society["total_trades"]%7==0:
        _event(society,hour,str(npc["name"]),"从市集付出两文，购买两份确实存在的粮食。")

static func _meal(society: Dictionary, npc: Dictionary, region: Dictionary, hour: int) -> void:
    _purchase(society,npc,region,hour)
    if int(npc["rations"])>0:
        npc["rations"]=int(npc["rations"])-1
        npc["hunger"]=maxi(0,int(npc["hunger"])-1)
        society["total_consumption"]=int(society["total_consumption"])+1
        var day: Dictionary=society["daily"].get(str(int(hour/24)+1),{})
        day["consumption"]=int(day.get("consumption",0))+1
    else:
        npc["hunger"]=int(npc["hunger"])+1
        npc["health"]=maxi(0,int(npc["health"])-2)
        npc["mood"]="饥饿"
        if npc["hunger"]==2:
            _event(society,hour,str(npc["name"]),"钱粮不足，已经连续几餐没有吃饱。")

static func _work_place(npc: Dictionary, hour: int) -> String:
    var job:=str(npc["job"])
    var village:=str(npc["origin"])=="石桥村"
    if job in ["农夫","巡卒"]: return "石桥村·田边" if village else "临安县城·东市"
    if job=="渔夫": return "石桥村·溪边" if village else "临安县城·东市"
    if job in ["樵夫","采药人"]: return "石桥村·林缘" if village else "临安县城·东市"
    if job in ["商贩","匠人"]: return "石桥村·街口" if village else "临安县城·东市"
    if job in ["医者","教书人","学徒"]: return "石桥村·街口" if village else "临安县城·南巷"
    if job=="脚夫":
        if hour<11: return "临安官道"
        if hour<=16: return "临安县城·东市"
        return "临安官道"
    return str(npc["home"])

static func _hour_step(society: Dictionary, absolute_hour: int) -> void:
    var hour:=absolute_hour%24
    if hour==5: _wild_grow(society,absolute_hour)
    var daykey:=str(int(absolute_hour/24)+1)
    if not society["daily"].has(daykey):
        society["daily"][daykey]={"production":0,"trades":0,"consumption":0,"wages":0}
    var agents: Dictionary=society["agents"]
    for name in agents:
        var person: Dictionary=agents[name]
        var area:=_zone(str(person["origin"]))
        var region: Dictionary=society["regions"][area]
        var job:=str(person["job"])
        if hour<6 or hour>=21:
            person["place"]=str(person["home"])
            person["activity"]="在家睡觉"
            person["energy"]=mini(100,int(person["energy"])+4)
        elif hour==6:
            person["place"]=str(person["home"])
            person["activity"]="准备早饭"
            _meal(society,person,region,absolute_hour)
        elif hour in [12,18]:
            person["place"]=_work_place(person,hour) if hour==12 else str(person["home"])
            person["activity"]="吃饭歇息" if hour==12 else "傍晚归家"
            _meal(society,person,region,absolute_hour)
        elif hour>=7 and hour<=17:
            person["place"]=_work_place(person,hour)
            person["activity"]="干本行的活："+job
            person["energy"]=maxi(0,int(person["energy"])-1)
            if hour in [9,15] and int(person["energy"])>=6:
                _produce(society,person,region,absolute_hour)
        elif hour in [19,20]:
            person["place"]=str(person["home"])
            person["activity"]="走亲访友" if hour==19 else "休闲学习"
            person["energy"]=mini(100,int(person["energy"])+2)
            if hour==19:
                var peer_index:=int(str(person["id"]).substr(5).to_int())%PEOPLE.size()
                var peer:=str(PEOPLE[peer_index][0])
                if peer!=name:
                    var friends: Dictionary=person.get("social",{})
                    friends[peer]=mini(100,int(friends.get(peer,0))+1)
                    person["social"]=friends
        person["last_hour"]=absolute_hour
        if int(person["health"])<=0:
            person["activity"]="病卧不起"
            person["mood"]="虚弱"
    society["total_steps"]=int(society["total_steps"])+1
    # Keep a rolling 30-day summary; hourly events remain bounded.
    var days: Dictionary=society.get("daily",{})
    if days.size()>31:
        var keys:=days.keys()
        keys.sort_custom(func(a,b): return int(a)<int(b))
        while keys.size()>31:
            days.erase(keys.pop_front())

static func advance_to(society: Dictionary, absolute_minute: int) -> int:
    var target:=int(absolute_minute/60)
    var start:=int(society.get("last_hour",target))
    if start>target: return 0
    var advanced:=0
    while start<target:
        start+=1
        _hour_step(society,start)
        advanced+=1
    society["last_hour"]=target
    return advanced

static func near_people(society: Dictionary, place: String) -> Array[Dictionary]:
    var result: Array[Dictionary]=[]
    for name in society.get("agents",{}):
        var npc: Dictionary=society["agents"][name]
        if str(npc["place"])==place: result.append(npc.duplicate(true))
    return result

static func report(society: Dictionary, current_place: String) -> String:
    var actors: Dictionary=society.get("agents",{})
    var nearby:=near_people(society,current_place)
    var region:=_zone("石桥村") if current_place.begins_with("石桥村") else "城"
    var economy: Dictionary=society.get("regions",{}).get(region,{})
    var supply: Dictionary=economy.get("stock",{})
    var lines: Array[String]=[
        "《仙凡 · 自运转的人间》",
        "这个世界里有%d名持续演算的具名职业NPC；这是首批社会样本，不是整个县的人口。" % actors.size(),
        "【所在地点】%s；附近职业NPC %d人" % [current_place,nearby.size()],
        "【本地库藏】粮%d份 · 木%d份 · 鱼%d条 · 药%d份 · 器具%d件" % [
            int(supply.get("粮",0)),int(supply.get("木",0)),int(supply.get("鱼",0)),
            int(supply.get("药",0)),int(supply.get("器",0))],
        "【公共钱库】%d文（工资从库中支出，买粮时钱回到库中）" % int(economy.get("treasury",0)),
        "【累计自主演算】%d小时；生产%d次 · 交易%d次 · 消费%d份" % [
            int(society.get("total_steps",0)),int(society.get("total_production",0)),
            int(society.get("total_trades",0)),int(society.get("total_consumption",0))]
    ]
    for agent in nearby.slice(0,10):
        lines.append("· %s｜%s｜%s｜存钱%d文" % [
            str(agent.get("name","")),str(agent.get("job","")),
            str(agent.get("activity","")),int(agent.get("coins",0))])
    lines.append("【最近真实事件】")
    var events: Array=society.get("events",[])
    for e in events.slice(-6):
        lines.append("第%d日%02d时 · %s：%s" % [
            int(e.get("day",0)),int(e.get("hour",0)),
            str(e.get("npc","")),str(e.get("detail",""))])
    return "\n".join(lines)
