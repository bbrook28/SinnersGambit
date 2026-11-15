## Phase 8 table, BLOCKOUT (Ben, 2026-11-15): flat shapes in the five-colour palette, under the
## restraint rules (Docs/UXPlan.md). Only the Sins' glass and the dice carry detail; everything else
## is a flat shape or plain ink line, a placeholder for the woodcut-ink pieces still to be drawn
## (Docs/review/latest/packet.md lists them).
## Static: one moment drawn from a fixture (tools/fixture.gd, screen "table"); nothing animates, no
## rules run, not wired into play.
##   Windows across the top: the active Sin's glass lit, its colour falling on the page; the rest
##   near-black. A plain parchment page below. Its left edge is the score track (ink line, goal at
##   the top), a marker per Sin. Dice in the middle; this turn's points as gold tally marks and a big
##   gold numeral (a bust blots them). My three Strike candles on the near edge with the skeleton; the
##   jester in the top corner. Bank and Throw seals under the thumbs; beside Throw a candle whose
##   flame reads the risk.
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
const WIN_MAX_H := 0.2     # of the screen height
const TALLY_PER := 50      # points per gold tally mark
const GOAL := 1000.0       # first to 1000 wins
const SEAL := 236.0        # Bank and Throw, px (86 pt)
const CANDLE := Vector2(46, 150)

## seats: [{sin, score, you}], cur: active seat, faces: dice on the page, points: at stake,
## strikes: 0-3, moment: "decision" | "rival" | "bust", safe: Vector2(top, bottom) insets in px.
var seats: Array = []
var cur := 0
var faces: Array = []
var points := 0
var strikes := 0
var moment := "decision"
var safe := Vector2.ZERO


