extends RefCounted
## User-authoritative OnePlus Ace 5 Pro / Snapdragon 8 Elite / Adreno 830
## Replaces ALL previous 200-draw / 150k triangle / frame-rate budgets.
## Never lower quality automatically, including FPS <45. UI always native.
const PROFILE_NAMES := ["极致画质", "高档", "普通"]
const TARGET_PANEL_SIZE := Vector2i(2780,1264)
const SETTINGS_PATH := "user://canglan_graphics_profiles_v1.cfg"
const PROFILES := {
  "极致画质": {"scale":1.00,"msaa":Viewport.MSAA_4X,
    "shadow_m":100.0,"shadow_splits":2,"grass_distance":80.0,"grass_density":1.0,
    "grass_instances":4500,"fireflies":100,"clouds":9,"fog_density":0.008,
    "glow":true,"name_distance":20.0,"target_fps":90,"min_fps":60,
    "draw_reference":1500,"triangle_reference":1500000},
  "高档": {"scale":0.85,"msaa":Viewport.MSAA_2X,
    "shadow_m":60.0,"shadow_splits":1,"grass_distance":40.0,"grass_density":0.65,
    "grass_instances":2400,"fireflies":60,"clouds":5,"fog_density":0.006,
    "glow":true,"name_distance":13.0,"target_fps":60,"min_fps":60,
    "draw_reference":800,"triangle_reference":600000},
  "普通": {"scale":0.67,"msaa":Viewport.MSAA_DISABLED,
    "shadow_m":30.0,"shadow_splits":0,"grass_distance":20.0,"grass_density":0.32,
    "grass_instances":1100,"fireflies":20,"clouds":2,"fog_density":0.003,
    "glow":false,"name_distance":8.0,"target_fps":60,"min_fps":60,
    "draw_reference":400,"triangle_reference":300000}
}
var selected: String = "高档"
var physical_screen: Vector2i = Vector2i(1280,720)
var actual_refresh: float = 60.0
var view: SubViewport
var scene_environment: Environment
var sun: DirectionalLight3D
var terrain: Node3D
var grass: MultiMeshInstance3D
var particles: GPUParticles3D
var clouds: MultiMeshInstance3D
var labels: Dictionary = {}
var diagnostic_text: Label
var low_fps_text: Label
var profile_applied: bool = false
var is_mobile_render: bool = true
var last_metrics: Dictionary = {}

func initialize(room: Node) -> void:
  view = room.get("view")
  sun = room.get("sun_light")
  scene_environment = room.get("scene_environment")
  terrain = room.get("terrain_world")
  labels = room.get("npc_nameplates")
  diagnostic_text = room.get("quality_diagnostic")
  low_fps_text = room.get("quality_warning")
  physical_screen = Vector2i(room.get_viewport().get_visible_rect().size)
  if OS.has_feature("mobile") or OS.has_feature("android"):
    var screen: Vector2i = DisplayServer.screen_get_size()
    if screen.x >= 800 and screen.y >= 450:
      # The actual screen pixels, NOT Godot's logical UI canvas size.
      physical_screen = screen
  actual_refresh = DisplayServer.screen_get_refresh_rate()
  if actual_refresh < 20.0 or actual_refresh > 240.0:
    actual_refresh = 60.0
  # No fabricated 120Hz claim. DisplayServer reports OS-chosen mode; PCK
  # cannot force a Java Android Display.Mode refresh rate not allowed by OS.
  Engine.max_fps = mini(120,maxi(30,roundi(actual_refresh)))
  is_mobile_render = ProjectSettings.get_setting("rendering/renderer/rendering_method","mobile") != "gl_compatibility"
  selected = _read_persisted_choice()
  _create_grass(room)
  _create_fireflies(room)
  _create_clouds(room)
  apply(selected,false)

