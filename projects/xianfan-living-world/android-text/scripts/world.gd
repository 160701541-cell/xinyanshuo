extends RefCounted
class_name XianfanWorld

# 《仙凡·苍岚》独立安卓剧情分支。开局是官方 EV000016 的公开快照。
# 此分支的独立生活演算不得回写 GitHub 权威事件链。
const SAVE_PATH := "user://xianfan_first_life.json"
const BACKUP_PATH := "user://xianfan_first_life.backup.json"
const SEED := "xianfan-canglan-text-20261024-v1"
const VERSION := 4
const MAX_JOURNAL := 100000
var data: Dictionary = {}
var journal: Array = []
var last_result := ""
var last_channel := "剧情"
var last_target := ""
const FEEDBACK_PATH := "user://xianfan_feedback.json"
var feedback: Array = []

func _init() -> void:
    if not load_save():
        new_game()
    _load_feedback()

func new_game() -> void:
    data = {
        "schema": VERSION, "source_event": "EV000016", "turn": 14,
        "day": 2, "minute": 674, "place": "临安县城·旧书铺",
        "name": "心魇说", "age": 16, "realm": "凡人（未修行）", "root": "未检测",
        "root_commitment": "897ffd3bec4b0c505b934d584835158fecaf6ddea61c5d70df6b8160db914dd7",
        "hp": 100, "stamina": 51, "money": 2, "insight": 0, "qi": 0,
        "house_money": 42, "grain_milli": 53892, "weather": "晴",
        "items": {"粗布衣": 1, "布鞋": 1, "简易竿坯": 1, "编织鱼笼": 1, "钓鱼线": 1, "鱼钩": 1, "青菜种子包": 1},
        "gear": {"first": {"owned": true, "catch": 1}, "second": {"owned": false, "catch": 0}},
        "fish_population": 4, "fish_cap": 7, "field": {"planted_day": 0, "crop": "", "watered_day": 0},
        "book_owned": false, "book_real": "未鉴定", "book_holder": "心魇说", "old_taoist_sold": false,
        "manual_proven": false, "cultivation_days": 0, "quiet_hours": 0, "sensation": "未产生可验证气感",
        "npc": {
            "孙成明": {"id": "CFNPC00003", "place": "石桥村·家中", "activity": "整理柴草", "rapport": 50, "learning": 0, "agreed": false, "mood": "平静", "last_met": 1},
            "钱然泽": {"id": "CFNPC00001", "place": "石桥村·田边", "activity": "农耕", "mood": "忙碌"},
            "郑舟清": {"id": "CFNPC00002", "place": "石桥村·家中", "activity": "做饭", "mood": "平静"}
        },
        "market": {"produce_cash": 15, "book_vendor_cash": 0, "book_vendor_stock": 1},
        "flags": {"meal_request_unanswered": true, "old_taoist_met": false, "manual_questioned": false},
        "daily_last": 1, "fishing_last_check": 1803, "last_meal": 1,
        "mode": "离线独立体验", "history_source": "EV000016 已核准起点；此后仅本机存档"
    }
    # Bootstrap from the latest audited public archive read on 2026-10-25:
    # EV000105 / turn 103 / day29 06:00. Do not overwrite existing phone saves.
    data["schema"] = VERSION
    data["source_event"] = "EV000105"
    data["turn"] = 103
    data["day"] = 29
    data["minute"] = 360
    data["place"] = "石桥村·家中"
    data["weather"] = "多云"
    data["stamina"] = 100
    data["money"] = 53
    data["house_money"] = 22
    data["grain_milli"] = 49464
    data["items"] = {"粗布衣": 1, "布鞋": 1, "小河鱼": 4, "简易鱼竿": 1, "引气初篇": 1}
    data["gear"] = {"first": {"owned": true, "catch": 0}, "second": {"owned": true, "catch": 0}}
    data["fish_population"] = 0
    data["fish_cap"] = 1
    data["field"] = {"planted_day": 3, "crop": "青菜", "watered_day": 3}
    data["book_owned"] = true
    data["book_real"] = "已证实为拼凑伪诀"
    data["book_holder"] = "孙成明"
    data["old_taoist_sold"] = true
    data["cultivation_days"] = 5
    data["flags"] = {"meal_request_unanswered": false, "old_taoist_met": true, "manual_questioned": true}
    data["market"]["book_vendor_cash"] = 2
    data["market"]["book_vendor_stock"] = 0
    data["daily_last"] = 29
    data["last_meal"] = 28
    data["fishing_last_check"] = 40800
    data["npc"]["孙成明"]["learning"] = 16
    data["npc"]["孙成明"]["agreed"] = true
    data["npc"]["孙成明"]["activity"] = "在院内收拾行囊，准备送你到村口"
    data["npc"]["钱然泽"]["activity"] = "将二十文盘缠交给儿子后早起下田"
    data["npc"]["郑舟清"]["activity"] = "为出远门的儿子备干粮"
    data["journey"] = {"stage": "未动身", "lodging_nights": 0, "tested": false, "goal": "青云山门测灵台", "fee": 30}
    data["history_source"] = "公开 GitHub EV000105 / 103回合 / 第29日06:00（2026-10-25读取）"
    journal = [
        "【权威基准 EV000105】承平三年第29日清晨，石桥村钱家院落。你攒下53文，家中还有22文、49.464斗粮。父亲准你去青云山门测灵根，妹妹只许送到村口。",
        "【先前经历】第二日从游方道人处买得残旧《引气初篇》；经数日尝试，已鉴定为拼凑伪诀，并停止照练。前后捕鱼十五条，河段一度见底；家中青菜第三日已播。",
        "【当前目标】天亮动身，走115分钟官道至临安，再沿357分钟山道到青云山门。山门测灵收费30文，脚店住一晚8文。灵根承诺仍然隐藏，没有原文就不能伪造测灵结果。",
        "【离线分支】这是2026-10-25读取的 GitHub 已同步快照，从此之后仅存本机。已有本机存档绝不自动重置。"
    ]
    save()

func _valid(d: Dictionary) -> bool:
    if not d.has("schema") or int(d["schema"]) > VERSION or int(d["schema"]) < 2:
        return false
    for key in ["day", "minute", "stamina", "money", "items", "npc", "place", "turn"]:
        if not d.has(key): return false
    if not (d["items"] is Dictionary) or not (d["npc"] is Dictionary): return false
    if int(d["day"]) < 1 or int(d["minute"]) < 0 or int(d["minute"]) >= 1440: return false
    if int(d["stamina"]) < 0 or int(d["stamina"]) > 100: return false
    if int(d["money"]) < 0 or int(d.get("grain_milli", 0)) < 0: return false
    if not d["npc"].has("孙成明"): return false
    return true

func _read_save(path: String) -> bool:
    if not FileAccess.file_exists(path): return false
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null: return false
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if not (parsed is Dictionary): return false
    if not (parsed.has("data") and parsed.has("journal")): return false
    if not (parsed["data"] is Dictionary) or not (parsed["journal"] is Array): return false
    var d: Dictionary = parsed["data"]
    if not _valid(d): return false
    data = d
    journal = parsed["journal"]
    _migrate()
    return true

func _migrate() -> void:
    # Non-destructive v0.3 -> v1 migration, retain original human play history.
    if int(data.get("schema", 0)) >= VERSION: return
    data["schema"] = VERSION
    data["market"] = {"produce_cash": 15, "book_vendor_cash": 2 if data.get("book_owned", false) else 0, "book_vendor_stock": 0 if data.get("book_owned", false) else 1}
    data["gear"] = {"first": {"owned": true, "catch": int(data.get("fish_in_first_basket", 0))}, "second": {"owned": int(data.get("placed_baskets", 1)) >= 2, "catch": 0}}
    data["fish_cap"] = 7
    data["field"] = {"planted_day": int(data.get("day", 1)) if data.get("planted", false) else 0, "crop": "青菜" if data.get("planted", false) else "", "watered_day": 0}
    data["old_taoist_sold"] = data.get("book_owned", false)
    data["manual_proven"] = false
    data["cultivation_days"] = 0
    data["quiet_hours"] = 0
    data["sensation"] = "未产生可验证气感"
    data["flags"] = {"meal_request_unanswered": true, "old_taoist_met": data.get("book_owned", false), "manual_questioned": false}
    data["daily_last"] = int(data.get("day", 2)) - 1
    data["fishing_last_check"] = 1803
    data["last_meal"] = int(data.get("day", 2)) - 1
    data["book_holder"] = "心魇说"
    data["journey"] = {"stage": "未动身", "lodging_nights": 0, "tested": false, "goal": "青云山门测灵台", "fee": 30}
    for key in ["孙成明", "钱然泽", "郑舟清"]:
        if not data["npc"].has(key): continue
        var n: Dictionary = data["npc"][key]
        if not n.has("id"):
            n["id"] = {"孙成明":"CFNPC00003", "钱然泽":"CFNPC00001", "郑舟清":"CFNPC00002"}[key]
        if not n.has("place"): n["place"] = "石桥村·家中"
        if not n.has("activity"): n["activity"] = "家务"
    _note("【版本升级】存档已无损迁移至 v1；旧行动继续保留。")

