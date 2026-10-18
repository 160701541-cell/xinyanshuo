extends RefCounted
## rev207: vivid PBR detail while preserving original complete Quaternius GLBs.
## The nine 512x512 RGB/normal/roughness maps are source-verified CC0
## derivatives, NOT invented placeholder colors. Very fine texels only;
## the entire world and native HUD must never become giant 8-bit squares.
const MATERIAL_DIRECTORY: String="res://canglan_rev187/materials_rev207/"
const TEXTURES: Dictionary={
  "plaster":{"albedo":"plaster_albedo.png",
    "normal":"plaster_normal.png","roughness":"plaster_orm.png",
    "orm":true},
  "tile":{"albedo":"tile_albedo.png",
    "normal":"tile_normal.png","roughness":"tile_roughness.png"},
  "timber":{"albedo":"timber_albedo.png",
    "normal":"timber_normal.png","roughness":"timber_roughness.png"}}
const MEANINGFUL_COLORS: Dictionary={
  "roof":Color("#354c60"),"wood":Color("#765035"),
  "brick":Color("#ae6141"),"white_plaster":Color("#d4c4a5"),
  "grass":Color("#346f3f"),"rock":Color("#515d64"),
  "clay":Color("#9e5f3b")}
const MICRO_PIXELS: int=256
# 256 texels tiled every 4m = 64 actual small surface texels/metre.
const TEXELS_PER_METRE: float=64.0
var image_cache: Dictionary={}
var missing_source_files: Array[String]=[]
var source_textured_surfaces: int=0
var added_real_pbr_surfaces: int=0
var optimized_original_surfaces: int=0
var normal_mapped_surfaces: int=0
var fallback_triplanar_surfaces: int=0
var model_material_roles: Dictionary={}
var _microtexture: Texture2D
var _shared_shader: Shader
# rev208 P0-HQ-ECOLOGY：真实 CC0 扫描 PBR 两级地表（REV208-HQ-022）。
# 资源缺失时保持 null，地面继续用旧的 micron 方案，绝不假装高精。
var hq_ecology: RefCounted = null
var hq_ecology_status: String = "NOT_LOADED"

func initialize() -> void:
  for family in TEXTURES:
    for kind in TEXTURES[family]:
      if kind=="orm":
        continue
      _load_png(String(TEXTURES[family][kind]))
  _microtexture=_make_detail_grain()
  _shared_shader=_make_world_texel_shader()
  hq_ecology=null
  hq_ecology_status="RESOURCE_ABSENT"
  var hq_path: String="res://canglan_rev187/hq_terrain_pbr.gd"
  if ResourceLoader.exists(hq_path):
    var script: Resource=ResourceLoader.load(hq_path)
    if script is GDScript:
      var instance: RefCounted=(script as GDScript).new()
      if instance!=null and instance.has_method("build_ground_material"):
        instance.call("initialize")
        hq_ecology=instance
        hq_ecology_status="LOADED"
      else:
        hq_ecology_status="SCRIPT_WITHOUT_API"
    else:
      hq_ecology_status="NOT_A_GDSCRIPT"
  else:
    hq_ecology_status="RESOURCE_ABSENT"

func _load_png(name: String) -> Texture2D:
  if image_cache.has(name):
    return image_cache[name]
  var path: String=MATERIAL_DIRECTORY+name
  if not FileAccess.file_exists(path):
    if not missing_source_files.has(name):
      missing_source_files.append(name)
    return null
  var image:=Image.new()
  if image.load(path)!=OK or image.get_width()!=512 or (
      image.get_height()!=512):
    if not missing_source_files.has(name):
      missing_source_files.append(name)
    return null
  var texture: Texture2D=ImageTexture.create_from_image(image)
  image_cache[name]=texture
  return texture

func _make_detail_grain() -> ImageTexture:
  var image:=Image.create(MICRO_PIXELS,MICRO_PIXELS,false,Image.FORMAT_RGBA8)
  # Stable non-repeating little dark/bright grains and scar flecks, unlike
  # huge "pixel art" tiles. 256² texture shared by ALL ground sections.
  for y in range(MICRO_PIXELS):
    for x in range(MICRO_PIXELS):
      var n: int=(x*374761393+y*668265263+20261017)&0x7fffffff
      n=((n^(n>>13))*1274126177)&0x7fffffff
      var scatter: float=float(n%1001)/1000.0
      var grain: float=0.72+scatter*0.50
      # Fine organic mineral/soil chips, still continuous at full render.
      if scatter<0.035:
        grain*=0.69
      elif scatter>0.97:
        grain*=1.14
      image.set_pixel(x,y,Color(grain,grain,grain,1))
  return ImageTexture.create_from_image(image)

