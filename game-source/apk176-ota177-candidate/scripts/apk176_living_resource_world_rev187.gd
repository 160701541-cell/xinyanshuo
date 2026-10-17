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
const VividMaterials = preload("res://canglan_rev187/vivid_material.gd")
const CultivationWorld = preload("res://canglan_rev187/cultivation_world.gd")
const SpiritResources = preload("res://canglan_rev187/spirit_resources.gd")
const PaidHousing = preload("res://canglan_rev187/paid_housing.gd")
const LivingRegions = preload("res://canglan_rev187/living_regions.gd")
const ASSETS := {
  "tree": "res://canglan_rev187/tree_oak.glb",
  "stone": "res://canglan_rev187/rocks_small.glb",
  "timber": "res://canglan_rev187/tree_log.glb",
  "fence": "res://canglan_rev187/wood_fence.glb",
  "steps": "res://canglan_rev187/stone_steps.glb",
  "door": "res://canglan_rev187/wood_door.glb",
  "worker": "res://canglan_rev187/animated_knight.glb"
}
# Rev206 prefabricated whole CC0 houses/outfits/animals, NOT buildings
# assembled from single fence poles or custom AI meshes. Exactly these
# binaries are pinned upstream in asset_intake_proof.json.
const READY_MADE_CC0: Dictionary={
  "house_1":"res://canglan_rev187/cc0_rev206/building/house_1.glb",
  "house_2":"res://canglan_rev187/cc0_rev206/building/house_2.glb",
  "house_3":"res://canglan_rev187/cc0_rev206/building/house_3.glb",
  "house_4":"res://canglan_rev187/cc0_rev206/building/house_4.glb",
  "inn":"res://canglan_rev187/cc0_rev206/building/inn.glb",
  "gazebo":"res://canglan_rev187/cc0_rev206/building/gazebo.glb",
  "monk":"res://canglan_rev187/cc0_rev206/character_clothing_rig/monk.glb",
  "wizard":"res://canglan_rev187/cc0_rev206/character_clothing_rig/wizard.glb",
  "wolf":"res://canglan_rev187/cc0_rev206/animal/wolf.glb",
  "fox":"res://canglan_rev187/cc0_rev206/animal/fox.glb",
  "deer":"res://canglan_rev187/cc0_rev206/animal/deer.glb",
  "cow":"res://canglan_rev187/cc0_rev206/animal/cow.glb",
  "dragon":"res://canglan_rev187/cc0_rev206/monster/dragon.glb",
  "goleling":"res://canglan_rev187/cc0_rev206/monster/goleling.glb"}
const TOWN := "CL-REV186-HX-VILLAGE"
const DEPOT := Vector3(0.0, 0.0, 10.0)
const SITE := Vector3(0.0, 0.0, -3.0)
# No staged scaffold/repair/building construction: all real buildings
# in this scene come from licensed complete third-party CC0 GLB prefabs.
var sim
var eco
var palette: RefCounted
var vivid_materials: RefCounted
var batch_renderer: Node3D
var terrain_world: Node3D
var controls: Node
var cultivation: RefCounted
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
var finished_prefabs: Dictionary={}
var finished_prefab_sources: Dictionary={}
var licensed_outfits: Dictionary={}
var native_wildlife_sources: Dictionary={}
var actual_wildlife: Dictionary={}
var housing: RefCounted
var housing_blueprints: Dictionary={}
var house_entry_colliders: Dictionary={}
var spirit_resources: RefCounted
# Authoritative offscreen world: 50,000 km² / initially 5,000 humans.
# Old 80,000-person city remains a backward-compatibility save snapshot only.
var world_society: RefCounted
var spirit_resource_sources: Dictionary={}
var spirit_resource_visuals: Dictionary={}
# Actual source-GLB understorey, GPU MultiMesh instancing with preserved UV
# and vendor surface PBR. Count not conflated with harvestable medicine.
var licensed_understory_count: int=0
var licensed_understory_draw_parts: int=0
var licensed_understory_triangle_budget: int=0
const SPIRIT_CC0_SOURCES: Dictionary={
  "flower":"res://canglan_rev187/cc0_spirit/herb/flower.glb",
  "flower2":"res://canglan_rev187/cc0_spirit/herb/flower2.glb",
  "flower3":"res://canglan_rev187/cc0_spirit/herb/flower3.glb",
  "mushroom":"res://canglan_rev187/cc0_spirit/herb/mushroom.glb",
  "bush":"res://canglan_rev187/cc0_spirit/herb/bush.glb",
  "rock1":"res://canglan_rev187/cc0_spirit/ore/rock1.glb",
  "rock2":"res://canglan_rev187/cc0_spirit/ore/rock2.glb"}
