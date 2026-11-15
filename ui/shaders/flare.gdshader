// Sin window light: living glass (TableDesign / Phase 8 brief). At rest the window is its PNG:
// the texture's own colour and alpha, no tint, saturation or contrast change. Everything else is
// brightness in neutral white, strongest on the bright panes and capped so no channel clips (a
// scale, so hue is kept). Checked by tests/glass_check.gd.
// glow: that Sin's turn (brighter). dim: inactive (darker). cast: per-window colour cast, 1 = none.
// phase: per-window offset so nothing moves in step. flash: speaks, offers or acts, 0..1, brief.
// light / pulse / pulse_speed / glint: intensities from ui/tuning.gd (GLASS_*).
// motion: 1, or 0 under Reduce Motion (the glass holds still).
shader_type canvas_item;

uniform float glow = 0.0;
uniform float dim = 0.0;
uniform vec4 cast : source_color = vec4(1.0);
uniform float phase = 0.0;
uniform float flash = 0.0;
uniform float light = 0.1;   // the band of light: at most this much brighter
uniform float pulse = 0.03;  // the slow swell: this much brighter and back
uniform float pulse_speed = 0.5;
uniform float glint = 0.6;
uniform float motion = 1.0;
uniform float bloom = 0.0;   // unused, kept so older callers still set it harmlessly

const vec3 LW = vec3(0.299, 0.587, 0.114);

void fragment() {
	float t = TIME * motion;
	vec4 c = COLOR;  // in Godot 4 this is already texture × modulate: sampling TEXTURE again would square it
	c.rgb *= cast.rgb;
	float lum = dot(c.rgb, LW);
	float bright = smoothstep(0.1, 0.6, lum);  // light shows most on the bright panes, little on the leading
	// Light behind the glass: a soft band crosses every ~9 s, over a slow swell.
	float sweep = fract(t * 0.11 + phase) * 1.9 - 0.45;
	float d = UV.x * 0.55 + UV.y * 0.45 - sweep;
	float band = exp(-d * d / 0.018) * motion;
	float swell = 0.5 + 0.5 * sin(t * pulse_speed + phase * 6.283);
	float gain = (band * light + swell * pulse * motion) * bright + glow * 0.25 + flash * 0.6;
	float top = max(max(c.r, c.g), max(c.b, 0.001));
	c.rgb *= min(1.0 + gain, max(1.0, 1.0 / top));  // brighter, never past white in any channel
	// Glints: small pale-gold highlights travelling along the lead lines.
	vec2 px = TEXTURE_PIXEL_SIZE * 1.5;
	float edge = abs(dot(texture(TEXTURE, UV + vec2(px.x, 0.0)).rgb, LW) - dot(texture(TEXTURE, UV - vec2(px.x, 0.0)).rgb, LW))
			+ abs(dot(texture(TEXTURE, UV + vec2(0.0, px.y)).rgb, LW) - dot(texture(TEXTURE, UV - vec2(0.0, px.y)).rgb, LW));
	float lead = (1.0 - smoothstep(0.08, 0.25, lum)) * smoothstep(0.12, 0.4, edge);
	float run = pow(max(0.0, sin((UV.y * 2.2 + UV.x * 0.9 - t * 0.23 + phase) * 6.283)), 36.0) * motion;
	c.rgb = min(c.rgb + vec3(1.0, 0.94, 0.8) * lead * run * glint * 0.5, vec3(1.0));
	// Flare: a brief white brightening on the panes (flash returns to 0 within half a second).
	c.rgb = mix(c.rgb, vec3(1.0), flash * 0.35 * bright);
	c.rgb *= 1.0 - 0.55 * dim * (1.0 - flash);
	COLOR = c;  // alpha is the texture's own
}
