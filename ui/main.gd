## Playtest UI: you + 6 bots, one Sin each, Rules.V2 with Tiers 1+2.
## Look: Docs/ArtDirection.md (art, iPhone layout) and Docs/ArtAudit.md. Built in code.
## Board: three zones. Glance (25%): Sin windows. Stage (45%): dice and score. Thumb (30%): actions.
extends Control

const Rules = preload("res://core/rules.gd")
const Game = preload("res://core/game.gd")
const BotPolicy = preload("res://ai/bot_policy.gd")
const Human = preload("res://ui/human.gd")
const Style = preload("res://ui/style.gd")
const Art = preload("res://ui/art.gd")
const Glass = preload("res://ui/widgets/glass.gd")
const Frame = preload("res://ui/widgets/frame.gd")
const Die = preload("res://ui/widgets/die.gd")
const CANDLE_BG = preload("res://ui/shaders/candle_bg.gdshader")
const ActionQueue = preload("res://ui/action_queue.gd")
const Director = preload("res://ui/director.gd")
const Tuning = preload("res://ui/tuning.gd")
const Events = preload("res://ui/events.gd")
const SETTINGS := "user://settings.cfg"
const SAVE := "user://save.json"
const SAVE_VERSION := 1
const MENU_TITLE := 120          # the title page: name, Play seal, Continue / Settings seals
const MENU_PLAY := 340
const MENU_SEAL := 250
const SPEEDS := [1.0, 2.0, 4.0]
const DOUBLE_TAP := 0.35
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

## Sizes in px (viewport 1080 wide = 393pt). Brief: text >= 13pt, small seals >= 44pt, Roll/Bank >= 88pt, dice >= 64pt.
const MIN_TEXT := 36
const SEAL_SMALL := 140
const SEAL_BIG := 250
const SEAL_CONFIRM := 200   # Bank and Throw: the same size whatever the dice count (polish item 4)
const TARGET_MIN := 44.0 * 1080.0 / 393.0   # 44 pt: smallest tappable thing (Apple HIG)
const GAP_MIN := 13.0 * 1080.0 / 393.0      # a little over 12 pt between separate targets
const SIDE_MIN := 17.0 * 1080.0 / 393.0     # a little over 16 pt from the screen's sides
const SEAL_RECESS := 0.46                  # the painted seal's wax recess, as a fraction of its width
const DIE_MAX := 280
const SCORE_SIZE := 136

var game = null
var human = null
## Fake notch/home-indicator insets (top, bottom) in px for desktop screenshots. Zero = ask the OS.
var debug_safe := Vector2.ZERO

var _content: VBoxContainer
var _portraits: Array = []        # one dict per seat: {window, glow, name, score, dice, sin}
var _banner_text: RichTextLabel
var _dice_area: Control
var _dice_row: HFlowContainer
var _throw_label: Label
var _turn_label: RichTextLabel
var _strike_icons: Array = []
var _prompt_label: RichTextLabel
var _buttons: Control             # holds only prompt Buttons (tests/ui_autoplay.gd presses them)
var _ticker: Button
var _ticker_text: RichTextLabel
var _waiting := true              # no human prompt showing
var _log_lines: Array[String] = []
var _log_overlay: Control
var _log: RichTextLabel
var _notes: Array = []           # marginalia currently showing, oldest first
## Every state change plays through this, one beat at a time (Docs/UXPass.md). The board shows
## the snapshot taken when the event happened, never the live rules state.
var _q: Node
var _dir: Node                    # ui/director.gd: stages each beat
var _fx: Control                  # flying numbers, stamps, particles, banners (above the board)
var _board: Control               # the page root (screen shake moves it)
var _banner: Control
var _turn_row: Control
var _log_row: Control
var _thumb: Control
var marginalia := {}               # jester / pennant / skeleton TextureRects on the thumb page (director reacts with them)
var _paper: Control               # thumb-zone parchment (slides and catches light with tilt)
var _tilt := Vector2.ZERO
var _inking := {}                 # lettering label -> ink-in progress 0..1 (_set_lettering, _process)
var _wash: ColorRect                # full-screen ink for screen transitions (_ink_wash)
static var _wash_on_load := false   # a New game reload starts under the ink and washes it away
static var _setup_on_load := false  # ...and opens on the Sin choice, not the menu
var _starting := false
var _save := {}                    # the game in progress, as written to SAVE
var _replaying := false            # Continue: replaying saved answers under the ink
var save_enabled := true           # tests turn this off
var _menu_seals: Array = []
var _settings: Control            # the Settings page while open
var _desk: Control
var _dice_nodes: Array = []       # the Die controls showing now, in face order
var _last_snap := {}              # the state as of the last queued event (the next one's "before")
var _focus_groups := {}
var _speed_label: Label
var _speed_slider: HSlider
var _last_tap := -1.0


func _ready() -> void:
	theme = Style.make_theme()
	_q = ActionQueue.new()
	add_child(_q)
	_dir = Director.new()
	add_child(_dir)
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS) == OK:
		Tuning.speed = clampf(float(cfg.get_value("ui", "speed", 1.0)), Tuning.SPEED_MIN, Tuning.SPEED_MAX)
		Tuning.muted = not bool(cfg.get_value("ui", "sound", true))
		Tuning.reduce_motion = bool(cfg.get_value("ui", "reduce_motion", false))
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var m := ShaderMaterial.new()
	m.shader = CANDLE_BG
	bg.material = m
	add_child(bg)
	# Painted desk: candle on the right, still life in the corners. Covers the gradient where it fits.
	var desk := TextureRect.new()
	desk.texture = Art.BG
	desk.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	desk.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	desk.set_anchors_preset(Control.PRESET_FULL_RECT)
	desk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desk.modulate = Color(0.78, 0.74, 0.7)  # keep the desk behind the UI, not competing
	add_child(desk)
	_desk = desk
	if _setup_on_load:  # New game goes straight to choosing a Sin
		_setup_on_load = false
		_build_setup()
	else:
		_build_menu()
	if _wash_on_load:
		_wash_on_load = false
		_ink_wash(false)


# ---------- Main menu ----------

## The title page: the game's name in illuminated lettering on the same candlelit parchment as
## play, the corner figures, and three wax seals (Play, Continue, Settings) that enter and breathe
## like the gameplay seals. Continue is cracked (disabled) when there is no game to continue.
func _build_menu() -> void:
	_content = _page()
	var cover := Control.new()
	cover.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(cover)
	var paper := Art.framed(Art.PAGE, Art.PAGE_MARGINS, 0.55)
	paper.material = Art.page_light_material()
	paper.modulate = Color(0.86, 0.78, 0.68)
	_paper = paper
	marginalia = _add_marginalia(paper)
	cover.add_child(paper)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 150
	v.offset_right = -150
	v.offset_top = 160
	v.offset_bottom = -150
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", int(GAP_MIN * 1.4))
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.add_child(v)
	var title := _make_lettering(MENU_TITLE, Style.C_INK.darkened(0.3), true)
	v.add_child(title)
	var sub := _make_lettering(46, Style.C_INK, false)
	v.add_child(sub)
	var gap := Control.new()
	gap.custom_minimum_size.y = 90
	v.add_child(gap)
	var saved := load_save()
	var play := _menu_seal("Play", MENU_PLAY, _open_setup)
	var cont := _menu_seal("Continue", MENU_SEAL, func(): _start(null, saved))
	cont.disabled = saved.is_empty()
	if cont.disabled:  # cracked and dimmed: nothing to continue
		cont.modulate = Color(0.55, 0.5, 0.48)
	var settings := _menu_seal("Settings", MENU_SEAL, _open_settings)
	var top := CenterContainer.new()
	top.add_child(play)
	v.add_child(top)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", int(GAP_MIN * 2.0))
	row.add_child(cont)
	row.add_child(settings)
	v.add_child(row)
	_menu_seals = [play, cont, settings]
	# Once laid out: ink the words in, bring the seals in one by one.
	(func():
		_set_lettering(title, "Sinners' Gambit", Style.C_CRIMSON)
		_set_lettering(sub, "Seven Sins at one table. First to 1000.", Style.C_STRIKE)
		_dir.seals_enter(_menu_seals)).call_deferred()


func _menu_seal(text: String, size: int, on_press: Callable) -> Button:
	var b := Button.new()
	b.set_meta("kind", "menu")
	b.custom_minimum_size = Vector2(size, size)
	Art.skin(b, Art.SEAL_L)
	_caption(b, text, int(size * 0.2))
	b.material = Art.glint_material(-Tuning.GLINT_STAGGER * size / 100.0)
	_seal_feel(b, "roll", on_press)
	return b


