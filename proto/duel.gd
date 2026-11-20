## Greybox duel (rework direction B, throwaway): you against one Sin, heads-up, on today's core/ (V5 with the
## table's options, no bets). Plain shapes plus the glass art and fonts. A rival's turn is one beat:
##   A (default): the result only, held RESULT_HOLD s.   B: its throws flash past (FLASH_THROW s each).
## Keys: V switches A/B, N starts a new duel. Debug line: seconds since your last answer, match time, round.
## Each duel appends one line to user://duel_log.jsonl (waits between decisions, length, result).
## godot --path . res://proto/duel.tscn -- --table [sin=Wrath rival=Greed variant=B se]
## (--table: ui/rules_text.gd words the powers for V5.) Tests: auto=<duels> speed=<x> seed=<n> shot=<folder>.
extends Control

const Rules = preload("res://core/rules.gd")
const Game = preload("res://core/game.gd")
const BotPolicy = preload("res://ai/bot_policy.gd")
const Human = preload("res://ui/human.gd")
const Art = preload("res://ui/art.gd")
const Style = preload("res://ui/style.gd")
const RulesText = preload("res://ui/rules_text.gd")
const DuelSim = preload("res://proto/duel_sim.gd")
const NAMES := ["Wrath", "Greed", "Lust", "Envy", "Pride", "Gluttony", "Sloth"]
const SIN_SCRIPTS := [
	preload("res://sins/wrath.gd"), preload("res://sins/greed.gd"), preload("res://sins/lust.gd"),
	preload("res://sins/envy.gd"), preload("res://sins/pride.gd"), preload("res://sins/gluttony.gd"),
	preload("res://sins/sloth.gd"),
]

const RESULT_HOLD := 1.2     # variant A: the rival's whole turn is this one beat
const FLASH_THROW := 0.45    # variant B: each rival throw shows this long
const FLASH_END := 0.8       # variant B: its result
const MY_THROW := 0.35       # my dice land
const BG := Color("120c0a")
const INK := Color("e8dcbc")
const DIM := Color("8a7d66")
const GOLD := Color("d9a520")
const CRIMSON := Color("b0202a")

var game
var human
var me
var rival
var my_sin := ""
var rival_sin := ""
var variant := "A"
var tempt_tip_seen := false  # ui/human.gd reads and sets it

var _t_match := 0.0
var _t_last_answer := -1.0
var _waits: Array = []       # seconds from my last answer to my next prompt
var _prompt_at := -1.0
var _rival_start := 0
var _rival_line := ""
var _status := ""
var _over := false
var _auto := 0
var _duels_done := 0
var _shots := ""
var _shot_taken := {}

# Nodes
var _window: TextureRect
var _rival_name: Label
var _race: Control
var _beat: Label
var _dice_row: HBoxContainer
var _stake: Label
var _strikes: Label
var _note: Label
var _buttons: HBoxContainer
var _extra: VBoxContainer
var _offer: PanelContainer
var _offer_box: CenterContainer
var _debug: Label


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("sin="):
			my_sin = a.substr(4)
		elif a.begins_with("rival="):
			rival_sin = a.substr(6)
		elif a.begins_with("variant="):
			variant = a.substr(8).to_upper()
		elif a.begins_with("auto="):
			_auto = int(a.substr(5))  # play this many duels yourself, then quit (tests, timings)
		elif a.begins_with("speed="):
			Engine.time_scale = float(a.substr(6))
		elif a.begins_with("shot="):
			_shots = a.substr(5)  # a folder: one PNG at the first decision, the first offer, a rival result, the end
		elif a.begins_with("seed="):
			seed(int(a.substr(5)))
		elif a == "se":
			DisplayServer.window_set_size(Vector2i(750, 1334))  # iPhone SE, as tools/fixture.gd SIZES
			get_window().size = Vector2i(750, 1334)
	if not OS.get_cmdline_user_args().has("--table"):
		push_warning("proto/duel: launch with -- --table, or the power lines are worded for V4")
	_build()
	_new_duel()


func _process(delta: float) -> void:
	if not _over:
		_t_match += delta
	var since := "" if _t_last_answer < 0 else "%.1f s since your last answer" % (_t_match - _t_last_answer)
	var med := "-"
	if not _waits.is_empty():
		var s := _waits.duplicate()
		s.sort()
		med = "%.1f" % s[s.size() / 2]
	_debug.text = "variant %s (V) | %s | waits median %s s, %d decisions | match %d:%02d | round %d" % [
		variant, since, med, _waits.size(), int(_t_match) / 60, int(_t_match) % 60, game.round_count if game else 0]


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		if e.keycode == KEY_V:
			variant = "B" if variant == "A" else "A"
		elif e.keycode == KEY_N:
			_new_duel()


