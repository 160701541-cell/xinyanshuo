extends SceneTree
## Two actual Godot avatar renders for internal art comparison:
## untouched CC0 anime base vs texture-accurate blue recolored CC0 anime base.
## Neither is the final DeepSeek whale-girl reference match.
func _initialize() -> void:
    call_deferred("_shoot")

func _shoot() -> void:
    var sample=load("res://qa_samples/anime_cc0_lookdev.vrm") as PackedScene
    var edited=load("res://qa_samples/blue_anime_lookdev.vrm") as PackedScene
    if sample==null or edited==null:
        push_error("Anime lookdev source or real UV recolored model missing")
        quit(2)
        return
    var stage=Node3D.new()
    root.add_child(stage)
    var original=sample.instantiate() as Node3D
    var blue=edited.instantiate() as Node3D
    stage.add_child(original)
    stage.add_child(blue)
    blue.visible=false
    var world=WorldEnvironment.new()
    var env=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color(.77,.84,.90)
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color(.85,.91,.99)
    env.ambient_light_energy=.45
    world.environment=env
    stage.add_child(world)
    var key=DirectionalLight3D.new()
    key.rotation_degrees=Vector3(-44,22,0)
    key.light_color=Color(1,.93,.84)
    key.light_energy=1.3
    stage.add_child(key)
    var fill=DirectionalLight3D.new()
    fill.rotation_degrees=Vector3(-30,170,0)
    fill.light_color=Color(.68,.82,1)
    fill.light_energy=.42
    stage.add_child(fill)
    var camera=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=2.9
    stage.add_child(camera)
    camera.current=true
    for i in range(25):
        await process_frame
    for variant in ["base","blue"]:
        original.visible=variant=="base"
        blue.visible=variant=="blue"
        for viewpoint in ["front","angle"]:
            original.rotation.y=0.0 if viewpoint=="front" else .72
            blue.rotation.y=original.rotation.y
            camera.position=Vector3(0,1.4,3.25)
            camera.look_at(Vector3(0,1.19,0))
            for i in range(15):
                await process_frame
            await RenderingServer.frame_post_draw
            var frame=root.get_texture().get_image()
            var output="res://anime-"+variant+"-"+viewpoint+".png"
            if frame.save_png(output)!=OK:
                push_error("Screenshot failed: "+output)
                quit(4)
                return
    print("PASS VRM CC0 ANIME BASE ACTUAL GODOT FRONT ANGLE QA SCREENSHOTS (2 variants, neither final)")
    quit(0)
