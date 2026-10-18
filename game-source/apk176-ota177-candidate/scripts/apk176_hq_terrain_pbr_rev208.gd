extends RefCounted
## 《苍岚·人生世界》rev208 P0-HQ-ECOLOGY / REV208-HQ-022
## 真实 CC0 扫描 PBR 的两级地表着色（macro 2–8m + detail 2–8cm）。
##
## 这不是“调高饱和度”或“画一张绿图”。所有 albedo / normal / ORM 都来自
## Poly Haven 的 CC0 真扫描材质，逐文件 SHA256 与尺寸登记在
## assets/hq-rev208/ecology-intake-provenance.json（由
## tools/asset_factory/rev208_ecology_polyhaven_intake.mjs 生成并自校验）。
##
## 关键约定（报告要求逐源核验，不允许假定）：
##   - albedo : sRGB，三通道
##   - normal : 线性，OpenGL(+Y) 切线空间
##   - ORM    : 线性，R=AO, G=Roughness, B=Metallic（Poly Haven 的 arm 布局）
##
## Mobile 渲染器没有 SSAO，因此这里只依赖真实 Normal + AO/ORM + 接触阴影，
## 不承诺任何 Mobile 上做不出来的特效。

const DIRECTORY: String = "res://canglan_rev187/hq_ecology_terrain"
const PROVENANCE_PATH: String = "res://canglan_rev187/hq_ecology_terrain/ecology-intake-provenance.json"

## slug -> 该材质在世界坐标下一张图覆盖的边长（米）
const MACRO_METRES: Dictionary = {
  "forest_floor": 6.0, "leafy_grass": 5.0, "wet_leaf_soil": 4.0,
  "sparse_grass": 5.0, "mossy_rock": 4.0}
## detail 层（2–8cm）单独一张，不参与 macro 权重混合。
const DETAIL_SLUGS: Array[String] = ["leaf_litter_detail"]
const DETAIL_METRES: float = 0.06

const BARK_SETS: Dictionary = {
  "cypress": {"slug": "bark_chinese_cedar", "zh": "古柏树皮（中国雪松 CC0 扫描）"},
  "pine": {"slug": "bark_knotted_pine", "zh": "苍松树皮（疙瘩松 CC0 扫描）"}}

var textures: Dictionary = {}
var missing_files: Array[String] = []
var loaded_sets: int = 0
var shader_ready: bool = false
var last_build_report: Dictionary = {}
var _cached_ground: ShaderMaterial

func initialize() -> void:
  textures.clear()
  missing_files.clear()
  var all_slugs: Array[String] = []
  for slug in MACRO_METRES:
    all_slugs.append(String(slug))
  for slug in DETAIL_SLUGS:
    all_slugs.append(slug)
  for slug in all_slugs:
    var entry: Dictionary = {"albedo": null, "normal": null, "orm": null}
    for kind in ["albedo", "normal", "orm"]:
      var path: String = "%s/%s/%s_%s_1k.jpg" % [DIRECTORY, slug, slug, kind]
      var tex: Texture2D = _load_texture(path, kind != "albedo")
      if tex == null:
        if not missing_files.has(path):
          missing_files.append(path)
      else:
        entry[kind] = tex
    if entry["albedo"] != null and entry["normal"] != null and entry["orm"] != null:
      textures[slug] = entry
      loaded_sets += 1
  shader_ready = loaded_sets >= 1

func _load_texture(path: String, _linear: bool) -> Texture2D:
  # 必须走 ResourceLoader：正式 PCK 里 jpg 已被导入成 .ctex，
  # 直接 Image.load("res://*.jpg") 在导出包里会拿不到文件。
  if ResourceLoader.exists(path):
    var res: Resource = ResourceLoader.load(path)
    if res is Texture2D:
      var t: Texture2D = res as Texture2D
      if t.get_width() > 2048 or t.get_height() > 2048:
        return null
      return t
  # 未导入的裸文件（本机调试）才退回 Image 解码。
  if not FileAccess.file_exists(path):
    return null
  var image: Image = Image.new()
  if image.load(path) != OK or image.is_empty():
    return null
  if image.get_width() > 2048 or image.get_height() > 2048:
    return null
  return ImageTexture.create_from_image(image)

## 真实统计：把实际加载成功的贴图与尺寸报出来，供 QA 断言。
func texture_report() -> Dictionary:
  var out: Dictionary = {}
  for slug in textures:
    var entry: Dictionary = textures[slug]
    var sizes: Dictionary = {}
    for kind in entry:
      var tex: Texture2D = entry[kind]
      sizes[kind] = "%dx%d" % [tex.get_width(), tex.get_height()]
    out[slug] = sizes
  return out

