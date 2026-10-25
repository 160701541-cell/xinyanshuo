extends RefCounted
class_name XianfanCivicPopulation

# Named civic population is saved permanently, but settles at daily cadence
# rather than spending 8B inference or per-frame scripts for everyone.
const SCHEMA := 1
const SURNAME := ["唐","赵","周","方","石","叶","吕","柏","林","蒲","孔","霍","柳","秦","陆","顾","严","裴","沈","谢","宋","鲁","陈","杜","许","崔","徐","韩","苏","魏","袁","程"]
const GIVEN := ["青","云","山","玉","春","秋","安","怀","志","景","文","知","书","海","小","明","静","兰","远","正","初","月","柳","川","宁","成","星","玉","承","若","景","天"]
const ENDING := ["生","禾","林","平","川","元","安","石","青","明","秀","远"]
# Domain, registered jobs, organization, class, sample workplace, economic
# effect (source-limited daily, not free item creation).
const DOMAINS := [
    ["农桑",["自耕农","佃农","稻农","菜农","果农","桑农","茶农","蚕农","牧牛人","牧羊人","水渠工","农田管事"],"村社田庄","平民","石桥村·田边","grain"],
    ["山林",["樵户","木炭匠","采药人","药农","山货采办","猎户","护林人","竹匠","采笋人","采茶人","野蜂采蜜人","林道修缮工"],"山林行会","平民","石桥村·林缘","wood"],
    ["水业",["渔户","河船夫","渡船客","蟹户","养鱼人","渔网工","舟子","码头管事","水车修理人","河道巡护","鱼市贩","摆渡学徒"],"溪河水业","平民","石桥村·溪边","fish"],
    ["金石工艺",["铁匠","铜匠","银匠","石匠","泥瓦匠","瓦匠","陶匠","木雕匠","竹编匠","造纸工","制墨匠","刻印匠"],"百工行会","匠户","临安县城·东市","craft"],
    ["纺织衣饰",["纺线工","织布工","染坊师傅","绣娘","裁缝","皮匠","鞋匠","制帽匠","洗衣人","衣铺掌柜","织机修理人","布料行商"],"布业行会","匠户","临安县城·东市","craft"],
    ["市场贸易",["米铺掌柜","油铺掌柜","布商","药商","货栈管事","行商","牙人","账房先生","典当伙计","香料商","杂货贩","市场秤手"],"临安商会","商籍","临安县城·东市","trade"],
    ["物流行旅",["镖师","车夫","脚夫","马夫","驿卒","货郎","商队领队","驮队伙计","仓储守夜人","渡口管事","官道修路工","码头搬运"],"官道镖行","平民","临安官道","service"],
    ["餐饮旅舍",["酒楼掌柜","客栈掌柜","厨子","面点师","豆腐匠","茶博士","卖饼人","屠户","酿酒工","酒坊管事","糕点师","客栈店小二"],"饮食商帮","商籍","临安县城·东市","service"],
    ["医药济世",["郎中","医馆学徒","采药学徒","产婆","接骨匠","针灸师","药柜先生","坐堂大夫","护理人","药房账房","医馆伙计","义诊医者"],"医药同仁会","平民","临安县城·南巷","heal"],
    ["文教百艺",["私塾先生","书院生员","童生","书吏","抄书人","印坊匠","画师","琴师","说书人","戏班伶人","戏班班主","棋馆主人"],"临安书院","士籍","临安县城·南巷","service"],
    ["官府军政",["县令","县丞","主簿","典史","衙役","捕快","里正","保甲长","税吏","仓曹","巡检","边防卒"],"临安县衙","吏籍","临安县城·南巷","administration"],
    ["寺观民俗",["僧人","住持","庙祝","道童","香客接待","香烛商","礼生","讲经人","钟鼓手","寺田农户","观中账房","观庙修缮人"],"临安寺观","出家/平民","临安县城·南巷","service"],
    ["修行外围",["寻仙少年","引气旁听生","山门脚夫","灵田杂役","书阁抄录人","练功场杂役","丹房童子","灵兽饲养人","灵植学徒","法器修缮人","外门膳房人","行脚访仙客"],"青云山门外围","待测灵根","青云山门·山门外","service"],
    ["社会边缘",["漂泊流民","乞食人","杂役","家仆","更夫","寡居者","无业人","孤儿照看人","廉价脚夫","卖柴童工","守墓人","行乞艺人"],"乡民互助","贫苦/流寓","石桥村·街口","service"]
]
const ACTIVE_COUNT_PER_ROLE := 2
const MAX_DAILY_HIGHLIGHTS := 32

