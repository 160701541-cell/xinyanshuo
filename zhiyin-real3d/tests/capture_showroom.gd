extends SceneTree
func _initialize()->void:
    call_deferred("_shoot")
func _shoot()->void:
    var resource=load("res://scenes/anime_showroom.tscn") as PackedScene
    if resource==null:
        quit(2)
        return
    var stage=resource.instantiate()
    root.add_child(stage)
    for i in range(45):
        await process_frame
    await RenderingServer.frame_post_draw
    var png=root.get_texture().get_image()
    if png==null or png.is_empty() or png.save_png("res://vrm-blue-showroom-real-engine.png")!=OK:
        push_error("Godot couldn't render the actual VRM Android showroom")
        quit(3)
        return
    print("PASS REAL GODOT ANIME VRM SHOWROOM SCREENSHOT ",png.get_size())
    quit(0)
