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
const RulesText = preload("res://ui/rules_text.gd")
const TABLE_TEX := preload("res://assets/art/runtime/table/table.jpg")  # REPLY 25: the painted table top (SpriteCook ebfa78e3)
# REPLY 27 lettering (the REPLY 26 type sheet): dark ink on the page, no shadows or outlines; gold and light
# colours only on dark (the painted plates); Pirata One (blackletter, every numeral) and IM Fell English.
const NUM_FONT := preload("res://assets/fonts/cinzel_bold.tres")  # REPLY 28: every small numeral in Cinzel (lining figures)
const STAKE_FONT := preload("res://assets/fonts/PirataOne-Regular.ttf")  # the stake alone in Pirata One
const PAGE_SHADE := 0.3  # the page's shadow at its edges (REPLY 27: from 0.88; dark ink needs a light page)
const PAGE_L := 0.25   # the page's darkest 5% under that shadow, relative luminance (0.62 unshaded, x 0.7^2.2, rounded down)
const PLATE_L := 0.03  # the plate's centre, lightest 5% (plate.png, measured 0.026)
const PAGE_TEX := preload("res://assets/art/runtime/table/page.jpg")  # REPLY 25: painted parchment (SpriteCook 56d071ca)
const SEAL_TEX := {"Bank": preload("res://assets/art/runtime/table/seal_bank.png"), "Throw": preload("res://assets/art/runtime/table/seal_throw.png")}  # REPLY 26: painted wax, key 453b9d40, dice a72f0f1c
const CANDLE_TEX := {true: preload("res://assets/art/runtime/table/candle_lit.png"), false: preload("res://assets/art/runtime/table/candle_out.png")}  # REPLY 26: painted wax, a3e8ded5
const CANDLE_TOP := {true: 135.0, false: 211.0}  # each piece's first row of full-width wax (above: flame or smoke), source px
const WAX_DYE := Color(0.95, 0.16, 0.16)  # the next-to-go band: the candle's own wax, dyed crimson (REPLY 27)
const SNUFFED := Color(0.42, 0.38, 0.36)  # a snuffed candle, darkened, no glow (REPLY 26: reads at a glance)
const SEAL_WORD_H := 58.0  # the word's strip under the wax, inside the seal's box (no word on the wax)
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
const SPEAK_SIZE := 60  # REPLY 22 (A2): a Sin's line on the Master's plate spot, in blackletter
const SPEAK_SMALL := 48  # REPLY 24: a Sin's line that would wrap at SPEAK_SIZE
const SPEAK_SIGIL := 56.0  # its speaker's sigil disc, at the plate's left
const LINE_MIN_W := 380.0  # the Master's plate is never narrower for his arm (REPLY 17: a 6-word line in two lines)
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
const POWER_SEAL := 180.0  # my Sin's seal (Rules.V5 power), px (66 pt), above Throw
const CHOICE_H := 128.0     # a choice button: 44 pt tall at the smallest phone
const CHOICE_GAP := 36.0    # between choice buttons: 12 pt
const CHOICE_PER_ROW := 4  # REPLY 23: a target's name over its total fits four a line at SE
const RIVAL_SEAL := 110.0  # a rival's seal beside its stake on its turn, px (display only)
const BAND_PAD := 14.0    # the track band's top and bottom padding (REPLY 16: from 30, so the windows get build 116's size)
const ROBE := Color("5b3a52")  # the Master's sleeve (mark and offer arms, still blockout)
# REPLY 27: the Master is the painted fiddle piece (cb2feec5) as a bust: masked to crown, hood, skull and
# shoulders (no hands, bow or fiddle), its jaw cut out as its own piece. Source px of the 998 px piece:
const MASTER_BUST := preload("res://assets/art/runtime/table/master_bust.png")  # the piece from (64, 0)
const MASTER_JAW := preload("res://assets/art/runtime/table/master_jaw.png")    # the jaw from (417, 226)
const M_SRC := 998.0
const M_BUST_AT := Vector2(64, 0)
const M_JAW_AT := Vector2(417, 226)
const M_SPAN := 391.0  # the hood's width at mid-skull (row 167): spans the hood box (REPLY 26)
const M_TOP := 2.0     # the crown's top row
const M_JAW := 279.0   # the jaw's line
const M_FOOT := Vector2(400, 546)  # the bust's foot: he breathes and sways from here
const M_HINGE := Vector2(430, 230)  # the jaw's hinge, under the ear
const PLATE_TEX := preload("res://assets/art/runtime/table/plate.png")  # painted plate (8de13e46)
const PLATE_EDGE := 22  # its nine-patch margins (the gold border), px
const PLATE_PAD := Vector2(30, 12)  # text inset from the plate's edge
const PLATE_GAP := 8.0  # the plate's top under his jaw
const RING_GAP := 12.0  # REPLY 33: his widened plate ends this far short of the mark's gold ring
const NOTCH := Vector2(40, 22)  # REPLY 32: a rival's line plate's notch, pointing up at its window: width, height
const LINE_EDGE := 18.0  # the gutter a Sin's line plate keeps from the screen's edges and the active window (12 px at SE, REPLY 33)
const LINE_STRADDLE := 10.0  # a rival's line plate's foot, this far onto the page's top edge (above the track's tokens)
const SHORT_SCREEN := 2100.0  # layout height under which a rival's line may take 3 lines (SE: 1920)
const RECOLOUR := preload("res://ui/shaders/plate_recolour.gdshader")
const MIN_TEXT := 44  # REPLY 28: no text under 15 pt on the smallest phone (375 pt wide: 1080 / 375 px per pt)
const WORDS_DROP := 9.0  # REPLY 28: a choice row's question sits this far lower inside its plate, off the gold border (the row keeps its height: the layout is locked)
const PLATE_OVER := 92.0  # REPLY 28: the most his plate may cover the rival windows' tops (as sheeted, REPLY 26)

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
var choice_question := ""  # REPLY 23: a choice row to come (set before build()): its question and items,
var choice_items: Array = []  # so the page keeps room for its plate under the track; the dice give way
var buy_ghosts: Array = []  # buying: the score each purchase would leave me on (REPLY 9)
var ghost_nodes: Array = []  # their ghost markers, in that order
var seal_top := 0.0     # REPLY 24: the top of my seal's slot (the game end's plate stands 16 px over it)
var band_bottom := 0.0  # the foot of the track band (a choice row past five wraps below it)
var call_at := 0       # REPLY 10: the Master calls the end when the leader reaches this (0: first to 1000 wins)
var call_live := true  # REPLY 21: false before the round he may first call it (the post is dim)
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
var master_node: Control  # REPLY 27: the painted bust (ui/table_play.gd moves it)
var master_jaw: Control   # its jaw, hinged while his line shows
static var _clock := 0.0  # REPLY 27: the Master's motion runs on across rebuilds (every beat redraws the view)
var stake_label: Label
var gain_label: Label
var master_label: Label
var seal_button: Button  # my Sin's seal (Rules.V5), when drawn
var flare_node: Control  # the seal whose power is firing now (ui/table_play.gd pulses it)
var page_rect := Rect2()
var dice_area := Rect2()


