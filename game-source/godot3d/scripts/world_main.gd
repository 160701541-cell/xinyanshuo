extends Node3D
## CAC-3D-001: opens the public 3D playable world, NOT a separate HD2D overlay.
## Deterministic streamable 3D terrain, modeled Chinese courtyards, independent
## furniture/props, NPCs with stable IDs. No old signed APK/PCK is modified.
const Rules = preload("res://scripts/world_rules.gd")
const Terrain = preload("res://scripts/terrain_chunk.gd")
const Buildings = preload("res://scripts/building_factory.gd")
const Props = preload("res://scripts/prop_factory.gd")
const Citizen = preload("res://scripts/npc_agent.gd")
const Interiors = preload("res://scripts/interior_factory.gd")
const LocalAI = preload("res://scripts/local_ai_service.gd")
# Authentic earlier Canglan 3D economy/identity source has been audited and
# safely migrated to the PUBLIC repository without any signing credentials.
const OriginalWorldState = preload("res://scripts/world_state.gd")
const OriginalWorldBridge = preload("res://scripts/world_state_bridge.gd")
const CHUNK_SIZE: float = 96.0
const VISIBLE_RADIUS: int = 2

var seed: int = 20261016
var rules: RefCounted
var authoritative_world: RefCounted
var building_factory: RefCounted
var interior_factory: RefCounted
var citizen_nodes: Array[Node3D] = []
var structures: Dictionary = {}
var chunk_nodes: Dictionary = {}
var terrain_root: Node3D
var settlement_root: Node3D
var npc_root: Node3D
var prop_root: Node3D
var avatar: CharacterBody3D
var cam: Camera3D
var sun: DirectionalLight3D
var world_env: WorldEnvironment
var ui_status: Label
var ui_action: Button
var ui_leave: Button
var local_ai: Node
var ui_ai_status: Label
var ui_ai_prompt: LineEdit
var ui_ai_answer: Label
var ui_ai_talk: Button
var _room: Node3D
var _inside: bool = false
var _selected: Node3D
var _yaw: float = 0.22
var _pitch: float = 0.37
var _distance: float = 14.0
var _first_person: bool = false
var _camera_focus := Vector3.ZERO
var _virtual_movement := Vector2.ZERO
var _touch_left_id: int = -1
var _touch_right_id: int = -1
var _touch_start := Vector2.ZERO
var _stream_clock: float = 0
var _hour: float = 12.0
var _npc_clock: float = 0

func _ready() -> void:
	authoritative_world = OriginalWorldState.new()
	rules = Rules.new()
	rules.call("configure",seed)
	building_factory = Buildings.new()
	interior_factory = Interiors.new()
	_build_lighting()
	terrain_root = Node3D.new()
	terrain_root.name = "StreamingTerrain"
	add_child(terrain_root)
	settlement_root = Node3D.new()
	settlement_root.name = "Actual3DSettlements"
	add_child(settlement_root)
	npc_root = Node3D.new()
	npc_root.name = "Civilians"
	add_child(npc_root)
	prop_root = Props.new()
	prop_root.name = "IndependentWorldProps"
	add_child(prop_root)
	_build_avatar()
	_load_nearby_terrain()
	_build_settlements()
	prop_root.call("build",rules,seed)
	# The actual GGUF/llama.cpp service is part of the same 3D game process.
	# When native binary or verified weights are missing it reports disabled,
	# never returns scripted dialog disguised as AI.
	local_ai = LocalAI.new()
	local_ai.name = "OfflineLocalAI"
	local_ai.state_changed.connect(_on_local_ai_state)
	local_ai.npc_reply.connect(_on_local_npc_reply)
	local_ai.inference_failed.connect(_on_local_ai_error)
	add_child(local_ai)
	_create_interface()
	_on_local_ai_state(String(local_ai.get("stage")),String(local_ai.get("info")))
	_update_camera(1.0)
	_refresh_status()
	print("CANGLAN_3D_WORLD_READY ",snapshot())

