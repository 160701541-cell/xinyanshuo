extends RefCounted
class_name XianfanNarrativeDB
# Offline authored responses grounded in the current authoritative world save.
# No model, internet, or fabricated historical facts are needed for a hit.
const CATALOG := "res://data/narrative_dialogue_v1.json"
var _topics: Array=[]
var _loaded := false

func _init() -> void:
    var stream:=FileAccess.open(CATALOG,FileAccess.READ)
    if stream==null: return
    var payload: Variant=JSON.parse_string(stream.get_as_text())
    if payload is Dictionary and int(payload.get("schema",0))==1:
        _topics=payload.get("topics",[])
        _loaded=true

func catalog_count() -> int:
    var count:=0
    for topic in _topics:
        if not (topic is Dictionary): continue
        for lines in topic.get("voices",{}).values():
            count+=lines.size()
    return count

static func _voice(name: String, npc: Dictionary) -> String:
    if name=="孙成明": return "sister"
    if name=="钱然泽": return "father"
    if name=="郑舟清": return "mother"
    if bool(npc.get("cultivation_member",false)): return "cultivator"
    if str(npc.get("sect_contract",""))=="山门役仆": return "sect_servant"
    if bool(npc.get("sect_boarding",false)): return "sect_mortal"
    var work:=str(npc.get("job",""))
    var domain:=str(npc.get("sector",""))
    if domain.contains("官府") or work.contains("衙") or work.contains("巡") or work.contains("县令") or work.contains("吏"): return "official"
    if domain.contains("文教") or work.contains("先生") or work.contains("书") or work.contains("学") or work.contains("刻印"): return "scholar"
    if domain.contains("市场") or domain.contains("贸易") or work.contains("商") or work.contains("贩") or work.contains("掌柜"): return "merchant"
    if domain.contains("农桑") or work.contains("农") or work.contains("牧") or work.contains("田"): return "farmer"
    if domain.contains("金石") or domain.contains("纺织") or work.contains("匠") or work.contains("工"): return "artisan"
    if domain.contains("水业") or domain.contains("山林") or work.contains("脚夫") or work.contains("船") or work.contains("猎"): return "traveler"
    return "resident"

static func _selection(seed: String, count: int) -> int:
    if count<=0: return 0
    var digest:=seed.sha256_text()
    return ("0x"+digest.substr(0,6)).hex_to_int()%count

# Independent, stable behavioral tendencies for every registered identity. The
# existing "trait", goals, relationships and memories remain authoritative;
# this profile changes how facts are expressed, NEVER what happened.
static func voice_profile(person: String, npc: Dictionary) -> Dictionary:
    var identity:=str(npc.get("id",person))
    var axes: Dictionary={}
    for axis in ["caution","curiosity","empathy","directness","privacy","initiative"]:
        axes[axis]=_selection(identity+"|"+axis,5)
    # The lasting rule-driven psychological state is authoritative when
    # available; older NPCs retain deterministic six-axis legacy voices.
    var actual: Dictionary=npc.get("psyche",{}).get("traits",{})
    if not actual.is_empty():
        axes["caution"]=clampi(int(actual.get("caution",50)/25),0,4)
        axes["curiosity"]=clampi(int(actual.get("curiosity",50)/25),0,4)
        axes["empathy"]=clampi(int(actual.get("empathy",50)/25),0,4)
        axes["directness"]=clampi(int(actual.get("honesty",50)/25),0,4)
        axes["privacy"]=clampi(int(actual.get("caution",50)/25),0,4)
        axes["initiative"]=clampi(int(actual.get("ambition",50)/25),0,4)
    axes["existing_trait"]=str(npc.get("trait",""))
    axes["voice"]=_voice(person,npc)
    return axes

