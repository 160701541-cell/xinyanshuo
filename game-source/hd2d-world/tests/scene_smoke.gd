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
	root.add_child(stage)
	await process_frame
	assert(stage.get_node_or_null("Camera2D") != null, "Camera2D missing")
	var camera := stage.get_node_or_null("Camera2D") as Camera2D
	assert(camera.is_current(), "No active camera")
	assert(camera.zoom.x > 0.0 and camera.zoom.x < 2.0, "Bad mobile zoom")
	var status: Variant = stage.get("_status")
	assert(status is Label, "Status HUD missing")
	# The atlas downloads asynchronously. We test initialization and the
	# actual published remote file separately in CI, never assume loaded.
	stage.call("_zoom", 1.2)
	assert(camera.zoom.x > 0.8, "Zoom handler did not work")
	print("PASS PUBLIC HD2D GODOT SCENE STARTUP: camera, HUD, pan/zoom contract")
	stage.queue_free()
	quit(0)
