extends Node
## REAL OFFLINE MODEL PATH ONLY. No remote inference, no pretending to have an AI.
## A single 0.6B model is shared by all NPCs; economy cannot be changed by text.
signal state_changed(stage: String, description: String)
signal npc_reply(entity_id: String, reply: String)
signal npc_intent(entity_id: String, intention: String)
signal inference_failed(message: String)

const MANIFEST_PATH := "res://local_ai/model_manifest.json"
const MODEL_RESOURCE := "res://models/Qwen3-0.6B.Q4_K_M.gguf"
const MODEL_INSTALLED := "user://local_models/Qwen3-0.6B.Q4_K_M.gguf"
var stage: String = "unavailable"
var info: String = "未加载"
var native: Node
var manifest: Dictionary = {}
var install_thread: Thread
var running_request_id: String = ""
var running_request_kind: String = ""
var dialogue_history: Dictionary = {}

func _ready() -> void:
	if not FileAccess.file_exists(MANIFEST_PATH):
		_update("unavailable","缺少公开的模型授权清单")
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if not (parsed is Dictionary):
		_update("unavailable","本地模型清单损坏")
		return
	manifest = parsed
	if not ClassDB.class_exists("CanglanLocalLLM"):
		_update("unavailable","当前APK未包含Android ARM64本地推理原生库；无法调用AI")
		return
	native = ClassDB.instantiate("CanglanLocalLLM")
	if native == null:
		_update("unavailable","llama.cpp原生类加载失败")
		return
	add_child(native)
	native.connect("model_ready",_on_model_ready)
	native.connect("model_error",_on_error)
	native.connect("reply_ready",_on_reply_ready)
	_update("checking","核验手机内已有的模型文件……")
	install_thread = Thread.new()
	var err: Error = install_thread.start(_install_or_verify.bind(String(manifest.get("sha256",""))))
	if err != OK:
		_update("unavailable","本地模型安装线程启动失败")

func _update(next: String, message: String) -> void:
	stage = next
	info = message
	state_changed.emit(next,message)

func _install_or_verify(expected_hash: String) -> Dictionary:
	# Worker thread does file IO only; never mutates scene tree.
	if expected_hash.length()!=64:
		return {"ok":false,"error":"模型SHA256不合法"}
	var dest: String = ProjectSettings.globalize_path(MODEL_INSTALLED)
	var root_dir: String = dest.get_base_dir()
	if DirAccess.make_dir_recursive_absolute(root_dir)!=OK:
		return {"ok":false,"error":"手机模型目录无法创建"}
	if FileAccess.file_exists(dest) and _hash_file(dest)==expected_hash:
		return {"ok":true,"file":dest}
	if not FileAccess.file_exists(MODEL_RESOURCE):
		return {"ok":false,"error":"APK中未内置GGUF模型（约484MB）；不允许假装离线AI已开启"}
	var reader := FileAccess.open(MODEL_RESOURCE,FileAccess.READ)
	if reader==null:
		return {"ok":false,"error":"APK里的GGUF模型无法读取"}
	var tmp: String = dest+".incomplete"
	var writer := FileAccess.open(tmp,FileAccess.WRITE)
	if writer==null:
		return {"ok":false,"error":"手机空间不足或无法写入GGUF"}
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	var moved: int = 0
	while not reader.eof_reached():
		var chunk: PackedByteArray = reader.get_buffer(2*1024*1024)
		if chunk.is_empty():
			break
		hash.update(chunk)
		writer.store_buffer(chunk)
		moved += chunk.size()
		if moved > 750*1024*1024 or writer.get_error()!=OK:
			writer.close()
			DirAccess.remove_absolute(tmp)
			return {"ok":false,"error":"模型包超限或手机存储不足"}
	writer.flush()
	writer.close()
	reader.close()
	if hash.finish().hex_encode()!=expected_hash:
		DirAccess.remove_absolute(tmp)
		return {"ok":false,"error":"本地模型校验失败，拒绝执行未验证GGUF"}
	if DirAccess.rename_absolute(tmp,dest)!=OK:
		DirAccess.remove_absolute(tmp)
		return {"ok":false,"error":"GGUF模型无法安装到应用目录"}
	return {"ok":true,"file":dest}

func _hash_file(path: String) -> String:
	var file := FileAccess.open(path,FileAccess.READ)
	if file==null:
		return ""
	var state_hash := HashingContext.new()
	state_hash.start(HashingContext.HASH_SHA256)
	while not file.eof_reached():
		var block := file.get_buffer(2*1024*1024)
		if block.is_empty():
			break
		state_hash.update(block)
	file.close()
	return state_hash.finish().hex_encode()