func build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vp := get_viewport_rect().size
	var me := 0
	for i in seats.size():
		if seats[i].get("you", false):
			me = i
	var col: Color = Style.SIN_COLORS[seats[cur].sin]
	_rect(Rect2(Vector2.ZERO, vp), BLACK)

	# Windows: the active one's glass lit, the rest near-black silhouettes.
	var n := seats.size()
	var ww: float = (vp.x - 2.0 * SIDE - (n - 1) * WIN_GAP) / n
	var wh: float = minf(ww * WIN_RATIO, vp.y * WIN_MAX_H)
	var wy: float = safe.x + 20.0
	var wr := Rect2()
	for i in n:
		var r := Rect2(SIDE + i * (ww + WIN_GAP), wy, ww, wh)
		var t := TextureRect.new()
		t.texture = Art.window_crop(seats[i].sin, wh / ww, Tuning.WINDOW_CROP_TOP.get(seats[i].sin, 0.0))
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		t.position = r.position
		t.size = r.size
		t.modulate = Color.WHITE if i == cur else Color(0.09, 0.08, 0.09)
		add_child(t)
		if i == cur:
			wr = r
		if i == me:  # yours: a crimson bar under it
			_rect(Rect2(r.get_center().x - ww * 0.2, r.end.y + 8, ww * 0.4, 8), CRIMSON)
		if moment == "rival" and i == cur:  # a rival's Strikes this turn: crimson ticks under its window
			for k in 3:
				var tw: float = minf(ww / 5.0, 30.0)
				_rect(Rect2(r.get_center().x + (k - 1.5) * tw * 1.4 + tw * 0.2, r.end.y + 26, tw, tw * 1.4),
					CRIMSON if k < strikes else Color(BONE, 0.18))

	# The page: plain parchment.
	var top: float = wy + wh + 64.0
	var bottom: float = vp.y - safe.y - 12.0
	var pg := Rect2(24, top, vp.x - 48, bottom - top)
	_rect(pg, PARCH)
	# Light through the active window falls across the page, in its colour.
	var shaft := Polygon2D.new()
	var sy1: float = pg.position.y + pg.size.y * 0.7
	shaft.polygon = PackedVector2Array([Vector2(wr.position.x, wr.end.y), Vector2(wr.end.x, wr.end.y),
		Vector2(minf(wr.end.x + 260.0, pg.end.x), sy1), Vector2(maxf(wr.position.x - 260.0, pg.position.x), sy1)])
	var c0 := Color(col, 0.34)
	var c1 := Color(col, 0.0)
	shaft.vertex_colors = PackedColorArray([c0, c0, c1, c1])
	add_child(shaft)

	# Score track: one ink line up the page's left edge, 0 at the bottom, the goal at the top.
	var tx: float = pg.position.x + 58.0
	var t0: float = pg.end.y - 40.0 - SEAL - 40.0
	var t1: float = pg.position.y + 110.0
	_line([Vector2(tx, t0), Vector2(tx, t1)], INK, 6.0)
	for q in [0.25, 0.5, 0.75]:
		var y: float = lerpf(t0, t1, q)
		_line([Vector2(tx - 14, y), Vector2(tx + 14, y)], INK, 4.0)
	_line([Vector2(tx - 26, t1), Vector2(tx + 26, t1)], GOLD, 10.0)
	var goal := _label("1000", 44, GOLD, INK)
	goal.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	goal.position = Vector2(tx - 32, t1 - 66)
	goal.size = Vector2(150, 56)
	var order := range(n)
	order.sort_custom(func(a, b): return seats[a].score < seats[b].score)
	var last_y := INF
	var lane := 0
	for i in order:
		var y: float = lerpf(t0, t1, clampf(float(seats[i].score) / GOAL, 0.0, 1.0))
		lane = lane + 1 if absf(y - last_y) < 70.0 else 0  # markers that would touch step right
		last_y = y
		var d: float = 76.0 if i == me else 66.0
		var fill: Color = col if i == cur else (CRIMSON if i == me else INK)
		var c := Vector2(tx + lane * 74.0, y)
		_disc(c, d / 2.0, fill, INK if i == cur else Color(0, 0, 0, 0))
		var l := _label(seats[i].sin.substr(0, 1), 46, BONE, INK, true)
		l.position = c - Vector2(d, d) / 2.0 - Vector2(0, 20)
		l.size = Vector2(d, d)

	# The jester in the top-right corner (ink silhouette); at a bust he leans in.
	var bust := moment == "bust"
	var js: float = 170.0 if bust else 130.0
	var jest := _ink_figure(Art.MARGINALIA.jester[0], Rect2(pg.end.x - js - 20.0, pg.position.y + 16.0, js, js))
	jest.pivot_offset = jest.size / 2.0
	jest.rotation = deg_to_rad(-14.0) if bust else 0.0

	# Dice on the page. Under each die: gold if it scores, crimson if it's a Strike, nothing if dead.
	var inner_l: float = tx + 120.0
	var inner_w: float = pg.end.x - 40.0 - inner_l
	var dn: int = maxi(faces.size(), 1)
	var ds: float = minf(150.0, (inner_w - (dn - 1) * 20.0) / dn)
	var dy: float = pg.position.y + 190.0
	var dx: float = inner_l + (inner_w - (dn * ds + (dn - 1) * 20.0)) / 2.0
	for k in faces.size():
		var f := int(faces[k])
		var die := Die.new(f, int(ds), k)
		die.position = Vector2(dx + k * (ds + 20.0), dy)
		die.size = Vector2(ds, ds)
		add_child(die)
		var mark: Color = GOLD if f >= 4 else (CRIMSON if f <= 2 else Color(0, 0, 0, 0))
		_rect(Rect2(die.position.x + ds * 0.15, dy + ds + 14.0, ds * 0.7, 10.0), mark)

	# Stakes: gold tally marks and the points in big gold numerals.
	var cx: float = inner_l + inner_w / 2.0
	var ty: float = dy + ds + 90.0
	var marks: int = ceili(float(points) / TALLY_PER)
	var groups: int = ceili(marks / 5.0)
	var gw := 150.0
	var x0: float = cx - (groups * gw - 40.0) / 2.0
	for m in marks:
		var gx: float = x0 + (m / 5) * gw
		var k: int = m % 5
		var jx := float((m * 7) % 5) - 2.0
		if k < 4:
			_line([Vector2(gx + k * 28.0 + jx, ty), Vector2(gx + k * 28.0 - jx, ty + 110)], GOLD, 12.0, INK)
		else:
			_line([Vector2(gx - 16.0, ty + 86), Vector2(gx + 100.0, ty + 22)], GOLD, 12.0, INK)
	var num := _label(str(points), 120, GOLD, INK)
	num.position = Vector2(cx - 260.0, ty + 124.0)
	num.size = Vector2(520, 150)
	if bust:
		_blot(Vector2(cx, ty + 60.0), maxf(groups * gw * 0.55, 150.0))

	# Near edge: Bank and Throw under the thumbs, my candles and the skeleton between them.
	var sy: float = pg.end.y - 40.0 - SEAL
	var live: bool = cur == me and moment == "decision"
	var bank := _seal("Bank", Vector2(pg.position.x + 36.0, sy), GOLD, INK, live)
	var throw := _seal("Throw", Vector2(pg.end.x - 36.0 - SEAL, sy), CRIMSON, BONE, live)
	# Three candles, one snuffed per Strike: a snuffed one keeps a crimson cap (Strikes are crimson).
	# On a rival's turn mine stand lit and wait.
	var mine_struck: int = (3 if bust else strikes) if cur == me else 0
	var cy: float = pg.end.y - 40.0 - CANDLE.y
	var c_l: float = vp.x / 2.0 - 1.5 * CANDLE.x - 30.0 + 50.0
	for k in 3:
		var p := Vector2(c_l + k * (CANDLE.x + 30.0), cy)
		_rect(Rect2(p, CANDLE), BONE)
		_rect(Rect2(p, Vector2(CANDLE.x, 3)), INK)
		if k >= 3 - mine_struck:
			_rect(Rect2(p - Vector2(0, 16), Vector2(CANDLE.x, 16)), CRIMSON)
		else:
			_flame(p + Vector2(CANDLE.x / 2.0, -6.0), 0)
	_ink_figure(Art.MARGINALIA.skeleton[0], Rect2(c_l - 150.0, pg.end.y - 40.0 - 170.0, 140, 170))
	# Throw's risk: the flame of the candle beside it burns calm, restless or guttering.
	var rp := Vector2(throw.position.x - 52.0, pg.end.y - 40.0 - 100.0)
	_rect(Rect2(rp, Vector2(34, 100)), BONE)
	_flame(rp + Vector2(17, -6), clampi(strikes, 0, 2))
	if not live:
		bank.modulate = Color(1, 1, 1, 0.35)
		throw.modulate = Color(1, 1, 1, 0.35)


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
	for k in 32:
		pts.append(c + Vector2.from_angle(TAU * k / 32.0) * r)
	p.polygon = pts
	p.color = fill
	add_child(p)


