extends CanvasLayer
## rev187: Original installed APK176 world. Autonomous *physical* gathering,
## warehouse delivery and material-paid construction. The Godot economy
## determines all quantities; art is licensed Kenney/Quaternius CC0 ONLY.
## This is a small playable production slice, NOT full village / on-device LLM.
const Economy = preload("res://canglan_rev187/worldbox_life_sim.gd")
const Ecology = preload("res://canglan_rev187/ecology_growth.gd")
const NaturalPalette = preload("res://canglan_rev187/visual_palette.gd")
const KenneyMultiMesh = preload("res://canglan_rev187/kenney_multimesh.gd")
const RealSoilTerrain = preload("res://canglan_rev187/strata_terrain.gd")
const PlayerControl = preload("res://canglan_rev187/player_controller.gd")
const ManualQuality = preload("res://canglan_rev187/quality_profiles.gd")
const ASSETS := {
  "tree": "res://canglan_rev187/tree_oak.glb",
  "stone": "res://canglan_rev187/rocks_small.glb",
  "timber": "res://canglan_rev187/tree_log.glb",
  "fence": "res://canglan_rev187/wood_fence.glb",
  "steps": "res://canglan_rev187/stone_steps.glb",
  "door": "res://canglan_rev187/wood_door.glb",
  "worker": "res://canglan_rev187/animated_knight.glb"
}
const TOWN := "CL-REV186-HX-VILLAGE"
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
var quality: RefCounted
var sun_light: DirectionalLight3D
var scene_environment: Environment
var quality_diagnostic: Label
var quality_warning: Label
var quality_menu: PanelContainer
var quality_menu_visible: bool = false
var quality_summary: PanelContainer
var quality_details_visible: bool = true
var developer_ui_visible: bool = false # rev188: player-first default
var hidden_performance_panels: int = 0
var _old_profiler_nodes: Array[CanvasItem] = []
var _foundation_dig_clock: float = 0.0
var _foundation_excavation_count: int = 0
var _render_sync_counter: float = 0.0
# Previous draw-call limit 200 and 150k triangles are superseded
# by user-specific manual extreme/high/normal phone budgets.
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
# rev199 genuinely licensed CC0 hair and real sword are separate scene
# sources; they MUST NOT inflate 7 original economy/batch material sources.
var licensed_long_hair_source: Node3D
var licensed_flying_sword_source: Node3D
var _licensed_hair_attachments: int=0
var _licensed_actor_zero_alpha_fixed: int = 0
var natural_meshes: Dictionary = {}
# rev197: cheap real world collisions for already-licensed instanced trunks
# and stones; they follow harvesting/growth without duplicating GLB rendering.
var natural_colliders: Dictionary = {}
var workers: Dictionary = {}
var _hidden_game_world: Array[Node3D] = []
var _clock: float = 0.0
var _economy_clock: float = 0.0
# rev199: The WHOLE authoritative world clock can run faster, not just
# visual day/night. Every tick still spends and produces real inventory.
const WORLD_SPEEDS: Array[int]=[1,5,20,100]
var world_time_scale: int=1
var _total_accelerated_hours: int=0
var local_npc_ai_state: String="unavailable_missing_native_android_llama"
var _daylight_last_hour: int=-1
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
  name = "CanglanAutonomousEcologyWorldRev187"
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
  palette = NaturalPalette.new()
  _build_interface()
  _load_assets()
  _initialize_batches()
  _create_landscape()
  _seed_resources()
  _make_workers()
  _create_playable_player()
  _create_quality_hud()
  _hide_old_render_world()
  _hide_original_debug_labels()
  quality = ManualQuality.new()
  quality.call("initialize",self)
  _set_dev_ui_visible(false)
  _update_camera()
  _sync_living_daylight()
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
  # SubViewportContainer.stretch_shrink is an INTEGER (1,2,3...).
  # It cannot represent the requested 85% or 67% resolution. Use an
  # independent SubViewport rendered into a full-size native-UI TextureRect.
  # The TextureRect scales only 3D pixels; buttons/labels remain native.
  var frame := TextureRect.new()
  frame.name = "RealWorldViewportContainer"
  frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  frame.stretch_mode = TextureRect.STRETCH_SCALE
  frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
  frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  ui.add_child(frame)
  view = SubViewport.new()
  view.name = "ActualLicensed3DWorldViewport"
  view.size = Vector2i(get_viewport().get_visible_rect().size)
  view.own_world_3d = true
  view.msaa_3d = Viewport.MSAA_2X
  view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
  frame.add_child(view)
  frame.texture = view.get_texture()
  world = Node3D.new()
  world.name = "ResourceConservationAndConstruction"
  view.add_child(world)
  var sun := DirectionalLight3D.new()
  sun.name = "KenneySingleDirectionalSun"
  sun_light = sun
  sun.rotation_degrees = Vector3(-52, -33, 0)
  sun.light_color = Color("#ffecd0")
  sun.light_energy = 1.2
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
  colors.sky_top_color = Color("#258ed7")
  colors.sky_horizon_color = Color("#c5e8fa")
  colors.ground_horizon_color = Color("#a9d5d5")
  colors.ground_bottom_color = Color("#729e8d")
  colors.use_debanding = true
  sky.sky_material = colors
  environment.sky = sky
  environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
  environment.ambient_light_energy = 0.63
  environment.fog_enabled = true
  environment.fog_light_color = Color("#b8d9e8")
  environment.fog_density = 0.005
  scene_environment = environment
  var atmosphere := WorldEnvironment.new()
  atmosphere.name = "VillageAtmosphere"
  atmosphere.environment = environment
  world.add_child(atmosphere)
  camera = Camera3D.new()
  camera.name = "TouchOrbitCamera"
  camera.current = true
  camera.fov = 57.0
  camera.far = 450.0
  world.add_child(camera)
  var hud := VBoxContainer.new()
  hud.name = "ProductionInspector"
  hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
  hud.position = Vector2(18, 16)
  ui.add_child(hud)
  var title := Label.new()
  title.text = "苍岚·人生世界 · 草木生动 / 三档画质 / rev187"
  title.add_theme_font_size_override("font_size", 22)
  hud.add_child(title)
  notice = Label.new()
  notice.text = "左摇杆走路 · 右侧滑动向下看 · 上帝/飞行/自由视野"
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
  info_bg.position = Vector2(18, 290)
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

