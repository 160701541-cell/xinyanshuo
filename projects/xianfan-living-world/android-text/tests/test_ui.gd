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
    _assert(ui.reader_card.get_theme_stylebox("panel").bg_color.is_equal_approx(Color("#FBF8F1")),"parchment theme preserved")
    _assert(ui.stamina_bar.value==float(ui.game.data["stamina"]),"actual stamina bar reflects save")
    ui._change_tab("对话")
    _assert(ui.view=="对话","dialogue page")
    _assert(ui.scene_text.text.contains("请选择下方") or ui.scene_text.text.contains("请选择"),
        "dialogue page requires selection of an actually nearby person")
    ui._change_tab("人物")
    _assert(ui.actor_buttons.visible,"NPC listing is visible")
    _assert(ui.actor_buttons.get_child_count()>=2,"nearby people are visible without showing the entire county")
    _assert(ui.tab_buttons.get_child_count()==6,"six compact primary navigation entries")
    ui._open_npc("孙成明")
    _assert(ui.overlay.visible,"NPC dossier modal opens")
    _assert(ui.modal_info.text.contains("【身份】"),"compact NPC card identifies the person")
    _assert(not ui.modal_info.text.contains("【真实技能】"),"advanced attributes collapsed by default")
    _assert(ui.modal_actions.get_child_count()>=1,"NPC interactions in modal")
    ui._close_modal()
    _assert(not ui.overlay.visible,"modal closes")
    ui._change_tab("地图")
    _assert(ui.scene_text.text.contains("当前所在"),"existing locations have travel navigation")
    ui._change_tab("市集")
    _assert(ui.scene_text.text.contains("市集") or ui.scene_text.text.contains("当前"),"market separated from story")
    ui._change_tab("更多")
    _assert(ui.scene_text.text.contains("按需打开"),"secondary services not cramped in story")
    ui._change_tab("反馈")
    _assert(ui.feedback_copy.visible,"copyable feedback surface")
    _assert(not ui.input_row.visible,"input not crowding feedback")
    ui._change_tab("设置")
    ui._open_ai_settings()
    _assert(ui.modal_info.text.contains("密钥"),"secret handling disclosed in UI")
    _assert(ui.setting_provider.get_item_count()==4,"rule, API, local server and embedded GGUF model settings exist")
    _assert(ui.local_model_url!=null,"model download URL available in settings")
    _assert(ui.modal_actions.get_child_count()>=3,"real download button must exist")
    ui._close_modal()
    ui._change_tab("剧情")
    _assert(ui.input_row.visible,"free input restored")
    print("XIANFAN MOBILE UI TESTS PASS" if not failed else "XIANFAN MOBILE UI TESTS FAILED")
    quit(1 if failed else 0)
