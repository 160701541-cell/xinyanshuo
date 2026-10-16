extends Node3D
## Genuine 3D building: WorldX's four individually authored directional wall images
## are mapped to four physical faces. Real collision, doorway and pitched roof.
## NO fullscreen 2D map, Sprite2D backdrop, HD2D camera or new APK.
## Source candidates are NOT considered visually approved without manual review.

const ROOT := "res://worldx3d/facades/courtyard_main_hall/"
const BUILDING_ID := "CL-WORLDX-3D-MAINHALL-001"
const FACINGS := ["front","back","left","right"]
const ROOF_COLOR := Color(0.25,0.36,0.38)
const WOOD_COLOR := Color(0.35,0.23,0.16)
const STONE_COLOR := Color(0.53,0.55,0.52)
@export var allow_unapproved_preview: bool = false
@export var spawn_next_to_player: bool = true

var _available := false
var _house: Node3D
var _door_hinge: Node3D
var _door_is_open := false
var _facade_layers: Dictionary = {}

func _ready() -> void:
	name = "WorldXFourFacades3D"
	available_setup()
	if _available and spawn_next_to_player:
		_place_next_to_original_avatar()

func available_setup() -> bool:
	var manifest_path: String = ROOT + "facades.json"
	if not FileAccess.file_exists(manifest_path):
		set_meta("art_status","FOUR_WORLDX_FACADES_PENDING")
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if not (parsed is Dictionary):
		push_error("WorldX 3D facades.json invalid")
		return false
	var manifest: Dictionary = parsed
	if str(manifest.get("building_id","")) != "courtyard_main_hall":
		push_error("WorldX 3D wrong building identity")
		return false
	var status: String = str(manifest.get("art_status",""))
	if status != "APPROVED_FOR_3D" and not allow_unapproved_preview:
		set_meta("art_status","FOUR_WORLDX_FACADES_AWAITING_VISUAL_QA")
		return false
	var mapping: Variant = manifest.get("materials",{})
	if not (mapping is Dictionary):
		return false
	var images: Dictionary = {}
	for side in FACINGS:
		if not mapping.has(side):
			push_error("WorldX 3D missing side: " + side)
			return false
		var info: Variant = mapping[side]
		if not (info is Dictionary):
			return false
		var filename: String = str(info.get("file",""))
		if filename.get_base_dir() != "." or not filename.begins_with(side+"."):
			push_error("WorldX 3D invalid facade relative filename: " + filename)
			return false
		var path: String = ROOT + filename
		if not FileAccess.file_exists(path):
			push_error("WorldX 3D missing texture: " + path)
			return false
		var raw: PackedByteArray = FileAccess.get_file_as_bytes(path)
		if raw.size() < 25000:
			push_error("WorldX 3D invalid texture bytes: " + side)
			return false
		var actual_hash: String = raw.sha256_buffer().hex_encode()
		if actual_hash != str(info.get("sha256","")):
			push_error("WorldX 3D invalid SHA256: " + side)
			return false
		var image := Image.new()
		var error_code: Error = OK
		if filename.ends_with(".png"):
			error_code = image.load_png_from_buffer(raw)
		elif filename.ends_with(".jpg") or filename.ends_with(".jpeg"):
			error_code = image.load_jpg_from_buffer(raw)
		else:
			return false
		if error_code != OK or image.get_width() < 768 or image.get_height() < 768:
			push_error("WorldX 3D image decode failed: " + side)
			return false
		images[side] = ImageTexture.create_from_image(image)
	if images.size() != 4:
		return false
	_build_true_3d_building(images)
	_available = true
	set_meta("entity_id",BUILDING_ID)
	set_meta("art_status","WORLDX_FOUR_VIEW_3D_PREVIEW" if allow_unapproved_preview else "WORLDX_FOUR_VIEW_APPROVED")
	set_meta("facade_count",4)
	set_meta("not_hd2d",true)
	return true

