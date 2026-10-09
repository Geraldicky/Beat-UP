shader_type canvas_item;
uniform vec4 grade_color : source_color = vec4(0.2, 0.85, 1.0, 1.0);
varying vec4 vertex_tint;
void vertex() {
	vertex_tint = COLOR;
}
void fragment() {
	vec4 glyph = texture(TEXTURE, UV);
	float face = min(glyph.r, min(glyph.g, glyph.b));
	vec3 tint = mix(grade_color.rgb, vec3(1.0), face * face * 0.88);
	COLOR = vec4(tint, glyph.a) * vertex_tint;
}
