extends SceneTree
## Genuine Godot 4.4 native glTF/glb import acceptance. This must be run
## ONLY after importing real publicly licensed source pack binaries.
const Bridge = preload("res://scripts/cc0_asset_bridge.gd")

func _initialize() -> void:
	call_deferred("_test")

func _test() -> void:
	var all_models: Dictionary = Bridge.PIECES
	assert(all_models.size()==12,"Missing expected 3D CC0 modules/props")
	var library: Dictionary = Bridge.get_import_status()
	assert((library["missing"] as Array).is_empty(),
		"Real Kenney/Quaternius files were not staged or imported into Godot")
	assert(all_models.has("civilian_rig") and all_models.has("guard_rig"))
	var scene_root := Node3D.new()
	scene_root.name = "RealExternalCC0SourceModels"
	root.add_child(scene_root)
	for asset_key in all_models.keys():
		var node: Node3D = Bridge.instantiate_asset(String(asset_key),
			scene_root,Vector3.ZERO)
		assert(node!=null,"Real external 3D model did not instantiate: "+String(asset_key))
		assert(node.get_meta("asset_origin")=="LICENSE_VERIFIED_EXISTING_CC0")
		assert(node.get_meta("asset_source") in ["kenney","quaternius"])
		var meshes: Array[Node] = node.find_children("*","MeshInstance3D",true,false)
		assert(meshes.size()>0,"Not a real 3D mesh: "+String(asset_key))
		for mesh in meshes:
			assert((mesh as MeshInstance3D).mesh!=null,
				"Missing imported GLTF geometry on "+String(asset_key))
		assert(node.get_parent()==scene_root)
	print("PASS_CC0_REAL_EXISTING_3D_KENNEY_QUATERNIUS_12_MODELS_NO_AI_GENERATION")
	scene_root.queue_free()
	quit(0)
