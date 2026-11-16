## Phase 8 table, BLOCKOUT round 4 (Ben, 2026-11-15): flat shapes in the five-colour palette, under
## the restraint rules (Docs/ArtDirection.md). Only the Sins' glass and the dice carry detail; everything
## else is a flat shape or plain ink line, a placeholder for the woodcut-ink pieces still to be drawn.
## Drawn whole from a state (build()); fixtures (tools/fixture.gd, screen "table") draw one moment,
## and ui/table_play.gd redraws it as the real game moves.
##   Top is them, bottom is me. Windows across the top, the active one twice the width, lit, and
##   grown into any spare wall above; on a rival's turn its stake and Strike marks sit under its
##   window in its light and my whole near edge dims. Under the windows the score track runs the
##   page's full width, 0 to 1000: rivals' sigils above the line on stems (close ones staggered,
##   never overlapping, the leader crowned on top), mine below it. The whole track is one tap target
##   (the standings). Built bottom-up round my decision: Bank and Throw at the bottom, my three Strike
##   candles between them (flames steady, restless or guttering), my marks stamped along the page's
##   near edge, the stake in gold above Bank, the dice above that. The page is lit in a pool round
##   the dice and decision; the desk is dark.
extends Control

signal throw_pressed
signal bank_pressed
signal standings_pressed
signal seal_pressed
signal stand_pressed

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
const UNDER_WIN := 190.0   # the zone at the windows' feet: a rival's stake, a spoken line, a choice row (REPLY 16: over the windows)
const ROW_GAP := 22.0      # the gap left under the window row: my crimson bar (REPLY 16; the windows took the rest)
const GOAL := 1000.0       # first to 1000 wins
const SEAL := 236.0        # Bank and Throw, px (86 pt)
const EDGE := 76.0         # seals and candles stand this far in from the page's near edge (marks below)
const CANDLE := Vector2(84, 300)
const CANDLE_GAP := 30.0
const MARK := 60.0         # track marker, px: display only (the track is the tap target)
const LEVEL := 70.0        # a rival stem level: marker + gap (plus TOTAL_H for the total above each head)
const TOTAL_SIZE := 44     # each player's total at their marker (REPLY 12), px: 15 pt at the smallest phone
const TOTAL_H := 46.0      # the room a total takes above a rival's head or under my marker
const STEM := 24.0         # the shortest stem
const DIE_MAX := 186.0
const DIE_MAX_ROWS := 140.0  # two rows of dice
const DIE_MIN := 110.0
const DIE_GAP := 18.0
const STAMP := 52.0        # a mark's sigil stamp on the near edge
const GAIN_GOLD := Color("c98a12")  # deep gold: a throw's points, the boldest thing on the page for that beat
const POWER_SEAL := 180.0  # my Sin's seal (Rules.V5 power), px (66 pt), above Throw
const CHOICE_H := 128.0     # a choice button: 44 pt tall at the smallest phone
const CHOICE_GAP := 36.0    # between choice buttons: 12 pt
const CHOICE_PER_ROW := 5
const RIVAL_SEAL := 110.0  # a rival's seal beside its stake on its turn, px (display only)
const BAND_PAD := 14.0    # the track band's top and bottom padding (REPLY 16: from 30, so the windows get build 116's size)
const HOOD := Color("3f2639")  # the Master's hood, darker than his robe
const ROBE := Color("5b3a52")  # the Master's blockout robe: flat, muted plum, edged in bone

## seats: [{sin, score, you, marks {Sin: n}, pend [cost]}], cur: active seat, faces: dice on the page,
## points: at stake, strikes: 0-3, moment: "decision" | "rival" | "bust" | "wait",
## speak: {seat, line} a Sin's spoken line, ability: die index my Sin's ability just changed (-1 none),
## bank_loss: points a pending cost takes off my next Bank, safe: Vector2(top, bottom) insets in px.
var seats: Array = []
var cur := 0
var faces: Array = []
var points := 0
var strikes := 0
var moment := "decision"
var speak := {}
var ability := -1
var bank_loss := 0
var gain := 0            # the throw's points, shown over the dice until the stake takes them
var can_bank := true     # in play: Bank is offered (not before the first throw)
var can_throw := true
var safe := Vector2.ZERO
## Rules.V5: my seal ("" none, "ready" glowing and live, "idle" unspent, "spent"), the face Lust's seal
## shows (0 none), a power firing ({seat, dice: [indices it changed]}), the dice live as "let it stand",
## and the Master's line (spoken from his figure over the windows, REPLY 14).
var seal := ""
var seal_face := 0
var firing := {}
var stand_live := false
var master_line := ""
var rival_seal := ""     # the active rival's seal: "" none, "idle", "spent"
var buy_ghosts: Array = []  # buying: the score each purchase would leave me on (REPLY 9)
var ghost_nodes: Array = []  # their ghost markers, in that order
var band_bottom := 0.0  # the foot of the track band (a choice row past five wraps below it)
var call_at := 0       # REPLY 10: the Master calls the end when the leader reaches this (0: first to 1000 wins)
var rounds_left := 0   # after his call: 2 (penultimate round), 1 (final round)
## The Master's figure (REPLY 14, blockout): rest, speak, call (arm raised), mark (arm to master_target's
## window, a ring on it), offer (both hands out to master_target's window, a card held).
var master_pose := "rest"
var master_target := -1
var marked_seat := -1  # the seat the Master marked this round (Rules.V5 "mark"): a gold ring on its window
## Pixel boxes from the last build (REPLY 16 item 8, for art made to size): head, mask, shoulders, robe,
## arm, card, windows.
var boxes := {}

## Built nodes other scripts move (ui/table_play.gd): dice in face order, candles, stake label.
var dice_nodes: Array = []
var candle_rects: Array = []
var stake_label: Label
var gain_label: Label
var master_label: Label
var seal_button: Button  # my Sin's seal (Rules.V5), when drawn
var flare_node: Control  # the seal whose power is firing now (ui/table_play.gd pulses it)
var page_rect := Rect2()
var dice_area := Rect2()