static func job_catalog() -> Array[Dictionary]:
    var roles: Array[Dictionary]=[]
    for row in DOMAINS:
        for occupation in row[1]:
            roles.append({"job":str(occupation),"sector":str(row[0]),
                "faction":str(row[2]),"standing":str(row[3]),
                "base_place":str(row[4]),"effect":str(row[5])})
    return roles

static func _name(idx: int) -> String:
    var given:=GIVEN[idx%GIVEN.size()]
    var suffix:=ENDING[int(idx/GIVEN.size())%ENDING.size()]
    var surname:=SURNAME[idx%SURNAME.size()]
    return surname+given+suffix

static func _region(npc: Dictionary) -> String:
    return str(npc.get("region","村"))

static func _house(region: String, idx: int) -> String:
    return ("石桥村" if region=="村" else "临安县城") + "·" + ("街口" if region=="村" else "南巷")

static func _daily_place(npc: Dictionary, hour: int) -> String:
    if not bool(npc.get("alive",true)): return "故人名录"
    if hour<7 or hour>=19: return str(npc["home"])
    if hour in [12,18]: return str(npc["home"])
    return str(npc["work_place"])

static func initialize(society: Dictionary, start_hour: int) -> bool:
    if society.has("civic_agents"): return false
    var civilians: Dictionary={}
    var roles:=job_catalog()
    var idx:=0
    for role in roles:
        var card: Dictionary=role
        for variant in range(ACTIVE_COUNT_PER_ROLE):
            # Each occupation has one local and one city/outer-village
            # practitioner. Factions and social status are separate from job.
            var region: String="村" if variant==0 else "城"
            if str(card["sector"])=="官府军政": region="城"
            if str(card["sector"])=="修行外围": region="村"
            var home:=_house(region,idx)
            var name:=_name(idx)
            var base:=str(card["base_place"])
            var workplace:=base if variant==1 else (
                "石桥村·田边" if str(card["effect"])=="grain" else
                "石桥村·林缘" if str(card["effect"])=="wood" else
                "石桥村·溪边" if str(card["effect"])=="fish" else
                "石桥村·街口")
            if str(card["sector"])=="修行外围": workplace="青云山门·山门外"
            civilians[name]={
                "id":"CIV%06d"%(idx+1),"name":name,"age":16+(idx*13)%50,
                "job":str(card["job"]),"sector":str(card["sector"]),
                "faction":str(card["faction"]),"standing":str(card["standing"]),
                "effect":str(card["effect"]),"region":region,"origin":home.split("·")[0],
                "home":home,"work_place":workplace,"place":_daily_place(
                    {"alive":true,"home":home,"work_place":workplace},start_hour%24),
                "activity":"照看自己家业","mood":"平静",
                "trait":"以%s为生，有自己的生活与选择" % str(card["job"]),
                "wish":"在%s安稳立足" % str(card["faction"]),
                "coins":5+idx%9,"rations":3,"energy":60+idx%34,"health":100,
                "hunger":0,"work_done":0,"social":{},"cargo":{},
                "household":"民户-%04d"%int(idx/3+1),
                "skills":{str(card["job"]):1},"biography":[],"alive":true,
                "born_hour":start_hour,"last_day":int(start_hour/24)+1,
                "root":"待鉴定" # not a verified cultivator or free breakthrough
            }
            idx+=1
    society["civic_agents"]=civilians
    society["civic_schema"]=SCHEMA
    society["civic_last_day"]=int(start_hour/24)+1
    society["civic_life_events"]=[]
    society["civic_total_work"]=0
    society["civic_total_trade"]=0
    return true

static func valid(society: Dictionary) -> bool:
    if not society.has("civic_agents"): return true
    for person in society["civic_agents"].values():
        var npc: Dictionary=person
        if str(npc.get("id","")).is_empty(): return false
        if int(npc.get("coins",-1))<0 or int(npc.get("rations",-1))<0: return false
        if int(npc.get("health",-1))<0 or int(npc.get("energy",-1))<0: return false
        if int(npc.get("hunger",-1))<0: return false
    return true

static func _event(society: Dictionary, npc: Dictionary, day: int, detail: String) -> void:
    var events: Array=society.get("civic_life_events",[])
    events.append({"day":day,"npc":str(npc["name"]),"uid":str(npc["id"]),
        "sector":str(npc["sector"]),"detail":detail})
    if events.size()>MAX_DAILY_HIGHLIGHTS: events.pop_front()
    society["civic_life_events"]=events