func _create_quality_hud() -> void:
  # Only ONE diagnostics panel in the original game. A fully native-UI
  # VBox ensures orange warnings cannot overlap the meter or stocks.
  quality_summary=PanelContainer.new()
  quality_summary.name="NativeResolutionRealQualityTelemetry"
  quality_summary.mouse_filter=Control.MOUSE_FILTER_IGNORE
  quality_summary.position=Vector2(18,126)
  ui.add_child(quality_summary)
  var box:=VBoxContainer.new()
  box.name="NonOverlappingDiagnosticVBox"
  quality_summary.add_child(box)
  var expand:=Button.new()
  expand.name="CollapseExpandAllMetrics"
  expand.text="性能监测  ▼  点击折叠"
  expand.mouse_filter=Control.MOUSE_FILTER_STOP
  expand.custom_minimum_size=Vector2(290,31)
  expand.pressed.connect(_toggle_diagnostics)
  box.add_child(expand)
  quality_diagnostic=Label.new()
  quality_diagnostic.name="LiveModeFPSTrianglesDrawAnd3DResolution"
  quality_diagnostic.add_theme_font_size_override("font_size",16)
  box.add_child(quality_diagnostic)
  quality_warning=Label.new()
  quality_warning.name="FPSBelow45WarningNoAutoDowngrade"
  quality_warning.visible=false
  quality_warning.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  quality_warning.custom_minimum_size=Vector2(340,22)
  quality_warning.add_theme_font_size_override("font_size",16)
  quality_warning.add_theme_color_override("font_color",Color("#ffb066"))
  box.add_child(quality_warning)
  var quality_button:=Button.new()
  quality_button.name="OpenManualQualitySettings"
  quality_button.text="画质·帧率设置"
  quality_button.custom_minimum_size=Vector2(155,47)
  quality_button.position=Vector2(maxf(500,get_viewport().get_visible_rect().size.x-515),81)
  quality_button.pressed.connect(_toggle_quality_settings)
  ui.add_child(quality_button)
  quality_menu=PanelContainer.new()
  quality_menu.name="ManuallySelectedPersistentOnePlusQualitySettings"
  quality_menu.position=Vector2(maxf(460,get_viewport().get_visible_rect().size.x-550),140)
  quality_menu.visible=false
  ui.add_child(quality_menu)
  var vertical:=VBoxContainer.new()
  quality_menu.add_child(vertical)
  var header:=Label.new()
  header.text="画质（仅手动切换 / 保存上次选择）"
  header.add_theme_font_size_override("font_size",16)
  vertical.add_child(header)
  var row:=HBoxContainer.new()
  vertical.add_child(row)
  for profile_name in ["极致画质","高档","普通"]:
    var option:=Button.new()
    option.name="SetQuality_"+profile_name
    option.text=profile_name
    option.custom_minimum_size=Vector2(99,38)
    option.pressed.connect(_select_quality.bind(profile_name))
    row.add_child(option)
  var fps_head:=Label.new()
  fps_head.text="帧率上限（不自动降档）"
  vertical.add_child(fps_head)
  var caps:=HBoxContainer.new()
  vertical.add_child(caps)
  for cap_mode in ["跟随刷新率","30","60","90","120"]:
    var button:=Button.new()
    button.name="SetFPSCap_"+cap_mode
    button.text=cap_mode
    button.custom_minimum_size=Vector2(100 if cap_mode=="跟随刷新率" else 52,37)
    button.pressed.connect(_select_fps_cap.bind(cap_mode))
    caps.add_child(button)
  var note:=Label.new()
  note.text="极致画质更耗电/易发热，但不会禁止使用\n低于45FPS只提醒；3D缩放不影响UI文字"
  note.add_theme_font_size_override("font_size",15)
  vertical.add_child(note)
  var close_button:=Button.new()
  close_button.text="收起设置"
  close_button.pressed.connect(_toggle_quality_settings)
  vertical.add_child(close_button)

