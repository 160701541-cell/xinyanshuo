extends RefCounted
## rev187: user-controlled OnePlus Ace5Pro QUALITY + separate FPS cap:
## "跟随刷新率"(vsync, max120), 30,60,90,120, no forced eco mode.
## UI never scaled, only the game-world SubViewport. Color count UNLIMITED.
const PROFILE_NAMES := ["极致画质","高档","普通"]
const FPS_MODES := ["跟随刷新率","30","60","90","120"]
const SETTINGS_PATH := "user://canglan_graphics_profiles_v1.cfg"
const PROFILES := {
 "极致画质":{"scale":1.00,"msaa":Viewport.MSAA_4X,"shadow_m":100.0,
   "shadow_splits":2,"grass_distance":80.0,"grass_instances":4500,
   "fireflies":100,"clouds":9,"fog_density":0.007,"name_distance":20.0,
   "glow":true,"draw_reference":1500,"triangle_reference":1500000,"target_fps":90},
 "高档":{"scale":0.85,"msaa":Viewport.MSAA_2X,"shadow_m":60.0,
   "shadow_splits":1,"grass_distance":40.0,"grass_instances":2400,
   "fireflies":60,"clouds":5,"fog_density":0.005,"name_distance":13.0,
   "glow":true,"draw_reference":800,"triangle_reference":600000,"target_fps":60},
 "普通":{"scale":0.67,"msaa":Viewport.MSAA_DISABLED,"shadow_m":30.0,
   "shadow_splits":0,"grass_distance":20.0,"grass_instances":1100,
   "fireflies":20,"clouds":2,"fog_density":0.003,"name_distance":8.0,
   "glow":false,"draw_reference":400,"triangle_reference":300000,"target_fps":60}
}
var selected: String = "高档"
var fps_mode: String = "跟随刷新率"
var physical_screen: Vector2i = Vector2i(1280,720)
var actual_refresh: float = 0.0
var view: SubViewport
var scene_environment: Environment
var sun: DirectionalLight3D
var terrain: Node3D
var grass: MultiMeshInstance3D
var flowers: MultiMeshInstance3D
var particles: GPUParticles3D
var clouds: MultiMeshInstance3D
var labels: Dictionary = {}
var diagnostic_text: Label
var low_fps_text: Label
var profile_applied: bool = false
var last_metrics: Dictionary = {}
var grass_points: Array[Vector3] = []
var flower_points: Array[Vector3] = []
var grass_rotations: Array[Transform3D] = []
var flower_rotations: Array[Transform3D] = []
var grass_cells: Dictionary = {}
var _hidden_transform: Transform3D = Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO),Vector3.ZERO)

func initialize(room: Node) -> void:
  view = room.get("view")
  sun = room.get("sun_light")
  scene_environment = room.get("scene_environment")
  terrain = room.get("terrain_world")
  labels = room.get("npc_nameplates")
  diagnostic_text = room.get("quality_diagnostic")
  low_fps_text = room.get("quality_warning")
  physical_screen = Vector2i(room.get_viewport().get_visible_rect().size)
  if OS.has_feature("android"):
    var device_pixels: Vector2i = DisplayServer.screen_get_size()
    if device_pixels.x >= 800 and device_pixels.y >= 450:
      physical_screen = device_pixels
  actual_refresh = DisplayServer.screen_get_refresh_rate()
  # Android often tells Godot 30/60 while the OS settings show 120Hz.
  # Never trust a low stale query as a reason to CAP THE GAME AT 30 FPS.
  # VSYNC controls real presentation and Engine.max_fps=120 is only a
  # ceiling. Expose the raw query separately and DO NOT invent OS 120Hz.
  _read_settings()
  _create_grass_and_flowers(room)
  _create_fireflies(room)
  _create_clouds(room)
  terrain.connect("terrain_cell_changed",Callable(self,"_on_terrain_changed"))
  apply(selected,false)
  set_fps_mode(fps_mode,false)

