extends SceneTree

func _initialize() -> void:
    call_deferred("_inspect")

func _inspect() -> void:
    var lib=load("res://assets/animation/UAL1_Standard.glb") as PackedScene
    var female=load("res://assets/characters/Superhero_Female_FullBody.gltf") as PackedScene
    if lib==null or female==null:
        push_error("Required rig/animations not imported")
        quit(2)
        return
    var a=lib.instantiate()
    var b=female.instantiate()
    root.add_child(a)
    root.add_child(b)
    await process_frame
    for actor in [{"name":"MOTION_LIBRARY","root":a},{"name":"FEMALE","root":b}]:
        var scene=actor["root"] as Node
        var players=scene.find_children("*","AnimationPlayer",true,false)
        var bones=scene.find_children("*","Skeleton3D",true,false)
        for raw in bones:
            var sk=raw as Skeleton3D
            var names=[]
            for i in range(sk.get_bone_count()):
                names.append(sk.get_bone_name(i))
            print(actor["name"]," skeleton=",sk.get_path()," count=",sk.get_bone_count()," first_bones=",names.slice(0,18))
        for raw in players:
            var player=raw as AnimationPlayer
            var ids=player.get_animation_list()
            print(actor["name"]," player=",player.get_path()," root=",player.root_node," clips=",ids.size()," names=",ids.slice(0,65))
            if not ids.is_empty():
                var clip=player.get_animation(ids[0])
                print(actor["name"]," first_animation=",ids[0]," tracks=",clip.get_track_count())
                for k in range(mini(clip.get_track_count(),10)):
                    print("TRACK",clip.track_get_path(k), " type=",clip.track_get_type(k))
    quit(0)
