extends Node
class_name XianfanLocalLLM
# NobodyWho v12.1.0 native Godot GDExtension, Android ARM64.
# Model downloaded only after an explicit button press, never at startup.
signal status_changed(message: String)
signal answered(payload: Dictionary)
signal streaming(kind: String, content: String)
signal download_progress(info: Dictionary)
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
# All Qwen3 presets support 32K native context; on a phone KV cache RAM
# and thermal throttling become the limit far earlier.
const CONTEXT_CHOICES := [4096,8192,16384,32768]
static func default_context(model_name: String) -> int:
    if model_name=="4B" or model_name=="1.7B": return 16384
    if model_name=="8B" or model_name=="14B": return 4096
    return 8192
static func context_hint(tokens: int, model_name: String) -> String:
    var risk:="常规" if tokens<=8192 else ("高内存/发热风险" if tokens<=16384 else "极高风险：12GB物理内存上8B可能被系统终止")
    return "%d tokens · %s · 历史经历独立存在本地，不因上下文滚动而删除。必须卸载并重新加载模型才会改变已建立的上下文大小。" % [tokens,risk]

static func preset(index: int) -> Dictionary:
    if index<0 or index>=MODELS.size(): return {}
    return MODELS[index].duplicate(true)

static func preset_index(path: String) -> int:
    for i in range(MODELS.size()):
        if str(MODELS[i]["path"])==path: return i
        if path.begins_with("https://hf-mirror.com/"):
            var resolved:=XianfanResumableModelDownload.source_url(str(MODELS[i]["path"]))
            if path==resolved.replace("https://huggingface.co/","https://hf-mirror.com/"):
                return i
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
var generation_cancelled := false
var current_chat: Variant
var model_source := MODEL
var context_tokens := 8192
var context_customized := false
var active_name := "0.6B"
var last_error := ""
var pending_confirmation := false
var load_started_ticks := 0
var heartbeat: Timer
var download_manager: XianfanResumableModelDownload
var loading_weights := false
const MAX_DIALOGUE_SECONDS := 45.0
const MAX_STORY_SECONDS := 60.0
var _generation_watchdog: Timer
var _generation_timed_out := false

func _heartbeat() -> void:
    if not loading: return
    var elapsed:=maxi(0,int((Time.get_ticks_msec()-load_started_ticks)/1000))
    if download_manager.active:
        var bytes:=int(download_manager.last_progress.get("bytes",0))
        var total:=int(download_manager.last_progress.get("total",-1))
        status_changed.emit("已下载 %.2f GB / %s；文件已在磁盘缓存，网络中断会自动断点重试。" % [
            float(bytes)/1000000000.0,("%.2f GB" % (float(total)/1000000000.0)) if total>0 else "总大小待服务器确认"])
    else:
        status_changed.emit("本机 %s 正在加载模型权重，已持续%d秒。" % [active_name,elapsed])

func _ready() -> void:
    download_manager=XianfanResumableModelDownload.new()
    add_child(download_manager)
    download_manager.progress.connect(_on_download_progress)
    download_manager.completed.connect(_on_download_finished)
    heartbeat=Timer.new()
    heartbeat.wait_time=5.0
    heartbeat.one_shot=false
    heartbeat.timeout.connect(_heartbeat)
    add_child(heartbeat)
    _generation_watchdog=Timer.new()
    _generation_watchdog.one_shot=true
    _generation_watchdog.timeout.connect(_on_generation_timeout)
    add_child(_generation_watchdog)
    if not FileAccess.file_exists(PREF_PATH): return
    var file:=FileAccess.open(PREF_PATH,FileAccess.READ)
    if file==null: return
    var parsed: Variant=JSON.parse_string(file.get_as_text())
    if parsed is Dictionary:
        var saved:=str(parsed.get("source",""))
        if saved.begins_with("hf://") or saved.begins_with("https://") or saved.begins_with("user://"):
            model_source=saved
            _update_name()
        var selected:=int(parsed.get("n_ctx",default_context(active_name)))
        if CONTEXT_CHOICES.has(selected): context_tokens=selected
        context_customized=bool(parsed.get("context_customized",false))
        # Earlier builds stored an 8192-token default for 8B. Migrate only
        # uncustomized selections, preserving deliberate user settings.
        if not context_customized: context_tokens=default_context(active_name)

