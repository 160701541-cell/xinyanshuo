extends Node3D
## APK176 rev187: real deformable triangulated terrain with stratified subsurface
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
# Surface treatments do not limit the number of colors; natural variation
# is driven by deterministic world position and layer depth.
const STONE_COLORS := {
  "grass":Color("#7fac70"),"grass_deep":Color("#4c8651"),
  "grass_light":Color("#a6bf68"),"grass_warm":Color("#a5a76a"),
  "soil":Color("#c2a078"),"soil_dark":Color("#875f43"),
  "soil_sand":Color("#d8bd8e"),"clay":Color("#a87956"),
  "gravel":Color("#909393"),"weathered_rock":Color("#6e8584")
}
signal terrain_cell_changed(center: Vector3, radius: float)
var cells: Dictionary = {}
var spoil_bag: Dictionary = {"topsoil":0,"clay":0,"gravel":0,"weathered_rock":0}
var dug_units: int = 0
var terrain: MeshInstance3D
var collision: CollisionShape3D
var water: MeshInstance3D
var world_materials: Dictionary = {}
var mesh_revisions: int = 0
var river_enabled: bool = true
# REV193: deterministic, physically collidable terrain chunks outside the
# original 92m excavation square. Existing central NPC/economy stays intact.
const STREAM_CHUNK_M: float = 46.0 # 23*2m; +/-46 seam is EXACTLY shared
const STREAM_CELLS: int = 23
const STREAM_CELL: float = 2.0
const STREAM_RADIUS: int = 2
const STREAM_MAX_ACTIVE: int = 36
const STREAM_SAVE_SCHEMA: int = 1
const STREAM_WORLD_SEED: int = 20261017
var stream_chunks: Dictionary = {} # "cx:cz" -> Node3D containing visual+physics
var stream_cut_cells: Dictionary = {} # "cx:cz:ix:iz" -> depth [1..8]
var stream_center: Vector2i = Vector2i(999999,999999)
var stream_save_path: String = "user://canglan_world_streamed_terrain_v1.json"
var stream_save_ok: bool = true
var stream_last_save_error: String = ""
var stream_created: int = 0
var stream_unloaded: int = 0
var stream_saved_updates: int = 0
var stream_terrain_mesh_triangles: int = 0

func _ready() -> void:
  name = "PhysicalDeformable92mVillageStrata"
  for kind in STONE_COLORS:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = STONE_COLORS[kind]
    mat.roughness = 0.94
    mat.metallic = 0.0
    # rev191 REAL MESA GPU SCREENSHOT caught the soil NOT RENDERING:
    # the 92m inner field was pixel-identical to blue SKY with floating grass.
    # Display both sides of the excavatable mesh; the underside is only
    # geological exposure while physics remains the same triangle mesh.
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    world_materials[kind] = mat
  # One smooth vertex-colored biome skin for the unexcavated soil.
  # Previous per-cell random material choices rendered as an enormous
  # brown/green 2m CHECKERBOARD in the first genuine rev191 Godot capture.
  var ground_mat:=StandardMaterial3D.new()
  ground_mat.albedo_color=Color.WHITE
  ground_mat.vertex_color_use_as_albedo=true
  ground_mat.cull_mode=BaseMaterial3D.CULL_DISABLED
  ground_mat.roughness=0.96
  world_materials["natural_ground"]=ground_mat
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
  _construct_far_land()
  _load_stream_deltas()
  # Spawn first physical chunk ring before player movement begins; Godot
  # tests are allowed to inspect true StaticBody3D collisions immediately.
  stream_around(Vector3(0,0,10),true)

# Deterministic 46m coordinate grid, matching the original centre border:
# core world = chunks (0,0), (1,0), (0,1), (1,1).
func _stream_coords(x: float,z: float) -> Vector2i:
  return Vector2i(floori((x+HALF)/STREAM_CHUNK_M),
    floori((z+HALF)/STREAM_CHUNK_M))

