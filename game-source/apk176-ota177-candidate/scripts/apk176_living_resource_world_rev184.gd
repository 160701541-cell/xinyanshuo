extends CanvasLayer
## rev184: Original installed APK176 world. Autonomous *physical* gathering,
## warehouse delivery and material-paid construction. The Godot economy
## determines all quantities; art is licensed Kenney/Quaternius CC0 ONLY.
## This is a small playable production slice, NOT full village / on-device LLM.
const Economy = preload("res://canglan_rev184/worldbox_life_sim.gd")
const Ecology = preload("res://canglan_rev184/ecology_growth.gd")
const FivePalette = preload("res://canglan_rev184/visual_palette.gd")
const KenneyMultiMesh = preload("res://canglan_rev184/kenney_multimesh.gd")
const RealSoilTerrain = preload("res://canglan_rev184/strata_terrain.gd")
const PlayerControl = preload("res://canglan_rev184/player_controller.gd")
const ASSETS := {
  "tree": "res://canglan_rev184/tree_oak.glb",
  "stone": "res://canglan_rev184/rocks_small.glb",
  "timber": "res://canglan_rev184/tree_log.glb",
  "fence": "res://canglan_rev184/wood_fence.glb",
  "steps": "res://canglan_rev184/stone_steps.glb",
  "door": "res://canglan_rev184/wood_door.glb",
  "worker": "res://canglan_rev184/animated_knight.glb"
}
const TOWN := "CL-REV184-HX-VILLAGE"
const DEPOT := Vector3(0.0, 0.0, 10.0)
const SITE := Vector3(0.0, 0.0, -3.0)
const STAGES := [
  {"id": "stone_foundation", "consume": {"stone": 6}, "time": 6.0},
  {"id": "timber_posts", "consume": {"wood": 9}, "time": 7.0},
  {"id": "fenced_walls", "consume": {"wood": 6}, "time": 7.0},
  {"id": "door_frame", "consume": {"wood": 3, "stone": 3}, "time": 8.0}
]
var sim
var eco
var palette: RefCounted
var batch_renderer: Node3D
var terrain_world: Node3D
var controls: Node
var _foundation_dig_clock: float = 0.0
var _foundation_excavation_count: int = 0
var _render_sync_counter: float = 0.0
const BUDGET_DRAW_CALLS := 200
var npc_nameplates: Dictionary = {}
var hill_zone: MeshInstance3D
var _camera_focus := Vector3(0.0, 1.1, 10.0)
var _current_focus_id: String = "CL-NPC-0184-03"
var _follow_builder: bool = false
var _geo_pushes: int = 0
var world: Node3D
var view: SubViewport
var camera: Camera3D
var ui: Control
var notice: Label
var status: Label
var animation_report: Dictionary = {}
var asset_errors: Array[String] = []
var asset_sources: Dictionary = {}
var natural_meshes: Dictionary = {}
var workers: Dictionary = {}
var _hidden_game_world: Array[Node3D] = []
var _clock: float = 0.0
var _economy_clock: float = 0.0
var _camera_yaw: float = 0.40
var _camera_pitch: float = 0.47
var _camera_distance: float = 19.5
var _stage_index: int = 0
var _stage_progress: float = 0.0
var _stage_paid: bool = false
var _deliveries: int = 0
var _harvests: int = 0
var _built_pieces: int = 0
var _closed: bool = false
var _events: Array[String] = []

func _ready() -> void:
  name = "CanglanAutonomousEcologyWorldRev184"
  layer = 70
  sim = Economy.new()
  sim.start(20261017)
  # Existing food is a finite initial village inventory. Wood and stone = 0.
  assert(sim.create_village(TOWN, {"homes": 1, "fields": 0,
    "food": 24, "grain": 0, "water": 24, "wood": 0, "stone": 0}))
  assert(sim.add_citizen("CL-NPC-0184-01", TOWN, "woodcutter", 28))
  assert(sim.add_citizen("CL-NPC-0184-02", TOWN, "quarryman", 31))
  assert(sim.add_citizen("CL-NPC-0184-03", TOWN, "builder", 24))
  # The human player is a genuine world citizen with an identity and an
  # authoritative economy backpack, not a passive floating observer.
  assert(sim.add_citizen("CL-PLAYER-0184-0001", TOWN, "traveler", 21))
  # The original stock schema is kept intact. This version adds a reserved
  # ecological seed key only to the in-memory demonstration village ledger.
  sim.villages[TOWN]["stock"]["tree_seed"] = 0
  eco = Ecology.new()
  eco.setup(sim, TOWN, SITE, DEPOT)
  palette = FivePalette.new()
  _build_interface()
  _load_assets()
  _initialize_batches()
  _create_landscape()
  _seed_resources()
  _make_workers()
  _create_playable_player()
  _hide_old_render_world()
  _update_camera()
  _update_status()
  set_meta("prototype", "REUSABLE_MATERIALS_AND_INDEPENDENT_WORKERS")
  set_meta("mutates_original_save", false)
  set_meta("not_a_complete_npc_city", true)

