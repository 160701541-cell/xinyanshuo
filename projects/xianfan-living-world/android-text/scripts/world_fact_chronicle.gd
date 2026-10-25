extends RefCounted
class_name XianfanWorldFactChronicle
# Append-only local event ledger. Real events alone may be entered by the rules
# engine; authored story suggestions and NPC rumors never go here.
# A SQLite backend may later replace this indexed JSONL store without rewriting
# the authoritative events or NPC memory files.
const ROOT := "user://xianfan_world_facts_v1"
const SCHEMA := 1
var _path := ""
var _seen: Dictionary={}
var _readable := false

func configure(campaign: String) -> bool:
    if campaign.is_empty(): return false
    if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ROOT))!=OK: return false
    _path=ROOT+"/"+campaign.sha256_text().substr(0,24)+".jsonl"
    _seen.clear()
    _readable=true
    if not FileAccess.file_exists(_path): return true
    var input:=FileAccess.open(_path,FileAccess.READ)
    if input==null:
        _readable=false
        return false
    while not input.eof_reached():
        var text_line:=input.get_line().strip_edges()
        if text_line.is_empty(): continue
        var item: Variant=JSON.parse_string(text_line)
        if item is Dictionary and str(item.get("id",""))!="":
            _seen[str(item["id"])]=true
    return true

func append_rule_fact(source: String, person: String, day: int, detail: String, original_uid: String="", place: String="") -> bool:
    if not _readable or _path.is_empty(): return false
    if source not in ["society_milestone","civic_life","rule_action"]: return false
    if person.is_empty() or detail.strip_edges().is_empty() or day<1: return false
    var normalized:=source+"|"+person+"|"+str(day)+"|"+original_uid+"|"+detail
    var event_id:="FACT-"+normalized.sha256_text().substr(0,24)
    if _seen.has(event_id): return true
    var record: Dictionary={"schema":SCHEMA,"id":event_id,"source":source,
        "person":person,"day":day,"detail":detail.substr(0,500),
        "original_uid":original_uid,"place":place,
        "public":false,"confidence":"rule_confirmed"}
    var file: FileAccess
    if FileAccess.file_exists(_path):
        file=FileAccess.open(_path,FileAccess.READ_WRITE)
        if file!=null: file.seek_end()
    else:
        file=FileAccess.open(_path,FileAccess.WRITE)
    if file==null: return false
    file.store_line(JSON.stringify(record))
    file.flush()
    var ok:=file.get_error()==OK
    file.close()
    if ok: _seen[event_id]=true
    return ok

func number_of_facts() -> int:
    return _seen.size()

func personal_facts(person: String, limit: int=5) -> Array[Dictionary]:
    # Chronology does not confer omniscience: callers must check the speaker
    # really is the subject (or provide separately verified public evidence).
    var out: Array[Dictionary]=[]
    if not _readable or not FileAccess.file_exists(_path): return out
    var stream:=FileAccess.open(_path,FileAccess.READ)
    if stream==null: return out
    while not stream.eof_reached():
        var line:=stream.get_line()
        var item: Variant=JSON.parse_string(line)
        if item is Dictionary and str(item.get("person",""))==person and str(item.get("confidence",""))=="rule_confirmed":
            out.append(item)
            if out.size()>maxi(1,limit): out.pop_front()
    return out
