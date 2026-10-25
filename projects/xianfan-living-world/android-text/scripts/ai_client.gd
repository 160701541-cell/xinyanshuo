extends Node
class_name XianfanAI

# Optional external provider. No model weights or private keys are bundled.
# A locally-running HTTP server can be selected, but that is NOT a packaged
# on-device LLM. In-app Android GGUF inference requires a native plugin.
signal completed(payload: Dictionary)

const PREFS := "user://xianfan_ai_settings.json"
var provider := "关闭"
var endpoint := "https://api.openai.com/v1/chat/completions"
var model := ""
var api_key := ""  # Memory-only: never written to disk, feedback or game save.
var busy := false
var request_node: HTTPRequest
var pending_text := ""
var pending_npc := ""

func _ready() -> void:
    request_node = HTTPRequest.new()
    request_node.timeout = 35.0
    add_child(request_node)
    request_node.request_completed.connect(_finished)
    load_prefs()

func load_prefs() -> void:
    if not FileAccess.file_exists(PREFS): return
    var file := FileAccess.open(PREFS,FileAccess.READ)
    if file == null: return
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if not (parsed is Dictionary): return
    var p: Dictionary = parsed
    var kind := str(p.get("provider","关闭"))
    if kind in ["关闭","API","本机服务"]: provider=kind
    var url := str(p.get("endpoint",""))
    if not url.is_empty(): endpoint=url
    model=str(p.get("model",""))

func configure(kind: String, url: String, selected_model: String, secret: String) -> String:
    if not kind in ["关闭","API","本机服务"]: return "服务类型不可识别。"
    var address := url.strip_edges()
    if kind=="API" and not address.begins_with("https://"):
        return "外部API只允许HTTPS，防止密钥明文传输。"
    if kind=="本机服务" and not (address.begins_with("http://127.0.0.1:") or address.begins_with("http://localhost:")):
        return "本机服务仅支持127.0.0.1或localhost，不等于内置模型。"
    if address.length()>280 or selected_model.length()>100: return "地址或模型名过长。"
    provider=kind
    if not address.is_empty(): endpoint=address
    model=selected_model.strip_edges()
    api_key=secret.strip_edges() if kind=="API" else ""
    var file := FileAccess.open(PREFS,FileAccess.WRITE)
    if file!=null:
        file.store_string(JSON.stringify({"provider":provider,"endpoint":endpoint,"model":model}))
    return "已保存服务地址与模型名称。密钥仅保存在本次应用运行的内存中。"

func configured() -> bool:
    if provider=="关闭": return false
    if model.is_empty() or endpoint.is_empty(): return false
    if provider=="API" and api_key.is_empty(): return false
    return true

func status() -> String:
    if provider=="关闭": return "纯规则模式（无AI调用）"
    if provider=="API":
        return "API已就绪" if configured() else "API尚未配置密钥或模型"
    return "本机HTTP服务已设置（需另有推理程序正在运行）" if configured() else "本机HTTP服务未配置"

