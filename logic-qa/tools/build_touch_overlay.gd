extends SceneTree
## CI-only unsigned overlay smoke-test pack. NEVER publish this as an Android update.
const SOURCE := "res://scripts/touch_look_router.gd"
const TARGET := "res://scripts/touch_look_router.gd"

func _initialize() -> void:
	var out: String = OS.get_environment("CANGLAN_QA_PCK_PATH")
	if out.is_empty() or not out.ends_with(".pck"):
		printerr("FAIL: output pack path absent or malformed")
		quit(2)
		return
	var file: String = ProjectSettings.globalize_path(SOURCE)
	if not FileAccess.file_exists(file):
		printerr("FAIL: no original touch router script")
		quit(3)
		return
	var writer := PCKPacker.new()
	var result: Error = writer.pck_start(out)
	if result != OK:
		printerr("FAIL: PCK start ", result)
		quit(4)
		return
	result = writer.add_file(TARGET, file)
	if result != OK:
		printerr("FAIL: cannot add router into PCK ", result)
		quit(5)
		return
	result = writer.flush()
	if result != OK:
		printerr("FAIL: PCK flush ", result)
		quit(6)
		return
	print("PASS CANG LAN TEST PACK GENERATED (UNSIGNED, NOT FOR ANDROID RELEASE)")
	quit(0)
