## Playtest UI: you + 6 bots, one Sin each, Rules.V2 with Tiers 1+2.
## Look: candlelit manuscript + stained glass (Docs/Plan.md, ui/style.gd). Built in code.
extends Control

const Rules = preload("res://core/rules.gd")
const Game = preload("res://core/game.gd")
const BotPolicy = preload("res://ai/bot_policy.gd")
const Human = preload("res://ui/human.gd")
const Style = preload("res://ui/style.gd")
const Glass = preload("res://ui/widgets/glass.gd")
const Frame = preload("res://ui/widgets/frame.gd")
const Die = preload("res://ui/widgets/die.gd")
const Strikes = preload("res://ui/widgets/strikes.gd")
const CANDLE_BG = preload("res://ui/shaders/candle_bg.gdshader")
const SIN_SCRIPTS := [
	preload("res://sins/wrath.gd"),
	preload("res://sins/greed.gd"),
	preload("res://sins/lust.gd"),
	preload("res://sins/envy.gd"),
	preload("res://sins/pride.gd"),
	preload("res://sins/gluttony.gd"),
	preload("res://sins/sloth.gd"),
]
const SIN_TITLES := {
	"Wrath": "the Avenger", "Greed": "the Hoarder", "Lust": "the Temptress", "Envy": "the Mirror",
	"Pride": "the Untouchable", "Gluttony": "the Devourer", "Sloth": "the Delayer",
}
const SIN_TEXT := {
	"Wrath": ["Spark of Rage: +40 whenever another player busts.", "Fury: once a round, make an opponent reroll their 3 best dice."],
	"Greed": ["The Vig: +17 for every die another player buys.", "Interest: buy no dice, gain 8% of your score (max 60)."],
	"Lust": ["Whisper: once a turn, swap a 3 (or a 2) for the last player's best face.", "Binding Pact: take 15% of an opponent's next banked turn."],
	"Envy": ["Glance: once a turn, add a copy of the last player's best face.", "Mimicry: borrow the last player's Tier 1 for your turn."],
	"Pride": ["Hubris: call it before rolling. Beat the last turn (min 50) for x1.6, or score 0.", "Untouchable: bounce the first attack on you each round."],
	"Gluttony": ["Feast: once a turn, feed a die to the Supply for +90. A Strike die cancels its Strike.", "Gorge: the first die you buy each turn costs 70."],
	"Sloth": ["Lazy Bones: your first Strike each turn doesn't count.", "Drag: an opponent throws 3 fewer dice next turn."],
}

var game = null
var human = null
var fast := false

var _content: VBoxContainer
var _portraits: Array = []        # one dict per seat: {glass, score, dice, tag}
var _banner: RichTextLabel
var _dice_row: HFlowContainer
var _throw_label: Label
var _strikes
var _turn_label: Label
var _my_glass
var _my_status: Label
var _prompt_label: RichTextLabel
var _buttons: HFlowContainer
var _ticker: Button
var _ticker_text: RichTextLabel
var _waiting := true              # no human prompt showing
var _log_lines: Array[String] = []
var _log_overlay: Control
var _log: RichTextLabel


func _ready() -> void:
	theme = Style.make_theme()
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var m := ShaderMaterial.new()
	m.shader = CANDLE_BG
	bg.material = m
	add_child(bg)
	_build_setup()


# ---------- Setup ----------