func _build_interface() -> void:
  ui = Control.new()
  ui.name = "LivingWorldUI"
  ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
  ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  add_child(ui)
  var frame := SubViewportContainer.new()
  frame.name = "RealWorldViewportContainer"
  frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
  frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  frame.stretch = true
  # Actual mobile screen resolution, NEVER upscaled half-resolution blocks.
  # Low-poly geometry should be crisp; MSAA suppresses polygon jaggies.
  frame.stretch_shrink = 1
  ui.add_child(frame)
  view = SubViewport.new()
  view.name = "ActualLicensed3DWorldViewport"
  view.size = Vector2i(get_viewport().get_visible_rect().size)
  view.msaa_3d = Viewport.MSAA_2X
  view.own_world_3d = true
  view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
  frame.add_child(view)
  world = Node3D.new()
  world.name = "ResourceConservationAndConstruction"
  view.add_child(world)
  var sun := DirectionalLight3D.new()
  sun.name = "KenneySingleDirectionalSun"
  sun.rotation_degrees = Vector3(-52, -33, 0)
  sun.light_color = Color("#fff2df")
  sun.light_energy = 1.08
  sun.shadow_enabled = true
  sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
  sun.directional_shadow_max_distance = 48.0
  sun.shadow_bias = 0.055
  sun.shadow_normal_bias = 1.5
  world.add_child(sun)
  var environment := Environment.new()
  environment.background_mode = Environment.BG_SKY
  var sky := Sky.new()
  var colors := ProceduralSkyMaterial.new()
  # Sky has neutral illumination, not another competing gameplay material.
  colors.sky_top_color = Color("#799b9f")
  colors.sky_horizon_color = Color("#e3e2ce")
  colors.ground_horizon_color = Color("#889783")
  colors.ground_bottom_color = Color("#657762")
  sky.sky_material = colors
  environment.sky = sky
  environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
  environment.ambient_light_energy = 0.38
  var atmosphere := WorldEnvironment.new()
  atmosphere.name = "VillageAtmosphere"
  atmosphere.environment = environment
  world.add_child(atmosphere)
  camera = Camera3D.new()
  camera.name = "TouchOrbitCamera"
  camera.current = true
  camera.fov = 57.0
  camera.far = 165.0
  world.add_child(camera)
  var hud := VBoxContainer.new()
  hud.name = "ProductionInspector"
  hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
  hud.position = Vector2(18, 16)
  ui.add_child(hud)
  var title := Label.new()
  title.text = "苍岚·人生世界 〔真实地形 / 玩家可玩 / rev184〕"
  title.add_theme_font_size_override("font_size", 22)
  hud.add_child(title)
  notice = Label.new()
  notice.text = "高清Kenney低模 · 左摇杆走路 / 右侧看世界 / 可切第一人称"
  hud.add_child(notice)
  var close := Button.new()
  close.name = "ReturnToOriginalWorld"
  close.text = "返回原游戏"
  close.custom_minimum_size = Vector2(170, 53)
  close.mouse_filter = Control.MOUSE_FILTER_STOP
  close.pressed.connect(_close_world)
  hud.add_child(close)
  var info_bg := PanelContainer.new()
  info_bg.name = "VillageStockAndWorkerHUD"
  info_bg.position = Vector2(20, 145)
  info_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
  ui.add_child(info_bg)
  status = Label.new()
  status.name = "TrueConservationStock"
  status.add_theme_font_size_override("font_size", 16)
  info_bg.add_child(status)
  var reopen := Button.new()
  reopen.name = "ReopenAutonomousWorld"
  reopen.text = "进入生活世界"
  reopen.visible = false
  reopen.custom_minimum_size = Vector2(185, 57)
  reopen.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
  reopen.position = Vector2(-205, 18)
  reopen.pressed.connect(_reopen_world)
  ui.add_child(reopen)
  var focus := Button.new()
  focus.name = "FollowActualBuilder"
  focus.text = "看施工NPC"
  focus.position = Vector2(470, 20)
  focus.custom_minimum_size = Vector2(146, 50)
  focus.pressed.connect(_focus_builder)
  ui.add_child(focus)
  var geology := Button.new()
  geology.name = "GeologicalEpochsOnly"
  geology.text = "地质演示 +25万年"
  geology.position = Vector2(630,20)
  geology.custom_minimum_size = Vector2(220,50)
  geology.pressed.connect(_demo_tectonic_uplift)
  ui.add_child(geology)

func _focus_builder() -> void:
  var builder: Dictionary = workers.get("CL-NPC-0184-03",{})
  if builder.is_empty():
    return
  var character: Node3D = builder["node"]
  _camera_focus = character.position + Vector3(0.0,1.3,0)
  _follow_builder = true
  _camera_distance = 12.5
  _update_camera()

