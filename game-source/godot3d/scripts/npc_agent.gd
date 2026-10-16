extends Node3D
## Procedural 3D citizen, identifiable/scheduled, rendered as a temporary humanoid
## mannequin. NOT a rigged/face-animation or fully autonomous AI NPC.
const TextAvatar = preload("res://scripts/npc_text_avatar.gd")
const TEXT_ONLY_TEST_MODE := true
const FAMILY_NAMES := ["沈","林","周","许","叶","陆","秦","顾","苏","江","方","唐"]
const GIVEN_NAMES := ["守田","青禾","景安","春山","清河","成林","怀谷","平生",
	"远舟","小满","东来","知秋","长青","景年","阿宁","思源","秋实","云生"]
signal inspection_requested(actor_id: String)
var text_marker: Node3D
var civilian_name: String = ""
var sim_profile: Dictionary = {}
const ROLE_NAMES := ["农人","商贾","铁匠","工匠","学徒","旅人","卫卒","医者","书生","茶客"]
var entity_id: String = ""
var profession: String = ""
var home: Vector3
var rules: RefCounted
var random := RandomNumberGenerator.new()
var _observer: Node3D
var _target := Vector3.ZERO
var _external_job_destination: Vector3 = Vector3.ZERO
var _externally_assigned_job: bool = false
var _walk_clock: float = 0.0
var _decide_clock: float = 0.0
var _body_visual: Node3D
var _generated_role_visual: Node3D
var _left_leg: Node3D
var _right_leg: Node3D
var _left_arm: Node3D
var _right_arm: Node3D
var _is_resting: bool = false
var _working_hours: float = 10.0
var _movement_speed: float = 0.95
var _citizen_state := {"inventory":{},"goal":"daily_routine","task":"idle","owner_id":""}

func setup(id: String,role_index: int,spawn: Vector3,world_rules: RefCounted,
		observer: Node3D) -> void:
	entity_id = id
	profession = ROLE_NAMES[posmod(role_index,ROLE_NAMES.size())]
	home = spawn
	rules = world_rules
	_observer = observer
	name = id
	random.seed = int(id.hash()) + 2031
	position = spawn
	_decide_clock = random.randf_range(0.1,3.0)
	_movement_speed = random.randf_range(0.75,1.45)
	set_meta("entity_id",id)
	set_meta("role",profession)
	set_meta("art_status","PROCEDURAL_HUMANOID_PLACEHOLDER")
	var ordinal: int = absi(id.hash())
	civilian_name = FAMILY_NAMES[ordinal%FAMILY_NAMES.size()] + GIVEN_NAMES[int(ordinal/FAMILY_NAMES.size())%GIVEN_NAMES.size()]
	set_meta("display_name",civilian_name)
	if TEXT_ONLY_TEST_MODE:
		text_marker = TextAvatar.new()
		add_child(text_marker)
		text_marker.call("configure",id,civilian_name,profession,ordinal)
		text_marker.connect("selected",Callable(self,"_notify_inspect"))
		set_meta("art_status","TEXT_ONLY_BILLBOARD_IN_3D")
	else:
		_build_body(role_index)

