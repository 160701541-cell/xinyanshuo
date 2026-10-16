extends SceneTree
## Run in REAL Godot 4.4, with the candidate original-package PCK mounted.
## Does not mistake 2D background images for 3D geometry or sign a release.
func _initialize() -> void:
	call_deferred("_check")

func _die(why: String,number: int) -> void:
	printerr("FAIL_APK176_WORLDX3D_FOUR_FACE ",why)
	quit(number)

func _check() -> void:
	var pack: String = OS.get_environment("CANGLAN_QA_PCK_PATH")
	if pack.is_empty() or not FileAccess.file_exists(pack):
		_die("PCK_MISSING",2)
		return
	if not ProjectSettings.load_resource_pack(pack,true):
		_die("PCK_MOUNT_FAIL",3)
		return
	if FileAccess.file_exists("res://scripts/hd2d_original_overlay_ota177.gd"):
		print("INFORMATIONAL: old installed HD2D script still exists in base; new scene must not instantiate it")
	var script: Script = load("res://scripts/worldx_four_face_3d.gd")
	if script == null:
		_die("SCRIPT_UNAVAILABLE",4)
		return
	var model: Node3D = script.new()
	model.set("allow_unapproved_preview",true)
	model.set("spawn_next_to_player",false)
	get_root().add_child(model)
	await process_frame
	await process_frame
	if int(model.call("facade_count")) != 4:
		_die("NOT_FOUR_INDEPENDENT_WORLDX_TEXTURES",5)
		return
	if model.get_node_or_null("WorldXPhysical3DBuilding/SouthFrontLeft") == null:
		_die("PHYSICAL_FRONT_GEOMETRY_MISSING",6)
		return
	for side_path in ["SouthFrontLeft","NorthBack","WestLeft","EastRight"]:
		var part: MeshInstance3D = model.get_node_or_null("WorldXPhysical3DBuilding/"+side_path)
		if part == null or part.mesh == null:
			_die("3D_MESH_MISSING_"+side_path,7)
			return
		var face_mat: StandardMaterial3D = part.mesh.surface_get_material(0)
		if face_mat == null or face_mat.albedo_texture == null:
			_die("REAL_WORLDX_IMAGE_TEXTURE_NOT_MAPPED_"+side_path,8)
			return
	if model.get_node_or_null("WorldXPhysical3DBuilding/SouthDoorOverhead") == null:
		_die("PASSABLE_CENTER_DOOR_HEADER_MISSING",9)
		return
	if model.get_node_or_null("WorldXPhysical3DBuilding/NorthTiledRoof") == null:
		_die("3D_PITCHED_ROOF_NOT_PRESENT",10)
		return
	if model.get_node_or_null("WorldXPhysical3DBuilding/RearWallCollisionBody") == null:
		_die("PHYSICAL_WALL_COLLISION_MISSING",11)
		return
	if model.get_node_or_null("WorldXPhysical3DBuilding/DoorHinge") == null:
		_die("HINGED_DOOR_NOT_PRESENT",12)
		return
	if not bool(model.call("toggle_door")):
		_die("DOOR_COULD_NOT_OPEN",13)
		return
	if bool(model.call("toggle_door")):
		_die("DOOR_COULD_NOT_CLOSE",14)
		return
	assert(not model.has_node("HD2DArtAcceptance"),
		"Reintroducing HD2D full-screen overlay is a P0 release blocker")
	assert(str(model.get_meta("art_status",""))=="WORLDX_FOUR_VIEW_3D_PREVIEW")
	print("PASS_WORLDX_ORIGINAL_APK176_TRUE_3D_QUADS_4_DIRECTIONS_ROOF_COLLIDERS_HINGED_DOOR")
	quit(0)
