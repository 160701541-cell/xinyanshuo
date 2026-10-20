shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;

uniform int mode = 0;          // 0=眼 1=眉 2=嘴
uniform float side = 1.0;
uniform vec3 sclera : source_color = vec3(0.97, 0.96, 0.93);
uniform vec3 pupil : source_color = vec3(0.06, 0.05, 0.05);
uniform vec3 browc : source_color = vec3(0.09, 0.07, 0.07);
uniform vec3 lipc : source_color = vec3(0.55, 0.18, 0.17);
// 眼睛（mode 0）专用，默认值即可直接用，cloth.gd 不用改
uniform vec3 iris : source_color = vec3(0.22, 0.12, 0.07);
uniform vec3 flesh : source_color = vec3(0.80, 0.52, 0.47);
uniform vec3 lid : source_color = vec3(0.10, 0.08, 0.08);
uniform float catch_light : hint_range(0.0, 1.0) = 0.95;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	p.x *= side;
	float a = 0.0;
	vec3 col = sclera;

	if (mode == 0) {
		// 注意：Godot 的 UV.y 朝下，所以 p.y 正方向是画面下方。
		// 眼睛用 e（向上为正、+x 朝外眼角）作坐标，上睑才会画在上面。
		vec2 e = vec2(p.x, -p.y);
		// 细长上挑的眼：横 1 : 竖 0.42；外眼角（+e.x）抬高
		vec2 q = e;
		q.y -= 0.18 * q.x;
		float d = length(vec2(q.x / 0.95, q.y / 0.42));
		a = 1.0 - smoothstep(0.90, 1.0, d);

		// 1) 眼球体积感：越靠近眼角/下缘越暗；内眼角（-e.x 一侧）带一点肉色
		col = sclera * (1.0 - 0.24 * smoothstep(0.30, 1.0, d));
		col = mix(col, flesh, 0.55 * smoothstep(0.55, 0.95, -e.x));

		// 2) 虹膜 + 瞳孔：径向渐变，边缘一圈深色角膜缘
		vec2 ip = e - vec2(0.10, -0.02);
		float idist = length(ip / vec2(0.31, 0.38));
		float imask = 1.0 - smoothstep(0.90, 1.0, idist);
		vec3 ic = mix(iris * 1.30, iris * 0.55, smoothstep(0.15, 0.95, idist));
		ic = mix(ic, pupil, 0.65 * smoothstep(0.78, 1.0, idist));
		col = mix(col, ic, imask);
		float pd = length(ip / vec2(0.145, 0.18));
		col = mix(col, pupil, 1.0 - smoothstep(0.85, 1.0, pd));

		// 3) 上睑在眼球上的投影（越靠近上睑越暗），虹膜上缘被盖住一点
		col *= 1.0 - 0.38 * smoothstep(-0.05, 0.30, e.y);

		// 4) 高光：光从屏幕左上来，两只眼的高光在屏幕上同侧（用未镜像的 raw.x）
		vec2 raw = vec2(e.x * side, e.y);
		vec2 pc = vec2(0.10 * side, -0.02);
		float hl = 1.0 - smoothstep(0.55, 1.0, length((raw - pc - vec2(-0.07, 0.11)) / vec2(0.075, 0.095)));
		float hl2 = 1.0 - smoothstep(0.55, 1.0, length((raw - pc - vec2(0.08, -0.10)) / vec2(0.04, 0.05)));
		col = mix(col, vec3(1.0), clamp(hl * catch_light + hl2 * 0.35 * catch_light, 0.0, 1.0));

		// 5) 上睑线：外眼角（+e.x）加粗上挑，像睫毛根；下睑一条很淡的线
		float lw = 0.10 + 0.07 * smoothstep(0.0, 0.9, e.x);
		float lidline = 1.0 - smoothstep(0.0, lw, abs(e.y - 0.30));
		col = mix(col, pupil, lidline * 0.88);
		float lower = 1.0 - smoothstep(0.0, 0.09, abs(d - 0.93));
		col = mix(col, lid * 2.2, lower * 0.30 * (1.0 - smoothstep(-0.10, 0.10, e.y)));

		// 切掉上三分之一
		a *= 1.0 - smoothstep(0.34, 0.56, e.y);
	} else if (mode == 1) {
		// 斜挑的眉：细长椭圆
		vec2 q = p;
		q.y += 0.22 * q.x;
		float d = length(vec2(q.x / 0.92, q.y / 0.34));
		a = 1.0 - smoothstep(0.75, 1.0, d);
		col = browc;
	} else {
		// 嘴：上唇 + 下唇 + 中缝
		float up = length(vec2(p.x / 0.86, (p.y - 0.16) / 0.30));
		float dn = length(vec2(p.x / 0.80, (p.y + 0.24) / 0.34));
		a = max(1.0 - smoothstep(0.86, 1.0, up), 1.0 - smoothstep(0.86, 1.0, dn));
		col = lipc;
		float seam = 1.0 - smoothstep(0.0, 0.12, abs(p.y));
		col = mix(col, lipc * 0.35, seam);
	}
	ALBEDO = col;
	ALPHA = a;
}