func _update_name() -> void:
    var i:=preset_index(model_source)
    active_name=str(MODELS[i]["id"]) if i>=0 else "自定义"

func context_usage() -> String:
    if not model_ready or current_chat==null:
        return "当前模型未加载。已设置 %d tokens；本地记忆不会随窗口溢出删除。" % context_tokens
    if busy: return "模型正在生成，请完成或停止后再查询使用情况。"
    var stats: Variant=await current_chat.get_stats()
    if not (stats is Dictionary): return "原生库未返回上下文统计。"
    return "当前模型上下文：%d / %d tokens，记忆另存独立本地文件。" % [
        int(stats.get("context_used",0)),int(stats.get("context_size",context_tokens))]

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
        file.store_string(JSON.stringify({"source":model_source,"n_ctx":context_tokens,
            "context_customized":context_customized}))

func choose_context(tokens: int) -> String:
    if not CONTEXT_CHOICES.has(tokens): return "不支持的上下文档位。"
    if loading or busy: return "模型正在运行，请先完成当前任务。"
    if model_ready and context_tokens!=tokens:
        return "模型已经加载。请先卸载模型，再选择新的上下文长度。"
    context_tokens=tokens
    context_customized=true
    persist_selection()
    return "已设置 "+context_hint(tokens,active_name)

func _ctx_for_model() -> void:
    if not context_customized:
        context_tokens=default_context(active_name)


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
    _ctx_for_model()
    last_error=""
    persist_selection()
    return "已选择 %s；请点下载/加载。首次下载不在APK内。" % active_name

func status() -> String:
    if loading:
        if loading_weights: return "正在把 %s 权重载入RAM，请勿切换。" % active_name
        var stats: Dictionary=download_manager.last_progress if download_manager!=null else {}
        var bytes:=int(stats.get("bytes",0))
        var total:=int(stats.get("total",-1))
        return "下载 %s：%.2fGB/%s（断点保留）" % [
            active_name,float(bytes)/1000000000.0,("%.2fGB"% (float(total)/1000000000.0)) if total>0 else "等待大小"]
    if model_ready: return "本机 %s · %d tokens 已加载，可离线对话" % [active_name,context_tokens]
    if not ClassDB.class_exists("NobodyWhoChat"): return "%s：原生推理扩展未加载；请到反馈页复制错误。" % active_name
    if not last_error.is_empty(): return "%s：%s" % [active_name,last_error]
    if download_manager!=null and not model_source.begins_with("user://"):
        var cache_path:=download_manager.final_path(model_source)
        if FileAccess.file_exists(cache_path):
            return "%s 权重已保存在手机，尚未载入内存。点击【下载/加载】会复用本地文件，不会重新下载。" % active_name
        if download_manager.current_bytes(model_source)>0:
            return "%s 下载缓存已保留（%.2f GB），点击【下载/加载】从断点恢复。" % [active_name,float(download_manager.current_bytes(model_source))/1000000000.0]
    return "%s 未加载。选定后点击下载/加载，模型会缓存到手机。" % active_name

func _on_download_progress(state: Dictionary) -> void:
    download_progress.emit(state)

func _on_download_finished(result: Dictionary) -> void:
    if bool(result.get("ok",false)):
        var file_path:=str(result.get("path",""))
        if file_path.is_empty() or not FileAccess.file_exists(file_path):
            loading=false
            heartbeat.stop()
            last_error="下载已结束，但找不到模型文件。"
            status_changed.emit(last_error)
            return
        _load_native(file_path)
    elif bool(result.get("paused",false)):
        loading=false
        loading_weights=false
        heartbeat.stop()
        status_changed.emit("已暂停下载，缓存仍在本地，返回游戏或重启后可自动断点继续。")
    else:
        loading=false
        loading_weights=false
        heartbeat.stop()
        last_error=str(result.get("error","下载失败"))
        status_changed.emit(last_error)

