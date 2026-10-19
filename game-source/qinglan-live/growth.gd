extends Node3D
# 生长/建造动画：用世界 Y 截断，从地面往上"长"出来

var shader_src := """
shader_type spatial;
render_mode cull_disabled;
uniform float cut = 100.0;
uniform float edge = 0.35;
varying vec3 wpos;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	if (wpos.y > cut) discard;
	ALBEDO = COLOR.rgb;
	if (wpos.y > cut - edge) {
		ALBEDO = mix(COLOR.rgb, vec3(1.0, 0.92, 0.7), 0.55);
	}
	ROUGHNESS = 0.92;
}
"""

var mats: Array[ShaderMaterial] = []
var tops: Array[float] = []

func _ready() -> void:
	_env()
	var sh := Shader.new()
	sh.code = shader_src
	# 房子
	var vb1 = load("res://voxel.gd").new()
	_house(vb1, 0, 0)
	_add(vb1, sh, Vector3(-5.5, 0, 0))
	# 树
	var vb2 = load("res://voxel.gd").new()
	var tg = load("res://trees.gd").new()
	tg.vb = vb2
	tg.broadleaf(16, Color(0.24, 0.42, 0.21))
	_add(vb2, sh, Vector3(5.5, 0, 0))
	_label("建造：地基 → 柱 → 梁 → 瓦", Vector3(-5.5, -0.9, 6.0))
	_label("生长：主干 → 分枝 → 展叶", Vector3(5.5, -0.9, 6.0))
	var cam := Camera3D.new()
	cam.position = Vector3(0, 4.2, 13.5)
	cam.fov = 45
	add_child(cam)
	cam.look_at(Vector3(0, 2.2, 0), Vector3.UP)

func _house(vb, cx: int, cz: int) -> void:
	vb.box(cx - 9, 0, cz - 7, cx + 9, 1, cz + 7, Color(0.62, 0.60, 0.55))
	vb.box(cx - 8, 1, cz - 6, cx + 8, 9, cz + 6, Color(0.74, 0.68, 0.55), 0.03)
	for sx in [-1, 1]:
		vb.box(cx + sx * 8 - 1, 1, cz - 6, cx + sx * 8, 9, cz + 6, Color(0.36, 0.26, 0.18))
	vb.box(cx - 9, 9, cz - 7, cx + 9, 10, cz + 7, Color(0.36, 0.26, 0.18))
	for i in 3:
		var ext := 2 - i
		vb.box(cx - 9 - ext, 10 + i * 2, cz - 7 - ext, cx + 9 + ext, 12 + i * 2, cz + 7 + ext, Color(0.56, 0.46, 0.28).darkened(float(i) * 0.06), 0.05)
	vb.box(cx - 2, 1, cz - 7, cx + 2, 5, cz - 6, Color(0.26, 0.18, 0.12))
	vb.box_e(cx + 3, 2, cz - 7, cx + 6, 5, cz - 6, Color(1.0, 0.74, 0.38))

func _add(vb, sh: Shader, at: Vector3) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("cut", -1.0)
	mats.append(mat)
	var arr: Array = vb.build(mat, mat)
	for m in arr:
		m.position = at
		add_child(m)
	var top := 0.0
	for k in vb.solid.keys():
		top = max(top, float(k.y) * 0.25 + at.y)
	tops.append(top + 0.4)

func _label(t: String, at: Vector3) -> void:
	var l := Label3D.new()
	var f := FontFile.new()
	f.data = FileAccess.get_file_as_bytes("res://cjk.ttc")
	l.font = f
	l.text = t
	l.font_size = 96
	l.pixel_size = 0.006
	l.modulate = Color(0.95, 0.92, 0.84)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = at
	add_child(l)

func _env() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.10, 0.11, 0.13)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.66, 0.70, 0.80)
	env.ambient_light_energy = 0.85
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -34, 0)
	sun.light_energy = 1.5
	add_child(sun)

func _process(_d: float) -> void:
	var t := fmod(Time.get_ticks_msec() / 1000.0, 6.0) / 3.4
	t = clampf(t, 0.0, 1.0)
	t = t * t * (3.0 - 2.0 * t)
	for i in mats.size():
		mats[i].set_shader_parameter("cut", lerpf(-1.0, tops[i], t))
