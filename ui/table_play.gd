## Blockout 4 (Ben, 2026-11-15): the table blockout (ui/table_blockout.gd) played for real. A layer over
## main's board, built in ui/main.gd _build_board when Tuning.table_view() is on. The game, the director,
## the prompts, the temptation offer and every overlay stay main's: this only draws the table from
## main's snapshots (_refresh), turns its Bank and Throw seals into main's answers, and steps aside
## (hides) whenever main shows something of its own (an offer, the rulebook, Settings, the game's end).
## Flat shapes only; throws, scoring and Strikes animate simply.
extends CanvasLayer

const TableBlockout = preload("res://ui/table_blockout.gd")
const Rules = preload("res://core/rules.gd")
const Style = preload("res://ui/style.gd")
const Tuning = preload("res://ui/tuning.gd")
const RulesText = preload("res://ui/rules_text.gd")

const SPEAK_FOR := 2.6   # s a spoken line stays

var main               # ui/main.gd
var view               # ui/table_blockout.gd
var _snap := {}
var _buttons: Array = []   # main's prompt Buttons now showing
var _text := ""
var _speak := {}
var _speak_left := 0.0
var _drawn := ""           # the signature of what's drawn (rebuild only on a change)
var _last := {}            # what was drawn last: throws, faces, points, strikes, cur
var _extra: Control        # the prompt's other choices, in the gap under the windows
var _landed := ""         # the throw last landed (seat, faces, throw count)
var _gain := 0             # its points, shown over the dice until the stake takes them
var _gain_base := 0
var _standings: Control
var _firing := {}          # Rules.V5: a power firing now {seat, dice}
var _master := ""          # the Master's line by the skeleton
var _master_left := 0.0
var _master_pending := ""  # said while the table was hidden: shown when it returns
var rounds_left := 0      # REPLY 10: after the Master's call, rounds left (2 penultimate, 1 final); ui/main.gd sets it
var _idle := 0.0           # s at my decision with no answer (his idle line)


func setup(m) -> void:
	main = m
	layer = 50
	view = TableBlockout.new()
	add_child(view)
	view.throw_pressed.connect(func(): _answer("roll"))
	view.bank_pressed.connect(func(): _answer("bank"))
	view.standings_pressed.connect(_open_standings)
	view.seal_pressed.connect(func(): _answer("seal"))
	view.stand_pressed.connect(func(): _answer("stand"))


## Is the table showing (main's own screens are hidden under it)?
func showing() -> bool:
	return visible


func show_state(s: Dictionary) -> void:
	_snap = s
	_draw()


func prompt(text: String, buttons: Array) -> void:
	_text = text
	_buttons = buttons
	_draw()


func prompt_cleared() -> void:
	_buttons = []
	_text = ""
	_draw()


func say(seat: int, line: String) -> void:
	if seat < 0:
		return
	_speak = {"seat": seat, "line": line}
	_speak_left = SPEAK_FOR
	_master = ""  # never the Master and a Sin at once
	_master_left = 0.0
	_draw()


## Rules.V5: a power fired (ui/main.gd _power_event, a queued beat): a ring and its Sin's sigil on the
## dice it changed, or round the stake it took; its seal blazes and pulses (REPLY 6: seen, not read).
## Held for Tuning.POWER_FOR in real seconds (only the global speed scales it), bots' turns included,
## so a rival's power gets its beat.
func power_fired(seat: int, _sname: String, changed: Array) -> void:
	_firing = {"seat": seat, "dice": changed}
	_draw()
	if visible:
		var k: float = 1.0 / maxf(Tuning.speed, 0.01)
		var h: Control = view.flare_node
		if h:
			h.scale = Vector2.ONE * 0.85
			var tw := h.create_tween()
			tw.tween_property(h, "scale", Vector2.ONE * 1.3, Tuning.SEAL_FLARE * k).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(h, "scale", Vector2.ONE, Tuning.SEAL_FLARE * 1.5 * k).set_trans(Tween.TRANS_SINE)
			# A ring of the Sin's colour spreads out from the seal and fades.
			var ring := Line2D.new()
			var pts := PackedVector2Array()
			for i in 41:
				pts.append(Vector2.from_angle(TAU * i / 40.0) * 60.0)
			ring.points = pts
			ring.width = 10.0
			ring.default_color = Style.SIN_COLORS[main.game.players[seat].sin.sin_name].lightened(0.2)
			ring.position = h.global_position
			view.add_child(ring)
			var rt := ring.create_tween().set_parallel()
			rt.tween_property(ring, "scale", Vector2.ONE * 3.2, Tuning.SEAL_FLARE * 2.5 * k).set_ease(Tween.EASE_OUT)
			rt.tween_property(ring, "modulate:a", 0.0, Tuning.SEAL_FLARE * 2.5 * k)
			rt.chain().tween_callback(ring.queue_free)
		await main.get_tree().create_timer(Tuning.POWER_FOR * k).timeout
	_firing = {}
	_draw()


