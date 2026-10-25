extends SceneTree
func _initialize() -> void:
    call_deferred("_run")
func _run() -> void:
    var model = load("res://scripts/local_llm.gd").new()
    root.add_child(model)
    var state = {"day":29,"minute":368,"place":"石桥村·家中","name":"心魇说","npc":{"孙成明":{"place":"石桥村·家中","activity":"整理行囊","mood":"平静"},"钱然泽":{"place":"石桥村·田边","activity":"耕田","mood":"忙碌"}},"dialogue_log":[{"speaker":"孙成明","player":"在吗","reply":"我正在路上。"},{"speaker":"钱然泽","player":"吃饭了吗","reply":"我在田里。"}]}
    var msg: Array=model.build_messages("哪个路上","孙成明",state)
    var valid := msg.size()==4
    valid = valid and str(msg[0]["content"]).contains("石桥村·家中")
    valid = valid and str(msg[2]["content"])=="我正在路上。"
    valid = valid and str(msg[3]["content"])=="哪个路上"
    valid = valid and not JSON.stringify(msg).contains("我在田里")
    valid = valid and model._unusable_duplicate("我正在路上。","孙成明",state,"哪个路上")
    print("XIANFAN NPC CONTEXT PASS" if valid else "XIANFAN NPC CONTEXT FAIL")
    quit(0 if valid else 1)