func _read_persisted_choice() -> String:
  var config := ConfigFile.new()
  if config.load(SETTINGS_PATH) != OK:
    return "高档"
  var saved: String = String(config.get_value("graphics","manual_quality","高档"))
  return saved if PROFILES.has(saved) else "高档"

func _save_choice() -> void:
  var config := ConfigFile.new()
  config.set_value("graphics","manual_quality",selected)
  if config.save(SETTINGS_PATH) != OK:
    push_warning("Could not save manual quality selection; keep it in memory")

func _create_grass(room: Node) -> void:
  grass = MultiMeshInstance3D.new()
  grass.name = "RealTerrainGrassBatchedByProfile"
  var blade := QuadMesh.new()
  blade.size = Vector2(0.15,0.28)
  var mat := StandardMaterial3D.new()
  mat.albedo_color = Color("#668b53")
  mat.roughness = 1.0
  mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
  mat.cull_mode = BaseMaterial3D.CULL_DISABLED
  blade.material = mat
  var mm := MultiMesh.new()
  mm.transform_format = MultiMesh.TRANSFORM_3D
  mm.mesh = blade
  mm.instance_count = 4500
  var rng := RandomNumberGenerator.new()
  rng.seed = 20261017
  for i in range(mm.instance_count):
    var x: float = rng.randf_range(-43.0,43.0)
    var z: float = rng.randf_range(-43.0,43.0)
    var skip: bool = bool(terrain.call("_is_road",x,z))
    skip = skip or (Vector2(x,z+3).length() < 8.0)
    skip = skip or Vector2(x,z).distance_to(Vector2(-9,-28)) < 9.0
    var t := Transform3D.IDENTITY
    if skip:
      t = Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO),Vector3.ZERO)
    else:
      var height: float = float(terrain.call("height_at",x,z))
      var rot := Basis(Vector3.UP,rng.randf_range(-PI,PI))
      var size: float = rng.randf_range(0.75,1.55)
      t = Transform3D(rot.scaled(Vector3.ONE*size),Vector3(x,height+0.14,z))
    mm.set_instance_transform(i,t)
  grass.multimesh = mm
  grass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  room.get("world").add_child(grass)

func _create_fireflies(room: Node) -> void:
  particles = GPUParticles3D.new()
  particles.name = "TierScaledKenneyFireflies"
  particles.position = Vector3(-7,2.0,-26)
  particles.emitting = true
  particles.amount = 60
  particles.lifetime = 6.0
  particles.explosiveness = 0.0
  var pm := ParticleProcessMaterial.new()
  pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
  pm.emission_box_extents = Vector3(18,2,15)
  pm.gravity = Vector3.ZERO
  pm.initial_velocity_min = 0.06
  pm.initial_velocity_max = 0.38
  pm.damping_min = 0.02
  pm.damping_max = 0.07
  particles.process_material = pm
  var quad := QuadMesh.new()
  quad.size = Vector2(0.07,0.07)
  var glow_mat := StandardMaterial3D.new()
  glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
  glow_mat.albedo_color = Color("#f6ecb2",0.72)
  glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
  glow_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
  glow_mat.emission_enabled = true
  glow_mat.emission = Color("#ecd881")
  glow_mat.emission_energy_multiplier = 1.1
  quad.material = glow_mat
  particles.draw_pass_1 = quad
  room.get("world").add_child(particles)

func _create_clouds(room: Node) -> void:
  clouds = MultiMeshInstance3D.new()
  clouds.name = "ProfileCloudLayersNotHeavyVolumetrics"
  var mesh := QuadMesh.new()
  mesh.size = Vector2(11.0,4.5)
  var mat := StandardMaterial3D.new()
  mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
  mat.albedo_color = Color("#f5f2e6",0.22)
  mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
  mat.cull_mode = BaseMaterial3D.CULL_DISABLED
  mat.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
  mesh.material = mat
  var mm := MultiMesh.new()
  mm.transform_format = MultiMesh.TRANSFORM_3D
  mm.mesh = mesh
  mm.instance_count = 9
  for i in range(mm.instance_count):
    var t := Transform3D.IDENTITY.rotated_local(Vector3.RIGHT,-PI/2.0)
    t.origin = Vector3(-37.0+float(i%3)*28.0,25.0+float(i%3)*2.4,-28.0+float(int(i/3))*22.0)
    mm.set_instance_transform(i,t)
  clouds.multimesh = mm
  clouds.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  room.get("world").add_child(clouds)