## Play: the ink washes over the title page and the Sin choice is under it.
func _open_setup() -> void:
	if _starting:
		return
	_starting = true
	await _ink_wash(true)
	_dir._stop_pulses()
	_content.get_parent().queue_free()
	_build_setup()
	_starting = false
	if _wash:
		move_child(_wash, -1)
	_ink_wash(false)


## Settings turn in like a page over whatever is showing: speed, sound, Reduce Motion.
func _open_settings() -> void:
	var ov := Control.new()
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(Style.C_BLACK, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.add_child(dim)
	var holder := _margin(60, 0)
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	var safe := _safe_insets()
	holder.add_theme_constant_override("margin_top", int(safe.x) + 220)
	holder.add_theme_constant_override("margin_bottom", int(safe.y) + 220)
	ov.add_child(holder)
	var paper := Art.framed(Art.PAGE, Art.PAGE_MARGINS, 0.55)
	paper.modulate = Color(0.86, 0.78, 0.68)
	var page := Control.new()
	_add_marginalia(paper)
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(paper)
	holder.add_child(page)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 130
	v.offset_right = -130
	v.offset_top = 110
	v.offset_bottom = -110
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", int(GAP_MIN * 1.5))
	page.add_child(v)
	var title := _make_lettering(80, Style.C_INK.darkened(0.3), true)
	v.add_child(title)
	var rows := [
		[func(): return "Speed: %s" % _speed_text(), func():
			_set_speed(SPEEDS[(SPEEDS.find(Tuning.speed) + 1) % SPEEDS.size()])],
		[func(): return "Sound: %s" % ("Off" if Tuning.muted else "On"), func():
			Tuning.muted = not Tuning.muted
			_save_settings()],
		[func(): return "Reduce Motion: %s" % ("On" if Tuning.reduce_motion else "Off"), func():
			Tuning.reduce_motion = not Tuning.reduce_motion
			_save_settings()],
	]
	for r in rows:
		var b := Button.new()
		b.set_meta("kind", "setting")
		Art.skin(b, [Art.YOU_TAB, Art.YOU_TAB, Art.YOU_TAB], Color.WHITE, 24)
		b.custom_minimum_size = Vector2(620, SEAL_SMALL)
		b.add_theme_font_size_override("font_size", 46)
		b.text = r[0].call()
		var label_fn: Callable = r[0]
		var act: Callable = r[1]
		_seal_feel(b, "pill", func():
			act.call()
			b.text = label_fn.call())
		var c := CenterContainer.new()
		c.add_child(b)
		v.add_child(c)
	var back := _menu_seal("Back", 220, func(): _close_settings(ov))
	var bc := CenterContainer.new()
	bc.add_child(back)
	v.add_child(bc)
	add_child(ov)
	_settings = ov
	(func():
		_set_lettering(title, "Settings", Style.C_CRIMSON)
		_page_turn(ov, true)).call_deferred()


func _close_settings(ov: Control) -> void:
	await _page_turn(ov, false)
	ov.queue_free()
	_settings = null


func _speed_text() -> String:
	return ("%dx" % int(Tuning.speed)) if is_equal_approx(Tuning.speed, roundf(Tuning.speed)) else ("%.2gx" % Tuning.speed)


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
		hit.button_down.connect(func(): _dir.sfx.play("seal", 0.5, 1.0, true))
		g.add_child(hit)
		_content.add_child(g)


## Starts a game as `my_sin`, or rebuilds a saved one (Continue): same seed, same seats, and your
## saved answers given back under the ink until the game reaches your next decision.
func _start(my_sin: Script, saved := {}) -> void:
	if _starting:
		return  # a second tap while the ink covers the setup
	_starting = true
	if _content:
		await _ink_wash(true)
		_content.get_parent().queue_free()
		_content = null
	human = Human.new()
	human.view = self
	var bot = BotPolicy.chooser(5, [99, 2, 0], 300)
	var order := []  # [sin index, is human] per seat
	if saved.is_empty():
		for s in SIN_SCRIPTS:
			order.append([SIN_SCRIPTS.find(s), s == my_sin])
		order.shuffle()
	else:
		for e in saved.seats:
			order.append([int(e[0]), bool(e[1])])
	var bots := []
	var sins := []
	for e in order:
		bots.append(human if e[1] else bot)
		sins.append(SIN_SCRIPTS[e[0]].new())
	var options := Rules.V2.duplicate()
	options["tier2"] = true
	var seed_value: int = randi() if saved.is_empty() else int(saved.seed)
	game = Game.new(bots, seed_value, options, sins)
	game.view = self
	_save = {"v": SAVE_VERSION, "seed": seed_value, "seats": order, "choices": human.record}
	human.on_answer = _save_game
	_build_board()
	if _wash:
		move_child(_wash, -1)  # the board was added above the ink
	if saved.is_empty():
		_ink_wash(false)
	else:
		human.replay = saved.choices.duplicate()
		_replaying = true
		_q.skip_all = true  # every beat jumps to its end; show_prompt lifts the ink
	var w = await game.play()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))  # a finished game can't be continued
	log_line("")
	log_line("[b]%s WIN%s with %d![/b]" % [player_name(w).to_upper(), "" if w.bot == human else "S", w.score])
	_q.push(func(): _set_banner("%s %s" % [player_name(w), "win!" if w.bot == human else "wins"], w))
	show_prompt("The game is done. %s reached %d." % [player_name(w), w.score], [["New game", "new"]])
	_on_new_game_wait()


## The save is the seed, the seats and every answer you've given (ui/human.gd records them).
func _save_game() -> void:
	if _save.is_empty() or not save_enabled:
		return
	var f := FileAccess.open(SAVE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(_save))


static func load_save() -> Dictionary:
	if not FileAccess.file_exists(SAVE):
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	if not (d is Dictionary) or int(d.get("v", 0)) != SAVE_VERSION or not d.has("seats") or not d.has("choices"):
		return {}
	return d


func _on_new_game_wait() -> void:
	await human.answered
	_wash_on_load = true
	_setup_on_load = true
	await _ink_wash(true)
	get_tree().reload_current_scene()


# ---------- Board ----------

func _build_board() -> void:
	_content = _page()
	_content.add_theme_constant_override("separation", 14)
	var glance := _zone(25)
	var stage := _zone(45)
	var thumb := _zone(30)
	_build_glance(glance)
	_build_stage(stage)
	_build_thumb(thumb)
	_board = _content.get_parent()
	_fx = Control.new()
	_fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fx)
	_dir.setup(self, _q, _fx)
	# What the director can dim or spotlight: one entry per thing the eye might land on.
	for i in _portraits.size():
		_focus_groups["seat%d" % i] = _portraits[i].col
	_focus_groups["banner"] = _banner
	_focus_groups["dice"] = _dice_area
	_focus_groups["throw"] = _throw_label
	_focus_groups["turn"] = _turn_row
	_focus_groups["log"] = _log_row
	_focus_groups["thumb"] = _thumb
	_focus_groups["desk"] = _desk
	if Tuning.SHOW_DEBUG_SLIDER:
		_build_speed_slider()
	_build_log_overlay()


func focus_groups() -> Dictionary:
	return _focus_groups


## Debug: global speed multiplier, on screen. Default 1.0 = the timings in ui/tuning.gd.
func _build_speed_slider() -> void:
	var box := HBoxContainer.new()
	box.position = Vector2(size.x - 470, maxf(8.0, _safe_insets().x - 64))
	box.size = Vector2(450, 56)
	box.add_theme_constant_override("separation", 10)
	var l := Style.label("", 30, Style.C_BONE, false, 6)
	l.add_theme_font_override("font", Style.NUMERAL)
	l.custom_minimum_size.x = 170
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	_speed_slider = HSlider.new()
	_speed_slider.min_value = Tuning.SPEED_MIN
	_speed_slider.max_value = Tuning.SPEED_MAX
	_speed_slider.step = 0.05
	_speed_slider.value = Tuning.speed
	_speed_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_speed_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_speed_slider.custom_minimum_size.y = 48
	var show := func(v: float): l.text = "speed %.2f" % v
	show.call(Tuning.speed)
	_speed_slider.value_changed.connect(func(v: float):
		show.call(v)
		_set_speed(v))
	box.add_child(l)
	box.add_child(_speed_slider)
	add_child(box)


func _zone(ratio: float) -> VBoxContainer:
	var z := VBoxContainer.new()
	z.size_flags_vertical = Control.SIZE_EXPAND_FILL
	z.size_flags_stretch_ratio = ratio
	z.add_theme_constant_override("separation", 10)
	_content.add_child(z)
	return z


