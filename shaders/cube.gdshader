shader_type spatial;

uniform sampler2D cube_texture : hint_albedo;
uniform vec4 colour : hint_color = vec4(1);

void fragment() {
	ALBEDO = texture(cube_texture, UV).r * colour.rgb;
	EMISSION = ALBEDO * 2.0;
}