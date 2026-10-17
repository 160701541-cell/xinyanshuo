extends RefCounted
## REV187: explicit user removal of the deprecated EXACTLY-FIVE-SWATCHES rule.
## Unlimited natural colour variety; preserve original licensed Kenney GLB
## geometry/UVs/material texture if available, tint per real material surface
## AND per individual world entity using MultiMesh instance colour.
const SWATCHES := {
 "grass": Color("#7caf67"), "grass_dark": Color("#4f8950"),
 "grass_sun": Color("#acc977"), "grass_yellow": Color("#b9be69"),
 "grass_shadow": Color("#3b7350"),
 "leaf": Color("#499452"), "leaf_spring": Color("#9abf52"),
 "leaf_deep": Color("#28744e"), "leaf_warm": Color("#6caa54"),
 "leaf_soft": Color("#80b56c"),
 "wood": Color("#90613e"), "wood_dark": Color("#674329"),
 "wood_light": Color("#be8b5c"), "wood_warm": Color("#a66c44"),
 "stone": Color("#92999a"), "stone_blue": Color("#698b91"),
 "stone_brown": Color("#9b9081"), "stone_light": Color("#bababa"),
 "soil": Color("#bd9166"), "clay": Color("#a16e4c"),
 "soil_sand": Color("#d0b687"), "soil_deep": Color("#805a43"),
 "wall": Color("#e6dac1"), "roof": Color("#425a65"),
 "roof_slate": Color("#596a72"), "door_paint": Color("#813f33"),
 "water": Color("#4babb6"),
 "flower_white": Color("#f6f1de"), "flower_yellow": Color("#eacb56"),
 "flower_pink": Color("#e79cb3"), "flower_purple": Color("#b0a2d7")
}
const VARIANTS := {
 "tree": [Color("#e3ffe0"),Color("#d3f4d8"),Color("#efffd5"),Color("#e1e9cc"),
          Color("#d5e7d6"),Color("#f6f6c8")],
 "stone": [Color("#f2f4f7"),Color("#d5e6ed"),Color("#e3dccc"),Color("#bbd1ce"),
           Color("#e8e0d2"),Color("#c4d1d3")],
 "timber": [Color("#f3dcc4"),Color("#e9caa8"),Color("#dbbb9b"),Color("#ffead1")],
 "fence": [Color("#e4cdac"),Color("#b8a58b"),Color("#d4baa0")],
 "steps": [Color("#dae3ed"),Color("#e7ddd1"),Color("#bdd0d1")],
 "door": [Color("#e7b99b"),Color("#f9dec1"),Color("#ba7968")]
}
var materials: Dictionary = {}

func swatch(role: String) -> Color:
  if SWATCHES.has(role):
    return SWATCHES[role]
  return SWATCHES["grass"]

func material(role: String) -> StandardMaterial3D:
  if materials.has(role):
    return materials[role]
  var mat := StandardMaterial3D.new()
  mat.resource_name = "CanglanNaturalKenney_" + role
  mat.albedo_color = swatch(role)
  mat.roughness = 0.88
  mat.metallic = 0.0
  mat.vertex_color_use_as_albedo = true
  materials[role] = mat
  return mat

func role_for_mesh(asset_role: String, mesh_path: String, source_mat: Material = null) -> String:
  if asset_role == "stone" or asset_role == "steps":
    return "stone"
  if asset_role == "fence":
    return "wood_dark"
  if asset_role == "door":
    return "wood_warm"
  if asset_role == "timber":
    return "wood"
  if asset_role != "tree":
    return "soil"
  var path: String = mesh_path.to_lower()
  if path.contains("trunk") or path.contains("bark") or path.contains("branch") or path.contains("wood"):
    return "wood_dark"
  if path.contains("leaf") or path.contains("crown") or path.contains("foliage"):
    return "leaf"
  if source_mat is BaseMaterial3D:
    var c: Color = (source_mat as BaseMaterial3D).albedo_color
    if c.r > c.g * 1.14 and c.r > c.b * 1.10:
      return "wood"
  return "leaf"

func palettize_static_mesh(source: Mesh, asset_role: String, mesh_path: String) -> Mesh:
  if source == null:
    return null
  var copy: Mesh = source.duplicate()
  for surface in range(copy.get_surface_count()):
    var original: Material = source.surface_get_material(surface)
    var role: String = role_for_mesh(asset_role,mesh_path+"/"+str(surface),original)
    # If Kenney carries a usable material texture, preserve it. Multiplying by
    # a warm natural tint never deletes the source artwork or UV information.
    var tinted: StandardMaterial3D
    if original is StandardMaterial3D:
      tinted = (original as StandardMaterial3D).duplicate()
      tinted.albedo_color = tinted.albedo_color.lerp(swatch(role),0.43)
    else:
      tinted = material(role)
    tinted.vertex_color_use_as_albedo = true
    tinted.roughness = 0.85
    copy.surface_set_material(surface,tinted)
  return copy

func instance_variant(asset_role: String, entity_name: String) -> Color:
  var colors: Array = VARIANTS.get(asset_role,[Color.WHITE])
  var seed: int = 0
  for chr in entity_name.to_utf8_buffer():
    seed = (seed * 31 + int(chr)) % 2147483647
  return colors[seed % colors.size()]

func swatch_count() -> int:
  return SWATCHES.size()

func color_count_unrestricted() -> bool:
  return SWATCHES.size() > 20