func _build_lighting() -> void:
	world_env = WorldEnvironment.new()
	world_env.name = "NaturalAtmosphere"
	add_child(world_env)
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("#7294b1")
	sky_mat.sky_horizon_color = Color("#c1cad1")
	sky_mat.ground_bottom_color = Color("#586957")
	sky_mat.ground_horizon_color = Color("#99a38e")
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.reflected_light_source = Environment.REFLECTION_SOURCE_BG
	env.ambient_light_energy = 0.66
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_env.environment = env
	sun = DirectionalLight3D.new()
	sun.name = "TimeOfDaySun"
	sun.rotation_degrees = Vector3(-58,-33,0)
	sun.light_color = Color("#f7dfb9")
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 72.0
	add_child(sun)

func _build_avatar() -> void:
	avatar = CharacterBody3D.new()
	avatar.name = "PlayerWithCollision"
	avatar.position = Vector3(0,3.0,38.0)
	add_child(avatar)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.85
	shape.shape = capsule
	shape.position.y = 0.95
	avatar.add_child(shape)
	var body := MeshInstance3D.new()
	body.name = "TemporaryPlayerHumanoid"
	var visual := CapsuleMesh.new()
	visual.radius = 0.33
	visual.height = 1.8
	body.mesh = visual
	body.position.y = 0.95
	var player_mat := StandardMaterial3D.new()
	player_mat.albedo_color = Color("#487c73")
	body.material_override = player_mat
	avatar.add_child(body)
	cam = Camera3D.new()
	cam.name = "Follow3DCamera"
	cam.current = true
	cam.far = 265.0
	add_child(cam)

func _load_nearby_terrain() -> void:
	var center: Vector2i = Vector2i(floori(avatar.position.x/CHUNK_SIZE),
			floori(avatar.position.z/CHUNK_SIZE))
	var desired: Dictionary = {}
	for dz in range(-VISIBLE_RADIUS,VISIBLE_RADIUS+1):
		for dx in range(-VISIBLE_RADIUS,VISIBLE_RADIUS+1):
			var cell: Vector2i = center+Vector2i(dx,dz)
			desired[cell] = true
			if not chunk_nodes.has(cell):
				var chunk := Terrain.new()
				terrain_root.add_child(chunk)
				chunk.call("build",cell,rules)
				chunk_nodes[cell] = chunk
	for cell in chunk_nodes.keys():
		if not desired.has(cell):
			var old: Node3D = chunk_nodes[cell]
			terrain_root.remove_child(old)
			old.queue_free()
			chunk_nodes.erase(cell)

func _build_settlements() -> void:
	var ordinal: int = 0
	for row in range(4):
		for col in range(5):
			ordinal += 1
			var center := Vector3(float(col-2)*54.0,0.17,float(row)*65.0-92.0)
			var kind: String = String(rules.call("settlement_zone",col,row))
			var yard_id := "YD-HX-%08d" % ordinal
			var courtyard: Node3D = building_factory.call("make_courtyard",
					yard_id,center,46.0,49.0)
			settlement_root.add_child(courtyard)
			structures[yard_id] = courtyard
			for slot in range(3):
				var zoffset: float = -12.0 if slot==0 else 7.0
				var xoffset: float = 0.0 if slot==0 else (-13.5 if slot==1 else 13.5)
				var bkind: String = kind if slot==0 else ("home" if kind!="market" else "shop")
				var home_id := "FZ-HX-%08d" % (ordinal*10+slot)
				var building: Node3D = building_factory.call("make_building",home_id,bkind,
						center+Vector3(xoffset,0,zoffset),ordinal*4+slot)
				settlement_root.add_child(building)
				structures[home_id] = building
			for n in range(4):
				var civil: Node3D = Citizen.new()
				var x: float = center.x + float(n-2)*4.1
				var z: float = center.z+8.4+float(n%2)*4.0
				var y: float = float(rules.call("height_at",x,z))
				var spawn := Vector3(x,y,z)
				var canonical_id: String = authoritative_world.call("create_actor",
					"苍岚居民%03d" % (ordinal*4+n+1),spawn)
				var id: String = OriginalWorldBridge.actor_public_code(authoritative_world,canonical_id)
				assert(not id.is_empty(),"Original WorldState identity generator failed")
				civil.call("setup",id,(ordinal+n)%10,spawn,rules,avatar)
				civil.set_meta("canonical_id",canonical_id)
				npc_root.add_child(civil)
				citizen_nodes.append(civil)
	_make_streets()
	_make_river()

