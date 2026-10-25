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
# Supply-dependent quotes are the same for NPCs and player. Prices only
# change when real local stocks cross thresholds, never via language-model text.
const BASE_PRICE := {"粮":2,"木":3,"鱼":3,"药":5,"器":8}
const REGIONAL_TARGET := {"村":{"粮":120,"木":18,"鱼":8,"药":8,"器":5},
    "城":{"粮":300,"木":65,"鱼":15,"药":35,"器":30}}

static func regional_price(society: Dictionary, region_name: String, good: String) -> int:
    if not BASE_PRICE.has(good): return 0
    var region: Dictionary=society.get("regions",{}).get(region_name,{})
    var stock: Dictionary=region.get("stock",{})
    var target: Dictionary=REGIONAL_TARGET.get(region_name,{})
    if not stock.has(good): return 0
    var quantity:=int(stock[good])
    var expected:=maxi(1,int(target.get(good,10)))
    var quote:=int(BASE_PRICE[good])
    if quantity<=expected/4: quote+=3
    elif quantity<=expected/2: quote+=2
    elif quantity>=expected*3: quote-=2
    elif quantity>=expected*2: quote-=1
    return maxi(1,quote)

static func _prepare_social(society: Dictionary) -> void:
    if not society.has("households"):
        society["households"]={}
    if not society.has("caravans"):
        society["caravans"]=[
            {"id":"ROAD-FISH-01","from":"村","to":"城","good":"鱼","limit":2,
                "agent":"孟远川","state":"idle","qty":0,"depart_hour":-1,"arrive_hour":-1},
            {"id":"ROAD-TOOLS-02","from":"城","to":"村","good":"器","limit":1,
                "agent":"秦九山","state":"idle","qty":0,"depart_hour":-1,"arrive_hour":-1}
        ]
    var members: Dictionary=society.get("agents",{})
    # Assign starting households to pairs of people in each settlement.
    # "Household" means mutual support, not invented romantic ties.
    var per_region: Dictionary={"村":[],"城":[]}
    for who in members:
        var item: Dictionary=members[who]
        if item.has("household"): continue
        var region: String=_zone(str(item.get("origin","石桥村")))
        per_region[region].append(str(who))
    for region in per_region:
        var names: Array=per_region[region]
        for i in range(names.size()):
            var who:=str(names[i])
            var household_id: String=region+"-同户%02d" % int(i/2+1)
            members[who]["household"]=household_id
            var homes: Dictionary=society["households"]
            var group: Array=homes.get(household_id,[])
            if not group.has(who): group.append(who)
            homes[household_id]=group
    if not society.has("family_support_count"):
        society["family_support_count"]=0
    if not society.has("caravan_trades"):
        society["caravan_trades"]=0

static func _family_support(society: Dictionary, absolute_hour: int) -> void:
    var agents: Dictionary=society["agents"]
    for household in society.get("households",{}):
        var members: Array=society["households"][household]
        for needy_name in members:
            var needy: Dictionary=agents[needy_name]
            if not bool(needy.get("alive",true)) or int(needy.get("rations",0))>=1: continue
            for donor_name in members:
                if str(donor_name)==str(needy_name): continue
                var donor: Dictionary=agents[donor_name]
                if bool(donor.get("alive",true)) and int(donor["rations"])>=2:
                    donor["rations"]=int(donor["rations"])-1
                    needy["rations"]=int(needy["rations"])+1
                    society["family_support_count"]=int(society["family_support_count"])+1
                    _event(society,absolute_hour,str(donor_name),
                        "从自己真实口粮中分出一份，帮助同户的%s。" % str(needy_name))
                    break

static func _depart_caravans(society: Dictionary, absolute_hour: int) -> void:
    for trip in society.get("caravans",[]):
        var convoy: Dictionary=trip
        if str(convoy["state"])!="idle": continue
        if not bool(society["agents"][str(convoy["agent"])].get("alive",true)): continue
        var from_region: Dictionary=society["regions"][str(convoy["from"])]
        var to_region: Dictionary=society["regions"][str(convoy["to"])]
        var good:=str(convoy["good"])
        var price:=regional_price(society,str(convoy["to"]),good)
        var stock: Dictionary=from_region["stock"]
        var qty:=mini(int(convoy["limit"]),maxi(0,int(stock[good])-1))
        if qty<1 or int(to_region["treasury"])<qty*price: continue
        stock[good]=int(stock[good])-qty
        convoy["qty"]=qty
        convoy["state"]="road"
        convoy["depart_hour"]=absolute_hour
        convoy["arrive_hour"]=absolute_hour+8
        convoy["quoted_price"]=price
        var who:=str(convoy["agent"])
        var agent: Dictionary=society["agents"][who]
        var cargo: Dictionary=agent.get("cargo",{})
        cargo[good]=int(cargo.get(good,0))+qty
        agent["cargo"]=cargo
        _event(society,absolute_hour,who,"带着%d份%s从%s启程前往%s，货物已从起点仓库扣除。" % [
            qty,good,str(convoy["from"]),str(convoy["to"])])