func load_save() -> bool:
    if _read_save(SAVE_PATH): return true
    if _read_save(BACKUP_PATH):
        _note("【存档恢复】主存档不可用，已加载备份。")
        return true
    return false

func save() -> void:
    if not _valid(data):
        push_error("Refusing invalid game save")
        return
    var payload := JSON.stringify({"data": data, "journal": journal}, "  ")
    var tmp := SAVE_PATH + ".tmp"
    var file := FileAccess.open(tmp, FileAccess.WRITE)
    if file == null:
        push_error("Cannot write save: " + str(FileAccess.get_open_error()))
        return
    file.store_string(payload)
    file.flush()
    file.close()
    var main := ProjectSettings.globalize_path(SAVE_PATH)
    var backup := ProjectSettings.globalize_path(BACKUP_PATH)
    var temp := ProjectSettings.globalize_path(tmp)
    if FileAccess.file_exists(SAVE_PATH):
        DirAccess.copy_absolute(main, backup)
    var err := DirAccess.rename_absolute(temp, main)
    if err != OK: push_error("Cannot commit save: " + str(err))

func _load_feedback() -> void:
    feedback.clear()
    if not FileAccess.file_exists(FEEDBACK_PATH): return
    var file := FileAccess.open(FEEDBACK_PATH, FileAccess.READ)
    if file == null: return
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if parsed is Array: feedback = parsed.slice(-80)

func _record_feedback(input: String, message: String, code: String) -> void:
    var record := {
        "code": code,
        "action": input.substr(0, 350),
        "reason": message.substr(0, 350),
        "time": time_string(),
        "place": str(data.get("place","未知")),
        "game_schema": int(data.get("schema",0)),
        "source_event": str(data.get("source_event","")),
        "mode": "离线规则"
    }
    feedback.append(record)
    if feedback.size() > 80: feedback.pop_front()
    var f := FileAccess.open(FEEDBACK_PATH, FileAccess.WRITE)
    if f != null:
        f.store_string(JSON.stringify(feedback, "  "))

func feedback_report() -> String:
    var lines: Array[String] = []
    lines.append("《仙凡·苍岚》问题与功能反馈")
    lines.append("版本：Android文字游戏 v1.3 · Godot 4.4.1")
    lines.append("规则存档：%s · %s" % [str(data.get("source_event","")),time_string()])
    lines.append("当前位置：" + str(data.get("place","")))
    lines.append("注意：以下仅是用户输入与规则错误，不包含 API 密钥、网络请求体或私人服务器配置。")
    if feedback.is_empty(): lines.append("尚无未支持动作和错误记录。")
    var start := maxi(0, feedback.size()-30)
    for i in range(start, feedback.size()):
        var entry: Dictionary = feedback[i]
        lines.append("\n#%d [%s] %s\n行动：%s\n原因：%s" % [i+1,str(entry.get("time","")),str(entry.get("code","")),str(entry.get("action","")),str(entry.get("reason",""))])
    return "\n".join(lines)

func note_api_failure(action: String, reason: String) -> void:
    _record_feedback(action, reason, "AI_API_FAILED")

func record_ai_dialogue(person: String, player_text: String, reply: String, engine: String="api") -> String:
    if not data["npc"].has(person): return "NPC不存在，无法进行对话。"
    var npc: Dictionary = data["npc"][person]
    if str(npc.get("place","")) != str(data["place"]):
        return "%s不在此处，无法进行当面交谈。" % person
    if reply.strip_edges().is_empty() or reply.length() > 700:
        return "AI返回的对话长度异常，没有写入存档。"
    _tick(4)
    var log: Array = data.get("dialogue_log",[])
    var clean_player := player_text.strip_edges()
    for prefix in ["跟"+person+"说：","跟"+person+"说:","对"+person+"说：","对"+person+"说:"]:
        if clean_player.begins_with(prefix):
            clean_player=clean_player.trim_prefix(prefix).strip_edges()
            break
    log.append({"day":int(data["day"]),"speaker":person,"player":clean_player.substr(0,250),"reply":reply.strip_edges(),"ai":true,"engine":engine})
    if log.size()>80: log.pop_front()
    data["dialogue_log"]=log
    # Append-only dialogue archive and NPC-indexed memory survive recent-log rotation.
    # Dialogue is a record of what was said, not a source of new world facts.
    var archive: Array=data.get("dialogue_archive",[])
    var saved_turn: Dictionary=log.back().duplicate(true)
    saved_turn["minute"]=int(data["minute"])
    archive.append(saved_turn)
    data["dialogue_archive"]=archive
    var npc_memories: Dictionary=data.get("npc_memories",{})
    var personal: Array=npc_memories.get(person,[])
    personal.append({"day":int(data["day"]),"turn":int(data["turn"]),"player":clean_player.substr(0,250),"reply":reply.strip_edges().substr(0,350)})
    npc_memories[person]=personal
    data["npc_memories"]=npc_memories
    last_channel="对话"
    last_target=person
    last_result=reply.strip_edges()
    save()
    return last_result

# Model may propose a bounded plot beat, but the rules engine authorizes and
# stores every transition. Narrative text alone never grants resources or levels.
const STORY_BEATS := {
    "sister_choice":{"title":"成明的打算","place":"石桥村·家中","npc":"孙成明"},
    "mother_warning":{"title":"母亲的叮嘱","place":"石桥村·家中","npc":"郑舟清"},
    "forged_manual":{"title":"伪诀风波","place":"石桥村·家中","npc":"孙成明"},
    "river_balance":{"title":"溪河枯竭","place":"石桥村·溪边","npc":""},
    "forest_custom":{"title":"村社林规","place":"石桥村·林缘","npc":""},
    "market_rumor":{"title":"东市闲闻","place":"临安县城·东市","npc":""},
    "mountain_gate":{"title":"山门抉择","place":"青云山门·山门外","npc":""}
}

func available_story_beats() -> Array[Dictionary]:
    var result: Array[Dictionary]=[]
    var flags: Dictionary=data.get("story_flags",{})
    for key in STORY_BEATS:
        if flags.has(key): continue
        var beat: Dictionary=STORY_BEATS[key]
        if str(beat["place"])!=str(data["place"]): continue
        var required_npc:=str(beat.get("npc",""))
        if not required_npc.is_empty():
            if not data["npc"].has(required_npc): continue
            if str(data["npc"][required_npc].get("place",""))!=str(data["place"]): continue
        if key=="forged_manual" and not data.get("manual_questioned",data.get("flags",{}).get("manual_questioned",false)): continue
        if key=="river_balance" and int(data.get("fish_population",10))>2: continue
        result.append({"id":key,"title":str(beat["title"])})
    return result

func story_context() -> Dictionary:
    var npc_visible: Array=[]
    for name in data["npc"]:
        var n: Dictionary=data["npc"][name]
        if str(n.get("place",""))==str(data["place"]):
            npc_visible.append({"name":name,"activity":n.get("activity",""),"mood":n.get("mood",""),"wish":n.get("wish","未公开")})
    return {"day":int(data["day"]),"minute":int(data["minute"]),"place":str(data["place"]),
        "weather":str(data.get("weather","")),"stamina":int(data.get("stamina",0)),
        "inventory":data.get("items",{}).duplicate(true),"realm":str(data.get("realm","凡人")),
        "root":str(data.get("root","未检测")),"npc_here":npc_visible,
        "world_facts":look(),"available_beats":available_story_beats(),
        "last_rule_result":last_result.substr(0,340),
        "recent_npc_days":data.get("npc_life_events",[]).slice(-6),
        "open_plot_threads":data.get("story_flags",{}).keys()}

func recent_story_ai(n: int=3) -> String:
    var events: Array=data.get("ai_story_log",[])
    var lines: Array[String]=[]
    for i in range(maxi(0,events.size()-n),events.size()):
        var e: Dictionary=events[i]
        lines.append(str(e.get("scene","")))
    return "\n\n".join(lines)

func _ai_story_must_reject(text: String) -> bool:
    # Visible prose cannot impersonate irreversible numerical world changes.
    for keyword in ["成功突破","已突破","灵根是","灵根为","获得灵石","得到灵石","凭空出现","境界提升","气血增加","铜钱增加","寿元增加"]:
        if text.contains(keyword): return true
    return false