# ---------- Layout ----------

func _label(size: int, col := INK, font: Font = Style.SERIF) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		m.add_theme_constant_override("margin_" + side, 48)
	m.add_theme_constant_override("margin_top", 80)
	m.add_theme_constant_override("margin_bottom", 60)
	add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	m.add_child(v)
	_debug = _label(24, DIM)
	_debug.autowrap_mode = TextServer.AUTOWRAP_OFF
	_debug.clip_text = true
	v.add_child(_debug)
	_window = TextureRect.new()
	_window.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_window.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_window.custom_minimum_size.y = 470
	v.add_child(_window)
	_rival_name = _label(60, INK, Style.BLACKLETTER)
	v.add_child(_rival_name)
	_race = Control.new()
	_race.custom_minimum_size.y = 210
	_race.draw.connect(_draw_race)
	v.add_child(_race)
	_beat = _label(52, INK, Style.BLACKLETTER)
	_beat.custom_minimum_size.y = 140
	v.add_child(_beat)
	_note = _label(34, DIM)
	v.add_child(_note)
	_dice_row = HBoxContainer.new()
	_dice_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_dice_row.add_theme_constant_override("separation", 18)
	_dice_row.custom_minimum_size.y = 170
	v.add_child(_dice_row)
	var mid := HBoxContainer.new()
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	mid.add_theme_constant_override("separation", 60)
	v.add_child(mid)
	_stake = _label(110, GOLD, Style.NUMERAL)
	_stake.autowrap_mode = TextServer.AUTOWRAP_OFF
	mid.add_child(_stake)
	_strikes = _label(60, CRIMSON)
	_strikes.autowrap_mode = TextServer.AUTOWRAP_OFF
	mid.add_child(_strikes)
	_extra = VBoxContainer.new()
	_extra.add_theme_constant_override("separation", 12)
	v.add_child(_extra)
	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(fill)
	_buttons = HBoxContainer.new()
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_buttons.add_theme_constant_override("separation", 40)
	_buttons.custom_minimum_size.y = 170
	v.add_child(_buttons)
	_offer_box = CenterContainer.new()  # the offer card, centred over everything
	_offer_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	_offer_box.visible = false
	add_child(_offer_box)
	_offer = PanelContainer.new()
	_offer_box.add_child(_offer)


func _button(text: String, on_press: Callable, wide := 440, col := Color("3a2a22")) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(wide, 150)
	b.add_theme_font_override("font", Style.BLACKLETTER)
	b.add_theme_font_size_override("font_size", 64)
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(18)
	for k in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(k, sb)
	b.add_theme_color_override("font_color", INK)
	b.pressed.connect(on_press)
	return b


# ---------- A duel ----------

func _new_duel() -> void:
	_over = false
	_t_match = 0.0
	_t_last_answer = -1.0
	_waits.clear()
	_status = ""
	_clear_prompt_nodes()
	var mine: String = my_sin if my_sin in NAMES else NAMES.pick_random()
	var others := NAMES.filter(func(n): return n != mine)
	var theirs: String = rival_sin if rival_sin in others else others.pick_random()
	human = Human.new()
	human.view = self
	var bot = BotPolicy.chooser(5, [99, 2, 0], 300)
	var seats := [[human, mine], [bot, theirs]]
	seats.shuffle()
	var o := DuelSim.duel_rules()
	game = Game.new([seats[0][0], seats[1][0]], randi(), o,
		[SIN_SCRIPTS[NAMES.find(seats[0][1])].new(), SIN_SCRIPTS[NAMES.find(seats[1][1])].new()])
	game.view = self
	for p in game.players:
		if p.bot == human:
			me = p
		else:
			rival = p
	_window.texture = Art.window(rival.sin.sin_name)
	_rival_name.text = rival.sin.sin_name
	_rival_name.add_theme_color_override("font_color", Style.SIN_COLORS[rival.sin.sin_name].lightened(0.25))
	_beat.text = "You are %s. %s throws first." % [me.sin.sin_name, "You" if game.players[0] == me else rival.sin.sin_name]
	_refresh()
	_run.call_deferred(game)