# The live world continues to update, but all diagnostics and demo buttons
# are invisible until the player explicitly enables developer tools.
func _set_dev_ui_visible(value: bool) -> void:
  developer_ui_visible=value
  if ui==null:
    return
  for node_name in ["ProductionInspector","VillageStockAndWorkerHUD",
      "FollowActualBuilder","GeologicalEpochsOnly",
      "NativeResolutionRealQualityTelemetry","OpenManualQualitySettings"]:
    var item: CanvasItem=ui.get_node_or_null(node_name) as CanvasItem
    if item!=null:
      item.visible=value
  if not value:
    quality_menu_visible=false
    if quality_menu!=null:
      quality_menu.visible=false

func _toggle_diagnostics() -> void:
  quality_details_visible=not quality_details_visible
  quality_diagnostic.visible=quality_details_visible
  # Keep warning in the ONLY panel and never overlap a HUD item.
  quality_warning.visible=quality_details_visible and quality_warning.visible
  var fold: Button=quality_summary.get_node("NonOverlappingDiagnosticVBox/CollapseExpandAllMetrics")
  fold.text="性能监测  ▼  点击折叠" if quality_details_visible else "性能监测  ▶  已折叠"

func _toggle_quality_settings() -> void:
  quality_menu_visible=not quality_menu_visible
  quality_menu.visible=quality_menu_visible

func _select_quality(profile_name: String) -> void:
  if quality!=null and quality.call("apply",profile_name,true):
    controls.call("say","已选"+profile_name+"，手动切换，无自动降档")

func _select_fps_cap(mode: String) -> void:
  if quality!=null and quality.call("set_fps_mode",mode,true):
    controls.call("say","帧率已选："+mode+"（重启保留）")

func _hide_original_debug_labels() -> void:
  # Deactivate the legacy whole-game draw/GPU meter in the INHERITED Main.
  # The original panel can re-show text every frame, so clean every 0.5s.
  var base: Node=get_parent()
  for node in base.find_children("*","Control",true,false):
    if is_ancestor_of(node):
      continue
    var candidate: Control=node as Control
    var value: String=""
    if candidate is Label:
      value=(candidate as Label).text
    elif candidate is RichTextLabel:
      value=(candidate as RichTextLabel).text
    if not (value.contains("Draw ") or value.contains("三角面") or
      (value.contains("FPS") and value.contains("GPU"))):
      continue
    var target: CanvasItem=candidate
    if candidate.get_parent() is PanelContainer or candidate.get_parent() is ColorRect:
      target=candidate.get_parent()
    if not _old_profiler_nodes.has(target):
      _old_profiler_nodes.append(target)
      hidden_performance_panels+=1
    target.visible=false

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