func record_ai_story(scene: String, beat_id: String, expected_clock: int, origin: String="local-gguf") -> Dictionary:
    if _clock()!=expected_clock:
        return {"ok":false,"error":"世界时间已变化，旧AI剧情不再有效。"}
    var text_scene:=scene.strip_edges()
    if text_scene.length()<8 or text_scene.length()>440:
        return {"ok":false,"error":"AI剧情文字长度异常，未写入存档。"}
    if _ai_story_must_reject(text_scene):
        return {"ok":false,"error":"AI企图在旁白中擅自改动修为、钱财或属性。"}
    var approved_id:=""
    for available in available_story_beats():
        if str(available["id"])==beat_id: approved_id=beat_id
    var event: Dictionary={"day":int(data["day"]),"minute":int(data["minute"]),
        "place":str(data["place"]),"scene":text_scene,"origin":origin,
        "beat_id":approved_id,"rule_turn":int(data["turn"])}
    var stories: Array=data.get("ai_story_log",[])
    stories.append(event)
    data["ai_story_log"]=stories
    if not approved_id.is_empty():
        var flags: Dictionary=data.get("story_flags",{})
        flags[approved_id]={"day":int(data["day"]),"turn":int(data["turn"])}
        data["story_flags"]=flags
        var npc: Dictionary=data["npc"]
        if approved_id=="sister_choice":
            npc["孙成明"]["wish"]="想自己决定是否学习与出门见识"
        elif approved_id=="mother_warning":
            npc["郑舟清"]["wish"]="盼孩子平安回家、带好盘缠"
        elif approved_id=="forged_manual":
            npc["孙成明"]["wish"]="先辨别真伪，再谈修炼"
        _note("【人生支线开启】"+str(STORY_BEATS[approved_id]["title"]))
    save()
    return {"ok":true,"approved_beat":approved_id,"scene":text_scene}

func related_npc_memories(person: String, query: String, max_results: int=6) -> Array:
    var all_npcs: Dictionary=data.get("npc_memories",{})
    var memory: Array=all_npcs.get(person,[])
    var tokens: Array[String]=[]
    for i in range(maxi(0,query.length()-1)):
        var chunk:=query.substr(i,2)
        if not tokens.has(chunk): tokens.append(chunk)
    var ranked: Array=[]
    for i in range(memory.size()):
        var item: Dictionary=memory[i]
        var combined:=str(item.get("player",""))+" "+str(item.get("reply",""))
        var relevance:=0
        for token in tokens:
            if combined.contains(token): relevance+=1
        if relevance>0:
            ranked.append({"score":relevance,"index":i,"memory":item})
    ranked.sort_custom(func(a,b): return (int(a["score"])*10000+int(a["index"]))>(int(b["score"])*10000+int(b["index"])))
    var selected: Array=[]
    for i in range(mini(max_results,ranked.size())):
        selected.append(ranked[i]["memory"])
    return selected

func npcs_status() -> Array[Dictionary]:
    var arr: Array[Dictionary] = []
    for key in ["孙成明","钱然泽","郑舟清"]:
        if not data["npc"].has(key): continue
        var n: Dictionary = data["npc"][key]
        arr.append({
            "name":key,"id":str(n.get("id","")),
            "age":16 if key=="孙成明" else (35 if key=="钱然泽" else 49),
            "relationship":"妹妹" if key=="孙成明" else ("父亲" if key=="钱然泽" else "母亲"),
            "place":str(n.get("place","未知")),
            "activity":str(n.get("activity","未知")),
            "wish":str(n.get("wish","未公开")),
            "goal_progress":int(n.get("goal_progress",0)),
            "mood":str(n.get("mood","未公开")),
            "rapport":int(n.get("rapport",0)) if key=="孙成明" else -1,
            "learning":int(n.get("learning",0)) if key=="孙成明" else -1,
            "items":n.get("items",{}),
            "here":str(n.get("place",""))==str(data["place"])
        })
    return arr

func dialogue_recent(n: int=24) -> String:
    var lines: Array[String] = []
    var records: Array = data.get("dialogue_log",[])
    for i in range(maxi(0,records.size()-n),records.size()):
        var v: Dictionary = records[i]
        var source := "规则对话"
        if v.get("ai",false):
            source = "手机本地AI" if str(v.get("engine",""))=="local-gguf" else ("API生成" if str(v.get("engine",""))=="api" else "AI生成")
        lines.append("你 · 第%d日\n%s\n\n%s · %s\n%s" % [int(v.get("day",0)),str(v.get("player","")),str(v.get("speaker","")),source,str(v.get("reply",""))])
    return "\n\n────────────\n\n".join(lines) if not lines.is_empty() else "还没有对话。点击NPC卡片可以交谈，或者在下方直接输入。"

func _note(msg: String) -> void:
    if journal.size() < MAX_JOURNAL: journal.append(msg)

func time_string() -> String:
    return "承平三年 · 第%d日 · %02d:%02d" % [int(data["day"]), int(int(data["minute"]) / 60), int(data["minute"]) % 60]

func _clock() -> int:
    return (int(data["day"]) - 1) * 1440 + int(data["minute"])

func _roll(label: String, day: int, max_value: int = 100) -> int:
    var key := "%s|%s|%d" % [SEED, label, day]
    return (int(key.hash()) & 0x7fffffff) % max_value

func _tick(minutes: int, stamina_delta: int = 0) -> void:
    if minutes < 0: return
    data["minute"] = int(data["minute"]) + minutes
    data["stamina"] = clampi(int(data["stamina"]) + stamina_delta, 0, 100)
    while int(data["minute"]) >= 1440:
        data["minute"] = int(data["minute"]) - 1440
        data["day"] = int(data["day"]) + 1
        _daily()
    data["turn"] = int(data["turn"]) + 1

func _daily() -> void:
    var day := int(data["day"])
    if int(data["daily_last"]) == day: return
    data["daily_last"] = day
    var grain := int(data["grain_milli"])
    var eaten := mini(grain, 108)
    data["grain_milli"] = grain - eaten
    if eaten < 108:
        data["hp"] = maxi(0, int(data["hp"]) - 5)
        _note("【生计】家中四口的粮食不足，体力和健康都受到影响。")
    # Forest resource regrowth is capped and independent from player wishes.
    var forest: Dictionary = data.get("forest_stock",{"枯枝":6,"车前草":3})
    forest["枯枝"]=mini(8,int(forest.get("枯枝",0))+2)
    forest["车前草"]=mini(4,int(forest.get("车前草",0))+1)
    data["forest_stock"]=forest
    # The environmental ledger is replenished only through a bounded migration rule.
    if int(data["fish_population"]) < int(data["fish_cap"]):
        data["fish_population"] = int(data["fish_population"]) + 1
        _note("【生态】汛后有一小群野鱼进入河湾，鱼群数量增加一。")
    data["weather"] = ["晴", "多云", "晴", "小雨", "阴"][day % 5]
    var sister: Dictionary = data["npc"]["孙成明"]
    sister["activity"] = ["洗衣", "拾柴", "帮忙做饭", "在田埂边忙活", "整理家什"][day % 5]
    sister["place"] = "石桥村·家中" if day % 5 != 3 else "石桥村·田边"
    sister["mood"] = ["平静", "忙碌", "有些困倦", "精神不错"][day % 4]
    if int(sister["learning"]) > 0 and day % 2 == 0:
        sister["learning"] = mini(100, int(sister["learning"]) + 1)
    # Long-lived independent intentions evolve through simulation, not freeform
    # LLM claims; no spiritual breakthrough is inferred from ordinary study.
    if not str(sister.get("wish","")).is_empty():
        sister["goal_progress"]=mini(100,int(sister.get("goal_progress",0))+2)
        if day % 4==0 and sister["place"]=="石桥村·家中":
            sister["activity"]="忙完家务后自行温习旧书"
    if not str(data["npc"]["郑舟清"].get("wish","")).is_empty():
        data["npc"]["郑舟清"]["goal_progress"]=mini(100,int(data["npc"]["郑舟清"].get("goal_progress",0))+1)
    data["npc"]["钱然泽"]["activity"] = "修理农具" if day % 6 == 0 else "田间劳作"
    data["npc"]["郑舟清"]["activity"] = "料理厨房" if day % 3 != 0 else "晾晒家粮"
    if int(data["field"]["planted_day"]) > 0 and day == int(data["field"]["planted_day"]) + 3:
        _note("【农事】菜畦里冒出嫩芽。")
    # Keep durable, engine-computed NPC life events for optional AI narration.
    # These exist even with AI disabled, and cannot mint any material resources.
    var life: Array=data.get("npc_life_events",[])
    for person in ["孙成明","钱然泽","郑舟清"]:
        var n: Dictionary=data["npc"][person]
        life.append({"day":day,"npc":person,"place":str(n.get("place","")),
            "activity":str(n.get("activity","")),"mood":str(n.get("mood","平静")),
            "goal":str(n.get("wish","")),"goal_progress":int(n.get("goal_progress",0))})
    data["npc_life_events"]=life
    _note("【日结】第%d日，家中消耗粮食 %.3f 斗，天气%s。" % [day, float(eaten) / 1000.0, data["weather"]])

func _has(item: String, number: int = 1) -> bool:
    return int(data["items"].get(item, 0)) >= number

func _add(item: String, number: int = 1) -> void:
    data["items"][item] = int(data["items"].get(item, 0)) + number

