extends Node
class_name XianfanLocalLLM
# NobodyWho v12.1.0 native Godot GDExtension, Android ARM64.
# Model downloaded only after an explicit button press, never at startup.
signal status_changed(message: String)
signal answered(payload: Dictionary)
const MODEL := "hf://NobodyWho/Qwen_Qwen3-0.6B-GGUF/Qwen_Qwen3-0.6B-Q4_K_M.gguf"
# Sources: official Qwen GGUF file names; sizes in decimal GB, rounded.
# RAM figures are conservative guidance, not a guarantee of successful loading.
const MODELS := [
    {"id":"0.6B","title":"Qwen3 0.6B · 轻量测试","size_gb":0.5,"ram_gb":4,"storage_gb":1.2,"path":MODEL},
    {"id":"1.7B","title":"Qwen3 1.7B · 入门","size_gb":1.28,"ram_gb":6,"storage_gb":2.2,"path":"hf://Qwen/Qwen3-1.7B-GGUF/Qwen3-1.7B-Q4_K_M.gguf"},
    {"id":"4B","title":"Qwen3 4B · 推荐","size_gb":2.50,"ram_gb":8,"storage_gb":4.0,"path":"hf://Qwen/Qwen3-4B-GGUF/Qwen3-4B-Q4_K_M.gguf"},
    {"id":"8B","title":"Qwen3 8B · 大型","size_gb":5.03,"ram_gb":12,"storage_gb":7.0,"path":"hf://Qwen/Qwen3-8B-GGUF/Qwen3-8B-Q4_K_M.gguf"},
    {"id":"14B","title":"Qwen3 14B · 超大型/高风险","size_gb":9.0,"ram_gb":20,"storage_gb":12.0,"path":"hf://Qwen/Qwen3-14B-GGUF/Qwen3-14B-Q4_K_M.gguf"}
]
const PREF_PATH := "user://xianfan_local_model_selection.json"

static func preset(index: int) -> Dictionary:
    if index<0 or index>=MODELS.size(): return {}
    return MODELS[index].duplicate(true)

static func preset_index(path: String) -> int:
    for i in range(MODELS.size()):
        if str(MODELS[i]["path"])==path: return i
    return -1

static func model_hint(index: int) -> String:
    var item:=preset(index)
    if item.is_empty(): return "自定义 GGUF：请自行确认模型体积与手机兼容性。"
    return "%s · 约 %.2f GB 下载 · 建议内存至少 %d GB · 预留存储 %.1f GB。%s" % [
        str(item["title"]),float(item["size_gb"]),int(item["ram_gb"]),float(item["storage_gb"]),
        "可能因手机系统内存限制被终止，运行速度也可能很慢。" if index>=3 else "实际能否运行仍取决于手机与系统剩余内存。"
    ]
var model_ready := false
var loading := false
var busy := false
var current_chat: Variant
var model_source := MODEL
var active_name := "0.6B"
var last_error := ""
var pending_confirmation := false
var load_started_ticks := 0
var heartbeat: Timer

func _heartbeat() -> void:
    if not loading: return
    var elapsed:=maxi(0,int((Time.get_ticks_msec()-load_started_ticks)/1000))
    status_changed.emit("正在下载/加载 %s · 已持续%d秒。原生下载器尚不提供可验证的百分比，请勿强制关闭应用。" % [active_name,elapsed])

func _ready() -> void:
    heartbeat=Timer.new()
    heartbeat.wait_time=5.0
    heartbeat.one_shot=false
    heartbeat.timeout.connect(_heartbeat)
    add_child(heartbeat)
    if not FileAccess.file_exists(PREF_PATH): return
    var file:=FileAccess.open(PREF_PATH,FileAccess.READ)
    if file==null: return
    var parsed: Variant=JSON.parse_string(file.get_as_text())
    if parsed is Dictionary:
        var saved:=str(parsed.get("source",""))
        if saved.begins_with("hf://") or saved.begins_with("https://") or saved.begins_with("user://"):
            model_source=saved
            _update_name()

func _update_name() -> void:
    var i:=preset_index(model_source)
    active_name=str(MODELS[i]["id"]) if i>=0 else "自定义"

func unload_model() -> String:
    if loading or busy: return "模型正在下载或生成中，不能切换。"
    current_chat=null
    model_ready=false
    last_error=""
    status_changed.emit("已卸载当前模型。可选择其他模型下载；旧模型缓存不会自动删除。")
    return "已卸载，可切换"

func model_info() -> String:
    var i:=preset_index(model_source)
    return model_hint(i)

func persist_selection() -> void:
    var file:=FileAccess.open(PREF_PATH,FileAccess.WRITE)
    if file!=null:
        file.store_string(JSON.stringify({"source":model_source}))