func _demo_tectonic_uplift() -> void:
  # Sandbox geological time ONLY: millions of years do not pass for NPCs.
  # No quarry is refilled and no village stock is changed by this UI.
  if eco.advance_geological_years(250000.0, true):
    _geo_pushes += 1
    _rebuild_geological_ridge()
    _add_event("地壳25万年：造山=板块抬升-侵蚀(远景缩尺)")
    _update_status()

func _parse_existing_cc0(path: String) -> Node3D:
  if not FileAccess.file_exists(path):
    asset_errors.append("MISSING_LICENSED_ASSET:" + path)
    return null
  var binary := FileAccess.get_file_as_bytes(path)
  if binary.size() < 256:
    asset_errors.append("EMPTY_LICENSED_ASSET:" + path)
    return null
  var doc := GLTFDocument.new()
  var state := GLTFState.new()
  if doc.append_from_buffer(binary, path.get_base_dir(), state) != OK:
    asset_errors.append("GLB_PARSE_FAILED:" + path)
    return null
  var instance: Node3D = doc.generate_scene(state)
  if instance == null:
    asset_errors.append("GLB_SCENE_FAILED:" + path)
  return instance

func _load_assets() -> void:
  for role in ASSETS:
    var art := _parse_existing_cc0(String(ASSETS[role]))
    if art == null:
      continue
    asset_sources[role] = art

func _initialize_batches() -> void:
  batch_renderer = KenneyMultiMesh.new()
  batch_renderer.name = "RealKenneySourceMeshesMergedPerPart"
  world.add_child(batch_renderer)
  if not batch_renderer.call("initialize", asset_sources, palette):
    for err in batch_renderer.get("rejected"):
      asset_errors.append(String(err))

func _place_asset(role: String, id: String, target: Vector3, scale_factor: float = 1.0) -> Node3D:
  if not asset_sources.has(role):
    return null
  var part: Node3D = null
  if role != "worker":
    # Batching creates a transform-only data proxy, not another rendered GLB.
    # Individual tree/stone nodes still have IDs, positions, scales and visibility
    # for real ecology, harvesting, growth and finite storehouse logic.
    part = batch_renderer.call("register", role, id, target, scale_factor)
  else:
    # Animated rigged characters CANNOT be blindly merged as static instances.
    part = (asset_sources[role] as Node3D).duplicate()
    part.name = id
    part.position = target
    part.scale = Vector3.ONE * scale_factor
    world.add_child(part)
  if part == null:
    asset_errors.append("BATCH_NO_SLOT_OR_SOURCE_" + role + "_" + id)
    return null
  # The physical terrain determines the foot elevation. Excavated stone
  # foundation components are placed below grade rather than floating.
  if terrain_world != null:
    var foot: float = float(terrain_world.call("height_at",target.x,target.z))
    part.position.y = foot
    if id.begins_with("NPCStoneFoundation_"):
      part.position.y = minf(foot,-0.68)
  part.set_meta("provider", "VERIFIED_EXISTING_CC0")
  part.set_meta("material_role", role)
  return part

func _terrain_piece(id: String, size: Vector2, height: float, color_role: String) -> void:
  # Godot primitive *ground* geometry only. Finished house/character 3D
  # models are never generated here.
  var mesh := MeshInstance3D.new()
  mesh.name = id
  var plane := PlaneMesh.new()
  plane.size = size
  mesh.mesh = plane
  mesh.position.y = height
  mesh.material_override = palette.call("material", color_role)
  mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  world.add_child(mesh)

func _create_landscape() -> void:
  # The top surface, exposed subsoil, collision AND pond basin are all derived
  # from this single physical deformable heightfield. No green PlaneMesh land.
  terrain_world = RealSoilTerrain.new()
  terrain_world.name = "PhysicalDeformable92mVillageStrata"
  world.add_child(terrain_world)
  # Independent geological time-lapse distant massif remains preview only.
  hill_zone = MeshInstance3D.new()
  hill_zone.name = "DistantGeologyRidgeTerrainLODNotQuarryLoot"
  world.add_child(hill_zone)
  _rebuild_geological_ridge()
  var depot_marker := _place_asset("timber", "VillageWarehouseActualExistingCC0Log", DEPOT + Vector3(1,0,-0.6), 1.1)
  if depot_marker != null:
    depot_marker.set_meta("decor_not_game_stock", true)
  _place_asset("steps", "LicensedWorksiteVisibleStoneApproach", SITE + Vector3(0,0,5), 1.6)

