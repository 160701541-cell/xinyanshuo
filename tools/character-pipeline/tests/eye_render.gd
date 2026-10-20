extends SceneTree
## 把 face_decal.gdshader 的眼（mode 0）真实渲染成一张图，用来肉眼检查眼睛。
## 需要有显示：xvfb-run -a godot --rendering-driver opengl3 --path <项目根> \
##   --script res://tools/character-pipeline/tests/eye_render.gd -- <out.png>
## （headless 模式不会编译 shader，必须用 opengl3/vulkan。<项目根> 要能解析 res://tools/...）
## 注意：Godot 的 UV.y 朝下；眼睛分支用 e=(p.x,-p.y) 作"向上为正"的坐标，见 shader 注释。

func _init() -> void:
	var out_path: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "eye_render.png"
	var vp := SubViewport.new()
	vp.size = Vector2i(1100, 300)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.60, 0.46, 0.34)
	we.environment = env
	vp.add_child(we)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 1.5
	cam.position = Vector3(0, 0, 3)
	vp.add_child(cam)
	cam.current = true
	var sh: Shader = load("res://tools/character-pipeline/src/face_decal.gdshader")
	for si in 2:
		var q := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(2.0, 1.0)
		q.mesh = qm
		q.position = Vector3(-1.1 if si == 0 else 1.1, 0, 0)
		var m := ShaderMaterial.new()
		m.shader = sh
		m.set_shader_parameter("mode", 0)
		m.set_shader_parameter("side", -1.0 if si == 0 else 1.0)
		q.material_override = m
		vp.add_child(q)
	for i in 8:
		await process_frame
	vp.get_texture().get_image().save_png(out_path)
	print("SAVED ", out_path)
	quit()
