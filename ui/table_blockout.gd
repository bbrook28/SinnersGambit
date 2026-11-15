## Phase 8 table, BLOCKOUT round 2 (Ben, 2026-11-15): flat shapes in the five-colour palette, under
## the restraint rules (Docs/UXPlan.md). Only the Sins' glass and the dice carry detail; everything
## else is a flat shape or plain ink line, a placeholder for the woodcut-ink pieces still to be drawn.
## Static: one moment drawn from a fixture (tools/fixture.gd, screen "table"); nothing animates, no
## rules run, not wired into play.
##   Built bottom-up round the decision: Bank and Throw under the thumbs, the three Strike candles
##   between them on my edge, the points at stake in gold directly above Bank, the dice above that.
##   The page fits round them and the windows sit just above it (spare height is dark wall on top).
##   The active window is drawn twice the width of the others. The page is lit in a pool round the
##   dice and decision, falling to shadow at its edges; the desk is dark.
##   Score track, two variants (`track`): "margin", a wide column down the page's left edge, or
##   "band", a strip across the top of the page under the windows. Markers are 124 px (45 pt) and
##   never overlap: close scores stand side by side in two lanes, an ink tick marking the true place.
extends Control

const Art = preload("res://ui/art.gd")
const Style = preload("res://ui/style.gd")
const Tuning = preload("res://ui/tuning.gd")
const Die = preload("res://ui/widgets/die.gd")

# The palette: black, parchment, bone, crimson, gold leaf (+ the active Sin's glass colour).
const BLACK := Color("140d0b")
const INK := Color("2a1810")      # black, on parchment
const PARCH := Color("dccb9f")
const BONE := Color("e8dcbc")
const CRIMSON := Color("9e1c22")
const GOLD := Color("e9c46a")

const SIDE := 40.0         # px, screen side margin
const WIN_GAP := 12.0
const WIN_RATIO := 1.8     # window crop height / width (as the board windows)
const GOAL := 1000.0       # first to 1000 wins
const SEAL := 236.0        # Bank and Throw, px (86 pt)
const EDGE := 40.0         # seals and candles stand this far in from the page's near edge
const CANDLE := Vector2(84, 300)
const CANDLE_GAP := 30.0
const MARK := 124.0        # track marker, px (45 pt)
const LANE := 164.0        # marker spacing along the track and between lanes (room for the leader's ring and crown)
const LANES := 2

## seats: [{sin, score, you}], cur: active seat, faces: dice on the page, points: at stake,
## strikes: 0-3, moment: "decision" | "rival" | "bust", track: "margin" | "band",
## safe: Vector2(top, bottom) insets in px.
var seats: Array = []
var cur := 0
var faces: Array = []
var points := 0
var strikes := 0
var moment := "decision"
var track := "margin"
var safe := Vector2.ZERO


