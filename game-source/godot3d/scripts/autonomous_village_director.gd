extends Node3D
## CAC-LIFE-003 autonomous physical job dispatch. No LLM necessary.
## Straight-line steering is PROTOTYPE ONLY; NavMesh and obstacle avoidance pending.
const TOWN := "CL-HX-VILLAGE-0001"
var economy: RefCounted
var assignments: Dictionary = {}
var natural_art: Dictionary = {}
var warehouse_spot := Vector3(0,0,26)
var completed_deliveries: int = 0
var harvested_jobs: int = 0
var construction_built: int = 0
var state_time: float = 0.0
var _last_homes: int = 22
var _construction_visuals: int = 0
var _has_started_house: bool = false

func _mesh(kind: String,at: Vector3,scale3: Vector3,color: Color,
		parent: Node3D) -> MeshInstance3D:
	var result := MeshInstance3D.new()
	result.name = kind
	var shape := BoxMesh.new()
	shape.size = scale3
	result.mesh = shape
	result.position = at
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 1.0
	result.material_override = mat
	parent.add_child(result)
	return result

func _make_node(id: String,point: Vector3,kind: String) -> Node3D:
	var source := Node3D.new()
	source.name = id
	source.position = point
	add_child(source)
	if kind=="tree":
		_mesh("TreeTrunk",Vector3(0,1.1,0),Vector3(.48,2.2,.48),
			Color("#72533c"),source)
		_mesh("TreeCrown",Vector3(0,2.7,0),Vector3(1.8,1.65,1.8),
			Color("#65865c"),source)
	else:
		_mesh("FiniteQuarryStone",Vector3(0,.38,0),Vector3(1.3,.75,1.2),
			Color("#8a8e89"),source)
	return source

func setup(sim: RefCounted, citizens: Array[Node3D]) -> void:
	economy = sim
	name = "AutonomousNPCJobsWorldVisible"
	_last_homes = int(economy.get("villages")[TOWN]["homes"])
	var assigned: int = 0
	for citizen in citizens:
		var code: String = String(citizen.get_meta("entity_id",""))
		if code.is_empty():
			continue
		var data: Dictionary = economy.get("citizens").get(code,{})
		var role: String = String(data.get("profession",""))
		if role not in ["woodcutter","quarryman"]:
			continue
		var type: String = "tree" if role=="woodcutter" else "stone"
		var node_id: String = "AUTO-NAT-%08d" % (assigned+1)
		var pos: Vector3 = citizen.home+Vector3(11.0,0,10.0)
		if not bool(economy.call("register_natural_node",node_id,TOWN,type,9)):
			continue
		natural_art[node_id] = _make_node(node_id,pos,type)
		assignments[code] = {"node_id":node_id,"kind":type,
			"citizen":citizen,"phase":"to_resource","depot":citizen.home,
			"done":0}
		citizen.call("assign_work_destination",pos)
		assigned+=1
		# Bound near-field dispatch: eight independent NPCs work in first town.
		if assigned>=8:
			break
	assert(assignments.size()>0,"Autonomous citizens have no jobs")

func _process(delta: float) -> void:
	if economy==null:
		return
	state_time+=delta
	if state_time<0.20:
		return
	state_time=0
	for code in assignments.keys():
		var job: Dictionary = assignments[code]
		var citizen: Node3D = job["citizen"]
		if not is_instance_valid(citizen):
			continue
		var phase: String = String(job["phase"])
		if phase=="done":
			continue
		if phase=="to_resource" and bool(citizen.call("reached_work_destination",1.20)):
			if bool(economy.call("gather_to_actor",code,String(job["node_id"]))):
				harvested_jobs+=1
				var node_info: Dictionary = economy.get("natural_nodes")[job["node_id"]]
				if bool(node_info["depleted"]):
					natural_art[job["node_id"]].visible=false
				job["phase"]="to_depot"
				citizen.call("assign_work_destination",job["depot"])
			else:
				job["phase"]="done"
				citizen.call("cancel_work_destination")
		elif phase=="to_depot" and bool(citizen.call("reached_work_destination",1.20)):
			if bool(economy.call("deliver_carried",code)):
				completed_deliveries+=1
				job["done"]=int(job["done"])+1
				job["phase"]="to_resource"
				citizen.call("assign_work_destination",
					natural_art[job["node_id"]].position)
			else:
				job["phase"]="done"
				citizen.call("cancel_work_destination")
	# Physically instantiate a small Chinese-style house only after simulation
	# has paid real materials and the authoritative time-tick completes it.
	var town: Dictionary = economy.get("villages")[TOWN]
	if not _has_started_house and completed_deliveries>=1:
		_has_started_house=bool(economy.call("request_construction",TOWN,"home"))
	if int(town["homes"])>_last_homes:
		var old_count: int = _last_homes
		_last_homes=int(town["homes"])
		for counter in range(_last_homes-old_count):
			_make_house(construction_built)
			construction_built+=1

func _make_house(slot: int) -> void:
	var house := Node3D.new()
	house.name="BuiltFromActualVillageResources_%02d" % slot
	house.position = Vector3(12+slot*6,0,25)
	add_child(house)
	_mesh("PlasteredWalls",Vector3(0,1.25,0),Vector3(3.8,2.5,2.8),
		Color("#c3b8a5"),house)
	_mesh("GreyTileRoof",Vector3(0,2.73,0),Vector3(4.5,.57,3.35),
		Color("#59686a"),house)
	_mesh("WoodenDoor",Vector3(0,1.05,1.44),Vector3(.85,1.8,.05),
		Color("#775c46"),house)

func stats() -> Dictionary:
	var working: int = 0
	for job in assignments.values():
		if job["phase"]!="done":
			working+=1
	return {"workers":assignments.size(),"active_workers":working,
		"harvested":harvested_jobs,"delivered":completed_deliveries,
		"new_houses_visible":construction_built,
		"remaining_trees":int(economy.call("resource_remaining","tree")),
		"remaining_stone":int(economy.call("resource_remaining","stone")),
		"navigation":"direct_steering_only_not_navmesh"}
