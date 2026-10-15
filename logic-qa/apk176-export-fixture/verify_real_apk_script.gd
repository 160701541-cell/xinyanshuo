extends SceneTree
## Test extracted ACTUAL signed APK176 .gdc + .gd.remap against OTA PCK.
## A real Android engine on the phone is still required for release acceptance.
func _initialize() -> void:
	var pack: String = OS.get_environment("CANGLAN_QA_PCK_PATH")
	if pack.is_empty() or not FileAccess.file_exists(pack):
		printerr("FAIL_APK176_BYTECODE: no candidate QA PCK")
		quit(2)
		return
	for path in ["res://scripts/touch_look_router.gdc", "res://scripts/touch_look_router.gd.remap"]:
		if not FileAccess.file_exists(path):
			printerr("FAIL_APK176_BYTECODE: extracted real Android resource missing: ", path)
			quit(3)
			return
	# The real exported code must be present BEFORE we mount the OTA candidate.
	if not ProjectSettings.load_resource_pack(pack, true):
		printerr("FAIL_APK176_BYTECODE: PCK mount failed")
		quit(4)
		return
	var script: GDScript = load("res://scripts/touch_look_router.gd") as GDScript
	if script == null:
		printerr("FAIL_APK176_BYTECODE: exported GDScript remap failed to resolve")
		quit(5)
		return
	var router: RefCounted = script.new()
	var viewport := Vector2(1280, 720)
	if not router.begin(2, Vector2(820, 360), viewport):
		printerr("FAIL_APK176_BYTECODE: right-hand control did not begin")
		quit(6)
		return
	if not router.begin(3, Vector2(1080, 360), viewport):
		printerr("FAIL_APK176_BYTECODE: pinch second pointer not accepted")
		quit(7)
		return
	var scale: Dictionary = router.move(3, Vector2(1190, 360))
	if scale.get("action", "") != "zoom":
		printerr("FAIL_APK176_BYTECODE: 2-finger camera zoom failed")
		quit(8)
		return
	router.end(3, Vector2(1190, 360))
	if not router.move(2, Vector2(880, 360)).is_empty():
		printerr("FAIL_APK176_BYTECODE: camera jerk from obsolete APK176 bytecode, OTA override NOT established")
		quit(9)
		return
	print("PASS CANG LAN EXPORTED APK176 GDC REMAP OVERLAID BY TEST PCK (not Android phone QA)")
	quit(0)
