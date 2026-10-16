extends RefCounted
## Original parameterized 3D geometry: walls, curved tiled eaves, timber, doors.
## NOT billboards or imported image sheets. Every building has an immutable ID.
const WALL: int = 0
const WOOD: int = 1
const ROOF: int = 2
const RIDGE: int = 3
const STONE: int = 4
const PAPER: int = 5
const METAL: int = 6
const PALETTE := ["#d4cbb6","#614431","#455c62","#83918b","#858a83","#b8ad83","#a28758"]
var _materials: Array[StandardMaterial3D] = []

func _ensure_materials() -> void:
	if not _materials.is_empty():
		return
	for i in range(PALETTE.size()):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(PALETTE[i])
		mat.roughness = 0.94 if i != METAL else 0.45
		mat.metallic = 0.35 if i == METAL else 0.0
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_materials.append(mat)

func _quad(geom: Array, idx: int,a: Vector3,b: Vector3,c: Vector3,d: Vector3) -> void:
	var v: Array = geom[idx]
	for p in [a,b,c,a,c,d]:
		v.append(p)

func _box(geom: Array,idx: int,center: Vector3,size: Vector3) -> void:
	var x: float = size.x*0.5
	var y: float = size.y*0.5
	var z: float = size.z*0.5
	var p := center
	_quad(geom,idx,p+Vector3(-x,-y,-z),p+Vector3(x,-y,-z),p+Vector3(x,y,-z),p+Vector3(-x,y,-z))
	_quad(geom,idx,p+Vector3(x,-y,z),p+Vector3(-x,-y,z),p+Vector3(-x,y,z),p+Vector3(x,y,z))
	_quad(geom,idx,p+Vector3(-x,-y,z),p+Vector3(-x,-y,-z),p+Vector3(-x,y,-z),p+Vector3(-x,y,z))
	_quad(geom,idx,p+Vector3(x,-y,-z),p+Vector3(x,-y,z),p+Vector3(x,y,z),p+Vector3(x,y,-z))
	_quad(geom,idx,p+Vector3(-x,y,-z),p+Vector3(x,y,-z),p+Vector3(x,y,z),p+Vector3(-x,y,z))
	_quad(geom,idx,p+Vector3(-x,-y,z),p+Vector3(x,-y,z),p+Vector3(x,-y,-z),p+Vector3(-x,-y,-z))

func _mesh_from_buffers(geom: Array) -> ArrayMesh:
	var output := ArrayMesh.new()
	for idx in range(geom.size()):
		if (geom[idx] as Array).is_empty():
			continue
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for point in geom[idx]:
			st.add_vertex(point)
		st.generate_normals()
		var arrays: Array = st.commit_to_arrays()
		output.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		output.surface_set_material(output.get_surface_count()-1,_materials[idx])
	return output

func _make_door(parent: Node3D, entity_id: String,w: float,d: float) -> Node3D:
	var hinge := Node3D.new()
	hinge.name = "DoorHinge"
	hinge.position = Vector3(-0.75,0.16,d*0.5+0.08)
	parent.add_child(hinge)
	var slab := MeshInstance3D.new()
	slab.name = "DoorLeaf"
	var mesh_box := BoxMesh.new()
	mesh_box.size = Vector3(1.48,2.3,0.13)
	slab.mesh = mesh_box
	slab.position = Vector3(0.74,1.23,0)
	slab.material_override = _materials[WOOD]
	hinge.add_child(slab)
	var band := MeshInstance3D.new()
	var band_mesh := BoxMesh.new()
	band_mesh.size = Vector3(1.3,0.08,0.15)
	band.mesh = band_mesh
	band.material_override = _materials[METAL]
	band.position = Vector3(0.74,1.65,0.0)
	hinge.add_child(band)
	hinge.set_meta("entity_id",entity_id+"-DOOR")
	hinge.set_meta("open",false)
	return hinge

func set_door_open(building: Node3D, open: bool) -> void:
	var hinge: Node3D = building.get_node_or_null("DoorHinge")
	if hinge == null:
		return
	hinge.rotation.y = -PI*0.50 if open else 0.0
	hinge.set_meta("open",open)

