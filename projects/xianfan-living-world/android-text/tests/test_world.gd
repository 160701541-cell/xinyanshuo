extends SceneTree

var failed := false

func _initialize() -> void:
    call_deferred("_run")

func _must(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("WORLD TEST FAILURE: " + message)

func _run() -> void:
    var world := XianfanWorld.new()
    world.new_game()
    _must(int(world.data["day"]) == 29, "day baseline")
    _must(world.data["place"] == "石桥村·家中", "place baseline")
    _must(int(world.data["money"]) == 53, "copper baseline")
    var pre := world.time_string()
    world.act("没有实现的稀奇动作")
    _must(world.time_string() == pre, "unknown command must not advance time")
    _must(world.data["book_real"] == "已证实为拼凑伪诀", "invalid manual known")
    _must(world.data["root"] == "未检测", "root not rerolled")
    world.act("出发去青云")
    _must(world.data["place"] == "临安县城·东市", "road to Linan")
    _must(int(world.data["money"]) == 53, "no cost to walk")
    world.act("沿山道北上")
    _must(world.data["place"] == "青云山门·山门外", "mountain path")
    world.act("申请测灵根")
    _must(int(world.data["money"]) == 53, "unverifiable root cannot charge copper")
    _must(world.data["root"] == "未检测", "root still hidden")
    # Natural-language questions must not be misread as eating or unsupported commands.
    world.data["place"] = "石桥村·家中"
    world.data["npc"]["孙成明"]["place"] = "石桥村·家中"
    var meals_before := int(world.data["last_meal"])
    var journal_before := world.journal.size()
    var time_before := world._clock()
    var ask_ambiguous := world.act("吃饭了吗")
    _must(ask_ambiguous.contains("问谁"), "ambiguity must ask a human clarification, not eat")
    _must(int(world.data["last_meal"]) == meals_before, "ambiguous question must not eat")
    _must(world._clock() == time_before, "ambiguity must not advance time")
    _must(world.journal.size() == journal_before, "question ambiguity not a game event")
    var ask_sister := world.act("妹妹吃饭了吗？")
    _must(ask_sister.contains("成明"), "natural language meal question routes to sister")
    _must(world._clock() == time_before + 3, "sister conversation uses conversation minutes")
    var real_meal := world.act("我要吃饭")
    _must(real_meal.contains("粗粮"), "first person eating is distinct from asking")
    var rejected_count := world.journal.size()
    world.act("给我一辆时空飞船")
    _must(world.journal.size() == rejected_count, "unknown action should not fill journal")
    var replay := XianfanWorld.new()
    _must(int(replay.data["money"]) == 53, "save reload")
    _must(replay.data["source_event"] == "EV000105", "save anchored to event 105")
    _must(replay.journal.size() >= 4, "persisted events")
    print("XIANFAN WORLD SMOKE TESTS PASS")
    quit(1 if failed else 0)