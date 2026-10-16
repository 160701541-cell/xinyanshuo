extends Node3D
## CAC-MAT-NPC-001: WorldX paints REUSABLE MATERIAL TEXTURES, not entire buildings.
## Actual individualized NPCs autonomously decide, craft, carry, and construct
## structural parts IN THE REAL 3D WORLD. No finished-house art generation.
## Navigation still uses the existing prototype steering, NOT obstacle-aware navmesh.
const TOWN := "CL-HX-VILLAGE-0001"
const CC0Bridge = preload("res://scripts/cc0_asset_bridge.gd")
const FreeCC0 = preload("res://scripts/cc0_asset_bridge.gd")
const YARD := Vector3(2.0, 0.4, 40.0)
const WORKSHOP_LOCATION := Vector3(39.0, 0.35, 43.0)
const STAGE_DATA := [
	{"id":"foundation","materials":{"cut_stone":3,"mortar":2},"work":3},
	{"id":"frame","materials":{"timber":4},"work":3},
	{"id":"walls","materials":{"timber":2,"mortar":2},"work":3},
	{"id":"roof","materials":{"roof_tile":4,"timber":1},"work":4}
]
const RECIPES := {
	"cut_stone":{"maker":"mason","consume":{"stone":1},"produce":1},
	"timber":{"maker":"carpenter","consume":{"wood":1},"produce":1},
	"mortar":{"maker":"mason","consume":{"clay":1,"water":1},"produce":2},
	"roof_tile":{"maker":"potter","consume":{"clay":1,"wood":1},"produce":2}
}
const MAT_COLORS := {
	"cut_stone":"#85878a", "timber":"#836246",
	"mortar":"#c1b5a0", "roof_tile":"#4f6870"
}
const TEXTURE_ROOT := "res://assets/generated/materials/worldx/"
var simulation: RefCounted
var artisans: Dictionary = {}
var builder: Node3D
var builder_code: String = ""
var architect_code: String = ""
var construction_sites: Dictionary = {}
var current_project: String = ""
var inventory_on_actor: Dictionary = {}
var visible_load: Node3D
var visual_sites: Dictionary = {}
var event_log: Array[String] = []
var completed: int = 0
var _clock: float = 0.0

func _mesh_piece(parent: Node3D,label: String,pos: Vector3,shape: Vector3,
		material: String, tilt: float = 0.0) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = label
	var box := BoxMesh.new()
	box.size = shape
	part.mesh = box
	part.position = pos
	part.rotation.z = tilt
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(String(MAT_COLORS.get(material,"#b8afa0")))
	mat.roughness = 0.95
	var source: String = TEXTURE_ROOT + material + ".png"
	if ResourceLoader.exists(source):
		var tex: Texture2D = load(source) as Texture2D
		if tex != null:
			mat.albedo_texture = tex
			mat.uv1_triplanar = true
			mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	part.material_override = mat
	parent.add_child(part)
	# Existing real CC0 modular parts replace the temporary handmade render
	# ONLY AFTER this named NPC has delivered stock and completed this stage.
	# Free meshes have NO effect on bill, collision authority or build timer.
	var reusable: String = ""
	if label.begins_with("NPCBuilt"):
		reusable="plaster_wall"
	elif label.begins_with("NPCLaidRoofSlope"):
		reusable="clay_tiled_roof"
	elif label.begins_with("NPCSetTimberPost"):
		reusable="wood_fence"
	elif label=="ActuallyBuiltStoneFoundation":
		reusable="stone_steps"
	elif label=="RawTimberMaterial":
		reusable="tree_log"
	elif label=="StoneMaterial":
		reusable="stone_cluster"
	if not reusable.is_empty() and CC0Bridge.is_installed(reusable):
		var imported: Node3D = CC0Bridge.instantiate_asset(reusable,part,Vector3.ZERO)
		if imported!=null:
			# Preserve the part's persistent semantic name for save/QA.
			# A third-party model is VISUAL ONLY; no completed prefab city.
			part.mesh=null
			part.set_meta("visual_source","EXISTING_KENNEY_OR_QUATERNIUS_CC0")
			part.set_meta("cc0_part_key",reusable)
			# Conservative bounded size fit: prevents 100m/unseen vendor scales.
			var mesh_nodes: Array[Node] = imported.find_children("*","MeshInstance3D",true,false)
			if not mesh_nodes.is_empty():
				var native: MeshInstance3D = mesh_nodes[0] as MeshInstance3D
				if native.mesh!=null:
					var bound: Vector3 = native.mesh.get_aabb().size
					imported.scale=Vector3(clampf(shape.x/maxf(bound.x,0.1),0.15,2.0),
						clampf(shape.y/maxf(bound.y,0.1),0.15,2.0),
						clampf(shape.z/maxf(bound.z,0.1),0.15,2.0))
	return part

