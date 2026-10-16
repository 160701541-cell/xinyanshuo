extends SceneTree
## Genuine Godot integration fixture: simulate arrival by positioning NPC.
## This verifies physical inventory transfer, NOT NavigationAgent avoidance.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	assert(scene != null)
	var stage: Node3D = scene.instantiate()
	root.add_child(stage)
	var sim: RefCounted = stage.get("life_sim")
	var director: Node3D = stage.get("autonomous_director")
	assert(director != null and sim != null)
	var jobs: Dictionary = director.get("assignments")
	assert(jobs.size() >= 8, "Seeded world must assign finite resource workers")
	var chosen: Dictionary = {}
	var farmer_jobs: Array[Dictionary] = []
	for job in jobs.values():
		if String(job["kind"]) == "field":
			farmer_jobs.append(job)
		elif chosen.is_empty():
			chosen = job
	assert(not chosen.is_empty(), "No worker assigned to authored tree or mine")
	assert(farmer_jobs.size() >= 2, "Two actual farmers must have fields")
	var actor: Node3D = chosen["citizen"]
	var code: String = String(actor.get_meta("entity_id", ""))
	var node_id: String = String(chosen["node_id"])
	var source: Dictionary = sim.get("natural_nodes")[node_id]
	var before_node: int = int(source["remaining"])
	var stock: Dictionary = sim.get("villages")["CL-HX-VILLAGE-0001"]["stock"]
	var stock_kind: String = "wood" if String(chosen["kind"]) == "tree" else "stone"
	var before_stock: int = int(stock[stock_kind])
	actor.position = sim.get("resource_positions")[node_id]
	director.call("_process", 0.25)
	assert(int(source["remaining"]) == before_node - 3)
	assert(int(stock[stock_kind]) == before_stock, "Harvest must not teleport to depot")
	assert(sim.get("carried_by_actor").has(code))
	assert(String(chosen["phase"]) == "to_depot")
	actor.position = chosen["depot"]
	director.call("_process", 0.25)
	assert(int(stock[stock_kind]) == before_stock + 3)
	assert(not sim.get("carried_by_actor").has(code))
	assert(int(director.get("completed_deliveries")) >= 1)
	for field_job in farmer_jobs:
		var farmer: Node3D = field_job["citizen"]
		var field_id: String = String(field_job["node_id"])
		var farmer_id: String = String(farmer.get_meta("entity_id", ""))
		var grain_before: int = int(stock["grain"])
		farmer.position = sim.get("resource_positions")[field_id]
		director.call("_process", 0.25)
		assert(int(stock["grain"]) == grain_before,
			"Harvested crop cannot appear in warehouse until actual delivery")
		assert(sim.get("carried_by_actor").has(farmer_id))
		farmer.position = field_job["depot"]
		director.call("_process", 0.25)
		assert(int(stock["grain"]) == grain_before + 5)
		assert(not sim.get("carried_by_actor").has(farmer_id))
	assert(int(director.get("grain_deliveries")) >= 2)
	print("PASS CAC AUTONOMOUS NPC LOOP: pre-existing CC0-linked nodes, finite extraction, carrying, actual depot credits, two distinct field workers")
	stage.queue_free()
	quit(0)