## Seven windows in seat order, each over a brass-framed plate: name, score, dice. Look-only.
func _build_glance(zone: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 4)
	zone.add_child(row)
	for p in game.players:
		var sname: String = p.sin.sin_name
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 4)
		row.add_child(col)

		var win_box := Control.new()
		win_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
		win_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(win_box)
		var glow := TextureRect.new()
		var gt := GradientTexture2D.new()
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.5, 0.5)
		gt.fill_to = Vector2(0.5, 0.0)
		# Backlight: every pane is lit from behind; the current Sin's burns brighter (see _refresh).
		var gr := Gradient.new()
		var light: Color = _backlight(sname)
		gr.set_color(0, Color(light, 0.9))
		gr.set_color(1, Color(light, 0.0))
		gt.gradient = gr
		glow.texture = gt
		glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		glow.set_anchors_preset(Control.PRESET_FULL_RECT)
		glow.offset_left = -26
		glow.offset_right = 26
		glow.offset_top = -10
		glow.offset_bottom = 20
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		win_box.add_child(glow)
		var win := TextureRect.new()
		win.texture = Art.window(sname)
		win.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		win.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		win.set_anchors_preset(Control.PRESET_FULL_RECT)
		win.material = Art.flare_material()
		win.material.set_shader_parameter("phase", float(p.seat) * 0.37)  # shimmer out of step
		if sname == "Greed":
			win.material.set_shader_parameter("cast", Color(0.86, 1.0, 1.22))  # cold silver, not grey
		win.mouse_filter = Control.MOUSE_FILTER_IGNORE
		win_box.add_child(win)

		var plate := Control.new()
		plate.custom_minimum_size.y = 172
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plate.add_child(Art.framed(Art.TRAY, [48, 40, 48, 40], 0.42))
		var pv := VBoxContainer.new()
		pv.set_anchors_preset(Control.PRESET_FULL_RECT)
		pv.offset_top = 10
		pv.offset_bottom = -16
		pv.alignment = BoxContainer.ALIGNMENT_CENTER
		pv.add_theme_constant_override("separation", 0)
		pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plate.add_child(pv)
		var mine: bool = p.bot == human
		var name_box := Control.new()
		name_box.custom_minimum_size.y = 46
		name_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if mine:
			var tab := Art.framed(Art.YOU_TAB, [24, 20, 24, 20], 0.55)
			tab.offset_left = 10
			tab.offset_right = -10
			tab.material = Art.tint_material(Style.SIN_COLORS[sname].darkened(0.2))  # your Sin's colour, as the banner
			name_box.add_child(tab)
		var name_l := Style.label("You" if mine else sname, MIN_TEXT, Style.C_BONE, false, 6)
		name_l.add_theme_font_override("font", Style.SERIF)
		name_l.resized.connect(_fit_label.bind(name_l, MIN_TEXT, 30))
		name_l.set_anchors_preset(Control.PRESET_FULL_RECT)
		name_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_box.add_child(name_l)
		col.add_child(name_box)  # above the frame: names get the full column width
		var score_l := Style.number("0", 54)
		pv.add_child(score_l)
		var dice_row := HBoxContainer.new()
		dice_row.alignment = BoxContainer.ALIGNMENT_CENTER
		dice_row.add_theme_constant_override("separation", 4)
		dice_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var die_icon := TextureRect.new()
		die_icon.texture = Art.ICON_DIE
		die_icon.custom_minimum_size = Vector2(42, 42)
		die_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		die_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		dice_row.add_child(die_icon)
		var dice_l := Style.label("", MIN_TEXT + 6, Style.C_BONE, false, 6)
		dice_l.add_theme_font_override("font", Style.NUMERAL)
		dice_row.add_child(dice_l)
		pv.add_child(dice_row)
		for l in [name_l, score_l, dice_l]:
			l.autowrap_mode = TextServer.AUTOWRAP_OFF
		name_l.clip_text = true
		col.add_child(plate)
		_portraits.append({"window": win, "glow": glow, "name": name_l, "score": score_l, "dice": dice_l, "sin": sname, "mine": mine, "col": col})


## Turn banner (in the current Sin's colour), the leather dice stage with the score as hero, then the log.
func _build_stage(zone: VBoxContainer) -> void:
	# Whose turn, as manuscript lettering straight on the page: no banner behind it (banners are
	# only for the transient turn-change announcement, director._banner_band).
	var banner := Control.new()
	banner.custom_minimum_size.y = 110
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_text = _make_lettering(60, Style.C_BONE, false)
	_banner_text.autowrap_mode = TextServer.AUTOWRAP_OFF
	_banner_text.add_theme_constant_override("outline_size", 10)
	_banner_text.add_theme_color_override("font_outline_color", Style.C_BLACK)
	_banner_text.set_anchors_preset(Control.PRESET_HCENTER_WIDE)
	_banner_text.anchor_top = 0.5
	_banner_text.anchor_bottom = 0.5
	_banner_text.grow_vertical = Control.GROW_DIRECTION_BOTH
	banner.add_child(_banner_text)
	zone.add_child(banner)
	_banner = banner

	# Dice stage: leather in a brass rule. Shadows fall left (candle to the right).
	var tray := Control.new()
	tray.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tray.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var leather := TextureRect.new()
	leather.texture = Art.LEATHER
	leather.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	leather.stretch_mode = TextureRect.STRETCH_SCALE
	leather.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		leather.set("offset_" + side, 14 if side in ["left", "top"] else -14)
	leather.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tray.add_child(leather)
	tray.add_child(Art.framed(Art.TRAY, [48, 40, 48, 40], 0.5, false))
	var tv := VBoxContainer.new()
	tv.set_anchors_preset(Control.PRESET_FULL_RECT)
	tv.offset_left = 30
	tv.offset_right = -30
	tv.offset_top = 26
	tv.offset_bottom = -22
	tv.add_theme_constant_override("separation", 0)
	tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tray.add_child(tv)
	_dice_area = Control.new()
	_dice_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_dice_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dice_area.resized.connect(func(): _dice_row.set_meta("key", ""))
	tv.add_child(_dice_area)
	_dice_row = HFlowContainer.new()
	_dice_row.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dice_row.alignment = FlowContainer.ALIGNMENT_CENTER
	_dice_row.add_theme_constant_override("h_separation", 16)
	_dice_row.add_theme_constant_override("v_separation", 16)
	_dice_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dice_area.add_child(_dice_row)
	_throw_label = Style.number("", SCORE_SIZE, 14)
	_throw_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	tv.add_child(_throw_label)
	_turn_label = Style.body("", 44, Style.C_BONE, 8)
	var srow := HBoxContainer.new()
	srow.alignment = BoxContainer.ALIGNMENT_CENTER
	srow.add_theme_constant_override("separation", 14)
	srow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sl := Style.label("Strikes", 42, Style.C_BONE, false, 8)
	sl.autowrap_mode = TextServer.AUTOWRAP_OFF
	_turn_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_turn_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	srow.add_child(_turn_label)  # one row with the Strikes, so the dice get the height
	srow.add_child(sl)
	for i in Rules.STRIKES_TO_BUST:
		var t := TextureRect.new()
		t.texture = Art.STRIKE_EMPTY
		t.custom_minimum_size = Vector2(88, 88)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		srow.add_child(t)
		_strike_icons.append(t)
	tv.add_child(srow)
	_turn_row = srow
	zone.add_child(tray)

	# Log strip (tap = Chronicle) and the fast-bots seal, clear of every screen edge.
	var lrow := HBoxContainer.new()
	lrow.custom_minimum_size.y = 104
	_log_row = lrow
	lrow.add_theme_constant_override("separation", int(GAP_MIN))
	_ticker = Button.new()
	_ticker.flat = true
	_ticker.clip_contents = true
	_ticker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for st in ["normal", "hover", "pressed", "focus"]:
		_ticker.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	var strip := Art.framed(Art.LOG_STRIP, [70, 36, 70, 36], 0.5)
	strip.modulate = Color(0.42, 0.36, 0.3)  # a quiet margin note, not a bright bar
	_ticker.add_child(strip)
	_ticker_text = RichTextLabel.new()
	_ticker_text.bbcode_enabled = true
	_ticker_text.scroll_active = false
	_ticker_text.autowrap_mode = TextServer.AUTOWRAP_OFF
	_ticker_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ticker_text.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ticker_text.offset_left = 56
	_ticker_text.offset_right = -40
	_ticker_text.offset_top = 28
	_ticker_text.add_theme_constant_override("outline_size", 6)
	_ticker_text.add_theme_color_override("font_outline_color", Style.C_BLACK)
	_ticker_text.add_theme_font_override("normal_font", Style.SERIF)
	_ticker_text.add_theme_font_size_override("normal_font_size", MIN_TEXT + 2)
	_ticker_text.add_theme_color_override("default_color", Style.C_BONE_DARK)
	_ticker.add_child(_ticker_text)
	_ticker.pressed.connect(func(): _page_turn(_log_overlay, true))
	_ticker.button_down.connect(func(): _dir.sfx.play("plaque", 0.3, 1.0, true))
	lrow.add_child(_ticker)
	var fv := VBoxContainer.new()
	fv.add_theme_constant_override("separation", -8)
	# One global speed for every beat: 1x, 2x, 4x. Remembered between sessions.
	var speed := Button.new()
	speed.custom_minimum_size = Vector2(SEAL_SMALL, SEAL_SMALL) * 0.86
	Art.skin(speed, [Art.SEAL_FAST, Art.SEAL_FAST, Art.SEAL_FAST])
	speed.add_theme_stylebox_override("pressed", _seal_style(Art.SEAL_FAST, Color(1.25, 1.1, 0.8)))
	speed.pressed.connect(_cycle_speed)
	speed.button_down.connect(func(): _dir.sfx.play("seal", 0.3, 1.2, true))
	fv.add_child(speed)
	_speed_label = Style.label("", MIN_TEXT + 4, Style.C_BONE, false, 6)
	_speed_label.add_theme_font_override("font", Style.NUMERAL)
	fv.add_child(_speed_label)
	_show_speed()
	lrow.add_child(fv)
	# Clear of the screen sides (the zone margin alone is under 16 pt).
	var lpad := _margin(24, 0)
	lpad.add_child(lrow)
	zone.add_child(lpad)