func build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vp := get_viewport_rect().size
	var me := 0
	var lead := 0
	for i in seats.size():
		if seats[i].get("you", false):
			me = i
		if seats[i].score > seats[lead].score:
			lead = i
	var col: Color = Style.SIN_COLORS[seats[cur].sin]
	var bust := moment == "bust"
	var live: bool = cur == me and moment == "decision"
	var band := track == "band"
	_rect(Rect2(Vector2.ZERO, vp), BLACK)

	# Bottom up: the near edge, seals, stake, dice; then the page round them.
	var pb: float = vp.y - safe.y - 12.0
	var px0 := 24.0
	var px1: float = vp.x - 24.0
	var sy: float = pb - EDGE - SEAL
	var stake_size: int = int(lerpf(120.0, 190.0, clampf(points / 600.0, 0.0, 1.0)))  # grows as dice score
	var stake_h: float = stake_size * 1.45  # Cinzel's line box
	var stake_top: float = sy - 8.0 - stake_h
	var col_w: float = (LANES * LANE + 40.0) if not band else 0.0  # the margin track's column
	var dl: float = px0 + 40.0 + col_w
	var dw: float = px1 - 40.0 - dl
	var dn: int = maxi(faces.size(), 1)
	var ds: float = minf(186.0, (dw - (dn - 1) * 18.0) / dn)
	var dy: float = stake_top - 56.0 - ds
	var band_h: float = LANES * LANE + 70.0 if band else 0.0
	var want_top: float = dy - 150.0 - band_h
	if not band:  # the margin track wants length for seven markers, ending above the stake
		want_top = minf(want_top, stake_top - 40.0 - 7.0 * LANE * 0.75 - 130.0)
	# Windows above the page: base width, the active one twice it.
	var n := seats.size()
	var bw: float = (vp.x - 2.0 * SIDE - (n - 1) * WIN_GAP) / (n + 1)
	var wh_active: float = 2.0 * bw * WIN_RATIO
	var wy_min: float = safe.x + 20.0
	var pt: float = maxf(want_top, wy_min + wh_active + 56.0)
	pt = minf(pt, dy - 60.0 - band_h)  # never squeeze the dice
	var room: float = pt - 56.0 - wy_min  # if the windows don't fit, they shrink
	var k: float = minf(1.0, room / wh_active)
	var pg := Rect2(px0, pt, px1 - px0, pb - pt)

	# Windows, bottoms on one line just above the page.
	var wb: float = pt - 56.0
	var x := SIDE + (vp.x - 2.0 * SIDE - ((n + 1) * bw + (n - 1) * WIN_GAP) * k) / 2.0
	var wr := Rect2()
	for i in n:
		var w: float = bw * k * (2.0 if i == cur else 1.0)
		var h: float = w * WIN_RATIO
		var r := Rect2(x, wb - h, w, h)
		x += w + WIN_GAP * k
		var t := TextureRect.new()
		t.texture = Art.window_crop(seats[i].sin, WIN_RATIO, Tuning.WINDOW_CROP_TOP.get(seats[i].sin, 0.0))
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		t.position = r.position
		t.size = r.size
		t.modulate = Color.WHITE if i == cur else Color(0.09, 0.08, 0.09)
		add_child(t)
		if i == cur:
			wr = r
		if i == me:  # yours: a crimson bar under it
			_rect(Rect2(r.get_center().x - w * 0.2, r.end.y + 8, w * 0.4, 10), CRIMSON)
		if moment == "rival" and i == cur:  # a rival's Strikes this turn: crimson marks under its window
			for s in 3:
				_rect(Rect2(r.get_center().x + (s - 1.5) * 46.0 + 4.0, r.end.y + 24, 34, 24), CRIMSON if s < strikes else Color(BONE, 0.2))

	# The page, lit in a pool round the dice and decision, falling to shadow at its edges.
	_rect(pg, PARCH)
	var pool_c := Vector2((dl + dw / 2.0 - pg.position.x) / pg.size.x, (stake_top - pg.position.y) / pg.size.y)
	var shade := TextureRect.new()
	var g := GradientTexture2D.new()
	g.fill = GradientTexture2D.FILL_RADIAL
	g.fill_from = pool_c
	g.fill_to = pool_c + Vector2(0.0, 0.62)
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	grad.colors = PackedColorArray([Color(BLACK, 0.0), Color(BLACK, 0.45), Color(BLACK, 0.88)])
	g.gradient = grad
	g.width = 256
	g.height = 256
	shade.texture = g
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.position = pg.position
	shade.size = pg.size
	add_child(shade)
	# Light through the active window across the gap and onto the page, in its colour.
	var shaft := Polygon2D.new()
	var sy1: float = pg.position.y + minf(pg.size.y * 0.45, 600.0)
	shaft.polygon = PackedVector2Array([Vector2(wr.position.x, wr.end.y), Vector2(wr.end.x, wr.end.y),
		Vector2(minf(wr.end.x + 200.0, pg.end.x), sy1), Vector2(maxf(wr.position.x - 200.0, pg.position.x), sy1)])
	shaft.vertex_colors = PackedColorArray([Color(col, 0.3), Color(col, 0.3), Color(col, 0.0), Color(col, 0.0)])
	add_child(shaft)

	# Score track.
	var order := range(n)
	order.sort_custom(func(a, b): return seats[a].score < seats[b].score)
	if band:
		var ax0: float = pg.position.x + 90.0
		var ax1: float = pg.end.x - 200.0
		var ay: float = pg.position.y + 50.0
		_line([Vector2(ax0, ay), Vector2(ax1, ay)], INK, 6.0)
		for q in [0.25, 0.5, 0.75]:
			var qx: float = lerpf(ax0, ax1, q)
			_line([Vector2(qx, ay - 14), Vector2(qx, ay + 14)], INK, 4.0)
		_goal(Vector2(ax1, ay), true)
		var placed := _place(order, ax1 - ax0, ax1 - ax0 - MARK / 2.0 - 24.0)
		var cs := {}
		for i in placed:  # ticks and leader lines first, all markers over them
			var along: float = ax0 + placed[i].x
			var c := Vector2(along, ay + 30.0 + MARK / 2.0 + placed[i].y * LANE)
			var true_x: float = ax0 + (ax1 - ax0) * clampf(seats[i].score / GOAL, 0.0, 1.0)
			_line([Vector2(true_x, ay - 10), Vector2(true_x, ay + 10)], INK, 8.0)
			if absf(true_x - along) > 2.0 or placed[i].y > 0:
				_line([Vector2(true_x, ay + 10), c], Color(INK, 0.6), 3.0)
			cs[i] = c
		for i in cs:
			_marker(cs[i], i, me, lead, col)
	else:
		var tx: float = pg.position.x + 40.0
		var t0: float = stake_top - 40.0 - MARK / 2.0
		var t1: float = pg.position.y + 120.0
		_line([Vector2(tx, t0), Vector2(tx, t1)], INK, 6.0)
		for q in [0.25, 0.5, 0.75]:
			var qy: float = lerpf(t0, t1, q)
			_line([Vector2(tx - 14, qy), Vector2(tx + 14, qy)], INK, 4.0)
		_goal(Vector2(tx, t1), false)
		var placed := _place(order, t0 - t1, t0 - t1 - MARK / 2.0 - 60.0)
		var cs := {}
		for i in placed:  # ticks and leader lines first, all markers over them
			var along: float = t0 - placed[i].x
			var c := Vector2(tx + 30.0 + MARK / 2.0 + placed[i].y * LANE, along)
			var true_y: float = t0 - (t0 - t1) * clampf(seats[i].score / GOAL, 0.0, 1.0)
			_line([Vector2(tx - 10, true_y), Vector2(tx + 10, true_y)], INK, 8.0)
			if absf(true_y - along) > 2.0 or placed[i].y > 0:
				_line([Vector2(tx + 10, true_y), c], Color(INK, 0.6), 3.0)
			cs[i] = c
		for i in cs:
			_marker(cs[i], i, me, lead, col)

	# The jester in the page's top-right corner (below the band); at a bust he leans in.
	var js: float = 170.0 if bust else 130.0
	var jest := _ink_figure(Art.MARGINALIA.jester[0], Rect2(pg.end.x - js - 20.0, pg.position.y + band_h + 16.0, js, js))
	jest.pivot_offset = jest.size / 2.0
	jest.rotation = deg_to_rad(-14.0) if bust else 0.0

	# Dice. Under each: gold if it scores, crimson if a Strike, nothing if dead (paint onto the dice later).
	var dx: float = dl + (dw - (dn * ds + (dn - 1) * 18.0)) / 2.0
	for d in faces.size():
		var f := int(faces[d])
		var die := Die.new(f, int(ds), d)
		die.position = Vector2(dx + d * (ds + 18.0), dy)
		die.size = Vector2(ds, ds)
		add_child(die)
		var mark: Color = GOLD if f >= 4 else (CRIMSON if f <= 2 else Color(0, 0, 0, 0))
		_rect(Rect2(die.position.x + ds * 0.15, dy + ds + 12.0, ds * 0.7, 10.0), mark)

	# Seals under the thumbs.
	var bank := _seal("Bank", Vector2(px0 + 36.0, sy), GOLD, INK, live)
	var throw := _seal("Throw", Vector2(px1 - 36.0 - SEAL, sy), CRIMSON, BONE, live)
	if not live:
		bank.modulate = Color(1, 1, 1, 0.35)
		throw.modulate = Color(1, 1, 1, 0.35)
	# The stake: one gold numeral directly above Bank (what Bank keeps). A bust blots it.
	var bc: float = bank.position.x + SEAL / 2.0
	var num := _label(str(points), stake_size, GOLD, INK)
	num.size = Vector2(560, stake_h)
	num.position = Vector2(maxf(px0 + 70.0, bc - 280.0), stake_top)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if bc - 280.0 < px0 + 70.0 else HORIZONTAL_ALIGNMENT_CENTER
	if bust:  # the blot covers the figure itself
		var tw: float = Style.NUMERAL.get_string_size(str(points), HORIZONTAL_ALIGNMENT_LEFT, -1, stake_size).x
		var tx0: float = num.position.x if num.horizontal_alignment == HORIZONTAL_ALIGNMENT_LEFT else num.position.x + (num.size.x - tw) / 2.0
		var rr := Vector2((tw / 2.0 + 28.0) / 0.91, stake_size * 0.64)  # the whole figure and its ink edge, at the blot's narrowest
		_blot(Vector2(tx0 + tw / 2.0, stake_top + stake_h / 2.0), rr)

	# The three Strike candles, large, on my edge between the seals: lit, or snuffed with a crimson
	# cap and a thread of smoke. On a rival's turn mine stand lit and wait.
	var struck: int = (3 if bust else strikes) if cur == me else 0
	var cw: float = 3.0 * CANDLE.x + 2.0 * CANDLE_GAP
	var cl: float = (bank.position.x + SEAL + throw.position.x) / 2.0 - cw / 2.0
	var ct: float = pb - EDGE - CANDLE.y
	for c in 3:
		var p := Vector2(cl + c * (CANDLE.x + CANDLE_GAP), ct)
		_rect(Rect2(p, CANDLE), BONE)
		if c >= 3 - struck:
			_rect(Rect2(p, Vector2(CANDLE.x, 26)), CRIMSON)
			_line([p + Vector2(CANDLE.x / 2.0, -8), p + Vector2(CANDLE.x / 2.0 + 14, -40), p + Vector2(CANDLE.x / 2.0 - 6, -72)], Color(INK, 0.55), 5.0)
		else:
			var glow := TextureRect.new()  # candlelight
			glow.texture = Art.soft_dot(64, Color("ffcf7a"))
			glow.material = Art.additive()
			glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			glow.size = Vector2(170, 170)
			glow.position = p + Vector2(CANDLE.x / 2.0, -40.0) - glow.size / 2.0
			glow.modulate.a = 0.35
			add_child(glow)
			_rect(Rect2(p + Vector2(CANDLE.x / 2.0 - 3, -14), Vector2(6, 16)), INK)  # wick
			_flame(p + Vector2(CANDLE.x / 2.0, -12.0), 0, 2.0)
	_ink_figure(Art.MARGINALIA.skeleton[0], Rect2(cl + cw - 36.0, ct - 118.0, 100, 118))
	# Throw's risk: a small candle on top of the Throw seal, its flame calm, restless or guttering.
	var rp := Vector2(throw.position.x + SEAL / 2.0 - 15.0, sy - 84.0)
	_rect(Rect2(rp, Vector2(30, 80)), BONE)
	_flame(rp + Vector2(15, -4), clampi(strikes, 0, 2), 1.0)


