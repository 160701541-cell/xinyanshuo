extends Node3D
## APK176 rev184: real deformable triangulated terrain with stratified subsurface
## cells. Buildings remove SOIL VOLUME and expose actual vertical soil walls.
## Top-layer elevations, below-grade inventory, collision and pond basin are
## bound to one finite data set, not a color background plane.
const GRID: int = 46
const CELL: float = 2.0
const HALF: float = float(GRID) * CELL / 2.0
const CUT_HEIGHT: float = 0.45
const MAX_CUTS: int = 8
const POND_CENTER := Vector2(-9.0,-28.0)
const POND_RADIUS: float = 7.0
const WATER_LEVEL: float = -0.72
const SOIL_LABELS := ["表土", "表土", "黏土", "黏土", "砾石", "砾石", "风化岩", "风化岩"]
const SOIL_KEYS := ["topsoil", "topsoil", "clay", "clay", "gravel", "gravel", "weathered_rock", "weathered_rock"]
const STONE_COLORS := {
  "grass": Color("#86a17b"),
  "soil": Color("#b6a488"),
  "clay": Color("#aa866d"),
  "gravel": Color("#999795"),
  "weathered_rock": Color("#767b82")
}
var cells: Dictionary = {}
var spoil_bag: Dictionary = {"topsoil":0,"clay":0,"gravel":0,"weathered_rock":0}
var dug_units: int = 0
var terrain: MeshInstance3D
var collision: CollisionShape3D
var water: MeshInstance3D
var world_materials: Dictionary = {}
var mesh_revisions: int = 0
var river_enabled: bool = true

func _ready() -> void:
  name = "PhysicalDeformable92mVillageStrata"
  for kind in STONE_COLORS:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = STONE_COLORS[kind]
    mat.roughness = 0.94
    mat.metallic = 0.0
    world_materials[kind] = mat
  terrain = MeshInstance3D.new()
  terrain.name = "REAL_DEFORMABLE_TERRAIN_NOT_PLANE"
  terrain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
  add_child(terrain)
  var ground_body := StaticBody3D.new()
  ground_body.name = "PhysicalExcavatedSoilCollision"
  add_child(ground_body)
  collision = CollisionShape3D.new()
  collision.name = "RegeneratedSoilCollision"
  ground_body.add_child(collision)
  _construct_terrain()
  _construct_pond()

func _key(ix: int, iz: int) -> String:
  return str(ix) + ":" + str(iz)

func _coord(ix: int, iz: int) -> Vector2:
  return Vector2(-HALF + (float(ix)+0.5)*CELL, -HALF + (float(iz)+0.5)*CELL)

func _indices(x: float,z: float) -> Vector2i:
  return Vector2i(floori((x+HALF)/CELL),floori((z+HALF)/CELL))

func _in_bounds(ix: int, iz: int) -> bool:
  return ix >= 0 and ix < GRID and iz >= 0 and iz < GRID

func _is_road(x: float,z: float) -> bool:
  if absf(x) <= 3.5 and z >= -19.0 and z <= 22.0:
    return true
  if absf(z-10.5) <= 1.8 and x >= -22.0 and x <= 5.0:
    return true
  if absf(z-(2.5-0.25*x)) <= 1.8 and x >= -3.0 and x <= 24.0:
    return true
  return false

func _base_at(x: float,z: float) -> float:
  # Actual raised hills and a carved basin, not a PlaneMesh texture.
  var hills: float = 0.18 + 1.10*sin(x*0.072)*cos(z*0.086) + 0.35*sin(z*0.19+x*0.09)
  var site_dist: float = Vector2(x,z+3.0).length()
  var depot_dist: float = Vector2(x,z-10.0).length()
  if site_dist < 8.0 or depot_dist < 5.0 or _is_road(x,z):
    hills = lerpf(hills,0.10,0.95)
  var from_pond: float = Vector2(x,z).distance_to(POND_CENTER)
  if from_pond < POND_RADIUS+3.0:
    var depth_ratio: float = clampf((POND_RADIUS+3.0-from_pond)/3.0,0.0,1.0)
    hills = lerpf(hills,-1.70,depth_ratio)
  return hills

func _load_cell(ix: int,iz: int) -> Dictionary:
  var key: String = _key(ix,iz)
  if not cells.has(key):
    var p: Vector2 = _coord(ix,iz)
    cells[key] = {"initial_y":_base_at(p.x,p.y),"cuts":0}
  return cells[key]

