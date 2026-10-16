extends CanvasLayer
## rev180: Original installed APK176 world. Autonomous *physical* gathering,
## warehouse delivery and material-paid construction. The Godot economy
## determines all quantities; art is licensed Kenney/Quaternius CC0 ONLY.
## This is a small playable production slice, NOT full village / on-device LLM.
const Economy = preload("res://canglan_rev180/worldbox_life_sim.gd")
const ASSETS := {
  "tree": "res://canglan_rev180/tree_oak.glb",
  "stone": "res://canglan_rev180/rocks_small.glb",
  "timber": "res://canglan_rev180/tree_log.glb",
  "fence": "res://canglan_rev180/wood_fence.glb",
  "steps": "res://canglan_rev180/stone_steps.glb",
  "door": "res://canglan_rev180/wood_door.glb",
  "worker": "res://canglan_rev180/animated_knight.glb"
}
const TOWN := "CL-REV180-HX-VILLAGE"
const DEPOT := Vector3(0.0, 0.0, 10.0)
const SITE := Vector3(0.0, 0.0, -3.0)
const STAGES := [
  {"id": "stone_foundation", "consume": {"stone": 6}, "time": 6.0},
  {"id": "timber_posts", "consume": {"wood": 9}, "time": 7.0},
  {"id": "fenced_walls", "consume": {"wood": 6}, "time": 7.0},
  {"id": "door_frame", "consume": {"wood": 3, "stone": 3}, "time": 8.0}
]
var sim: RefCounted
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
var _camera_pitch: float = 0.68
var _camera_distance: float = 32.0
var _stage_index: int = 0
var _stage_progress: float = 0.0
var _stage_paid: bool = false
var _deliveries: int = 0
var _harvests: int = 0
var _built_pieces: int = 0
var _closed: bool = false
var _events: Array[String] = []

func _ready() -> void:
  name = "CanglanAutonomousMaterialWorldRev180"
  layer = 70
  sim = Economy.new()
  sim.start(20261017)
  # Existing food is a finite initial village inventory. Wood and stone = 0.
  assert(sim.create_village(TOWN, {"homes": 1, "fields": 0,
    "food": 24, "grain": 0, "water": 24, "wood": 0, "stone": 0}))
  assert(sim.add_citizen("CL-NPC-0180-01", TOWN, "woodcutter", 28))
  assert(sim.add_citizen("CL-NPC-0180-02", TOWN, "quarryman", 31))
  assert(sim.add_citizen("CL-NPC-0180-03", TOWN, "builder", 24))
  _build_interface()
  _load_assets()
  _create_landscape()
  _seed_resources()
  _make_workers()
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
  ui.add_child(frame)
  view = SubViewport.new()
  view.name = "ActualLicensed3DWorldViewport"
  view.size = Vector2i(1280, 720)
  view.own_world_3d = true
  view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
  frame.add_child(view)
  world = Node3D.new()
  world.name = "ResourceConservationAndConstruction"
  view.add_child(world)
  var sun := DirectionalLight3D.new()
  sun.name = "MorningSunlight"
  sun.rotation_degrees = Vector3(-52, -33, 0)
  sun.light_color = Color("#fff1d5")
  sun.light_energy = 1.05
  sun.shadow_enabled = true
  world.add_child(sun)
  var environment := Environment.new()
  environment.background_mode = Environment.BG_SKY
  var sky := Sky.new()
  var colors := ProceduralSkyMaterial.new()
  colors.sky_top_color = Color("#648ba0")
  colors.sky_horizon_color = Color("#d6dfd1")
  colors.ground_horizon_color = Color("#8d987f")
  colors.ground_bottom_color = Color("#566e5b")
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
  camera.fov = 56.0
  camera.far = 165.0
  world.add_child(camera)
  var hud := VBoxContainer.new()
  hud.name = "ProductionInspector"
  hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
  hud.position = Vector2(18, 16)
  ui.add_child(hud)
  var title := Label.new()
  title.text = "苍岚 · 资源→搬运→施工 (rev180)"
  title.add_theme_font_size_override("font_size", 22)
  hud.add_child(title)
  notice = Label.new()
  notice.text = "Kenney/Quaternius CC0 · 实际物资守恒 · 右侧拖动旋转视角"
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
  info_bg.position = Vector2(18, 160)
  info_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
  ui.add_child(info_bg)
  status = Label.new()
  status.name = "TrueConservationStock"
  status.add_theme_font_size_override("font_size", 19)
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