func apply(profile_name: String, save: bool = true) -> bool:
  if not PROFILES.has(profile_name):
    return false
  selected = profile_name
  var p: Dictionary = PROFILES[selected]
  # UI overlay is never scaled, only the 3D SubViewport's texture.
  view.size = Vector2i(maxi(16,roundi(physical_screen.x*float(p["scale"]))),
    maxi(16,roundi(physical_screen.y*float(p["scale"]))))
  view.msaa_3d = p["msaa"]
  sun.directional_shadow_max_distance = float(p["shadow_m"])
  if int(p["shadow_splits"])==2:
    sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
  elif int(p["shadow_splits"])==1:
    sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
  else:
    sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
  sun.shadow_enabled = true
  scene_environment.fog_enabled = true
  scene_environment.fog_density = float(p["fog_density"])
  # Glow may be unavailable under Godot 4.x Mobile. Don't misstate engine
  # support: use cheaper emissive fireflies and sky shading as fallback.
  scene_environment.glow_enabled = bool(p["glow"]) and ProjectSettings.get_setting(
    "rendering/renderer/rendering_method","mobile")=="gl_compatibility"
  grass.visibility_range_end = float(p["grass_distance"])
  grass.multimesh.visible_instance_count = int(p["grass_instances"])
  particles.amount = int(p["fireflies"])
  particles.restart()
  clouds.multimesh.visible_instance_count = int(p["clouds"])
  for label in labels.values():
    var tag: Label3D = label
    tag.visibility_range_end = float(p["name_distance"])
  profile_applied = true
  if save:
    _save_choice()
  update_diagnostics()
  return true

func render_profile() -> Dictionary:
  return PROFILES[selected].duplicate(true)

func update_diagnostics() -> Dictionary:
  if not profile_applied:
    return {}
  var fps: int = Engine.get_frames_per_second()
  var draws: int = RenderingServer.get_rendering_info(
    RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
  var triangles: int = RenderingServer.get_rendering_info(
    RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
  var p: Dictionary = PROFILES[selected]
  var resolution: Vector2i = view.size
  last_metrics = {"profile":selected,"fps":fps,
    "draw_calls":draws,"triangles":triangles,
    "render_3d_size":resolution,"render_scale":float(p["scale"]),
    "screen_pixels":physical_screen,"screen_actual_hz":actual_refresh,
    "engine_fps_limit":Engine.max_fps,
    "reference_max_draw_calls":int(p["draw_reference"]),
    "reference_max_triangles":int(p["triangle_reference"]),
    "reference_fps_goal":int(p["target_fps"]),
    "glow_native_supported":scene_environment.glow_enabled,
    "auto_quality_changes":false}
  if diagnostic_text!=null:
    diagnostic_text.text = ("%s · FPS %d · Draw %d/%d · 三角面 %d/%d\n3D渲染 %d×%d (%d%%) · 实际刷新 %.0fHz / 帧率上限%d" %
      [selected,fps,draws,int(p["draw_reference"]),triangles,int(p["triangle_reference"]),
      resolution.x,resolution.y,int(float(p["scale"])*100.0),actual_refresh,Engine.max_fps])
  if low_fps_text!=null:
    low_fps_text.visible = fps > 0 and fps < 45
    if low_fps_text.visible:
      low_fps_text.text = "⚠ 当前不足45 FPS；仅提示，不自动切画质（当前：" + selected + "）"
  return last_metrics.duplicate(true)

func get_stats() -> Dictionary:
  return last_metrics.duplicate(true)
