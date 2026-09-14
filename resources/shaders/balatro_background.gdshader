shader_type canvas_item;

uniform vec4 color_red : source_color = vec4(0.88, 0.16, 0.20, 1.0);
uniform vec4 color_blue : source_color = vec4(0.06, 0.46, 0.90, 1.0);
uniform vec4 color_dark : source_color = vec4(0.02, 0.03, 0.06, 1.0);
uniform float swirl_speed : hint_range(0.1, 5.0) = 0.75;
uniform float swirl_scale : hint_range(1.0, 20.0) = 4.2;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.18;
uniform float vignette_strength : hint_range(0.0, 2.0) = 0.95;

void fragment() {
	vec2 uv = UV;
	vec2 p = (uv - vec2(0.5)) * 2.0;
	
	// CRT lens curvature distortion
	float dist = length(p);
	p *= (1.0 + 0.09 * dist * dist);
	dist = length(p);
	float angle = atan(p.y, p.x);
	
	// Authentic Balatro Dual-Vortex Fluid Swirl
	float time = TIME * swirl_speed;
	float spiral = angle * 2.0 + dist * swirl_scale - time;
	
	// Multi-frequency wave interference
	float w1 = sin(p.x * 2.5 + spiral) + cos(p.y * 2.5 - spiral);
	float w2 = sin(p.x * 4.5 - time * 0.7 + w1) * cos(p.y * 4.5 + time * 0.5 - w1);
	float w3 = sin(dist * 6.5 - time * 1.1 + w2 * 1.4);
	float fluid = (w1 * 0.5 + w2 * 0.3 + w3 * 0.2);
	
	// Sharp fluid interface between Red flame and Electric Blue
	float mix_val = smoothstep(-0.25, 0.25, fluid);
	
	vec4 red_shade = mix(color_red * 0.6, color_red, sin(spiral * 1.5) * 0.5 + 0.5);
	vec4 blue_shade = mix(color_blue * 0.5, color_blue, cos(spiral * 1.5) * 0.5 + 0.5);
	vec4 base_color = mix(red_shade, blue_shade, mix_val);
	
	// Dark vortex swirl crevices
	float crevices = smoothstep(0.7, 0.98, abs(sin(spiral * 2.8 + w2)));
	base_color = mix(base_color, color_dark, crevices * 0.55);
	
	// CRT Scanlines
	float scanline = sin(uv.y * 480.0 * 3.14159) * 0.5 + 0.5;
	base_color.rgb -= scanline * scanline_strength;
	
	// Vignette edge shading
	float vignette = smoothstep(1.35, 0.35, dist);
	base_color.rgb *= mix(1.0, vignette, vignette_strength);
	base_color.a = 1.0;
	
	COLOR = base_color;
}

