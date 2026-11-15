## Bakes each Sin's living-portrait layers (living glass, stage 2) from SpriteCook edits of its
## portrait (sins/portrait_raw/<sin>_layer_*_raw.png, 1024 square). Output goes in the portrait's 4:5
## window (the crop tools/bake_art.gd uses, PORTRAIT_CX), in assets/art/runtime/sins/<sin>_layers/.
##
## Gluttony (the first, hand-placed) keeps its own bake and layout.json, read by ui/living_portrait.gd.
## The other Sins go through the generic bake below and write parts.json instead, so the game keeps
## showing their still portraits until living_portrait reads the new layout (next step).
##
## Generic bake, per Sin (SINS):
##   bg      full plate, cropped to the window.
##   body    cut-out, fitted to the portrait (inside body_rects if given: the face, when the edit
##           changed the body's proportions), warped into the window at full size.
##   parts   cut-outs, each fitted to the portrait by offset, scale and rotation: a coarse grid around
##           the seed, then a hill-climb, on colour difference at quarter scale. Options:
##             file      raw name if not the part's name
##             at, s, r  seed: where the anchor lands (portrait px), scale, degrees
##             anchor    the source point that goes to `at` (default: the cut-out's centre)
##             search    {t: px, s: fraction, r: degrees, rstep: degrees} around the seed
##             keep      [x, y, w, h] in source px: only this region (feathered) is used
##             split     n: the n largest pieces become separate parts (name_0.. left to right)
##             place     {centre, width}: no fit (props the portrait doesn't have)
##             align_to  another part: fitted to that part's raw, then carried by its transform
##             alt       an alternate state: not in still.png
##             replaces  the part an alt state stands in for (for the review sheet)
##   patches full repaints (a smile, closed eyes, a drawn hood): fitted inside `rects`, then kept only
##           inside those rects (feathered) and over the body and parts.
## Every part and patch is a PNG cropped to its bounds; parts.json gives each one's rect in the window.
## still.png is bg + body + parts at rest. Docs/review/layers/<sin>.png puts the portrait's window
## beside the still and each alternate state, for checking by eye.
## godot --headless --path . --script res://tools/bake_layers.gd [-- sin ...]
extends SceneTree

const BakeArt = preload("res://tools/bake_art.gd")
const SRC := "res://assets/art/sins/portrait_raw/"
const OUT := "res://assets/art/runtime/sins/"
const REVIEW := "res://Docs/review/layers/"
const WIN_W := 819
const FIT_N := 2000  # samples for the hill-climb (the coarse grid uses COARSE_N)
const COARSE_N := 250
const FEATHER := 20.0  # px, patch and keep edges

## Gluttony: the arm's scale and offset over the portrait's arm, and the loose dice (centre and width
## in the portrait, 1024 space).
const GLUTTONY := {
	"cx": 0.468,
	"arm": {"scale": 0.89, "offset": [-123, 4], "pivot": [60, 1024]},
	"dice": [[530, 440, 86], [588, 505, 86], [548, 582, 86]],
}

const SINS := {
	"envy": {
		"parts": {
			# The redone edit has the head and neck in place; its coils are invented, so keep only those.
			"serpent": {"file": "serpent_v2", "keep": [600, 280, 424, 420], "search": {"t": 24, "s": 0.06, "r": 4}},
		},
		"patches": {"hooded": {"rects": [[347, 107, 400, 453]]}},
	},
	"greed": {
		"parts": {
			"purse": {"at": [345, 912], "s": 0.4, "search": {"t": 60, "s": 0.25, "r": 15}},
			"coin": {"place": {"centre": [560, 430], "width": 110}},
		},
	},
	"lust": {
		"parts": {
			"arm": {"file": "armopen", "anchor": [550, 738], "at": [246, 784], "s": 0.55, "r": 40,
				"search": {"t": 50, "s": 0.2, "r": 40, "rstep": 10}},
			"arm_closed": {"file": "armclosed_v2", "align_to": "arm", "alt": true, "replaces": "arm"},
		},
		"patches": {"wink": {"rects": [[553, 154, 170, 215]]}},
	},
	"pride": {
		# v2: the mirror, reflection and holding arm kept in place (the first edit had an empty, re-shaped glass).
		"parts": {"mirror": {"file": "mirror_v2", "search": {"t": 30, "s": 0.06, "r": 4}}},
		# Her face and the face in the mirror.
		"patches": {"smile": {"rects": [[387, 160, 213, 240], [747, 160, 133, 187]]}},
	},
	"sloth": {
		"parts": {
			"candle": {"search": {"t": 60, "s": 0.15, "r": 4}},
			"flame": {"at": [146, 515], "s": 0.31, "search": {"t": 40, "s": 0.25, "r": 6}},
		},
		"patches": {"sleep": {"rects": [[369, 123, 170, 307]]}},
	},
	"wrath": {
		"body_rects": [[402, 190, 210, 340]],
		"parts": {"arms": {"split": 2, "s": 0.75, "search": {"t": 100, "s": 0.12, "r": 8}}},
	},
}