func build() -> void:
	for c in get_children():
		c.queue_free()
		remove_child(c)
	dice_nodes.clear()
	candle_rects.clear()
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
	if seats[lead].score <= 0 or seats.filter(func(s): return s.score == seats[lead].score).size() > 1:
		lead = -1  # a tie (everyone on 0 at the start): no one is crowned
	var col: Color = Style.SIN_COLORS[seats[cur].sin]
	var bust := moment == "bust"
	var mine: bool = cur == me
	var live: bool = mine and moment == "decision"
	var pend: Array = seats[me].get("pend", [])
	_rect(Rect2(Vector2.ZERO, vp), BLACK)

	# Track heads first (they set the band's height): rivals above the line on two levels at most. Along
	# the scores, a rival close to the one before goes on the other level; the leader is always on the
	# top level, crowned. On each level close heads then fan sideways (stems lean from the true score).
	var n := seats.size()
	var order := range(n)
	order.sort_custom(func(a, b): return seats[a].score < seats[b].score)
	var span: float = vp.x - 48.0 - 160.0
	var widest := 0.0  # heads on one level stand far enough apart for their totals (REPLY 12)
	for s in seats:
		widest = maxf(widest, Style.NUMERAL.get_string_size(str(int(s.score)), HORIZONTAL_ALIGNMENT_LEFT, -1, TOTAL_SIZE).x)
	var gap: float = maxf(MARK, widest) + 16.0
	var lvl := {}
	var head := {}  # seat -> head x, track coordinates (0 = score 0)
	var prev := -1
	for i in order:
		if i == me:
			continue
		var x: float = span * clampf(seats[i].score / GOAL, 0.0, 1.0)
		var l := 0
		if prev >= 0 and x - head[prev] < gap:
			l = 1 - lvl[prev]
		if i == lead:
			l = 1
		lvl[i] = l
		head[i] = x
		prev = i
	var edge: float = maxf(80.0, gap / 2.0 + 48.0)  # a head's total stays inside the side margins
	var lo: float = edge - (24.0 + 80.0)
	var hi: float = vp.x - edge - (24.0 + 80.0)
	for l in 2:
		var row: Array = order.filter(func(i): return lvl.has(i) and lvl[i] == l)
		# Groups of heads, each centred on its scores' mean; touching groups merge.
		var groups: Array = []
		for i in row:
			groups.append([i])
			while groups.size() > 1:
				var a: Array = groups[groups.size() - 2]
				var b: Array = groups[groups.size() - 1]
				var ca := _centre(a, span) - (a.size() - 1) * gap / 2.0
				var ea := ca + (a.size() - 1) * gap
				var cb := _centre(b, span) - (b.size() - 1) * gap / 2.0
				if cb - ea >= gap:
					break
				groups.pop_back()
				groups[groups.size() - 1] = a + b
		for g in groups:
			var x0: float = _centre(g, span) - (g.size() - 1) * gap / 2.0
			for k in g.size():
				head[g[k]] = x0 + k * gap
		for k in row.size():  # keep inside the page and apart once clamped
			head[row[k]] = maxf(head[row[k]], lo if k == 0 else head[row[k - 1]] + gap)
		for k in range(row.size() - 1, -1, -1):
			head[row[k]] = minf(head[row[k]], hi if k == row.size() - 1 else head[row[k + 1]] - gap)
	var max_l: int = 0
	for j in lvl:
		max_l = maxi(max_l, lvl[j])
	var above: float = 44.0 + TOTAL_H + MARK + STEM + max_l * (LEVEL + TOTAL_H)  # crown + total + marker + stems
	var band_h: float = BAND_PAD + above + STEM + MARK + TOTAL_H + BAND_PAD  # mine hangs below, its total under it

	# Bottom up: my near edge, seals, stake, dice; then the track band; then the page round them.
	var pb: float = vp.y - safe.y - 12.0
	var px0 := 24.0
	var px1: float = vp.x - 24.0
	var sy: float = pb - EDGE - SEAL
	var stake_size: int = int(lerpf(120.0, 190.0, clampf(points / 600.0, 0.0, 1.0)))  # grows as dice score
	var gain_size: int = stake_size + 10  # at least the stake numeral
	var gain_h: float = gain_size * 0.82 + 24.0  # the strip between the track and the dice (Cinzel's glyphs, not its line box)
	var stake_h: float = stake_size * 1.45  # Cinzel's line box
	var stake_top: float = sy - 8.0 - stake_h
	var dl: float = px0 + 40.0
	var dw: float = px1 - 40.0 - dl
	var slots: int = faces.size() + pend.count("fewer") + pend.count("die")  # a ghost per die to lose
	var dn: int = maxi(slots, 1)
	var rows: int = 1 if dn <= 6 else 2
	var per: int = ceili(float(dn) / rows)
	var bw: float = (vp.x - 2.0 * SIDE - (n - 1) * WIN_GAP) / (n + 1)
	var wh_active: float = 2.0 * bw * WIN_RATIO
	var wy_min: float = safe.x + 4.0
	# REPLY 16: the row takes the old gap under it; the Master stands behind it, over the rivals.
	var wy_top: float = wy_min
	# Dice give way before the windows do.
	var ds: float = minf(DIE_MAX if rows == 1 else DIE_MAX_ROWS, (dw - (per - 1) * DIE_GAP) / per)
	var dy: float = 0.0
	while true:
		dy = stake_top - 56.0 - rows * ds - (rows - 1) * 34.0
		if dy - 40.0 - band_h - gain_h >= wy_top + wh_active + ROW_GAP or ds <= DIE_MIN:
			break
		ds -= 6.0
	var pt: float = maxf(dy - 70.0 - band_h - gain_h, wy_top + wh_active + ROW_GAP)
	pt = minf(pt, dy - 40.0 - band_h - gain_h)
	var room: float = pt - ROW_GAP - wy_top
	var k: float = minf(1.0, room / wh_active)  # only if even the smallest dice leave no room
	# The active window grows into spare wall above, as wide as the row allows.
	var aw: float = minf(room / WIN_RATIO, vp.x - 2.0 * SIDE - (n - 1) * (bw * k + WIN_GAP))
	aw = maxf(aw, 2.0 * bw * k)
	var pg := Rect2(px0, pt, px1 - px0, pb - pt)
	page_rect = pg

	# Windows, bottoms on one line above the gap: placed first, so the Master can stand behind them.
	var wb: float = pt - ROW_GAP
	var row_w: float = aw + (n - 1) * (bw * k + WIN_GAP)
	var x: float = (vp.x - row_w) / 2.0
	var wr := Rect2()
	var win_rects := []
	for i in n:
		var w: float = aw if i == cur else bw * k
		win_rects.append(Rect2(x, wb - w * WIN_RATIO, w, w * WIN_RATIO))
		x += w + WIN_GAP
	boxes = {"windows": win_rects.duplicate()}
	var mf := _master_body(win_rects, cur, wy_min, pt, vp.x, bw * k)  # behind the windows
	for i in n:
		var r: Rect2 = win_rects[i]
		var w: float = r.size.x
		var t := TextureRect.new()
		t.texture = Art.window_crop(seats[i].sin, WIN_RATIO, Tuning.WINDOW_CROP_TOP.get(seats[i].sin, 0.0))
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		t.position = r.position
		t.size = r.size
		t.modulate = Color.WHITE if i == cur else Color(0.3, 0.28, 0.3)  # REPLY 16: rivals readable against the plum
		add_child(t)
		_line([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position], INK, 5.0)
		if i == cur:
			wr = r
		if i == me:  # yours: a crimson bar under it
			_rect(Rect2(r.get_center().x - minf(w, 120.0) * 0.4, r.end.y + 8, minf(w, 120.0) * 0.8, 10), CRIMSON)
	_master_arms(mf, win_rects, px0, px1)  # in front of them

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
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	add_child(shaft)

	# A rival's turn: its stake and Strike marks under its window, in its light.
	if not mine:  # REPLY 16: on an ink plate over the foot of its window (the gap under the row is gone)
		var under: float = wr.end.y - 150.0
		var plate_x: float = clampf(wr.get_center().x - 130.0 - 60.0, px0 + 20.0, px1 - 400.0)
		_rect(Rect2(plate_x - 12.0, under - 26.0, 270.0 + 3 * 46.0 + RIVAL_SEAL + 48.0, 152.0), Color(BLACK, 0.85))
		var rs := _label(str(points), 92, GOLD, INK)
		rs.size = Vector2(260, 92 * 1.45)
		rs.position = Vector2(plate_x, under - 22.0)
		for s in 3:
			_rect(Rect2(rs.position.x + 270.0 + s * 46.0, under + 30.0, 32, 48), CRIMSON if s < strikes else Color(BONE, 0.22))
		if not firing.is_empty() and firing.get("dice", []).is_empty():  # its power took the stake (Cash Out, Hubris)
			var rw: float = Style.NUMERAL.get_string_size(str(points), HORIZONTAL_ALIGNMENT_LEFT, -1, 92).x
			_stake_ring(Rect2(rs.position.x + (rs.size.x - rw) / 2.0, rs.position.y + rs.size.y * 0.2, rw, rs.size.y * 0.6), int(firing.seat), self, BONE, Vector2(rs.position.x + 270.0 + 3 * 46.0 + 16.0, under + 10.0), rival_seal == "")
		if rival_seal != "":  # its seal beside its Strike marks: spent once used, blazing as it fires
			_power_seal(self, Vector2(rs.position.x + 270.0 + 3 * 46.0 + 24.0 + RIVAL_SEAL / 2.0, under + 54.0), seats[cur].sin, rival_seal, RIVAL_SEAL, not firing.is_empty() and int(firing.seat) == cur)
	# A Sin's spoken line, anchored under its window, in its colour. On a rival's turn its stake has the
	# gap, so the line sits over the foot of the speaker's window instead.
	if not speak.is_empty():
		var sr: Rect2 = win_rects[int(speak.seat)]
		var scol: Color = Style.SIN_COLORS[seats[int(speak.seat)].sin].lightened(0.15)
		var line := _label(str(speak.line), 84, scol, BLACK, true)
		var lw: float = Style.BLACKLETTER.get_string_size(str(speak.line), HORIZONTAL_ALIGNMENT_LEFT, -1, 84).x + 40.0
		line.size = Vector2(lw, 110)
		var ly: float = sr.end.y - 130.0  # REPLY 16: over the foot of the speaker's window
		line.position = Vector2(clampf(sr.get_center().x - lw / 2.0, px0 + 20.0, px1 - 20.0 - lw), ly)

	# Score track: the page's full width, 0 at the left, 1000 at the right.
	var ax0: float = pg.position.x + 80.0
	var ax1: float = ax0 + span
	var ay: float = pg.position.y + BAND_PAD + above
	_line([Vector2(ax0, ay), Vector2(ax1, ay)], INK, 6.0)
	for q in [0.25, 0.5, 0.75]:
		var qx: float = lerpf(ax0, ax1, q)
		_line([Vector2(qx, ay - 12), Vector2(qx, ay + 12)], INK, 4.0)
	_line([Vector2(ax0, ay - 18), Vector2(ax0, ay + 18)], INK, 6.0)
	if call_at <= 0:
		_line([Vector2(ax1, ay - 40), Vector2(ax1, ay + 40)], GOLD, 16.0, INK)
		var gl := _label("1000", 46, GOLD, INK)
		gl.size = Vector2(150, 60)
		gl.position = Vector2(ax1 - 75.0, ay + 44.0)
	else:  # REPLY 10: no finish line; the Master's post where he calls the end, crimson once called,
		# with a pip for each round left (2: the penultimate round, 1: the final round)
		_line([Vector2(ax1, ay - 18), Vector2(ax1, ay + 18)], INK, 6.0)
		var px: float = ax0 + span * clampf(float(call_at) / GOAL, 0.0, 1.0)
		var pc: Color = CRIMSON if rounds_left > 0 else GOLD
		_line([Vector2(px, ay - 40), Vector2(px, ay + 40)], pc, 16.0, INK)
		var cl := _label(str(call_at), 46, BONE, INK)  # REPLY 11: bone on a dark outline (4.5:1); the post carries the colour
		# REPLY 15: just under the line at the post, never stacked on my total; when my marker hangs near the
		# post, the number moves beside the post, on the side away from my marker.
		var post_w: float = Style.NUMERAL.get_string_size(str(call_at), HORIZONTAL_ALIGNMENT_LEFT, -1, 46).x + 24.0
		cl.size = Vector2(post_w, 60)
		var my_x: float = ax0 + span * clampf(seats[me].score / GOAL, 0.0, 1.0)
		var clear: float = MARK / 2.0 + 10.0
		var post_x: float = px - post_w / 2.0
		if absf(my_x - px) < clear + post_w / 2.0:
			post_x = minf(px - 12.0, my_x - clear) - post_w if my_x >= px else maxf(px + 12.0, my_x + clear)
		cl.position = Vector2(clampf(post_x, pg.position.x + 8.0, pg.end.x - 8.0 - post_w), ay + 16.0)
		for pip in rounds_left:
			_disc(Vector2(px + (pip - (rounds_left - 1) / 2.0) * 40.0, ay - 66.0), 14.0, CRIMSON, INK)
	var draw := order.filter(func(i): return i != me and i != lead)
	if lead != me and lead >= 0:
		draw.append(lead)
	draw.append(me)
	var centres := {}
	for i in draw:  # stems first, so no stem crosses a marker
		var mx: float = ax0 + span * clampf(seats[i].score / GOAL, 0.0, 1.0)
		if i == me:  # mine: below the line
			_line([Vector2(mx, ay), Vector2(mx, ay + STEM)], CRIMSON, 4.0)
			centres[i] = Vector2(mx, ay + STEM + MARK / 2.0)
		else:  # a leaning stem from the true score up to the head
			var top: float = ay - STEM - lvl[i] * (LEVEL + TOTAL_H)
			var hx: float = ax0 + head[i]
			_line([Vector2(mx, ay), Vector2(mx, ay - 8.0), Vector2(hx, top)], INK, 3.0)
			centres[i] = Vector2(hx, top - MARK / 2.0)
	# Buying (REPLY 9, 10, 11): where each purchase would leave me, a ghost of my marker along my side
	# of the line: hollow, in ink, never my crimson. Hidden at rest; choice_row() shows one while its
	# button is held.
	ghost_nodes.clear()
	for s in buy_ghosts:
		var gh := Control.new()
		gh.position = Vector2(ax0 + span * clampf(float(s) / GOAL, 0.0, 1.0), centres[me].y)
		gh.mouse_filter = Control.MOUSE_FILTER_IGNORE
		gh.visible = false
		add_child(gh)
		var ring := []
		for j in 41:
			ring.append(Vector2.from_angle(TAU * j / 40.0) * MARK / 2.0)
		_line(ring, INK, 5.0, Color(0, 0, 0, 0), gh)
		_sigil(seats[me].sin, Rect2(-Vector2(MARK, MARK) * 0.36, Vector2(MARK, MARK) * 0.72), INK, gh)
		ghost_nodes.append(gh)
	for i in draw:
		_marker(centres[i], i, me, lead)
	var track := Button.new()  # the whole band is one tap target: the standings
	track.flat = true
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		track.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	band_bottom = pg.position.y + band_h
	track.position = Vector2(56.0, pg.position.y + 44.0)  # inside the side margins, clear of a choice row above the page
	track.size = Vector2(vp.x - 112.0, band_h - 44.0)
	track.focus_mode = Control.FOCUS_NONE
	track.pressed.connect(func(): standings_pressed.emit())
	add_child(track)

	# Dice, one or two rows, then a ghost for each die a pending cost will take.
	# Under each: gold if it scores, crimson if a Strike, nothing if dead.
	dice_area = Rect2(dl, dy, dw, rows * ds + (rows - 1) * 34.0)
	gain_label = null
	master_label = null
	seal_button = null
	flare_node = null
	if gain > 0:  # the throw's points, gold, in the strip just above the dice
		var gain_l := _label("+%d" % gain, gain_size, GAIN_GOLD, BLACK)
		gain_l.add_theme_font_override("font", Style.NUMERAL)
		gain_l.add_theme_constant_override("outline_size", 22)  # a dark edge
		gain_l.add_theme_color_override("font_shadow_color", Color(BLACK, 0.7))
		gain_l.add_theme_constant_override("shadow_offset_x", 5)
		gain_l.add_theme_constant_override("shadow_offset_y", 7)
		gain_l.add_theme_constant_override("shadow_outline_size", 22)
		gain_l.size = Vector2(dw, gain_size * 1.45)
		# Glyphs centred in the strip just above the dice (the line box overhangs it, the glyphs don't).
		gain_l.position = Vector2(dl, dy - gain_h / 2.0 - 4.0 - gain_l.size.y / 2.0)
		gain_label = gain_l
	for d in slots:
		var row: int = d / per
		var in_row: int = mini(per, dn - row * per)
		var rx: float = dl + (dw - (in_row * ds + (in_row - 1) * DIE_GAP)) / 2.0
		var p := Vector2(rx + (d % per) * (ds + DIE_GAP), dy + row * (ds + 34.0))
		if d >= faces.size():  # ghost: the die a pending cost takes
			_dashed_box(Rect2(p + Vector2(ds, ds) * 0.06, Vector2(ds, ds) * 0.88), CRIMSON)
			continue
		var f := int(faces[d])
		# A Sin's ability or power just changed this die: a ring of that Sin's glass colour, its sigil above.
		var by: int = me if d == ability else (int(firing.seat) if not firing.is_empty() and d in firing.get("dice", []) else -1)
		if by >= 0:
			_disc(p + Vector2(ds, ds) / 2.0, ds * 0.72, Color(Style.SIN_COLORS[seats[by].sin], 0.55), Color(0, 0, 0, 0))
			_sigil(seats[by].sin, Rect2(p + Vector2(ds * 0.2, -ds * 0.62), Vector2(ds * 0.6, ds * 0.6)), INK)
		var die := Die.new(f, int(ds), d)
		die.position = p
		die.size = Vector2(ds, ds)
		add_child(die)
		dice_nodes.append(die)
		var mk: Color = GOLD if f >= 4 else (CRIMSON if f <= 2 else Color(0, 0, 0, 0))
		_rect(Rect2(p.x + ds * 0.15, p.y + ds + 10.0, ds * 0.7, 9.0), mk)
	if stand_live:  # my power is ready on this throw: a tap on the dice lets the throw stand
		var st := Button.new()
		st.flat = true
		for k2 in ["normal", "hover", "pressed", "focus", "disabled"]:
			st.add_theme_stylebox_override(k2, StyleBoxEmpty.new())
		st.position = dice_area.position - Vector2(0, 20)
		st.size = dice_area.size + Vector2(0, 50)
		st.focus_mode = Control.FOCUS_NONE
		st.pressed.connect(func(): stand_pressed.emit())
		add_child(st)

	# My near edge. On a rival's turn all of it dims.
	var near := Control.new()
	near.mouse_filter = Control.MOUSE_FILTER_IGNORE
	near.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(near)
	if not mine:
		near.modulate = Color(1, 1, 1, 0.38)
	var bank := _seal(near, "Bank", Vector2(px0 + 36.0, sy), GOLD, INK, live and can_bank)
	var throw := _seal(near, "Throw", Vector2(px1 - 36.0 - SEAL, sy), CRIMSON, BONE, live and can_throw)
	bank.pressed.connect(func(): bank_pressed.emit())
	throw.pressed.connect(func(): throw_pressed.emit())
	if mine and not (live and can_bank):
		bank.modulate = Color(1, 1, 1, 0.35)
	if mine and not (live and can_throw):
		throw.modulate = Color(1, 1, 1, 0.35)
	# Rules.V5: my Sin's seal, the third control, centred over Throw: glowing and live when my power is
	# ready, plain when unspent, dark and crossed once spent this turn.
	if seal != "":
		var pc := Vector2(throw.position.x + SEAL / 2.0, sy - 40.0 - POWER_SEAL / 2.0)
		_power_seal(near, pc, seats[me].sin, seal, POWER_SEAL, not firing.is_empty() and int(firing.seat) == me, seal_face)
		_seal_hit(near, pc)

	# The stake: one gold numeral directly above Bank (what Bank keeps), a pending Bank loss in crimson
	# beside it. A bust blots it.
	var cw: float = 3.0 * CANDLE.x + 2.0 * CANDLE_GAP
	var c_l: float = (bank.position.x + SEAL + throw.position.x) / 2.0 - cw / 2.0
	var loss := ("-%d" % bank_loss) if bank_loss > 0 else ""
	var loss_w: float = (Style.NUMERAL.get_string_size(loss, HORIZONTAL_ALIGNMENT_LEFT, -1, 64).x + 16.0) if loss != "" else 0.0
	while stake_size > 90 and Style.NUMERAL.get_string_size(str(points), HORIZONTAL_ALIGNMENT_LEFT, -1, stake_size).x > c_l - 40.0 - (px0 + 70.0):
		stake_size -= 4  # never under the candles
	stake_label = null
	if mine and buy_ghosts.is_empty():  # buying: the stake has landed on the track (REPLY 9)
		var bc: float = bank.position.x + SEAL / 2.0
		var tw: float = Style.NUMERAL.get_string_size(str(points), HORIZONTAL_ALIGNMENT_LEFT, -1, stake_size).x
		var num := _label(str(points), stake_size, GOLD, INK, false, near)
		num.size = Vector2(tw + 24.0, stake_h)
		num.position = Vector2(maxf(px0 + 70.0, bc - num.size.x / 2.0), stake_top)
		stake_label = num
		if loss != "":
			var ll := _label(loss, 64, CRIMSON, BONE, false, near)
			ll.size = Vector2(loss_w, 90)
			ll.position = Vector2(num.position.x + num.size.x - 8.0, stake_top - 18.0)  # raised, clear of the flames
		if not firing.is_empty() and int(firing.seat) == me and firing.get("dice", []).is_empty():
			_stake_ring(Rect2(num.position.x + 12.0, stake_top + stake_h * 0.12, tw, stake_h * 0.76), me, near)
		if bust:  # the blot covers the figure itself
			_blot(near, Vector2(num.position.x + num.size.x / 2.0, stake_top + stake_h / 2.0), Vector2((tw / 2.0 + 28.0) / 0.91, stake_size * 0.64))
	# Marks I hold: small sigil stamps along the page's near edge.
	var marks: Dictionary = seats[me].get("marks", {})
	var mx0: float = bank.position.x + SEAL + 20.0
	for s in marks:
		for m in int(marks[s]):
			var c := Vector2(mx0 + STAMP / 2.0, pb - EDGE / 2.0)
			_disc(c, STAMP / 2.0, BONE, CRIMSON, near)
			_sigil(s, Rect2(c - Vector2(STAMP, STAMP) * 0.42, Vector2(STAMP, STAMP) * 0.84), CRIMSON, near)
			mx0 += STAMP + 12.0
	# My three Strike candles, large, on my edge between the seals: lit (the flame steady, restless or
	# guttering with the Strikes taken), or snuffed with a crimson cap and a thread of smoke. A Strike
	# I'll start my next turn with is a crimson band round the first candle to go.
	var struck: int = (3 if bust else strikes) if mine else 0
	var risk: int = clampi(strikes, 0, 2) if mine else 0
	var ct: float = pb - EDGE - CANDLE.y
	for c in 3:
		var p := Vector2(c_l + c * (CANDLE.x + CANDLE_GAP), ct)
		candle_rects.append(Rect2(p, CANDLE))
		_rect(Rect2(p, CANDLE), BONE, near)
		if pend.has("strike") and c == 2 - struck:  # the next candle to go
			_rect(Rect2(p + Vector2(0, CANDLE.y * 0.42), Vector2(CANDLE.x, 22)), CRIMSON, near)
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
			glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
			near.add_child(glow)
			_rect(Rect2(p + Vector2(CANDLE.x / 2.0 - 3, -14), Vector2(6, 16)), INK, near)  # wick
			_flame(near, p + Vector2(CANDLE.x / 2.0, -12.0), risk, 2.0)
	# (REPLY 14: no skeleton by the candles; the Master stands over the windows and speaks from there.)