## REPLY 27: the Master breathes, sways and tilts his head; while his own line shows, his jaw moves.
func _process(delta: float) -> void:
	_clock += delta
	if master_node == null or not is_instance_valid(master_node):
		return
	var b: float = sin(TAU * _clock / Tuning.MASTER_BREATH_PERIOD)
	var base: float = master_node.get_meta("scale", master_node.scale.x)
	master_node.set_meta("scale", base)
	master_node.scale = Vector2(base, base * (1.0 + Tuning.MASTER_BREATH * (b * 0.5 + 0.5)))
	master_node.rotation = deg_to_rad(Tuning.MASTER_SWAY_DEG * sin(TAU * _clock / Tuning.MASTER_SWAY_PERIOD)
		+ Tuning.MASTER_TILT_DEG * sin(TAU * _clock / Tuning.MASTER_TILT_PERIOD + 1.3))
	var open := 0.0
	if master_line != "" and is_instance_valid(master_label):
		var syl: float = maxf(0.0, sin(TAU * _clock / Tuning.MASTER_JAW_PERIOD))
		open = Tuning.MASTER_JAW_DEG * syl * (0.65 + 0.35 * sin(TAU * _clock * 0.37))
	if is_instance_valid(master_jaw):
		master_jaw.rotation = deg_to_rad(open)


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
		widest = maxf(widest, NUM_FONT.get_string_size(str(int(s.score)), HORIZONTAL_ALIGNMENT_LEFT, -1, TOTAL_SIZE).x)
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
	var row_h: float = _choice_plate(vp.x).h
	if row_h > 0.0:  # REPLY 23: a choice row's plate takes the strip (its foot 16 px over the dice); no gain shows under it
		gain_h = maxf(gain_h, row_h - 12.0)
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
		var speaking: bool = master_line == "" and not speak.is_empty() and int(speak.seat) == i  # REPLY 32: a speaking rival's window brightens
		t.modulate = Color.WHITE if i == cur or speaking else Color(0.3, 0.28, 0.3)  # REPLY 16: rivals readable against the plum
		if i != cur:  # REPLY 25: a rival's glass is dimmed by darkening only; nothing behind shows through it
			var back := _solid(t.texture)
			if back:
				var bk := TextureRect.new()
				bk.texture = back
				bk.expand_mode = t.expand_mode
				bk.stretch_mode = t.stretch_mode
				bk.position = t.position
				bk.size = t.size
				bk.mouse_filter = Control.MOUSE_FILTER_IGNORE
				add_child(bk)
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
	var board := TextureRect.new()  # REPLY 25: the table top, from the page's top line down, under the page
	board.texture = TABLE_TEX
	board.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	board.stretch_mode = TextureRect.STRETCH_TILE
	board.position = Vector2(0, pg.position.y)
	board.size = Vector2(vp.x, vp.y - pg.position.y)
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(board)
	var paper := TextureRect.new()  # REPLY 25: the painted page
	paper.texture = PAGE_TEX
	paper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	paper.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	paper.position = pg.position
	paper.size = pg.size
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(paper)
	var pool_c := Vector2(0.5, (stake_top - pg.position.y) / pg.size.y)
	var shade := TextureRect.new()
	var g := GradientTexture2D.new()
	g.fill = GradientTexture2D.FILL_RADIAL
	g.fill_from = pool_c
	g.fill_to = pool_c + Vector2(0.0, 0.62)
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	grad.colors = PackedColorArray([Color(BLACK, 0.0), Color(BLACK, PAGE_SHADE * 0.5), Color(BLACK, PAGE_SHADE)])  # REPLY 27: from 0.88, so ink reads to the page's edge
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

	# (REPLY 22, A2: a rival plays on my page: its stake, Strikes and seal in my places, below; its line and
	# every Sin's line sit on the Master's plate spot in his robe, _master_arms.)

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
		var gl := _label("1000", 46, INK, Color(0, 0, 0, 0))
		gl.size = Vector2(150, 60)
		gl.position = Vector2(ax1 - 75.0, ay + 44.0)
	else:  # REPLY 10: no finish line; the Master's post where he calls the end, crimson once called,
		# with a pip for each round left (2: the penultimate round, 1: the final round)
		_line([Vector2(ax1, ay - 18), Vector2(ax1, ay + 18)], INK, 6.0)
		var px: float = ax0 + span * clampf(float(call_at) / GOAL, 0.0, 1.0)
		var pc: Color = CRIMSON if rounds_left > 0 else (GOLD if call_live else Color("8a7a5c"))  # dim: a grey-gold bar, the number keeps its contrast
		_line([Vector2(px, ay - 40), Vector2(px, ay + 40)], pc, 16.0, INK)
		var cl := _label(str(call_at), 46, on_page(CRIMSON), Color(0, 0, 0, 0))  # REPLY 27: crimson ink on the page
		# REPLY 15: just under the line at the post, never stacked on my total; when my marker hangs near the
		# post, the number moves beside the post, on the side away from my marker.
		var post_w: float = NUM_FONT.get_string_size(str(call_at), HORIZONTAL_ALIGNMENT_LEFT, -1, 46).x + 24.0
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
	if gain > 0 and row_h <= 0.0:  # the throw's points, gold, in the strip just above the dice
		var gain_l := _label("+%d" % gain, gain_size, INK, Color(0, 0, 0, 0))  # REPLY 27: ink, no edge or shadow
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
	var pc := Vector2(throw.position.x + SEAL / 2.0, sy - 40.0 - POWER_SEAL / 2.0)
	seal_top = pc.y - POWER_SEAL / 2.0
	if seal != "" and mine:
		_power_seal(near, pc, seats[me].sin, seal, POWER_SEAL, not firing.is_empty() and int(firing.seat) == me, seal_face)
		_seal_hit(near, pc)
	elif not mine and rival_seal != "":  # REPLY 22 (A2): a rival's seal in my seal's slot, mine hidden: a flat disc, never live
		if not firing.is_empty() and int(firing.seat) == cur:
			_power_seal(self, pc, seats[cur].sin, rival_seal, POWER_SEAL, true)  # blazing as it fires
		else:
			var sc: Color = col.darkened(0.55) if rival_seal == "spent" else col.lightened(0.1)
			_disc(pc, POWER_SEAL / 2.0, sc, INK)
			var rr: float = POWER_SEAL / 2.0
			_sigil(seats[cur].sin, Rect2(pc - Vector2(rr, rr) * 0.78, Vector2(rr, rr) * 1.56), Color(BONE, 0.5) if rival_seal == "spent" else INK)
			if rival_seal == "spent":
				_line([pc - Vector2(rr, rr) * 0.55, pc + Vector2(rr, rr) * 0.55], CRIMSON, 10.0)

	# The stake: one gold numeral directly above Bank (what Bank keeps), a pending Bank loss in crimson
	# beside it. A bust blots it.
	var cw: float = 3.0 * CANDLE.x + 2.0 * CANDLE_GAP
	var c_l: float = (bank.position.x + SEAL + throw.position.x) / 2.0 - cw / 2.0
	var loss := ("-%d" % bank_loss) if bank_loss > 0 else ""
	var loss_w: float = (NUM_FONT.get_string_size(loss, HORIZONTAL_ALIGNMENT_LEFT, -1, 64).x + 16.0) if loss != "" else 0.0
	while stake_size > 90 and STAKE_FONT.get_string_size(str(points), HORIZONTAL_ALIGNMENT_LEFT, -1, stake_size).x > c_l - 40.0 - (px0 + 70.0):
		stake_size -= 4  # never under the candles
	stake_label = null
	# REPLY 22 (A2): a rival's stake stands where mine does, undimmed, "<Sin>'s turn" over it in its colour (REPLY 28: the stake in ink).
	var rcol: Color = on_page(col)  # REPLY 27: the Sin's colour darkened to 4.5:1 on the page
	if not mine or buy_ghosts.is_empty():  # buying: the stake has landed on the track (REPLY 9)
		var bc: float = bank.position.x + SEAL / 2.0
		var tw: float = STAKE_FONT.get_string_size(str(points), HORIZONTAL_ALIGNMENT_LEFT, -1, stake_size).x
		var num := _label(str(points), stake_size, INK, Color(0, 0, 0, 0), false, near if mine else self)  # REPLY 28: every stake in ink
		num.add_theme_font_override("font", STAKE_FONT)  # REPLY 28: the heaviest thing on the page
		num.size = Vector2(tw + 24.0, stake_h)
		num.position = Vector2(maxf(px0 + 70.0, bc - num.size.x / 2.0), stake_top)
		stake_label = num
		var ringed: bool = not firing.is_empty() and int(firing.seat) == cur and firing.get("dice", []).is_empty()
		if not mine and not ringed:  # REPLY 23: hidden while a power's ring is round the stake
			var whose := _label(RulesText.word("their_turn", {"name": seats[cur].sin}), 44, rcol, Color(0, 0, 0, 0), false, self)
			whose.size = Vector2(maxf(num.size.x, whose.get_minimum_size().x + 16.0), 56.0)
			whose.position = Vector2(maxf(px0 + 16.0, num.position.x + (num.size.x - whose.size.x) / 2.0), stake_top - 24.0)
		if loss != "" and mine:
			var ll := _label(loss, 64, on_page(CRIMSON), Color(0, 0, 0, 0), false, near)
			ll.size = Vector2(loss_w, 90)
			ll.position = Vector2(num.position.x + num.size.x - 8.0, stake_top - 18.0)  # raised, clear of the flames
		if not firing.is_empty() and int(firing.seat) == cur and firing.get("dice", []).is_empty():
			_stake_ring(Rect2(num.position.x + 12.0, stake_top + stake_h * 0.12, tw, stake_h * 0.76), cur, near if mine else self, INK, Vector2(-1, -1), mine or rival_seal == "")  # a rival's blazing seal is its sigil
		if bust:  # the blot covers the figure itself
			_blot(near if mine else self, Vector2(num.position.x + num.size.x / 2.0, stake_top + stake_h / 2.0), Vector2((tw / 2.0 + 28.0) / 0.91, stake_size * 0.64))
	# Marks I hold: small sigil stamps along the page's near edge.
	var marks: Dictionary = seats[me].get("marks", {})
	var mx0: float = bank.position.x + SEAL + 20.0
	for s in marks:
		for m in int(marks[s]):
			var c := Vector2(mx0 + STAMP / 2.0, pb - EDGE / 2.0)
			_disc(c, STAMP / 2.0, BONE, CRIMSON, near)
			_sigil(s, Rect2(c - Vector2(STAMP, STAMP) * 0.42, Vector2(STAMP, STAMP) * 0.84), CRIMSON, near)
			mx0 += STAMP + 12.0
	# My three Strike candles, large, on my edge between the seals: painted, lit (their glow shrinking
	# with the Strikes taken), or snuffed, darkened with no glow (REPLY 26). A Strike
	# I'll start my next turn with is a crimson band round the first candle to go.
	var struck: int = 3 if bust else strikes  # REPLY 22 (A2): a rival's Strikes on my candles, undimmed, on its turn
	var risk: int = clampi(strikes, 0, 2)
	var cpar: Control = near if mine else self
	var ct: float = pb - EDGE - CANDLE.y
	for c in 3:
		var p := Vector2(c_l + c * (CANDLE.x + CANDLE_GAP), ct)
		candle_rects.append(Rect2(p, CANDLE))
		var lit: bool = c < 3 - struck
		if lit:
			var glow := TextureRect.new()  # candlelight
			glow.texture = Art.soft_dot(64, Color("ffcf7a"))
			glow.material = Art.additive()
			glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			glow.size = Vector2(170, 170) * [1.0, 0.85, 0.6][risk]
			glow.position = p + Vector2(CANDLE.x / 2.0, -40.0) - glow.size / 2.0
			glow.modulate.a = 0.35
			glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cpar.add_child(glow)
		var tex: Texture2D = CANDLE_TEX[lit]  # REPLY 26: the painted candle, its wax fitted to the candle's box
		var cs: float = CANDLE.y / (tex.get_height() - CANDLE_TOP[lit])
		var wax := TextureRect.new()
		wax.texture = tex
		wax.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		wax.size = Vector2(tex.get_width(), tex.get_height()) * cs
		wax.position = Vector2(p.x + CANDLE.x / 2.0 - wax.size.x / 2.0, p.y + CANDLE.y - wax.size.y)
		wax.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not lit:
			wax.modulate = SNUFFED
		cpar.add_child(wax)
		if mine and pend.has("strike") and c == 2 - struck:  # the next candle to go: REPLY 27, a band of the wax itself dyed crimson
			var band_y: float = CANDLE.y * 0.42
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(0, (p.y + band_y - wax.position.y) / cs, tex.get_width(), 22.0 / cs)
			var band := TextureRect.new()
			band.texture = at
			band.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			band.position = Vector2(wax.position.x, p.y + band_y)
			band.size = Vector2(wax.size.x, 22.0)
			band.modulate = WAX_DYE
			band.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cpar.add_child(band)
	# (REPLY 14: no skeleton by the candles; the Master stands over the windows and speaks from there.)
	if master_line == "" and not speak.is_empty():
		_sin_line(win_rects[int(speak.seat)], win_rects[cur], int(speak.seat) == cur, str(seats[int(speak.seat)].sin), str(speak.line))


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
	var fall: float = y_sh + (bottom - y_sh) * 0.25
	var sw: float = head_w * 0.72  # shoulders: half-width from his centre
	# REPLY 27: the painted bust, his hood at mid-skull spanning the hood box, the crown at its top.
	var ms: float = head_w / M_SPAN
	var mo := Vector2(cx - M_SRC * ms / 2.0, top - M_TOP * ms)  # the piece's origin
	var mb := Control.new()
	mb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mb.pivot_offset = M_FOOT
	# REPLY 31: it scales round its foot (for the breath), so its position takes the pivot back out; drawn
	# where its boxes say at every size (at SE it had sat 150 px low, his plate over his skull).
	mb.position = mo - M_FOOT * (1.0 - ms)
	mb.size = Vector2(M_SRC, M_SRC)
	mb.scale = Vector2(ms, ms)
	add_child(mb)
	var bust := TextureRect.new()
	bust.texture = MASTER_BUST
	bust.position = M_BUST_AT
	bust.size = MASTER_BUST.get_size()
	bust.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mb.add_child(bust)
	var jaw := TextureRect.new()
	jaw.texture = MASTER_JAW
	jaw.position = M_JAW_AT
	jaw.size = MASTER_JAW.get_size()
	jaw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	jaw.pivot_offset = M_HINGE - M_JAW_AT
	mb.add_child(jaw)
	master_node = mb
	master_jaw = jaw
	var jaw_y: float = mo.y + M_JAW * ms
	var mask := Rect2(mo + Vector2(410, 110) * ms, Vector2(150, 205) * ms)  # the skull
	boxes["head"] = hood
	boxes["mask"] = mask
	boxes["shoulders"] = Rect2(cx - sw, y_sh - 4.0, 2.0 * sw, 8.0)
	boxes["robe"] = Rect2(0, y_sh, w, bottom - y_sh)
	return {"jaw_y": jaw_y, "cx": cx, "top": top, "y_sh": y_sh, "sw": sw, "fall": fall, "head_w": head_w, "arm_w": rw, "rt": rt, "wb": (win_rects[cur] as Rect2).end.y, "act": win_rects[cur],
		"sh_l": Vector2(cx - sw * 0.8, y_sh - rw * 0.15), "sh_r": Vector2(cx + sw * 0.8, y_sh - rw * 0.15)}  # arm joints on the shoulder line


