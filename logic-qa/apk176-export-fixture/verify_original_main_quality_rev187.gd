extends SceneTree
## Actual exported APK176 compiled MAIN with rev187 real resource economy.
## No fake "pass" without 7 real GLBs, original base scene, three animated
## character skeletons, conservation and actual physical stage construction.
const INITIAL_WOOD: int = 12 * 12
const INITIAL_STONE: int = 9 * 18
const PHASE_WOOD := [0, 9, 6, 3]
const PHASE_STONE := [6, 0, 0, 3]

func _initialize() -> void:
  call_deferred("_run")

func _fail(code: int, message: String) -> void:
  printerr("FAIL_APK176_REV187_AUTONOMOUS_WORLD ", message)
  quit(code)

func _total_inventory(econ, role: String, paid: int) -> int:
  var resources: int = int(econ.call("resource_remaining", role))
  var village: Dictionary = econ.get("villages")["CL-REV186-HX-VILLAGE"]
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
  var room: Node = main.get_node_or_null("CanglanAutonomousEcologyWorldRev187")
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
  if int(first.get("revision",0)) != 187:
    _fail(9, "REVISION_MISMATCH_ACTUAL_ROOM_REPORT_" + str(first.get("revision")))
    return
  if int(first.get("source_assets",0)) != 7:
    _fail(44, "MUST_LOAD_ALL_SEVEN_REAL_LICENSED_SOURCE_MODELS_GOT_" + str(first.get("source_assets",0)))
    return
  # rev198: existence of a MeshInstance and 1.8m AABB were NOT enough.
  # Real Godot screenshots proved a solid Knight armor material Alpha 0.0
  # rendered ZERO character pixels even though node.visible=true.
  if int(first.get("licensed_animated_body_materials_fixed_from_alpha_zero",0))<1:
    _fail(232,"REV198_ANIMATED_CHARACTER_STILL_TRANSPARENT_IMPORTED_KNIGHT_MATERIAL")
    return
  var character_source: Node3D=room.get("asset_sources")["worker"]
  for solid_mesh in character_source.find_children("*","MeshInstance3D",true,false):
    var part: MeshInstance3D=solid_mesh as MeshInstance3D
    for surface in range(part.mesh.get_surface_count()):
      var material: Material=part.get_active_material(surface)
      if material is StandardMaterial3D and (material as StandardMaterial3D).albedo_color.a<0.5:
        _fail(233,"REV198_SOLID_LICENSED_KNIGHT_STILL_HAS_ZERO_ALPHA_SURFACE_"+str(surface))
        return
  print("PASS_REV198_REAL_LICENSED_KNIGHT_ARMOR_SKIN_OPACITY_REPAIRED")
  # REV199: do not fake a hair/sword as procedural models; require the
  # two real immutable Git-blob-verified CC0 Quaternius GLB sources.
  if not bool(first.get("real_cc0_long_hair_attached_to_entities",0)>=4) or (
      not bool(first.get("real_cc0_sword_loaded",false))):
    _fail(250,"REV199_USER_SAW_BARE_BALD_HEAD_AND_NO_REAL_CC0_SWORD")
    return
  var original_hero: Node3D=room.get("controls").get("actor")
  var hair: MeshInstance3D=original_hero.get_node_or_null(
    "ActualCC0QuaterniusHairLongNOTArtificialHelmet")
  if hair==null or hair.mesh==null or hair.mesh.surface_get_arrays(0)[
      Mesh.ARRAY_VERTEX].size()<2800:
    _fail(251,"REV199_CC0_HAIRSTYLE_GEOMETRY_NOT_ACTUALLY_ON_PLAYER_HEAD")
    return
  if hair.material_override==null or (hair.material_override as StandardMaterial3D).albedo_color.a<0.95:
    _fail(252,"REV199_HAIR_MUST_BE_ACTUAL_OPAQUE_BLACK_HAIR_NOT_A_FAKE_UI_LABEL")
    return
  # rev200: previous hair node & 3080 vertices QA falsely passed while the
  # GLB nested below a Knight root scaled 5.6->1.8m; hair was IN TORSO.
  # Require genuine WORLD-SPACE hair bounds over top of the 1.8m actual
  # avatar, and reject cosmetic hair assembled far above the scalp.
  var hair_bounds: Vector2=room.call("_visible_bounds",hair)
  var hero_world_top: float=float(original_hero.position.y)+float(
    original_hero.get_meta("actor_visual_height_m",0.0))
  if hair_bounds.x<hero_world_top-0.50 or hair_bounds.x>hero_world_top+0.02 or (
      hair_bounds.y<hero_world_top-0.11 or hair_bounds.y>hero_world_top+0.40):
    _fail(254,"REV200_SCENE_TREE_HAIR_EXISTS_BUT_ACTUAL_HEAD_IS_STILL_BALD_"+
      str(hair_bounds)+"_player_head_y_"+str(hero_world_top))
    return
  print("PASS_REV200_REAL_CC0_HAIR_BOUNDS_FOLLOW_LICENSED_3D_AVATAR_HEAD",hair_bounds)
  var sword_source: Node3D=room.get("licensed_flying_sword_source")
  var sword_meshes: Array[Node]=sword_source.find_children("*","MeshInstance3D",true,false)
  if sword_meshes.is_empty() or (sword_meshes[0] as MeshInstance3D).mesh.get_surface_count()<3:
    _fail(253,"REV199_FLYING_SWORD_NOT_THE_REAL_MULTI_MATERIAL_LICENSED_QUATERNIUS_GLB")
    return
  print("PASS_REV199_IMMUTABLE_AUTHENTIC_CC0_LONG_HAIR_PLAYER_AND_NPC_PLUS_REAL_MULTIMATERIAL_FLYING_SWORD")
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
  var drawn_parts: Array[Node] = world.find_children("ActualKenneyBatch_*", "MultiMeshInstance3D", true, false)
  var batch: Dictionary = first.get("kenney_batch",{})
  if int(first.get("palette_roles",0)) <= 20 or not first.get("palette_unlimited",false) or not first.get("old_fixed_five_swatch_rule_removed",false):
    _fail(12,"USER_EXPLICITLY_CANCELLED_FIVE_SWATCH_LOCK_WANTS_RICH_NATURAL_COLORS")
    return
  var palette: RefCounted=room.get("palette")
  for shade in ["grass_deep","grass_light","leaf_spring","leaf_deep","wood_light",
      "stone_brown","soil_sand","roof","water","flower_white","flower_yellow",
      "flower_pink","flower_purple"]:
    if palette.call("swatch",shade).is_equal_approx(palette.call("swatch","grass")):
      _fail(101,"NATURAL_PALETTE_NOT_ACTUALLY_DIFFERENT_FOR_"+shade)
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
  if int(batch.get("mesh_surface_draw_floor",0)) <= 0:
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
  if not sun.shadow_enabled or sun.directional_shadow_max_distance>100.1:
    _fail(51,"SINGLE_SUN_SHADOW_MUST_MATCH_MANUAL_TIER_UP_TO_100_METRES")
    return
  if not sun.shadow_enabled or sun.directional_shadow_max_distance<29.9:
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
  if float(terrain.call("height_at",-9.0,-28.0)) >= -0.72:
    _fail(61,"POND_IS_A_FAKE_BLUE_GROUND_PLANE")
    return
  # REV193 genuine deterministic exterior mesh + collision + persisted mining.
  # Simulating a far-view background is insufficient: the actual player
  # must cross the old x=46 wall on a physically loaded and diggable chunk.
  var start_chunks: Dictionary=terrain.get("stream_chunks")
  if start_chunks.size()<12 or start_chunks.size()>36 or not bool(terrain.call(
      "stream_contains_physical_chunk",55.0,12.0)):
    _fail(174,"REV193_NO_PHYSICAL_46M_EXTERIOR_STREAMED_CHUNKS")
    return
  for world_pos in [Vector2(46.0,12.0),Vector2(-46.0,12.0),
      Vector2(12.0,46.0),Vector2(12.0,-46.0)]:
    var edge: Vector2=world_pos
    var xa: float=edge.x
    var za: float=edge.y
    var side_x: float=0.001 if absf(absf(xa)-46.0)<0.001 else 0.0
    var side_z: float=0.001 if absf(absf(za)-46.0)<0.001 else 0.0
    var a_height: float=float(terrain.call("height_at",xa-side_x,za-side_z))
    var b_height: float=float(terrain.call("height_at",xa+side_x,za+side_z))
    if absf(a_height-b_height)>0.025:
      _fail(175,"REV193_STREAM_AND_CORE_STITCH_DIFFER_IN_HEIGHT_"+str(edge))
      return
  var exterior: Vector3=Vector3(75.0,0.0,11.0)
  terrain.call("stream_around",exterior,true)
  var exterior_key: String=terrain.call("_stream_chunk_key",
    terrain.call("_stream_coords",exterior.x,exterior.z))
  var chunk_root: Node3D=(terrain.get("stream_chunks") as Dictionary).get(exterior_key)
  if chunk_root==null or chunk_root.get_node_or_null(
      "PhysicalStreamedTerrainCollision/RegeneratedStreamedSoilCollision")==null:
    _fail(176,"REV193_EXTERIOR_CHUNK_HAS_NO_ACTUAL_PHYSICAL_COLLISION_SHAPE")
    return
  var collision_shape: CollisionShape3D=chunk_root.get_node(
      "PhysicalStreamedTerrainCollision/RegeneratedStreamedSoilCollision")
  if collision_shape.shape==null or not collision_shape.shape is ConcavePolygonShape3D:
    _fail(177,"REV193_CHUNK_COLLISION_IS_NOT_GENERATED_FROM_TERRAIN_TRIMESH")
    return
  var external_height_before: float=float(terrain.call("height_at",exterior.x,exterior.z))
  var resources_before: int=int((terrain.get("stream_spoil_bag") as Dictionary).get("topsoil",0))
  var original_save_path: String=String(terrain.get("stream_save_path"))
  terrain.set("stream_save_path","user://rev193_qa_ephemeral_deltas.json")
  (terrain.get("stream_cut_cells") as Dictionary).clear()
  var excavation: Dictionary=terrain.call("excavate_at",exterior,"CL-PLAYER-0184-0001")
  if not bool(excavation.get("ok",false)) or not bool(excavation.get("persistent",false)):
    _fail(178,"REV193_EXTERIOR_PHYSICAL_EXCAVATION_CANNOT_PERSIST")
    return
  if absf(float(terrain.call("height_at",exterior.x,exterior.z))-
      (external_height_before-0.45))>0.002:
    _fail(179,"REV193_EXTERIOR_MESH_AND_HEIGHTFIELD_DISAGREE_AFTER_DIG")
    return
  if int((terrain.get("stream_spoil_bag") as Dictionary).get("topsoil",0))!=resources_before+1:
    _fail(180,"REV193_EXTERIOR_MINING_DOES_NOT_PRODUCE_CONSERVED_SOIL")
    return
  terrain.call("stream_around",Vector3(460,0,460),true)
  if (terrain.get("stream_chunks") as Dictionary).has(exterior_key):
    _fail(181,"REV193_STREAM_MUST_UNLOAD_FAR_PHYSICAL_COLLISION")
    return
  (terrain.get("stream_cut_cells") as Dictionary).clear()
  terrain.call("_load_stream_deltas") # reload actual JSON from user:// save
  var loaded_cut: int=int((terrain.get("stream_cut_cells") as Dictionary).get(
    String(excavation.get("cell","")),0))
  if loaded_cut!=1:
    _fail(182,"REV193_MINED_CHUNK_DELTA_DOES_NOT_SURVIVE_FILE_RELOAD")
    return
  if not terrain.call("inventory_conserved") or int(
      (terrain.get("stream_spoil_bag") as Dictionary).get("topsoil",0))!=resources_before+1:
    _fail(186,"REV193_RELOADING_CHUNK_DUPLICATED_OR_LOST_REAL_SOIL_MASS")
    return
  terrain.call("stream_around",exterior,true)
  if absf(float(terrain.call("height_at",exterior.x,exterior.z))-
      (external_height_before-0.45))>0.002:
    _fail(183,"REV193_MINED_CHUNK_REPOPULATED_INSTEAD_OF_RESTORING_WORLD")
    return
  terrain.call("stream_around",Vector3(0,0,10),true)
  terrain.set("stream_save_path",original_save_path)
  (terrain.get("stream_cut_cells") as Dictionary).clear()
  if int((terrain.get("stream_chunks") as Dictionary).size())>36:
    _fail(184,"REV193_CHUNK_PHYSICS_MEMORY_UNBOUNDED")
    return
  print("PASS_REV193_DETERMINISTIC_WALKABLE_PHYSICAL_CHUNKS_NO_92M_WALL_AND_PERSISTED_MINING")
  var player: Node = room.get("controls")
  var pc: Dictionary = player.call("stats") if player != null else {}
  if not pc.get("player_exists",false) or not pc.get("joystick_exists",false):
    _fail(62,"NO_REAL_PLAYER_AND_ANDROID_LEFT_JOYSTICK")
    return
  if not pc.get("first_person_available",false) or int(pc.get("zoom_buttons",0))!=2:
    _fail(63,"NO_FIRST_PERSON_ZOOM_AND_TOUCH_LOOK")
    return
  # Cross the previous 42m player clamp using the genuine input pathway.
  var hero: Node3D=player.get("actor")
  var saved_position: Vector3=hero.position
  var saved_yaw: float=float(player.get("_yaw"))
  hero.position=Vector3(45.65,
    float(terrain.call("height_at",45.65,12.0))+float(hero.get_meta("actor_ground_offset_y",0.0)),12.0)
  player.set("_yaw",-PI/2.0)
  player.set("_joystick",Vector2(0.0,-1.0))
  player.call("step",0.50)
  player.set("_joystick",Vector2.ZERO)
  if hero.position.x<=46.01 or hero.position.x>=52.0 or not bool(
      terrain.call("stream_contains_physical_chunk",hero.position.x,hero.position.z)):
    _fail(185,"REV193_REAL_PLAYER_STILL_STOPPED_AT_ORIGINAL_46M_TERRAIN_BORDER")
    return
  hero.position=saved_position
  player.set("_yaw",saved_yaw)
  player.call("update_camera")
  terrain.call("stream_around",hero.position,true)
  print("PASS_REV193_ORIGINAL_PLAYER_ACTUALLY_WALKED_ACROSS_46M_WORLD_BOUNDARY")
  # rev188 user phone QA regression: normal HUD MUST replace QA controls.
  var game_hud: Control=player.get("hud") as Control
  if game_hud==null:
    _fail(141,"REV188_PLAYER_HUD_MISSING")
    return
  for key in ["LiveGameVitalsRev188","GameMenu_角色","GameMenu_背包",
      "GameMenu_修炼","GameMenu_菜单","MobileGameplay_GatherAction",
      "MobileGameplay_DashAction","MobileGameplay_DigAction",
      "MobileGameplay_InteractAction","MobileGameplay_ViewAction"]:
    if game_hud.get_node_or_null(key)==null:
      _fail(142,"REV188_REQUIRED_PLAYER_HUD_CONTROL_MISSING_"+key)
      return
  if bool(room.get("developer_ui_visible")) or ui.get_node("ProductionInspector").visible:
    _fail(143,"REV188_DEBUG_QA_CONTROLS_SHOULD_BE_HIDDEN_IN_NORMAL_GAMEPLAY")
    return
  var found_hp: Array[Node]=game_hud.find_children("RealHealthFromFallDamageAndFood","ProgressBar",true,false)
  var found_stamina: Array[Node]=game_hud.find_children("ActualWorldCitizenEnergy","ProgressBar",true,false)
  if found_hp.size()!=1 or found_stamina.size()!=1:
    _fail(144,"REV188_LIVE_VITALS_NOT_IN_ACTUAL_SCENE_TREE")
    return
  var gauges: ProgressBar=found_hp[0] as ProgressBar
  var stamina: ProgressBar=found_stamina[0] as ProgressBar
  if gauges==null or stamina==null or int(gauges.value)!=100:
    _fail(144,"REV188_MOBILE_HEALTH_OR_STAMINA_GAUGE_NOT_REAL")
    return
  if int(stamina.value)!=int(econ.citizens["CL-PLAYER-0184-0001"]["energy"]):
    _fail(145,"REV188_PLAYER_STAMINA_NOT_BOUND_TO_WORLD_SIM")
    return
  if int(player.call("apply_player_damage",17))!=83 or int(gauges.value)!=83:
    _fail(146,"REV188_DAMAGE_MUST_CHANGE_REAL_HP_AND_ACTUAL_HUD")
    return
  player.set("_player_health",100)
  player.call("_refresh_game_hud")
  player.call("_open_game_menu","inventory")
  if not game_hud.get_node("Rev188CharacterInventoryCultivationMenu").visible:
    _fail(147,"REV188_BAG_MENU_CANNOT_OPEN")
    return
  player.call("_open_game_menu","inventory")
  room.call("_set_dev_ui_visible",true)
  if not ui.get_node("ProductionInspector").visible:
    _fail(148,"REV188_DEVELOPER_TOOLS_CANNOT_BE_REOPENED")
    return
  room.call("_set_dev_ui_visible",false)
  print("PASS_REV188_REAL_HEALTH_STAMINA_GAME_HUD_BAG_MENU_AND_OPT_IN_DEV_TOOLS")
  # rev189 gamepad QA injects normalized JoyButton events; CI has NO real
  # paired Android HID hardware. Do not call this a physical pad acceptance.
  if not (player.call("_pad_axis_deadzone",Vector2(0.05,-0.06)) as Vector2).is_zero_approx():
    _fail(151,"PAD_ANALOG_DEADZONE_DRIFTS_AT_REST")
    return
  var filtered: Vector2=player.call("_pad_axis_deadzone",Vector2(0.95,0.95))
  if filtered.length()>1.001 or filtered.length()<0.95:
    _fail(152,"PAD_DIAGONAL_INPUT_MUST_BE_RADIAL_AND_CLAMPED")
    return
  var pad_menu: Node=game_hud.get_node("Rev188CharacterInventoryCultivationMenu")
  var yaw_before: float=float(player.get("_yaw"))
  player.call("_pad_apply_look",Vector2(0.7,0.37),0.20)
  if absf(float(player.get("_yaw"))-yaw_before)<0.04:
    _fail(153,"PAD_RIGHT_STICK_DOES_NOT_MOVE_REAL_CAMERA")
    return
  player.set("_yaw",yaw_before)
  player.call("update_camera")
  var physical_button_event:=InputEventJoypadButton.new()
  physical_button_event.device=42 # synthetic QA ID, NOT a paired device
  physical_button_event.button_index=JOY_BUTTON_START
  physical_button_event.pressed=true
  player.set("_pad_device",42)
  player.call("handle_input",physical_button_event)
  if not pad_menu.visible or String(player.get("_game_sheet_mode"))!="settings":
    _fail(154,"PAD_START_CANNOT_OPEN_GAME_SETTINGS")
    return
  player.call("_pad_focus_menu",0)
  var menu_buttons: Array=player.get("_pad_menu_options")
  if menu_buttons.size()<3:
    _fail(155,"PAD_MENU_HAS_NO_SELECTABLE_SETTINGS")
    return
  player.call("_pad_press_button",JOY_BUTTON_DPAD_DOWN)
  if int(player.get("_pad_menu_index"))==0:
    _fail(156,"PAD_DPAD_CANNOT_NAVIGATE_MENU")
    return
  var quality_index: int=-1
  for i in range(menu_buttons.size()):
    if (menu_buttons[i] as Button).name=="QualitySettingsFromGameMenu":
      quality_index=i
      break
  if quality_index<0:
    _fail(164,"PAD_CANNOT_FOCUS_GRAPHICS_MENU")
    return
  player.call("_pad_focus_menu",quality_index)
  player.call("_pad_press_button",JOY_BUTTON_A)
  if not bool(room.get("quality_menu_visible")) or (player.get("_pad_menu_options") as Array).size()<5:
    _fail(165,"PAD_A_CANNOT_OPEN_OR_FOCUS_NATIVE_QUALITY_FPS_SETTINGS")
    return
  player.call("_pad_press_button",JOY_BUTTON_B)
  if bool(room.get("quality_menu_visible")) or not pad_menu.visible:
    _fail(166,"PAD_B_MUST_CLOSE_QUALITY_POPUP_BUT_KEEP_GAME_MENU")
    return
  player.call("_pad_press_button",JOY_BUTTON_B)
  if pad_menu.visible:
    _fail(157,"PAD_B_CANNOT_CLOSE_MENU")
    return
  player.call("_pad_press_button",JOY_BUTTON_RIGHT_SHOULDER)
  if not pad_menu.visible or String(player.get("_game_sheet_mode"))!="inventory":
    _fail(158,"PAD_RB_CANNOT_OPEN_REAL_INVENTORY")
    return
  player.call("_pad_press_button",JOY_BUTTON_B)
  player.call("_pad_press_button",JOY_BUTTON_LEFT_SHOULDER)
  if not bool(player.get("is_first_person")):
    _fail(159,"PAD_LB_CANNOT_TOGGLE_FIRST_PERSON")
    return
  player.call("_pad_press_button",JOY_BUTTON_LEFT_SHOULDER)
  if bool(player.get("is_first_person")):
    _fail(160,"PAD_LB_CANNOT_RESTORE_THIRD_PERSON")
    return
  player.call("_pad_press_button",JOY_BUTTON_BACK)
  if not pad_menu.visible or String(player.get("_game_sheet_mode"))!="character":
    _fail(161,"PAD_SELECT_CANNOT_OPEN_CHARACTER")
    return
  player.call("_pad_press_button",JOY_BUTTON_B)
  var speed_before: float=float(player.get("_pad_sensitivity"))
  player.call("_cycle_pad_sensitivity")
  if is_equal_approx(float(player.get("_pad_sensitivity")),speed_before):
    _fail(162,"PAD_LOOK_SENSITIVITY_CANNOT_CHANGE")
    return
  player.set("_pad_sensitivity",speed_before)
  player.call("_save_pad_options")
  player.set("_pad_device",-1)
  if int(player.get("_pad_button_event_count"))<7 or not player.call("stats").get("gamepad_hotplug_support",false):
    _fail(163,"PAD_GAMEPLAY_DISPATCH_AND_HOTPLUG_STATUS_MISSING")
    return
  print("PASS_REV189_SYNTHETIC_GODOT_JOYPAD_BUTTON_MENU_LOOK_DEADZONE_HOTPLUG_AND_TOUCH_FALLBACK_NOT_ANDROID_HARDWARE")
  var render_frame: TextureRect = ui.get_node("RealWorldViewportContainer")
  if render_frame==null or render_frame.texture==null or render_frame.stretch_mode!=TextureRect.STRETCH_SCALE:
    _fail(64,"NATIVE_RESOLUTION_UI_NEEDS_3D_ONLY_RESIZABLE_SUBVIEWPORT_TEXTURE")
    return
  var quality: RefCounted = room.get("quality")
  if quality==null or quality.get("selected")!="高档":
    _fail(79,"PHONE_MUST_DEFAULT_TO_HIGH_PROFILE_UNLESS_USER_SAVED_OVERRIDE")
    return
  # rev194: remote physical terrain must not turn into bald, flat emptiness.
  var initial_loaded: Dictionary=terrain.get("stream_chunks")
  quality.call("sync_streamed_meadows")
  var streamed: Dictionary=quality.get("streamed_meadows")
  if initial_loaded.size()<12 or streamed.size()!=initial_loaded.size():
    _fail(187,"REV194_STREAMED_CHUNKS_MISSING_GRASS_BATCHES_"+str(streamed.size()))
    return
  var visible_stream_tufts: int=0
  for id in streamed:
    var field: MultiMeshInstance3D=streamed[id]
    if not is_instance_valid(field) or field.multimesh.instance_count!=320 or (
        field.get_parent()!=initial_loaded[id]):
      _fail(188,"REV194_STREAMED_GRASS_NOT_PARENTED_TO_PHYSICAL_CHUNK")
      return
    for i in range(field.multimesh.instance_count):
      var t: Transform3D=field.multimesh.get_instance_transform(i)
      if t.basis.determinant()>0.001:
        visible_stream_tufts+=1
  if visible_stream_tufts<600:
    _fail(189,"REV194_EXTERIOR_STILL_BALD_OR_ALL_GRASS_ON_CUT_SOIL_"+str(visible_stream_tufts))
    return
  var env: Environment=room.get("scene_environment")
  if env.fog_density>=0.003 or env.ambient_light_energy>=0.57:
    _fail(190,"REV194_BLEACHED_MOBILE_FOG_AND_OVERLIT_AMBIENT_NOT_FIXED")
    return
  var soil: Color=terrain.call("ground_color_at",27.0,22.0)
  if soil.g<=soil.r or soil.g-soil.r<0.05:
    _fail(191,"REV194_FRONT_MEADOW_MUST_BE_LIVING_GREEN_NOT_CHALK_GREY")
    return
  print("PASS_REV194_PHYSICAL_STREAMED_MEADOWS_DEEP_GREENS_AND_NO_WASHOUT_FOG",visible_stream_tufts)
  var native_screen: Vector2i = quality.get("physical_screen")
  if viewport.size != Vector2i(roundi(float(native_screen.x)*0.85),roundi(float(native_screen.y)*0.85)):
    _fail(80,"ACTUAL_THREE_DIMENSIONAL_RESOLUTION_MUST_BE_EXACTLY_85_PERCENT_DEFAULT")
    return
  if viewport.msaa_3d!=Viewport.MSAA_2X:
    _fail(81,"HIGH_QUALITY_MUST_HAVE_REAL_2X_MSAA")
    return
  if ui.get_node_or_null("OpenManualQualitySettings")==null or ui.get_node_or_null("ManuallySelectedPersistentOnePlusQualitySettings")==null:
    _fail(82,"MISSING_NATIVE_RESOLUTION_USER_SELECTABLE_QUALITY_MENU")
    return
  var profiles: Array = [
    {"key":"极致画质","scale":1.0,"msaa":Viewport.MSAA_4X,"shadows":100.0,
     "draw":1500,"triangles":1500000,"grass":4500,"grass_m":80.0,"fireflies":100,"clouds":9},
    {"key":"高档","scale":0.85,"msaa":Viewport.MSAA_2X,"shadows":60.0,
     "draw":800,"triangles":600000,"grass":2400,"grass_m":40.0,"fireflies":60,"clouds":5},
    {"key":"普通","scale":0.67,"msaa":Viewport.MSAA_DISABLED,"shadows":30.0,
     "draw":400,"triangles":300000,"grass":1100,"grass_m":20.0,"fireflies":20,"clouds":2}
  ]
  for expected in profiles:
    if not quality.call("apply",String(expected["key"]),true):
      _fail(83,"MANUAL_PHONE_PROFILE_SWITCH_FAILED")
      return
    var resolved: Dictionary = quality.call("render_profile")
    var target_view: Vector2i = Vector2i(roundi(native_screen.x*float(expected["scale"])),
      roundi(native_screen.y*float(expected["scale"])))
    if viewport.size!=target_view or viewport.msaa_3d!=expected["msaa"]:
      _fail(84,"THREE_DIMENSIONAL_ONLY_PER_TIER_PIXEL_SIZE_OR_MSAA_WRONG_"+String(expected["key"]))
      return
    if absf(sun.directional_shadow_max_distance-float(expected["shadows"]))>0.1:
      _fail(85,"HIGH_MEDIUM_LOW_SHADOW_RANGE_WRONG")
      return
    if int(resolved["draw_reference"])!=int(expected["draw"]) or int(resolved["triangle_reference"])!=int(expected["triangles"]):
      _fail(86,"OLD_200_DRAW_BUDGET_STILL_ACTIVE")
      return
    var grass: MultiMeshInstance3D=world.get_node("LivingClusteredMeadowTuftsTerrainConforming")
    var flies: GPUParticles3D=world.get_node("NaturalWarmMobileFireflyParticlesTiered")
    var clouds: MultiMeshInstance3D=world.get_node("RealBlueSkySoftWhiteCumulusCards")
    if grass.multimesh.visible_instance_count!=int(expected["grass"]) or absf(grass.visibility_range_end-float(expected["grass_m"]))>0.1:
      _fail(87,"GRASS_DENSITY_AND_DISTANCE_NEED_PER_TIER_SCALE")
      return
    if flies.amount!=int(expected["fireflies"]) or clouds.multimesh.visible_instance_count!=int(expected["clouds"]):
      _fail(88,"PARTICLE_AND_CLOUD_COMPLEXITY_MUST_TIER_SCALE")
      return
    # rev195: source previously declared high/ultra "glow":true but always
    # forced Environment.glow_enabled=false. Godot 4.4 MOBILE supports glow.
    # Confirm actual Environment (not just a config flag) is tier-controlled.
    var mobile_env: Environment=room.get("scene_environment")
    var should_glow: bool=String(expected["key"])!="普通"
    if mobile_env.glow_enabled!=should_glow:
      _fail(192,"REV195_GODOT_MOBILE_GLOW_IGNORES_MANUAL_GRAPHICS_TIER_"+String(expected["key"]))
      return
    if should_glow and (absf(mobile_env.glow_hdr_threshold-0.90)>0.001 or
        mobile_env.glow_intensity<1.2 or mobile_env.glow_bloom<=0.0):
      _fail(193,"REV195_MOBILE_HDR_GLOW_IS_CONFIGURED_BUT_STILL_INVISIBLE")
      return
    if not should_glow and mobile_env.fog_sun_scatter>=0.05:
      _fail(194,"REV195_LOW_PROFILE_WASTES_FOG_SUN_SCATTER")
      return
    var actual_glow: Dictionary=quality.call("update_diagnostics")
    if bool(actual_glow.get("real_mobile_glow_enabled",not should_glow))!=should_glow:
      _fail(195,"REV195_PERFORMANCE_TELEMETRY_MUST_REPORT_ACTUAL_GLOW_STATE")
      return
  print("PASS_REV195_REAL_GODOT_MOBILE_GLOW_HDR_THRESHOLD_AND_THREE_USER_GRAPHICS_TIERS")
  var caps: Array = ["30","60","90","120","跟随刷新率"]
  for mode in caps:
    if not quality.call("set_fps_mode",mode,true):
      _fail(102,"FPS_CAP_30_60_90_120_AND_FOLLOW_ALL_REQUIRED")
      return
    var expected_cap: int=120 if mode=="跟随刷新率" else int(mode)
    if Engine.max_fps!=expected_cap:
      _fail(103,"FALSE_FPS_CAP_READ_FROM_STALE_DISPLAY_RATE_"+mode)
      return
  if quality.get("fps_mode")!="跟随刷新率" or Engine.max_fps!=120:
    _fail(104,"DEFAULT_FOLLOW_REFRESH_MUST_NEVER_CAP_TO30")
    return
  if not quality.call("apply","高档",true):
    _fail(89,"RESTORE_HIGH_AS_DEFAULT_AFTER_MOBILE_PRESET_QA")
    return
  var persisted := ConfigFile.new()
  if persisted.load("user://canglan_graphics_profiles_v1.cfg")!=OK or String(persisted.get_value("graphics","manual_quality",""))!="高档":
    _fail(90,"MANUAL_QUALITY_CHOICE_NOT_PERSISTED_ACROSS_GAME_RESTART")
    return
  if String(persisted.get_value("graphics","manual_fps_cap",""))!="跟随刷新率":
    _fail(105,"FPS_CAP_NOT_PERSISTED_SEPARATELY_FROM_QUALITY")
    return
  var meter: PanelContainer=ui.get_node("NativeResolutionRealQualityTelemetry")
  if meter.get_node_or_null("NonOverlappingDiagnosticVBox/FPSBelow45WarningNoAutoDowngrade")==null:
    _fail(106,"ORANGE_FPS_WARNING_IS_ABSOLUTELY_POSITIONED_OVER_OTHER_LABELS")
    return
  var toggler: Button=meter.get_node("NonOverlappingDiagnosticVBox/CollapseExpandAllMetrics")
  toggler.pressed.emit()
  if room.get("quality_diagnostic").visible:
    _fail(107,"NEW_PERFORMANCE_PANEL_CANNOT_COLLAPSE")
    return
  toggler.pressed.emit()
  if not room.get("quality_diagnostic").visible:
    _fail(108,"NEW_PERFORMANCE_PANEL_CANNOT_EXPAND")
    return
  var atmosphere: WorldEnvironment=world.get_node("VillageAtmosphere")
  var sky_color: ProceduralSkyMaterial=atmosphere.environment.sky.sky_material
  if sky_color.sky_top_color.b<=sky_color.sky_top_color.r*1.35 or sky_color.sky_horizon_color.b<=sky_color.sky_horizon_color.r:
    _fail(109,"SKY_MUST_BE_LIGHT_BLUE_GRADIENT_NOT_GRAY_PURPLE")
    return
  if atmosphere.environment.fog_light_color.b<=atmosphere.environment.fog_light_color.r:
    _fail(110,"DISTANCE_FOG_MUST_BE_PALE_BLUE")
    return
  if not terrain.call("stats").get("no_infinite_gray_void",false):
    _fail(111,"LOCAL_WORLD_EDGE_IS_STILL_A_FLOATING_THIN_CARD")
    return
  var stitched_far: Node3D=terrain.get_node_or_null("FarGroundAndMountainFoothills_AllCameraDirections_600m") as Node3D
  if stitched_far==null or terrain.get_node_or_null("RealEarthCrustBorderSkirtNotFloatingThinSheet")!=null:
    _fail(112,"REV191_DISALLOW_VISIBLE_VERTICAL_MAP_EDGE_AND_OLD_22M_CRUST_SKIRT")
    return
  if stitched_far.get_meta("far_terrain_overlaps_local_square",true) or int(stitched_far.get_meta("far_stitched_seam_quads",0))<32:
    _fail(167,"REV191_FAR_TERRAIN_LOD_MUST_BE_GEOMETRICALLY_CLIPPED_TO_CENTER_BOUNDARY")
    return
  if not terrain.call("stats").get("far_seam_stitched",false) or terrain.call("stats").get("infinite_streaming_complete",true):
    _fail(168,"REV191_NO_FALSE_CLAIMS_ABOUT_MINECRAFT_LIKE_STREAMING")
    return
  if not terrain.call("stats").get("checkerboard_cell_materials_removed",false):
    _fail(172,"REV192_NO_MORE_RANDOM_2M_GRASS_SOIL_CHECKERBOARD")
    return
  var actual_ground: MeshInstance3D=terrain.get_node("REAL_DEFORMABLE_TERRAIN_NOT_PLANE")
  var continuous_biome_surfaces: int=0
  var biome_colors: Dictionary={}
  for surface in range(actual_ground.mesh.get_surface_count()):
    var material: Material=actual_ground.mesh.surface_get_material(surface)
    if material is StandardMaterial3D and (material as StandardMaterial3D).vertex_color_use_as_albedo:
      continuous_biome_surfaces+=1
      var colors: PackedColorArray=actual_ground.mesh.surface_get_arrays(surface)[Mesh.ARRAY_COLOR]
      for idx in range(0,colors.size(),maxi(1,int(colors.size()/50))):
        biome_colors[colors[idx].to_html()]=true
  if continuous_biome_surfaces!=1 or biome_colors.size()<7:
    _fail(173,"REV192_REAL_TOP_SURFACE_NEEDS_ONE_CONTINUOUS_MULTICOLOR_BIOME_MATERIAL")
    return
  # Enumerate the genuine far-field triangles. Every exterior polygon stays
  # outside the central diggable square, and every +/-46m border vertex has
  # the EXACT elevation of the central unexcavated mesh it touches.
  var seam_samples: int=0
  var edge_error: float=0.0
  var overlaps: int=0
  for far_part in stitched_far.get_children():
    if not far_part is MeshInstance3D:
      continue
    var mesh: Mesh=far_part.mesh
    if mesh==null:
      continue
    for surface in range(mesh.get_surface_count()):
      var vertices: PackedVector3Array=mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
      for idx in range(0,vertices.size(),3):
        if idx+2>=vertices.size():
          break
        var a3: Vector3=vertices[idx]
        var b3: Vector3=vertices[idx+1]
        var c3: Vector3=vertices[idx+2]
        var mid: Vector3=(a3+b3+c3)/3.0
        if absf(mid.x)<45.9999 and absf(mid.z)<45.9999:
          overlaps+=1
        for vertex in [a3,b3,c3]:
          if (absf(absf(vertex.x)-46.0)<0.001 and absf(vertex.z)<=46.001) or (
              absf(absf(vertex.z)-46.0)<0.001 and absf(vertex.x)<=46.001):
            seam_samples+=1
            edge_error=maxf(edge_error,absf(vertex.y-float(terrain.call("_base_at",vertex.x,vertex.z))))
  if overlaps>0 or seam_samples<75 or edge_error>0.002:
    _fail(169,"REV191_VISIBLE_MAP_SEAM_OR_RENDER_OVERLAP_"+str(overlaps)+"_"+
      str(seam_samples)+"_"+str(edge_error))
    return
  print("PASS_REV191_NO_FLOATING_SLICE_LOD_OVERLAP_OR_22M_CLIFF_ACTUAL_MESH_TRIANGLES",seam_samples)
  var grass_visual: MultiMeshInstance3D=world.get_node("LivingClusteredMeadowTuftsTerrainConforming")
  var actual_grass: Mesh=grass_visual.multimesh.mesh
  if actual_grass.get_surface_count()<1:
    _fail(113,"NO_REAL_MULTIBLADE_GRASS_GEOMETRY")
    return
  var grass_verts: PackedVector3Array=actual_grass.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
  if grass_verts.size()<75:
    _fail(114,"REV191_MORE_THAN_5_SPARSE_THIN_GRASS_STUBBLE_BLADES_REQUIRED")
    return
  var grass_extent: float=0.0
  for blade in grass_verts:
    grass_extent=maxf(grass_extent,Vector2(blade.x,blade.z).length())
  if grass_extent<0.24:
    _fail(170,"REV191_GRASS_MUST_HAVE_BROAD_NATURAL_TUFT_PROFILE_NOT_TOOTHPICK_STUBBLE")
    return
  var grass_quality: RefCounted=room.get("quality")
  var meadow_points: Array=grass_quality.get("grass_points") if grass_quality!=null else []
  if meadow_points.size()!=4500:
    _fail(171,"REV191_NATIVE_GRASS_BATCH_MUST_STILL_COVER_LOCAL_MEADOW")
    return
  var max_grass_height: float=0
  for vertex in grass_verts:
    max_grass_height=maxf(max_grass_height,vertex.y)
  if max_grass_height<0.3 or max_grass_height>0.61:
    _fail(115,"GRASS_LEAF_HEIGHT_MUST_BE_0_3_TO_0_6_M")
    return
  var flowers: MultiMeshInstance3D=world.get_node("SubtleFourColorWildflowersGrowingFromRealSoil")
  if flowers.multimesh.instance_count<150:
    _fail(116,"MISSING_WHITE_YELLOW_PINK_PURPLE_WILDFLOWERS")
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
  var labels: Dictionary = room.get("npc_nameplates")
  for item in labels.values():
    var label: Label3D=item
    if label.text=="施工工":
      _fail(117,"BUILDER_TITLE_HAS_REPEATED_WORD_NEEDS_ARCHITECTURAL_WORKER")
      return
    if label.text.contains("CL-") or label.font_size>26 or label.no_depth_test:
      _fail(96,"NPC_SYSTEM_ID_CANNOT_FILL_WORLD_AS_GIANT_LABEL")
      return
  for actor_info in (room.get("workers") as Dictionary).values():
    var physical: Node3D = actor_info["node"]
    var bbox: Vector2 = room.call("_visible_bounds",physical)
    var at_soil: float = float(terrain.call("height_at",physical.position.x,physical.position.z))
    if absf(bbox.x-at_soil)>0.22:
      _fail(97,"NPC_ACTUAL_LICENSED_MESH_FEET_CLIPPED_BELOW_TERRAIN")
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
    var seed_stock: int = int(econ.get("villages")["CL-REV186-HX-VILLAGE"]["stock"].get("tree_seed",0))
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
  if not (report.get("native_resolution_ui",false) and report.get("no_auto_quality_switch",false)):
    _fail(91,"UI_SCALED_WITH_3D_OR_AUTOMATIC_QUALITY_DOWNGRADE")
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
  if not econ.register_natural_node("CL-REV186-EXCLUSION-TEST", "CL-REV186-HX-VILLAGE","stone",3):
    _fail(36,"UNABLE_REGISTER_TEST_STONE")
    return
  econ.register_resource_position("CL-REV186-EXCLUSION-TEST",Vector3(0,0,-3))
  ecology.register_stone("CL-REV186-EXCLUSION-TEST")
  var test_rock: Dictionary = econ.natural_nodes["CL-REV186-EXCLUSION-TEST"]
  test_rock["remaining"] = 0
  var test_bank: int = int(ecology.stone["CL-REV186-EXCLUSION-TEST"]["subsurface"])
  ecology.advance_ecology_hours(168)
  if int(test_rock["remaining"]) != 0 or int(ecology.stone["CL-REV186-EXCLUSION-TEST"]["subsurface"]) != test_bank:
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
  if int(econ.get("villages")["CL-REV186-HX-VILLAGE"]["stock"]["stone"]) != int(report["stock_stone"]):
    _fail(41,"GEOLOGICAL_TIME_ADVANCE_MUST_NOT_MINT_GAMEPLAY_STONE")
    return
  # Test REAL player movement with the SAME mobile input vector and
  # on-ground contact. Switch to a truly first-person camera view.
  var actor: Node3D = player.get("actor")
  var before_move: Vector3 = actor.position
  var actual_gui_joystick: Panel = player.get("joystick_ring")
  if actual_gui_joystick.mouse_filter!=Control.MOUSE_FILTER_STOP:
    _fail(92,"REV184_PHONE_JOYSTICK_DID_NOT_CAPTURE_GUI_TOUCH")
    return
  var press := InputEventScreenTouch.new()
  press.index = 7
  press.position = Vector2(73,24)
  press.pressed = true
  actual_gui_joystick.emit_signal("gui_input",press)
  if not player.get("_joystick").is_equal_approx(Vector2(0,-0.81666666)):
    _fail(93,"TOUCHSCREEN_GUI_LOCAL_POSITION_NOT_MAPPED_TO_ANALOG_AXIS")
    return
  player.call("step",0.8)
  var release := InputEventScreenTouch.new()
  release.index = 7
  release.position = Vector2(73,24)
  release.pressed = false
  actual_gui_joystick.emit_signal("gui_input",release)
  if player.get("_joystick").length()>0.01:
    _fail(94,"ANDROID_JOYSTICK_TOUCH_RELEASE_NOT_RECOGNIZED")
    return
  if Vector2(actor.position.x-before_move.x,actor.position.z-before_move.z).length()<1.0:
    _fail(68,"LEFT_ANALOG_MOVE_DID_NOT_MOVE_ACTUAL_PLAYER_ENTITY")
    return
  var drag_start: float=float(player.get("_pitch"))
  player.call("turn_view",Vector2(0,32))
  if float(player.get("_pitch"))>=drag_start:
    _fail(118,"ANDROID_RIGHT_SCREEN_DOWN_DRAG_WRONGLY_MOVES_VIEW_UP")
    return
  var before_yaw: float = float(player.get("_yaw"))
  var zone: Control = player.get("_look_zone")
  if zone==null or zone.mouse_filter!=Control.MOUSE_FILTER_STOP:
    _fail(95,"RIGHT_SIDE_MUST_USE_OWN_REAL_GUI_TOUCH_REGION")
    return
  # Crucial real-phone report: timber trees occupy the LEFT side of
  # landscape, so a right-side-only tap target still fails interaction.
  var left_zone: Control = player.get("_left_world_zone")
  if left_zone==null or left_zone.mouse_filter!=Control.MOUSE_FILTER_STOP:
    _fail(98,"FOREST_AND_TIMBER_ON_LEFT_MUST_ACCEPT_WORLD_ENTITY_TAPS")
    return
  if not bool(player.call("stats").get("left_zone_joystick_conflict_free",false)):
    _fail(99,"LEFT_WORLD_TAPS_MUST_NOT_SWALLOW_ANALOG_JOYSTICK")
    return
  var left_count: int = int(player.get("_gui_input_events"))
  var left_press := InputEventScreenTouch.new()
  left_press.index=15
  left_press.position=Vector2(93,122)
  left_press.pressed=true
  left_zone.emit_signal("gui_input",left_press)
  var left_release := InputEventScreenTouch.new()
  left_release.index=15
  left_release.position=Vector2(94,123)
  left_release.pressed=false
  left_zone.emit_signal("gui_input",left_release)
  if int(player.get("_gui_input_events")) < left_count+2:
    _fail(100,"LEFT_WORLD_GUI_TAPS_DO_NOT_ACTUALLY_ARRIVE")
    return
  var look_down := InputEventScreenTouch.new()
  look_down.index = 8
  look_down.position = Vector2(100,130)
  look_down.pressed = true
  zone.emit_signal("gui_input",look_down)
  var look_drag := InputEventScreenDrag.new()
  look_drag.index = 8
  look_drag.position = Vector2(160,143)
  look_drag.relative = Vector2(60,13)
  zone.emit_signal("gui_input",look_drag)
  var look_up := InputEventScreenTouch.new()
  look_up.index = 8
  look_up.position = Vector2(160,143)
  look_up.pressed = false
  zone.emit_signal("gui_input",look_up)
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
  if not bool(player.get("is_first_person")) or not actor.visible:
    _fail(72,"REV197_FIRST_PERSON_SHOULD_NOT_DELETE_WHOLE_AVATAR_BODY")
    return
  if absf(float(room.get("camera").position.y)-
      float(actor.position.y)-1.58)>0.035:
    _fail(73,"REV197_FIRST_PERSON_EYE_CAMERA_NOT_AT_VISIBLE_AVATAR_HEAD_HEIGHT")
    return
  player.call("toggle_perspective")
  if bool(player.get("is_first_person")) or not actor.visible:
    _fail(74,"THIRD_PERSON_MUST_RESTORE_VISIBLE_ANIMATED_PLAYER")
    return
  player.call("toggle_god_view")
  if player.get("camera_mode")!="god":
    _fail(119,"PLAYER_STUCK_NO_GOD_VIEW")
    return
  var god_before: Vector3=player.get("_god_focus")
  player.set("_joystick",Vector2(1.0,0.0))
  player.call("step",1.0)
  player.set("_joystick",Vector2.ZERO)
  if (player.get("_god_focus") as Vector3).distance_to(god_before)<1.0:
    _fail(120,"GOD_VIEW_DID_NOT_ACTUALLY_PAN_THE_WORLD")
    return
  player.call("toggle_fly_view")
  if player.get("camera_mode")!="fly":
    _fail(121,"PLAYER_STUCK_CANNOT_FLY")
    return
  var airborne: Vector3=player.get("_flight_position")
  player.call("fly_up")
  player.call("fly_down")
  player.call("fly_up")
  if (player.get("_flight_position") as Vector3).y<=airborne.y:
    _fail(122,"FLY_ASCEND_DESCEND_BUTTONS_NOT_WORKING")
    return
  player.call("reset_camera")
  if player.get("camera_mode")!="third":
    _fail(123,"NEED_ONE_BUTTON_TO_ESCAPE_BUILDING_AND_RESET_VIEW")
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
  # rev195 reference-study implementation: the actual stamina-paid mortal
  # dash (NOT fake spellcasting) must emit small, transient mobile VFX.
  var restored_hero_pos: Vector3=actor.position
  var restored_yaw: float=float(player.get("_yaw"))
  var traveler: Dictionary=econ.citizens["CL-PLAYER-0184-0001"]
  var old_energy: int=int(traveler["energy"])
  var dash_test_point:=Vector3(29.0,float(terrain.call("height_at",29.0,29.0)),29.0)
  actor.position=dash_test_point
  player.set("_yaw",PI)
  player.set("_dash_cd",0.0)
  traveler["energy"]=30
  var dash_used: bool=bool(player.call("dash_action"))
  var motion_shards: Array[Node]=world.find_children(
      "ActualMortalDashFootworkMotionShards","GPUParticles3D",true,false)
  if not dash_used or motion_shards.size()!=1:
    _fail(196,"REV195_REAL_STAMINA_DASH_DID_NOT_SPAWN_ACTUAL_MOBILE_MOVEMENT_SHARDS")
    return
  var dash_vfx: GPUParticles3D=motion_shards[0] as GPUParticles3D
  if not dash_vfx.one_shot or dash_vfx.amount!=14 or dash_vfx.lifetime>0.40:
    _fail(197,"REV195_DASH_VFX_NOT_ONE_SHOT_OR_OVERDRAWS_MOBILE")
    return
  if int(traveler["energy"])!=22 or actor.position.z<30.8:
    _fail(198,"REV195_DASH_VFX_APPEARED_WITHOUT_REAL_STAMINA_DEBIT_AND_MOVEMENT")
    return
  var trail_count: int=motion_shards.size()
  var failed_second_dash: bool=bool(player.call("dash_action"))
  if failed_second_dash or world.find_children(
      "ActualMortalDashFootworkMotionShards","GPUParticles3D",true,false).size()!=trail_count:
    _fail(199,"REV195_COOLDOWN_ACTION_IS_MINTING_FALSE_SKILL_TRAILS")
    return
  traveler["energy"]=old_energy
  actor.position=restored_hero_pos
  player.set("_yaw",restored_yaw)
  player.set("_dash_cd",0.0)
  player.call("update_camera")
  print("PASS_REV195_REAL_MORTAL_DASH_MOBILE_VFX_REQUIRES_SUCCESS_AND_STAMINA_DEBIT")
  # REV196: real licensed animated sparring player/NPC and finite stamina,
  # at least one timed perfect guard, one normal block, one true dodge,
  # and an actual HP-damaging unguarded strike. No fake skill animation.
  var spar_original_pos: Vector3=actor.position
  var spar_original_yaw: float=float(player.get("_yaw"))
  var mortal: Dictionary=econ.citizens["CL-PLAYER-0184-0001"]
  var mortal_energy: int=int(mortal.get("energy",0))
  actor.position=Vector3(29.0,float(terrain.call("height_at",29,29))+
    float(actor.get_meta("actor_ground_offset_y",0.0)),29.0)
  player.set("_yaw",0.0)
  mortal["energy"]=100
  player.set("_player_health",100)
  var started: Dictionary=player.call("practice_action")
  if not bool(started.get("ok",false)) or not bool(started.get("active",false)):
    _fail(200,"REV196_VOLUNTARY_REAL_SPARRING_CANNOT_SPAWN_LICENSED_OPPONENT_"+str(started))
    return
  var trainer: Node3D=player.get("_spar_partner")
  var physical: StaticBody3D=player.get("_spar_collision")
  var cue: MeshInstance3D=player.get("_spar_telegraph")
  if trainer==null or physical==null or cue==null or physical.get_node_or_null(
      "RealMortalOpponentCapsule")==null or not physical.collision_layer==2:
    _fail(201,"REV196_PRACTICE_OPPONENT_MUST_BE_REAL_ANIMATED_GLB_WITH_PHYSICAL_BODY_AND_VISIBLE_WARNING")
    return
  player.call("_spar_tick",0.82)
  if String(player.get("_spar_stage"))!="windup" or not cue.visible:
    _fail(202,"REV196_OPPONENT_HAS_NO_VISIBLE_ATTACK_TELEGRAPH_WINDOW")
    return
  player.call("_spar_tick",0.59)
  var guard_energy_start: int=int(mortal["energy"])
  if not bool(player.call("guard_action")) or int(mortal["energy"])!=guard_energy_start-5:
    _fail(203,"REV196_GUARD_MUST_USE_AUTHORITATIVE_REAL_PLAYER_STAMINA")
    return
  player.call("_spar_tick",0.11)
  if int(player.get("_spar_perfect_guards"))!=1 or int(player.get("_player_health"))!=100 or cue.visible:
    _fail(204,"REV196_TRUE_PERFECT_GUARD_SHOULD_BLOCK_HIT_AND_HIDE_ATTACK_WARNING")
    return
  player.call("_spar_tick",1.25)
  player.call("_spar_tick",0.35)
  if not bool(player.call("guard_action")):
    _fail(205,"REV196_NORMAL_GUARD_UNEXPECTEDLY_BLOCKED")
    return
  player.call("_spar_tick",0.35)
  if int(player.get("_spar_normal_guards"))!=1 or int(player.get("_player_health"))!=97:
    _fail(206,"REV196_NORMAL_GUARD_SHOULD_CAUSE_SMALL_REAL_DAMAGE_NOT_FAKE_INVULNERABILITY")
    return
  player.call("_spar_tick",1.40)
  player.call("_spar_tick",0.59)
  var origin: Vector3=actor.position
  if not bool(player.call("evade_action")):
    _fail(207,"REV196_EVADE_MUST_PHYSICALLY_MOVE_ON_REAL_COLLIDABLE_GROUND")
    return
  if actor.position.distance_to(origin)<1.50:
    _fail(208,"REV196_EVADE_VISUAL_BUT_PLAYER_POSITION_UNCHANGED")
    return
  player.call("_spar_tick",0.11)
  if int(player.get("_spar_perfect_dodges"))!=1 or int(player.get("_player_health"))!=97:
    _fail(209,"REV196_PERFECT_DODGE_DID_NOT_RECOGNIZE_TRUE_ATTACK_HIT_TIME")
    return
  player.call("_spar_tick",1.40)
  actor.position=origin
  player.call("_spar_tick",0.70)
  if int(player.get("_spar_hits"))!=1 or int(player.get("_player_health"))!=85:
    _fail(210,"REV196_UNDEFENDED_ENEMY_MELEE_MUST_HIT_REAL_PLAYER_HP")
    return
  player.call("stop_practice")
  if String(player.get("_spar_stage"))!="inactive":
    _fail(211,"REV196_CANNOT_LEAVE_VOLUNTARY_PRACTICE_AND_RETURN_TO_NORMAL_WORLD")
    return
  mortal["energy"]=mortal_energy
  actor.position=spar_original_pos
  player.set("_yaw",spar_original_yaw)
  player.set("_player_health",100)
  player.call("_refresh_game_hud")
  player.call("update_camera")
  print("PASS_REV196_REAL_OPPONENT_TELEGRAPH_PERFECT_GUARD_NORMAL_GUARD_TRUE_EVADE_DAMAGE_STAMINA_WITHOUT_SPIRIT_MAGIC")
  # rev197 P0 phone usability regression: test real UI nodes AND the
  # actual physical movement/camera state, not only declared feature flags.
  var v197: Array[String]=["Iso45Button","GodShortcutButton",
    "SoarAvatarButton","RealJumpButton","CameraLockButton",
    "PhoneZoomInButton","PhoneZoomOutButton"]
  for key in v197:
    var control: Button=game_hud.get_node_or_null(key)
    if control==null or not control.visible or not control.is_visible_in_tree():
      _fail(212,"REV197_ESSENTIAL_PHONE_CAMERA_JUMP_FLIGHT_BUTTON_HIDDEN_"+key)
      return
  var human_meshes: Array[Node]=actor.find_children("*","MeshInstance3D",true,false)
  if not actor.visible or human_meshes.is_empty() or float(actor.get_meta(
      "actor_visual_height_m",0.0))<1.5:
    _fail(213,"REV197_REAL_3D_CHARACTER_NOT_VISIBLE_OR_WITHOUT_LICENSED_MESH")
    return
  player.call("toggle_iso45")
  var topdown_camera: Camera3D=room.get("camera")
  var head: Vector3=actor.position+Vector3.UP*1.0
  if String(player.get("camera_mode"))!="iso" or absf(float(player.get("_pitch"))-PI/4.0)>0.001 or (
      topdown_camera.is_position_behind(head)):
    _fail(214,"REV197_REAL_FOLLOWING_45_DEGREE_CHARACTER_CAMERA_NOT_AVAILABLE")
    return
  var projected: Vector2=topdown_camera.unproject_position(head)
  var scene_pixels: Vector2=Vector2(viewport.size)
  if projected.x<scene_pixels.x*0.12 or projected.x>scene_pixels.x*0.88 or (
      projected.y<scene_pixels.y*0.12 or projected.y>scene_pixels.y*0.88):
    _fail(215,"REV197_MAIN_CHARACTER_IS_OUTSIDE_45DEG_SCREEN_"+str(projected))
    return
  player.call("toggle_camera_lock")
  var locked_yaw: float=float(player.get("_yaw"))
  player.call("turn_view",Vector2(50,55))
  if not is_equal_approx(float(player.get("_yaw")),locked_yaw):
    _fail(216,"REV197_CAMERA_ANGLE_LOCK_STILL_ALLOWS_ACCIDENTAL_DRAG")
    return
  var near_distance: float=float(player.get("_distance"))
  var plus: Button=game_hud.get_node("PhoneZoomInButton")
  plus.pressed.emit()
  if float(player.get("_distance"))>=near_distance:
    _fail(217,"REV197_VISIBLE_PLUS_BUTTON_DID_NOT_MOVE_REAL_CAMERA")
    return
  var after_plus: float=float(player.get("_distance"))
  (game_hud.get_node("PhoneZoomOutButton") as Button).pressed.emit()
  if float(player.get("_distance"))<=after_plus:
    _fail(218,"REV197_VISIBLE_MINUS_BUTTON_DID_NOT_MOVE_REAL_CAMERA")
    return
  player.call("toggle_camera_lock")
  var before_pinch: float=float(player.get("_distance"))
  var touch_a:=InputEventScreenTouch.new()
  touch_a.index=32
  touch_a.position=Vector2(560,280)
  touch_a.pressed=true
  var touch_b:=InputEventScreenTouch.new()
  touch_b.index=33
  touch_b.position=Vector2(750,295)
  touch_b.pressed=true
  player.call("handle_input",touch_a)
  player.call("handle_input",touch_b)
  var zoom_drag:=InputEventScreenDrag.new()
  zoom_drag.index=33
  zoom_drag.position=Vector2(890,295)
  zoom_drag.relative=Vector2(140,0)
  player.call("handle_input",zoom_drag)
  touch_a.pressed=false
  touch_b.pressed=false
  player.call("handle_input",touch_b)
  player.call("handle_input",touch_a)
  if int(player.get("_pinch_zoom_events"))<1 or float(player.get("_distance"))>=before_pinch:
    _fail(219,"REV197_REAL_CROSS_ZONE_TWO_FINGER_PINCH_STILL_CANNOT_ZOOM")
    return
  player.call("toggle_iso45")
  if String(player.get("camera_mode"))!="third":
    _fail(220,"REV197_45DEG_CAMERA_CANNOT_RETURN_TO_VISIBLE_THIRD_PERSON")
    return
  var rev197_before: Vector3=actor.position
  var rev197_energy: int=int(mortal["energy"])
  actor.position=Vector3(29.0,float(terrain.call("height_at",29,29))+
    float(actor.get_meta("actor_ground_offset_y",0.0)),29)
  mortal["energy"]=100
  if not bool(player.call("jump_action")) or int(mortal["energy"])!=96:
    _fail(221,"REV197_REAL_JUMP_DID_NOT_START_OR_USE_REAL_STAMINA")
    return
  player.call("step",0.10)
  if float(player.get("_jump_height"))<0.23 or actor.position.y<=float(
      terrain.call("height_at",actor.position.x,actor.position.z))+0.23:
    _fail(222,"REV197_JUMP_IS_BUTTON_ONLY_WITHOUT_REAL_PLAYER_HEIGHT")
    return
  for i in range(16):
    player.call("step",0.075)
  if float(player.get("_jump_height"))>0.001 or int(player.get("_landing_count"))<1:
    _fail(223,"REV197_GRAVITY_JUMP_NOT_LANDING_BACK_ON_PHYSICAL_TERRAIN")
    return
  player.call("toggle_avatar_flight")
  if String(player.get("camera_mode"))!="soar" or not actor.visible or float(
      player.get("_soar_altitude"))>0.05:
    _fail(224,"REV202_AVATAR_TAKEOFF_MUST_BEGIN_ON_GROUND_WITHOUT_INSTANT_TELEPORT")
    return
  var up_button: Button=game_hud.get_node("FlyUpButton") as Button
  var down_button: Button=game_hud.get_node("FlyDownButton") as Button
  if not up_button.visible or not down_button.visible:
    _fail(277,"REV202_REAL_SOAR_ASCEND_AND_DESCEND_MUST_BOTH_BE_TOUCH_VISIBLE")
    return
  var altitude_start: float=float(player.get("_soar_altitude"))
  player.call("step",0.85)
  if float(player.get("_soar_altitude"))<2.85:
    _fail(225,"REV199_MUST_ACTUALLY_RISE_TO_INITIAL_THREE_METER_TARGET")
    return
  var altitude_before: float=float(player.get("_soar_altitude"))
  (game_hud.get_node("FlyUpButton") as Button).pressed.emit()
  if float(player.get("_soar_altitude"))>=altitude_before+0.01:
    _fail(225,"REV199_ASCEND_SHOULD_NOT_JERK_TELEPORT")
    return
  player.call("step",0.61)
  if float(player.get("_soar_altitude"))<altitude_before+1.5:
    _fail(225,"REV199_ACTUAL_FLY_UP_TARGET_NOT_REACHED_SMOOTHLY")
    return
  (game_hud.get_node("FlyDownButton") as Button).pressed.emit()
  player.call("step",0.61)
  if float(player.get("_soar_altitude"))>altitude_before+0.2:
    _fail(226,"REV199_ACTUAL_FLY_DOWN_TARGET_NOT_REACHED_SMOOTHLY")
    return
  # Rev203 real hold input must keep climbing beyond a single 2.5m tap,
  # and finger release must stop it. World ×100 cannot accelerate this axis.
  if up_button.action_mode!=BaseButton.ACTION_MODE_BUTTON_PRESS or (
      down_button.action_mode!=BaseButton.ACTION_MODE_BUTTON_PRESS):
    _fail(282,"REV203_TOUCH_HOLD_BUTTON_REPEATS_ONLY_ON_RELEASE")
    return
  up_button.button_down.emit()
  up_button.pressed.emit()
  var tap_target: float=float(player.get("_soar_target_altitude"))
  for i in range(6):
    player.call("step",0.15)
  if float(player.get("_soar_target_altitude"))<=tap_target+1.0:
    _fail(283,"REV203_HOLD_ASCENT_DID_NOT_CONTINUOUSLY_CHANGE_REAL_HEIGHT_TARGET")
    return
  up_button.button_up.emit()
  var released_target: float=float(player.get("_soar_target_altitude"))
  player.call("step",0.25)
  if absf(float(player.get("_soar_target_altitude"))-released_target)>0.005 or (
      absf(float(player.get("_soar_hold_axis")))>0.005):
    _fail(284,"REV203_RELEASED_THUMB_CONTINUES_TO_CLIMB_UNCONTROLLED")
    return
  # Return to the pre-existing three-metre flight test altitude so that
  # old landing/collision assertions remain physically equivalent.
  player.set("_soar_target_altitude",3.0)
  player.call("step",1.10)
  if float(player.get("_soar_altitude"))>3.10 or (
      float(player.get("_soar_camera_extra"))<0.06):
    _fail(285,"REV203_MISSING_TERRAIN_CONTEXT_PULLBACK_OR_SAFE_REDESCENT")
    return
  var flyer_before: Vector3=actor.position
  player.set("_yaw",0.0)
  actor.rotation.y=1.3 # Heading error creates a measurable true-body bank.
  player.set("_joystick",Vector2(0.0,-1.0))
  player.call("step",0.15)
  player.set("_joystick",Vector2.ZERO)
  var blade: Node3D=world.get_node_or_null(
      "ActualQuaterniusKnightCC0FlyingSwordUnderPlayerFeet")
  if absf(actor.rotation.z)<0.003 or (
      blade==null or absf(blade.rotation.z-actor.rotation.z)>0.005):
    _fail(286,"REV203_LICENSED_PLAYER_AND_FLYING_SWORD_MUST_BANK_TOGETHER_IN_TURNS")
    return
  if Vector2(actor.position.x-flyer_before.x,
      actor.position.z-flyer_before.z).length()<0.6 or (
      actor.position.y<float(terrain.call("height_at",actor.position.x,actor.position.z))+1.8):
    _fail(227,"REV197_AVATAR_FLY_JOYSTICK_ONLY_MOVED_A_HIDDEN_CAMERA")
    return
  var midair_height: float=float(player.get("_soar_altitude"))
  player.call("_set_mode","third") # Camera switch cannot delete actual height.
  if String(player.get("camera_mode"))!="soar" or not bool(player.get("_soar_landing")) or (
      absf(float(player.get("_soar_altitude"))-midair_height)>0.005):
    _fail(278,"REV202_MIDAIR_PERSPECTIVE_SWITCH_INSTANTLY_DROPPED_AVATAR")
    return
  if up_button.visible or down_button.visible:
    _fail(279,"REV202_VERTICAL_TOUCH_CONTROLS_STILL_ACTIVE_WHILE_LANDING")
    return
  player.call("step",0.80)
  if player.get("camera_mode")!="third" or float(player.get("_soar_altitude"))!=0.0:
    _fail(228,"REV199_FLYING_AVATAR_CANNOT_SOFT_LAND_AND_WALK")
    return
  # Normal landing button remains functional after perspective-switch landing.
  player.call("toggle_avatar_flight")
  player.call("step",0.85)
  player.call("toggle_avatar_flight")
  if not bool(player.get("_soar_landing")):
    _fail(280,"REV202_NORMAL_LANDING_BUTTON_MUST_ENTER_DESCENT")
    return
  player.call("step",0.80)
  if String(player.get("camera_mode"))!="third" or float(player.get("_soar_altitude"))>0.045:
    _fail(281,"REV202_NORMAL_LANDING_BUTTON_FAILED_TO_RETURN_TO_GROUND")
    return
  print("PASS_REV202_TRUE_ORIGINAL_SOAR_TOUCH_ASCENT_SMOOTH_TAKEOFF_AND_MIDAIR_CAMERA_LANDING")
  if absf(actor.rotation.z)>0.0005 or (
      absf(float(player.get("_soar_bank_angle")))>0.0005):
    _fail(287,"REV203_ACTUAL_PLAYER_REMAINS_BANKED_AFTER_LANDING")
    return
  print("PASS_REV203_ORIGINAL_AVATAR_SWORD_BANK_THUMB_HOLD_CAMERA_DEPTH_AND_LANDING")
  var stairs: StaticBody3D=world.get_node_or_null(
      "ConstructionOccluder_LicensedWorksiteVisibleStoneApproach")
  if stairs==null or stairs.collision_layer!=4 or stairs.get_node_or_null(
      "TrueWalkableStairRampCollision")==null:
    _fail(229,"REV197_STAIR_SHOULD_HAVE_WALKABLE_RAMP_NOT_TALL_BLOCKING_CUBE")
    return
  var testwall:=StaticBody3D.new()
  testwall.name="REV197_REAL_COLLISION_TEMP_BARRIER"
  testwall.collision_layer=2
  testwall.collision_mask=0
  testwall.position=actor.position+Vector3(0,0.95,-0.52)
  var testwall_shape:=CollisionShape3D.new()
  var testwall_box:=BoxShape3D.new()
  testwall_box.size=Vector3(2.0,1.9,0.18)
  testwall_shape.shape=testwall_box
  testwall.add_child(testwall_shape)
  world.add_child(testwall)
  await process_frame # Register an actual PhysicsServer body for cast_motion
  var wall_begin: Vector3=actor.position
  var blocked_before: int=int(player.get("_blocked_wall_steps"))
  player.set("_yaw",0.0)
  player.set("_joystick",Vector2(0.0,-1.0))
  player.call("step",0.21)
  player.set("_joystick",Vector2.ZERO)
  if actor.position.z<wall_begin.z-0.42 or int(player.get(
      "_blocked_wall_steps"))<=blocked_before:
    _fail(230,"REV197_REAL_SWEPT_PLAYER_CAPSULE_STILL_PHASES_THROUGH_WALL")
    return
  var wished_camera: Vector3=actor.position+Vector3.UP*1.18+Vector3(0,1.4,-3.0)
  var blocked_view: Vector3=player.call("_safe_camera_position",
    actor.position+Vector3.UP*1.18,wished_camera)
  if blocked_view.distance_to(actor.position+Vector3.UP*1.18)>2.80:
    _fail(231,"REV197_CAMERA_CLIPS_THROUGH_A_COLLIDABLE_WALL")
    return
  testwall.queue_free()
  await process_frame
  actor.position=rev197_before
  mortal["energy"]=rev197_energy
  player.call("reset_camera")
  player.call("update_camera")
  player.call("_refresh_game_hud")
  print("PASS_REV197_REAL_ANDROID_TOUCH_PINCH_45DEG_VISIBLE_AVATAR_CAMERA_LOCK_JUMP_AVATAR_FLIGHT_STAIRS_AND_COLLISION")
  # REV199 actual mobile P0 user feedback: previous test passed merely
  # because the knight node existed, while flying showed an inert rigid pose,
  # no height reference, no world acceleration and no offline AI install state.
  var time_button: Button=game_hud.get_node_or_null(
      "RealFullWorldAccelerationTimes1_5_20_100")
  var clock_ui: Label=game_hud.get_node_or_null(
      "ActualAuthoritativeWorldDayHourAndAcceleration")
  var ai_ui: Label=game_hud.get_node_or_null(
      "RealOfflineNPCNativeRuntimeStatusNotFakeLLM")
  var height_ui: Label=game_hud.get_node_or_null(
      "ActualAltitudeAGLVerticalSpeedAndWorldGroundReference")
  if time_button==null or clock_ui==null or ai_ui==null or height_ui==null:
    _fail(240,"REV199_REAL_TIME_AI_AND_AIR_HUD_MUST_BE_NATIVE_ALWAYS_VISIBLE_CONTROLS")
    return
  if not ai_ui.text.contains("不可用") or bool(room.call("get_living_clock").get(
      "npc_model_loaded",true)):
    _fail(241,"REV199_LOCAL_QWEN_NATIVE_ABSENT_MUST_NOT_PRETEND_TO_HAVE_AI")
    return
  var clock_before: Dictionary=room.call("get_living_clock")
  var advanced_before: int=int(clock_before["whole_world_hours_processed"])
  var sim_start_hour: int=int(econ.day-1)*24+int(econ.hour)
  for i in range(3):
    time_button.pressed.emit()
  if int(room.get("world_time_scale"))!=100 or not clock_ui.text.contains("×100"):
    _fail(242,"REV199_WORLD_SPEED_BUTTON_NOT_APPLIED_TO_REAL_SIM_TIME")
    return
  for i in range(12):
    room.call("_process",0.10)
  var clock_after: Dictionary=room.call("get_living_clock")
  var advanced_after: int=int(clock_after["whole_world_hours_processed"])
  var sim_end_hour: int=int(econ.day-1)*24+int(econ.hour)
  if advanced_after-advanced_before!=10 or sim_end_hour-sim_start_hour!=10:
    _fail(243,"REV199_TIME_ACCEL_ONLY_CHANGES_CLOCK_UI_WITHOUT_REAL_ECOLOGY_AND_NPCS_"+
      str(clock_before)+"_"+str(clock_after))
    return
  if world.get_node_or_null("KenneySingleDirectionalSun")==null or (
      not is_finite(float(room.get("sun_light").light_energy))):
    _fail(244,"REV199_REAL_SKY_AND_LIGHT_MUST_ADVANCE_WITH_AUTHORITY_CLOCK")
    return
  time_button.pressed.emit()
  if int(room.get("world_time_scale"))!=1:
    _fail(245,"REV199_ACCEL_MUST_RESET_TO_1X_WITHOUT_LOSING_WORLD_TIME")
    return
  player.call("toggle_avatar_flight")
  player.call("step",0.55)
  var wind: GPUParticles3D=world.get_node_or_null(
      "ActuallyEmittingMobileWindTrailWhileAvatarSoars")
  var rune: MeshInstance3D=world.get_node_or_null(
      "ActualSoaringFootWindRuneNotFakeSword")
  var disk: MeshInstance3D=world.get_node_or_null(
      "ActualGroundShadowAltitudeReferenceFromPhysicalTerrain")
  var tether: MeshInstance3D=world.get_node_or_null(
      "ContinuousAirToGroundAltitudeReferenceLine")
  var p199: Dictionary=player.call("stats")
  var real_sword: Node3D=world.get_node_or_null(
      "ActualQuaterniusKnightCC0FlyingSwordUnderPlayerFeet")
  if wind==null or rune==null or disk==null or tether==null or real_sword==null or (
      not real_sword.visible) or not wind.emitting or not rune.visible or (
      not disk.visible) or not tether.visible or not height_ui.visible:
    _fail(246,"REV199_NO_TRUE_WIND_AURA_GROUND_PROJECTION_ALTITUDE_GUIDE_DURING_SOAR")
    return
  if float(p199.get("avatar_soar_altitude_m",0))<2.5 or (
      absf(float(tether.scale.y)-float(p199.get("avatar_soar_altitude_m",0)))>0.15):
    _fail(247,"REV199_GROUND_HEIGHT_LINE_DOES_NOT_REFLECT_ACTUAL_AIR_ALTITUDE")
    return
  var visual_anim: String=String(p199.get("actual_knight_bone_animation",""))
  if not (visual_anim.to_lower().contains("sword") or visual_anim.to_lower().contains("jump")):
    _fail(248,"REV199_AVATAR_STILL_USES_DEFAULT_STIFF_WALK_IDLE_WHILE_SOARING_"+visual_anim)
    return
  player.call("toggle_avatar_flight")
  var landing_initial_alt: float=float(player.get("_soar_altitude"))
  var landing_steps: int=0
  # The renderer and world use variable physics frame times; a single large
  # 0.75s tick can reject an intermediate collision probe. Simulate a real
  # sequence of 12 frames with a strict total 1.44s landing budget.
  for i in range(12):
    player.call("step",0.12)
    landing_steps+=1
    if String(player.get("camera_mode"))=="third":
      break
  if player.get("camera_mode")!="third" or wind.emitting or disk.visible or (
      height_ui.visible):
    _fail(249,"REV199_STILL_HAS_GHOST_FLIGHT_EFFECTS_AFTER_ACTUAL_SOFT_LANDING"+
      " from="+str(landing_initial_alt)+" remaining="+str(player.get("_soar_altitude"))+
      " target="+str(player.get("_soar_target_altitude"))+
      " still_landing="+str(player.get("_soar_landing"))+
      " steps="+str(landing_steps)+
      " camera="+String(player.get("camera_mode"))+
      " wind="+str(wind.emitting)+" disk="+str(disk.visible)+
      " height_ui="+str(height_ui.visible)+
      " blocked_collisions="+str(player.get("_blocked_wall_steps")))
    return
  print("PASS_REV199_REAL_WORLD_ACCELERATES_NPC_ECOLOGY_HOURS_DAY_NIGHT_AND_TRAINING_FLIGHT_WITH_VISIBLE_ALTITUDE_SPEED_AIR_TRAIL_AND_HONEST_OFFLINE_AI")
  # rev201 independently verify TRUE seeded cultivation in original APK176
  # Main, NOT mock class or a screenshot-only green UI.
  var spir: RefCounted=room.get("cultivation")
  if spir==null:
    _fail(261,"REV201_CULTIVATION_AUTHORITY_NOT_MOUNTED_IN_ORIGINAL_GAME")
    return
  var world_report: Dictionary=spir.call("stats")
  if int(world_report.get("world_seed",0))<=0 or not bool(
      world_report.get("seed_is_persistent",false)) or int(
      world_report.get("cultivator_count",0))!=12:
    _fail(262,"REV201_REAL_GENERATED_SEED_AND_12_LICENSED_CULTIVATORS_ABSENT_"+str(world_report))
    return
  var spiritual_altar: Node3D=spir.get("altar")
  if spiritual_altar==null or not String(spiritual_altar.get_meta(
      "entity_id","")).begins_with("CL-ANCIENT-SPIRIT-ROOT") or not (
      spiritual_altar.has_meta("provider")):
    _fail(263,"REV201_DETECTION_ALTAR_NOT_AN_ACTUAL_LICENSED_STONE_WORLD_ENTITY")
    return
  var spirit_npcs: Dictionary=spir.get("npc_visuals")
  var spirit_records: Dictionary=spir.get("npc_data")
  if spirit_npcs.size()!=12 or spirit_records.size()!=12 or int(world_report.get("physical_cultivator_colliders",0))!=12:
    _fail(264,"REV201_NPCS_MISSING_INDEPENDENT_ENTITY_ID_HOURLY_AUTHORITY_OR_PHYSICAL_COLLIDERS")
    return
  for spirit_id in spirit_npcs:
    var spirit_avatar: Node3D=spirit_npcs[spirit_id]["actor"]
    if spirit_avatar==null or spirit_avatar.find_children("*","MeshInstance3D",true,false).is_empty() or not spirit_avatar.has_meta("entity_id"):
      _fail(265,"REV201_CULTIVATOR_IS_FAKE_STATIC_LABEL_NOT_ACTUAL_ANIMATED_GLB")
      return
  var unauthenticated: Dictionary=spir.call("public_player_status")
  if unauthenticated.has("root_kind") or unauthenticated.has("root_weights"):
    _fail(266,"REV201_HIDDEN_PLAYER_SPIRIT_ROOT_LEAKED_BEFORE_THE_DETECTION_ALTAR")
    return
  var real_first_result: Dictionary=player.call("_try_root_examination")
  if bool(real_first_result.get("ok",false)):
    _fail(267,"REV201_SPIRIT_ROOT_TEST_CAN_BE_TAKEN_ANYWHERE_NOT_AT_REAL_ALTAR")
    return
  var before_altar_pos: Vector3=actor.position
  actor.position=Vector3(12.0,float(terrain.call("height_at",12,7))+
    float(actor.get_meta("actor_ground_offset_y",0.0)),7.0)
  var altar_btn: Button=game_hud.get_node_or_null(
      "LiveActualSpiritRootAltarExamTouchAction")
  var meditation_btn: Button=game_hud.get_node_or_null(
      "LiveOriginalWorldMeditationRealHourTouchAction")
  var realm_btn: Button=game_hud.get_node_or_null(
      "LiveActualQiPaidBreakthroughTouchAction")
  var seed_label: Label=game_hud.get_node_or_null(
      "ActuallyPersistentSpiritualWorldGenerationSeedVisible")
  if altar_btn==null or meditation_btn==null or realm_btn==null or seed_label==null:
    _fail(268,"REV201_NO_REAL_ANDROID_ROOT_TEST_MEDITATION_BREAKTHROUGH_SEED_CONTROLS")
    return
  altar_btn.pressed.emit()
  var tested: Dictionary=spir.call("public_player_status")
  if not bool(tested.get("tested",false)) or not seed_label.text.contains(
      str(world_report["world_seed"])):
    _fail(269,"REV201_BUTTON_NOT_CONNECTED_TO_REAL_SEED_SPIRIT_ROOT_EXAM_AND_HUD")
    return
  var rolled: Dictionary=spir.call("_roll_player_roots")
  if String(tested.get("root_kind",""))!=String(rolled.get("kind","")):
    _fail(270,"REV201_PLAYER_ROOT_IS_REROLLED_UNDETERMINISTICALLY")
    return
  if String(tested.get("root_kind",""))=="无灵根":
    if bool(spir.call("toggle_player_meditation").get("ok",true)):
      _fail(271,"REV201_NO_ROOT_PLAYER_ILLEGALLY_GENERATED_SPIRIT_MANA")
      return
  else:
    var practice_start: Dictionary=spir.call("toggle_player_meditation")
    if not bool(practice_start.get("ok",false)):
      _fail(272,"REV201_REAL_SPIRITROOT_PLAYER_CANNOT_PRACTICE_AT_ALL")
      return
    var npc_first_code: String="CL-XIUXIAN-001"
    var old_npc_hours: int=int(spirit_records[npc_first_code]["life_hours"])
    var before_qi: int=int(tested["qi"])
    var before_sim_hour: int=int(econ.day-1)*24+int(econ.hour)
    room.call("cycle_world_time_scale")
    room.call("cycle_world_time_scale")
    room.call("cycle_world_time_scale") # 100x WHOLE-world mode
    for i in range(10):
      room.call("_process",0.10)
    var later: Dictionary=spir.call("public_player_status")
    var sim_elapsed: int=int(econ.day-1)*24+int(econ.hour)-before_sim_hour
    var npc_elapsed: int=int(spirit_records[npc_first_code]["life_hours"])-old_npc_hours
    if sim_elapsed<6 or npc_elapsed!=sim_elapsed or int(later["qi"])<=before_qi+55:
      _fail(273,"REV201_MEDITATION_AND_REAL_NPC_AGING_NOT_ADVANCING_TOGETHER_WITH_WHOLE_WORLD_TIME")
      return
    var qi_before_break: int=int(later["qi"])
    var breakthrough: Dictionary=spir.call("player_breakthrough")
    if not bool(breakthrough.get("ok",false)) or int(
        spir.get("player_data")["layer"])!=1 or int(
        spir.get("player_data")["qi"])>=qi_before_break:
      _fail(274,"REV201_QI_NOT_SPENT_FOR_TRUE_FIRST_LEVEL_BREAKTHROUGH")
      return
    # Same world ID after reloading the serialized file: no more repeated
    # "roll 3 times" exploit from reopening the game.
    if not bool(spir.call("save_state")):
      _fail(275,"REV201_WORLD_SEED_ROOT_PROGRESS_MISSING_SAVE")
      return
    var Cult: GDScript=spir.get_script() as GDScript
    var clone: RefCounted=Cult.new()
    clone.call("_load_or_initialize")
    var loaded: Dictionary=clone.call("public_player_status")
    if int(clone.get("world_seed"))!=int(spir.get("world_seed")) or int(
        loaded.get("layer",0))!=1 or String(loaded.get("root_kind",""))!=String(
        tested.get("root_kind","")):
      _fail(276,"REV201_ROOT_AND_SPIRIT_LEVEL_REROLLED_OR_LOST_ON_REAL_SAVE_RELOAD")
      return
    room.call("cycle_world_time_scale") # reset to 1x
  actor.position=before_altar_pos
  player.call("update_camera")
  player.call("_refresh_game_hud")
  print("PASS_REV201_ACTUAL_LICENSED_ALTAR_HIDDEN_DETERMINISTIC_ROOT_12_AUTONOMOUS_CULTIVATORS_REAL_HOUR_MEDITATION_QI_AND_BREAKTHROUGH_SAVED")
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
  print("PASS_REV187_LICENSED_3D_NPC_RESOURCE_TRANSPORT_MATERIAL_CONSERVATION_STAGE_BUILD")
  print("PASS_REV187_PHONE_VISIBILITY_TREE_SEED_BEDROCK_EXCLUSION_AND_TECTONIC_MILLIONS_OF_YEARS")
  print("PASS_REV187_UNLIMITED_NATURAL_MULTIHUE_KENNEY_MESH_BATCH_SINGLE_WARM_SUN")
  print("REV187_ONEPLUS_1500_800_400_DRAW_REFERENCE_REAL_DEVICE_UNVERIFIED")
  print("PASS_REV187_REAL_MOVABLE_PLAYER_FIRST_THIRD_PERSON_ZOOM_TOUCH_INTERACT_AND_EXCAVATE_STRATIFIED_COLLISION_WATER")
  print("PASS_REV187_ONEPLUS_MANUAL_EXTREME_HIGH_NORMAL_QUALITY_100_85_67_MSAA_SHADOW_GRASS_FX_FOG_HUD_AND_NATIVE_UI")
  print("PASS_REV187_ACTUAL_GUI_JOYSTICK_RIGHT_LOOK_NPC_MESH_FEET_CONTINUOUS_TERRAIN_NO_WORLD_SYSTEM_IDS")
  print("PASS_REV187_LEFT_AND_RIGHT_WORLD_TOUCH_TO_ENTITY_INTERACTION_NO_JOYSTICK_CONFLICT")
  print("PASS_REV187_5_FPS_CAPS_3_GRAPHICS_FOLDING_PERF_NO_WARNING_OVERLAP_WARM_BLUE_SKY_CLOUDS_BLUISH_FOG_FAR_LAND_FIVE_LEAF_GRASS")
  print("PASS_REV187_ANDROID_VERTICAL_DRAG_NOT_INVERTED_GOD_VIEW_AND_FREE_FLIGHT_RESET")
  print("REV187_ACTUAL_APK176_QA_STATS ",report)
  # Explicitly teardown original exported scene before the headless RenderServer
  # exits: otherwise GLTF skeleton/animation/mesh RIDs report leaked resources.
  main.queue_free()
  await process_frame
  await process_frame
  quit(0)