func _build_setup() -> void:
	_content = _page()
	var title := _rich(110, true)
	title.text = "[center]%s[/center]" % _drop_cap("Sinners' Gambit", 150)
	_content.add_child(title)
	_content.add_child(Style.body("Choose thy Sin. Six others shall face thee. First to 1000.", 34, Style.C_BONE))
	for s in SIN_SCRIPTS:
		var sname: String = s.new().sin_name
		var g = Glass.new(Style.SIN_COLORS[sname], 60.0, float(SIN_SCRIPTS.find(s)) * 3.1)
		g.custom_minimum_size.y = 196
		g.dim = 0.35  # keep the text readable over the glass
		g.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var box := _margin(34, 22)
		var v := VBoxContainer.new()
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.add_theme_constant_override("separation", 2)
		v.add_child(Style.label("%s, %s" % [sname, SIN_TITLES[sname]], 50, Style.C_IVORY, true, 10))
		for line in SIN_TEXT[sname]:
			v.add_child(Style.body(line, 26, Style.C_IVORY, 10))
		box.add_child(v)
		g.add_child(box)
		var hit := Button.new()
		hit.flat = true
		for st in ["normal", "hover", "pressed"]:
			hit.add_theme_stylebox_override(st, StyleBoxEmpty.new())
		hit.pressed.connect(_start.bind(s))
		g.add_child(hit)
		_content.add_child(g)


func _start(my_sin: Script) -> void:
	if _content:
		_content.get_parent().queue_free()
		_content = null
	human = Human.new()
	human.view = self
	var bot = BotPolicy.chooser(5, [99, 2, 0], 300)
	var seats := []
	for s in SIN_SCRIPTS:
		seats.append([human if s == my_sin else bot, s.new()])
	seats.shuffle()
	var bots := []
	var sins := []
	for e in seats:
		bots.append(e[0])
		sins.append(e[1])
	var options := Rules.V2.duplicate()
	options["tier2"] = true
	game = Game.new(bots, randi(), options, sins)
	game.view = self
	_build_board(my_sin.new().sin_name)
	var w = await game.play()
	log_line("")
	log_line("[b]%s WIN%s with %d![/b]" % [player_name(w).to_upper(), "" if w.bot == human else "S", w.score])
	_refresh()
	_banner.text = "[center]%s[/center]" % _drop_cap("%s %s" % [player_name(w), "win!" if w.bot == human else "wins"], 92)
	show_prompt("The game is done. %s reached %d." % [player_name(w), w.score], [["New game", "new"]])
	_on_new_game_wait()


func _on_new_game_wait() -> void:
	await human.answered
	get_tree().reload_current_scene()


# ---------- Board ----------

