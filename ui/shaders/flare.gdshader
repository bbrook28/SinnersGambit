// Sin window light: living glass (TableDesign / Phase 8 brief). Glass is backlit: bright, saturated
// panes glow, dark leading stays dark.
// glow: that Sin's turn. dim: inactive. cast: per-window colour cast (Greed's cold silver).
// phase: per-window offset so nothing moves in step. flash: speaks, offers or acts, 0..1.
// light / pulse / pulse_speed / glint: intensities from ui/tuning.gd (GLASS_*).
// motion: 1, or 0 under Reduce Motion (the glass holds still).
shader_type canvas_item;

uniform float glow = 0.0;
uniform float dim = 0.0;
uniform vec4 cast : source_color = vec4(1.0);
uniform float phase = 0.0;
uniform float flash = 0.0;
uniform float light = 0.2;
uniform float pulse = 0.1;
uniform float pulse_speed = 0.5;
uniform float glint = 0.6;
uniform float motion = 1.0;
uniform float bloom = 1.0;  // light-through-glass boost: 1 on the board lancets, less on brighter art

float lum_at(sampler2D tex, vec2 uv) {
	return dot(texture(tex, uv).rgb, vec3(0.299, 0.587, 0.114));
}

void fragment() {
	float t = TIME * motion;
	vec4 c = texture(TEXTURE, UV) * COLOR;
	c.rgb *= cast.rgb;
	float lum = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	// Slow colour pulse: the panes' saturation swells and ebbs, a little warmer at the crest.
	float p = sin(t * pulse_speed + phase * 6.283);
	c.rgb = mix(vec3(lum), c.rgb, 1.25 + pulse * p);
	c.rgb *= vec3(1.0 + pulse * 0.25 * p, 1.0, 1.0 - pulse * 0.2 * p);
	c.rgb = c.rgb * (1.0 + 0.2 * bloom) + c.rgb * c.rgb * 0.9 * bloom;  // light through glass: brights bloom, leading doesn't
	// Light moving behind the glass: a soft band crosses the pane every ~9 s over an uneven breathing.
	float sweep = fract(t * 0.11 + phase) * 1.9 - 0.45;
	float d = UV.x * 0.55 + UV.y * 0.45 - sweep;
	float band = exp(-d * d / 0.018);
	float wob = 0.035 * sin(t * 1.3 + phase * 6.283) + 0.025 * sin(t * 2.7 + phase * 11.0);
	c.rgb *= 1.0 + band * light + wob * (light / 0.2);
	// Glints along the lead lines: dark pixels beside bright glass catch thin travelling highlights.
	vec2 px = TEXTURE_PIXEL_SIZE * 1.5;
	float edge = abs(lum_at(TEXTURE, UV + vec2(px.x, 0.0)) - lum_at(TEXTURE, UV - vec2(px.x, 0.0)))
			+ abs(lum_at(TEXTURE, UV + vec2(0.0, px.y)) - lum_at(TEXTURE, UV - vec2(0.0, px.y)));
	float lead = (1.0 - smoothstep(0.08, 0.25, lum)) * smoothstep(0.12, 0.4, edge);
	float run = pow(max(0.0, sin((UV.y * 2.2 + UV.x * 0.9 - t * 0.23 + phase) * 6.283)), 36.0);
	c.rgb += vec3(1.0, 0.92, 0.75) * lead * run * glint * c.a;
	float flick = 1.0 + glow * 0.06 * sin(TIME * 7.0 * motion);
	c.rgb *= (1.0 + glow * 0.35) * flick;
	c.rgb = mix(c.rgb, c.rgb * 0.45, dim * (1.0 - flash));
	// Flare: the glass goes white-hot, panes first, leading barely.
	float pane = smoothstep(0.04, 0.3, lum);
	c.rgb = c.rgb * (1.0 + flash * 1.2) + vec3(1.0, 0.94, 0.82) * flash * 0.55 * pane;
	COLOR = c;
}
