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
    quality: RefCounted,vendor_sources: Dictionary) -> bool:
  if initialized or original_world==null or terrain==null or quality==null:
    return false
  _world=original_world
  _terrain=terrain
  _quality=quality
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
  _world.add_child(self)
  for cx in range(CELL_GRID_MIN,CELL_GRID_MAX+1):
    for cz in range(CELL_GRID_MIN,CELL_GRID_MAX+1):
      for kind in SOURCE_SPECIES:
        _create_cell(cx,cz,kind,definitions[kind])
  initialized=true
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
      var x: float=clampf((float(cx)+rand.randf_range(0.04,0.96))*
        CELL_METRES,-42.25,42.25)
      var z: float=clampf((float(cz)+rand.randf_range(0.04,0.96))*
        CELL_METRES,-42.25,42.25)
      # Real overlapping river/houses, not an artificially flat carpet.
      if x>5.0 and rand.randf()<0.92:
        continue
      if not bool(_quality.call("_natural_plantable",x,z)):
        continue
      if Vector2(x-1.5,z-7.0).length()<9.0 or (
          Vector2(x-12.0,z-7.0).length()<6.0):
        continue
      if Vector2(x+7.0,z+18.0).length()<7.0 or (
          Vector2(x-4.8,z+24.0).length()<7.0) or (
          Vector2(x+5.0,z-25.0).length()<7.0):
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
    mm.visible_instance_count=slots.size()

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
    mm.visible_instance_count=slots.size()

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

func sync_visibility(player: Vector3,quality_name: String) -> void:
  var distance: float=65.0 if quality_name=="极致画质" else (
    45.0 if quality_name=="高档" else 31.0)
  for cell in cells.values():
    var center:=Vector2((float(cell["x"])+0.5)*CELL_METRES,
      (float(cell["z"])+0.5)*CELL_METRES)
    var near: bool=center.distance_to(Vector2(player.x,player.z))<=distance
    for part in cell["parts"]:
      (part["draw"] as MultiMeshInstance3D).visible=near

func stats() -> Dictionary:
  var count: int=0
  var drawing: int=0
  var checked: int=0
  var real_surfaces: int=0
  var error: Array[String]=[]
  for key in cells:
    var cell: Dictionary=cells[key]
    var active: Array=cell["active_ids"]
    count+=active.size()
    for part in cell["parts"]:
      var draw: MultiMeshInstance3D=part["draw"]
      var mm: MultiMesh=draw.multimesh
      drawing+=1
      real_surfaces+=mm.mesh.get_surface_count()
      if mm.visible_instance_count!=active.size():
        error.append("NOT_CONTIGUOUS_GPU_SLOT_COUNT_"+String(key))
      for index in range(active.size()):
        var id: String=String(active[index])
        if int(cell["slot_by_id"].get(id,-1))!=index:
          error.append("WRONG_SWAP_REMOVE_SLOT_"+id)
          continue
        var t: Transform3D=mm.get_instance_transform(index)
        var expected: Transform3D=_placement(id)*part["relative"]
        if not t.origin.is_finite() or (
            t.origin.distance_to(expected.origin)>0.035) or (
            absf(t.basis.determinant())<0.0001):
          error.append("GHOST_GPU_TRANSFORM_OR_FLOATING_SOURCE_3D_"+id)
        checked+=1
      for index in range(active.size(),int(cell["capacity"])):
        var dormant: Transform3D=mm.get_instance_transform(index)
        if dormant.origin.length()<1000.0:
          error.append("INVISIBLE_GPU_SLOT_AT_WORLD_ORIGIN_"+String(key))
  return {"actual_32m_cells":cells.size(),"active_real_cc0_plants":count,
    "gpu_real_pbr_parts":drawing,"source_mesh_surface_parts":real_surfaces,
    "verified_live_gpu_slots":checked,"rejected_sites":rejected_sites,
    "never_free_inventory":true,"source_license":LICENSE,
    "errors":error,"species":SOURCE_SPECIES.duplicate(),
    "uses_swap_remove":true,"all_visible_slots_contiguous":error.is_empty()}

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
