shader_type spatial;
render_mode unshaded, blend_add, cull_disabled;

uniform vec4 colour : hint_color = vec4(1, 1, 1, 1);

varying vec3 vpos;

void vertex() {
	vpos = VERTEX.xyz;
}

void fragment() {
	ALBEDO = colour.rgb;
	EMISSION = colour.rgb * 1.75;
	ALPHA = sin(TIME * 2.0 - (vpos.y * 0.5)) * 0.75 + 0.3;
}