func _ground_shader() -> Shader:
  var shader: Shader = Shader.new()
  shader.code = """
shader_type spatial;
render_mode cull_back, depth_draw_opaque;

// ---- macro 层（2–8m）----
uniform sampler2D macro_floor_albedo : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D macro_floor_normal : hint_normal, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D macro_floor_orm    : hint_default_white, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D macro_grass_albedo : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D macro_grass_normal : hint_normal, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D macro_grass_orm    : hint_default_white, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D macro_mud_albedo   : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D macro_mud_normal   : hint_normal, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D macro_mud_orm      : hint_default_white, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D macro_rock_albedo  : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D macro_rock_normal  : hint_normal, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D macro_rock_orm     : hint_default_white, repeat_enable, filter_linear_mipmap_anisotropic;

// ---- detail 层（2–8cm）----
uniform sampler2D detail_albedo : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D detail_normal : hint_normal, repeat_enable, filter_linear_mipmap_anisotropic;

uniform float macro_tiles_per_metre = 0.1666;
uniform float detail_tiles_per_metre = 16.6666;
uniform float detail_strength = 0.55;
uniform float vertex_tint_strength = 0.22;
uniform float global_brightness = 1.0;
uniform bool vertex_biome = true;

varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

// 稳定、可复现的低频权重场：不随机、不依赖时间，两档画质结果一致。
float weight_field(vec2 p, float scale, float seed) {
    vec2 q = p * scale + vec2(seed, seed * 1.7);
    vec2 i = floor(q);
    vec2 f = fract(q);
    f = f * f * (3.0 - 2.0 * f);
    float a = fract(sin(dot(i, vec2(12.9898, 78.233)) + seed) * 43758.5453);
    float b = fract(sin(dot(i + vec2(1.0, 0.0), vec2(12.9898, 78.233)) + seed) * 43758.5453);
    float c = fract(sin(dot(i + vec2(0.0, 1.0), vec2(12.9898, 78.233)) + seed) * 43758.5453);
    float d = fract(sin(dot(i + vec2(1.0, 1.0), vec2(12.9898, 78.233)) + seed) * 43758.5453);
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
    vec2 macro_uv = world_pos.xz * macro_tiles_per_metre;
    vec2 detail_uv = world_pos.xz * detail_tiles_per_metre;

    // 坡度：越陡越走岩石层，平地走林地/草甸。真实法线，不是贴图假装。
    float slope = 1.0 - clamp(world_normal.y, 0.0, 1.0);

    float n_grass = weight_field(world_pos.xz, 0.055, 3.1);
    float n_mud   = weight_field(world_pos.xz, 0.090, 11.7);
    float rock_w  = smoothstep(0.18, 0.42, slope);
    float grass_w = smoothstep(0.52, 0.82, n_grass) * (1.0 - rock_w);
    float mud_w   = smoothstep(0.55, 0.85, n_mud) * (1.0 - rock_w) * (1.0 - grass_w);
    float floor_w = clamp(1.0 - rock_w - grass_w - mud_w, 0.0, 1.0);

    vec3 a_floor = texture(macro_floor_albedo, macro_uv).rgb;
    vec3 a_grass = texture(macro_grass_albedo, macro_uv).rgb;
    vec3 a_mud   = texture(macro_mud_albedo,   macro_uv).rgb;
    vec3 a_rock  = texture(macro_rock_albedo,  macro_uv).rgb;
    vec3 albedo = a_floor * floor_w + a_grass * grass_w + a_mud * mud_w + a_rock * rock_w;

    float o_floor = texture(macro_floor_orm, macro_uv).g;
    float o_grass = texture(macro_grass_orm, macro_uv).g;
    float o_mud   = texture(macro_mud_orm,   macro_uv).g;
    float o_rock  = texture(macro_rock_orm,  macro_uv).g;
    float rough = o_floor * floor_w + o_grass * grass_w + o_mud * mud_w + o_rock * rock_w;
    float ao = texture(macro_floor_orm, macro_uv).r * floor_w
             + texture(macro_grass_orm, macro_uv).r * grass_w
             + texture(macro_mud_orm,   macro_uv).r * mud_w
             + texture(macro_rock_orm,  macro_uv).r * rock_w;

    // 细节层：2–8cm 微观细枝/落叶，只在亮度上叠加，避免把 biome 色带翻掉。
    vec3 d_rgb = texture(detail_albedo, detail_uv).rgb;
    float d_l = mix(1.0, luma(d_rgb) * 2.0, detail_strength * 0.35);
    albedo *= clamp(d_l, 0.72, 1.28);

    // 顶点 biome 色只作为色相调制参与，不让它抹掉真实纹理细节。
    if (vertex_biome) {
        float cl = max(luma(COLOR.rgb), 0.06);
        vec3 tint = COLOR.rgb / cl;
        albedo *= mix(vec3(1.0), tint, vertex_tint_strength);
    }

    ALBEDO = clamp(albedo * global_brightness, vec3(0.0), vec3(1.0));
    ROUGHNESS = clamp(rough, 0.18, 1.0);
    METALLIC = 0.0;
    AO = clamp(ao, 0.0, 1.0);

    // 法线：主 macro 层 + 细节层，切线空间相加后重整化（移动端可承受）。
    vec3 nf = texture(macro_floor_normal, macro_uv).xyz * 2.0 - 1.0;
    vec3 ng = texture(macro_grass_normal, macro_uv).xyz * 2.0 - 1.0;
    vec3 nm = texture(macro_mud_normal,   macro_uv).xyz * 2.0 - 1.0;
    vec3 nr = texture(macro_rock_normal,  macro_uv).xyz * 2.0 - 1.0;
    vec3 n_macro = nf * floor_w + ng * grass_w + nm * mud_w + nr * rock_w;
    vec3 n_detail = texture(detail_normal, detail_uv).xyz * 2.0 - 1.0;
    vec3 n_t = normalize(n_macro + n_detail * detail_strength * 0.6);
    NORMAL_MAP = n_t * 0.5 + 0.5;
}
"""
  return shader

