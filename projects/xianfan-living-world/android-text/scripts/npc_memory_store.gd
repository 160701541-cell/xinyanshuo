extends RefCounted
class_name XianfanMemoryStore

# Per-campaign, per-person storage. Raw JSONL is append-only; compact profiles
# are derived, replaceable caches. Nothing in a summary becomes world truth.
const ROOT := "user://xianfan_npc_memory_v1"
const PROFILE_SCHEMA := 1
var campaign := ""
var _known: Dictionary = {}

func configure(identifier: String) -> void:
    campaign = identifier.sha256_text().substr(0,24)

func _person_key(person: String) -> String:
    return person.sha256_text().substr(0,18)

func _directory(person: String) -> String:
    return ROOT + "/" + campaign + "/" + _person_key(person)

func _raw_dir(person: String) -> String:
    return _directory(person) + "/raw"

func _day_file(person: String, day: int) -> String:
    return _raw_dir(person) + "/day_%06d.jsonl" % day

func _profile_file(person: String) -> String:
    return _directory(person) + "/profile.json"

func _ensure(person: String) -> bool:
    if campaign.is_empty(): return false
    var path := ProjectSettings.globalize_path(_raw_dir(person))
    return DirAccess.make_dir_recursive_absolute(path) == OK

func _initial_profile(person: String, npc: Dictionary) -> Dictionary:
    var baseline := ""
    if person=="孙成明": baseline="家务勤快，有自己的安排；是否修行由本人决定"
    elif person=="钱然泽": baseline="农户，务实谨慎，重视家中生计"
    elif person=="郑舟清": baseline="操持家务，关心家人饮食起居"
    elif not npc.is_empty():
        baseline="%s；从事%s；属于%s。核心经历应基于真实存档，不能因一次闲聊改变。" % [
            str(npc.get("trait","沉稳朴实")),str(npc.get("job","村中事务")),
            str(npc.get("household","独居"))]
    return {"schema":PROFILE_SCHEMA,"person":person,"npc_id":str(npc.get("id","")),
        "core":{"identity":person,"baseline":baseline,"immutable":true},
        "personality_notes":[],"days":{},"habits":{},"important":[],
        "total_dialogues":0,"total_life_events":0,"total_events":0,
        "last_day":0}

func _rebuild_profile(person: String, npc: Dictionary={}) -> Dictionary:
    # The profile is an expendable cache. A malformed or missing profile
    # must be reconstructed from the untouched raw archive, not "forgotten".
    var rebuilt:=_initial_profile(person,npc)
    for record in read_all(person):
        if record is Dictionary and record.has("type"):
            _derive(rebuilt,record)
    _write_profile(person,rebuilt)
    return rebuilt

func _load_profile(person: String, npc: Dictionary={}) -> Dictionary:
    var file_path:=_profile_file(person)
    if FileAccess.file_exists(file_path):
        var f:=FileAccess.open(file_path,FileAccess.READ)
        if f!=null:
            var parsed: Variant=JSON.parse_string(f.get_as_text())
            if parsed is Dictionary and int(parsed.get("schema",0))==PROFILE_SCHEMA and parsed.has("core") and parsed.has("days") and parsed.has("total_events"):
                return parsed
    return _rebuild_profile(person,npc)

func profile(person: String, npc: Dictionary={}) -> Dictionary:
    return _load_profile(person,npc).duplicate(true)

func _write_profile(person: String, p: Dictionary) -> bool:
    if not _ensure(person): return false
    var dest:=_profile_file(person)
    var tmp:=dest+".tmp"
    var f:=FileAccess.open(tmp,FileAccess.WRITE)
    if f==null: return false
    f.store_string(JSON.stringify(p,"  "))
    f.flush()
    f.close()
    var src:=ProjectSettings.globalize_path(tmp)
    var target:=ProjectSettings.globalize_path(dest)
    var prev:=ProjectSettings.globalize_path(dest+".bak")
    if FileAccess.file_exists(dest): DirAccess.copy_absolute(target,prev)
    return DirAccess.rename_absolute(src,target)==OK

func _ids(path: String) -> Dictionary:
    if _known.has(path): return _known[path]
    var result: Dictionary={}
    if FileAccess.file_exists(path):
        var file:=FileAccess.open(path,FileAccess.READ)
        if file!=null:
            while not file.eof_reached():
                var line:=file.get_line()
                if line.is_empty(): continue
                var item: Variant=JSON.parse_string(line)
                if item is Dictionary and item.has("uid"):
                    result[str(item["uid"])]=true
    _known[path]=result
    return result

func _kind_label(activity: String) -> String:
    if activity.contains("田") or activity.contains("农") or activity.contains("播种"): return "农田劳作"
    if activity.contains("饭") or activity.contains("灶") or activity.contains("厨房"): return "饮食家务"
    if activity.contains("柴") or activity.contains("整理") or activity.contains("清扫"): return "整理家事"
    if activity.contains("书") or activity.contains("温习") or activity.contains("学"): return "阅读学习"
    if activity.contains("鱼") or activity.contains("溪"): return "溪河劳动"
    return activity.substr(0,40)

