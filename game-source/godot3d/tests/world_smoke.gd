extends SceneTree
## Real Godot engine-run regression. Explicitly NO claim of Android approval.
const Rules = preload("res://scripts/world_rules.gd")
const OriginalWorld = preload("res://scripts/world_state.gd")
const Bridge = preload("res://scripts/world_state_bridge.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var original: PackedScene = load("res://scenes/main.tscn")
	assert(original!=null, "The 3D source main scene must exist")
	var stage: Node3D = original.instantiate()
	root.add_child(stage)
	assert(stage.is_node_ready(),"3D world failed to initialize")
	var camera: Camera3D = stage.get_node_or_null("Follow3DCamera")
	assert(camera!=null and camera.current, "Cannot play without third-person camera")
	var terrain: Node3D = stage.get_node_or_null("StreamingTerrain")
	var settlement: Node3D = stage.get_node_or_null("Actual3DSettlements")
	var npcs: Node3D = stage.get_node_or_null("Civilians")
	var props: Node3D = stage.get_node_or_null("IndependentWorldProps")
	assert(terrain!=null and settlement!=null and npcs!=null and props!=null,
		"Any missing world subsystem is release-blocking")
	var director: Node3D = stage.get_node_or_null("AutonomousNPCJobsWorldVisible")
	assert(director!=null,"Actual Godot world has no autonomous NPC work director")
	var jobs: Dictionary = director.call("stats")
	assert(int(jobs["workers"])==10, "8 finite-resource carriers plus 2 actual field workers must be assigned")
	var economy: RefCounted = stage.get("life_sim")
	assert((economy.get("harvested_fields") as Dictionary).size()==2,
		"Two independently growing/harvestable farm plots must exist in the rendered 3D world")
	assert((economy.get("natural_nodes") as Dictionary).size()==9,
		"8 finite natural work sites + 1 visible manual tree must exist")
	for worker in (director.get("assignments") as Dictionary).values():
		var citizen: Node3D = worker["citizen"]
		assert(bool(citizen.get("_externally_assigned_job")),
			"NPC is not physically steering toward real resource site")
	var worksite: Node3D = stage.get_node_or_null("CAC_LifeWorksite_PlayerVisible")
	assert(worksite!=null,"Actual physical harvest/build/eat scene missing")
	var before: Dictionary = stage.call("snapshot")
	print("PUBLIC_CANGLAN_3D_COUNTS:",before)
	assert(before["source"]=="PUBLIC_GODOT3D","Wrong engine baseline")
	assert(int(before["terrain_chunks"])==25,"Actual terrain must be streamed into scene")
	assert(int(before["buildings_and_yards"])==80,"Expected 60 houses and 20 3D courtyards")
	assert(int(before["npc_ids"])==80,"80 individually created people required")
	assert(int(before["original_world_actor_entities"])==80,
		"Every visible NPC must exist in original WorldState")
	var authoritative: RefCounted = stage.get("authoritative_world")
	var world_entities: Dictionary = authoritative.get("entities")
	assert(world_entities.size()==80,"Original game economy generated unwanted free props")
	for npc in npcs.get_children():
		var canonical: String = String(npc.get_meta("canonical_id",""))
		assert(world_entities.has(canonical),"Render actor missing original canonical ID")
		assert(npc.get_meta("entity_id")==world_entities[canonical].get("public_code"),
			"Historical stable NPC public code mismatch")
	var saved: Dictionary = authoritative.call("serialize")
	var restored: RefCounted = OriginalWorld.new()
	restored.call("restore",saved)
	assert((restored.get("entities") as Dictionary).size()==80,
		"Original WorldState serialize/restore compatibility broken")
	var first_canonical: String = String(npcs.get_child(0).get_meta("canonical_id"))
	var inventory_count: int = (authoritative.get("inventories") as Dictionary).size()
	assert(not Bridge.sync_actor(authoritative,first_canonical,Vector3(9999,0,9999),1.0),
		"Motion authority allowed teleportation")
	assert((authoritative.get("inventories") as Dictionary).size()==inventory_count,
		"Rendering is not allowed to create inventory" )
	assert(int(before["world_props"])>=600,"Hundreds of independently addressed world props required")
	assert(int(before["batched_instances"])>=600,"Actual MultiMesh draw batches must exist")
	assert(stage.get("_inside")==false,"Startup must be outdoors")
	var first_terrain: MeshInstance3D = terrain.get_child(0) as MeshInstance3D
	assert(first_terrain!=null and first_terrain.mesh!=null,"Terrain must be actual 3D geometry")
	assert(first_terrain.get_node_or_null("GroundCollision")!=null,"No real ground collision")
	var found_buildings: int = 0
	var ids := {}
	var target: Node3D
	for obj in settlement.get_children():
		if not (obj is Node3D) or not obj.has_meta("entity_id"):
			continue
		var id: String = String(obj.get_meta("entity_id"))
		assert(not ids.has(id),"Duplicate building/yard entity ID")
		ids[id]=true
		if String(obj.get_meta("kind"))!="courtyard_wall":
			found_buildings+=1
			if target==null:
				target=obj
				assert(obj.get_node_or_null("DoorHinge")!=null,"Independent door is missing")
	assert(found_buildings==60,"Procedural Han house count mismatch")
	var npc_ids := {}
	for n in npcs.get_children():
		var id: String = String(n.get_meta("entity_id"))
		assert(not npc_ids.has(id),"Duplicate NPC ID")
		npc_ids[id]=true
		assert(n.call("status")["id"]==id,"NPC identity doesn't match its state")
	assert(npc_ids.size()==80,"NPC headcount not supported by nodes")
	# The batch generator must be reflected in the 3D game, not merely an
	# artifact ZIP that the mobile player never sees.
	if ResourceLoader.exists("res://assets/generated/npc/role_00.glb"):
		var loaded_role_models: int = 0
		for npc in npcs.get_children():
			if npc.get_meta("art_status","")=="UNRIGGED_GENERATED_GLB_CANDIDATE":
				loaded_role_models += 1
				assert(npc.get_node_or_null("ProceduralArtNotApproved/GeneratedOccupationGLB_Unrigged")!=null,
					"NPC GLB declared imported but has no actual Godot scene")
		assert(loaded_role_models==80,"All 80 NPC visual instances must import real occupation GLBs")
		if ResourceLoader.exists("res://assets/generated/npc/male_merchant_han_v2.glb"):
			var male_count: int = 0
			for npc in npcs.get_children():
				var job: String = String(npc.get_meta("role",""))
				if job in ["商贾","学徒","卫卒","书生"]:
					male_count += 1
					assert(String(npc.get_meta("shared_master",""))=="CAC_HAN_MALE_V2",
						"Occupation NPC did not switch to improved male mother model")
					assert(String(npc.get_meta("model_source","")).contains("/male_"),
						"Male candidate GLB was not actually instantiated")
			assert(male_count>=20,"Male base was not applied to the expected 4 civilian professions")

	var sample: RefCounted = Rules.new()
	sample.call("configure",20261016)
	var y1: float = float(sample.call("height_at",141.0,27.0))
	sample.call("configure",20261016)
	var y2: float = float(sample.call("height_at",141.0,27.0))
	assert(is_equal_approx(y1,y2),"Fixed terrain seed did not reproduce")
	var avatar: CharacterBody3D = stage.get_node_or_null("PlayerWithCollision")
	assert(avatar!=null and avatar.get_node_or_null("CollisionShape3D")!=null,
		"Player has no physical character collider")
	avatar.position = target.position + Vector3(0,2,2)
	stage.call("_interact_nearby")
	assert(bool(stage.get("_inside")),"Door should connect to the actual indoor room")
	var room: Node3D = stage.get_node_or_null("ActiveInterior")
	assert(room!=null,"Interior is not a real 3D node")
	assert(String(room.get_meta("building_id"))==String(target.get_meta("entity_id")),
		"Interior lost canonical source building ID")
	assert(int(room.get_meta("furniture_count"))==8,"Furniture must be independent IDs")
	assert(room.get_node("IndependentFurniture").get_child_count()==8,
		"Furniture currently baked into static scene")
	stage.call("_leave_room")
	assert(not bool(stage.get("_inside")),"Cannot exit building")
	assert(stage.get_node_or_null("ActiveInterior")==null or
		stage.get_node("ActiveInterior").is_queued_for_deletion(),"Indoor node didn't cleanly release")
	var factory: RefCounted = stage.get("building_factory")
	factory.call("set_damaged",target,2)
	assert(int(target.get_meta("damage"))==2 and target.get_node("CollapsedRubble").visible,
		"Collapse state isn't rendered")
	print("PASS PUBLIC CANGLAN 3D GODOT SCENE: 25 live terrain chunks / 60 houses / 80 NPC / 600+ props / indoor furniture / door / collapse / stable IDs")
	stage.queue_free()
	quit(0)
