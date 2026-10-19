shader_type spatial;
// 工笔底：PBR 参数按美术纪律固定，只加一点轮廓冷光
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec4 albedo : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.85;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform vec3 rim_color : source_color = vec3(0.72, 0.86, 1.0);
uniform float rim_strength : hint_range(0.0, 1.0) = 0.10;
// 布料摆动：越往下摆幅越大；phase 让多层布错开相位
uniform float wind_amp = 0.0;
uniform float wind_phase = 0.0;
uniform float wind_gust = 1.0;

void vertex() {
	if (wind_amp > 0.0001) {
		float h = clamp((0.10 - VERTEX.y) / 0.55, 0.0, 1.0);
		float w = h * h;
		float t = TIME * 1.9 + wind_phase;
		VERTEX.x += sin(t + VERTEX.y * 3.2) * wind_amp * w * wind_gust;
		VERTEX.z += cos(t * 0.8 + wind_phase * 1.7) * wind_amp * 0.65 * w * wind_gust;
		VERTEX.y -= abs(sin(t)) * wind_amp * 0.12 * w;
	}
}

void fragment() {
	ALBEDO = albedo.rgb;
	ROUGHNESS = roughness;
	METALLIC = metallic;
	float f = 1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	EMISSION = rim_color * pow(f, 3.0) * rim_strength;
}
