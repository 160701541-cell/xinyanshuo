shader_type spatial;
// 罩体：只有边缘发光（菲涅尔），中间近乎透明 —— 解决“鸡笼”感
render_mode unshaded, cull_disabled, blend_add, depth_draw_never, shadows_disabled;
uniform vec4 tint : source_color = vec4(0.34, 0.78, 0.64, 1.0);
uniform float power = 2.6;
uniform float strength = 1.6;

void fragment() {
	float f = 1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float rim = pow(f, power) * strength;
	ALBEDO = tint.rgb * rim;
}
