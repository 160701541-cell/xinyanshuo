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
const LocalNPCIntents = preload("res://scripts/npc_intent_policy.gd")
const LifeSim = preload("res://scripts/worldbox_life_sim.gd")
const Worksites = preload("res://scripts/worldbox_visible_worksite.gd")
const AutonomousDirector = preload("res://scripts/autonomous_village_director.gd")
const NPCBuilding = preload("res://scripts/npc_building_system.gd")
# Authentic earlier Canglan 3D economy/identity source has been audited and
# safely migrated to the PUBLIC repository without any signing credentials.
const OriginalWorldState = preload("res://scripts/world_state.gd")
const OriginalWorldBridge = preload("res://scripts/world_state_bridge.gd")
const CHUNK_SIZE: float = 96.0
const VISIBLE_RADIUS: int = 2

var seed: int = 20261016
var rules: RefCounted
var authoritative_world: RefCounted
var life_sim: RefCounted
var visible_worksite: Node3D
var autonomous_director: Node3D
var npc_building_system: Node3D
var ui_auto: Label
var ui_work_result: Label
var _life_last_hour: int = 12
var _life_day: int = 1
var ui_life: Label
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
var ui_panel: PanelContainer
var ui_toggle: Button
var ui_scroller: ScrollContainer
var ui_status: Label
var ui_npc_details: Label
var ui_farmer_a: Button
var ui_farmer_b: Button
var inspected_npc: String = ""
var npc_node_index: Dictionary = {}
var npc_text_refresh_accum: float = 0.0
var ui_action: Button
var ui_leave: Button
var local_ai: Node
var npc_intent_policy: RefCounted
var _local_npc_ai_budget_clock: float = 55.0
var _local_npc_ai_cursor: int = 0
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
	# WorldBox-like real simulation continues regardless of local LLM availability.
	life_sim = LifeSim.new()
	life_sim.call("start",seed)
	life_sim.call("create_village","CL-HX-VILLAGE-0001",
		{"homes":22,"fields":7,"food":280,"grain":100,"water":90,
		 "wood":85,"stone":45,"clay":30,"coin":12})
	# The world must contain actual tradesmen with their own persistent IDs.
	# WorldX generates reusable MATERIAL surface art, not prebuilt houses.
	var work_roles := ["farmer","woodcutter","quarryman","cook","potter",
		"farmer","farmer","cook","woodcutter","farmer",
		"carpenter","mason","builder","guard"]
	for n in range(citizen_nodes.size()):
		life_sim.call("add_citizen",
			String(citizen_nodes[n].get_meta("entity_id","")),
			"CL-HX-VILLAGE-0001",work_roles[n%work_roles.size()],20+n%42)
		var person_id: String = String(citizen_nodes[n].get_meta("entity_id",""))
		var profile: Dictionary = life_sim.get("citizens")[person_id]
		citizen_nodes[n].call("refresh_text_status",profile)
	prop_root.call("build",rules,seed)
	# One tangible gameplay loop: chop physical tree -> carrier walks to depot
	# -> materials delivered -> paid house -> crops -> food -> eating.
	visible_worksite = Worksites.new()
	add_child(visible_worksite)
	if not citizen_nodes.is_empty():
		visible_worksite.call("setup",life_sim,
			String(citizen_nodes[0].get_meta("entity_id","")))
	# Autonomous profession AI operates on original 3D NPC nodes, using
	# finite physical world resources; the optional LLM never mints materials.
	autonomous_director = AutonomousDirector.new()
	add_child(autonomous_director)
	autonomous_director.call("setup",life_sim,citizen_nodes)
	# New structures come from real craftsperson NPCs, carried materials and
	# visible building stages, NOT a pre-rendered 2D/HD2D/4-facade background.
	npc_building_system = NPCBuilding.new()
	add_child(npc_building_system)
	npc_building_system.call("setup",life_sim,citizen_nodes)
	# The actual GGUF/llama.cpp service is part of the same 3D game process.
	# When native binary or verified weights are missing it reports disabled,
	# never returns scripted dialog disguised as AI.
	local_ai = LocalAI.new()
	local_ai.name = "OfflineLocalAI"
	npc_intent_policy = LocalNPCIntents.new()
	local_ai.connect("state_changed",Callable(self,"_on_local_ai_state"))
	local_ai.connect("npc_reply",Callable(self,"_on_local_npc_reply"))
	local_ai.connect("npc_intent",Callable(self,"_on_autonomous_npc_intent"))
	local_ai.connect("inference_failed",Callable(self,"_on_local_ai_error"))
	add_child(local_ai)
	_create_interface()
	_on_local_ai_state(String(local_ai.get("stage")),String(local_ai.get("info")))
	_update_camera(1.0)
	_refresh_status()
	print("CANGLAN_3D_WORLD_READY ",snapshot())