static func _produce(society: Dictionary, npc: Dictionary, day: int) -> bool:
    var region: Dictionary=society["regions"][_region(npc)]
    var stock: Dictionary=region["stock"]
    var wild: Dictionary=region["wild"]
    var effect:=str(npc["effect"])
    var made:=false
    match effect:
        "grain":
            if int(wild["肥力"])>=2 and int(stock["粮"])<900:
                wild["肥力"]=int(wild["肥力"])-2
                stock["粮"]=int(stock["粮"])+2
                made=true
        "wood":
            if int(wild["木林"])>=1 and int(stock["木"])<220:
                wild["木林"]=int(wild["木林"])-1
                stock["木"]=int(stock["木"])+1
                made=true
        "fish":
            if int(wild["野鱼"])>=1 and int(stock["鱼"])<80:
                wild["野鱼"]=int(wild["野鱼"])-1
                stock["鱼"]=int(stock["鱼"])+1
                made=true
        "craft":
            if int(stock["木"])>=2 and int(stock["器"])<160:
                stock["木"]=int(stock["木"])-2
                stock["器"]=int(stock["器"])+1
                made=true
        "heal":
            # Healthcare is a paid service requiring real medicines. One
            # unit of herb is consumed even when no NPC is actively injured.
            if int(stock["药"])>=1 and int(npc["energy"])<=80:
                stock["药"]=int(stock["药"])-1
                npc["energy"]=mini(100,int(npc["energy"])+12)
                made=true
        "trade":
            made=true # logistics/market work uses time, creates no goods
        "administration":
            made=true # administration keeps duties, no minted taxes
        "service":
            made=true
    if not made: return false
    var skills: Dictionary=npc["skills"]
    var occupation:=str(npc["job"])
    skills[occupation]=int(skills.get(occupation,0))+1
    npc["work_done"]=int(npc["work_done"])+1
    society["civic_total_work"]=int(society.get("civic_total_work",0))+1
    # Pay from existing regional treasury; coin conservation across society.
    var salary: int=2 if effect in ["administration","heal","craft"] else 1
    var pay:=mini(salary,int(region["treasury"]))
    region["treasury"]=int(region["treasury"])-pay
    npc["coins"]=int(npc["coins"])+pay
    if int(npc["work_done"])==12:
        _event(society,npc,day,"凭真实工作积累12次本职经验，行当逐渐熟练。")
    return true

static func _eat(society: Dictionary, npc: Dictionary, day: int) -> void:
    var region: Dictionary=society["regions"][_region(npc)]
    if int(npc["rations"])<2:
        var base_price:=2
        var remaining:=int(region["stock"]["粮"])
        var target:=120 if _region(npc)=="村" else 300
        if remaining<=target/4: base_price+=3
        elif remaining<=target/2: base_price+=2
        elif remaining>=target*3: base_price-=2
        elif remaining>=target*2: base_price-=1
        var cost:=maxi(1,base_price)
        if int(npc["coins"])>=cost and int(region["stock"]["粮"])>=1:
            npc["coins"]=int(npc["coins"])-cost
            region["treasury"]=int(region["treasury"])+cost
            region["stock"]["粮"]=int(region["stock"]["粮"])-1
            npc["rations"]=int(npc["rations"])+1
            society["civic_total_trade"]=int(society.get("civic_total_trade",0))+1
    if int(npc["rations"])>=1:
        npc["rations"]=int(npc["rations"])-1
        npc["hunger"]=maxi(0,int(npc["hunger"])-1)
    else:
        npc["hunger"]=int(npc["hunger"])+1
        npc["health"]=maxi(0,int(npc["health"])-2)
        npc["mood"]="饥饿"
        if int(npc["hunger"])==2: _event(society,npc,day,"两天未能买到食物，正在设法寻求帮助。")