func _seed_resources() -> void:
  var rng := RandomNumberGenerator.new()
  rng.seed = 1802026
  # Two natural-shaped GROVES, not an equidistant test grid. All trees are
  # kept outside the 7m center road and outside the construction exclusion.
  var groves := [Vector2(-22.0,-13.0),Vector2(-21.0,22.0)]
  for index in range(12):
    var center: Vector2 = groves[int(index % groves.size())]
    var spread: float = rng.randf_range(1.5, 7.0)
    var angle: float = rng.randf_range(-PI, PI)
    var x: float = minf(-11.0,center.x+cos(angle)*spread)
    var z: float = center.y+sin(angle)*spread
    if z > 7.0 and z < 14.0:
      z += 7.0
    var entity_id := "CL-TREE-0184-%03d" % index
    assert(sim.register_natural_node(entity_id, TOWN, "tree", 12))
    assert(sim.register_resource_position(entity_id, Vector3(x,
      float(terrain_world.call("height_at",x,z)),z)))
    assert(eco.register_tree(entity_id))
    var instance := _place_asset("tree", entity_id, Vector3(x,0,z), rng.randf_range(1.45,2.2))
    if instance != null:
      instance.set_meta("resource_id", entity_id)
      natural_meshes[entity_id] = instance
  # Two mineral outcrops (right-hand side), all outside the main road.
  var quarry_groups := [Vector2(21.0,-15.0),Vector2(23.0,19.0)]
  for index in range(9):
    var center: Vector2 = quarry_groups[int(index % quarry_groups.size())]
    var spread: float = rng.randf_range(1.0,6.5)
    var angle: float = rng.randf_range(-PI, PI)
    var x: float = maxf(12.0,center.x+cos(angle)*spread)
    var z: float = center.y+sin(angle)*spread
    if z > 7.0 and z < 14.0:
      z -= 8.0
    var entity_id := "CL-STONE-0184-%03d" % index
    assert(sim.register_natural_node(entity_id, TOWN, "stone", 18))
    assert(sim.register_resource_position(entity_id, Vector3(x,
      float(terrain_world.call("height_at",x,z)),z)))
    assert(eco.register_stone(entity_id))
    var instance := _place_asset("stone", entity_id, Vector3(x,0,z), rng.randf_range(1.0,1.55))
    if instance != null:
      natural_meshes[entity_id] = instance

func _make_workers() -> void:
  var identities := [
    {"id":"CL-NPC-0184-01","kind":"tree","name":"樵夫"},
    {"id":"CL-NPC-0184-02","kind":"stone","name":"采石工"},
    {"id":"CL-NPC-0184-03","kind":"builder","name":"施工工"}
  ]
  for profile in identities:
    var code: String = profile["id"]
    var character := _place_asset("worker", code, DEPOT + Vector3(
      float(workers.size()-1)*2.7, 0, 0), 1.0)
    if character == null:
      continue
    # Import asset native scale varies radically across GLB vendors.
    # Measure the animated mesh itself and normalize actual real-world height.
    _normalize_worker_height(character)
    var label := Label3D.new()
    label.name = "PersistentNamePlate_" + code
    label.text = String(profile["name"]) + " · " + code
    label.font_size = 44
    label.pixel_size = 0.006
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.no_depth_test = true
    label.position = character.position + Vector3(0, 2.2, 0)
    world.add_child(label)
    npc_nameplates[code] = label
    var anim_nodes: Array[Node] = character.find_children("*", "AnimationPlayer", true, false)
    var walk_name := ""
    var idle_name := ""
    var player: AnimationPlayer
    for candidate in anim_nodes:
      var animator: AnimationPlayer = candidate as AnimationPlayer
      for name in animator.get_animation_list():
        var lowered := String(name).to_lower()
        if lowered.contains("walk") or lowered.contains("run"):
          walk_name = String(name)
          player = animator
        if lowered.contains("idle") or lowered.contains("stand"):
          idle_name = String(name)
    animation_report[code] = {"walk": walk_name, "idle": idle_name}
    workers[code] = {"entity_id": code, "node": character,
      "kind": profile["kind"], "phase": "idle", "target": DEPOT,
      "player": player, "walking": walk_name, "idle_animation": idle_name}
    character.set_meta("npc_id", code)
    character.set_meta("npc_profession", profile["name"])
    if player != null and not idle_name.is_empty():
      player.play(idle_name)

func _create_playable_player() -> void:
  controls = PlayerControl.new()
  world.add_child(controls)
  controls.call("initialize", self)

func _hide_old_render_world() -> void:
  # Keep the original main scene alive with scripts and saves untouched,
  # but suspend rendering its separate mesh tree while viewing this scene.
  var base: Node = get_parent()
  for child in base.get_children():
    if child is Node3D and child.visible:
      _hidden_game_world.append(child as Node3D)
      (child as Node3D).visible = false
  var old_overlay: Node = base.get_node_or_null("HD2DArtAcceptance")
  if old_overlay != null and old_overlay.has_method("_set_visible"):
    old_overlay.call("_set_visible", false)

func _set_worker_animation(worker: Dictionary, moving: bool) -> void:
  var anim: AnimationPlayer = worker.get("player")
  if anim == null:
    return
  var name: String = worker["walking"] if moving else worker["idle_animation"]
  if not name.is_empty() and anim.current_animation != name:
    anim.play(name)

