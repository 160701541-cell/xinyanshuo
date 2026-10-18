shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float shadow_cool : hint_range(0.0, 1.0) = 0.42;
uniform float light_warm : hint_range(0.0, 1.0) = 0.16;
uniform float sat : hint_range(0.5, 1.5) = 1.04;
uniform float contrast : hint_range(0.5, 1.5) = 1.07;

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	vec3 cool = vec3(0.88, 0.96, 1.12);
	vec3 warm = vec3(1.07, 1.01, 0.93);
	float k = smoothstep(0.10, 0.80, l);
	vec3 tint = mix(cool, warm, k);
	c *= mix(vec3(1.0), tint, mix(shadow_cool, light_warm, k));
	c = (c - 0.5) * contrast + 0.5;
	float g = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(g), c, sat);
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
