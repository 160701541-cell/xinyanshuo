extends SceneTree
## Produces an UNSIGNED *candidate* PCK with an override to the ORIGINAL game's
## main scene path. Reuses original res://scripts/main.gd (compiled in APK176).
## Final phone installation is prohibited without original RSA key + QA.
const FILES := {
	"res://scenes/main.tscn.remap": "scenes/main.tscn.remap",
	"res://scenes/main_hd2d_ota177.tscn": "scenes/main_hd2d_ota177.tscn",
	"res://scripts/hd2d_original_overlay_ota177.gd": "scripts/hd2d_original_overlay_ota177.gd",
	"res://scripts/hd2d_stone_road.gd": "scripts/hd2d_stone_road.gd",
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
	var worldx_png: String = base.path_join("hd2d/worldx/worldx_000.png")
	if FileAccess.file_exists(worldx_png):
		source_list["res://hd2d/worldx/worldx_000.png"] = "hd2d/worldx/worldx_000.png"
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
	print("PASS ORIGINAL APK176 HD2D CANDIDATE PCK BUILT: FIVE OR SIX FILES, NOT SIGNED")
	quit(0)
