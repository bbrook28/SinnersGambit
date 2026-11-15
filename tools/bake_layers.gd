## Bakes a Sin's living-portrait layers (Phase 8 living glass, stage 2) from SpriteCook edits of its
## portrait (sins/portrait_raw/<sin>_layer_{bg,body,arm,dice}_raw.png, 1024 square, the arm and dice
## not quite where the portrait has them). Output, in the portrait's 4:5 window (same crop as
## tools/bake_art.gd): bg.png and body.png at full window size, arm.png on the full 1024 canvas, one
## PNG per loose die, and layout.json with where the arm and dice go. Also still.png: the layers
## composited at rest, to compare with the portrait.
## godot --headless --path . --script res://tools/bake_layers.gd
extends SceneTree

const SRC := "res://assets/art/sins/portrait_raw/"
const OUT := "res://assets/art/runtime/sins/"
## Per Sin: the window's crop centre (as bake_art PORTRAIT_CX), the arm's scale and offset that put it
## over the portrait's arm, and the loose dice: centre and width in the portrait (1024 space).
const SINS := {
	"gluttony": {
		"cx": 0.468,
		"arm": {"scale": 0.89, "offset": [-123, 4], "pivot": [60, 1024]},
		"dice": [[530, 440, 86], [588, 505, 86], [548, 582, 86]],
	},
}


func _initialize() -> void:
	for s in SINS:
		if FileAccess.file_exists(ProjectSettings.globalize_path(SRC + "%s_layer_bg_raw.png" % s)):
			_bake(s, SINS[s])
	print("layers baked")
	quit()


func _bake(s: String, cfg: Dictionary) -> void:
	var dir := OUT + "%s_layers/" % s
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var x0 := clampi(roundi(1024 * cfg.cx - 409.6), 0, 1024 - 819)
	var win := Rect2i(x0, 0, 819, 1024)
	var bg := _load("bg")
	var body := _cut(_load("body"))
	var arm := _cut(_load("arm"))
	var dice := _cut(_load("dice"))
	bg.get_region(win).save_png(ProjectSettings.globalize_path(dir + "bg.png"))
	body.get_region(win).save_png(ProjectSettings.globalize_path(dir + "body.png"))
	arm.save_png(ProjectSettings.globalize_path(dir + "arm.png"))
	# The loose dice: connected pieces, largest three, matched to the portrait's dice top to bottom.
	var parts := _pieces(dice)
	parts.sort_custom(func(a, b): return a.size.x * a.size.y > b.size.x * b.size.y)
	parts = parts.slice(0, cfg.dice.size())
	parts.sort_custom(func(a, b): return a.position.y < b.position.y)
	var layout := {"window_x": x0, "arm": cfg.arm, "dice": []}
	for i in parts.size():
		var r: Rect2i = parts[i]
		dice.get_region(r).save_png(ProjectSettings.globalize_path(dir + "die_%d.png" % i))
		var want: Array = cfg.dice[i]
		layout.dice.append({"file": "die_%d.png" % i, "centre": [want[0] - x0, want[1]], "scale": float(want[2]) / r.size.x})
	var f := FileAccess.open(ProjectSettings.globalize_path(dir + "layout.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(layout, "\t"))
	f.close()
	# Still composite at rest, in window space.
	var still := bg.get_region(win)
	still.blend_rect(body.get_region(win), Rect2i(Vector2i.ZERO, win.size), Vector2i.ZERO)
	var a2 := arm.duplicate()
	a2.resize(roundi(1024 * cfg.arm.scale), roundi(1024 * cfg.arm.scale), Image.INTERPOLATE_LANCZOS)
	still.blend_rect(a2, Rect2i(Vector2i.ZERO, a2.get_size()), Vector2i(cfg.arm.offset[0] - x0, cfg.arm.offset[1]))
	for d in layout.dice:
		var im := Image.load_from_file(ProjectSettings.globalize_path(dir + d.file))
		im.resize(maxi(1, roundi(im.get_width() * d.scale)), maxi(1, roundi(im.get_height() * d.scale)), Image.INTERPOLATE_LANCZOS)
		still.blend_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i(d.centre[0] - im.get_width() / 2, d.centre[1] - im.get_height() / 2))
	still.save_png(ProjectSettings.globalize_path(dir + "still.png"))


func _load(layer: String) -> Image:
	var im := Image.load_from_file(ProjectSettings.globalize_path(SRC + "gluttony_layer_%s_raw.png" % layer))
	im.convert(Image.FORMAT_RGBA8)
	return im


## Hard alpha cut at 0.6: drops the soft glow halo SpriteCook leaves round a cut-out.
func _cut(im: Image) -> Image:
	for y in im.get_height():
		for x in im.get_width():
			var c := im.get_pixel(x, y)
			c.a = 1.0 if c.a > 0.6 else 0.0
			im.set_pixel(x, y, c)
	return im


## Bounding rects of the opaque connected pieces (4-neighbour flood fill).
func _pieces(im: Image) -> Array:
	var w := im.get_width()
	var h := im.get_height()
	var seen := PackedByteArray()
	seen.resize(w * h)
	var out := []
	for y0 in h:
		for x0 in w:
			var i0 := y0 * w + x0
			if seen[i0] == 1 or im.get_pixel(x0, y0).a < 0.5:
				continue
			var r := Rect2i(x0, y0, 1, 1)
			var stack: Array[int] = [i0]
			seen[i0] = 1
			var n := 0
			while not stack.is_empty():
				var i: int = stack.pop_back()
				var x := i % w
				var y := i / w
				n += 1
				r = r.expand(Vector2i(x, y))
				for j in [i - 1 if x > 0 else -1, i + 1 if x < w - 1 else -1, i - w, i + w]:
					if j >= 0 and j < w * h and seen[j] == 0 and im.get_pixel(j % w, j / w).a >= 0.5:
						seen[j] = 1
						stack.append(j)
			if n > 400:
				out.append(Rect2i(r.position, r.size + Vector2i.ONE))
	return out
