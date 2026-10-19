shader_type canvas_item;
uniform vec4 glow_color : source_color = vec4(0.78, 0.86, 1.0, 1.0);
uniform float sweep_speed = 0.55;
uniform float intensity = 1.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	// 环形扫光：0→1 循环，宽窄固定，永远有一条在扫
	float d = fract(UV.x * 0.85 + (1.0 - UV.y) * 0.85 - TIME * sweep_speed);
	float band = smoothstep(0.14, 0.0, abs(d - 0.5));
	band = pow(band, 1.8);
	// 呼吸（整体亮度轻微起伏）
	float pulse = 0.93 + 0.07 * sin(TIME * 1.9);
	// 边缘辉光
	float edge = 1.0 - smoothstep(0.0, 0.12, min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y)));
	vec3 add = glow_color.rgb * band * 1.05 * intensity + glow_color.rgb * edge * 0.40 * intensity;
	c.rgb = c.rgb * pulse + add * c.a;
	COLOR = c;
}
