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


func setup(m) -> void:
	main = m
	layer = 50
	view = TableBlockout.new()
	add_child(view)
	view.throw_pressed.connect(func(): _answer("roll"))
	view.bank_pressed.connect(func(): _answer("bank"))
	view.standings_pressed.connect(_open_standings)


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
	_draw()


func _process(delta: float) -> void:
	var g = main.game
	var on: bool = g != null and main._tutor == null and g.winner == null \
		and not is_instance_valid(main._offer_card) and main._overlay == null and main._settings == null \
		and not (main._log_overlay and main._log_overlay.visible) and not _snap.is_empty()
	if on != visible:
		visible = on
	if _speak_left > 0.0:
		_speak_left -= delta * Tuning.pace
		if _speak_left <= 0.0:
			_speak = {}
			_draw()


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
	var roll := _live("roll")
	var bank := _live("bank")
	var moment := "wait"
	if strikes >= Rules.STRIKES_TO_BUST and faces.size() > 0:
		moment = "bust"
	elif cur != me:
		moment = "rival"
	elif roll or bank:
		moment = "decision"
	var others := _buttons.filter(func(b): return is_instance_valid(b) and not b.is_queued_for_deletion() and b.get_meta("kind", "") in ["pill", "num", "new"])
	if not others.is_empty() and cur != me:  # my choice between turns (buying dice): my side of the table
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
	var sig := "%s|%s|%d|%d|%d|%s|%s|%s|%s|%d" % [str(seats), str(faces), int(t.points), strikes, cur, moment,
		str(_speak), str(others.map(func(b): return _word(b))), str([roll != null, bank != null]), int(t.throws) * 100000 + _gain]
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
	view.can_bank = bank != null
	view.can_throw = roll != null
	view.safe = main._safe_insets()
	view.build()
	_choices(others)
	if _gain > 0:
		var a: Rect2 = view.dice_area
		var gl := Label.new()
		gl.text = "+%d" % _gain
		gl.add_theme_font_override("font", Style.NUMERAL)
		gl.add_theme_font_size_override("font_size", 120)
		gl.add_theme_color_override("font_color", TableBlockout.GOLD)
		gl.add_theme_color_override("font_outline_color", TableBlockout.INK)
		gl.add_theme_constant_override("outline_size", 14)
		gl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		gl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		gl.size = Vector2(a.size.x, 180)
		gl.position = Vector2(a.position.x, a.get_center().y - 90.0)
		gl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		view.add_child(gl)
		gl.modulate.a = 0.0
		var k: float = 1.0 / maxf(Tuning.pace, 0.01)
		gl.create_tween().tween_property(gl, "modulate:a", 1.0, 0.12 * k).set_delay(0.25 * k)
	_animate(t, faces, strikes, cur, moment)
	_last = {"throws": int(t.throws), "faces": faces.duplicate(), "points": int(t.points), "strikes": strikes, "cur": cur}


## The words on one of main's prompt Buttons.
func _word(b: Button) -> String:
	if b.text != "":
		return b.text
	var ls := b.find_children("*", "Label", true, false)
	if not ls.is_empty():
		return ls[0].text
	var rs := b.find_children("*", "RichTextLabel", true, false)
	return rs[0].get_parsed_text() if not rs.is_empty() else str(b.get_meta("value", "?"))


## A choice that is neither Bank nor Throw (an ability's yes or no, a target): flat bone buttons in the
## dark gap under the windows, with the prompt's words above them.
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
	var vp: Vector2 = view.get_viewport_rect().size
	var top: float = view.page_rect.position.y - TableBlockout.UNDER_WIN + 22.0  # under my crimson bar
	var words := Label.new()
	words.text = "Buy dice?" if _text.begins_with("Buy dice?") else _text.replace("\n", "  ")  # Ben: just the question
	words.add_theme_font_override("font", Style.SERIF)
	words.add_theme_font_size_override("font_size", 36)
	words.add_theme_color_override("font_color", TableBlockout.BONE)
	words.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	words.clip_text = true
	words.position = Vector2(56, top)
	words.size = Vector2(vp.x - 112, 40)
	_extra.add_child(words)
	var bw: float = minf(320.0, (vp.x - 112.0 - (others.size() - 1) * 40.0) / others.size())
	var x: float = (vp.x - (others.size() * bw + (others.size() - 1) * 40.0)) / 2.0
	for o in others:
		var b := Button.new()
		b.text = _word(o)
		b.clip_text = true
		b.add_theme_font_override("font", Style.BLACKLETTER)
		var fs := 42
		while fs > 28 and Style.BLACKLETTER.get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > bw - 24.0:
			fs -= 2
		b.add_theme_font_size_override("font_size", fs)
		for st in ["font_color", "font_hover_color", "font_pressed_color"]:
			b.add_theme_color_override(st, TableBlockout.INK)
		var sb := StyleBoxFlat.new()
		sb.bg_color = TableBlockout.BONE
		sb.border_color = TableBlockout.INK
		sb.set_border_width_all(4)
		sb.set_corner_radius_all(10)
		sb.content_margin_left = 8
		sb.content_margin_right = 8
		for st in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(st, sb)
		b.position = Vector2(x, top + 40.0)
		b.size = Vector2(bw, 122)  # 44 pt
		var val = o.get_meta("value")
		b.pressed.connect(func(): main.human.answered.emit(val))
		_extra.add_child(b)
		x += bw + 40.0


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
		if p.in_purgatory:
			notes.append("in Purgatory")
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