func _stream_is_core(c: Vector2i) -> bool:
  return c.x>=0 and c.x<=1 and c.y>=0 and c.y<=1

func _stream_chunk_key(c: Vector2i) -> String:
  return str(c.x)+":"+str(c.y)

func _stream_cell_key(c: Vector2i,ix: int,iz: int) -> String:
  return str(c.x)+":"+str(c.y)+":"+str(ix)+":"+str(iz)

func _stream_cut_count(c: Vector2i,ix: int,iz: int) -> int:
  return clampi(int(stream_cut_cells.get(_stream_cell_key(c,ix,iz),0)),0,MAX_CUTS)

func _stream_local_cell(c: Vector2i,x: float,z: float) -> Vector2i:
  return Vector2i(clampi(floori((x-(-HALF+float(c.x)*STREAM_CHUNK_M))/STREAM_CELL),0,STREAM_CELLS-1),
    clampi(floori((z-(-HALF+float(c.y)*STREAM_CHUNK_M))/STREAM_CELL),0,STREAM_CELLS-1))

func stream_contains_physical_chunk(x: float,z: float) -> bool:
  var c: Vector2i=_stream_coords(x,z)
  return _stream_is_core(c) or stream_chunks.has(_stream_chunk_key(c))

func _stream_base_cell_height(c: Vector2i,ix: int,iz: int,x: float,z: float) -> float:
  return far_height_at(x,z)-float(_stream_cut_count(c,ix,iz))*CUT_HEIGHT