func _take(item: String, number: int = 1) -> bool:
    if not _has(item, number): return false
    var remaining := int(data["items"][item]) - number
    if remaining == 0: data["items"].erase(item)
    else: data["items"][item] = remaining
    return true

func _sister_here() -> bool:
    return data["place"] == "石桥村·家中" and data["npc"]["孙成明"]["place"] == "石桥村·家中"

func _move(place: String, minutes: int, cost: int) -> String:
    if int(data["stamina"]) < cost: return "精力不足，先找地方休息。"
    _tick(minutes, -cost)
    data["place"] = place
    return "你一路行至%s。" % place

func _fish_check() -> String:
    if data["place"] != "石桥村·溪边": return "鱼笼在溪边，须亲自过去查看。"
    var minutes_elapsed := _clock() - int(data["fishing_last_check"])
    if minutes_elapsed < 120: return "离上次查看还不到两个时辰，鱼笼需要时间。"
    _tick(15, -2)
    var cycles := mini(6, maxi(1, int(minutes_elapsed / 120)))
    var caught := 0
    for idx in range(cycles):
        if int(data["fish_population"]) <= 0: break
        var r := _roll("fish-basket-%d-%d" % [int(data["turn"]), idx], int(data["day"]))
        if r < 19:
            var gear_key := "second" if data["gear"]["second"]["owned"] and idx % 2 == 0 else "first"
            data["gear"][gear_key]["catch"] = int(data["gear"][gear_key]["catch"]) + 1
            data["fish_population"] = int(data["fish_population"]) - 1
            caught += 1
    data["fishing_last_check"] = _clock()
    return "你查看两只鱼笼，新增%d条小鱼。河湾尚有%d条登记小鱼（不是无限刷新）。" % [caught, int(data["fish_population"])]

func _catch_fish() -> String:
    if data["place"] != "石桥村·溪边": return "你不在石桥溪边。"
    var total := int(data["gear"]["first"]["catch"]) + int(data["gear"]["second"]["catch"])
    if total == 0: return "鱼笼是空的，可以等候后再次查看。"
    _tick(15, -2)
    data["gear"]["first"]["catch"] = 0
    data["gear"]["second"]["catch"] = 0
    _add("小河鱼", total)
    return "你将鱼笼里的%d条小河鱼收入竹篓，鱼已从水中取出。" % total

func _sleep() -> String:
    if data["place"] != "石桥村·家中": return "这里没有安全的睡处。"
    _tick(480, 48)
    return "你睡了八个小时（四个时辰），醒来精神有所恢复。"

func _study() -> String:
    if not data["book_owned"]: return "你还没有《引气初篇》。"
    if data["book_real"] == "已证实为拼凑伪诀": return "这部残卷已查明是拼凑的伪诀，不值得再耗费时日。"
    if int(data["stamina"]) < 5: return "困倦得看不进书，先休息。"
    _tick(60, -5)
    data["insight"] = mini(100, int(data["insight"]) + 9)
    return "你整理呼吸法与经络记述，对文字更熟悉了。参悟值上升，但不是修为增长。"

func _meditate() -> String:
    if not data["book_owned"]: return "你只得进行普通静坐，还未得到修行口诀。"
    if data["book_real"] == "已证实为拼凑伪诀": return "你已确认此书为伪本，照练反倒耽误农时；应去山门寻正途。"
    if int(data["stamina"]) < 10: return "精神涣散，无法集中，最好睡一觉。"
    _tick(120, -9)
    data["quiet_hours"] = int(data["quiet_hours"]) + 2
    data["insight"] = mini(100, int(data["insight"]) + 6)
    return "静坐两小时。呼吸平稳，胸腹偶有暖意，但目前没有可验证的灵力，更谈不上突破。"

func _meal() -> String:
    if data["place"] != "石桥村·家中": return "家中的饭食不在这里。"
    if int(data["grain_milli"]) < 15: return "家中口粮见底，得先想办法解决生计。"
    _tick(45, 8)
    data["last_meal"] = int(data["day"])
    return "一家人围着灶台吃了些粗粮与青菜。粮食在每日家庭账本统一结算，避免重复扣费。"

func _teach() -> String:
    if not _sister_here(): return "孙成明今日不在屋里，她并不会随叫随到。"
    if not data["book_owned"]: return "你手上还没有《引气初篇》。"
    if _roll("sister-consent", int(data["day"])) >= int(data["npc"]["孙成明"]["rapport"]) + 25:
        _tick(5)
        return "成明摇头：‘我先把活干完，过两天再说。’她有自己的安排。"
    _tick(70, -4)
    data["npc"]["孙成明"]["learning"] = mini(100, int(data["npc"]["孙成明"]["learning"]) + 8)
    data["npc"]["孙成明"]["agreed"] = true
    return "你教成明认读口诀，她边听边记，盘腿片刻便伸了伸腿：‘腿都麻了，哥，先到这儿吧。’她学会些字句，尚未确认有灵根。"

func _talk() -> String:
    if not _sister_here(): return "成明外出忙活了，晚些时候可能回来。"
    _tick(6)
    data["npc"]["孙成明"]["rapport"] = mini(100, int(data["npc"]["孙成明"]["rapport"]) + 1)
    if data["flags"]["meal_request_unanswered"]:
        data["flags"]["meal_request_unanswered"] = false
        return "你问起昨日说好的送饭。成明抓了抓衣角：‘昨日回去给娘搭手，后来竟忘了你还在溪边。你回来时我才想起来……这事是我不好。’"
    return "成明一边整理家什一边问：‘今日去溪边了吗？我瞧天要变，不如早点回来。’"

func _sow() -> String:
    if data["place"] != "石桥村·家中": return "菜畦在院子旁边。"
    if int(data["field"]["planted_day"]) > 0: return "菜畦已有作物，不能重叠播种。"
    if not _take("青菜种子包"): return "身上没有青菜种子。"
    _tick(90, -11)
    data["field"]["planted_day"] = int(data["day"])
    data["field"]["crop"] = "青菜"
    return "你征得母亲同意，将院旁闲置菜畦松土播种。要过八日左右才有可能收获。"

func _harvest() -> String:
    if data["place"] != "石桥村·家中": return "菜畦不在这里。"
    if int(data["field"]["planted_day"]) == 0: return "地里没有正在种的青菜。"
    if int(data["day"]) - int(data["field"]["planted_day"]) < 30: return "青菜尚未长成，距播种要满一月左右才能采收。"
    _tick(60, -7)
    var amount := 3 + _roll("harvest", int(data["day"]), 4)
    _add("青菜", amount)
    data["field"]["planted_day"] = 0
    data["field"]["crop"] = ""
    return "你收了%d把青菜，来自本院前些日子种下的那包种子。" % amount

func _rod() -> String:
    if not (_has("简易竿坯") and _has("钓鱼线") and _has("鱼钩")): return "组装鱼竿还缺杆坯、线或鱼钩。"
    _tick(35, -4)
    _take("简易竿坯"); _take("钓鱼线"); _take("鱼钩"); _add("简易鱼竿")
    return "你固定好线和鱼钩，做成一根简易鱼竿。"

func _buy_manual() -> String:
    if data["place"] != "临安县城·旧书铺": return "游方老道士并不在这里。"
    if data["old_taoist_sold"]: return "那位道人已经离开，没有第二本书可卖。"
    if int(data["money"]) < 2 or int(data["market"]["book_vendor_stock"]) <= 0: return "铜钱不足，或者他手上已没有书。"
    data["money"] = int(data["money"]) - 2
    data["market"]["book_vendor_cash"] = int(data["market"]["book_vendor_cash"]) + 2
    data["market"]["book_vendor_stock"] = int(data["market"]["book_vendor_stock"]) - 1
    _add("引气初篇")
    data["book_owned"] = true
    data["old_taoist_sold"] = true
    data["flags"]["old_taoist_met"] = true
    _tick(9)
    return "你从檐下的游方老道士手里用两文购得残旧《引气初篇》。他笑了笑，只说一声：‘日后好相见。’真伪尚未鉴定。"

func _sell(item: String) -> String:
    if data["place"] != "临安县城·东市": return "只能到县城东市找商贩交易。"
    if not _has(item): return "你并没有可出售的%s。" % item
    var price := 3 if item == "小河鱼" else 2
    if int(data["market"]["produce_cash"]) < price: return "菜肉摊今天带的钱不够，不能收货。"
    _take(item)
    data["market"]["produce_cash"] = int(data["market"]["produce_cash"]) - price
    data["money"] = int(data["money"]) + price
    _tick(12)
    return "菜肉摊收下一份%s，付给你%d文；摊位账本同步扣除。" % [item, price]

