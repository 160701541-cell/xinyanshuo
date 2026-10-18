extends SceneTree

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var out_path := "res://out/frame.png"
	var args := OS.get_cmdline_user_args()
	for i in range(args.size()):
		if args[i] == "--out" and i + 1 < args.size():
			out_path = args[i + 1]
	var scene: PackedScene = load("res://main.tscn")
	if scene == null:
		push_error("main.tscn missing")
		quit(2)
		return
	var root_node := scene.instantiate()
	root.add_child(root_node)
	for i in range(10):
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var err := img.save_png(out_path)
	print("CAPTURE_SAVED " + out_path + " err=" + str(err) + " size=" + str(img.get_width()) + "x" + str(img.get_height()))
	quit(0)