## The Master of the Dance (REPLY 16), a flat blockout and the largest figure on screen. He stands behind
## the window row over the longest run of rival windows (the short ones leave him room; the active window is
## as tall as the wall): hood and mask at least two windows wide, shoulders above the rivals' tops, robe to
## the screen's edges and down to the table top. For a mark or an offer he stands away from its window.
func _master_body(win_rects: Array, cur: int, top: float, bottom: float, w: float, rw: float) -> Dictionary:
	var avoid: int = master_target if master_pose in ["mark", "offer"] else -1
	var runs := []
	var run := []
	for i in win_rects.size():
		if i == cur or i == avoid:
			if not run.is_empty():
				runs.append(run)
			run = []
		else:
			run.append(i)
	if not run.is_empty():
		runs.append(run)
	var best := []
	var best_w := -1.0
	for r in runs:
		var rw0: float = (win_rects[r[-1]] as Rect2).end.x - (win_rects[r[0]] as Rect2).position.x
		var mid: float = ((win_rects[r[-1]] as Rect2).end.x + (win_rects[r[0]] as Rect2).position.x) / 2.0
		if rw0 > best_w + 1.0 or (absf(rw0 - best_w) <= 1.0 and absf(mid - w / 2.0) < absf(_run_mid(win_rects, best) - w / 2.0)):
			best = r
			best_w = rw0
	var head_w: float = minf(2.0 * rw + WIN_GAP, w - 32.0)  # two windows wide
	var cx: float = w / 2.0
	var rt: float = (win_rects[cur] as Rect2).position.y + (win_rects[cur] as Rect2).size.y / 2.0  # no rivals: half the wall
	if not best.is_empty():
		cx = _run_mid(win_rects, best)
		rt = (win_rects[best[0]] as Rect2).position.y
	cx = clampf(cx, 16.0 + head_w / 2.0, w - 16.0 - head_w / 2.0)
	var y_sh: float = rt - maxf(24.0, (rt - top) * 0.12)  # shoulders, above the rivals' tops
	var hood := Rect2(cx - head_w / 2.0, top, head_w, (y_sh - top) * 1.04)
	var edge := Color(BONE, 0.85)
	var none := Color(0, 0, 0, 0)
	var fall: float = y_sh + (bottom - y_sh) * 0.25
	var sw: float = head_w * 0.72  # shoulders: half-width from his centre
	var outline := [Vector2(cx - sw, y_sh), Vector2(maxf(0.0, cx - sw * 1.9), fall), Vector2(0, fall), Vector2(0, bottom),
		Vector2(w, bottom), Vector2(w, fall), Vector2(minf(w, cx + sw * 1.9), fall), Vector2(cx + sw, y_sh)]
	var robe := Polygon2D.new()
	robe.polygon = PackedVector2Array(outline)
	robe.color = ROBE
	add_child(robe)
	_line([outline[2], outline[1], outline[0], outline[7], outline[6], outline[5]], edge, 4.0, none)
	# The hood: a dome two windows wide whose sides flare down into the shoulders.
	var ry: float = (y_sh - top) * 0.5
	var cy: float = top + ry
	var cowl := []
	for j in 25:
		var t: float = PI + PI * j / 24.0
		cowl.append(Vector2(cx + cos(t) * head_w / 2.0, cy + sin(t) * ry))
	cowl.append(Vector2(cx + sw * 0.95, y_sh + 12.0))
	cowl.append(Vector2(cx - sw * 0.95, y_sh + 12.0))
	var hp := Polygon2D.new()
	hp.polygon = PackedVector2Array(cowl)
	hp.color = HOOD
	add_child(hp)
	_line(cowl.slice(0, 27), edge, 5.0, none)
	_line([cowl[0], cowl[26]], edge, 5.0, none)
	var mask := Rect2(cx - head_w * 0.2, cy - ry * 0.35, head_w * 0.4, ry * 1.1)
	_ellipse(mask, BONE, INK, 4.0)
	for e in [-1, 1]:  # eye holes
		_ellipse(Rect2(cx + e * head_w * 0.085 - head_w * 0.04, mask.position.y + mask.size.y * 0.32, head_w * 0.08, mask.size.y * 0.16), INK, none, 0.0)
	_line([Vector2(cx - sw * 0.55, y_sh + 6.0), Vector2(cx, y_sh + sw * 0.35), Vector2(cx + sw * 0.55, y_sh + 6.0)], GOLD, 8.0, none)
	boxes["head"] = hood
	boxes["mask"] = mask
	boxes["shoulders"] = Rect2(cx - sw, y_sh - 4.0, 2.0 * sw, 8.0)
	boxes["robe"] = Rect2(0, y_sh, w, bottom - y_sh)
	return {"cx": cx, "top": top, "y_sh": y_sh, "head_w": head_w, "arm_w": rw, "rt": rt, "wb": (win_rects[cur] as Rect2).end.y,
		"sh_l": Vector2(cx - sw * 0.8, y_sh - rw * 0.15), "sh_r": Vector2(cx + sw * 0.8, y_sh - rw * 0.15)}  # arm joints on the shoulder line


