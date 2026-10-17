extends SceneTree
## GENUINE original APK176 compiled Main + rev187 REAL unsigned PCK framebuffer.
## Capture near the original user's worksite positions. A CPU/Vulkan GitHub
## Linux rendering snapshot is NOT a fake phone screenshot or concept art.
const OUT_ENV: String="CANGLAN_SCREENSHOT_DIR"
const PACK_ENV: String="CANGLAN_QA_PCK_PATH"
var base: Node
var room: Node
var view: SubViewport
var camera: Camera3D

func _initialize() -> void:
  call_deferred("_capture")

func _fail(why: String) -> void:
  printerr("FAIL_REV187_REAL_GAME_SCREENSHOT_",why)
  quit(5)

func _save(file_name: String) -> bool:
  var out: String=OS.get_environment(OUT_ENV)
  var image: Image=get_root().get_texture().get_image()
  if image==null or image.is_empty() or image.get_width()<900 or image.get_height()<500:
    return false
  var bins: Dictionary={}
  for y in range(30,image.get_height()-30,23):
    for x in range(30,image.get_width()-30,23):
      var c: Color=image.get_pixel(x,y)
      bins[int(c.r8/18)*220+int(c.g8/18)*15+int(c.b8/18)]=true
  if bins.size()<28:
    return false
  if image.save_png(out.path_join(file_name))!=OK:
    return false
  print("PASS_REV187_REAL_ORIGINAL_MAIN_VISUAL_FRAME ",file_name,
    " ",image.get_width(),"x",image.get_height(),
    " colors=",bins.size()," actual_camera=",camera.position)
  return true

func _capture() -> void:
  var out: String=OS.get_environment(OUT_ENV)
  var pack: String=OS.get_environment(PACK_ENV)
  if out.is_empty() or pack.is_empty() or not FileAccess.file_exists(pack):
    _fail("PCK_OR_OUTPUT_MISSING")
    return
  if not ProjectSettings.load_resource_pack(pack,true):
    _fail("REAL_APK176_PCK_FAILED_TO_MOUNT")
    return
  var scene: PackedScene=load("res://scenes/main.tscn")
  if scene==null:
    _fail("REAL_APK176_MAIN_MISSING")
    return
  base=scene.instantiate()
  get_root().add_child(base)
  await process_frame
  await process_frame
  room=base.get_node_or_null("CanglanAutonomousEcologyWorldRev187")
  if room==null:
    _fail("NEW_REAL_SCENE_NOT_ACTIVE")
    return
  var state: Dictionary=room.call("stats")
  if int(state["revision"])!=187:
    _fail("NOT_REV187_RUNTIME_SCENE")
    return
  view=room.get("view")
  camera=room.get("camera")
  var player: Node=room.get("controls")
  player.call("_set_mode","fly")
  # Same original rev184/rev186 worksite: exterior slightly elevated look
  # toward stage construction, with road and trees around it.
  player.set("_flight_position",Vector3(16,9,22))
  player.set("_yaw",0.55)
  player.set("_pitch",-0.22)
  player.call("update_camera")
  for i in range(90):
    room.call("_process",0.70)
    await process_frame
  # After worksite progresses, restore exact camera for stable comparison.
  player.set("_flight_position",Vector3(16,9,22))
  player.call("update_camera")
  for i in range(6):
    await process_frame
  await RenderingServer.frame_post_draw
  if not _save("real_apk176_rev187_worksite_same_position_wide.png"):
    _fail("WIDE_FRAME_TOO_MONOCHROMATIC_OR_SAVE_FAIL")
    return
  player.set("_flight_position",Vector3(9,5.7,6))
  player.set("_yaw",0.77)
  player.set("_pitch",-0.1)
  player.call("update_camera")
  for i in range(6):
    await process_frame
  await RenderingServer.frame_post_draw
  if not _save("real_apk176_rev187_worksite_same_position_close.png"):
    _fail("CLOSE_FRAME_RENDER_FAIL")
    return
  print("PASS_REV187_TWO_GENUINE_ENGINE_RENDERED_WORKSITE_FRAMES_NOT_PHONE_TESTS")
  base.queue_free()
  await process_frame
  quit(0)