func _build_board(my_sin_name: String) -> void:
	_content = _page()

	# Everyone in seat order: small glass portraits.
	var strip := HBoxContainer.new()
	strip.add_theme_constant_override("separation", 8)
	_content.add_child(strip)
	for p in game.players:
		var g = Glass.new(Style.SIN_COLORS[p.sin.sin_name], 34.0, float(p.seat) * 5.7)
		g.custom_minimum_size = Vector2(0, 232)
		g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var box := _margin(6, 16)
		var v := VBoxContainer.new()
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.add_theme_constant_override("separation", -4)
		var name_l := Style.label("You" if p.bot == human else p.sin.sin_name, 30, Style.C_IVORY, true, 8)
		var score_l := Style.label("0", 50, Style.C_GOLD, true, 10)
		var dice_l := Style.label("", 28, Style.C_BONE, true, 6)
		var tag_l := Style.label("", 20, Style.C_GOLD, false, 6)
		for l in [name_l, score_l, dice_l, tag_l]:
			l.autowrap_mode = TextServer.AUTOWRAP_OFF
			l.clip_text = true
			v.add_child(l)
		box.add_child(v)
		g.add_child(box)
		strip.add_child(g)
		_portraits.append({"glass": g, "score": score_l, "dice": dice_l, "tag": tag_l})

	_banner = _rich(64, true)
	_content.add_child(_banner)

	# Dice tray: a dark vellum page.
	var tray = Frame.new(false)
	tray.custom_minimum_size.y = 470
	tray.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 10)
	tv.alignment = BoxContainer.ALIGNMENT_CENTER
	tray.add_child(tv)
	_dice_row = HFlowContainer.new()
	_dice_row.alignment = FlowContainer.ALIGNMENT_CENTER
	_dice_row.add_theme_constant_override("h_separation", 18)
	_dice_row.add_theme_constant_override("v_separation", 18)
	_dice_row.custom_minimum_size.y = 150

	tv.add_child(_dice_row)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 30)
	_throw_label = Style.label("", 48, Style.C_GOLD, true, 8)
	_throw_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(_throw_label)
	_strikes = Strikes.new()
	row.add_child(_strikes)
	tv.add_child(row)
	_turn_label = Style.label("", 80, Style.C_GOLD, true, 12)
	tv.add_child(_turn_label)
	_content.add_child(tray)

	# Your Sin: the big window.
	_my_glass = Glass.new(Style.SIN_COLORS[my_sin_name], 64.0, 11.0)
	_my_glass.custom_minimum_size.y = 210
	_my_glass.dim = 0.3
	var mb := _margin(36, 22)
	var mv := VBoxContainer.new()
	mv.alignment = BoxContainer.ALIGNMENT_CENTER
	mv.add_theme_constant_override("separation", 0)
	mv.add_child(Style.label("%s, %s" % [my_sin_name, SIN_TITLES[my_sin_name]], 46, Style.C_IVORY, true, 10))
	mv.add_child(Style.body("I  " + SIN_TEXT[my_sin_name][0], 26, Style.C_IVORY, 10))
	mv.add_child(Style.body("II  " + SIN_TEXT[my_sin_name][1], 26, Style.C_IVORY, 10))
	_my_status = Style.label("", 28, Style.C_GOLD, true, 8)
	mv.add_child(_my_status)
	mb.add_child(mv)
	_my_glass.add_child(mb)
	_content.add_child(_my_glass)

	# The prompt: a parchment page with wax seals.
	var page = Frame.new(true)
	page.custom_minimum_size.y = 330
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 18)
	pv.alignment = BoxContainer.ALIGNMENT_CENTER
	page.add_child(pv)
	_prompt_label = Style.body("", 36, Style.C_INK)
	pv.add_child(_prompt_label)
	_buttons = HFlowContainer.new()
	_buttons.alignment = FlowContainer.ALIGNMENT_CENTER
	_buttons.add_theme_constant_override("h_separation", 18)
	_buttons.add_theme_constant_override("v_separation", 18)
	pv.add_child(_buttons)
	_content.add_child(page)

	# Ticker: last log line; tap for the full chronicle. The seal toggles fast bots.
	var tick_row := HBoxContainer.new()
	tick_row.add_theme_constant_override("separation", 12)
	_ticker = Button.new()
	_ticker.flat = true
	_ticker.clip_contents = true
	_ticker.custom_minimum_size.y = 132  # 44pt touch target
	_ticker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for st in ["normal", "hover", "pressed"]:
		_ticker.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	_ticker_text = RichTextLabel.new()
	_ticker_text.bbcode_enabled = true
	_ticker_text.scroll_active = false
	_ticker_text.autowrap_mode = TextServer.AUTOWRAP_OFF
	_ticker_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ticker_text.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ticker_text.offset_top = 46
	_ticker_text.add_theme_font_override("normal_font", Style.SERIF)
	_ticker_text.add_theme_font_size_override("normal_font_size", 28)
	_ticker_text.add_theme_color_override("default_color", Style.C_BONE)
	_ticker.add_child(_ticker_text)
	_ticker.pressed.connect(func(): _log_overlay.visible = true)
	tick_row.add_child(_ticker)
	var speed := Button.new()
	speed.toggle_mode = true
	speed.text = ">>"
	speed.custom_minimum_size = Vector2(110, 80)
	speed.add_theme_font_size_override("font_size", 36)
	speed.toggled.connect(func(on): fast = on)
	tick_row.add_child(speed)
	_content.add_child(tick_row)

	_build_log_overlay()