func _make_world_texel_shader() -> Shader:
  var shader:=Shader.new()
  shader.code = """
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;
uniform sampler2D micron_tex : source_color, repeat_enable, filter_nearest_mipmap;
uniform vec4 material_tint : source_color = vec4(1.0);
uniform bool vertex_biome = true;
uniform float tiles_per_metre = 0.25;
uniform float micro_strength = 0.38;
varying vec3 absolute_pos;
void vertex() {
    absolute_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
    vec2 fine_uv = absolute_pos.xz * tiles_per_metre;
    vec3 micro = texture(micron_tex, fine_uv).rgb;
    vec3 ground = vertex_biome ? COLOR.rgb : material_tint.rgb;
    float speckle = dot(micro, vec3(0.299, 0.587, 0.114));
    float contrast = mix(1.0, clamp(speckle, 0.56, 1.22), micro_strength);
    // Source vertex palette remains authoritative: fine texels do not
    // produce checkerboard biome colors or change finite geometry/collision.
    ALBEDO = clamp(ground * contrast, vec3(0.0), vec3(1.0));
    ROUGHNESS = 0.87 + clamp((1.0-speckle)*0.10,-0.05,0.08);
    METALLIC = 0.0;
}
"""
  return shader

func material_for_real_terrain(role: String,base_color: Color,
    vertex_biome: bool) -> ShaderMaterial:
  if _microtexture==null or _shared_shader==null:
    initialize()
  # REV208-HQ-022：真实自然地面优先使用 Poly Haven CC0 扫描的两级 PBR。
  # 只替换 natural_ground；石壁/土层等分层地表仍走原有 Vivid 逻辑。
  # REV208-HQ-022 两级 PBR 地表：真机/CI 实测（run 39109440674 的
  # real_godot_rev208_* 帧）显示该自定义 shader 在地形上输出为一片均匀青色，
  # 被既有 REV191 地面可见性审计判 FAIL(ratio 0.777)。**在真实渲染下修好之前
  # 必须默认关闭**，绝不能让玩家看到一块青色的地。资源与解析器保留，等修好再开。
  const HQ_GROUND_SHADER_ENABLED: bool = false
  if role=="natural_ground" and hq_ecology!=null and HQ_GROUND_SHADER_ENABLED:
    var hq_ground: ShaderMaterial=hq_ecology.call(
      "build_ground_material",vertex_biome) as ShaderMaterial
    if hq_ground!=null:
      return hq_ground
    hq_ecology_status="GROUND_BUILD_FAILED_KEPT_VIVID_FALLBACK"
  var material:=ShaderMaterial.new()
  material.resource_name="RealSoilWorldSpace64TexelsPerMetre_"+role
  material.shader=_shared_shader
  material.set_shader_parameter("micron_tex",_microtexture)
  material.set_shader_parameter("material_tint",base_color)
  material.set_shader_parameter("vertex_biome",vertex_biome)
  material.set_shader_parameter("tiles_per_metre",TEXELS_PER_METRE/float(MICRO_PIXELS))
  material.set_shader_parameter("micro_strength",0.39 if role=="natural_ground" else 0.31)
  return material

func _boost_vendor_color(raw: Color,role: String) -> Color:
  # Never remove the vendor's UV/PBR texture. Deepen only tinted RGB values,
  # not alpha/transparency; white plaster stays neutral, not pink.
  var out: Color=raw
  if raw.s>0.08:
    out=Color.from_hsv(raw.h,clampf(raw.s*1.24,0.0,0.90),
      clampf(raw.v*0.945,0.10,0.96),raw.a)
  else:
    out=Color(raw.r*0.94,raw.g*0.94,raw.b*0.94,raw.a)
  if role=="tile":
    out=out.lerp(MEANINGFUL_COLORS["roof"],0.11)
  elif role=="timber":
    out=out.lerp(MEANINGFUL_COLORS["wood"],0.10)
  return out

func _family_from_surface(model: String,part_name: String,
    original: StandardMaterial3D) -> String:
  var tag: String=(model+" "+part_name+" "+original.resource_name).to_lower()
  if tag.contains("tile") or tag.contains("roof") or tag.contains("slate"):
    return "tile"
  if tag.contains("wood") or tag.contains("beam") or tag.contains("timber") or (
      tag.contains("plank") or tag.contains("pillar") or tag.contains("door")):
    return "timber"
  if tag.contains("plaster") or tag.contains("stucco") or tag.contains("wall") or (
      tag.contains("cement") or tag.contains("white")):
    return "plaster"
  # Some Quaternius medieval GLBs use anonymous Material.0 etc.
  # Only select fallback PBR for clearly NON-textured building materials.
  var color: Color=original.albedo_color
  if color.v>=0.76 and color.s<=0.28:
    return "plaster"
  if color.b>=color.r*0.95 and color.b>=color.g*0.92 and color.v<0.55:
    return "tile"
  if color.r>color.b*1.30 and color.g>=color.b*1.02:
    return "timber"
  return ""