# REV198 P0 real renderer bug caught by actual pixel QA, NOT inferred:
# The current CC0 Quaternius Knight GLB has an imported Armor material with
# albedo Alpha 0.0 and alpha-scissor transparency. MeshNode.visible=true and
# Godot has draw calls, but the PLAYER AND NPCs were visually invisible.
# Fix each deliberately solid body surface once at the legally licensed
# source scene, preserving all existing GLB geometry and animation/skins.
func _repair_licensed_opaque_character_model(source: Node3D) -> void:
  for visual in source.find_children("*","MeshInstance3D",true,false):
    var part: MeshInstance3D=visual as MeshInstance3D
    if part.mesh==null:
      continue
    for surface in range(part.mesh.get_surface_count()):
      var old: Material=part.get_active_material(surface)
      if old is StandardMaterial3D:
        var original: StandardMaterial3D=old as StandardMaterial3D
        if original.albedo_color.a<=0.01:
          var material: StandardMaterial3D=original.duplicate(true) as StandardMaterial3D
          var original_tint: Color=material.albedo_color
          original_tint.a=1.0
          material.albedo_color=original_tint
          # Alpha-zero BLEND/SCISSOR hashes ALL pixels away. Solid armor,
          # skin and boots should not be culled by an accidental alpha.
          material.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
          if original.resource_name.to_lower().contains("skin"):
            # Undo the old yellow-metal face look without changing the
            # original Quaternius anatomy or faking a 2D face overlay.
            material.albedo_color=Color("#d9ae9e")
            material.roughness=0.91
            material.metallic=0.0
          part.set_surface_override_material(surface,material)
          _licensed_actor_zero_alpha_fixed+=1

# Existing Quaternius Universal Base Characters Standard Long hairstyle:
# the packed GLB preserves the author's original vertices/normals/UVs.
# This is a static head attachment preview. A new full humanoid retarget
# will be needed for truly swaying long hair; never claim this is it.
func _attach_real_cc0_long_hair(actor: Node3D,variant: int=0) -> bool:
  if licensed_long_hair_source==null:
    return false
  var mesh_parts: Array[Node]=licensed_long_hair_source.find_children(
    "*","MeshInstance3D",true,false)
  if mesh_parts.is_empty():
    return false
  var source: MeshInstance3D=mesh_parts[0] as MeshInstance3D
  if source.mesh==null:
    return false
  var hair:=MeshInstance3D.new()
  hair.name="ActualCC0QuaterniusHairLongNOTArtificialHelmet"
  hair.mesh=source.mesh
  var fabric:=StandardMaterial3D.new()
  fabric.albedo_color=Color("#1c2833") if variant==0 else (
    Color("#48352d") if variant==1 else Color("#343337"))
  fabric.roughness=0.93
  fabric.metallic=0.0
  fabric.cull_mode=BaseMaterial3D.CULL_DISABLED
  hair.material_override=fabric
  hair.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON
  # Hair GLB shares Quaternius's ~1.75m anthropometric coordinate frame.
  # Attach after actor height normalization; do not rescale the gameplay
  # collision body, or snap to a position detached from the real player.
  hair.position=Vector3(0.0,0.015,0.0)
  actor.add_child(hair)
  _licensed_hair_attachments+=1
  return true

func _load_assets() -> void:
  for role in ASSETS:
    var art := _parse_existing_cc0(String(ASSETS[role]))
    if art == null:
      continue
    if role=="worker":
      _repair_licensed_opaque_character_model(art)
    asset_sources[role] = art
  licensed_long_hair_source=_parse_existing_cc0(
    "res://canglan_rev187/quaternius_hair_long_static.glb")
  licensed_flying_sword_source=_parse_existing_cc0(
    "res://canglan_rev187/quaternius_knight_sword.glb")
  if licensed_flying_sword_source!=null:
    _repair_licensed_opaque_character_model(licensed_flying_sword_source)
  if licensed_long_hair_source==null or licensed_flying_sword_source==null:
    asset_errors.append("REV199_MISSING_REAL_CC0_HAIR_SWORD_NOT_SELF_MODELED")

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
  if role in ["tree","stone"]:
    _register_resource_collision(id,part,role)
  if role=="steps" or id.begins_with("NPCPlacedTimber_") or id.begins_with("NPCAssembledFence_") or id.begins_with("NPCInstalledLicensedDoor"):
    _register_camera_occluder(id,part,role)
  return part

