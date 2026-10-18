extends Node3D
## REV208 HQ-021: original vendor CC0 GLB geometry, UVs and PBR untouched.
## Near-ground forest cover batched by true 32m habitat cell + species + mesh.
## Physical plant IDs are cosmetic ONLY: zero inventory/material creation.
## Swap-remove keeps active GPU slots contiguous; invisible stale transforms
## are moved outside the world so they never become (0,0,0) ghost meshes.
const CELL_METRES: float=32.0
const CELL_GRID_MIN: int=-2
const CELL_GRID_MAX: int=1
const SOURCE_SPECIES: Array[String]=["fern","grass"]
const PER_CELL: Dictionary={"fern":10,"grass":7}
const LICENSE: String="CC0-Innerscene-exact-source-page"
const NO_SLOT: Transform3D=Transform3D(Basis.IDENTITY,Vector3(9999.0,-9999.0,9999.0))
var _world: Node3D
var _terrain: Node3D
var _quality: RefCounted
var cells: Dictionary={}
var position_by_id: Dictionary={}
var species_by_id: Dictionary={}
var source_faces_per_instance: Dictionary={}
var rejected_sites: int=0
var initialized: bool=false
var _missing_source: Array[String]=[]
var protected_world_sites: Array[Dictionary]=[]
var real_source_templates: Dictionary={}
var physical_fallback_visuals: Dictionary={}
var gpu_matrix_unsupported: bool=false
var last_camera_player: Vector3=Vector3.ZERO
var last_quality: String="高档"
var fallback_gpu_probe_result: String=""

func _local_from_source(original: Node3D,child: Node3D) -> Transform3D:
  var result:=Transform3D.IDENTITY
  var cursor: Node=child
  while cursor!=original:
    if not cursor is Node3D or cursor.get_parent()==null:
      return Transform3D.IDENTITY
    result=(cursor as Node3D).transform*result
    cursor=cursor.get_parent()
  return result

func _source_parts(original: Node3D) -> Array[Dictionary]:
  var parts: Array[Dictionary]=[]
  var meshes: Array[Node]=original.find_children("*","MeshInstance3D",true,false)
  if original is MeshInstance3D:
    meshes.append(original)
  for node in meshes:
    var part: MeshInstance3D=node as MeshInstance3D
    if part==null or part.mesh==null:
      continue
    var real_surfaces: int=part.mesh.get_surface_count()
    if real_surfaces<1:
      continue
    parts.append({"mesh":part.mesh,
      "relative":_local_from_source(original,part),
      "surfaces":real_surfaces})
  return parts

func _low_y(source_parts: Array[Dictionary]) -> float:
  var bottom: float=INF
  for part in source_parts:
    var mesh: Mesh=part["mesh"]
    var box: AABB=mesh.get_aabb()
    var relative: Transform3D=part["relative"]
    for corner in range(8):
      bottom=minf(bottom,(relative*box.get_endpoint(corner)).y)
  return bottom