func _run_mid(win_rects: Array, run: Array) -> float:
	if run.is_empty():
		return INF
	return ((win_rects[run[-1]] as Rect2).end.x + (win_rects[run[0]] as Rect2).position.x) / 2.0


## His gestures (REPLY 28: no arm in any pose): the round's mark is a gold ring on marked_seat's window.
## His line sits under his jaw, on the painted plate, centred on him.
func _master_arms(mf: Dictionary, win_rects: Array, px0: float, px1: float) -> void:
	var none := Color(0, 0, 0, 0)
	var cx: float = mf.cx
	var vp_w: float = get_viewport_rect().size.x
	if marked_seat >= 0 and marked_seat < win_rects.size():
		var mr: Rect2 = win_rects[marked_seat]
		var rc := Vector2(mr.get_center().x, mr.position.y + minf(46.0, mr.size.y * 0.15))
		var ring := []
		var rr: float = minf(32.0, mr.size.x * 0.28)
		for j in 41:
			ring.append(rc + Vector2.from_angle(TAU * j / 40.0) * rr)
		_line(ring, GOLD, 7.0, none)
		boxes["ring"] = Rect2(rc - Vector2(rr + 3.5, rr + 3.5), Vector2(rr + 3.5, rr + 3.5) * 2.0)
	# REPLY 28: no arm in any pose (call, mark, offer): his plate and the mark's gold ring only.
	# REPLY 22 (A2): a Sin's spoken line takes the same spot, in its blackletter and colour, its sigil at the left.
	var text: String = master_line  # REPLY 32: a Sin's line is on its own window (_sin_line), never here
	var who := ""
	if text != "":  # REPLY 17: his words on an ink plate in his robe, just above the rivals' tops, centred on him
		var act: Rect2 = mf.act  # never across the active window, which is as tall as the wall
		var lo: float = maxf(px0 + 16.0, 52.0)
		var hi: float = minf(px1 - 16.0, vp_w - 52.0)
		if act.get_center().x < cx:
			lo = maxf(lo, act.end.x + 12.0)
		else:
			hi = minf(hi, act.position.x - 12.0)
		for k in ["card", "arm"]:  # nor across the card in his hand, nor his reaching arm if two lines still fit
			if not boxes.has(k):
				continue
			var r: Rect2 = boxes[k]
			var l2: float = lo
			var h2: float = hi
			if r.get_center().x < cx:
				l2 = maxf(lo, r.end.x + 12.0)
			else:
				h2 = minf(hi, r.position.x - 12.0)
			if k == "card" or h2 - l2 >= LINE_MIN_W:
				lo = l2
				hi = h2
		var sg: float = 0.0 if who == "" else SPEAK_SIGIL + 14.0  # the speaker's sigil, left of the words
		var lw: float = hi - lo - sg
		var ml := Style.label(text, 44 if who == "" else SPEAK_SIZE, BONE if who == "" else on_plate(Style.SIN_COLORS[who].lightened(0.25)), who != "")  # REPLY 27: no outline, 4.5:1 on the plate
		ml.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		ml.custom_minimum_size = Vector2(lw, 0)
		ml.size = Vector2(lw, 0)
		var plate := NinePatchRect.new()  # REPLY 27: the painted plate
		plate.texture = PLATE_TEX
		plate.patch_margin_left = PLATE_EDGE
		plate.patch_margin_right = PLATE_EDGE
		plate.patch_margin_top = PLATE_EDGE
		plate.patch_margin_bottom = PLATE_EDGE
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(plate)
		add_child(ml)
		var th: float = ml.get_minimum_size().y
		# REPLY 23: the plate ends inside his figure, never on the black wall: its ends follow his outline at the
		# middle of a two-line plate (one pass; his own line never narrower than LINE_MIN_W).
		var fs: float = 44.0 if who == "" else float(SPEAK_SIZE)
		var room := Vector2(lo, hi)  # the room clear of the active window and the card, before his outline narrows it
		var clear := room  # REPLY 33: that room less the mark's gold ring and RING_GAP, preferred when one line fits
		if boxes.has("ring"):
			var rg: Rect2 = boxes["ring"]
			if rg.get_center().x > cx:
				clear.y = minf(clear.y, rg.position.x - RING_GAP - PLATE_PAD.x)
			else:
				clear.x = maxf(clear.x, rg.end.x + RING_GAP + PLATE_PAD.x)
		var hw: float = _figure_half_w(mf, mf.rt - 12.0 - 6.0 - fs * 1.25) - 12.0
		var l3: float = maxf(lo, mf.cx - hw + 12.0)
		var h3: float = minf(hi, mf.cx + hw - 12.0)
		var floor_w: float = LINE_MIN_W if who == "" else SPEAK_SIGIL + 14.0 + 200.0  # a Sin's line always fits: the sigil on him
		if h3 - l3 >= floor_w and h3 - l3 < hi - lo:
			lo = l3
			hi = h3
			lw = hi - lo - sg
			ml.custom_minimum_size = Vector2(lw, 0)
			ml.size = Vector2(lw, 0)
			th = ml.get_minimum_size().y
		if who == "" and ml.get_line_count() > 1:  # REPLY 32: his line widens to one line when the room beside him allows
			var one: float = ml.get_theme_font("font").get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(fs)).x + 4.0
			if one <= clear.y - clear.x:
				room = clear
			if one <= room.y - room.x:  # REPLY 33: one line even if it then meets the ring, never wrapped (reported)
				lw = one
				lo = clampf(mf.cx - one / 2.0, room.x, room.y - one)
				hi = lo + one
				ml.custom_minimum_size = Vector2(lw, 0)
				ml.size = Vector2(lw, 0)
				th = ml.get_minimum_size().y
		if who != "" and ml.get_line_count() > 1:  # REPLY 24: a Sin's line that would wrap drops to SPEAK_SMALL
			ml.add_theme_font_size_override("font_size", SPEAK_SMALL)
			th = ml.get_minimum_size().y
		if who == "":  # REPLY 28: his plate stands at most PLATE_OVER px over the rival tops; his words step down to fit
			while ml.get_theme_font_size("font_size") - 2 >= MIN_TEXT and mf.jaw_y + PLATE_GAP + th + 2.0 * PLATE_PAD.y - mf.rt > PLATE_OVER:
				ml.add_theme_font_size_override("font_size", ml.get_theme_font_size("font_size") - 2)
				th = ml.get_minimum_size().y
		ml.size = Vector2(lw, th)
		# REPLY 27: its top 8 px under his jaw; it may stand over the rival windows' tops (TableSpec).
		ml.position = Vector2(lo + sg, mf.jaw_y + PLATE_GAP + PLATE_PAD.y)
		plate.position = Vector2(lo - PLATE_PAD.x, mf.jaw_y + PLATE_GAP)
		plate.size = Vector2(lw + sg + 2.0 * PLATE_PAD.x, th + 2.0 * PLATE_PAD.y)
		boxes["line"] = Rect2(plate.position, plate.size)
		if who != "":
			var c := Vector2(lo + SPEAK_SIGIL / 2.0, ml.position.y + th / 2.0)
			_disc(c, SPEAK_SIGIL / 2.0, Style.SIN_COLORS[who].lightened(0.1), INK)
			_sigil(who, Rect2(c - Vector2(SPEAK_SIGIL, SPEAK_SIGIL) * 0.39, Vector2(SPEAK_SIGIL, SPEAK_SIGIL) * 0.78), INK)
		else:
			master_label = ml