func _run(g) -> void:
	await g.play()
	if g != game:
		return  # a new duel replaced this one
	_over = true
	var won: bool = g.winner == me
	_beat.text = "%s, %d to %d." % ["You win" if won else rival.sin.sin_name + " wins", me.score if won else rival.score, rival.score if won else me.score]
	_note.text = ""
	_stake.text = ""
	_strikes.text = ""
	for c in _dice_row.get_children():
		c.queue_free()
	_log_duel(won)
	_clear_prompt_nodes()
	_buttons.add_child(_button("Again", _new_duel))
	await _shot("end")
	if _auto > 0:
		_duels_done += 1
		print("DUEL %d %s | %s vs %s | %d-%d | rounds %d | %.1f s | waits %s" % [_duels_done, "won" if won else "lost",
			me.sin.sin_name, rival.sin.sin_name, me.score, rival.score, g.round_count, _t_match, str(_waits.map(func(w): return snappedf(w, 0.1)))])
		if _duels_done >= _auto:
			get_tree().quit()
		else:
			_new_duel()


## One PNG per kind, the first time it happens (shot=<folder>).
func _shot(kind: String) -> void:
	if _shots == "" or _shot_taken.has(kind):
		return
	_shot_taken[kind] = true
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(_shots)
	get_viewport().get_texture().get_image().save_png(_shots.path_join("duel_%s.png" % kind))


## Autoplay: throw until 250 or two Strikes, take every third offer, else the first option.
func _auto_answer(options: Array, offer: Dictionary) -> void:
	await get_tree().create_timer(0.05).timeout
	var pick = options[0][1]
	if offer.has("terms"):
		pick = options[0][1] if randi() % 3 == 0 else options[-1][1]
	else:
		var bank = null
		var throw = null
		for o in options:
			if str(o[0]).begins_with("Bank"):
				bank = o[1]
			elif str(o[0]).is_valid_int():
				throw = o[1]
		if throw != null:
			pick = throw
			if bank != null and (game.turn.points >= 250 or game.turn.strikes >= 2):
				pick = bank
	_answer(pick)


func _log_duel(won: bool) -> void:
	var f := FileAccess.open("user://duel_log.jsonl", FileAccess.READ_WRITE if FileAccess.file_exists("user://duel_log.jsonl") else FileAccess.WRITE)
	if f == null:
		return
	f.seek_end()
	f.store_line(JSON.stringify({"variant": variant, "me": me.sin.sin_name, "rival": rival.sin.sin_name, "won": won,
		"me_score": me.score, "rival_score": rival.score, "rounds": game.round_count, "seconds": snappedf(_t_match, 0.1),
		"waits": _waits.map(func(w): return snappedf(w, 0.1)), "time": Time.get_datetime_string_from_system()}))


# ---------- What the board shows ----------

func _refresh() -> void:
	if game == null:
		return
	_race.queue_redraw()
	var mine_now: bool = game.current == me
	for c in _dice_row.get_children():
		c.queue_free()
	if game.turn and (mine_now or variant == "B"):
		for f in game.turn.faces:
			_dice_row.add_child(_die(int(f)))
	if mine_now and game.turn:
		_stake.text = str(game.turn.points) if game.turn.throws > 0 else ""
		_strikes.text = "Strikes %d / 3" % game.turn.strikes if game.turn.throws > 0 else ""
	elif not mine_now:
		_stake.text = ""
		_strikes.text = ""
	var notes := []
	if game.is_marked(me) and game.current == me:
		notes.append("You lead: no chain bonus this round.")
	if game.called_round >= 0:
		notes.append("The Master has called it." if not game.end_triggered else "Final round.")
	if me.pend_bank > 0:
		notes.append("Your next Bank loses %d." % me.pend_bank)
	for s in me.marks:
		if me.marks[s] > 0:
			notes.append("%s's marks: %d of %d." % [s, me.marks[s], game.marks_to_claim])
	for s in me.claims:
		notes.append("Claimed by %s." % s)
	if _status != "":
		notes.push_front(_status)
	_note.text = "  ".join(notes)


