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
##             graft     {rect, sat}: portrait pixels joined on (Greed's strap): saturated ones plus their lead
##             align_to  another part: fitted to that part's raw, then carried by its transform
##             alt       an alternate state: not in still.png
##             replaces  the part an alt state stands in for (for the review sheet)
##   body_fix rects where the body takes the portrait's own pixels (feathered).
##   patches full repaints (a smile, closed eyes, a drawn hood): fitted inside `rects`, then kept only
##           inside those rects (feathered) and over the body and parts. rest: part of the still.
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

## Figure and ground (Ben, Nov 15, version B): the bg layer is darkened and desaturated per Sin, with a
## vignette (darker toward the edges, less dark behind the head and shoulders), and every figure layer
## gets a dark lead line round its silhouette, its own image so it moves with the layer.
const LINE := 10       # px at window size: full-strength lead line
const LINE_SOFT := 2   # px of canvas padding beyond it (the line itself is crisp)
const LEAD := Color("140d0b")
const VIG_EDGE := 0.25     # extra darkening at the window's corners
const VIG_NIMBUS := 0.35   # share of the darkening taken off at the head
const VIG_SIGMA := 210.0   # px, the nimbus falloff
## Tuning: the lightest grade where, in greyscale, the figure's edge band is lighter than the ground
## band beyond its lead line in TUNE_COVER of the 64 px cells along the silhouette, by TUNE_CELL each,
## and by TUNE_MEAN overall.
const TUNE_DARK := [0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85]
const TUNE_DESAT := [0.2, 0.3, 0.4, 0.5]
const TUNE_COVER := 0.9
const TUNE_CELL := 0.05
const TUNE_MEAN := 0.15

## Gluttony: the arm's scale and offset over the portrait's arm, and the loose dice (centre and width
## in the portrait, 1024 space).
const GLUTTONY := {
	"cx": 0.468,
	"arm": {"scale": 0.89, "offset": [-123, 4], "pivot": [60, 1024]},
	"dice": [[530, 440, 86], [588, 505, 86], [548, 582, 86]],
	"head": [560, 380],
}

