extends SceneTree
var failures: Array[String]=[]

func _check(value: bool, reason: String) -> void:
    if not value: failures.append(reason)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var library:=XianfanNarrativeDB.new()
    _check(library.catalog_count()>=300,"Expected at least 300 individually authored NPC voice variants")
    var people: Dictionary={
        "孙成明":{"id":"CFNPC00003","place":"石桥村·家中","job":"家务","activity":"整理行装","alive":true,"biography":[]},
        "赵实":{"id":"CIV000210","place":"石桥村·家中","job":"农夫","sector":"农桑","activity":"忙着晒谷","alive":true,"wish":"保住自家田"},
        "李铁":{"id":"CIV000211","place":"石桥村·家中","job":"陶匠","sector":"金石工艺","activity":"修陶缸","alive":true},
        "王书":{"id":"CIV000212","place":"石桥村·家中","job":"私塾先生","sector":"文教百艺","activity":"整理教案","alive":true}
    }
    var state: Dictionary={"day":29,"place":"石桥村·家中","npc":people,
        "dialogue_log":[],"source_event":"EV000105"}
    var sister:=library.answer("孙成明","前朝怎么灭亡的？",state)
    var teacher:=library.answer("王书","前朝怎么灭亡的？",state)
    _check(bool(sister.get("covered",false)) and bool(teacher.get("covered",false)),
        "Historical inquiry should be answered without asking 8B to invent a dynasty")
    _check(str(sister.get("reply",""))!=str(teacher.get("reply","")),
        "Same factual uncertainty must produce character-specific language")
    var worker:=library.answer("赵实","你现在在忙什么？",state)
    _check(str(worker.get("reply","")).contains("晒谷"),"Dynamic activity must be grounded in live NPC state")
    var identity:=library.answer("李铁","你叫什么？",state)
    _check(str(identity.get("reply","")).contains("李铁"),"Reply must refer to the actual speaker")
    var unanswered:=library.answer("李铁","九层妖塔里的第三面镜子在哪里？",state)
    _check(not bool(unanswered.get("covered",false)),"Uncovered question must fall back to AI, not generic confabulation")
    var moved: Dictionary=state.duplicate(true)
    moved["npc"]["李铁"]["place"]="临安县城·东市"
    _check(not bool(library.answer("李铁","你叫什么？",moved).get("covered",false)),
        "No face-to-face dialogue with a remote NPC")
    var dead: Dictionary=state.duplicate(true)
    dead["npc"]["李铁"]["alive"]=false
    _check(not bool(library.answer("李铁","你叫什么？",dead).get("covered",false)),
        "The deceased must not answer")
    var first:=library.answer("赵实","你做什么营生？",state)
    state["dialogue_log"].append({"speaker":"赵实","topic":"work"})
    var second:=library.answer("赵实","你做什么营生？",state)
    _check(str(first.get("reply",""))!=str(second.get("reply","")),
        "Repeated encounters rotate between authored replies without changing the speaker identity")
    var chronicle:=XianfanWorldFactChronicle.new()
    var campaign:="qa-narrative-"+str(Time.get_ticks_usec())
    _check(chronicle.configure(campaign),"Rule-event sidecar should initialize")
    _check(chronicle.append_rule_fact("civic_life","李铁",29,"凭真实工时练好一批陶器","CIV000211","石桥村·街口"),
        "Verified event should append")
    _check(chronicle.append_rule_fact("civic_life","李铁",29,"凭真实工时练好一批陶器","CIV000211","石桥村·街口"),
        "Duplicate event should be idempotent")
    _check(chronicle.number_of_facts()==1,"Same real event must not be recorded twice")
    _check(not chronicle.append_rule_fact("ai_generated","李铁",29,"皇帝驾崩"),
        "Never admit unaudited AI fiction into authoritative event ledger")
    var reopened:=XianfanWorldFactChronicle.new()
    _check(reopened.configure(campaign) and reopened.number_of_facts()==1,
        "World fact history should survive a new app session")
    var records:=reopened.personal_facts("李铁",4)
    _check(records.size()==1 and str(records[0].get("detail","")).contains("陶器"),
        "Retrieval must preserve provenance and exact actor")
    if failures.is_empty():
        print("NARRATIVE DB: PASS, %d authored variants, non-fiction history and persistent rule ledger" % library.catalog_count())
        quit(0)
    else:
        for failure in failures: push_error("NARRATIVE DB FAILURE: "+failure)
        quit(1)