func pause_download() -> void:
    if download_manager!=null and download_manager.active:
        download_manager.pause()

func resume_pending() -> void:
    if model_ready or busy: return
    if loading:
        # Android may resume on the same frame that the previous paused HTTP
        # coroutine is unwinding. Retry later instead of silently losing the
        # user's requested auto-resume.
        if download_manager!=null and download_manager.paused:
            call_deferred("_resume_after_pause")
        return
    if download_manager!=null and download_manager.is_pending(model_source):
        status_changed.emit("检测到上次未完成的GGUF下载，正在从磁盘已保存的断点继续。")
        load_model()

func _resume_after_pause() -> void:
    for i in range(4):
        if not loading: break
        await get_tree().create_timer(0.25).timeout
    if not loading:
        resume_pending()

func load_model() -> void:
    if model_ready or loading: return
    if not ClassDB.class_exists("NobodyWhoChat"):
        status_changed.emit("原生推理库没有加载成功，请用反馈页记录设备型号与版本。")
        return
    loading=true
    loading_weights=false
    load_started_ticks=Time.get_ticks_msec()
    heartbeat.start()
    last_error=""
    if model_source.begins_with("user://"):
        if not FileAccess.file_exists(model_source):
            loading=false
            heartbeat.stop()
            last_error="选择的本地GGUF文件不存在。"
            status_changed.emit(last_error)
            return
        _load_native(model_source)
        return
    status_changed.emit("开始下载 %s。实际百分比、速度和已保存字节数显示在主界面；失败会重试，保留断点。" % active_name)
    download_manager.begin(model_source)