func _run_mid(win_rects: Array, run: Array) -> float:
	if run.is_empty():
		return INF
	return ((win_rects[run[-1]] as Rect2).end.x + (win_rects[run[0]] as Rect2).position.x) / 2.0


## A flat ellipse filling r, with an optional edge.
func _ellipse(r: Rect2, fill: Color, edge: Color, width: float) -> void:
	var pts := PackedVector2Array()
	for j in 48:
		pts.append(r.get_center() + Vector2(cos(TAU * j / 48.0) * r.size.x / 2.0, sin(TAU * j / 48.0) * r.size.y / 2.0))
	var poly := Polygon2D.new()
	poly.polygon = pts
	poly.color = fill
	add_child(poly)
	if width > 0.0 and edge.a > 0.0:
		var ring := Array(pts)
		ring.append(pts[0])
		_line(ring, edge, width, Color(0, 0, 0, 0))


## His arm by pose, in front of the windows and as thick as a rival window is wide: rest and speak (none),
## call (raised), mark (reaching to master_target's window, a gold ring on it), offer (a card held centred
## just above that window, inside its width). The round's mark stays as a ring on marked_seat's window.
## His line sits under his collar, on an ink plate, centred on him.
func _master_arms(mf: Dictionary, win_rects: Array, px0: float, px1: float) -> void:
	var none := Color(0, 0, 0, 0)
	var cx: float = mf.cx
	var aw: float = mf.arm_w
	var vp_w: float = get_viewport_rect().size.x
	if marked_seat >= 0 and marked_seat < win_rects.size():
		var mr: Rect2 = win_rects[marked_seat]
		var rc := Vector2(mr.get_center().x, mr.position.y + minf(46.0, mr.size.y * 0.15))
		var ring := []
		var rr: float = minf(32.0, mr.size.x * 0.28)
		for j in 41:
			ring.append(rc + Vector2.from_angle(TAU * j / 40.0) * rr)
		_line(ring, GOLD, 7.0, none)
	var tr := Rect2()
	if master_target >= 0 and master_target < win_rects.size():
		tr = win_rects[master_target]
	var hand := Vector2.ZERO
	var reach_left := false
	match master_pose:
		"call":
			reach_left = cx > vp_w / 2.0  # raised on the side with more room
			hand = Vector2(cx + (-1.0 if reach_left else 1.0) * mf.head_w * 0.62, mf.top + aw * 0.35)
		"mark":
			if tr.size.x > 0.0:
				hand = Vector2(tr.get_center().x, tr.position.y - aw * 0.9)  # pointing at it, clear of the ring
		"offer":
			if tr.size.x > 0.0:
				var cw: float = minf(tr.size.x - 16.0, 170.0)  # inside its window's width: never over a neighbour
				var card := Rect2(tr.get_center().x - cw / 2.0, tr.position.y - 12.0 - cw * 1.4, cw, cw * 1.4)
				card.position.y = maxf(card.position.y, mf.top)
				boxes["card"] = card
				hand = Vector2(card.get_center().x, card.position.y + 10.0)
	if hand != Vector2.ZERO:
		if master_pose != "call":
			reach_left = hand.x < cx
		var sh: Vector2 = mf.sh_l if reach_left else mf.sh_r
		_line([sh, hand], ROBE, aw, Color(BONE, 0.7))
		boxes["arm"] = Rect2(minf(sh.x, hand.x) - aw / 2.0, minf(sh.y, hand.y) - aw / 2.0, absf(sh.x - hand.x) + aw, absf(sh.y - hand.y) + aw)
		if boxes.has("card"):  # the card, then the hand holding it by its top
			var card: Rect2 = boxes.card
			_rect(card, BONE)
			_line([card.position, Vector2(card.end.x, card.position.y), card.end, Vector2(card.position.x, card.end.y), card.position], INK, 4.0, none)
		_disc(hand, minf(aw * 0.36, 60.0), BONE, INK)
	if master_line != "":  # his words on an ink plate across the rivals' middles, centred on him (their tops and rings stay clear)
		var lw: float = clampf(mf.head_w * 1.3, 300.0, px1 - px0 - 32.0)
		var l: float = clampf(cx - lw / 2.0, maxf(px0 + 16.0, 52.0), minf(px1 - 16.0, vp_w - 52.0) - lw)
		var ml := Style.label(master_line, 44, BONE, false, 10)
		ml.add_theme_color_override("font_outline_color", INK)
		ml.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		ml.custom_minimum_size = Vector2(lw, 0)
		ml.position = Vector2(l, mf.rt + (mf.wb - mf.rt) * 0.4)
		ml.size = Vector2(lw, 0)
		var plate := ColorRect.new()
		plate.color = Color(BLACK, 0.8)
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(plate)
		add_child(ml)
		var th: float = ml.get_minimum_size().y
		ml.size = Vector2(lw, th)
		plate.position = ml.position - Vector2(12, 6)
		plate.size = Vector2(lw + 24, th + 12)
		master_label = ml