func _make_streets() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#a59f8f")
	mat.roughness = 1.0
	var brick := StandardMaterial3D.new()
	brick.albedo_color = Color("#77746b")
	brick.roughness = 1.0
	# Hundreds of paving joints share one MultiMesh draw instead of ~190 nodes.
	var seam_mesh := BoxMesh.new()
	seam_mesh.size = Vector3(0.1,0.035,8.2)
	var seam_batch := MultiMesh.new()
	seam_batch.transform_format = MultiMesh.TRANSFORM_3D
	seam_batch.mesh = seam_mesh
	seam_batch.instance_count = 5*38
	var seam_index: int = 0
	for row in range(5):
		var path := MeshInstance3D.new()
		path.name = "EastWestStoneStreet_%d" % row
		var mesh_plane := BoxMesh.new()
		mesh_plane.size = Vector3(325,0.13,8.3)
		path.mesh = mesh_plane
		path.material_override = mat
		path.position = Vector3(0,0.20,float(row)*65.0-124.0)
		settlement_root.add_child(path)
		for j in range(38):
			var world_point: Vector3 = path.position+Vector3(float(j-19)*8.3,0.09,0)
			seam_batch.set_instance_transform(seam_index,Transform3D(Basis.IDENTITY,world_point))
			seam_index += 1
	var seams := MultiMeshInstance3D.new()
	seams.name = "190StoneStreetJointsOneDrawGroup"
	seams.multimesh = seam_batch
	seams.material_override = brick
	settlement_root.add_child(seams)
	for col in range(6):
		var lane := MeshInstance3D.new()
		lane.name = "NorthSouthRoad_%d" % col
		var mesh_plane := BoxMesh.new()
		mesh_plane.size = Vector3(8.0,0.13,305)
		lane.mesh = mesh_plane
		lane.material_override = mat
		lane.position = Vector3(float(col)*54.0-135.0,0.19,5)
		settlement_root.add_child(lane)

func _make_river() -> void:
	# Physically placed world surface instead of fixed-screen wallpaper.
	var water := MeshInstance3D.new()
	water.name = "RiverValleySurface"
	var plane := PlaneMesh.new()
	plane.size = Vector2(1250,57)
	water.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.24,0.45,0.51,0.79)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.22
	mat.metallic = 0.09
	water.material_override = mat
	water.position = Vector3(0,-3.95,270)
	add_child(water)
	for crossing in [-175.0,140.0]:
		var bridge := MeshInstance3D.new()
		bridge.name = "StoneArchBridge_%d" % int(crossing)
		var deck := BoxMesh.new()
		deck.size = Vector3(9.0,0.48,67.0)
		bridge.mesh = deck
		bridge.position = Vector3(crossing,0.23,270+sin(crossing*0.003)*37.0)
		var rock_mat := StandardMaterial3D.new()
		rock_mat.albedo_color = Color("#969589")
		bridge.material_override = rock_mat
		add_child(bridge)