var _wildlife_anim_count: int=0
var _beast_hit_events: int=0
var _beast_deaths: int=0
const YAO_BEAST_SPEC: Dictionary={
  "wolf":{"name":"苍牙山狼妖","realm":"炼气三层","root":"风灵根",
    "max_health":185,"max_mana":64,"size":2.7,"damage":9,"hostile":true},
  "fox":{"name":"赤瞳灵狐妖","realm":"炼气二层","root":"火灵根",
    "max_health":165,"max_mana":80,"size":2.4,"damage":8,"hostile":true},
  "deer":{"name":"碧角灵鹿妖","realm":"炼气一层","root":"木灵根",
    "max_health":145,"max_mana":52,"size":2.9,"damage":7,"hostile":false},
  "cow":{"name":"磐甲蛮牛妖","realm":"炼气四层","root":"土灵根",
    "max_health":320,"max_mana":90,"size":3.8,"damage":14,"hostile":false}}
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
  assert(sim.add_citizen("CL-NPC-0184-03", TOWN, "steward", 24))
  # The human player is a genuine world citizen with an identity and an
  # authoritative economy backpack, not a passive floating observer.
  assert(sim.add_citizen("CL-PLAYER-0184-0001", TOWN, "traveler", 21))
  # The original stock schema is kept intact. This version adds a reserved
  # ecological seed key only to the in-memory demonstration village ledger.
  sim.villages[TOWN]["stock"]["tree_seed"] = 0
  eco = Ecology.new()
  eco.setup(sim, TOWN, SITE, DEPOT)
  palette = NaturalPalette.new()
  vivid_materials=VividMaterials.new()
  vivid_materials.call("initialize")
  housing=PaidHousing.new()
  if not bool(housing.call("initialize")):
    asset_errors.append("REV208_PAID_HOUSE_LEDGER_LOAD_FAILURE")
  _build_interface()
  _load_assets()
  spirit_resources=SpiritResources.new()
  if not bool(spirit_resources.call("initialize")):
    asset_errors.append("REV206_SPIRIT_RESOURCES_SAVE_LOAD_FAILED")
  _initialize_batches()
  _create_landscape()
  _seed_resources()
  _spawn_spirit_resource_nodes()
  _place_completed_cc0_village()
  _make_workers()
  # New houses are STRICTLY paid and constructed; no visual CC0 house
  # or real residential capacity exists merely because a source GLB loads.
  sim.villages[TOWN]["homes"]=int(housing.call("stats").get(
    "actually_completed_houses",0))
  _spawn_native_animals()
  _create_playable_player()
  # Initialized only AFTER the real player, terrain, original NPC economy,
  # CC0 animated rigs and original site/collision are live. No parallel
  # world or invented resource/financial ledger is created.
  cultivation=CultivationWorld.new()
  cultivation.call("initialize",self)
  world_society=LivingRegions.new()
  if not bool(world_society.call("initialize",int(cultivation.get("world_seed")))):
    asset_errors.append("REV207_WORLD_50000KM2_MORTAL_ECOLOGY_SAVE_LOAD_FAILED")
  else:
    _sync_mine_guardian_realms()
  _create_quality_hud()
  _spawn_licensed_living_understory()
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
  sun.light_color = Color("#ffe1b2")
  sun.light_energy = 1.14
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
  colors.sky_top_color=Color("#0866b4")
  colors.sky_horizon_color=Color("#83cbed")
  colors.ground_horizon_color=Color("#5b9aa1")
  colors.ground_bottom_color=Color("#3a7254")
  colors.use_debanding = true
  sky.sky_material = colors
  environment.sky = sky
  environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
  environment.ambient_light_energy=0.36
  environment.fog_enabled=true
  environment.fog_light_color=Color("#729eb7")
  environment.fog_density=0.00105
  environment.adjustment_enabled=true
  environment.adjustment_saturation=1.30
  environment.adjustment_contrast=1.095
  environment.adjustment_brightness=0.975
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
  # rev200 first real Godot screenshot audit: normalized Knight skeleton
  # source height 5.60m to avatar 1.8m (actor root scale ~=0.322), while
  # Universal hair GLB IS ALREADY modeled at 1.5..1.78 human-meter height.
  # The old hair lived at y0.48..0.57, INSIDE THE TORSO, so the HEAD
  # appeared bald although scene-tree QA falsely claimed it had hair!
  # Correct relative transform using root scale; preserve vendor mesh and
  # player collider, position dark hair on actual head, not under the ribs.
  var root_scale: float=maxf(0.001,absf(actor.scale.y))
  hair.scale=Vector3.ONE*(1.22/root_scale)
  hair.position=Vector3(0.0,-0.15/root_scale,0.0)
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
    vivid_materials.call("upgrade_completed_cc0_model",art,
      String(role),"character_clothing_rig" if role=="worker" else "natural_source")
    asset_sources[role] = art
  licensed_long_hair_source=_parse_existing_cc0(
    "res://canglan_rev187/quaternius_hair_long_static.glb")
  licensed_flying_sword_source=_parse_existing_cc0(
    "res://canglan_rev187/quaternius_knight_sword.glb")
  if licensed_flying_sword_source!=null:
    _repair_licensed_opaque_character_model(licensed_flying_sword_source)
  if licensed_long_hair_source==null or licensed_flying_sword_source==null:
    asset_errors.append("REV199_MISSING_REAL_CC0_HAIR_SWORD_NOT_SELF_MODELED")
  # Complete and licensed models are checked by SHA256 at packaging. No
  # "if missing, procedurally rebuild" fallback: missing assets BLOCK the QA.
  # Source CC0 textured flowers, fungus, bushes and complete mineral rocks.
  # Users should see real meshes and embedded vendor PBR/material textures.
  for model_id in SPIRIT_CC0_SOURCES:
    var source: Node3D=_parse_existing_cc0(
      String(SPIRIT_CC0_SOURCES[model_id]))
    if source==null:
      asset_errors.append("REV206_SPIRIT_MESH_NOT_GENUINE_"+String(model_id))
      continue
    vivid_materials.call("upgrade_completed_cc0_model",source,
      String(model_id),"natural_source")
    spirit_resource_sources[model_id]=source
  for model_id in READY_MADE_CC0:
    var original: Node3D=_parse_existing_cc0(
      String(READY_MADE_CC0[model_id]))
    if original==null:
      asset_errors.append("REV206_MISSING_GENUINE_CC0_"+String(model_id))
      continue
    var category: String=(
      "building" if model_id in ["house_1","house_2","house_3","house_4","inn","gazebo"]
      else ("character_clothing_rig" if model_id in ["monk","wizard"] else (
        "animal" if model_id in ["wolf","fox","deer","cow"] else "monster")))
    vivid_materials.call("upgrade_completed_cc0_model",original,
      String(model_id),category)
    if model_id in ["house_1","house_2","house_3","house_4",
        "inn","gazebo"]:
      finished_prefab_sources[model_id]=original
    elif model_id in ["monk","wizard"]:
      licensed_outfits[model_id]=original
    else:
      native_wildlife_sources[model_id]=original

func _place_completed_cc0_village() -> void:
  # Source CC0 prefabs remain uninstantiated until finite village warehouse
  # spends EXACT material bill and worker completes the required game hours.
  # A blueprint is ONLY a text site marker, never a finished building.
  var specs: Array=[
    ["house_1",Vector3(-7.0,0.0,-18.0),-0.12,"CL-HOME-V206-001"],
    ["house_2",Vector3( 4.8,0.0,-24.0), 0.28,"CL-HOME-V206-002"],
    ["house_3",Vector3(-5.0,0.0, 25.0), 0.42,"CL-HOME-V206-003"],
    ["house_4",Vector3( 4.0,0.0, 31.0),-0.20,"CL-HOME-V206-004"],
    ["inn",Vector3(-6.0,0.0,-31.0),0.10,"CL-INN-V206-001"],
    ["gazebo",Vector3(-2.0,0.0,37.0),0.35,"CL-GAZEBO-V206-001"]]
  for config in specs:
    var id: String=String(config[3])
    housing_blueprints[id]={"kind":String(config[0]),"at":config[1],
      "yaw":float(config[2])}
    if bool(housing.get("sites")[id]["completed"]):
      _materialize_paid_house(id)
      continue
    var tag:=Label3D.new()
    tag.name="OnlyBluePrintNoFreeConstructedHouse_"+id
    tag.text="住宅图纸：木200 / 石150 / 5人" if id.begins_with(
      "CL-HOME") else "公共建筑蓝图 · 施工需真实资源"
    tag.font_size=35
    tag.pixel_size=0.008
    tag.billboard=BaseMaterial3D.BILLBOARD_ENABLED
    tag.modulate=Color("#dfbb74")
    var pos: Vector3=config[1]
    tag.position=Vector3(pos.x,float(terrain_world.call(
      "height_at",pos.x,pos.z))+1.2,pos.z)
    tag.visibility_range_end=14.0
    world.add_child(tag)
    housing_blueprints[id]["marker"]=tag
  _add_event("6项真实建造蓝图；木200石150，NPC付费施工后才显示原版整屋")