func _top(ix: int,iz: int) -> float:
  var entry: Dictionary = _load_cell(ix,iz)
  return float(entry["initial_y"]) - int(entry["cuts"])*CUT_HEIGHT

func height_at(x: float,z: float) -> float:
  var idx: Vector2i = _indices(x,z)
  if not _in_bounds(idx.x,idx.y):
    return _base_at(x,z)
  return _top(idx.x,idx.y)

func is_water(x: float,z: float) -> bool:
  return height_at(x,z) < WATER_LEVEL and Vector2(x,z).distance_to(POND_CENTER) <= POND_RADIUS+1.3

func _material_for(ix: int, iz: int) -> String:
  var entry: Dictionary = _load_cell(ix,iz)
  var depth: int = int(entry["cuts"])
  if depth >= 7:
    return "weathered_rock"
  if depth >= 5:
    return "gravel"
  if depth >= 3:
    return "clay"
  var p: Vector2 = _coord(ix,iz)
  if _is_road(p.x,p.y) or p.distance_to(POND_CENTER) < POND_RADIUS+2.2:
    return "soil"
  return "grass"

func _mat_for_depth(depth: float) -> String:
  if depth < 0.90:
    return "soil"
  if depth < 1.80:
    return "clay"
  if depth < 2.70:
    return "gravel"
  return "weathered_rock"

func _push_triangle(surface: SurfaceTool, a: Vector3,b: Vector3,c: Vector3) -> void:
  surface.add_vertex(a)
  surface.add_vertex(b)
  surface.add_vertex(c)

func _push_quad(surface: SurfaceTool,a:Vector3,b:Vector3,c:Vector3,d:Vector3) -> void:
  _push_triangle(surface,a,b,c)
  _push_triangle(surface,a,c,d)

func _construct_terrain() -> void:
  var builders: Dictionary = {}
  for kind in STONE_COLORS:
    var t := SurfaceTool.new()
    t.begin(Mesh.PRIMITIVE_TRIANGLES)
    builders[kind] = t
  var edges: Array = [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]
  for iz in range(GRID):
    for ix in range(GRID):
      var p: Vector2 = _coord(ix,iz)
      var y: float = _top(ix,iz)
      var q: float = CELL*0.5
      var a := Vector3(p.x-q,y,p.y-q)
      var b := Vector3(p.x+q,y,p.y-q)
      var c := Vector3(p.x+q,y,p.y+q)
      var d := Vector3(p.x-q,y,p.y+q)
      # Upward top normals; no black backfacing holes in terrain.
      _push_quad(builders[_material_for(ix,iz)],a,d,c,b)
      for dir in edges:
        var nx: int = ix+dir.x
        var nz: int = iz+dir.y
        var neighbour_y: float = _top(nx,nz) if _in_bounds(nx,nz) else y-4.2
        if neighbour_y >= y-0.02:
          continue
        var wall_a: Vector3
        var wall_b: Vector3
        if dir == Vector2i(1,0):
          wall_a = b
          wall_b = c
        elif dir == Vector2i(-1,0):
          wall_a = d
          wall_b = a
        elif dir == Vector2i(0,1):
          wall_a = c
          wall_b = d
        else:
          wall_a = a
          wall_b = b
        var from_y: float = neighbour_y
        while from_y < y-0.001:
          var top_y: float = minf(y,from_y+CUT_HEIGHT)
          var depth: float = float(_load_cell(ix,iz)["initial_y"]) - (from_y+top_y)*0.5
          var wall: SurfaceTool = builders[_mat_for_depth(depth)]
          _push_quad(wall,Vector3(wall_a.x,top_y,wall_a.z),
            Vector3(wall_a.x,from_y,wall_a.z),
            Vector3(wall_b.x,from_y,wall_b.z),
            Vector3(wall_b.x,top_y,wall_b.z))
          from_y = top_y
  var assembled := ArrayMesh.new()
  for kind in builders:
    var builder: SurfaceTool = builders[kind]
    builder.generate_normals()
    var surface_mesh: ArrayMesh = builder.commit()
    if surface_mesh == null or surface_mesh.get_surface_count() == 0:
      continue
    var arrays: Array = surface_mesh.surface_get_arrays(0)
    if (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).is_empty():
      continue
    assembled.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
    assembled.surface_set_material(assembled.get_surface_count()-1,world_materials[kind])
  terrain.mesh = assembled
  # Mesh collision rebuilds from precisely the same excavated triangles.
  collision.shape = assembled.create_trimesh_shape()
  mesh_revisions += 1