func _create_interface() -> void:
	var layer := CanvasLayer.new()
	layer.name = "MobileUI"
	add_child(layer)
	var board := PanelContainer.new()
	board.position = Vector2(16,13)
	layer.add_child(board)
	var stack := VBoxContainer.new()
	board.add_child(stack)
	var heading := Label.new()
	heading.text = "苍岚·人生世界 | 开源3D世界工程"
	stack.add_child(heading)
	ui_status = Label.new()
	ui_status.text = "构建场景中"
	stack.add_child(ui_status)
	var actions := HBoxContainer.new()
	stack.add_child(actions)
	var toggle_cam := Button.new()
	toggle_cam.text = "第一/第三人称"
	toggle_cam.pressed.connect(func() -> void:
		_first_person = not _first_person
		_distance = 0.1 if _first_person else 14.0
	)
	actions.add_child(toggle_cam)
	ui_action = Button.new()
	ui_action.text = "开门 / 进入"
	ui_action.pressed.connect(_interact_nearby)
	actions.add_child(ui_action)
	ui_leave = Button.new()
	ui_leave.text = "离开室内"
	ui_leave.visible = false
	ui_leave.pressed.connect(_leave_room)
	actions.add_child(ui_leave)
	var time_btn := Button.new()
	time_btn.text = "切换昼夜"
	time_btn.pressed.connect(func() -> void:
		_hour = 23.0 if _hour<18.0 else 12.0
		_refresh_light()
	)
	actions.add_child(time_btn)
	var ai_title := Label.new()
	ai_title.text = "本机NPC语言模型 / Qwen3 0.6B（完全离线）"
	stack.add_child(ai_title)
	ui_ai_status = Label.new()
	ui_ai_status.text = "正在检测手机本地模型……"
	stack.add_child(ui_ai_status)
	var chat_row := HBoxContainer.new()
	stack.add_child(chat_row)
	ui_ai_prompt = LineEdit.new()
	ui_ai_prompt.placeholder_text = "对附近的NPC说话……"
	ui_ai_prompt.custom_minimum_size = Vector2(220,46)
	ui_ai_prompt.max_length = 120
	ui_ai_prompt.text_submitted.connect(func(_value: String) -> void: _talk_to_nearby())
	chat_row.add_child(ui_ai_prompt)
	ui_ai_talk = Button.new()
	ui_ai_talk.text = "和NPC交谈"
	ui_ai_talk.disabled = true
	ui_ai_talk.pressed.connect(_talk_to_nearby)
	chat_row.add_child(ui_ai_talk)
	ui_ai_answer = Label.new()
	ui_ai_answer.text = "仅在模型文件哈希校验与本机推理引擎成功加载后开放。"
	ui_ai_answer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ui_ai_answer.custom_minimum_size = Vector2(365,0)
	stack.add_child(ui_ai_answer)
	var footer := Label.new()
	footer.text = "左半屏拖动行走 · 右半屏拖动视角 · WASD移动 · 鼠标右键转向"
	stack.add_child(footer)

func _on_local_ai_state(next_state: String, description: String) -> void:
	if ui_ai_status!=null:
		ui_ai_status.text = "离线AI：" + description
	if ui_ai_talk!=null:
		ui_ai_talk.disabled = (next_state!="ready")

func _on_local_npc_reply(entity_code: String, message: String) -> void:
	if ui_ai_answer!=null:
		ui_ai_answer.text = entity_code + "： " + message

func _on_local_ai_error(message: String) -> void:
	if ui_ai_answer!=null:
		ui_ai_answer.text = "本地模型：" + message

func _nearest_citizen(radius_m: float = 7.0) -> Node3D:
	var best: Node3D = null
	var best_sq: float = radius_m*radius_m
	for citizen in citizen_nodes:
		var d: float = citizen.global_position.distance_squared_to(avatar.global_position)
		if d<best_sq:
			best_sq = d
			best = citizen
	return best

func _talk_to_nearby() -> void:
	if _inside or local_ai==null:
		return
	var near: Node3D = _nearest_citizen()
	if near==null:
		ui_ai_answer.text = "附近7米没有可以交谈的居民，请靠近一名NPC。"
		return
	var code: String = String(near.get_meta("entity_id",""))
	var profession: String = String(near.get_meta("role","村民"))
	var prompt: String = ui_ai_prompt.text
	if prompt.strip_edges().is_empty():
		ui_ai_answer.text = "先输入你想说的话。"
		return
	var ok: bool = bool(local_ai.call("ask_npc",code,profession,prompt,_hour,
			{"place":"苍岚河西新镇"}))
	if ok:
		ui_ai_answer.text = "正在用手机本地模型计算 " + code + " 的回答……"
		ui_ai_prompt.clear()

