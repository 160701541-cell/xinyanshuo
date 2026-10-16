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
var _citizens: Array[Node3D] = []

func setup(sim: RefCounted, citizens: Array[Node3D]) -> void:
	economy = sim
	_citizens = citizens
	name = "AutonomousNPCJobsWorldVisible"
	_last_homes = int(economy.get("villages")[TOWN]["homes"])
	_dispatch_idle_workers()

func _dispatch_idle_workers() -> void:
	if economy == null:
		return
	var reserved: Dictionary = {}
	for job in assignments.values():
		if String(job.get("phase", "")) not in ["done", "waiting_resource", "waiting_field"]:
			reserved[String(job["node_id"])] = true
	for citizen in _citizens:
		if not is_instance_valid(citizen):
			continue
		var code: String = String(citizen.get_meta("entity_id", ""))
		if code.is_empty():
			continue
		var role: String = String(economy.get("citizens").get(code, {}).get("profession", ""))
		if role not in ["woodcutter", "quarryman", "farmer"]:
			continue
		if assignments.has(code):
			var phase: String = String(assignments[code]["phase"])
			if phase not in ["done", "waiting_resource", "waiting_field"]:
				continue
		var kind: String = "tree" if role == "woodcutter" else ("stone" if role == "quarryman" else "field")
		var candidates: Array[String] = economy.call("get_available_resource_nodes", TOWN, kind)
		for node_id in candidates:
			if reserved.has(node_id):
				continue
			reserved[node_id] = true
			var position: Vector3 = economy.get("resource_positions")[node_id]
			assignments[code] = {"node_id": node_id, "kind": kind,
				"citizen": citizen, "phase": "to_resource",
				"depot": Vector3(citizen.get("home")), "done": 0}
			citizen.call("assign_work_destination", position)
			break

func _set_resource_visible(node_id: String, value: bool) -> void:
	if natural_art.has(node_id) and is_instance_valid(natural_art[node_id]):
		(natural_art[node_id] as Node3D).visible = value

func _process(delta: float) -> void:
	if economy==null:
		return
	state_time+=delta
	if state_time<0.20:
		return
	state_time=0
	_dispatch_idle_workers()
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
				_set_resource_visible(String(job["node_id"]), true)
				job["phase"]="to_resource"
				citizen.call("assign_work_destination",
					economy.get("resource_positions")[job["node_id"]])
			continue
		if phase=="to_resource" and bool(citizen.call("reached_work_destination",1.20)):
			var picked: bool = bool(economy.call("gather_field_to_actor",code,String(job["node_id"]))) if job["kind"]=="field" else bool(economy.call("gather_to_actor",code,String(job["node_id"])))
			if picked:
				harvested_jobs+=1
				if job["kind"]=="field":
					_set_resource_visible(String(job["node_id"]), false)
				else:
					var node_info: Dictionary = economy.get("natural_nodes")[job["node_id"]]
					if bool(node_info["depleted"]):
						_set_resource_visible(String(job["node_id"]), false)
				_show_cargo(code,citizen,String(job["kind"]))
				job["phase"]="to_depot"
				citizen.call("assign_work_destination",job["depot"])
			else:
				job["phase"]="waiting_resource"
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
					var source: Dictionary = economy.get("natural_nodes").get(job["node_id"], {})
					if int(source.get("remaining", 0)) > 0:
						job["phase"]="to_resource"
						citizen.call("assign_work_destination",
							economy.get("resource_positions")[job["node_id"]])
					else:
						job["phase"]="waiting_resource"
						citizen.call("cancel_work_destination")
			else:
				job["phase"]="done"
				citizen.call("cancel_work_destination")
	# Construction visualization is exclusively handled by NPCBuilding
	# after real material production, physical delivery and named NPC labor.

func _show_cargo(code: String, _person: Node3D, _kind: String) -> void:
	# The inventory load is authoritative; visual attachment awaits licensed
	# CC0 carried-item assets, not placeholder BoxMesh geometry.
	cargo_art.erase(code)

func _clear_cargo(code: String) -> void:
	cargo_art.erase(code)

func stats() -> Dictionary:
	var working: int = 0
	for job in assignments.values():
		if job["phase"] not in ["done", "waiting_resource", "waiting_field"]:
			working+=1
	return {"workers":assignments.size(),"active_workers":working,
		"harvested":harvested_jobs,"delivered":completed_deliveries,
		"new_houses_visible":construction_built,
		"grain_deliveries":grain_deliveries, "visible_cargo":cargo_art.size(),
		"remaining_trees":int(economy.call("resource_remaining","tree")),
		"remaining_stone":int(economy.call("resource_remaining","stone")),
		"navigation":"direct_steering_only_not_navmesh"}
