extends Node3D
## Godot 4.4 REAL 3D room test.
## All furniture and avatar are instantiated from actual glTF GLB meshes.
## Room uses StandardMaterial3D (PBR albedo/normal/roughness).
## Only renderer/art/interaction validation: original Android AI, memory,
## payroll and voice services are NOT yet bridged into this scene.

const ROOM := 3.2
const HALF := ROOM * 0.5
const FURNITURE := [
    {"id":"bed","name":"单人床","at":Vector2(-1.01,-0.88),"dims":Vector3(0.88,0.60,1.26),"rotation":0.0},
    {"id":"dresser","name":"储物衣柜","at":Vector2(-1.40,0.02),"dims":Vector3(0.34,1.55,0.78),"rotation":0.0},
    {"id":"bookshelf","name":"书架","at":Vector2(-0.17,-1.34),"dims":Vector3(0.56,1.65,0.26),"rotation":0.0},
    {"id":"stove","name":"灶台","at":Vector2(0.90,-1.29),"dims":Vector3(0.47,0.80,0.43),"rotation":0.0},
    {"id":"sink","name":"水池","at":Vector2(1.37,-1.20),"dims":Vector3(0.32,0.83,0.42),"rotation":0.0},
    {"id":"fridge","name":"小冰箱","at":Vector2(1.38,-0.40),"dims":Vector3(0.33,1.23,0.36),"rotation":0.0},
    {"id":"desk","name":"书桌","at":Vector2(-0.96,0.96),"dims":Vector3(0.81,0.75,0.36),"rotation":0.0},
    {"id":"chair","name":"椅子","at":Vector2(-0.66,0.50),"dims":Vector3(0.36,0.82,0.38),"rotation":0.0},
    {"id":"sofa","name":"坐垫沙发","at":Vector2(0.43,1.06),"dims":Vector3(0.73,0.55,0.41),"rotation":0.0},
    {"id":"plant","name":"植物","at":Vector2(1.32,1.35),"dims":Vector3(0.24,0.85,0.24),"rotation":0.0},
    {"id":"floorlamp","name":"落地灯","at":Vector2(-1.39,1.40),"dims":Vector3(0.24,1.61,0.24),"rotation":0.0},
    {"id":"rug","name":"地毯","at":Vector2(0.26,0.11),"dims":Vector3(0.82,0.020,0.96),"rotation":0.0}
]
var camera: Camera3D
var camera_target := Vector3(0.0,0.72,0.0)
var camera_zoom := 5.25
var active_fingers: Dictionary = {}
var dragging := false
var down_position := Vector2.ZERO
var last_mouse := Vector2.ZERO
var status_text: Label
var task_text: Label
var avatar: Node3D
var avatar_target := Vector3(0.15,0.0,0.10)
var avatar_idle := Vector3(0.15,0.0,0.10)
var avatar_animation: AnimationPlayer
var last_task := "阅读"
var idle_seconds := 0.0
var prop_positions := {}
var picked: String = ""
var material_floor: StandardMaterial3D
var material_wall: StandardMaterial3D
var material_stone: StandardMaterial3D

func _ready() -> void:
    _setup_world()
    material_floor = _pbr("oak", Vector3(2.0,2.0,2.0))
    material_wall = _pbr("wall", Vector3(1.25,1.25,1.25))
    material_stone = _pbr("stone", Vector3(1.0,1.0,1.0))
    _build_room()
    _import_furniture()
    _import_character()
    _setup_camera()
    _setup_ui()
    _status("17项GLB  ·  PBR木纹/法线  ·  3D物理交互")
    set_process(true)
    set_process_unhandled_input(true)

