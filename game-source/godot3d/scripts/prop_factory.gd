extends Node3D
## Batches hundreds of independent world-entity IDs using Godot MultiMesh.
## Visual batching is NOT the authoritative economy or inventory registry.
var entities: Dictionary = {}
var rendered_instances: int = 0
var _groups: Dictionary = {}
var _meshes: Dictionary = {}
var _material: StandardMaterial3D

func _ready() -> void:
	_material = StandardMaterial3D.new()
	_material.albedo_color = Color.WHITE
	_material.roughness = 0.98
	_make_meshes()

func _make_meshes() -> void:
	var box := BoxMesh.new()
	box.size = Vector3.ONE
	_meshes["trunk"] = box
	_meshes["lantern"] = box
	_meshes["crops"] = box
	var canopy := SphereMesh.new()
	canopy.radius = 0.65
	canopy.height = 1.3
	canopy.radial_segments = 9
	canopy.rings = 5
	_meshes["canopy"] = canopy
	var rock := SphereMesh.new()
	rock.radius = 0.6
	rock.height = 1.2
	rock.radial_segments = 7
	rock.rings = 3
	_meshes["rock"] = rock
	var barrel := CylinderMesh.new()
	barrel.top_radius = 0.5
	barrel.bottom_radius = 0.53
	barrel.height = 1.0
	_meshes["barrel"] = barrel

func _add_instance(kind: String,at: Vector3,scale3: Vector3,tint: Color) -> void:
	if not _groups.has(kind):
		_groups[kind] = []
	var group: Array = _groups[kind]
	group.append({"at":at,"scale":scale3,"color":tint})

func _entity(id: String,kind: String,at: Vector3) -> void:
	assert(not entities.has(id),"Duplicate visual entity identifier")
	entities[id] = {"id":id,"kind":kind,"position":[at.x,at.y,at.z],
		"owner_id":"","season":0,"age":2,"damaged":false}

func build(rules: RefCounted,seed: int) -> void:
	for old in get_children():
		old.queue_free()
	entities.clear()
	_groups.clear()
	rendered_instances = 0
	var random := RandomNumberGenerator.new()
	random.seed = seed + 900719
	# Hillsides with deterministic tree distribution; never spawn beneath buildings.
	for i in range(480):
		var x: float = random.randf_range(-355.0,355.0)
		var z: float = random.randf_range(-355.0,355.0)
		if absf(x)<151.0 and absf(z)<140.0:
			continue
		if bool(rules.call("is_river",x,z)):
			continue
		var y: float = float(rules.call("height_at",x,z))
		var a := Vector3(x,y,z)
		var age: int = random.randi_range(0,2)
		var growth: float = [0.55,0.85,1.25][age]
		var id: String = "SM-HX-%08d" % (i+1)
		_entity(id,"living_tree",a)
		entities[id]["age"] = age
		_add_instance("trunk",a+Vector3(0,growth*1.6,0),
			Vector3(0.55*growth,3.2*growth,0.55*growth),Color("#62462f"))
		var foliage := Color("#5b8158") if i%3 else Color("#79936c")
		_add_instance("canopy",a+Vector3(0,3.9*growth,0),
			Vector3(2.4*growth,2.0*growth,2.4*growth),foliage)
	for i in range(170):
		var x: float = random.randf_range(-360.0,360.0)
		var z: float = random.randf_range(-360.0,360.0)
		if absf(x)<146.0 and absf(z)<133.0:
			continue
		var y: float = float(rules.call("height_at",x,z))
		var p := Vector3(x,y,z)
		_entity("ST-HX-%08d" % (i+1),"stone",p)
		_add_instance("rock",p+Vector3(0,0.26,0),
			Vector3(random.randf_range(0.7,2.1),random.randf_range(0.4,1.3),1.0),Color("#8c918a"))
	# Each courtyard gets multiple separately indexed items, all visually batched.
	for row in range(4):
		for col in range(5):
			var cx: float = float(col-2)*54.0
			var cz: float = float(row)*65.0-92.0
			var index: int = row*5+col
			for side in [-1,1]:
				var lp := Vector3(cx+float(side)*17.0,0.0,cz+18.5)
				var id := "DL-HX-%08d" % (index*2+(side+1)/2+1)
				_entity(id,"lantern",lp)
				_add_instance("trunk",lp+Vector3(0,2.05,0),
					Vector3(0.10,4.1,0.10),Color("#63513c"))
				_add_instance("lantern",lp+Vector3(0,3.35,0),
					Vector3(0.56,0.72,0.52),Color("#b76b48"))
			var water := Vector3(cx+8,0.3,cz+1)
			_entity("JT-HX-%08d" % (index+1),"well",water)
			_add_instance("barrel",water,Vector3(2.9,0.55,2.9),Color("#a2a294"))
			var jar := Vector3(cx-9,0.45,cz+11)
			_entity("GT-HX-%08d" % (index+1),"ceramic_pot",jar)
			_add_instance("barrel",jar,Vector3(0.82,0.94,0.82),Color("#78664b"))
			for j in range(7):
				var crop_x := cx+float(j-3)*3.0
				var cp := Vector3(crop_x,0.1,cz-14.0)
				if (col+row)%3==0:
					_entity("ZW-HX-%02d-%02d" % [index,j],"plant",cp)
					_add_instance("crops",cp+Vector3(0,0.28,0),
						Vector3(0.19,0.55,1.5),Color("#7c9b5f"))
	# Every instance shares one source mesh and material to control draw calls.
	for key in _groups.keys():
		var records: Array = _groups[key]
		if records.is_empty():
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = _meshes[key]
		mm.instance_count = records.size()
		for i in range(records.size()):
			var record: Dictionary = records[i]
			var transform := Transform3D(Basis.IDENTITY.scaled(record["scale"]),record["at"])
			mm.set_instance_transform(i,transform)
			mm.set_instance_color(i,record["color"])
		var instance := MultiMeshInstance3D.new()
		instance.name = "Batched_" + String(key)
		instance.multimesh = mm
		instance.material_override = _material
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if key=="crops" else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		add_child(instance)
		rendered_instances += records.size()

func stats() -> Dictionary:
	return {"independent_prop_ids":entities.size(),"multimesh_draw_groups":_groups.size(),
			"visible_mesh_instances":rendered_instances}
