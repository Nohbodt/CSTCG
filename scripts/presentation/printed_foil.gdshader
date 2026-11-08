shader_type spatial;
render_mode unshaded, cull_back, blend_mix, depth_draw_opaque;

uniform sampler2D print_texture : source_color, filter_linear_mipmap;
uniform vec4 tint : source_color = vec4(0.65, 0.42, 1.0, 1.0);
uniform float phase = 0.0;
uniform float strength = 0.2;
uniform float portrait_protection = 0.0;
uniform float energy = 0.0;

void fragment() {
	vec4 ink = texture(print_texture, UV);
	float lightness = max(max(ink.r, ink.g), ink.b);
	// Protect the live printed names/numbers. Foil catches in the dark art only.
	float foil_mask = 1.0 - smoothstep(0.16, 0.42, lightness);
	float portrait = step(0.240, UV.x) * step(UV.x, 0.940) * step(0.097, UV.y) * step(UV.y, 0.668);
	foil_mask *= 1.0 - portrait * portrait_protection;
	// The slanted nameplate may use dark lettering on bright metal.
	// Shield its live type and the complete stats/footer region as well.
	foil_mask *= 1.0 - step(0.597, UV.y) * portrait_protection;
	float band = pow(max(0.0, sin(UV.x * 6.0 + UV.y * 4.0 + phase)), 18.0);
	float fine = 0.5 + 0.5 * sin(UV.x * 180.0 + UV.y * 60.0);
	vec3 spectrum = mix(vec3(0.20, 0.55, 1.0), tint.rgb, UV.y);
	float sharp = pow(max(0.0, sin(UV.x * 6.0 + UV.y * 4.0 + phase)), 72.0);
	float edge = 1.0 - smoothstep(0.0, 0.055, min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y)));
	vec3 glare = spectrum * band * (1.0 + energy * 1.2) + vec3(1.0) * sharp * energy * 0.65;
	ALBEDO = ink.rgb + glare * foil_mask * strength + tint.rgb * fine * foil_mask * 0.02 + spectrum * edge * energy * foil_mask * 0.14;
	ALPHA = ink.a;
}
