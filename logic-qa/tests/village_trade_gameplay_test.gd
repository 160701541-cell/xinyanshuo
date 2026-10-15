extends SceneTree
## Real village gameplay test: finite harvest -> voluntary NPC barter -> save/load.
const W = preload("res://scripts/world_state.gd")
const Trade = preload("res://scripts/village_trade.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world = W.new()
	var farmer: String = world.create_actor("秦禾", Vector3.ZERO)
	var woodsman: String = world.create_actor("许木生", Vector3(3, 0, 2))
	var crop: String = world.create_natural_resource("vegetables", 8, Vector3(1, 0, 1), "cultivated")
	var wood: String = world.create_natural_resource("firewood", 9, Vector3(5, 0, 1), "fallen")
	assert(world.harvest(farmer, crop, 6))
	assert(world.harvest(woodsman, wood, 7))
	var original_crop: int = world.quantity(farmer, "vegetables") + world.quantity(woodsman, "vegetables")
	var original_wood: int = world.quantity(farmer, "firewood") + world.quantity(woodsman, "firewood")
	var offer: Dictionary = Trade.best_survival_offer(world, woodsman, farmer)
	assert(not offer.is_empty(), "Hungry woodcutter should propose real barter")
	assert(Trade.execute_offer(world, offer), "Both owners must consent to valid finite exchange")
	assert(world.quantity(farmer, "firewood") == 2 and world.quantity(woodsman, "vegetables") == 2)
	assert(world.quantity(farmer, "vegetables") + world.quantity(woodsman, "vegetables") == original_crop)
	assert(world.quantity(farmer, "firewood") + world.quantity(woodsman, "firewood") == original_wood)
	# Do not assume the offer itself is stateful; re-evaluate after transaction.
	assert(Trade.best_survival_offer(world, woodsman, farmer).is_empty(),
		"At least two acquired vegetables should stop repeat hunger trades")
	var before: String = JSON.stringify(world.serialize())
	assert(not Trade.barter(world, farmer, woodsman, "vegetables", 999, "firewood", 1),
		"Invalid trade must never debit the other side")
	assert(not Trade.barter(world, farmer, woodsman, "vegetables", 1, "firewood", 999),
		"Both halves must pass inventory checks")
	assert(not Trade.barter(world, farmer, farmer, "vegetables", 1, "firewood", 1))
	assert(not Trade.barter(world, farmer, woodsman, "firewood", 0, "vegetables", 1))
	assert(JSON.stringify(world.serialize()) == before, "Rejected trades cannot mutate world")
	var loaded = W.new()
	loaded.restore(world.serialize())
	assert(loaded.quantity(farmer, "firewood") == 2)
	assert(loaded.quantity(woodsman, "vegetables") == 2)
	assert(loaded.entities[woodsman]["public_code"] == world.entities[woodsman]["public_code"])
	var trace := false
	for entry in loaded.ledger:
		if entry.get("action") == "barter":
			trace = true
	assert(trace, "Trade history should persist for NPC memories and player consequences")
	print("PASS CANGLAN PLAYABLE VILLAGE TRADE: finite harvest, conserved bilateral barter, adaptive goals, save-load, no ghost stock")
	quit(0)