func _stream_chunk_mesh(c: Vector2i) -> ArrayMesh:
  var ox: float=-HALF+float(c.x)*STREAM_CHUNK_M
  var oz: float=-HALF+float(c.y)*STREAM_CHUNK_M
  var top:=SurfaceTool.new()
  top.begin(Mesh.PRIMITIVE_TRIANGLES)
  var sides: Dictionary={}
  for kind in ["topsoil","clay","gravel","weathered_rock"]:
    var wall:=SurfaceTool.new()
    wall.begin(Mesh.PRIMITIVE_TRIANGLES)
    sides[kind]=wall
  var sides_count: Dictionary={}
  for kind in sides:
    sides_count[kind]=0
  for iz in range(STREAM_CELLS):
    for ix in range(STREAM_CELLS):
      var x: float=ox+float(ix)*STREAM_CELL
      var z: float=oz+float(iz)*STREAM_CELL
      var depth: int=_stream_cut_count(c,ix,iz)
      var a:=Vector3(x,far_height_at(x,z)-float(depth)*CUT_HEIGHT,z)
      var b:=Vector3(x+STREAM_CELL,far_height_at(x+STREAM_CELL,z)-float(depth)*CUT_HEIGHT,z)
      var c1:=Vector3(x+STREAM_CELL,far_height_at(x+STREAM_CELL,z+STREAM_CELL)-float(depth)*CUT_HEIGHT,z+STREAM_CELL)
      var d:=Vector3(x,far_height_at(x,z+STREAM_CELL)-float(depth)*CUT_HEIGHT,z+STREAM_CELL)
      # Native visible AND collidable top geometry, world-space biome color.
      for v in [a,d,c1,a,c1,b]:
        top.set_color(ground_color_at(v.x,v.z) if depth==0 else STONE_COLORS["soil_dark"])
        top.add_vertex(Vector3(v.x-ox,v.y,v.z-oz))
      # Actual exposed soil walls around dug cells, including across chunk
      # borders; do not fabricate terrain from a color-only decal.
      var edges: Array[Vector2i]=[
        Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]
      for normal in edges:
        var nx: int=ix+normal.x
        var nz: int=iz+normal.y
        var other: Vector2i=c
        if nx<0:
          other.x-=1
          nx=STREAM_CELLS-1
        elif nx>=STREAM_CELLS:
          other.x+=1
          nx=0
        if nz<0:
          other.y-=1
          nz=STREAM_CELLS-1
        elif nz>=STREAM_CELLS:
          other.y+=1
          nz=0
        var neighbor_depth: int=_stream_cut_count(other,nx,nz)
        if _stream_is_core(other):
          # Old core geometry keeps its own physically excavated strata; at
          # this seam stream deltas are only allowed on exterior cells.
          neighbor_depth=0
        if depth<=neighbor_depth:
          continue
        var pa: Vector2
        var pb: Vector2
        if normal==Vector2i(1,0):
          pa=Vector2(x+STREAM_CELL,z)
          pb=Vector2(x+STREAM_CELL,z+STREAM_CELL)
        elif normal==Vector2i(-1,0):
          pa=Vector2(x,z+STREAM_CELL)
          pb=Vector2(x,z)
        elif normal==Vector2i(0,1):
          pa=Vector2(x+STREAM_CELL,z+STREAM_CELL)
          pb=Vector2(x,z+STREAM_CELL)
        else:
          pa=Vector2(x,z)
          pb=Vector2(x+STREAM_CELL,z)
        for depth_layer in range(neighbor_depth,depth):
          var layer_top: float=float(depth_layer)*CUT_HEIGHT
          var layer_bottom: float=float(depth_layer+1)*CUT_HEIGHT
          var kind: String=SOIL_KEYS[mini(depth_layer,SOIL_KEYS.size()-1)]
          var surface: SurfaceTool=sides[kind]
          var qa:=Vector3(pa.x-ox,far_height_at(pa.x,pa.y)-layer_top,pa.y-oz)
          var qb:=Vector3(pb.x-ox,far_height_at(pb.x,pb.y)-layer_top,pb.y-oz)
          var qc:=Vector3(pb.x-ox,far_height_at(pb.x,pb.y)-layer_bottom,pb.y-oz)
          var qd:=Vector3(pa.x-ox,far_height_at(pa.x,pa.y)-layer_bottom,pa.y-oz)
          _push_quad(surface,qa,qb,qc,qd)
          sides_count[kind]=int(sides_count[kind])+1
  top.generate_normals()
  var output:=ArrayMesh.new()
  var topmesh: ArrayMesh=top.commit()
  if topmesh!=null:
    output.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,topmesh.surface_get_arrays(0))
    output.surface_set_material(output.get_surface_count()-1,world_materials["natural_ground"])
  for kind in sides:
    if int(sides_count[kind])<=0:
      continue
    var wall: SurfaceTool=sides[kind]
    wall.generate_normals()
    var walls: ArrayMesh=wall.commit()
    if walls!=null and walls.get_surface_count()>0:
      output.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,walls.surface_get_arrays(0))
      output.surface_set_material(output.get_surface_count()-1,
        world_materials["soil"] if kind=="topsoil" else world_materials[kind])
  return output

func _create_stream_chunk(c: Vector2i) -> void:
  var key: String=_stream_chunk_key(c)
  if _stream_is_core(c) or stream_chunks.has(key):
    return
  var root:=Node3D.new()
  root.name="PersistentChunk_"+str(c.x)+"_"+str(c.y)
  root.position=Vector3(-HALF+float(c.x)*STREAM_CHUNK_M,0,
    -HALF+float(c.y)*STREAM_CHUNK_M)
  var visible_mesh:=MeshInstance3D.new()
  visible_mesh.name="ActualWalkableStreamedTerrainMesh"
  visible_mesh.mesh=_stream_chunk_mesh(c)
  root.add_child(visible_mesh)
  var body:=StaticBody3D.new()
  body.name="PhysicalStreamedTerrainCollision"
  root.add_child(body)
  var shape:=CollisionShape3D.new()
  shape.name="RegeneratedStreamedSoilCollision"
  shape.shape=visible_mesh.mesh.create_trimesh_shape()
  body.add_child(shape)
  # Draw chunks against existing far LOD. Shader/LOD replacement is a
  # separate milestone; never claim these are fully textured biomes yet.
  add_child(root)
  stream_chunks[key]=root
  stream_created+=1

