extends RefCounted
class_name XianfanPsyche

# Persistent, non-omniscient NPC motives. A thought is NOT a completed action.
# Rules own assets, location, harm, witnesses and history; local LLM only speaks.
const SCHEMA := 1
const ADULT_AGE := 18
const TRAITS := ["greed","compassion","empathy","self_control","honesty","justice",
    "ambition","envy","loyalty","fear","pride","curiosity","altruism",
    "dominance","caution","desire","resentment","shame","impulsivity",
    "forgiveness","diligence","attachment","risk_taking","conformity"]
const DAILY_EVENT_CAP := 7

static func _roll(key: String, maximum: int=100) -> int:
    return int(("0x"+key.sha256_text().substr(0,7)).hex_to_int()) % maxi(1,maximum)

static func _new_psyche(npc: Dictionary) -> Dictionary:
    var id:=str(npc.get("id",""))
    var traits: Dictionary={}
    for axis in TRAITS:
        # Individual dispositions; no gender, appearance, ancestry, occupation,
        # cultivator talent or wealth is treated as evidence of vice.
        traits[axis]=10+_roll(id+"|mind-v1|"+axis,81)
    if int(npc.get("age",0))<ADULT_AGE:
        traits["desire"]=0
    return {"schema":SCHEMA,"traits":traits,"stress":0,
        "adult_desire_initialized":int(npc.get("age",0))>=ADULT_AGE,"attachment":{},
        "romance_consent":{},"wishes":[],"cooldowns":{},"last_decision":"",
        "known_violations":[],"last_day":0}

static func ensure(society: Dictionary) -> bool:
    var changed:=false
    var existing: Array=[]
    existing.append_array(society.get("civic_agents",{}).values())
    existing.append_array(society.get("agents",{}).values())
    existing.append_array(society.get("cultivation_world",{}).get("agents",{}).values())
    for npc in existing:
        if not npc.has("psyche"):
            npc["psyche"]=_new_psyche(npc)
            changed=true
        else:
            var mind: Dictionary=npc["psyche"]
            if not mind.has("traits"):
                mind["traits"]=_new_psyche(npc)["traits"]
                changed=true
            # When an NPC naturally becomes an adult, initialize the adult
            # desire trait once. Never expose sexual mechanics before age 18.
            if int(npc.get("age",0))>=ADULT_AGE and (
                    not bool(mind.get("adult_desire_initialized",true))):
                var values: Dictionary=mind["traits"]
                if int(values.get("desire",0))==0:
                    values["desire"]=10+_roll(str(npc["id"])+"|mind-v1|desire",81)
                mind["adult_desire_initialized"]=true
                changed=true
            if not mind.has("romance_consent"): mind["romance_consent"]={}
            if not mind.has("cooldowns"): mind["cooldowns"]={}
            if not mind.has("known_violations"): mind["known_violations"]=[]
            if not mind.has("stress"): mind["stress"]=0
            if not mind.has("last_day"): mind["last_day"]=0
    if not society.has("psyche_cases"):
        society["psyche_cases"]=[]
        changed=true
    if not society.has("psyche_debts"):
        society["psyche_debts"]=[]
        changed=true
    if not society.has("psyche_last_day"):
        society["psyche_last_day"]=int(society.get("civic_last_day",0))
        changed=true
    return changed

static func get_traits(npc: Dictionary) -> Dictionary:
    var psyche: Dictionary=npc.get("psyche",{})
    return psyche.get("traits",{})

static func _place(npc: Dictionary) -> String:
    # Typical socializing time after work. All actor pairs must be co-located.
    return XianfanCivicPopulation._daily_place(npc,18)

static func _nearby(a: Dictionary, b: Dictionary) -> bool:
    return bool(a.get("alive",false)) and bool(b.get("alive",false)) and (
        str(a.get("id",""))!=str(b.get("id",""))) and _place(a)==_place(b)

static func _social(npc: Dictionary, other_id: String, delta: int) -> void:
    var bonds: Dictionary=npc.get("social",{})
    bonds[other_id]=clampi(int(bonds.get(other_id,0))+delta,-100,100)
    npc["social"]=bonds

