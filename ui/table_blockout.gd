## Phase 8 table, BLOCKOUT round 3 (Ben, 2026-11-15): flat shapes in the five-colour palette, under
## the restraint rules (Docs/UXPlan.md). Only the Sins' glass and the dice carry detail; everything
## else is a flat shape or plain ink line, a placeholder for the woodcut-ink pieces still to be drawn.
## Static: one moment drawn from a fixture (tools/fixture.gd, screen "table"); nothing animates, no
## rules run, not wired into play.
##   Top is them, bottom is me. Windows across the top, the active one drawn twice the width and lit;
##   on a rival's turn its stake and Strike marks sit under its window in its light, and my whole near
##   edge dims. Under the windows the score track runs the page's full width, 0 to 1000, each Sin's
##   ink sigil on the line at its true score (close scores nudged up or down a little).
##   Built bottom-up round my decision: Bank and Throw at the bottom, my three Strike candles between
##   them (their flames steady, restless or guttering show the risk), the stake in gold directly above
##   Bank, the dice above that. The page is lit in a pool round the dice and decision; the desk is dark.
extends Control

const Art = preload("res://ui/art.gd")
const Style = preload("res://ui/style.gd")
const Tuning = preload("res://ui/tuning.gd")
const Die = preload("res://ui/widgets/die.gd")
const INK_EMBLEM = preload("res://ui/shaders/ink_emblem.gdshader")

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
const UNDER_WIN := 150.0   # the dark gap under the windows: a rival's stake, a Sin's spoken line
const GOAL := 1000.0       # first to 1000 wins
const SEAL := 236.0        # Bank and Throw, px (86 pt)
const EDGE := 40.0         # seals and candles stand this far in from the page's near edge
const CANDLE := Vector2(84, 300)
const CANDLE_GAP := 30.0
const MARK := 124.0        # track marker, px (45 pt)
const NUDGE := 34.0        # close scores: one marker this far above the line, the next below
const DIE_GAP := 18.0

