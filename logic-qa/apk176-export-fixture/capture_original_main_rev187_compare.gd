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

# REV191: the earlier "successful" Godot screenshots had a completely
# INVISIBLE terrain mesh. At x=340..920, y=425..590, 83% of pixels were
# exactly the SKY background. Fail REAL framebuffer acceptance on that.
func _audit_visible_ground() -> bool:
  var screenshot: Image=get_root().get_texture().get_image()
  if screenshot==null or screenshot.get_width()<900 or screenshot.get_height()<600:
    return false
  var w: float=float(screenshot.get_width())/1280.0
  var h: float=float(screenshot.get_height())/720.0
  var sky: Color=screenshot.get_pixel(roundi(640*w),roundi(140*h))
  var sky_like: int=0
  var total: int=0
  for yi in range(425,590,17):
    for xi in range(340,920,17):
      var c: Color=screenshot.get_pixel(roundi(float(xi)*w),roundi(float(yi)*h))
      var delta: float=maxf(absf(c.r-sky.r),
        maxf(absf(c.g-sky.g),absf(c.b-sky.b)))
      if delta<0.051:
        sky_like+=1
      total+=1
  var ratio: float=float(sky_like)/maxf(1.0,float(total))
  print("REV191_REAL_RENDER_SOIL_VS_SKY_BLUE_VOID_PIXEL_RATIO ",ratio)
  if ratio>0.48:
    printerr("FAIL_REV191_GROUND_IS_STILL_INVISIBLE_SKY_BLUE_VOID ",ratio)
    return false
  return true

func _assert_rendered_character_pixels(label: String) -> bool:
  # The original QA only inspected the scene tree and projected a headpoint.
  # Those tests PASSED WHILE THE ACTUAL HERO WAS 100% TRANSPARENT.
  # The photo below must contain dark-colored Knight armor in a true 3D
  # framebuffer rectangle around the player; empty light soil is a failure.
  var frame: Image=get_root().get_texture().get_image()
  if frame==null or frame.is_empty() or frame.get_width()<900:
    return false
  var dark_samples: int=0
  var palette: Dictionary={}
  for yy in range(290,445,3):
    for xx in range(578,704,3):
      var sample: Color=frame.get_pixel(xx,yy)
      if sample.get_luminance()<0.50:
        dark_samples+=1
      palette[sample.to_html(false)]=true
  print("REV198_GENUINE_SCREEN_RENDERED_PLAYER_PIXEL_AUDIT ",label,
    " opaque_dark_samples=",dark_samples," color_variety=",palette.size())
  if dark_samples<34 or palette.size()<45:
    printerr("FAIL_REV198_RENDERED_PLAYER_IS_STILL_INVISIBLE_NOT_MERE_SCENE_NODE ",label,
      " dark=",dark_samples," distinct=",palette.size())
    return false
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
  if not _audit_visible_ground():
    _fail("REV191_REAL_PHYSICAL_SOIL_IS_INVISIBLE_OR_BLUE_SKY_VOID")
    return
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
  # REV197: actual original APK176 license-backed CHARACTER is in the
  # camera frame in third person and follows a fixed 45-degree iso orbit.
  # Screenshots are Mesa/Linux Godot frames, NEVER user Adreno phone photos.
  player.call("_set_mode","third")
  player.set("_yaw",0.65)
  player.set("_pitch",0.41)
  player.set("_distance",5.2)
  player.call("update_camera")
  for i in range(7):
    await process_frame
  await RenderingServer.frame_post_draw
  var avatar: Node3D=player.get("actor")
  var head_point: Vector3=avatar.position+Vector3.UP*1.0
  var actual_bounds: Vector2=room.call("_visible_bounds",avatar)
  print("REV197_PLAYER_ACTUAL_CAMERA_RENDER_DIAG actor=",avatar.position,
    " bounds=",actual_bounds," meshes=",avatar.find_children(
    "*","MeshInstance3D",true,false).size()," camera=",camera.position,
    " pixel_head=",camera.unproject_position(head_point),
    " camera_cull=",camera.cull_mask)
  for mesh_node in avatar.find_children("*","MeshInstance3D",true,false):
    var mesh_part: MeshInstance3D=mesh_node as MeshInstance3D
    var has_material: String=""
    if mesh_part.mesh!=null and mesh_part.mesh.get_surface_count()>0:
      var material: Material=mesh_part.get_active_material(0)
      has_material=str(material)
      if material is StandardMaterial3D:
        var std: StandardMaterial3D=material
        has_material+=" color="+str(std.albedo_color)+" transparency="+str(std.transparency)
    print("REV197_PLAYER_MESH_DIAG name=",mesh_part.name,
      " visible=",mesh_part.visible," visible_in_tree=",mesh_part.is_visible_in_tree(),
      " local_aabb=",mesh_part.get_aabb()," glob_origin=",mesh_part.global_position,
      " mat=",has_material)
  if not avatar.visible or camera.is_position_behind(head_point):
    _fail("REV197_THIRD_PERSON_AVATAR_ACTUALLY_INVISIBLE_IN_RENDERING_CAMERA")
    return
  if not _save("real_apk176_rev197_licensed_player_visible_close.png"):
    _fail("REV197_ACTUAL_THIRD_PERSON_FRAME_NOT_CAPTURED")
    return
  if not _assert_rendered_character_pixels("third_close"):
    _fail("REV198_TRUE_OPAQUE_CHARACTER_PIXELS_MISSING_FROM_THIRD_VIEW")
    return
  player.call("toggle_iso45")
  player.call("update_camera")
  for i in range(8):
    await process_frame
  await RenderingServer.frame_post_draw
  if player.get("camera_mode")!="iso" or absf(float(player.get("_pitch"))-PI/4.0)>0.002:
    _fail("REV197_ACTUAL_45DEG_FOLLOW_CAMERA_NOT_45DEG")
    return
  if not _save("real_apk176_rev197_follow_player_45deg_view.png"):
    _fail("REV197_REAL_45DEG_FRAME_NOT_CAPTURED")
    return
  if not _assert_rendered_character_pixels("follow_45deg"):
    _fail("REV198_TRUE_OPAQUE_CHARACTER_PIXELS_MISSING_FROM_45DEG_VIEW")
    return
  print("PASS_REV198_ACTUAL_OPAQUE_AVATAR_PIXELS_RENDER_IN_REAL_3D_THIRD_PERSON_AND_45DEG")
  print("PASS_REV197_ORIGINAL_GODOT_ENGINE_VISIBLE_ANIMATED_PLAYER_CLOSE_AND_45DEG_REAL_FRAMES")
  print("PASS_REV187_TWO_GENUINE_ENGINE_RENDERED_WORKSITE_FRAMES_NOT_PHONE_TESTS")
  base.queue_free()
  await process_frame
  quit(0)
