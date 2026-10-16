extends SceneTree
## Genuine original APK176 main-resource PCK, FOUR WorldX 3D surfaces.
## QA-ONLY UNAPPROVED until human visual inspection and real-device testing.
## NEVER substitute an independent APK or HD2D fullscreen overlay.
const BUILDING := "courtyard_main_hall"
const SIDE_NAMES := ["front","back","left","right"]
const RESOURCE_ROOT := "worldx3d/facades/courtyard_main_hall/"

func _initialize() -> void:
	var base: String = OS.get_environment("CANGLAN_OTA_STAGE_DIR")
	var target: String = OS.get_environment("CANGLAN_QA_PCK_PATH")
	if base.is_empty() or not target.ends_with(".pck"):
		printerr("BLOCKED_WORLDX3D: source stage and PCK target required")
		quit(2)
		return
	var mapping: Dictionary = {
		"res://scenes/main.tscn.remap":"scenes/main.tscn.remap",
		"res://scenes/main_3d_worldx_ota179.tscn":"scenes/main_3d_worldx_ota179.tscn",
		"res://scripts/worldx_four_face_3d.gd":"scripts/worldx_four_face_3d.gd",
		"res://" + RESOURCE_ROOT + "facades.json": RESOURCE_ROOT + "facades.json"}
	var manifest_path: String = base.path_join(RESOURCE_ROOT + "facades.json")
	if not FileAccess.file_exists(manifest_path):
		printerr("BLOCKED_WORLDX3D: WorldX four-face manifest missing")
		quit(3)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if not (parsed is Dictionary):
		quit(4)
		return
	if str(parsed.get("building_id","")) != BUILDING:
		quit(5)
		return
	if str(parsed.get("art_status","")) != "GENERATED_UNAPPROVED":
		printerr("BLOCKED_WORLDX3D: QA expects transparently UNAPPROVED 4-face assets")
		quit(6)
		return
	var views: Variant = parsed.get("materials",{})
	if not (views is Dictionary) or views.size() != 4:
		quit(7)
		return
	for face in SIDE_NAMES:
		if not views.has(face) or not (views[face] is Dictionary):
			quit(8)
			return
		var rel: String = str(views[face].get("file",""))
		if rel.get_file()!=rel or not rel.begins_with(face+"."):
			quit(9)
			return
		mapping["res://" + RESOURCE_ROOT + rel] = RESOURCE_ROOT + rel
	var packer := PCKPacker.new()
	if packer.pck_start(target) != OK:
		quit(10)
		return
	for destination in mapping:
		var source: String = base.path_join(mapping[destination])
		if not FileAccess.file_exists(source):
			printerr("BLOCKED_WORLDX3D missing source: ",source)
			quit(11)
			return
		if packer.add_file(destination,source) != OK:
			quit(12)
			return
	if packer.flush() != OK:
		quit(13)
		return
	print("PASS_WORLDX3D_APK176_FOUR_FACES_PACKED_NO_HD2D_QA_ONLY_OTA179")
	quit(0)