func _draw_race() -> void:
	if game == null:
		return
	var w := _race.size.x
	var top := maxi(int(game.master_call * 1.3), maxi(me.score, rival.score) + 100)
	var x := func(s: int) -> float: return 40.0 + (w - 80.0) * clampf(float(s) / top, 0.0, 1.0)
	var y := 90.0
	_race.draw_line(Vector2(40, y), Vector2(w - 40, y), DIM, 6)
	var cx: float = x.call(game.master_call)
	_race.draw_line(Vector2(cx, y - 40), Vector2(cx, y + 40), GOLD, 6)
	var f: Font = Style.SERIF
	_race.draw_string(f, Vector2(cx - 40, y + 70), "call %d" % game.master_call, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, GOLD)
	var rc: Color = Style.SIN_COLORS[rival.sin.sin_name]
	var rx: float = x.call(rival.score)
	_race.draw_circle(Vector2(rx, y - 30), 22, rc)
	_race.draw_string(f, Vector2(rx - 60, y - 60), "%s %d" % [rival.sin.sin_name, rival.score], HORIZONTAL_ALIGNMENT_LEFT, -1, 36, rc.lightened(0.3))
	var mx: float = x.call(me.score)
	_race.draw_circle(Vector2(mx, y + 30), 22, INK)
	_race.draw_string(f, Vector2(mx - 40, y + 140 - 40), "You %d" % me.score, HORIZONTAL_ALIGNMENT_LEFT, -1, 36, INK)


func _die(face: int) -> Control:
	var d := Control.new()
	d.custom_minimum_size = Vector2(150, 150)
	d.draw.connect(func():
		var strike: bool = face <= 2
		var scorer: bool = face >= 4
		d.draw_rect(Rect2(Vector2.ZERO, d.size), Color("f1e6c8") if not strike else Color("6b4a3a"), true)
		d.draw_rect(Rect2(Vector2.ZERO, d.size), GOLD if scorer else (CRIMSON if strike else DIM), false, 8)
		var pips := {1: [[0.5, 0.5]], 2: [[0.28, 0.28], [0.72, 0.72]], 3: [[0.28, 0.28], [0.5, 0.5], [0.72, 0.72]],
			4: [[0.28, 0.28], [0.72, 0.28], [0.28, 0.72], [0.72, 0.72]],
			5: [[0.28, 0.28], [0.72, 0.28], [0.5, 0.5], [0.28, 0.72], [0.72, 0.72]],
			6: [[0.28, 0.25], [0.72, 0.25], [0.28, 0.5], [0.72, 0.5], [0.28, 0.75], [0.72, 0.75]]}
		for pp in pips.get(face, []):
			d.draw_circle(Vector2(pp[0], pp[1]) * d.size, 14, CRIMSON if strike else Color("2a1810")))
	return d


# ---------- core/game.gd's view ----------

func player_name(p) -> String:
	return "You" if p == me else p.sin.sin_name


func log_line(text: String) -> void:
	if rival and game and game.current == rival:
		var i := text.find(" banks ")
		if i >= 0:
			_rival_line = "%s banks %s" % [rival.sin.sin_name, text.substr(i + 7).get_slice(" ", 0)]
		elif text.strip_edges().begins_with("keeps "):
			_rival_line = "%s busts, keeps %s" % [rival.sin.sin_name, text.strip_edges().get_slice(" ", 1)]
		elif " buys " in text:
			var m := RegEx.create_from_string("buys (\\d+) \\w+ for (\\d+)").search(text)
			if m:
				_rival_line += ", buys %s %s (-%s)" % [m.get_string(1), "die" if m.get_string(1) == "1" else "dice", m.get_string(2)]
		elif " BUSTS" in text and _rival_line == "":
			_rival_line = "%s busts" % rival.sin.sin_name


func turn_started(p) -> void:
	_status = ""
	if p == rival:
		_rival_start = rival.score
		_rival_line = ""
		_beat.text = "%s's turn" % rival.sin.sin_name if variant == "B" else ""
	else:
		_beat.text = ""
	_refresh()


func beat(p, kind: String) -> void:
	_refresh()
	if p == me:
		if kind == "throw":
			await get_tree().create_timer(MY_THROW).timeout
		return
	# A rival's turn: variant A shows only its result; B flashes each throw first.
	if kind == "throw":
		if variant == "B":
			_beat.text = "%s: +%d (%d Strike%s)" % [rival.sin.sin_name, game.turn.throw_points, game.turn.strikes, "" if game.turn.strikes == 1 else "s"]
			await get_tree().create_timer(FLASH_THROW).timeout
		return
	if kind == "end":
		if _rival_line == "":
			_rival_line = "%s banks %d" % [rival.sin.sin_name, rival.score - _rival_start]
		_beat.text = _rival_line
		_shot("rival")
		await get_tree().create_timer(RESULT_HOLD if variant == "A" else FLASH_END).timeout