## seats: [{sin, score, you, marks {Sin: n}, pend [cost]}], cur: active seat, faces: dice on the page,
## points: at stake, strikes: 0-3, moment: "decision" | "rival" | "bust",
## speak: {seat, line} a Sin's spoken line, ability: die index my Sin's ability just changed (-1 none),
## safe: Vector2(top, bottom) insets in px.
var seats: Array = []
var cur := 0
var faces: Array = []
var points := 0
var strikes := 0
var moment := "decision"
var speak := {}
var ability := -1
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
	var mine: bool = cur == me
	var live: bool = mine and moment == "decision"
	_rect(Rect2(Vector2.ZERO, vp), BLACK)

	# Bottom up: my near edge, seals, stake, dice; then the track band; then the page round them.
	var pb: float = vp.y - safe.y - 12.0
	var px0 := 24.0
	var px1: float = vp.x - 24.0
	var sy: float = pb - EDGE - SEAL
	var stake_size: int = int(lerpf(120.0, 190.0, clampf(points / 600.0, 0.0, 1.0)))  # grows as dice score
	var stake_h: float = stake_size * 1.45  # Cinzel's line box
	var stake_top: float = sy - 8.0 - stake_h
	var dl: float = px0 + 40.0
	var dw: float = px1 - 40.0 - dl
	var dn: int = maxi(faces.size(), 1)
	var rows: int = 1 if dn <= 6 else 2
	var per: int = ceili(float(dn) / rows)
	var ds: float = minf(186.0, (dw - (per - 1) * DIE_GAP) / per)
	var dy: float = stake_top - 56.0 - rows * ds - (rows - 1) * 34.0
	var band_h: float = MARK + 2.0 * NUDGE + 110.0
	var n := seats.size()
	var bw: float = (vp.x - 2.0 * SIDE - (n - 1) * WIN_GAP) / (n + 1)
	var wh_active: float = 2.0 * bw * WIN_RATIO
	var wy_min: float = safe.x + 20.0
	var pt: float = maxf(dy - 70.0 - band_h, wy_min + wh_active + UNDER_WIN)
	pt = minf(pt, dy - 40.0 - band_h)  # never squeeze the dice
	var k: float = minf(1.0, (pt - UNDER_WIN - wy_min) / wh_active)  # windows shrink if they don't fit
	var pg := Rect2(px0, pt, px1 - px0, pb - pt)

	# Windows, bottoms on one line above the gap.
	var wb: float = pt - UNDER_WIN
	var x := SIDE + (vp.x - 2.0 * SIDE - ((n + 1) * bw + (n - 1) * WIN_GAP) * k) / 2.0
	var wr := Rect2()
	var win_rects := []
	for i in n:
		var w: float = bw * k * (2.0 if i == cur else 1.0)
		var h: float = w * WIN_RATIO
		var r := Rect2(x, wb - h, w, h)
		win_rects.append(r)
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

	# Light through the active window, down across the gap and onto the page, in its colour.
	var shaft := Polygon2D.new()
	var sy1: float = pg.position.y + minf(pg.size.y * 0.45, 600.0)
	shaft.polygon = PackedVector2Array([Vector2(wr.position.x, wr.end.y), Vector2(wr.end.x, wr.end.y),
		Vector2(minf(wr.end.x + 200.0, pg.end.x), sy1), Vector2(maxf(wr.position.x - 200.0, pg.position.x), sy1)])
	shaft.vertex_colors = PackedColorArray([Color(col, 0.3), Color(col, 0.3), Color(col, 0.0), Color(col, 0.0)])

	# The page, lit in a pool round the dice and decision, falling to shadow at its edges.
	_rect(pg, PARCH)
	var pool_c := Vector2(0.5, (stake_top - pg.position.y) / pg.size.y)
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
	add_child(shaft)

	# A rival's turn: its stake and Strike marks under its window, in its light.
	if not mine:
		var under: float = wr.end.y + 18.0
		var rs := _label(str(points), 92, GOLD, INK)
		rs.size = Vector2(260, 92 * 1.45)
		rs.position = Vector2(clampf(wr.get_center().x - 130.0 - 60.0, px0 + 20.0, px1 - 400.0), under - 22.0)
		for s in 3:
			_rect(Rect2(rs.position.x + 270.0 + s * 46.0, under + 30.0, 32, 48), CRIMSON if s < strikes else Color(BONE, 0.22))
	# A Sin's spoken line, under its window.
	if not speak.is_empty():
		var sr: Rect2 = win_rects[int(speak.seat)]
		var line := _label(str(speak.line), 60, BONE, BLACK, true)
		line.size = Vector2(620, 84)
		line.position = Vector2(clampf(sr.get_center().x - 310.0, px0 + 20.0, px1 - 640.0), sr.end.y + 34.0)
		_line([Vector2(sr.get_center().x, sr.end.y + 6), Vector2(sr.get_center().x, sr.end.y + 30)], BONE, 4.0)

	# Score track: the page's full width, 0 at the left, 1000 at the right; sigils on the line.
	var ax0: float = pg.position.x + 80.0
	var ax1: float = pg.end.x - 80.0
	var ay: float = pg.position.y + 70.0 + NUDGE + MARK / 2.0
	_line([Vector2(ax0, ay), Vector2(ax1, ay)], INK, 6.0)
	for q in [0.25, 0.5, 0.75]:
		var qx: float = lerpf(ax0, ax1, q)
		_line([Vector2(qx, ay - 14), Vector2(qx, ay + 14)], INK, 4.0)
	_line([Vector2(ax0, ay - 18), Vector2(ax0, ay + 18)], INK, 6.0)
	_line([Vector2(ax1, ay - 40), Vector2(ax1, ay + 40)], GOLD, 16.0, INK)
	var gl := _label("1000", 46, GOLD, INK)
	gl.size = Vector2(150, 60)
	gl.position = Vector2(ax1 - 75.0, ay - 40.0 - 66.0)
	var order := range(n)
	order.sort_custom(func(a, b): return seats[a].score < seats[b].score)
	var at := {}
	var prev_x := -INF
	var prev_off := 0.0
	for i in order:
		var mx: float = lerpf(ax0, ax1, clampf(seats[i].score / GOAL, 0.0, 1.0))
		var off := 0.0
		if mx - prev_x < MARK * 0.9:  # close to the one before: nudge the other way
			off = NUDGE if prev_off <= 0.0 else -NUDGE
		at[i] = Vector2(mx, ay + off)
		prev_x = mx
		prev_off = off
	var draw := order.filter(func(i): return i != me and i != lead)
	if lead != me:
		draw.append(lead)
	draw.append(me)
	for i in draw:
		_marker(at[i], i, me, lead)

	# The jester, top right of the page under the track; at a bust he leans in.
	var js: float = 170.0 if bust else 130.0
	var jest := _ink_figure(Art.MARGINALIA.jester[0], Rect2(pg.end.x - js - 20.0, pg.position.y + band_h - 10.0, js, js))
	jest.pivot_offset = jest.size / 2.0
	jest.rotation = deg_to_rad(-14.0) if bust else 0.0

	# Dice, one or two rows. Under each: gold if it scores, crimson if a Strike, nothing if dead.
	for d in faces.size():
		var row: int = d / per
		var in_row: int = mini(per, dn - row * per)
		var rx: float = dl + (dw - (in_row * ds + (in_row - 1) * DIE_GAP)) / 2.0
		var p := Vector2(rx + (d % per) * (ds + DIE_GAP), dy + row * (ds + 34.0))
		var f := int(faces[d])
		if d == ability:  # my Sin's ability just changed this die: a ring of my glass colour, my sigil above
			_disc(p + Vector2(ds, ds) / 2.0, ds * 0.72, Color(Style.SIN_COLORS[seats[me].sin], 0.55), Color(0, 0, 0, 0))
			_sigil(seats[me].sin, Rect2(p + Vector2(ds * 0.2, -ds * 0.62), Vector2(ds * 0.6, ds * 0.6)), INK)
		var die := Die.new(f, int(ds), d)
		die.position = p
		die.size = Vector2(ds, ds)
		add_child(die)
		var mk: Color = GOLD if f >= 4 else (CRIMSON if f <= 2 else Color(0, 0, 0, 0))
		_rect(Rect2(p.x + ds * 0.15, p.y + ds + 10.0, ds * 0.7, 9.0), mk)

	# My near edge. On a rival's turn all of it dims.
	var near := Control.new()
	near.mouse_filter = Control.MOUSE_FILTER_IGNORE
	near.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(near)
	if not mine:
		near.modulate = Color(1, 1, 1, 0.38)
	var bank := _seal(near, "Bank", Vector2(px0 + 36.0, sy), GOLD, INK, live)
	var throw := _seal(near, "Throw", Vector2(px1 - 36.0 - SEAL, sy), CRIMSON, BONE, live)
	if mine and not live:
		bank.modulate = Color(1, 1, 1, 0.35)
		throw.modulate = Color(1, 1, 1, 0.35)
	# The stake: one gold numeral directly above Bank (what Bank keeps). A bust blots it.
	var c_left: float = (px0 + 36.0 + SEAL + px1 - 36.0 - SEAL) / 2.0 - (3.0 * CANDLE.x + 2.0 * CANDLE_GAP) / 2.0
	while stake_size > 90 and Style.NUMERAL.get_string_size(str(points), HORIZONTAL_ALIGNMENT_LEFT, -1, stake_size).x > c_left - 40.0 - (px0 + 70.0):
		stake_size -= 4  # never under the candles
	if mine:
		var bc: float = bank.position.x + SEAL / 2.0
		var num := _label(str(points), stake_size, GOLD, INK, false, near)
		num.size = Vector2(560, stake_h)
		var left: bool = bc - 280.0 < px0 + 70.0
		num.position = Vector2(px0 + 70.0 if left else bc - 280.0, stake_top)
		num.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if left else HORIZONTAL_ALIGNMENT_CENTER
		if bust:  # the blot covers the figure itself
			var tw: float = Style.NUMERAL.get_string_size(str(points), HORIZONTAL_ALIGNMENT_LEFT, -1, stake_size).x
			var tx0: float = num.position.x if left else num.position.x + (num.size.x - tw) / 2.0
			_blot(near, Vector2(tx0 + tw / 2.0, stake_top + stake_h / 2.0), Vector2((tw / 2.0 + 28.0) / 0.91, stake_size * 0.64))
	# Marks I hold and costs coming: sigil chips and a crimson cost, above Throw.
	var marks: Dictionary = seats[me].get("marks", {})
	var pend: Array = seats[me].get("pend", [])
	var chip := 84.0
	var cy: float = sy - 24.0 - chip
	var cx: float = throw.position.x + SEAL - chip
	for s in marks:
		var cr := Rect2(cx, cy, chip, chip)
		_disc(cr.get_center(), chip / 2.0, BONE, INK, near)
		_sigil(s, cr.grow(-8.0), INK, near)
		cx -= chip + 14.0
	var ty: float = cy - 84.0
	for cost in pend:  # crimson on a bone tag, so it reads in the page's shadow
		var txt := _cost_text(str(cost))
		var tw: float = Style.NUMERAL.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 52).x + 36.0
		var tag := Rect2(throw.position.x + SEAL - tw, ty, tw, 70)
		_rect(tag, BONE, near)
		var cl := _label(txt, 52, CRIMSON, Color(0, 0, 0, 0), false, near)
		cl.add_theme_font_override("font", Style.NUMERAL)  # a count: lining figures
		cl.position = tag.position
		cl.size = tag.size
		ty -= 84.0
	# My three Strike candles, large, on my edge between the seals: lit (the flame steady, restless or
	# guttering with the Strikes taken), or snuffed with a crimson cap and a thread of smoke.
	var struck: int = (3 if bust else strikes) if mine else 0
	var risk: int = clampi(strikes, 0, 2) if mine else 0
	var cw: float = 3.0 * CANDLE.x + 2.0 * CANDLE_GAP
	var c_l: float = (bank.position.x + SEAL + throw.position.x) / 2.0 - cw / 2.0
	var ct: float = pb - EDGE - CANDLE.y
	for c in 3:
		var p := Vector2(c_l + c * (CANDLE.x + CANDLE_GAP), ct)
		_rect(Rect2(p, CANDLE), BONE, near)
		if c >= 3 - struck:
			_rect(Rect2(p, Vector2(CANDLE.x, 26)), CRIMSON, near)
			_line([p + Vector2(CANDLE.x / 2.0, -8), p + Vector2(CANDLE.x / 2.0 + 14, -40), p + Vector2(CANDLE.x / 2.0 - 6, -72)], Color(INK, 0.55), 5.0, Color(0, 0, 0, 0), near)
		else:
			var glow := TextureRect.new()  # candlelight
			glow.texture = Art.soft_dot(64, Color("ffcf7a"))
			glow.material = Art.additive()
			glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			glow.size = Vector2(170, 170) * [1.0, 0.85, 0.6][risk]
			glow.position = p + Vector2(CANDLE.x / 2.0, -40.0) - glow.size / 2.0
			glow.modulate.a = 0.35
			near.add_child(glow)
			_rect(Rect2(p + Vector2(CANDLE.x / 2.0 - 3, -14), Vector2(6, 16)), INK, near)  # wick
			_flame(near, p + Vector2(CANDLE.x / 2.0, -12.0), risk, 2.0)
	_ink_figure(Art.MARGINALIA.skeleton[0], Rect2(c_l + cw - 36.0, ct - 118.0, 100, 118), near)