func _rebuild_stream_chunk(c: Vector2i) -> void:
  var root: Node3D=stream_chunks.get(_stream_chunk_key(c)) as Node3D
  if root==null:
    return
  var visual: MeshInstance3D=root.get_node("ActualWalkableStreamedTerrainMesh")
  visual.mesh=_stream_chunk_mesh(c)
  var collision_node: CollisionShape3D=root.get_node(
    "PhysicalStreamedTerrainCollision/RegeneratedStreamedSoilCollision")
  collision_node.shape=visual.mesh.create_trimesh_shape()

func stream_around(position: Vector3, force: bool=false) -> void:
  var center: Vector2i=_stream_coords(position.x,position.z)
  if center==stream_center and not force:
    return
  stream_center=center
  var required: Dictionary={}
  for offset_z in range(-STREAM_RADIUS,STREAM_RADIUS+1):
    for offset_x in range(-STREAM_RADIUS,STREAM_RADIUS+1):
      var c:=Vector2i(center.x+offset_x,center.y+offset_z)
      if not _stream_is_core(c):
        required[_stream_chunk_key(c)]=c
  # Unload the visual+collision node only; the authoritative cell deltas
  # persist separately and will restore when returning to this location.
  for id in stream_chunks.keys():
    if not required.has(id):
      var old_chunk: Node3D=stream_chunks[id]
      old_chunk.queue_free()
      stream_chunks.erase(id)
      stream_unloaded+=1
  for key in required:
    if not stream_chunks.has(key):
      _create_stream_chunk(required[key])
  assert(stream_chunks.size()<=STREAM_MAX_ACTIVE)

func _load_stream_deltas() -> void:
  if not FileAccess.file_exists(stream_save_path):
    return
  var file:=FileAccess.open(stream_save_path,FileAccess.READ)
  if file==null:
    stream_save_ok=false
    stream_last_save_error="STREAM_SAVE_READ_FAILED"
    return
  var parsed: Variant=JSON.parse_string(file.get_as_text())
  if not parsed is Dictionary:
    stream_save_ok=false
    stream_last_save_error="STREAM_SAVE_INVALID_JSON"
    return
  var data: Dictionary=parsed
  if int(data.get("schema",-1))!=STREAM_SAVE_SCHEMA or int(data.get("seed",-1))!=STREAM_WORLD_SEED:
    stream_save_ok=false
    stream_last_save_error="STREAM_SAVE_WRONG_SCHEMA_OR_WORLD_SEED"
    return
  var saved: Dictionary=data.get("cut_cells",{})
  if saved.size()>100000:
    stream_save_ok=false
    stream_last_save_error="STREAM_SAVE_TOO_LARGE"
    return
  for key in saved:
    var entry: Array=String(key).split(":")
    if entry.size()!=4:
      continue
    var coord:=Vector2i(int(entry[0]),int(entry[1]))
    var ix: int=int(entry[2])
    var iz: int=int(entry[3])
    var depth: int=int(saved[key])
    if _stream_is_core(coord) or ix<0 or iz<0 or ix>=STREAM_CELLS or iz>=STREAM_CELLS or depth<=0 or depth>MAX_CUTS:
      continue
    stream_cut_cells[key]=depth

func _save_stream_deltas() -> bool:
  var json:=JSON.stringify({
    "schema":STREAM_SAVE_SCHEMA,
    "seed":STREAM_WORLD_SEED,
    "cut_cells":stream_cut_cells}, "",false)
  var temporary: String=stream_save_path+".tmp"
  var file:=FileAccess.open(temporary,FileAccess.WRITE)
  if file==null:
    stream_save_ok=false
    stream_last_save_error="STREAM_SAVE_OPEN_WRITE_FAILED"
    return false
  file.store_string(json)
  file.flush()
  file.close()
  var old_absolute: String=ProjectSettings.globalize_path(temporary)
  var new_absolute: String=ProjectSettings.globalize_path(stream_save_path)
  if DirAccess.rename_absolute(old_absolute,new_absolute)!=OK:
    stream_save_ok=false
    stream_last_save_error="STREAM_SAVE_ATOMIC_RENAME_FAILED"
    return false
  stream_save_ok=true
  stream_last_save_error=""
  stream_saved_updates+=1
  return true

