extends SceneTree
## P0 regression: hourly simulation must not mint grain/wood/stone without
## existing natural nodes, actual harvest and physical delivery.
const Life = preload("res://scripts/worldbox_life_sim.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var sim: RefCounted = Life.new()
	sim.call("start", 20261017)
	assert(sim.call("create_village", "v1", {"fields": 2, "homes": 2}))
	assert(sim.call("add_citizen", "farmer1", "v1", "farmer", 25))
	assert(sim.call("add_citizen", "wood1", "v1", "woodcutter", 28))
	assert(sim.call("add_citizen", "stone1", "v1", "quarryman", 29))
	for i in range(1000):
		sim.call("tick")
	var stock: Dictionary = sim.get("villages")["v1"]["stock"]
	assert(int(stock["grain"]) == 0, "Hourly farmer minted grain without harvesting")
	assert(int(stock["wood"]) == 0, "Hourly woodcutter minted wood without resource")
	assert(int(stock["stone"]) == 0, "Hourly quarryman minted stone without resource")
	assert(sim.call("register_natural_node", "tree1", "v1", "tree", 4))
	assert(sim.call("register_resource_position", "tree1", Vector3(4, 0, 9)))
	assert(sim.call("get_available_resource_nodes", "v1", "tree") == ["tree1"])
	assert(sim.call("gather_to_actor", "wood1", "tree1"))
	assert(int(sim.get("natural_nodes")["tree1"]["remaining"]) == 1)
	assert(int(sim.get("villages")["v1"]["stock"]["wood"]) == 0)
	assert(sim.call("deliver_carried", "wood1"))
	assert(not sim.call("deliver_carried", "wood1"), "Double delivery minted wood")
	assert(int(sim.get("villages")["v1"]["stock"]["wood"]) == 3)
	assert(sim.call("gather_to_actor", "wood1", "tree1"))
	assert(sim.call("deliver_carried", "wood1"))
	assert(int(sim.get("villages")["v1"]["stock"]["wood"]) == 4)
	assert(int(sim.get("natural_nodes")["tree1"]["remaining"]) == 0)
	assert(not sim.call("gather_to_actor", "wood1", "tree1"))
	assert(sim.call("get_available_resource_nodes", "v1", "tree").is_empty())
	# A rich vein has a larger finite reserve and replenishes slowly.
	assert(sim.call("register_rich_mineral_vein", "vein1", "v1", "stone",
		Vector3(12, 0, 8), 12000))
	assert(int(sim.get("natural_nodes")["vein1"]["capacity"]) == 12000)
	assert(int(sim.get("natural_nodes")["vein1"]["remaining"]) == 1000)
	assert(sim.call("gather_to_actor", "stone1", "vein1"))
	assert(sim.call("deliver_carried", "stone1"))
	for i in range(11):
		sim.call("tick")
	assert(int(sim.get("natural_nodes")["vein1"]["remaining"]) == 997,
		"Rich mineral vein regenerated before its recovery delay")
	for i in range(25):
		sim.call("tick")
	assert(int(sim.get("natural_nodes")["vein1"]["remaining"]) <= 999,
		"Mine replenishment exceeded two units per 12 hours")
	assert(int(sim.get("natural_nodes")["vein1"]["remaining"]) < 1000,
		"Mine replenished faster than a single extraction")
	# Trees can regrow, but only if explicitly configured by the biome.
	assert(sim.call("register_natural_node", "sapling1", "v1", "tree", 3))
	assert(sim.call("configure_resource_recovery", "sapling1", 3, 1, 48, 24))
	assert(sim.call("gather_to_actor", "wood1", "sapling1"))
	assert(sim.call("deliver_carried", "wood1"))
	assert(int(sim.get("natural_nodes")["sapling1"]["remaining"]) == 0)
	for i in range(48):
		sim.call("tick")
	assert(int(sim.get("natural_nodes")["sapling1"]["remaining"]) == 0)
	for i in range(24):
		sim.call("tick")
	assert(int(sim.get("natural_nodes")["sapling1"]["remaining"]) == 1)
	sim.call("start", 20261017)
	assert(sim.get("natural_nodes").is_empty(), "Restart retained stale world nodes")
	assert(sim.get("resource_positions").is_empty(), "Restart retained stale resource positions")
	assert(sim.get("carried_by_actor").is_empty(), "Restart retained stale cargo")
	assert(sim.get("harvested_fields").is_empty(), "Restart retained stale fields")
	print("PASS_RESOURCE_CONSERVATION_1000_TICKS_NO_MINT_NO_DOUBLE_DELIVERY")
	quit(0)
