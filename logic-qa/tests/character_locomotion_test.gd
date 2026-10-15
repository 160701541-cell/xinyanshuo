extends SceneTree
const Motion = preload("res://scripts/character_locomotion.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var model := Node3D.new()
	root.add_child(model)
	var skel := Skeleton3D.new()
	model.add_child(skel)
	var names := ["Hips", "LeftUpLeg", "LeftLeg", "LeftFoot", "RightUpLeg", "RightLeg", "RightFoot",
		"LeftArm", "LeftForeArm", "RightArm", "RightForeArm"]
	for name in names:
		skel.add_bone(name)
	var mapping: Dictionary = {}
	for i in range(names.size()):
		mapping[names[i]] = i
	for side in ["Left", "Right"]:
		var thigh: int = mapping[side + "UpLeg"]
		var shin: int = mapping[side + "Leg"]
		var foot: int = mapping[side + "Foot"]
		skel.set_bone_parent(thigh, 0)
		skel.set_bone_parent(shin, thigh)
		skel.set_bone_parent(foot, shin)
		var sign_value: float = -1.0 if side == "Left" else 1.0
		skel.set_bone_rest(thigh, Transform3D(Basis.IDENTITY, Vector3(sign_value*0.2, -0.13, 0)))
		skel.set_bone_rest(shin, Transform3D(Basis.IDENTITY, Vector3(0, -0.7, 0)))
		skel.set_bone_rest(foot, Transform3D(Basis.IDENTITY, Vector3(0, -0.72, 0)))
		var arm: int = mapping[side + "Arm"]
		var forearm: int = mapping[side + "ForeArm"]
		skel.set_bone_parent(arm, 0)
		skel.set_bone_parent(forearm, arm)
		skel.set_bone_rest(arm, Transform3D(Basis.IDENTITY, Vector3(sign_value*0.26,0.48,0)))
		skel.set_bone_rest(forearm, Transform3D(Basis.IDENTITY, Vector3(sign_value*0.57,0,0)))
	var motion = Motion.new()
	model.add_child(motion)
	assert(motion.bind(model))
	assert(motion.has_walk_rig())
	motion.update_motion(0.1,0.0)
	var left_arm: Quaternion = skel.get_bone_pose_rotation(mapping["LeftArm"])
	assert(not left_arm.is_equal_approx(Quaternion.IDENTITY), "Idle T-pose arms must lower")
	var left_base: Quaternion = skel.get_bone_pose_rotation(mapping["LeftUpLeg"])
	motion.update_motion(0.25,3.0)
	var left_walk: Quaternion = skel.get_bone_pose_rotation(mapping["LeftUpLeg"])
	assert(not left_base.is_equal_approx(left_walk), "Moving feet require rotating thigh bone")
	var right_walk: Quaternion = skel.get_bone_pose_rotation(mapping["RightUpLeg"])
	assert(not left_walk.is_equal_approx(right_walk), "Legs alternate rather than both slide")
	motion.update_motion(0.15,0.0,true)
	assert(motion.carrying, "Carried object switches upper arm stance")
	assert(Motion.bone_role("mixamorig:RightForeArm") == "right_forearm")
	assert(Motion.bone_role("UpperArm.L") == "left_upper_arm")
	assert(Motion.bone_role("LeftUpLeg") == "left_thigh")
	assert(Motion.bone_role("thigh_l") == "left_thigh", "CC0 thigh_l bone classification regression")
	assert(Motion.bone_role("thigh_r") == "right_thigh", "CC0 thigh_r bone classification regression")
	assert(Motion.bone_role("calf_l") == "left_shin", "CC0 calf_l regression")
	assert(Motion.bone_role("upperarm_r") == "right_upper_arm", "CC0 upperarm_r regression")
	print("PASS: humanoid rig relaxes arms, alternates real thigh/shin bones on movement, keeps carried object supported")
	quit(0)