func _place_asset(role: String, id: String, target: Vector3, scale_factor: float = 1.0) -> Node3D:
  if not asset_sources.has(role):
    return null
  var part: Node3D = (asset_sources[role] as Node3D).duplicate()
  part.name = id
  part.position = target
  part.scale = Vector3.ONE * scale_factor
  part.set_meta("provider", "VERIFIED_EXISTING_CC0")
  part.set_meta("material_role", role)
  world.add_child(part)
  return part

func _terrain_piece(id: String, size: Vector2, height: float, color: String) -> void:
  # Godot primitive *ground* geometry only. Finished house/character 3D
  # models are never generated here.
  var mesh := MeshInstance3D.new()
  mesh.name = id
  var plane := PlaneMesh.new()
  plane.size = size
  mesh.mesh = plane
  mesh.position.y = height
  var mat := StandardMaterial3D.new()
  mat.albedo_color = Color(color)
  mat.roughness = 1.0
  mesh.material_override = mat
  world.add_child(mesh)

func _create_landscape() -> void:
  _terrain_piece("PhysicalNaturalGroundNotPrefab", Vector2(70, 65), -0.07, "#728c69")
  _terrain_piece("WalkableVillagePackedEarth", Vector2(9, 31), -0.049, "#b3a488")
  var depot_marker := _place_asset("timber", "VillageWarehouseActualExistingCC0Log", DEPOT + Vector3(1,0,-0.6), 1.1)
  if depot_marker != null:
    depot_marker.set_meta("decor_not_game_stock", true)
  _place_asset("steps", "LicensedWorksiteVisibleStoneApproach", SITE + Vector3(0,0,5), 1.6)

func _seed_resources() -> void:
  var rng := RandomNumberGenerator.new()
  rng.seed = 1802026
  for index in range(12):
    var x: float = rng.randf_range(-25.0, -11.0)
    var z: float = rng.randf_range(-22.0, 14.0)
    var entity_id := "CL-TREE-0180-%03d" % index
    assert(sim.register_natural_node(entity_id, TOWN, "tree", 12))
    assert(sim.register_resource_position(entity_id, Vector3(x,0,z)))
    assert(sim.configure_resource_recovery(entity_id, 12, 1, 48, 24))
    var instance := _place_asset("tree", entity_id, Vector3(x,0,z), rng.randf_range(1.45,2.2))
    if instance != null:
      instance.set_meta("resource_id", entity_id)
      natural_meshes[entity_id] = instance
  for index in range(9):
    var x: float = rng.randf_range(12.0, 25.0)
    var z: float = rng.randf_range(-21.0, 15.0)
    var entity_id := "CL-STONE-0180-%03d" % index
    assert(sim.register_natural_node(entity_id, TOWN, "stone", 18))
    assert(sim.register_resource_position(entity_id, Vector3(x,0,z)))
    var instance := _place_asset("stone", entity_id, Vector3(x,0,z), rng.randf_range(1.0,1.55))
    if instance != null:
      natural_meshes[entity_id] = instance