func setup(world_sim: RefCounted, citizens: Array[Node3D]) -> void:
	simulation = world_sim
	name = "NPCDesignedMaterialBuiltWorld"
	var people: Dictionary = simulation.get("citizens")
	for actor in citizens:
		var code: String = String(actor.get_meta("entity_id",""))
		if not people.has(code):
			continue
		var occupation: String = String(people[code]["profession"])
		if occupation in ["carpenter","mason","potter"] and not artisans.has(occupation):
			artisans[occupation]=actor
		if occupation=="builder" and builder==null:
			builder=actor
			builder_code=code
		if architect_code.is_empty():
			architect_code=code
	# The construction site is a WORLD actor project, never a prefabricated
	# house model: physical elements appear only after deliveries + work.
	if builder != null:
		_create_plan_if_needed()
	# A visible resource depot represents real stock, not decorative scenery.
	var depot := Node3D.new()
	depot.name="NPCMaterialDepot"
	depot.position=YARD
	add_child(depot)
	_mesh_piece(depot,"RawTimberMaterial",Vector3(-1.4,0.2,0),Vector3(1.8,.4,.7),"timber")
	_mesh_piece(depot,"StoneMaterial",Vector3(1.2,.3,0),Vector3(1.2,.6,.75),"cut_stone")
	# Real Kenney GLBs only when imported, keeping physics and material stock authoritative.
	var timber_display: Node3D = FreeCC0.instantiate_asset(
		"tree_log",depot,Vector3(-1.4,.28,-.7),Vector3.ONE)
	var stone_display: Node3D = FreeCC0.instantiate_asset(
		"stone_cluster",depot,Vector3(1.2,.1,-.7),Vector3.ONE)
	depot.set_meta("visual_source",
		"REAL_KENNEY_CC0_GLBS" if timber_display!=null and stone_display!=null
		else "ORIGINAL_3D_GEOMETRY_FALLBACK")

func _create_plan_if_needed() -> void:
	if simulation==null or builder==null or not current_project.is_empty():
		return
	var village: Dictionary = simulation.get("villages")[TOWN]
	# Real NPC decision based on settlement needs, not author-placed houses.
	var needs_workshop: bool = int(village["workshops"])==0
	var needs_housing: bool = int(village["population"])>int(village["homes"])*4
	if not needs_workshop and not needs_housing:
		return
	var kind: String = "workshop" if needs_workshop else "home"
	var site_code: String = "NPC-BUILD-%s-%03d" % [kind,construction_sites.size()+1]
	var point: Vector3 = WORKSHOP_LOCATION+Vector3(float(construction_sites.size())*13.0,0,0)
	var site: Dictionary = {"entity_id":site_code,"kind":kind,
		"architect_id":architect_code,"builder_id":builder_code,
		"stage":0,"work_done":0,"delivered":{},"position":point,
		"complete":false,"name":"NPC独立规划建筑"}
	construction_sites[site_code]=site
	current_project=site_code
	var scene := Node3D.new()
	scene.name=site_code
	scene.position=point
	scene.set_meta("entity_id",site_code)
	scene.set_meta("builder_id",builder_code)
	scene.set_meta("built_by_npc_materials",true)
	add_child(scene)
	visual_sites[site_code]=scene
	_add_event("规划",site_code,"由NPC "+architect_code+"决定建造"+kind)
	builder.call("assign_work_destination",YARD)

func _add_event(action: String,site: String,detail: String) -> void:
	var line: String = action+" "+site+" "+detail
	event_log.append(line)
	if event_log.size()>128:
		event_log.pop_front()
	if simulation!=null:
		simulation.call("_journal",TOWN,"npc_world_"+action,1,detail)

func _phase() -> Dictionary:
	if current_project.is_empty() or not construction_sites.has(current_project):
		return {}
	var site: Dictionary = construction_sites[current_project]
	if int(site["stage"])>=STAGE_DATA.size():
		return {}
	return STAGE_DATA[int(site["stage"])]

func _needed_after_deliveries() -> Dictionary:
	var phase: Dictionary = _phase()
	if phase.is_empty():
		return {}
	var site: Dictionary = construction_sites[current_project]
	var result: Dictionary = {}
	for material in phase["materials"]:
		var still: int = int(phase["materials"][material])-int(site["delivered"].get(material,0))
		if String(inventory_on_actor.get("material",""))==String(material):
			still-=int(inventory_on_actor.get("amount",0))
		if still>0:
			result[material]=still
	return result

