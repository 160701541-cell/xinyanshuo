extends SceneTree
## Renders real imported CC0 anime VRM as a LOOKDEV base for visual review.
## Never label these pixels as DeepSeek. They are an existing pixiv model
## (old beta, CC0 sample), without the user-specific whale character details.
func _initialize() -> void:
    call_deferred("_shoot")

func _shoot() -> void:
    var sample=load("res://qa_samples/anime_cc0_lookdev.vrm") as PackedScene
    if sample==null:
        quit(2)
        return
    var stage=Node3D.new()
    stage.name="CC0动漫角色建模基底评估"
    root.add_child(stage)
    var avatar=sample.instantiate() as Node3D
    if avatar==null:
        quit(3)
        return
    stage.add_child(avatar)
    var background=WorldEnvironment.new()
    var environment=Environment.new()
    environment.background_mode=Environment.BG_COLOR
    environment.background_color=Color(.76,.83,.89)
    environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color=Color(.85,.89,.99)
    environment.ambient_light_energy=.5
    background.environment=environment
    stage.add_child(background)
    var key=DirectionalLight3D.new()
    key.rotation_degrees=Vector3(-45,18,-10)
    key.light_color=Color(1,.92,.84)
    key.light_energy=1.2
    stage.add_child(key)
    var fill=DirectionalLight3D.new()
    fill.rotation_degrees=Vector3(-30,170,10)
    fill.light_color=Color(.68,.82,1)
    fill.light_energy=.4
    stage.add_child(fill)
    var camera=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=2.7
    stage.add_child(camera)
    camera.current=true
    for i in range(30):
        await process_frame
    for pass_name in ["front","angle"]:
        avatar.rotation.y=0.0 if pass_name=="front" else .73
        camera.position=Vector3(0,1.35,3.1)
        camera.look_at(Vector3(0,1.23,0))
        for i in range(20):
            await process_frame
        await RenderingServer.frame_post_draw
        var frame=root.get_texture().get_image()
        if frame.save_png("res://anime-base-"+pass_name+".png")!=OK:
            quit(4)
            return
    print("PASS VRM CC0 ANIME BASE ACTUAL GODOT FRONT ANGLE QA SCREENSHOTS -- NOT DEEPSEEK")
    quit(0)