func _load_native(local_path: String) -> void:
    loading_weights=true
    status_changed.emit("模型已在手机本地保存，正在加载 %s 权重并申请运行内存。" % active_name)
    # NobodyWho accepts Godot user:// paths; use the real filesystem path so
    # Android logs and native errors can be correlated with the exact cached file.
    var native_path:=ProjectSettings.globalize_path(local_path)
    var loaded = await ClassDB.class_call_static("NobodyWhoChat","create",native_path,{
        "n_ctx":context_tokens,"n_threads":3,"use_gpu":true,
        "context_shift":{"keep_first_turns":0,"keep_last_turns":3,"target":0.75},
        "template_variables":{"enable_thinking":false}
    })
    loading=false
    loading_weights=false
    heartbeat.stop()
    if loaded==null:
        model_ready=false
        var size_gb:=0.0
        var fd:=FileAccess.open(local_path,FileAccess.READ)
        if fd!=null: size_gb=float(fd.get_length())/1000000000.0
        last_error="模型已存盘（%.2f GB），但NobodyWho原生create返回空值；未执行重新下载。请复制Godot原生错误日志，并检查Vulkan、可用物理内存、上下文长度。可卸载后尝试4096 tokens或较小模型。" % size_gb
        status_changed.emit(last_error)
        return
    current_chat=loaded
    model_ready=true
    status_changed.emit("本机 %s 已加载完成。可离线对话，不需要API Key。" % active_name)


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
        var relationship := "妹妹" if person=="孙成明" else ("父亲" if person=="钱然泽" else ("母亲" if person=="郑舟清" else str(npc.get("relationship","同乡"))))
        var personality := "心直口快、爱帮家里干活，有自己的打算，不是永远等着哥哥说话。" if person=="孙成明" else ("朴实慎重，不喜欢空口许诺。" if person=="钱然泽" else "细心务实，惦念家中饭食。")
        if not person in ["孙成明","钱然泽","郑舟清"]:
            personality=str(npc.get("trait","普通人；有自主生活、意愿与职业责任"))
        var system_text := "你正在扮演独立人生修仙世界中的真实NPC%s，身份是玩家%s的%s。职业：%s。性格：%s。" % [person,nickname,relationship,str(npc.get("job","家务")),personality]
        system_text += "\n可信世界事实（优先级最高）：今天是第%d日 %02d:%02d。玩家位置：%s。你的当前位置：%s。你正在做：%s。你的情绪：%s。" % [current_day,int(time/60),time%60,scene,str(npc.get("place","未知")),str(npc.get("activity","家务")),str(npc.get("mood","平静"))]
        system_text += "\n约束：只扮演NPC，以一两句自然中文回答。每次要真正回应玩家最新问题和追问；不能答非所问、机械重复前一轮、虚构自己离开或正在路上。"
        system_text += "没有移动事件时不得宣称自己换了位置；你可以表达个人意愿和拒绝，但不能宣布获得物品、修炼突破、改变任何游戏数值。"
        system_text += "玩家问‘你在哪条路’时，必须基于登记位置解释，不能只重复‘我正在路上’。不要输出JSON或带‘旁白’的段落。"
        # Full archive stays on disk, semantic retrieval brings only relevant
        # long-term talk back into the narrow LLM context.
        var compact: Dictionary=state.get("memory_context",{})
        if not compact.is_empty():
            var anchor: Dictionary=compact.get("anchor",{})
            var baseline:=str(anchor.get("baseline",""))
            if not baseline.is_empty():
                system_text+="\n【不可被日常摘要覆盖的性格基线】"+baseline
            var stable_habits: Array=compact.get("habits",[])
            if not stable_habits.is_empty():
                system_text+="\n【多日行为证据支持的习惯】"+"；".join(stable_habits.slice(0,8))
            var daily_rollups: Array=compact.get("last_week",[])
            if not daily_rollups.is_empty():
                system_text+="\n【近期真实日常摘要】"+"；".join(daily_rollups.slice(-4))
            var pinned: Array=compact.get("important",[])
            var special: Array[String]=[]
            for i in range(maxi(0,pinned.size()-3),pinned.size()):
                var exact: Dictionary=pinned[i]
                special.append("第%d日：玩家说%s；你说%s" % [int(exact.get("day",0)),
                    str(exact.get("player","")).substr(0,65),str(exact.get("reply","")).substr(0,75)])
            if not special.is_empty():
                system_text+="\n【不可轻易否认的重要旧话】"+"；".join(special)
            var retrieved: Array=compact.get("recalled",[])
            var old_relevant: Array[String]=[]
            for past in retrieved.slice(0,8):
                if not (past is Dictionary): continue
                old_relevant.append("第%d日玩家说：%s；你答：%s" % [int(past.get("day",0)),
                    str(past.get("player","")).substr(0,90),str(past.get("reply","")).substr(0,110)])
            if not old_relevant.is_empty():
                system_text+="\n【从独立本地原始档案检索出的相关回忆，原文可追溯】\n"+"\n".join(old_relevant)
        # Compatibility fallback for older save versions without a sidecar:
        var stored: Dictionary=state.get("npc_memories",{})
        var memories: Array=stored.get(person,[])
        var latest_tokens: Array[String]=[]
        for i in range(maxi(0,cleaned_text.length()-1)):
            var token:=cleaned_text.substr(i,2)
            if not latest_tokens.has(token): latest_tokens.append(token)
        var ranked: Array=[]
        for i in range(memories.size()):
            var memory: Dictionary=memories[i]
            var phrase:=str(memory.get("player",""))+" "+str(memory.get("reply",""))
            var score:=0
            for token in latest_tokens:
                if phrase.contains(token): score+=1
            if score>0: ranked.append({"rank":score*10000+i,"item":memory})
        ranked.sort_custom(func(a,b): return int(a["rank"])>int(b["rank"]))
        var useful: Array[String]=[]
        for i in range(mini(4,ranked.size())):
            var old_memory: Dictionary=ranked[i]["item"]
            useful.append("第%d日 玩家曾说：%s；你当时答：%s" % [
                int(old_memory.get("day",0)),str(old_memory.get("player","")).substr(0,65),
                str(old_memory.get("reply","")).substr(0,85)])
        if compact.is_empty() and not useful.is_empty():
            system_text+="\n相关旧日交谈（仅为人物记忆，不是世界事实）：\n"+"\n".join(useful)
        messages.append({"role":"system","content":system_text})
        var all_dialogue: Array = state.get("dialogue_log",[])
        var scoped: Array = []
        for item in all_dialogue:
            if not (item is Dictionary): continue
            var entry: Dictionary = item
            if str(entry.get("speaker",""))==person:
                scoped.append(entry)
        # Keep the latest two exchanges in the active inference context.
        # The complete transcript and long-term retrieval remain on disk.
        for idx in range(maxi(0,scoped.size()-2),scoped.size()):
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