## Places each seat's marker on a track of `length` px: as near its score as it can be, in whichever
## lane lets it sit nearest, never closer than LANE to the one before it in that lane.
## No marker goes past `cap` (clear of the goal mark). ## Returns {seat: Vector2(px along, lane)}.
func _place(order: Array, length: float, cap: float) -> Dictionary:
	var last := []
	for l in LANES:
		last.append(-INF)
	var out := {}
	for i in order:
		var want: float = length * clampf(seats[i].score / GOAL, 0.0, 1.0)
		var best := 0
		var best_at := INF
		for l in LANES:
			var at: float = minf(maxf(want, last[l] + LANE), cap)
			if at < best_at - 0.5:
				best_at = at
				best = l
		last[best] = best_at
		out[i] = Vector2(best_at, best)
	# Pushed past the cap: walk each lane back from the top so none overlaps (short tracks, small screens).
	var next := []
	for l in LANES:
		next.append(INF)
	for j in range(order.size() - 1, -1, -1):
		var i = order[j]
		var l := int(out[i].y)
		var at: float = minf(out[i].x, next[l] - LANE)
		out[i] = Vector2(at, l)
		next[l] = at
	return out


## A track marker (placeholder for the woodcut figure): ink disc with the Sin's initial. Yours is
## crimson with a bone ring; the active rival's is its glass colour; the leader wears a gold ring
## and a gold crown.
func _marker(c: Vector2, i: int, me: int, lead: int, col: Color) -> void:
	var r: float = MARK / 2.0
	var fill: Color = CRIMSON if i == me else (col if i == cur else INK)
	if i == lead:
		_disc(c, r + 12.0, GOLD, INK)
	elif i == me:
		_disc(c, r + 10.0, BONE, INK)
	_disc(c, r, fill, INK)
	if i == lead:
		var p := Polygon2D.new()
		var top := c - Vector2(0, r + 10.0)
		p.polygon = PackedVector2Array([top + Vector2(-30, 0), top + Vector2(-34, -34), top + Vector2(-14, -16),
			top + Vector2(0, -40), top + Vector2(14, -16), top + Vector2(34, -34), top + Vector2(30, 0)])
		p.color = GOLD
		add_child(p)
	var l := _label(seats[i].sin.substr(0, 1), 70, BONE, INK, true)
	l.position = c - Vector2(r, r) - Vector2(0, 14)
	l.size = Vector2(MARK, MARK)