func _register_resource_collision(id: String,proxy: Node3D,role: String) -> void:
  var body:=StaticBody3D.new()
  body.name="ActualPhysicalNaturalResource_"+id
  body.collision_layer=2
  body.collision_mask=0
  var shape:=CollisionShape3D.new()
  shape.name="TrunkOrRockSolidCollider"
  if role=="tree":
    var trunk:=CylinderShape3D.new()
    trunk.radius=0.36
    trunk.height=2.25
    shape.shape=trunk
    body.position=proxy.position+Vector3(0,1.125,0)
  else:
    var stone:=SphereShape3D.new()
    stone.radius=0.70
    shape.shape=stone
    body.position=proxy.position+Vector3(0,0.42,0)
  body.add_child(shape)
  world.add_child(body)
  body.set_meta("source_entity_id",id)
  natural_colliders[id]=body

func _sync_resource_collisions() -> void:
  for id in natural_colliders:
    var body: StaticBody3D=natural_colliders[id]
    if not is_instance_valid(body) or not natural_meshes.has(id):
      continue
    var visual: Node3D=natural_meshes[id]
    if not is_instance_valid(visual):
      body.collision_layer=0
      continue
    body.collision_layer=2 if visual.visible else 0
    var scale_amount: float=clampf(visual.scale.x,0.10,1.8)
    body.scale=Vector3.ONE*scale_amount

func _register_camera_occluder(entity_id: String, proxy: Node3D, role: String) -> void:
  # Actual licensed model draw remains batched; only a cheap physics proxy
  # is attached so the camera CANNOT clip through building walls/doors.
  var box:=StaticBody3D.new()
  box.name="ConstructionOccluder_"+entity_id
  # Ordinary construction walls stop both camera and player. Staircases
  # are WALKABLE ramps on bit 4, not impenetrable 1m-high cubic barriers.
  box.collision_layer=4 if role=="steps" else 2
  box.collision_mask=0
  box.position=proxy.position+(Vector3(0,0.48,0) if role=="steps" else Vector3(0,0.8,0))
  var shape:=CollisionShape3D.new()
  shape.name="TrueWalkableStairRampCollision" if role=="steps" else "TrueConstructedWallCollision"
  var form:=BoxShape3D.new()
  if role=="fence":
    form.size=Vector3(1.65,1.7,0.42)
  elif role=="door":
    form.size=Vector3(1.6,2.4,0.52)
  elif role=="steps":
    form.size=Vector3(1.60,0.18,2.0)
    shape.rotation_degrees.x=18.0
  else:
    form.size=Vector3(0.75,2.1,0.75)
  shape.shape=form
  box.add_child(shape)
  world.add_child(box)

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
    {"id":"CL-NPC-0184-03","kind":"builder","name":"建筑工"}
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
    _attach_real_cc0_long_hair(character,workers.size()%3)
    var label := Label3D.new()
    label.name = "ShortNPCProfessionNearPlayer_" + code
    # Unique IDs stay systemic data, NEVER giant wall text on top of NPCs.
    label.text = String(profile["name"])
    label.font_size = 22
    label.pixel_size = 0.004
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.no_depth_test = false
    label.visibility_range_end = 13.0
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
    character.position.y = float(terrain_world.call("height_at",character.position.x,character.position.z)) + float(character.get_meta("actor_ground_offset_y",0.0))
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
        _add_event("建筑工挖出" + String(spoil.get("kind","土")) + "·地基深" + str(spoil.get("depth_m",0.0))+"米")
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