# Stop an excessively slow inference instead of leaving NPC conversation busy forever.
# Timeout fires even while next_token() is awaiting the native backend.
func _on_generation_timeout() -> void:
    if not busy or current_chat==null: return
    _generation_timed_out=true
    generation_cancelled=true
    status_changed.emit("本机AI本轮超过时间上限，正在停止原生推理；请改用1.7B/4B或检查GPU实际加速。")
    current_chat.stop_generation()

func _begin_generation(seconds: float) -> void:
    _generation_timed_out=false
    generation_cancelled=false
    _generation_watchdog.start(seconds)

func _end_generation() -> void:
    _generation_watchdog.stop()

# Render tokens incrementally without awaiting the same stream twice.
# Never save partially generated text; only a completed response can be committed.
func _collect_stream(stream: Variant, kind: String) -> Variant:
    var full: String=""
    var last_emit:=0
    var start_ms:=Time.get_ticks_msec()
    var first_token_ms:=-1
    var count:=0
    while true:
        var token: Variant=await stream.next_token()
        if token==null: break
        if generation_cancelled: return null
        if first_token_ms<0:
            first_token_ms=Time.get_ticks_msec()
            status_changed.emit("AI首字等待 %.1f 秒，正在逐字生成。" % [float(first_token_ms-start_ms)/1000.0])
        count+=1
        full+=str(token)
        var now:=Time.get_ticks_msec()
        if now-last_emit>=180:
            last_emit=now
            streaming.emit(kind,full.substr(maxi(0,full.length()-900)))
    if generation_cancelled: return null
    streaming.emit(kind,full.substr(maxi(0,full.length()-900)))
    var seconds:=maxf(0.001,float(Time.get_ticks_msec()-start_ms)/1000.0)
    status_changed.emit("本轮AI生成：%d token / %.1f秒（约 %.1f token/秒，含首字等待）。" % [count,seconds,float(count)/seconds])
    return full

# Story director proposes only observations and a named candidate plot beat.
# World.record_ai_story() is the sole authorization point.
func build_story_messages(player_action: String, resolved_event: String, facts: Dictionary) -> Array:
    var options: Array=facts.get("available_beats",[])
    var hooks: Array[String]=["none"]
    for beat in options:
        hooks.append(str(beat.get("id","")))
    var setup := "你是中国古风人生修仙文字游戏的世界叙事导演。"
    setup+="只输出一个JSON对象，包含scene字符串(35到180字)，beat_id字符串。"
    setup+="仅描写当前真实发生的动作、环境、人物自然反应、已知矛盾和伏笔；有因有果、富有仙侠气韵，不重复数值日志。"
    setup+="不得生成任何规则未结算的战利品、伤害、修为、灵根、财富、异地传送或NPC移动。"
    setup+="beat_id只能从以下名单选择："+", ".join(hooks)+"。没有自然衔接时使用none。"
    setup+="不要在scene中描写beat_id尚未被规则确认的效果；人物并非玩家的附庸，他们各有愿望。"
    var prompt := "已核算动作："+player_action.substr(0,180)
    prompt+="\n规则确定结果："+resolved_event.substr(0,340)
    prompt+="\n真实世界快照："+JSON.stringify(facts).substr(0,1300)
    prompt+="\n请给出简短剧情与最多一个伏笔。"
    return [{"role":"system","content":setup},{"role":"user","content":prompt}]

