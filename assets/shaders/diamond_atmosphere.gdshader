shader_type canvas_item;
render_mode unshaded;

uniform float phase = 0.0;
uniform float aspect = 1.777778;
uniform float strength = 1.0;

float diamond(vec2 p, vec2 center, float radius, float width) {
	float edge = abs(abs(p.x - center.x) + abs(p.y - center.y) - radius);
	return 1.0 - smoothstep(width, width + 0.002, edge);
}

void fragment() {
	vec2 uv = UV;
	vec2 p = vec2(uv.x * aspect, uv.y);
	float t = phase * 0.035;
	vec2 drift = vec2(sin(t), cos(t * 0.73)) * 0.018;
	vec3 base = vec3(0.023, 0.029, 0.041);
	float blue = exp(-length((uv - vec2(0.82, 0.23) - drift) * vec2(2.4, 2.0)) * 3.0);
	float amber = exp(-length((uv - vec2(0.12, 0.85) + drift) * vec2(2.6, 2.0)) * 3.5);
	vec3 col = base + strength * (blue * vec3(0.025, 0.09, 0.13) + amber * vec3(0.065, 0.031, 0.012));
	// Sparse edge geometry, not a tiled grid. The horizontal play lane is quiet.
	float lane_mask = smoothstep(0.10, 0.27, abs(uv.y - 0.48));
	float edges = diamond(p, vec2(aspect * 0.94, 0.12) + drift, 0.34, 0.0007);
	edges += diamond(p, vec2(aspect * 0.94, 0.12) + drift, 0.42, 0.0005) * 0.35;
	edges += diamond(p, vec2(aspect * 0.04, 0.95) - drift, 0.26, 0.0007) * 0.6;
	col += edges * lane_mask * strength * vec3(0.025, 0.05, 0.064);
	float vignette = smoothstep(0.2, 0.83, length((uv - 0.5) * vec2(1.0, 0.8)));
	col *= 1.0 - vignette * 0.35;
	// Stationary fine grain; no temporal noise or beat flashes.
	float grain = fract(sin(dot(floor(uv * vec2(1920.0, 1080.0)), vec2(12.9898, 78.233))) * 43758.5453);
	col += (grain - 0.5) * 0.003;
	COLOR = vec4(col, 1.0) * COLOR;
}
