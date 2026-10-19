shader_type spatial;
render_mode unshaded, cull_front;
uniform vec4 line_color : source_color = vec4(0.05, 0.06, 0.09, 1.0);
uniform float thick = 0.014;
void vertex() { VERTEX += NORMAL * thick; }
void fragment() { ALBEDO = line_color.rgb; }
