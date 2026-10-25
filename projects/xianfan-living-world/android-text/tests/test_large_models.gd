extends SceneTree
var issues: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _test(ok: bool, description: String) -> void:
    if not ok:
        issues.append(description)
        push_error("LARGE MODEL TEST: "+description)

func _run() -> void:
    var adapter = load("res://scripts/local_llm.gd").new()
    root.add_child(adapter)
    var count: int = XianfanLocalLLM.MODELS.size()
    _test(count >= 5,"0.6B/1.7B/4B/8B/14B preset catalog present")
    var names: Array[String] = []
    for i in range(count):
        var entry: Dictionary = XianfanLocalLLM.preset(i)
        names.append(str(entry["id"]))
        _test(str(entry["path"]).begins_with("hf://"),"preset source is Hugging Face path")
        _test(str(entry["path"]).ends_with(".gguf"),"preset is an individual GGUF file")
        _test(XianfanLocalLLM.preset_index(str(entry["path"]))==i,"preset round-trips")
        _test(float(entry["storage_gb"])>float(entry["size_gb"]),"storage guidance includes spare space")
        _test(XianfanLocalLLM.model_hint(i).contains("GB"),"size/RAM warning shown")
    _test(names==["0.6B","1.7B","4B","8B","14B"],"model tiers in ascending order")
    var bigger: Dictionary = XianfanLocalLLM.preset(3)
    var selected: String=adapter.choose_model(str(bigger["path"]))
    _test(selected.begins_with("已选择"),"8B selectable")
    _test(adapter.active_name=="8B","8B model name shown")
    _test(str(adapter.status()).contains("8B"),"selection appears in status")
    _test(not adapter.model_ready and not adapter.loading,"choosing model does not trigger download")
    adapter.model_ready=true
    _test(adapter.choose_model(str(XianfanLocalLLM.preset(2)["path"])).contains("卸载"),"cannot hot-swap loaded model")
    adapter.unload_model()
    _test(adapter.choose_model(str(XianfanLocalLLM.preset(4)["path"])).begins_with("已选择"),"14B can be explicitly selected")
    _test(adapter.active_name=="14B","14B current tier after switching")
    var scene=load("res://main.tscn").instantiate()
    root.add_child(scene)
    scene._open_ai_settings()
    scene.setting_provider.select(3)
    scene._sync_provider_fields()
    _test(scene.local_model_selector.item_count>=5,"real picker inside Android settings popup")
    scene._choose_local_preset(3)
    _test(scene.local_model_url.text==str(XianfanLocalLLM.preset(3)["path"]),"8B picker actually updates target download path")
    _test(scene.local_model_hint.text.contains("5.03"),"8B download size disclosed")
    var prev_loading: bool=bool(scene.local_llm.get("loading"))
    scene._enable_local_and_load()
    _test(scene.modal_title.text.contains("确认"),"high-risk large model requires confirmation")
    _test(bool(scene.local_llm.get("loading"))==prev_loading,"no 5GB download without explicit confirmation")
    _test(scene.pending_model_path==str(XianfanLocalLLM.preset(3)["path"]),"confirm dialog retains exact model selection")
    print("XIANFAN LARGE MODEL PICKER PASS" if issues.is_empty() else "XIANFAN LARGE MODEL PICKER FAILED")
    quit(0 if issues.is_empty() else 1)