## A Sin's line (TableSpec exception 2, REPLY 28/31/32) at the foot of its own window, on the painted plate with
## its gold border recoloured in that Sin's colour. Active: inside its window's foot, at least the window's width,
## centred and clamped to the screen. Rival: its foot on the page's top edge, so it straddles its window's foot
## and grows upward over the rival row, never down over the track; a notch points up at its window.
## At most 2 lines (a rival 3 on a short screen): the plate widens first, then the size steps down; the lines are
## balanced, never a one-word line.
func _sin_line(win: Rect2, act: Rect2, active: bool, who: String, text: String) -> void:
	var vw: float = get_viewport_rect().size.x
	var col: Color = Style.SIN_COLORS[who]
	var ml := Style.label(text, SPEAK_SIZE, on_plate(col.lightened(0.25)), true)
	ml.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	ml.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var plate := NinePatchRect.new()
	plate.texture = PLATE_TEX
	for m in ["patch_margin_left", "patch_margin_right", "patch_margin_top", "patch_margin_bottom"]:
		plate.set(m, PLATE_EDGE)
	plate.material = _recolour(col.lightened(0.15))
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(plate)
	add_child(ml)
	var max_lines: int = 2 if active or get_viewport_rect().size.y >= SHORT_SCREEN else 3
	# REPLY 33: the room: the screen less LINE_EDGE; a rival's never over the active window, on its own side of it
	var lo: float = LINE_EDGE
	var hi: float = vw - LINE_EDGE
	if not active:
		if act.get_center().x < win.get_center().x:
			lo = maxf(lo, act.end.x + LINE_EDGE)
		else:
			hi = minf(hi, act.position.x - LINE_EDGE)
	var maxw: float = hi - lo
	var fit: Vector3 = _fit_line(ml, win.size.x - 2.0 * PLATE_PAD.x, maxw - 2.0 * PLATE_PAD.x, max_lines)
	var w: float = maxf(win.size.x, fit.x + 2.0 * PLATE_PAD.x)
	var h: float = fit.y + 2.0 * PLATE_PAD.y
	var x: float = clampf(win.get_center().x - w / 2.0, lo, hi - w)
	if not active:  # REPLY 33: from its own window's edge away from the active window, growing over the other rivals
		x = clampf(win.position.x if act.get_center().x < win.get_center().x else win.end.x - w, lo, hi - w)
	var foot: float = win.end.y if active else page_rect.position.y + LINE_STRADDLE
	var rect := Rect2(x, foot - h, w, h)
	if not active:
		var tip := Vector2(win.get_center().x, rect.position.y - NOTCH.y)
		var base_y: float = rect.position.y + 6.0
		var notch := Polygon2D.new()
		notch.polygon = PackedVector2Array([Vector2(tip.x - NOTCH.x / 2.0, base_y), Vector2(tip.x + NOTCH.x / 2.0, base_y), tip])
		notch.color = Color(0.17, 0.12, 0.09)
		add_child(notch)
		move_child(notch, plate.get_index())
		var edge := _line([Vector2(tip.x - NOTCH.x / 2.0, rect.position.y + 3.0), tip, Vector2(tip.x + NOTCH.x / 2.0, rect.position.y + 3.0)], col.lightened(0.15), 4.0)
		edge.joint_mode = Line2D.LINE_JOINT_ROUND
		move_child(edge, plate.get_index())
	plate.position = rect.position
	plate.size = rect.size
	ml.custom_minimum_size = Vector2(fit.z, 0)
	ml.size = Vector2(fit.z, fit.y)
	ml.position = Vector2(rect.get_center().x - fit.z / 2.0, rect.position.y + PLATE_PAD.y)
	boxes["line"] = rect