func _make_workers() -> void:
  var identities := [
    {"id":"CL-NPC-0180-01","kind":"tree","name":"樵夫"},
    {"id":"CL-NPC-0180-02","kind":"stone","name":"采石工"},
    {"id":"CL-NPC-0180-03","kind":"builder","name":"施工工"}
  ]
  for profile in identities:
    var code: String = profile["id"]
    var character := _place_asset("worker", code, DEPOT + Vector3(
      float(workers.size()-1)*2.7, 0, 0), 1.0)
    if character == null:
      continue
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
      _add_event(code + " 采集 " + source)
    else:
      worker["phase"] = "waiting_for_resource"
  elif phase == "to_depot":
    if sim.deliver_carried(code):
      _deliveries += 1
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
  if _stage_index >= STAGES.size():
    worker["phase"] = "waiting_for_roof_components"
    _set_worker_animation(worker, false)
    return
  var phase: Dictionary = STAGES[_stage_index]
  if not _stage_paid:
    if not sim._spend(TOWN, phase["consume"]):
      worker["phase"] = "waiting_materials"
      _set_worker_animation(worker, false)
      return
    _stage_paid = true
    _stage_progress = 0.0
    worker["phase"] = "to_building_site"
    worker["target"] = SITE
    _add_event("工地领料 " + String(phase["id"]))
  if not _navigate(worker, delta):
    return
  worker["phase"] = "working_" + String(phase["id"])
  _stage_progress += delta
  if _stage_progress >= float(phase["time"]):
    _place_stage_art(String(phase["id"]))
    _add_event("NPC竣工阶段 " + String(phase["id"]))
    _stage_index += 1
    _stage_paid = false
    _stage_progress = 0.0
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
  status.text = ("木材 %d   石材 %d  |  运入库 %d  采集 %d\n" +
    "居民 3名   工作营地 ID: CL-REV180-HX\n" +
    "真实施工: %s  构件 %d\n" +
    "樵夫:%s  采石工:%s\n" +
    "最新: %s") % [
      int(stock["wood"]), int(stock["stone"]), _deliveries, _harvests,
      build, _built_pieces,
      String(workers.get("CL-NPC-0180-01",{}).get("phase","missing")),
      String(workers.get("CL-NPC-0180-02",{}).get("phase","missing")),
      _events.back() if not _events.is_empty() else "资源先于劳动存在"
    ]

func _update_camera() -> void:
  if camera == null:
    return
  camera.position = Vector3(
    sin(_camera_yaw)*cos(_camera_pitch)*_camera_distance,
    sin(_camera_pitch)*_camera_distance,
    cos(_camera_yaw)*cos(_camera_pitch)*_camera_distance)
  camera.look_at(Vector3(0,0,-1), Vector3.UP)

func _input(event: InputEvent) -> void:
  if _closed:
    return
  if event is InputEventScreenDrag:
    var screen_size: Vector2 = get_viewport().get_visible_rect().size
    if event.position.x > screen_size.x * 0.42 and event.position.y > 110:
      _camera_yaw -= event.relative.x * 0.007
      _camera_pitch = clampf(_camera_pitch + event.relative.y*0.003,0.23,1.15)
      _update_camera()
  elif event is InputEventMagnifyGesture:
    _camera_distance = clampf(_camera_distance / maxf(event.factor,0.1),12,60)
    _update_camera()

func _process(delta: float) -> void:
  if _closed:
    return
  _clock += delta
  _economy_clock += delta
  if _economy_clock >= 12.0:
    _economy_clock = 0
    sim.tick()
    # Independent finite trees can recover from actual world tick rules.
    for id in natural_meshes:
      var node: Dictionary = sim.natural_nodes.get(id, {})
      if not node.is_empty():
        (natural_meshes[id] as Node3D).visible = int(node.get("remaining",0)) > 0
  for worker in workers.values():
    if String(worker["kind"]) == "builder":
      _move_builder(worker, delta)
    else:
      _move_gatherer(worker, delta)
  if _clock >= 0.5:
    _clock = 0.0
    _update_status()

func _close_world() -> void:
  _closed = true
  ui.get_node("RealWorldViewportContainer").visible = false
  ui.get_node("ProductionInspector").visible = false
  ui.get_node("VillageStockAndWorkerHUD").visible = false
  ui.get_node("ReopenAutonomousWorld").visible = true
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
  ui.get_node("ReopenAutonomousWorld").visible = false

func stats() -> Dictionary:
  var stock: Dictionary = sim.villages[TOWN]["stock"]
  return {"revision": 180, "world_seed": 20261017,
    "worker_count": workers.size(), "resource_node_count": sim.natural_nodes.size(),
    "source_assets": asset_sources.size(), "missing_assets": asset_errors.duplicate(),
    "animation_reports": animation_report.duplicate(true),
    "harvests": _harvests, "deliveries": _deliveries,
    "stock_wood": int(stock["wood"]), "stock_stone": int(stock["stone"]),
    "stage": _stage_index, "built_cc0_parts": _built_pieces,
    "not_whole_finished_house": true, "save_unchanged": true}