func _important(utterance: String) -> bool:
    for mark in ["答应","承诺","约定","誓","背叛","救命","生死","亲人","离开","修仙","灵根","青云","宗门","成亲","永远","秘密","受伤","告别"]:
        if utterance.contains(mark): return true
    return false

func _derive(p: Dictionary, event: Dictionary) -> void:
    var day:=int(event.get("day",0))
    var daykey:=str(day)
    var days: Dictionary=p.get("days",{})
    var daily: Dictionary=days.get(daykey,{"speech":0,"life":0,"activities":{},"important_ids":[]})
    var kind:=str(event.get("type",""))
    var uid:=str(event.get("uid",""))
    if kind=="life":
        daily["life"]=int(daily.get("life",0))+1
        p["total_life_events"]=int(p.get("total_life_events",0))+1
        var activity:=_kind_label(str(event.get("activity","")))
        if not activity.is_empty():
            var acts: Dictionary=daily.get("activities",{})
            acts[activity]=int(acts.get(activity,0))+1
            daily["activities"]=acts
            # Habits are evidence-linked *observed repeated actions*, not a
            # generated personality rewrite based on one conversational claim.
            var habits: Dictionary=p.get("habits",{})
            var item: Dictionary=habits.get(activity,{"distinct_days":[],"count":0,"evidence":[]})
            var distinct: Array=item.get("distinct_days",[])
            if not distinct.has(day): distinct.append(day)
            item["distinct_days"]=distinct
            item["count"]=int(item.get("count",0))+1
            var proof: Array=item.get("evidence",[])
            if proof.size()<16: proof.append(uid)
            item["evidence"]=proof
            habits[activity]=item
            p["habits"]=habits
    elif kind=="speech":
        daily["speech"]=int(daily.get("speech",0))+1
        p["total_dialogues"]=int(p.get("total_dialogues",0))+1
        var speech:=str(event.get("player",""))+" "+str(event.get("reply",""))
        if _important(speech):
            var pinned: Array=daily.get("important_ids",[])
            if pinned.size()<24: pinned.append(uid)
            daily["important_ids"]=pinned
            var exact: Array=p.get("important",[])
            # A pointer plus short, exact quote; the original text is never
            # modified or deleted in raw/day_*.jsonl.
            exact.append({"uid":uid,"day":day,
                "player":str(event.get("player","")).substr(0,120),
                "reply":str(event.get("reply","")).substr(0,120)})
            if exact.size()>128: exact.pop_front()
            p["important"]=exact
    days[daykey]=daily
    p["days"]=days
    p["total_events"]=int(p.get("total_events",0))+1
    p["last_day"]=maxi(int(p.get("last_day",0)),day)

func append_event(person: String, event: Dictionary, npc: Dictionary={}) -> bool:
    if not _ensure(person): return false
    var uid:=str(event.get("uid",""))
    if uid.is_empty(): return false
    var p:=_load_profile(person,npc)
    var filename:=_day_file(person,int(event.get("day",0)))
    var known:=_ids(filename)
    if known.has(uid): return true
    var file: FileAccess
    if FileAccess.file_exists(filename):
        file=FileAccess.open(filename,FileAccess.READ_WRITE)
    else:
        file=FileAccess.open(filename,FileAccess.WRITE_READ)
    if file==null: return false
    file.seek_end()
    file.store_line(JSON.stringify(event))
    file.flush()
    file.close()
    known[uid]=true
    _derive(p,event)
    return _write_profile(person,p)

func archive_dialogue(person: String, record: Dictionary, npc: Dictionary={}) -> bool:
    var day:=int(record.get("day",0))
    var turn:=int(record.get("turn",0))
    var uid:=str(record.get("uid",""))
    if uid.is_empty():
        uid="D-"+str(day)+"-"+str(turn)+"-"+(JSON.stringify(record).sha256_text().substr(0,18))
    var event: Dictionary={"uid":uid,"type":"speech","day":day,
        "turn":turn,"minute":int(record.get("minute",0)),
        "player":str(record.get("player","")),"reply":str(record.get("reply","")),
        "engine":str(record.get("engine","rule")),
        "source":"NPC话语，不是事实授权"}
    return append_event(person,event,npc)

func archive_life(person: String, entry: Dictionary, npc: Dictionary={}) -> bool:
    var day:=int(entry.get("day",0))
    var uid:="L-"+str(day)+"-"+(JSON.stringify(entry).sha256_text().substr(0,18))
    var event: Dictionary={"uid":uid,"type":"life","day":day,"turn":int(entry.get("turn",0)),
        "place":str(entry.get("place","")),"activity":str(entry.get("activity","")),
        "mood":str(entry.get("mood","")),"goal":str(entry.get("goal","")),
        "source":"世界演算观察"}
    return append_event(person,event,npc)