## 构建真实两级 PBR 地面材质。返回 null 表示贴图确实缺失（调用方应保留旧材质）。
func build_ground_material(vertex_biome: bool = true) -> ShaderMaterial:
  if loaded_sets < 4:
    initialize()
  var need: Array[String] = ["forest_floor", "leafy_grass", "wet_leaf_soil", "mossy_rock"]
  for slug in need:
    if not textures.has(slug):
      missing_files.append(DIRECTORY + "/" + slug + " (set incomplete)")
      return null
  if not textures.has("leaf_litter_detail"):
    missing_files.append(DIRECTORY + "/leaf_litter_detail (detail layer)")
    return null
  var material: ShaderMaterial = ShaderMaterial.new()
  material.resource_name = "HQ_TwoScale_RealCC0_PBR_Ground_REV208"
  material.shader = _ground_shader()
  var alias: Dictionary = {
    "forest_floor": "floor", "leafy_grass": "grass",
    "wet_leaf_soil": "mud", "mossy_rock": "rock"}
  for slug in alias:
    var key: String = String(alias[slug])
    material.set_shader_parameter("macro_%s_albedo" % key, textures[slug]["albedo"])
    material.set_shader_parameter("macro_%s_normal" % key, textures[slug]["normal"])
    material.set_shader_parameter("macro_%s_orm" % key, textures[slug]["orm"])
  material.set_shader_parameter("detail_albedo", textures["leaf_litter_detail"]["albedo"])
  material.set_shader_parameter("detail_normal", textures["leaf_litter_detail"]["normal"])
  material.set_shader_parameter("macro_tiles_per_metre", 1.0 / float(MACRO_METRES["forest_floor"]))
  material.set_shader_parameter("detail_tiles_per_metre", 1.0 / DETAIL_METRES)
  material.set_shader_parameter("detail_strength", 0.55)
  material.set_shader_parameter("vertex_tint_strength", 0.22)
  material.set_shader_parameter("vertex_biome", vertex_biome)
  _cached_ground = material
  last_build_report = {
    "material": material.resource_name,
    "macro_layers": alias.size(),
    "detail_layer": "leaf_litter_detail",
    "macro_metres": MACRO_METRES.duplicate(),
    "detail_metres": DETAIL_METRES,
    "real_cc0_pbr_sets_loaded": loaded_sets,
    "missing": missing_files.duplicate()}
  return material

