extends SceneTree

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var scene = load("res://scenes/apartment.tscn") as PackedScene
    if scene == null:
        push_error("Scene is absent")
        quit(2)
        return
    var stage = scene.instantiate()
    root.add_child(stage)
    await process_frame
    await process_frame
    var meshes = stage.find_children("*", "MeshInstance3D", true, false)
    var assets = stage.find_children("REAL_GLTF_*", "Node3D", true, false)
    var lights = stage.find_children("*", "Light3D", true, false)
    var pbr = 0
    for raw in meshes:
        var material = (raw as MeshInstance3D).material_override
        if material is StandardMaterial3D:
            if material.albedo_texture != null and material.roughness_texture != null and material.normal_texture != null:
                pbr += 1
    print("3D QA models=", assets.size(), " meshes=", meshes.size(), " lights=", lights.size(), " pbr=", pbr)
    if assets.size() < 10 or meshes.size() < 28 or lights.size() < 2 or pbr < 15:
        push_error("Godot mesh/material quality gate failed")
        quit(3)
        return
    print("PASS ZHIYIN TRUE 3D RENDER SCENE")
    quit(0)