func _navigate(worker: Dictionary, delta: float) -> bool:
  var character: Node3D = worker["node"]
  var goal: Vector3 = worker["target"]
  var difference: Vector3 = goal - character.position
  difference.y = 0.0
  if difference.length() <= 1.0:
    _set_worker_animation(worker, false)
    return true
  var delta_move: float = minf(difference.length(), delta * 4.4)
  character.position += difference.normalized() * delta_move
  if terrain_world != null:
    character.position.y = float(terrain_world.call("height_at",character.position.x,character.position.z))
  # Front orientation is model-dependent; do not rotate skeleton bone tracks.
  character.rotation.y = atan2(difference.x, difference.z)
  _set_worker_animation(worker, true)
  return false

func _give_work(worker: Dictionary) -> void:
  var kind: String = worker["kind"]
  var available: Array[String] = sim.get_available_resource_nodes(TOWN, kind)
  if available.is_empty():
    worker["phase"] = "waiting_for_resource"
    return
  var code: String = available[0]
  worker["source_id"] = code
  worker["phase"] = "to_source"
  worker["target"] = sim.resource_positions[code]

func _move_gatherer(worker: Dictionary, delta: float) -> void:
  var phase: String = worker["phase"]
  if phase in ["idle", "waiting_for_resource"]:
    _give_work(worker)
    return
  if not _navigate(worker, delta):
    return
  var code: String = worker["entity_id"]
  if phase == "to_source":
    var source: String = worker["source_id"]
    if sim.gather_to_actor(code, source):
      _harvests += 1
      worker["phase"] = "to_depot"
      worker["target"] = DEPOT
      var node: Dictionary = sim.natural_nodes[source]
      if natural_meshes.has(source) and int(node["remaining"]) <= 0:
        (natural_meshes[source] as Node3D).visible = false
      if String(node["kind"]) == "tree" and int(node["remaining"]) == 0:
        if eco.on_tree_cut_to_zero(code, source):
          _add_event("整树伐尽→" + code + "随身获得1枚种子")
      _add_event(code + " 采集 " + source)
    else:
      worker["phase"] = "waiting_for_resource"
  elif phase == "to_depot":
    if sim.deliver_carried(code):
      _deliveries += 1
      var actual_seeds: int = eco.delivered_seed_from_actor(code)
      if actual_seeds > 0:
        _add_event("种子实际入库×" + str(actual_seeds))
        # Keep half of the delivered seeds as REAL village stock available
        # for future player/NPC planting, instead of consuming every seed.
        if eco.planted_count * 2 < eco.minted_seed_events:
          var new_id: String = eco.plant_first_available()
          if not new_id.is_empty():
            var position: Vector3 = eco.trees[new_id]["position"]
            var sapling: Node3D = _place_asset("tree", new_id, position, 0.10)
            if sapling != null:
              natural_meshes[new_id] = sapling
            _add_event("村民消耗1枚种子种入林地 " + new_id)
      _add_event(code + " 运输入库")
      worker["phase"] = "idle"

func _place_stage_art(stage_name: String) -> void:
  if stage_name == "stone_foundation":
    for i in range(4):
      if _place_asset("steps", "NPCStoneFoundation_%02d" % i,
        SITE + Vector3(-2.1 + i*1.35,0,0), 1.6) != null:
        _built_pieces += 1
  elif stage_name == "timber_posts":
    for i in range(4):
      if _place_asset("timber", "NPCPlacedTimber_%02d" % i,
        SITE + Vector3(-2.5 + i*1.7,0,-2.4), 1.7) != null:
        _built_pieces += 1
  elif stage_name == "fenced_walls":
    for i in range(4):
      if _place_asset("fence", "NPCAssembledFence_%02d" % i,
        SITE + Vector3(-2.0 + i*1.4,0,2.2), 1.65) != null:
        _built_pieces += 1
  elif stage_name == "door_frame":
    if _place_asset("door", "NPCInstalledLicensedDoor", SITE + Vector3(0,0,2.1), 2.0) != null:
      _built_pieces += 1

