extends SceneTree

func _initialize() -> void:
    call_deferred("_render")

func _render() -> void:
    var packed = load("res://scenes/apartment.tscn") as PackedScene
    if packed == null:
        quit(2)
        return
    root.add_child(packed.instantiate())
    for i in range(60):
        await process_frame
    await RenderingServer.frame_post_draw
    var image: Image = root.get_texture().get_image()
    if image == null or image.is_empty():
        quit(3)
        return
    if image.save_png("res://room-qa-render.png") != OK:
        quit(4)
        return
    print("PASS ACTUAL GODOT 3D FRAME ", image.get_size())
    quit(0)