## The words within max_lines: the most lines (up to max_lines) for which every line keeps two words or more,
## each balanced (the narrowest width that keeps that many lines, never under the longest word) and within hi;
## else fewer lines; else the next size down (SPEAK_SIZE, SPEAK_SMALL, MIN_TEXT).
## Returns (the plate's text width, at least lo; text height; the words' width).
func _fit_line(ml: Label, lo: float, hi: float, max_lines: int) -> Vector3:
	var words: PackedStringArray = ml.text.split(" ", false)
	for s in [SPEAK_SIZE, SPEAK_SMALL, MIN_TEXT]:
		ml.add_theme_font_size_override("font_size", s)
		var f: Font = ml.get_theme_font("font")
		var longest := 0.0
		for wd in words:
			longest = maxf(longest, f.get_string_size(wd, HORIZONTAL_ALIGNMENT_LEFT, -1, s).x + 4.0)
		for n in range(mini(max_lines, words.size()), 0, -1):
			var w := _narrowest(ml, n, longest, hi)
			if w < 0.0:
				continue
			_wrap(ml, w)
			var ok := true
			if n > 1:
				for i in ml.get_line_count():
					if _line_words(ml, i) < 2:
						ok = false
			if ok:
				return Vector3(maxf(w, lo), ml.get_minimum_size().y, w)
	_wrap(ml, hi)
	return Vector3(hi, ml.get_minimum_size().y, hi)