static func _arrive_caravans(society: Dictionary, absolute_hour: int) -> void:
    for trip in society.get("caravans",[]):
        var convoy: Dictionary=trip
        if str(convoy["state"])!="road": continue
        if absolute_hour<int(convoy["arrive_hour"]): continue
        var qty:=int(convoy["qty"])
        var from_zone:=str(convoy["from"])
        var to_zone:=str(convoy["to"])
        var from_region: Dictionary=society["regions"][from_zone]
        var to_region: Dictionary=society["regions"][to_zone]
        var price:=int(convoy["quoted_price"])
        var good:=str(convoy["good"])
        var who:=str(convoy["agent"])
        var agent: Dictionary=society["agents"][who]
        var cargo: Dictionary=agent["cargo"]
        if int(to_region["treasury"])>=qty*price:
            to_region["treasury"]=int(to_region["treasury"])-qty*price
            from_region["treasury"]=int(from_region["treasury"])+qty*price
            to_region["stock"][good]=int(to_region["stock"][good])+qty
            society["caravan_trades"]=int(society["caravan_trades"])+1
            society["total_trades"]=int(society["total_trades"])+1
            _event(society,absolute_hour,who,
                "沿官道抵达%s，交割%d份%s；从目的地钱库划转%d文给起点钱库。" % [
                    to_zone,qty,good,qty*price])
        else:
            # No buyer cash: the wagon turns back, but items remain physical.
            # Mark a return journey rather than teleporting the stock.
            convoy["state"]="returning"
            convoy["arrive_hour"]=absolute_hour+8
            _event(society,absolute_hour,who,"目的地无力付款，押货原路返回。")
            continue
        cargo[good]=maxi(0,int(cargo.get(good,0))-qty)
        convoy["qty"]=0
        convoy["state"]="idle"
        convoy["arrive_hour"]=-1

static func _return_caravans(society: Dictionary, absolute_hour: int) -> void:
    for trip in society.get("caravans",[]):
        var convoy: Dictionary=trip
        if str(convoy["state"])!="returning" or absolute_hour<int(convoy["arrive_hour"]): continue
        var good:=str(convoy["good"])
        var qty:=int(convoy["qty"])
        society["regions"][str(convoy["from"])]["stock"][good]=int(society["regions"][str(convoy["from"])]["stock"][good])+qty
        var agent: Dictionary=society["agents"][str(convoy["agent"])]
        var cargo: Dictionary=agent["cargo"]
        cargo[good]=maxi(0,int(cargo.get(good,0))-qty)
        convoy["state"]="idle"
        convoy["qty"]=0
        convoy["arrive_hour"]=-1
        _event(society,absolute_hour,str(convoy["agent"]),"远行未能成交，所押货物如数退回原仓。")

static func _caravan_position(society: Dictionary, npc: Dictionary, absolute_hour: int) -> bool:
    for trip in society.get("caravans",[]):
        var convoy: Dictionary=trip
        if str(convoy["agent"])!=str(npc["name"]): continue
        if str(convoy["state"]) in ["road","returning"]:
            npc["place"]="临安官道"
            npc["activity"]="押送有账可查的货物：" + str(convoy["good"])
            return true
    return false


# Long-running NPC biography: objective training, career changes and mortality.
# All transitions are deterministic; no LLM narration can alter possessions.
static func _life_defaults(society: Dictionary) -> void:
    if not society.has("chronicle"): society["chronicle"]=[]
    if not society.has("deaths"): society["deaths"]=0
    if not society.has("career_changes"): society["career_changes"]=0
    if not society.has("births"): society["births"]=0
    for name in society["agents"]:
        var npc: Dictionary=society["agents"][name]
        if not npc.has("alive"): npc["alive"]=true
        if not npc.has("skills"): npc["skills"]={str(npc.get("job","学徒")):int(npc.get("work_done",0))}
        if not npc.has("biography"): npc["biography"]=[]
        if not npc.has("age_anchor_day"):
            npc["age_anchor_day"]=int(int(npc.get("last_hour",0))/24)+1
        if not npc.has("life_span"):
            var numeric:=int(str(npc.get("id","0")).hash() & 0x7fffffff)
            npc["life_span"]=73+numeric%17
        if not npc.has("mentor"): npc["mentor"]=""
        if not npc.has("training"):
            npc["training"]=0

