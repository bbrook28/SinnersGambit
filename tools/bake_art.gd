## Bakes runtime textures from SpriteCook raw sources (assets/art/*/raw, which Godot ignores).
## godot --headless --path . --script res://tools/bake_art.gd
## Raw images carry a soft glow halo in alpha: a hard cut at 0.6 keeps only the object.
extends SceneTree

const SINS := ["pride", "greed", "wrath", "envy", "gluttony", "lust", "sloth"]
const OUT := "res://assets/art/runtime/"


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT + "sins"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT + "sigils"))
	for s in SINS:
		var src: String = "greed_silver" if s == "greed" else s
		var im := _cut(_load("res://assets/art/sins/raw/%s_glass_raw.png" % src))
		_save(_fit_h(im, 760), OUT + "sins/%s.png" % s)
	var sig := _split(_cut(_load("res://assets/art/extra/raw/sigils_raw.png")), 7)
	for i in SINS.size():
		_save(_fit_h(sig[i], 96), OUT + "sigils/%s.png" % SINS[i])
	var st := _split(_cut(_load("res://assets/art/extra/raw/strikes_raw.png")), 2)
	_save(_fit_h(st[0], 160), OUT + "strike_empty.png")
	_save(_fit_h(st[1], 200), OUT + "strike_struck.png")
	var lea := _load("res://assets/art/extra/raw/leather_raw.png")
	lea.resize(512, 512, Image.INTERPOLATE_LANCZOS)
	_save(lea, OUT + "leather.png")
	print("baked")
	quit()


func _load(path: String) -> Image:
	var im := Image.load_from_file(ProjectSettings.globalize_path(path))
	im.convert(Image.FORMAT_RGBA8)
	return im


func _cut(im: Image) -> Image:
	for y in im.get_height():
		for x in im.get_width():
			var c := im.get_pixel(x, y)
			c.a = 1.0 if c.a > 0.6 else 0.0
			im.set_pixel(x, y, c)
	return im.get_region(im.get_used_rect())


func _fit_h(im: Image, h: int) -> Image:
	var w := int(round(float(im.get_width()) * h / im.get_height()))
	im.resize(w, h, Image.INTERPOLATE_LANCZOS)
	return im


## Splits a row of n objects at the n-1 widest empty column gaps.
func _split(im: Image, n: int) -> Array:
	var empty := []
	for x in im.get_width():
		var any := false
		for y in im.get_height():
			if im.get_pixel(x, y).a > 0.0:
				any = true
				break
		empty.append(not any)
	var runs := []  # [start, length] of empty runs
	var x := 0
	while x < empty.size():
		if empty[x]:
			var s := x
			while x < empty.size() and empty[x]:
				x += 1
			runs.append([s, x - s])
		else:
			x += 1
	runs.sort_custom(func(a, b): return a[1] > b[1])
	var cuts := []
	for i in n - 1:
		cuts.append(runs[i][0] + runs[i][1] / 2)
	cuts.sort()
	var out := []
	var left := 0
	for c in cuts + [im.get_width()]:
		var part := im.get_region(Rect2i(left, 0, c - left, im.get_height()))
		out.append(part.get_region(part.get_used_rect()))
		left = c
	return out


func _save(im: Image, path: String) -> void:
	im.save_png(ProjectSettings.globalize_path(path))
