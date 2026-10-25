extends SceneTree
var errors: Array[String]=[]
func _initialize() -> void:
    call_deferred("_go")
func _go() -> void:
    if not ClassDB.class_exists("NobodyWhoChat"):
        errors.append("Native NobodyWhoChat class not registered for this platform")
    var root_node:=XianfanLocalLLM.new()
    root.add_child(root_node)
    if root_node.model_ready or root_node.loading:
        errors.append("Local model must not download or load without an explicit click")
    if not root_node.status().contains("未加载") and not root_node.status().contains("缺少"):
        errors.append("Runtime status must disclose model absence before download")
    if not errors.is_empty():
        for e in errors: push_error("NATIVE LLM TEST FAILURE "+e)
        quit(1)
    else:
        print("XIANFAN NATIVE LLM PLUGIN PRESENT; MODEL DOWNLOAD/INFERENCE NOT RUN IN CI")
        quit(0)