static func _milestone(society: Dictionary, npc: Dictionary, hour: int, category: String, detail: String) -> void:
    var record: Dictionary={"uid":"LIFE-"+str(npc["id"])+"-"+str(hour)+"-"+category,
        "day":int(hour/24)+1,"hour":hour%24,"npc":str(npc["name"]),
        "category":category,"detail":detail}
    var archive: Array=society.get("chronicle",[])
    archive.append(record)
    society["chronicle"]=archive
    var persona_log: Array=npc.get("biography",[])
    persona_log.append(record.duplicate(true))
    npc["biography"]=persona_log
    _event(society,hour,str(npc["name"]),detail)

static func _mentor_for(society: Dictionary, student: Dictionary) -> String:
    var candidates: Array[String]=[]
    for other_name in society["agents"]:
        var mentor: Dictionary=society["agents"][other_name]
        if str(mentor["id"])==str(student["id"]): continue
        if not bool(mentor.get("alive",true)): continue
        if str(mentor["origin"])!=str(student["origin"]): continue
        if str(mentor["job"])!="匠人": continue
        if int(mentor.get("skills",{}).get("匠人",0))<3: continue
        candidates.append(str(other_name))
    candidates.sort()
    return candidates[0] if not candidates.is_empty() else ""

static func _skill_work(society: Dictionary, npc: Dictionary, hour: int) -> void:
    if not bool(npc.get("alive",true)): return
    var job:=str(npc["job"])
    var skills: Dictionary=npc.get("skills",{})
    if job=="学徒":
        var mentor_name:=_mentor_for(society,npc)
        if mentor_name.is_empty():
            npc["activity"]="本地尚无愿意教工艺的合格师傅，继续自学"
            return
        npc["mentor"]=mentor_name
        var mentor: Dictionary=society["agents"][mentor_name]
        if str(mentor.get("place",""))!=str(npc.get("place","")):
            npc["activity"]="在工坊等师傅，整理器具"
            return
        # Learning costs time, requires a co-located trained craftsperson,
        # and is distinct from inventing completed goods from a speech turn.
        npc["training"]=int(npc["training"])+1
        skills["匠人"]=int(skills.get("匠人",0))+1
        if int(npc["training"])==1:
            _milestone(society,npc,hour,"拜师","跟随%s在同一个工坊里开始学习木作。" % mentor_name)
        elif int(npc["training"])>=24:
            npc["job"]="匠人"
            npc["wish"]="以手艺养活自己，不再只做学徒"
            society["career_changes"]=int(society["career_changes"])+1
            _milestone(society,npc,hour,"出师","师从%s累计24次真实工时，已出师成为匠人。" % mentor_name)
    else:
        skills[job]=int(skills.get(job,0))+1
        if int(skills[job])==20:
            _milestone(society,npc,hour,"技艺","经过20次实际工作，%s的%s技艺变得熟练。" % [str(npc["name"]),job])
    npc["skills"]=skills

static func _retire_person(society: Dictionary, npc: Dictionary, hour: int, reason: String) -> void:
    if not bool(npc.get("alive",true)): return
    npc["alive"]=false
    npc["death_day"]=int(hour/24)+1
    npc["health"]=0
    npc["place"]="故人名录"
    npc["activity"]="已故（%s）" % reason
    npc["wish"]=""
    var assets:=int(npc["coins"])
    var foods:=int(npc["rations"])
    var receiver: String=""
    for peer in society.get("households",{}).get(str(npc.get("household","")),[]):
        if str(peer)==str(npc["name"]): continue
        var person: Dictionary=society["agents"].get(str(peer),{})
        if not person.is_empty() and bool(person.get("alive",true)):
            receiver=str(peer)
            break
    if not receiver.is_empty():
        var heir: Dictionary=society["agents"][receiver]
        heir["coins"]=int(heir["coins"])+assets
        heir["rations"]=int(heir["rations"])+foods
    else:
        var region: Dictionary=society["regions"][_zone(str(npc["origin"]))]
        region["treasury"]=int(region["treasury"])+assets
        region["stock"]["粮"]=int(region["stock"]["粮"])+foods
    npc["coins"]=0
    npc["rations"]=0
    society["deaths"]=int(society["deaths"])+1
    _milestone(society,npc,hour,"死亡","%s因%s离世，遗留%d文与%d份口粮%s。" % [
        str(npc["name"]),reason,assets,foods,
        "交由同户%s继承" % receiver if not receiver.is_empty() else "归还当地公共库"])
    # This milestone retains identity and NPC ID in a permanent biography;
    # the actor does not reappear as a working NPC after death.

