shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never, shadows_disabled;

uniform vec4 tint : source_color = vec4(0.33, 0.68, 1.0, 1.0);
uniform float energy = 0.0;
uniform float core = 1.0;
uniform float ring = 0.0;
uniform float radius = 0.65;

void fragment() {
	float distance = length((UV - vec2(0.5)) * 2.0);
	float halo = pow(max(0.0, 1.0 - distance), 2.8) * core;
	float wave = exp(-pow((distance - radius) * 34.0, 2.0)) * ring;
	float edge = 1.0 - smoothstep(0.85, 1.0, distance);
	float mask = (halo + wave) * edge;
	ALBEDO = tint.rgb * (0.7 + energy * 1.2);
	ALPHA = clamp(mask * energy, 0.0, 0.85);
}
