extends RefCounted
class_name CanglanTouchLookRouter
## Independent right-hand camera pointer(s). Left joystick is a separate
## Control consuming its own GUI events and owns its own finger index.
## Any touch beginning in the left movement zone is never camera input.
## No tap ever invokes ray picking: interaction is an EXPLICIT on-screen button.
const LOOK_ZONE_START: float = 0.47
const DRAG_THRESHOLD_PIXELS: float = 12.0
const TAP_LIMIT_SECONDS: float = 0.28
const MIN_PINCH_SPAN: float = 22.0

var hands: Dictionary = {}
var zooming: bool = false

static func is_right_zone(position: Vector2, viewport: Vector2) -> bool:
	return viewport.x > 0 and position.x >= viewport.x * LOOK_ZONE_START

func begin(index: int, point: Vector2, viewport: Vector2, now_seconds: float = 0.0) -> bool:
	if not is_right_zone(point, viewport) or hands.has(index):
		return false
	hands[index] = {
		"start": point,
		"previous": point,
		"time": now_seconds,
		"dragged": false,
	}
	if hands.size() >= 2:
		zooming = true
		for key in hands:
			hands[key]["dragged"] = true
	return true

func move(index: int, point: Vector2) -> Dictionary:
	if not hands.has(index):
		return {}
	var state: Dictionary = hands[index]
	var before: Vector2 = state["previous"]
	state["previous"] = point
	if point.distance_to(state["start"]) >= DRAG_THRESHOLD_PIXELS:
		state["dragged"] = true
	if hands.size() == 2:
		var other_index: int = -1
		for key in hands:
			if key != index:
				other_index = int(key)
				break
		if other_index < 0:
			return {}
		var other: Vector2 = hands[other_index]["previous"]
		var old_span: float = before.distance_to(other)
		var new_span: float = point.distance_to(other)
		if old_span >= MIN_PINCH_SPAN and new_span >= MIN_PINCH_SPAN:
			return {"action": "zoom", "factor": clampf(old_span / new_span, 0.65, 1.55)}
		return {}
	if hands.size() > 1:
		return {}
	# After a two-finger pinch, suppress one-finger look until both fingers
	# are released. Otherwise the surviving finger jerks the camera.
	if zooming:
		return {}
	if bool(state["dragged"]):
		return {"action": "look", "delta": point - before}
	return {}

func end(index: int, point: Vector2, now_seconds: float = 0.0) -> Dictionary:
	if not hands.has(index):
		return {}
	var state: Dictionary = hands[index]
	hands.erase(index)
	var tapped: bool = not bool(state["dragged"]) and not zooming \
		and point.distance_to(state["start"]) < DRAG_THRESHOLD_PIXELS \
		and now_seconds - float(state["time"]) < TAP_LIMIT_SECONDS
	if hands.size() == 0:
		zooming = false
	# "tap" is informational only. Never call _pick() from touch camera.
	return {"action": "tap"} if tapped else {"action": "end"}

func clear() -> void:
	hands.clear()
	zooming = false

func is_looking() -> bool:
	return not hands.is_empty()
