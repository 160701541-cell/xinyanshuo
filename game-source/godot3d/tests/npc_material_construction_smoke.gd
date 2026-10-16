extends SceneTree
## CAC-MAT-NPC-001: a functional SCENE test. Teleport simulates worker arrival;
## this does NOT prove obstacle avoidance or a live phone OTA has passed.
func _initialize() -> void:
	call_deferred("_test")

func _test() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	assert(packed!=null)
	var game: Node3D = packed.instantiate()
	root.add_child(game)
	var system: Node3D = game.get("npc_building_system")
	var economy: RefCounted = game.get("life_sim")
	assert(system!=null and economy!=null,"NPC material-built world system must be live in the 3D scene")
	var people: Dictionary = economy.get("citizens")
	var town: Dictionary = economy.get("villages")["CL-HX-VILLAGE-0001"]
	var stock: Dictionary = town["stock"]
	var site_id: String = String(system.get("current_project"))
	assert(not site_id.is_empty(),"NPC population/settlement needs must generate autonomous construction")
	var project: Dictionary = system.get("construction_sites")[site_id]
	assert(String(project["kind"])=="workshop",
		"Population without crafting workshop must plan its own productive building")
	assert(String(project["architect_id"])!=String() and String(project["builder_id"])!=String())
	assert(int(project["stage"])==0)
	assert(not bool(project["complete"]))
	assert(int(town["workshops"])==0)
	assert(int(stock["timber"])==0 and int(stock["cut_stone"])==0 and
		int(stock["roof_tile"])==0 and int(stock["mortar"])==0,
		"Input is RAW resources only, not pre-made walls/roofs")
	var before: Dictionary = stock.duplicate(true)
	var builder: Node3D = system.get("builder")
	var builder_id: String = String(system.get("builder_code"))
	assert(String(people[builder_id]["profession"])=="builder")
	var artisan_roles: Dictionary = system.get("artisans")
	assert(artisan_roles.has("carpenter") and artisan_roles.has("mason")
		and artisan_roles.has("potter"),"3 real manufacturing trades are required")
	var visual: Node3D = system.get("visual_sites")[site_id]
	assert(visual!=null and visual.get_child_count()==0,
		"No predesigned building geometry or facade can spawn at planning time")
	# Artisan must be at their depot to craft. No remote inventory magic.
	for worker in artisan_roles.values():
		(worker as Node3D).position=Vector3(200,0,200)
	system.call("_tick")
	assert(int(stock["timber"])==0 and int(stock["cut_stone"])==0 and
		int(stock["mortar"])==0,"Distant workers must NOT process materials by magic")
	for worker in artisan_roles.values():
		(worker as Node3D).position=Vector3(2,0.4,40)
		(worker as Node3D).call("assign_work_destination",Vector3(2,0.4,40))
	# A second step checks real distance before accepting site work.
	builder.position=Vector3(2,0.4,40)
	system.call("_tick")
	assert(visual.get_child_count()==0,
		"No instant house materialization after the first craft job")
	var seen_cargo: bool = false
	var seen_materials_at_site: bool = false
	var saw_individual_labor: bool = false
	for step in range(240):
		# Stage navigation uses the real Actor3D work destination; move fixture
		# only to mimic arrival. Runtime still uses actual physical movement.
		builder.position=builder.get("_external_job_destination")
		system.call("_tick")
		if not (system.get("inventory_on_actor") as Dictionary).is_empty():
			seen_cargo=true
			assert(builder.get_node_or_null("ActualCarriedConstructionMaterials")!=null)
		if not (project["delivered"] as Dictionary).is_empty():
			seen_materials_at_site=true
		if int(project["work_done"])>0:
			saw_individual_labor=true
		if bool(project["complete"]):
			break
	assert(seen_cargo and seen_materials_at_site and saw_individual_labor,
		"No carrier, delivery or named NPC labor was observed")
	assert(bool(project["complete"]) and int(project["stage"])==4,
		"Four individually constructed parts must complete the building")
	assert(int(town["workshops"])==1,
		"Only after real deliveries plus work may a workshop add to settlement economy")
	assert(int(system.get("completed"))==1)
	assert(visual.get_node_or_null("ActuallyBuiltStoneFoundation")!=null)
	assert(visual.get_node_or_null("NPCRaisedBeam")!=null)
	assert(visual.get_node_or_null("NPCBuiltBackWall")!=null)
	assert(visual.get_node_or_null("NPCPlacedRoofRidge")!=null)
	assert(stock["stone"]<before["stone"] and stock["wood"]<before["wood"]
		and stock["clay"]<before["clay"],
		"Material costs must come from REAL existing stock, no image magically creates matter")
	for material in ["wood","stone","clay","water","timber","cut_stone","mortar","roof_tile"]:
		assert(int(stock[material])>=0,"Negative stock in NPC construction production chain")
	assert(String(system.call("stats")["raw_art_policy"])==
		"WorldX_SEAMLESS_MATERIALS_ONLY_NOT_FINISHED_HOUSES")
	var save: Dictionary = system.call("snapshot")
	assert(save["schema"]==1 and save["sites"].has(site_id))
	assert(save["assigned_builder"]==builder_id)
	assert(save["completed"]==1)
	assert(visual.get_meta("built_by_npc_materials",false)==true)
	print("PASS CAC NPC MATERIAL-BUILT WORLD: independent citizens plan workshop; carpenter/mason/potter craft only REAL raw materials; builder carries and constructs foundation/frame/walls/roof")
	game.queue_free()
	quit(0)
