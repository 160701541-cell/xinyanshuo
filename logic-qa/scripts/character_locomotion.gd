extends Node
class_name CanglanHumanoidMotion
## Preview-level skeletal locomotion. Uses REAL imported Skeleton3D bones.
## Not motion capture; art review still requires proper hand/foot animation.
var skeleton: Skeleton3D
var visual_root: Node3D
var bones: Dictionary = {}
var neutral_pose: Dictionary = {}
var neutral_arms: Dictionary = {}
var phase: float = 0.0
var blend: float = 0.0
var carrying: bool = false

static func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found: Skeleton3D = _find_skeleton(child)
		if found != null:
			return found
	return null

static func _side(name: String) -> String:
	# Imported CC0 rigs use thigh_l/calf_l/hand_l (Godot 4.4.1).
	# Do NOT erase side delimiters before classifying them: that broke native
	# art smoke at the thigh bones and prevented new APK export.
	var raw: String = name.to_lower().replace("mixamorig:", "").strip_edges()
	var normalized: String = raw.replace("_", "").replace("-", "").replace(" ", "")
	if normalized.begins_with("left") or raw.ends_with("_l") or raw.ends_with(".l") or raw.ends_with("-l"):
		return "left"
	if normalized.begins_with("right") or raw.ends_with("_r") or raw.ends_with(".r") or raw.ends_with("-r"):
		return "right"
	return ""

static func bone_role(name: String) -> String:
	var normalized: String = name.to_lower().replace("mixamorig:", "").replace("_", "").replace("-", "").replace(" ", "")
	var side: String = _side(name) # Preserve _l/_r endings on imported CC0 rigs.
	if side.is_empty():
		return ""
	if normalized.contains("upleg") or normalized.contains("thigh") or normalized.contains("upperleg"):
		return side + "_thigh"
	if normalized.contains("lowerleg") or normalized.contains("calf") or normalized.contains("shin") or (normalized.contains("leg") and not normalized.contains("up")):
		return side + "_shin"
	if normalized.contains("foot") and not normalized.contains("toe"):
		return side + "_foot"
	if normalized.contains("forearm") or normalized.contains("lowerarm"):
		return side + "_forearm"
	if normalized.contains("upperarm") or (normalized.contains("arm") and not normalized.contains("fore") and not normalized.contains("lower") and not normalized.contains("hand")):
		return side + "_upper_arm"
	return ""

func bind(source: Node3D) -> bool:
	visual_root = source
	skeleton = _find_skeleton(source)
	bones.clear()
	neutral_pose.clear()
	neutral_arms.clear()
	if skeleton == null:
		return false
	for i in range(skeleton.get_bone_count()):
		var role: String = bone_role(skeleton.get_bone_name(i))
		if not role.is_empty() and not bones.has(role):
			bones[role] = i
			neutral_pose[role] = skeleton.get_bone_pose_rotation(i)
	# A T-pose arm goes from upper-arm to forearm and should hang in an
	# anatomically plausible relaxed *diagonal* rather than straight sideways.
	for side in ["left", "right"]:
		var upper: String = side + "_upper_arm"
		var fore: String = side + "_forearm"
		if bones.has(upper) and bones.has(fore):
			var a: int = int(bones[upper])
			var b: int = int(bones[fore])
			var rest_a: Transform3D = skeleton.get_bone_global_rest(a)
			var rest_b: Transform3D = skeleton.get_bone_global_rest(b)
			var direction: Vector3 = rest_b.origin - rest_a.origin
			if direction.length_squared() > 0.0001:
				var desired: Vector3 = Vector3(-0.4 if side == "left" else 0.4, -0.9, 0).normalized()
				var delta_skeleton: Quaternion = Quaternion(direction.normalized(), desired)
				var basis: Basis = rest_a.basis.orthonormalized()
				neutral_arms[upper] = (basis.inverse() * Basis(delta_skeleton) * basis).get_rotation_quaternion()
		# Imported skeletons and uninitialized mock rigs can report zero-length
		# child rest offsets. NEVER leave these shoulders in default T-pose.
		if not neutral_arms.has(upper) or (neutral_arms[upper] as Quaternion).is_equal_approx(Quaternion.IDENTITY):
			neutral_arms[upper] = Quaternion(Vector3.FORWARD, 1.05 if side == "left" else -1.05)
	return true

func has_walk_rig() -> bool:
	return skeleton != null and bones.has("left_thigh") and bones.has("right_thigh")

func _pose(role: String, angle: float, axis_skeleton: Vector3, correction: Quaternion = Quaternion.IDENTITY) -> void:
	if not bones.has(role):
		return
	var idx: int = int(bones[role])
	var rest: Basis = skeleton.get_bone_global_rest(idx).basis.orthonormalized()
	var local_axis: Vector3 = (rest.inverse() * axis_skeleton).normalized()
	var animation_rotation: Quaternion = Quaternion(local_axis, angle)
	var base: Quaternion = neutral_pose[role]
	# Overwrite only this bone's *pose*, never alter imported rest skeleton.
	skeleton.set_bone_pose_rotation(idx, (base * correction * animation_rotation).normalized())

func update_motion(delta: float, speed: float, held_item: bool = false) -> void:
	if skeleton == null:
		return
	var moving: float = clampf(speed / 3.0, 0.0, 1.0)
	blend = move_toward(blend, moving, delta * 6.0)
	phase = fposmod(phase + delta * maxf(speed, 0.0) * 5.3, TAU)
	carrying = held_item
	var swing: float = sin(phase) * 0.52 * blend
	var bend_left: float = maxf(0.0, -sin(phase)) * 0.42 * blend
	var bend_right: float = maxf(0.0, sin(phase)) * 0.42 * blend
	_pose("left_thigh", swing, Vector3.RIGHT)
	_pose("right_thigh", -swing, Vector3.RIGHT)
	_pose("left_shin", bend_left, Vector3.RIGHT)
	_pose("right_shin", bend_right, Vector3.RIGHT)
	_pose("left_foot", -swing * 0.22, Vector3.RIGHT)
	_pose("right_foot", swing * 0.22, Vector3.RIGHT)
	# Drop upper arms toward hips in idle; alternate swing while walking.
	var left_idle: Quaternion = neutral_arms.get("left_upper_arm", Quaternion.IDENTITY)
	var right_idle: Quaternion = neutral_arms.get("right_upper_arm", Quaternion.IDENTITY)
	_pose("left_upper_arm", -swing * 0.65, Vector3.RIGHT, left_idle)
	# Pot carry: avoid swinging the right hand that owns its bone socket.
	_pose("right_upper_arm", 0.12 if held_item else swing * 0.65, Vector3.RIGHT,
		right_idle.slerp(Quaternion.IDENTITY, 0.7) if held_item else right_idle)