func _read_settings() -> void:
  var file := ConfigFile.new()
  if file.load(SETTINGS_PATH)!=OK:
    selected="高档"
    fps_mode="跟随刷新率"
    return
  selected=String(file.get_value("graphics","manual_quality","高档"))
  if not PROFILES.has(selected):
    selected="高档"
  fps_mode=String(file.get_value("graphics","manual_fps_cap","跟随刷新率"))
  if not FPS_MODES.has(fps_mode):
    fps_mode="跟随刷新率"

func _save_settings() -> void:
  var config := ConfigFile.new()
  config.set_value("graphics","manual_quality",selected)
  config.set_value("graphics","manual_fps_cap",fps_mode)
  if config.save(SETTINGS_PATH)!=OK:
    push_warning("Failed to save graphics manual settings")

func set_fps_mode(mode: String, save: bool=true) -> bool:
  if not FPS_MODES.has(mode):
    return false
  fps_mode=mode
  # Always enable VSync; the hardware/Android window refresh rate is
  # authoritative. "Follow" never accidentally reads 30 and caps at 30.
  if DisplayServer.get_name() != "headless":
    DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
  Engine.max_fps = 120 if mode=="跟随刷新率" else int(mode)
  if save:
    _save_settings()
  update_diagnostics()
  return true

func _grass_mesh() -> ArrayMesh:
  # Geometry of ONE actual grass tuft: 4 pairs of narrow pointed leaves,
  # each 0.30--0.60m tall after fixed leaf lengths. No flat rectangle.
  var st:=SurfaceTool.new()
  st.begin(Mesh.PRIMITIVE_TRIANGLES)
  for leaf in range(5):
    var angle: float = TAU*float(leaf)/5.0
    var dx: float = cos(angle)
    var dz: float = sin(angle)
    var height: float = 0.31+float(leaf%4)*0.092
    var width: float = 0.033+0.006*float(leaf%2)
    var tip := Vector3(dx*0.09,height,dz*0.09)
    var a := Vector3(dx*-width,0.0,dz*-width)
    var b := Vector3(dx*width,0.0,dz*width)
    st.add_vertex(a)
    st.add_vertex(tip)
    st.add_vertex(b)
    # Alternate base width and tip direction: actual thin low-poly blades.
    var a2:=Vector3(-dz*width,0,-dx*width)
    var b2:=Vector3(dz*width,0,dx*width)
    st.add_vertex(a2)
    st.add_vertex(tip)
    st.add_vertex(b2)
  st.generate_normals()
  var mesh: ArrayMesh = st.commit()
  var mat := StandardMaterial3D.new()
  mat.albedo_color=Color.WHITE
  mat.vertex_color_use_as_albedo=true
  mat.cull_mode=BaseMaterial3D.CULL_DISABLED
  mat.roughness=1.0
  mesh.surface_set_material(0,mat)
  return mesh

func _flower_mesh() -> ArrayMesh:
  var st:=SurfaceTool.new()
  st.begin(Mesh.PRIMITIVE_TRIANGLES)
  for side in range(5):
    var a: float = TAU*float(side)/5.0
    var b: float = TAU*float(side+1)/5.0
    st.add_vertex(Vector3(0,0.34,0))
    st.add_vertex(Vector3(cos(a)*0.042,0.34,sin(a)*0.042))
    st.add_vertex(Vector3(cos(b)*0.042,0.34,sin(b)*0.042))
  st.generate_normals()
  var mesh: ArrayMesh = st.commit()
  var mat:=StandardMaterial3D.new()
  mat.albedo_color=Color.WHITE
  mat.vertex_color_use_as_albedo=true
  mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
  mat.cull_mode=BaseMaterial3D.CULL_DISABLED
  mesh.surface_set_material(0,mat)
  return mesh

func _natural_plantable(x: float,z: float) -> bool:
  if bool(terrain.call("_is_road",x,z)):
    return false
  if Vector2(x,z+3).length()<8.0 or Vector2(x,z-10).length()<5.0:
    return false
  if Vector2(x,z).distance_to(Vector2(-9,-28))<9.0:
    return false
  return true