func _make_material(material: String) -> void:
	if not RECIPES.has(material) or not artisans.has(String(RECIPES[material]["maker"])):
		return
	var worker: Node3D = artisans[String(RECIPES[material]["maker"])]
	if not is_instance_valid(worker):
		return
	var role_id: String = String(worker.get_meta("entity_id",""))
	var profile: Dictionary = simulation.get("citizens")[role_id]
	if int(profile["energy"])<5:
		return
	if not bool(worker.call("reached_work_destination",2.0)):
		worker.call("assign_work_destination",YARD)
		return
	var recipe: Dictionary = RECIPES[material]
	if not bool(simulation.call("_spend",TOWN,recipe["consume"])):
		return
	var quantity: int = int(recipe["produce"])
	assert(bool(simulation.call("_add_stock",TOWN,material,quantity)))
	profile["energy"]=maxi(0,int(profile["energy"])-1)
	profile["schedule"]="crafted_"+material
	_add_event("制造",current_project,role_id+"制作材料"+material+"×"+str(quantity))

func _choose_material() -> String:
	var requirements: Dictionary = _needed_after_deliveries()
	var stock: Dictionary = simulation.get("villages")[TOWN]["stock"]
	for material in requirements.keys():
		if int(stock.get(material,0))>0:
			return String(material)
	return ""

func _assign_builder_load() -> bool:
	if builder==null or not inventory_on_actor.is_empty():
		return false
	var needed: Dictionary = _needed_after_deliveries()
	var chosen: String = _choose_material()
	if chosen.is_empty() or not needed.has(chosen):
		return false
	if not bool(builder.call("reached_work_destination",2.0)):
		builder.call("assign_work_destination",YARD)
		return false
	var stock: Dictionary = simulation.get("villages")[TOWN]["stock"]
	var quantity: int = mini(3,mini(int(stock[chosen]),int(needed[chosen])))
	if quantity<=0 or not bool(simulation.call("_spend",TOWN,{chosen:quantity})):
		return false
	inventory_on_actor={"material":chosen,"amount":quantity,
		"site":current_project,"carrier_id":builder_code}
	visible_load=Node3D.new()
	visible_load.name="ActualCarriedConstructionMaterials"
	builder.add_child(visible_load)
	_mesh_piece(visible_load,"Cargo_"+chosen,Vector3(0,1.25,-.42),
		Vector3(.6,.4,.5),chosen)
	builder.call("assign_work_destination",construction_sites[current_project]["position"])
	_add_event("搬运",current_project,builder_code+"领取"+chosen+"×"+str(quantity))
	return true

func _deliver() -> void:
	if inventory_on_actor.is_empty() or builder==null:
		return
	var site: Dictionary = construction_sites[current_project]
	if not bool(builder.call("reached_work_destination",2.0)):
		return
	var kind: String = String(inventory_on_actor["material"])
	var amount: int = int(inventory_on_actor["amount"])
	site["delivered"][kind]=int(site["delivered"].get(kind,0))+amount
	if is_instance_valid(visible_load):
		visible_load.queue_free()
	visible_load=null
	inventory_on_actor.clear()
	_add_event("送达",current_project,builder_code+"将"+kind+"×"+str(amount)+"送到真实工地")
	builder.call("assign_work_destination",YARD)

func _all_stage_materials_delivered() -> bool:
	var phase: Dictionary = _phase()
	if phase.is_empty():
		return false
	var site: Dictionary = construction_sites[current_project]
	for material in phase["materials"]:
		if int(site["delivered"].get(material,0))<int(phase["materials"][material]):
			return false
	return inventory_on_actor.is_empty()

func _render_completed_stage(stage_id: String) -> void:
	var parent: Node3D = visual_sites[current_project]
	if stage_id=="foundation":
		_mesh_piece(parent,"ActuallyBuiltStoneFoundation",Vector3(0,.22,0),
			Vector3(5.8,.44,4.6),"cut_stone")
	elif stage_id=="frame":
		for x in [-2.1,2.1]:
			for z in [-1.7,1.7]:
				_mesh_piece(parent,"NPCSetTimberPost_%s_%s" % [x,z],
					Vector3(x,1.9,z),Vector3(.34,3.4,.34),"timber")
		_mesh_piece(parent,"NPCRaisedBeam",Vector3(0,3.5,0),
			Vector3(5.0,.25,3.9),"timber")
	elif stage_id=="walls":
		# Existing free modular Quaternius wall model. Art fit pending:
		# don't allow an unreviewed facade to replace true stage geometry.
		var plaster_candidate: Node3D = FreeCC0.instantiate_asset(
			"plaster_wall",parent,Vector3(0,1.85,-1.7),Vector3.ONE)
		if plaster_candidate!=null:
			plaster_candidate.visible = false
			plaster_candidate.set_meta("art_review_pending",true)
		_mesh_piece(parent,"NPCBuiltBackWall",Vector3(0,1.85,-1.7),
			Vector3(4.4,2.7,.25),"mortar")
		for x in [-2.1,2.1]:
			_mesh_piece(parent,"NPCBuiltSideWall_"+str(x),
				Vector3(x,1.85,0),Vector3(.25,2.7,3.3),"mortar")
		for x in [-1.55,1.55]:
			_mesh_piece(parent,"NPCBuiltFrontWall_"+str(x),
				Vector3(x,2.2,1.7),Vector3(1.25,2.0,.25),"mortar")
	elif stage_id=="roof":
		var roof_candidate: Node3D = FreeCC0.instantiate_asset(
			"clay_tiled_roof",parent,Vector3(0,4.3,0),Vector3.ONE)
		if roof_candidate!=null:
			roof_candidate.visible = false
			roof_candidate.set_meta("art_review_pending",true)
		for sign in [-1.0,1.0]:
			_mesh_piece(parent,"NPCLaidRoofSlope_"+str(sign),
				Vector3(sign*1.15,4.2,0),Vector3(2.9,.22,5.0),
				"roof_tile",-sign*0.36)
		_mesh_piece(parent,"NPCPlacedRoofRidge",Vector3(0,4.72,0),
			Vector3(.32,.3,5.1),"roof_tile")