## Darkened parchment page: the prompt line, then the seals. Roll sits under the right thumb.
func _build_thumb(zone: VBoxContainer) -> void:
	var page := Control.new()
	_thumb = page
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Only the plain vine edges stretch; the corner marginalia keep their shape.
	var paper := Art.framed(Art.PAGE, Art.PAGE_MARGINS, 0.55)
	paper.material = Art.page_light_material()  # candle pool that slides with tilt (_process)
	_paper = paper
	# The corner figures are their own sprites so the director can make them react (jester, skeleton, pennant).
	marginalia = _add_marginalia(paper)
	paper.modulate = Color(0.8, 0.72, 0.62)
	page.add_child(paper)
	var pv := VBoxContainer.new()
	pv.set_anchors_preset(Control.PRESET_FULL_RECT)
	pv.offset_left = 64
	pv.offset_right = -64
	pv.offset_top = 14
	pv.offset_bottom = -22
	pv.add_theme_constant_override("separation", 2)
	page.add_child(pv)
	_prompt_label = _make_lettering(Tuning.PROMPT_FONT, Style.C_INK.darkened(0.4), true)
	# The words stay clear of the corner boxes (the seals below may use the full width).
	var lm := MarginContainer.new()
	var side := maxi(0, roundi(Art.PAGE_MARGINS[0] * 0.55) - 64 + 28)
	lm.add_theme_constant_override("margin_left", side)
	lm.add_theme_constant_override("margin_right", side)
	lm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lm.add_child(_prompt_label)
	pv.add_child(lm)
	_buttons = Control.new()
	_buttons.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_buttons.resized.connect(_layout_buttons)
	pv.add_child(_buttons)
	zone.add_child(page)


func _build_log_overlay() -> void:
	_log_overlay = MarginContainer.new()
	_log_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	var safe := _safe_insets()
	for side in ["left", "right"]:
		_log_overlay.add_theme_constant_override("margin_" + side, 30)
	_log_overlay.add_theme_constant_override("margin_top", int(safe.x) + 40)
	_log_overlay.add_theme_constant_override("margin_bottom", int(safe.y) + 40)
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
	_log.add_theme_font_size_override("normal_font_size", MIN_TEXT)
	_log.add_theme_font_size_override("bold_font_size", 40)
	_log.add_theme_color_override("default_color", Style.C_BONE)
	_log.text = _with_sigils(Style.numbers("\n".join(_log_lines))) + "\n"
	v.add_child(_log)
	var close := Button.new()
	close.text = "Close"
	close.custom_minimum_size = Vector2(300, SEAL_SMALL)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	Art.skin(close, [Art.YOU_TAB, Art.YOU_TAB, Art.YOU_TAB], Color.WHITE, 24)
	close.pressed.connect(func(): _page_turn(_log_overlay, false))
	v.add_child(close)
	_log_overlay.add_child(f)
	_log_overlay.visible = false
	add_child(_log_overlay)


## The seal steps 1x, 2x, 4x; the debug slider sets any value. Both write Tuning.speed, saved.
func _cycle_speed() -> void:
	var i := 0
	while i < SPEEDS.size() and SPEEDS[i] <= Tuning.speed + 0.01:
		i += 1
	_set_speed(SPEEDS[i % SPEEDS.size()])
	if _speed_slider:
		_speed_slider.set_value_no_signal(Tuning.speed)
		_speed_slider.value_changed.emit(Tuning.speed)


func _set_speed(v: float) -> void:
	Tuning.speed = clampf(v, Tuning.SPEED_MIN, Tuning.SPEED_MAX)
	_show_speed()
	_save_settings()


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS)
	cfg.set_value("ui", "speed", Tuning.speed)
	cfg.set_value("ui", "sound", not Tuning.muted)
	cfg.set_value("ui", "reduce_motion", Tuning.reduce_motion)
	cfg.save(SETTINGS)


func _show_speed() -> void:
	if _speed_label:
		_speed_label.text = _speed_text()


## Tap anywhere that isn't a button: finish the current beat. Double tap: skip to your next decision.
func _input(event: InputEvent) -> void:
	if game == null or not _q.busy():
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var c := get_viewport().gui_get_hovered_control()
	while c:
		if c is Button:
			return
		c = c.get_parent() as Control
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_tap < DOUBLE_TAP:
		_q.skip_to_decision()
	else:
		_q.skip_beat()
	_last_tap = now


## What the board shows, copied from the rules at the moment an event happened.
func _snapshot() -> Dictionary:
	var ps := []
	for p in game.players:
		var tag := ""
		if p.in_purgatory:
			tag = "Purgatory"
		elif p.drag > 0:
			tag = "Dragged"
		elif p.pact_by != null:
			tag = "Pact"
		elif _t2_ready(p):
			tag = "II ready"
		ps.append({"score": p.score, "dice": p.dice, "purg": p.in_purgatory, "tag": tag})
	var s := {"players": ps, "cur": game.players.find(game.current), "winner": game.winner != null}
	var t = game.turn
	if t:
		var faces: Array = (t.faces if t.throws > 0 else t.redeem_faces).duplicate()
		s.turn = {"faces": faces, "throws": t.throws, "points": t.points, "strikes": t.strikes}
	return s


const ALL_PARTS := ["plates", "glow", "banner", "dice", "throw", "turn", "strikes", "prompt"]


## Draws a snapshot. parts: only those pieces (the director animates the rest itself).
func _refresh(s: Dictionary, parts: Array = ALL_PARTS) -> void:
	var cur_i: int = s.cur
	for i in game.players.size():
		var ps: Dictionary = s.players[i]
		var pt: Dictionary = _portraits[i]
		if "plates" in parts:
			_refresh_plate(pt, ps)
		if "glow" in parts:
			var lit: bool = i == cur_i
			pt.glow.modulate.a = 1.0 if lit else 0.35
			var m: ShaderMaterial = pt.window.material
			m.set_shader_parameter("glow", 0.6 if lit else 0.0)
			m.set_shader_parameter("dim", 0.0 if lit else (0.55 if ps.purg else 0.15))
	if cur_i < 0 or not s.has("turn"):
		return
	var cur = game.players[cur_i]
	var t: Dictionary = s.turn
	if "banner" in parts and not s.winner:
		_set_banner("Your turn" if cur.bot == human else "%s's turn" % player_name(cur), cur)
	var faces: Array = t.faces
	if "dice" in parts:
		_show_dice(faces)
	if "throw" in parts:
		var text := ""
		var size := SCORE_SIZE
		if t.throws > 0:
			var pts: int = Rules.score(Array(faces, TYPE_INT, "", null), game.chain, game.face_mult)
			text = "+%d" % pts
		elif faces.size() > 0:
			text = "Redemption: need a 6"
			size = 72
		_throw_label.text = text
		_throw_label.add_theme_font_size_override("font_size", size)
	if "turn" in parts:
		set_turn_points(t.points)
	if "strikes" in parts:
		for i in _strike_icons.size():
			_strike_icons[i].texture = Art.STRIKE_STRUCK if i < t.strikes else Art.STRIKE_EMPTY
	if "prompt" in parts and _waiting and not s.winner:
		set_waiting_text("%s %s at the dice." % [player_name(cur), "are" if cur.bot == human else "is"])