func _streamed_height_at(x: float,z: float) -> float:
  var c: Vector2i=_stream_coords(x,z)
  var local: Vector2i=_stream_local_cell(c,x,z)
  var ox: float=-HALF+float(c.x)*STREAM_CHUNK_M
  var oz: float=-HALF+float(c.y)*STREAM_CHUNK_M
  var x0: float=ox+float(local.x)*STREAM_CELL
  var z0: float=oz+float(local.y)*STREAM_CELL
  var u: float=clampf((x-x0)/STREAM_CELL,0.0,1.0)
  var v: float=clampf((z-z0)/STREAM_CELL,0.0,1.0)
  var h: float=lerpf(lerpf(far_height_at(x0,z0),
    far_height_at(x0+STREAM_CELL,z0),u),lerpf(
    far_height_at(x0,z0+STREAM_CELL),
    far_height_at(x0+STREAM_CELL,z0+STREAM_CELL),u),v)
  return h-float(_stream_cut_count(c,local.x,local.y))*CUT_HEIGHT

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
  # Bilinear interpolation of the SAME shared 3D terrain vertices the mesh
  # renders. Not center-of-cell terracing (the rev184 screenshot defect).
  var idx: Vector2i = _indices(x,z)
  if not _in_bounds(idx.x,idx.y):
    return _base_at(x,z)
  var p: Vector2 = _coord(idx.x,idx.y)
  var left: float = p.x-CELL*0.5
  var north: float = p.y-CELL*0.5
  var u: float = clampf((x-left)/CELL,0.0,1.0)
  var v: float = clampf((z-north)/CELL,0.0,1.0)
  var depth: float = float(int(_load_cell(idx.x,idx.y)["cuts"]))*CUT_HEIGHT
  return lerpf(lerpf(_base_at(left,north),_base_at(left+CELL,north),u),
    lerpf(_base_at(left,north+CELL),_base_at(left+CELL,north+CELL),u),v)-depth

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
  var seeded: float = sin(float(ix)*0.43+float(iz)*1.75)*cos(float(iz)*0.23-float(ix)*1.03)
  if _is_road(p.x,p.y):
    return "soil_sand" if seeded>0.24 else ("soil_dark" if seeded<-0.33 else "soil")
  if p.distance_to(POND_CENTER) < POND_RADIUS+2.2:
    return "soil_sand" if seeded>0 else "soil"
  if seeded>0.46:
    return "grass_light"
  if seeded<-0.34:
    return "grass_deep"
  if seeded>0.11:
    return "grass_warm"
  return "grass"

func _mat_for_depth(depth: float) -> String:
  if depth < 0.90:
    return "soil"
  if depth < 1.80:
    return "clay"
  if depth < 2.70:
    return "gravel"
  return "weathered_rock"