func _mat(rgb: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = rgb
	material.roughness = 0.94
	return material

func _mesh(mesh: Mesh,mat: Material,at: Vector3,parent: Node3D,
		scale3: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	node.position = at
	node.scale = scale3
	parent.add_child(node)
	return node

func _build_body(role: int) -> void:
	_body_visual = Node3D.new()
	_body_visual.name = "ProceduralArtNotApproved"
	add_child(_body_visual)
	var robes := [Color("#668779"),Color("#a18a62"),Color("#68747d"),
			Color("#856d58"),Color("#8c9a8b"),Color("#657f92"),
			Color("#65706c"),Color("#918272"),Color("#687b8e"),Color("#a07865")]
	var cloth := _mat(robes[posmod(role,robes.size())])
	var flesh := _mat(Color("#c8a68a"))
	var hair := _mat(Color("#2d2b28"))
	var sash := _mat(Color("#544436"))
	var torso := CylinderMesh.new()
	torso.top_radius = 0.32
	torso.bottom_radius = 0.48
	torso.height = 1.13
	_mesh(torso,cloth,Vector3(0,1.23,0),_body_visual)
	var head := SphereMesh.new()
	head.radius = 0.245
	head.height = 0.48
	head.radial_segments = 12
	head.rings = 6
	_mesh(head,flesh,Vector3(0,2.13,0),_body_visual)
	var cap := SphereMesh.new()
	cap.radius = 0.251
	cap.height = 0.24
	_mesh(cap,hair,Vector3(0,2.315,-0.01),_body_visual)
	var belt := CylinderMesh.new()
	belt.top_radius = 0.36
	belt.bottom_radius = 0.36
	belt.height = 0.07
	_mesh(belt,sash,Vector3(0,0.96,0),_body_visual)
	var leg_mesh := CapsuleMesh.new()
	leg_mesh.radius = 0.12
	leg_mesh.height = 0.9
	for side in [-1.0,1.0]:
		var leg := Node3D.new()
		leg.position = Vector3(side*0.2,0.79,0)
		_body_visual.add_child(leg)
		_mesh(leg_mesh,cloth,Vector3(0,-0.35,0),leg)
		if side<0:
			_left_leg = leg
		else:
			_right_leg = leg
		var arm := Node3D.new()
		arm.position = Vector3(side*0.39,1.70,0)
		_body_visual.add_child(arm)
		_mesh(leg_mesh,cloth,Vector3(side*0.035,-0.32,0),arm,
				Vector3(0.83,0.78,0.83))
		if side<0:
			_left_arm = arm
		else:
			_right_arm = arm

	# Prefer the actual 3D GLB exported by the open-source model factory.
	# It is intentionally marked UNRIGGED; never claim skeletal walking,
	# BlendShapes, or a production quality character until tested.
	var model_file: String = "res://assets/generated/npc/role_%02d.glb" % posmod(role,10)
	# First real low-poly male civilian MASTER, 4 role-accurate outfits.
	# Other residents retain their independent candidate models until
	# female, child, elder, humanoid rig and animation gates are approved.
	var male_roles: Dictionary = {
		1:"merchant", 4:"apprentice", 6:"guard", 8:"scholar"}
	var occupation_index: int = posmod(role,10)
	if male_roles.has(occupation_index):
		var candidate: String = "res://assets/generated/npc/male_%s_han_v2.glb" % male_roles[occupation_index]
		if ResourceLoader.exists(candidate):
			model_file = candidate
	if ResourceLoader.exists(model_file):
		var imported: Resource = load(model_file)
		if imported is PackedScene:
			var model: Node3D = (imported as PackedScene).instantiate()
			for old_mesh in _body_visual.get_children():
				var previous: Node3D = old_mesh as Node3D
				if previous != null:
					previous.visible = false
			model.name = "GeneratedOccupationGLB_Unrigged"
			_body_visual.add_child(model)
			_generated_role_visual = model
			set_meta("art_status","UNRIGGED_GENERATED_GLB_CANDIDATE")
			set_meta("model_source",model_file)
			if model_file.contains("/male_"):
				set_meta("shared_master","CAC_HAN_MALE_V2")
				set_meta("costume_dna","JIaOLING_YOUREN_HEADWRAP_CLOTH_SASH")
				set_meta("wardrobe_role",String(male_roles[occupation_index]))
				set_meta("skeleton_status","NOT_SKINNED_NO_RIG")

func _process(delta: float) -> void:
	if _observer == null or rules == null:
		return
	var proximity: float = global_position.distance_to(_observer.global_position)
	# Render/activity LOD: citizens are IDs even when not visually instantiated.
	_body_visual.visible = proximity < 65.0
	if proximity > 190.0 and not _externally_assigned_job:
		set_process(false)
		return
	_decide_clock -= delta
	if _externally_assigned_job:
		_target = _external_job_destination
	elif _decide_clock <= 0:
		_decide_clock = random.randf_range(4.0,8.0)
		if _is_resting:
			_target = home
		else:
			_target = home + Vector3(random.randf_range(-10.0,10.0),0,
					random.randf_range(-8.0,8.0))
	var delta_target := Vector3(_target.x-position.x,0,_target.z-position.z)
	if delta_target.length() > 0.25:
		var direction := delta_target.normalized()
		position += direction * minf(delta_target.length(),delta*_movement_speed)
		rotation.y = atan2(direction.x,direction.z)
		_walk_clock += delta * 6.7
		if _generated_role_visual != null:
			_generated_role_visual.position.y = absf(sin(_walk_clock))*0.035
		_left_leg.rotation.x = sin(_walk_clock)*0.42
		_right_leg.rotation.x = -sin(_walk_clock)*0.42
		_left_arm.rotation.x = -sin(_walk_clock)*0.35
		_right_arm.rotation.x = sin(_walk_clock)*0.35
		_citizen_state["task"] = "rest_home" if _is_resting else "walking"
	else:
		_left_leg.rotation.x = lerpf(_left_leg.rotation.x,0,delta*5)
		_right_leg.rotation.x = lerpf(_right_leg.rotation.x,0,delta*5)
		_left_arm.rotation.x = lerpf(_left_arm.rotation.x,0,delta*5)
		_right_arm.rotation.x = lerpf(_right_arm.rotation.x,0,delta*5)
		if _generated_role_visual != null:
			_generated_role_visual.position.y = lerpf(_generated_role_visual.position.y,0.0,clampf(delta*6,0.0,1.0))
		_citizen_state["task"] = "resting" if _is_resting else "waiting"
	position.y = float(rules.call("height_at",position.x,position.z))

func assign_work_destination(location: Vector3) -> void:
	_external_job_destination = location
	_externally_assigned_job = true
	_target = location
	_decide_clock = 0.0
	set_process(true)

func cancel_work_destination() -> void:
	_externally_assigned_job = false
	_target = home

func reached_work_destination(radius: float=1.1) -> bool:
	if not _externally_assigned_job:
		return false
	return Vector2(position.x,position.z).distance_to(
		Vector2(_external_job_destination.x,_external_job_destination.z))<=radius

func set_hour(hour: float) -> void:
	_is_resting = hour < 6.0 or hour > 20.0
	if _is_resting:
		_citizen_state["goal"] = "sleep"
	else:
		_citizen_state["goal"] = "work_" + profession

func wake_near_player() -> void:
	set_process(true)

func status() -> Dictionary:
	return {"id":entity_id,"profession":profession,"home":[home.x,home.y,home.z],
			"goal":_citizen_state["goal"],"task":_citizen_state["task"],
			"art_status":String(get_meta("art_status","PROCEDURAL_HUMANOID_PLACEHOLDER"))}