## A dashed outline (a ghost die).
func _dashed_box(r: Rect2, c: Color) -> void:
	var pts := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position]
	for e in 4:
		var a: Vector2 = pts[e]
		var b: Vector2 = pts[e + 1]
		var len: float = a.distance_to(b)
		var t := 0.0
		while t < len:
			_line([a.lerp(b, t / len), a.lerp(b, minf(t + 18.0, len) / len)], Color(c, 0.8), 5.0)
			t += 30.0


## A track marker: the Sin's colour (muted) with its sigil in ink. Mine wears a crimson ring;
## the leader wears a gold ring and a gold crown.
func _marker(c: Vector2, i: int, me: int, lead: int) -> void:
	var r: float = MARK / 2.0
	# The total (REPLY 12), always shown: above a rival's head, under mine (mine hangs below the line).
	var tl := _label(str(int(seats[i].score)), TOTAL_SIZE, BONE, INK)  # bone on ink: legible on the vignette and the cone
	tl.size = Vector2(maxf(MARK, tl.get_minimum_size().x) + 16.0, TOTAL_H)
	tl.position = Vector2(c.x - tl.size.x / 2.0, (c.y + r + 6.0) if i == me else (c.y - r - 4.0 - TOTAL_H))
	if i == lead:
		_disc(c, r + 6.0, GOLD, INK)
		var p := Polygon2D.new()
		var top := c - Vector2(0, r + 4.0 + (0.0 if i == me else TOTAL_H))  # a rival's crown sits over its total
		p.polygon = PackedVector2Array([top + Vector2(-20, 0), top + Vector2(-23, -24), top + Vector2(-10, -12),
			top + Vector2(0, -30), top + Vector2(10, -12), top + Vector2(23, -24), top + Vector2(20, 0)])
		p.color = GOLD
		add_child(p)
	# Filled with the Sin's colour, muted (Ben: the one exception to the single-glass-colour rule),
	# the sigil in dark ink on top. Mine wears a crimson ring.
	if i == me:
		_disc(c, r + 8.0, CRIMSON, CRIMSON)
	var fill: Color = Style.SIN_COLORS[seats[i].sin].lerp(BONE, 0.42)
	fill.s *= 0.8
	_disc(c, r, fill, INK)
	_sigil(seats[i].sin, Rect2(c - Vector2(r, r) * 0.92, Vector2(r, r) * 1.84), INK)


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