func _setup_world() -> void:
    var env := WorldEnvironment.new()
    env.name="真实3D环境光"
    var setting := Environment.new()
    setting.background_mode = Environment.BG_COLOR
    setting.background_color = Color(0.34,0.47,0.52)
    setting.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    setting.ambient_light_color = Color(0.67,0.75,0.82)
    setting.ambient_light_energy = 0.36
    setting.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.environment=setting
    add_child(env)

    var sunlight := DirectionalLight3D.new()
    sunlight.name="自然阳光"
    sunlight.rotation_degrees=Vector3(-44,-31,0)
    sunlight.light_color=Color(1.0,0.91,0.76)
    sunlight.light_energy=0.63
    sunlight.shadow_enabled=true
    add_child(sunlight)

    var room_light := OmniLight3D.new()
    room_light.name="室内暖光"
    room_light.position=Vector3(0.30,2.13,-0.15)
    room_light.light_color=Color(1.0,0.78,0.57)
    room_light.light_energy=0.27
    room_light.omni_range=4.15
    room_light.shadow_enabled=true
    add_child(room_light)

func _pbr(texture_name:String, tiling:Vector3) -> StandardMaterial3D:
    var out := StandardMaterial3D.new()
    out.metallic=0.0
    out.roughness=0.72
    out.uv1_scale=tiling
    var folder="res://assets/materials/"+texture_name+"_"
    out.albedo_texture=load(folder+"albedo.png")
    out.roughness_texture=load(folder+"roughness.png")
    out.normal_enabled=true
    out.normal_texture=load(folder+"normal.png")
    out.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
    return out

func _mesh_box(label_name:String, size:Vector3, where:Vector3,
               mat:Material, collidable:bool=false) -> MeshInstance3D:
    var mesh := MeshInstance3D.new()
    mesh.name=label_name
    var box := BoxMesh.new()
    box.size=size
    mesh.mesh=box
    mesh.material_override=mat
    mesh.position=where
    mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON
    add_child(mesh)
    if collidable:
        var body := StaticBody3D.new()
        body.name=label_name+"物理阻挡"
        body.position=where
        var shape := CollisionShape3D.new()
        var brick := BoxShape3D.new()
        brick.size=size
        shape.shape=brick
        body.add_child(shape)
        add_child(body)
    return mesh

func _build_room() -> void:
    var slab := _mesh_box("房间地基",Vector3(ROOM+0.19,0.17,ROOM+0.19),
        Vector3(0.0,-0.125,0.0),material_stone,true)
    slab.name="真实3D地基 · 3.2米×3.2米"

    # 16 actual plank meshes, PBR wood albedo + roughness + normal maps.
    for i in range(16):
        var z := -HALF+0.10+i*0.20
        _mesh_box("木地板_%02d" % i,Vector3(ROOM,0.028,0.194),
            Vector3(0,-0.027,z),material_floor,false)

    # Camera looks from +x +z: back and left walls retain usable cutaway view.
    _mesh_box("后墙下半",Vector3(ROOM,0.9,0.12),Vector3(0.0,0.45,-1.66),material_wall,true)
    _mesh_box("后墙窗上",Vector3(ROOM,0.48,0.12),Vector3(0.0,2.28,-1.66),material_wall,false)
    _mesh_box("后墙窗左",Vector3(1.05,0.94,0.12),Vector3(-1.075,1.37,-1.66),material_wall,false)
    _mesh_box("后墙窗右",Vector3(1.05,0.94,0.12),Vector3(1.075,1.37,-1.66),material_wall,false)
    _mesh_box("侧墙",Vector3(0.13,2.55,ROOM),
        Vector3(-1.66,1.275,0.0),material_wall,true)
    _mesh_box("窗台",Vector3(1.09,0.07,0.22),Vector3(0.0,0.92,-1.57),material_floor)
    _mesh_box("窗框上",Vector3(1.09,0.065,0.09),Vector3(0.0,1.81,-1.54),material_floor)
    _mesh_box("窗框左",Vector3(0.055,0.93,0.09),Vector3(-0.54,1.36,-1.54),material_floor)
    _mesh_box("窗框右",Vector3(0.055,0.93,0.09),Vector3(0.54,1.36,-1.54),material_floor)

    var glass := StandardMaterial3D.new()
    glass.albedo_color=Color(0.46,0.74,0.86,0.32)
    glass.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
    glass.roughness=0.13
    glass.metallic=0.07
    _mesh_box("透明窗玻璃",Vector3(1.0,0.89,0.018),
        Vector3(0.0,1.36,-1.63),glass)

    _mesh_box("木制脚线",Vector3(ROOM,0.065,0.04),
        Vector3(0,0.05,-1.58),material_floor)
    _mesh_box("侧墙脚线",Vector3(0.04,0.065,ROOM),
        Vector3(-1.58,0.05,0),material_floor)