func _mat(base: Color, texture: Texture2D = null) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.roughness = 0.91
	material.albedo_color = base
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	if texture != null:
		material.albedo_texture = texture
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return material

func _quad(material: StandardMaterial3D, label: String, a: Vector3,
		b: Vector3, c: Vector3, d: Vector3, from_uv: Vector2 = Vector2.ZERO,
		to_uv: Vector2 = Vector2.ONE) -> MeshInstance3D:
	var surface := ArrayMesh.new()
	var vertices := PackedVector3Array([a,b,c,a,c,d])
	var uv := PackedVector2Array([
		Vector2(from_uv.x,to_uv.y),Vector2(to_uv.x,to_uv.y),
		Vector2(to_uv.x,from_uv.y),Vector2(from_uv.x,to_uv.y),
		Vector2(to_uv.x,from_uv.y),Vector2(from_uv.x,from_uv.y)])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uv
	surface.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	surface.surface_set_material(0,material)
	var mesh := MeshInstance3D.new()
	mesh.name = label
	mesh.mesh = surface
	_house.add_child(mesh)
	return mesh

func _box(label: String, centre: Vector3, dimensions: Vector3,
		color: Color, collision: bool = false) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = label
	var box := BoxMesh.new()
	box.size = dimensions
	mesh.mesh = box
	mesh.material_override = _mat(color)
	mesh.position = centre
	_house.add_child(mesh)
	if collision:
		var body := StaticBody3D.new()
		body.name = label+"Body"
		body.position = centre
		var shape := CollisionShape3D.new()
		var collision_box := BoxShape3D.new()
		collision_box.size = dimensions
		shape.shape = collision_box
		body.add_child(shape)
		_house.add_child(body)