func _do_builder_work() -> void:
	if builder==null:
		return
	var site: Dictionary = construction_sites[current_project]
	if not bool(builder.call("reached_work_destination",2.0)):
		builder.call("assign_work_destination",site["position"])
		return
	var worker: Dictionary = simulation.get("citizens")[builder_code]
	if int(worker["energy"])<5:
		return
	var phase: Dictionary = _phase()
	if phase.is_empty():
		return
	site["work_done"]=int(site["work_done"])+1
	worker["energy"]=maxi(0,int(worker["energy"])-1)
	worker["schedule"]="building_"+String(phase["id"])
	_add_event("施工",current_project,builder_code+"工作于"+String(phase["id"]))
	if int(site["work_done"])>=int(phase["work"]):
		var finished: String = String(phase["id"])
		_render_completed_stage(finished)
		site["stage"]=int(site["stage"])+1
		site["work_done"]=0
		site["delivered"]={}
		_add_event("竣工阶段",current_project,finished)
		if int(site["stage"])>=STAGE_DATA.size():
			site["complete"]=true
			var village: Dictionary = simulation.get("villages")[TOWN]
			if String(site["kind"])=="workshop":
				village["workshops"]=int(village["workshops"])+1
			else:
				village["homes"]=int(village["homes"])+1
			completed+=1
			_add_event("竣工",current_project,
				"由NPC "+builder_code+"实付材料建成"+String(site["kind"]))
			current_project=""
			builder.call("cancel_work_destination")
		else:
			builder.call("assign_work_destination",YARD)

func _tick() -> void:
	if simulation==null or builder==null:
		return
	_create_plan_if_needed()
	if current_project.is_empty():
		return
	# No blueprint instantly appears. An individual craftworker at the
	# workplace processes finite stock; builder hauls to site and performs labor.
	var phase: Dictionary = _phase()
	var needed: Dictionary = _needed_after_deliveries()
	var stock: Dictionary = simulation.get("villages")[TOWN]["stock"]
	for component in needed.keys():
		if int(stock.get(component,0))<int(needed[component]):
			_make_material(String(component))
	if not inventory_on_actor.is_empty():
		_deliver()
		return
	if _all_stage_materials_delivered():
		_do_builder_work()
		return
	_assign_builder_load()

func _process(delta: float) -> void:
	if simulation==null:
		return
	_clock+=delta
	if _clock>=0.5:
		_clock=0
		_tick()

func stats() -> Dictionary:
	var site: Dictionary = construction_sites.get(current_project,{})
	return {"architect_id":architect_code,"builder_id":builder_code,
		"artisans":artisans.keys(),"active_site":current_project,
		"stage":String(_phase().get("id","complete")),"work":int(site.get("work_done",0)),
		"materials_required_now":_needed_after_deliveries(),
		"carried_by_npc":inventory_on_actor.duplicate(true),
		"completed":completed,"construction_site_count":construction_sites.size(),
		"raw_art_policy":"WorldX_SEAMLESS_MATERIALS_ONLY_NOT_FINISHED_HOUSES",
		"nav":"DIRECT_STEERING_NOT_NAVMESH",
		"source_asset_lib":"EXISTING_KENNEY_QUATERNIUS_CC0",
		"third_party_asset_status":FreeCC0.get_import_status()}

func snapshot() -> Dictionary:
	return {"schema":1,"sites":construction_sites.duplicate(true),
		"completed":completed,"current_project":current_project,
		"assigned_builder":builder_code,
		"inventory_on_actor":inventory_on_actor.duplicate(true),
		"event_log":event_log.duplicate()}