## The Master of the Dance says a line (ui/main.gd master_event): ink by the skeleton for
## Tuning.MASTER_FOR; while the table is hidden it waits until the table returns.
func master_say(line: String) -> void:
	if not visible:
		_master_pending = line
		return
	_speak = {}
	_speak_left = 0.0
	_master = line
	_master_left = Tuning.MASTER_FOR
	_draw()


func _process(delta: float) -> void:
	var g = main.game
	var on: bool = g != null and main._tutor == null \
		and not is_instance_valid(main._offer_card) and main._overlay == null and main._settings == null \
		and not (main._log_overlay and main._log_overlay.visible) and not _snap.is_empty()
	if on != visible:
		visible = on
		if on and _master_pending != "":
			var l := _master_pending
			_master_pending = ""
			master_say(l)
	if _speak_left > 0.0:
		_speak_left -= delta * Tuning.pace
		if _speak_left <= 0.0:
			_speak = {}
			_draw()
	if _master_left > 0.0:
		_master_left -= delta * Tuning.pace
		if _master_left <= 0.0:
			_master = ""
			_draw()
	# No answer at my decision for a while: the Master's idle line (one a turn; main decides).
	if visible and (_live("roll") or _live("bank") or _live("seal")):
		_idle += delta
		if _idle >= Tuning.MASTER_IDLE:
			_idle = -INF  # once per decision
			main.master_idle()
	else:
		_idle = 0.0


func _live(kind: String) -> Button:
	for b in _buttons:
		if is_instance_valid(b) and not b.is_queued_for_deletion() and b.get_meta("kind", "") == kind and not b.disabled:
			return b
	return null


func _answer(kind: String) -> void:
	var b := _live(kind)
	if b:
		main.human.answered.emit(b.get_meta("value"))