static func _daily_lifecycle(society: Dictionary, hour: int) -> void:
    var day:=int(hour/24)+1
    _life_defaults(society)
    for name in society["agents"]:
        var npc: Dictionary=society["agents"][name]
        if not bool(npc.get("alive",true)): continue
        if int(npc["health"])<=0:
            _retire_person(society,npc,hour,"长期饥饿或疾病")
            continue
        var anchor:=int(npc.get("age_anchor_day",day))
        if day-anchor>=360:
            npc["age"]=int(npc["age"])+1
            npc["age_anchor_day"]=anchor+360
            if int(npc["age"])%10==0:
                _milestone(society,npc,hour,"生辰","年满%d岁；如今以%s为生。" % [int(npc["age"]),str(npc["job"])])
        if day%30==0 and int(npc["age"])>=67:
            npc["health"]=maxi(0,int(npc["health"])-3)
        if int(npc["age"])>=int(npc["life_span"]) or int(npc["health"])<=0:
            _retire_person(society,npc,hour,"寿终" if int(npc["health"])>0 else "疾病")

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
    _prepare_social(society)
    _life_defaults(society)
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
        if npc.has("skills"):
            for skill in npc["skills"].values():
                if int(skill)<0: return false
        if int(npc.get("age",0))<0: return false
        if not bool(npc.get("alive",true)) and int(npc["coins"])!=0: return false
    for shipment in society.get("caravans",[]):
        if not shipment is Dictionary: return false
        if int(shipment.get("qty",0))<0: return false
        if str(shipment.get("state","idle")) not in ["idle","road","returning"]: return false
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
            var growth:=70 if region_key=="村" else 32
            if key=="木林": growth=4
            elif key=="野鱼": growth=4
            elif key=="野药": growth=3
            wild[key]=mini(int(cap[key]),int(wild[key])+growth)
        # Existing unnamed farming households are simulated as one cooperative
        # batch to balance the named citizens, NOT per-person 18k population.
        var collective:=40 if region_key=="村" else 22
        var stores: Dictionary=region["stock"]
        var capacity:=460 if region_key=="村" else 860
        var harvest:=mini(collective,mini(int(wild["肥力"]),maxi(0,capacity-int(stores["粮"]))))
        if harvest>0:
            wild["肥力"]=int(wild["肥力"])-harvest
            stores["粮"]=int(stores["粮"])+harvest
            society["total_production"]=int(society["total_production"])+harvest
            _event(society,absolute_hour,"村社农田" if region_key=="村" else "县城周边农田","集体农户收获%d份真实粮食；已扣除田力并受粮仓容量限制。" % harvest)
    var day:=int(absolute_hour/24)+1
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
        if job in ["农夫","渔夫","樵夫","采药人","匠人"]:
            society["total_production"]=int(society["total_production"])+1
        var day: Dictionary=society["daily"].get(str(int(hour/24)+1),{})
        if job in ["农夫","渔夫","樵夫","采药人","匠人"]:
            day["production"]=int(day.get("production",0))+1
        _grant_pay(society,npc,region,hour)

