extends Node3D
## CAC-LIFE-002: visible low-poly production loop inside the SAME existing 3D world.
## All state transitions are accepted only by the authoritative life_sim.
const VILLAGE := "CL-HX-VILLAGE-0001"
const TREE := "SM-LOOP-00000001"
const FIELD := "FIELD-LOOP-00000001"
var sim: RefCounted
var worker_id: String
var worker_node: Node3D
var work_tree: Node3D
var tree_stump: Node3D
var log_load: Node3D
var new_house: Node3D
var crop_patch: Node3D
var food_basket: Node3D
var house_started: bool = false
var steps: Array[String] = []
var _run_anim: bool = false
var _run_clock: float = 0.0
var _start: Vector3 = Vector3(8,0,39)
var _storage: Vector3 = Vector3(1,0,39)

func _box(parent: Node3D, label: String, at: Vector3, dim: Vector3,
		tint: Color) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = label
	item.position = at
	var mesh := BoxMesh.new()
	mesh.size = dim
	item.mesh = mesh
	var paint := StandardMaterial3D.new()
	paint.albedo_color = tint
	paint.roughness = 1.0
	item.material_override = paint
	parent.add_child(item)
	return item

func setup(world_sim: RefCounted, actor_id: String) -> void:
	sim = world_sim
	worker_id = actor_id
	name = "CAC_LifeWorksite_PlayerVisible"
	sim.call("register_natural_node",TREE,VILLAGE,"tree",3)
	sim.call("register_field",FIELD,VILLAGE)
	sim.call("register_resource_position", TREE, _start)
	sim.call("register_resource_position", FIELD, Vector3(10,0,47))
	work_tree = Node3D.new()
	work_tree.name = "FiniteHarvestableTree"
	work_tree.position = _start
	add_child(work_tree)
	_box(work_tree,"Trunk",Vector3(0,1.3,0),Vector3(.53,2.6,.53),Color("#79614e"))
	_box(work_tree,"LeafTop",Vector3(0,3.1,0),Vector3(2.3,1.8,2.0),Color("#60835a"))
	_box(work_tree,"LeafMiddle",Vector3(0,2.6,0),Vector3(2.9,1.2,2.3),Color("#7a986b"))
	tree_stump = Node3D.new()
	tree_stump.name = "RemainsAfterChopping"
	tree_stump.visible = false
	tree_stump.position = _start
	add_child(tree_stump)
	_box(tree_stump,"Stump",Vector3(0,.24,0),Vector3(.65,.47,.65),Color("#80634d"))
	log_load = Node3D.new()
	log_load.name = "VisibleTransportLogs"
	log_load.visible = false
	add_child(log_load)
	for i in range(3):
		_box(log_load,"CarryableLog_%d"%i,Vector3(.8,i*.27+.18,.25),
			Vector3(1.1,.23,.26),Color("#966f4d"))
	new_house = Node3D.new()
	new_house.name = "MaterialPaidNewHouse"
	new_house.visible = false
	new_house.position = Vector3(-6,0,43)
	add_child(new_house)
	_box(new_house,"Foundation",Vector3(0,.12,0),Vector3(4.4,.24,3.3),Color("#9b9183"))
	_box(new_house,"ClayWall",Vector3(0,1.25,0),Vector3(3.8,2.25,2.8),Color("#ccbea8"))
	_box(new_house,"ChineseGreyRoof",Vector3(0,2.60,0),Vector3(4.5,.65,3.4),Color("#58646a"))
	_box(new_house,"Door",Vector3(0,1.10,1.47),Vector3(.8,1.82,.06),Color("#62503c"))
	crop_patch = Node3D.new()
	crop_patch.name = "ReplantingField"
	crop_patch.position = Vector3(10,0,47)
	add_child(crop_patch)
	for i in range(8):
		_box(crop_patch,"Crops_%02d"%i,Vector3(float(i%4)*.75, .31,
				float(i/4)*.8),Vector3(.20,.63,.18),Color("#90a65e"))
	food_basket = Node3D.new()
	food_basket.name = "VisibleFoodConsumed"
	food_basket.visible = false
	food_basket.position = _storage
	add_child(food_basket)
	_box(food_basket,"CookedFood",Vector3(0,.4,-1.0),
		Vector3(1.1,.75,.85),Color("#bb934d"))
	worker_node = Node3D.new()
	worker_node.name = "SimulatedCarrier"
	add_child(worker_node)
	worker_node.position = _start
	_box(worker_node,"WorkerOutfit",Vector3(0,1.0,0),Vector3(.62,1.40,.38),
		Color("#839488"))
	_box(worker_node,"Head",Vector3(0,1.90,0),Vector3(.30,.34,.31),
		Color("#c5a78d"))

func action_chop() -> bool:
	if sim==null or not bool(sim.call("gather_to_actor",worker_id,TREE)):
		return false
	work_tree.visible=false
	tree_stump.visible=true
	log_load.visible=true
	_run_anim=true
	_run_clock=0
	steps.append("砍倒实物树：木材转入工人负载，村庄库存尚未增加")
	return true

func action_deliver() -> bool:
	if sim==null:
		return false
	# Player cannot deliver from across the map: carrier must reach depot.
	if worker_node.position.distance_to(_storage)>1.5:
		return false
	if not bool(sim.call("deliver_carried",worker_id)):
		return false
	log_load.visible=false
	steps.append("工人到达仓库：实际背负的物资已入库")
	return true

func action_build_house() -> bool:
	if sim==null or house_started:
		return false
	if not bool(sim.call("request_construction",VILLAGE,"home")):
		return false
	house_started=true
	steps.append("付出12木与6石：等待世界时间推进后才能出现新房")
	return true

func action_harvest() -> bool:
	if sim==null or not bool(sim.call("harvest_field",VILLAGE,FIELD,worker_id)):
		return false
	crop_patch.visible=false
	worker_node.position = crop_patch.position
	_run_anim = true
	_run_clock = 0.0
	steps.append("农田收获5粮装入工人背包：运到仓库后才会入库，次日复长")
	return true

func action_cook() -> bool:
	if sim==null or not bool(sim.call("prepare_meal",VILLAGE,worker_id)):
		return false
	food_basket.visible=true
	steps.append("真实扣除粮食2、水1，做出食物3")
	return true

func action_eat() -> bool:
	if sim==null or not bool(sim.call("feed_citizen",worker_id)):
		return false
	food_basket.visible=false
	steps.append("食物实际减少1，工人饥饿值降低")
	return true

func _process(delta: float) -> void:
	if sim==null:
		return
	if _run_anim:
		_run_clock += delta
		worker_node.position = worker_node.position.move_toward(_storage,delta*2.1)
		log_load.position = worker_node.position
		if worker_node.position.distance_to(_storage)<.05:
			_run_anim=false
			steps.append("运输完成：点击入库，木料不会凭空传送")
	if house_started and not new_house.visible:
		var town: Dictionary = sim.get("villages")[VILLAGE]
		if int(town["homes"])>22:
			new_house.visible=true
			steps.append("支付成本且经过建造时间：房屋出现在3D地形里")
	var fields: Dictionary = sim.get("harvested_fields")
	if fields.has(FIELD) and bool(fields[FIELD]["ready"]):
		crop_patch.visible=true

func stats() -> Dictionary:
	return {"steps":steps.size(),"carrying":sim.get("carried_by_actor").has(worker_id),
		"tree_cut":not work_tree.visible,"house_visible":new_house.visible,
		"crops_visible":crop_patch.visible,"food_visible":food_basket.visible,
		"worker_at_storage":worker_node.position.distance_to(_storage)<1.5}