func _build_log_overlay() -> void:
	_log_overlay = MarginContainer.new()
	_log_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		_log_overlay.add_theme_constant_override("margin_" + side, 30)
	_log_overlay.add_theme_constant_override("margin_top", 140)
	_log_overlay.add_theme_constant_override("margin_bottom", 90)
	var f = Frame.new(false)
	var v := VBoxContainer.new()
	f.add_child(v)
	v.add_child(Style.label("The Chronicle", 56, Style.C_GOLD, true, 8))
	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log.add_theme_font_override("normal_font", Style.SERIF)
	_log.add_theme_font_override("bold_font", Style.BLACKLETTER)
	_log.add_theme_font_size_override("normal_font_size", 30)
	_log.add_theme_font_size_override("bold_font_size", 34)
	_log.add_theme_color_override("default_color", Style.C_BONE)
	_log.text = Style.numbers("\n".join(_log_lines)) + "\n"
	v.add_child(_log)
	var close := Button.new()
	close.text = "Close"
	close.custom_minimum_size = Vector2(260, 100)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(func(): _log_overlay.visible = false)
	v.add_child(close)
	_log_overlay.add_child(f)
	_log_overlay.visible = false
	add_child(_log_overlay)


func _process(_delta: float) -> void:
	if game and _banner:
		_refresh()


func _refresh() -> void:
	for i in game.players.size():
		var p = game.players[i]
		var pt: Dictionary = _portraits[i]
		pt.score.text = str(p.score)
		pt.dice.text = "%d dice" % p.dice
		var tag := ""
		if p.in_purgatory:
			tag = "Purgatory"
		elif p.drag > 0:
			tag = "Dragged"
		elif p.pact_by != null:
			tag = "Pact"
		elif _t2_ready(p):
			tag = "II ready"
		pt.tag.text = tag
		pt.tag.add_theme_color_override("font_color", Style.C_STRIKE.lightened(0.35) if p.in_purgatory else Style.C_GOLD)
		var g = pt.glass
		g.glow = 0.55 if p == game.current else 0.0
		g.dim = 0.0 if p == game.current else (0.7 if p.in_purgatory else 0.35)

	var me = _me()
	if me:
		_my_glass.glow = 0.35 if _t2_ready(me) else 0.0
		if me.score < Rules.TIER2_SCORE and not me.t2_unlocked:
			_my_status.text = "II unlocks at %d" % Rules.TIER2_SCORE
		elif _t2_ready(me):
			_my_status.text = "II is ready"
		else:
			_my_status.text = "II recharges next turn"

	var cur = game.current
	var t = game.turn
	if cur == null or t == null:
		return
	if game.winner == null:
		var who: String = "Your turn" if cur.bot == human else "%s's turn" % player_name(cur)
		_banner.text = "[center]%s[/center]" % _drop_cap(who, 92)
	var faces: Array = t.faces if t.throws > 0 else t.redeem_faces
	_show_dice(faces)
	var scorers := 0
	for f in faces:
		if f >= 4:
			scorers += 1
	var mult: float = 1.0 + game.chain * maxi(0, scorers - 1)
	if t.throws > 0:
		var pts: int = Rules.score(faces, game.chain, game.face_mult)
		_throw_label.text = "+%d   x%.1f" % [pts, mult] if pts > 0 else "+0"
	elif faces.size() > 0:
		_throw_label.text = "Redemption: need a 6"
	else:
		_throw_label.text = ""
	_strikes.strikes = t.strikes
	_turn_label.text = "Turn %d" % t.points
	if _waiting and game.winner == null:
		var wait_text := "%s %s at the dice." % [player_name(cur), "are" if cur.bot == human else "is"]
		if _prompt_label.get_meta("wait", "") != wait_text:
			_prompt_label.set_meta("wait", wait_text)
			Style.set_body(_prompt_label, "[color=#%s]%s[/color]" % [Style.C_DIM.darkened(0.3).to_html(false), wait_text])


func _t2_ready(p) -> bool:
	return game.tier2 and ((p.t2_unlocked and p.t2_ready) or (not p.t2_unlocked and p.score >= Rules.TIER2_SCORE))


func _me():
	for p in game.players:
		if p.bot == human:
			return p
	return null


