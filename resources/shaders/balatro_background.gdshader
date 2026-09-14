shader_type canvas_item;

uniform vec4 color_primary : source_color = vec4(0.08, 0.04, 0.15, 1.0);
uniform vec4 color_secondary : source_color = vec4(0.18, 0.05, 0.08, 1.0);
uniform vec4 color_tertiary : source_color = vec4(0.03, 0.08, 0.14, 1.0);
uniform float swirl_speed : hint_range(0.1, 5.0) = 0.65;
uniform float swirl_scale : hint_range(1.0, 20.0) = 6.0;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.15;
uniform float vignette_strength : hint_range(0.0, 2.0) = 0.7;

void fragment() {
	vec2 uv = UV;
	vec2 centered_uv = uv - vec2(0.5);
	
	// Distance from center
	float dist = length(centered_uv);
	float angle = atan(centered_uv.y, centered_uv.x);
	
	// Psychedelic Swirl Plasma (Balatro-style)
	float time = TIME * swirl_speed;
	float swirl = sin(angle * 3.0 + dist * swirl_scale - time) + cos(dist * 5.0 - time * 0.8);
	float plasma = sin(centered_uv.x * 4.0 + swirl + time * 0.5) * cos(centered_uv.y * 4.0 - swirl + time * 0.4);
	
	float mix_val = clamp((swirl + plasma + 1.5) * 0.35, 0.0, 1.0);
	vec4 base_color = mix(color_primary, color_secondary, mix_val);
	base_color = mix(base_color, color_tertiary, sin(dist * 4.0 - time * 0.3) * 0.3 + 0.3);
	
	// CRT Scanlines
	float scanline = sin(uv.y * 600.0) * 0.5 + 0.5;
	base_color.rgb -= scanline * scanline_strength;
	
	// Vignette edge shading
	float vignette = 1.0 - smoothstep(0.3, 0.75, dist);
	base_color.rgb *= mix(1.0, vignette, vignette_strength);
	
	COLOR = base_color;
}