func _routine() -> String:
    if data["place"] != "石桥村·家中": return "今日的家庭日程须先在石桥村安排。"
    var entries: Array[String] = []
    if int(data["stamina"]) < 35: entries.append(_sleep())
    if data["book_owned"] and _sister_here(): entries.append(_teach())
    if int(data["field"]["planted_day"]) == 0 and _has("青菜种子包"): entries.append(_sow())
    if _has("简易竿坯") and _has("钓鱼线") and _has("鱼钩"): entries.append(_rod())
    if int(data["stamina"]) < 15: entries.append(_sleep())
    entries.append(_move("石桥村·溪边", 18, 3))
    if data["place"] == "石桥村·溪边":
        entries.append(_catch_fish())
        if _has("编织鱼笼"):
            _tick(18, -3); _take("编织鱼笼"); data["gear"]["second"]["owned"] = true
            entries.append("第二只鱼笼已经固定到水草间，初放置时为空。")
        entries.append(_fish_check())
        entries.append(_move("石桥村·家中", 18, 2))
    if data["place"] == "石桥村·家中":
        entries.append(_meal())
        if data["book_owned"] and data["book_real"] != "已证实为拼凑伪诀":
            entries.append(_study())
            if int(data["stamina"]) >= 10: entries.append(_meditate())
        entries.append(_sleep())
    return "【今日批量结算】\n" + "\n".join(entries)

func _continuous(days: int = 10) -> String:
    if data["place"] != "石桥村·家中": return "先回到安全的家中再安排长期修炼。"
    if not data["book_owned"]: return "还没有得到入门册子。"
    if data["book_real"] == "已证实为拼凑伪诀": return "这本《引气初篇》已判定为伪诀。连续照练无法得到可验证修为；当前应前往青云山门测灵。"
    if int(data["grain_milli"]) < days * 108: return "粮食储备不足以完成连续日程。"
    var start := int(data["day"])
    for i in range(days):
        if int(data["stamina"]) < 45: _sleep()
        _study()
        if int(data["stamina"]) >= 10: _meditate()
        # One day's chores, meals and sleep are accounted for by the world tick.
        _tick(1440 - int(data["minute"]) + 360, 25)
        data["cultivation_days"] = int(data["cultivation_days"]) + 1
        if int(data["hp"]) == 0: break
    return "从第%d日开始，你按正常饮食作息连续修习%d天。已登记静坐%d小时、参悟%d/100；功法真伪和原始灵根揭示尚无证据，不能将暖意算作引气成功。本次提供明确的‘证据不足’结论，没有伪造突破。" % [start, int(data["cultivation_days"]), int(data["quiet_hours"]), int(data["insight"])]

# The offline game interprets everyday speech locally. Dialogue is not a free-form LLM.
# Every spoken exchange is bounded by NPC presence and the family life ledger.
func _family_chat(person: String, topic: String) -> String:
    if data["place"] != "石桥村·家中":
        return "你不在家里，眼前没有可以这样交谈的家人。"
    if person == "孙成明":
        if not _sister_here():
            return "成明今日在外头忙。她不是随叫随到的，等她回家再问。"
        _tick(3)
        if topic == "饭":
            return "你问成明吃过饭没有。她放下手里的活：‘娘会留饭，我自己知道吃。倒是你，出远门记得带干粮。’"
        if topic == "青云":
            return "成明看你一眼：‘爹只肯让我送到村口，再远便不让我去了。你上山可别逞强。’"
        return "成明正忙着%s，抬头同你说了几句家常。她还有自己的事要做。" % str(data["npc"]["孙成明"].get("activity", "家务"))
    if person == "郑舟清":
        _tick(3)
        if topic == "饭":
            return "母亲搁下手里的活：‘灶上有吃食。想吃便坐下，别空着肚子赶路。’"
        if topic == "青云":
            return "母亲帮你理了理行囊：‘钱装好，饼带够。天黑前找地方落脚。’"
        return "母亲正在料理家务，听你说话时也没停下手里的活。"
    if person == "钱然泽":
        if int(data["minute"]) >= 420 and int(data["minute"]) <= 1050:
            return "父亲这会儿在田里，若要当面说话，得等他回来。"
        _tick(3)
        if topic == "青云":
            return "父亲沉着脸：‘银钱是借你看个明白的。测不出就回来踏实做事。’"
        if topic == "饭":
            return "父亲皱眉：‘家里吃饭有时辰，不用你替我操心。’"
        return "父亲放下农具，听完你的话，点头应了一声。"
    return "这里没有这个人。"

func scene_overview() -> String:
    var paragraph := "【眼前的世界】\n" + look()
    if not last_result.is_empty():
        paragraph += "\n\n【刚刚发生】\n" + last_result
    match str(data["place"]):
        "石桥村·家中":
            paragraph += "\n\n【路途与打算】\n去青云山门测灵根的盘缠已备。你可启程去临安，也可陪家人说话、安排田间劳作。"
        "临安县城·东市":
            paragraph += "\n\n【路途与打算】\n北门外是通往青云山门的山路，途中需要留意精力与天色。"
        "青云山门·山门外":
            paragraph += "\n\n【路途与打算】\n山门执事正在登记。原始灵根揭示缺失，不能在这里伪造结果或先扣费用。"
        _:
            paragraph += "\n\n【路途与打算】\n你可以查看附近、往来行走，也能直接输入想说的话。"
    return paragraph

# Free-text actions are resolved BEFORE fixed-button aliases.
# Only the rules engine mutates the world. Unrecognized requests cannot grant items.
func _free_observe(topic: String) -> String:
    var place := str(data["place"])
    if topic.contains("鱼") or topic.contains("溪") or topic.contains("河"):
        if place == "石桥村·溪边":
            return "你查看溪水与岸边。河道现有登记的小鱼%d条，岸上两只鱼笼须按时间检查；不能凭一句话生出渔获。" % int(data["fish_population"])
        return "溪边不在你眼前。想查看鱼笼，需要先走到石桥溪边。"
    if topic.contains("田") or topic.contains("菜") or topic.contains("庄稼"):
        if place == "石桥村·家中":
            return "院旁菜畦种着%s；播于第%d日。生长需要按农时结算。" % [str(data["field"]["crop"]),int(data["field"]["planted_day"])]
        return "田地在村边，从这里看不清菜畦的生长情况。"
    if topic.contains("妹妹") or topic.contains("成明"):
        var npc: Dictionary = data["npc"]["孙成明"]
        return "成明此刻登记在%s，正在%s。她的去向按自己的日程变化。" % [str(npc["place"]),str(npc["activity"])]
    if topic.contains("包") or topic.contains("钱") or topic.contains("物品"):
        return status()
    return look()

func _free_wait(raw: String) -> String:
    var minutes := 15
    var match_regex := RegEx.new()
    match_regex.compile("([0-9]{1,3})\\s*(分钟|分|小时|时辰)")
    var found := match_regex.search(raw)
    if found:
        minutes = int(found.get_string(1))
        if found.get_string(2) == "小时": minutes *= 60
        if found.get_string(2) == "时辰": minutes *= 120
    elif raw.contains("一小时"): minutes = 60
    elif raw.contains("半小时"): minutes = 30
    elif raw.contains("一刻"): minutes = 15
    elif raw.contains("两小时"): minutes = 120
    if raw.contains("明天") or raw.contains("一整天") or raw.contains("几天"):
        return "连续多日不能只靠站着等待；须先安排饮食、睡眠与补给。可说‘自动完成今日安排’。"
    if minutes < 1 or minutes > 480: return "一次等待限1至480分钟，以免跳过饮食、睡眠和NPC日程。"
    _tick(minutes)
    return "你在%s停留了%d分钟。天色、家人日程和世界时间继续流转。" % [str(data["place"]),minutes]

func _free_visit(raw: String) -> String:
    var place := str(data["place"])
    if raw.contains("林") or raw.contains("山脚树林") or raw.contains("野地"):
        if place == "石桥村·家中": return _move("石桥村·林缘",24,4)
        if place == "石桥村·溪边": return _move("石桥村·林缘",22,4)
        return "离这片村外林缘还有一段路，须先返回石桥村。"
    if place == "石桥村·林缘" and (raw.contains("回家") or raw.contains("回村")):
        return _move("石桥村·家中",24,4)
    if place == "石桥村·林缘" and (raw.contains("溪") or raw.contains("河")):
        return _move("石桥村·溪边",22,4)
    if raw.contains("青云") or raw.contains("山门"):
        return _act_core("出发去青云" if place == "石桥村·家中" else "沿山道北上")
    if raw.contains("县城") or raw.contains("临安") or raw.contains("市集"):
        return _act_core("去东市")
    if raw.contains("溪") or raw.contains("河边"):
        if place == "石桥村·家中": return _act_core("去溪边")
        return "目前不在能直接抵达石桥溪边的路段，需先返村。"
    if raw.contains("回家") or raw.contains("回村"):
        return _act_core("回家")
    return "你暂不知道通往这个地点的安全道路。可以先打听线索，而不能瞬间移动。"

