extends SceneTree

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    var packed=load("res://scenes/apartment.tscn") as PackedScene
    if packed==null:
        quit(2)
        return
    var scene=packed.instantiate()
    root.add_child(scene)
    await process_frame
    if scene.avatar_identity.get("identity","")!="npc_deepseek_blue":
        push_error("Can't render missing DeepSeek character")
        quit(3)
        return
    scene.camera_target=scene.avatar.position+Vector3(0,1.10,0)
    scene.camera_zoom=2.05
    scene._set_camera()
    for i in range(40):
        await process_frame
    await RenderingServer.frame_post_draw
    var image: Image=root.get_texture().get_image()
    var err=image.save_png("res://deepseek-blue-avatar-engine-portrait.png")
    if err!=OK:
        push_error("Failed saving actual game engine character portrait")
        quit(4)
        return
    print("PASS ACTUAL DEEPSEEK BLUE 3D ENGINE PORTRAIT ",image.get_size())
    quit(0)
