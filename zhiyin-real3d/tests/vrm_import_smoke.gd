extends SceneTree
## This test validates the importer and an anime-style rig, NOT reference
## likeness. The model is CC0 pixiv legacy sample and must not be shipped
## under the DeepSeek/Claude identity without full independent art production.
func _initialize() -> void:
    call_deferred("_verify")
func _verify() -> void:
    var sample:=load("res://qa_samples/anime_cc0_lookdev.vrm") as PackedScene
    if sample==null:
        push_error("VRM importer did not produce a real PackedScene")
        quit(2)
        return
    var root_avatar:=sample.instantiate()
    root.add_child(root_avatar)
    await process_frame
    await process_frame
    var rigged=root_avatar.find_children("*","Skeleton3D",true,false)
    var drawables=root_avatar.find_children("*","MeshInstance3D",true,false)
    var morph_names: PackedStringArray=PackedStringArray()
    var textured=0
    var custom_shader=0
    var joint_count=0
    for item in rigged:
        var s=item as Skeleton3D
        joint_count=maxi(joint_count,s.get_bone_count())
    for item in drawables:
        var mesh3d=item as MeshInstance3D
        if mesh3d.mesh==null:
            continue
        for idx in range(mesh3d.mesh.get_blend_shape_count()):
            morph_names.append(str(mesh3d.mesh.get_blend_shape_name(idx)))
        for si in range(mesh3d.mesh.get_surface_count()):
            var mat=mesh3d.get_active_material(si)
            if mat is ShaderMaterial:
                custom_shader+=1
            elif mat is StandardMaterial3D:
                if (mat as StandardMaterial3D).albedo_texture!=null:
                    textured+=1
    print("VRM_LOOKDEV_IMPORT_LOG"," bones=",joint_count," meshes=",drawables.size(),
          " facial_morphs=",morph_names.size()," real_textured_materials=",textured,
          " MToon_or_other_shader_materials=",custom_shader,
          " example_morphs=",morph_names.slice(0,12))
    if joint_count<40 or drawables.size()<2:
        push_error("Not a real skinned humanoid anime VRM")
        quit(3)
        return
    if morph_names.size()<3:
        push_error("Anime VRM import stripped real blendshape expressions")
        quit(4)
        return
    if textured+custom_shader<2:
        push_error("VRM lost all its face, clothing and hair materials")
        quit(5)
        return
    var Driver=load("res://scenes/vrm_expression_driver.gd")
    var face=Driver.new() as Node
    root_avatar.add_child(face)
    var bound=face.attach_avatar(root_avatar)
    print("VRM_FACE_DRIVER bound=",bound," control_names=",face.available_controls())
    if bound<2:
        push_error("Imported anime face does not expose enough usable morph controls")
        quit(6)
        return
    face.set_emotion("joy",0.75)
    face.set_viseme("aa",0.90)
    face.set_silent()
    var Production=load("res://scenes/production_vrm_avatar.gd")
    var desired=Production.load_actor(root_avatar,"npc_deepseek_blue",Vector3.ZERO)
    if str(desired.get("status",""))!="MISSING_AUTHORED_VRM":
        push_error("Production must NOT silently substitute a generic sample avatar")
        quit(7)
        return
    print("PASS: missing authored DeepSeek asset never silently replaced by a generic mannequin")
    print("PASS REAL VRM ANIME MODEL IMPORT + SKELETON + FACIAL MORPHS + MATERIALS")
    quit(0)