func _on_worksite_action(method_name: String) -> void:
	if visible_worksite==null:
		return
	var result: bool = bool(visible_worksite.call(method_name))
	var events: Array = visible_worksite.get("steps")
	if ui_work_result!=null:
		if result and not events.is_empty():
			ui_work_result.text = String(events.back())
		elif method_name=="action_deliver":
			ui_work_result.text = "木材还未送到村庄仓库，等搬运工走到仓库后再入库。"
		else:
			ui_work_result.text = "操作未达成：请检查材料、食物、农田复长和操作顺序。"
	_refresh_status()

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
	env.ambient_light_energy = 0.34
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_env.environment = env
	sun = DirectionalLight3D.new()
	sun.name = "TimeOfDaySun"
	sun.rotation_degrees = Vector3(-58,-33,0)
	sun.light_color = Color("#f7dfb9")
	sun.light_energy = 0.70
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 72.0
	add_child(sun)

func _build_avatar() -> void:
	avatar = CharacterBody3D.new()
	avatar.name = "PlayerWithCollision"
	avatar.position = Vector3(0,3.0,38.0)
	add_child(avatar)
	var shape := CollisionShape3D.new()
	shape.name = "CollisionShape3D"
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
				civil.connect("inspection_requested",Callable(self,"_inspect_npc"))
				npc_node_index[id] = civil
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
	# Mobile-first layout: the world is playable without a giant always-open overlay.
	ui_toggle = Button.new()
	ui_toggle.name = "ToggleCompactHUD"
	ui_toggle.text = "☰ 人物 / 玩法"
	ui_toggle.position = Vector2(12,12)
	ui_toggle.custom_minimum_size = Vector2(144,46)
	ui_toggle.pressed.connect(_toggle_game_panel)
	layer.add_child(ui_toggle)
	ui_panel = PanelContainer.new()
	ui_panel.name = "CollapsibleGamePanel"
	ui_panel.position = Vector2(12,65)
	ui_panel.visible = false
	var backing := StyleBoxFlat.new()
	backing.bg_color = Color(0.10,0.15,0.17,0.90)
	backing.set_corner_radius_all(9)
	backing.content_margin_left = 10.0
	backing.content_margin_right = 10.0
	backing.content_margin_top = 8.0
	backing.content_margin_bottom = 8.0
	ui_panel.add_theme_stylebox_override("panel",backing)
	layer.add_child(ui_panel)
	ui_scroller = ScrollContainer.new()
	ui_scroller.name = "MobileGameplayScroll"
	ui_scroller.custom_minimum_size = Vector2(420,0)
	ui_scroller.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ui_scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ui_panel.add_child(ui_scroller)
	var viewport_height: float = get_viewport().get_visible_rect().size.y
	ui_panel.custom_minimum_size = Vector2(440,minf(545.0,maxf(270.0,viewport_height-82.0)))
	var stack := VBoxContainer.new()
	stack.custom_minimum_size = Vector2(404,0)
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ui_scroller.add_child(stack)
	var heading := Label.new()
	heading.text = "苍岚·人生世界 | NPC自主建设真实3D世界"
	stack.add_child(heading)
	ui_status = Label.new()
	ui_status.text = "构建场景中"
	stack.add_child(ui_status)
	ui_life = Label.new()
	ui_life.text = "村镇生活模拟：初始化中"
	stack.add_child(ui_life)
	ui_auto = Label.new()
	ui_auto.text = "自主村民：等待工人出发……"
	stack.add_child(ui_auto)
	var panel := PanelContainer.new()
	panel.name = "IndividualCitizenInfoPanel"
	stack.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var heading_npc := Label.new()
	heading_npc.text = "NPC个体档案 · 3D文字人物测试"
	column.add_child(heading_npc)
	var selector := HBoxContainer.new()
	column.add_child(selector)
	var farmer_ids: Array[String] = []
	for npc in citizen_nodes:
		var code: String = String(npc.get_meta("entity_id",""))
		var profile: Dictionary = life_sim.get("citizens").get(code,{})
		if String(profile.get("profession",""))=="farmer":
			farmer_ids.append(code)
			if farmer_ids.size()>=2:
				break
	assert(farmer_ids.size()==2,"Two unique farmer entities required")
	ui_farmer_a = Button.new()
	ui_farmer_a.name = "InspectFarmerA"
	ui_farmer_a.text = "农民甲 · "+String(npc_node_index[farmer_ids[0]].get_meta("display_name"))
	ui_farmer_a.pressed.connect(_inspect_npc.bind(farmer_ids[0]))
	selector.add_child(ui_farmer_a)
	ui_farmer_b = Button.new()
	ui_farmer_b.name = "InspectFarmerB"
	ui_farmer_b.text = "农民乙 · "+String(npc_node_index[farmer_ids[1]].get_meta("display_name"))
	ui_farmer_b.pressed.connect(_inspect_npc.bind(farmer_ids[1]))
	selector.add_child(ui_farmer_b)
	ui_npc_details = Label.new()
	ui_npc_details.name = "CitizenLiveStatus"
	ui_npc_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ui_npc_details.custom_minimum_size = Vector2(365,0)
	column.add_child(ui_npc_details)
	inspected_npc = farmer_ids[0]
	_refresh_inspected_npc()
	var work_header := Label.new()
	work_header.text = "生活闭环试玩 · 砍树→运输→建房→收粮→煮饭→进食"
	stack.add_child(work_header)
	var workflow := GridContainer.new()
	workflow.columns = 3
	stack.add_child(workflow)
	for pair in [
		["1.砍树","action_chop"],
		["2.木材入库","action_deliver"],
		["3.建房","action_build_house"],
		["4.收粮","action_harvest"],
		["5.煮饭","action_cook"],
		["6.进食","action_eat"]]:
		var btn := Button.new()
		btn.text = String(pair[0])
		btn.custom_minimum_size = Vector2(110,43)
		var verb: String = String(pair[1])
		btn.pressed.connect(_on_worksite_action.bind(verb))
		workflow.add_child(btn)
	ui_work_result = Label.new()
	ui_work_result.text = "点击砍树：实体消失，工人搬木材回库；未运到仓库无法入库。"
	ui_work_result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ui_work_result.custom_minimum_size = Vector2(360,0)
	stack.add_child(ui_work_result)
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