func _physics_process(delta: float) -> void:
	if avatar == null or _inside:
		return
	var move := _virtual_movement
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		move.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		move.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		move.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		move.x += 1
	move = move.limit_length()
	var forward := Vector3(-sin(_yaw),0,-cos(_yaw))
	var right := Vector3(cos(_yaw),0,-sin(_yaw))
	var vector := forward*(-move.y) + right*move.x
	var speed: float = 6.5 if Input.is_key_pressed(KEY_SHIFT) else 4.1
	avatar.velocity.x = vector.x * speed
	avatar.velocity.z = vector.z * speed
	avatar.velocity.y -= 15.0 * delta
	avatar.move_and_slide()
	if vector.length_squared()>0.02:
		avatar.rotation.y = atan2(vector.x,vector.z)
	# Safety: wait for streamed collider or avoid free fall during chunk transitions.
	var floor_level: float = float(rules.call("height_at",avatar.position.x,avatar.position.z))
	if avatar.position.y < floor_level - 4.0:
		avatar.position.y = floor_level+2.0
		avatar.velocity.y = 0.0

func _process(delta: float) -> void:
	if avatar == null:
		return
	_stream_clock -= delta
	if _stream_clock<=0.0:
		_stream_clock = 1.75
		_load_nearby_terrain()
		for citizen in citizen_nodes:
			if citizen.global_position.distance_squared_to(avatar.global_position)<190.0*190.0:
				citizen.call("wake_near_player")
	_refresh_status_throttled(delta)
	_update_camera(delta)
	_hour = fmod(_hour+delta*0.0033,24.0)
	_npc_clock -= delta
	if _npc_clock < 0:
		_npc_clock = 11.0
		for citizen in citizen_nodes:
			citizen.call("set_hour",_hour)
			var canonical_id: String = String(citizen.get_meta("canonical_id",""))
			if not canonical_id.is_empty():
				OriginalWorldBridge.sync_actor(authoritative_world,canonical_id,
					citizen.global_position,11.0)
		_refresh_light()

func _refresh_status_throttled(delta: float) -> void:
	# UI text updates at 2Hz, not on every mobile render frame.
	var t: float = float(get_meta("hud_time",0.0))-delta
	set_meta("hud_time",t)
	if t<=0.0:
		set_meta("hud_time",0.5)
		_refresh_status()

func _refresh_light() -> void:
	if sun == null:
		return
	var day: bool = _hour>=6.0 and _hour<=19.0
	sun.light_energy = 1.15 if day else 0.07
	sun.light_color = Color("#f7dfb9") if day else Color("#8299bd")
	sun.rotation_degrees.x = -65.0 if day else -12.0
	var env: Environment = world_env.environment
	env.ambient_light_energy = 0.65 if day else 0.20

func _update_camera(delta: float) -> void:
	if cam == null or avatar == null:
		return
	if _inside:
		var center: Vector3 = _room.global_position+Vector3(0,1.8,0)
		cam.global_position = center+Vector3(0,1.0,4.8)
		cam.look_at(center+Vector3(0,1.0,-0.8))
		return
	var focus := avatar.global_position+Vector3(0,1.7,0)
	_camera_focus = _camera_focus.lerp(focus,clampf(delta*8.0,0.0,1.0))
	var distance: float = 0.08 if _first_person else _distance
	var offset := Vector3(sin(_yaw)*cos(_pitch),sin(_pitch),
			cos(_yaw)*cos(_pitch))*distance
	cam.global_position = _camera_focus+offset
	if _first_person:
		cam.look_at(_camera_focus+Vector3(-sin(_yaw),sin(_pitch),-cos(_yaw)))
	else:
		cam.look_at(_camera_focus)

func _unhandled_input(event: InputEvent) -> void:
	if _inside:
		return
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_yaw -= event.relative.x*0.006
		_pitch = clampf(_pitch+event.relative.y*0.004,0.09,1.15)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_distance = clampf(_distance*0.85,3.5,36.0)
			_first_person = false
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_distance = clampf(_distance*1.15,3.5,36.0)
			_first_person = false
		elif event.button_index == MOUSE_BUTTON_LEFT:
			_select_from_ray(event.position)
	elif event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < get_viewport().get_visible_rect().size.x*0.50 and _touch_left_id<0:
				_touch_left_id=event.index
				_touch_start=event.position
			elif _touch_right_id<0:
				_touch_right_id=event.index
		else:
			if event.index==_touch_left_id:
				_touch_left_id=-1
				_virtual_movement=Vector2.ZERO
			if event.index==_touch_right_id:
				_touch_right_id=-1
	elif event is InputEventScreenDrag:
		if event.index==_touch_left_id:
			_virtual_movement=((event.position-_touch_start)/72.0).limit_length()
		elif event.index==_touch_right_id:
			_yaw -= event.relative.x*0.004
			_pitch = clampf(_pitch+event.relative.y*0.003,0.07,1.12)