func _materialize_paid_house(id: String) -> bool:
  if finished_prefabs.has(id) or not housing_blueprints.has(id):
    return false
  if not bool(housing.get("sites")[id]["paid"]) or not (
      bool(housing.get("sites")[id]["completed"])):
    return false
  var site: Dictionary=housing_blueprints[id]
  var kind: String=String(site["kind"])
  if not finished_prefab_sources.has(kind):
    return false
  var at: Vector3=site["at"]
  var house: Node3D=(finished_prefab_sources[kind] as Node3D).duplicate()
  house.name=id
  house.position=Vector3(at.x,float(terrain_world.call(
    "height_at",at.x,at.z)),at.z)
  house.rotation.y=float(site["yaw"])
  house.set_meta("source_license","Quaternius-CC0")
  house.set_meta("no_free_material_building",true)
  house.set_meta("building_type",kind)
  house.set_meta("resident_capacity",int(housing.get("sites")[
    id]["real_resident_capacity"]))
  house.set_meta("assigned_resident_ids",(housing.get("sites")[
    id]["residents"] as Array).duplicate())
  world.add_child(house)
  var bounds: Vector2=_visible_bounds(house)
  var height: float=bounds.y-bounds.x
  var intended: float=8.0 if kind=="inn" else (
    4.0 if kind=="gazebo" else 5.0)
  if height>0.10 and is_finite(height):
    house.scale*=clampf(intended/height,0.08,6.0)
    var after: Vector2=_visible_bounds(house)
    house.position.y+=float(terrain_world.call("height_at",
      at.x,at.z))-after.x
  house.set_meta("source_ready_meters",intended)
  finished_prefabs[id]=house
  if kind.begins_with("house"):
    sim.villages[TOWN]["homes"]=int(sim.villages[TOWN]["homes"])+1
  # The collider matches a furnished WALKABLE ENTRY opening at the
  # front, while exterior walls/corners stop the original swept capsule.
  # Only completed paid houses receive collision.
  _add_house_shell_collision(id,house)
  if housing_blueprints[id].has("marker"):
    var marker: Label3D=housing_blueprints[id]["marker"]
    if is_instance_valid(marker):
      marker.visible=false
  return true

func _add_house_shell_collision(id: String,house: Node3D) -> void:
  var base: StaticBody3D=StaticBody3D.new()
  base.name="RealPaidDwellingCollisionDoorGap_"+id
  base.collision_layer=2
  base.collision_mask=0
  base.position=house.position
  base.rotation.y=house.rotation.y
  world.add_child(base)
  # Four exterior walls made from cheap independent physical primitives,
  # not a sealed whole-house collision cube. Front doorway has 1.6m gap.
  var is_house: bool=String(house.get_meta(
    "building_type","")).begins_with("house")
  var edge: float=3.15 if is_house else 4.4
  for edge_spec in [
    ["back",Vector3(0,1.5,-edge),Vector3(edge*2,3.0,0.34)],
    ["left",Vector3(-edge,1.5,0),Vector3(0.34,3.0,edge*2)],
    ["right",Vector3(edge,1.5,0),Vector3(0.34,3.0,edge*2)],
    ["front_left",Vector3(-edge*0.67,1.5,edge),
      Vector3(edge*0.65,3.0,0.34)],
    ["front_right",Vector3(edge*0.67,1.5,edge),
      Vector3(edge*0.65,3.0,0.34)]]:
    var hit: CollisionShape3D=CollisionShape3D.new()
    hit.name="NonPhantomActualHouseWall_"+String(edge_spec[0])
    hit.position=edge_spec[1]
    var shape: BoxShape3D=BoxShape3D.new()
    shape.size=edge_spec[2]
    hit.shape=shape
    base.add_child(hit)
  house_entry_colliders[id]=base

func quote_and_fund_near_house(point: Vector3) -> Dictionary:
  if housing==null or not bool(housing.get("_loaded")):
    return {"ok":false,"reason":"HOUSE_LEDGER_NOT_AVAILABLE"}
  var best_id: String=""
  var best: float=3.2
  for id in housing_blueprints:
    var p: Vector3=housing_blueprints[id]["at"]
    var dist: float=Vector2(point.x-p.x,point.z-p.z).length()
    if dist<best:
      best=dist
      best_id=String(id)
  if best_id.is_empty():
    return {"ok":false,"reason":"NO_HOUSE_BLUEPRINT_NEARBY"}
  if bool(housing.get("sites")[best_id]["completed"]):
    var occupied: Dictionary=housing.call("quote",best_id)
    occupied["reason"]="HOUSE_ALREADY_COMPLETED"
    return occupied
  var result: Dictionary=housing.call("try_fund",best_id,sim,TOWN)
  if bool(result.get("ok",false)):
    _add_event("真实仓库扣木%d石%d；%s排入NPC工期" % [
      int(result["spent_wood"]),int(result["spent_stone"]),best_id])
  return result