func _label(text: String, size: int, c: Color, outline: Color, blackletter := false) -> Label:
	var l := Style.label(text, size, c, blackletter, 10 if outline.a > 0.0 else 0)
	if text.is_valid_int():  # numbers in Cinzel (Style.NUMERAL), never the old-style Fell figures
		l.add_theme_font_override("font", Style.NUMERAL)
	if outline.a > 0.0:
		l.add_theme_color_override("font_outline_color", outline)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(l)
	return l


## A flat flame: 0 calm (tall, still, gold), 1 restless (wider, leaning), 2 guttering (low, crimson).
func _flame(base: Vector2, risk: int) -> void:
	var h: float = [46.0, 40.0, 20.0][risk]
	var w: float = [14.0, 22.0, 16.0][risk]
	var lean: float = [0.0, 12.0, -4.0][risk]
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
	b.add_theme_font_override("font", Style.label("x", 10, ink, true).get_theme_font("font"))
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


## Spilled ink over the stakes: a flat irregular blot and a few drops.
func _blot(c: Vector2, r: float) -> void:
	var pts := PackedVector2Array()
	for k in 28:
		var a := TAU * k / 28.0
		var w := 1.0 + 0.22 * sin(a * 3.0 + 1.3) + 0.12 * sin(a * 7.0)
		pts.append(c + Vector2(cos(a) * r * 1.3, sin(a) * r * 0.6) * w)
	var p := Polygon2D.new()
	p.polygon = pts
	p.color = INK
	add_child(p)
	for k in 6:
		if sin(TAU * k / 6.0 + 0.4) < -0.5:
			continue  # no drops upward, onto the dice
		var dc := c + Vector2.from_angle(TAU * k / 6.0 + 0.4) * Vector2(r * 1.6, r * 0.75)
		_disc(dc, 10.0 + (k * 5) % 14, INK, Color(0, 0, 0, 0))


static var _ink_mat: ShaderMaterial
static func _ink_lines() -> ShaderMaterial:
	if _ink_mat == null:
		var sh := Shader.new()
		sh.code = "shader_type canvas_item;\nuniform vec4 ink : source_color = vec4(0.165, 0.094, 0.063, 1.0);\nvoid fragment() {\n\tfloat l = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));\n\tfloat e = step(0.04, UV.x) * step(UV.x, 0.96) * step(0.04, UV.y) * step(UV.y, 0.96);
	COLOR = vec4(ink.rgb, e * COLOR.a * (1.0 - smoothstep(0.28, 0.4, l)));\n}\n"
		_ink_mat = ShaderMaterial.new()
		_ink_mat.shader = sh
	return _ink_mat
