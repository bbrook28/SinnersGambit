## Figure-ground test (Ben, Nov 15): one Sin's baked layers composited three ways, each with a
## greyscale copy underneath. A: as baked. B: the bg layer darkened and desaturated, plus a dark
## lead line round the figure's silhouette. C: a regenerated bg layer (raw path given), plus the line.
## godot --headless --path . --script res://tools/bg_test.gd -- <sin> <out.png> [regenerated bg raw]
extends SceneTree

const BakeArt = preload("res://tools/bake_art.gd")
const DARKEN := 0.4      # B: value x (1 - DARKEN)
const DESAT := 0.3       # B: saturation x (1 - DESAT)
const LINE := 10         # px at window size (819 wide): full-strength lead line round the figure
const LINE_SOFT := 3     # px of soft outer edge beyond it
const LEAD := Color("140d0b")


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var s: String = a[0]
	var dir := "res://assets/art/runtime/sins/%s_layers/" % s
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(dir + "parts.json"))
	var bg := _load(dir + "bg.png")
	var body := _load(dir + "body.png")
	var figure: Image = body.duplicate()  # body + parts at rest
	var parts := []
	for p in layout.parts:
		var im := _load(dir + p.file)
		parts.append([im, Vector2i(p.rect[0], p.rect[1])])
		figure.blend_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i(p.rect[0], p.rect[1]))
	var line := _outline(figure)

	var graded: Image = bg.duplicate()
	for y in graded.get_height():
		for x in graded.get_width():
			var c := graded.get_pixel(x, y)
			graded.set_pixel(x, y, Color.from_hsv(c.h, c.s * (1.0 - DESAT), c.v * (1.0 - DARKEN)))
	var cols: Array[Image] = [_compose(bg, null, body, parts), _compose(graded, line, body, parts)]
	if a.size() > 2:
		var raw := Image.load_from_file(ProjectSettings.globalize_path(a[2]))
		raw.convert(Image.FORMAT_RGBA8)
		var x0: int = layout.window_x
		cols.append(_compose(raw.get_region(Rect2i(x0, 0, 819, 1024)), line, body, parts))

	var w := 410
	var h := 512
	var sheet := Image.create(cols.size() * (w + 8) - 8, h * 2 + 8, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.1, 0.1, 0.1))
	for i in cols.size():
		var im: Image = cols[i].duplicate()
		im.resize(w, h, Image.INTERPOLATE_LANCZOS)
		sheet.blit_rect(im, Rect2i(0, 0, w, h), Vector2i(i * (w + 8), 0))
		for y in h:
			for x in w:
				var c := im.get_pixel(x, y)
				var l := 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
				im.set_pixel(x, y, Color(l, l, l))
		sheet.blit_rect(im, Rect2i(0, 0, w, h), Vector2i(i * (w + 8), h + 8))
	sheet.save_png(ProjectSettings.globalize_path(a[1]))
	print("bg test: %d versions" % cols.size())
	quit()


func _compose(bg: Image, line: Image, body: Image, parts: Array) -> Image:
	var out: Image = bg.duplicate()
	if line:
		out.blend_rect(line, Rect2i(Vector2i.ZERO, line.get_size()), Vector2i.ZERO)
	out.blend_rect(body, Rect2i(Vector2i.ZERO, body.get_size()), Vector2i.ZERO)
	for p in parts:
		out.blend_rect(p[0], Rect2i(Vector2i.ZERO, p[0].get_size()), p[1])
	return out


## A dark band LINE px wide round the figure's alpha, fading over LINE_SOFT more.
func _outline(fig: Image) -> Image:
	var w := fig.get_width()
	var h := fig.get_height()
	var m := PackedFloat32Array()
	m.resize(w * h)
	for y in h:
		for x in w:
			m[y * w + x] = 1.0 if fig.get_pixel(x, y).a > 0.5 else 0.0
	var r := LINE + LINE_SOFT
	var d := _dilate(m, w, h, r)  # distance-free: grows the mask r px (square), then
	var inner := _dilate(m, w, h, LINE)
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for i in w * h:
		var a := maxf(inner[i], d[i] * 0.45)
		if a > 0.0:
			out.set_pixel(i % w, i / w, Color(LEAD, a))
	return out


## Separable max filter (square dilation).
func _dilate(m: PackedFloat32Array, w: int, h: int, r: int) -> PackedFloat32Array:
	var t := PackedFloat32Array()
	t.resize(w * h)
	for y in h:
		var row := y * w
		for x in w:
			var v := 0.0
			for k in range(maxi(0, x - r), mini(w, x + r + 1)):
				if m[row + k] > v:
					v = m[row + k]
					break
			t[row + x] = v
	var o := PackedFloat32Array()
	o.resize(w * h)
	for x in w:
		for y in h:
			var v := 0.0
			for k in range(maxi(0, y - r), mini(h, y + r + 1)):
				if t[k * w + x] > v:
					v = t[k * w + x]
					break
			o[y * w + x] = v
	return o


func _load(path: String) -> Image:
	var im := Image.load_from_file(ProjectSettings.globalize_path(path))
	im.convert(Image.FORMAT_RGBA8)
	return im
