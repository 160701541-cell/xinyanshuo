extends Node3D
## A real anime VRM beauty/rig test bench. Source: pixiv legacy beta CC0,
## recolored with genuine UV textures (NOT the approved DeepSeek model yet).
## The user’s 3D production avatar is still missing bespoke whale fins/tail,
## customized face, outfit decals, and independent AI/life integration.
const FACE=preload("res://scenes/vrm_expression_driver.gd")
const LOOKDEV="res://assets/characters/lookdev/blue_anime_lookdev.vrm"
var avatar: Node3D
var face: Node
var rig: Skeleton3D
var camera: Camera3D
var status_label: Label
var turn:float=0.0
var angle:float=0.0
var zoom:float=2.15
var dragging:=false
var gesture:Dictionary={}
var last_screen:=Vector2.ZERO
var expression_reset:float=0.0
var elapsed:float=0.0

func _ready() -> void:
    _lighting()
    _camera()
    _avatar()
    _ui()
    set_process(true)
    set_process_unhandled_input(true)

func _lighting() -> void:
    var env=WorldEnvironment.new()
    var setup=Environment.new()
    setup.background_mode=Environment.BG_COLOR
    setup.background_color=Color(.77,.84,.89)
    setup.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    setup.ambient_light_color=Color(.82,.89,1)
    setup.ambient_light_energy=.54
    setup.tonemap_mode=Environment.TONE_MAPPER_FILMIC
    env.environment=setup
    add_child(env)
    var key=DirectionalLight3D.new()
    key.rotation_degrees=Vector3(-47,28,0)
    key.light_color=Color(1,.92,.82)
    key.light_energy=1.02
    key.shadow_enabled=true
    add_child(key)
    var fill=DirectionalLight3D.new()
    fill.rotation_degrees=Vector3(-31,-138,0)
    fill.light_color=Color(.58,.76,1)
    fill.light_energy=.48
    add_child(fill)
    var platform_mat=StandardMaterial3D.new()
    platform_mat.albedo_color=Color(.76,.80,.86)
    platform_mat.roughness=.72
    var platform=CylinderMesh.new()
    platform.height=.11
    platform.top_radius=1.06
    platform.bottom_radius=1.1
    platform.radial_segments=72
    var stand=MeshInstance3D.new()
    stand.name="三维地台"
    stand.mesh=platform
    stand.material_override=platform_mat
    stand.position=Vector3(0,-.10,0)
    add_child(stand)

func _camera() -> void:
    camera=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=zoom
    camera.far=100
    add_child(camera)
    camera.current=true
    _update_camera()

func _update_camera() -> void:
    camera.position=Vector3(sin(angle)*3.0,1.32,cos(angle)*3.0)
    camera.look_at(Vector3(0,.97,0))
    camera.size=zoom

func _avatar() -> void:
    var model=load(LOOKDEV) as PackedScene
    if model==null:
        push_error("没有经过VRM导入的专业动漫基型")
        return
    avatar=model.instantiate() as Node3D
    if avatar==null:
        push_error("真实VRM模型不能实例化")
        return
    avatar.name="CC0_AnimeLookdev_NOT_DeepSeek_Final"
    add_child(avatar)
    var rigs=avatar.find_children("*","Skeleton3D",true,false)
    if rigs.is_empty():
        push_error("角色缺少SkinnedSkeleton3D")
        return
    rig=rigs[0] as Skeleton3D
    # Use actual upper-arm joints, not a hand-drawn static sticker.
    _arm_pose("J_Bip_L_UpperArm",-57)
    _arm_pose("J_Bip_R_UpperArm",57)
    face=FACE.new()
    avatar.add_child(face)
    var count=face.attach_avatar(avatar)
    if count<8:
        push_error("角色面部表情BlendShape绑定不完整")
    avatar.set_meta("avatar_id","lookdev_cc0_anime_base")
    avatar.set_meta("reference_fidelity_approved",false)

func _arm_pose(bone_name:String,degrees:float) -> void:
    if rig==null:
        return
    var idx=rig.find_bone(bone_name)
    if idx<0:
        push_warning("Missing imported upper-arm bone "+bone_name)
        return
    var source=rig.get_bone_pose_rotation(idx)
    rig.set_bone_pose_rotation(idx,source*Quaternion(Vector3(0,0,1),deg_to_rad(degrees)))

func _style(c:Color,corner:int=18) -> StyleBoxFlat:
    var st=StyleBoxFlat.new()
    st.bg_color=c
    st.set_corner_radius_all(corner)
    st.content_margin_left=15
    st.content_margin_right=15
    st.content_margin_top=10
    st.content_margin_bottom=10
    return st

func _make_btn(host:HBoxContainer,label:String,cb:Callable) -> void:
    var btn=Button.new()
    btn.text=label
    btn.custom_minimum_size=Vector2(135,46)
    btn.add_theme_color_override("font_color",Color(.97,.98,1))
    btn.add_theme_stylebox_override("normal",_style(Color(.18,.31,.47)))
    btn.add_theme_stylebox_override("hover",_style(Color(.25,.42,.58)))
    btn.pressed.connect(cb)
    host.add_child(btn)