func _create_grass_and_flowers(room: Node) -> void:
  var rng:=RandomNumberGenerator.new()
  rng.seed=20261017
  grass=MultiMeshInstance3D.new()
  grass.name="FineFiveLeafGrassTuftsTerrainConforming"
  var grass_mm:=MultiMesh.new()
  grass_mm.transform_format=MultiMesh.TRANSFORM_3D
  grass_mm.use_colors=true
  grass_mm.mesh=_grass_mesh()
  grass_mm.instance_count=4500
  var greens: Array[Color]=[
    Color("#57964f"),Color("#76ad52"),Color("#89b95b"),Color("#4b8050"),
    Color("#aac46d"),Color("#92ad48"),Color("#619b5d"),Color("#8ea758")]
  for i in range(grass_mm.instance_count):
    var x: float = rng.randf_range(-42.5,42.5)
    var z: float = rng.randf_range(-42.5,42.5)
    var pos:=Vector3(x,0,z)
    grass_points.append(pos)
    var rotation:=Basis(Vector3.UP,rng.randf_range(-PI,PI))
    var scale:=rng.randf_range(0.9,1.13)
    grass_rotations.append(Transform3D(rotation.scaled(Vector3.ONE*scale),Vector3.ZERO))
    grass_mm.set_instance_color(i,greens[rng.randi_range(0,greens.size()-1)])
    if _natural_plantable(x,z):
      var y: float = float(terrain.call("height_at",x,z))
      grass_mm.set_instance_transform(i,Transform3D(grass_rotations[i].basis,Vector3(x,y,z)))
    else:
      grass_mm.set_instance_transform(i,_hidden_transform)
  grass.multimesh=grass_mm
  grass.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  room.get("world").add_child(grass)
  flowers=MultiMeshInstance3D.new()
  flowers.name="SubtleFourColorWildflowersGrowingFromRealSoil"
  var flower_mm:=MultiMesh.new()
  flower_mm.transform_format=MultiMesh.TRANSFORM_3D
  flower_mm.use_colors=true
  flower_mm.mesh=_flower_mesh()
  flower_mm.instance_count=270
  var flower_shades: Array[Color]=[
    Color("#f4f0e3"),Color("#e8cd55"),Color("#e997b8"),Color("#baa2de")]
  for i in range(flower_mm.instance_count):
    var x: float=rng.randf_range(-40,40)
    var z: float=rng.randf_range(-40,40)
    var flower_pos:=Vector3(x,0,z)
    flower_points.append(flower_pos)
    flower_rotations.append(Transform3D.IDENTITY)
    flower_mm.set_instance_color(i,flower_shades[i%4])
    if _natural_plantable(x,z):
      flower_mm.set_instance_transform(i,Transform3D(Basis.IDENTITY,
        Vector3(x,float(terrain.call("height_at",x,z)),z)))
    else:
      flower_mm.set_instance_transform(i,_hidden_transform)
  flowers.multimesh=flower_mm
  flowers.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  room.get("world").add_child(flowers)

func _on_terrain_changed(position: Vector3,radius: float) -> void:
  # A real excavation can never leave old 3D grass hovering above its soil.
  # Re-evaluate every tuft ONCE PER DIG, not once per render frame.
  for i in range(grass_points.size()):
    var p: Vector3=grass_points[i]
    if Vector2(p.x-position.x,p.z-position.z).length()>radius+1.5:
      continue
    var cut_idx: Vector2i=terrain.call("_indices",p.x,p.z)
    var cut_depth: int=int(terrain.call("_load_cell",cut_idx.x,cut_idx.y)["cuts"])
    if cut_depth>0 or not _natural_plantable(p.x,p.z):
      grass.multimesh.set_instance_transform(i,_hidden_transform)
    else:
      grass.multimesh.set_instance_transform(i,
        Transform3D(grass_rotations[i].basis,
          Vector3(p.x,float(terrain.call("height_at",p.x,p.z)),p.z)))
  for i in range(flower_points.size()):
    var p: Vector3=flower_points[i]
    if Vector2(p.x-position.x,p.z-position.z).length()>radius+1.5:
      continue
    var idx: Vector2i=terrain.call("_indices",p.x,p.z)
    if int(terrain.call("_load_cell",idx.x,idx.y)["cuts"])>0:
      flowers.multimesh.set_instance_transform(i,_hidden_transform)
    else:
      flowers.multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY,
        Vector3(p.x,float(terrain.call("height_at",p.x,p.z)),p.z)))