func _cost_text(cost: String) -> String:
	return {"die": "-1 die", "fewer": "-1 die", "strike": "+1 Strike", "bank": "-50"}.get(cost, cost)


## A track marker: the Sin's sigil in ink on a bone disc. Mine in crimson ink with a crimson ring;
## the leader wears a gold ring and a gold crown.
func _marker(c: Vector2, i: int, me: int, lead: int) -> void:
	var r: float = MARK / 2.0
	if i == lead:
		_disc(c, r + 12.0, GOLD, INK)
		var p := Polygon2D.new()
		var top := c - Vector2(0, r + 10.0)
		p.polygon = PackedVector2Array([top + Vector2(-30, 0), top + Vector2(-34, -34), top + Vector2(-14, -16),
			top + Vector2(0, -40), top + Vector2(14, -16), top + Vector2(34, -34), top + Vector2(30, 0)])
		p.color = GOLD
		add_child(p)
	_disc(c, r, BONE, CRIMSON if i == me else INK)
	_sigil(seats[i].sin, Rect2(c - Vector2(r, r) * 0.92, Vector2(r, r) * 1.84), CRIMSON if i == me else INK)


## The Sin's Accept-seal emblem as ink line (ui/shaders/ink_emblem.gdshader).
func _sigil(sname: String, r: Rect2, ink: Color, parent: Node = self) -> void:
	var t := TextureRect.new()
	t.texture = Art.emblem("accept_" + sname.to_lower())
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.position = r.position
	t.size = r.size
	var m := ShaderMaterial.new()
	m.shader = INK_EMBLEM
	m.set_shader_parameter("ink", ink)
	t.material = m
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(t)


