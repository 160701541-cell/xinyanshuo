extends SceneTree
## Strict original-APK176 PCK replacement: real inherited Main plus Kenney
## licensed GLB source assets parsed through engine GLTFDocument at runtime.
## No standalone APK and NO automatic website publication.
const FILES := {
	"res://scenes/main.tscn.remap": "scenes/main_rev187.tscn.remap",
	"res://scenes/main_original_quality_rev187.tscn": "scenes/main_original_quality_rev187.tscn",
	"res://scripts/hd2d_original_overlay_ota177.gd": "scripts/hd2d_original_overlay_ota177.gd",
	"res://scripts/hd2d_stone_road.gd": "scripts/hd2d_stone_road.gd",
	"res://scripts/hd2d_worldx_npcs.gd": "scripts/hd2d_worldx_npcs.gd",
	"res://scripts/hd2d_house_portal.gd": "scripts/hd2d_house_portal.gd",
	"res://scripts/apk176_living_resource_world_rev187.gd": "scripts/apk176_living_resource_world_rev187.gd",
	"res://canglan_rev187/ecology_growth.gd": "canglan_rev187/ecology_growth.gd",
	"res://canglan_rev187/visual_palette.gd": "canglan_rev187/visual_palette.gd",
	"res://canglan_rev187/kenney_multimesh.gd": "canglan_rev187/kenney_multimesh.gd",
	"res://canglan_rev187/strata_terrain.gd": "canglan_rev187/strata_terrain.gd",
	"res://canglan_rev187/player_controller.gd": "canglan_rev187/player_controller.gd",
	"res://canglan_rev187/cultivation_world.gd": "canglan_rev187/cultivation_world.gd",
	"res://canglan_rev187/quality_profiles.gd": "canglan_rev187/quality_profiles.gd",
	"res://canglan_rev187/worldbox_life_sim.gd": "canglan_rev187/worldbox_life_sim.gd",
	"res://canglan_rev187/tree_oak.glb": "canglan_rev187/tree_oak.glb",
	"res://canglan_rev187/rocks_small.glb": "canglan_rev187/rocks_small.glb",
	"res://canglan_rev187/tree_log.glb": "canglan_rev187/tree_log.glb",
	"res://canglan_rev187/wood_fence.glb": "canglan_rev187/wood_fence.glb",
	"res://canglan_rev187/stone_steps.glb": "canglan_rev187/stone_steps.glb",
	"res://canglan_rev187/wood_door.glb": "canglan_rev187/wood_door.glb",
	"res://canglan_rev187/animated_knight.glb": "canglan_rev187/animated_knight.glb",
	"res://canglan_rev187/quaternius_hair_long_static.glb": "canglan_rev187/quaternius_hair_long_static.glb",
	"res://canglan_rev187/quaternius_knight_sword.glb": "canglan_rev187/quaternius_knight_sword.glb",
	# Castle Kit GLBs resolve this external palette relative to their own
	# canglan_rev187 directory. The root alias remains for old loader paths.
	"res://canglan_rev187/Textures/colormap.png": "canglan_rev187/Textures/colormap.png",
	"res://Textures/colormap.png": "Textures/colormap.png",
	"res://hd2d/atlas_village_ota177.jpg": "hd2d/atlas_village_ota177.jpg"
}

func _initialize() -> void:
	var source_dir: String = OS.get_environment("CANGLAN_OTA_STAGE_DIR")
	var destination: String = OS.get_environment("CANGLAN_QA_PCK_PATH")
	if source_dir.is_empty() or not destination.ends_with(".pck"):
		printerr("BLOCKED_REV187_INVALID_STAGE_OR_PCK_OUTPUT")
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
		printerr("BLOCKED_REV187_CANNOT_OPEN_PACK")
		quit(3)
		return
	for target in files:
		var path: String = source_dir.path_join(files[target])
		if not FileAccess.file_exists(path):
			printerr("BLOCKED_REV187_MISSING_ORIGINAL_OR_CC0_RESOURCE ", path)
			quit(4)
			return
		if writer.add_file(target, path) != OK:
			printerr("BLOCKED_REV187_FAILED_PACK_RESOURCE ", target)
			quit(5)
			return
	if writer.flush() != OK:
		printerr("BLOCKED_REV187_PCK_FLUSH_FAILED")
		quit(6)
		return
	print("PASS_APK176_REV187_LIVING_3D_AUTONOMOUS_PCK_BUILT_UNSIGNED")
	quit(0)