## The narrowest width in [lo, hi] at which the words take n lines or fewer; -1 if hi is not enough.
func _narrowest(ml: Label, n: int, lo: float, hi: float) -> float:
	if _wrap(ml, hi) > n:
		return -1.0
	var a := lo
	var b := hi
	if _wrap(ml, a) <= n:
		return a
	while b - a > 2.0:
		var m := (a + b) / 2.0
		if _wrap(ml, m) <= n:
			b = m
		else:
			a = m
	return b


func _wrap(ml: Label, w: float) -> int:
	ml.custom_minimum_size = Vector2(w, 0)
	ml.size = Vector2(w, 0)
	return ml.get_line_count()


## How many words line i of the label holds, wrapped as the label wraps.
func _line_words(ml: Label, i: int) -> int:
	var s: int = ml.get_theme_font_size("font_size")
	var para := TextParagraph.new()
	para.add_string(ml.text, ml.get_theme_font("font"), s)
	para.width = ml.size.x
	para.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
	if i >= para.get_line_count():
		return 0
	var r: Vector2i = para.get_line_range(i)
	return ml.text.substr(r.x, r.y - r.x).split(" ", false).size()


## The plate's gold border recoloured (its darker wood is left as it is).
static func _recolour(tint: Color) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = RECOLOUR
	mat.set_shader_parameter("tint", tint)
	return mat