func _draw() -> void:
	var s := _snap
	if s.is_empty() or int(s.get("cur", -1)) < 0 or not s.has("turn") or main.game == null:
		return
	var g = main.game
	var t: Dictionary = s.turn
	var me := 0
	var seats := []
	for i in g.players.size():
		var p = g.players[i]
		var ps: Dictionary = s.players[i]
		if p.bot == main.human:
			me = i
		var pend := []
		var debts: Array = ps.get("debts", [0, 0, 0, 0])
		if int(debts[1]) > 0:
			pend.append("strike")
		for k in int(debts[2]):
			pend.append("fewer")
		for k in int(debts[3]):
			pend.append("die")
		seats.append({"sin": p.sin.sin_name, "score": int(ps.score), "you": p.bot == main.human,
			"marks": ps.get("marks", {}), "pend": pend, "bank": int(debts[0])})
	var cur: int = s.cur
	var faces: Array = t.faces
	var strikes: int = int(t.strikes)
	if s.get("winner", false):  # the game is done (REPLY 12: it ends on the table): my side, no dice
		cur = me
		faces = []
		strikes = 0
		t = {"points": 0, "throws": 0}
	var roll := _live("roll")
	var bank := _live("bank")
	var moment := "wait"
	if strikes >= Rules.STRIKES_TO_BUST and faces.size() > 0:
		moment = "bust"
	elif cur != me:
		moment = "rival"
	elif roll or bank or _live("seal") or _live("stand"):
		moment = "decision"
	var others := _buttons.filter(func(b): return is_instance_valid(b) and not b.is_queued_for_deletion() and b.get_meta("kind", "") in ["pill", "num", "new"])
	# Rules.V5: my seal. Ready while main offers it; spent once used this turn; else unspent.
	var seals := _buttons.filter(func(b): return is_instance_valid(b) and not b.is_queued_for_deletion() and b.get_meta("kind", "") == "seal")
	if seals.size() > 1:  # Pride names a Bank: each one a bone button too
		others += seals
	var mine_p = g.players[me]
	var seal := ""
	if g.opt("powers", false) and mine_p.sin.power_window() != "":
		seal = "ready" if not seals.is_empty() else ("spent" if s.cur == me and t.get("power_used", false) else "idle")
	var seal_face: int = int(mine_p.sin.power_face(g)) if seal == "ready" and mine_p.sin.has_method("power_face") else 0
	var rival_seal := ""  # the active rival's seal on its turn
	if s.cur != me and g.opt("powers", false) and g.players[s.cur].sin.power_window() != "":
		rival_seal = "spent" if t.get("power_used", false) else "idle"
	var stand := _live("stand") != null
	# Buying (REPLY 9): dice are paid from my total, so the banked stake has landed on the track (no stake
	# or dice on the page) and each choice has a ghost of my marker where it would leave me.
	var buying := _text.begins_with("Buy dice?") and not others.is_empty()
	var ghosts := []
	if buying:
		for b in others:
			var n = b.get_meta("value", 0)
			if n is int and n > 0:
				ghosts.append(int(mine_p.score) - int(g._buy_price(mine_p, n)))
	if not others.is_empty() and (cur != me or buying):  # my choice between turns (buying dice): my side of the table
		cur = me
		moment = "wait"
		faces = []
		strikes = 0
		t = {"points": 0, "throws": 0}
	# The throw's points, in gold over the dice the moment they land, until the next beat adds them
	# to the stake (no dead wait while main's hidden board plays its scoring beat).
	var key := "%d|%s|%d" % [cur, str(faces), int(t.throws)]
	if int(t.throws) > 0 and faces.size() > 0 and key != _landed:
		_landed = key
		_gain = Rules.score(Array(faces, TYPE_INT, "", null), g.chain, g.face_mult)
		_gain_base = int(t.points)
	if key != _landed or int(t.points) != _gain_base or moment == "bust":
		_gain = 0
	var sig := "%s|%s|%d|%d|%d|%s|%s|%s|%s|%d|%s|%s|%s" % [str(seats), str(faces), int(t.points), strikes, cur, moment,
		str(_speak), str(others.map(func(b): return _word(b))), str([roll != null, bank != null, stand]), int(t.throws) * 100000 + _gain,
		seal + str(seal_face) + rival_seal + str(ghosts) + str(rounds_left), str(_firing), _master]
	if sig == _drawn:
		return
	_drawn = sig
	view.seats = seats
	view.cur = cur
	view.faces = faces
	view.points = int(t.points)
	view.strikes = mini(strikes, Rules.STRIKES_TO_BUST)
	view.moment = moment
	view.speak = _speak
	view.ability = -1
	view.bank_loss = int(seats[me].bank)
	view.gain = _gain
	view.can_bank = bank != null
	view.can_throw = roll != null
	view.safe = main._safe_insets()
	view.seal = seal
	view.seal_face = seal_face
	view.rival_seal = rival_seal
	view.buy_ghosts = ghosts
	view.firing = _firing
	view.stand_live = stand
	view.master_line = _master
	if g.called_round < 0:
		rounds_left = 0  # a new game
	view.call_at = int(g.master_call)
	view.rounds_left = rounds_left
	view.build()
	_choices(others)
	if view.gain_label:
		var gl: Label = view.gain_label
		gl.modulate.a = 0.0
		var k: float = 1.0 / maxf(Tuning.pace, 0.01)
		gl.create_tween().tween_property(gl, "modulate:a", 1.0, 0.12 * k).set_delay(0.25 * k)
	_animate(t, faces, strikes, cur, moment)
	_last = {"throws": int(t.throws), "faces": faces.duplicate(), "points": int(t.points), "strikes": strikes, "cur": cur}