func tell_story(player_action: String, resolved_event: String, facts: Dictionary, expected_clock: int) -> void:
    if busy or not model_ready:
        answered.emit({"ok":false,"kind":"story","error":"本地模型正在忙或尚未加载。"})
        return
    busy=true
    _begin_generation(MAX_STORY_SECONDS)
    var messages:=build_story_messages(player_action,resolved_event,facts)
    var settings: Dictionary={"template_variables":{"enable_thinking":false}}
    if ClassDB.class_exists("NobodyWhoSamplerPresets"):
        settings["sampler"]=ClassDB.class_call_static("NobodyWhoSamplerPresets","temperature",0.65)
    var stream=current_chat.complete(messages,settings)
    if stream==null:
        _end_generation()
        busy=false
        answered.emit({"ok":false,"kind":"story","error":"剧情生成上下文创建失败。"})
        return
    var output: Variant=await _collect_stream(stream,"story")
    _end_generation()
    busy=false
    if output==null:
        answered.emit({"ok":false,"kind":"story","error":"本地AI剧情生成失败。"})
        return
    var raw:=str(output).strip_edges()
    var a:=raw.find("{")
    var b:=raw.rfind("}")
    if a<0 or b<=a:
        answered.emit({"ok":false,"kind":"story","error":"剧情模型未按约定输出JSON。"})
        return
    var payload: Variant=JSON.parse_string(raw.substr(a,b-a+1))
    if not (payload is Dictionary):
        answered.emit({"ok":false,"kind":"story","error":"剧情JSON解析失败。"})
        return
    var result: Dictionary=payload
    answered.emit({"ok":true,"kind":"story","scene":str(result.get("scene","")).substr(0,460),
        "beat_id":str(result.get("beat_id","none")).substr(0,45),
        "expected_clock":expected_clock,"origin":"local-gguf"})

func cancel_generation() -> void:
    if busy and current_chat!=null:
        generation_cancelled=true
        _end_generation()
        current_chat.stop_generation()

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
    if not person.is_empty() and not npc.is_empty() and not bool(npc.get("alive",true)):
        answered.emit({"ok":false,"error":"这位人物已故，只能查看生前档案，不能模拟当面交流。"})
        return
    if not person.is_empty() and (npc.is_empty() or str(npc.get("place",""))!=str(state.get("place",""))):
        answered.emit({"ok":false,"error":"NPC不在眼前。先走到对方所在地，不能远程生成当面对话。"})
        return
    busy=true
    _begin_generation(MAX_DIALOGUE_SECONDS)
    var messages := build_messages(text,person,state)
    # complete() replaces the native chat history, preventing NPC cross-talk and
    # keeping reliable turn-taking based on the persistent game save.
    var sampler_settings: Dictionary={"template_variables":{"enable_thinking":false}}
    if ClassDB.class_exists("NobodyWhoSamplerPresets"):
        sampler_settings["sampler"]=ClassDB.class_call_static("NobodyWhoSamplerPresets","temperature",0.72 if not person.is_empty() else 0.2)
    var stream = current_chat.complete(messages,sampler_settings)
    if stream==null:
        _end_generation()
        busy=false
        answered.emit({"ok":false,"error":"本地模型无法建立上下文，未写入人物记忆。"})
        return
    var output: Variant=await _collect_stream(stream,"dialogue" if not person.is_empty() else "action")
    if output==null:
        _end_generation()
        busy=false
        answered.emit({"ok":false,"error":"AI生成超时，已尝试停止本轮推理；建议使用4B/1.7B及4096上下文。" if _generation_timed_out else "模型生成失败，未写入对话。"})
        return
    var reply := str(output).strip_edges()
    if not person.is_empty() and _unusable_duplicate(reply,person,state,text):
        var retry: Array=messages.duplicate(true)
        retry.append({"role":"assistant","content":reply})
        retry.append({"role":"user","content":"你刚刚原样重复了上一轮答复。请具体回答我现在追问的内容，并且不得声称自己换了地方。"})
        var second_stream=current_chat.complete(retry,{})
        if second_stream!=null:
            var second: Variant=await _collect_stream(second_stream,"dialogue")
            if second!=null:
                reply=str(second).strip_edges()
    _end_generation()
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