func _create_fireflies(room: Node) -> void:
  particles=GPUParticles3D.new()
  particles.name="NaturalWarmMobileFireflyParticlesTiered"
  particles.position=Vector3(-7,2.0,-26)
  particles.amount=60
  particles.emitting=true
  particles.lifetime=7.0
  var process:=ParticleProcessMaterial.new()
  process.emission_shape=ParticleProcessMaterial.EMISSION_SHAPE_BOX
  process.emission_box_extents=Vector3(18,2.0,14.0)
  process.gravity=Vector3.ZERO
  process.initial_velocity_min=0.04
  process.initial_velocity_max=0.27
  particles.process_material=process
  var quad:=QuadMesh.new()
  quad.size=Vector2(0.055,0.055)
  var mat:=StandardMaterial3D.new()
  mat.albedo_color=Color("#ffe8a6",0.82)
  mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
  mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
  mat.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED
  mat.emission_enabled=true
  mat.emission=Color("#f4d882")
  mat.emission_energy_multiplier=0.95
  quad.material=mat
  particles.draw_pass_1=quad
  room.get("world").add_child(particles)

func _cloud_texture() -> ImageTexture:
  # An RGBA silhouette with round overlapping cumulus blobs; unlike
  # rectangular flat cards, transparent corners show actual blue sky.
  var pic:=Image.create(128,64,false,Image.FORMAT_RGBA8)
  for y in range(64):
    for x in range(128):
      var uv:=Vector2((float(x)-64.0)/64.0,(float(y)-32.0)/32.0)
      var value: float=0.0
      for center in [Vector2(-0.57,0.22),Vector2(-0.20,-0.10),
          Vector2(0.17,0.13),Vector2(0.55,0.23),Vector2(0.0,0.30)]:
        var rx: float=0.35 if center.y>0.0 else 0.48
        var ry: float=0.30 if center.y>0.0 else 0.53
        var d: float=Vector2((uv.x-center.x)/rx,(uv.y-center.y)/ry).length()
        value=maxf(value,clampf((1.0-d)*5.0,0,1.0))
      var soft: float=value*0.55
      pic.set_pixel(x,y,Color(1.0,0.985,0.95,soft))
  return ImageTexture.create_from_image(pic)

func _create_clouds(room: Node) -> void:
  clouds=MultiMeshInstance3D.new()
  clouds.name="RealBlueSkySoftWhiteCumulusCards"
  var mesh:=QuadMesh.new()
  mesh.size=Vector2(28,10)
  var material:=StandardMaterial3D.new()
  material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
  material.albedo_texture=_cloud_texture()
  material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
  material.cull_mode=BaseMaterial3D.CULL_DISABLED
  material.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED
  material.depth_draw_mode=BaseMaterial3D.DEPTH_DRAW_DISABLED
  mesh.material=material
  var mm:=MultiMesh.new()
  mm.transform_format=MultiMesh.TRANSFORM_3D
  mm.mesh=mesh
  mm.instance_count=9
  for i in range(9):
    var theta: float=TAU*float(i)/9.0
    var center:=Vector3(sin(theta)*float(84+i*8),42.0+float(i%3)*6.0,
      cos(theta)*float(84+i*8))
    mm.set_instance_transform(i,Transform3D(Basis.IDENTITY,center))
  clouds.multimesh=mm
  clouds.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  room.get("world").add_child(clouds)

