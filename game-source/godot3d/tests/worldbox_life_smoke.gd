extends SceneTree
const Sim = preload("res://scripts/worldbox_life_sim.gd")
func _initialize() -> void:
	call_deferred("_test")

func _test() -> void:
	var sim: RefCounted = Sim.new()
	sim.call("start",141)
	assert(bool(sim.call("create_village","TEST-01",
		{"homes":2,"fields":2,"food":30,"water":30,
		"grain":20,"wood":25,"stone":10,"clay":8})))
	assert(not bool(sim.call("create_village","TEST-01",{})))
	assert(bool(sim.call("add_citizen","P-01","TEST-01","farmer")))
	assert(bool(sim.call("add_citizen","P-02","TEST-01","woodcutter")))
	assert(bool(sim.call("add_citizen","P-03","TEST-01","cook")))
	assert(bool(sim.call("add_citizen","P-04","TEST-01","potter")))
	assert(not bool(sim.call("add_citizen","P-04","TEST-01","potter")))
	assert(not bool(sim.call("request_construction","TEST-01","palace")))
	var town: Dictionary = sim.get("villages")["TEST-01"]
	var old_wood: int = int(town["stock"]["wood"])
	assert(not bool(sim.call("request_construction","TEST-01","workshop")))
	assert(int(town["stock"]["wood"])==old_wood,"Failed construction consumed inventory")
	assert(bool(sim.call("request_construction","TEST-01","home")))
	assert(int(town["stock"]["wood"])==old_wood-12,"Construction lacks real price")
	assert(int(town["homes"])==2,"Building appeared before simulation work")
	sim.call("tick")
	assert(int(town["homes"])==3,"Completed building never appeared")
	for i in range(24):
		sim.call("tick")
	var outcome: Dictionary = sim.call("get_world_summary")
	assert(int(outcome["population"])==4)
	assert(int(outcome["day"])>=2)
	assert(int(town["stock"]["grain"])>=0)
	assert(int(town["stock"]["wood"])>=0)
	assert(int(town["stock"]["stone"])>=0)
	assert(int(town["stock"]["food"])>=0)
	assert(int(town["stock"]["clay"])>=0)
	assert(int(outcome["events"])>=1)
	assert(int(outcome["average_prosperity"])>=0 and int(outcome["average_prosperity"])<=100)
	# Simulation must be deterministic for same ID, seed, input and tick order.
	var replica: RefCounted = Sim.new()
	replica.call("start",141)
	replica.call("create_village","TEST-01",
		{"homes":2,"fields":2,"food":30,"water":30,
		"grain":20,"wood":25,"stone":10,"clay":8})
	for entry in ["farmer","woodcutter","cook","potter"]:
		replica.call("add_citizen","P-%02d" % (
			["farmer","woodcutter","cook","potter"].find(entry)+1),
			"TEST-01",entry)
	replica.call("request_construction","TEST-01","home")
	for i in range(25):
		replica.call("tick")
	assert(var_to_str(sim.call("snapshot"))==var_to_str(replica.call("snapshot")),
		"Deterministic world simulation diverged")
	print("PASS CAC WORLD LIFE SIM: 4 jobs, real resource costs, 25 ticks, deterministic state, new house, no negative stock")
	quit(0)