func _free_collect(raw: String) -> String:
    if str(data["place"]) != "石桥村·林缘":
        return "采集地点不在眼前。村外林缘有落枝和普通草药；必须实际走到那里。"
    var kind := "车前草" if raw.contains("药") or raw.contains("草") or raw.contains("车前") else "枯枝"
    if raw.contains("砍") or raw.contains("伐") or raw.contains("整棵"):
        return "整棵树是村社的林木，不是无主资源；须先征得管地人的准许。可以捡地上的枯枝。"
    var stocks: Dictionary = data.get("forest_stock",{"枯枝":6,"车前草":3})
    var count := int(stocks.get(kind,0))
    if count < 1: return "这一带暂时没有可以安全采下的%s，需要等资源自然恢复。" % kind
    if int(data["stamina"]) < 7: return "精力不足，今天不宜继续在野地采集。"
    stocks[kind] = count-1
    data["forest_stock"]=stocks
    _tick(40,-7)
    _add(kind,1)
    return "你沿林缘寻找，取到一份%s。林地余量已登记，采走一份就少一份。" % kind

func _free_chore(raw: String) -> String:
    if str(data["place"]) != "石桥村·家中": return "家务要回到钱家院落才能做。"
    if int(data.get("chores_day",0)) == int(data["day"]):
        return "今天已经帮着做过一轮家务，家里暂时没有更多活需要你重复做。"
    if int(data["stamina"]) < 8: return "你精力不足，家人劝你先歇一歇。"
    _tick(45,-8)
    data["chores_day"]=int(data["day"])
    var npc: Dictionary = data["npc"]["孙成明"]
    npc["rapport"]=mini(100,int(npc["rapport"])+2)
    return "你把院子扫净，帮忙挑水劈细柴。家务用了45分钟，成明见你分担了活，态度亲近了些。"

func _free_fish() -> String:
    if str(data["place"]) != "石桥村·溪边": return "手竿得在溪边才能用。"
    if not _has("简易鱼竿"): return "你身上没有能使用的鱼竿。"
    if int(data["stamina"]) < 9: return "精力不足，先休息。"
    _tick(70,-9)
    if int(data["fish_population"]) <= 0: return "你钓了一个多小时，河段已无登记存量的小鱼，没有收获。"
    var lucky := _roll("handline-%d" % int(data["turn"]),int(data["day"]))
    if lucky >= 42: return "浮漂沉沉浮浮，你等了一个多小时，仍没有鱼上钩。"
    data["fish_population"] = int(data["fish_population"])-1
    _add("小河鱼")
    return "你凭手竿钓起一条小河鱼。河段登记鱼群减少一条，背包增加一条。"

func _free_give(raw: String) -> String:
    var npc_name := ""
    if raw.contains("妹妹") or raw.contains("成明"): npc_name="孙成明"
    elif raw.contains("母亲") or raw.contains("娘"): npc_name="郑舟清"
    elif raw.contains("父亲") or raw.contains("爹"): npc_name="钱然泽"
    if npc_name.is_empty(): return "你打算把物品给谁？请说明人物和物品。"
    if str(data["place"]) != "石桥村·家中": return "要当面交给家人，须先回到钱家院落。"
    if npc_name=="孙成明" and not _sister_here(): return "成明不在家，暂时无法当面交给她。"
    if npc_name=="钱然泽" and int(data["minute"]) >= 420 and int(data["minute"]) <= 1050:
        return "父亲正在田里，待他回来再交。"
    var item := ""
    for candidate in ["小河鱼","枯枝","车前草","青菜","引气初篇"]:
        if raw.contains(candidate) or candidate=="小河鱼" and raw.contains("鱼"):
            item=candidate
            break
    if item.is_empty(): return "没听清你想交出什么物品。可说‘把小河鱼给妹妹’。"
    if not _has(item): return "你背包里没有%s，不能凭话语创造财物。" % item
    if item=="引气初篇":
        return "这本残旧册子目前由成明保管，不应再次从你的背包重复赠送。"
    _take(item)
    var person: Dictionary = data["npc"][npc_name]
    var owned: Dictionary = person.get("items",{})
    owned[item]=int(owned.get(item,0))+1
    person["items"]=owned
    _tick(5)
    if npc_name=="孙成明": person["rapport"]=mini(100,int(person["rapport"])+2)
    return "你当面把一份%s交给%s。物品已从你的背包移入对方的物品账本。" % [item,npc_name]

func _free_say(raw: String) -> String:
    var who := ""
    if raw.contains("妹妹") or raw.contains("成明"): who="孙成明"
    elif raw.contains("母亲") or raw.contains("娘"): who="郑舟清"
    elif raw.contains("父亲") or raw.contains("爹"): who="钱然泽"
    if who.is_empty(): return "你想跟谁说话？可以写‘问妹妹今天忙什么’。"
    var topic := "家常"
    if raw.contains("饭") or raw.contains("饿"): topic="饭"
    elif raw.contains("青云") or raw.contains("上山") or raw.contains("测灵"): topic="青云"
    elif raw.contains("忙") or raw.contains("干什么"): topic="劳作"
    elif raw.contains("鱼"): topic="捕鱼"
    elif raw.contains("学习") or raw.contains("口诀"): topic="读书"
    if topic in ["饭","青云"]: return _family_chat(who,topic)
    if str(data["place"]) != "石桥村·家中": return "此人不在眼前，要找到对方才能交谈。"
    if who=="孙成明" and not _sister_here(): return "成明正在外面忙自己的事情，暂时不能交谈。"
    if who=="钱然泽" and int(data["minute"])>=420 and int(data["minute"])<=1050:
        return "父亲此时还在田里，不能替他远程回答。"
    _tick(4)
    if who=="孙成明":
        if topic=="捕鱼": return "成明说：‘河里的鱼最近少了不少。你要是还想下笼，得让它们缓一缓。’"
        if topic=="读书": return "成明摇摇头：‘那册子不是假的吗？先别急着照练，我要先把今天的活做完。’"
        return "成明抬头应你：‘我今天%s呢，忙完再多聊。’" % str(data["npc"]["孙成明"]["activity"])
    if who=="郑舟清": return "母亲说：‘外头事情再多，也要顾着家里的米粮和脚下的路。’"
    return "父亲放下手里的活：‘凡事得先看清楚，再动手。’"

func _npc_free_chat(raw: String) -> String:
    # Explicit direct-speech form only. Do not infer dialogue from incidental NPC mentions.
    var recipient := ""
    for person in ["孙成明", "钱然泽", "郑舟清"]:
        if raw.begins_with("跟" + person + "说") or raw.begins_with("对" + person + "说") or raw.begins_with("问" + person) or raw.begins_with("和" + person + "聊天"):
            recipient = person
            break
    if recipient.is_empty():
        return ""
    var npc: Dictionary = data["npc"][recipient]
    if str(npc.get("place", "")) != str(data["place"]):
        return "%s此刻在%s，不在你身边。你说的话没有人能当面听见。" % [recipient,str(npc.get("place","别处"))]
    if recipient=="钱然泽" and int(data["minute"]) >= 420 and int(data["minute"]) <= 1050:
        return "父亲白天正在忙田间事务，得等他回家才能当面谈。"
    var said := raw
    for prefix in ["跟"+recipient+"说：","对"+recipient+"说：","跟"+recipient+"说:","对"+recipient+"说:","问"+recipient,"和"+recipient+"聊天"]:
        if said.begins_with(prefix):
            said=said.trim_prefix(prefix).strip_edges()
            break
    if said.is_empty(): return "你想对%s说什么？输入完整的话即可。" % recipient
    _tick(4)
    var mood := str(npc.get("mood","平静"))
    if said.contains("饭") or said.contains("饿"):
        if recipient=="孙成明": return "成明把手中的活放下：‘娘会留饭。你问我吃没吃？我一会儿就去灶屋看看。’"
        if recipient=="郑舟清": return "母亲笑道：‘锅里留着吃的，你也得准时吃饭。’"
        return "父亲应道：‘忙过这阵子便吃。’"
    if said.contains("青云") or said.contains("修仙") or said.contains("灵根"):
        if recipient=="孙成明": return "成明认真听着：‘我也不晓得测灵究竟怎么做。你回来可得把见闻讲给我听。’"
        if recipient=="郑舟清": return "母亲嘱咐：‘走远路谨慎些，真有不明白的事情，要问清再花钱。’"
        return "父亲说：‘读书修行都要看实在的东西，不要再买那样的假诀了。’"
    if said.contains("鱼") or said.contains("田") or said.contains("收成") or said.contains("种"):
        if recipient=="孙成明": return "成明答道：‘溪里的鱼少了，田里的事也不能耽搁。等忙完再去看看吧。’"
        if recipient=="郑舟清": return "母亲说：‘田里的收成要按农时来，别只图一时热闹。’"
        return "父亲答道：‘鱼和粮都得有个账本，取了就得记清楚。’"
    if said.contains("干嘛") or said.contains("忙") or said.contains("做什么"):
        return "%s抬头应你：‘我现在正%s，忙完再说吧。’" % [recipient,str(npc.get("activity","忙家事"))]
    if said.contains("你好") or said.contains("早上好") or said.contains("晚安") or said.contains("谢谢"):
        return "%s听完你的话，点点头：‘嗯，知道了。’" % recipient
    # Honest fallback: acknowledge exact message, without repeatedly using a generic script.
    return "%s听你说完‘%s’，沉吟片刻：‘这我一时也说不准。你怎么会想到这个？’（情绪：%s）" % [recipient,said.substr(0,36),mood]