func _process(_delta: float) -> void:
	if install_thread!=null and not install_thread.is_alive():
		var result: Dictionary = install_thread.wait_to_finish()
		install_thread = null
		if not bool(result.get("ok",false)):
			_update("unavailable",String(result.get("error","模型校验失败")))
			return
		_update("loading","正在用手机CPU加载Qwen3 0.6B模型……")
		native.call("load_gguf",String(result["file"]),
			int(manifest.get("max_context_tokens",2048)),
			int(manifest.get("threads",3)))

func _on_model_ready() -> void:
	_update("ready","Qwen3 0.6B 已在本机离线加载，可与附近NPC对话")

func _on_error(message: String) -> void:
	running_request_id = ""
	running_request_kind = ""
	_update("ready" if native!=null and bool(native.call("model_loaded")) else "unavailable",
			"本地推理异常："+message)
	inference_failed.emit(message)

func _on_reply_ready(entity_code: String, reply: String) -> void:
	if entity_code != running_request_id:
		return
	var kind: String = running_request_kind
	running_request_id = ""
	running_request_kind = ""
	var safe: String = reply.strip_edges().substr(0,240)
	if safe.is_empty():
		inference_failed.emit("模型输出为空")
		return
	if kind=="intent":
		# This line is a PROPOSAL, never a command executed by this class.
		# WorldBox validates intent and decides if any real-world action is legal.
		npc_intent.emit(entity_code,safe)
		_update("ready","本地AI给出NPC意向；正在由世界规则核验")
		return
	if kind!="dialogue":
		inference_failed.emit("本地模型回复了未知请求类型")
		return
	if not dialogue_history.has(entity_code):
		dialogue_history[entity_code] = []
	var records: Array = dialogue_history[entity_code]
	records.append(safe)
	if records.size()>3:
		records.pop_front()
	_update("ready","AI离线运行中 · 已完成一轮对话")
	npc_reply.emit(entity_code,safe)

func ask_npc_intent(entity_id: String, profession: String,
		world_hour: float, facts: Dictionary) -> bool:
	# A shared 0.6B CPU model is throttled to one sequential near-player NPC.
	if stage!="ready" or native==null or running_request_id!="" or bool(native.call("inference_busy")):
		return false
	if entity_id.is_empty() or entity_id.length()>52 or profession.length()>35:
		return false
	var energy: int = clampi(int(facts.get("energy",70)),0,100)
	var hunger: int = clampi(int(facts.get("hunger",0)),0,100)
	var food: int = maxi(0,int(facts.get("food",0)))
	var ongoing: String = "有" if bool(facts.get("construction_pending",false)) else "无"
	var persona: String = ("你是苍岚世界独立居民%s，职业%s，当前%.0f时，精力%d，饥饿%d，村庄粮食%d，有施工项目%s。" %
		[entity_id,profession,world_hour,energy,hunger,food,ongoing])
	persona += "只决定本人下一步愿望，不允许虚构物品、建造或更改数字。只返回一行ACTION=选项；选项必须是eat,rest,inspect_stock,inspect_site,keep_working之一，且只能是其中一个。/no_think"
	running_request_id=entity_id
	running_request_kind="intent"
	_update("thinking","离线AI根据NPC真实需要思考选择……")
	native.call("request_reply",entity_id,persona,
		"从你的实际饥饿、精力、职业和工地进度选择一件合理的下一步行为。只返回ACTION=xxx。",
		48,true)
	return true

func ask_npc(entity_id: String, role_name: String, player_text: String,
		world_hour: float, world_facts: Dictionary) -> bool:
	if stage!="ready" or native==null or bool(native.call("inference_busy")):
		inference_failed.emit("模型尚未准备好或正在回答上一位居民")
		return false
	if entity_id.length()>52 or role_name.length()>35:
		return false
	var text: String = player_text.strip_edges().substr(0,120)
	if text.is_empty():
		return false
	var mood: String = "劳作中" if world_hour>6.0 and world_hour<19.0 else "夜间休息"
	var nearby: String = String(world_facts.get("place","苍岚旧街")).substr(0,25)
	var persona: String = ("你是架空修仙世界苍岚的普通居民，身份码%s，职业%s，时间%.0f时（%s），所在%s。"
		% [entity_id,role_name,world_hour,mood,nearby])
	persona += "你不知道无从获知的秘密，不能凭空赠送、交易或更改库存；只用简洁自然古风中文回答，最多两三句话。"
	if dialogue_history.has(entity_id):
		persona += "最近曾说过："+ "；".join(dialogue_history[entity_id])
	running_request_id = entity_id
	running_request_kind = "dialogue"
	_update("thinking","离线AI正在思考，其他NPC仍执行原作息……")
	native.call("request_reply",entity_id,persona,text,
		int(manifest.get("max_reply_tokens",96)))
	return true

func _exit_tree() -> void:
	if native!=null:
		native.call("cancel")
	if install_thread!=null:
		install_thread.wait_to_finish()
