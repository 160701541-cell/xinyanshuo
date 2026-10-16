extends RefCounted
## rev183 - Approved Kenney low-poly style. EXACTLY FIVE dominant material roles.
## Reuse licensed source geometry/textures: this is not a 3D asset generator.
const SWATCHES := {
  "grass": Color("#86a17b"), # sage
  "soil": Color("#b6a488"),  # warm path
  "leaf": Color("#58978d"),  # blue-green forest
  "wood": Color("#9a704e"),  # timber, worker routes
  "stone": Color("#8a8c9a")  # cool grey rocks
}
var materials: Dictionary = {}

func swatch(role: String) -> Color:
  assert(SWATCHES.has(role))
  return SWATCHES[role]

func material(role: String) -> StandardMaterial3D:
  assert(SWATCHES.has(role))
  if materials.has(role):
    return materials[role]
  var mat := StandardMaterial3D.new()
  mat.resource_name = "KenneyFiveSwatches_" + role
  mat.albedo_color = SWATCHES[role]
  mat.roughness = 1.0
  mat.metallic = 0.0
  materials[role] = mat
  return mat

func role_for_mesh(asset_role: String, mesh_path: String, source_mat: Material = null) -> String:
  if asset_role == "stone" or asset_role == "steps":
    return "stone"
  if asset_role in ["timber", "fence", "door"]:
    return "wood"
  if asset_role != "tree":
    return "soil"
  var n: String = mesh_path.to_lower()
  if n.contains("trunk") or n.contains("bark") or n.contains("branch") or n.contains("wood"):
    return "wood"
  if n.contains("leaf") or n.contains("crown") or n.contains("foliage"):
    return "leaf"
  # Kenney GLBs frequently separate trunk/crown as two surfaces. Classify
  # their source swatch by source material instead of coloring all trees green.
  if source_mat is BaseMaterial3D:
    var m := source_mat as BaseMaterial3D
    var c: Color = m.albedo_color
    if c.r > c.g * 1.18 and c.r > c.b * 1.12:
      return "wood"
  return "leaf"

func palettize_static_mesh(source: Mesh, asset_role: String, mesh_path: String) -> Mesh:
  if source == null:
    return null
  # Preserve the authentic Kenney low-poly topology. Only replace surface
  # material pointers. Duplicate the resource so original assets stay intact.
  var copy: Mesh = source.duplicate()
  for surface in range(copy.get_surface_count()):
    var original: Material = source.surface_get_material(surface)
    var role: String = role_for_mesh(asset_role, mesh_path + "/" + str(surface), original)
    copy.surface_set_material(surface, material(role))
  return copy

func swatch_count() -> int:
  return SWATCHES.size()
