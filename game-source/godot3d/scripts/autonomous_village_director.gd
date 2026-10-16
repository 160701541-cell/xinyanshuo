extends Node3D
## CAC-LIFE-003 autonomous physical job dispatch. No LLM necessary.
## Straight-line steering is PROTOTYPE ONLY; NavMesh and obstacle avoidance pending.
const TOWN := "CL-HX-VILLAGE-0001"
var economy: RefCounted
var assignments: Dictionary = {}
var natural_art: Dictionary = {}
var cargo_art: Dictionary = {}
var grain_deliveries: int = 0
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
	if kind=="field":
		for row in range(3):
			for col in range(4):
				_mesh("Rice_%d_%d" % [row,col],
					Vector3(float(col)*.45-.65,.35,float(row)*.45-.5),
					Vector3(.11,.67,.12),Color("#849b56"),source)
	elif kind=="tree":
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
	var farmers: int = 0
	for citizen in citizens:
		var code: String = String(citizen.get_meta("entity_id",""))
		if code.is_empty():
			continue
		var data: Dictionary = economy.get("citizens").get(code,{})
		var role: String = String(data.get("profession",""))
		if role not in ["woodcutter","quarryman","farmer"]:
			continue
		if role=="farmer" and (farmers>=2 or assigned==0):
			continue
		if role!="farmer" and assigned>=10:
			continue
		var type: String = "tree" if role=="woodcutter" else ("stone" if role=="quarryman" else "field")
		var node_id: String = ("AUTO-FIELD-%08d" if type=="field" else "AUTO-NAT-%08d") % (assigned+1)
		var pos: Vector3 = Vector3(citizen.get("home"))+Vector3(11.0,0,10.0)
		var accepted: bool = bool(economy.call("register_field",node_id,TOWN)) if type=="field" else bool(economy.call("register_natural_node",node_id,TOWN,type,9))
		if not accepted:
			continue
		if type=="field":
			farmers+=1
		natural_art[node_id] = _make_node(node_id,pos,type)
		assignments[code] = {"node_id":node_id,"kind":type,
			"citizen":citizen,"phase":"to_resource","depot":Vector3(citizen.get("home")),
			"done":0}
		citizen.call("assign_work_destination",pos)
		assigned+=1
		# Bound near-field dispatch: 8 timber/stone NPCs plus 2 actual farmers.
		if assigned>=10 and farmers>=2:
			break
	assert(assignments.size()>=8,"Autonomous citizens have no jobs")

func _process(delta: float) -> void:
	if economy==null:
		return
	state_time+=delta
	if state_time<0.20:
		return
	state_time=0
	# Never call legacy request_construction here. Resource haulers deliver
	# only raw wood/stone/grain. NPCBuilding assigns living tradesmen to craft
	# reusable materials and physically place each 3D structural part.
	for code in assignments.keys():
		var job: Dictionary = assignments[code]
		var citizen: Node3D = job["citizen"]
		if not is_instance_valid(citizen):
			continue
		var phase: String = String(job["phase"])
		if phase=="done":
			continue
		if phase=="waiting_field":
			var plot: Dictionary = economy.get("harvested_fields").get(job["node_id"],{})
			if bool(plot.get("ready",false)):
				(natural_art[job["node_id"]] as Node3D).visible=true
				job["phase"]="to_resource"
				citizen.call("assign_work_destination",
					(natural_art[job["node_id"]] as Node3D).position)
			continue
		if phase=="to_resource" and bool(citizen.call("reached_work_destination",1.20)):
			var picked: bool = bool(economy.call("gather_field_to_actor",code,String(job["node_id"]))) if job["kind"]=="field" else bool(economy.call("gather_to_actor",code,String(job["node_id"])))
			if picked:
				harvested_jobs+=1
				if job["kind"]=="field":
					(natural_art[job["node_id"]] as Node3D).visible=false
				else:
					var node_info: Dictionary = economy.get("natural_nodes")[job["node_id"]]
					if bool(node_info["depleted"]):
						(natural_art[job["node_id"]] as Node3D).visible=false
				_show_cargo(code,citizen,String(job["kind"]))
				job["phase"]="to_depot"
				citizen.call("assign_work_destination",job["depot"])
			else:
				job["phase"]="done"
				citizen.call("cancel_work_destination")
		elif phase=="to_depot" and bool(citizen.call("reached_work_destination",1.20)):
			if bool(economy.call("deliver_carried",code)):
				completed_deliveries+=1
				_clear_cargo(code)
				if job["kind"]=="field":
					grain_deliveries+=1
				job["done"]=int(job["done"])+1
				if job["kind"]=="field":
					job["phase"]="waiting_field"
					citizen.call("cancel_work_destination")
				else:
					job["phase"]="to_resource"
					citizen.call("assign_work_destination",
						(natural_art[job["node_id"]] as Node3D).position)
			else:
				job["phase"]="done"
				citizen.call("cancel_work_destination")
	# Construction visualization is exclusively handled by NPCBuilding
	# after real material production, physical delivery and named NPC labor.

func _show_cargo(code: String, person: Node3D, kind: String) -> void:
	_clear_cargo(code)
	var cargo := Node3D.new()
	cargo.name = "RealCarried_%s" % code.replace("-","_")
	person.add_child(cargo)
	_mesh("Physical_"+kind,Vector3(0,1.10,-.35),
		Vector3(.65,.44,.65),
		Color("#b5a064") if kind=="field" else (
			Color("#805a3d") if kind=="tree" else Color("#93928a")),cargo)
	cargo_art[code] = cargo

func _clear_cargo(code: String) -> void:
	if cargo_art.has(code):
		var old: Node3D = cargo_art[code]
		if is_instance_valid(old):
			old.queue_free()
		cargo_art.erase(code)

func stats() -> Dictionary:
	var working: int = 0
	for job in assignments.values():
		if job["phase"]!="done":
			working+=1
	return {"workers":assignments.size(),"active_workers":working,
		"harvested":harvested_jobs,"delivered":completed_deliveries,
		"new_houses_visible":construction_built,
		"grain_deliveries":grain_deliveries, "visible_cargo":cargo_art.size(),
		"remaining_trees":int(economy.call("resource_remaining","tree")),
		"remaining_stone":int(economy.call("resource_remaining","stone")),
		"navigation":"direct_steering_only_not_navmesh"}
