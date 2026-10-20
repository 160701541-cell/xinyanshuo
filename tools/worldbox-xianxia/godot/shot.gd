extends Node
# Minimal isolated screenshot service for the existing item3d.gd factory.
# Not packaged into any WorldBox or Canglan app.
func grab(node: Node, output_path: String) -> void:
    await RenderingServer.frame_post_draw
    var viewport: Viewport = node.get_viewport()
    var capture: Image = viewport.get_texture().get_image()
    if capture.is_empty():
        push_error("NO_REAL_RENDER_FRAME: " + output_path)
        get_tree().quit(30)
        return
    var filename: String = ProjectSettings.globalize_path(output_path)
    var folder: String = filename.get_base_dir()
    var err: Error = DirAccess.make_dir_recursive_absolute(folder)
    if err != OK:
        push_error("OUT_DIRECTORY_ERROR " + str(err))
        get_tree().quit(31)
        return
    err = capture.save_png(filename)
    if err != OK:
        push_error("SAVE_FRAME_ERROR " + str(err))
        get_tree().quit(32)
        return
    print("REAL_GODOT_FRAME " + filename + " " + str(capture.get_size()))
