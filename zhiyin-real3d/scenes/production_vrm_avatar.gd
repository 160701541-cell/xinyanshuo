extends RefCounted
## Production VRM prefab adapter. Distinct from the rejected v0.9.4
## Quaternius/procedurally assembled whale character.
##
## Packaging rule: an authored VRM must be supplied with the full, licensed
## hair, eyes, costume, blue/white texture set and real facial morph binds.
## Mere blue-tinted CC0 sample base is never accepted as final DeepSeek.
const PRODUCTION_BLUE="res://assets/characters/production/DeepSeek_Blue.vrm"
const PRODUCTION_AMBER="res://assets/characters/production/Claude_Amber.vrm"
const FACE_SCRIPT=preload("res://scenes/vrm_expression_driver.gd")

static func _inspect(root:Node3D) -> Dictionary:
    var rigs=root.find_children("*","Skeleton3D",true,false)
    var pieces=root.find_children("*","MeshInstance3D",true,false)
    var highest_bones=0
    var morphs=0
    var textured=0
    for raw in rigs:
        var skel=raw as Skeleton3D
        highest_bones=maxi(highest_bones,skel.get_bone_count())
    for raw in pieces:
        var part=raw as MeshInstance3D
        if part.mesh==null:continue
        morphs+=part.mesh.get_blend_shape_count()
        for surface in range(part.mesh.get_surface_count()):
            var mat=part.get_active_material(surface)
            if mat is ShaderMaterial or (mat is StandardMaterial3D and (mat as StandardMaterial3D).albedo_texture!=null):
                textured+=1
    return {"bones":highest_bones,"meshes":pieces.size(),"morphs":morphs,"textured_surfaces":textured}

static func load_actor(parent:Node3D,identity:String,where:Vector3) -> Dictionary:
    var asset=PRODUCTION_BLUE if identity=="npc_deepseek_blue" else PRODUCTION_AMBER if identity=="npc_claude_amber" else ""
    if asset.is_empty() or not ResourceLoader.exists(asset):
        return {"status":"MISSING_AUTHORED_VRM","identity":identity}
    var packed=load(asset) as PackedScene
    if packed==null:
        return {"status":"IMPORT_FAILED","identity":identity}
    var obj=packed.instantiate() as Node3D
    if obj==null:
        return {"status":"NOT_3D_RIG","identity":identity}
    var stats=_inspect(obj)
    if stats["bones"]<45 or stats["meshes"]<6 or stats["morphs"]<8 or stats["textured_surfaces"]<5:
        obj.free()
        return {"status":"FAILED_3D_ART_GATE","identity":identity,"stats":stats}
    # Rendering models alone is not sufficient: face lips, expression controls
    # are required for a conversational companion.
    var driver=FACE_SCRIPT.new()
    driver.name="真实面部表情和口型"
    obj.add_child(driver)
    var controls=driver.attach_avatar(obj)
    if controls<5:
        obj.free()
        return {"status":"FAILED_MORPH_BINDING","identity":identity,"stats":stats}
    obj.name=identity
    obj.position=where
    parent.add_child(obj)
    obj.set_meta("npc_id",identity)
    obj.set_meta("production_avatar",true)
    obj.set_meta("model_provider_independent",true)
    return {"status":"LOADED_REAL_VRM","identity":identity,"node":obj,
            "driver":driver,"stats":stats,
            "visual_qa":"PENDING_HUMAN_REFERENCE_MATCH"}