## The goal: a thick gold bar across the track's end, 1000 beside it.
func _goal(at: Vector2, across: bool) -> void:
	if across:
		_line([at + Vector2(0, -36), at + Vector2(0, 36)], GOLD, 16.0, INK)
		var l := _label("1000", 52, GOLD, INK)
		l.position = at + Vector2(14, -34)
		l.size = Vector2(140, 64)
	else:
		_line([at + Vector2(-30, 0), at + Vector2(LANES * LANE, 0)], GOLD, 16.0, INK)
		var l := _label("1000", 52, GOLD, INK)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		l.position = at + Vector2(LANES * LANE + 16.0, -34)
		l.size = Vector2(170, 64)


func _rect(r: Rect2, c: Color) -> ColorRect:
	var cr := ColorRect.new()
	cr.position = r.position
	cr.size = r.size
	cr.color = c
	cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cr)
	return cr


func _line(pts: Array, c: Color, w: float, edge := Color(0, 0, 0, 0)) -> void:
	if edge.a > 0.0:  # an ink edge under gold, so it reads on parchment
		_line(pts, edge, w + 6.0)
	var ln := Line2D.new()
	ln.points = PackedVector2Array(pts)
	ln.width = w
	ln.default_color = c
	ln.begin_cap_mode = Line2D.LINE_CAP_ROUND
	ln.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(ln)