## His figure's half-width at height y: the hood's dome, its sides flaring to the shoulders, then the robe.
func _figure_half_w(mf: Dictionary, y: float) -> float:
	var ry: float = (mf.y_sh - mf.top) * 0.5
	var cy: float = mf.top + ry
	var hr: float = mf.head_w / 2.0
	if y < cy:
		var d: float = clampf((cy - y) / maxf(1.0, ry), 0.0, 1.0)
		return hr * sqrt(1.0 - d * d)
	if y < mf.y_sh:
		return lerpf(hr, mf.sw * 0.95, (y - cy) / maxf(1.0, mf.y_sh + 12.0 - cy))
	return mf.sw * (1.0 + 0.9 * clampf((y - mf.y_sh) / maxf(1.0, mf.fall - mf.y_sh), 0.0, 1.0))


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
	var tl := _label(str(int(seats[i].score)), TOTAL_SIZE, INK, Color(0, 0, 0, 0))  # REPLY 27: ink on the page
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
	if text.lstrip("+-").is_valid_int():  # REPLY 28: small numerals in Cinzel (the stake overrides to Pirata One)
		l.add_theme_font_override("font", NUM_FONT)
	if outline.a > 0.0:
		l.add_theme_color_override("font_outline_color", outline)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	parent.add_child(l)
	return l