func _build_true_3d_building(images: Dictionary) -> void:
	_house = Node3D.new()
	_house.name = "WorldXPhysical3DBuilding"
	add_child(_house)
	var w := 10.0
	var d := 7.0
	var h := 4.0
	var fx := w * 0.5
	var fz := d * 0.5
	var door_half := 1.2
	var door_top := 2.65
	_box("PhysicalStoneFoundation",Vector3(0,0.10,0),
		Vector3(w+0.5,0.23,d+0.5),STONE_COLOR,true)
	var front: StandardMaterial3D = _mat(Color.WHITE,images["front"])
	var back: StandardMaterial3D = _mat(Color.WHITE,images["back"])
	var left: StandardMaterial3D = _mat(Color.WHITE,images["left"])
	var right: StandardMaterial3D = _mat(Color.WHITE,images["right"])
	var zl := fz+0.04
	# The front picture is UV-cut into three actual 3D surfaces so the original
	# interactive doorway is NOT painted over by a solid flat billboard.
	_quad(front,"SouthFrontLeft",Vector3(-fx,0,zl),Vector3(-door_half,0,zl),
		Vector3(-door_half,h,zl),Vector3(-fx,h,zl),
		Vector2.ZERO,Vector2((fx-door_half)/w,1))
	_quad(front,"SouthFrontRight",Vector3(door_half,0,zl),Vector3(fx,0,zl),
		Vector3(fx,h,zl),Vector3(door_half,h,zl),
		Vector2((fx+door_half)/w,0),Vector2.ONE)
	_quad(front,"SouthDoorOverhead",Vector3(-door_half,door_top,zl),
		Vector3(door_half,door_top,zl),Vector3(door_half,h,zl),
		Vector3(-door_half,h,zl),Vector2((fx-door_half)/w,0),
		Vector2((fx+door_half)/w,(h-door_top)/h))
	_quad(back,"NorthBack",Vector3(fx,0,-fz-0.04),Vector3(-fx,0,-fz-0.04),
		Vector3(-fx,h,-fz-0.04),Vector3(fx,h,-fz-0.04))
	_quad(left,"WestLeft",Vector3(-fx-0.04,0,fz),Vector3(-fx-0.04,0,-fz),
		Vector3(-fx-0.04,h,-fz),Vector3(-fx-0.04,h,fz))
	_quad(right,"EastRight",Vector3(fx+0.04,0,-fz),Vector3(fx+0.04,0,fz),
		Vector3(fx+0.04,h,fz),Vector3(fx+0.04,h,-fz))
	_facade_layers = {
		"front":get_node("WorldXPhysical3DBuilding/SouthFrontLeft"),
		"back":get_node("WorldXPhysical3DBuilding/NorthBack"),
		"left":get_node("WorldXPhysical3DBuilding/WestLeft"),
		"right":get_node("WorldXPhysical3DBuilding/EastRight")}
	# Real 3D volume and passable central door, independent of 2D image pixels.
	_box("RearWallCollision",Vector3(0,h/2,-fz),Vector3(w,h,0.28),STONE_COLOR,true)
	_box("WestWallCollision",Vector3(-fx,h/2,0),Vector3(0.28,h,d),STONE_COLOR,true)
	_box("EastWallCollision",Vector3(fx,h/2,0),Vector3(0.28,h,d),STONE_COLOR,true)
	_box("SouthLeftCollision",Vector3((-fx-door_half)/2,h/2,fz),
		Vector3(fx-door_half,h,0.28),WOOD_COLOR,true)
	_box("SouthRightCollision",Vector3((fx+door_half)/2,h/2,fz),
		Vector3(fx-door_half,h,0.28),WOOD_COLOR,true)
	_box("SouthDoorLintelCollision",Vector3(0,(h+door_top)/2,fz),
		Vector3(door_half*2,h-door_top,0.28),WOOD_COLOR,true)
	# Real pitched roof (two sloping 3D meshes), not a fake roof drawn on map.
	var ridge := h+1.9
	var eave := h+0.16
	_quad(_mat(ROOF_COLOR),"NorthTiledRoof",Vector3(-fx-0.6,eave,-fz-0.7),
		Vector3(fx+0.6,eave,-fz-0.7),Vector3(fx+0.6,ridge,0),
		Vector3(-fx-0.6,ridge,0))
	_quad(_mat(ROOF_COLOR),"SouthTiledRoof",Vector3(-fx-0.6,ridge,0),
		Vector3(fx+0.6,ridge,0),Vector3(fx+0.6,eave,fz+0.7),
		Vector3(-fx-0.6,eave,fz+0.7))
	_box("RoofRidge",Vector3(0,ridge+0.045,0),
		Vector3(w+1.2,0.17,0.22),STONE_COLOR,false)
	_door_hinge = Node3D.new()
	_door_hinge.name = "DoorHinge"
	_door_hinge.position = Vector3(-door_half,0,fz+0.18)
	_house.add_child(_door_hinge)
	var leaf := MeshInstance3D.new()
	leaf.name = "PhysicalOpeningDoor"
	var leaf_mesh := BoxMesh.new()
	leaf_mesh.size = Vector3(door_half*2,door_top-0.1,0.12)
	leaf.mesh = leaf_mesh
	leaf.position = Vector3(door_half,(door_top-0.1)/2,0)
	leaf.material_override = _mat(WOOD_COLOR)
	_door_hinge.add_child(leaf)

func toggle_door() -> bool:
	if _door_hinge == null:
		return false
	_door_is_open = not _door_is_open
	_door_hinge.rotation.y = -PI/2.0 if _door_is_open else 0.0
	_door_hinge.set_meta("open",_door_is_open)
	return _door_is_open

func facade_count() -> int:
	return _facade_layers.size()

func _place_next_to_original_avatar() -> void:
	var root: Node = get_tree().current_scene
	if root == null:
		root = get_tree().root
	var potential: Array[Node] = root.find_children("*","CharacterBody3D",true,false)
	for node in potential:
		if node is CharacterBody3D and not is_ancestor_of(node):
			var origin: Vector3 = (node as CharacterBody3D).global_position
			global_position = Vector3(origin.x+19.0,origin.y,origin.z+4.0)
			return