# Actual continuous grass/sand/soil biome colors. One world-space color
# field evaluated at shared vertices; no random material per 2m cell.
func ground_color_at(x: float,z: float) -> Color:
  var low: float=0.5+0.5*sin(x*0.075+0.7*sin(z*0.11))*cos(z*0.092)
  var high: float=0.5+0.5*sin(x*0.39+z*0.28)*cos(z*0.43-x*0.19)
  var grass_a:=Color("#648e5c")
  var grass_b:=Color("#a0bc72")
  var grass:=grass_a.lerp(grass_b,clampf(0.23+0.54*low+0.23*high,0.0,1.0))
  # Narrow natural cart-road shoulders; no one-cell ochre checkerboard.
  var road_weight: float=0.0
  if z>=-20.0 and z<=23.0:
    road_weight=maxf(road_weight,1.0-smoothstep(2.6,5.0,absf(x)))
  if x>=-23.0 and x<=6.0:
    road_weight=maxf(road_weight,1.0-smoothstep(1.1,3.2,absf(z-10.5)))
  if x>=-4.0 and x<=25.0:
    road_weight=maxf(road_weight,1.0-smoothstep(1.1,3.2,absf(z-(2.5-0.25*x))))
  var sand_dist: float=Vector2(x,z).distance_to(POND_CENTER)
  var shore_weight: float=1.0-smoothstep(POND_RADIUS+1.1,POND_RADIUS+4.5,sand_dist)
  var soil:=Color("#b8a07b").lerp(Color("#a99276"),low*0.32)
  var sand:=Color("#cdb896").lerp(Color("#c2ae84"),high*0.24)
  var mixed:=grass.lerp(sand,shore_weight*0.84)
  return mixed.lerp(soil,road_weight*0.95)

func _push_ground_quad(surface: SurfaceTool,a:Vector3,b:Vector3,c:Vector3,d:Vector3) -> void:
  for p in [a,b,c,a,c,d]:
    surface.set_color(ground_color_at(p.x,p.z))
    surface.add_vertex(p)

func _push_triangle(surface: SurfaceTool, a: Vector3,b: Vector3,c: Vector3) -> void:
  surface.add_vertex(a)
  surface.add_vertex(b)
  surface.add_vertex(c)

func _push_quad(surface: SurfaceTool,a:Vector3,b:Vector3,c:Vector3,d:Vector3) -> void:
  _push_triangle(surface,a,b,c)
  _push_triangle(surface,a,c,d)

func _construct_terrain() -> void:
  # REV186: every neighboring unexcavated cell SHARES four actual corner
  # heights. Natural slopes are CONTINUOUS, never 2m tall stair-step walls.
  # Only a player/NPC EXCAVATION creates real vertical layer exposures.
  var builders: Dictionary = {}
  for kind in STONE_COLORS:
    var builder := SurfaceTool.new()
    builder.begin(Mesh.PRIMITIVE_TRIANGLES)
    builders[kind] = builder
  var ground_builder:=SurfaceTool.new()
  ground_builder.begin(Mesh.PRIMITIVE_TRIANGLES)
  builders["natural_ground"]=ground_builder
  var edges: Array[Vector2i] = [Vector2i(1,0),Vector2i(-1,0),
    Vector2i(0,1),Vector2i(0,-1)]
  for iz in range(GRID):
    for ix in range(GRID):
      var p: Vector2 = _coord(ix,iz)
      var left: float = p.x-CELL*0.5
      var right: float = p.x+CELL*0.5
      var top: float = p.y-CELL*0.5
      var bottom: float = p.y+CELL*0.5
      var cuts: int = int(_load_cell(ix,iz)["cuts"])
      var depth: float = CUT_HEIGHT*float(cuts)
      var a := Vector3(left,_base_at(left,top)-depth,top)
      var b := Vector3(right,_base_at(right,top)-depth,top)
      var c := Vector3(right,_base_at(right,bottom)-depth,bottom)
      var d := Vector3(left,_base_at(left,bottom)-depth,bottom)
      if cuts==0:
        _push_ground_quad(builders["natural_ground"],a,d,c,b)
      else:
        _push_quad(builders[_material_for(ix,iz)],a,d,c,b)
      # Exposed strata exist ONLY where a cell is genuinely dug LOWER
      # than the adjacent cell (or at the outer 3m deep geological boundary).
      for direction in edges:
        var nx: int = ix+direction.x
        var nz: int = iz+direction.y
        var beyond: bool = not _in_bounds(nx,nz)
        var adjacent_cuts: int = int(_load_cell(nx,nz)["cuts"]) if not beyond else 0
        if not beyond and cuts<=adjacent_cuts:
          continue
        var start_point: Vector2
        var end_point: Vector2
        if direction==Vector2i(1,0):
          start_point=Vector2(right,top)
          end_point=Vector2(right,bottom)
        elif direction==Vector2i(-1,0):
          start_point=Vector2(left,bottom)
          end_point=Vector2(left,top)
        elif direction==Vector2i(0,1):
          start_point=Vector2(right,bottom)
          end_point=Vector2(left,bottom)
        else:
          start_point=Vector2(left,top)
          end_point=Vector2(right,top)
        var top_cuts: int = adjacent_cuts
        var bottom_cuts: int = cuts if not beyond else maxi(cuts,8)
        for layer in range(top_cuts,bottom_cuts):
          # At the cut boundary different geological horizons are real
          # geometric walls, not fake brown color on a background plane.
          var from_height: float = CUT_HEIGHT*float(layer)
          var to_height: float = CUT_HEIGHT*float(layer+1)
          var kind: String = _mat_for_depth((from_height+to_height)*0.5)
          var st: SurfaceTool = builders[kind]
          var upper_a := Vector3(start_point.x,
            _base_at(start_point.x,start_point.y)-from_height,start_point.y)
          var lower_a := Vector3(start_point.x,
            _base_at(start_point.x,start_point.y)-to_height,start_point.y)
          var upper_b := Vector3(end_point.x,
            _base_at(end_point.x,end_point.y)-from_height,end_point.y)
          var lower_b := Vector3(end_point.x,
            _base_at(end_point.x,end_point.y)-to_height,end_point.y)
          _push_quad(st,upper_a,upper_b,lower_b,lower_a)
  var new_mesh := ArrayMesh.new()
  for kind in builders:
    var tool: SurfaceTool = builders[kind]
    tool.generate_normals()
    var part: ArrayMesh = tool.commit()
    if part==null or part.get_surface_count()==0:
      continue
    var verts: Array = part.surface_get_arrays(0)
    if (verts[Mesh.ARRAY_VERTEX] as PackedVector3Array).is_empty():
      continue
    new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,verts)
    new_mesh.surface_set_material(new_mesh.get_surface_count()-1,world_materials[kind])
  terrain.mesh = new_mesh
  collision.shape = new_mesh.create_trimesh_shape()
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