func _line(pts: Array, c: Color, w: float, edge := Color(0, 0, 0, 0), parent: Node = self) -> Line2D:
	if edge.a > 0.0:  # an ink edge under gold, so it reads on parchment
		_line(pts, edge, w + 6.0, Color(0, 0, 0, 0), parent)
	var ln := Line2D.new()
	ln.points = PackedVector2Array(pts)
	ln.width = w
	ln.default_color = c
	ln.begin_cap_mode = Line2D.LINE_CAP_ROUND
	ln.end_cap_mode = Line2D.LINE_CAP_ROUND
	parent.add_child(ln)
	return ln


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


## Rules.V5: my Sin's seal. Ready: a glow of my glass colour round a bone disc, my sigil in ink, live
## (seal_pressed). Idle: the bone disc and sigil, not live. Spent: dark, the sigil faint, crossed.
## Firing (REPLY 6, seen not read): the seal blazes, a wide ring of its colour round it, the sigil in
## its colour on bone; ui/table_play.gd pulses it (flare_node). Lust's seal shows the face it would give.
## A rival's seal (size RIVAL_SEAL, never live) sits beside its stake on its turn. Drawn in a holder
## centred on c, so it can pulse.
func _power_seal(parent: Node, c: Vector2, sname: String, state: String, d: float, fire: bool, face := 0) -> Control:
	var h := Control.new()
	h.position = c
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(h)
	var r: float = d / 2.0
	var o := Vector2.ZERO
	var col: Color = Style.SIN_COLORS[sname]
	var ready := state == "ready"
	var spent := state == "spent" and not fire
	if ready or fire:
		var aura := Control.new()  # the glow: a coloured halo (reads on parchment) under additive light
		aura.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(aura)
		for add in [false, true]:
			var glow := TextureRect.new()
			glow.texture = Art.soft_dot(64, col.lightened(0.3) if add else col)
			if add:
				glow.material = Art.additive()
			glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			glow.size = Vector2(d, d) * ((2.4 if fire else 2.2) if add else 2.3)
			glow.position = -glow.size / 2.0
			glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
			aura.add_child(glow)
		if ready and not fire:  # it can fire now: the glow breathes (seen, not read)
			var tw := aura.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			var half: float = Tuning.SEAL_READY_PULSE / 2.0 / Tuning.speed
			tw.tween_property(aura, "modulate:a", 0.6, half).from(1.0)
			tw.parallel().tween_property(aura, "scale", Vector2(0.88, 0.88), half).from(Vector2.ONE)
			tw.tween_property(aura, "modulate:a", 1.0, half)
			tw.parallel().tween_property(aura, "scale", Vector2.ONE, half)
		_disc(o, r + (22.0 if fire else 14.0) * d / POWER_SEAL, col.lightened(0.15) if fire else col.lightened(0.1), Color(0, 0, 0, 0), h)
	var fill: Color = INK.lerp(BLACK, 0.4) if spent else BONE
	var rival := d < POWER_SEAL  # on the dark band under the windows: a rim of its colour so it reads, no glow
	if rival and not fire:
		_disc(o, r + 11.0, Color(BONE, 0.55) if spent else col.lightened(0.2), Color(0, 0, 0, 0), h)
	_disc(o, r, fill, INK, h)
	var ink: Color = Color(BONE, 0.55 if rival else 0.3) if spent else (col.darkened(0.25) if fire else INK)
	_sigil(sname, Rect2(-Vector2(r, r) * 0.78, Vector2(r, r) * 1.56), ink, h)
	if spent:
		_line([Vector2(-r, -r) * 0.55, Vector2(r, r) * 0.55], CRIMSON, 10.0 * d / POWER_SEAL, Color(0, 0, 0, 0), h)
	if face > 0 and not spent:  # Lust: the face her seal gives
		var fd := Die.new(face, 70, 0)
		fd.position = Vector2(r * 0.42, r * 0.42)
		fd.size = Vector2(70, 70)
		fd.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(fd)
	if fire:
		flare_node = h
	return h