func initialize(original_world: Node3D,terrain: Node3D,
    quality: RefCounted,vendor_sources: Dictionary,
    blueprint_sites: Dictionary,spirit_visuals: Dictionary) -> bool:
  if initialized or original_world==null or terrain==null or quality==null:
    return false
  _world=original_world
  _terrain=terrain
  _quality=quality
  for house in blueprint_sites.values():
    var house_pos: Vector3=house["at"]
    protected_world_sites.append({"center":Vector2(house_pos.x,house_pos.z),
      "radius":7.2})
  for wild in spirit_visuals.values():
    var herb_actor: Node3D=wild["model"]
    if is_instance_valid(herb_actor):
      protected_world_sites.append({
        "center":Vector2(herb_actor.position.x,herb_actor.position.z),
        "radius":1.7})
  name="REV208PhysicalCC0FernGrass32mLivingHabitatCells"
  set_meta("source_license",LICENSE)
  set_meta("never_free_inventory",true)
  var definitions: Dictionary={}
  for kind in SOURCE_SPECIES:
    if not vendor_sources.has(kind):
      _missing_source.append(kind)
      return false
    var original: Node3D=vendor_sources[kind]
    var real_parts: Array[Dictionary]=_source_parts(original)
    if real_parts.is_empty():
      _missing_source.append(kind+"_EMPTY_REAL_GLTF")
      return false
    source_faces_per_instance[kind]=0
    for part in real_parts:
      source_faces_per_instance[kind]+=int(part["surfaces"])
    definitions[kind]={"parts":real_parts,"ground_offset":_low_y(real_parts)}
    real_source_templates[kind]=original
  _world.add_child(self)
  for cx in range(CELL_GRID_MIN,CELL_GRID_MAX+1):
    for cz in range(CELL_GRID_MIN,CELL_GRID_MAX+1):
      for kind in SOURCE_SPECIES:
        _create_cell(cx,cz,kind,definitions[kind])
  initialized=true
  # Godot4.4.1 original APK176 QA 39080924183 / 39081138496:
  # imported glTF MultiMesh readback was IDENTITY for all physical slots,
  # including hidden slots. Never show phantom plants at world (0,0,0).
  gpu_matrix_unsupported=not _gpu_transform_probe()
  if gpu_matrix_unsupported:
    fallback_gpu_probe_result="BLOCKED_IMPORTED_GLTF_MULTIMESH_IDENTITY_REAL_GODOT_441"
    for habitat in cells.values():
      for part in habitat["parts"]:
        var batch: MultiMeshInstance3D=part["draw"]
        batch.visible=false
        batch.multimesh.visible_instance_count=0
    set_meta("hq021_gpu_source_transform_status",fallback_gpu_probe_result)
    print("REV208_HQ021_GPU_SOURCE_TRANSFORM_BLOCKED_CPU_REAL_GLTF_VISUAL_FALLBACK")
  return true

func _create_cell(cx: int,cz: int,kind: String,definition: Dictionary) -> void:
  var key: String="%d_%d_%s" % [cx,cz,kind]
  var capacity: int=int(PER_CELL[kind])
  var habitat: Dictionary={"x":cx,"z":cz,"kind":kind,
    "capacity":capacity,"active_ids":[],"slot_by_id":{},
    "original_candidates":[],"parts":[]}
  var source_parts: Array[Dictionary]=definition["parts"]
  for part in source_parts:
    var batch:=MultiMeshInstance3D.new()
    batch.name="REV208_ActualVendor3D_32m_"+key
    var mm:=MultiMesh.new()
    mm.transform_format=MultiMesh.TRANSFORM_3D
    mm.mesh=part["mesh"]
    mm.instance_count=capacity
    mm.visible_instance_count=0
    # Real world XZ transforms are used because batch parent is the world.
    # Keep bounds to the actual cell to avoid one giant forest-wide draw.
    mm.custom_aabb=AABB(Vector3(cx*CELL_METRES-3.0,-7.0,
      cz*CELL_METRES-3.0),Vector3(39.0,38.0,39.0))
    for slot in range(capacity):
      mm.set_instance_transform(slot,NO_SLOT)
    batch.multimesh=mm
    batch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    batch.set_meta("real_cc0_source",kind)
    batch.set_meta("cell_key",key)
    batch.set_meta("source_license",LICENSE)
    batch.set_meta("never_free_inventory",true)
    add_child(batch)
    habitat["parts"].append({"draw":batch,"relative":part["relative"]})
  cells[key]=habitat
  var rand:=RandomNumberGenerator.new()
  rand.seed=208311+((cx+4)*12767)+((cz+4)*6913)+(
    431 if kind=="fern" else 907)
  for index in range(capacity):
    var attempt: int=0
    var accepted: bool=false
    while attempt<28:
      attempt+=1
      # Never clamp off-world candidates onto an 84m hard boundary:
      # that previously created a wall of identical overlapping plants.
      var x: float=(float(cx)+rand.randf_range(0.04,0.96))*CELL_METRES
      var z: float=(float(cz)+rand.randf_range(0.04,0.96))*CELL_METRES
      if absf(x)>42.25 or absf(z)>42.25:
        continue
      # Real overlapping river/houses, not an artificially flat carpet.
      if x>5.0 and rand.randf()<0.92:
        continue
      if not bool(_quality.call("_natural_plantable",x,z)):
        continue
      if Vector2(x-1.5,z-7.0).length()<9.0 or (
          Vector2(x-12.0,z-7.0).length()<6.0):
        continue
      var protected: bool=false
      for site in protected_world_sites:
        if Vector2(x,z).distance_to(site["center"])<float(site["radius"]):
          protected=true
          break
      if protected:
        continue
      accepted=true
      var index_id: String="CL-REV208-FLOOR-%s-%d-%d-%02d" % [
        kind,cx,cz,index]
      var yaw: float=rand.randf_range(-PI,PI)
      var scale: float=rand.randf_range(0.68,0.96) if kind=="fern" else (
        rand.randf_range(0.46,0.78))
      var pos:=Vector3(x,0.0,z)
      position_by_id[index_id]={"xz":pos,"rotation":yaw,
        "scale":scale,"origin_min_y":float(definition["ground_offset"]),
        "cell":key}
      species_by_id[index_id]=kind
      habitat["original_candidates"].append(index_id)
      _add_slot(habitat,index_id)
      break
    if not accepted:
      rejected_sites+=1
  cells[key]=habitat

