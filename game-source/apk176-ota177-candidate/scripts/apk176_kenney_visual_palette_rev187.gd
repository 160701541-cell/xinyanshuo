extends RefCounted
## REV187: explicit user removal of the deprecated EXACTLY-FIVE-SWATCHES rule.
## Unlimited natural colour variety; preserve original licensed Kenney GLB
## geometry/UVs/material texture if available, tint per real material surface
## AND per individual world entity using MultiMesh instance colour.
# Rev207 genuine deep chroma palette. Source GLB UV/PBR texture survives;
# no global five-color posterization and no chalky white multiplying trees.
const SWATCHES := {
 "grass":Color("#347544"),"grass_dark":Color("#275f38"),
 "grass_deep":Color("#184f31"),"grass_light":Color("#67a445"),
 "grass_sun":Color("#7bb24c"),"grass_yellow":Color("#8ca23e"),
 "grass_shadow":Color("#204f3d"),
 "leaf":Color("#338648"),"leaf_spring":Color("#75b743"),
 "leaf_deep":Color("#176538"),"leaf_warm":Color("#559737"),
 "leaf_soft":Color("#5ca351"),
 "wood":Color("#89552d"),"wood_dark":Color("#59351f"),
 "wood_light":Color("#b57a3b"),"wood_warm":Color("#9f5834"),
 "stone":Color("#626e74"),"stone_blue":Color("#4d6876"),
 "stone_brown":Color("#746956"),"stone_light":Color("#abb2ac"),
 "soil":Color("#9d673f"),"clay":Color("#8b4f35"),
 "soil_sand":Color("#be9858"),"soil_deep":Color("#553b2a"),
 "wall":Color("#e0d0ab"),"roof":Color("#344e63"),
 "roof_slate":Color("#48606d"),"door_paint":Color("#8c3528"),
 "water":Color("#207fac"),
 "flower_white":Color("#f4ebce"),"flower_yellow":Color("#e8ad24"),
 "flower_pink":Color("#ee658c"),"flower_purple":Color("#986ace")
}
const VARIANTS := {
 "tree":[Color("#b6e6b4"),Color("#a8dba9"),Color("#a3e8ae"),
         Color("#c4ef9e"),Color("#b9e3bf"),Color("#c5e3a6")],
 "stone":[Color("#b5c6ce"),Color("#b1c4ce"),Color("#c3bcac"),
          Color("#849aa4"),Color("#a8b5c1"),Color("#98aaa8")],
 "timber":[Color("#dfad7e"),Color("#c58a5d"),Color("#aa7654"),
           Color("#e0a269")],
 "fence":[Color("#d2a076"),Color("#b38966"),Color("#a7784a")],
 "steps":[Color("#c8d3d2"),Color("#b6bfc9"),Color("#93a4ad")],
 "door":[Color("#d29370"),Color("#cd825b"),Color("#a65642")]
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
  mat.roughness = 0.92
  mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS_ANISOTROPIC
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
      # Only 22% art-direction tint. Do not bleach/erase real glTF UV or
      # source albedo textures; rich local material owns most of its color.
      var source_tint: Color=tinted.albedo_color
      if source_tint.s>0.07:
        source_tint=Color.from_hsv(source_tint.h,
          clampf(source_tint.s*1.30,0.0,1.0),
          clampf(source_tint.v*0.95,0.0,1.0),source_tint.a)
      tinted.albedo_color=source_tint.lerp(swatch(role),0.22)
      tinted.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS_ANISOTROPIC
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