func _free_action(raw: String) -> String:
    var t := raw.strip_edges().replace("，","").replace("。","").replace("！","")
    if t.is_empty(): return ""
    # Move to a destination first, then execute the requested gathering there.
    if (t.contains("去") or t.contains("前往") or t.contains("走到")) and (t.contains("林缘") or t.contains("树林") or t.contains("村外")) and (t.contains("拾") or t.contains("捡") or t.contains("采")):
        var travel := _free_visit(t)
        if str(data["place"]) == "石桥村·林缘":
            return travel + "\n" + _free_collect(t)
        return travel
    var direct_speech := _npc_free_chat(t)
    if not direct_speech.is_empty(): return direct_speech
    # Speech and inspection take priority over broad keyword shortcuts.
    if t.contains("观察") or t.contains("查看") or t.contains("看看") or t.contains("打量") or t.contains("调查"):
        if t.contains("鱼笼"): return _act_core("查看鱼笼")
        return _free_observe(t)
    if (t.contains("问") or t.contains("聊天") or t.contains("说话") or t.contains("聊聊") or t.contains("告诉")) and (t.contains("妹妹") or t.contains("成明") or t.contains("母亲") or t.contains("娘") or t.contains("父亲") or t.contains("爹")):
        return _free_say(t)
    if t.contains("等候") or t.begins_with("等") or t.contains("待一会"):
        return _free_wait(t)
    if t.contains("给") and (t.contains("妹妹") or t.contains("成明") or t.contains("母亲") or t.contains("娘") or t.contains("父亲") or t.contains("爹")) and (t.contains("鱼") or t.contains("草") or t.contains("柴") or t.contains("枝") or t.contains("菜") or t.contains("书")):
        return _free_give(t)
    if t.contains("打扫") or t.contains("挑水") or t.contains("家务") or t.contains("劈柴") or t.contains("帮娘干活"):
        return _free_chore(t)
    if t.contains("钓鱼") or t.contains("甩竿") or t.contains("下竿"): return _free_fish()
    if (t.contains("捡") or t.contains("拾") or t.contains("采") or t.contains("挖") or t.contains("砍")) and (t.contains("柴") or t.contains("枝") or t.contains("草") or t.contains("药") or t.contains("树") or t.contains("木")):
        return _free_collect(t)
    if t.contains("去") or t.contains("前往") or t.contains("走到") or t.contains("回村") or t.contains("回家"):
        if t.contains("林") or t.contains("树林") or t.contains("森林") or t.contains("村外") or t.contains("溪") or t.contains("河边") or t.contains("青云") or t.contains("县城") or t.contains("临安") or t.contains("市集") or t.contains("回家") or t.contains("回村"):
            return _free_visit(t)
    return ""

func _act_core(action: String) -> String:
    match action:
        "查看四周": return look()
        "向老道买书": return _buy_manual()
        "回石桥村":
            if data["place"] == "石桥村·家中": return "你已经在家。"
            return _move("石桥村·家中", 124, 18)
        "去溪边":
            if data["place"] != "石桥村·家中": return "你得先在石桥村家中整理行装。"
            return _move("石桥村·溪边", 18, 3)
        "回家":
            if data["place"] == "石桥村·家中": return "你已经在家。"
            if data["place"] == "石桥村·溪边": return _move("石桥村·家中", 18, 2)
            return _move("石桥村·家中", 124, 18)
        "出发去青云":
            if data["place"] != "石桥村·家中": return "要从石桥村家里启程。"
            if int(data["money"]) < 30: return "测灵台需30文，你现在盘缠不足，不宜贸然上路。"
            var started := _move("临安县城·东市", 115, 17)
            data["journey"]["stage"] = "抵达临安，准备北上"
            return "你向父母道别，成明送到村口，山风吹动她的衣袖。\n" + started
        "沿山道北上":
            if data["place"] != "临安县城·东市": return "先到临安，再从北门走青云山道。"
            # Fatigue is real: a traveller can stop and rest en route.
            if int(data["stamina"]) < 45: return "离开县城前体力不足，先在客店歇脚。"
            _tick(357, -43)
            data["place"] = "青云山门·山门外"
            data["journey"]["stage"] = "抵达青云山门，尚未测灵"
            return "你走过蜿蜒山道，终于看见青云山门石阶和云雾中的测灵台。凡人须先向执事报明来意。"
        "山脚脚店投宿":
            if data["place"] != "临安县城·东市" and data["place"] != "青云山门·山门外": return "这里找不到山脚脚店。"
            if int(data["money"]) < 8: return "脚店一晚8文，你付不起。"
            data["money"] = int(data["money"]) - 8
            data["journey"]["lodging_nights"] = int(data["journey"]["lodging_nights"]) + 1
            _tick(480, 48)
            return "你付八文住了一晚，有粗饭和热水，睡醒体力恢复。"
        "申请测灵根":
            if data["place"] != "青云山门·山门外": return "必须先到青云山门测灵台。"
            if int(data["money"]) < 30: return "测灵台过门钱30文，尚不够。"
            if data["journey"]["tested"]: return "此前已进行过检测，不能重复。"
            # Crucial: without original secret salt/root opening, SHA256 commitment alone
            # cannot yield the underlying root. Do not take money for a nonexistent result.
            return "执事收好登记簿，示意你等候。要完成‘一次定终身’的测灵归档，还缺原开局灵根承诺的原始揭示值；本地版不能从哈希倒推资质，也不会扣去30文或假报无灵根。"
        "去东市":
            if data["place"].begins_with("临安县城"): return _move("临安县城·东市", 20, 2)
            return _move("临安县城·东市", 115, 16)
        "回旧书铺":
            if data["place"] == "临安县城·东市": return _move("临安县城·旧书铺", 20, 2)
            return "从这里要先去县城。"
        "读引气初篇": return _study()
        "静坐修炼": return _meditate()
        "吃饭休息": return _meal()
        "睡觉": return _sleep()
        "跟妹妹说话": return _talk()
        "问妹妹吃饭了吗": return _family_chat("孙成明", "饭")
        "问母亲吃饭了吗": return _family_chat("郑舟清", "饭")
        "问父亲吃饭了吗": return _family_chat("钱然泽", "饭")
        "问妹妹青云的事": return _family_chat("孙成明", "青云")
        "问母亲青云的事": return _family_chat("郑舟清", "青云")
        "问父亲青云的事": return _family_chat("钱然泽", "青云")
        "询问吃饭对象": return "你想问谁吃饭了？可以输入‘问妹妹吃饭了吗’、‘问母亲吃饭了吗’；若你自己要吃饭，请说‘我要吃饭’。"
        "查看当前目标": return "眼下要去青云山门测灵根。先从石桥村出发，经临安北上。你的《引气初篇》已证实是伪诀，无须再耗时照练。"
        "教妹妹修炼": return _teach()
        "取鱼笼里的鱼": return _catch_fish()
        "查看鱼笼": return _fish_check()
        "布第二只鱼笼":
            if data["place"] != "石桥村·溪边": return "必须来到溪边才能布笼。"
            if not _take("编织鱼笼"): return "背包里没有备用鱼笼。"
            _tick(18, -3)
            data["gear"]["second"]["owned"] = true
            return "你把第二只鱼笼安置在浅水湾，刚放下时笼里是空的。"
        "组装鱼竿": return _rod()
        "播种青菜": return _sow()
        "收获青菜": return _harvest()
        "出售小河鱼": return _sell("小河鱼")
        "出售青菜": return _sell("青菜")
        "自动完成今日安排": return _routine()
        "连续修炼十日": return _continuous(10)
        "连续修炼一天": return _continuous(1)
        "查看修炼结论": return "当前灵根承诺 %s…，尚未揭示且无法重抽。经络热感不等于灵力；本地版只登记学习与静坐，不会伪造突破。" % String(data["root_commitment"]).substr(0, 12)
        _:
            return "暂不支持‘%s’。此操作没有消耗时间或资源。" % action