## The words on one of main's prompt Buttons.
func _word(b: Button) -> String:
	if b.get_meta("kind", "") == "seal":
		return RulesText.table("hubris_name", {"n": b.get_meta("value")})
	if b.text != "":
		return b.text
	var ls := b.find_children("*", "Label", true, false)
	if not ls.is_empty():
		return ls[0].text
	var rs := b.find_children("*", "RichTextLabel", true, false)
	return rs[0].get_parsed_text() if not rs.is_empty() else str(b.get_meta("value", "?"))


## A choice that is neither Bank nor Throw (an ability's yes or no, a target, buying): the view draws
## the row (TableBlockout.choice_row); each button answers with its prompt button's value.
func _choices(others: Array) -> void:
	if is_instance_valid(_extra):
		_extra.queue_free()
	_extra = null
	if others.is_empty():
		return
	_extra = Control.new()
	_extra.set_anchors_preset(Control.PRESET_FULL_RECT)
	_extra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.add_child(_extra)
	var question: String = "Buy dice?" if _text.begins_with("Buy dice?") else _text.replace("\n", "  ")  # Ben: just the question
	var items := others.map(func(o): return {"text": _word(o), "value": o.get_meta("value")})
	for b in view.choice_row(_extra, question, items):
		var val = b.get_meta("value")
		b.pressed.connect(func(): main.human.answered.emit(val))


## Simple motion: a new throw's dice drop in, the stake swells when it grows, a Strike flashes its
## candle, a bust shakes the page.
func _animate(t: Dictionary, faces: Array, strikes: int, cur: int, moment: String) -> void:
	var k: float = 1.0 / maxf(Tuning.pace, 0.01)
	var new_throw: bool = int(t.throws) > 0 and (int(t.throws) != int(_last.get("throws", -1)) or cur != int(_last.get("cur", -1)) or faces != _last.get("faces", []))
	if new_throw:
		for i in view.dice_nodes.size():
			var d: Control = view.dice_nodes[i]
			var home := d.position
			d.pivot_offset = d.size / 2.0
			d.position = home + Vector2(randf_range(-40, 40), -160)
			d.rotation = randf_range(-0.9, 0.9)
			d.modulate.a = 0.0
			var tw := d.create_tween().set_parallel()
			tw.tween_property(d, "position", home, 0.22 * k).set_delay(0.04 * i * k).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(d, "rotation", 0.0, 0.22 * k).set_delay(0.04 * i * k)
			tw.tween_property(d, "modulate:a", 1.0, 0.1 * k).set_delay(0.04 * i * k)
	if view.stake_label and int(t.points) > int(_last.get("points", 0)) and cur == int(_last.get("cur", -1)):
		var l: Label = view.stake_label
		l.pivot_offset = l.size / 2.0
		l.scale = Vector2.ONE * 1.3
		l.create_tween().tween_property(l, "scale", Vector2.ONE, 0.3 * k).set_delay(0.2 * k).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var was: int = int(_last.get("strikes", 0)) if cur == int(_last.get("cur", -1)) else 0
	if moment != "rival" and strikes > was:
		for c in range(3 - mini(strikes, 3), 3 - was):
			var r: Rect2 = view.candle_rects[c]
			var f := ColorRect.new()
			f.color = TableBlockout.CRIMSON
			f.position = r.position - Vector2(10, 10)
			f.size = r.size + Vector2(20, 20)
			f.mouse_filter = Control.MOUSE_FILTER_IGNORE
			view.add_child(f)
			var tw := f.create_tween()
			tw.tween_property(f, "modulate:a", 0.0, 0.5 * k).set_delay(0.15 * k)
			tw.tween_callback(f.queue_free)
	if moment == "bust" and _last.get("strikes", 0) < Rules.STRIKES_TO_BUST:
		var tw: Tween = view.create_tween()
		for j in 6:
			tw.tween_property(view, "position", Vector2(18.0 * (1 if j % 2 == 0 else -1), 0), 0.04 * k)
		tw.tween_property(view, "position", Vector2.ZERO, 0.04 * k)