## A window's shape in solid near-black (every pixel the glass covers at all), to back a dimmed window. Cached.
static var _solids := {}
func _solid(tex: Texture2D) -> Texture2D:
	var key := tex.get_instance_id()
	if not _solids.has(key):
		var img: Image = tex.get_image()
		if img == null:  # headless: no pixels
			return null
		img = img.duplicate()
		if img.is_compressed():
			img.decompress()
		img.convert(Image.FORMAT_RGBA8)
		for y in img.get_height():
			for x in img.get_width():
				img.set_pixel(x, y, Color(BLACK, 1.0) if img.get_pixel(x, y).a > 0.02 else Color(0, 0, 0, 0))
		_solids[key] = ImageTexture.create_from_image(img)
	return _solids[key]


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
	# REPLY 26: painted wax over the top of the box, no word on it; the word under it, inside the box.
	# The box is still the tap target. Pressed darkens the wax; not live, the caller dims the whole seal.
	var b := Button.new()
	var none := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "disabled", "focus"]:
		b.add_theme_stylebox_override(st, none)
	b.size = Vector2(SEAL, SEAL)
	b.custom_minimum_size = b.size
	b.position = pos
	b.disabled = not live
	b.focus_mode = Control.FOCUS_NONE
	b.set_meta("word", word)
	var d: float = SEAL - SEAL_WORD_H
	var wax := TextureRect.new()
	wax.texture = SEAL_TEX[word]
	wax.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wax.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	wax.position = Vector2(SEAL_WORD_H / 2.0, 0)
	wax.size = Vector2(d, d)
	wax.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(wax)
	b.button_down.connect(func(): wax.modulate = Color(0.7, 0.7, 0.7))
	b.button_up.connect(func(): wax.modulate = Color.WHITE)
	var l := Label.new()
	l.text = word
	l.add_theme_font_override("font", Style.BLACKLETTER)
	l.add_theme_font_size_override("font_size", 48)
	l.add_theme_color_override("font_color", INK if word == "Bank" else on_page(fill))  # REPLY 27: ink on the page
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.position = Vector2(-20, d - 6)
	l.size = Vector2(SEAL + 40, SEAL_WORD_H + 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(l)
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
## REPLY 23: every choice row but the game's end sits on its own plate on the page under the track: the
## question (up to two lines), then the buttons, at most CHOICE_PER_ROW a line (buying: all on one line).
## build() keeps room for it from choice_question and choice_items. {h, per, words_h}; h 0 when none.
func _choice_plate(vw: float) -> Dictionary:
	var n := choice_items.size()
	if n == 0 or choice_items.any(func(it): return str(it.value) == "new"):
		return {"h": 0.0, "per": maxi(n, 1), "words_h": 46.0}
	var per: int = n if not buy_ghosts.is_empty() else mini(n, CHOICE_PER_ROW)
	var lines: int = ceili(float(n) / per)
	var probe := _choice_words(choice_question, vw)
	add_child(probe)  # measured in the tree, as drawn: one line or two
	var words_h: float = maxf(46.0, probe.get_minimum_size().y)
	remove_child(probe)
	probe.free()
	return {"h": 18.0 + words_h + lines * CHOICE_H + (lines - 1) * CHOICE_GAP + 24.0, "per": per, "words_h": words_h}


## A choice row's question, wrapping onto a second line when it must.
func _choice_words(question: String, vw: float) -> Label:
	var words := Label.new()
	words.text = question
	words.add_theme_font_override("font", Style.SERIF)
	words.add_theme_font_size_override("font_size", 44)
	words.add_theme_color_override("font_color", GOLD)  # REPLY 27: gold on the plate
	words.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	words.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.custom_minimum_size = Vector2(vw - 112.0, 0)
	words.size = Vector2(vw - 112.0, 0)
	return words


func choice_row(parent: Node, question: String, items: Array) -> Array:
	var vp: Vector2 = get_viewport_rect().size
	choice_question = question
	choice_items = items
	var plate: Dictionary = _choice_plate(vp.x)
	# REPLY 19 item 3: the game's end ("New game") sits on the page where the dice were, so my window and every
	# total on the track stay in view.
	var at_end: bool = items.any(func(it): return str(it.value) == "new")
	var top: float = band_bottom + 30.0
	if at_end:  # REPLY 24: its plate's foot 16 px over my seal (the plate is 18 px above the words to 36 px under the row)
		top = seal_top - 16.0 - (46.0 + CHOICE_H + 36.0) + 18.0
	var words_h: float = plate.words_h
	var back := NinePatchRect.new()  # REPLY 27: the painted plate, not a flat bar
	back.texture = PLATE_TEX
	back.patch_margin_left = PLATE_EDGE
	back.patch_margin_right = PLATE_EDGE
	back.patch_margin_top = PLATE_EDGE
	back.patch_margin_bottom = PLATE_EDGE
	back.position = Vector2(page_rect.position.x, top - 18.0)
	back.size = Vector2(page_rect.size.x, (46.0 + CHOICE_H + 36.0) if at_end else plate.h)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(back)
	var words := _choice_words(question, vp.x)
	words.position = Vector2(56, top - 4.0 + (WORDS_DROP if words_h <= 46.0 else 0.0))  # REPLY 28: one line drops clear of the gold border; two lines already clear it
	words.size = Vector2(vp.x - 112, words_h)
	parent.add_child(words)
	var buying := not buy_ghosts.is_empty()
	var row := items.duplicate()
	if buying:  # REPLY 21: one row, low to high: "Buy none" first, then 1 up to what I can afford (at most Rules.MAX_BUY)
		row.sort_custom(func(a, b): return int(a.value) < int(b.value))
	var per: int = plate.per
	var bw: float = minf(320.0, (vp.x - 112.0 - (per - 1) * CHOICE_GAP) / per)
	var out := []
	for i in row.size():
		var it: Dictionary = row[i]
		var line: int = i / per
		var in_line: int = mini(per, row.size() - line * per)
		var x: float = (vp.x - (in_line * bw + (in_line - 1) * CHOICE_GAP)) / 2.0 + (i % per) * (bw + CHOICE_GAP)
		var y: float = top + words_h + line * (CHOICE_H + CHOICE_GAP)
		var val = it.value
		var b := Button.new()
		b.text = str(it.text)
		# REPLY 21, 23: "Buy 3" over its price, a target's name over its total, so neither shrinks below 15 pt
		var m := RegEx.create_from_string("^(.+) [(]([0-9]+)[)]$").search(b.text)
		if m:
			b.text = m.get_string(1) + "\n" + m.get_string(2)
		if buying and not m and b.text.begins_with("Buy "):  # "Buy none": the same two lines
			b.text = b.text.replace("Buy ", "Buy\n")
		b.set_meta("value", val)
		b.clip_text = true
		b.add_theme_font_override("font", Style.BLACKLETTER)
		var fs := MIN_TEXT + 4
		var widest := 0.0
		for part in b.text.split("\n"):
			widest = maxf(widest, Style.BLACKLETTER.get_string_size(part, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
		while fs > MIN_TEXT and widest > bw - 24.0:
			fs -= 2
			widest = 0.0
			for part in b.text.split("\n"):
				widest = maxf(widest, Style.BLACKLETTER.get_string_size(part, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
		b.add_theme_font_size_override("font_size", fs)
		for st in ["font_color", "font_hover_color", "font_pressed_color"]:
			b.add_theme_color_override(st, INK)
		var parts: PackedStringArray = b.text.split("\n")
		if parts.size() == 2 and parts[1].is_valid_int():  # REPLY 28: the word in Pirata One over its number in Cinzel
			b.text = ""
			for j in 2:
				var pl := Label.new()
				pl.text = parts[j]
				pl.add_theme_font_override("font", Style.BLACKLETTER if j == 0 else NUM_FONT)
				pl.add_theme_font_size_override("font_size", fs)  # REPLY 28: both at the button's size, never under MIN_TEXT
				pl.add_theme_color_override("font_color", INK)
				pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				pl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				pl.position = Vector2(0, 8.0 + j * (CHOICE_H - 16.0) / 2.0)
				pl.size = Vector2(bw, (CHOICE_H - 16.0) / 2.0)
				pl.mouse_filter = Control.MOUSE_FILTER_IGNORE
				b.add_child(pl)
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


## REPLY 27: a colour darkened in steps until it reads 4.5:1 on the page's darkest 5%.
static func on_page(c: Color) -> Color:
	var out := c
	for i in 40:
		if _contrast(_rl(out), PAGE_L) >= 4.5:
			break
		out = out.darkened(0.05)
	return out


## A colour lightened in steps until it reads 4.5:1 on the plate's lightest 5%.
static func on_plate(c: Color) -> Color:
	var out := c
	for i in 40:
		if _contrast(_rl(out), PLATE_L) >= 4.5:
			break
		out = out.lightened(0.05)
	return out


static func _contrast(a: float, b: float) -> float:
	return (maxf(a, b) + 0.05) / (minf(a, b) + 0.05)


## WCAG relative luminance.
static func _rl(c: Color) -> float:
	var f := func(v: float) -> float: return v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * f.call(c.r) + 0.7152 * f.call(c.g) + 0.0722 * f.call(c.b)
