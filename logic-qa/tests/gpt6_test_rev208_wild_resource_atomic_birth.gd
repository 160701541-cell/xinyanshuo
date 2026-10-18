extends SceneTree
## Independent Godot 4.4.1 real execution regression: no UI, GLB, screenshots.
## DSH owns graphics/UI; this verifies only GPT-6's isolated resource ID
## transaction fix against the actual game spawner script.
const Spawner = preload("res://wild_tree_stone_birth_rev208.gd")

class MockEconomy:
  extends RefCounted
  var natural_nodes: Dictionary={}
  var resource_positions: Dictionary={}
  var existing_stock: Dictionary={"wood":4,"stone":5}
  var reject_recovery: bool=false

  func register_natural_node(id: String,village: String,kind: String,
      qty: int) -> bool:
    if natural_nodes.has(id) or qty<1 or village!="CL-REV186-HX-VILLAGE":
      return false
    natural_nodes[id]={"id":id,"kind":kind,"capacity":qty,
      "remaining":qty,"depleted":false,"next_regen_hour":-1}
    return true

  func register_resource_position(id: String,at: Vector3) -> bool:
    if not natural_nodes.has(id) or resource_positions.has(id):
      return false
    resource_positions[id]=at
    return true

  func configure_resource_recovery(id: String,capacity: int,units: int,
      interval: int,delay: int) -> bool:
    if reject_recovery or not natural_nodes.has(id):
      return false
    var row: Dictionary=natural_nodes[id]
    row["capacity"]=capacity
    row["regen_units"]=units
    row["regen_hours"]=interval
    row["recovery_hours"]=delay
    row["next_regen_hour"]=-1
    return true

class MockEcology:
  extends RefCounted
  var trees: Dictionary={}
  var stone: Dictionary={}
  var economy: MockEconomy

  func register_tree(id: String) -> bool:
    if trees.has(id) or not economy.natural_nodes.has(id):
      return false
    trees[id]={"id":id,"position":economy.resource_positions[id]}
    return true

  func register_stone(id: String) -> bool:
    if stone.has(id) or not economy.natural_nodes.has(id):
      return false
    stone[id]={"id":id,"position":economy.resource_positions[id]}
    return true

class MockTerrain:
  extends Node3D
  func height_at(x: float,z: float) -> float:
    return 0.4+0.01*x+0.025*z

class MockQuality:
  extends RefCounted
  func _natural_plantable(x: float,z: float) -> bool:
    return absf(x)<43.0 and absf(z)<43.0

func _fail(reason: String) -> void:
  printerr("FAIL_GPT6_RESOURCE_BIRTH_SAVE_TRANSACTION_"+reason)
  quit(87)

func _initialize() -> void:
  call_deferred("_run")

