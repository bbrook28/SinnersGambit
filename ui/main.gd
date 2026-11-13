## Minimal playtest UI: you + 6 bots, one Sin each, Rules.V2 with Tiers 1+2. Placeholder look, built in code.
extends Control

const Rules = preload("res://core/rules.gd")
const Game = preload("res://core/game.gd")
const BotPolicy = preload("res://ai/bot_policy.gd")
const Human = preload("res://ui/human.gd")
const SIN_SCRIPTS := [
	preload("res://sins/wrath.gd"),
	preload("res://sins/greed.gd"),
	preload("res://sins/lust.gd"),
	preload("res://sins/envy.gd"),
	preload("res://sins/pride.gd"),
	preload("res://sins/gluttony.gd"),
	preload("res://sins/sloth.gd"),
]
const SIN_TEXT := {
	"Wrath": "T1 Spark of Rage: +40 when anyone else busts.\nT2 Fury: once a round, make an opponent reroll their 3 best dice.",
	"Greed": "T1 The Vig: +17 per die anyone else buys.\nT2 Interest: buy no dice, gain 8% of your score (max 60).",
	"Lust": "T1 Whisper: once a turn, swap a 3 (or a 2) for the previous player's best face.\nT2 Binding Pact: take 15% of an opponent's next banked turn.",
	"Envy": "T1 Glance: once a turn, add a copy of the previous player's best face to a throw.\nT2 Mimicry: borrow the previous player's Tier 1 for your turn.",
	"Pride": "T1 Hubris: before rolling, call it. Bank more than the last turn (min 50) for x1.6, or score 0.\nT2 Untouchable: bounce the first attack on you each round.",
	"Gluttony": "T1 Feast: once a turn, feed a die to the Supply for +90 (a Strike die cancels its Strike).\nT2 Gorge: first die you buy costs 70.",
	"Sloth": "T1 Lazy Bones: your first Strike each turn doesn't count.\nT2 Drag: an opponent throws 3 fewer dice next turn.",
}
const C_BG := Color("1a1418")
const C_PANEL := Color("2a2026")
const C_GOLD := Color("e8c060")
const C_RED := Color("e05050")
const C_DIM := Color("8a8088")
const C_TEXT := Color("f0e8e0")

var game = null
var human = null
var fast := false

var _setup: VBoxContainer
var _board: VBoxContainer
var _rows: Array[Label] = []
var _turn_label: Label
var _dice_row: HBoxContainer
var _throw_label: Label
var _turn_points: Label
var _prompt_label: Label
var _buttons: GridContainer
var _log: RichTextLabel
var _sin_info: Label


func _ready() -> void:
	var th := Theme.new()
	th.default_font_size = 34
	theme = th
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_build_setup()


# ---------- Setup ----------

func _build_setup() -> void:
	_setup = _page()
	_setup.add_child(_label("SINNERS' GAMBIT", 64, C_GOLD))
	_setup.add_child(_label("Pick your Sin. Six bots take the others. First to 1000.", 32, C_TEXT))
	for s in SIN_SCRIPTS:
		var sname: String = s.new().sin_name
		var b := _button("%s\n%s" % [sname.to_upper(), SIN_TEXT[sname]], 30)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size.y = 190
		b.pressed.connect(_start.bind(s))
		_setup.add_child(b)


func _start(my_sin: Script) -> void:
	if _setup:
		_setup.queue_free()
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
	_build_board()
	_sin_info.text = "You are %s.\n%s" % [my_sin.new().sin_name, SIN_TEXT[my_sin.new().sin_name]]
	var w = await game.play()
	log_line("")
	log_line("[b]%s WIN%s with %d![/b]" % [player_name(w).to_upper(), "" if w.bot == human else "S", w.score])
	_refresh()
	show_prompt("Game over: %s won." % player_name(w), [["New game", "new"]])
	_on_new_game_wait()


func _on_new_game_wait() -> void:
	await human.answered
	get_tree().reload_current_scene()


# ---------- Board ----------

func _build_board() -> void:
	_board = _page()
	var players_box := PanelContainer.new()
	players_box.add_theme_stylebox_override("panel", _box(C_PANEL))
	var pv := VBoxContainer.new()
	players_box.add_child(pv)
	_board.add_child(players_box)
	for p in game.players:
		var l := _label("", 38, C_TEXT)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_rows.append(l)
		pv.add_child(l)

	_turn_label = _label("", 40, C_GOLD)
	_board.add_child(_turn_label)
	_dice_row = HBoxContainer.new()
	_dice_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_dice_row.custom_minimum_size.y = 130
	_dice_row.add_theme_constant_override("separation", 12)
	_board.add_child(_dice_row)
	_throw_label = _label("", 36, C_TEXT)
	_board.add_child(_throw_label)
	_turn_points = _label("", 40, C_TEXT)
	_board.add_child(_turn_points)

	_prompt_label = _label("", 36, C_GOLD)
	_prompt_label.custom_minimum_size.y = 90
	_board.add_child(_prompt_label)
	_buttons = GridContainer.new()
	_buttons.columns = 3
	_buttons.add_theme_constant_override("h_separation", 12)
	_buttons.add_theme_constant_override("v_separation", 12)
	_board.add_child(_buttons)

	var speed := CheckButton.new()
	speed.text = "Fast bots"
	speed.toggled.connect(func(on): fast = on)
	_board.add_child(speed)

	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log.add_theme_font_size_override("normal_font_size", 30)
	_log.add_theme_font_size_override("bold_font_size", 30)
	_log.add_theme_stylebox_override("normal", _box(C_PANEL))
	_board.add_child(_log)

	_sin_info = _label("", 28, C_DIM)
	_board.add_child(_sin_info)


