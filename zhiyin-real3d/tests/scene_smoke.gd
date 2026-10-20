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
    var assembled_heads: int=0
    var assembled_hair: int=0
    if hero != null:
        assembled_heads=hero.find_children("知音头部","MeshInstance3D",true,false).size()
        assembled_hair=hero.find_children("知音长发*","MeshInstance3D",true,false).size()
    var face_pbr: bool=false
    if hero!=null:
        var face_mesh=hero.find_child("知音头部",true,false) as MeshInstance3D
        if face_mesh!=null and face_mesh.mesh!=null:
            var skin_mat=face_mesh.mesh.surface_get_material(0) as StandardMaterial3D
            face_pbr=skin_mat!=null and skin_mat.albedo_texture!=null and skin_mat.normal_texture!=null
    var hero_motion_count = 0
    var hero_anim_playing = false
    if hero != null:
        var players = hero.find_children("*","AnimationPlayer",true,false)
        for raw in players:
            var player = raw as AnimationPlayer
            if player.has_animation("Idle") and player.has_animation("Walk") and player.has_animation("Sitting_Idle"):
                hero_motion_count = player.get_animation_list().size()
                hero_anim_playing = player.is_playing()
    print("3D QA models=", assets.size(), " meshes=", meshes.size(), " lights=", lights.size(), " pbr=", pbr, " skeletons=", skeletons.size(), " hero_bones=",hero_joints," authentic_motion_clips=",hero_motion_count," playing=",hero_anim_playing," full_head=",assembled_heads," skinned_hair=",assembled_hair," face_PBR=",face_pbr)
    if assets.size() < 10 or meshes.size() < 28 or lights.size() < 2 or pbr < 15 or hero_joints < 50 or hero_motion_count < 40 or not hero_anim_playing or assembled_heads!=1 or assembled_hair<1 or not face_pbr:
        push_error("Godot mesh/material quality gate failed")
        quit(3)
        return
    print("PASS ZHIYIN TRUE 3D RENDER SCENE")
    quit(0)
