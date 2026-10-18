shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 tint : source_color = vec3(0.84, 0.83, 0.79);
uniform float uv_scale = 4.0;
uniform float desat = 0.55;
uniform float rough = 0.93;

void fragment() {
	vec3 c = texture(tex, UV * uv_scale).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(c, vec3(l), desat) * tint;
	ALBEDO = c;
	ROUGHNESS = rough;
	SPECULAR = 0.18;
}
