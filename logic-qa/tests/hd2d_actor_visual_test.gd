extends SceneTree
## Run against the *actual* CC0 Han PNGs, not painted test rectangles.
const ActorView = preload("res://scripts/hd2d_actor.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	assert(ActorView.has_authored_sprite(true), "Missing actual male source art")
	assert(ActorView.has_authored_sprite(false), "Missing actual female source art")
	var host := Node3D.new()
	root.add_child(host)
	var male = ActorView.create_for({"id":"actor:hexi:player"}, true)
	var female = ActorView.create_for({"id":"actor:hexi:farmer"}, false)
	assert(male != null and female != null)
	host.add_child(male)
	host.add_child(female)
	for actor in [male, female]:
		assert(actor.sprite != null and actor.foot_shadow != null)
		assert(actor.sprite.texture != null)
		assert(actor.sprite.billboard == BaseMaterial3D.BILLBOARD_FIXED_Y)
		assert(actor.sprite.position.y > 0.8 and actor.sprite.position.y < 1.0)
		assert(actor.sprite.hframes == 3 and actor.sprite.vframes == 4)
		assert(actor.sprite.pixel_size * float(actor.sprite.texture.get_height() / actor.sprite.vframes) > 1.70)
		assert(actor.sprite.pixel_size * float(actor.sprite.texture.get_height() / actor.sprite.vframes) < 1.75)
		assert(actor.sprite.no_depth_test == false, "Sprites must respect 3D depth")
		assert(actor.foot_shadow.position.y < 0.03)
		var old: float = float(actor.sprite.position.y)
		actor.set_world_direction(Vector3(0, 0, -1))
		assert(actor.direction_row == 3)
		var old_frame: int = actor.sprite.frame
		actor.update_motion(0.45, 3.0)
		assert(actor.sprite.position.y >= old)
		assert(actor.sprite.frame != old_frame, "Actual walking frame must advance")
		assert(actor.sprite.frame >= 9 and actor.sprite.frame <= 11)
		actor.set_world_direction(Vector3(-2, 0, 0))
		assert(actor.direction_row == 1)
		actor.update_motion(0.1, 0.0)
		assert(actor.sprite.frame == 4, "Standing selects middle frame for heading")
		assert(is_equal_approx(actor.sprite.position.y, old))
		assert(actor.get_meta("render_source") == "licensed_cc0_hd2d_character")
	print("PASS CANGLAN ACTUAL CC0 HAN SPRITE3D: native PNG/feet/3D depth/camera billboard/ground shadow/identity")
	quit(0)
