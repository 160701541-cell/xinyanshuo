extends Control
class_name AncientTouchJoystick
## Touch-local virtual stick; does not steal taps/pinches outside its own rect.
signal direction_changed(value: Vector2)

var finger_id: int = -1
var mouse_held: bool = false
var direction: Vector2 = Vector2.ZERO
const JOYSTICK_DEAD_ZONE: float = 0.11


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()

func apply_pointer(local_position: Vector2) -> void:
	var center: Vector2 = size * 0.5
	var radius: float = maxf(1.0, minf(size.x, size.y) * 0.34)
	var desired: Vector2 = ((local_position - center) / radius).limit_length(1.0)
	# Avoid accidental slow drift when finger rests close to thumbstick center.
	var magnitude: float = desired.length()
	direction = desired.normalized() * inverse_lerp(JOYSTICK_DEAD_ZONE, 1.0, magnitude) \
		if magnitude > JOYSTICK_DEAD_ZONE else Vector2.ZERO
	direction_changed.emit(direction)
	queue_redraw()

func cancel_input() -> void:
	finger_id = -1
	mouse_held = false
	release_pointer()

func release_pointer() -> void:
	direction = Vector2.ZERO
	direction_changed.emit(direction)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and finger_id < 0:
			finger_id = event.index
			apply_pointer(event.position)
			accept_event()
		elif not event.pressed and event.index == finger_id:
			finger_id = -1
			release_pointer()
			accept_event()
	elif event is InputEventScreenDrag and event.index == finger_id:
		apply_pointer(event.position)
		accept_event()
	elif not OS.has_feature("mobile") and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		mouse_held = event.pressed
		if mouse_held:
			apply_pointer(event.position)
		else:
			release_pointer()
		accept_event()
	elif not OS.has_feature("mobile") and event is InputEventMouseMotion and mouse_held:
		apply_pointer(event.position)
		accept_event()

func _draw() -> void:
	var c: Vector2 = size * 0.5
	var r: float = minf(size.x, size.y) * 0.36
	draw_circle(c, r, Color(0.09, 0.15, 0.14, 0.27))
	draw_arc(c, r, 0.0, TAU, 48, Color(0.78, 0.74, 0.59, 0.6), 2.0)
	draw_circle(c + direction * (r * 0.80), r * 0.37, Color(0.79, 0.69, 0.48, 0.77))

