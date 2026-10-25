extends Node
class_name XianfanLocalLLM
# NobodyWho v12.1.0 native Godot GDExtension, Android ARM64.
# Model downloaded only after an explicit button press, never at startup.
signal status_changed(message: String)
signal answered(payload: Dictionary)
const MODEL := "hf://NobodyWho/Qwen_Qwen3-0.6B-GGUF/Qwen_Qwen3-0.6B-Q4_K_M.gguf"
var ready := false
var loading := false
var busy := false
var current_chat: Variant

func status() -> String:
    if loading: return "模型下载或加载中（约数百MB；请使用稳定Wi-Fi）"
    if ready: return "Qwen3-0.6B 本地模型已加载，可离线对话"
    if not ClassDB.class_exists("NobodyWhoChat"): return "缺少原生 NobodyWho GDExtension；此APK无法运行本地模型"
    return "本地模型未加载，须用户手动确认下载"

func load_model() -> void:
    if ready or loading: return
    if not ClassDB.class_exists("NobodyWhoChat"):
        status_changed.emit("原生推理库没有加载成功，请用反馈页记录设备型号与版本。")
        return
    loading=true
    status_changed.emit("开始下载/打开 Qwen3 0.6B Q4 模型。首次需要稳定网络和足够手机空间。")
    # The native plugin downloads the model and caches it. It runs CPU-based
    # inference on device; no remote Chat Completions server or API key is used.
    var loaded = await NobodyWhoChat.create(MODEL, {})
    loading=false
    if loaded==null:
        ready=false
        status_changed.emit("本地模型下载或加载失败。请查看网络、储存空间及插件错误信息。")
        return
    current_chat=loaded
    ready=true
    status_changed.emit("本地模型已加载，断网后可继续交谈。")

func talk(text: String, person: String, state: Dictionary) -> void:
    if busy:
        answered.emit({"ok":false,"error":"上一轮模型生成尚未结束。"})
        return
    if not ready:
        answered.emit({"ok":false,"error":"未下载并加载本地模型。请先在设置里点击下载。"})
        return
    var npc: Dictionary=state.get("npc",{}).get(person,{})
    if not person.is_empty() and (npc.is_empty() or str(npc.get("place",""))!=str(state.get("place",""))):
        answered.emit({"ok":false,"error":"NPC不在身边，不能进行当面对话。"})
        return
    busy=true
    var prompt := ""
    if not person.is_empty():
        prompt = "你正扮演古风生活游戏里的%s。现在正%s，情绪%s。" % [person,str(npc.get("activity","忙碌")),str(npc.get("mood","平静"))]
        prompt += "\n只能扮演NPC，回复简短自然的中文口语。不能凭空修改游戏地点、物品、亲密值、灵根或修为。\n玩家刚才说："+text.substr(0,250)+"\nNPC回应："
    else:
        prompt="你是古风文字游戏的行为解释器。只回复一个JSON对象，形如{\"kind\":\"action\",\"command\":\"去林缘\"}，无法执行时回复{\"kind\":\"clarify\",\"message\":\"尚未开发的动作\"}。"
        prompt+="\n不能创造钱、装备、人物属性或者突破。已支持行动：查看四周、去林缘、捡枯枝、采车前草、钓鱼、出发去青云、等30分钟、回家、打扫院子、睡觉。"
        prompt+="\n地点："+str(state.get("place","未知"))+" 玩家要求："+text.substr(0,250)+"\nJSON："
    var stream=current_chat.ask(prompt)
    var result=await stream.completed()
    busy=false
    var reply := str(result).strip_edges()
    if result==null or reply.is_empty():
        answered.emit({"ok":false,"error":"原生本地模型没有返回可用回复。"})
        return
    if not person.is_empty():
        answered.emit({"ok":true,"kind":"dialogue","npc":person,"reply":reply.substr(0,300),"raw":text})
        return
    var a:=reply.find("{")
    var b:=reply.rfind("}")
    if a<0 or b<a:
        answered.emit({"ok":true,"kind":"clarify","message":"本地模型无法转换这项行动；请改用具体文字指令。","raw":text})
        return
    var parsed: Variant=JSON.parse_string(reply.substr(a,b-a+1))
    if not (parsed is Dictionary):
        answered.emit({"ok":true,"kind":"clarify","message":"动作解析格式不正确，请换种说法。","raw":text})
        return
    var result: Dictionary=parsed
    if str(result.get("kind",""))=="action":
        answered.emit({"ok":true,"kind":"action","command":str(result.get("command","")).substr(0,200),"raw":text})
    else:
        answered.emit({"ok":true,"kind":"clarify","message":str(result.get("message","无法解析动作")).substr(0,200),"raw":text})
