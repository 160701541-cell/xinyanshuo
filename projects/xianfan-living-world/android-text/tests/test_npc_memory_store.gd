extends SceneTree

var problems: Array[String]=[]
func _initialize() -> void:
    call_deferred("_run")
func expect(value: bool, why: String) -> void:
    if not value:
        problems.append(why)
        push_error("NPC SIDECAR TEST FAILURE: "+why)

func _run() -> void:
    var world:=XianfanWorld.new()
    world.new_game()
    var campaign:=str(world.data["memory_campaign"])
    var sister: Dictionary=world.data["npc"]["孙成明"]
    for i in range(143):
        var statement: String="第%d次聊旧事：村东的桥" % i
        var answer: String="我记得第%d次的桥边见闻。" % i
        if i==23:
            statement="我们约定明年在溪边看晚霞"
            answer="我答应，等活做完一起去。"
        world.record_ai_dialogue("孙成明",statement,answer,"local-gguf")
    var originals: Array=world.memory_store.read_all("孙成明")
    expect(originals.size()==143,"all 143 exact original speeches independently archived")
    expect(world.data.get("dialogue_archive",[]).size()<=120,"main save keeps bounded archive cache")
    expect(world.data.get("npc_memories",{}).get("孙成明",[]).size()<=96,"main save keeps bounded per-person cache")
    var hit: Array=world.memory_recall("孙成明","约定明年溪边晚霞",8)
    expect(hit.size()>0,"long-ago pinned important conversation searchable")
    if not hit.is_empty():
        expect(str(hit[0]["player"]).contains("约定"),"original quotation preserved")
    var memory: Dictionary=world.memory_digest("孙成明")
    expect(int(memory.get("total_raw",0))==143,"profile counters reflect exact log")
    var core_before: Dictionary=memory.get("anchor",{}).duplicate(true)
    expect(str(core_before.get("baseline","")).contains("自己"),"immutable character grounding present")
    for day in [30,31,32,33]:
        var fact={"day":day,"npc":"孙成明","place":"石桥村·家中",
            "activity":"整理柴草","mood":"平静","goal":"","turn":day}
        expect(world.memory_store.archive_life("孙成明",fact,sister),"life fact archived")
    var rolled: Dictionary=world.memory_digest("孙成明")
    expect(rolled.get("habits",[]).size()>0,"habit requires observations on at least three separate days")
    expect(str(rolled.get("habits",[])).contains("整理家事"),"repeated practice summarized accurately")
    expect(rolled.get("anchor",{})==core_before,"mundane compaction cannot rewrite personality core")
    var again: Array=world.memory_store.read_all("孙成明")
    expect(again.size()==147,"original records retained after rollup")
    var duplicate: Dictionary=again.back()
    expect(world.memory_store.append_event("孙成明",duplicate,sister),"idempotent replay succeeds")
    expect(world.memory_store.read_all("孙成明").size()==147,"replaying same UID does not duplicate history")
    var ctx: Dictionary=world.ai_context("孙成明","约定明年溪边晚霞")
    expect(ctx.has("memory_context"),"disk digest injected into model request")
    expect(ctx["memory_context"].get("recalled",[]).size()>0,"relevant old memory selected for context")
    var llm = load("res://scripts/local_llm.gd").new()
    root.add_child(llm)
    var prompts: Array=llm.build_messages("你记得我们约定看晚霞吗？","孙成明",ctx)
    var prompt_text:=JSON.stringify(prompts)
    expect(prompt_text.contains("人格") or prompt_text.contains("性格基线"),"stable persona always supplied")
    expect(prompt_text.contains("明年") or prompt_text.contains("晚霞"),"long-ago details still available past 80-turn limit")
    expect(prompt_text.contains("整理家事"),"repeated daily habits available to AI")
    expect(XianfanLocalLLM.CONTEXT_CHOICES.has(16384) and XianfanLocalLLM.CONTEXT_CHOICES.has(32768),"expanded context options")
    expect(str(llm.choose_context(16384)).contains("16384"),"16k context choice persisted")
    expect(int(llm.get("context_tokens"))==16384,"context changed for next load")
    llm.model_ready=true
    expect(str(llm.choose_context(32768)).contains("卸载"),"cannot change runtime context without model reload")
    llm.unload_model()
    expect(str(llm.choose_context(32768)).contains("32768"),"32k opt-in possible after unload")
    var reloaded:=XianfanWorld.new()
    expect(str(reloaded.data.get("memory_campaign",""))==campaign,"campaign ID stable across reload")
    expect(reloaded.memory_store.read_all("孙成明").size()==147,"independent raw memory survives restart")
    expect(reloaded.memory_digest("孙成明").get("anchor",{})==core_before,"persona baseline survives reload")
    if problems.is_empty(): print("XIANFAN NPC SIDECAR MEMORY TESTS PASS")
    else: print("XIANFAN NPC SIDECAR MEMORY TESTS FAILED "+str(problems))
    quit(0 if problems.is_empty() else 1)
