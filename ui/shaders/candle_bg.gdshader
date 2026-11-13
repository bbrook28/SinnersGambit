// Candlelit black: warm glow from one candle, vignette, faint flicker, pixel grain. Never pure black.
shader_type canvas_item;

uniform vec4 base_color : source_color = vec4(0.075, 0.05, 0.045, 1.0);
uniform vec4 glow_color : source_color = vec4(0.34, 0.16, 0.07, 1.0);
uniform vec2 light_pos = vec2(0.5, 0.45);
uniform float pixel = 6.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 cell = floor(FRAGCOORD.xy / pixel);
	float flick = 0.9 + 0.06 * sin(TIME * 7.3) + 0.04 * sin(TIME * 13.7 + 1.3) + 0.02 * sin(TIME * 23.1);
	vec2 c = UV - light_pos;
	c.x *= 0.7;
	float d = length(c);
	float glow = smoothstep(0.7, 0.0, d) * flick;
	vec3 col = mix(base_color.rgb, glow_color.rgb, glow * 0.6);
	float vig = smoothstep(0.95, 0.2, d);
	col = mix(base_color.rgb * 0.45, col, vig);
	col += (hash(cell) - 0.5) * 0.018;
	col = floor(col * 64.0) / 64.0;
	COLOR = vec4(col, 1.0);
}