## My seal's tap target (live only when ready).
func _seal_hit(parent: Node, c: Vector2) -> void:
	var r: float = POWER_SEAL / 2.0
	var b := Button.new()
	b.flat = true
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	b.position = c - Vector2(r, r)
	b.size = Vector2(POWER_SEAL, POWER_SEAL)
	b.focus_mode = Control.FOCUS_NONE
	b.disabled = seal != "ready"
	b.pressed.connect(func(): seal_pressed.emit())
	parent.add_child(b)
	seal_button = b


## A power that took the stake (Greed's Cash Out, Pride's Hubris): a ring of that Sin's colour round
## the figure and its sigil at the ring's left.
func _stake_ring(r: Rect2, seat: int, parent: Node = self, ink := INK, at := Vector2(-1, -1), sigil := true) -> void:
	var col: Color = Style.SIN_COLORS[seats[seat].sin]
	var pts := []
	var c := r.get_center()
	var rr := r.size / 2.0 + Vector2(24, 16)
	for k in 41:
		pts.append(c + Vector2(cos(TAU * k / 40.0) * rr.x, sin(TAU * k / 40.0) * rr.y))
	_line(pts, col, 9.0, INK, parent)
	var s: float = minf(90.0, rr.y * 1.2)
	var sp := at if at.x >= 0.0 else Vector2(c.x - rr.x - s * 0.6, c.y - rr.y - s * 0.3)  # at: where its sigil goes instead
	if sigil:
		_sigil(seats[seat].sin, Rect2(sp, Vector2(s, s)), ink, parent)


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