const SINS := {
	"envy": {
		"head": [560, 400],  # portrait px: the vignette's nimbus (head and shoulders)
		"body_fix": [[470, 240, 140, 110, 1]],  # the body cut left a hole above his right eye (the bg showed through)
		"parts": {
			# The redone edit has the head and neck in place; its coils are invented, so keep only those
			# (from x 705: left of that it has a green smudge by his face).
			"serpent": {"file": "serpent_v2", "keep": [705, 280, 319, 420], "search": {"t": 24, "s": 0.06, "r": 4}},
		},
		"patches": {"hooded": {"rects": [[347, 107, 400, 453]]}},
	},
	"greed": {
		"head": [600, 380],
		"parts": {
			# The strap and buckle come from the portrait (the body edit dropped them), joined to the purse.
			"purse": {"at": [345, 912], "s": 0.4, "search": {"t": 60, "s": 0.25, "r": 15},
				"graft": {"rect": [430, 730, 130, 160], "sat": 0.28}},
			# The loose coin for the drop into the purse: half size, where coinhand has it.
			"coin": {"place": {"centre": [600, 445], "width": 48}, "alt": true},
		},
		# The coin pinched in his fingers, painted into the glass (an edit of the portrait).
		"patches": {"coinhand": {"rest": true, "rects": [[560, 370, 250, 220]]}},
	},
	"lust": {
		"head": [520, 340],
		"parts": {
			"arm": {"file": "armopen", "anchor": [550, 738], "at": [246, 784], "s": 0.55, "r": 40,
				"search": {"t": 50, "s": 0.2, "r": 40, "rstep": 10}},
			"arm_closed": {"file": "armclosed_v2", "align_to": "arm", "alt": true, "replaces": "arm"},
		},
		"patches": {"wink": {"rects": [[553, 154, 170, 215]]}},
	},
	"pride": {
		"head": [480, 360],
		# v2: the mirror, reflection and holding arm kept in place (the first edit had an empty, re-shaped glass).
		"parts": {"mirror": {"file": "mirror_v2", "search": {"t": 30, "s": 0.06, "r": 4}}},
		# Her face and the face in the mirror.
		"patches": {"smile": {"rects": [[387, 160, 213, 240], [747, 160, 133, 187]]}},
	},
	"sloth": {
		"head": [430, 360],
		"parts": {
			"candle": {"search": {"t": 60, "s": 0.15, "r": 4}},
			"flame": {"at": [146, 515], "s": 0.31, "search": {"t": 40, "s": 0.25, "r": 6}},
		},
		"patches": {"sleep": {"rects": [[369, 123, 170, 307]]}},
	},
	"wrath": {
		"head": [510, 400],
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

	var bg := _img(s + "_layer_bg").get_region(Rect2i(x0, 0, WIN_W, 1024))  # graded and saved below

	var body_src := _cut(_img(s + "_layer_body"))
	var bc := Vector2(512, 512)
	var brects: Array[Rect2i] = []
	for r in cfg.get("body_rects", []):
		brects.append(_rect(r))
	var bp := _fit(body_src, portrait, bc, {"s": 1.0, "r": 0.0, "at": bc}, {"t": 60, "s": 0.15, "r": 3}, brects)
	print("%s body: %s" % [s, _fmt(bp)])
	var body := _warp(body_src, to_win * _xf(bc, bp), win)
	# body_fix: the portrait's own pixels inside feathered rects (an edit's flaw, or a portrait fix
	# the body edit predates). The body keeps its alpha, unless the rect's fifth number is 1 (fill a
	# hole the cut left inside the figure).
	for r in cfg.get("body_fix", []):
		var fr := _rect(r)
		var fill: bool = r.size() > 4 and r[4] == 1
		for y in range(maxi(fr.position.y, 0), mini(fr.end.y, 1024)):
			for x in range(maxi(fr.position.x - x0, 0), mini(fr.end.x - x0, WIN_W)):
				var d := minf(minf(x + x0 - fr.position.x, fr.end.x - x - x0), minf(y - fr.position.y, fr.end.y - y))
				var k := clampf(d / FEATHER, 0.0, 1.0)
				var c := body.get_pixel(x, y)
				var pc := portrait.get_pixel(x + x0, y)
				if fill:
					var a := maxf(c.a, k)
					var kc := k if c.a > 0.0 else 1.0
					body.set_pixel(x, y, Color(lerpf(c.r, pc.r, kc), lerpf(c.g, pc.g, kc), lerpf(c.b, pc.b, kc), a))
				elif c.a > 0.0:
					body.set_pixel(x, y, Color(lerpf(c.r, pc.r, k), lerpf(c.g, pc.g, k), lerpf(c.b, pc.b, k), c.a))
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
			if pc.has("graft"):
				# Portrait pixels in the rect: the saturated ones (leather, gold) plus the dark lead
				# round them, specks dropped; joined to this part so they move with it.
				var gr: Dictionary = pc.graft
				var g := Rect2i(Vector2i(gr.rect[0] - x0, gr.rect[1]), Vector2i(gr.rect[2], gr.rect[3])).intersection(win)
				var gw := g.size.x
				var gh := g.size.y
				var sat_m := PackedByteArray()
				sat_m.resize(gw * gh)
				for y in gh:
					for x in gw:
						var pcol := portrait.get_pixel(g.position.x + x + x0, g.position.y + y)
						if pcol.s >= gr.sat and pcol.v >= 0.08:
							sat_m[y * gw + x] = 1
				var rim := _dil(sat_m, gw, gh, 4)
				var gm := Image.create(gw, gh, false, Image.FORMAT_RGBA8)
				for y in gh:
					for x in gw:
						var pcol := portrait.get_pixel(g.position.x + x + x0, g.position.y + y)
						if sat_m[y * gw + x] == 1 or (rim[y * gw + x] == 1 and pcol.v < 0.22):
							gm.set_pixel(x, y, Color(pcol, 1.0))
				var keep_parts := _pieces(gm)  # pieces over 400 px
				var big := out.merge(g)
				var bim := Image.create(big.size.x, big.size.y, false, Image.FORMAT_RGBA8)
				var n := 0
				for r in keep_parts:
					for y in range(r.position.y, r.end.y):
						for x in range(r.position.x, r.end.x):
							var c2 := gm.get_pixel(x, y)
							if c2.a > 0.5:
								bim.set_pixelv(g.position + Vector2i(x, y) - big.position, c2)
								n += 1
				bim.blend_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), out.position - big.position)
				print("%s %s graft: %d px from the portrait" % [s, pname, n])
				im = bim
				out = big
			_save(im, dir + pname + ".png")
			layout.parts.append({"name": pname, "file": pname + ".png", "rect": [out.position.x, out.position.y, out.size.x, out.size.y]})
			layers.append([pname, im, out.position, pc.get("alt", false), pc.get("replaces", "")])
			if not pc.get("alt", false):
				cover.blend_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), out.position)

	var patches := []  # [image, position, rest]
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
		layout.patches.append({"name": name, "file": name + ".png", "rect": [out.position.x, out.position.y, out.size.x, out.size.y],
			"rest": pc.get("rest", false)})
		patches.append([im, out.position, pc.get("rest", false)])

	# Lead lines: one per figure layer, in its own image (rect grown by the line), so it moves with it.
	var pad := LINE + LINE_SOFT
	var body_line := _line_img(body, pad, LINE, LINE_SOFT)
	_save(body_line, dir + "body_line.png")
	layout["body_line"] = [-pad, -pad, body_line.get_width(), body_line.get_height()]
	for l in layers:
		var li := _line_img(l[1], pad, LINE, LINE_SOFT)
		_save(li, dir + l[0] + "_line.png")
		l.append(li)
		l.append(l[2] - Vector2i(pad, pad))
		for e in layout.parts:
			if e.name == l[0]:
				e["line"] = {"file": l[0] + "_line.png", "rect": [l[2].x - pad, l[2].y - pad, li.get_width(), li.get_height()]}

	# Figure at rest (no ground), to tune the ground's grade against.
	var figure := Image.create(WIN_W, 1024, false, Image.FORMAT_RGBA8)
	figure.blend_rect(body, win, Vector2i.ZERO)
	for l in layers:
		if not l[3]:
			figure.blend_rect(l[1], Rect2i(Vector2i.ZERO, l[1].get_size()), l[2])
	for pt in patches:
		if pt[2]:
			figure.blend_rect(pt[0], Rect2i(Vector2i.ZERO, pt[0].get_size()), pt[1])
	var head := Vector2(cfg.head[0] - x0, cfg.head[1])
	var grade := _tune(bg, figure, head, float(cfg.get("hue", 0.0)))
	print("%s ground: darker %d%%, less saturated %d%%; figure lighter in %d%% of edge cells, by %.2f mean" % [
		s, roundi(grade.dark * 100), roundi(grade.desat * 100), roundi(grade.cover * 100), grade.mean])
	layout["grade"] = grade
	bg = _grade(bg, grade, head)
	_save(bg, dir + "bg.png")

	# Rest patches belong to the still (Greed's coin in his fingers); the others are alternate states.
	var with_rest := func(im: Image) -> Image:
		for pt in patches:
			if pt[2]:
				im.blend_rect(pt[0], Rect2i(Vector2i.ZERO, pt[0].get_size()), pt[1])
		return im
	var still: Image = with_rest.call(_compose(bg, body, body_line, layers, ""))
	_save(still, dir + "still.png")
	var review: Array[Image] = [portrait.get_region(Rect2i(x0, 0, WIN_W, 1024)), still]
	for l in layers:
		if l[3] and l[4] != "":
			review.append(with_rest.call(_compose(bg, body, body_line, layers, l[0])))
	for pt in patches:
		if not pt[2]:
			var st: Image = still.duplicate()
			st.blend_rect(pt[0], Rect2i(Vector2i.ZERO, pt[0].get_size()), pt[1])
			review.append(st)

	var f := FileAccess.open(ProjectSettings.globalize_path(dir + "parts.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(layout, "\t"))
	f.close()
	_save_review(review, REVIEW + s + ".png")
	print("%s baked in %.1f s" % [s, (Time.get_ticks_msec() - t0) / 1000.0])


## bg, every lead line, body, then every part that isn't an alternate state; `state` swaps one alt in
## for the part it replaces. Lines sit under all the figure layers, so they only show against the bg.
func _compose(bg: Image, body: Image, body_line: Image, layers: Array, state: String) -> Image:
	var out: Image = bg.duplicate()
	var hide := ""
	for l in layers:
		if l[0] == state:
			hide = l[4]
	var shown := []
	for l in layers:
		if not ((l[3] and l[0] != state) or l[0] == hide):
			shown.append(l)
	var pad := LINE + LINE_SOFT
	out.blend_rect(body_line, Rect2i(Vector2i.ZERO, body_line.get_size()), Vector2i(-pad, -pad))
	for l in shown:
		out.blend_rect(l[5], Rect2i(Vector2i.ZERO, l[5].get_size()), l[6])
	out.blend_rect(body, Rect2i(Vector2i.ZERO, body.get_size()), Vector2i.ZERO)
	for l in shown:
		out.blend_rect(l[1], Rect2i(Vector2i.ZERO, l[1].get_size()), l[2])
	return out


# --- Figure and ground --------------------------------------------------------------------------

## A dark lead line r px wide round im's alpha, on a canvas pad px bigger each side. Crisp (Ben): round
## (near-Euclidean chamfer distance), solid to r and antialiased over its last pixel; `soft` only pads.
func _line_img(im: Image, pad: int, r: int, _soft: int) -> Image:
	var w := im.get_width() + pad * 2
	var h := im.get_height() + pad * 2
	var big := 1 << 20
	var d := PackedInt32Array()
	d.resize(w * h)
	d.fill(big)
	for y in im.get_height():
		for x in im.get_width():
			if im.get_pixel(x, y).a > 0.5:
				d[(y + pad) * w + x + pad] = 0
	# 5-7-11 chamfer, in fifths of a pixel: forward then backward pass.
	var fwd := [[-1, 0, 5], [0, -1, 5], [-1, -1, 7], [1, -1, 7], [-2, -1, 11], [-1, -2, 11], [1, -2, 11], [2, -1, 11]]
	var bwd := [[1, 0, 5], [0, 1, 5], [1, 1, 7], [-1, 1, 7], [2, 1, 11], [1, 2, 11], [-1, 2, 11], [-2, 1, 11]]
	for y in h:
		for x in w:
			var i := y * w + x
			var v: int = d[i]
			if v == 0:
				continue
			for k in fwd:
				var xx: int = x + k[0]
				var yy: int = y + k[1]
				if xx >= 0 and xx < w and yy >= 0:
					v = mini(v, d[yy * w + xx] + k[2])
			d[i] = v
	for y in range(h - 1, -1, -1):
		for x in range(w - 1, -1, -1):
			var i := y * w + x
			var v: int = d[i]
			if v == 0:
				continue
			for k in bwd:
				var xx: int = x + k[0]
				var yy: int = y + k[1]
				if xx >= 0 and xx < w and yy < h:
					v = mini(v, d[yy * w + xx] + k[2])
			d[i] = v
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for i in w * h:
		var a := clampf(r + 0.5 - d[i] / 5.0, 0.0, 1.0)
		if a > 0.0:
			out.set_pixel(i % w, i / w, Color(LEAD, a))
	return out


## Square dilation by r px, with running sums along rows then columns.
func _dil(m: PackedByteArray, w: int, h: int, r: int) -> PackedByteArray:
	var t := PackedByteArray()
	t.resize(w * h)
	var acc := PackedInt32Array()
	acc.resize(maxi(w, h) + 1)
	for y in h:
		var row := y * w
		acc[0] = 0
		for x in w:
			acc[x + 1] = acc[x] + m[row + x]
		for x in w:
			if acc[mini(w, x + r + 1)] - acc[maxi(0, x - r)] > 0:
				t[row + x] = 1
	var o := PackedByteArray()
	o.resize(w * h)
	for x in w:
		acc[0] = 0
		for y in h:
			acc[y + 1] = acc[y] + t[y * w + x]
		for y in h:
			if acc[mini(h, y + r + 1)] - acc[maxi(0, y - r)] > 0:
				o[y * w + x] = 1
	return o


## The ground's value multiplier at (x, y): darker by g.dark (less near the head), darker still at the edges.
func _vig(x: float, y: float, dark: float, head: Vector2) -> float:
	var nimbus := exp(-Vector2(x, y).distance_squared_to(head) / (2.0 * VIG_SIGMA * VIG_SIGMA))
	var ex := (x - WIN_W / 2.0) / (WIN_W / 2.0)
	var ey := (y - 512.0) / 512.0
	return (1.0 - dark * (1.0 - VIG_NIMBUS * nimbus)) * (1.0 - VIG_EDGE * (ex * ex + ey * ey) / 2.0)


func _grade(bg: Image, g: Dictionary, head: Vector2) -> Image:
	var out: Image = bg.duplicate()
	for y in out.get_height():
		for x in out.get_width():
			var c := out.get_pixel(x, y)
			out.set_pixel(x, y, Color.from_hsv(wrapf(c.h + g.hue, 0.0, 1.0), c.s * (1.0 - g.desat), c.v * _vig(x, y, g.dark, head), c.a))
	return out


static func _lum(c: Color) -> float:
	return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b


## The lightest grade (TUNE_DARK x TUNE_DESAT) where the figure reads lighter than the ground along
## its silhouette: per 64 px cell, the figure 8-24 px inside its edge against the ground 14-34 px out
## (beyond the lead line), in greyscale. Falls back to the grade with the best cover.
func _tune(bg: Image, figure: Image, head: Vector2, hue: float) -> Dictionary:
	var w := WIN_W
	var h := 1024
	var m := PackedByteArray()
	m.resize(w * h)
	var nm := PackedByteArray()
	nm.resize(w * h)
	for y in h:
		for x in w:
			var on := figure.get_pixel(x, y).a > 0.5
			m[y * w + x] = 1 if on else 0
			nm[y * w + x] = 0 if on else 1
	var skin := _dil(nm, w, h, 8)    # the cut-outs carry a black stroke round their edge: skip it
	var band := _dil(nm, w, h, 24)
	var near := _dil(m, w, h, LINE + LINE_SOFT + 1)
	var far := _dil(m, w, h, 34)
	var cw := ceili(w / 64.0)
	var cells := cw * ceili(h / 64.0)
	var in_sum := PackedFloat32Array()
	in_sum.resize(cells)
	var in_n := PackedInt32Array()
	in_n.resize(cells)
	var out_px := []  # [cell, h, s, v, x, y]
	for y in range(4, h - 4):
		for x in range(4, w - 4):
			var i := y * w + x
			var cell := (y / 64) * cw + x / 64
			if m[i] == 1 and skin[i] == 0 and band[i] == 1:
				in_sum[cell] += _lum(figure.get_pixel(x, y))
				in_n[cell] += 1
			elif m[i] == 0 and far[i] == 1 and near[i] == 0:
				var c := bg.get_pixel(x, y)
				out_px.append([cell, c.h, c.s, c.v, x, y])
	var best := {}
	var best_key := INF
	for dark in TUNE_DARK:
		var vig := PackedFloat32Array()
		vig.resize(out_px.size())
		for k in out_px.size():
			vig[k] = _vig(out_px[k][4], out_px[k][5], dark, head)
		for desat in TUNE_DESAT:
			var o_sum := PackedFloat32Array()
			o_sum.resize(cells)
			var o_n := PackedInt32Array()
			o_n.resize(cells)
			for k in out_px.size():
				var p: Array = out_px[k]
				o_sum[p[0]] += _lum(Color.from_hsv(wrapf(p[1] + hue, 0.0, 1.0), p[2] * (1.0 - desat), p[3] * vig[k]))
				o_n[p[0]] += 1
			var used := 0
			var passed := 0
			var diff := 0.0
			for c in cells:
				if in_n[c] < 40 or o_n[c] < 40:
					continue
				var d := in_sum[c] / in_n[c] - o_sum[c] / o_n[c]
				used += 1
				diff += d
				if d >= TUNE_CELL:
					passed += 1
			var cover := float(passed) / maxi(used, 1)
			var mean := diff / maxi(used, 1)
			var ok := cover >= TUNE_COVER and mean >= TUNE_MEAN
			# Passing grades: the lightest touch wins. Otherwise: the best cover.
			var key: float = (dark + desat * 0.5) if ok else (10.0 - cover - mean * 0.1)
			if key < best_key:
				best_key = key
				best = {"dark": dark, "desat": desat, "hue": hue, "cover": cover, "mean": mean, "passed": ok}
	return best


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
	var bg := _img("gluttony_layer_bg").get_region(win)
	var body := _cut(_img("gluttony_layer_body")).get_region(win)
	var arm := _cut(_img("gluttony_layer_arm"))
	var dice := _cut(_img("gluttony_layer_dice"))
	_save(body, dir + "body.png")
	_save(arm, dir + "arm.png")
	var ascale: float = cfg.arm.scale
	# Lead lines, each the same size as its layer (dice padded, centred), so a child sprite with the
	# layer's offset sits on it. Widths are divided by the layer's scale to land at LINE on screen.
	var body_line := _line_img(body, 0, LINE, LINE_SOFT)
	_save(body_line, dir + "body_line.png")
	var arm_line := _line_img(arm, 0, roundi(LINE / ascale), roundi(LINE_SOFT / ascale))
	_save(arm_line, dir + "arm_line.png")
	# The loose dice: connected pieces, largest three, matched to the portrait's dice top to bottom.
	var parts := _pieces(dice)
	parts.sort_custom(func(a, b): return a.size.x * a.size.y > b.size.x * b.size.y)
	parts = parts.slice(0, cfg.dice.size())
	parts.sort_custom(func(a, b): return a.position.y < b.position.y)
	var layout := {"window_x": x0, "arm": cfg.arm, "dice": [], "lines": true}
	var die_ims := []
	for i in parts.size():
		var r: Rect2i = parts[i]
		var die := dice.get_region(r)
		_save(die, dir + "die_%d.png" % i)
		var want: Array = cfg.dice[i]
		var sc := float(want[2]) / r.size.x
		var p := ceili((LINE + LINE_SOFT) / sc)
		var dl := _line_img(die, p, roundi(LINE / sc), roundi(LINE_SOFT / sc))
		_save(dl, dir + "die_%d_line.png" % i)
		die_ims.append([die, dl, sc, Vector2i(want[0] - x0, want[1])])
		layout.dice.append({"file": "die_%d.png" % i, "line": "die_%d_line.png" % i, "centre": [want[0] - x0, want[1]], "scale": sc})

	# At rest, in window space: figure alone (to tune the ground) and its lines.
	var arm_at := Vector2i(cfg.arm.offset[0] - x0, cfg.arm.offset[1])
	var a2: Image = arm.duplicate()
	a2.resize(roundi(1024 * ascale), roundi(1024 * ascale), Image.INTERPOLATE_LANCZOS)
	var al: Image = arm_line.duplicate()
	al.resize(a2.get_width(), a2.get_height(), Image.INTERPOLATE_BILINEAR)
	var figure := Image.create(819, 1024, false, Image.FORMAT_RGBA8)
	var lines := Image.create(819, 1024, false, Image.FORMAT_RGBA8)
	figure.blend_rect(body, Rect2i(Vector2i.ZERO, win.size), Vector2i.ZERO)
	lines.blend_rect(body_line, Rect2i(Vector2i.ZERO, win.size), Vector2i.ZERO)
	figure.blend_rect(a2, Rect2i(Vector2i.ZERO, a2.get_size()), arm_at)
	lines.blend_rect(al, Rect2i(Vector2i.ZERO, al.get_size()), arm_at)
	for d in die_ims:
		for k in 2:
			var im: Image = d[k].duplicate()
			im.resize(maxi(1, roundi(im.get_width() * d[2])), maxi(1, roundi(im.get_height() * d[2])), Image.INTERPOLATE_LANCZOS)
			(figure if k == 0 else lines).blend_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), d[3] - im.get_size() / 2)
	var head := Vector2(cfg.head[0] - x0, cfg.head[1])
	var grade := _tune(bg, figure, head, 0.0)
	print("gluttony ground: darker %d%%, less saturated %d%%; figure lighter in %d%% of edge cells, by %.2f mean" % [
		roundi(grade.dark * 100), roundi(grade.desat * 100), roundi(grade.cover * 100), grade.mean])
	layout["grade"] = grade
	bg = _grade(bg, grade, head)
	_save(bg, dir + "bg.png")
	var f := FileAccess.open(ProjectSettings.globalize_path(dir + "layout.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(layout, "\t"))
	f.close()
	var still: Image = bg.duplicate()
	still.blend_rect(lines, Rect2i(Vector2i.ZERO, win.size), Vector2i.ZERO)
	still.blend_rect(figure, Rect2i(Vector2i.ZERO, win.size), Vector2i.ZERO)
	_save(still, dir + "still.png")
	var review: Array[Image] = [_img("gluttony_portrait").get_region(win), still]
	_save_review(review, REVIEW + "gluttony.png")