func choose_model(source: String) -> String:
    if loading or busy: return "正在加载/生成，暂不能切换模型。"
    var path := source.strip_edges()
    if model_ready and path!=model_source: return "请先卸载当前已加载模型，再选择新模型。"
    if path.is_empty(): path=MODEL
    if not (path.begins_with("hf://") or path.begins_with("https://") or path.begins_with("user://")):
        return "只允许 Hugging Face 模型、HTTPS GGUF地址或已下载的user://模型。"
    if path.length()>500: return "模型地址过长。"
    model_source=path
    _update_name()
    last_error=""
    persist_selection()
    return "已选择 %s；请点下载/加载。首次下载不在APK内。" % active_name

func status() -> String:
    if loading: return "正在下载或加载 %s（可能需数GB）；请保持应用前台运行。" % active_name
    if model_ready: return "本机 %s 已加载，可离线对话" % active_name
    if not ClassDB.class_exists("NobodyWhoChat"): return "%s：原生推理扩展未加载；请到反馈页复制错误。" % active_name
    if not last_error.is_empty(): return "%s：%s" % [active_name,last_error]
    return "%s 未加载。选定后点击下载/加载，模型会缓存到手机。" % active_name

func load_model() -> void:
    if model_ready or loading: return
    if not ClassDB.class_exists("NobodyWhoChat"):
        status_changed.emit("原生推理库没有加载成功，请用反馈页记录设备型号与版本。")
        return
    loading=true
    load_started_ticks=Time.get_ticks_msec()
    heartbeat.start()
    last_error=""
    status_changed.emit("开始下载/加载 %s，模型体积约 %.2f GB；首次需稳定Wi-Fi及足够内存。原生下载器暂无百分比回调。" % [active_name,float(MODELS[preset_index(model_source)]["size_gb"]) if preset_index(model_source)>=0 else 0.0])
    # The native plugin downloads the model and caches it. It runs CPU-based
    # inference on device; no remote Chat Completions server or API key is used.
    # Dynamic call avoids a compile-time link on x86 CI; Android still resolves
    # the registered native class after loading the ARM64 extension.
    var loaded = await ClassDB.class_call_static("NobodyWhoChat","create",model_source, {"n_ctx":2048,"n_threads":3,"template_variables":{"enable_thinking":false}})
    loading=false
    heartbeat.stop()
    if loaded==null:
        model_ready=false
        last_error="下载或加载失败。请确认网络可访问模型仓库、手机存储与内存足够。"
        status_changed.emit(last_error)
        return
    current_chat=loaded
    model_ready=true
    status_changed.emit("已加载 %s。下载缓存可供离线对话。" % active_name)

# Build a fresh, bounded conversation for *each* NPC. The previous code kept
# accumulating unrelated multi-NPC prompts in one shared native chat context.
# This is a pure GDScript function so CI can verify role, scene and history.
func build_messages(text: String, person: String, state: Dictionary) -> Array:
    var scene := str(state.get("place","未知地点"))
    var current_day := int(state.get("day",0))
    var time := int(state.get("minute",0))
    var nickname := str(state.get("name","玩家"))
    var cleaned_text := text.strip_edges()
    if not person.is_empty():
        for prefix in ["跟"+person+"说：","跟"+person+"说:","对"+person+"说：","对"+person+"说:"]:
            if cleaned_text.begins_with(prefix):
                cleaned_text = cleaned_text.trim_prefix(prefix).strip_edges()
                break
    var messages: Array = []
    if not person.is_empty():
        var npc: Dictionary = state.get("npc",{}).get(person,{})
        var relationship := "妹妹" if person=="孙成明" else ("父亲" if person=="钱然泽" else "母亲")
        var personality := "心直口快、爱帮家里干活，有自己的打算，不是永远等着哥哥说话。" if person=="孙成明" else ("朴实慎重，不喜欢空口许诺。" if person=="钱然泽" else "细心务实，惦念家中饭食。")
        var system_text := "你正在扮演独立人生修仙世界中的真实NPC%s，身份是玩家%s的%s。性格：%s。" % [person,nickname,relationship,personality]
        system_text += "\n可信世界事实（优先级最高）：今天是第%d日 %02d:%02d。玩家位置：%s。你的当前位置：%s。你正在做：%s。你的情绪：%s。" % [current_day,int(time/60),time%60,scene,str(npc.get("place","未知")),str(npc.get("activity","家务")),str(npc.get("mood","平静"))]
        system_text += "\n约束：只扮演NPC，以一两句自然中文回答。每次要真正回应玩家最新问题和追问；不能答非所问、机械重复前一轮、虚构自己离开或正在路上。"
        system_text += "没有移动事件时不得宣称自己换了位置；你可以表达个人意愿和拒绝，但不能宣布获得物品、修炼突破、改变任何游戏数值。"
        system_text += "玩家问‘你在哪条路’时，必须基于登记位置解释，不能只重复‘我正在路上’。不要输出JSON或带‘旁白’的段落。"
        messages.append({"role":"system","content":system_text})
        var all_dialogue: Array = state.get("dialogue_log",[])
        var scoped: Array = []
        for item in all_dialogue:
            if not (item is Dictionary): continue
            var entry: Dictionary = item
            if str(entry.get("speaker",""))==person:
                scoped.append(entry)
        # Recent 4 exchanges max, and every NPC gets their own context.
        for idx in range(maxi(0,scoped.size()-4),scoped.size()):
            var old: Dictionary=scoped[idx]
            var player_words := str(old.get("player","")).substr(0,180)
            for prefix in ["跟"+person+"说：","跟"+person+"说:"]:
                if player_words.begins_with(prefix):
                    player_words=player_words.trim_prefix(prefix)
                    break
            messages.append({"role":"user","content":player_words})
            messages.append({"role":"assistant","content":str(old.get("reply","")).substr(0,180)})
        messages.append({"role":"user","content":cleaned_text.substr(0,300)})
    else:
        var system_text := "你是古风生活世界里的行为解释器，只输出一份JSON对象。形如{\"kind\":\"action\",\"command\":\"去林缘\"}。"
        system_text += "不能创造物品、钱财、NPC决定或修炼结果。只有合法的动作建议会交给世界引擎重新结算；缺少规则就输出{\"kind\":\"clarify\",\"message\":\"行动未实现\"}。"
        system_text += "支持：查看四周、去林缘、捡枯枝、采车前草、钓鱼、等30分钟、回家、打扫院子、睡觉、出发去青云。"
        messages.append({"role":"system","content":system_text})
        messages.append({"role":"user","content":"当前地点："+scene+"；第%d日；玩家行动：" % current_day+cleaned_text.substr(0,300)})
    return messages

