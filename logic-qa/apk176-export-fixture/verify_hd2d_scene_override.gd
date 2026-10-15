extends SceneTree
## Loaded from the PUBLIC APK176 exported-assets QA fixture.
## The fixture includes real exported main.gdc and Godot .remap.
## A resource test does NOT claim full 3D world/Android-phone validation.
func _initialize() -> void:
	var path := OS.get_environment("CANGLAN_QA_PCK_PATH")
	if path.is_empty() or not FileAccess.file_exists(path):
		printerr("FAIL: no HD2D candidate")
		quit(2)
		return
	if not ProjectSettings.load_resource_pack(path, true):
		printerr("FAIL: real PCK failed to mount")
		quit(3)
		return
	for resource in ["res://scenes/main.tscn.remap", "res://scenes/main_hd2d_ota177.tscn",
			"res://scripts/hd2d_original_overlay_ota177.gd",
			"res://hd2d/atlas_village_ota177.jpg"]:
		if not FileAccess.file_exists(resource):
			printerr("FAIL: candidate missing ",resource)
			quit(4)
			return
	var main_remap := FileAccess.get_file_as_string("res://scenes/main.tscn.remap")
	if not main_remap.contains("main_hd2d_ota177.tscn"):
		printerr("FAIL: original scene entrypoint did not point to new scene")
		quit(5)
		return
	# The real installed client loads the canonical path. A versioned scene
	# that loads by itself proves nothing unless the OLD path is redirected.
	var scene := ResourceLoader.load("res://scenes/main.tscn") as PackedScene
	if scene == null:
		printerr("FAIL: live overlay scene cannot be loaded with APK176 compiled script")
		quit(6)
		return
	print("PASS_APK176_HD2D_OVERLAY_MOUNT_AND_CANONICAL_MAIN_SCENE (NOT PHONE QA)")
	quit(0)
