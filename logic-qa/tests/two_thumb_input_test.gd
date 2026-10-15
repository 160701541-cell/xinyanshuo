extends SceneTree
## Real Godot scene input contract: left joystick and right camera must work at the same time.
const Stick = preload("res://scripts/ancient_touch_joystick.gd")
const Look = preload("res://scripts/touch_look_router.gd")
var failures: Array[String] = []

func verify(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
		printerr("TWO_THUMB_FAIL ", description)

func touch(index: int, pos: Vector2, pressed: bool) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = pos
	event.pressed = pressed
	return event

func drag(index: int, pos: Vector2) -> InputEventScreenDrag:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = pos
	return event

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var stick := Stick.new()
	root.add_child(stick)
	stick.size = Vector2(200, 200)
	var look := Look.new()
	var viewport_size := Vector2(1280, 720)

	stick._gui_input(touch(7, Vector2(100, 100), true))
	verify(stick.finger_id == 7, "first left finger owns joystick")
	verify(stick.direction == Vector2.ZERO, "joystick initially neutral")
	verify(not look.begin(7, Vector2(100, 600), viewport_size), "left input cannot own right camera")
	verify(look.begin(8, Vector2(930, 360), viewport_size), "second simultaneous finger owns camera")
	stick._gui_input(drag(7, Vector2(170, 100)))
	verify(stick.direction.x > 0.70 and absf(stick.direction.y) < 0.01, "left thumb moves while right thumb held")
	var look_action: Dictionary = look.move(8, Vector2(1050, 370))
	verify(look_action.get("action", "") == "look", "right thumb rotates while left thumb moves")
	verify(stick.direction.x > 0.70, "camera drag does not cancel left movement")
	stick._gui_input(touch(8, Vector2(180, 150), false))
	verify(stick.finger_id == 7 and stick.direction.x > 0.70, "wrong finger cannot release joystick")
	stick._gui_input(touch(7, Vector2(170, 100), false))
	verify(stick.finger_id == -1 and stick.direction == Vector2.ZERO, "left finger release stops character")
	verify(look.is_looking(), "joystick release does not cancel right camera")
	verify(look.end(8, Vector2(1050, 370), 0.15).get("action", "") == "end", "right camera release does not produce world interaction")
	verify(not look.is_looking(), "all look pointers released")
	stick.apply_pointer(Vector2(105, 100))
	verify(stick.direction == Vector2.ZERO, "small center movement is dead-zoned")
	stick.apply_pointer(Vector2(2000, 100))
	verify(stick.direction.length() <= 1.00001, "out-of-bounds thumb input stays clamped")
	stick.cancel_input()
	verify(stick.direction == Vector2.ZERO, "screen focus cancellation stops movement")
	stick.queue_free()
	print("CANG LAN TWO THUMB INPUT QA failed=", failures.size())
	if failures.is_empty():
		print("PASS CANG LAN SIMULTANEOUS TWO THUMB TOUCH")
		quit(0)
	else:
		quit(1)
