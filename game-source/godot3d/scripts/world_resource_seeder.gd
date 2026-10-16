extends RefCounted
## Deterministic resource ecology: nodes exist before NPC jobs, never minted
## by job assignment. Visual meshes must be supplied by licensed asset bridge.
const NATURAL_COUNT := 32

func seed_village(sim: RefCounted, rules: RefCounted,
		village_id: String, seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed + 271828
	var placed: Dictionary = {"tree": 0, "stone": 0, "clay": 0, "field": 0, "rich_vein": 0}
	for i in range(NATURAL_COUNT):
		var kind: String = "tree" if i < 16 else ("stone" if i < 26 else "clay")
		var x: float = rng.randf_range(-180.0, 180.0)
		var z: float = rng.randf_range(-180.0, 180.0)
		# Avoid the central village streets and courtyards.
		if absf(x) < 120.0:
			x = 120.0 if x >= 0.0 else -120.0
		var pos := Vector3(x, float(rules.call("height_at", x, z)), z)
		var node_id: String = "CL-NAT-%04d" % (i + 1)
		var accepted: bool = false
		if i == 26:
			accepted = bool(sim.call("register_rich_mineral_vein",
				node_id, village_id, "clay", pos, 12000))
			if accepted:
				placed["rich_vein"] += 1
		else:
			accepted = bool(sim.call("register_natural_node",
				node_id, village_id, kind, 12 if kind == "tree" else 80))
			if accepted:
				accepted = bool(sim.call("register_resource_position", node_id, pos))
				if kind == "tree":
					sim.call("configure_resource_recovery", node_id, 12, 1, 48, 24)
		if accepted:
			placed[kind] += 1
	# Reserve the seventh capacity slot for the interactive player worksite.\n\t# Farmland is an authored world entity and has a one-day growth cycle.
	for i in range(6):
		var x: float = -165.0 + float(i) * 7.0
		var z: float = -205.0
		var pos := Vector3(x, float(rules.call("height_at", x, z)), z)
		var node_id: String = "CL-FIELD-%04d" % (i + 1)
		if bool(sim.call("register_field", node_id, village_id)):
			if bool(sim.call("register_resource_position", node_id, pos)):
				placed["field"] += 1
	return placed