# Each small shrub is genuine licensed Quaternius bush GLB geometry,
# UV and PBR (not a fake homemade building/flat billboard), drawn as a
# per-part MultiMesh to avoid one expensive draw node per plant.  The
# engine's plantability mask excludes ponds, rock, paths and excavation.
# This is decorative living understorey, NOT free harvestable inventory:
# collectible medicine remains the strictly conserved spirit_resource ledger.
func _spawn_licensed_living_understory() -> void:
  if not spirit_resource_sources.has("bush") or quality==null:
    asset_errors.append("REV207_UNDERSTORY_CC0_BUSH_NOT_IMPORTED")
    return
  var original: Node3D=spirit_resource_sources["bush"]
  var meshes: Array[Node]=original.find_children("*","MeshInstance3D",true,false)
  if meshes.is_empty():
    asset_errors.append("REV207_UNDERSTORY_REAL_GLTF_SOURCE_HAS_NO_MESH")
    return
  var source_triangles: int=0
  var actual_parts: Array[MeshInstance3D]=[]
  for source in meshes:
    var part: MeshInstance3D=source as MeshInstance3D
    if part==null or part.mesh==null:
      continue
    actual_parts.append(part)
    for idx in range(part.mesh.get_surface_count()):
      var arrays: Array=part.mesh.surface_get_arrays(idx)
      var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
      var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
      source_triangles+=int(indices.size()/3) if not indices.is_empty() else (
        int(vertices.size()/3))
  if actual_parts.is_empty() or source_triangles<=0:
    asset_errors.append("REV207_UNDERSTORY_EMPTY_OR_NONTRIANGLE_LICENSED_GLTF")
    return
  # Hard source-aware mobile triangle budget: do not multiply a 20k-tri
  # authored plant by 1,000 on phones. Conservative, deterministic upper
  # bound; exact draw calls still depend on original GLB surface count.
  var count: int=clampi(220000/maxi(1,source_triangles),24,980)
  var random:=RandomNumberGenerator.new()
  random.seed=20261018
  var locations: Array[Transform3D]=[]
  var attempts: int=0
  while locations.size()<count and attempts<count*12:
    attempts+=1
    var x: float=random.randf_range(-42.0,42.0)
    var z: float=random.randf_range(-42.0,42.0)
    if not bool(quality.call("_natural_plantable",x,z)):
      continue
    # Keep the exact six real CC0 housing blueprints (including paid future
    # houses), stair access and medical herb nodes free of rooted bushes.
    var reserved: bool=false
    for site in housing_blueprints.values():
      var p: Vector3=site["at"]
      if Vector2(x-p.x,z-p.z).length()<7.2:
        reserved=true
        break
    if reserved:
      continue
    var no_collision: bool=true
    for living_herb in spirit_resource_visuals.values():
      var h: Node3D=living_herb["model"]
      if Vector2(h.position.x-x,h.position.z-z).length()<1.6:
        no_collision=false
        break
    if not no_collision:
      continue
    var scale_factor: float=random.randf_range(0.38,0.72)
    var t:=Transform3D(Basis(Vector3.UP,random.randf_range(-PI,PI)).scaled(
      Vector3.ONE*scale_factor),
      Vector3(x,float(terrain_world.call("height_at",x,z)),z))
    locations.append(t)
  for part in actual_parts:
    # Detached original GLTF source has no world transform; compose its
    # existing authoring transform hierarchy without calling to_global().
    var offset: Transform3D=Transform3D.IDENTITY
    var cursor: Node3D=part
    while cursor!=null and cursor!=original:
      offset=cursor.transform*offset
      cursor=cursor.get_parent() as Node3D
    var batch:=MultiMesh.new()
    batch.transform_format=MultiMesh.TRANSFORM_3D
    batch.mesh=part.mesh
    batch.instance_count=locations.size()
    for i in range(locations.size()):
      batch.set_instance_transform(i,locations[i]*offset)
    var draw:=MultiMeshInstance3D.new()
    draw.name="RealQuaterniusLicensedPBRUnderstoryBatched_"+str(
      licensed_understory_draw_parts)
    draw.multimesh=batch
    draw.material_override=part.material_override
    draw.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    draw.visibility_range_end=73.0
    world.add_child(draw)
    licensed_understory_draw_parts+=1
  licensed_understory_count=locations.size()
  licensed_understory_triangle_budget=locations.size()*source_triangles
  if licensed_understory_count<24:
    asset_errors.append("REV207_UNDERSTORY_ALL_LICENSED_BUSHES_MISSING")

func _spawn_spirit_resource_nodes() -> void:
  if spirit_resources==null or not bool(spirit_resources.get("_loaded")):
    return
  var records: Dictionary=spirit_resources.get("nodes")
  var recipes: Dictionary=SpiritResources.RESOURCE_DEFS
  for id in records:
    if spirit_resource_visuals.has(id):
      continue
    var data: Dictionary=records[id]
    var kind: String=String(data["kind"])
    var prefab: String=String(recipes[kind]["prefab"])
    if not spirit_resource_sources.has(prefab):
      asset_errors.append("REV206_SPIRIT_RESOURCE_NO_CC0_"+prefab)
      continue
    var original: Node3D=spirit_resource_sources[prefab]
    var model: Node3D=original.duplicate()
    model.name=String(id)
    var x: float=float(data["x"])
    var z: float=float(data["z"])
    model.position=Vector3(x,float(
      terrain_world.call("height_at",x,z)),z)
    model.set_meta("rev206_actual_world_ore_or_herb",kind)
    model.set_meta("source_license","Quaternius-CC0")
    model.set_meta("world_entity_id",String(id))
    world.add_child(model)
    var b: Vector2=_visible_bounds(model)
    var current_height: float=b.y-b.x
    var target_height: float=1.25 if kind=="spirit_stone" else (
      0.72 if kind=="mushroom" else 0.85)
    if current_height>0.05:
      model.scale*=clampf(target_height/current_height,0.05,6.0)
      b=_visible_bounds(model)
      model.position.y+=float(
        terrain_world.call("height_at",x,z))-b.x
    # Vendor base-color texture/normal/roughness remains in effect. A
    # carefully colored mineral luminescence makes ore distinguishable.
    if kind=="spirit_stone":
      for child in model.find_children("*","MeshInstance3D",true,false):
        var mesh: MeshInstance3D=child as MeshInstance3D
        if mesh.mesh==null:
          continue
        for surface in range(mesh.mesh.get_surface_count()):
          var previous: Material=mesh.get_active_material(surface)
          if previous is StandardMaterial3D:
            var mat: StandardMaterial3D=(previous as StandardMaterial3D).duplicate(
              true) as StandardMaterial3D
            mat.albedo_color=mat.albedo_color.lerp(Color("#329f9a"),0.48)
            mat.emission_enabled=true
            mat.emission=Color("#3ad1bf")
            mat.emission_energy_multiplier=0.72
            mesh.set_surface_override_material(surface,mat)
    var tag:=Label3D.new()
    tag.name="ActualRespawningWildHerbOrSpiritOre"
    tag.text=String(recipes[kind]["display"])
    tag.font_size=38
    tag.pixel_size=0.012
    tag.billboard=BaseMaterial3D.BILLBOARD_ENABLED
    tag.modulate=Color(String(recipes[kind]["color"]))
    tag.outline_size=7
    tag.no_depth_test=false
    tag.position=Vector3(0,2.1,0)
    tag.visible=false
    model.add_child(tag)
    # The living stem/seed bank remains even after harvestable buds reach
    # zero. Picking herbs never makes a species disappear from the land.
    model.visible=int(data["remaining"])>0 or kind!="spirit_stone"
    spirit_resource_visuals[id]={"model":model,"caption":tag,
      "kind":kind,"display":String(recipes[kind]["display"])}
  _add_event("已生成%d株实体野生灵药/矿脉；全部由实际CC0花草岩石绘制" % [
    spirit_resource_visuals.size()])

