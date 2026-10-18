extends SceneTree
## 《苍岚·人生世界》rev208 P0-HQ-ECOLOGY 真实 Godot 4.4.1 验证
##
## 这个脚本在真引擎里跑，不是读文件猜结果：
##   1. 逐文件用 HashingContext 重算 SHA256，和入库 manifest 对比；
##   2. 真的把 jpg 解码成 Image，核对像素尺寸、通道数，并统计方差，
##      证明它是有细节的真实扫描材质而不是一整片纯色；
##   3. 真的 import 每一个 glTF，统计运行时网格三角面数，和 manifest 对比；
##   4. 真的构造两级 PBR 地面材质，检查 shader uniform 全部绑定；
##      构造苍松/古柏树皮 PBR 材质，核对 ORM 通道映射；
##   5. 任何一项不成立就退出码 1，并打印具体失败原因。
##
## 用法：
##   godot --headless --path <fixture> --script res://verify_rev208_hq_ecology_pbr.gd

const MODULE := "res://canglan_rev187/hq_terrain_pbr.gd"
const TERRAIN_DIR := "res://canglan_rev187/hq_ecology_terrain"
const GROUNDCOVER_DIR := "res://canglan_rev187/hq_ecology_groundcover"
const PROVENANCE := TERRAIN_DIR + "/ecology-intake-provenance.json"

var failures: Array[String] = []
var checks: int = 0

func _fail(msg: String) -> void:
  failures.append(msg)
  push_error("QA FAIL: " + msg)

func _ok(cond: bool, msg: String) -> void:
  checks += 1
  if not cond:
    _fail(msg)

func _sha256(path: String) -> String:
  var fa := FileAccess.open(path, FileAccess.READ)
  if fa == null:
    return ""
  var ctx := HashingContext.new()
  ctx.start(HashingContext.HASH_SHA256)
  while not fa.eof_reached():
    var chunk := fa.get_buffer(1 << 20)
    if chunk.size() > 0:
      ctx.update(chunk)
  fa.close()
  return ctx.finish().hex_encode()

func _load_image(path: String) -> Image:
  # 正式 PCK 里 jpg 是导入过的 .ctex，必须用 ResourceLoader 取回 Image。
  if ResourceLoader.exists(path):
    var res: Resource = ResourceLoader.load(path)
    if res is Texture2D:
      var img: Image = (res as Texture2D).get_image()
      return img
  var raw := Image.new()
  if raw.load(path) == OK:
    return raw
  return null

func _image_stats(path: String) -> Dictionary:
  var img := _load_image(path)
  if img == null:
    return {"ok": false, "err": "load failed"}
  var w := img.get_width()
  var h := img.get_height()
  var fmt := img.get_format()
  var total := 0.0
  var total_sq := 0.0
  var n := 0
  var step := maxi(1, int(w / 64))
  for y in range(0, h, step):
    for x in range(0, w, step):
      var c := img.get_pixel(x, y)
      var v := c.r
      total += v
      total_sq += v * v
      n += 1
  var mean := total / float(maxi(1, n))
  var variance := maxf(0.0, total_sq / float(maxi(1, n)) - mean * mean)
  return {"ok": true, "w": w, "h": h, "format": fmt, "mean": mean,
    "stddev": sqrt(variance), "samples": n}

func _img_variance_rgb(path: String) -> Dictionary:
  var img := _load_image(path)
  if img == null:
    return {}
  img.decompress()
  img.convert(Image.FORMAT_RGBA8)
  var w := img.get_width()
  var h := img.get_height()
  var acc := [0.0, 0.0, 0.0]
  var acc2 := [0.0, 0.0, 0.0]
  var n := 0.0
  var step := maxi(1, int(w / 48))
  for y in range(0, h, step):
    for x in range(0, w, step):
      var c := img.get_pixel(x, y)
      var vals := [c.r, c.g, c.b]
      for i in 3:
        acc[i] += vals[i]
        acc2[i] += vals[i] * vals[i]
      n += 1.0
  var out := {}
  var names := ["r", "g", "b"]
  for i in 3:
    var m: float = acc[i] / n
    out[names[i]] = sqrt(maxf(0.0, acc2[i] / n - m * m))
  out["n"] = n
  return out