func _unusable_duplicate(reply: String, person: String, state: Dictionary, current_text: String) -> bool:
    if person.is_empty(): return false
    var logs: Array = state.get("dialogue_log",[])
    for i in range(logs.size()-1,-1,-1):
        var record: Variant=logs[i]
        if record is Dictionary and str(record.get("speaker",""))==person:
            # Repeating a reply verbatim to a different follow-up is not a conversation.
            return str(record.get("reply","")).strip_edges()==reply.strip_edges() and str(record.get("player","")).strip_edges()!=current_text.strip_edges()
    return false

func talk(text: String, person: String, state: Dictionary) -> void:
    if busy:
        answered.emit({"ok":false,"error":"上一轮还在生成，请完成后再发。"})
        return
    if not model_ready:
        answered.emit({"ok":false,"error":"本地模型尚未完成下载/加载。"})
        return
    var npc: Dictionary=state.get("npc",{}).get(person,{})
    if not person.is_empty() and (npc.is_empty() or str(npc.get("place",""))!=str(state.get("place",""))):
        answered.emit({"ok":false,"error":"NPC不在眼前。先走到对方所在地，不能远程生成当面对话。"})
        return
    busy=true
    var messages := build_messages(text,person,state)
    # complete() replaces the native chat history, preventing NPC cross-talk and
    # keeping reliable turn-taking based on the persistent game save.
    var stream = current_chat.complete(messages,{})
    if stream==null:
        busy=false
        answered.emit({"ok":false,"error":"本地模型无法建立上下文，未写入人物记忆。"})
        return
    var output: Variant=await stream.completed()
    if output==null:
        busy=false
        answered.emit({"ok":false,"error":"模型生成失败，未写入对话。"})
        return
    var reply := str(output).strip_edges()
    if not person.is_empty() and _unusable_duplicate(reply,person,state,text):
        var retry: Array=messages.duplicate(true)
        retry.append({"role":"assistant","content":reply})
        retry.append({"role":"user","content":"你刚刚原样重复了上一轮答复。请具体回答我现在追问的内容，并且不得声称自己换了地方。"})
        var second_stream=current_chat.complete(retry,{})
        if second_stream!=null:
            var second: Variant=await second_stream.completed()
            if second!=null:
                reply=str(second).strip_edges()
    busy=false
    if reply.is_empty():
        answered.emit({"ok":false,"error":"模型返回了空白答复。"})
        return
    if not person.is_empty():
        if _unusable_duplicate(reply,person,state,text):
            answered.emit({"ok":false,"error":"本地AI连续重复上一轮回复，已拒绝写入；可在反馈页复制问题。"})
            return
        answered.emit({"ok":true,"kind":"dialogue","npc":person,"reply":reply.substr(0,300),"raw":text,"engine":"local-gguf"})
        return
    var a:=reply.find("{")
    var b:=reply.rfind("}")
    if a<0 or b<a:
        answered.emit({"ok":true,"kind":"clarify","message":"本地模型无法转换为可执行动作，请进一步说明。","raw":text})
        return
    var parsed: Variant=JSON.parse_string(reply.substr(a,b-a+1))
    if not (parsed is Dictionary):
        answered.emit({"ok":true,"kind":"clarify","message":"动作JSON无效，请换个说法。","raw":text})
        return
    var candidate: Dictionary=parsed
    if str(candidate.get("kind",""))=="action":
        answered.emit({"ok":true,"kind":"action","command":str(candidate.get("command","")).substr(0,200),"raw":text})
    else:
        answered.emit({"ok":true,"kind":"clarify","message":str(candidate.get("message","动作未实现")).substr(0,200),"raw":text})
