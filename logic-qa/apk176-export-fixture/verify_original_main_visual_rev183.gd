extends SceneTree
## Actual exported APK176 compiled MAIN with rev183 real resource economy.
## No fake "pass" without 7 real GLBs, original base scene, three animated
## character skeletons, conservation and actual physical stage construction.
const INITIAL_WOOD: int = 12 * 12
const INITIAL_STONE: int = 9 * 18
const PHASE_WOOD := [0, 9, 6, 3]
const PHASE_STONE := [6, 0, 0, 3]

func _initialize() -> void:
  call_deferred("_run")

func _fail(code: int, message: String) -> void:
  printerr("FAIL_APK176_REV183_AUTONOMOUS_WORLD ", message)
  quit(code)

func _total_inventory(econ, role: String, paid: int) -> int:
  var resources: int = int(econ.call("resource_remaining", role))
  var village: Dictionary = econ.get("villages")["CL-REV183-HX-VILLAGE"]
  var material: String = "wood" if role == "tree" else "stone"
  resources += int(village["stock"][material])
  for cargo in (econ.get("carried_by_actor") as Dictionary).values():
    if String(cargo.get("kind","")) == material:
      resources += int(cargo["amount"])
  return resources + paid

func _run() -> void:
  var pack: String = OS.get_environment("CANGLAN_QA_PCK_PATH")
  if pack.is_empty() or not FileAccess.file_exists(pack):
    _fail(2, "SIGNED_PCK_CANDIDATE_MISSING")
    return
  if not ProjectSettings.load_resource_pack(pack, true):
    _fail(3, "PACK_MOUNT_FAILED")
    return
  var packed: PackedScene = load("res://scenes/main.tscn")
  if packed == null:
    _fail(4, "APK176_MAIN_OVERRIDE_FAILED")
    return
  var main: Node = packed.instantiate()
  if main == null:
    _fail(5, "APK176_COMPILED_MAIN_INSTANTIATE_FAILED")
    return
  get_root().add_child(main)
  await process_frame
  await process_frame
  var room: Node = main.get_node_or_null("CanglanAutonomousEcologyWorldRev183")
  if room == null:
    _fail(6, "ORIGINAL_MAIN_MISSING_LIVING_WORLD")
    return
  var ui: Control = room.get_node_or_null("LivingWorldUI")
  var viewport: SubViewport = ui.get_node_or_null(
    "RealWorldViewportContainer/ActualLicensed3DWorldViewport") if ui != null else null
  if viewport == null or not viewport.own_world_3d or viewport.size.x < 460 or viewport.size.y < 260:
    _fail(7, "NO_SEPARATE_TRUE_3D_WORLD_ACTUAL_SIZE_" + (str(viewport.size) if viewport != null else "null"))
    return
  var world: Node3D = viewport.get_node_or_null("ResourceConservationAndConstruction")
  if world == null or world.get_node_or_null("TouchOrbitCamera") == null:
    _fail(8, "MISSING_3D_CAMERA")
    return
  var econ = room.get("sim")
  var first: Dictionary = room.call("stats")
  if int(first.get("revision",0)) != 183:
    _fail(9, "REVISION_MISMATCH_ACTUAL_ROOM_REPORT_" + str(first.get("revision")))
    return
  if int(first.get("source_assets",0)) != 7:
    _fail(44, "MUST_LOAD_ALL_SEVEN_REAL_LICENSED_SOURCE_MODELS_GOT_" + str(first.get("source_assets",0)))
    return
  if not (first.get("missing_assets", []) as Array).is_empty():
    _fail(10, "SOME_LICENSED_GLB_OR_TEXTURES_MISSING")
    return
  if int(first.get("visible_actor_labels",0)) != 3:
    _fail(27, "MISSING_VISIBLE_NPC_WORKER_JOB_LABELS")
    return
  var heights: Dictionary = first.get("worker_visual_heights_m",{})
  for profession in ["woodcutter","quarryman","builder"]:
    var actual_height: float = float(heights.get(profession,0.0))
    if actual_height < 1.5 or actual_height > 2.2:
      _fail(28, "NPC_NOT_SCALED_TO_VISIBLE_REAL_HEIGHT_" + profession + "_" + str(actual_height))
      return
  if int(first.get("worker_count",0)) != 3 or int(first.get("resource_node_count",0)) != 21:
    _fail(11, "NPC_AND_FINITE_RESOURCE_IDENTITIES_MISSING")
    return
  if (world.find_children("*", "MeshInstance3D", true, false) as Array).size() < 28:
    _fail(12, "REAL_GLBS_NOT_IN_RENDER_TREE")
    return
  var animations: Dictionary = first.get("animation_reports", {})
  for code in ["CL-NPC-0183-01","CL-NPC-0183-02","CL-NPC-0183-03"]:
    if not animations.has(code):
      _fail(13, "MISSING_ACTOR_ANIMATION_REGISTRATION " + code)
      return
    if String(animations[code].get("walk","")).is_empty():
      _fail(14, "UNANIMATED_CC0_HUMANOID_REJECTED " + code)
      return
  if _total_inventory(econ,"tree",0)!=INITIAL_WOOD or _total_inventory(econ,"stone",0)!=INITIAL_STONE:
    _fail(15,"NONZERO_WOOD_STONE_DEPOT_OR_INITIAL_ACCOUNTING_ERROR")
    return
  var paid_wood := 0
  var paid_stone := 0
  var known_stage := 0
  var paid_stage := false
  var observed_live_tree_seed_rewards: bool = false
  var saw_seed_in_depot: bool = false
  var observed_planting: bool = false
  var observed_builder_carried_real_materials := false
  var observed_builder_depot_with_material_pickup := false
  var returned_for_second_stage := false
  for tick in range(360):
    room.call("_process", 1.0)
    var live_workers: Dictionary = room.get("workers")
    var builder: Dictionary = live_workers.get("CL-NPC-0183-03", {})
    if String(builder.get("phase","")) == "to_building_site":
      var held: Dictionary = builder.get("carried_materials", {})
      if held.is_empty() or not builder.has("cargo_visual"):
        _fail(25, "BUILDER_ARRIVED_WITHOUT_PHYSICALLY_CARRIED_LICENSED_MATERIALS")
        return
      observed_builder_carried_real_materials = true
      if (builder["node"] as Node3D).position.distance_to(Vector3(0,0,10)) < 1.5:
        observed_builder_depot_with_material_pickup = true
    if String(builder.get("phase","")) == "to_warehouse_for_materials" and int(room.get("_stage_index"))>=1:
      returned_for_second_stage = true
    var ecology = room.get("eco")
    var seed_stock: int = int(econ.get("villages")["CL-REV183-HX-VILLAGE"]["stock"].get("tree_seed",0))
    var seed_pending: int = 0
    for count in ecology.awaiting_seed_delivery.values():
      seed_pending += int(count)
    if seed_stock+seed_pending+ecology.planted_count != ecology.minted_seed_events:
      _fail(29,"TREE_SEED_MULTIPLICATION_LOSS_OR_UNPAID_PLANTING")
      return
    observed_live_tree_seed_rewards = observed_live_tree_seed_rewards or ecology.minted_seed_events > 0
    observed_planting = observed_planting or ecology.planted_count > 0
    saw_seed_in_depot = saw_seed_in_depot or seed_stock > 0
    var stage: int = int(room.get("_stage_index"))
    var stage_paid_now: bool = bool(room.get("_stage_paid"))
    if stage < known_stage or stage > 4:
      _fail(16, "CONSTRUCTION_STAGE_ROLLBACK_OR_OVERFLOW")
      return
    known_stage = stage
    paid_wood = 0
    paid_stone = 0
    for i in range(stage):
      paid_wood += int(PHASE_WOOD[i])
      paid_stone += int(PHASE_STONE[i])
    if stage_paid_now:
      paid_wood += int(PHASE_WOOD[stage])
      paid_stone += int(PHASE_STONE[stage])
    if _total_inventory(econ,"tree",paid_wood)!=INITIAL_WOOD:
      _fail(17, "PHYSICAL_WOOD_INFLATION_OR_LOSS_TICK_%d" % tick)
      return
    if _total_inventory(econ,"stone",paid_stone)!=INITIAL_STONE:
      _fail(18, "PHYSICAL_STONE_INFLATION_OR_LOSS_TICK_%d" % tick)
      return
    paid_stage = paid_stage or stage_paid_now
  var report: Dictionary = room.call("stats")
  if int(report["harvests"]) < 4 or int(report["deliveries"]) < 4:
    _fail(19, "NPC_MUST_ACTUALLY_WALK_TO_RESOURCES_AND_DELIVER")
    return
  if int(report["stage"]) < 2 or int(report["built_cc0_parts"]) < 6:
    _fail(20, "REAL_MATERIAL_PAID_MULTI_STAGE_CONSTRUCTION_MUST_PROGRESS")
    return
  if not paid_stage:
    _fail(21, "NO_EVIDENCE_OF_ACTUAL_STOCK_RESERVATION")
    return
  if not (observed_builder_carried_real_materials and observed_builder_depot_with_material_pickup and returned_for_second_stage):
    _fail(26, "BUILDER_MUST_WALK_TO_WAREHOUSE_AND_TRANSPORT_STAGED_MATERIALS")
    return
  if not observed_live_tree_seed_rewards or not observed_planting:
    _fail(30,"TREE_MUST_ONLY_DROP_ONE_SEED_WHEN_FULLY_CUT_AND_REAL_SEED_MUST_GERMINATE")
    return
  if not saw_seed_in_depot:
    _fail(31,"HALF_THE_SEEDS_MUST_REMAIN_IN_PHYSICAL_DEPOT_STOCK")
    return
  if not bool(report.get("save_unchanged",false)):
    _fail(22, "MUST_PRESERVE_EXISTING_SAVES")
    return
  # World geology must not add building-site rocks or spawn mountain material.
  var ecology = room.get("eco")
  var rocks: Dictionary = ecology.stone
  var exposed_id: String = ""
  for id in rocks:
    if int(econ.natural_nodes[id]["remaining"]) == 0:
      exposed_id = id
      break
  if exposed_id.is_empty():
    _fail(32,"MUST_EXHAUST_AT_LEAST_ONE_REAL_ROCK_TO_PROVE_REGROWTH")
    return
  var underground_before: int = int(rocks[exposed_id]["subsurface"])
  var surface_before: int = int(econ.natural_nodes[exposed_id]["remaining"])
  rocks[exposed_id]["hours"] = 0
  ecology.advance_ecology_hours(48)
  if int(econ.natural_nodes[exposed_id]["remaining"]) != surface_before+1:
    _fail(33,"DEPLETED_QUARRY_MUST_REOPEN_AS_ONE_PEBBLE_AFTER_48_SIMULATED_HOURS")
    return
  if int(rocks[exposed_id]["subsurface"]) != underground_before-1:
    _fail(34,"STONE_EXPOSURE_MUST_DEBIT_FINITE_DEEP_STRATUM")
    return
  if String(rocks[exposed_id]["stage"]) != "pebbles":
    _fail(35,"STONE_VISUAL_LIFE_STAGES_PEBBLES_ROCK_CLUSTER_EXPECTED")
    return
  # Construction exclusion is physically enforced, not just label decoration.
  if not econ.register_natural_node("CL-REV183-EXCLUSION-TEST", "CL-REV183-HX-VILLAGE","stone",3):
    _fail(36,"UNABLE_REGISTER_TEST_STONE")
    return
  econ.register_resource_position("CL-REV183-EXCLUSION-TEST",Vector3(0,0,-3))
  ecology.register_stone("CL-REV183-EXCLUSION-TEST")
  var test_rock: Dictionary = econ.natural_nodes["CL-REV183-EXCLUSION-TEST"]
  test_rock["remaining"] = 0
  var test_bank: int = int(ecology.stone["CL-REV183-EXCLUSION-TEST"]["subsurface"])
  ecology.advance_ecology_hours(168)
  if int(test_rock["remaining"]) != 0 or int(ecology.stone["CL-REV183-EXCLUSION-TEST"]["subsurface"]) != test_bank:
    _fail(37,"NO_GEOLOGICAL_STONE_RECOVERY_INSIDE_BUILDING_FOOTPRINT")
    return
  if ecology.advance_geological_years(1000000.0,false):
    _fail(38,"NO_TECTONIC_UPLIFT_OUTSIDE_CONVERGENT_BOUNDARY")
    return
  for i in range(5):
    if not ecology.advance_geological_years(1000000.0,true):
      _fail(39,"TECTONIC_BOUNDARY_SHOULD_UPLIFT_OVER_MILLIONS_OF_YEARS")
      return
  if ecology.geological_ridge_m < 7000.0 or ecology.geological_ridge_m > 9000.0:
    _fail(40,"HIMALAYA_SCALE_OROGENY_MUST_REQUIRE_MILLIONS_OF_YEARS")
    return
  # Do not run this time-skip on NPC ages, warehouse or live construction.
  if int(econ.get("villages")["CL-REV183-HX-VILLAGE"]["stock"]["stone"]) != int(report["stock_stone"]):
    _fail(41,"GEOLOGICAL_TIME_ADVANCE_MUST_NOT_MINT_GAMEPLAY_STONE")
    return
  room.call("_focus_builder")
  if not bool(room.get("_follow_builder")) or float(room.get("_camera_distance")) > 14.0:
    _fail(42,"BUTTON_MUST_ACTUALLY_FOCUS_VISIBLE_NPC")
    return
  room.call("_close_world")
  if ui.get_node("RealWorldViewportContainer").visible:
    _fail(23, "CANNOT_RETURN_TO_INSTALLED_ORIGINAL_WORLD")
    return
  room.call("_reopen_world")
  if not ui.get_node("RealWorldViewportContainer").visible:
    _fail(24, "CANNOT_REENTER_PRODUCTION_WORLD")
    return
  print("PASS_APK176_REAL_3D_PREVIEW")
  print("OBSERVED_APK176_MAIN_INSTANCE_WITH_PORTAL_AND_IMAGES_PENDING_ENGINE_ERROR_AUDIT")
  print("PASS_APK176_ACTUAL_MAIN_INSTANTIATED_NO_ENGINE_ERRORS_WITH_REAL_HOUSE")
  print("PASS_REV183_LICENSED_3D_NPC_RESOURCE_TRANSPORT_MATERIAL_CONSERVATION_STAGE_BUILD")
  print("PASS_REV183_PHONE_VISIBILITY_TREE_SEED_BEDROCK_EXCLUSION_AND_TECTONIC_MILLIONS_OF_YEARS")
  print("REV183_ACTUAL_APK176_QA_STATS ",report)
  # Explicitly teardown original exported scene before the headless RenderServer
  # exits: otherwise GLTF skeleton/animation/mesh RIDs report leaked resources.
  main.queue_free()
  await process_frame
  await process_frame
  quit(0)
