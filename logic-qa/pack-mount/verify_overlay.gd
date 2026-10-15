extends SceneTree
## Mount in an EMPTY independent project. Confirms bytes are in the PCK,
## rather than accidentally loading loose files from the sandbox project.
func _initialize() -> void:
	var pack: String = OS.get_environment("CANGLAN_QA_PCK_PATH")
	if pack.is_empty() or not FileAccess.file_exists(pack):
		printerr("FAIL_OVERLAY: PCK file absent")
		quit(2)
		return
	# The installed/base project deliberately has a stale implementation.
	# No ResourceLoader.load() before mounting: production UpdateMount also
	# loads the signed pack during autoload initialization.
	if not FileAccess.file_exists("res://scripts/touch_look_router.gd"):
		printerr("FAIL_OVERLAY: missing deliberately stale base fixture")
		quit(3)
		return
	if not ProjectSettings.load_resource_pack(pack, true):
		printerr("FAIL_OVERLAY: load_resource_pack returned false")
		quit(4)
		return
	var scene_script: GDScript = load("res://scripts/touch_look_router.gd") as GDScript
	if scene_script == null:
		printerr("FAIL_OVERLAY: packed script not loadable")
		quit(5)
		return
	var router: RefCounted = scene_script.new()
	if not router.begin(8, Vector2(1000, 400), Vector2(1280, 720)):
		printerr("FAIL_OVERLAY: right touch did not route")
		quit(6)
		return
	if router.move(8, Vector2(1100, 460)).get("action", "") != "look":
		printerr("FAIL_OVERLAY: mounted script did not produce expected look")
		quit(7)
		return
	print("PASS CANG LAN TEST PCK OVERRIDES STALE BASE SCRIPT (UNSIGNED QA, NOT APK INTEROP)")
	quit(0)