func _show_dice(faces: Array) -> void:
	var key := str(faces)
	if _dice_row.get_meta("key", "") == key:
		return
	_dice_row.set_meta("key", key)
	for c in _dice_row.get_children():
		c.queue_free()
	var side := 140 if faces.size() <= 6 else 112
	for i in faces.size():
		_dice_row.add_child(Die.new(faces[i], side, i * 7 + faces[i]))


# ---------- Called by core/game.gd and ui/human.gd ----------

func player_name(p) -> String:
	if p.bot == human:
		return "You"
	return p.sin.sin_name if p.sin else "Bot %d" % p.seat


func log_line(text: String) -> void:
	_log_lines.append(text)
	if _log:
		_log.append_text(Style.numbers(text) + "\n")
	if _ticker_text and text.strip_edges() != "":
		var plain := RegEx.create_from_string("\\[[^\\]]*\\]").sub(text, "", true).strip_edges()
		_ticker_text.text = Style.numbers(plain)


func turn_started(p) -> void:
	log_line("")
	log_line("[color=#e9c46a]-- %s (%d) --[/color]" % [player_name(p), p.score])


func beat(p, kind: String) -> void:
	var t := 0.0
	if p.bot == human:
		t = 0.3 if kind == "throw" else 1.2
	else:
		t = 0.8 if kind == "throw" else 1.0
		if fast:
			t *= 0.25
	await get_tree().create_timer(t).timeout


## Short labels (a number) become round seals; longer ones are pill seals.
func show_prompt(text: String, options: Array) -> void:
	clear_prompt()
	_waiting = false
	Style.set_body(_prompt_label, text)
	for o in options:
		var b := Button.new()
		b.text = o[0]
		var short: bool = o[0].is_valid_int()
		b.custom_minimum_size = Vector2(124, 124) if short else Vector2(250, 112)
		if short:
			b.add_theme_font_size_override("font_size", 60)
		b.pressed.connect(func(): human.answered.emit(o[1]))
		_buttons.add_child(b)


func clear_prompt() -> void:
	_waiting = true
	_prompt_label.set_meta("wait", "")
	Style.set_body(_prompt_label, "")
	for c in _buttons.get_children():
		c.queue_free()


# ---------- Helpers ----------

func _page() -> VBoxContainer:
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 24)
	m.add_theme_constant_override("margin_right", 24)
	var safe := _safe_insets()
	m.add_theme_constant_override("margin_top", int(safe.x) + 24)
	m.add_theme_constant_override("margin_bottom", int(safe.y) + 16)
	add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	m.add_child(v)
	return v


## Notch and home-indicator insets in viewport pixels (x = top, y = bottom). Zero on web.
func _safe_insets() -> Vector2:
	var screen := DisplayServer.screen_get_size()
	var safe := DisplayServer.get_display_safe_area()
	if screen.y <= 0 or safe.size.y <= 0:
		return Vector2.ZERO
	var k: float = get_viewport_rect().size.y / float(screen.y)
	return Vector2(maxf(0.0, safe.position.y * k), maxf(0.0, (screen.y - safe.end.y) * k))


func _margin(h: int, v: int) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", h)
	m.add_theme_constant_override("margin_right", h)
	m.add_theme_constant_override("margin_top", v)
	m.add_theme_constant_override("margin_bottom", v)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return m


func _rich(size: int, blackletter: bool) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_OFF
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.add_theme_font_override("normal_font", Style.BLACKLETTER if blackletter else Style.SERIF)
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_color_override("default_color", Style.C_GOLD)
	r.add_theme_constant_override("outline_size", 10)
	r.add_theme_color_override("font_outline_color", Style.C_BLACK)
	return r


## Illuminated drop cap: first letter larger and crimson.
func _drop_cap(text: String, cap_size: int) -> String:
	return "[font_size=%d][color=#%s]%s[/color][/font_size]%s" % [cap_size, Style.C_CRIMSON.lightened(0.15).to_html(false), text.left(1), text.substr(1)]