## The standings (a tap on the track): every seat's score, marks and pending costs, plus the pause menu.
func _open_standings() -> void:
	if is_instance_valid(_standings) or main.game == null:
		return
	var vp: Vector2 = view.get_viewport_rect().size
	_standings = Control.new()
	_standings.set_anchors_preset(Control.PRESET_FULL_RECT)
	_standings.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_standings)
	var dim := ColorRect.new()
	dim.color = Color(TableBlockout.BLACK, 0.85)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_standings.add_child(dim)
	var players: Array = main.game.players.duplicate()
	players.sort_custom(func(a, b): return a.score > b.score)
	var y: float = main._safe_insets().x + 80.0
	var head := _text_label("Standings", 72, TableBlockout.GOLD, true)
	head.position = Vector2(56, y)
	head.size = Vector2(vp.x - 112, 100)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	y += 130.0
	for p in players:
		var col: Color = Style.SIN_COLORS[p.sin.sin_name].lightened(0.2)
		var you: bool = p.bot == main.human
		var name := _text_label(p.sin.sin_name + ("  (you)" if you else ""), 52, col if not you else TableBlockout.CRIMSON.lightened(0.35), true)
		name.position = Vector2(80, y)
		name.size = Vector2(560, 70)
		var sc := _text_label(str(p.score), 60, TableBlockout.GOLD, false)
		sc.position = Vector2(vp.x - 80 - 220, y - 4)
		sc.size = Vector2(220, 76)
		sc.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		var notes := []
		for m in p.marks:
			if int(p.marks[m]) > 0:
				notes.append("%s mark x%d" % [m, int(p.marks[m])])
		if p.pend_bank > 0:
			notes.append("next Bank -%d" % p.pend_bank)
		if p.pend_strike > 0:
			notes.append("starts with a Strike")
		if p.pend_fewer + p.pend_die > 0:
			notes.append("-%d die" % (p.pend_fewer + p.pend_die))
		y += 72.0
		if not notes.is_empty():
			var nl := _text_label(", ".join(notes), 34, TableBlockout.BONE, false)
			nl.position = Vector2(80, y)
			nl.size = Vector2(vp.x - 160, 44)
			nl.clip_text = true
			y += 48.0
		y += 22.0
	var bottom: float = vp.y - main._safe_insets().y - 60.0 - 140.0
	_flat_button("Close", Vector2(80, bottom), Vector2((vp.x - 200) / 2.0, 140), func(): _close_standings())
	_flat_button("Menu", Vector2(vp.x / 2.0 + 20, bottom), Vector2((vp.x - 200) / 2.0, 140), func():
		_close_standings()
		main._open_pause())


func _close_standings() -> void:
	if is_instance_valid(_standings):
		_standings.queue_free()
	_standings = null


func _text_label(text: String, size: int, c: Color, blackletter: bool) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", Style.BLACKLETTER if blackletter else (Style.NUMERAL if text.is_valid_int() else Style.SERIF))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", c)
	l.add_theme_color_override("font_outline_color", TableBlockout.BLACK)
	l.add_theme_constant_override("outline_size", 8)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_standings.add_child(l)
	return l


func _flat_button(word: String, pos: Vector2, size: Vector2, on_press: Callable) -> void:
	var b := Button.new()
	b.text = word
	b.add_theme_font_override("font", Style.BLACKLETTER)
	b.add_theme_font_size_override("font_size", 56)
	for st in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(st, TableBlockout.INK)
	var sb := StyleBoxFlat.new()
	sb.bg_color = TableBlockout.BONE
	sb.border_color = TableBlockout.INK
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(12)
	for st in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(st, sb)
	b.position = pos
	b.size = size
	b.pressed.connect(on_press)
	_standings.add_child(b)