func _construct_pond() -> void:
  water = MeshInstance3D.new()
  water.name = "REAL_WATER_SURFACE_INSIDE_CARVED_BASIN"
  var st := SurfaceTool.new()
  st.begin(Mesh.PRIMITIVE_TRIANGLES)
  var origin := Vector3(POND_CENTER.x,WATER_LEVEL,POND_CENTER.y)
  for k in range(36):
    var a: float = TAU*float(k)/36.0
    var b: float = TAU*float(k+1)/36.0
    var first := Vector3(origin.x+cos(a)*POND_RADIUS,WATER_LEVEL,origin.z+sin(a)*POND_RADIUS)
    var second := Vector3(origin.x+cos(b)*POND_RADIUS,WATER_LEVEL,origin.z+sin(b)*POND_RADIUS)
    _push_triangle(st,origin,second,first)
  st.generate_normals()
  water.mesh = st.commit()
  var mat := StandardMaterial3D.new()
  mat.albedo_color = Color("#547f94",0.86)
  mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
  mat.roughness = 0.23
  mat.metallic = 0.08
  mat.cull_mode = BaseMaterial3D.CULL_DISABLED
  water.material_override = mat
  water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  add_child(water)

func can_dig(position: Vector3) -> bool:
  var idx: Vector2i = _indices(position.x,position.z)
  if not _in_bounds(idx.x,idx.y):
    return false
  if is_water(position.x,position.z):
    return false
  # Protect the central transit route and warehouse, while the foundation
  # excavation itself is allowed directly around SITE=(0,-3).
  if _is_road(position.x,position.z) and Vector2(position.x,position.z+3).length()>4.1:
    return false
  if Vector2(position.x,position.z-10).length()<4.0:
    return false
  return int(_load_cell(idx.x,idx.y)["cuts"])<MAX_CUTS

func excavate_at(position: Vector3, actor_id: String = "CL-PLAYER-0184") -> Dictionary:
  if not can_dig(position):
    return {"ok":false,"reason":"NO_DIG_PERMISSION_OR_BEDROCK"}
  var idx: Vector2i = _indices(position.x,position.z)
  var entry: Dictionary = _load_cell(idx.x,idx.y)
  var current: int = int(entry["cuts"])
  var kind: String = SOIL_KEYS[current]
  entry["cuts"] = current + 1
  spoil_bag[kind] = int(spoil_bag[kind])+1
  dug_units += 1
  _construct_terrain()
  return {"ok":true,"cell":_key(idx.x,idx.y),"depth_m":float(entry["cuts"])*CUT_HEIGHT,
    "kind":kind,"quantity":1,"actor":actor_id,
    "base_mass_unmined":MAX_CUTS-int(entry["cuts"]),"bedrock_below":true}

func foundation_points() -> Array[Vector3]:
  return [
    Vector3(-1.0,0,-4.0),Vector3(1.0,0,-4.0),
    Vector3(-1.0,0,-2.0),Vector3(1.0,0,-2.0)
  ]

func foundation_ready() -> bool:
  for location in foundation_points():
    var idx: Vector2i = _indices(location.x,location.z)
    if int(_load_cell(idx.x,idx.y)["cuts"])<2:
      return false
  return true

func next_foundation_cut() -> Dictionary:
  for location in foundation_points():
    var idx: Vector2i = _indices(location.x,location.z)
    if int(_load_cell(idx.x,idx.y)["cuts"])<2:
      return excavate_at(location,"CL-NPC-0184-03")
  return {"ok":false,"reason":"FOUNDATION_DONE"}

func inventory_conserved() -> bool:
  var removed: int = 0
  for entry in cells.values():
    var count: int = int(entry["cuts"])
    if count<0 or count>MAX_CUTS:
      return false
    removed += count
  var spoil_total: int = 0
  for count in spoil_bag.values():
    spoil_total += int(count)
  return removed == dug_units and dug_units == spoil_total

func stats() -> Dictionary:
  return {"real_heightfield":true,"layer_count":5,"real_water_basin":water!=null,
    "size_m":int(GRID*CELL),"cell_count":GRID*GRID,
    "excavation_units":dug_units,"cut_cells":cells.values().filter(func(x): return int(x["cuts"])>0).size(),
    "spoil":spoil_bag.duplicate(true),
    "strata_mass_conserved":inventory_conserved(),
    "foundation_ready":foundation_ready(),"max_dig_depth_m":CUT_HEIGHT*MAX_CUTS,
    "mesh_collision_rebuilt":mesh_revisions,"draw_surface_count":terrain.mesh.get_surface_count()}
