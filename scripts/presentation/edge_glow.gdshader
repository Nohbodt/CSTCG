shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never, shadows_disabled;

uniform vec4 tint : source_color = vec4(0.33, 0.68, 1.0, 1.0);
uniform float energy = 0.0;
uniform float progress = 1.0;

void fragment() {
	float revealed = 1.0 - smoothstep(progress - 0.012, progress + 0.012, UV.x);
	float core = exp(-pow((UV.y - 0.5) * 28.0, 2.0));
	float halo = exp(-pow((UV.y - 0.5) * 6.0, 2.0)) * 0.32;
	float ends = smoothstep(0.0, 0.025, UV.x) * (1.0 - smoothstep(0.975, 1.0, UV.x));
	ALBEDO = mix(tint.rgb, vec3(1.0), clamp(energy * 0.18, 0.0, 0.8));
	ALPHA = clamp((core + halo) * energy * revealed * ends, 0.0, 0.98);
}
