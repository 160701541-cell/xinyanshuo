extends SceneTree
## Must prove real local model loaded, generated tokens, no HTTP backend.
## Runs on CI Linux with the same C++ GDExtension that is cross-built for Android.
const AI = preload("res://scripts/local_ai_service.gd")
var service: Node
var answered: bool = false
var failure: String = ""

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	assert(ClassDB.class_exists("CanglanLocalLLM"),
		"Missing REAL llama.cpp GDExtension; cannot claim on-device AI")
	service = AI.new()
	service.name = "LiveQwenOfflineAI"
	root.add_child(service)
	service.npc_reply.connect(func(code: String, answer: String) -> void:
		if code=="NPC-HX-00000001" and answer.strip_edges().length()>0:
			print("ACTUAL_LOCAL_AI_TOKEN_RESPONSE:",answer.substr(0,75))
			answered = true
	)
	service.inference_failed.connect(func(reason: String) -> void: failure=reason)
	var started: bool = false
	for counter in range(850):
		await create_timer(0.15).timeout
		var status: String = String(service.get("stage"))
		if status=="unavailable":
			printerr("OFFLINE_AI_QA_BLOCKED:",service.get("info"))
			quit(2)
			return
		if status=="ready" and not started:
			started = true
			var manifest: Dictionary = service.get("manifest")
			manifest["max_reply_tokens"]=24
			assert(bool(service.call("ask_npc","NPC-HX-00000001","农人",
				"你好，村里今天忙什么？",12.0,{"place":"苍岚河西"})),
				"Ready local model failed to receive NPC text")
		if not failure.is_empty():
			printerr("OFFLINE_AI_QA_BLOCKED:",failure)
			quit(3)
			return
		if answered:
			print("PASS NATIVE OFFLINE GGUF INFERENCE: model SHA-256 verified, real llama.cpp tokens, Chinese NPC prompt")
			service.queue_free()
			quit(0)
			return
		printerr("OFFLINE_AI_QA_BLOCKED: model not ready or no tokens in bounded time")
		quit(4)
