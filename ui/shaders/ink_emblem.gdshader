// A Sin's Accept-seal emblem (runtime/seals/e_accept_<sin>.png) redrawn as ink line for the table
// blockout's track markers: only the emblem inside the gold ring (a circle of `radius` round the
// middle) is kept, and its relief becomes ink where the shading changes sharply (Sobel edges).
// Placeholder for the hand-drawn woodcut sigils.
shader_type canvas_item;

uniform vec4 ink : source_color = vec4(0.165, 0.094, 0.063, 1.0);
uniform float radius = 0.27;     // of the texture, round its centre: inside the gold ring
uniform float step_px = 3.0;     // edge sample distance, texture px
uniform float gain = 4.0;

float lum(sampler2D tex, vec2 uv) {
	vec4 c = texture(tex, uv);
	return dot(c.rgb, vec3(0.299, 0.587, 0.114)) * c.a;
}

void fragment() {
	vec2 uv = vec2(0.5) + (UV - vec2(0.5)) * radius * 2.0;
	vec2 d = TEXTURE_PIXEL_SIZE * step_px;
	float tl = lum(TEXTURE, uv + vec2(-d.x, -d.y)), t = lum(TEXTURE, uv + vec2(0.0, -d.y)), tr = lum(TEXTURE, uv + vec2(d.x, -d.y));
	float l = lum(TEXTURE, uv + vec2(-d.x, 0.0)), r = lum(TEXTURE, uv + vec2(d.x, 0.0));
	float bl = lum(TEXTURE, uv + vec2(-d.x, d.y)), b = lum(TEXTURE, uv + vec2(0.0, d.y)), br = lum(TEXTURE, uv + vec2(d.x, d.y));
	float gx = (tr + 2.0 * r + br) - (tl + 2.0 * l + bl);
	float gy = (bl + 2.0 * b + br) - (tl + 2.0 * t + tr);
	float e = clamp(length(vec2(gx, gy)) * gain, 0.0, 1.0);
	float inside = 1.0 - smoothstep(0.46, 0.5, length(UV - vec2(0.5)));
	COLOR = vec4(ink.rgb, ink.a * smoothstep(0.25, 0.6, e) * inside);
}
