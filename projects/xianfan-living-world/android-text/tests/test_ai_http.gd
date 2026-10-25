extends SceneTree
var failed := false
func _initialize() -> void: call_deferred("_run")
func check(cond: bool, label: String) -> void:
    if not cond:
        failed=true
        push_error("AI REQUEST TEST FAIL: "+label)
func _run() -> void:
    var node:=XianfanAI.new()
    root.add_child(node)
    var accepted=node.configure("本机服务","http://127.0.0.1:19180/v1/chat/completions","demo-local","")
    check(accepted.contains("已保存"),"local test provider configured")
    var st={"place":"石桥村·家中","day":29,"minute":360,"money":53,"stamina":100,"items":{},"npc":{"孙成明":{"place":"石桥村·家中","activity":"打扫","mood":"平静"}}}
    check(node.ask("今天在忙什么？",st,"孙成明"),"NPC request started")
    var reply: Dictionary=await node.completed
    check(reply.get("ok",false),"NPC HTTP response success")
    check(reply.get("kind","")=="dialogue","NPC natural reply kind")
    check(str(reply.get("reply","")).contains("扫院子"),"NPC natural response visible")
    check(node.ask("打扫院子",st), "action HTTP request started")
    var action: Dictionary=await node.completed
    check(action.get("ok",false),"action HTTP request success")
    check(action.get("kind","")=="action","action JSON parsing")
    check(action.get("command","")=="打扫院子","command extracted")
    print("XIANFAN LOOPBACK AI REQUESTS PASS" if not failed else "XIANFAN LOOPBACK AI REQUESTS FAILED")
    quit(1 if failed else 0)