func cycle_world_time_scale() -> int:
  var idx: int=WORLD_SPEEDS.find(world_time_scale)
  world_time_scale=WORLD_SPEEDS[(idx+1)%WORLD_SPEEDS.size()]
  # Never reset the partial hour; the entire world stays on one clock.
  _update_status()
  return world_time_scale

func _sync_living_daylight() -> void:
  # Only step the sky on a TRUE economy-hour boundary, not per FPS frame.
  var h: int=int(sim.hour)
  if h==_daylight_last_hour or scene_environment==null:
    return
  _daylight_last_hour=h
  var radians: float=(float(h)-6.0)/24.0*TAU
  var altitude: float=sin(radians)*90.0
  var daylight: float=clampf(sin(radians),0.0,1.0)
  # Twilight is not a gray fog overlay. Dusk becomes blue and the moonlit
  # night has only ~22% ambient. One directional sun, no mobile raytracing.
  sun_light.rotation_degrees=Vector3(-maxf(8.0,altitude),-55.0,0)
  sun_light.light_energy=0.16+daylight*0.97
  sun_light.light_color=Color("#ffdfb5").lerp(Color("#fff0dd"),daylight)
  var backdrop: ProceduralSkyMaterial=scene_environment.sky.sky_material
  backdrop.sky_top_color=Color("#102944").lerp(Color("#147ec7"),daylight)
  backdrop.sky_horizon_color=Color("#274869").lerp(Color("#b9e7ff"),daylight)
  backdrop.ground_horizon_color=Color("#213d50").lerp(Color("#83bbaa"),daylight)
  backdrop.ground_bottom_color=Color("#223846").lerp(Color("#527d61"),daylight)
  scene_environment.fog_light_color=Color("#283e5a").lerp(Color("#8fb5c5"),daylight)
  scene_environment.ambient_light_energy=0.18+daylight*0.28

func get_living_clock() -> Dictionary:
  return {"day":int(sim.day),"hour":int(sim.hour),
    "minutes":clampi(roundi(_economy_clock/12.0*60.0),0,59),
    "speed_multiplier":world_time_scale,
    "whole_world_hours_processed":_total_accelerated_hours,
    "npc_model_loaded":false,
    "npc_ai_status":local_npc_ai_state,
    "npc_real_rule_simulation":true}

func _process(delta: float) -> void:
  if _closed:
    return
  if controls != null:
    controls.call("step",delta)
  _clock += delta
  # Keep the original Godot 0.7s/step NPC/economy deterministic QA and
  # background catch-up behavior. New 100x multiplier must NOT silently
  # slow the original 1x simulation by clamping every frame to 0.10s.
  var accelerated_delta: float=clampf(delta,0.0,0.75)*float(world_time_scale)
  # Loop EACH skipped hour through the SAME sim, ecology and inventory
  # state transitions. Do not jump a visual clock past unpaid production.
  _economy_clock+=accelerated_delta
  var advanced: int=0
  while _economy_clock>=12.0 and advanced<32:
    _economy_clock-=12.0
    sim.tick()
    eco.advance_ecology_hours(1)
    _total_accelerated_hours+=1
    advanced+=1
  if advanced>0:
    _refresh_ecology_meshes()
  _sync_living_daylight()
  for worker in workers.values():
    if String(worker["kind"]) == "builder":
      _move_builder(worker, accelerated_delta)
    else:
      _move_gatherer(worker, accelerated_delta)
  var hero: Node3D = controls.get("actor") if controls!=null else null
  var visible_label_distance: float = float(quality.call("render_profile").get("name_distance",13.0)) if quality!=null else 13.0
  for code in workers:
    var actor: Node3D = workers[code]["node"]
    if npc_nameplates.has(code):
      var tag: Label3D = npc_nameplates[code]
      tag.position = Vector3(actor.position.x,
        float(terrain_world.call("height_at",actor.position.x,actor.position.z))+2.10,
        actor.position.z)
      tag.visible = hero!=null and Vector2(hero.position.x-actor.position.x,hero.position.z-actor.position.z).length()<visible_label_distance
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
    _sync_resource_collisions()
  if _clock >= 0.5:
    _clock=0.0
    _update_status()
    _hide_original_debug_labels()
    if quality!=null:
      # Keep vegetation child nodes aligned with real loaded physical chunks.
      # No separate far-away cosmetic terrain creates unlimited memory usage.
      quality.call("sync_streamed_meadows")
      quality.call("update_diagnostics")
      quality_warning.visible=quality_details_visible and quality_warning.visible