func _toggle_game_panel() -> void:
	if ui_panel==null:
		return
	ui_panel.visible = not ui_panel.visible
	if ui_toggle!=null:
		ui_toggle.text = "× 关闭信息" if ui_panel.visible else "☰ 人物 / 玩法"

func _inspect_npc(actor_id: String) -> void:
	if not npc_node_index.has(actor_id):
		return
	inspected_npc = actor_id
	if ui_panel!=null:
		ui_panel.visible = true
		if ui_toggle!=null:
			ui_toggle.text = "× 关闭信息"
	for npc in citizen_nodes:
		npc.call("select_text_marker",
			String(npc.get_meta("entity_id",""))==actor_id)
	_refresh_inspected_npc()

func _refresh_inspected_npc() -> void:
	if ui_npc_details==null or life_sim==null or not npc_node_index.has(inspected_npc):
		return
	var record: Dictionary = life_sim.get("citizens").get(inspected_npc,{})
	if record.is_empty():
		return
	var npc: Node3D = npc_node_index[inspected_npc]
	var job_name: String = String({
		"farmer":"农民","woodcutter":"樵夫","quarryman":"采石工",
		"cook":"厨师","potter":"陶工"}.get(String(record["profession"]),record["profession"]))
	var load: Dictionary = life_sim.get("carried_by_actor").get(inspected_npc,{})
	var cargo: String = "无" if load.is_empty() else (
		String(load.get("kind",""))+" x"+str(load.get("amount",0)))
	var loc: Vector3 = npc.global_position
	ui_npc_details.text = "%s / %s / 年龄%d\n身份编码: %s\n精力%d/100  饥饿%d/100  心情%d/100\n状态: %s  携带: %s\n3D坐标: %.1f, %.1f, %.1f" % [
		String(npc.get_meta("display_name","居民")),job_name,
		int(record.get("age",0)),inspected_npc,int(record.get("energy",0)),
		int(record.get("hunger",0)),int(record.get("mood",0)),
		String(record.get("schedule","idle")),cargo,loc.x,loc.y,loc.z]

func _on_local_ai_state(next_state: String, description: String) -> void:
	if ui_ai_status!=null:
		ui_ai_status.text = "离线AI：" + description
	if ui_ai_talk!=null:
		ui_ai_talk.disabled = (next_state!="ready")

func _on_autonomous_npc_intent(entity_code: String, response: String) -> void:
	if npc_intent_policy==null or life_sim==null:
		return
	var choice: String = String(npc_intent_policy.call("parse_intent",response))
	if choice.is_empty():
		return
	var actor: Node3D = npc_node_index.get(entity_code) as Node3D
	if actor==null:
		return
	var now: int = int(life_sim.get("day"))*24 + int(life_sim.get("hour"))
	var accepted: bool = bool(npc_intent_policy.call("apply_intent",entity_code,
		choice,life_sim,actor,npc_building_system,now))
	if accepted and ui_work_result!=null:
		ui_work_result.text = "离线NPC自主决定：" + entity_code + " → " + choice