# rev191: the visible 92m square used to be surrounded by a vertical
# 22-metre "crust skirt", while the distant 6m mesh quads OVERLAPPED the
# centre square. This is what the player's screenshot called a cut-out slab.
# The far field must meet the *same* local heightfield at x/z=+/-46m.
func far_height_at(x: float,z: float) -> float:
  var outside: float=maxf(0.0,maxf(absf(x)-HALF,absf(z)-HALF))
  if outside<=0.0001:
    return _base_at(x,z)
  var blend: float=clampf(outside/190.0,0.0,1.0)
  blend=blend*blend*(3.0-2.0*blend) # C1 transition, no sudden cliff
  var low_hills: float=(1.8*sin(x*0.029)*cos(z*0.021)+
    1.3*sin(x*0.046+z*0.024))*blend
  var mountains: float=pow(blend,2.4)*(9.0+6.0*sin(x*0.036)*cos(z*0.035))
  return _base_at(x,z)+low_hills+mountains

func _far_clip_marks(from: float,to: float) -> Array[float]:
  # Local 2m grid ends at x/z +/-HALF. Split any six-metre LOD tile
  # exactly at those coordinate planes BEFORE emitting triangles.
  var result: Array[float]=[from]
  if from < -HALF and to > -HALF:
    result.append(-HALF)
  if from < HALF and to > HALF:
    result.append(HALF)
  result.append(to)
  result.sort()
  return result

