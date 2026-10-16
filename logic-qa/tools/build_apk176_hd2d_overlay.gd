extends SceneTree
## Produces an UNSIGNED *candidate* PCK with an override to the ORIGINAL game's
## main scene path. Reuses original res://scripts/main.gd (compiled in APK176).
## Final phone installation is prohibited without original RSA key + QA.
const FILES := {
	"res://scenes/main.tscn.remap": "scenes/main.tscn.remap",
	"res://scenes/main_hd2d_ota177.tscn": "scenes/main_hd2d_ota177.tscn",
	"res://scripts/hd2d_original_overlay_ota177.gd": "scripts/hd2d_original_overlay_ota177.gd",
	"res://scripts/hd2d_stone_road.gd": "scripts/hd2d_stone_road.gd",
	"res://scripts/hd2d_worldx_npcs.gd": "scripts/hd2d_worldx_npcs.gd",
	"res://scripts/hd2d_house_portal.gd": "scripts/hd2d_house_portal.gd",
	"res://hd2d/atlas_village_ota177.jpg": "hd2d/atlas_village_ota177.jpg"
}

func _initialize() -> void:
	var base: String = OS.get_environment("CANGLAN_OTA_STAGE_DIR")
	var output: String = OS.get_environment("CANGLAN_QA_PCK_PATH")
	if base.is_empty() or not output.ends_with(".pck"):
		printerr("BLOCKED: candidate staging and output are required")
		quit(2)
		return
	var writer := PCKPacker.new()
	if writer.pck_start(output) != OK:
		printerr("BLOCKED: cannot create PCK")
		quit(3)
		return
	var source_list: Dictionary = FILES.duplicate()
	for i in range(8):
		var nav_rel: String = "hd2d/worldx/nav_%03d.json" % i
		if FileAccess.file_exists(base.path_join(nav_rel)):
			source_list["res://" + nav_rel] = nav_rel
		var zone_rel: String = "hd2d/worldx/zones_%03d.json" % i
		if FileAccess.file_exists(base.path_join(zone_rel)):
			source_list["res://" + zone_rel] = zone_rel
		var rel: String = "hd2d/worldx/worldx_%03d.png" % i
		if FileAccess.file_exists(base.path_join(rel)):
			source_list["res://" + rel] = rel
	for file in ["main_house_v3_source.png", "main_house_interior.png"]:
		var rel: String = "hd2d/courtyard/" + file
		if FileAccess.file_exists(base.path_join(rel)):
			source_list["res://" + rel] = rel
	var npc_manifest: String = base.path_join("hd2d/worldx/npcs/npcs.json")
	if FileAccess.file_exists(npc_manifest):
		source_list["res://hd2d/worldx/npcs/npcs.json"] = "hd2d/worldx/npcs/npcs.json"
		for i in range(16):
			var rel: String = "hd2d/worldx/npcs/npc_%02d.png" % i
			if FileAccess.file_exists(base.path_join(rel)):
				source_list["res://" + rel] = rel
	for target in source_list:
		var src: String = base.path_join(source_list[target])
		if not FileAccess.file_exists(src):
			printerr("BLOCKED: missing OTA asset ", src)
			quit(4)
			return
		var err: Error = writer.add_file(target, src)
		if err != OK:
			printerr("BLOCKED: PCK pack file ", target, " error ", err)
			quit(5)
			return
	if writer.flush() != OK:
		printerr("BLOCKED: PCK flush failed")
		quit(6)
		return
	print("PASS ORIGINAL APK176 HD2D CANDIDATE PCK BUILT: REAL WORLDX RASTER AND NPC ASSETS, NOT SIGNED")
	quit(0)