func set_turn_points(v: int) -> void:
	if _turn_label.get_meta("pts", -1) != v:
		_turn_label.set_meta("pts", v)
		Style.set_body(_turn_label, "This turn %d" % v)


## The line on the page while it isn't your move ("Wrath is thinking...").


## Manuscript lettering (polish 1, 2): an illuminated first capital (coloured, gold-edged), the rest
## in blackletter, optionally a thin red flourish under, inked in left to right when the words change.
func _make_lettering(size: int, color: Color, flourish: bool) -> RichTextLabel:
	var r := Style.body("", size, color)
	r.add_theme_font_override("normal_font", Style.BLACKLETTER)
	r.material = Art.ink_material()
	if flourish:
		var pad := StyleBoxEmpty.new()
		pad.content_margin_bottom = 16
		r.add_theme_stylebox_override("normal", pad)
		var f := Control.new()
		f.name = "Flourish"
		f.use_parent_material = true  # spans the label's width, so it inks in with the words
		f.mouse_filter = Control.MOUSE_FILTER_IGNORE
		f.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		f.offset_top = -16
		f.draw.connect(func(): _draw_flourish(f, r))
		f.resized.connect(f.queue_redraw)
		r.add_child(f)
	return r


## Sets lettering text. It re-inks only when `key` (default: the text) changes, so a bot's
## "thinking..." dots don't re-ink every tick.
func _set_lettering(r: RichTextLabel, text: String, cap_color := Style.C_STRIKE, key := "") -> void:
	if key == "":
		key = text
	var body := Style.numbers(text)
	var first := text.left(1)
	if first != "" and first.to_upper() != first.to_lower():  # a letter (not bbcode, not a digit)
		var size: int = r.get_theme_font_size("normal_font_size")
		body = "[font_size=%d][color=#%s][outline_size=8][outline_color=#%s]%s[/outline_color][/outline_size][/color][/font_size]%s" % [
			roundi(size * Tuning.CAP_SCALE), cap_color.to_html(false), Style.C_GOLD.to_html(false), first, Style.numbers(text.substr(1))]
	r.text = "[center]%s[/center]" % body
	var f := r.get_node_or_null("Flourish")
	if f:
		f.queue_redraw()
	if r.get_meta("ink_key", "") == key:
		return
	r.set_meta("ink_key", key)
	# Advanced in _process with a capped step: new words cost a long frame (glyphs rasterising),
	# which would swallow a tween whole.
	_inking[r] = 0.0 if text != "" else 1.0
	(r.material as ShaderMaterial).set_shader_parameter("reveal", _inking[r])


## A thin red pen flourish under the words: a swash that swells in the middle, curls at both ends.
func _draw_flourish(f: Control, r: RichTextLabel) -> void:
	if r.get_parsed_text().strip_edges() == "":
		return
	var w := minf(f.size.x * 0.8, maxf(160.0, r.get_content_width() * 0.7))
	var cx := f.size.x / 2.0
	var cy := f.size.y * 0.45
	var pts := PackedVector2Array()
	var n := 48
	for i in n + 1:
		var t := float(i) / n
		var x := cx + (t - 0.5) * w
		pts.append(Vector2(x, cy + sin(t * TAU * 1.5) * 4.0 * sin(t * PI)))
	var col := Style.C_STRIKE.darkened(0.1)
	for i in n:
		var t := (float(i) + 0.5) / n
		f.draw_line(pts[i], pts[i + 1], col, 1.0 + 2.6 * sin(t * PI), true)  # pen pressure: thick mid, hairline ends
	# Curls and a lozenge at the centre.
	for s in [-1.0, 1.0]:
		f.draw_arc(Vector2(cx + s * (w / 2.0 + 5.0), cy - 4.0), 6.0, 0.0, TAU * 0.75, 16, col, 1.2, true)
	f.draw_colored_polygon(PackedVector2Array([Vector2(cx, cy - 6), Vector2(cx + 5, cy), Vector2(cx, cy + 6), Vector2(cx - 5, cy)]), col)
func set_waiting_text(text: String) -> void:
	if not _waiting or _prompt_label.get_meta("wait", "") == text:
		return
	_prompt_label.set_meta("wait", text)
	_set_lettering(_prompt_label, text, Style.C_STRIKE, text.rstrip(". "))  # the dots don't re-ink


func show_ticker(text: String) -> void:
	_show_log(text)


func _refresh_plate(pt: Dictionary, ps: Dictionary) -> void:
	pt.score.text = str(ps.score)
	pt.dice.text = str(ps.dice)
	var tag: String = ps.tag
	var nm: String = tag if tag != "" and not pt.mine else ("You" if pt.mine else pt.sin)
	if pt.name.text != nm:
		pt.name.text = nm
		_fit_label(pt.name, MIN_TEXT, 30)
	pt.name.add_theme_color_override("font_color", Style.C_STRIKE.lightened(0.4) if ps.purg else (Style.C_GOLD if tag != "" and not pt.mine else Style.C_BONE))


## Whose turn: the capital is illuminated in that player's Sin colour.
func _set_banner(text: String, p) -> void:
	if _banner_text.get_meta("ink_key", "") == text:
		return
	_set_lettering(_banner_text, text, Style.SIN_COLORS[p.sin.sin_name].lightened(0.1))


## Shrinks a one-line label until its text fits its width ("Gluttony" on a narrow plate).
func _fit_label(l: Label, size: int, floor_size: int) -> void:
	var font: Font = l.get_theme_font("font")
	var s := size
	while s > floor_size and font.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, s).x > l.size.x - 4:
		s -= 1
	l.add_theme_font_size_override("font_size", s)


## Light behind a Sin's window. Greed's silver glass gets a cold blue-white candle so it glows.
func _backlight(sname: String) -> Color:
	return Color("bcd8ff") if sname == "Greed" else Style.SIN_COLORS[sname].lightened(0.15)


func _t2_ready(p) -> bool:
	return game.tier2 and ((p.t2_unlocked and p.t2_ready) or (not p.t2_unlocked and p.score >= Rules.TIER2_SCORE))


func _me():
	for p in game.players:
		if p.bot == human:
			return p
	return null


## Up to 5 dice in one row, more in two. As big as the stage allows, capped at 64pt.
func _show_dice(faces: Array) -> void:
	var key := str(faces)
	if _dice_row.get_meta("key", "") == key:
		return
	_dice_row.set_meta("key", key)
	for c in _dice_row.get_children():
		c.queue_free()
	_dice_nodes.clear()
	var n := faces.size()
	if n == 0:
		return
	var rows := 1 if n <= 5 else 2
	var per_row := ceili(float(n) / rows)
	var gap := 16.0
	var area := _dice_area.size
	var side := minf(DIE_MAX, (area.x - gap * (per_row - 1)) / per_row)
	side = minf(side, (area.y - gap * (rows - 1)) / rows)
	side = maxf(side, 60.0)
	_dice_row.offset_top = maxf(0.0, (area.y - rows * side - (rows - 1) * gap) / 2.0)
	# Each die sits in a fixed holder so the director can throw, lift and spin it without the flow
	# container snapping it back.
	for i in n:
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(side, side)
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var d = Die.new(faces[i], int(side), i * 7 + faces[i])
		d.size = Vector2(side, side)
		d.pivot_offset = Vector2(side, side) / 2
		holder.add_child(d)
		_dice_row.add_child(holder)
		_dice_nodes.append(d)


# ---------- Called by core/game.gd and ui/human.gd ----------

func player_name(p) -> String:
	if p.bot == human:
		return "You"
	return p.sin.sin_name if p.sin else "Bot %d" % p.seat


## Every rules log line becomes one queued beat that shows the state as it was when said.
func log_line(text: String) -> void:
	if _q == null or game == null or _portraits.is_empty():
		_show_log(text)
		return
	var snap := _snapshot()
	var prev := _last_snap
	_last_snap = snap
	var ev := Events.classify(text)
	_q.push(func(): await _dir.play(text, ev, prev, snap))