static func _unpack_speech(person: String, phrase: String, npc: Dictionary, data: Dictionary) -> String:
    var value:=phrase
    var substitutions: Dictionary={
        "{name}":person,"{job}":str(npc.get("job","家务")),
        "{activity}":str(npc.get("activity","照顾手头的事")),
        "{place}":str(npc.get("place","附近")),
        "{wish}":str(npc.get("wish","平安过日子")),
        "{day}":str(data.get("day",0)),
        "{realm}":str(npc.get("realm","未测境界"))}
    for key in substitutions: value=value.replace(str(key),str(substitutions[key]).substr(0,90))
    return value

static func _first_person_fact(name: String, npc: Dictionary) -> String:
    var events: Array=npc.get("biography",[])
    for idx in range(events.size()-1,-1,-1):
        if not (events[idx] is Dictionary): continue
        var entry: Dictionary=events[idx]
        if str(entry.get("npc",name))!=name: continue
        var detail:=str(entry.get("detail","")).strip_edges()
        if not detail.is_empty():
            return "第%d日我亲身经历过：%s" % [int(entry.get("day",0)),detail.substr(0,120)]
    return ""

func answer(person: String, question: String, data: Dictionary) -> Dictionary:
    if not _loaded: return {"covered":false,"reason":"catalog_not_loaded"}
    var npc: Dictionary=data.get("npc",{}).get(person,{})
    if npc.is_empty() or not bool(npc.get("alive",true)):
        return {"covered":false,"reason":"absent_or_dead"}
    if str(npc.get("place",""))!=str(data.get("place","")):
        return {"covered":false,"reason":"not_here"}
    var query:=question.strip_edges()
    for prefix in ["跟"+person+"说：","跟"+person+"说:","对"+person+"说：","对"+person+"说:","问"+person]:
        if query.begins_with(prefix):
            query=query.trim_prefix(prefix).strip_edges()
            break
    if query.is_empty(): return {"covered":false,"reason":"empty"}
    if query.contains("强奸") or query.contains("性侵") or query.contains("强迫亲密"):
        return {"covered":true,"reply":"强迫他人违背意愿是严重伤害。任何亲密关系都必须尊重对方明确的自主选择；遇到威胁应优先保护当事人并寻求可靠帮助。",
            "topic":"protect_personal_boundaries","voice":_voice(person,npc),
            "source":"authored-local-library","speaker_id":str(npc.get("id",""))}
    if query.contains("你是什么样的人") or query.contains("你的性格是什么") or query.contains("你心里想什么") or query.contains("你有什么欲望"):
        return {"covered":true,"reply":XianfanPsyche.private_self_description(npc),
            "topic":"private_psyche_self_view","voice":_voice(person,npc),
            "source":"verified-world-personality","speaker_id":str(npc.get("id",""))}
    # Adult romance and sexual desire are not simulated for minors. Rejecting
    # a conversation invitation never creates a consensual relationship.
    var asks_adult_intimacy:=query.contains("性欲") or query.contains("亲密关系") or (
        query.contains("恋爱") or query.contains("结婚") or query.contains("成亲"))
    if asks_adult_intimacy and int(npc.get("age",18))<18:
        return {"covered":true,"reply":"这些成人之间的私事我暂时不想谈。每个人的想法和界限都应得到尊重。",
            "topic":"age_appropriate_boundary","voice":_voice(person,npc),
            "source":"authored-local-library","speaker_id":str(npc.get("id",""))}
    # Query the present speaker's actual certificate. Never infer the player's
    # undisclosed root or claim a random cultivator has passed a test.
    var asks_root:=query.contains("你的灵根") or query.contains("你是什么灵根") or query.contains("你测过灵根")
    var asks_realm:=query.contains("你现在什么境界") or query.contains("你修炼到") or query.contains("你是炼气几层")
    if asks_root or asks_realm:
        var verified:=bool(npc.get("root_verified",false))
        var root_info:=str(npc.get("root","待鉴定")) if verified else "尚无可信测灵记录"
        var realm_info:=str(npc.get("realm","尚无明确境界")) if bool(npc.get("cultivation_member",false)) else "未登记修为"
        var personal: String=""
        if asks_root:
            personal="我的根性记录是%s。" % root_info if verified else "我尚无可信的测灵记录，不会胡乱认定自己的根性。"
        if asks_realm:
            personal+="我目前的修行境界是%s。" % realm_info
        return {"covered":true,"reply":personal,"topic":"verified_personal_status",
            "voice":_voice(person,npc),"source":"verified-world-fact",
            "speaker_id":str(npc.get("id",""))}
    # First-person physiology facts must be derived from the live record, not
    # guessed from the speaker's clothing, title or faction membership.
    if query.contains("你辟谷了吗") or query.contains("你会辟谷吗") or query.contains("你还需要吃饭吗"):
        var rank:=int(npc.get("realm_level",0))
        if rank<14:
            return {"covered":true,"reply":"我目前并未到能凭辟谷丹或功法维持辟谷的筑基境界，仍需正常吃饭起居。",
                "topic":"verified_diet","voice":_voice(person,npc),"source":"verified-world-fact",
                "speaker_id":str(npc.get("id",""))}
        var today_fasting:=bool(npc.get("physiology",{}).get("bigu_today",false))
        var message: String="我今天已有有效辟谷手段，不必为了饱腹进食，但仍可自愿品尝佳肴。" if today_fasting else "我虽有筑基境界，但今天没有有效的辟谷维持，仍需正常吃饭起居。"
        return {"covered":true,"reply":message,"topic":"verified_diet",
            "voice":_voice(person,npc),"source":"verified-world-fact",
            "speaker_id":str(npc.get("id",""))}
    var selected: Dictionary={}
    var top_score:=0
    for entry in _topics:
        if not (entry is Dictionary): continue
        var topic: Dictionary=entry
        var score:=0
        for word in topic.get("keywords",[]):
            if query.contains(str(word)): score+=str(word).length()*10
        if score>0: score+=int(topic.get("priority",0))
        if score>top_score:
            selected=topic
            top_score=score
    if selected.is_empty(): return {"covered":false,"reason":"uncovered_question"}
    var voice:=_voice(person,npc)
    var voices: Dictionary=selected.get("voices",{})
    var lines: Array=voices.get(voice,voices.get("resident",[]))
    if lines.is_empty(): return {"covered":false,"reason":"missing_voice"}
    var topic_id:=str(selected.get("id",""))
    var repeat_count:=0
    for item in data.get("dialogue_log",[]):
        if not (item is Dictionary): continue
        if str(item.get("speaker",""))==person and str(item.get("topic",""))==topic_id:
            repeat_count+=1
    var index:=(_selection(str(npc.get("id",person))+"|"+topic_id,lines.size())+repeat_count)%lines.size()
    var text:=_unpack_speech(person,str(lines[index]),npc,data)
    if topic_id=="personal_history":
        var personal_fact:=_first_person_fact(person,npc)
        if not personal_fact.is_empty():
            text=personal_fact+"。"+text
    if topic_id=="recent_events":
        # No omniscience: private actor milestones, county ledgers and rumor
        # are not automatically public knowledge. Only verified self-events
        # may be added to speech, never an imagined public scandal.
        var personal_event:=_first_person_fact(person,npc)
        if not personal_event.is_empty():
            text=personal_event+"。"+text
    var profile:=voice_profile(person,npc)
    if topic_id in ["aspiration","trust","family","personal_history"]:
        if int(profile["privacy"])>=4:
            text+=" 有些涉及我自己的事，熟到一定地步我才愿意细讲。"
        elif int(profile["curiosity"])>=4:
            text+=" 我也想听听，你为什么会这样想？"
        elif int(profile["directness"])>=4:
            text+=" 若有具体事，就直接说吧。"
        elif int(profile["caution"])>=4:
            text+=" 这话说定之前，我还想核对清楚。"
    return {"covered":true,"reply":text,"topic":topic_id,"voice":voice,
        "personality_profile":profile,
        "source":"authored-local-library","speaker_id":str(npc.get("id",""))}
