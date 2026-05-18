// Subtle pixel-color-range flicker. Picks out pixels in a target color and
// animates their brightness rhythmically with per-pixel phase noise so the
// effect feels organic rather than uniform.
//
// Used for Fire flame flicker, Poison cauldron bubble, and similar
// sprite-integrated ambient animations.
//
// Debug: set debug_show_match to 1 to paint matched pixels bright cyan
// and unmatched pixels dark grey. Useful for diagnosing why the effect
// isn't visible — confirms which pixels the shader is targeting.
shader_type canvas_item;

uniform vec4 target_color : source_color = vec4(1.0, 0.5, 0.2, 1.0);
uniform float color_tolerance : hint_range(0.0, 1.0) = 0.4;
uniform float flicker_intensity : hint_range(0.0, 1.0) = 0.2;
uniform float flicker_speed : hint_range(0.1, 20.0) = 6.0;
uniform float phase_offset : hint_range(0.0, 100.0) = 0.0;
uniform float per_pixel_phase : hint_range(0.0, 1.0) = 0.5;
uniform float debug_show_match : hint_range(0.0, 1.0) = 0.0;


void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	// How close is this pixel to the target color?
	float color_distance = length(tex.rgb - target_color.rgb);
	float match_factor = 1.0 - smoothstep(0.0, color_tolerance, color_distance);

	if (debug_show_match > 0.5) {
		// Cyan = matched, dark grey = unmatched. Keeps the sprite's alpha.
		vec3 debug_color = mix(vec3(0.15), vec3(0.0, 1.0, 1.0), match_factor);
		COLOR = vec4(debug_color, tex.a);
	} else {
		// Per-pixel phase noise so matched pixels do not pulse in sync.
		float pixel_noise = fract(sin(UV.x * 12.9898 + UV.y * 78.233) * 43758.5453);
		float t = TIME * flicker_speed + phase_offset + pixel_noise * per_pixel_phase * 6.2831853;

		// Layered sines give an organic-feeling wave rather than a clean pulse.
		float wave = sin(t) * 0.5 + sin(t * 1.7 + 1.3) * 0.3 + sin(t * 2.9 + 2.7) * 0.2;

		// Modulate brightness on matched pixels only.
		vec3 modulated = tex.rgb * (1.0 + flicker_intensity * wave);
		tex.rgb = mix(tex.rgb, modulated, match_factor);

		COLOR = tex;
	}
}