static func _purchase(society: Dictionary, npc: Dictionary, region: Dictionary, hour: int) -> void:
    if int(npc["rations"])>=2 or int(region["stock"]["粮"])<2: return
    var zone:=_zone(str(npc["origin"]))
    var price:=regional_price(society,zone,"粮")
    var bill:=price*2
    if int(npc["coins"])<bill: return
    npc["coins"]=int(npc["coins"])-bill
    region["treasury"]=int(region["treasury"])+bill
    region["stock"]["粮"]=int(region["stock"]["粮"])-2
    npc["rations"]=int(npc["rations"])+2
    society["total_trades"]=int(society["total_trades"])+1
    var day: Dictionary=society["daily"].get(str(int(hour/24)+1),{})
    day["trades"]=int(day.get("trades",0))+1
    if society["total_trades"]%7==0:
        _event(society,hour,str(npc["name"]),"按今日市价支付%d文，买下真实存货中的两份粮食。" % bill)

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
    _prepare_social(society)
    _life_defaults(society)
    var hour:=absolute_hour%24
    _return_caravans(society,absolute_hour)
    _arrive_caravans(society,absolute_hour)
    if hour==8: _depart_caravans(society,absolute_hour)
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
        if not bool(person.get("alive",true)):
            person["last_hour"]=absolute_hour
            continue
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
                _skill_work(society,person,absolute_hour)
        elif hour in [19,20]:
            person["place"]=str(person["home"])
            person["activity"]="走亲访友" if hour==19 else "休闲学习"
            person["energy"]=mini(100,int(person["energy"])+2)
            if hour==19:
                # Social ties require physical co-presence; a villager cannot
                # befriend somebody in a distant county by an arbitrary ID roll.
                var peers: Array[String]=[]
                for other_name in agents:
                    if other_name==name: continue
                    var other: Dictionary=agents[other_name]
                    if str(other.get("home",""))==str(person["home"]):
                        peers.append(str(other_name))
                if not peers.is_empty():
                    var pick:=int(person["id"].hash() & 0x7fffffff)%peers.size()
                    var peer:=peers[pick]
                    var friends: Dictionary=person.get("social",{})
                    friends[peer]=mini(100,int(friends.get(peer,0))+1)
                    person["social"]=friends
        # Goal selection is grounded in needs/occupation, not a cosmetic fixed wish.
        if hour==20 and int(person["health"])>0:
            if int(person["hunger"])>0 or int(person["rations"])==0:
                person["wish"]="努力挣钱买粮，别再挨饿"
                person["mood"]="忧虑"
            elif int(person["coins"])>=25:
                person["wish"]="攒钱改善居所与日常生活"
                person["mood"]="安心"
            elif job=="脚夫" and not person["cargo"].is_empty():
                person["wish"]="把押运货物如数送达"
            elif job in ["学徒","教书人"]:
                person["wish"]="继续学习本业，逐步提升技艺"
            elif int(person["work_done"])>10:
                person["wish"]="靠手艺和劳动积累家底"
            else:
                person["wish"]="凭本事把日子过好"
        person["last_hour"]=absolute_hour
        if int(person["health"])<=0:
            person["activity"]="病卧不起"
            person["mood"]="虚弱"
        elif _caravan_position(society,person,absolute_hour):
            pass
    if hour==19: _family_support(society,absolute_hour)
    if hour==20: _daily_lifecycle(society,absolute_hour)
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
        if bool(npc.get("alive",true)) and str(npc["place"])==place: result.append(npc.duplicate(true))
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
    if society.has("caravans"):
        lines.append("【跨区商路 · 每日按真实库存运送】")
        for shipment in society["caravans"]:
            lines.append("· %s：%s→%s，%s %d份（%s）" % [
                str(shipment.get("agent","")),str(shipment.get("from","")),str(shipment.get("to","")),
                str(shipment.get("good","")),int(shipment.get("qty",0)),
                str(shipment.get("state","idle"))])
    lines.append("【本地实时牌价】粮%d文 · 鱼%d文 · 木%d文 · 药%d文 · 器%d文" % [
        regional_price(society,region,"粮"),regional_price(society,region,"鱼"),
        regional_price(society,region,"木"),regional_price(society,region,"药"),
        regional_price(society,region,"器")])
    lines.append("【村人互助】同户支援口粮%d次；跨区货物交割%d次" % [
        int(society.get("family_support_count",0)),int(society.get("caravan_trades",0))])
    lines.append("【人生演化】职业转换%d次 · 真实死亡%d人 · 人物重要经历%d条（旧人有档案可查）" % [
        int(society.get("career_changes",0)),int(society.get("deaths",0)),
        society.get("chronicle",[]).size()])
    lines.append("【最近真实事件】")
    var events: Array=society.get("events",[])
    for e in events.slice(-6):
        lines.append("第%d日%02d时 · %s：%s" % [
            int(e.get("day",0)),int(e.get("hour",0)),
            str(e.get("npc","")),str(e.get("detail",""))])
    return "\n".join(lines)
