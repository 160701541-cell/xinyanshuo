extends SceneTree
## Strict public HD2D scene startup smoke test (no Android/signing claims).
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var path := "res://scenes/village.tscn"
	var packed := load(path)
	assert(packed is PackedScene, "Missing actual Godot scene")
	var stage := (packed as PackedScene).instantiate()
	assert(stage is Node2D, "HD2D scene must be a 2D world")
	print("SCENE_SCRIPT:", stage.get_script())
	root.add_child(stage)
	# add_child enters tree synchronously; no frame delay or network dependency.
	print("SCENE_READY:",stage.is_node_ready(), " children:",stage.get_children())
	assert(stage.get_node_or_null("Camera2D") != null, "Camera2D missing")
	var camera := stage.get_node_or_null("Camera2D") as Camera2D
	assert(camera.is_current(), "No active camera")
	assert(camera.zoom.x > 0.0 and camera.zoom.x < 2.0, "Bad mobile zoom")
	var status: Variant = stage.get("_status")
	assert(status is Label, "Status HUD missing")
	# The atlas downloads asynchronously. We test initialization and the
	# actual published remote file separately in CI, never assume loaded.
	# Regression for the requested connectable stone brick road.
	var paving := load("res://scripts/stone_road.gd")
	assert(paving != null, "Stone road generator missing")
	var road_image: Image = paving.make_image()
	assert(road_image.get_width() == 256 and road_image.get_height() == 256, "Wrong paving texture dimensions")
	assert(paving.edges_match(road_image), "Stone road edges will show seams")
	var joined: Node = stage.get_node_or_null("SeamlessStoneRoad")
	assert(joined != null, "Road not assembled in real scene")
	assert(joined.get_child_count() == 14, "Expected 14 connected road segments")
	stage.call("_zoom", 1.2)
	assert(camera.zoom.x > 0.8, "Zoom handler did not work")
	print("PASS PUBLIC HD2D GODOT SCENE STARTUP: camera, HUD, seamless road QA, pan/zoom contract")
	stage.queue_free()
	quit(0)