func _move_builder(worker: Dictionary, delta: float) -> void:
  # A real foundation is EXCAVATED before stone is placed. Every cut alters
  # the physical terrain mesh, rebuilds collision and debits strata mass.
  if _stage_index == 0 and terrain_world != null and not bool(terrain_world.call("foundation_ready")):
    worker["phase"] = "excavating_foundation"
    worker["target"] = SITE + Vector3(2.0,0,0.0)
    if not _navigate(worker,delta):
      return
    _set_worker_animation(worker,false)
    _foundation_dig_clock += delta
    if _foundation_dig_clock>=1.8:
      _foundation_dig_clock = 0.0
      var spoil: Dictionary = terrain_world.call("next_foundation_cut")
      if bool(spoil.get("ok",false)):
        _foundation_excavation_count += 1
        _add_event("施工工挖出" + String(spoil.get("kind","土")) + "·地基深" + str(spoil.get("depth_m",0.0))+"米")
    return
  if _stage_index >= STAGES.size():
    worker["phase"] = "waiting_for_roof_components"
    _set_worker_animation(worker, false)
    return
  var phase: Dictionary = STAGES[_stage_index]
  var worker_node: Node3D = worker["node"]
  if not _stage_paid:
    # Builder MUST first walk back to the real warehouse; no teleporting
    # materials from village stock directly to the worksite.
    worker["phase"] = "to_warehouse_for_materials"
    worker["target"] = DEPOT
    if not _navigate(worker, delta):
      return
    if not sim._spend(TOWN, phase["consume"]):
      worker["phase"] = "waiting_materials"
      return
    _stage_paid = true
    _stage_progress = 0.0
    # Stock is now in this specific builder's finite load, *not minted*.
    worker["carried_materials"] = phase["consume"].duplicate(true)
    worker["phase"] = "to_building_site"
    worker["target"] = SITE
    var role: String = "timber" if int(phase["consume"].get("wood",0))>0 else "stone"
    if asset_sources.has(role):
      var visual: Node3D = (asset_sources[role] as Node3D).duplicate()
      visual.name = "ActualCarriedLicensedMaterial"
      visual.position = Vector3(0.25, 1.1, -0.1)
      visual.scale = Vector3.ONE * 0.54
      worker_node.add_child(visual)
      worker["cargo_visual"] = visual
    _add_event("工人领取实体材料 " + String(phase["id"]))
    return
  if String(worker.get("phase","")) == "to_building_site":
    if not _navigate(worker, delta):
      return
    # Materials are delivered only on physical arrival, before labor starts.
    worker["delivered_materials"] = worker.get("carried_materials",{}).duplicate(true)
    worker.erase("carried_materials")
    if worker.has("cargo_visual"):
      var cargo: Node3D = worker["cargo_visual"]
      if is_instance_valid(cargo):
        cargo.queue_free()
      worker.erase("cargo_visual")
    worker["phase"] = "working_" + String(phase["id"])
    _add_event("实体材料到达工地 " + String(phase["id"]))
    return
  # Work is measured in elapsed physical seconds after delivery; no instant
  # spawn on job assignment and no appearance before material reservation.
  _set_worker_animation(worker, false)
  _stage_progress += delta
  if _stage_progress >= float(phase["time"]):
    _place_stage_art(String(phase["id"]))
    _add_event("NPC竣工阶段 " + String(phase["id"]))
    worker.erase("delivered_materials")
    _stage_index += 1
    _stage_paid = false
    _stage_progress = 0.0
    worker["phase"] = "return_to_warehouse"
    worker["target"] = DEPOT

func _add_event(message: String) -> void:
  _events.append(message)
  if _events.size() > 6:
    _events.pop_front()

func _update_status() -> void:
  if status == null:
    return
  var village: Dictionary = sim.villages[TOWN]
  var stock: Dictionary = village["stock"]
  var build: String = "等待授权瓦件/屋顶工程" if _stage_index >= STAGES.size() else (
    "阶段 %d/%d %s %d%%" % [_stage_index+1,STAGES.size(),
      STAGES[_stage_index]["id"],
      int(100.0 * _stage_progress/maxf(1.0,float(STAGES[_stage_index]["time"])))]
  )
  var terrain_state: Dictionary = terrain_world.call("stats") if terrain_world!=null else {}
  status.text = ("木 %d  石 %d  树种库存 %d  伐倒产种 %d\n" +
    "入库 %d  种下 %d  地下矿脉露出 %d\n" +
    "施工 %s  构件 %d\n" +
    "樵夫:%s  采石:%s\n" +
    "真实地层挖掘 %d格·深可至3.6米 / 水塘有实河床\n" +
    "地质(独立年代) %d万年 / 远景海拔 %.0fm\n" +
    "最近: %s") % [
      int(stock["wood"]),int(stock["stone"]),int(stock.get("tree_seed",0)),eco.minted_seed_events,
      _deliveries,eco.planted_count,eco.exposed_from_subsoil,
      build,_built_pieces,
      String(workers.get("CL-NPC-0184-01",{}).get("phase","missing")),
      String(workers.get("CL-NPC-0184-02",{}).get("phase","missing")),
      int(terrain_state.get("excavation_units",0)),
      int(eco.geology_years/10000.0), eco.geological_ridge_m,
      _events.back() if not _events.is_empty() else "砍完一树只产一颗种子"
    ]

func _update_camera() -> void:
  if controls != null:
    controls.call("update_camera")
    return
  if camera == null:
    return
  camera.position = _camera_focus + Vector3(
    sin(_camera_yaw)*cos(_camera_pitch)*_camera_distance,
    sin(_camera_pitch)*_camera_distance,
    cos(_camera_yaw)*cos(_camera_pitch)*_camera_distance)
  camera.look_at(_camera_focus, Vector3.UP)

