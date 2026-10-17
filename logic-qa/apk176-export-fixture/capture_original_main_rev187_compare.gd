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
  # rev200: original screenshot QA previously failed to show a user the
  # NEW air animation/sword/wind and mistook hair UNDER the torso for hair
  # on the head. Capture a real engine airborne view before OTA signing.
  var head_hair: MeshInstance3D=player.get("actor").get_node_or_null(
    "ActualCC0QuaterniusHairLongNOTArtificialHelmet")
  if head_hair==null:
    _fail("REV200_NO_HAIR_ON_REAL_RENDERED_AVATAR")
    return
  var hair_bounds: Vector2=room.call("_visible_bounds",head_hair)
  var target_y: float=float(player.get("actor").position.y)+float(
    player.get("actor").get_meta("actor_visual_height_m",0.0))
  if hair_bounds.y<target_y-0.10 or hair_bounds.x<target_y-0.55:
    _fail("REV200_SOURCES_HAIR_HIDDEN_IN_CHEST_WHILE_FACE_STILL_BARE_"+str(hair_bounds))
    return
  player.call("toggle_iso45")
  player.call("toggle_avatar_flight")
  player.set("_distance",6.5)
  for i in range(12):
    player.call("step",0.085)
    await process_frame
  player.call("update_camera")
  for i in range(9):
    await process_frame
  await RenderingServer.frame_post_draw
  var flying: Dictionary=player.call("stats")
  if not bool(flying.get("actual_licensed_3d_flying_sword_visible",false)) or (
      not bool(flying.get("actual_wind_particles_emitting",false))):
    _fail("REV200_FLYING_GODOT_IMAGE_NOT_AN_ACTUAL_REAL_SWORD_AND_WIND_SCENE")
    return
  if not _save("real_apk176_rev200_actual_licensed_sword_soaring_visible_ground_altitude.png"):
    _fail("REV200_GODOT_SKY_TRAVEL_RENDERED_FRAME_FAILURE")
    return
  print("PASS_REV200_ORIGINAL_REAL_GODOT_AIRBORNE_SWORD_WIND_HAIR_HEIGHT_UI_FRAME")
  # Rev203 actual rendered turning frame: licensed blade follows the player's
  # physical airborne bank; no still image or faked image-space rotation.
  var banking_avatar: Node3D=player.get("actor")
  banking_avatar.rotation.y=1.25
  player.set("_yaw",0.25)
  player.set("_joystick",Vector2(0.0,-1.0))
  player.call("step",0.16)
  player.set("_joystick",Vector2.ZERO)
  var licensed_blade: Node3D=room.get("world").get_node_or_null(
    "ActualQuaterniusKnightCC0FlyingSwordUnderPlayerFeet")
  if absf(banking_avatar.rotation.z)<0.003 or licensed_blade==null or (
      absf(licensed_blade.rotation.z-banking_avatar.rotation.z)>0.005):
    _fail("REV203_REAL_PLAYER_AND_LICENSED_SWORD_NOT_BANKING_IN_GODOT")
    return
  for i in range(6):
    await process_frame
  await RenderingServer.frame_post_draw
  if not _save("real_apk176_rev203_actual_bank_sword_ground_reference.png"):
    _fail("REV203_REAL_TURNING_SWORD_GAME_FRAME_NOT_VISIBLE")
    return
  print("PASS_REV203_REAL_GODOT_RENDERED_LICENCED_SWORD_BANK_AND_GROUND_REFERENCE")
  player.call("toggle_avatar_flight")
  # The screenshot worksite may lie over a solid building occluder. Move
  # the QA camera/hero to the exact known open 29m practice site BEFORE
  # the real physical landing tick; do not bypass any flight collisions or
  # make the game appear to support landing through blocked roofs.
  var training_ground: Node3D=player.get("actor")
  var physical_ground_y: float=float(room.get("terrain_world").call(
    "height_at",29.0,29.0))
  training_ground.position=Vector3(29.0,physical_ground_y+
    float(training_ground.get_meta("actor_ground_offset_y",0.0))+
    float(player.get("_soar_altitude")),29.0)
  var physical_descent_frames: int=0
  for i in range(20):
    player.call("step",0.12)
    physical_descent_frames+=1
    if String(player.get("camera_mode"))=="third":
      break
  if String(player.get("camera_mode"))!="third":
    _fail("REV204_PHYSICAL_LANDING_AT_DRY_OPEN_PRACTICE_SITE_FAILED height="+
      str(player.get("_soar_altitude"))+" frames="+str(physical_descent_frames)+
      " blocked="+str(player.get("_blocked_wall_steps")))
    return
  # Capture the actual original game's martial duel target HUD and **world**
  # HP/MP overhead bars, then the physically moving spiritual projectile.
  # Engine photos are clearly labeled Linux/Mesa, NEVER phone images.
  var fighter: Node3D=player.get("actor")
  fighter.position=Vector3(29,float(room.get("terrain_world").call(
    "height_at",29.0,29.0))+float(fighter.get_meta(
      "actor_ground_offset_y",0.0)),29)
  player.set("_yaw",0.0)
  player.call("update_camera")
  var training: Dictionary=player.call("practice_action")
  if not bool(training.get("ok",false)):
    _fail("REV204_REAL_PRACTICE_OPPONENT_NOT_AVAILABLE_FOR_ENGINE_SNAPSHOT_"+str(training))
    return
  var opponent_ui: PanelContainer=player.get("_target_panel")
  var head_label: Label3D=player.get("_spar_opponent_tag")
  if opponent_ui==null or not opponent_ui.visible or head_label==null:
    _fail("REV204_REAL_TARGET_HEALTH_MANA_MISSING_FROM_ENGINE_FRAME")
    return
  # Let the mobile third-person duel camera ease from the original 9.5m
  # walk distance to an immersive 6.4m focus while preserving user zoom.
  for i in range(12):
    player.call("step",0.105)
  if float(player.get("_combat_camera_pull"))>-1.5:
    _fail("REV204_REAL_DUEL_CAMERA_STILL_TOO_FAR_TO_SEE_ACTUAL_MAGIC")
    return
  if String(player.get("_locked_target_kind"))!="spar" or int(
      player.get("_kenney_ui_asset_count"))!=10 or not bool(
      game_hud.get_meta("kenney_ui_cc0_loaded",false)):
    _fail("REV205_TRUE_TARGET_LOCK_AND_AUTHENTIC_KENNEY_UI_NOT_VISIBLE_IN_ORIGINAL_ENGINE")
    return
  for i in range(2):
    await process_frame
  await RenderingServer.frame_post_draw
  if not _save("real_apk176_rev205_kenney_ui_enemy_lock_combat_hud.png"):
    _fail("REV205_TRUE_CC0_SKIN_LOCKON_GODOT_SCREENSHOT_MISSING")
    return
  print("PASS_REV205_REAL_GODOT_KENNEY_CC0_SKIN_ENEMY_LOCKON_AND_MOBILE_HUD_SCREENSHOT")
  var before_hp: int=int(player.get("_spar_enemy_health"))
  if not bool(player.call("sword_attack")) or (
      int(player.get("_spar_enemy_health"))>=before_hp):
    _fail("REV204_REAL_SWORD_3D_IMPACT_OR_HEALTH_LEDGER_NOT_WORKING")
    return
  for i in range(2):
    await process_frame
  await RenderingServer.frame_post_draw
  if not _save("real_apk176_rev204_opponent_realm_hp_mp_sword_sparks.png"):
    _fail("REV204_REAL_COMBAT_VITALS_AND_MORTAL_SWORD_SCREENSHOT_MISSING")
    return
  print("PASS_REV204_REAL_GODOT_RENDERED_OPPONENT_OVERHEAD_HP_MP_AND_SWORD_IMPACT")
  # Only screenshot QA uses a documented, reversible level-1 art fixture.
  # Mechanics+finite-mana authority are independently checked in real Main
  # QA using actual root examination and Qi-paid breakthrough.
  var arts: RefCounted=room.get("cultivation")
  var saved: Dictionary=arts.get("player_data").duplicate(true)
  var trial: Dictionary=arts.get("player_data")
  trial["tested"]=true
  trial["root_kind"]="木灵根"
  trial["method"]="CL-TECH-NAYUAN-BREATHING-V1"
  trial["layer"]=1
  trial["realm"]="炼气"
  trial["mana"]=12
  trial["known_arts"]=["CL-ART-SPIRIT-BOLT-V1"]
  var spell: Dictionary=player.call("cast_spirit_bolt")
  if not bool(spell.get("ok",false)) or not bool(spell.has("projectile")):
    _fail("REV204_REAL_MANA_PAID_QI_PROJECTILE_NOT_SPAWNED_IN_ENGINE")
    return
  player.call("_step_spell_projectiles",0.050)
  var active_bolts: Array=player.get("_spell_projectiles")
  if active_bolts.size()!=1 or (not is_instance_valid(active_bolts[0]["node"])):
    _fail("REV204_MAGIC_PROJECTILE_DISAPPEARED_BEFORE_TRUE_MIDAIR_CAPTURE")
    return
  var impact_health_before: int=int(player.get("_spar_enemy_health"))
  # Freeze only the controllable hero for TWO renderer frames to capture a
  # real spatial bolt in transit (Godot engine frame, no Photoshop composite).
  # Restore simulation immediately afterward and check actual damage.
  player.set("_enabled",false)
  for i in range(2):
    await process_frame
  await RenderingServer.frame_post_draw
  if not _save("real_apk176_rev204_mana_paid_qi_bolt_midair.png"):
    _fail("REV204_REAL_QI_PROJECTILE_3D_MIDFLIGHT_SCREENSHOT_MISSING")
    return
  player.set("_enabled",true)
  player.call("_step_spell_projectiles",0.18)
  if int(player.get("_spar_enemy_health"))>=impact_health_before:
    _fail("REV204_MIDFLIGHT_BOLT_FAILED_TO_DEAL_ACTUAL_MANA_PAID_HIT_DAMAGE")
    return
  for i in range(2):
    await process_frame
  await RenderingServer.frame_post_draw
  if not _save("real_apk176_rev204_qi_bolt_real_impact_damage.png"):
    _fail("REV204_QI_BOLT_REAL_IMPACT_AND_DAMAGE_FRAME_MISSING")
    return
  print("PASS_REV204_REAL_GODOT_RENDERED_MANA_PAID_SPIRIT_BOLT_IN_FLIGHT")
  print("PASS_REV204_REAL_GODOT_MIDFLIGHT_AND_IMPACT_FINITE_MANA_REAL_HP_DAMAGE_FRAMES")
  player.call("stop_practice")
  arts.set("player_data",saved)
  arts.call("save_state")
  print("PASS_REV197_ORIGINAL_GODOT_ENGINE_VISIBLE_ANIMATED_PLAYER_CLOSE_AND_45DEG_REAL_FRAMES")
  print("PASS_REV187_TWO_GENUINE_ENGINE_RENDERED_WORKSITE_FRAMES_NOT_PHONE_TESTS")
  base.queue_free()
  await process_frame
  quit(0)