func _disc(c: Vector2, r: float, fill: Color, edge: Color) -> void:
	if edge.a > 0.0:
		_disc(c, r + 5.0, edge, Color(0, 0, 0, 0))
	var p := Polygon2D.new()
	var pts := PackedVector2Array()
	for k in 40:
		pts.append(c + Vector2.from_angle(TAU * k / 40.0) * r)
	p.polygon = pts
	p.color = fill
	add_child(p)


func _label(text: String, size: int, c: Color, outline: Color, blackletter := false) -> Label:
	var l := Style.label(text, size, c, blackletter, 10 if outline.a > 0.0 else 0)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF  # one line; sizes below are set to fit
	if text.is_valid_int():  # numbers in Cinzel (Style.NUMERAL), never the old-style Fell figures
		l.add_theme_font_override("font", Style.NUMERAL)
	if outline.a > 0.0:
		l.add_theme_color_override("font_outline_color", outline)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(l)
	return l


## A flat flame: 0 calm (tall, still, gold), 1 restless (wider, leaning), 2 guttering (low, crimson).
func _flame(base: Vector2, risk: int, s: float) -> void:
	var h: float = [46.0, 40.0, 20.0][risk] * s
	var w: float = [14.0, 22.0, 16.0][risk] * s
	var lean: float = [0.0, 12.0, -4.0][risk] * s
	var p := Polygon2D.new()
	p.polygon = PackedVector2Array([base + Vector2(-w / 2.0, 0), base + Vector2(-w * 0.55, -h * 0.35),
		base + Vector2(lean, -h), base + Vector2(w * 0.55, -h * 0.35), base + Vector2(w / 2.0, 0)])
	p.color = CRIMSON if risk == 2 else GOLD
	add_child(p)