func _input(event: InputEvent) -> void:
  if not _closed and controls != null:
    controls.call("handle_input",event)

func _process(delta: float) -> void:
  if _closed:
    return
  if controls != null:
    controls.call("step",delta)
  _clock += delta
  _economy_clock += delta
  if _economy_clock >= 12.0:
    _economy_clock = 0
    sim.tick()
    eco.advance_ecology_hours(1)
    _refresh_ecology_meshes()
  for worker in workers.values():
    if String(worker["kind"]) == "builder":
      _move_builder(worker, delta)
    else:
      _move_gatherer(worker, delta)
  for code in workers:
    var actor: Node3D = workers[code]["node"]
    if npc_nameplates.has(code):
      (npc_nameplates[code] as Label3D).position = actor.position + Vector3(0,2.25,0)
  if _follow_builder and workers.has(_current_focus_id):
    var following: Node3D = workers[_current_focus_id]["node"]
    _camera_focus = _camera_focus.lerp(following.position+Vector3(0,1.15,0),clampf(delta*3.5,0,1))
    _update_camera()
  _render_sync_counter += delta
  if _render_sync_counter >= 0.10:
    _render_sync_counter = 0.0
    # Dynamic finite-resource growth/depletion and staged construction remain
    # visible without 1 mesh per tree/rock or 1 draw call per object.
    batch_renderer.call("sync_all")
  if _clock >= 0.5:
    _clock = 0.0
    _update_status()

func _close_world() -> void:
  _closed = true
  ui.get_node("RealWorldViewportContainer").visible = false
  ui.get_node("ProductionInspector").visible = false
  ui.get_node("VillageStockAndWorkerHUD").visible = false
  ui.get_node("FollowActualBuilder").visible = false
  ui.get_node("GeologicalEpochsOnly").visible = false
  ui.get_node("ReopenAutonomousWorld").visible = true
  if controls != null:
    controls.call("set_enabled",false)
  for child in _hidden_game_world:
    if is_instance_valid(child):
      child.visible = true

func _reopen_world() -> void:
  _closed = false
  for child in _hidden_game_world:
    if is_instance_valid(child):
      child.visible = false
  ui.get_node("RealWorldViewportContainer").visible = true
  ui.get_node("ProductionInspector").visible = true
  ui.get_node("VillageStockAndWorkerHUD").visible = true
  ui.get_node("FollowActualBuilder").visible = true
  ui.get_node("GeologicalEpochsOnly").visible = true
  ui.get_node("ReopenAutonomousWorld").visible = false
  if controls != null:
    controls.call("set_enabled",true)

func stats() -> Dictionary:
  var stock: Dictionary = sim.villages[TOWN]["stock"]
  return {"revision": 184, "world_seed": 20261017,
    "worker_count": workers.size(), "resource_node_count": sim.natural_nodes.size(),
    "source_assets": asset_sources.size(), "missing_assets": asset_errors.duplicate(),
    "animation_reports": animation_report.duplicate(true),
    "harvests": _harvests, "deliveries": _deliveries,
    "stock_wood": int(stock["wood"]), "stock_stone": int(stock["stone"]),
    "stage": _stage_index, "built_cc0_parts": _built_pieces,
    "tree_seeds_village": int(stock.get("tree_seed",0)),
    "tree_seeds_carried": eco.awaiting_seed_delivery.duplicate(true),
    "felled_seed_events": eco.minted_seed_events,
    "saplings_planted": eco.planted_count,
    "exposed_geological_stone": eco.exposed_from_subsoil,
    "geological_years": eco.geology_years,
    "ridge_elevation_m": eco.geological_ridge_m,
    "visible_actor_labels": npc_nameplates.size(),
    "palette_roles": palette.call("swatch_count"),
    "kenney_batch": batch_renderer.call("stats"),
    "base_3d_lights": world.find_children("*", "DirectionalLight3D", true, false).size(),
    "performance_draw_budget": BUDGET_DRAW_CALLS,
    "render_quality": "NATIVE_PIXEL_RATIO_1_MSAA2",
    "native_resolution_shrink": 1,
    "physical_strata": terrain_world.call("stats") if terrain_world!=null else {},
    "player_controls": controls.call("stats") if controls!=null else {},
    "foundation_excavation_npc_cuts": _foundation_excavation_count,
    "worker_visual_heights_m": {
      "woodcutter": float(workers["CL-NPC-0184-01"]["node"].get_meta("actor_visual_height_m",0.0)) if workers.has("CL-NPC-0184-01") else 0.0,
      "quarryman": float(workers["CL-NPC-0184-02"]["node"].get_meta("actor_visual_height_m",0.0)) if workers.has("CL-NPC-0184-02") else 0.0,
      "builder": float(workers["CL-NPC-0184-03"]["node"].get_meta("actor_visual_height_m",0.0)) if workers.has("CL-NPC-0184-03") else 0.0
    },
    "not_whole_finished_house": true, "save_unchanged": true}


