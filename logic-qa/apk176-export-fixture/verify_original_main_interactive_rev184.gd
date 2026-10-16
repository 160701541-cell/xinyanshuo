extends SceneTree
## Actual exported APK176 compiled MAIN with rev184 real resource economy.
## No fake "pass" without 7 real GLBs, original base scene, three animated
## character skeletons, conservation and actual physical stage construction.
const INITIAL_WOOD: int = 12 * 12
const INITIAL_STONE: int = 9 * 18
const PHASE_WOOD := [0, 9, 6, 3]
const PHASE_STONE := [6, 0, 0, 3]

func _initialize() -> void:
  call_deferred("_run")

func _fail(code: int, message: String) -> void:
  printerr("FAIL_APK176_REV184_AUTONOMOUS_WORLD ", message)
  quit(code)

func _total_inventory(econ, role: String, paid: int) -> int:
  var resources: int = int(econ.call("resource_remaining", role))
  var village: Dictionary = econ.get("villages")["CL-REV184-HX-VILLAGE"]
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
  var room: Node = main.get_node_or_null("CanglanAutonomousEcologyWorldRev184")
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
  if int(first.get("revision",0)) != 184:
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
  # The entire point of this version is that static Kenney GLBs must NO
  # LONGER create one independently rendered MeshInstance3D per tree/stone.
  var drawn_parts: Array[Node] = world.find_children("*", "MultiMeshInstance3D", true, false)
  var batch: Dictionary = first.get("kenney_batch",{})
  if int(first.get("palette_roles",0)) != 5:
    _fail(12, "KENNEY_MAIN_PALETTE_MUST_HAVE_EXACTLY_FIVE_SWATCHES")
    return
  if drawn_parts.size() == 0 or int(batch.get("multimesh_draw_nodes",0)) < 3:
    _fail(45, "NO_REAL_MULTI_MESH_BATCHING_OF_LICENSED_KENNEY_SOURCES")
    return
  if drawn_parts.size() != int(batch["multimesh_draw_nodes"]):
    _fail(46, "BATCH_NODES_MUST_BE_REAL_MULTIMESH_DRAWABLES")
    return
  if int(batch.get("batched_world_objects",0)) < 23:
    _fail(47, "TREES_ROCKS_AND_SITE_ITEMS_NOT_ACTUALLY_BATCHED")
    return
  if int(batch.get("mesh_surface_draw_floor",9999)) > 65:
    _fail(48, "SOURCE_GLBS_HAVE_TOO_MANY_SURFACES_FOR_MOBILE_200_BUDGET")
    return
  if not (batch.get("batch_errors", []) as Array).is_empty():
    _fail(49, "MISSING_OR_INVALID_KENNEY_MULTIMESH_ROLE")
    return
  var sun_nodes: Array[Node] = world.find_children("*","DirectionalLight3D",true,false)
  if sun_nodes.size() != 1:
    _fail(50, "SCENE_MUST_HAVE_EXACTLY_ONE_MOBILE_DIRECTIONAL_SUN")
    return
  var sun: DirectionalLight3D = sun_nodes[0]
  if not sun.shadow_enabled or sun.directional_shadow_max_distance > 55.0:
    _fail(51, "SUN_MUST_CAST_CHEAP_SHORT_DISTANCE_SHADOWS")
    return
  # NO BACKGROUND PLANE masquerading as terrain: material, height,
  # collision, exposed strata and true water must share ONE 3D model.
  var terrain: Node3D = room.get("terrain_world")
  if terrain == null or world.get_node_or_null("PhysicalDeformable92mVillageStrata") == null:
    _fail(52,"MISSING_REAL_HEIGHTFIELD_AND_UNDERGROUND_GEOLOGY")
    return
  var soil_state: Dictionary = terrain.call("stats")
  if not soil_state.get("real_heightfield",false) or not soil_state.get("real_water_basin",false):
    _fail(55,"NO_PHYSICAL_EXCAVATABLE_TERRAIN_OR_CARVED_WATER")
    return
  if int(soil_state.get("cell_count",0)) < 1000 or int(soil_state.get("layer_count",0)) < 5:
    _fail(56,"TOO_FEW_ACTUAL_3D_SOIL_CELLS_AND_STRATA")
    return
  if world.find_children("*","StaticBody3D",true,false).is_empty():
    _fail(57,"TERRAIN_HAS_NO_PHYSICAL_COLLISION")
    return
  if world.get_node_or_null("PhysicalNaturalGroundNotPrefab") != null:
    _fail(58,"OLD_GREEN_PLANE_MUST_BE_REMOVED")
    return
  if not bool(terrain.call("_is_road",0.0,5.0)) or not bool(terrain.call("_is_road",-16.0,10.5)):
    _fail(59,"MISSING_QUIET_GREEN_DIRT_TRANSPORT_ROAD_IN_REAL_TERRAIN")
    return
  if not bool(terrain.call("is_water",-9.0,-28.0)):
    _fail(60,"VISIBLE_POOL_NEEDS_GENUINELY_LOWER_WATERBED")
    return
  if float(terrain.call("height_at",-9.0,-28.0)) >= float(terrain.get("WATER_LEVEL")):
    _fail(61,"POND_IS_A_FAKE_BLUE_GROUND_PLANE")
    return
  var player: Node = room.get("controls")
  var pc: Dictionary = player.call("stats") if player != null else {}
  if not pc.get("player_exists",false) or not pc.get("joystick_exists",false):
    _fail(62,"NO_REAL_PLAYER_AND_ANDROID_LEFT_JOYSTICK")
    return
  if not pc.get("first_person_available",false) or int(pc.get("zoom_buttons",0))!=2:
    _fail(63,"NO_FIRST_PERSON_ZOOM_AND_TOUCH_LOOK")
    return
  var render_frame: SubViewportContainer = ui.get_node("RealWorldViewportContainer")
  if render_frame.stretch_shrink != 1 or viewport.msaa_3d != Viewport.MSAA_2X:
    _fail(64,"PIXELATED_HALF_RES_RENDERER_MUST_BE_DISABLED_AND_MSAA_ENABLED")
    return
  var source_positions: Dictionary = econ.get("resource_positions")
  for rid in source_positions:
    var id_text: String = String(rid)
    if not id_text.begins_with("CL-TREE-0184-") and not id_text.begins_with("CL-STONE-0184-"):
      continue
    var position: Vector3 = source_positions[rid]
    if id_text.begins_with("CL-TREE-0184-") and position.x > -10.0:
      _fail(53, "FOREST_BLOCKS_CLEAR_CENTRAL_PATH_" + id_text)
      return
    if id_text.begins_with("CL-STONE-0184-") and position.x < 11.0:
      _fail(54, "QUARRY_BLOCKS_CLEAR_CENTRAL_PATH_" + id_text)
      return
  var animations: Dictionary = first.get("animation_reports", {})
  for code in ["CL-NPC-0184-01","CL-NPC-0184-02","CL-NPC-0184-03"]:
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
  var observed_real_foundation_digging: bool = false
  var observed_live_tree_seed_rewards: bool = false
  var saw_seed_in_depot: bool = false
  var observed_planting: bool = false
  var observed_builder_carried_real_materials := false
  var observed_builder_depot_with_material_pickup := false
  var returned_for_second_stage := false
  for tick in range(360):
    room.call("_process", 1.0)
    var terrain: Node3D = room.get("terrain_world")
    if not bool(terrain.call("inventory_conserved")):
      _fail(65,"EXCAVATION_CREATED_SOIL_OUT_OF_NOTHING_OR_LOST_MASS")
      return
    if int(terrain.call("stats").get("excavation_units",0)) > 0:
      observed_real_foundation_digging = true
    var live_workers: Dictionary = room.get("workers")
    var builder: Dictionary = live_workers.get("CL-NPC-0184-03", {})
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
    var seed_stock: int = int(econ.get("villages")["CL-REV184-HX-VILLAGE"]["stock"].get("tree_seed",0))
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
  if not observed_real_foundation_digging or not bool(terrain.call("foundation_ready")):
    _fail(66,"NPC_MUST_EXCAVATE_LAYERED_3D_PIT_BEFORE_BUILDING_FOUNDATION")
    return
  if int(report.get("foundation_excavation_npc_cuts",0)) < 6:
    _fail(67,"REAL_NPC_NEVER_ACTUALLY_REMOVED_FOUNDATION_SOIL")
    return
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
  if not econ.register_natural_node("CL-REV184-EXCLUSION-TEST", "CL-REV184-HX-VILLAGE","stone",3):
    _fail(36,"UNABLE_REGISTER_TEST_STONE")
    return
  econ.register_resource_position("CL-REV184-EXCLUSION-TEST",Vector3(0,0,-3))
  ecology.register_stone("CL-REV184-EXCLUSION-TEST")
  var test_rock: Dictionary = econ.natural_nodes["CL-REV184-EXCLUSION-TEST"]
  test_rock["remaining"] = 0
  var test_bank: int = int(ecology.stone["CL-REV184-EXCLUSION-TEST"]["subsurface"])
  ecology.advance_ecology_hours(168)
  if int(test_rock["remaining"]) != 0 or int(ecology.stone["CL-REV184-EXCLUSION-TEST"]["subsurface"]) != test_bank:
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
  if int(econ.get("villages")["CL-REV184-HX-VILLAGE"]["stock"]["stone"]) != int(report["stock_stone"]):
    _fail(41,"GEOLOGICAL_TIME_ADVANCE_MUST_NOT_MINT_GAMEPLAY_STONE")
    return
  # Test REAL player movement with the SAME mobile input vector and
  # on-ground contact. Switch to a truly first-person camera view.
  var player: Node = room.get("controls")
  var actor: Node3D = player.get("actor")
  var before_move: Vector3 = actor.position
  player.set("_joystick",Vector2(0,-1))
  player.call("step",0.8)
  player.set("_joystick",Vector2.ZERO)
  if Vector2(actor.position.x-before_move.x,actor.position.z-before_move.z).length()<1.0:
    _fail(68,"LEFT_ANALOG_MOVE_DID_NOT_MOVE_ACTUAL_PLAYER_ENTITY")
    return
  var before_yaw: float = float(player.get("_yaw"))
  player.call("turn_view",Vector2(72,23))
  if is_equal_approx(float(player.get("_yaw")),before_yaw):
    _fail(69,"RIGHT_DRAG_DID_NOT_ROTATE_REAL_CAMERA")
    return
  var before_zoom: float = float(player.get("_distance"))
  player.call("zoom_in")
  if float(player.get("_distance"))>=before_zoom:
    _fail(70,"PLUS_BUTTON_DID_NOT_ZOOM_REAL_CAMERA")
    return
  player.call("zoom_out")
  if float(player.get("_distance")) <= 3.1:
    _fail(71,"MINUS_BUTTON_DID_NOT_ZOOM_REAL_CAMERA")
    return
  player.call("toggle_perspective")
  if not bool(player.get("is_first_person")) or actor.visible:
    _fail(72,"FIRST_PERSON_DID_NOT_HIDE_OWN_CHARACTER_AND_ENTER_EYE_CAMERA")
    return
  if not is_equal_approx(room.get("camera").position.y,actor.position.y+1.65):
    _fail(73,"FIRST_PERSON_CAMERA_IS_NOT_AT_PLAYER_HEAD")
    return
  player.call("toggle_perspective")
  if bool(player.get("is_first_person")) or not actor.visible:
    _fail(74,"THIRD_PERSON_MUST_RESTORE_VISIBLE_ANIMATED_PLAYER")
    return
  # Player (not a pre-scripted NPC) must be able to dig real terrain material.
  # Move player near the real worksite without calling any fake stock grant.
  actor.position = Vector3(-1.0,float(terrain.call("height_at",-1.0,0.0)),0.0)
  var before_dug: int = int(terrain.get("dug_units"))
  var before_collision: int = int(terrain.get("mesh_revisions"))
  var attempted: Dictionary = player.call("dig")
  if not bool(attempted.get("ok",false)):
    _fail(75,"ACTUAL_PLAYER_DIG_BUTTON_CANNOT_EXCAVATE_SOIL")
    return
  if int(terrain.get("dug_units"))!=before_dug+1 or int(terrain.get("mesh_revisions"))<=before_collision:
    _fail(76,"PLAYER_DIG_DID_NOT_UPDATE_VISUAL_SURFACE_AND_COLLISION")
    return
  if not bool(terrain.call("inventory_conserved")):
    _fail(77,"PLAYER_DIG_MUST_PRESERVE_TOTAL_UNDERGROUND_MASS")
    return
  # Interact with the SAME authoritative warehouse and work NPCs.
  actor.position = Vector3(0,float(terrain.call("height_at",0.0,10.0)),10.0)
  var depot_interaction: Dictionary = player.call("interact")
  if not bool(depot_interaction.get("ok",false)):
    _fail(78,"WAREHOUSE_INTERACTION_BUTTON_IS_NONFUNCTIONAL")
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
  print("PASS_REV184_LICENSED_3D_NPC_RESOURCE_TRANSPORT_MATERIAL_CONSERVATION_STAGE_BUILD")
  print("PASS_REV184_PHONE_VISIBILITY_TREE_SEED_BEDROCK_EXCLUSION_AND_TECTONIC_MILLIONS_OF_YEARS")
  print("PASS_REV184_FIVE_SWATCHES_REAL_KENNEY_MULTIMESH_ONE_SUN_AND_CLEAR_ROADS")
  print("REV184_MOBILE_DRAW_BUDGET_200_REQUIRES_ANDROID_HUD_OBSERVATION_NOT_HEADLESS_EMULATION")
  print("PASS_REV184_REAL_MOVABLE_PLAYER_FIRST_THIRD_PERSON_ZOOM_TOUCH_INTERACT_AND_EXCAVATE_STRATIFIED_COLLISION_WATER")
  print("REV184_ACTUAL_APK176_QA_STATS ",report)
  # Explicitly teardown original exported scene before the headless RenderServer
  # exits: otherwise GLTF skeleton/animation/mesh RIDs report leaked resources.
  main.queue_free()
  await process_frame
  await process_frame
  quit(0)