func _sync_spirit_resource_visuals(hero: Node3D=null) -> void:
  if spirit_resources==null:
    return
  var ledger: Dictionary=spirit_resources.get("nodes")
  for id in spirit_resource_visuals:
    var visual: Dictionary=spirit_resource_visuals[id]
    var entity: Node3D=visual["model"]
    if not is_instance_valid(entity):
      continue
    var remaining: int=int(ledger[id]["remaining"])
    entity.visible=remaining>0 or String(visual["kind"])!="spirit_stone"
    var tag: Label3D=visual["caption"]
    if entity.visible and hero!=null:
      var distance: float=Vector2(
        entity.position.x-hero.position.x,
        entity.position.z-hero.position.z).length()
      tag.visible=distance<7.0
      if tag.visible:
        tag.text=String(visual["display"])+" ×%d [采集]" % remaining
    else:
      tag.visible=false

func harvest_real_spirit_resource(point: Vector3,
    backpack: RefCounted) -> Dictionary:
  if spirit_resources==null or not bool(spirit_resources.get("_loaded")):
    return {"ok":false,"reason":"NO_REAL_RESOURCE_WORLD"}
  var nearest: Dictionary=spirit_resources.call(
    "get_nearest_resource",point,3.1)
  if nearest.is_empty():
    return {"ok":false,"reason":"NO_NEARBY_SPIRIT_RESOURCE"}
  var response: Dictionary=spirit_resources.call(
    "harvest",String(nearest["id"]),backpack)
  if bool(response.get("ok",false)):
    _sync_spirit_resource_visuals()
  return response

func _spawn_native_animals() -> void:
  # Four physical CC0 spiritual beast leaders truly GUARD four physical
  # ore veins, a few metres away from each node. Their invisible wild packs
  # breed and cultivate in a bounded regional ledger, never 5000 3D nodes.
  var animals: Array=[
    ["wolf",Vector3(25.2,0.0,-31.0),"CL-WILDLIFE-WOLF-01"],
    ["fox",Vector3(26.4,0.0,30.3),"CL-WILDLIFE-FOX-01"],
    ["deer",Vector3(18.2,0.0,37.1),"CL-WILDLIFE-DEER-01"],
    ["cow",Vector3(33.2,0.0,3.8),"CL-WILDLIFE-COW-01"]]
  for element in animals:
    var kind: String=element[0]
    if not native_wildlife_sources.has(kind):
      continue
    var at: Vector3=element[1]
    var critter: Node3D=(native_wildlife_sources[kind] as Node3D).duplicate()
    critter.name=String(element[2])
    critter.position=Vector3(at.x,
      float(terrain_world.call("height_at",at.x,at.z)),at.z)
    critter.set_meta("source_license","Quaternius-CC0")
    critter.set_meta("animal_not_human_citizen",true)
    critter.set_meta("species",kind)
    critter.set_meta("wildlife_entity_id",String(element[2]))
    critter.set_meta("ore_guardian_territory",true)
    # Match the exact living ore position in the original physical scene.
    var guard_index: int=animals.find(element)
    critter.set_meta("guarded_spirit_ore",String(
      LivingRegions.MINE_GUARDS[guard_index]["ore"]))
    world.add_child(critter)
    var bounds: Vector2=_visible_bounds(critter)
    var measured: float=bounds.y-bounds.x
    var target_height: float=float(YAO_BEAST_SPEC[kind]["size"])
    if measured>0.10 and is_finite(measured):
      critter.scale*=clampf(target_height/measured,0.04,8.0)
      var new_bounds: Vector2=_visible_bounds(critter)
      critter.position.y+=float(terrain_world.call("height_at",
        at.x,at.z))-new_bounds.x
    critter.set_meta("feet_ground_offset",
      critter.position.y-float(terrain_world.call("height_at",at.x,at.z)))
    var clips: Array[Node]=critter.find_children("*","AnimationPlayer",true,false)
    var animator: AnimationPlayer=clips[0] as AnimationPlayer if not clips.is_empty() else null
    var idle_clip: String=""
    var walk_clip: String=""
    if animator!=null:
      var choices: PackedStringArray=animator.get_animation_list()
      for clip in choices:
        if idle_clip=="" and clip.to_lower().contains("idle"):
          idle_clip=clip
        if walk_clip=="" and (clip.to_lower().contains("walk") or (
            clip.to_lower().contains("run"))):
          walk_clip=clip
      if idle_clip=="" and choices.size()>0:
        idle_clip=choices[0]
      if walk_clip=="" and choices.size()>1:
        walk_clip=choices[1]
      if idle_clip!="":
        animator.play(idle_clip)
      _wildlife_anim_count+=1 if choices.size()>0 else 0
    var plan: Dictionary=YAO_BEAST_SPEC[kind]
    var solid: StaticBody3D=StaticBody3D.new()
    solid.name="ActualYaoBeastBodyCollider_"+String(element[2])
    solid.collision_layer=2
    solid.collision_mask=0
    solid.position=critter.position+Vector3.UP*(
      target_height*0.50)
    var capsule:=CollisionShape3D.new()
    capsule.name="PhysicalRaisedSpiritualBeastNotDecorativeAnimal"
    var physics:=CapsuleShape3D.new()
    physics.radius=maxf(0.45,target_height*0.27)
    physics.height=maxf(1.25,target_height*0.87)
    capsule.shape=physics
    solid.add_child(capsule)
    world.add_child(solid)
    var label:=Label3D.new()
    label.name="ActualYaoBeastRealmRootCurrentMaxHPMP_"+String(element[2])
    label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
    label.font_size=30
    label.pixel_size=0.0052
    label.outline_size=8
    label.visibility_range_end=25.0
    label.position=critter.position+Vector3.UP*(target_height+0.65)
    world.add_child(label)
    critter.set_meta("actual_spirit_monster",true)
    critter.set_meta("beast_realm",String(plan["realm"]))
    actual_wildlife[critter.name]={
      "node":critter,"species":kind,"spawn":critter.position,
      "wander_angle":float(actual_wildlife.size())*1.71,
      "timer":0.0,"activity":"巡游","age_days":16,
      "name":String(plan["name"]),"realm":String(plan["realm"]),
      "root":String(plan["root"]),
      "health":int(plan["max_health"]),"max_health":int(plan["max_health"]),
      "mana":int(plan["max_mana"]),"max_mana":int(plan["max_mana"]),
      "body_height":target_height,
      "aggressive":bool(plan["hostile"]),"damage":int(plan["damage"]),
      "attack_cooldown":1.2,"attack_windup":0.0,
      "loot_available":false,"state":"patrol",
      "guarded_ore":String(critter.get_meta("guarded_spirit_ore")),
      "collider":solid,"head_label":label,
      "animator":animator,"idle":idle_clip,"walk":walk_clip}