## The mean true position of a group of track heads (track coordinates).
func _centre(g: Array, span: float) -> float:
	var s := 0.0
	for i in g:
		s += span * clampf(seats[i].score / GOAL, 0.0, 1.0)
	return s / g.size()


## A choice that is neither Bank nor Throw (an ability's yes or no, a target, buying dice): flat bone
## buttons in the dark gap under the windows, the question above. items: [{text, value}]. Buying
## (buy_ghosts set, REPLY 10, 11): the buttons stand in the order of where they'd leave me on the track;
## holding one shows the ghost of my marker where it would leave me (none at rest, no tie lines).
## Returns the buttons in order (ui/table_play.gd connects them; tools/fixture.gd draws
## them for a still).
func choice_row(parent: Node, question: String, items: Array) -> Array:
	var vp: Vector2 = get_viewport_rect().size
	var top: float = page_rect.position.y - UNDER_WIN + 18.0  # over the windows' feet (REPLY 16), on a dark backing
	var back := ColorRect.new()
	back.color = Color(BLACK, 0.85)
	back.position = Vector2(0, top - 18.0)
	back.size = Vector2(vp.x, page_rect.position.y - top + 18.0 - ROW_GAP)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(back)
	var words := Label.new()
	words.text = question
	words.add_theme_font_override("font", Style.SERIF)
	words.add_theme_font_size_override("font_size", 44)
	words.add_theme_color_override("font_color", BONE)
	words.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	words.clip_text = true
	words.position = Vector2(56, top)
	words.size = Vector2(vp.x - 112, 46)
	parent.add_child(words)
	var buying := not buy_ghosts.is_empty()
	var row := items.duplicate()
	if buying:  # left to right as on the track: most dice (lowest score) first, "Buy none" last
		row.sort_custom(func(a, b): return int(a.value) > int(b.value))
	var per: int = mini(row.size(), CHOICE_PER_ROW)  # past five, rows wrap onto the page under the track
	var bw: float = minf(320.0, (vp.x - 112.0 - (per - 1) * CHOICE_GAP) / per)
	var out := []
	for i in row.size():
		var it: Dictionary = row[i]
		var line: int = i / per
		var in_line: int = mini(per, row.size() - line * per)
		var x: float = (vp.x - (in_line * bw + (in_line - 1) * CHOICE_GAP)) / 2.0 + (i % per) * (bw + CHOICE_GAP)
		var y: float = top + 46.0 if line == 0 else band_bottom + 40.0 + (line - 1) * (CHOICE_H + CHOICE_GAP)
		var val = it.value
		var b := Button.new()
		b.text = str(it.text)
		b.set_meta("value", val)
		b.clip_text = true
		b.add_theme_font_override("font", Style.BLACKLETTER)
		var fs := 42
		while fs > 28 and Style.BLACKLETTER.get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > bw - 24.0:
			fs -= 2
		b.add_theme_font_size_override("font_size", fs)
		for st in ["font_color", "font_hover_color", "font_pressed_color"]:
			b.add_theme_color_override(st, INK)
		var sb := StyleBoxFlat.new()
		sb.bg_color = BONE
		sb.border_color = INK
		sb.set_border_width_all(4)
		sb.set_corner_radius_all(10)
		sb.content_margin_left = 8
		sb.content_margin_right = 8
		for st in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(st, sb)
		b.position = Vector2(x, y)
		b.size = Vector2(bw, CHOICE_H)
		if buying and val is int and val >= 1 and val <= ghost_nodes.size():  # "Buy none" has no ghost
			var gh: Control = ghost_nodes[val - 1]
			b.button_down.connect(func(): _show_ghost(gh, true))
			b.button_up.connect(func(): _show_ghost(gh, false))
		parent.add_child(b)
		out.append(b)
	return out


## Buying: a held choice shows its ghost; letting go hides it (REPLY 11: no ghosts at rest).
func _show_ghost(gh: Control, on: bool) -> void:
	if is_instance_valid(gh):
		gh.visible = on