func _show_log(text: String) -> void:
	_log_lines.append(text)
	if _log:
		_log.append_text(_with_sigils(Style.numbers(text)) + "\n")
	if _ticker_text and text.strip_edges() != "":
		var plain := RegEx.create_from_string("\\[[^\\]]*\\]").sub(text, "", true).strip_edges()
		_ticker_text.text = _with_sigils(Style.numbers(plain))


## Anticipation (slight draw-in), impact (white-hot, punch out), settle.
func _flare(pt: Dictionary) -> void:
	var win: TextureRect = pt.window
	var mat: ShaderMaterial = win.material
	win.pivot_offset = win.size / 2
	if pt.has("flare_tw") and pt.flare_tw.is_valid():
		pt.flare_tw.kill()
	var tw: Tween = _q.tween(self)
	pt.flare_tw = tw
	var set_flash := func(v: float): mat.set_shader_parameter("flash", v)
	tw.tween_property(win, "scale", Vector2(0.96, 0.96), 0.06)
	tw.tween_method(set_flash, 0.0, 1.0, 0.07)
	tw.parallel().tween_property(win, "scale", Vector2(1.12, 1.12), 0.07).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_method(set_flash, 1.0, 0.0, 0.5).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(win, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)


## One short handwritten line under the Sin's plate: ability in gold, what it did in ivory.
## Returned so the director can take it away when its beat ends.
func _marginalia(pt: Dictionary, ability: String, what: String) -> Control:
	_notes = _notes.filter(func(n): return is_instance_valid(n) and not n.is_queued_for_deletion())
	while _notes.size() >= 2:  # at most two at once; the Chronicle keeps them all
		_notes.pop_front().queue_free()
	var w := 560.0
	var note := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(Style.C_BLACK, 0.88)
	sb.border_color = Color(Style.SIN_COLORS[pt.sin], 0.9)
	sb.border_width_left = 6
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(12)
	sb.content_margin_left = 22
	note.add_theme_stylebox_override("panel", sb)
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var text := Style.body("[color=#e9c46a]%s[/color]\n%s" % [ability, what], MIN_TEXT, Style.C_IVORY)
	text.custom_minimum_size.x = w - 34
	note.add_child(text)
	var r: Rect2 = pt.col.get_global_rect()
	var y := r.end.y + 6
	for n in _notes:
		y = maxf(y, n.position.y + maxf(n.size.y, 110.0) + 8)
	note.position = Vector2(clampf(r.get_center().x - w / 2, 24.0, size.x - 24.0 - w), y - 10)
	note.modulate.a = 0.0
	add_child(note)
	if _log_overlay:
		move_child(note, _log_overlay.get_index())  # under the Chronicle
	_notes.append(note)
	var tw: Tween = _q.tween(note)
	tw.tween_property(note, "modulate:a", 1.0, 0.2)
	tw.parallel().tween_property(note, "position:y", y, Tuning.ACTION).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	return note


## Puts each Sin's sigil before its name, so the log reads by shape as well as colour.
func _with_sigils(bb: String) -> String:
	for sname in Style.SIN_COLORS:
		bb = bb.replace(sname, "[img=40x40]%s[/img] %s" % [Art.sigil_path(sname), sname])
	return bb


## Turn change: its own beat (longer when it's yours). Docs/UXPass.md #1.
func turn_started(p) -> void:
	var snap := _snapshot()
	_last_snap = snap
	var header := "[color=#e9c46a]-- %s (%d) --[/color]" % [player_name(p), p.score]
	_q.push(func():
		_show_log("")
		_show_log(header)
		await _dir.turn_change(p, snap))


## core/game.gd awaits this after a throw, a bust and at the end of a turn: let the screen catch up
## (and show the state as it stands now, e.g. Purgatory after a bust) before the rules go on.
func beat(_p, _kind: String) -> void:
	var snap := _snapshot()
	_last_snap = snap
	_q.push(func(): _refresh(snap, ["plates", "glow", "banner", "turn", "strikes"]))
	await _q.drain()


## Queued like everything else, so the buttons only appear once the board has caught up.
## Then the director pulses what you can tap and dims the rest.
func show_prompt(text: String, options: Array) -> void:
	_q.push(func():
		_q.skip_all = false  # "skip to my next decision" ends here
		if _replaying:  # Continue: caught up, lift the ink
			_replaying = false
			_ink_wash(false)
		if game and not _portraits.is_empty():
			_refresh(_snapshot(), ["plates", "glow", "banner", "turn", "strikes"])
		_show_prompt_now(text, options)
		await get_tree().process_frame  # buttons placed
		_layout_buttons()
		_dir.my_turn(_buttons.get_children().filter(func(b): return not b.is_queued_for_deletion())))


## Dice counts become one row of small seals that only select (the most dice starts selected),
## and a separate Throw seal below that commits the selection (crimson, right thumb).
## Bank is the bronze seal beside it on the left. Anything else is a red plaque.
func _show_prompt_now(text: String, options: Array) -> void:
	clear_prompt()
	_waiting = false
	_set_lettering(_prompt_label, text)
	var counts := options.filter(func(o): return o[0].is_valid_int())
	var most := 0
	for o in counts:
		most = maxi(most, int(o[0]))
	var group := ButtonGroup.new()
	var throw_b: Button = null
	if most > 0:
		throw_b = Button.new()
		throw_b.set_meta("kind", "roll")
		Art.skin(throw_b, Art.SEAL_L)
		_seal_face(throw_b, most, true)
		throw_b.set_meta("value", counts.filter(func(o): return int(o[0]) == most)[0][1])
		_seal_feel(throw_b, "roll", func(): human.answered.emit(throw_b.get_meta("value")))
		throw_b.material = Art.glint_material(-Tuning.GLINT_STAGGER * (most + 1))
	for o in options:
		var kind := "pill"
		if o[0].is_valid_int():
			if counts.size() < 2:
				continue  # one choice: the Throw seal alone
			kind = "num"
		elif o[0].begins_with("Bank") and most > 0:
			kind = "bank"
		var b := Button.new()
		b.set_meta("kind", kind)
		match kind:
			"num":
				Art.skin(b, Art.SEAL_S, Color(0.82, 0.76, 0.76))
				# Selected: the wax brightens and a gold ring circles it (toggled on = "pressed" style).
				for st in ["pressed", "hover_pressed"]:
					b.add_theme_stylebox_override(st, _seal_style(Art.SEAL_S[0], Color(1.2, 1.1, 1.0)))
				_seal_face(b, int(o[0]), false)
				b.toggle_mode = true
				b.button_group = group
				b.button_pressed = int(o[0]) == most
				_selected_ring(b)
				b.material = Art.glint_material(-Tuning.GLINT_STAGGER * int(o[0]))  # glints travel along the row
				var n := int(o[0])
				var cv = o[1]
				b.toggled.connect(func(on: bool):
					if on and throw_b:
						throw_b.set_meta("value", cv)
						_seal_face(throw_b, n, true))
				_seal_feel(b, "num", Callable())
				_buttons.add_child(b)
				continue
			"bank":
				_bronze_seal(b)
				_caption(b, o[0].replace(" ", "\n"), 56)
			_:
				Art.skin(b, [Art.YOU_TAB, Art.YOU_TAB, Art.YOU_TAB], Color.WHITE, 24)
				b.set_meta("w", Style.BLACKLETTER.get_string_size(o[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 42).x + 70)
				if RegEx.create_from_string("\\d").search(o[0]):
					_caption(b, o[0], 42)
				else:
					b.text = o[0]
					b.add_theme_font_size_override("font_size", 42)
		var val = o[1]
		_seal_feel(b, kind, func(): human.answered.emit(val))
		_buttons.add_child(b)
	if throw_b:
		_buttons.add_child(throw_b)
	_layout_buttons.call_deferred()


## Tactile press: the seal sinks under the finger and springs back, with a sound.
## on_press: what a committing press does (empty for the dice-count seals, which only select).
func _seal_feel(b: Button, kind: String, on_press: Callable) -> void:
	b.add_theme_color_override("font_color", Style.C_IVORY)
	b.add_theme_color_override("font_hover_color", Style.C_IVORY)
	b.add_theme_color_override("font_pressed_color", Style.C_BONE)
	b.add_theme_constant_override("line_spacing", -14)
	b.button_down.connect(func():
		if on_press.is_valid():
			_dir.prompt_answered()
		else:
			_dir.haptic(0.15)
		_dir.sfx.play("plaque" if kind == "pill" else "seal", 0.7 if kind in ["roll", "bank"] else 0.4, 1.0, true)
		b.pivot_offset = b.size / 2
		# Squash: the wax gives under the thumb, wider and flatter.
		b.create_tween().tween_property(b, "scale", Tuning.PRESS_SQUASH, 0.06))
	b.button_up.connect(func():
		# Wobble back: spring the scale, rock the seal once either way.
		var tw := b.create_tween()
		tw.tween_property(b, "scale", Vector2.ONE, Tuning.RELEASE_WOBBLE).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
		var rk := b.create_tween()
		rk.tween_property(b, "rotation", deg_to_rad(Tuning.WOBBLE_DEG), Tuning.RELEASE_WOBBLE * 0.2)
		rk.tween_property(b, "rotation", deg_to_rad(-Tuning.WOBBLE_DEG * 0.5), Tuning.RELEASE_WOBBLE * 0.25)
		rk.tween_property(b, "rotation", 0.0, Tuning.RELEASE_WOBBLE * 0.55).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT))
	if on_press.is_valid():
		b.pressed.connect(on_press)


