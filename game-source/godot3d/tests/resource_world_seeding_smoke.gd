extends SceneTree
const Life = preload("res://scripts/worldbox_life_sim.gd")
const Seeder = preload("res://scripts/world_resource_seeder.gd")
const Rules = preload("res://scripts/world_rules.gd")

func _initialize() -> void:
	call_deferred("_test")

func _test() -> void:
	var sim: RefCounted = Life.new()
	sim.call("start", 20261017)
	assert(sim.call("create_village", "CL-HX-VILLAGE-0001",
		{"homes": 22, "fields": 7}))
	var rules: RefCounted = Rules.new()
	rules.call("configure", 20261017)
	var placed: Dictionary = Seeder.new().call("seed_village", sim,
		rules, "CL-HX-VILLAGE-0001", 20261017)
	assert(int(placed["tree"]) == 16)
	assert(int(placed["stone"]) == 10)
	assert(int(placed["clay"]) == 6)
	assert(int(placed["rich_vein"]) == 1)
	assert(int(placed["field"]) == 6)
	assert(sim.get("natural_nodes").size() == 32)
	assert(sim.get("resource_positions").size() == 38)
	assert(sim.call("get_available_resource_nodes",
		"CL-HX-VILLAGE-0001", "tree").size() == 16)
	var sim2: RefCounted = Life.new()
	sim2.call("start", 20261017)
	assert(sim2.call("create_village", "CL-HX-VILLAGE-0001",
		{"homes": 22, "fields": 7}))
	Seeder.new().call("seed_village", sim2, rules,
		"CL-HX-VILLAGE-0001", 20261017)
	assert(sim.call("snapshot")["resource_positions"] ==
		sim2.call("snapshot")["resource_positions"],
		"Seeded resource coordinates are not deterministic")
	print("PASS_WORLD_RESOURCE_SEEDING_PREEXISTING_NODES")
	quit(0)