func ask(action_text: String, state: Dictionary, dialogue_target: String="") -> bool:
    if busy:
        completed.emit.call_deferred({"ok":false,"error":"上一条AI请求还没结束，可取消或稍后重试。"})
        return false
    if not configured():
        completed.emit.call_deferred({"ok":false,"error":"请先在设置中配置API或本机推理服务。"})
        return false
    if not dialogue_target.is_empty():
        var nearby: Dictionary=state.get("npc",{}).get(dialogue_target,{})
        if nearby.is_empty() or str(nearby.get("place",""))!=str(state.get("place","")):
            completed.emit.call_deferred({"ok":false,"error":"NPC不在面前，不能远程生成对话。","raw":action_text})
            return false
    # Small, explicit context, with no API key, save-file path, or full conversation history.
    var visible: Array[String] = []
    for key in ["孙成明","钱然泽","郑舟清"]:
        var n: Dictionary=state.get("npc",{}).get(key,{})
        if str(n.get("place",""))==str(state.get("place","")): visible.append(key)
    var system_prompt := "你是中文文字人生游戏的意图解析器。只输出一个JSON对象，不能用Markdown。" +         "规则世界中的时间、财产、地点、灵根和NPC意志均不可擅自更改。" +         "kind只能是action、dialogue、clarify。action需command字符串，例：去林缘、捡枯枝、钓鱼、等30分钟、打扫院子、问妹妹吃饭了吗、出发去青云、查看四周。" +         "dialogue只允许在场NPC，在npc字段中给出真实名字，并在reply中写简短自然口语（最多150字）；不得宣称已取得物品、突破或移动。" +         "任何不支持的操作必须输出kind=clarify，并在message中解释缺乏哪个世界规则，不能虚构成功。"
    var context := {
        "location": str(state.get("place","未知")),
        "day":int(state.get("day",0)),
        "minute":int(state.get("minute",0)),
        "money":int(state.get("money",0)),
        "stamina":int(state.get("stamina",0)),
        "inventory":state.get("items",{}),
        "npc_here":visible,
        "cultivation":"未检测灵根；《引气初篇》已证实伪诀，不得突破"
    }
    var system_text := system_prompt
    if not dialogue_target.is_empty():
        var npc: Dictionary=state.get("npc",{}).get(dialogue_target,{})
        system_text="你扮演中国古风生活文字游戏中名叫"+dialogue_target+"的真实人物。" + \
            "请用简短自然中文直接回应玩家，最多120字，不输出JSON，不要旁白，不重复固定台词。" + \
            "当前正在做："+str(npc.get("activity","家务"))+"；情绪："+str(npc.get("mood","平静"))+"。" + \
            "不能决定世界数值、NPC行动是否成功、物品、灵根、修为或改变任何角色状态。" + \
            "如不知道的问题请坦诚说不清楚。"
    var messages: Array=[{"role":"system","content":system_text}]
    if not dialogue_target.is_empty():
        # The API also gets a bounded, NPC-scoped exchange history.
        # Past speech is replayed as dialogue, never as authoritative world facts.
        messages[0]["content"]=system_text+"\n可信地点："+str(state.get("place","未知"))+"；NPC当前地点："+str(state.get("npc",{}).get(dialogue_target,{}).get("place","未知"))+"。不要虚构移动，不要重复前一条回复。"
        var history: Array=state.get("dialogue_log",[])
        var relevant: Array=[]
        for entry in history:
            if entry is Dictionary and str(entry.get("speaker",""))==dialogue_target:
                relevant.append(entry)
        for i in range(maxi(0,relevant.size()-4),relevant.size()):
            var old: Dictionary=relevant[i]
            messages.append({"role":"user","content":str(old.get("player","")).substr(0,170)})
            messages.append({"role":"assistant","content":str(old.get("reply","")).substr(0,170)})
        var clean:=action_text.strip_edges()
        for prefix in ["跟"+dialogue_target+"说：","跟"+dialogue_target+"说:"]:
            if clean.begins_with(prefix):
                clean=clean.trim_prefix(prefix).strip_edges()
                break
        messages.append({"role":"user","content":clean.substr(0,300)})
    else:
        messages.append({"role":"user","content":"世界事实："+JSON.stringify(context)+"\n玩家说："+action_text.substr(0,350)})
    var payload := {"model":model,"messages":messages,"temperature":0.65 if not dialogue_target.is_empty() else 0.25,"max_tokens":260}
    var headers := PackedStringArray(["Content-Type: application/json"])
    if provider=="API": headers.append("Authorization: Bearer "+api_key)
    pending_text=action_text
    pending_npc=dialogue_target
    var err := request_node.request(endpoint,headers,HTTPClient.METHOD_POST,JSON.stringify(payload))
    if err!=OK:
        pending_text=""
        pending_npc=""
        completed.emit.call_deferred({"ok":false,"error":"无法启动HTTP请求，错误代码%d" % int(err)})
        return false
    busy=true
    return true

func cancel() -> void:
    if not busy: return
    request_node.cancel_request()
    busy=false
    pending_text=""
    pending_npc=""
    completed.emit({"ok":false,"error":"用户取消了AI请求。"})

func _finished(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    if not busy: return
    busy=false
    var raw := pending_text
    var npc := pending_npc
    pending_text=""
    pending_npc=""
    if result!=HTTPRequest.RESULT_SUCCESS:
        completed.emit({"ok":false,"error":"网络请求失败（代码%d），检查网络、服务地址或本机服务是否启动。" % result,"raw":raw})
        return
    if code<200 or code>=300:
        completed.emit({"ok":false,"error":"API返回HTTP %d；检查余额、模型名称和密钥。" % code,"raw":raw})
        return
    var response: Variant=JSON.parse_string(body.get_string_from_utf8())
    if not (response is Dictionary):
        completed.emit({"ok":false,"error":"API返回了非JSON响应。","raw":raw})
        return
    var choices: Array=response.get("choices",[])
    if choices.is_empty() or not (choices[0] is Dictionary):
        completed.emit({"ok":false,"error":"API响应缺少choices。","raw":raw})
        return
    var msg: Dictionary=choices[0].get("message",{})
    var message := str(msg.get("content","")).strip_edges()
    if not npc.is_empty():
        if message.is_empty():
            completed.emit({"ok":false,"error":"API未返回NPC发言。","raw":raw})
        else:
            completed.emit({"ok":true,"kind":"dialogue","npc":npc,"reply":message.substr(0,300),"raw":raw})
        return
    if message.begins_with("```"):
        message=message.replace("```json","").replace("```","").strip_edges()
    var start := message.find("{")
    var end := message.rfind("}")
    if start<0 or end<start:
        completed.emit({"ok":false,"error":"模型没有按约定返回动作JSON。","raw":raw})
        return
    var parsed: Variant=JSON.parse_string(message.substr(start,end-start+1))
    if not (parsed is Dictionary):
        completed.emit({"ok":false,"error":"模型返回的动作JSON无法解析。","raw":raw})
        return
    var out: Dictionary=parsed
    var kind := str(out.get("kind",""))
    if not kind in ["action","dialogue","clarify"]:
        completed.emit({"ok":false,"error":"模型意图类型不合法，未执行任何动作。","raw":raw})
        return
    completed.emit({"ok":true,"kind":kind,"command":str(out.get("command","")).substr(0,200),
        "npc":str(out.get("npc","")).substr(0,30),"reply":str(out.get("reply","")).substr(0,300),
        "message":str(out.get("message","")).substr(0,300),"raw":raw})