func _ask_one_autonomous_npc(delta: float) -> void:
	if local_ai==null or life_sim==null or npc_intent_policy==null:
		return
	_local_npc_ai_budget_clock -= delta
	if _local_npc_ai_budget_clock>0.0:
		return
	# 0.6B on mobile is shared: one suggestion at most every 75 seconds.
	_local_npc_ai_budget_clock=75.0
	if String(local_ai.get("stage"))!="ready" or citizen_nodes.is_empty():
		return
	var profiles: Dictionary = life_sim.get("citizens")
	for offset in range(citizen_nodes.size()):
		var index: int = (_local_npc_ai_cursor+offset)%citizen_nodes.size()
		var actor: Node3D = citizen_nodes[index]
		if actor.global_position.distance_squared_to(avatar.global_position)>35.0*35.0:
			continue
		var code: String = String(actor.get_meta("entity_id",""))
		if not profiles.has(code):
			continue
		var person: Dictionary = profiles[code]
		if bool(actor.get("_externally_assigned_job")):
			continue  # Never hijack physical work already assigned by NPC builders.
		var town: Dictionary = life_sim.get("villages")[String(person["village_id"])]
		var context: Dictionary = {
			"energy":int(person["energy"]),
			"hunger":int(person["hunger"]),
			"food":int((town["stock"] as Dictionary).get("food",0)),
			"construction_pending":not String(npc_building_system.get("current_project")).is_empty()
		}
		var queued: bool = bool(local_ai.call("ask_npc_intent",code,
			String(person["profession"]),_hour,context))
		if queued:
			_local_npc_ai_cursor=(index+1)%citizen_nodes.size()
		return

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
	_ask_one_autonomous_npc(delta)
	npc_text_refresh_accum+=delta
	if npc_text_refresh_accum>=0.6 and life_sim!=null:
		npc_text_refresh_accum=0.0
		var profiles: Dictionary = life_sim.get("citizens")
		for npc in citizen_nodes:
			if npc.global_position.distance_squared_to(avatar.global_position)<10000.0:
				var code: String = String(npc.get_meta("entity_id",""))
				if profiles.has(code):
					npc.call("refresh_text_status",profiles[code])
		_refresh_inspected_npc()
	_update_camera(delta)
	_hour = fmod(_hour+delta*0.0033,24.0)
	# One authoritative, bounded economy tick per in-game hour;
	# visual crowds and NPC speech cannot create free stock.
	var current_hour: int = int(_hour)
	if current_hour != _life_last_hour and life_sim != null:
		_life_last_hour = current_hour
		life_sim.call("tick")
		if ui_life != null:
			var state: Dictionary = life_sim.call("get_world_summary")
			var town: Dictionary = life_sim.get("villages")["CL-HX-VILLAGE-0001"]
			var stock: Dictionary = town["stock"]
			ui_life.text = "生活模拟 第%d日 %02d时 | 村民%d | 繁荣%d | 粮%d 木%d 石%d 食物%d" % [
				int(state["day"]),int(state["hour"]),int(state["population"]),
				int(state["average_prosperity"]),int(stock["grain"]),int(stock["wood"]),
				int(stock["stone"]),int(stock["food"])]
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
		if autonomous_director!=null and ui_auto!=null:
			var work: Dictionary = autonomous_director.call("stats")
			ui_auto.text = "NPC真实生产：%d名 / 采集%d / 实际运回%d / 林木剩余%d" % [
				int(work["workers"]),int(work["harvested"]),int(work["delivered"]),
				int(work["remaining_trees"])]
			if npc_building_system!=null:
				var progress: Dictionary = npc_building_system.call("stats")
				ui_auto.text += "\\nNPC规划: %s | 施工阶段:%s | 实际已建:%d" % [
					String(progress["active_site"]),String(progress["stage"]),
					int(progress["completed"])]
				ui_auto.text += "\\n木匠/石匠/陶匠 → 材料仓库 → %s 实地建设" % String(progress["builder_id"])

func _refresh_light() -> void:
	if sun == null:
		return
	var day: bool = _hour>=6.0 and _hour<=19.0
	sun.light_energy = 0.70 if day else 0.07
	sun.light_color = Color("#f7dfb9") if day else Color("#8299bd")
	sun.rotation_degrees.x = -65.0 if day else -12.0
	var env: Environment = world_env.environment
	env.ambient_light_energy = 0.34 if day else 0.16

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
		if npc_node_index.has(key):
			_inspect_npc(key)
			return
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
		"npc_material_build_status":npc_building_system.call("stats") if npc_building_system!=null else {},
		"local_ai_state":String(local_ai.get("stage")) if local_ai!=null else "not_installed",
		"npc_local_ai_intents":npc_intent_policy.call("snapshot") if npc_intent_policy!=null else {},
		"local_ai_backend":"llama.cpp GGUF embedded C++ GDExtension (when compiled)",
		"model_verified":String(local_ai.get("stage")) in ["loading","ready","thinking"] if local_ai!=null else false}