func _ui() -> void:
    var layer=CanvasLayer.new()
    add_child(layer)
    var root=Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter=Control.MOUSE_FILTER_IGNORE
    var system_font=SystemFont.new()
    system_font.font_names=PackedStringArray(["Noto Sans CJK SC","Noto Sans SC","Microsoft YaHei","Noto Sans"])
    var theme=Theme.new()
    theme.default_font=system_font
    root.theme=theme
    layer.add_child(root)
    var title=PanelContainer.new()
    title.set_anchors_preset(Control.PRESET_TOP_LEFT)
    title.offset_left=18
    title.offset_top=16
    title.offset_right=465
    title.offset_bottom=144
    title.add_theme_stylebox_override("panel",_style(Color(.10,.18,.28,.91)))
    root.add_child(title)
    var labels=VBoxContainer.new()
    title.add_child(labels)
    var heading=Label.new()
    heading.text="知音 / 蓝鲸少女 · 真人形VRM美术试验"
    heading.add_theme_font_size_override("font_size",19)
    heading.add_theme_color_override("font_color",Color(.89,.96,1))
    labels.add_child(heading)
    var subtitle=Label.new()
    subtitle.text="真实VRoid动漫基型 / UV蓝发 / 蓝瞳 / 3D布料"
    subtitle.add_theme_color_override("font_color",Color(.66,.80,.92))
    labels.add_child(subtitle)
    status_label=Label.new()
    status_label.text="外观仍未还原原图：鲸鳍、鲸尾、专属脸型待制作"
    status_label.add_theme_color_override("font_color",Color(1,.78,.54))
    labels.add_child(status_label)

    var dock=PanelContainer.new()
    dock.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    dock.offset_left=16
    dock.offset_right=-16
    dock.offset_top=-84
    dock.offset_bottom=-14
    dock.add_theme_stylebox_override("panel",_style(Color(.09,.17,.25,.94)))
    root.add_child(dock)
    var row=HBoxContainer.new()
    row.add_theme_constant_override("separation",8)
    dock.add_child(row)
    _make_btn(row,"正面",func(): angle=0;_update_camera())
    _make_btn(row,"侧面",func(): angle=PI*.5;_update_camera())
    _make_btn(row,"背面",func(): angle=PI;_update_camera())
    _make_btn(row,"微笑",func(): _emotion("joy"))
    _make_btn(row,"生气",func(): _emotion("angry"))
    _make_btn(row,"张嘴",func(): _speak())
    _make_btn(row,"复位",func(): angle=0;zoom=2.15;_update_camera();_emotion(""))

func _emotion(mood:String) -> void:
    if face!=null:
        face.set_emotion(mood,1.0)
    expression_reset=3.5 if not mood.is_empty() else 0.0
    status_label.text="真实表情BlendShape："+(mood if not mood.is_empty() else "已恢复")

func _speak() -> void:
    if face!=null:
        face.set_viseme("aa",1.0)
        expression_reset=1.4
        status_label.text="真实嘴部BlendShape：A元音（仅测试，未接AI语音）"

func _process(delta:float) -> void:
    elapsed+=delta
    if expression_reset>0.0:
        expression_reset-=delta
        if expression_reset<=0 and face!=null:
            face.set_emotion("",0.0)
            face.set_silent()
            status_label.text="实时眨眼运行中 · 当前仅为3D美术基型"

func _unhandled_input(e:InputEvent) -> void:
    if e is InputEventMouseButton:
        var b=e as InputEventMouseButton
        if b.button_index==MOUSE_BUTTON_WHEEL_UP and b.pressed:
            zoom=clampf(zoom-.12,1.15,4.2);_update_camera()
        elif b.button_index==MOUSE_BUTTON_WHEEL_DOWN and b.pressed:
            zoom=clampf(zoom+.12,1.15,4.2);_update_camera()
        elif b.button_index==MOUSE_BUTTON_LEFT:
            dragging=b.pressed
            last_screen=b.position
    elif e is InputEventMouseMotion and dragging:
        var motion=e as InputEventMouseMotion
        angle+=motion.relative.x*.008
        _update_camera()
    elif e is InputEventScreenTouch:
        var touch=e as InputEventScreenTouch
        if touch.pressed:
            gesture[touch.index]=touch.position
        else:
            gesture.erase(touch.index)
    elif e is InputEventScreenDrag:
        var drag=e as InputEventScreenDrag
        gesture[drag.index]=drag.position
        if gesture.size()>1:
            zoom=clampf(zoom+drag.relative.y*.006,1.15,4.2)
        else:
            angle+=drag.relative.x*.011
        _update_camera()
    elif e is InputEventMagnifyGesture:
        zoom=clampf(zoom/maxf(.6,(e as InputEventMagnifyGesture).factor),1.15,4.2)
        _update_camera()