func _resolve_input(raw: String) -> String:
    var text := raw.strip_edges()
    if text.is_empty(): return ""
    var known: Array[String] = ["查看四周", "向老道买书", "回石桥村", "去溪边", "回家", "去东市", "回旧书铺", "读引气初篇", "静坐修炼", "吃饭休息", "睡觉", "跟妹妹说话", "教妹妹修炼", "取鱼笼里的鱼", "查看鱼笼", "布第二只鱼笼", "组装鱼竿", "播种青菜", "收获青菜", "出售小河鱼", "出售青菜", "自动完成今日安排", "连续修炼一天", "连续修炼十日", "查看修炼结论", "出发去青云", "沿山道北上", "山脚脚店投宿", "申请测灵根"]
    if known.has(text): return text
    # Everyday interrogatives must not trigger eating or physical movement.
    var question := text.ends_with("吗") or text.ends_with("呢") or text.contains("？") or text.contains("?") or text.contains("有没有") or text.contains("怎么")
    if text.contains("饭") or text.contains("饿"):
        if question:
            if text.contains("妹妹") or text.contains("成明"): return "问妹妹吃饭了吗"
            if text.contains("母亲") or text.contains("娘") or text.contains("妈妈"): return "问母亲吃饭了吗"
            if text.contains("父亲") or text.contains("爹") or text.contains("爸爸"): return "问父亲吃饭了吗"
            return "询问吃饭对象"
        if text.contains("吃") or text.contains("饿") or text.contains("开饭"): return "吃饭休息"
    if text.contains("青云") and question:
        if text.contains("妹妹") or text.contains("成明"): return "问妹妹青云的事"
        if text.contains("母亲") or text.contains("娘"): return "问母亲青云的事"
        if text.contains("父亲") or text.contains("爹"): return "问父亲青云的事"
        return "查看当前目标"
    if text.contains("做什么") or text.contains("下一步") or text.contains("目标"): return "查看当前目标"
    # Ordered intents: teach before cultivate, place before generic fish lookup.
    if text.contains("青云") and (text.contains("出发") or text.contains("动身") or text.contains("去")):
        return "出发去青云" if data["place"] == "石桥村·家中" else "沿山道北上"
    if text.contains("北上") or text.contains("山道"): return "沿山道北上"
    if text.contains("测灵") or text.contains("检测灵根"): return "申请测灵根"
    if text.contains("脚店") or text.contains("投宿"): return "山脚脚店投宿"
    if text.contains("日程") or text.contains("今日安排") or text.contains("家务全做"): return "自动完成今日安排"
    if text.contains("教") and (text.contains("妹妹") or text.contains("成明")): return "教妹妹修炼"
    if text.contains("十日") or text.contains("十天") or text.contains("直到有结果"): return "连续修炼十日"
    if text.contains("一天") or text.contains("整日"): return "连续修炼一天"
    if text.contains("老道") or text.contains("买书"): return "向老道买书"
    if text.contains("出售") or text.contains("卖"):
        if text.contains("鱼"): return "出售小河鱼"
        if text.contains("菜"): return "出售青菜"
    if text.contains("去东市") or text.contains("去市场") or text.contains("进城卖"): return "去东市"
    if text.contains("县城") and text.contains("回"): return "去东市"
    if text.contains("布") and text.contains("鱼笼"): return "布第二只鱼笼"
    if text.contains("查看鱼笼") or text.contains("检查鱼笼"): return "查看鱼笼"
    if text.contains("鱼") and text.contains("取"): return "取鱼笼里的鱼"
    if text.contains("鱼竿"): return "组装鱼竿"
    if text.contains("播种") or text.contains("种菜"): return "播种青菜"
    if text.contains("收菜") or text.contains("收获青菜"): return "收获青菜"
    if text.contains("妹妹") or text.contains("成明"): return "跟妹妹说话"
    if text.contains("读") or text.contains("背书"): return "读引气初篇"
    if text.contains("修炼") or text.contains("引气") or text.contains("静坐"): return "静坐修炼"
    if text.contains("睡") or text.contains("休息"): return "睡觉"
    if text.contains("回家") or text.contains("回村"): return "回家"
    if text.contains("溪") or text.contains("河边"): return "去溪边"
    if text.contains("看") or text.contains("周围"): return "查看四周"
    return text

func act(action: String) -> String:
    if action.strip_edges().is_empty(): return "没有输入行动。"
    var before := _clock()
    var free_result := _free_action(action)
    var canonical := _resolve_input(action) if free_result.is_empty() else "自由行动"
    var result := _act_core(canonical) if free_result.is_empty() else free_result
    last_result = result
    var line := action.strip_edges()
    var dialogue := (line.contains("妹妹") or line.contains("成明") or line.contains("母亲") or line.contains("父亲") or line.contains("爹") or line.contains("娘")) and (line.contains("问") or line.contains("说") or line.contains("聊") or line.contains("吃饭了吗"))
    dialogue = dialogue or canonical.begins_with("问妹妹") or canonical.begins_with("问母亲") or canonical.begins_with("问父亲") or canonical=="跟妹妹说话"
    var is_rejected := result.begins_with("暂不支持")
    if is_rejected:
        _record_feedback(line, result, "UNSUPPORTED_ACTION")
        last_channel="反馈"
        last_target=""
    elif dialogue:
        var who := "孙成明"
        if line.contains("母亲") or line.contains("娘"): who="郑舟清"
        elif line.contains("父亲") or line.contains("爹"): who="钱然泽"
        last_channel="对话"
        last_target=who
        if _clock() > before:
            var conversations: Array = data.get("dialogue_log",[])
            conversations.append({"day":int(data["day"]),"speaker":who,"player":line.substr(0,250),"reply":result,"ai":false})
            if conversations.size()>80: conversations.pop_front()
            data["dialogue_log"]=conversations
    else:
        last_channel="剧情"
        last_target=""
        if canonical != "询问吃饭对象" and canonical != "查看当前目标":
            _note("【%s · %s】\n%s" % [time_string(), line, result])
    if _clock() < before: push_error("World time unexpectedly reversed")
    save()
    return result

func look() -> String:
    match data["place"]:
        "临安县城·旧书铺": return "城里旧书铺并没有可靠修仙法门。屋檐下的游方老道还坐着，面前放着一本泛黄小册。"
        "临安县城·东市": return "东市里菜肉摊正收河鱼与青菜。官道在东门外，青云山道从北门蜿蜒而上。"
        "青云山门·山门外": return "高石阶旁立着宗门的测灵碑。凡人走到这里不容易；执事让排队，30文测灵费须在能够真正测试时缴纳。"
        "石桥村·家中": return "院里晒着谷物，灶上有烟，屋旁是菜畦。成明有自己的家务；父亲田里忙，母亲管家。"
        "石桥村·溪边": return "浅溪旁芦苇成片。第一只鱼笼还在水里，已登记的河鱼并非取之不尽。"
        "石桥村·林缘": return "村外林缘落枝散乱，偶尔能找到车前草。往深处是村社林木，不得随意伐树。" 
    return "远处田野与山路相接，世界仍有人各自谋生。"

func actions_for_place() -> Array[String]:
    match data["place"]:
        "临安县城·旧书铺": return ["查看四周", "向老道买书", "回石桥村", "去东市", "查看修炼结论"]
        "临安县城·东市": return ["查看四周", "沿山道北上", "山脚脚店投宿", "出售小河鱼", "出售青菜", "回旧书铺", "回石桥村"]
        "石桥村·溪边": return ["查看四周", "查看鱼笼", "钓鱼", "取鱼笼里的鱼", "去林缘", "回家"]
        "石桥村·林缘": return ["查看四周", "捡枯枝", "采车前草", "去溪边", "回家"]
        "青云山门·山门外": return ["查看四周", "申请测灵根", "山脚脚店投宿", "查看修炼结论"]
        _: return ["查看四周", "自动完成今日安排", "跟妹妹说话", "教妹妹修炼", "读引气初篇", "静坐修炼", "连续修炼一天", "连续修炼十日", "查看修炼结论", "吃饭休息", "睡觉", "播种青菜", "收获青菜", "组装鱼竿", "去溪边", "出发去青云", "去东市"]

func status() -> String:
    var lines: Array[String] = []
    lines.append("【人物】 %s · %d岁" % [data["name"], int(data["age"])])
    lines.append("【日期】 " + time_string())
    lines.append("【地点】 %s · %s" % [data["place"], data["weather"]])
    lines.append("【境界】 %s · 灵根%s" % [data["realm"], data["root"]])
    lines.append("【身体】 气血%d/100 · 精力%d/100" % [int(data["hp"]), int(data["stamina"])])
    lines.append("【财物】 随身%d文 · 家中%d文" % [int(data["money"]), int(data["house_money"])])
    lines.append("【口粮】 %.3f斗" % [float(data["grain_milli"]) / 1000.0])
    lines.append("【修行】 参悟%d/100 · 静坐%d小时" % [int(data["insight"]), int(data["quiet_hours"])])
    lines.append("【功法】 %s" % [data["book_real"] if data["book_owned"] else "尚未获得"])
    lines.append("\n【背包】")
    for item in data["items"]: lines.append(" · %s ×%d" % [item, int(data["items"][item])])
    lines.append("\n【家人】")
    for npc in data["npc"]:
        lines.append(" · %s：%s（%s）" % [npc, data["npc"][npc]["activity"], data["npc"][npc]["place"]])
    lines.append("\n【提示】 手机离线存档，主线锚点 %s；未知资质不擅自揭示。" % data["source_event"])
    return "\n".join(lines)

func story_recent(n: int = 10) -> String:
    var arr: Array[String] = []
    for i in range(maxi(0, journal.size() - n), journal.size()): arr.append(str(journal[i]))
    return "\n\n".join(arr)