func _placement(id: String) -> Transform3D:
  var spec: Dictionary=position_by_id[id]
  var pos: Vector3=spec["xz"]
  var scale: float=float(spec["scale"])
  var height: float=float(_terrain.call("height_at",pos.x,pos.z))
  var floor_y: float=float(spec["origin_min_y"])
  var transform:=Transform3D(
    Basis(Vector3.UP,float(spec["rotation"])).scaled(Vector3.ONE*scale),
    Vector3(pos.x,height-floor_y*scale+0.014,pos.z))
  return transform

func _write_slot(cell: Dictionary,id: String,slot: int) -> void:
  var root_transform: Transform3D=_placement(id)
  for part in cell["parts"]:
    var batch: MultiMeshInstance3D=part["draw"]
    var mm: MultiMesh=batch.multimesh
    var original_mesh_offset: Transform3D=part["relative"]
    mm.set_instance_transform(slot,root_transform*original_mesh_offset)

func _add_slot(cell: Dictionary,id: String) -> void:
  var slots: Array=cell["active_ids"]
  if cell["slot_by_id"].has(id) or slots.size()>=int(cell["capacity"]):
    return
  var slot: int=slots.size()
  slots.append(id)
  cell["slot_by_id"][id]=slot
  _write_slot(cell,id,slot)
  for part in cell["parts"]:
    var mm: MultiMesh=(part["draw"] as MultiMeshInstance3D).multimesh
    mm.visible_instance_count=0 if gpu_matrix_unsupported else slots.size()

func _remove_slot(cell: Dictionary,id: String) -> void:
  if not cell["slot_by_id"].has(id):
    return
  var slots: Array=cell["active_ids"]
  var slot: int=int(cell["slot_by_id"][id])
  var last_slot: int=slots.size()-1
  if slot!=last_slot:
    var moved: String=String(slots[last_slot])
    slots[slot]=moved
    cell["slot_by_id"][moved]=slot
    _write_slot(cell,moved,slot)
  slots.remove_at(last_slot)
  cell["slot_by_id"].erase(id)
  for part in cell["parts"]:
    var mm: MultiMesh=(part["draw"] as MultiMeshInstance3D).multimesh
    mm.set_instance_transform(last_slot,NO_SLOT)
    mm.visible_instance_count=0 if gpu_matrix_unsupported else slots.size()

func on_terrain_changed(at: Vector3,radius: float) -> void:
  if not initialized:
    return
  for cell in cells.values():
    for id in cell["original_candidates"]:
      var pos: Vector3=position_by_id[id]["xz"]
      if Vector2(pos.x-at.x,pos.z-at.z).length()>radius+2.0:
        continue
      if bool(_quality.call("_natural_plantable",pos.x,pos.z)):
        if cell["slot_by_id"].has(id):
          _write_slot(cell,id,int(cell["slot_by_id"][id]))
        else:
          _add_slot(cell,id)
      else:
        _remove_slot(cell,id)
  if gpu_matrix_unsupported:
    _sync_fallback_physical_glbs(last_camera_player,last_quality)

