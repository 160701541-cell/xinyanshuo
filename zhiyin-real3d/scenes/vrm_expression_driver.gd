extends Node
## Runtime facial motion for REAL imported VRM face mesh blendshapes.
## No cartoon spheres; this drives true skin morph targets authored in VRM.
## Usage: var face=preload("res://scenes/vrm_expression_driver.gd").new()
##        model.add_child(face); face.attach_avatar(model)
##        face.set_viseme("aa", amplitude); face.set_emotion("joy", 0.8)

const VOWELS: Array[String]=["aa","ih","ou","ee","oh"]
const CANONICAL: Dictionary={
    "blink":["blink","fcl_eye_close","eyeclose","close"],
    "joy":["happy","joy","fcl_all_joy","smile"],
    "angry":["angry","fcl_all_angry","pout"],
    "sad":["sad","fcl_all_sorrow","sorrow"],
    "surprised":["surprised","fcl_all_surprised","surprise"],
    "aa":["aa","a","fcl_mth_a"],
    "ih":["ih","i","fcl_mth_i"],
    "ou":["ou","u","fcl_mth_u"],
    "ee":["ee","e","fcl_mth_e"],
    "oh":["oh","o","fcl_mth_o"]
}
var avatar: Node3D
var shape_bindings: Dictionary={}
var active: Dictionary={}
var last_vowel=""
var blink_timer=3.0
var blink_remaining=0.0
var initialized=false

func _norm(value: String)->String:
    return value.to_lower().replace(" ","").replace("-","").replace("_","").replace(".","")

func _resolve_label(source:String)->String:
    var normalized:=_norm(source)
    var keys=CANONICAL.keys()
    for key in keys:
        for alias in CANONICAL[key]:
            var a: String=_norm(alias)
            if normalized==a or normalized.ends_with(a):
                return key
    return ""

func attach_avatar(root_avatar: Node3D) -> int:
    avatar=root_avatar
    shape_bindings.clear()
    active.clear()
    if avatar==null:
        initialized=false
        return 0
    var total=0
    for raw in avatar.find_children("*","MeshInstance3D",true,false):
        var mesh_node:=raw as MeshInstance3D
        if mesh_node==null or mesh_node.mesh==null:
            continue
        for i in range(mesh_node.mesh.get_blend_shape_count()):
            var shape_name: String=str(mesh_node.mesh.get_blend_shape_name(i))
            var category: String=_resolve_label(shape_name)
            if category.is_empty():
                continue
            if not shape_bindings.has(category):
                shape_bindings[category]=[]
            shape_bindings[category].append({"mesh":mesh_node,"index":i,"name":shape_name})
            total+=1
    initialized=total>0
    set_process(initialized)
    return total

func available_controls() -> PackedStringArray:
    var keys=PackedStringArray()
    for name in shape_bindings.keys():
        keys.append(str(name))
    return keys

func _set_shape(category:String,strength:float) -> void:
    if not shape_bindings.has(category):
        return
    var v=clampf(strength,0.0,1.0)
    active[category]=v
    for bind in shape_bindings[category]:
        var mesh=bind["mesh"] as MeshInstance3D
        if is_instance_valid(mesh):
            mesh.set_blend_shape_value(int(bind["index"]),v)

func set_emotion(mood:String,strength:float=1.0) -> void:
    for key in ["joy","angry","sad","surprised"]:
        _set_shape(key,strength if key==mood else 0.0)

func set_viseme(vowel:String,strength:float) -> void:
    # Only a single vowel can dominate; protect from permanent open mouth.
    for key in VOWELS:
        _set_shape(key,strength if key==vowel else 0.0)
    last_vowel=vowel

func set_silent() -> void:
    set_viseme("",0.0)

func _process(delta:float) -> void:
    if not initialized:
        return
    blink_timer-=delta
    if blink_remaining>0:
        blink_remaining-=delta
        _set_shape("blink",clampf(blink_remaining/.12,0,1))
        if blink_remaining<=0:
            _set_shape("blink",0)
            blink_timer=3.0+randf_range(0.5,2.8)
    elif blink_timer<=0:
        blink_remaining=.20
        _set_shape("blink",1.0)
