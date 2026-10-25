extends SceneTree
var failed := false

func _initialize() -> void:
    call_deferred("_run")

func _assert(ok: bool, label: String) -> void:
    if not ok:
        failed=true
        push_error("UI TEST FAILURE: "+label)

func _run() -> void:
    var scene=load("res://main.tscn")
    var ui=scene.instantiate()
    root.add_child(ui)
    _assert(ui.view=="剧情","default page is story")
    _assert(ui.input_row.visible,"free input visible")
    ui._change_tab("对话")
    _assert(ui.view=="对话","dialogue page")
    _assert(ui.scene_text.text.contains("还没有对话"),"dialogue independent from scene journal")
    ui._change_tab("人物")
    _assert(ui.actor_buttons.visible,"NPC listing is visible")
    _assert(ui.actor_buttons.get_child_count()>=4,"all family members listed")
    ui._open_npc("孙成明")
    _assert(ui.overlay.visible,"NPC dossier modal opens")
    _assert(ui.modal_info.text.contains("【身份】"),"NPC details in modal")
    _assert(ui.modal_actions.get_child_count()>=1,"NPC interactions in modal")
    ui._close_modal()
    _assert(not ui.overlay.visible,"modal closes")
    ui._change_tab("反馈")
    _assert(ui.feedback_copy.visible,"copyable feedback surface")
    _assert(not ui.input_row.visible,"input not crowding feedback")
    ui._change_tab("设置")
    ui._open_ai_settings()
    _assert(ui.modal_info.text.contains("密钥"),"secret handling disclosed in UI")
    _assert(ui.setting_provider.get_item_count()==3,"rule, API and local server settings exist")
    ui._close_modal()
    ui._change_tab("剧情")
    _assert(ui.input_row.visible,"free input restored")
    print("XIANFAN MOBILE UI TESTS PASS" if not failed else "XIANFAN MOBILE UI TESTS FAILED")
    quit(1 if failed else 0)