func _visible_bounds(actor: Node3D) -> Vector2:
  var smallest_y: float = INF
  var largest_y: float = -INF
  for child in actor.find_children("*","MeshInstance3D",true,false):
    var part: MeshInstance3D = child as MeshInstance3D
    if part.mesh == null:
      continue
    var bb: AABB = part.get_aabb()
    for corner in range(8):
      var point: Vector3 = part.to_global(bb.get_endpoint(corner))
      smallest_y = minf(smallest_y,point.y)
      largest_y = maxf(largest_y,point.y)
  return Vector2(smallest_y,largest_y)

func _normalize_worker_height(actor: Node3D) -> void:
  var native: Vector2 = _visible_bounds(actor)
  var measured: float = native.y-native.x
  if measured <= 0.0001 or not is_finite(measured):
    actor.set_meta("actor_visual_height_m",0.0)
    return
  actor.scale *= clampf(1.8/measured,0.01,100.0)
  var new_bounds: Vector2 = _visible_bounds(actor)
  # Character imported foot offsets must not sink behind ground or hover.
  actor.position.y -= new_bounds.x
  actor.set_meta("actor_visual_height_m",new_bounds.y-new_bounds.x)
  actor.set_meta("actor_scale_normalized",true)

func _refresh_ecology_meshes() -> void:
  for id in eco.trees:
    if not natural_meshes.has(id):
      continue
    var art: Node3D = natural_meshes[id]
    if not is_instance_valid(art):
      continue
    var state: Dictionary = eco.trees[id]
    if bool(state["planted"]):
      var life: String = String(state["stage"])
      var growth_scale: float = 0.10
      if life == "sapling":
        growth_scale = 0.20
      elif life == "young_tree":
        growth_scale = 0.65
      elif life == "mature":
        growth_scale = 1.65
      art.scale = Vector3.ONE * growth_scale
      art.visible = life != "stump"
    else:
      art.visible = int(sim.natural_nodes[id]["remaining"]) > 0
  for id in eco.stone:
    if not natural_meshes.has(id):
      continue
    var art: Node3D = natural_meshes[id]
    var remaining: int = int(sim.natural_nodes[id]["remaining"])
    art.visible = remaining > 0
    var stage: String = String(eco.stone[id]["stage"])
    if stage == "pebbles":
      art.scale = Vector3.ONE * 0.19
    elif stage == "small_rock":
      art.scale = Vector3.ONE * 0.38
    elif stage == "rock_cluster":
      art.scale = Vector3.ONE * 0.72
    elif remaining > 16:
      art.scale = Vector3.ONE * 1.35

func _rebuild_geological_ridge() -> void:
  if hill_zone == null:
    return
  # A small procedural TERRAIN TILE, not a procedurally built model;
  # a real full-world heightfield+LOD system is a separate engineering task.
  var surface := SurfaceTool.new()
  surface.begin(Mesh.PRIMITIVE_TRIANGLES)
  var display_height: float = minf(55.0, eco.geological_ridge_m / 160.0)
  for row in range(9):
    for col in range(18):
      var xl: float = -54.0+float(col)*6.0
      var xr: float = xl+6.0
      var zn: float = -35.0-float(row)*5.0
      var zf: float = zn-5.0
      var triangle := [
        Vector2(xl,zn),Vector2(xr,zn),Vector2(xr,zf),
        Vector2(xl,zn),Vector2(xr,zf),Vector2(xl,zf)]
      for pos in triangle:
        var width: float = maxf(0.0,1.0-absf(pos.x)/60.0)
        var ridge: float = pow(width,1.3)*maxf(0.0,1.0-absf(pos.y+55.0)/27.0)
        var height: float = -0.06+display_height*ridge
        surface.set_uv(Vector2((pos.x+54.0)/108.0,(-pos.y-35.0)/45.0))
        surface.add_vertex(Vector3(pos.x,height,pos.y))
  surface.generate_normals()
  hill_zone.mesh = surface.commit()
  var material := StandardMaterial3D.new()
  material.albedo_color = Color("#838e7b")
  material.roughness = 1.0
  hill_zone.material_override = palette.call("material", "stone")
  hill_zone.set_meta("geological_height_m",eco.geological_ridge_m)
  hill_zone.set_meta("preview_terrain_reduced_vertical_scale",true)

func _exit_tree() -> void:
  # GLTFDocument.generate_scene produces freestanding Node3D templates.
  # They are NOT in the SceneTree, so main.queue_free() cannot clean them.
  # Release their Skeleton/Mesh/Animation resources before the renderer exits.
  if batch_renderer != null and is_instance_valid(batch_renderer):
    batch_renderer.queue_free()
  for source in asset_sources.values():
    if is_instance_valid(source):
      source.free()
  asset_sources.clear()
  _hidden_game_world.clear()
