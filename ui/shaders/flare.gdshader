// Sin window light. Glass is backlit: bright, saturated panes glow, dark leading stays dark.
// glow: that Sin's turn. dim: inactive. cast: per-window colour cast (Greed's cold silver).
// phase: per-window offset so the idle shimmer never moves in step. flash: ability trigger, 0..1.
shader_type canvas_item;

uniform float glow = 0.0;
uniform float dim = 0.0;
uniform vec4 cast : source_color = vec4(1.0);
uniform float phase = 0.0;
uniform float flash = 0.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	c.rgb *= cast.rgb;
	float lum = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	c.rgb = mix(vec3(lum), c.rgb, 1.25);           // a little richer
	c.rgb = c.rgb * 1.2 + c.rgb * c.rgb * 0.9;      // light through glass: brights bloom, leading doesn't
	// Idle: a candle drifting behind the glass. A soft band of light crosses the pane every ~9 s,
	// over a slow uneven breathing. Multiplies the glass, so the leading stays dark.
	float sweep = fract(TIME * 0.11 + phase) * 1.9 - 0.45;
	float d = UV.x * 0.55 + UV.y * 0.45 - sweep;
	float band = exp(-d * d / 0.018);
	float wob = 0.035 * sin(TIME * 1.3 + phase * 6.283) + 0.025 * sin(TIME * 2.7 + phase * 11.0);
	c.rgb *= 1.0 + band * 0.2 + wob;
	float flick = 1.0 + glow * 0.06 * sin(TIME * 7.0);
	c.rgb *= (1.0 + glow * 0.35) * flick;
	c.rgb = mix(c.rgb, c.rgb * 0.45, dim * (1.0 - flash));
	// Trigger: the glass goes white-hot, panes first, leading barely.
	float pane = smoothstep(0.04, 0.3, lum);
	c.rgb = c.rgb * (1.0 + flash * 1.2) + vec3(1.0, 0.94, 0.82) * flash * 0.55 * pane;
	COLOR = c;
}
