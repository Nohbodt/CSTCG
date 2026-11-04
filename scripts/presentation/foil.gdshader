shader_type spatial;
render_mode cull_disabled;

uniform vec4 tint : source_color = vec4(0.65, 0.42, 1.0, 1.0);
uniform float energy = 0.0;
uniform float phase = 0.0;

void fragment() {
	float fold = sin(UV.x * 48.0 + sin(UV.y * 19.0) * 2.5) * 0.5 + 0.5;
	float sweep = pow(max(0.0, sin(UV.x * 5.0 + UV.y * 3.0 + phase)), 12.0);
	vec3 interference = mix(vec3(0.14, 0.45, 0.9), vec3(0.9, 0.16, 0.42), UV.x);
	ALBEDO = mix(tint.rgb * (0.13 + fold * 0.18), interference, sweep * 0.32);
	METALLIC = 0.72;
	ROUGHNESS = 0.26 + fold * 0.16;
	EMISSION = tint.rgb * (0.04 + energy * 0.35) + interference * sweep * energy * 0.3;
}