func sync_visibility(player: Vector3,quality_name: String) -> void:
  last_camera_player=player
  last_quality=quality_name
  if gpu_matrix_unsupported:
    _sync_fallback_physical_glbs(player,quality_name)
    return
  var distance: float=65.0 if quality_name=="极致画质" else (
    45.0 if quality_name=="高档" else 31.0)
  for cell in cells.values():
    var center:=Vector2((float(cell["x"])+0.5)*CELL_METRES,
      (float(cell["z"])+0.5)*CELL_METRES)
    var near: bool=center.distance_to(Vector2(player.x,player.z))<=distance
    for part in cell["parts"]:
      (part["draw"] as MultiMeshInstance3D).visible=near

func _gpu_transform_probe() -> bool:
  var samples: int=0
  for cell in cells.values():
    if (cell["active_ids"] as Array).is_empty():
      continue
    var first: String=String(cell["active_ids"][0])
    var expect: Transform3D=_placement(first)
    for part in cell["parts"]:
      var batch: MultiMeshInstance3D=part["draw"]
      var actual: Transform3D=batch.multimesh.get_instance_transform(0)
      var wanted: Transform3D=expect*part["relative"]
      if not actual.origin.is_finite() or (
          actual.origin.distance_to(wanted.origin)>0.035) or (
          absf(actual.basis.determinant())<0.0001):
        return false
      samples+=1
      if samples>=4:
        return true
  return samples>=2

func _sync_fallback_physical_glbs(player: Vector3,quality_name: String) -> void:
  # Fallback is genuinely authored source GLB PBR with exact physical
  # world transform. Never render the invalid MultiMesh IDENTITY buffer.
  # Source models are imported once and shared as duplicated Mesh resources.
  var view_radius: float=56.0 if quality_name=="极致画质" else (
    38.0 if quality_name=="高档" else 25.0)
  var cap: int=72 if quality_name=="极致画质" else (
    42 if quality_name=="高档" else 23)
  var candidates: Array[Dictionary]=[]
  for cell in cells.values():
    for id in cell["active_ids"]:
      var spec: Dictionary=position_by_id[id]
      var p: Vector3=spec["xz"]
      var distance: float=Vector2(p.x-player.x,p.z-player.z).length()
      if distance<=view_radius:
        candidates.append({"id":String(id),"distance":distance})
  candidates.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
    return float(a["distance"])<float(b["distance"]))
  var chosen: Dictionary={}
  for i in range(mini(cap,candidates.size())):
    var id: String=candidates[i]["id"]
    chosen[id]=true
    var transform: Transform3D=_placement(id)
    if physical_fallback_visuals.has(id) and is_instance_valid(
        physical_fallback_visuals[id]):
      (physical_fallback_visuals[id] as Node3D).transform=transform
      continue
    var kind: String=String(species_by_id[id])
    if not real_source_templates.has(kind):
      continue
    var actor: Node3D=(real_source_templates[kind] as Node3D).duplicate()
    actor.name=id
    actor.set_meta("source_license",LICENSE)
    actor.set_meta("true_vendor_glb_3d_cell",String(position_by_id[id]["cell"]))
    actor.set_meta("never_free_inventory",true)
    actor.transform=transform
    add_child(actor)
    physical_fallback_visuals[id]=actor
  for id in physical_fallback_visuals.keys():
    if chosen.has(id):
      continue
    var unused: Node3D=physical_fallback_visuals[id]
    if is_instance_valid(unused):
      unused.queue_free()
    physical_fallback_visuals.erase(id)