func set_damaged(building: Node3D, level: int) -> void:
	var v: int = clampi(level,0,2)
	building.set_meta("damage",v)
	var draw_node: MeshInstance3D = building.get_node_or_null("BuildingVisual")
	if draw_node != null:
		draw_node.visible = v < 2
	# Collapse is visibly represented by rubble rather than deleting IDs.
	var rubble: Node3D = building.get_node_or_null("CollapsedRubble")
	if rubble != null:
		rubble.visible = v >= 2
	var hinge: Node3D = building.get_node_or_null("DoorHinge")
	if hinge != null:
		hinge.visible = v < 2

func make_building(id: String,kind: String,location: Vector3,variation: int) -> Node3D:
	_ensure_materials()
	var result := Node3D.new()
	result.name = id
	result.position = location
	result.set_meta("entity_id",id)
	result.set_meta("kind",kind)
	result.set_meta("damage",0)
	var w: float = 8.7 + float(variation%4)*0.85
	var d: float = 6.7+float((variation/3)%3)*0.65
	var ornate: bool = kind in ["temple","school","inn","teahouse"]
	if ornate:
		w += 2.7
	var geom: Array = []
	for i in range(_materials.size()):
		geom.append([])
	# Solid stone foundation and real front door aperture.
	_box(geom,STONE,Vector3(0,0.13,0),Vector3(w+0.7,0.35,d+0.7))
	var front_z: float = d*0.5
	var back_z: float = -d*0.5
	var wall_h: float = 3.8 + (1.2 if ornate else 0.0)
	_box(geom,WALL,Vector3(0,wall_h/2.0,back_z),Vector3(w,wall_h,0.29))
	_box(geom,WALL,Vector3(-w/2+0.18,wall_h/2,0),Vector3(0.34,wall_h,d))
	_box(geom,WALL,Vector3(w/2-0.18,wall_h/2,0),Vector3(0.34,wall_h,d))
	var side_len: float = (w-2.5)*0.5
	for side in [-1.0,1.0]:
		_box(geom,WALL,Vector3(side*(1.25+side_len*0.5),wall_h/2,front_z),Vector3(side_len,wall_h,0.27))
		_box(geom,WOOD,Vector3(side*(w/2-0.25),wall_h/2,front_z+0.18),Vector3(0.38,wall_h+0.2,0.4))
		_box(geom,WOOD,Vector3(side*1.36,wall_h/2,front_z+0.14),Vector3(0.27,wall_h+0.2,0.31))
		var win_x: float = side*(w/2-1.65)
		_box(geom,WOOD,Vector3(win_x,2.08,front_z+0.19),Vector3(1.55,1.55,0.25))
		_box(geom,PAPER,Vector3(win_x,2.08,front_z+0.345),Vector3(1.29,1.29,0.06))
		for offset in [-0.42,0.0,0.42]:
			_box(geom,WOOD,Vector3(win_x+offset,2.1,front_z+0.39),Vector3(0.067,1.3,0.10))
		for offset in [-0.4,0.4]:
			_box(geom,WOOD,Vector3(win_x,2.1+offset,front_z+0.39),Vector3(1.3,0.072,0.10))
	for side in [-1.0,1.0]:
		_box(geom,WOOD,Vector3(side*(w/2-0.2),wall_h+0.05,0),Vector3(0.40,0.32,d+1.1))
	_box(geom,WOOD,Vector3(0,wall_h+0.06,front_z+0.17),Vector3(w+0.75,0.33,0.48))
	_box(geom,WOOD,Vector3(0,wall_h+0.12,back_z-0.17),Vector3(w+0.75,0.36,0.48))
	# A real pitched roof with thick overhanging eaves and a continuous raised ridge.
	var edge_y: float = wall_h+0.22
	var ridge_y: float = wall_h + (2.36 if ornate else 1.85)
	var ez: float = d*0.5+0.7
	var ex: float = w*0.5+0.62
	_quad(geom,ROOF,Vector3(-ex,edge_y,-ez),Vector3(ex,edge_y,-ez),
			Vector3(ex,ridge_y,0),Vector3(-ex,ridge_y,0))
	_quad(geom,ROOF,Vector3(-ex,ridge_y,0),Vector3(ex,ridge_y,0),
			Vector3(ex,edge_y,ez),Vector3(-ex,edge_y,ez))
	_box(geom,RIDGE,Vector3(0,ridge_y+0.065,0),Vector3(w+1.7,0.26,0.39))
	for k in range(12):
		var roof_x: float = lerpf(-ex+0.17,ex-0.17,float(k)/11.0)
		for sign in [-1.0,1.0]:
			# Each course is raised out of the sloped roof, not just painted stripes.
			for j in range(4):
				var q: float = (float(j)+0.5)/4.0
				var zz: float = sign*ez*q
				var yy: float = lerpf(ridge_y,edge_y,q)+0.043
				_box(geom,RIDGE,Vector3(roof_x,yy,zz),Vector3(0.075,0.06,0.55))
	_box(geom,WOOD,Vector3(0,edge_y-0.11,ez),Vector3(w+1.2,0.28,0.29))
	_box(geom,WOOD,Vector3(0,edge_y-0.11,-ez),Vector3(w+1.2,0.28,0.29))
	if ornate:
		_box(geom,METAL,Vector3(0,wall_h-0.23,front_z+0.42),Vector3(2.45,0.52,0.16))
		for side in [-1.0,1.0]:
			_box(geom,RIDGE,Vector3(side*(ex-0.14),edge_y+0.1,0),Vector3(0.34,0.50,d+1.6))
	var instance := MeshInstance3D.new()
	instance.name = "BuildingVisual"
	instance.mesh = _mesh_from_buffers(geom)
	result.add_child(instance)
	# Wall collider is real, and the doorway is not blocked by an invisible full-house box.
	var solid := StaticBody3D.new()
	solid.name = "WallsCollision"
	solid.set_meta("entity_id",id)
	result.add_child(solid)
	_add_collider(solid,Vector3(0,wall_h/2,back_z),Vector3(w,wall_h,0.4))
	for sx in [-1.0,1.0]:
		_add_collider(solid,Vector3(sx*(w/2-0.16),wall_h/2,0),Vector3(0.35,wall_h,d))
		_add_collider(solid,Vector3(sx*(1.25+side_len*0.5),wall_h/2,front_z),Vector3(side_len,wall_h,0.35))
	_make_door(result,id,w,d)
	var debris := Node3D.new()
	debris.name = "CollapsedRubble"
	debris.visible = false
	result.add_child(debris)
	for j in range(9):
		var stone := MeshInstance3D.new()
		var m := BoxMesh.new()
		m.size = Vector3(0.9+float(j%3),0.26+float(j%2)*0.4,0.65+float(j%4)*0.2)
		stone.mesh = m
		stone.material_override = _materials[STONE if j%3==0 else ROOF]
		stone.position = Vector3(float(j%3-1)*1.7,0.25,float(j/3-1)*1.7)
		stone.rotation.y = float(j)*0.23
		debris.add_child(stone)
	return result

