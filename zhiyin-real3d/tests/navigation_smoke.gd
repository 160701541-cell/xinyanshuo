extends SceneTree

func _initialize() -> void:
    call_deferred("_test")

func _test() -> void:
    var scene = load("res://scenes/apartment.tscn") as PackedScene
    if scene==null:
        quit(5)
        return
    var stage=scene.instantiate()
    root.add_child(stage)
    await process_frame
    var walkable=0
    for target in ["bed","desk","stove","sofa","plant","bookshelf"]:
        stage._go_to(target,"A* QA")
        if stage.waypoint_list.is_empty():
            push_error("No A* route for "+target)
            quit(6)
            return
        if not stage.room_nav.path_is_clear(stage.waypoint_list):
            push_error("Path intersects an occupied furniture grid cell: "+target)
            quit(7)
            return
        walkable+=1
    var motion=stage.avatar_animation as AnimationPlayer
    if motion==null:
        push_error("Missing real skinned AnimationPlayer")
        quit(8)
        return
    for clip in ["Walk","Idle","Sitting_Idle","Interact","Idle_Talking"]:
        if not motion.has_animation(clip):
            push_error("Missing real Quaternius life motion "+clip)
            quit(9)
            return
    print("PASS ZHIYIN FURNITURE PATH A-STAR AND 5 REAL LIFE ANIMATIONS; targets=",walkable,
        " solid_cells=",stage.room_nav.obstacle_count)
    quit(0)