func table_event(_kind: String, _p, _other = null) -> void:
	pass


func master_event(kind: String, p, facts: Dictionary) -> void:
	match kind:
		"call":
			_status = "The Master calls it: one more round, then the final round."
		"final":
			_status = "Final round."
		"leader_mark":
			pass
		"claim":
			_status = "%s claims you." % (p.sin.sin_name if p else "A Sin") if p == me else _status
	_refresh()


func bet_event(_kind: String, _p, _facts: Dictionary) -> void:
	pass


func _save_settings() -> void:
	pass


# ---------- ui/human.gd's prompts ----------

func show_prompt(text: String, options: Array, offer := {}) -> void:
	_prompt_at = _t_match
	if _t_last_answer >= 0:
		_waits.append(_prompt_at - _t_last_answer)
	_refresh()
	_clear_prompt_nodes()
	if offer.has("terms"):
		_show_offer(offer, options)
		_after_prompt("offer", options, offer)
		return
	var row: Array = []
	var extra: Array = []
	for o in options:
		var label: String = str(o[0])
		var val = o[1]
		if label.is_valid_int():
			row.append(_button("Throw", _answer.bind(val), 440, Color("6e1a1f")))
		elif label.begins_with("Bank"):
			row.push_front(_button("Bank", _answer.bind(val), 440, Color("6b5418")))
		elif label.begins_with("@seal"):
			var n := label.substr(6)
			extra.append(_button(("Name %s" % n) if n != "" else "Use %s's power" % me.sin.sin_name, _answer.bind(val), 900, Color("2c3a5a")))
		elif label == "@stand":
			extra.append(_button("Let the throw stand", _answer.bind(val), 900))
		else:
			extra.append(_button(label, _answer.bind(val), 900))
	if text != "" and not text.begins_with("Throw"):
		var t := _label(36, INK)
		t.text = text
		_extra.add_child(t)
	if not extra.is_empty() and me.sin:
		var hint := _label(30, DIM)
		hint.text = RulesText.power(me.sin.sin_name) if options.any(func(o): return str(o[0]).begins_with("@")) else ""
		if hint.text != "":
			_extra.add_child(hint)
	var holder: Control = _extra
	if extra.size() > 2:  # many choices (Hubris names): a wrapping row of small buttons
		var flow := HFlowContainer.new()
		flow.alignment = FlowContainer.ALIGNMENT_CENTER
		flow.add_theme_constant_override("h_separation", 16)
		flow.add_theme_constant_override("v_separation", 16)
		_extra.add_child(flow)
		holder = flow
	for b in extra:
		if extra.size() > 2:
			b.custom_minimum_size = Vector2(300, 130)
			b.add_theme_font_size_override("font_size", 52)
		holder.add_child(b)
	for b in row:
		_buttons.add_child(b)
	_after_prompt("decision" if game.turn and game.turn.throws > 0 else "start", options, offer)


func _after_prompt(kind: String, options: Array, offer: Dictionary) -> void:
	await _shot(kind)
	if _auto > 0:
		_auto_answer(options, offer)


func _show_offer(offer: Dictionary, options: Array) -> void:
	_offer_box.visible = true
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("1e1512")
	sb.border_color = Style.SIN_COLORS.get(offer.get("sin", ""), GOLD)
	sb.set_border_width_all(6)
	sb.set_content_margin_all(40)
	_offer.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 20)
	v.custom_minimum_size.x = 900
	_offer.add_child(v)
	for pair in [[offer.get("sin", ""), 64, Style.BLACKLETTER], [offer.get("say", ""), 48, Style.BLACKLETTER], [offer.get("terms", ""), 44, Style.SERIF], [offer.get("context", ""), 30, Style.SERIF], [offer.get("tip", ""), 30, Style.SERIF]]:
		if str(pair[0]) == "":
			continue
		var l := _label(pair[1], INK, pair[2])
		l.text = " ".join(pair[0]) if pair[0] is Array else str(pair[0])
		v.add_child(l)
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 30)
	v.add_child(h)
	for o in options:
		h.add_child(_button(str(o[0]), _answer.bind(o[1]), 380))


func clear_prompt() -> void:
	_clear_prompt_nodes()


func _clear_prompt_nodes() -> void:
	for c in _buttons.get_children() + _extra.get_children() + _offer.get_children():
		c.queue_free()
	_offer_box.visible = false


func _answer(v) -> void:
	_t_last_answer = _t_match
	_clear_prompt_nodes()
	human.answered.emit(v)