static func _event(society: Dictionary, actor: Dictionary, day: int, kind: String,
        detail: String, peer: Dictionary={}) -> void:
    var line: String=detail
    # Confidential grievances and alleged crimes belong in private records,
    # not the county's world-readable public notice board.
    if kind not in ["私下盗窃","失窃","越界纠缠","拒绝并求助","借债","借出","偿债","收回借款","债务逾期"]:
        XianfanCivicPopulation._event(society,actor,day,line)
    var memoir: Array=actor.get("biography",[])
    memoir.append({"day":day,"npc":str(actor["name"]),"category":kind,
        "detail":line,"person_id":str(actor["id"]),"other_id":str(peer.get("id","")),
        "place":_place(actor),"source":"psyche_rules","confidence":"rule_confirmed"})
    if memoir.size()>128: memoir= memoir.slice(-128)
    actor["biography"]=memoir

static func _adult_pair(a: Dictionary, b: Dictionary) -> bool:
    return int(a.get("age",0))>=ADULT_AGE and int(b.get("age",0))>=ADULT_AGE

static func resolve(society: Dictionary, actor_name: String, other_name: String,
        action: String, day: int) -> Dictionary:
    # Public action result tells only what the participants can actually know.
    var people: Dictionary=society.get("civic_agents",{})
    var actor: Dictionary=people.get(actor_name,{})
    var other: Dictionary=people.get(other_name,{})
    if actor.is_empty() or other.is_empty() or not _nearby(actor,other):
        return {"ok":false,"why":"location_or_identity"}
    ensure(society)
    if day<1: return {"ok":false,"why":"invalid_date"}
    var mind: Dictionary=actor["psyche"]
    var traits: Dictionary=mind["traits"]
    var existing_cd: Dictionary=mind.get("cooldowns",{})
    var interval:=5 if action=="help" else 25
    if day-int(existing_cd.get(action,-9999))<interval:
        return {"ok":false,"why":"cooldown"}
    var other_mind: Dictionary=other["psyche"]
    var other_traits: Dictionary=other_mind["traits"]
    if action in ["express_interest","accept_courtship","boundary_violation"] and not _adult_pair(actor,other):
        return {"ok":false,"why":"adults_only"}
    var outcome: Dictionary={"ok":false,"why":"not_feasible"}
    match action:
        "help":
            if int(traits.get("compassion",0))<=55 and int(traits.get("altruism",0))<=60:
                return outcome
            if int(actor.get("coins",0))<=0 or int(other.get("coins",0))>5:
                return outcome
            var contribution:=mini(2,int(actor["coins"]))
            actor["coins"]=int(actor["coins"])-contribution
            other["coins"]=int(other["coins"])+contribution
            _social(actor,str(other["id"]),4)
            _social(other,str(actor["id"]),12)
            traits["compassion"]=mini(100,int(traits["compassion"])+1)
            other_mind["stress"]=maxi(0,int(other_mind["stress"])-6)
            _event(society,actor,day,"援助",
                "将本人实有的%d文交给正在缺钱的%s；钱财总量不变。" % [contribution,str(other["name"])],other)
            _event(society,other,day,"受到援助",
                "收到%s主动相助的%d文，记得这份帮助。" % [str(actor["name"]),contribution],actor)
            outcome={"ok":true,"kind":"help","delta_coins":contribution}
        "borrow":
            if int(actor.get("coins",0))>4 or int(other.get("coins",0))<8:
                return outcome
            var accepted:=int(other_traits.get("compassion",0))>=55 and (
                int(other.get("social",{}).get(str(actor["id"]),0))>=-10)
            if not accepted:
                _event(society,actor,day,"求借未成",
                    "向%s提出借钱请求，但对方自主拒绝，财物没有转移。" % other_name,other)
                return {"ok":true,"kind":"borrow_refused"}
            for debt in society["psyche_debts"]:
                if not (debt is Dictionary): continue
                if str(debt.get("borrower_id",""))==str(actor["id"]) and (
                        str(debt.get("lender_id",""))==str(other["id"])) and (
                        str(debt.get("status","")) in ["open","overdue"]):
                    return outcome
            var amount:=mini(3,int(other["coins"])-5)
            if amount<=0: return outcome
            actor["coins"]=int(actor["coins"])+amount
            other["coins"]=int(other["coins"])-amount
            var debt_id:="LOAN-"+str(actor["id"])+"-"+str(other["id"])+"-"+str(day)
            var loan: Dictionary={"id":debt_id,"day":day,"due_day":day+7,
                "borrower_id":str(actor["id"]),"lender_id":str(other["id"]),
                "principal":amount,"outstanding":amount,"status":"open",
                "place":_place(actor)}
            var debts: Array=society["psyche_debts"]
            debts.append(loan)
            _event(society,actor,day,"借债",
                "向%s真借得%d文，有七天归还约定；并未凭空创造钱。" % [other_name,amount],other)
            _event(society,other,day,"借出",
                "依本人意愿借给%s %d文，约定第%d日归还。" % [actor_name,amount,day+7],actor)
            outcome={"ok":true,"kind":"loan","debt_id":debt_id,"amount":amount}
        "repay":
            var matched: Dictionary={}
            for candidate in society["psyche_debts"]:
                if not (candidate is Dictionary): continue
                if str(candidate.get("borrower_id",""))==str(actor["id"]) and (
                        str(candidate.get("lender_id",""))==str(other["id"])) and (
                        str(candidate.get("status","")) in ["open","overdue"]):
                    matched=candidate
                    break
            var owed:=int(matched.get("outstanding",0))
            if owed<=0 or int(actor.get("coins",0))<owed: return outcome
            actor["coins"]=int(actor["coins"])-owed
            other["coins"]=int(other["coins"])+owed
            matched["outstanding"]=0
            matched["status"]="repaid"
            matched["repaid_day"]=day
            _social(other,str(actor["id"]),8)
            _event(society,actor,day,"偿债",
                "亲自偿还此前向%s借的%d文；债务按账核销。" % [other_name,owed],other)
            _event(society,other,day,"收回借款",
                "收到%s按真实旧借据偿还的%d文。" % [actor_name,owed],actor)
            outcome={"ok":true,"kind":"repaid","amount":owed,
                "debt_id":str(matched["id"])}
        "attempt_theft":
            if int(traits.get("greed",0))<=75 or int(traits.get("self_control",100))>=35:
                return outcome
            if int(other.get("coins",0))<=0: return outcome
            var amount:=mini(2,int(other["coins"]))
            other["coins"]=int(other["coins"])-amount
            actor["coins"]=int(actor["coins"])+amount
            _social(other,str(actor["id"]),-18)
            traits["shame"]=mini(100,int(traits["shame"])+2)
            other_mind["stress"]=mini(100,int(other_mind["stress"])+10)
            var case_id:="PC-"+str(actor["id"])+"-"+str(other["id"])+"-"+str(day)
            var case_entry: Dictionary={"id":case_id,"day":day,"kind":"theft",
                "offender_id":str(actor["id"]),"victim_id":str(other["id"]),
                "amount":amount,"evidence":0,"suspect_public":false,
                "status":"uninvestigated","location":_place(actor)}
            var cases: Array=society["psyche_cases"]
            cases.append(case_entry)
            # Offender's private memory is not public testimony. Victim cannot
            # confidently name someone without actual evidence/witnesses.
            _event(society,actor,day,"私下盗窃",
                "私下从%s身上取走%d文；此事实不应仅凭对话变成公开定罪。" % [
                    str(other["name"]),amount],other)
            _event(society,other,day,"失窃",
                "发现自己少了%d文，尚不能确认是谁所为；此事需要证据调查。" % amount,actor)
            outcome={"ok":true,"kind":"theft","case_id":case_id,"delta_coins":amount}
        "express_interest":
            if int(traits.get("desire",0))<=50 or int(traits.get("self_control",0))<25: return outcome
            var actor_id:=str(actor["id"])
            var recipient_id:=str(other["id"])
            # Consent is each person's voluntary choice; attractiveness,
            # wealth or seniority cannot force acceptance.
            var accepted:=int(other_traits.get("attachment",0))>=42 and (
                int(other_traits.get("caution",0))<=70) and (
                int(other_mind.get("stress",0))<60) and (
                int(other.get("social",{}).get(actor_id,0))>=0)
            var consent: Dictionary=other_mind["romance_consent"]
            consent[actor_id]=accepted
            if accepted:
                _social(actor,recipient_id,3)
                _social(other,actor_id,3)
                traits["loyalty"]=mini(100,int(traits["loyalty"])+1)
                _event(society,actor,day,"表达心意",
                    "向%s坦诚表达好感，对方愿意继续了解；并未自动成婚或建立亲密关系。" % other_name,other)
                _event(society,other,day,"自主选择",
                    "收到%s的好感表达，自主决定暂时愿意进一步了解。" % actor_name,actor)
            else:
                _event(society,actor,day,"表达心意",
                    "向%s表达好感，对方明确拒绝，必须尊重其边界。" % other_name,other)
                _event(society,other,day,"自主拒绝",
                    "拒绝%s的好感表达；拒绝不会被系统视为同意。" % actor_name,actor)
            outcome={"ok":true,"kind":"courtship","accepted":accepted}
        "boundary_violation":
            # Non-graphic, serious unlawful *attempt*. This action records
            # harassment and the affected person's right to refuse/report.
            # Sexual violence itself is NOT gamified or simulated here.
            if int(traits.get("desire",0))<=55 or int(traits.get("self_control",100))>=35 or int(traits.get("compassion",100))>=35:
                return outcome
            var boundaries: Dictionary=other_mind["romance_consent"]
            if bool(boundaries.get(str(actor["id"]),false)): return outcome
            _social(other,str(actor["id"]),-35)
            other_mind["stress"]=mini(100,int(other_mind["stress"])+15)
            var report_id:="BOUND-"+str(actor["id"])+"-"+str(other["id"])+"-"+str(day)
            var incident: Dictionary={"id":report_id,"day":day,
                "kind":"coercive_boundary_violation_attempt",
                "offender_id":str(actor["id"]),"victim_id":str(other["id"]),
                "evidence":1,"status":"reported_for_review","public":false,
                "location":_place(actor),"no_sexual_act_occurred":true}
            var cases: Array=society["psyche_cases"]
            cases.append(incident)
            _event(society,actor,day,"越界纠缠",
                "对%s作出不受欢迎的越界纠缠，被当事人明确拒绝并留下申诉记录；未发生进一步侵害。" % other_name,other)
            _event(society,other,day,"拒绝并求助",
                "明确拒绝%s的越界纠缠，并留下可供后续处理的申诉；不公开个人私事。" % actor_name,actor)
            outcome={"ok":true,"kind":"reported_boundary_violation","case_id":report_id}
    if bool(outcome.get("ok",false)):
        mind["last_decision"]=action
        var cooldowns: Dictionary=mind["cooldowns"]
        cooldowns[action]=day
    return outcome