func _initialize() -> void:
	var only := OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REVIEW))
	if only.is_empty() or only.has("gluttony"):
		_bake_gluttony()
	for s in SINS:
		if only.is_empty() or only.has(s):
			_bake(s, SINS[s])
	print("layers baked")
	quit()


# --- Generic bake -------------------------------------------------------------------------------

func _bake(s: String, cfg: Dictionary) -> void:
	var t0 := Time.get_ticks_msec()
	var dir := OUT + "%s_layers/" % s
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var portrait := _img(s + "_portrait")
	var x0 := clampi(roundi(1024 * float(BakeArt.PORTRAIT_CX.get(s, 0.5)) - 409.6), 0, 1024 - WIN_W)
	var win := Rect2i(0, 0, WIN_W, 1024)
	var to_win := Transform2D(0.0, Vector2(-x0, 0))
	var layout := {"window_x": x0, "size": [WIN_W, 1024], "parts": [], "patches": []}
	var layers := []  # [name, image, position in the window, alt, replaces]

	var bg := _img(s + "_layer_bg").get_region(Rect2i(x0, 0, WIN_W, 1024))
	_save(bg, dir + "bg.png")

	var body_src := _cut(_img(s + "_layer_body"))
	var bc := Vector2(512, 512)
	var brects: Array[Rect2i] = []
	for r in cfg.get("body_rects", []):
		brects.append(_rect(r))
	var bp := _fit(body_src, portrait, bc, {"s": 1.0, "r": 0.0, "at": bc}, {"t": 60, "s": 0.15, "r": 3}, brects)
	print("%s body: %s" % [s, _fmt(bp)])
	var body := _warp(body_src, to_win * _xf(bc, bp), win)
	_save(body, dir + "body.png")
	var cover: Image = body.duplicate()  # alpha of everything over the bg, window space

	var xfs := {}   # part -> portrait-space transform
	var raws := {}  # part -> its cut source
	for name in cfg.get("parts", {}):
		var pc: Dictionary = cfg.parts[name]
		var src := _cut(_img(s + "_layer_" + pc.get("file", name)))
		if pc.has("keep"):
			_keep(src, _rect(pc.keep))
		raws[name] = src
		# One entry per piece: [name, source, its used rect]. Split pieces are fitted one by one.
		var pieces := [[name, src, src.get_used_rect()]]
		if pc.has("split"):
			var rs := _pieces(src)
			rs.sort_custom(func(a, b): return a.size.x * a.size.y > b.size.x * b.size.y)
			rs = rs.slice(0, int(pc.split))
			rs.sort_custom(func(a, b): return a.position.x < b.position.x)
			pieces = []
			for i in rs.size():
				pieces.append(["%s_%d" % [name, i], _only(src, rs[i]), rs[i]])
		for pe in pieces:
			var pname: String = pe[0]
			var piece: Image = pe[1]
			var used: Rect2i = pe[2]
			var c := Vector2(pc.anchor[0], pc.anchor[1]) if pc.has("anchor") else Vector2(used.get_center())
			var xf: Transform2D
			if pc.has("place"):
				var pl: Dictionary = pc.place
				xf = _xf(c, {"s": float(pl.width) / used.size.x, "r": 0.0, "at": Vector2(pl.centre[0], pl.centre[1])})
			elif pc.has("align_to"):
				var rel := _fit(piece, raws[pc.align_to], c, {"s": 1.0, "r": 0.0, "at": c}, {"t": 40, "s": 0.1, "r": 8})
				print("%s %s on %s: %s" % [s, pname, pc.align_to, _fmt(rel)])
				xf = xfs[pc.align_to] * _xf(c, rel)
			else:
				var at := Vector2(pc.at[0], pc.at[1]) if pc.has("at") else c
				var p := _fit(piece, portrait, c, {"s": float(pc.get("s", 1.0)), "r": deg_to_rad(pc.get("r", 0.0)), "at": at},
					pc.get("search", {}))
				print("%s %s: %s" % [s, pname, _fmt(p)])
				xf = _xf(c, p)
			xfs[pname] = xf
			var wxf := to_win * xf
			var out := Rect2i((wxf * Rect2(used)).grow(2)).intersection(win)
			if out.size.x <= 0 or out.size.y <= 0:
				push_warning("%s %s lands outside the window" % [s, pname])
				continue
			var im := _warp(piece, wxf, out)
			_save(im, dir + pname + ".png")
			layout.parts.append({"name": pname, "file": pname + ".png", "rect": [out.position.x, out.position.y, out.size.x, out.size.y]})
			layers.append([pname, im, out.position, pc.get("alt", false), pc.get("replaces", "")])
			if not pc.get("alt", false):
				cover.blend_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), out.position)

	var still := _compose(bg, body, layers, "")
	_save(still, dir + "still.png")
	var review: Array[Image] = [portrait.get_region(Rect2i(x0, 0, WIN_W, 1024)), still]
	for l in layers:
		if l[3]:
			review.append(_compose(bg, body, layers, l[0]))

	for name in cfg.get("patches", {}):
		var pc: Dictionary = cfg.patches[name]
		var rep := _img(s + "_layer_" + pc.get("file", name))
		var rects: Array[Rect2i] = []
		for r in pc.rects:
			rects.append(_rect(r))
		var c := Vector2(512, 512)
		var p := _fit(rep, portrait, c, {"s": 1.0, "r": 0.0, "at": c}, {"t": 16, "s": 0.03, "r": 2}, rects)
		print("%s patch %s: %s" % [s, name, _fmt(p)])
		var u := rects[0]
		for r in rects:
			u = u.merge(r)
		var out := Rect2i(u.position - Vector2i(x0, 0), u.size).intersection(win)
		var im := _warp(rep, to_win * _xf(c, p), out)
		for y in out.size.y:
			for x in out.size.x:
				var q := Vector2(out.position.x + x + x0, out.position.y + y)  # portrait px
				var a := 0.0
				for r in rects:
					var d := minf(minf(q.x - r.position.x, r.end.x - q.x), minf(q.y - r.position.y, r.end.y - q.y))
					a = maxf(a, clampf(d / FEATHER, 0.0, 1.0))
				a *= cover.get_pixel(out.position.x + x, out.position.y + y).a
				var col := im.get_pixel(x, y)
				col.a *= a
				im.set_pixel(x, y, col)
		_save(im, dir + name + ".png")
		layout.patches.append({"name": name, "file": name + ".png", "rect": [out.position.x, out.position.y, out.size.x, out.size.y]})
		var st: Image = still.duplicate()
		st.blend_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), out.position)
		review.append(st)

	var f := FileAccess.open(ProjectSettings.globalize_path(dir + "parts.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(layout, "\t"))
	f.close()
	_save_review(review, REVIEW + s + ".png")
	print("%s baked in %.1f s" % [s, (Time.get_ticks_msec() - t0) / 1000.0])


## bg, body, then every part that isn't an alternate state; `state` swaps one alt in for the part it replaces.
func _compose(bg: Image, body: Image, layers: Array, state: String) -> Image:
	var out: Image = bg.duplicate()
	out.blend_rect(body, Rect2i(Vector2i.ZERO, body.get_size()), Vector2i.ZERO)
	var hide := ""
	for l in layers:
		if l[0] == state:
			hide = l[4]
	for l in layers:
		if (l[3] and l[0] != state) or l[0] == hide:
			continue
		out.blend_rect(l[1], Rect2i(Vector2i.ZERO, l[1].get_size()), l[2])
	return out


## Side by side at half size.
func _save_review(ims: Array[Image], path: String) -> void:
	var w := WIN_W / 2
	var sheet := Image.create(w * ims.size() + 8 * (ims.size() - 1), 512, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.1, 0.1, 0.1))
	for i in ims.size():
		var im: Image = ims[i].duplicate()
		im.resize(w, 512, Image.INTERPOLATE_LANCZOS)
		sheet.blit_rect(im, Rect2i(0, 0, w, 512), Vector2i(i * (w + 8), 0))
	_save(sheet, path)


# --- Fitting ------------------------------------------------------------------------------------

## Source px -> portrait px: the anchor c goes to p.at, scaled by p.s and turned by p.r (radians).
func _xf(c: Vector2, p: Dictionary) -> Transform2D:
	return Transform2D(p.r, Vector2(p.s, p.s), 0.0, p.at) * Transform2D(0.0, -c)


## Finds the scale, rotation and position that put src's opaque pixels over the same colours in
## target. A coarse grid around the seed, then a hill-climb; all at quarter scale. rects limits the
## samples (patches).
func _fit(src: Image, target: Image, c: Vector2, seed: Dictionary, search: Dictionary, rects: Array[Rect2i] = []) -> Dictionary:
	const F := 4.0
	var tg: Image = target.duplicate()
	tg.resize(256, 256, Image.INTERPOLATE_BILINEAR)
	var td := tg.get_data()
	var sm: Image = src.duplicate()
	sm.resize(256, 256, Image.INTERPOLATE_BILINEAR)
	var sd := sm.get_data()
	var pts := PackedVector2Array()
	var cols := PackedFloat32Array()
	for y in 256:
		for x in 256:
			var i := (y * 256 + x) * 4
			if sd[i + 3] < 230:
				continue
			var p := Vector2(x + 0.5, y + 0.5) * F
			if not rects.is_empty():
				var inside := false
				for r in rects:
					inside = inside or Rect2(r).has_point(p)
				if not inside:
					continue
			pts.append(p)
			cols.append_array([sd[i] / 255.0, sd[i + 1] / 255.0, sd[i + 2] / 255.0])
	if pts.is_empty():
		push_warning("nothing to fit")
		return seed
	var cost := func(p: Dictionary, n: int) -> float:
		var xf := _xf(c, p)
		var step := maxi(1, pts.size() / n)
		var sum := 0.0
		var k := 0
		for i in range(0, pts.size(), step):
			var q: Vector2 = xf * pts[i] / F
			var x := int(q.x)
			var y := int(q.y)
			k += 1
			if x < 0 or y < 0 or x >= 256 or y >= 256:
				sum += 1.0
				continue
			var j := (y * 256 + x) * 4
			if td[j + 3] < 128:
				sum += 1.0
				continue
			sum += (absf(cols[i * 3] - td[j] / 255.0) + absf(cols[i * 3 + 1] - td[j + 1] / 255.0) + absf(cols[i * 3 + 2] - td[j + 2] / 255.0)) / 3.0
		return sum / k
	# Coarse grid.
	var R := deg_to_rad(search.get("r", 0.0))
	var rstep := deg_to_rad(search.get("rstep", 4.0))
	var S: float = search.get("s", 0.0)
	var T: float = search.get("t", 0.0)
	var tstep := maxf(4.0, T / 5.0)
	var best := seed.duplicate()
	var best_c: float = cost.call(best, COARSE_N)
	var r := -R
	while r <= R + 0.0001:
		for si in (5 if S > 0.0 else 1):
			var sc: float = seed.s * (1.0 + (S * (si - 2) / 2.0 if S > 0.0 else 0.0))
			var tx := -T
			while tx <= T:
				var ty := -T
				while ty <= T:
					var p := {"s": sc, "r": seed.r + r, "at": seed.at + Vector2(tx, ty)}
					var k: float = cost.call(p, COARSE_N)
					if k < best_c:
						best_c = k
						best = p
					ty += tstep
				tx += tstep
		r += rstep
		if R <= 0.0:
			break
	# Hill-climb.
	best_c = cost.call(best, FIT_N)
	var dt := tstep / 2.0
	var ds := 0.02
	var dr := deg_to_rad(1.0)
	while dt > 0.5:
		var moved := false
		for d in [{"at": Vector2(dt, 0)}, {"at": Vector2(-dt, 0)}, {"at": Vector2(0, dt)}, {"at": Vector2(0, -dt)},
				{"s": ds}, {"s": -ds}, {"r": dr}, {"r": -dr}]:
			var p := best.duplicate()
			p.at += d.get("at", Vector2.ZERO)
			p.s *= 1.0 + d.get("s", 0.0)
			p.r += d.get("r", 0.0)
			var k: float = cost.call(p, FIT_N)
			if k < best_c:
				best_c = k
				best = p
				moved = true
		if not moved:
			dt /= 2.0
			ds /= 2.0
			dr /= 2.0
	best["cost"] = best_c
	return best


func _fmt(p: Dictionary) -> String:
	return "at (%d, %d) x%.3f %.1f deg, diff %.3f" % [p.at.x, p.at.y, p.s, rad_to_deg(p.r), p.get("cost", -1.0)]


# --- Images -------------------------------------------------------------------------------------

## src resampled through xf into rect (destination px), bilinear on premultiplied colour.
func _warp(src: Image, xf: Transform2D, rect: Rect2i) -> Image:
	var inv := xf.affine_inverse()
	var out := Image.create(rect.size.x, rect.size.y, false, Image.FORMAT_RGBA8)
	var w := src.get_width()
	var h := src.get_height()
	for y in rect.size.y:
		for x in rect.size.x:
			var p := inv * Vector2(rect.position.x + x + 0.5, rect.position.y + y + 0.5) - Vector2(0.5, 0.5)
			if p.x <= -1.0 or p.y <= -1.0 or p.x >= w or p.y >= h:
				continue
			var ix := floori(p.x)
			var iy := floori(p.y)
			var fx := p.x - ix
			var fy := p.y - iy
			var acc := Color(0, 0, 0, 0)
			for k in 4:
				var sx := ix + (k & 1)
				var sy := iy + (k >> 1)
				if sx < 0 or sy < 0 or sx >= w or sy >= h:
					continue
				var wt := (fx if k & 1 else 1.0 - fx) * (fy if k >> 1 else 1.0 - fy)
				var c := src.get_pixel(sx, sy)
				acc += Color(c.r * c.a, c.g * c.a, c.b * c.a, c.a) * wt
			if acc.a > 0.002:
				out.set_pixel(x, y, Color(acc.r / acc.a, acc.g / acc.a, acc.b / acc.a, acc.a))
	return out


## Only the region r is kept, its edge feathered.
func _keep(im: Image, r: Rect2i) -> void:
	for y in im.get_height():
		for x in im.get_width():
			var d := minf(minf(x - r.position.x, r.end.x - x), minf(y - r.position.y, r.end.y - y))
			if d < FEATHER:
				var c := im.get_pixel(x, y)
				c.a *= clampf(d / FEATHER, 0.0, 1.0)
				im.set_pixel(x, y, c)


## A copy with everything outside r cleared.
func _only(im: Image, r: Rect2i) -> Image:
	var out := Image.create(im.get_width(), im.get_height(), false, Image.FORMAT_RGBA8)
	out.blit_rect(im, r, r.position)
	return out


func _rect(a: Array) -> Rect2i:
	return Rect2i(a[0], a[1], a[2], a[3])


func _img(name: String) -> Image:
	var im := Image.load_from_file(ProjectSettings.globalize_path(SRC + name + "_raw.png"))
	im.convert(Image.FORMAT_RGBA8)
	return im


func _save(im: Image, path: String) -> void:
	im.save_png(ProjectSettings.globalize_path(path))


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


# --- Gluttony (hand-placed, layout.json for ui/living_portrait.gd) ------------------------------

func _bake_gluttony() -> void:
	var cfg := GLUTTONY
	var dir := OUT + "gluttony_layers/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var x0 := clampi(roundi(1024 * cfg.cx - 409.6), 0, 1024 - 819)
	var win := Rect2i(x0, 0, 819, 1024)
	var bg := _img("gluttony_layer_bg")
	var body := _cut(_img("gluttony_layer_body"))
	var arm := _cut(_img("gluttony_layer_arm"))
	var dice := _cut(_img("gluttony_layer_dice"))
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
	var a2: Image = arm.duplicate()
	a2.resize(roundi(1024 * cfg.arm.scale), roundi(1024 * cfg.arm.scale), Image.INTERPOLATE_LANCZOS)
	still.blend_rect(a2, Rect2i(Vector2i.ZERO, a2.get_size()), Vector2i(cfg.arm.offset[0] - x0, cfg.arm.offset[1]))
	for d in layout.dice:
		var im := Image.load_from_file(ProjectSettings.globalize_path(dir + d.file))
		im.resize(maxi(1, roundi(im.get_width() * d.scale)), maxi(1, roundi(im.get_height() * d.scale)), Image.INTERPOLATE_LANCZOS)
		still.blend_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i(d.centre[0] - im.get_width() / 2, d.centre[1] - im.get_height() / 2))
	still.save_png(ProjectSettings.globalize_path(dir + "still.png"))
