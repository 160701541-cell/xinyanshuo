extends Node3D
## rev186. One MultiMeshInstance3D per source GLB mesh part (not per object).
## Works with real licensed multi-surface Kenney assets; one part may have
## multiple surfaces and thus >1 draw. Never claim one draw for the whole GLB.
const MAX_CAPACITY := {
  "tree": 40, # 12 originals + <=24 seed descendants + small reserve
  "stone": 12,
  "timber": 24,
  "fence": 12,
  "steps": 18,
  "door": 4
}
var invisible_transform: Transform3D = Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO), Vector3.ZERO)
var group_parts: Dictionary = {}
var proxies: Dictionary = {}
var capacity_used: Dictionary = {}
var geometry_batch_count: int = 0
var source_mesh_parts: int = 0
var original_individual_meshes_avoided: int = 0
var geometry_draw_surfaces: int = 0
var rejected: Array[String] = []

func initialize(source_by_role: Dictionary, palette: RefCounted) -> bool:
  for role in MAX_CAPACITY:
    if not source_by_role.has(role):
      rejected.append("BATCH_SOURCE_ABSENT_" + role)
      continue
    var template: Node3D = source_by_role[role]
    var parts: Array[Node] = template.find_children("*", "MeshInstance3D", true, false)
    if parts.is_empty():
      rejected.append("BATCH_NO_REAL_KENNEY_MESH_" + role)
      continue
    var entries: Array = []
    for node in parts:
      var part: MeshInstance3D = node as MeshInstance3D
      if part.mesh == null:
        continue
      # GLTF templates are detached from the SceneTree; querying
      # global_transform or get_path() here triggers engine errors.
      # Compose local hierarchy transforms directly, up to this GLB root.
      var local: Transform3D = Transform3D.IDENTITY
      var cursor: Node3D = part
      while cursor != null and cursor != template:
        local = cursor.transform * local
        cursor = cursor.get_parent() as Node3D
      var multimesh := MultiMesh.new()
      multimesh.transform_format = MultiMesh.TRANSFORM_3D
      multimesh.mesh = palette.call("palettize_static_mesh", part.mesh, role, String(part.name))
      # Allocate exactly once. Each instance can be hidden using a zero
      # transform, without reallocation or making another draw call.
      multimesh.instance_count = int(MAX_CAPACITY[role])
      for n in range(multimesh.instance_count):
        multimesh.set_instance_transform(n, invisible_transform)
      var draw := MultiMeshInstance3D.new()
      draw.name = "ActualKenneyBatch_" + role + "_" + str(entries.size())
      draw.multimesh = multimesh
      draw.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
      draw.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
      add_child(draw)
      entries.append({"node":draw,"multi":multimesh,"local":local})
      geometry_batch_count += 1
      source_mesh_parts += 1
      geometry_draw_surfaces += part.mesh.get_surface_count()
    if entries.is_empty():
      rejected.append("BATCH_NO_VALID_MESH_" + role)
      continue
    group_parts[role] = entries
    capacity_used[role] = 0
    proxies[role] = []
  return rejected.is_empty()

func register(role: String, object_name: String, position: Vector3, model_scale: float) -> Node3D:
  if not group_parts.has(role):
    rejected.append("BATCH_ROLE_NOT_CONFIGURED_" + role)
    return null
  var slot: int = int(capacity_used[role])
  if slot >= int(MAX_CAPACITY[role]):
    rejected.append("BATCH_CAPACITY_EXHAUSTED_" + role)
    return null
  var proxy := Node3D.new()
  proxy.name = object_name
  proxy.position = position
  proxy.scale = Vector3.ONE * model_scale
  proxy.set_meta("batched_kenney_real_geometry", true)
  proxy.set_meta("kenney_batch_role", role)
  proxy.set_meta("kenney_batch_slot", slot)
  get_parent().add_child(proxy)
  (proxies[role] as Array).append(proxy)
  capacity_used[role] = slot + 1
  # Existing ecology sees the same node.visible and node.scale semantics.
  # Renderer transforms are synchronized from them instead of cloning meshes.
  sync_role(role)
  return proxy

func sync_role(role: String) -> void:
  if not group_parts.has(role):
    return
  var items: Array = proxies[role]
  for part in group_parts[role]:
    var instance: MultiMesh = part["multi"]
    var local_transform: Transform3D = part["local"]
    for index in range(items.size()):
      var proxy: Node3D = items[index]
      var world_transform: Transform3D = invisible_transform
      if is_instance_valid(proxy) and proxy.visible:
        world_transform = proxy.transform * local_transform
      instance.set_instance_transform(index, world_transform)

func sync_all() -> void:
  for role in group_parts:
    sync_role(role)

func stats() -> Dictionary:
  var live := 0
  for role in capacity_used:
    live += int(capacity_used[role])
  return {"source_mesh_parts":source_mesh_parts,
    "multimesh_draw_nodes":geometry_batch_count,
    "mesh_surface_draw_floor":geometry_draw_surfaces,
    "single_mesh_nodes_replaced":live*maxi(1,source_mesh_parts),
    "batched_world_objects":live,
    "role_capacity_used":capacity_used.duplicate(true),
    "batch_errors":rejected.duplicate()}