## Selected state for a dice-count seal: a gold ring drawn round it while it's toggled on.
func _selected_ring(b: Button) -> void:
	var ring := Control.new()
	ring.set_anchors_preset(Control.PRESET_FULL_RECT)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.draw.connect(func():
		if b.button_pressed:
			var r := minf(ring.size.x, ring.size.y) / 2.0
			ring.draw_arc(ring.size / 2, r - 4.0, 0, TAU, 64, Style.C_GOLD, 7.0, true))
	# Idle: the ring glows brighter and dimmer while selected.
	var glow := ring.create_tween().set_loops()
	glow.tween_property(ring, "modulate", Color(1.35, 1.25, 1.0), Tuning.RING_PULSE / 2).set_trans(Tween.TRANS_SINE)
	glow.tween_property(ring, "modulate", Color(0.7, 0.62, 0.5), Tuning.RING_PULSE / 2).set_trans(Tween.TRANS_SINE)
	b.add_child(ring)
	b.toggled.connect(func(_on): ring.queue_redraw())


func clear_prompt() -> void:
	_waiting = true
	_prompt_label.set_meta("wait", "")
	_set_lettering(_prompt_label, "")
	for c in _buttons.get_children():
		c.queue_free()


## Places the prompt buttons inside _buttons by hand (it holds only Buttons, see tests/ui_autoplay.gd).
func _layout_buttons() -> void:
	if _buttons == null:
		return
	var bs: Array = _buttons.get_children().filter(func(b): return not b.is_queued_for_deletion())
	var w := _buttons.size.x
	var h := _buttons.size.y
	var big := bs.filter(func(b): return b.get_meta("kind") in ["roll", "bank"])
	var nums := bs.filter(func(b): return b.get_meta("kind") == "num")
	var pills := bs.filter(func(b): return b.get_meta("kind") == "pill")
	var gap := GAP_MIN
	var mid := w / 2.0
	if not big.is_empty() or not nums.is_empty():
		# Dice counts: one centred row of equal seals (wraps above what fits), selecting only.
		# Below it, apart: Bank (left) and Throw (right), the only seals that commit.
		# Bank and Throw are one size whatever the dice count (SEAL_CONFIRM). Only the counts
		# shrink and wrap. When they overflow the space above, Bank and Throw move out to the page
		# edges and the last counts sit between them. Only past that (9+ dice with Bank) do the
		# confirm seals give way.
		var has_bank := big.any(func(b): return b.get_meta("kind") == "bank")
		var d := minf(minf(float(SEAL_CONFIRM), h - SEAL_SMALL - gap * 1.5), (w - gap * 2.0) / 2.0)
		var s := float(SEAL_SMALL)
		var per_row := 1
		var in_band := 0
		var top := 0.0
		var slot_l := 0.0
		var slot_w := 0.0
		var fits := false
		while not fits:
			d = maxf(d, TARGET_MIN)
			top = h - d
			var room := h - d - gap * 1.5
			slot_l = (d + gap) if has_bank else 0.0
			slot_w = w - d - gap - slot_l
			s = float(SEAL_SMALL)
			while true:
				per_row = maxi(1, int((w + gap) / (s + gap)))
				var fit_rows := maxi(0, int((room + gap) / (s + gap)))
				var rows := ceili(float(nums.size()) / per_row)
				in_band = 0
				if rows <= fit_rows:
					fits = true
				elif not big.is_empty():
					in_band = nums.size() - fit_rows * per_row
					fits = in_band <= maxi(0, int((slot_w + gap) / (s + gap)))
				if fits or s <= TARGET_MIN:
					break
				s = maxf(TARGET_MIN, s - 4.0)
			if not fits and d <= TARGET_MIN:
				break
			d -= 8.0
		if not fits:
			# Last resort (10+ dice): one grid of equal 44 pt seals, Bank and Throw ending the last row.
			var all := nums + big.filter(func(b): return b.get_meta("kind") == "bank") + big.filter(func(b): return b.get_meta("kind") == "roll")
			var gs := TARGET_MIN
			var gper := maxi(1, int((w + gap) / (gs + gap)))
			var grows := ceili(float(all.size()) / gper)
			var ggap := clampf((h - grows * gs) / maxf(1.0, grows - 1), 0.0, gap)  # squeeze rows if we must
			for i in all.size():
				var r := i / gper
				var in_row := mini(gper, all.size() - r * gper)
				var total := in_row * gs + (in_row - 1) * gap
				all[i].position = Vector2(mid - total / 2.0 + (i % gper) * (gs + gap), r * (gs + ggap))
				all[i].size = Vector2(gs, gs)
				if all[i].get_meta("kind") != "num":
					_fit_caption(all[i], gs)
			return
		var above := nums.size() - in_band
		for i in above:
			var r := i / per_row
			var in_row := mini(per_row, above - r * per_row)
			var total := in_row * s + (in_row - 1) * gap
			nums[i].position = Vector2(mid - total / 2.0 + (i % per_row) * (s + gap), r * (s + gap))
			nums[i].size = Vector2(s, s)
		var band_total := in_band * s + maxi(0, in_band - 1) * gap
		for j in in_band:
			var b: Control = nums[above + j]
			b.position = Vector2(slot_l + (slot_w - band_total) / 2.0 + j * (s + gap), top + (d - s) / 2.0)
			b.size = Vector2(s, s)
		for b in big:
			var cx: float = mid
			if in_band > 0:
				cx = (w - d / 2.0) if b.get_meta("kind") == "roll" else d / 2.0
			elif big.size() > 1:
				cx = mid + (d / 2.0 + gap) * (1.0 if b.get_meta("kind") == "roll" else -1.0)
			b.position = Vector2(cx - d / 2.0, top)
			b.size = Vector2(d, d)
			_fit_caption(b, d)
	if not pills.is_empty():
		var rows := [[]]
		var row_w := 0.0
		for b in pills:
			var bw := minf(w, maxf(240.0, b.get_meta("w", 240.0)))
			if row_w + bw > w and not rows[-1].is_empty():
				rows.append([])
				row_w = 0.0
			rows[-1].append([b, bw])
			row_w += bw + gap
		var bh := clampf((h - gap * (rows.size() - 1)) / rows.size(), TARGET_MIN + 2.0, float(SEAL_SMALL))  # rows fit the page
		var y := 0.0
		for r in rows:
			var rw := 0.0
			for e in r:
				rw += e[1]
			rw += gap * (r.size() - 1)
			var x := (w - rw) / 2.0
			for e in r:
				e[0].position = Vector2(x, y)
				e[0].size = Vector2(e[1], bh)
				x += e[1] + gap
			y += bh + gap


## Button face: words in blackletter, numbers in Cinzel gold. Leaves b.text empty.
func _caption(b: Button, text: String, size: int) -> void:
	var nums := RegEx.create_from_string("(\\d+)").sub(text, "[font=%s][color=#%s]$1[/color][/font]" % [Style.NUMERAL.resource_path, Style.C_GOLD.to_html(false)], true)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_OFF
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.add_theme_font_override("normal_font", Style.BLACKLETTER)
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_color_override("default_color", Style.C_IVORY)
	r.add_theme_constant_override("line_separation", -int(size * 0.25))
	r.add_theme_constant_override("outline_size", 8)
	r.add_theme_color_override("font_outline_color", Style.C_BLACK)
	r.text = "[center]%s[/center]" % nums
	c.add_child(r)
	b.add_child(c)


# ---------- Helpers ----------