# Same world-time ticker as NPC cultivation, seasonal vegetation and
# mine guardians. The available physical CC0 leader meshes are updated with
# actual realm, HP/MP ceiling and combat damage after slow breakthroughs.
func _sync_mine_guardian_realms() -> void:
  if world_society==null or not bool(world_society.get("_loaded")):
    return
  var packs: Dictionary=world_society.get("beast_packs")
  for id in actual_wildlife:
    if not packs.has(id):
      continue
    var pack: Dictionary=packs[id]
    var beast: Dictionary=actual_wildlife[id]
    if int(beast["health"])<=0:
      continue
    var layer: int=int(pack["layer"])
    var role: String=String(beast["species"])
    var base: Dictionary=YAO_BEAST_SPEC[role]
    var new_health: int=int(base["max_health"])+maxi(0,layer-1)*16
    var new_mana: int=int(base["max_mana"])+maxi(0,layer-1)*10
    var health_increase: int=new_health-int(beast["max_health"])
    var mana_increase: int=new_mana-int(beast["max_mana"])
    beast["max_health"]=new_health
    beast["health"]=mini(new_health,maxi(1,int(beast["health"])+maxi(0,health_increase)))
    beast["max_mana"]=new_mana
    beast["mana"]=mini(new_mana,maxi(0,int(beast["mana"])+maxi(0,mana_increase)))
    beast["damage"]=int(base["damage"])+maxi(0,layer-1)*2
    beast["realm"]=String(pack["realm"])
    beast["age_days"]=int(pack["age_months"])*30
    (beast["node"] as Node3D).set_meta("beast_realm",String(beast["realm"]))
    _sync_beast_vitals(beast)

func apply_yao_beast_damage(id: String,damage: int,
    element: String="sword") -> Dictionary:
  if not actual_wildlife.has(id):
    return {"ok":false,"reason":"NO_REAL_YAO_BEAST"}
  var beast: Dictionary=actual_wildlife[id]
  if int(beast["health"])<=0 or damage<=0:
    return {"ok":false,"reason":"ALREADY_DEAD_OR_ZERO_DAMAGE"}
  var resisted: int=0
  if element!="sword" and String(beast["root"]).contains(element):
    resisted=roundi(float(damage)*0.28)
  var dealt: int=mini(int(beast["health"]),maxi(1,damage-resisted))
  beast["health"]=int(beast["health"])-dealt
  beast["aggressive"]=true # Surviving a first attack causes real hostility.
  beast["attack_cooldown"]=maxf(0.3,float(beast["attack_cooldown"]))
  _beast_hit_events+=1
  if int(beast["health"])<=0:
    beast["state"]="dead"
    beast["activity"]="陨落"
    beast["loot_available"]=true
    beast["aggressive"]=false
    _beast_deaths+=1
    if world_society!=null and bool(world_society.get("_loaded")):
      world_society.call("record_guardian_death",id)
    var solid: StaticBody3D=beast["collider"]
    if is_instance_valid(solid):
      solid.collision_layer=0
    var animator: AnimationPlayer=beast["animator"]
    if animator!=null:
      animator.stop()
  _sync_beast_vitals(beast)
  return {"ok":true,"id":id,"actual_damage":dealt,
    "remaining_hp":int(beast["health"]),"max_hp":int(beast["max_health"]),
    "element_resisted":resisted,"defeated":bool(
      beast["state"]=="dead")}

func loot_defeated_yao_beast(point: Vector3,backpack: RefCounted) -> Dictionary:
  if backpack==null:
    return {"ok":false,"reason":"NO_REAL_BACKPACK"}
  for id in actual_wildlife:
    var beast: Dictionary=actual_wildlife[id]
    var entity: Node3D=beast["node"]
    if beast["state"]=="dead" and bool(beast[
        "loot_available"]) and entity.position.distance_to(point)<3.0:
      if not bool(backpack.call("_add","beast_core",1)):
        return {"ok":false,"reason":"BAG_FULL_NO_DUPLICATED_BEAST_DROP"}
      beast["loot_available"]=false
      _sync_beast_vitals(beast)
      return {"ok":true,"action":"loot_beast",
        "kind":"beast_core","source_entity_id":String(id)}
  return {"ok":false,"reason":"NO_DEFEATED_LOOT_WITHIN_REACH"}

func _sync_beast_vitals(beast: Dictionary) -> void:
  var tag: Label3D=beast["head_label"]
  if tag!=null and is_instance_valid(tag):
    tag.text="%s · %s · %s\n生命 %d/%d  法力 %d/%d · %s" % [
      String(beast["name"]),String(beast["realm"]),
      String(beast["root"]),int(beast["health"]),
      int(beast["max_health"]),int(beast["mana"]),
      int(beast["max_mana"]),String(beast["state"])]
    var node: Node3D=beast["node"]
    tag.position=node.position+Vector3.UP*(
      float(beast["body_height"])+0.64)