func _process(_delta: float) -> void:
	if game:
		_refresh()


func _refresh() -> void:
	for i in game.players.size():
		var p = game.players[i]
		var tags := []
		if p.in_purgatory:
			tags.append("PURGATORY")
		if game.tier2 and ((p.t2_unlocked and p.t2_ready) or (not p.t2_unlocked and p.score >= Rules.TIER2_SCORE)):
			tags.append("T2")
		if p.drag > 0:
			tags.append("Dragged")
		if p.pact_by != null:
			tags.append("Pact:" + player_name(p.pact_by))
		var arrow := "> " if p == game.current else "   "
		_rows[i].text = "%s%-10s %4d   %d dice   %s" % [arrow, player_name(p), p.score, p.dice, " ".join(tags)]
		var c := C_TEXT
		if p.bot == human:
			c = C_GOLD
		if p != game.current:
			c = c.darkened(0.3)
		_rows[i].add_theme_color_override("font_color", c)

	var cur = game.current
	var t = game.turn
	if cur == null or t == null:
		return
	_turn_label.text = "%s's turn" % player_name(cur) if cur.bot != human else "YOUR TURN"
	var faces: Array = t.faces if t.throws > 0 else t.redeem_faces
	_show_dice(faces)
	var scorers := 0
	for f in faces:
		if f >= 4:
			scorers += 1
	var mult: float = 1.0 + game.chain * maxi(0, scorers - 1)
	if t.throws > 0:
		var pts: int = Rules.score(faces, game.chain, game.face_mult)
		_throw_label.text = "Throw: %d pts   combo x%.1f   %d Strike%s" % [pts, mult, Rules.count_strikes(faces), "" if Rules.count_strikes(faces) == 1 else "s"]
	elif faces.size() > 0:
		_throw_label.text = "Redemption roll (needs a 6)"
	else:
		_throw_label.text = ""
	var marks := ""
	for k in Rules.STRIKES_TO_BUST:
		marks += "X" if k < t.strikes else "-"
	_turn_points.text = "Turn: %d pts    Strikes [%s]" % [t.points, marks]


func _show_dice(faces: Array) -> void:
	var key := str(faces)
	if _dice_row.get_meta("key", "") == key:
		return
	_dice_row.set_meta("key", key)
	for c in _dice_row.get_children():
		c.queue_free()
	var size := 120 if faces.size() <= 7 else maxi(60, 900 / faces.size())
	for f in faces:
		var col := C_DIM
		if f >= 4:
			col = C_GOLD
		elif f <= 2:
			col = C_RED
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(size, size)
		panel.add_theme_stylebox_override("panel", _box(col, 12))
		var l := _label(str(f), int(size * 0.55), C_BG)
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		panel.add_child(l)
		_dice_row.add_child(panel)


# ---------- Called by core/game.gd and ui/human.gd ----------

func player_name(p) -> String:
	if p.bot == human:
		return "You"
	return p.sin.sin_name if p.sin else "Bot %d" % p.seat


func log_line(text: String) -> void:
	if _log:
		_log.append_text(text + "\n")


func turn_started(p) -> void:
	log_line("")
	log_line("[color=#e8c060]-- %s (%d) --[/color]" % [player_name(p), p.score])


func beat(p, kind: String) -> void:
	var t := 0.0
	if p.bot == human:
		t = 0.3 if kind == "throw" else 1.2
	else:
		t = 0.8 if kind == "throw" else 1.0
		if fast:
			t *= 0.25
	await get_tree().create_timer(t).timeout


func show_prompt(text: String, options: Array) -> void:
	clear_prompt()
	_prompt_label.text = text
	for o in options:
		var b := _button(o[0], 32)
		b.custom_minimum_size = Vector2(320, 110)
		b.pressed.connect(func(): human.answered.emit(o[1]))
		_buttons.add_child(b)


func clear_prompt() -> void:
	_prompt_label.text = ""
	for c in _buttons.get_children():
		c.queue_free()


# ---------- Helpers ----------

func _page() -> VBoxContainer:
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 30)
	m.add_theme_constant_override("margin_right", 30)
	m.add_theme_constant_override("margin_top", 110)  # clear the phone notch
	m.add_theme_constant_override("margin_bottom", 60)
	add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	m.add_child(v)
	return v


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _button(text: String, size: int) -> Button:
	var b := Button.new()
	b.text = text
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.add_theme_font_size_override("font_size", size)
	return b


func _box(color: Color, radius := 16) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s