static func _live_day(society: Dictionary, day: int) -> void:
    # One deterministic settlement per day per registered civic person.
    var people: Dictionary=society.get("civic_agents",{})
    for name in people:
        var npc: Dictionary=people[name]
        if not bool(npc.get("alive",true)): continue
        if int(npc["health"])<=0:
            # Civic demographic deaths must also retain their identity and
            # transfer all spendable money and food to the public ledger.
            var zone: Dictionary=society["regions"][_region(npc)]
            zone["treasury"]=int(zone["treasury"])+int(npc["coins"])
            zone["stock"]["粮"]=int(zone["stock"]["粮"])+int(npc["rations"])
            npc["coins"]=0
            npc["rations"]=0
            npc["alive"]=false
            npc["death_day"]=day
            npc["activity"]="已故"
            npc["place"]="故人名录"
            _event(society,npc,day,"因健康耗尽离世，原始身份保留，遗产归入公共库。")
            continue
        npc["energy"]=mini(100,int(npc["energy"])+8)
        _produce(society,npc,day)
        _eat(society,npc,day)
        npc["last_day"]=day
        if day%360==0:
            npc["age"]=int(npc["age"])+1
            if int(npc["age"])>=72: npc["health"]=maxi(0,int(npc["health"])-2)
        if int(npc["hunger"])>=2:
            npc["wish"]="筹粮与寻求可靠生计"
        elif int(npc["coins"])>=20:
            npc["wish"]="扩展本业的家产和人脉"
        else:
            npc["wish"]="在%s立足" % str(npc["faction"])

static func advance_daily(society: Dictionary, absolute_hour: int) -> int:
    var current_day:=int(absolute_hour/24)+1
    var start:=int(society.get("civic_last_day",current_day))
    if current_day<=start: return 0
    var n:=0
    for day in range(start+1,current_day+1):
        _live_day(society,day)
        n+=1
    society["civic_last_day"]=current_day
    return n

static func snapshot(society: Dictionary, person: String, hour: int) -> Dictionary:
    var npc: Dictionary=society.get("civic_agents",{}).get(person,{})
    if npc.is_empty(): return {}
    var result: Dictionary=npc.duplicate(true)
    result["place"]=_daily_place(npc,hour%24)
    if bool(result.get("alive",true)):
        result["activity"]="做%s的本职工作" % str(result["job"]) if hour%24>=7 and hour%24<18 else "回到居所休息"
    return result

static func nearby(society: Dictionary, place: String, hour: int) -> Array[Dictionary]:
    var list: Array[Dictionary]=[]
    for name in society.get("civic_agents",{}):
        var npc:=snapshot(society,str(name),hour)
        if str(npc.get("place",""))==place and bool(npc.get("alive",true)):
            list.append(npc)
    return list

static func roster(society: Dictionary, sector: String="", page: int=0, count: int=15) -> Dictionary:
    var members: Array[Dictionary]=[]
    for name in society.get("civic_agents",{}):
        var npc: Dictionary=society["civic_agents"][name]
        if not sector.is_empty() and str(npc.get("sector",""))!=sector: continue
        members.append({"id":str(npc["id"]),"name":str(name),"job":str(npc["job"]),
            "sector":str(npc["sector"]),"standing":str(npc["standing"]),
            "faction":str(npc["faction"]),"alive":bool(npc.get("alive",true)),
            "work_place":str(npc["work_place"])})
    var size:=members.size()
    var per:=clampi(count,1,30)
    var pages:=maxi(1,int(ceili(float(size)/float(per))))
    var p:=clampi(page,0,pages-1)
    return {"size":size,"page":p,"pages":pages,"entries":members.slice(p*per,mini(size,(p+1)*per))}

static func statistics(society: Dictionary) -> String:
    var counts: Dictionary={}
    var statuses: Dictionary={}
    var living:=0
    for person in society.get("civic_agents",{}).values():
        var npc: Dictionary=person
        if bool(npc.get("alive",true)): living+=1
        var sec:=str(npc["sector"])
        counts[sec]=int(counts.get(sec,0))+1
        var standing:=str(npc["standing"])
        statuses[standing]=int(statuses.get(standing,0))+1
    var lines: Array[String]=["【多身份居民登记】%d名永久有ID具名人物（在世%d人；死亡不删除原始档案）"%[
        society.get("civic_agents",{}).size(),living],"【职业谱系】"]
    for sector in counts:
        lines.append("%s %d人" % [str(sector),int(counts[sector])])
    lines.append("【阶层/身份登记】")
    for standing in statuses:
        lines.append("%s %d人" % [str(standing),int(statuses[standing])])
    lines.append("【低频生活账本】已结算生产/劳务%d次，买粮交易%d次；所有个人现金来自现存库银和交易。" % [
        int(society.get("civic_total_work",0)),int(society.get("civic_total_trade",0))])
    return "\n".join(lines)
