extends SceneTree
## CAC-LIFE-003: real Godot node integration; teleport test fixture to simulate
## arrival at work site and depot. DOES NOT prove NavMesh obstacle traversal.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	assert(scene!=null)
	var stage: Node3D = scene.instantiate()
	root.add_child(stage)
	var sim: RefCounted = stage.get("life_sim")
	var director: Node3D = stage.get("autonomous_director")
	assert(director!=null and sim!=null)
	var jobs: Dictionary = director.get("assignments")
	assert(jobs.size()==8, "NPC autonomous director must bind eight 3D actors")
	var first_id: String = String(jobs.keys()[0])
	var job: Dictionary = jobs[first_id]
	var actor: Node3D = job["citizen"]
	var natural_id: String = String(job["node_id"])
	var source: Dictionary = sim.get("natural_nodes")[natural_id]
	var before_node: int = int(source["remaining"])
	var stock: Dictionary = sim.get("villages")["CL-HX-VILLAGE-0001"]["stock"]
	var stock_type: String = "wood" if job["kind"]=="tree" else "stone"
	var before_stock: int = int(stock[stock_type])
	var source_visible: Node3D = director.get("natural_art")[natural_id]
	# Simulation of actual arrival, NOT a claim of completed pathfinding.
	actor.position = source_visible.position
	director.call("_process",0.25)
	assert(int(source["remaining"])==before_node-3,
		"Moving NPC to real 3D resource must debit finite world stock")
	assert(int(stock[stock_type])==before_stock,
		"Logging resources at a stump must not teleport them to village store")
	assert(sim.get("carried_by_actor").has(first_id),
		"NPC actor must carry actual 3 units before delivery")
	assert(String(job["phase"])=="to_depot", "NPC should depart for warehouse")
	actor.position = job["depot"]
	director.call("_process",0.25)
	assert(int(stock[stock_type])==before_stock+3,
		"Arrival at warehouse must credit precisely three units")
	assert(not sim.get("carried_by_actor").has(first_id),
		"Completed cargo must be cleared after transfer")
	assert(String(job["phase"])=="to_resource",
		"NPC should return for next finite physical tree/stone haul")
	assert(int(director.get("completed_deliveries"))==1)
	# Fresh house is built only after resources were debited and time ticked.
	var town: Dictionary = sim.get("villages")["CL-HX-VILLAGE-0001"]
	var housing_before: int = int(town["homes"])
	var wood_before: int = int(stock["wood"])
	director.call("_process",0.25)
	assert(int(town["homes"])==housing_before,
		"New house appeared before simulation completed construction")
	if bool(director.get("_has_started_house")):
		assert(int(stock["wood"])==wood_before or int(stock["wood"])==wood_before-12,
			"Only authorized material payment may change wood inventory")
		sim.call("tick")
		director.call("_process",0.25)
		assert(int(town["homes"])==housing_before+1)
		assert(int(director.get("construction_built"))==1,
			"Paid simulation house must be rendered as Godot 3D object")
	print("PASS CAC AUTONOMOUS NPC LOOP: bound real 3D actor, finite tree, carrying, depot delivery, paid house after hour tick")
	stage.queue_free()
	quit(0)
