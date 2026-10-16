extends SceneTree
## Strict original-APK176 PCK replacement: real inherited Main plus Kenney
## licensed GLB source assets parsed through engine GLTFDocument at runtime.
## No standalone APK and NO automatic website publication.
const FILES := {
	"res://scenes/main.tscn.remap": "scenes/main_rev179.tscn.remap",
	"res://scenes/main_original_3d_preview_rev179.tscn": "scenes/main_original_3d_preview_rev179.tscn",
	"res://scripts/hd2d_original_overlay_ota177.gd": "scripts/hd2d_original_overlay_ota177.gd",
	"res://scripts/hd2d_stone_road.gd": "scripts/hd2d_stone_road.gd",
	"res://scripts/hd2d_worldx_npcs.gd": "scripts/hd2d_worldx_npcs.gd",
	"res://scripts/hd2d_house_portal.gd": "scripts/hd2d_house_portal.gd",
	"res://scripts/apk176_cc0_3d_preview.gd": "scripts/apk176_cc0_3d_preview.gd",
	"res://canglan_rev179/kenney_tree_oak.glb": "canglan_rev179/kenney_tree_oak.glb",
	"res://canglan_rev179/kenney_rocks_small.glb": "canglan_rev179/kenney_rocks_small.glb",
	"res://hd2d/atlas_village_ota177.jpg": "hd2d/atlas_village_ota177.jpg"
}

func _initialize() -> void:
	var source_dir: String = OS.get_environment("CANGLAN_OTA_STAGE_DIR")
	var destination: String = OS.get_environment("CANGLAN_QA_PCK_PATH")
	if source_dir.is_empty() or not destination.ends_with(".pck"):
		printerr("BLOCKED_REV179_INVALID_STAGE_OR_PCK_OUTPUT")
		quit(2)
		return
	var files: Dictionary = FILES.duplicate()
	for i in range(8):
		for pattern in ["hd2d/worldx/nav_%03d.json", "hd2d/worldx/zones_%03d.json",
				"hd2d/worldx/worldx_%03d.png"]:
			var rel: String = pattern % i
			if FileAccess.file_exists(source_dir.path_join(rel)):
				files["res://" + rel] = rel
	for file in ["main_house_v3_source.png", "main_house_interior.png",
			"main_house_isolated_edge04.png"]:
		var rel: String = "hd2d/courtyard/" + file
		if FileAccess.file_exists(source_dir.path_join(rel)):
			files["res://" + rel] = rel
	var npc_data := "hd2d/worldx/npcs/npcs.json"
	if FileAccess.file_exists(source_dir.path_join(npc_data)):
		files["res://" + npc_data] = npc_data
		for i in range(16):
			var rel: String = "hd2d/worldx/npcs/npc_%02d.png" % i
			if FileAccess.file_exists(source_dir.path_join(rel)):
				files["res://" + rel] = rel
	var writer := PCKPacker.new()
	if writer.pck_start(destination) != OK:
		printerr("BLOCKED_REV179_CANNOT_OPEN_PACK")
		quit(3)
		return
	for target in files:
		var path: String = source_dir.path_join(files[target])
		if not FileAccess.file_exists(path):
			printerr("BLOCKED_REV179_MISSING_ORIGINAL_OR_CC0_RESOURCE ", path)
			quit(4)
			return
		if writer.add_file(target, path) != OK:
			printerr("BLOCKED_REV179_FAILED_PACK_RESOURCE ", target)
			quit(5)
			return
	if writer.flush() != OK:
		printerr("BLOCKED_REV179_PCK_FLUSH_FAILED")
		quit(6)
		return
	print("PASS_APK176_REAL_3D_CC0_PREVIEW_UNSIGN_PCK_BUILT_NO_RELEASE")
	quit(0)