func _triangles_of_scene(path: String) -> Dictionary:
  var packed := load(path)
  if packed == null:
    return {"ok": false, "err": "load() returned null"}
  if not (packed is PackedScene):
    return {"ok": false, "err": "not a PackedScene"}
  var root := (packed as PackedScene).instantiate()
  if root == null:
    return {"ok": false, "err": "instantiate() failed"}
  var tris := 0
  var surfaces := 0
  var with_uv := 0
  var with_normal_tex := 0
  var nodes: Array[Node] = []
  if root is MeshInstance3D:
    nodes.append(root)
  for c in root.find_children("*", "MeshInstance3D", true, false):
    nodes.append(c)
  for node in nodes:
    var mi := node as MeshInstance3D
    if mi == null or mi.mesh == null:
      continue
    for s in range(mi.mesh.get_surface_count()):
      surfaces += 1
      var arrays := mi.mesh.surface_get_arrays(s)
      if arrays.size() <= Mesh.ARRAY_VERTEX:
        continue
      var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
      var count := verts.size()
      if arrays.size() > Mesh.ARRAY_INDEX:
        var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
        if idx.size() > 0:
          count = idx.size()
      tris += int(count / 3)
      if arrays.size() > Mesh.ARRAY_TEX_UV and arrays[Mesh.ARRAY_TEX_UV] != null:
        var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
        if uvs.size() > 0:
          with_uv += 1
      var mat := mi.get_active_material(s)
      if mat is StandardMaterial3D and (mat as StandardMaterial3D).normal_enabled:
        with_normal_tex += 1
  var info := {"ok": true, "triangles": tris, "surfaces": surfaces,
    "surfaces_with_uv": with_uv, "surfaces_with_normal_map": with_normal_tex,
    "meshes": nodes.size()}
  root.free()
  return info

