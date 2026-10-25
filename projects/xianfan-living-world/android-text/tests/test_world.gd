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
    var replay := XianfanWorld.new()
    _must(int(replay.data["money"]) == 53, "save reload")
    _must(replay.data["source_event"] == "EV000105", "save anchored to event 105")
    _must(replay.journal.size() >= 4, "persisted events")
    print("XIANFAN WORLD SMOKE TESTS PASS")
    quit(1 if failed else 0)