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
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT + "dice"))
	# Inked ivory dice, 3x2 grid. Strikes (1 and 2) carry red ink: the art inks only the 1 red, so the 2 is re-inked.
	var dice := _grid(_cut(_load("res://assets/art/dice/raw/dice_ink_a_raw.png")), 3, 2)
	_red_ink(dice[1])
	for i in 6:
		_save(_fit_h(dice[i], 320), OUT + "dice/%d.png" % (i + 1))
	# Wax seal (normal, pressed, cracked), gold-leaf numerals 1-9 (3x3 grid), marginalia throw hand.
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT + "seals"))
	for state in ["normal", "pressed", "cracked"]:
		var src: String = "seal_b" if state == "normal" else "seal_" + state
		_save(_fit_h(_square(_cut(_load("res://assets/art/seals/raw/%s_raw.png" % src))), 512), OUT + "seals/%s.png" % state)
	var nums := _grid(_cut(_load("res://assets/art/seals/raw/numerals_gold_b_raw.png")), 3, 3)
	for i in 9:
		_save(_fit_h(nums[i], 220), OUT + "seals/n%d.png" % (i + 1))
	_save(_fit_h(_cut(_load("res://assets/art/extra/raw/throw_hand_a_raw.png")), 256), OUT + "throw_hand.png")
	# Thumb-zone page: slim vine border, marginalia only in the corners (9-sliced in ui/main.gd).
	var page := _cut(_load("res://assets/art/ui/raw/page_b_b_raw.png"))
	page.resize(1600, 900, Image.INTERPOLATE_LANCZOS)
	_save(page, OUT + "page.png")
	var bg := _load("res://assets/art/bg/raw/bg_b_raw.png")
	bg.resize(1080, 1920, Image.INTERPOLATE_LANCZOS)
	_save(bg, OUT + "bg.png")
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


## Splits a grid of cols x rows objects: rows at the widest empty row gaps, then each row by columns.
func _grid(im: Image, cols: int, rows: int) -> Array:
	var t := _transpose(im)
	var out := []
	for r in _split(t, rows):
		out.append_array(_split(_transpose(r), cols))
	return out


func _transpose(im: Image) -> Image:
	var t := Image.create(im.get_height(), im.get_width(), false, Image.FORMAT_RGBA8)
	for y in im.get_height():
		for x in im.get_width():
			t.set_pixel(y, x, im.get_pixel(x, y))
	return t


## Turns dark, unsaturated ink (the pips) deep red, keeping its shading.
func _red_ink(im: Image) -> void:
	for y in im.get_height():
		for x in im.get_width():
			var c := im.get_pixel(x, y)
			var l := c.get_luminance()
			if c.a > 0.0 and l < 0.32 and c.s < 0.45:
				var k := clampf(1.0 - l / 0.32, 0.0, 1.0)
				im.set_pixel(x, y, c.lerp(Color(0.72 * (0.6 + l), 0.07, 0.05, c.a), k))


## Pads to a square (centred), so a button stylebox can stretch it without distortion.
func _square(im: Image) -> Image:
	var s := maxi(im.get_width(), im.get_height())
	var sq := Image.create(s, s, false, Image.FORMAT_RGBA8)
	sq.blit_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i((s - im.get_width()) / 2, (s - im.get_height()) / 2))
	return sq
