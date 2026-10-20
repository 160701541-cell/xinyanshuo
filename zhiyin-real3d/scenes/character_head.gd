extends RefCounted
## Quaternius FREE CC0: compose the ORIGINAL skinned female head + face +
## original skinned hairstyle with the FREE CC0 full-body Peasant outfit.
## Head extraction concept adapted from BLACKVEIN (MIT, (c) 2026 BLACKVEIN
## contributors): copyright notice retained in CREDITS_THIRD_PARTY.md.
## This avoids a floating separate head rig, nude body under clothing, and
## duplicated armatures which would animate out of sync.

static func _extract_head(original: MeshInstance3D) -> ArrayMesh:
    var input: Array=original.mesh.surface_get_arrays(0)
    var vertices: PackedVector3Array=input[Mesh.ARRAY_VERTEX]
    var joints: PackedInt32Array=input[Mesh.ARRAY_BONES]
    var weights: PackedFloat32Array=input[Mesh.ARRAY_WEIGHTS]
    var idx: PackedInt32Array=input[Mesh.ARRAY_INDEX]
    var per: int=int(joints.size()/maxi(1,vertices.size()))
    if per<=0 or original.skin==null:
        push_error("Original Quaternius base head is missing skin weights")
        return null
    var bind_names: Array[String]=[]
    for i in range(original.skin.get_bind_count()):
        var name_text: String=str(original.skin.get_bind_name(i))
        if name_text=="":
            var bone_idx: int=original.skin.get_bind_bone(i)
            var original_rig:=original.get_node_or_null(original.skeleton) as Skeleton3D
            if original_rig!=null and bone_idx>=0 and bone_idx<original_rig.get_bone_count():
                name_text=str(original_rig.get_bone_name(bone_idx))
        bind_names.append(name_text)
    var is_head:=PackedByteArray()
    is_head.resize(vertices.size())
    for vi in range(vertices.size()):
        var best_weight: float=-1.0
        var bind_idx: int=0
        for wi in range(per):
            var k=vi*per+wi
            if weights[k]>best_weight:
                best_weight=weights[k]
                bind_idx=joints[k]
        var key: String=bind_names[bind_idx] if bind_idx<bind_names.size() else ""
        is_head[vi]=1 if key in ["Head","neck_01"] else 0
    var kept:=PackedInt32Array()
    for tri in range(0,idx.size(),3):
        if tri+2>=idx.size():
            break
        if is_head[idx[tri]]==1 and is_head[idx[tri+1]]==1 and is_head[idx[tri+2]]==1:
            kept.append(idx[tri])
            kept.append(idx[tri+1])
            kept.append(idx[tri+2])
    if kept.is_empty():
        push_error("Female head extraction returned zero triangles")
        return null
    input[Mesh.ARRAY_INDEX]=kept
    for field in [Mesh.ARRAY_CUSTOM0,Mesh.ARRAY_CUSTOM1,Mesh.ARRAY_CUSTOM2,Mesh.ARRAY_CUSTOM3]:
        input[field]=null
    var flags:=Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS if per==8 else 0
    var output:=ArrayMesh.new()
    output.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,input,[],{},flags)
    # Most importantly: retain the actual ORIGINAL skinned head's PBR material.
    # Without this, Godot draws the new face mesh as a frightening gray mask.
    var original_mat:=original.mesh.surface_get_material(0) as StandardMaterial3D
    if original_mat!=null:
        var face_mat:=original_mat.duplicate(true) as StandardMaterial3D
        var face_tex:=load("res://assets/characters/T_Superhero_Female_Light_BaseColor.png") as Texture2D
        if face_tex!=null:
            face_mat.albedo_texture=face_tex
        face_mat.albedo_color=Color(1.0,0.95,0.90)
        output.surface_set_material(0,face_mat)
    return output

static func _attach_mesh(original:MeshInstance3D,rig:Skeleton3D,
                          display:String,override:Mesh=null) -> void:
    var dest:=MeshInstance3D.new()
    dest.name=display
    dest.mesh=override if override!=null else original.mesh
    if display.begins_with("知音长发"):
        var original_hair_mat:=original.mesh.surface_get_material(0) as StandardMaterial3D
        if original_hair_mat!=null:
            var tinted:=original_hair_mat.duplicate(true) as StandardMaterial3D
            tinted.albedo_color=Color(0.29,0.23,0.20)
            tinted.roughness=0.78
            dest.material_override=tinted
    dest.skin=original.skin
    if dest.material_override==null:
        dest.material_override=original.material_override
    dest.transform=original.transform
    rig.add_child(dest)
    dest.skeleton=NodePath("..")

static func attach(avatar:Node3D) -> Dictionary:
    var target_rigs:=avatar.find_children("*","Skeleton3D",true,false)
    if target_rigs.is_empty():
        push_error("Clothed Quaternius avatar missing target Skeleton3D")
        return {}
    var target:=target_rigs[0] as Skeleton3D
    if target.get_bone_count()<50:
        push_error("Clothed Quaternius avatar has invalid bone count")
        return {}
    var base_scene:=load("res://assets/characters/Superhero_Female_FullBody.gltf") as PackedScene
    var hair_scene:=load("res://assets/characters/hair/Hair_Long.gltf") as PackedScene
    if base_scene==null or hair_scene==null:
        push_error("Missing original CC0 base head or hair asset")
        return {}
    var base=base_scene.instantiate()
    var base_rigs=base.find_children("*","Skeleton3D",true,false)
    if base_rigs.is_empty():
        base.free()
        return {}
    var source_skel=base_rigs[0] as Skeleton3D
    if source_skel.get_bone_count()!=target.get_bone_count():
        push_error("Base face and dressed body do not use identical humanoid rigs")
        base.free()
        return {}
    for idx in range(target.get_bone_count()):
        if source_skel.get_bone_name(idx)!=target.get_bone_name(idx):
            push_error("Avatar head skeleton order mismatch")
            base.free()
            return {}
    var head_meshes:int=0
    for node in source_skel.get_children():
        var part:=node as MeshInstance3D
        if part==null:
            continue
        if str(part.name).to_lower().begins_with("superhero"):
            var head:=_extract_head(part)
            if head!=null:
                _attach_mesh(part,target,"知音头部",head)
                head_meshes+=1
        else:
            _attach_mesh(part,target,"知音"+str(part.name))
    base.free()
    var hair=hair_scene.instantiate()
    var hair_meshes:int=0
    for node in hair.find_children("*","MeshInstance3D",true,false):
        var part=node as MeshInstance3D
        if part==null:
            continue
        _attach_mesh(part,target,"知音长发"+str(hair_meshes))
        hair_meshes+=1
    hair.free()
    if head_meshes!=1 or hair_meshes<1:
        push_error("Fully dressed Quaternius NPC must have BOTH face and hair")
        return {}
    return {"head":head_meshes,"hair":hair_meshes,"joints":target.get_bone_count()}