func apply(profile_name: String,save: bool=true) -> bool:
  if not PROFILES.has(profile_name):
    return false
  selected=profile_name
  var p: Dictionary=PROFILES[selected]
  view.size=Vector2i(maxi(16,roundi(physical_screen.x*float(p["scale"]))),
    maxi(16,roundi(physical_screen.y*float(p["scale"]))))
  view.msaa_3d=p["msaa"]
  sun.directional_shadow_max_distance=float(p["shadow_m"])
  if int(p["shadow_splits"])==2:
    sun.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
  elif int(p["shadow_splits"])==1:
    sun.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
  else:
    sun.directional_shadow_mode=DirectionalLight3D.SHADOW_ORTHOGONAL
  sun.shadow_enabled=true
  sun.light_energy=1.08 if selected=="普通" else (1.15 if selected=="高档" else 1.25)
  scene_environment.fog_enabled=true
  scene_environment.fog_light_color=Color("#b8d9e8")
  scene_environment.fog_density=float(p["fog_density"])
  # Modern Godot Mobile renderer does not guarantee Forward+ screen glow.
  # The actual emissive fireflies remain visible in all three tiers.
  scene_environment.glow_enabled=false
  grass.visibility_range_end=float(p["grass_distance"])
  grass.multimesh.visible_instance_count=int(p["grass_instances"])
  flowers.multimesh.visible_instance_count=int(roundi(float(p["grass_instances"])/4500.0*270.0))
  particles.amount=int(p["fireflies"])
  particles.restart()
  clouds.multimesh.visible_instance_count=int(p["clouds"])
  for tag in labels.values():
    (tag as Label3D).visibility_range_end=float(p["name_distance"])
  profile_applied=true
  if save:
    _save_settings()
  update_diagnostics()
  return true

func render_profile() -> Dictionary:
  return PROFILES[selected].duplicate(true)

func update_diagnostics() -> Dictionary:
  if not profile_applied:
    return {}
  var fps: int=Engine.get_frames_per_second()
  var draws: int=RenderingServer.get_rendering_info(
    RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
  var triangles: int=RenderingServer.get_rendering_info(
    RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
  var p: Dictionary=PROFILES[selected]
  var size: Vector2i=view.size
  var cap_label: String="跟随刷新率（最高120）" if fps_mode=="跟随刷新率" else fps_mode
  last_metrics={
    "profile":selected,"fps":fps,"draw_calls":draws,"triangles":triangles,
    "render_3d_size":size,"render_scale":float(p["scale"]),
    "screen_pixels":physical_screen,"screen_api_reported_hz":actual_refresh,
    "fps_mode":fps_mode,"engine_fps_limit":Engine.max_fps,
    "reference_max_draw_calls":int(p["draw_reference"]),
    "reference_max_triangles":int(p["triangle_reference"]),
    "grass_leaf_blades_per_tuft":5,"grass_height_m_min":0.31,
    "grass_height_m_max":0.586,"total_flower_instances":flowers.multimesh.instance_count,
    "auto_quality_changes":false,"unrestricted_natural_palette":true
  }
  if diagnostic_text!=null:
    diagnostic_text.text=("%s | FPS %d | Draw %d/%d | 三角面 %d/%d\n" +
      "3D %d×%d (%d%%) | 帧率: %s | 系统接口刷新率 %.0fHz") % [
        selected,fps,draws,int(p["draw_reference"]),triangles,int(p["triangle_reference"]),
        size.x,size.y,int(float(p["scale"])*100.0),cap_label,actual_refresh]
  if low_fps_text!=null:
    low_fps_text.visible=fps>0 and fps<45
    if low_fps_text.visible:
      low_fps_text.text="⚠ 低于45FPS，仅提醒；画质与帧率上限绝不自动更改"
  return last_metrics.duplicate(true)

func get_stats() -> Dictionary:
  return last_metrics.duplicate(true)