func _bounds_of_meshes(root:Node3D) -> AABB:
    var found := false
    var total := AABB()
    for raw in root.find_children("*","MeshInstance3D",true,false):
        var mi := raw as MeshInstance3D
        if mi==null or mi.mesh==null:
            continue
        var b := mi.mesh.get_aabb()
        for x in [b.position.x,b.end.x]:
            for y in [b.position.y,b.end.y]:
                for z in [b.position.z,b.end.z]:
                    var pos := root.to_local(mi.to_global(Vector3(x,y,z)))
                    if not found:
                        total=AABB(pos,Vector3.ZERO)
                        found=true
                    else:
                        total=total.expand(pos)
    return total

func _instantiate_model(model_id:String, world_pos:Vector2,
                        wanted:Vector3, rotation:float) -> Node3D:
    var path := "res://assets/models/"+model_id+".glb"
    var source := load(path) as PackedScene
    if source==null:
        push_error("缺少真正GLB文件: "+path)
        return null
    var root := Node3D.new()
    root.name="REAL_GLTF_"+model_id
    add_child(root)
    var content := source.instantiate() as Node3D
    if content==null:
        push_error("不能实例化GLB: "+path)
        root.queue_free()
        return null
    root.add_child(content)
    var b := _bounds_of_meshes(root)
    if b.size.length()<0.01:
        push_error("GLB缺少可见Mesh: "+path)
        root.queue_free()
        return null
    var resize: float = minf(wanted.x/maxf(0.01,b.size.x),
        minf(wanted.y/maxf(0.01,b.size.y),wanted.z/maxf(0.01,b.size.z)))
    # We use a single uniform scale: no anatomical stretching of humanoids.
    if model_id=="prototype_character":
        # Humanoid height drives scale. X/Z restriction made the full 3D
        # model shrink to an unusable 50-pixel silhouette.
        resize=wanted.y/maxf(0.01,b.size.y)
    root.scale=Vector3.ONE*resize
    root.position=Vector3(world_pos.x,-b.position.y*resize,world_pos.y)
    root.rotation.y=rotation
    return root

func _import_furniture() -> void:
    for prop in FURNITURE:
        var id :String=prop["id"]
        var pos :Vector2=prop["at"]
        var dims :Vector3=prop["dims"]
        var thing:=_instantiate_model(id,pos,dims,float(prop["rotation"]))
        if thing==null:
            continue
        prop_positions[id]=Vector3(pos.x,0,pos.y)
        # Separate, precisely located physics interaction area.
        var zone := Area3D.new()
        zone.name="可交互_"+id
        zone.set_meta("furniture_id",id)
        zone.set_meta("display_name",prop["name"])
        zone.position=Vector3(pos.x,max(0.2,dims.y*0.5),pos.y)
        zone.collision_layer=1
        zone.collision_mask=0
        zone.input_ray_pickable=true
        var collision := CollisionShape3D.new()
        var solid := BoxShape3D.new()
        solid.size=Vector3(dims.x+0.13,max(.35,dims.y),dims.z+0.13)
        collision.shape=solid
        zone.add_child(collision)
        add_child(zone)

func _import_character() -> void:
    avatar=_instantiate_model("prototype_character",Vector2(0.14,0.16),
        Vector3(.35,1.65,.35),0.55)
    if avatar==null:return
    avatar.name="NPC演示体 · 待换高质量骨骼角色"
    avatar_idle=avatar.position
    avatar_target=avatar.position
    var candidates:=avatar.find_children("*","AnimationPlayer",true,false)
    if not candidates.is_empty():
        avatar_animation=candidates[0] as AnimationPlayer
        var tracks:=avatar_animation.get_animation_list()
        if tracks.has("idle"):
            avatar_animation.play("idle")

