extends Node3D
## Live presentation of existing authoritative resource nodes using imported,
## provenance-tracked Kenney CC0 meshes. No AI-generated or handmade 3D assets.
## Missing imports leave an explicit diagnostic label, never a fake BoxMesh.
const CC0 = preload("res://scripts/cc0_asset_bridge.gd")
var sim: RefCounted
var markers: Dictionary = {}
var models: Dictionary = {}
var elapsed: float = 0.0
var missing_assets: Array[String] = []

func setup(world_sim: RefCounted) -> void:
	sim = world_sim
	name = "VisibleCC0Resources"
	for id in sim.get("resource_positions").keys():
		var pos: Vector3 = sim.get("resource_positions")[id]
		var anchor := Node3D.new()
		anchor.name = "WorldResource_" + String(id)
		anchor.position = pos
		anchor.set_meta("resource_id", String(id))
		add_child(anchor)
		var marker := Label3D.new()
		marker.name = "InventoryDebug"
		marker.position = Vector3(0, 2.4, 0)
		marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		marker.font_size = 32
		marker.pixel_size = 0.007
		anchor.add_child(marker)
		markers[id] = marker
		if not sim.get("natural_nodes").has(id):
			continue
		var source: Dictionary = sim.get("natural_nodes")[id]
		var kind: String = String(source.get("kind", ""))
		var role: String = "tree_oak" if kind == "tree" else "stone_cluster"
		var visual: Node3D = CC0.instantiate_asset(role, anchor, Vector3.ZERO)
		if visual == null:
			if not missing_assets.has(role):
				missing_assets.append(role)
			continue
		visual.set_meta("resource_id", String(id))
		visual.set_meta("resource_visual_only", true)
		models[id] = visual
	_update_markers()

func _process(delta: float) -> void:
	if sim == null:
		return
	elapsed += delta
	if elapsed < 1.0:
		return
	elapsed = 0.0
	_update_markers()

func _update_markers() -> void:
	for id in markers.keys():
		var label: Label3D = markers[id]
		if sim.get("natural_nodes").has(id):
			var resource: Dictionary = sim.get("natural_nodes")[id]
			var amount: int = int(resource.get("remaining", 0))
			var cap: int = int(resource.get("capacity", amount))
			var kind: String = String(resource.get("kind", "unknown"))
			label.text = "%s %s [%d/%d]" % [String(id), kind, amount, cap]
			label.visible = amount > 0
			if models.has(id):
				var visual: Node3D = models[id]
				visual.visible = amount > 0
				# Grow back visibly over time, never change simulated quantities.
				if kind == "tree" and amount > 0:
					var factor: float = clampf(float(amount) / maxf(1.0, float(cap)), 0.28, 1.0)
					visual.scale = Vector3.ONE * factor
		elif sim.get("harvested_fields").has(id):
			var field: Dictionary = sim.get("harvested_fields")[id]
			label.text = "%s 农田 %s" % [String(id),
				"可收获" if bool(field.get("ready", false)) else "生长中"]
			label.visible = true

func stats() -> Dictionary:
	return {"authored_positions": markers.size(), "cc0_meshes": models.size(),
		"missing_asset_roles": missing_assets.duplicate(),
		"assets_create_zero_resources": true}