## 给苍松/古柏树干用的真实树皮 PBR（StandardMaterial3D，Godot 原生 PBR 管线）。
func build_bark_material(kind: String) -> StandardMaterial3D:
  if not BARK_SETS.has(kind):
    return null
  var slug: String = String(BARK_SETS[kind]["slug"])
  if loaded_sets < 1:
    initialize()
  if not textures.has(slug):
    # 树皮单独加载，不依赖地表层是否齐备。
    var entry: Dictionary = {"albedo": null, "normal": null, "orm": null}
    for k in ["albedo", "normal", "orm"]:
      entry[k] = _load_texture("%s/%s/%s_%s_1k.jpg" % [DIRECTORY, slug, slug, k], k != "albedo")
    if entry["albedo"] == null:
      return null
    textures[slug] = entry
  var set: Dictionary = textures[slug]
  var material: StandardMaterial3D = StandardMaterial3D.new()
  material.resource_name = "HQ_RealCC0_Bark_%s_REV208" % kind
  material.albedo_texture = set["albedo"]
  material.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
  if set["normal"] != null:
    material.normal_enabled = true
    material.normal_texture = set["normal"]
    material.normal_scale = 1.0
  if set["orm"] != null:
    # Poly Haven arm：R=AO / G=Roughness / B=Metallic
    material.roughness_texture = set["orm"]
    material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
    material.ao_enabled = true
    material.ao_texture = set["orm"]
    material.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
  material.uv1_scale = Vector3(1.0, 1.0, 1.0)
  material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
  material.texture_repeat = true
  material.roughness = 0.88
  return material

func summary() -> Dictionary:
  return {
    "module": "apk176_hq_terrain_pbr_rev208.gd",
    "checklist": ["REV208-HQ-022", "REV208-HQ-020"],
    "pbr_sets_loaded": loaded_sets,
    "expected_sets": MACRO_METRES.size() + DETAIL_SLUGS.size(),
    "textures": texture_report(),
    "missing": missing_files.duplicate(),
    "ground_material_built": _cached_ground != null,
    "last_build": last_build_report.duplicate(true)}

# ---------------------------------------------------------------------------
# REV208-HQ-020：真实扫描地被物种接入
# ---------------------------------------------------------------------------
## 这四个不是低模球体，是 Poly Haven CC0 扫描的蕨/灌木/苔藓/苔石。
## 资源缺失时（例如没跑 staging）整段安全跳过，不影响原世界启动。
const GROUNDCOVER_ROOT: String = "res://canglan_rev187/hq_ecology_groundcover"
const GROUNDCOVER_SPECIES: Dictionary = {
  "fern_clump": {"max": 10, "min_metres": 0.35, "collider": false},
  "shrub_low": {"max": 8, "min_metres": 0.25, "collider": false},
  "moss_patch": {"max": 12, "min_metres": 0.05, "collider": false},
  "rock_moss_set": {"max": 6, "min_metres": 0.35, "collider": true}}

func groundcover_availability() -> Dictionary:
  var out: Dictionary = {}
  for slug in GROUNDCOVER_SPECIES:
    var path: String = "%s/%s/%s_1k.gltf" % [GROUNDCOVER_ROOT, slug, slug]
    out[slug] = ResourceLoader.exists(path)
  return out