func _setup_camera() -> void:
    camera=Camera3D.new()
    camera.name="可拖动缩放45度镜头"
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=camera_zoom
    camera.near=.05
    camera.far=80.0
    add_child(camera)
    _set_camera()

func _set_camera() -> void:
    camera.position=camera_target+Vector3(5.5,5.3,7.1)
    camera.look_at(camera_target,Vector3.UP)
    camera.size=camera_zoom

func _process(delta:float) -> void:
    if avatar==null:return
    var to:=avatar_target-avatar.position
    to.y=0.0
    if to.length()>0.04:
        var movement: Vector3 = to.normalized()*minf(to.length(),delta*.65)
        avatar.position+=movement
        avatar.rotation.y=lerp_angle(avatar.rotation.y,atan2(movement.x,movement.z),delta*8.0)
        if avatar_animation!=null and avatar_animation.has_animation("walk"):
            if avatar_animation.current_animation!="walk":
                avatar_animation.play("walk")
    else:
        idle_seconds+=delta
        if avatar_animation!=null and avatar_animation.has_animation("idle"):
            if avatar_animation.current_animation!="idle":
                avatar_animation.play("idle")

func _make_style(color:Color)->StyleBoxFlat:
    var st:=StyleBoxFlat.new()
    st.bg_color=color
    st.set_corner_radius_all(14)
    st.content_margin_left=14
    st.content_margin_right=14
    st.content_margin_top=10
    st.content_margin_bottom=10
    return st

func _setup_ui() -> void:
    var canvas:=CanvasLayer.new()
    add_child(canvas)
    var root:=Control.new()
    # Android/Linux device-local Chinese font instead of missing-glyph tofu.
    var font:=SystemFont.new()
    font.font_names=PackedStringArray(["Noto Sans CJK SC","Noto Sans SC","Noto Sans","Microsoft YaHei","SimHei"])
    var theme:=Theme.new()
    theme.default_font=font
    root.theme=theme
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter=Control.MOUSE_FILTER_IGNORE
    canvas.add_child(root)

    var info:=PanelContainer.new()
    info.offset_left=16;info.offset_top=14
    info.offset_right=412;info.offset_bottom=132
    info.add_theme_stylebox_override("panel",_make_style(Color(.09,.15,.19,.88)))
    root.add_child(info)
    var stack:=VBoxContainer.new()
    info.add_child(stack)
    var title:=Label.new()
    title.text="知音   /   REAL 3D ROOM"
    title.add_theme_font_size_override("font_size",20)
    title.add_theme_color_override("font_color",Color(1,.94,.86))
    stack.add_child(title)
    var subtitle:=Label.new()
    subtitle.text="临河巷  •  3.2 × 3.2 m   •   GLB / PBR"
    subtitle.add_theme_font_size_override("font_size",14)
    subtitle.add_theme_color_override("font_color",Color(.78,.86,.86))
    stack.add_child(subtitle)
    status_text=Label.new()
    status_text.text="正在载入材质和立体模型..."
    status_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    status_text.add_theme_font_size_override("font_size",12)
    status_text.add_theme_color_override("font_color",Color(.98,.79,.60))
    stack.add_child(status_text)

    var dock:=PanelContainer.new()
    dock.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    dock.offset_left=12;dock.offset_top=-95
    dock.offset_right=-12;dock.offset_bottom=-12
    dock.add_theme_stylebox_override("panel",_make_style(Color(.08,.15,.18,.94)))
    root.add_child(dock)
    var row:=HBoxContainer.new()
    row.add_theme_constant_override("separation",10)
    dock.add_child(row)
    _button(row,"回到房间",func():camera_target=Vector3(0,.72,0);camera_zoom=5.25;_set_camera())
    _button(row,"阅读",func():_go_to("desk","她打算到书桌前阅读。"))
    _button(row,"做饭",func():_go_to("stove","她先走到真实3D灶台。"))
    _button(row,"休息",func():_go_to("bed","她回到床边休息。"))
    _button(row,"照料植物",func():_go_to("plant","她准备浇花。"))
    var foot:=Label.new()
    foot.name="3D-only QA / no AI bridge"
    foot.text="3D渲染验收版 · AI/存档待桥接"
    foot.add_theme_color_override("font_color",Color(1,.88,.76))
    foot.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    foot.offset_left=-355;foot.offset_right=-12
    foot.offset_top=20;foot.offset_bottom=52
    root.add_child(foot)