func _rect(r: Rect2, c: Color, parent: Node = self) -> ColorRect:
	var cr := ColorRect.new()
	cr.position = r.position
	cr.size = r.size
	cr.color = c
	cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(cr)
	return cr


func _line(pts: Array, c: Color, w: float, edge := Color(0, 0, 0, 0), parent: Node = self) -> void:
	if edge.a > 0.0:  # an ink edge under gold, so it reads on parchment
		_line(pts, edge, w + 6.0, Color(0, 0, 0, 0), parent)
	var ln := Line2D.new()
	ln.points = PackedVector2Array(pts)
	ln.width = w
	ln.default_color = c
	ln.begin_cap_mode = Line2D.LINE_CAP_ROUND
	ln.end_cap_mode = Line2D.LINE_CAP_ROUND
	parent.add_child(ln)


func _disc(c: Vector2, r: float, fill: Color, edge: Color, parent: Node = self) -> void:
	if edge.a > 0.0:
		_disc(c, r + 5.0, edge, Color(0, 0, 0, 0), parent)
	var p := Polygon2D.new()
	var pts := PackedVector2Array()
	for k in 40:
		pts.append(c + Vector2.from_angle(TAU * k / 40.0) * r)
	p.polygon = pts
	p.color = fill
	parent.add_child(p)


