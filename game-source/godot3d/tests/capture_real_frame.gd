extends SceneTree
## A real engine framebuffer, never a simulated mockup or concept render.
func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var stage: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(stage)
	var viewport: Viewport = root
	var camera: Camera3D = stage.get_node("Follow3DCamera")
	var avatar: CharacterBody3D = stage.get_node("PlayerWithCollision")
	avatar.position = Vector3(12,2,43)
	stage.set("_yaw",0.18)
	stage.set("_pitch",0.77)
	stage.set("_distance",39.0)
	stage.call("_update_camera",1.0)
	camera.far = 325.0
	# Wait until the renderer has completed the main world draw.
	for i in range(8):
		await process_frame
	await RenderingServer.frame_post_draw
	var img: Image = viewport.get_texture().get_image()
	if img == null or img.is_empty() or img.get_width()<1000 or img.get_height()<600:
		printerr("VISUAL_QA_BLOCKED: no authentic Godot rendered framebuffer")
		quit(2)
		return
	var samples: Dictionary = {}
	for y in range(40,img.get_height()-40,21):
		for x in range(40,img.get_width()-40,21):
			var color: Color = img.get_pixel(x,y)
			var packed: int = (int(color.r8/16)<<8)+(int(color.g8/16)<<4)+int(color.b8/16)
			samples[packed] = true
	if samples.size() < 20:
		printerr("VISUAL_QA_BLOCKED: near-uniform frame; not an actual world screenshot")
		quit(3)
		return
	var output := OS.get_environment("CANGLAN_3D_SCREENSHOT")
	if output.is_empty():
		output = "user://real_canglan_3d_scene.png"
	var err: Error = img.save_png(output)
	if err != OK:
		printerr("VISUAL_QA_BLOCKED: screenshot save failed: ",err)
		quit(4)
		return
	print("PASS REAL GODOT 3D FRAME CAPTURE: ",output," dimensions=",
			img.get_width(),"x",img.get_height()," color_bins=",samples.size(),
			" / VISUAL ARTISTIC APPROVAL STILL REQUIRED")
	stage.queue_free()
	quit(0)