## Bank: the same seal recast in dark bronze, so it can't be mistaken for Roll's crimson.
func _bronze_seal(b: Button) -> void:
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	var wax := TextureRect.new()
	wax.texture = Art.SEAL_L[0]
	wax.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wax.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	wax.set_anchors_preset(Control.PRESET_FULL_RECT)
	wax.show_behind_parent = true
	wax.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wax.material = Art.tint_material(Color("e0b872"))
	wax.modulate = Color(2.0, 1.75, 1.4)  # red wax is dark; lift it to bronze
	b.add_child(wax)
	b.button_down.connect(func(): wax.texture = Art.SEAL_L[1])
	b.button_up.connect(func(): wax.texture = Art.SEAL_L[0])


func _seal_style(tex: Texture2D, mod: Color) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = tex
	s.modulate_color = mod
	return s


func _page() -> VBoxContainer:
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 24)
	m.add_theme_constant_override("margin_right", 24)
	var safe := _safe_insets()
	m.add_theme_constant_override("margin_top", int(safe.x) + 16)
	m.add_theme_constant_override("margin_bottom", int(safe.y) + 12)
	add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	m.add_child(v)
	return v


## Notch and home-indicator insets in viewport pixels (x = top, y = bottom). Zero on web.
func _safe_insets() -> Vector2:
	if debug_safe != Vector2.ZERO:
		return debug_safe
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


## Resizes a seal's caption (see _caption) to fit a seal laid out smaller than full size.
func _caption_size(b: Button, size: int) -> void:
	for r in b.find_children("*", "RichTextLabel", true, false):
		r.add_theme_font_size_override("normal_font_size", size)
		r.add_theme_constant_override("line_separation", -int(size * 0.25))


## A seal's face: the gold-leaf numeral in the wax (Throw adds the marginalia hand above it).
## Numbers past 9 fall back to a text caption. Replaces any face already on the seal.
func _seal_face(b: Button, n: int, hand: bool) -> void:
	for c in b.get_children():
		if c.has_meta("face"):
			c.queue_free()
	var tex := Art.numeral(n)
	if tex == null:
		_caption(b, ("Throw\n%d" if hand else "%d") % n, 62)
		b.get_child(b.get_child_count() - 1).set_meta("face", true)
		return
	var face := Control.new()
	face.set_meta("face", true)
	face.set_anchors_preset(Control.PRESET_FULL_RECT)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Fractions of the seal: the wax recess is about the middle 60%. Throw's hand is ink on
	# parchment, so it sits outside, in the margin to the seal's upper right, tossing the dice.
	var parts := [[tex, Rect2(0.27, 0.22, 0.46, 0.5)]]
	if hand:
		parts.append([Art.THROW_HAND, Rect2(0.78, -0.12, 0.5, 0.62)])
	for p in parts:
		var t := TextureRect.new()
		t.texture = p[0]
		if p[0] == tex:
			t.material = Art.shimmer_material(n * 0.137)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var r: Rect2 = p[1]
		t.anchor_left = r.position.x
		t.anchor_top = r.position.y
		t.anchor_right = r.end.x
		t.anchor_bottom = r.end.y
		face.add_child(t)
	b.add_child(face)


## Sizes a seal's text caption (Bank, or a fallback) to sit inside the wax recess of a seal d px wide:
## every line within the recess width, all lines within its height. Words in blackletter, numbers in Cinzel.
func _fit_caption(b: Button, d: float) -> void:
	var rs := b.find_children("*", "RichTextLabel", true, false)
	if rs.is_empty():
		return
	var lines: PackedStringArray = rs[0].get_parsed_text().strip_edges().split("\n")
	var recess := d * SEAL_RECESS
	var size := 62.0
	for line in lines:
		var font: Font = Style.NUMERAL if line.is_valid_int() else Style.BLACKLETTER
		var w := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 100).x / 100.0  # width per px of font size
		size = minf(size, recess / maxf(0.01, w))
	size = minf(size, recess / (lines.size() * 0.82))
	_caption_size(b, int(maxf(20.0, size)))


## Device tilt moves the candle pool on the parchment and slides the page a few px.
## No accelerometer (desktop, web): a slow drift so the page still feels alive.
func _process(delta: float) -> void:
	for r in _inking.keys():
		if not is_instance_valid(r):
			_inking.erase(r)
			continue
		var cw: float = maxf(r.get_content_width(), 1.0)  # the words, centred: ink only across them
		var im := r.material as ShaderMaterial
		im.set_shader_parameter("start", (r.size.x - cw) / 2.0)
		im.set_shader_parameter("width", cw)
		var t: float = minf(1.0, _inking[r] + minf(delta, 1.0 / 30.0) / Tuning.INK_IN)
		(r.material as ShaderMaterial).set_shader_parameter("reveal", smoothstep(0.0, 1.0, t))
		if t >= 1.0:
			_inking.erase(r)
		else:
			_inking[r] = t
	if _paper == null or not is_instance_valid(_paper):
		return
	var g := Input.get_gravity()
	var want: Vector2
	if Tuning.reduce_motion:
		want = Vector2.ZERO
	elif g.length() > 0.5:
		want = Vector2(clampf(g.x / 9.8, -1, 1), clampf(-g.z / 9.8, -1, 1))
	else:
		var t := Time.get_ticks_msec() / 1000.0
		want = Vector2(sin(t * 0.31), cos(t * 0.23)) * Tuning.TILT_DRIFT
	_tilt = _tilt.lerp(want, clampf(delta * Tuning.TILT_SMOOTH, 0.0, 1.0))
	(_paper.material as ShaderMaterial).set_shader_parameter("tilt", _tilt)
	_paper.position = _tilt * Tuning.TILT_PX


## The page's corner figures as their own sprites (so the director can make them react).
func _add_marginalia(paper: Control) -> Dictionary:
	var out := {}
	for nm in Art.MARGINALIA:
		var md: Array = Art.MARGINALIA[nm]
		var tex: Texture2D = md[0]
		var corner: Vector2 = md[2]
		var sz := tex.get_size() * 0.55 * Tuning.MARGINALIA_SCALE
		var tr := TextureRect.new()
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.use_parent_material = true
		tr.anchor_left = corner.x
		tr.anchor_right = corner.x
		tr.anchor_top = corner.y
		tr.anchor_bottom = corner.y
		# Offsets are from the page corner, so scaling them grows the figure out of its corner.
		var p: Vector2 = (md[1] - corner * Vector2(Art.PAGE.get_size())) * 0.55 * Tuning.MARGINALIA_SCALE
		tr.offset_left = p.x
		tr.offset_top = p.y
		tr.offset_right = p.x + sz.x
		tr.offset_bottom = p.y + sz.y
		tr.pivot_offset = sz * (md[3] as Vector2)
		paper.add_child(tr)
		out[nm] = tr
	return out


# ---------- Screen transitions (polish 10) ----------

## Ink floods over the screen (cover) or draws away from it (uncover). Await it; taps are blocked
## while the ink is on screen.
func _ink_wash(cover: bool, origin := Vector2(0.5, 0.5)) -> void:
	if _wash == null:
		_wash = ColorRect.new()
		_wash.set_anchors_preset(Control.PRESET_FULL_RECT)
		_wash.material = Art.ink_wash_material()
		_wash.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(_wash)
	move_child(_wash, -1)
	_wash.visible = true
	var m := _wash.material as ShaderMaterial
	m.set_shader_parameter("origin", origin)
	m.set_shader_parameter("progress", 0.0 if cover else 1.0)
	var vp := get_viewport_rect().size
	m.set_shader_parameter("ratio", vp.y / maxf(vp.x, 1.0))
	var tw := create_tween()
	tw.tween_method(func(v: float): m.set_shader_parameter("progress", v), 0.0 if cover else 1.0, 1.0 if cover else 0.0, Tuning.WASH_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN if cover else Tween.EASE_OUT)
	await tw.finished
	if not cover:
		_wash.visible = false


## The Chronicle turns in like a page: it swings open from the left edge, shaded as it turns.
func _page_turn(node: Control, open: bool) -> void:
	node.pivot_offset = Vector2(0, node.size.y / 2.0)
	if open:
		node.visible = true
		node.scale = Vector2(0.02, 1.0)
		node.modulate = Color(0.35, 0.3, 0.28)
	var tw := create_tween()
	tw.tween_property(node, "scale:x", 1.0 if open else 0.02, Tuning.PAGE_TURN).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT if open else Tween.EASE_IN)
	tw.parallel().tween_property(node, "modulate", Color.WHITE if open else Color(0.35, 0.3, 0.28), Tuning.PAGE_TURN)
	await tw.finished
	if not open:
		node.visible = false
		node.scale = Vector2.ONE
		node.modulate = Color.WHITE
