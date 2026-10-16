extends Node3D
## Diagnostic in-world markers only, NOT final 3D tree/ore art.
## Never mint or mutate authoritative resources from presentation code.
var sim: RefCounted
var markers: Dictionary = {}
var elapsed: float = 0.0

func setup(world_sim: RefCounted) -> void:
	sim = world_sim
	name = "ResourceDebugMarkersAwaitingLicensedGLB"
	for id in sim.get("resource_positions").keys():
		var p: Vector3 = sim.get("resource_positions")[id]
		var marker := Label3D.new()
		marker.name = String(id)
		marker.position = p + Vector3(0, 1.8, 0)
		marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		marker.font_size = 32
		marker.pixel_size = 0.007
		marker.no_depth_test = false
		add_child(marker)
		markers[id] = marker
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
		elif sim.get("harvested_fields").has(id):
			var field: Dictionary = sim.get("harvested_fields")[id]
			label.text = "%s 农田 %s" % [String(id),
				"可收获" if bool(field.get("ready", false)) else "生长中"]
			label.visible = true
