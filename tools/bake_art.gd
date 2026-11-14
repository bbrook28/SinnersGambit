## Bakes runtime textures from SpriteCook raw sources (assets/art/*/raw, which Godot ignores).
## godot --headless --path . --script res://tools/bake_art.gd
## Raw images carry a soft glow halo in alpha: a hard cut at 0.6 keeps only the object.
extends SceneTree

const SINS := ["pride", "greed", "wrath", "envy", "gluttony", "lust", "sloth"]
const OUT := "res://assets/art/runtime/"
## Corner figures on page_c_a_raw.png: [rect in raw px, darkest parchment luminance, extra flood seeds].
const MARGINALIA := {
	"jester": [Rect2i(80, 84, 218, 214), 0.35, []],
	"pennant": [Rect2i(1738, 66, 220, 234), 0.35, []],
	"skeleton": [Rect2i(1738, 843, 210, 214), 0.35, []],
}


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
	# The jester, pennant and skeleton are keyed out into their own sprites (they react in play,
	# ui/director.gd) and their spots on the page are filled with plain parchment.
	var page := _load("res://assets/art/ui/raw/page_c_a_raw.png")
	var probe: Image = page.duplicate()
	for y in probe.get_height():
		for x in probe.get_width():
			var c := probe.get_pixel(x, y)
			c.a = 1.0 if c.a > 0.6 else 0.0
			probe.set_pixel(x, y, c)
	var used := probe.get_used_rect()  # what _cut keeps
	var k := Vector2(1600.0, 900.0) / Vector2(used.size)  # the page is resized to 1600x900, not quite uniformly
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT + "marginalia"))
	for name in MARGINALIA:
		var m: Array = MARGINALIA[name]
		var fig := _key_parchment(page, m[0], m[1], m[2])
		var box := fig.get_used_rect()
		var sprite := fig.get_region(box)
		sprite.resize(roundi(sprite.get_width() * k.x), roundi(sprite.get_height() * k.y), Image.INTERPOLATE_LANCZOS)
		_save(sprite, OUT + "marginalia/%s.png" % name)
		print("%s at %s size %s" % [name, (Vector2(m[0].position + box.position - used.position) * k).round(), sprite.get_size()])
	page = _cut(page)
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


## Floods parchment in from the rect's border (stopping at dark ink and saturated colour) and returns
## the rest as a figure the size of the rect. On `page` the figure (grown 3 px) is replaced with
## parchment: colours diffused in from around it, plus grain borrowed from the plain page centre.
func _key_parchment(page: Image, r: Rect2i, dark: float, seeds: Array) -> Image:
	var w := r.size.x
	var h := r.size.y
	var bg := PackedByteArray()
	bg.resize(w * h)
	var stack: Array[Vector2i] = []
	for x in w:
		stack.append(Vector2i(x, 0)); stack.append(Vector2i(x, h - 1))
	for y in h:
		stack.append(Vector2i(0, y)); stack.append(Vector2i(w - 1, y))
	stack.append_array(seeds)
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h or bg[p.y * w + p.x] == 1:
			continue
		var c := page.get_pixelv(r.position + p)
		if c.get_luminance() <= dark or c.h <= 0.03 or c.h >= 0.17 or c.s >= 0.8:
			continue
		bg[p.y * w + p.x] = 1
		stack.append(p + Vector2i.RIGHT); stack.append(p + Vector2i.LEFT); stack.append(p + Vector2i.DOWN); stack.append(p + Vector2i.UP)
	# Specks: figure islands under 60 px go back to parchment.
	var seen := PackedByteArray()
	seen.resize(w * h)
	for i in w * h:
		if bg[i] == 1 or seen[i] == 1:
			continue
		var island: Array[int] = []
		var todo: Array[int] = [i]
		seen[i] = 1
		while not todo.is_empty():
			var j: int = todo.pop_back()
			island.append(j)
			var jx := j % w
			for nb in [j - 1 if jx > 0 else -1, j + 1 if jx < w - 1 else -1, j - w, j + w]:
				if nb >= 0 and nb < w * h and bg[nb] == 0 and seen[nb] == 0:
					seen[nb] = 1
					todo.append(nb)
		if island.size() < 60:
			for j in island:
				bg[j] = 1
	var fig := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var c := page.get_pixel(r.position.x + x, r.position.y + y)
			if bg[y * w + x] == 1:
				c.a = 0.0
			fig.set_pixel(x, y, c)
	# Hole = figure grown 3 px. Fill it onion-style from the outside in.
	var hole := PackedByteArray()
	hole.resize(w * h)
	for y in h:
		for x in w:
			if bg[y * w + x] == 1:
				continue
			for dy in range(-3, 4):
				for dx in range(-3, 4):
					var xx := x + dx
					var yy := y + dy
					if xx >= 0 and yy >= 0 and xx < w and yy < h:
						hole[yy * w + xx] = 1
	var centre := page.get_size() / 2
	var mean := Color(0, 0, 0)
	for y in 32:
		for x in 32:
			mean += page.get_pixel(centre.x + x, centre.y + y) / 1024.0
	# Each hole pixel: the parchment found along 8 rays, weighted by nearness, plus real grain
	# from the plain page centre so the patch isn't smooth.
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]
	var fills := {}
	for y in h:
		for x in w:
			if hole[y * w + x] == 0:
				continue
			var sum := Color(0, 0, 0, 0)
			var wsum := 0.0
			for d in dirs:
				var q: Vector2i = Vector2i(x, y) + d
				for step in 400:
					var inside := q.x >= 0 and q.y >= 0 and q.x < w and q.y < h
					if not inside or hole[q.y * w + q.x] == 0:
						var qc := page.get_pixelv(r.position + q)
						if qc.get_luminance() > 0.35 and qc.h > 0.03 and qc.h < 0.17 and qc.s < 0.8 and qc.a > 0.6:
							var wt := 1.0 / float(step + 1)
							sum += qc * wt
							wsum += wt
							break
					q += d
					var pq := r.position + q
					if pq.x < 0 or pq.y < 0 or pq.x >= page.get_width() or pq.y >= page.get_height():
						break
			var base: Color = sum / wsum if wsum > 0.0 else mean
			var grain := page.get_pixel(centre.x + x, centre.y + y) - mean
			fills[Vector2i(x, y)] = Color(base.r + grain.r, base.g + grain.g, base.b + grain.b, 1.0)
	for p in fills:
		page.set_pixelv(r.position + p, fills[p])
	return fig


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