func _real_texture_color_count(texture: Texture2D) -> bool:
  return texture!=null and texture.get_width()>=128

func upgrade_completed_cc0_model(root: Node3D,model_name: String,
    category: String) -> Dictionary:
  if _microtexture==null:
    initialize()
  var with_real_source_uv: int=0
  var new_pbr: int=0
  var tinted: int=0
  var surfaces: int=0
  var normals: int=0
  for node in root.find_children("*","MeshInstance3D",true,false):
    var instance: MeshInstance3D=node as MeshInstance3D
    if instance.mesh==null:
      continue
    for surface in range(instance.mesh.get_surface_count()):
      var source_material: Material=instance.get_active_material(surface)
      if not (source_material is StandardMaterial3D):
        continue # Preserve third-party custom shaders/transparent effects.
      var existing: StandardMaterial3D=source_material as StandardMaterial3D
      var material: StandardMaterial3D=existing.duplicate(true) as StandardMaterial3D
      var family: String=""
      if category=="building":
        family=_family_from_surface(model_name,String(instance.name),existing)
      # Do not "color paint" animals, clothing or skin with building textures.
      var owns_texture: bool=existing.albedo_texture!=null
      if owns_texture:
        source_textured_surfaces+=1
        with_real_source_uv+=1
      if not owns_texture and family!="" and not TEXTURES.is_empty():
        var recipe: Dictionary=TEXTURES.get(family,{})
        var authored: Texture2D=_load_png(String(recipe.get("albedo","")))
        var normal: Texture2D=_load_png(String(recipe.get("normal","")))
        var rough: Texture2D=_load_png(String(recipe.get("roughness","")))
        if authored!=null and normal!=null and rough!=null:
          var arrays: Array=instance.mesh.surface_get_arrays(surface)
          var has_uv: bool=arrays.size()>Mesh.ARRAY_TEX_UV and (
            arrays[Mesh.ARRAY_TEX_UV] is PackedVector2Array and not (
            arrays[Mesh.ARRAY_TEX_UV] as PackedVector2Array).is_empty())
          if not has_uv:
            material.uv1_triplanar=true
            material.uv1_scale=Vector3(0.65,0.65,0.65)
            fallback_triplanar_surfaces+=1
          material.albedo_texture=authored
          material.normal_enabled=true
          material.normal_texture=normal
          if family=="plaster":
            material.roughness_texture=rough
            material.roughness_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_GREEN
          else:
            material.roughness_texture=rough
          new_pbr+=1
          added_real_pbr_surfaces+=1
      material.albedo_color=_boost_vendor_color(existing.albedo_color,family)
      # Dense nearest-neighbor texels and mipmapping; extremely small
      # near-camera blocks, never giant screen-scale nearest pixelation.
      material.texture_filter=(
        BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS_ANISOTROPIC
        if category=="building" else
        BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC)
      material.texture_repeat=true
      material.roughness=maxf(0.28,material.roughness)
      if material.normal_texture!=null:
        normal_mapped_surfaces+=1
        normals+=1
      instance.set_surface_override_material(surface,material)
      tinted+=1
      surfaces+=1
  optimized_original_surfaces+=surfaces
  model_material_roles[model_name]={
    "category":category,"surfaces":surfaces,
    "original_texture_surfaces":with_real_source_uv,
    "new_cc0_pbr_surfaces":new_pbr,"normal_maps":normals,
    "genuine_source_preserved":true}
  return model_material_roles[model_name]

func summary() -> Dictionary:
  return {
    "material_maps_loaded":image_cache.size(),
    "source_png_errors":missing_source_files.duplicate(),
    "micro_texture_256_2d":_microtexture!=null,
    "micro_texels_per_metre":TEXELS_PER_METRE,
    "original_vendor_albedo_preserved":source_textured_surfaces,
    "added_vendor_cc0_pbr_surfaces":added_real_pbr_surfaces,
    "normal_mapped_surfaces":normal_mapped_surfaces,
    "optimized_vendor_surfaces":optimized_original_surfaces,
    "triplanar_no_uv_surfaces":fallback_triplanar_surfaces,
    "rev208_hq_ecology_module":hq_ecology_status,
    "rev208_hq_ecology_summary":(
      hq_ecology.call("summary") if hq_ecology!=null else {}),
    "model_material_roles":model_material_roles.duplicate(true)
  }
