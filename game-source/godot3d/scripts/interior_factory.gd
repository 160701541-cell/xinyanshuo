extends RefCounted
## Runtime house interior paired with outside building's immutable entity ID.
## Real three-dimensional furniture, each a separate node/entity, not background.
var _wood: StandardMaterial3D
var _paper: StandardMaterial3D
var _stone: StandardMaterial3D

func _init() -> void:
	_wood = StandardMaterial3D.new()
	_wood.albedo_color = Color("#795a40")
	_paper = StandardMaterial3D.new()
	_paper.albedo_color = Color("#ddd0b6")
	_stone = StandardMaterial3D.new()
	_stone.albedo_color = Color("#a89f88")

func _box(parent: Node3D,part: String,center: Vector3,volume: Vector3,
		material: Material) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = volume
	var out := MeshInstance3D.new()
	out.name = part
	out.mesh = m
	out.position = center
	out.material_override = material
	parent.add_child(out)
	return out

func make_room(outside_building: Node3D,room_position: Vector3) -> Node3D:
	var id: String = String(outside_building.get_meta("entity_id"))
	var kind: String = String(outside_building.get_meta("kind"))
	var root := Node3D.new()
	root.name = "Room_" + id
	root.position = room_position
	root.set_meta("building_id",id)
	root.set_meta("kind",kind)
	root.set_meta("furniture_count",0)
	var structure := Node3D.new()
	structure.name = "RoomArchitecture"
	root.add_child(structure)
	_box(structure,"EarthFloor",Vector3(0,-0.18,0),Vector3(12.0,0.36,10.0),_wood)
	_box(structure,"RearWall",Vector3(0,2.25,-5),Vector3(12,4.5,0.25),_paper)
	_box(structure,"LeftWall",Vector3(-6,2.25,0),Vector3(0.25,4.5,10),_paper)
	_box(structure,"RightWall",Vector3(6,2.25,0),Vector3(0.25,4.5,10),_paper)
	for x in [-5.8,0.0,5.8]:
		_box(structure,"CedarColumn",Vector3(x,2.3,-4.84),Vector3(0.35,4.6,0.38),_wood)
	_box(structure,"CeilingBeam",Vector3(0,4.35,-4),Vector3(12,0.35,0.55),_wood)
	# Furniture is NOT hardwired into the architectural mesh.
	var furnishing := Node3D.new()
	furnishing.name = "IndependentFurniture"
	root.add_child(furnishing)
	var item_specs := [
		["table",Vector3(0,0,0),Vector3(2.7,0.19,1.7),_wood],
		["bed",Vector3(-3.8,0.3,-2.4),Vector3(2.5,0.6,3.1),_wood],
		["screen",Vector3(3.8,1.2,-3.3),Vector3(0.17,2.4,2.4),_wood],
		["cabinet",Vector3(4.1,0.9,0.2),Vector3(1.5,1.8,0.7),_wood],
		["bench_a",Vector3(-0.9,0.36,1.6),Vector3(1.7,0.7,0.46),_wood],
		["bench_b",Vector3(1.4,0.36,1.6),Vector3(1.7,0.7,0.46),_wood],
		["storage",Vector3(-4.3,0.5,3.5),Vector3(1.5,1,0.8),_stone],
		["jar",Vector3(4.45,0.6,3.4),Vector3(0.7,1.2,0.7),_stone]
	]
	var count := 0
	for spec in item_specs:
		var item := Node3D.new()
		item.name = id + "-ITEM-%03d" % (count+1)
		item.set_meta("entity_id",item.name)
		item.set_meta("kind",spec[0])
		furnishing.add_child(item)
		_box(item,"Visible3DGeometry",spec[1],spec[2],spec[3])
		count += 1
	root.set_meta("furniture_count",count)
	return root