func _add_collider(parent: StaticBody3D,center: Vector3,size: Vector3) -> void:
	var shape := CollisionShape3D.new()
	var block := BoxShape3D.new()
	block.size = size
	shape.shape = block
	shape.position = center
	parent.add_child(shape)

func make_courtyard(id: String,position3d: Vector3,width: float = 37.0,
		depth: float = 35.0) -> Node3D:
	_ensure_materials()
	var walls := Node3D.new()
	walls.name = id
	walls.position = position3d
	walls.set_meta("entity_id",id)
	walls.set_meta("kind","courtyard_wall")
	var geom: Array = []
	for idx in range(_materials.size()):
		geom.append([])
	var h: float = 2.3
	var t: float = 0.3
	_box(geom,WALL,Vector3(0,h/2,-depth/2),Vector3(width,h,t))
	for side in [-1.0,1.0]:
		_box(geom,WALL,Vector3(side*width/2,h/2,0),Vector3(t,h,depth))
		_box(geom,WALL,Vector3(side*(width+4.0)/4.0,h/2,depth/2),
				Vector3(width/2-4.0,h,t))
		_box(geom,STONE,Vector3(side*2.05,0.18,depth/2),Vector3(0.55,0.45,0.9))
	_box(geom,WOOD,Vector3(0,2.67,depth/2),Vector3(5.2,0.65,1.35))
	_box(geom,ROOF,Vector3(0,3.05,depth/2),Vector3(5.7,0.21,1.9))
	_box(geom,STONE,Vector3(0,0.1,0),Vector3(width-1,0.2,depth-1))
	var visual := MeshInstance3D.new()
	visual.mesh = _mesh_from_buffers(geom)
	walls.add_child(visual)
	return walls