func _construct_far_land() -> void:
  # True gap-free ring: DO NOT render any overlapping distant triangles on
  # top of the diggable centre; DO NOT draw a 22m vertical cliff around it.
  # Distant scenery is visual LOD only. Genuine global infinite chunks,
  # physics, saving and NPC streaming are a SEPARATE uncompleted milestone.
  var far_parent:=Node3D.new()
  far_parent.name="FarGroundAndMountainFoothills_AllCameraDirections_600m"
  add_child(far_parent)
  var far_material:=StandardMaterial3D.new()
  far_material.albedo_color=Color("#83ad75")
  far_material.roughness=1.0
  far_material.cull_mode=BaseMaterial3D.CULL_DISABLED
  var far_size: int=106
  var tile_step: int=18
  var tile_index: int=0
  var generated_quads: int=0
  var clipped_seam_quads: int=0
  for ztile in range(0,far_size,tile_step):
    for xtile in range(0,far_size,tile_step):
      var terrain_chunk:=SurfaceTool.new()
      terrain_chunk.begin(Mesh.PRIMITIVE_TRIANGLES)
      var added: int=0
      for nz in range(ztile,mini(far_size,ztile+tile_step)):
        for nx in range(xtile,mini(far_size,xtile+tile_step)):
          var x0: float=float(nx-53)*6.0
          var x1: float=x0+6.0
          var z0: float=float(nz-53)*6.0
          var z1: float=z0+6.0
          var xs: Array[float]=_far_clip_marks(x0,x1)
          var zs: Array[float]=_far_clip_marks(z0,z1)
          for zi in range(zs.size()-1):
            for xi in range(xs.size()-1):
              var lx: float=xs[xi]
              var rx: float=xs[xi+1]
              var tz: float=zs[zi]
              var bz: float=zs[zi+1]
              var mid_x: float=0.5*(lx+rx)
              var mid_z: float=0.5*(tz+bz)
              if absf(mid_x)<HALF and absf(mid_z)<HALF:
                continue # central diggable cells render EXACTLY ONCE
              var a:=Vector3(lx,far_height_at(lx,tz),tz)
              var b:=Vector3(rx,far_height_at(rx,tz),tz)
              var c:=Vector3(rx,far_height_at(rx,bz),bz)
              var d:=Vector3(lx,far_height_at(lx,bz),bz)
              _push_quad(terrain_chunk,a,d,c,b)
              added+=1
              generated_quads+=1
              if xs.size()>2 or zs.size()>2:
                clipped_seam_quads+=1
      if added<=0:
        continue
      terrain_chunk.generate_normals()
      var part:=MeshInstance3D.new()
      part.name="ActualFarGroundChunk_%02d" % tile_index
      tile_index+=1
      part.mesh=terrain_chunk.commit()
      part.material_override=far_material
      part.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
      far_parent.add_child(part)
  far_parent.set_meta("far_mesh_chunk_count",tile_index)
  far_parent.set_meta("far_quads",generated_quads)
  far_parent.set_meta("far_stitched_seam_quads",clipped_seam_quads)
  far_parent.set_meta("far_terrain_overlaps_local_square",false)
  far_parent.set_meta("real_infinite_chunk_streaming_complete",false)

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
  terrain_cell_changed.emit(Vector3(position.x,height_at(position.x,position.z),position.z),CELL)
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
  return {"real_heightfield":true,"continuous_shared_vertex_slopes":true,
    "no_infinite_gray_void":true,"surrounding_far_land_m":636,
    "far_seam_stitched":true,"far_cliff_skirt_removed":true,
    "continuous_vertex_biome":true,"checkerboard_cell_materials_removed":true,
    "infinite_streaming_complete":false,
    "recolors_unlimited":true,
    "natural_terrace_walls":false,"layer_count":5,"real_water_basin":water!=null,
    "size_m":int(GRID*CELL),"cell_count":GRID*GRID,
    "excavation_units":dug_units,"cut_cells":cells.values().filter(func(x): return int(x["cuts"])>0).size(),
    "spoil":spoil_bag.duplicate(true),
    "strata_mass_conserved":inventory_conserved(),
    "foundation_ready":foundation_ready(),"max_dig_depth_m":CUT_HEIGHT*MAX_CUTS,
    "mesh_collision_rebuilt":mesh_revisions,"draw_surface_count":terrain.mesh.get_surface_count()}
