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

func initialize() -> void:
  for family in TEXTURES:
    for kind in TEXTURES[family]:
      if kind=="orm":
        continue
      _load_png(String(TEXTURES[family][kind]))
  _microtexture=_make_detail_grain()
  _shared_shader=_make_world_texel_shader()

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

func upgrade_han_ccby_source(root: Node3D,model: String) -> Dictionary:
  # 0 A.D. original ancient Han glTF mesh has zero embedded texture images,
  # so it previously appeared as the same pale untextured material. Keep
  # existing Chinese geometry while adding nine genuine CC0 diffuse/normal/
  # roughness wall/wood/tile images as lawful *derived* CC-BY-SA 3.0 art.
  # Do not substitute a western medieval mesh or generate any 3D geometry.
  var wall: Texture2D=_load_png("plaster_albedo.png")
  var roof: Texture2D=_load_png("tile_albedo.png")
  var wood: Texture2D=_load_png("timber_albedo.png")
  var wall_normal: Texture2D=_load_png("plaster_normal.png")
  var roof_normal: Texture2D=_load_png("tile_normal.png")
  var wood_normal: Texture2D=_load_png("timber_normal.png")
  var plaster_orm: Texture2D=_load_png("plaster_orm.png")
  var tiles_rough: Texture2D=_load_png("tile_roughness.png")
  var wood_rough: Texture2D=_load_png("timber_roughness.png")
  if wall==null or roof==null or wood==null or wall_normal==null or (
      roof_normal==null or wood_normal==null or plaster_orm==null or (
      tiles_rough==null or wood_rough==null)):
    return {"ok":false,"reason":"NINE_ORIGINAL_REAL_CC0_PBR_IMAGES_MISSING"}
  var han_shader:=Shader.new()
  han_shader.code="""
shader_type spatial;
render_mode depth_draw_opaque, cull_back;
uniform sampler2D plaster_map : source_color, repeat_enable, filter_nearest_mipmap;
uniform sampler2D roof_map : source_color, repeat_enable, filter_nearest_mipmap;
uniform sampler2D timber_map : source_color, repeat_enable, filter_nearest_mipmap;
uniform sampler2D plaster_normal : hint_normal, repeat_enable, filter_linear_mipmap;
uniform sampler2D roof_normal : hint_normal, repeat_enable, filter_linear_mipmap;
uniform sampler2D timber_normal : hint_normal, repeat_enable, filter_linear_mipmap;
uniform sampler2D plaster_orm : repeat_enable, filter_linear_mipmap;
uniform sampler2D roof_rough : repeat_enable, filter_linear_mipmap;
uniform sampler2D timber_rough : repeat_enable, filter_linear_mipmap;
uniform float stone_base_world_y=0.0;
uniform float roof_transition_world_y=2.1;
varying vec3 world_point;
varying vec3 world_normal;
void vertex() {
  world_point=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
  world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);
}
void fragment() {
  // 512 texels per 8 m world repeat => 64 dense surface texels/metre.
  vec2 uv_v=world_point.xz*0.125;
  vec2 uv_w=world_point.xy*0.125;
  float roof_weight=smoothstep(roof_transition_world_y,
    roof_transition_world_y+1.0,world_point.y)
    *smoothstep(0.40,0.85,world_normal.y);
  float column_weight=(1.0-roof_weight)*
    (1.0-smoothstep(0.35,0.88,abs(world_normal.y)));
  // Keep solid vivid teak pillars narrow, never paint the whole house brown.
  float grain=abs(sin(world_point.x*1.45)*cos(world_point.z*1.10));
  float timber_weight=column_weight*smoothstep(0.72,0.92,grain)*0.64;
  vec3 plaster=texture(plaster_map,uv_w).rgb*vec3(0.91,0.86,0.78);
  vec3 tiled=texture(roof_map,uv_v).rgb*vec3(0.46,0.72,0.87);
  vec3 timber=texture(timber_map,uv_w).rgb*vec3(0.72,0.47,0.29);
  ALBEDO=mix(mix(plaster,timber,timber_weight),tiled,roof_weight);
  vec3 base_normal=texture(plaster_normal,uv_w).rgb;
  vec3 tile_n=texture(roof_normal,uv_v).rgb;
  vec3 wood_n=texture(timber_normal,uv_w).rgb;
  NORMAL_MAP=mix(mix(base_normal,wood_n,timber_weight),tile_n,roof_weight);
  NORMAL_MAP_DEPTH=0.32;
  float rough_plaster=texture(plaster_orm,uv_w).g;
  float rough_tile=texture(roof_rough,uv_v).r;
  float rough_wood=texture(timber_rough,uv_w).r;
  ROUGHNESS=clamp(mix(mix(rough_plaster,rough_wood,timber_weight),
    rough_tile,roof_weight),0.52,0.96);
  METALLIC=0.0;
}
"""
  var modified: int=0
  for child in root.find_children("*","MeshInstance3D",true,false):
    var part: MeshInstance3D=child as MeshInstance3D
    if part.mesh==null:
      continue
    for i in range(part.mesh.get_surface_count()):
      var original: Material=part.get_active_material(i)
      # If a future original Han art update includes genuine PBR maps,
      # honor it first instead of replacing that with a fallback shader.
      if original is StandardMaterial3D and (
          (original as StandardMaterial3D).albedo_texture!=null):
        continue
      var shader_mat:=ShaderMaterial.new()
      shader_mat.resource_name="RealSourceHanCCBYSA_PBR_64TexelsPerMetre_"+model
      shader_mat.shader=han_shader
      shader_mat.set_shader_parameter("plaster_map",wall)
      shader_mat.set_shader_parameter("roof_map",roof)
      shader_mat.set_shader_parameter("timber_map",wood)
      shader_mat.set_shader_parameter("plaster_normal",wall_normal)
      shader_mat.set_shader_parameter("roof_normal",roof_normal)
      shader_mat.set_shader_parameter("timber_normal",wood_normal)
      shader_mat.set_shader_parameter("plaster_orm",plaster_orm)
      shader_mat.set_shader_parameter("roof_rough",tiles_rough)
      shader_mat.set_shader_parameter("timber_rough",wood_rough)
      shader_mat.set_shader_parameter("roof_transition_world_y",2.0)
      part.set_surface_override_material(i,shader_mat)
      modified+=1
  model_material_roles[model]={
    "category":"real_ancient_Han_CC_BY_SA_3.0",
    "original_shape_kept":true,"source_3d_vendor":"0AD_WildfireGames",
    "pbr_source_images":9,"surfaces_textured":modified,
    "material_license":"CC-BY-SA-3.0_Han_mesh_with_CC0_derivative_PBR"}
  return {"ok":modified>0,"textured_surfaces":modified}

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
    "model_material_roles":model_material_roles.duplicate(true)
  }