func _button(host:Container, caption:String, action:Callable) -> void:
    var b:=Button.new()
    b.text=caption
    b.custom_minimum_size=Vector2(124,42)
    b.add_theme_stylebox_override("normal",_make_style(Color(.20,.36,.40)))
    b.add_theme_stylebox_override("hover",_make_style(Color(.32,.48,.49)))
    b.add_theme_color_override("font_color",Color(.99,.96,.91))
    b.pressed.connect(action)
    host.add_child(b)

func _status(message:String) -> void:
    if status_text!=null:status_text.text=message

func _go_to(item:String,message:String) -> void:
    if not prop_positions.has(item):
        _status("没有加载"+item+"的真正3D模型。")
        return
    picked=item
    var p :Vector3=prop_positions[item]
    avatar_target=Vector3(clamp(p.x*.72,-1.25,1.25),0,
        clamp(p.z*.72,-1.25,1.25))
    last_task=item
    _status(message)

func _pick(screen:Vector2) -> void:
    var from=camera.project_ray_origin(screen)
    var to=from+camera.project_ray_normal(screen)*100.0
    var query=PhysicsRayQueryParameters3D.create(from,to)
    query.collide_with_areas=true
    query.collide_with_bodies=false
    var result=get_world_3d().direct_space_state.intersect_ray(query)
    if result.is_empty():return
    var obj:=result.get("collider") as CollisionObject3D
    if obj!=null and obj.has_meta("furniture_id"):
        var key :=str(obj.get_meta("furniture_id"))
        var display:=str(obj.get_meta("display_name"))
        _go_to(key,"互动："+display+"，已安排移动到对应物件（目前尚未接真实工作逻辑）。")

func _unhandled_input(event:InputEvent) -> void:
    if event is InputEventMouseButton:
        var e:=event as InputEventMouseButton
        if e.button_index==MOUSE_BUTTON_WHEEL_UP and e.pressed:
            camera_zoom=clamp(camera_zoom-.35,3.5,10.0);_set_camera()
        elif e.button_index==MOUSE_BUTTON_WHEEL_DOWN and e.pressed:
            camera_zoom=clamp(camera_zoom+.35,3.5,10.0);_set_camera()
        elif e.button_index==MOUSE_BUTTON_LEFT:
            if e.pressed:
                down_position=e.position;last_mouse=e.position;dragging=false
            elif not dragging:
                _pick(e.position)
    elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        var e:=event as InputEventMouseMotion
        if e.position.distance_to(down_position)>9:dragging=true
        if dragging:
            _pan(e.relative)
    elif event is InputEventScreenTouch:
        var e:=event as InputEventScreenTouch
        if e.pressed:
            active_fingers[e.index]=e.position
            if active_fingers.size()==1:
                down_position=e.position;dragging=false
        else:
            if active_fingers.size()==1 and not dragging:
                _pick(e.position)
            active_fingers.erase(e.index)
    elif event is InputEventScreenDrag:
        var e:=event as InputEventScreenDrag
        if active_fingers.has(e.index):
            active_fingers[e.index]=e.position
        if active_fingers.size()>=2:
            # Gesture scale is used only with two concurrent fingers.
            var delta_scale=e.relative.x+e.relative.y
            camera_zoom=clamp(camera_zoom+delta_scale*.006,3.5,10)
            _set_camera()
        else:
            if e.position.distance_to(down_position)>11:dragging=true
            if dragging:_pan(e.relative)
    elif event is InputEventMagnifyGesture:
        var e:=event as InputEventMagnifyGesture
        camera_zoom=clamp(camera_zoom/max(.5,e.factor),3.5,10)
        _set_camera()

func _pan(delta:Vector2) -> void:
    camera_target.x=clamp(camera_target.x-delta.x*.004,-1.0,1.0)
    camera_target.z=clamp(camera_target.z+delta.y*.004,-1.0,1.0)
    _set_camera()