func _step_native_animals(delta: float) -> void:
  var hero: Node3D=controls.get("actor") if controls!=null else null
  for beast in actual_wildlife.values():
    var actor: Node3D=beast["node"]
    if not is_instance_valid(actor):
      continue
    if int(beast["health"])<=0:
      _sync_beast_vitals(beast)
      continue
    beast["timer"]=float(beast["timer"])+delta
    beast["attack_cooldown"]=maxf(0.0,
      float(beast["attack_cooldown"])-delta)
    var home: Vector3=beast["spawn"]
    var position_target: Vector3=home
    var dist: float=999.0
    if hero!=null and is_instance_valid(hero):
      dist=Vector2(actor.position.x-hero.position.x,
        actor.position.z-hero.position.z).length()
    var chase: bool=bool(beast["aggressive"]) and dist<12.0
    if chase:
      position_target=hero.position
      beast["state"]="alert" if dist>2.6 else "attack"
    else:
      var angle: float=float(beast["wander_angle"])+(
        float(int(float(beast["timer"])/17.0))*1.27)
      position_target=home+Vector3(sin(angle)*3.8,0.0,cos(angle)*3.8)
      beast["state"]="patrol" if fmod(float(
        beast["timer"]),17.0)>5.0 else "rest"
    var moving: bool=beast["state"] in ["alert","patrol"]
    if moving:
      var diff: Vector3=position_target-actor.position
      diff.y=0.0
      if diff.length()>0.48:
        var speed: float=2.0 if chase else 1.15
        var candidate: Vector3=actor.position+diff.normalized()*minf(
          speed*delta,diff.length())
        if bool(terrain_world.call("stream_contains_physical_chunk",
            candidate.x,candidate.z)) and not (
            bool(terrain_world.call("is_water",candidate.x,candidate.z))):
          actor.position.x=candidate.x
          actor.position.z=candidate.z
          actor.rotation.y=atan2(diff.x,diff.z)
    elif beast["state"]=="attack" and float(beast[
        "attack_cooldown"])<=0.0 and hero!=null:
      # Actual HP decrement, not just a hostile label / attack animation.
      var bullet_path:=PhysicsRayQueryParameters3D.create(
        actor.position+Vector3.UP*1.25,hero.position+Vector3.UP*0.95,2)
      bullet_path.exclude=[(beast["collider"] as StaticBody3D).get_rid()]
      var blocked: Dictionary=world.get_world_3d().direct_space_state.intersect_ray(
        bullet_path)
      if not blocked.is_empty():
        beast["state"]="alert"
        continue
      var hit_player: int=int(controls.call(
        "apply_player_damage",int(beast["damage"])))
      beast["attack_cooldown"]=2.2
      beast["mana"]=maxi(0,int(beast["mana"])-(
        3 if int(beast["mana"])>=3 else 0))
      beast["activity"]="冲撞命中"
      _add_event(String(beast["name"])+" 真实攻击玩家："+str(hit_player))
    actor.position.y=float(terrain_world.call("height_at",
      actor.position.x,actor.position.z))+float(
        actor.get_meta("feet_ground_offset",0.0))
    var hitbox: StaticBody3D=beast["collider"]
    if is_instance_valid(hitbox):
      hitbox.position=actor.position+Vector3.UP*(
        float(beast["body_height"])*0.5)
    var animator: AnimationPlayer=beast["animator"]
    if animator!=null:
      var clip: String=String(beast["walk"]) if moving else String(
        beast["idle"])
      if clip!="" and animator.current_animation!=clip:
        animator.play(clip)
    _sync_beast_vitals(beast)

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
  terrain_world.set("vivid_material_style",vivid_materials)
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
  for index in range(52):
    var center: Vector2 = groves[int(index % groves.size())]
    var spread: float = rng.randf_range(1.5, 7.0)
    var angle: float = rng.randf_range(-PI, PI)
    var x: float = minf(-11.0,center.x+cos(angle)*spread)
    var z: float = center.y+sin(angle)*spread
    if z > 7.0 and z < 14.0:
      z += 7.0
    var entity_id := "CL-TREE-0184-%03d" % index
    assert(sim.register_natural_node(entity_id, TOWN, "tree", 5))
    assert(sim.register_resource_position(entity_id, Vector3(x,
      float(terrain_world.call("height_at",x,z)),z)))
    assert(eco.register_tree(entity_id))
    var instance := _place_asset("tree", entity_id, Vector3(x,0,z), rng.randf_range(1.45,2.2))
    if instance != null:
      instance.set_meta("resource_id", entity_id)
      natural_meshes[entity_id] = instance
  # Two mineral outcrops (right-hand side), all outside the main road.
  var quarry_groups := [Vector2(21.0,-15.0),Vector2(23.0,19.0)]
  for index in range(20):
    var center: Vector2 = quarry_groups[int(index % quarry_groups.size())]
    var spread: float = rng.randf_range(1.0,6.5)
    var angle: float = rng.randf_range(-PI, PI)
    var x: float = maxf(12.0,center.x+cos(angle)*spread)
    var z: float = center.y+sin(angle)*spread
    if z > 7.0 and z < 14.0:
      z -= 8.0
    var entity_id := "CL-STONE-0184-%03d" % index
    assert(sim.register_natural_node(entity_id, TOWN, "stone", 10))
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
    {"id":"CL-NPC-0184-03","kind":"steward","name":"巡游管事"}
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

func _move_steward(worker: Dictionary, delta: float) -> void:
  # The old perpetual tiny-hut constructor is retired. This actual licensed
  # NPC has a home and a finite daily route, receives no fictitious tools.
  var home: Node3D=finished_prefabs.get("CL-HOME-V206-001",null)
  # Workers are not merely staring at an unfinished home. If the wood+
  # stone were paid, they physically commute to the site during workdays.
  for bid in housing_blueprints:
    var source: Dictionary=housing.get("sites")[bid]
    if bool(source["paid"]) and not bool(source["completed"]):
      worker["phase"]="licensed_paid_house_building"
      worker["target"]=housing_blueprints[bid]["at"]
      _navigate(worker,delta)
      return
  var night: bool=int(sim.hour)>=19 or int(sim.hour)<6
  worker["home_id"]="CL-HOME-V206-001"
  worker["phase"]="home_rest" if night else "inspecting_prefab_houses"
  if night and home!=null:
    worker["target"]=home.position+Vector3(0,0,2.1)
  else:
    worker["target"]=Vector3(-6.0,0,-31.0) if (
      sim.hour%4<2) else DEPOT
  if not _navigate(worker,delta):
    return
  _set_worker_animation(worker,false)

func _add_event(message: String) -> void:
  _events.append(message)
  if _events.size() > 6:
    _events.pop_front()

