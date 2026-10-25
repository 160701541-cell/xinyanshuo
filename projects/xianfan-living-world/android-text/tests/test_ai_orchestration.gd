extends SceneTree
var failures: Array[String]=[]
func _initialize() -> void:
    call_deferred("_run")
func expect(ok: bool, label: String) -> void:
    if not ok:
        failures.append(label)
        push_error("AI ORCHESTRATION FAILURE: "+label)
func _run() -> void:
    var scene=load("res://main.tscn")
    var ui=scene.instantiate()
    root.add_child(ui)
    ui.game.new_game()
    ui._refresh()
    expect(ui._detect_npc_speech("问妹妹在哪里")=="孙成明","recognizes contextual NPC speech")
    expect(ui._detect_npc_speech("帮妹妹做饭")=="","work is an action, not NPC speech")
    expect(ui._detect_npc_speech("问母亲青云宗在哪")=="郑舟清","resolves family aliases")
    ui._change_tab("对话")
    ui._on_local_stream("dialogue","成明抬起头，正在想你问的事情。")
    expect(ui.scene_text.text.contains("正在回复"),"partial local AI reply shown before completion")
    expect(ui.scene_text.text.contains("成明抬起头"),"partial tokens visible in dialogue area")
    ui._change_tab("剧情")
    ui.local_enabled=true
    ui.local_llm.set("model_ready",true)
    ui.director_mode="关键事件"
    var current_time:=ui.game._clock()
    var current_place:=str(ui.game.data["place"])
    expect(ui._narration_needed(current_time-90,current_place,"家里忙了一整日"),"important elapsed world event can request story")
    expect(not ui._narration_needed(current_time,current_place,"查看四周"),"zero-cost observation avoids large 8B narrative pass")
    ui.director_mode="关闭"
    expect(not ui._narration_needed(current_time-90,current_place,"家务"),"player can disable AI story director")
    ui.local_llm.set("model_ready",false)
    ui.local_enabled=false
    var old_stamina:=int(ui.game.data["stamina"])
    var old_money:=int(ui.game.data["money"])
    var old_root:=str(ui.game.data["root"])
    ui._on_ai_completed({"ok":true,"kind":"story","scene":"窗外微风拂过庭院，成明停下手中细活，像是有话要说。","beat_id":"sister_choice","expected_clock":current_time,"origin":"local-gguf"})
    expect(ui.game.data.get("story_flags",{}).has("sister_choice"),"AI suggested beat passes authoritative rules")
    expect(ui.scene_text.text.contains("本地AI叙事"),"story shows independently of player dialogue")
    expect(ui.scene_text.text.contains("成明停下手中细活"),"accepted narration is visible")
    expect(int(ui.game.data["stamina"])==old_stamina,"narrator cannot change stamina")
    expect(int(ui.game.data["money"])==old_money,"narrator cannot change money")
    expect(str(ui.game.data["root"])==old_root,"narrator cannot reveal unknown root")
    var flags: Dictionary=ui.game.data.get("story_flags",{})
    var previous_count:=flags.size()
    ui._on_ai_completed({"ok":true,"kind":"story","scene":"屋檐的风铃轻轻颤响，远处传来一阵若有若无的鸟鸣。","beat_id":"sister_choice","expected_clock":ui.game._clock(),"origin":"local-gguf"})
    expect(ui.game.data.get("story_flags",{}).size()==previous_count,"plot beat cannot duplicate")
    print("XIANFAN AI ORCHESTRATION PASS" if failures.is_empty() else "XIANFAN AI ORCHESTRATION FAILED")
    quit(0 if failures.is_empty() else 1)