## A marginalia figure reduced to its ink lines (dark strokes kept as flat ink, colour and parchment
## dropped): a placeholder for the one-weight woodcut line.
func _ink_figure(tex: Texture2D, r: Rect2) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.position = r.position
	t.size = r.size
	t.material = _ink_lines()
	add_child(t)
	return t


## A seal: a flat disc with its word (Bank gold leaf, Throw crimson).
func _seal(word: String, pos: Vector2, fill: Color, ink: Color, live: bool) -> Button:
	var b := Button.new()
	for st in ["normal", "hover", "pressed", "disabled", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = fill.darkened(0.15) if st == "pressed" else fill
		sb.set_corner_radius_all(int(SEAL))
		sb.set_border_width_all(6)
		sb.border_color = INK
		b.add_theme_stylebox_override(st, sb)
	b.text = word
	b.add_theme_font_override("font", Style.BLACKLETTER)
	b.add_theme_font_size_override("font_size", 64)
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color", "font_focus_color"]:
		b.add_theme_color_override(k, ink)
	b.size = Vector2(SEAL, SEAL)
	b.custom_minimum_size = b.size
	b.position = pos
	b.disabled = not live
	b.focus_mode = Control.FOCUS_NONE
	add_child(b)
	return b


## Spilled ink over the stake: a flat irregular blot and two drops.
func _blot(c: Vector2, rr: Vector2) -> void:
	var pts := PackedVector2Array()
	for k in 28:
		var a := TAU * k / 28.0
		var w := 1.0 + 0.06 * sin(a * 3.0 + 1.3) + 0.03 * sin(a * 7.0)  # never inside the figure it covers
		pts.append(c + Vector2(cos(a) * rr.x, sin(a) * rr.y) * w)
	var p := Polygon2D.new()
	p.polygon = pts
	p.color = INK
	add_child(p)
	for k in 6:
		var a := TAU * k / 6.0 + 0.4
		if k > 1:  # two drops only, down and to the right (clear of the page edge and the dice)
			break
		_disc(c + Vector2.from_angle(a) * rr * 1.25, 8.0 + (k * 5) % 10, INK, Color(0, 0, 0, 0))


static var _ink_mat: ShaderMaterial
static func _ink_lines() -> ShaderMaterial:
	if _ink_mat == null:
		var sh := Shader.new()
		sh.code = "shader_type canvas_item;\nuniform vec4 ink : source_color = vec4(0.165, 0.094, 0.063, 1.0);\nvoid fragment() {\n\tfloat l = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));\n\tfloat e = step(0.04, UV.x) * step(UV.x, 0.96) * step(0.04, UV.y) * step(UV.y, 0.96);\n\tCOLOR = vec4(ink.rgb, e * COLOR.a * (1.0 - smoothstep(0.28, 0.4, l)));\n}\n"
		_ink_mat = ShaderMaterial.new()
		_ink_mat.shader = sh
	return _ink_mat