func _initialize() -> void:
  print("=== rev208 HQ-Ecology real Godot verification ===")
  print("engine: ", Engine.get_version_info().string)

  if not FileAccess.file_exists(PROVENANCE):
    _fail("missing provenance manifest " + PROVENANCE)
    _finish()
    return
  var prov_text := FileAccess.get_file_as_string(PROVENANCE)
  var prov: Variant = JSON.parse_string(prov_text)
  if not (prov is Dictionary):
    _fail("provenance manifest is not valid JSON")
    _finish()
    return
  var manifest: Dictionary = prov

  # ---------- 1) 地表 PBR 贴图 ----------
  var texture_map_total := 0
  var texture_map_sha_ok := 0
  var flat_albedo := 0
  for tex in manifest["textures"]:
    var slug := String(tex["slug"])
    _ok(String(tex["license"]) == "CC0", "%s license is not CC0" % slug)
    var dir := "%s/%s" % [TERRAIN_DIR, slug]
    var albedo_std := -1.0
    var rough_std := -1.0
    for m in tex["maps"]:
      var p := "%s/%s" % [dir, String(m["file"])]
      texture_map_total += 1
      if not FileAccess.file_exists(p):
        _fail("missing texture file " + p)
        continue
      var got := _sha256(p)
      if got == String(m["sha256"]):
        texture_map_sha_ok += 1
      else:
        _fail("SHA256 mismatch %s got=%s want=%s" % [p, got, String(m["sha256"])])
      var st := _image_stats(p)
      _ok(bool(st.get("ok", false)), "cannot decode image " + p)
      if bool(st.get("ok", false)):
        var want: String = String(m["resolution"])
        var actual := "%dx%d" % [int(st["w"]), int(st["h"])]
        _ok(actual == want, "%s decoded %s != manifest %s" % [p, actual, want])
        _ok(int(st["w"]) <= 2048 and int(st["h"]) <= 2048,
          "%s exceeds android texture budget" % p)
        var var3 := _img_variance_rgb(p)
        var kind := String(m["kind"])
        if kind == "albedo":
          albedo_std = float(var3.get("g", 0.0))
        elif kind == "orm":
          rough_std = float(var3.get("g", 0.0))
    # 真实扫描材质必须有多样性；纯色图（stddev 近 0）不是 PBR 地表。
    _ok(albedo_std > 0.035,
      "%s albedo is flat (green stddev %.4f <= 0.035): not a real scanned material" % [slug, albedo_std])
    if albedo_std <= 0.035:
      flat_albedo += 1
    _ok(rough_std > 0.01,
      "%s ORM green channel (roughness) is constant: channel packing not real" % slug)

  _ok(texture_map_total == 24, "expected 24 macro/detail texture maps, got %d" % texture_map_total)
  _ok(texture_map_sha_ok == texture_map_total,
    "texture SHA mismatch %d/%d" % [texture_map_sha_ok, texture_map_total])

  # ---------- 2) 真实扫描地被 GLB ----------
  var model_tris := {}
  var total_model_tris := 0
  for mdl in manifest["models"]:
    var slug := String(mdl["slug"])
    _ok(String(mdl["license"]) == "CC0", "%s license is not CC0" % slug)
    var gltf_file := ""
    for f in mdl["files"]:
      var rel := String(f["file"])
      if rel.ends_with(".gltf"):
        gltf_file = rel
      var p := "%s/%s/%s" % [GROUNDCOVER_DIR, slug, rel]
      _ok(FileAccess.file_exists(p), "missing groundcover file " + p)
      if FileAccess.file_exists(p):
        _ok(_sha256(p) == String(f["sha256"]), "SHA256 mismatch " + p)
    _ok(gltf_file != "", "%s manifest has no gltf entry" % slug)
    if gltf_file == "":
      continue
    var info := _triangles_of_scene("%s/%s/%s" % [GROUNDCOVER_DIR, slug, gltf_file])
    _ok(bool(info.get("ok", false)), "%s failed to import: %s" % [slug, String(info.get("err", ""))])
    if not bool(info.get("ok", false)):
      continue
    var tris := int(info["triangles"])
    model_tris[slug] = tris
    total_model_tris += tris
    _ok(tris == int(mdl["triangle_lod0"]),
      "%s engine triangles %d != manifest %d" % [slug, tris, int(mdl["triangle_lod0"])])
    _ok(int(info["surfaces_with_uv"]) > 0, "%s has no UV0 surfaces" % slug)
    _ok(bool(mdl["all_primitives_have_uv0"]), "%s manifest says no UV0" % slug)
    print("  model %-16s tris=%-7d uv_surfaces=%d normal_mapped=%d" % [
      slug, tris, int(info["surfaces_with_uv"]), int(info["surfaces_with_normal_map"])])

  _ok(model_tris.size() == 4, "expected 4 real groundcover models, got %d" % model_tris.size())

  # ---------- 3) 两级 PBR 地面材质 ----------
  var script: GDScript = load(MODULE)
  _ok(script != null, "cannot load " + MODULE)
  if script != null:
    var mod: RefCounted = script.new()
    mod.call("initialize")
    var ground: ShaderMaterial = mod.call("build_ground_material", true)
    _ok(ground != null, "build_ground_material() returned null (texture set incomplete)")
    if ground != null:
      var shader := ground.shader
      _ok(shader != null, "ground material has no shader")
      var uniforms := shader.get_shader_uniform_list()
      var names := {}
      for u in uniforms:
        names[String(u["name"])] = true
      for required in [
          "macro_floor_albedo", "macro_floor_normal", "macro_floor_orm",
          "macro_grass_albedo", "macro_grass_normal", "macro_grass_orm",
          "macro_mud_albedo", "macro_mud_normal", "macro_mud_orm",
          "macro_rock_albedo", "macro_rock_normal", "macro_rock_orm",
          "detail_albedo", "detail_normal",
          "macro_tiles_per_metre", "detail_tiles_per_metre"]:
        _ok(names.has(required), "ground shader missing uniform " + required)
      var macro_t := float(ground.get_shader_parameter("macro_tiles_per_metre"))
      var detail_t := float(ground.get_shader_parameter("detail_tiles_per_metre"))
      # macro 2–8m / detail 2–8cm：报告要求的真实世界尺度，不是随便写的数字。
      _ok(macro_t > 1.0 / 8.0 and macro_t < 1.0 / 2.0,
        "macro tiling %.4f tiles/m outside 2-8m band" % macro_t)
      _ok(detail_t > 1.0 / 0.08 and detail_t < 1.0 / 0.02,
        "detail tiling %.2f tiles/m outside 2-8cm band" % detail_t)
      _ok(ground.get_shader_parameter("macro_floor_albedo") != null,
        "macro_floor_albedo not bound")
      _ok(ground.get_shader_parameter("detail_normal") != null,
        "detail_normal not bound")
      print("  ground material OK  macro=%.3f tiles/m detail=%.2f tiles/m" % [macro_t, detail_t])

    var bark_pine: StandardMaterial3D = mod.call("build_bark_material", "pine")
    var bark_cypress: StandardMaterial3D = mod.call("build_bark_material", "cypress")
    for pair in [["pine", bark_pine], ["cypress", bark_cypress]]:
      var kind := String(pair[0])
      var mat: StandardMaterial3D = pair[1]
      _ok(mat != null, "bark material %s is null" % kind)
      if mat != null:
        _ok(mat.albedo_texture != null, "bark %s missing albedo texture" % kind)
        _ok(mat.normal_enabled and mat.normal_texture != null,
          "bark %s missing real normal map" % kind)
        _ok(mat.roughness_texture != null, "bark %s missing roughness texture" % kind)
        _ok(mat.roughness_texture_channel == BaseMaterial3D.TEXTURE_CHANNEL_GREEN,
          "bark %s roughness must read ORM green channel" % kind)
        _ok(mat.ao_texture != null and
            mat.ao_texture_channel == BaseMaterial3D.TEXTURE_CHANNEL_RED,
          "bark %s AO must read ORM red channel" % kind)
        print("  bark %-8s albedo=%dx%d normal=%s" % [
          kind, mat.albedo_texture.get_width(), mat.albedo_texture.get_height(),
          str(mat.normal_texture != null)])

    var summary: Dictionary = mod.call("summary")
    _ok(int(summary.get("pbr_sets_loaded", 0)) >= 5,
      "loaded PBR sets %d < 5" % int(summary.get("pbr_sets_loaded", 0)))
    print("  pbr sets loaded: %d / %d" % [
      int(summary.get("pbr_sets_loaded", 0)), int(summary.get("expected_sets", 0))])


  # ---------- 4) 真实接入：vivid_material 地面委派 ----------
  var vivid_script: GDScript = load("res://canglan_rev187/vivid_material.gd")
  _ok(vivid_script != null, "cannot load staged vivid_material.gd")
  if vivid_script != null:
    var vivid: RefCounted = vivid_script.new()
    vivid.call("initialize")
    _ok(String(vivid.get("hq_ecology_status")) == "LOADED",
      "vivid_material did not load HQ ecology module (status=%s)" % String(vivid.get("hq_ecology_status")))
    var real_ground: ShaderMaterial = vivid.call("material_for_real_terrain",
      "natural_ground", Color(0.3, 0.55, 0.32), true)
    _ok(real_ground != null, "material_for_real_terrain(natural_ground) returned null")
    if real_ground != null:
      _ok(String(real_ground.resource_name).contains("HQ_TwoScale"),
        "natural_ground is NOT the HQ two-scale PBR material: " + String(real_ground.resource_name))
      _ok(real_ground.get_shader_parameter("macro_floor_albedo") != null,
        "delegated ground material has no bound albedo")
      print("  vivid delegation OK: ", real_ground.resource_name)
    # 非自然地面角色必须保持旧 Vivid 方案，不能被误替换。
    var soil: ShaderMaterial = vivid.call("material_for_real_terrain",
      "soil", Color(0.4, 0.3, 0.2), false)
    _ok(soil != null and not String(soil.resource_name).contains("HQ_TwoScale"),
      "non-ground role was wrongly replaced by HQ material")

  # ---------- 5) 真实接入：地被生成 + 树皮接管 ----------
  if script != null:
    var mod2: RefCounted = script.new()
    mod2.call("initialize")
    var avail: Dictionary = mod2.call("groundcover_availability")
    var avail_count := 0
    for k in avail:
      if bool(avail[k]):
        avail_count += 1
    _ok(avail_count == 4, "only %d/4 real scanned groundcover species are importable" % avail_count)

    var fake_world := Node3D.new()
    var fake_terrain := Node3D.new()
    var report: Dictionary = mod2.call("spawn_groundcover",
      fake_world, fake_terrain, null, 208311)
    _ok(int(report.get("spawned", 0)) > 0, "spawn_groundcover spawned nothing")
    _ok(int(report.get("spawned", 0)) == 36,
      "expected 36 real groundcover instances, got %d" % int(report.get("spawned", 0)))
    var by := report.get("by_species", {}) as Dictionary
    _ok(int(by.get("fern_clump", 0)) == 10 and int(by.get("shrub_low", 0)) == 8 and
        int(by.get("moss_patch", 0)) == 12 and int(by.get("rock_moss_set", 0)) == 6,
      "groundcover species distribution wrong: " + str(by))
    # 每一株都必须有唯一实体 ID 且真的挂进世界，不能只是数组里的数字。
    var installed: Array = report.get("installed", [])
    _ok(installed.size() == int(report.get("spawned", 0)),
      "installed list %d != spawned %d" % [installed.size(), int(report.get("spawned", 0))])
    var real_children := 0
    for c in fake_world.get_children():
      if c is Node3D and String(c.get_meta("hq_rev208_real_scanned_groundcover", "")) != "":
        real_children += 1
    _ok(real_children == int(report.get("spawned", 0)),
      "world children %d != spawned %d" % [real_children, int(report.get("spawned", 0))])
    print("  groundcover spawned=%d species=%s" % [int(report.get("spawned", 0)), str(by)])
    fake_world.free()
    fake_terrain.free()


    # 正式 OTA PCK 里放的是原始 .gltf（未导入），必须验证运行时 GLTFDocument
    # 解析路径真的能用——否则资产进包了但游戏里看不见。
    var abs_gltf := ProjectSettings.globalize_path(
      "res://canglan_rev187/hq_ecology_groundcover/fern_clump/fern_clump_1k.gltf")
    var runtime_scene: Node3D = mod2.call("_load_gltf_runtime", abs_gltf)
    _ok(runtime_scene != null, "runtime GLTFDocument parse of raw .gltf failed")
    if runtime_scene != null:
      var rt_tris := 0
      for c in runtime_scene.find_children("*", "MeshInstance3D", true, false):
        var mi2: MeshInstance3D = c as MeshInstance3D
        if mi2 == null or mi2.mesh == null:
          continue
        for s2 in range(mi2.mesh.get_surface_count()):
          var arr := mi2.mesh.surface_get_arrays(s2)
          var idx2: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
          rt_tris += int((idx2.size() if idx2.size() > 0 else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3)
      _ok(rt_tris == 6232, "runtime-packed fern triangles %d != 6232" % rt_tris)
      print("  runtime raw-gltf load OK tris=", rt_tris)
      runtime_scene.free()

    # 树皮接管：只改无贴图表面
    var tree := Node3D.new()
    var mi := MeshInstance3D.new()
    var box := BoxMesh.new()
    mi.mesh = box
    var plain := StandardMaterial3D.new()
    plain.albedo_texture = null
    mi.set_surface_override_material(0, plain)
    tree.add_child(mi)
    var hit: int = int(mod2.call("apply_bark_to_tree", tree, "pine"))
    _ok(hit == 1, "apply_bark_to_tree expected 1 surface, got %d" % hit)
    var now: Material = mi.get_active_material(0)
    _ok(now is StandardMaterial3D and (now as StandardMaterial3D).albedo_texture != null,
      "bark PBR was not actually applied to the trunk surface")
    tree.free()

  _finish(total_model_tris)

func _finish(total_model_tris: int = 0) -> void:
  print("=== checks=%d failures=%d ===" % [checks, failures.size()])
  if failures.is_empty():
    print("PASS_REV208_HQ_ECOLOGY_REAL_GODOT441_TWO_SCALE_PBR_GROUND_AND_GROUNDCOVER")
    quit(0)
  else:
    for f in failures:
      print("  FAILED: " + f)
    print("FAIL_REV208_HQ_ECOLOGY_REAL_GODOT441")
    quit(1)
