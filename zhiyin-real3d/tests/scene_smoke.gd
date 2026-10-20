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
    var skeletons = stage.find_children("*", "Skeleton3D", true, false)
    var hero = stage.get_node_or_null("知音 · 65关节Humanoid骨骼角色")
    var hero_joints = 0
    if hero != null:
        for node in hero.find_children("*", "Skeleton3D", true, false):
            hero_joints = maxi(hero_joints, (node as Skeleton3D).get_bone_count())
    print("3D QA models=", assets.size(), " meshes=", meshes.size(), " lights=", lights.size(), " pbr=", pbr, " skeletons=", skeletons.size(), " hero_bones=",hero_joints)
    if assets.size() < 10 or meshes.size() < 28 or lights.size() < 2 or pbr < 15 or hero_joints < 50:
        push_error("Godot mesh/material quality gate failed")
        quit(3)
        return
    print("PASS ZHIYIN TRUE 3D RENDER SCENE")
    quit(0)
