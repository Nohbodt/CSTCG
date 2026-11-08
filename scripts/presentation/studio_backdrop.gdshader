shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform vec4 tint : source_color = vec4(0.33, 0.68, 1.0, 1.0);

void fragment() {
	vec2 p = UV - vec2(0.5, 0.45);
	float vignette = exp(-dot(p * vec2(1.3, 1.8), p * vec2(1.3, 1.8)) * 4.0);
	float floor_y = clamp((UV.y - 0.58) / 0.42, 0.0, 1.0);
	float mask = smoothstep(0.01, 0.12, floor_y);
	float rays = abs(fract((UV.x - 0.5) / max(0.13, floor_y) * 5.0 + 0.5) - 0.5);
	float rows = abs(fract(floor_y * floor_y * 7.0) - 0.5);
	float grid = (1.0 - smoothstep(0.01, 0.03, rays)) + (1.0 - smoothstep(0.015, 0.035, rows));
	ALBEDO = vec3(0.037, 0.025, 0.071) + tint.rgb * vignette * 0.018 + tint.rgb * grid * mask * 0.055;
}