func _select_from_ray(pointer: Vector2) -> void:
	var origin: Vector3 = cam.project_ray_origin(pointer)
	var direction: Vector3 = cam.project_ray_normal(pointer)
	var query := PhysicsRayQueryParameters3D.create(origin,origin+direction*150.0)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var body: Object = hit["collider"]
	if body is Node and (body as Node).has_meta("entity_id"):
		var key: String = String((body as Node).get_meta("entity_id"))
		_selected = structures.get(key) as Node3D
	_refresh_status()

func _nearest_building() -> Node3D:
	var best: Node3D = null
	var dist_sq: float = 36.0
	for obj in structures.values():
		var b: Node3D = obj
		if String(b.get_meta("kind",""))=="courtyard_wall":
			continue
		var d: float = b.global_position.distance_squared_to(avatar.global_position)
		if d < dist_sq:
			dist_sq = d
			best = b
	return best

func _interact_nearby() -> void:
	if _inside:
		return
	var target: Node3D = _nearest_building()
	if target == null and _selected != null and _selected.global_position.distance_to(avatar.global_position)<11.0:
		target = _selected
	if target == null:
		return
	_selected = target
	if int(target.get_meta("damage",0))>=2:
		return
	building_factory.call("set_door_open",target,true)
	_room = interior_factory.call("make_room",target,Vector3(0,500.0,0))
	_room.name = "ActiveInterior"
	add_child(_room)
	_inside = true
	avatar.visible = false
	settlement_root.visible = false
	npc_root.visible = false
	prop_root.visible = false
	terrain_root.visible = false
	ui_action.visible = false
	ui_leave.visible = true
	_refresh_status()

func _leave_room() -> void:
	if not _inside:
		return
	if _selected != null:
		building_factory.call("set_door_open",_selected,false)
	_inside = false
	avatar.visible = true
	settlement_root.visible = true
	npc_root.visible = true
	prop_root.visible = true
	terrain_root.visible = true
	_room.queue_free()
	_room = null
	ui_action.visible = true
	ui_leave.visible = false
	_refresh_status()

func _refresh_status() -> void:
	if ui_status == null:
		return
	var props: Dictionary = prop_root.call("stats")
	ui_status.text = ("室内：" + String(_room.get_meta("building_id")) + " · 家具：" + str(_room.get_meta("furniture_count"))) if _inside else (
		"3D建筑:%d  NPC:%d  独立物体:%d  地形块:%d  时间:%02d:00" % [
			structures.size(),citizen_nodes.size(),int(props["independent_prop_ids"]),
			chunk_nodes.size(),int(_hour)])
	if _selected != null and not _inside:
		ui_status.text += "\n建筑ID：" + String(_selected.get_meta("entity_id",""))

func snapshot() -> Dictionary:
	var prop_stats: Dictionary = prop_root.call("stats") if prop_root != null else {}
	return {"source":"PUBLIC_GODOT3D","seed":seed,"terrain_chunks":chunk_nodes.size(),
		"buildings_and_yards":structures.size(),"npc_ids":citizen_nodes.size(),
		"original_world_actor_entities":OriginalWorldBridge.identity_count(authoritative_world),
		"world_props":int(prop_stats.get("independent_prop_ids",0)),
		"batched_instances":int(prop_stats.get("visible_mesh_instances",0)),
		"inside":_inside,"license":"MIT engine; original procedural geometry",
		"art_status":"WIP_NO_VISUAL_APPROVAL","original_apk_updated":false,
		"local_ai_state":String(local_ai.get("stage")) if local_ai!=null else "not_installed",
		"local_ai_backend":"llama.cpp GGUF embedded C++ GDExtension (when compiled)",
		"model_verified":String(local_ai.get("stage")) in ["loading","ready","thinking"] if local_ai!=null else false}
