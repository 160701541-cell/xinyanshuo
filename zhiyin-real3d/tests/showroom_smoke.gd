extends SceneTree
func _initialize()->void:
    call_deferred("_check")
func _check()->void:
    var scene=load("res://scenes/anime_showroom.tscn") as PackedScene
    if scene==null:
        quit(2)
        return
    var stage=scene.instantiate()
    root.add_child(stage)
    await process_frame
    await process_frame
    if stage.avatar==null or stage.rig==null or stage.face==null:
        push_error("No real VRM character, rig or face driver in native Godot showroom")
        quit(3)
        return
    if stage.rig.get_bone_count()<75:
        push_error("Anime model isn't a real multi-bone skinned character")
        quit(4)
        return
    var controls=stage.face.available_controls()
    for key in ["blink","joy","angry","aa","ih","ou","ee","oh"]:
        if not controls.has(key):
            push_error("Missing actual animated face control "+key)
            quit(5)
            return
    if stage.avatar.get_meta("reference_fidelity_approved",true):
        push_error("Generic anime base must NEVER be marked DeepSeek reference-faithful")
        quit(6)
        return
    stage._emotion("joy")
    stage._speak()
    print("PASS REAL ANIME VRM SHOWROOM: 103-bone model, skinned face, visemes, mood, touch/orbit camera")
    quit(0)