func stats() -> Dictionary:
  var count: int=0
  var drawing: int=0
  var checked: int=0
  var real_surfaces: int=0
  var errors: Array[String]=[]
  for key in cells:
    var cell: Dictionary=cells[key]
    var active: Array=cell["active_ids"]
    count+=active.size()
    for part in cell["parts"]:
      var draw: MultiMeshInstance3D=part["draw"]
      var mm: MultiMesh=draw.multimesh
      drawing+=1
      real_surfaces+=mm.mesh.get_surface_count()
      if gpu_matrix_unsupported:
        # Fail closed: unsupported source Mesh->MultiMesh transforms may
        # remain allocated but MUST NEVER DRAW at (0,0,0), even transiently.
        if draw.visible or mm.visible_instance_count!=0:
          errors.append("BROKEN_GLTF_GPU_BUFFER_WAS_RENDERED_"+String(key))
        continue
      if mm.visible_instance_count!=active.size():
        errors.append("NOT_CONTIGUOUS_GPU_SLOT_COUNT_"+String(key))
      for index in range(active.size()):
        var id: String=String(active[index])
        if int(cell["slot_by_id"].get(id,-1))!=index:
          errors.append("WRONG_SWAP_REMOVE_SLOT_"+id)
          continue
        var t: Transform3D=mm.get_instance_transform(index)
        var expected: Transform3D=_placement(id)*part["relative"]
        if not t.origin.is_finite() or (
            t.origin.distance_to(expected.origin)>0.035) or (
            absf(t.basis.determinant())<0.0001):
          errors.append("GHOST_GPU_TRANSFORM_OR_FLOATING_SOURCE_3D_"+id)
        checked+=1
      for index in range(active.size(),int(cell["capacity"])):
        var dormant: Transform3D=mm.get_instance_transform(index)
        if dormant.origin.length()<1000.0:
          errors.append("INVISIBLE_GPU_SLOT_AT_WORLD_ORIGIN_"+String(key))
  var genuine_fallback_mesh_count: int=0
  if gpu_matrix_unsupported:
    for id in physical_fallback_visuals:
      var actor: Node3D=physical_fallback_visuals[id]
      if not is_instance_valid(actor) or not actor.is_inside_tree() or (
          actor.get_parent()!=self) or (
          String(actor.get_meta("source_license",""))!=LICENSE) or (
          String(actor.get_meta("true_vendor_glb_3d_cell",""))!=String(
            position_by_id[id]["cell"])) or (
          actor.position.distance_to(_placement(id).origin)>0.035) or (
          actor.find_children("*","MeshInstance3D",true,false).is_empty()):
        errors.append("FALLBACK_AUTHOR_REAL_PBR_MESH_NOT_PHYSICALLY_PLANTED_"+String(id))
        continue
      genuine_fallback_mesh_count+=1
  return {"actual_32m_cells":cells.size(),"active_real_cc0_plants":count,
    "gpu_real_pbr_parts":drawing,"source_mesh_surface_parts":real_surfaces,
    "verified_live_gpu_slots":checked,"rejected_sites":rejected_sites,
    "never_free_inventory":true,"source_license":LICENSE,
    "protected_site_count":protected_world_sites.size(),
    "errors":errors,"species":SOURCE_SPECIES.duplicate(),
    "uses_swap_remove":true,"all_visible_slots_contiguous":errors.is_empty(),
    "gpu_matrix_unsupported":gpu_matrix_unsupported,
    "gpu_matrix_issue":fallback_gpu_probe_result,
    "actual_glb_pbr_fallback_nodes":genuine_fallback_mesh_count,
    "visually_draws_fake_gpu_instances":false if gpu_matrix_unsupported else null,
    "pending_actual_android_30min_qa":true}

func verify_swap_remove(actual_id: String) -> bool:
  # Test only: caller must restore identical ecological cover after audit.
  if not position_by_id.has(actual_id):
    return false
  var cell: Dictionary=cells[String(position_by_id[actual_id]["cell"])]
  if not cell["slot_by_id"].has(actual_id):
    return false
  var old_size: int=cell["active_ids"].size()
  _remove_slot(cell,actual_id)
  var removed: bool=not cell["slot_by_id"].has(actual_id) and (
    cell["active_ids"].size()==old_size-1)
  _add_slot(cell,actual_id)
  return removed and cell["active_ids"].size()==old_size and (
    not cell["slot_by_id"].is_empty())
