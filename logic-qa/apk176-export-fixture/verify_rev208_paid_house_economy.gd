extends SceneTree
# Original Godot4.4.1, one physical stock inventory shared with construction.
# No test-only grant of wood/stone is allowed; create and exhaust 40
# real 5-wood trees + 15 real 10-stone natural-node records using SAME
# actual gather-to-actor/depot-delivery methods as the running game.
func _fail(why: String) -> void:
  push_error("FAIL_REV208_PAID_HOUSE_TEST "+why)
  quit(4)

func _initialize() -> void:
  call_deferred("_run")

func _run() -> void:
  var Economy: GDScript=load("res://canglan_rev187/worldbox_life_sim.gd") as GDScript
  var Building: GDScript=load("res://canglan_rev187/paid_housing.gd") as GDScript
  if Economy==null or Building==null:
    _fail("MISSING_AUTHENTIC_ORIGINAL_ECONOMY_OR_HOUSING")
    return
  var sim: RefCounted=Economy.new()
  sim.call("start",20261018)
  if not sim.call("create_village","CL-QA-VILLAGE",{
      "wood":0,"stone":0,"food":40}):
    _fail("COULD_NOT_START_GENUINE_FINITE_ECONOMY")
    return
  if not sim.call("add_citizen","CL-QA-WORKER","CL-QA-VILLAGE","woodcutter",28):
    _fail("NO_ACTUAL_CITIZEN_TO_HARVEST")
    return
  var ledger: RefCounted=Building.new()
  if not ledger.call("initialize"):
    _fail("PERSISTENT_HOUSE_PLAN_LOAD_INVALID")
    return
  var house: String="CL-HOME-V206-001"
  var empty: Dictionary=ledger.call("quote",house,
    sim.get("villages")["CL-QA-VILLAGE"]["stock"])
  if int(empty.get("need_wood",0))!=200 or int(
      empty.get("need_stone",0))!=150 or bool(
      empty.get("completed",true)):
    _fail("FREE_PREFAB_OR_WRONG_HOUSE_MATERIALS")
    return
  var denied: Dictionary=ledger.call(
    "try_fund",house,sim,"CL-QA-VILLAGE")
  if bool(denied.get("ok",false)):
    _fail("FREE_HOUSE_WITHOUT_SPENDING_200_WOOD_150_STONE")
    return
  var total_tree_sources: int=40
  var total_rock_sources: int=15
  for i in range(total_tree_sources):
    if not sim.call("register_natural_node",
        "CL-5WOOD-TREE-%03d"%i,"CL-QA-VILLAGE","tree",5):
      _fail("5_WOOD_TREE_NOT_RECOGNIZED")
      return
  for i in range(total_rock_sources):
    if not sim.call("register_natural_node",
        "CL-10STONE-ROCK-%03d"%i,"CL-QA-VILLAGE","stone",10):
      _fail("10_STONE_ROCK_NOT_RECOGNIZED")
      return
  for id in sim.get("natural_nodes").keys():
    while int(sim.get("natural_nodes")[id]["remaining"])>0:
      sim.get("citizens")["CL-QA-WORKER"]["energy"]=100
      if not sim.call("gather_to_actor","CL-QA-WORKER",String(id)):
        _fail("WORLD_SOURCE_NODE_FAILED_TO_YIELD_FINITE_STOCK")
        return
      if not sim.call("deliver_carried","CL-QA-WORKER"):
        _fail("MATERIALS_TELEPORTED_INSTEAD_OF_REAL_TRANSPORT")
        return
  var stock: Dictionary=sim.get("villages")["CL-QA-VILLAGE"]["stock"]
  if int(stock["wood"])!=200 or int(stock["stone"])!=150:
    _fail("TREE5_STONE10_X40_X15_MUST_EQUAL_PRECISE_COST_"+str(stock))
    return
  var paid: Dictionary=ledger.call("try_fund",house,sim,"CL-QA-VILLAGE")
  if not bool(paid.get("ok",false)) or int(
      paid.get("spent_wood",0))!=200 or int(
      paid.get("spent_stone",0))!=150 or int(stock["wood"])!=0 or (
      int(stock["stone"])!=0):
    _fail("NOT_EXACT_ATOMIC_MATERIAL_DEBIT_"+str(paid))
    return
  if bool(ledger.get("sites")[house]["completed"]):
    _fail("SOURCE_GLB_APPEARED_FULLY_BUILT_INSTANTLY")
    return
  for hour in range(7):
    if not (ledger.call("advance_one_world_hour",1) as Array).is_empty():
      _fail("SOURCE_GLB_COMPLETED_BEFORE_EIGHT_REAL_WORK_HOURS")
      return
  if bool(ledger.get("sites")[house]["completed"]):
    _fail("HOUSE_COMPLETED_WITHOUT_LAST_REQUIRED_WORLD_HOUR")
    return
  var ready: Array=ledger.call("advance_one_world_hour",1)
  if ready!=[house] or not bool(ledger.get("sites")[house]["completed"]):
    _fail("EIGHT_HOUR_WORKER_SHIFTS_DID_NOT_FINISH_FUNDED_PREFAB")
    return
  for n in range(5):
    if not ledger.call("allocate_bed",house,"CL-HOUSE-RESIDENT-%d"%n):
      _fail("PAID_HOUSE_CANNOT_SLEEP_FIVE_RESIDENTS")
      return
  if ledger.call("allocate_bed",house,"CL-SIXTH-RESIDENT"):
    _fail("FIVE_PERSON_HOUSE_ALLOWING_SIXTH_OCCUPANT")
    return
  var second: RefCounted=Building.new()
  if not second.call("initialize") or not bool(
      second.get("sites")[house]["paid"]) or not bool(
      second.get("sites")[house]["completed"]) or int(
      second.call("stats").get("assigned_residents",0))!=5:
    _fail("REAL_BUILDING_AND_FIVE_BEDS_NOT_PERSISTED")
    return
  var repeat: Dictionary=second.call(
    "try_fund",house,sim,"CL-QA-VILLAGE")
  if bool(repeat.get("ok",false)):
    _fail("DUPLICATE_FREE_SAME_HOUSE_ON_ALREADY_FUNDED_BLUEPRINT")
    return
  print("PASS_REV208_40_REAL_5_WOOD_TREES_15_REAL_10_STONE_PILES_PAY_200_150_AND_EIGHT_WORK_HOURS")
  print("PASS_REV208_NO_FREE_LICENSED_GLB_HOUSES_FIVE_BED_CAPACITY_FOURTH_PERSON_SAVE_AND_ATOMIC_DEBIT")
  quit(0)