func sync_legacy(state: Dictionary) -> int:
    # Safe, restartable migration from old large save dictionaries.
    var synced:=0
    var archive: Array=state.get("dialogue_archive",[])
    for i in range(archive.size()):
        var r: Variant=archive[i]
        if not (r is Dictionary): continue
        var who:=str(r.get("speaker",""))
        if not state.get("npc",{}).has(who): continue
        var copy: Dictionary=r.duplicate(true)
        if not copy.has("uid"): copy["uid"]="legacy-"+str(i)+"-"+JSON.stringify(r).sha256_text().substr(0,18)
        if archive_dialogue(who,copy,state["npc"][who]): synced+=1
    # Earliest versions stored dialogue only in npc_memories; use it only
    # when no common archive was present, avoiding duplicate migrations.
    if archive.is_empty():
        var bank: Dictionary=state.get("npc_memories",{})
        for who in bank:
            if not state.get("npc",{}).has(who): continue
            var older: Array=bank[who]
            for i in range(older.size()):
                var v: Variant=older[i]
                if not (v is Dictionary): continue
                var entry: Dictionary=v.duplicate(true)
                entry["uid"]="early-"+str(i)+"-"+JSON.stringify(v).sha256_text().substr(0,18)
                if archive_dialogue(str(who),entry,state["npc"][who]): synced+=1
    for old in state.get("npc_life_events",[]):
        if not (old is Dictionary): continue
        var who:=str(old.get("npc",""))
        if state.get("npc",{}).has(who):
            if archive_life(who,old,state["npc"][who]): synced+=1
    return synced

func _two_grams(query: String) -> Array[String]:
    var tokens: Array[String]=[]
    var text:=query.strip_edges()
    for i in range(maxi(0,text.length()-1)):
        var pair:=text.substr(i,2)
        if not tokens.has(pair): tokens.append(pair)
    return tokens

func recall(person: String, query: String, limit: int=8) -> Array:
    # On-demand scan of disk, without loading the whole lifetime into RAM.
    # Exact high-salience experiences rank above mundane text; no AI summary
    # can permanently erase memories because original records remain on disk.
    var directory:=_raw_dir(person)
    if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(directory)): return []
    var days:=DirAccess.get_files_at(directory)
    days.sort()
    var tokens:=_two_grams(query)
    var ranked: Array=[]
    var sequence:=0
    for file_name in days:
        if not str(file_name).ends_with(".jsonl"): continue
        var handle:=FileAccess.open(directory+"/"+str(file_name),FileAccess.READ)
        if handle==null: continue
        while not handle.eof_reached():
            var line:=handle.get_line()
            if line.is_empty(): continue
            var val: Variant=JSON.parse_string(line)
            if not (val is Dictionary): continue
            var item: Dictionary=val
            if str(item.get("type",""))!="speech": continue
            var words:=str(item.get("player",""))+" "+str(item.get("reply",""))
            var score:=0
            for gram in tokens:
                if words.contains(gram): score+=1
            if score>0:
                ranked.append({"score":score,"index":sequence,"event":item})
            sequence+=1
    ranked.sort_custom(func(a,b):
        if int(a["score"])!=int(b["score"]): return int(a["score"])>int(b["score"])
        return int(a["index"])>int(b["index"]))
    var result: Array=[]
    for i in range(mini(clampi(limit,0,32),ranked.size())):
        result.append(ranked[i]["event"])
    return result

func read_all(person: String) -> Array:
    # For export or user-requested inspection, not normal prompt assembly.
    var result: Array=[]
    var directory:=_raw_dir(person)
    if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(directory)): return result
    var paths:=DirAccess.get_files_at(directory)
    paths.sort()
    for path in paths:
        if not str(path).ends_with(".jsonl"): continue
        var f:=FileAccess.open(directory+"/"+str(path),FileAccess.READ)
        if f==null: continue
        while not f.eof_reached():
            var line:=f.get_line()
            if line.is_empty(): continue
            var parsed: Variant=JSON.parse_string(line)
            if parsed is Dictionary: result.append(parsed)
    return result

func digest(person: String, npc: Dictionary={}) -> Dictionary:
    var p:=profile(person,npc)
    var summaries: Array[String]=[]
    var daily: Dictionary=p.get("days",{})
    var dates: Array=daily.keys()
    dates.sort()
    for i in range(maxi(0,dates.size()-7),dates.size()):
        var date:=str(dates[i])
        var day: Dictionary=daily[date]
        var activities: Dictionary=day.get("activities",{})
        var descriptions: Array[String]=[]
        for action in activities:
            descriptions.append("%s×%d" % [str(action),int(activities[action])])
        summaries.append("第%s日：交谈%d次、生活%d次；%s" % [
            date,int(day.get("speech",0)),int(day.get("life",0)),"、".join(descriptions)])
    var observed: Array[String]=[]
    var habits: Dictionary=p.get("habits",{})
    for action in habits:
        var habit: Dictionary=habits[action]
        if habit.get("distinct_days",[]).size()>=3:
            observed.append("%s（%d个不同日，证据记录可追溯）" % [str(action),habit["distinct_days"].size()])
    return {"person":person,"anchor":p.get("core",{}),
        "habits":observed,"last_week":summaries,
        "important":p.get("important",[]).slice(-12),
        "total_raw":int(p.get("total_events",0)),"total_dialogues":int(p.get("total_dialogues",0)),
        "notes":"摘要只是索引；raw文件完整保留，旧话不是世界规则事实。"}