func _label(text: String, size: int, c: Color, outline: Color, blackletter := false, parent: Node = self) -> Label:
	var l := Style.label(text, size, c, blackletter, 10 if outline.a > 0.0 else 0)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF  # one line; sizes below are set to fit
	if text.is_valid_int():  # numbers in Cinzel (Style.NUMERAL), never the old-style Fell figures
		l.add_theme_font_override("font", Style.NUMERAL)
	if outline.a > 0.0:
		l.add_theme_color_override("font_outline_color", outline)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	parent.add_child(l)
	return l


## A flat flame: 0 steady (tall, still, gold), 1 restless (wider, leaning), 2 guttering (low, crimson).
func _flame(parent: Node, base: Vector2, risk: int, s: float) -> void:
	var h: float = [46.0, 40.0, 20.0][risk] * s
	var w: float = [14.0, 22.0, 16.0][risk] * s
	var lean: float = [0.0, 12.0, -4.0][risk] * s
	var p := Polygon2D.new()
	p.polygon = PackedVector2Array([base + Vector2(-w / 2.0, 0), base + Vector2(-w * 0.55, -h * 0.35),
		base + Vector2(lean, -h), base + Vector2(w * 0.55, -h * 0.35), base + Vector2(w / 2.0, 0)])
	p.color = CRIMSON if risk == 2 else GOLD
	parent.add_child(p)


## A marginalia figure reduced to its ink lines (dark strokes kept as flat ink, colour and parchment
## dropped): a placeholder for the one-weight woodcut line.
func _ink_figure(tex: Texture2D, r: Rect2, parent: Node = self) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.position = r.position
	t.size = r.size
	t.material = _ink_lines()
	parent.add_child(t)
	return t


## A seal: a flat disc with its word (Bank gold leaf, Throw crimson).
func _seal(parent: Node, word: String, pos: Vector2, fill: Color, ink: Color, live: bool) -> Button:
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
	parent.add_child(b)
	return b


## Spilled ink over the stake: a flat irregular blot and two drops.
func _blot(parent: Node, c: Vector2, rr: Vector2) -> void:
	var pts := PackedVector2Array()
	for k in 28:
		var a := TAU * k / 28.0
		var w := 1.0 + 0.06 * sin(a * 3.0 + 1.3) + 0.03 * sin(a * 7.0)  # never inside the figure it covers
		pts.append(c + Vector2(cos(a) * rr.x, sin(a) * rr.y) * w)
	var p := Polygon2D.new()
	p.polygon = pts
	p.color = INK
	parent.add_child(p)
	for k in 2:  # down and to the right, clear of the page edge and the dice
		var a := TAU * k / 6.0 + 0.4
		_disc(c + Vector2.from_angle(a) * rr * 1.25, 8.0 + (k * 5) % 10, INK, Color(0, 0, 0, 0), parent)


static var _ink_mat: ShaderMaterial
static func _ink_lines() -> ShaderMaterial:
	if _ink_mat == null:
		var sh := Shader.new()
		sh.code = "shader_type canvas_item;\nuniform vec4 ink : source_color = vec4(0.165, 0.094, 0.063, 1.0);\nvoid fragment() {\n\tfloat l = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));\n\tfloat e = step(0.04, UV.x) * step(UV.x, 0.96) * step(0.04, UV.y) * step(UV.y, 0.96);\n\tCOLOR = vec4(ink.rgb, e * COLOR.a * (1.0 - smoothstep(0.28, 0.4, l)));\n}\n"
		_ink_mat = ShaderMaterial.new()
		_ink_mat.shader = sh
	return _ink_mat