static func _settle_overdue(society: Dictionary, day: int) -> void:
    var by_id: Dictionary={}
    for person in society.get("civic_agents",{}).values():
        by_id[str(person.get("id",""))]=person
    for loan in society.get("psyche_debts",[]):
        if not (loan is Dictionary) or str(loan.get("status",""))!="open": continue
        if day<=int(loan.get("due_day",day+1)): continue
        loan["status"]="overdue"
        loan["overdue_day"]=day
        var creditor: Dictionary=by_id.get(str(loan.get("lender_id","")),{})
        var debtor: Dictionary=by_id.get(str(loan.get("borrower_id","")),{})
        if creditor.is_empty() or debtor.is_empty(): continue
        _social(creditor,str(debtor["id"]),-12)
        _event(society,creditor,day,"债务逾期",
            "%s借走的%d文已逾期未归还；账上仍记录应收款，而非直接宣称对方盗窃。" % [
            str(debtor["name"]),int(loan.get("outstanding",0))],debtor)
        _event(society,debtor,day,"债务逾期",
            "欠%s的%d文已过约定日期，尚有真实还款义务。" % [
            str(creditor["name"]),int(loan.get("outstanding",0))],creditor)

static func advance_day(society: Dictionary, day: int) -> int:
    ensure(society)
    if day<=int(society.get("psyche_last_day",0)): return 0
    var people: Dictionary=society["civic_agents"]
    _settle_overdue(society,day)
    var grouped: Dictionary={}
    for name in people:
        var npc: Dictionary=people[name]
        if not bool(npc.get("alive",true)): continue
        var mind: Dictionary=npc["psyche"]
        var stress:=int(mind.get("stress",0))
        var hunger:=int(npc.get("hunger",0))
        mind["stress"]=clampi(stress+(10 if hunger>0 else -3),0,100)
        mind["last_day"]=day
        var place:=_place(npc)
        if not grouped.has(place): grouped[place]=[]
        grouped[place].append(str(name))
    var events:=0
    # Stable action selection; high drives only create motivation, not outcomes.
    for spot in grouped:
        var names: Array=grouped[spot]
        names.sort()
        if names.size()<2: continue
        for name in names:
            if events>=DAILY_EVENT_CAP: break
            var actor: Dictionary=people[name]
            var mind: Dictionary=actor["psyche"]
            var traits: Dictionary=mind["traits"]
            var opportunity:=_roll(str(actor["id"])+"|"+str(day)+"|event",1000)
            if opportunity>25: continue
            var choice:=int(_roll(str(actor["id"])+"|"+str(day)+"|friend",names.size()))
            var peer_name:=str(names[choice])
            if peer_name==name: peer_name=str(names[(choice+1)%names.size()])
            var peer: Dictionary=people[peer_name]
            var action: String=""
            if int(traits["compassion"])>70 and int(actor["coins"])>=1 and int(peer["coins"])<=5:
                action="help"
            elif int(actor["coins"])<=3 and int(peer["coins"])>=8 and (
                    int(traits["caution"])>=50):
                action="borrow"
            elif int(traits["greed"])>82 and int(traits["self_control"])<24 and (
                    int(mind["stress"])>55 or int(traits["envy"])>78) and int(peer["coins"])>0:
                action="attempt_theft"
            elif _adult_pair(actor,peer) and int(traits["attachment"])>75 and (
                    int(traits["desire"])>55) and int(traits["self_control"])>=45:
                action="express_interest"
            if action.is_empty(): continue
            var recent: Dictionary=mind["cooldowns"]
            if day-int(recent.get(action,-9999))<25: continue
            var response:=resolve(society,str(name),peer_name,action,day)
            if bool(response.get("ok",false)): events+=1
        if events>=DAILY_EVENT_CAP: break
    society["psyche_last_day"]=day
    return events

static func private_self_description(npc: Dictionary) -> String:
    var traits:=get_traits(npc)
    if traits.is_empty(): return "我的念头会随人生经历变化，不是一句善恶就能概括。"
    # A private self-report can be evasive: secret selfish motives and crimes
    # must NOT be revealed just by asking. Only own values openly stated.
    if int(traits.get("caution",50))>75:
        return "我做事比较谨慎，自己的心思不愿第一次见面就全盘托出。"
    if int(traits.get("compassion",50))>70:
        return "我会尽量顾着别人，但有时候也会犹豫，未必做得到处处周全。"
    if int(traits.get("ambition",50))>72:
        return "我想往上走，但也知道事情不能只靠一句豪言就成。"
    if int(traits.get("honesty",50))>70:
        return "我重视诺言与事实；真正做得到的事，我才愿意先应下。"
    return "我也有在意的人、想要的东西和不愿示人的念头；往后做的事才更能说明我是怎样的人。"
