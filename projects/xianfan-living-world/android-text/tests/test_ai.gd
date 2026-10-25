extends SceneTree
var failed := false

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, msg: String) -> void:
    if not ok:
        failed=true
        push_error("AI TEST FAILURE: "+msg)

func _run() -> void:
    var ai:=XianfanAI.new()
    root.add_child(ai)
    ai.provider="关闭"
    var bad:=ai.configure("API","http://other.example/v1/chat/completions","model","SECRET_TEST_TOKEN")
    check(bad.contains("HTTPS"),"remote API requires TLS")
    check(ai.provider=="关闭","invalid config must not mutate provider")
    var ok:=ai.configure("API","https://api.example.invalid/v1/chat/completions","test-model","SECRET_TEST_TOKEN")
    check(ok.contains("已保存"),"accept configured secure API")
    check(ai.configured(),"secure API setup")
    check(ai.status()=="API已就绪","status display")
    var f:=FileAccess.open(XianfanAI.PREFS,FileAccess.READ)
    var disk: String=f.get_as_text() if f else ""
    check(not disk.contains("SECRET_TEST_TOKEN"),"do not persist credentials")
    check(disk.contains("test-model"),"save nonsecret model id")
    var manual:=ai.configure("本机服务","http://127.0.0.1:8080/v1/chat/completions","local-qwen","")
    check(manual.contains("已保存"),"local service address allowed")
    check(ai.api_key.is_empty(),"switching to local service clears key")
    check(ai.configured(),"local network service correctly configured")
    check(ai.configure("本机服务","http://remote.example:8080/v1/chat/completions","m","").contains("127.0.0.1"),"no unsafe remote masquerade")
    print("XIANFAN AI CONFIG TESTS PASS" if not failed else "XIANFAN AI CONFIG TESTS FAILED")
    quit(1 if failed else 0)