## 在世界里布置真实扫描地被。返回可审计的 report（不含任何凭空物品）。
func spawn_groundcover(world: Node3D, terrain: Node3D, quality: RefCounted,
    seed_value: int = 208311) -> Dictionary:
  var report: Dictionary = {"spawned": 0, "by_species": {}, "skipped": [],
    "installed": [], "module": "apk176_hq_terrain_pbr_rev208.gd"}
  if world == null or terrain == null:
    report["skipped"].append("WORLD_OR_TERRAIN_MISSING")
    return report
  var rng: RandomNumberGenerator = RandomNumberGenerator.new()
  rng.seed = seed_value
  for slug in GROUNDCOVER_SPECIES:
    var cfg: Dictionary = GROUNDCOVER_SPECIES[slug]
    var path: String = "%s/%s/%s_1k.gltf" % [GROUNDCOVER_ROOT, slug, slug]
    var actor: Node3D = _load_gltf_runtime(path)
    if actor == null:
      report["skipped"].append(slug + ":RESOURCE_ABSENT_OR_UNPARSABLE")
      continue
    var placed: int = 0
    var attempt: int = 0
    while placed < int(cfg["max"]) and attempt < int(cfg["max"]) * 24:
      attempt += 1
      # 分布在与已有 HQ 松柏林同一片山林，而不是铺满全图。
      var x: float = rng.randf_range(-42.0, -13.0)
      var z: float = rng.randf_range(-42.0, 42.0)
      if quality != null and quality.has_method("_natural_plantable"):
        if not bool(quality.call("_natural_plantable", x, z)):
          continue
      # 每个实例都要独立拷贝，不能共用同一个模板节点。
      var instance: Node3D = actor.duplicate()
      if instance == null:
        continue
      var identity: String = "CL-ECOLOGY208-%s-%03d" % [slug, placed]
      instance.name = identity
      var ground: float = 0.0
      if terrain.has_method("height_at"):
        ground = float(terrain.call("height_at", x, z))
      # 真实高度落地：把网格最低点压到地形高度，不悬空也不埋进土里。
      var bounds: Vector3 = _node_low_point(instance)
      instance.position = Vector3(x, ground - bounds.y, z)
      instance.rotation.y = rng.randf_range(-PI, PI)
      instance.set_meta("world_entity_id", identity)
      instance.set_meta("hq_rev208_real_scanned_groundcover", slug)
      instance.set_meta("source_license", "CC0 Poly Haven exact source page")
      instance.set_meta("never_free_inventory", true)
      world.add_child(instance)
      if bool(cfg["collider"]):
        var body: StaticBody3D = StaticBody3D.new()
        body.name = "EcologyRock_" + identity
        body.collision_layer = 2
        body.collision_mask = 0
        var shape: CollisionShape3D = CollisionShape3D.new()
        var box: BoxShape3D = BoxShape3D.new()
        var aabb: AABB = _node_aabb(instance)
        box.size = Vector3(maxf(aabb.size.x, 0.4), maxf(aabb.size.y, 0.4),
          maxf(aabb.size.z, 0.4))
        shape.shape = box
        shape.position.y = box.size.y * 0.5
        body.add_child(shape)
        body.position = instance.position
        world.add_child(body)
      report["installed"].append(identity)
      placed += 1
      report["spawned"] = int(report["spawned"]) + 1
    report["by_species"][slug] = placed
    if is_instance_valid(actor):
      actor.free()
  return report

func _node_aabb(root: Node3D) -> AABB:
  var box: AABB = AABB()
  var first: bool = true
  for node in root.find_children("*", "MeshInstance3D", true, false):
    var mi: MeshInstance3D = node as MeshInstance3D
    if mi == null or mi.mesh == null:
      continue
    var local: AABB = mi.get_aabb()
    var world_box: AABB = mi.transform * local
    if first:
      box = world_box
      first = false
    else:
      box = box.merge(world_box)
  return box

func _node_low_point(root: Node3D) -> Vector3:
  var box: AABB = _node_aabb(root)
  return box.position if box.size != Vector3.ZERO else Vector3.ZERO

## REV208-HQ-020：给近景针叶树干上真正的 CC0 树皮 PBR。
## 只接管“原本没有任何 albedo 贴图”的表面，第三方已有 UV/PBR 一律保留。
func apply_bark_to_tree(root: Node3D, kind: String) -> int:
  if root == null or not BARK_SETS.has(kind):
    return 0
  var bark: StandardMaterial3D = build_bark_material(kind)
  if bark == null:
    return 0
  var replaced: int = 0
  var nodes: Array[Node] = []
  if root is MeshInstance3D:
    nodes.append(root)
  nodes.append_array(root.find_children("*", "MeshInstance3D", true, false))
  for node in nodes:
    var mi: MeshInstance3D = node as MeshInstance3D
    if mi == null or mi.mesh == null:
      continue
    for s in range(mi.mesh.get_surface_count()):
      var existing: Material = mi.get_active_material(s)
      if existing is StandardMaterial3D:
        var std: StandardMaterial3D = existing as StandardMaterial3D
        if std.albedo_texture != null:
          continue  # 真源已有贴图，不动
      mi.set_surface_override_material(s, bark)
      replaced += 1
  return replaced

## 正式 OTA PCK 里放的是原始 .gltf/.bin/textures（未导入成 .scn），
## 所以必须走 GLTFDocument 直接解析，和原项目 `_parse_existing_cc0` 一致。
func _load_gltf_runtime(path: String) -> Node3D:
  if ResourceLoader.exists(path):
    var res: Resource = ResourceLoader.load(path)
    if res is PackedScene:
      var n: Node = (res as PackedScene).instantiate()
      if n is Node3D:
        return n as Node3D
  if not FileAccess.file_exists(path):
    return null
  var binary: PackedByteArray = FileAccess.get_file_as_bytes(path)
  if binary.size() < 256:
    return null
  var doc: GLTFDocument = GLTFDocument.new()
  var state: GLTFState = GLTFState.new()
  if doc.append_from_buffer(binary, path.get_base_dir(), state) != OK:
    return null
  var scene: Node3D = doc.generate_scene(state)
  return scene