func _run() -> void:
  var terrain:=MockTerrain.new()
  get_root().add_child(terrain)
  var quality:=MockQuality.new()

  # A failed write is deterministic: nonexistent parent directory. Old
  # broken implementation left a 3D gatherable resource with no durable
  # ID and returned it as "successful" birth. It MUST rollback EVERYTHING.
  var bad_sim:=MockEconomy.new()
  var bad_eco:=MockEcology.new()
  bad_eco.economy=bad_sim
  var rejected: RefCounted=Spawner.new()
  rejected.set("save_path",
    "user://__nonexistent_gpt6_natural_qa_parent_20261018__/cannot_commit.json")
  if not bool(rejected.call("initialize",bad_sim,bad_eco,
      terrain,quality,{},null)):
    _fail("INIT_FAILED_FOR_UNWRITABLE_PATH")
    return
  for i in range(240):
    var born: Array[String]=rejected.call("advance_world_hour")
    if not born.is_empty() or not bad_sim.natural_nodes.is_empty() or (
        not bad_sim.resource_positions.is_empty()) or (
        not bad_eco.trees.is_empty()) or (
        not bad_eco.stone.is_empty()) or (
        not rejected.get("records").is_empty()):
      _fail("RESOURCE_BORN_WITHOUT_ATOMIC_DISK_COMMIT_AT_HOUR_"+str(i+1))
      return
  if int(rejected.get("spawn_tree_events"))!=0 or (
      int(rejected.get("spawn_stone_events"))!=0) or (
      bad_sim.existing_stock!={"wood":4,"stone":5}):
    _fail("FAILED_SAVE_MINTED_WOOD_OR_STONE_INVENTORY")
    return
  print("PASS_GPT6_REV208_NATURAL_SPAWN_WRITE_FAILURE_CLEANS_ALL_AUTHORITATIVE_AND_ECOLOGY_IDS")

  # Second failure mode occurs after economy/position/ecology register:
  # rejecting recovery settings must also erase all three references.
  var reject_sim:=MockEconomy.new()
  reject_sim.reject_recovery=true
  var reject_eco:=MockEcology.new()
  reject_eco.economy=reject_sim
  var broken_profile: RefCounted=Spawner.new()
  broken_profile.set("save_path",
    "user://qa_no_write_due_to_register_error_should_not_exist.json")
  if not bool(broken_profile.call("initialize",reject_sim,reject_eco,
      terrain,quality,{},null)):
    _fail("REJECT_INIT_FAILED")
    return
  for i in range(120):
    if not (broken_profile.call("advance_world_hour") as Array).is_empty():
      _fail("ECOLOGY_PROFILE_REJECTED_BUT_RESOURCE_VISUAL_SPAWNED")
      return
  if not reject_sim.natural_nodes.is_empty() or (
      not reject_sim.resource_positions.is_empty()) or (
      not reject_eco.trees.is_empty()):
    _fail("REJECTED_REGEN_PROFILE_LEFT_HARVESTABLE_GHOST")
    return
  print("PASS_GPT6_REV208_RECOVERY_SETUP_FAILURE_CANNOT_LEAVE_ORPHAN_ECONOMY_NODE")

  # Verify the fix did not break successful natural spontaneous resource
  # generation: two new trees & one new stone by world-hour 240. Nothing
  # enters village warehouse until an actor actually harvests it.
  var real_save: String="user://gpt6_qa_resource_atomic_birth_20261018.json"
  if FileAccess.file_exists(real_save):
    DirAccess.remove_absolute(ProjectSettings.globalize_path(real_save))
  var sim:=MockEconomy.new()
  var ecology:=MockEcology.new()
  ecology.economy=sim
  var real: RefCounted=Spawner.new()
  real.set("save_path",real_save)
  real.set("world_seed",19060418)
  if not bool(real.call("initialize",sim,ecology,terrain,quality,{},null)):
    _fail("REAL_SAVE_INIT_FAILED")
    return
  var actual_ids: Array[String]=[]
  for hour in range(240):
    for next_id in (real.call("advance_world_hour") as Array):
      actual_ids.append(String(next_id))
  if actual_ids.size()!=3 or sim.natural_nodes.size()!=3 or (
      sim.resource_positions.size()!=3 or ecology.trees.size()!=2 or (
      ecology.stone.size()!=1)) or (
      sim.existing_stock!={"wood":4,"stone":5}):
    _fail("VALID_DURABLE_SPAWN_CHANGED_QUANTITIES_OR_MINTED_INVENTORY")
    return
  var first_id: String=actual_ids[0]
  sim.natural_nodes[first_id]["remaining"]-=1
  var before: int=int(real.get("records")[first_id]["remaining"])
  real.set("save_path","user://__gpt6_no_parent__/bad.json")
  if bool(real.call("save_if_authoritative_amount_changed")):
    _fail("FAILED_WRITE_ACCEPTED")
    return
  if int(real.get("records")[first_id]["remaining"])!=before:
    _fail("FAILED_WRITE_MUTATED_BASELINE")
    return
  real.set("save_path",real_save)
  if not bool(real.call("save_if_authoritative_amount_changed")):
    _fail("HARVEST_RETRY_FAILED")
    return
  print("PASS_GPT6_REV208_HARVEST_FAILED_WRITE_RETRY")
  var refresh_sim:=MockEconomy.new()
  var refresh_eco:=MockEcology.new()
  refresh_eco.economy=refresh_sim
  var refreshed: RefCounted=Spawner.new()
  refreshed.set("save_path",real_save)
  if not bool(refreshed.call("initialize",refresh_sim,refresh_eco,
      terrain,quality,{},null)) or (
      int(refreshed.get("world_hours"))!=240) or (
      refresh_sim.natural_nodes.size()!=3) or (
      int(refresh_sim.natural_nodes[first_id]["remaining"])!=int(
        sim.natural_nodes[first_id]["remaining"])):
    _fail("ACTUAL_SAVE_LOAD_INCORRECT_TREE_HARVEST_OR_ENTITY_IDS")
    return
  if refresh_sim.existing_stock!={"wood":4,"stone":5}:
    _fail("RELOAD_OR_SPAWN_CREATED_FREE_WAREHOUSE_STOCK")
    return
  DirAccess.remove_absolute(ProjectSettings.globalize_path(real_save))
  print("PASS_GPT6_REV208_NATURAL_SUCCESS_WORLD240H_2TREES_1STONE_REAL_ATOMIC_SAVE_RELOAD_UNIQUE_IDS_NO_FREE_WAREHOUSE_STOCK")
  terrain.queue_free()
  quit(0)
