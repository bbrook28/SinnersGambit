// Stained glass: Voronoi panes in one jewel tone, thick black leading, backlit and flickering.
// Pixelated to a grid so it reads as pixel art. Set rect_size from script.
shader_type canvas_item;

uniform vec4 tint : source_color = vec4(0.75, 0.1, 0.15, 1.0);
uniform vec2 rect_size = vec2(300.0, 200.0);
uniform float pixel = 5.0;          // pixel-art cell in screen px
uniform float pane = 70.0;          // average pane size in px
uniform float lead = 7.0;           // leading width in px
uniform float frame = 15.0;         // outer frame width in px
uniform float glow = 0.0;           // 0..1 flare (ability fired, T2 ready)
uniform float dim = 0.0;            // 0..1 darken (not your focus)
uniform float seed = 0.0;

vec2 hash2(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p + seed) * 43758.5453);
}

void fragment() {
	vec2 px = (floor(UV * rect_size / pixel) + 0.5) * pixel;   // snapped pixel centre
	vec2 g = px / pane;
	vec2 ip = floor(g);
	float d1 = 9.0;
	float d2 = 9.0;
	vec2 id = vec2(0.0);
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 nb = vec2(float(x), float(y));
			vec2 pt = nb + 0.15 + 0.7 * hash2(ip + nb);
			float d = length(pt - (g - ip));
			if (d < d1) {
				d2 = d1;
				d1 = d;
				id = ip + nb;
			} else if (d < d2) {
				d2 = d;
			}
		}
	}
	float edge = (d2 - d1) * pane;              // distance to leading, in px
	vec2 fe = min(px, rect_size - px);
	float to_frame = min(fe.x, fe.y);

	float h = hash2(id).x;
	float flick = 0.94 + 0.06 * sin(TIME * (2.0 + 3.0 * h) + h * 40.0);
	float bright = mix(0.55, 1.15, h);
	vec3 col = tint.rgb * bright;
	col = mix(col, vec3(1.0, 0.92, 0.7), 0.12 * hash2(id + 7.0).y);   // a few paler panes
	// backlit: brighter toward the centre of the window and of each pane
	vec2 cc = UV - 0.5;
	float centre = 1.0 - dot(cc, cc) * 1.6;
	col *= (0.75 + 0.45 * centre) * (1.1 - 0.35 * d1) * flick;
	col *= 1.0 + glow * 0.8;
	col = mix(col, col * 0.35, dim);

	vec3 lead_col = vec3(0.06, 0.035, 0.03);
	if (edge < lead || to_frame < frame) {
		col = lead_col;
		if (to_frame < frame && to_frame > frame - pixel) {
			col = mix(lead_col, vec3(0.55, 0.42, 0.2), 0.5 + 0.5 * glow);   // gilt inner rim on the frame
		}
	}
	col = floor(col * 48.0) / 48.0;
	COLOR = vec4(col, 1.0);
}