func _close_world() -> void:
  _closed = true
  ui.get_node("RealWorldViewportContainer").visible = false
  ui.get_node("ProductionInspector").visible = false
  ui.get_node("VillageStockAndWorkerHUD").visible = false
  ui.get_node("FollowActualBuilder").visible = false
  ui.get_node("GeologicalEpochsOnly").visible = false
  ui.get_node("ReopenAutonomousWorld").visible = true
  ui.get_node("NativeResolutionRealQualityTelemetry").visible = false
  ui.get_node("OpenManualQualitySettings").visible = false
  quality_warning.visible = false
  quality_menu.visible = false
  for item in _old_profiler_nodes:
    if is_instance_valid(item):
      item.visible = true
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
  ui.get_node("NativeResolutionRealQualityTelemetry").visible = true
  ui.get_node("OpenManualQualitySettings").visible = true
  _hide_original_debug_labels()
  if controls != null:
    controls.call("set_enabled",true)

func stats() -> Dictionary:
  var stock: Dictionary = sim.villages[TOWN]["stock"]
  return {"revision": 187, "world_seed": 20261017,
    "worker_count": workers.size(), "resource_node_count": sim.natural_nodes.size(),
    "living_clock":get_living_clock(),
    "whole_world_speed_includes_npc_construction":true,
    "local_gguf_installed":false,
    "native_llama_bridge_present":ClassDB.class_exists("CanglanLocalLLM"),
    "source_assets": asset_sources.size(), "missing_assets": asset_errors.duplicate(),
    "real_cc0_long_hair_attached_to_entities":_licensed_hair_attachments,
    "real_cc0_sword_loaded":licensed_flying_sword_source!=null,
    "real_cc0_hair_loaded":licensed_long_hair_source!=null,
    "licensed_animated_body_materials_fixed_from_alpha_zero":_licensed_actor_zero_alpha_fixed,
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
    "palette_unlimited":palette.call("color_count_unrestricted"),
    "legacy_perf_panels_hidden":hidden_performance_panels,
    "old_fixed_five_swatch_rule_removed":true,
    "nonoverlap_collapsible_diagnostics":true,
    "kenney_batch": batch_renderer.call("stats"),
    "real_resource_collision_count":natural_colliders.size(),
    "walkable_stair_ramp":world.get_node_or_null("ConstructionOccluder_LicensedWorksiteVisibleStoneApproach")!=null,
    "base_3d_lights": world.find_children("*", "DirectionalLight3D", true, false).size(),
    "performance_draw_reference": int(quality.call("render_profile").get("draw_reference",800)) if quality!=null else 800,
    "performance_triangle_reference": int(quality.call("render_profile").get("triangle_reference",600000)) if quality!=null else 600000,
    "manual_quality": quality.call("get_stats") if quality!=null else {},
    "manual_quality_selected": quality.get("selected") if quality!=null else "高档",
    "native_resolution_ui": true,
    "no_auto_quality_switch": true,
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
  var terrain_y: float = 0.0
  if terrain_world != null:
    terrain_y = float(terrain_world.call("height_at",actor.position.x,actor.position.z))
  actor.position.y += terrain_y - new_bounds.x
  # Kenney/Quaternius GLB mesh origins are not at feet. Preserve the
  # import-specific offset at every future movement, not only on spawn.
  actor.set_meta("actor_ground_offset_y",actor.position.y-terrain_y)
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
  # rev199: two more GLTFDocument-generated meshes were created as
  # freestanding source templates (hair+sword), not children of world.
  # Without explicit release Godot aborts at exit with 2 DummyMesh
  # +9 Materials+2 Shaders still allocated. Cleanup is a real P0 gate.
  if licensed_long_hair_source!=null and is_instance_valid(licensed_long_hair_source):
    licensed_long_hair_source.free()
  licensed_long_hair_source=null
  if licensed_flying_sword_source!=null and is_instance_valid(licensed_flying_sword_source):
    licensed_flying_sword_source.free()
  licensed_flying_sword_source=null
  _hidden_game_world.clear()
  _old_profiler_nodes.clear()