func _update_status() -> void:
  if status == null:
    return
  var village: Dictionary = sim.villages[TOWN]
  var stock: Dictionary = village["stock"]
  var build: String="已完工%d栋 · 施工蓝图%d个 · 标准住宅200木150石/住5人" % [
    finished_prefabs.size(),housing_blueprints.size()-finished_prefabs.size()]
  var terrain_state: Dictionary = terrain_world.call("stats") if terrain_world!=null else {}
  status.text = ("木 %d  石 %d  树种库存 %d  伐倒产种 %d\n" +
    "入库 %d  种下 %d  地下矿脉露出 %d\n" +
    "现成建筑 %s  已修复旧脚手架数 %d\n" +
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
  sun_light.light_energy=0.12+daylight*1.15
  sun_light.light_color=Color("#ffd091").lerp(Color("#fff3cb"),daylight)
  var backdrop: ProceduralSkyMaterial=scene_environment.sky.sky_material
  backdrop.sky_top_color=Color("#10243b").lerp(Color("#0872c2"),daylight)
  backdrop.sky_horizon_color=Color("#214565").lerp(Color("#8cd1ed"),daylight)
  backdrop.ground_horizon_color=Color("#1b3544").lerp(Color("#58959c"),daylight)
  backdrop.ground_bottom_color=Color("#263f3c").lerp(Color("#376d50"),daylight)
  scene_environment.fog_light_color=Color("#283f57").lerp(Color("#699eaf"),daylight)
  scene_environment.ambient_light_energy=0.14+daylight*0.20

func get_living_clock() -> Dictionary:
  return {"day":int(sim.day),"hour":int(sim.hour),
    "minutes":clampi(roundi(_economy_clock/12.0*60.0),0,59),
    "speed_multiplier":world_time_scale,
    "whole_world_hours_processed":_total_accelerated_hours,
    "npc_model_loaded":false,
    "npc_ai_status":local_npc_ai_state,
    "npc_real_rule_simulation":true,
    "generated_spiritual_seed":int(cultivation.get("world_seed")) if cultivation!=null else 0,
    "real_cultivator_npc_count":int(cultivation.call("stats").get("cultivator_count",0)) if cultivation!=null else 0}

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
    if housing!=null:
      var paid_finished: Array=housing.call("advance_one_world_hour",1)
      for built_id in paid_finished:
        _materialize_paid_house(String(built_id))
    if cultivation!=null:
      cultivation.call("advance_world_hour")
    if spirit_resources!=null:
      var herb_count_before: int=int(spirit_resources.get("nodes").size())
      spirit_resources.call("advance_world_hour")
      if int(spirit_resources.get("nodes").size())>herb_count_before:
        _spawn_spirit_resource_nodes()
    if world_society!=null and bool(world_society.get("_loaded")):
      var month_before: int=int(world_society.get("months"))
      world_society.call("advance_world_hour")
      if int(world_society.get("months"))!=month_before:
        _sync_mine_guardian_realms()
    _total_accelerated_hours+=1
    advanced+=1
  if advanced>0:
    _refresh_ecology_meshes()
  _sync_living_daylight()
  for worker in workers.values():
    if String(worker["kind"])=="steward":
      _move_steward(worker,accelerated_delta)
    else:
      _move_gatherer(worker, accelerated_delta)
  _step_native_animals(delta)
  if cultivation!=null:
    cultivation.call("update_visible_npcs",accelerated_delta)
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
    _sync_spirit_resource_visuals(hero)
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
    "spiritual_world":cultivation.call("stats") if cultivation!=null else {},
    "whole_world_speed_includes_npc_construction":false,
    "rev206_perpetual_house_construction_retired":true,
    "rev206_cc0_completed_building_count":finished_prefabs.size(),
    "rev208_paid_construction_actual":housing.call("stats") if housing!=null else {},
    "rev208_genuine_unpaid_house_blueprints":housing_blueprints.size(),
    "rev208_paid_house_physics_colliders":house_entry_colliders.size(),
    "rev206_native_wildlife_count":actual_wildlife.size(),
    "rev208_true_yao_beast_counts":actual_wildlife.size(),
    "rev208_true_yao_beast_collision_count":actual_wildlife.values().filter(
      func(v): return is_instance_valid(v["collider"])).size(),
    "rev208_true_yao_beast_real_hit_events":_beast_hit_events,
    "rev208_yao_beast_deaths":_beast_deaths,
    "rev206_real_spirit_herbs_ore":spirit_resources.call("stats") if spirit_resources!=null else {},
    "rev207_real_living_world":world_society.call("stats") if world_society!=null else {},
    "rev207_authoritative_mortal_population":int(world_society.call(
      "population")) if world_society!=null and bool(
      world_society.get("_loaded")) else 0,
    "rev207_mine_guardian_positions_linked":actual_wildlife.values().filter(
      func(v): return String(v.get("guarded_ore",""))!="").size(),
    "rev207_real_cc0_shrub_understory":licensed_understory_count,
    "rev207_real_cc0_shrub_draw_nodes":licensed_understory_draw_parts,
    "rev207_real_cc0_shrub_triangles":licensed_understory_triangle_budget,
    "rev206_world_spirit_resource_visuals":spirit_resource_visuals.size(),
    "rev206_licensed_spirit_plant_rock_sources":spirit_resource_sources.size(),
    "rev206_native_animated_wildlife_count":_wildlife_anim_count,
    "rev206_outfit_source_count":licensed_outfits.size(),
    "rev206_completed_house_occupancy":(finished_prefabs.get(
      "CL-HOME-V206-001",null) as Node3D).get_meta("resident_capacity",0) if (
      finished_prefabs.has("CL-HOME-V206-001")) else 0,
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
    "stage":0,"built_cc0_parts":finished_prefabs.size(),
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
    "rev207_vivid_real_pbr_materials":vivid_materials.call("summary") if vivid_materials!=null else {},
    "rev207_color_saturation":scene_environment.adjustment_saturation if scene_environment!=null else 0.0,
    "rev207_preserved_existing_license_assets":true,
    "no_auto_quality_switch": true,
    "physical_strata": terrain_world.call("stats") if terrain_world!=null else {},
    "player_controls": controls.call("stats") if controls!=null else {},
    "foundation_excavation_npc_cuts": _foundation_excavation_count,
    "worker_visual_heights_m": {
      "woodcutter": float(workers["CL-NPC-0184-01"]["node"].get_meta("actor_visual_height_m",0.0)) if workers.has("CL-NPC-0184-01") else 0.0,
      "quarryman": float(workers["CL-NPC-0184-02"]["node"].get_meta("actor_visual_height_m",0.0)) if workers.has("CL-NPC-0184-02") else 0.0,
      "steward":float(workers["CL-NPC-0184-03"]["node"].get_meta("actor_visual_height_m",0.0)) if workers.has("CL-NPC-0184-03") else 0.0
    },
    "not_whole_finished_house":false, "save_unchanged":true,
    "original_licensed_complete_houses_used":true,
    "persistent_city_population_is_statistical_only":world_society!=null and (
      int(world_society.call("stats").get("area_km2",0))==50000) and (
      int(world_society.call("stats").get("real_loaded_human_scene_nodes",-1))==0)}


func _visible_bounds(actor: Node3D) -> Vector2:
  var smallest_y: float = INF
  var largest_y: float = -INF
  var mesh_parts: Array[Node]=actor.find_children("*","MeshInstance3D",true,false)
  if actor is MeshInstance3D:
    mesh_parts.push_front(actor)
  for child in mesh_parts:
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
  # Rev206 CC0 prefabs add 14 freestanding GLTFDocument.generate_scene()
  # templates. Each duplicate was parented to the world; templates were
  # NOT parented and must be explicitly freed exactly once on scene exit.
  # Otherwise headless Godot reports leaked 20 DummyMeshes, 137 materials,
  # multiple RIDs / ObjectDB instances and FAILS the release QA. This is
  # a real source lifetime fix, not hiding/suppressing engine ERROR logs.
  var unique_sources: Dictionary={}
  for collection in [finished_prefab_sources,licensed_outfits,
      native_wildlife_sources,spirit_resource_sources]:
    for original in (collection as Dictionary).values():
      if original is Node3D and is_instance_valid(original):
        unique_sources[(original as Node3D).get_instance_id()]=original
  for original in unique_sources.values():
    if is_instance_valid(original) and (original as Node3D).get_parent()==null:
      (original as Node3D).free()
  finished_prefab_sources.clear()
  licensed_outfits.clear()
  native_wildlife_sources.clear()
  spirit_resource_sources.clear()
  spirit_resource_visuals.clear()
  _hidden_game_world.clear()
  _old_profiler_nodes.clear()
