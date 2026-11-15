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
const LivingPortrait = preload("res://ui/living_portrait.gd")
const SinCarousel = preload("res://ui/sin_carousel.gd")
const TutorialGame = preload("res://ui/tutorial_game.gd")
const TutorialBot = preload("res://ui/tutorial_bot.gd")
const Frame = preload("res://ui/widgets/frame.gd")
const Die = preload("res://ui/widgets/die.gd")
const CANDLE_BG = preload("res://ui/shaders/candle_bg.gdshader")
const ActionQueue = preload("res://ui/action_queue.gd")
const Director = preload("res://ui/director.gd")
const Tuning = preload("res://ui/tuning.gd")
const Events = preload("res://ui/events.gd")
const RunState = preload("res://run/run_state.gd")
const RunBoard = preload("res://ui/run_board.gd")
const Kits = preload("res://run/kits.gd")
const SETTINGS := "user://settings.cfg"
const SAVE := "user://save.json"
const SAVE_VERSION := 3  # 3: Rules.V4 with temptations (Docs/TableDesign.md); a V3 save can't replay
const MENU_TITLE := 150          # the title page: name, Play seal, Continue / Settings seals
const MENU_PLAY := 400
const MENU_SEAL := 280
const MUSIC := "res://assets/audio/music/menu.ogg"
const MENU_GLASS := preload("res://ui/shaders/menu_glass.gdshader")
const MENU_SHAFT := preload("res://ui/shaders/menu_shaft.gdshader")
const PANEL_FROM := 0.94          # panels (Settings, Chronicle) open from this scale
const CANDLE_RAW := Vector2(1065, 150) / Vector2(1152, 2048)  # the flame on bg_hd_raw.png, as a fraction
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
## Every rule, term and ability sentence lives in ui/rules_text.gd (numbers from the config).
const RulesText = preload("res://ui/rules_text.gd")
const Rulebook = preload("res://ui/rulebook.gd")
const ExplainCard = preload("res://ui/explain_card.gd")
const LONG_PRESS := 0.45          # hold this long anywhere to explain what's under your finger
const PRESS_SLOP := 30.0          # px a press may drift and still count as a tap / hold

## Sizes in px (viewport 1080 wide = 393pt). Brief: text >= 13pt, small seals >= 44pt, Roll/Bank >= 88pt, dice >= 64pt.
const MIN_TEXT := 36
const SEAL_SMALL := 140
const SEAL_BIG := 250
const SEAL_CONFIRM := 200   # Bank and Throw: the same size whatever the dice count (polish item 4)
const TARGET_MIN := 44.0 * 1080.0 / 393.0   # 44 pt: smallest tappable thing (Apple HIG)
const GAP_MIN := 13.0 * 1080.0 / 393.0      # a little over 12 pt between separate targets
const SIDE_MIN := 17.0 * 1080.0 / 393.0     # a little over 16 pt from the screen's sides
const SEAL_RECESS := 0.46                  # the painted seal's wax recess, as a fraction of its width
## Emblem seals (Nov 15): the emblem says what it does, an inked word sits under the seal and a gold
## numeral beside it; nothing is written on the wax. Sizes as fractions of the seal's width.
const CAP_K := 0.2          # caption font size
const CAP_MIN := 34
const CAP_MAX := 60
const CAP_GAP := 2.0        # px between the wax and the word
const NUM_K := 0.5          # the numeral's height (gold-leaf texture), or its font size x 0.8
const SCORE_SIZE := 116

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
var _strike_icons: Array = []   # the Strike candles
var _result_label: Label          # one line under the throw total: what scored (result_line)
var _score_zone: Control          # the reserved strip holding the throw total and result line, or an ability note
var _prompt_label: RichTextLabel
var _buttons: Control             # holds only prompt Buttons (tests/ui_autoplay.gd presses them)
var _summary: Button               # bot-turn summary on the thumb page (tap: the Chronicle)
var _summary_rows: VBoxContainer
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
var _summary_parts: Array = []      # what the bot at the dice has done this turn (_summary_event)
var _thumb: Control
var marginalia := {}               # jester / pennant / skeleton TextureRects on the thumb page (director reacts with them)
var _paper: Control               # thumb-zone parchment (slides and catches light with tilt)
var _tilt := Vector2.ZERO
var _inking := {}                 # lettering label -> ink-in progress 0..1 (_set_lettering, _process)
var _wash: ColorRect                # full-screen ink for screen transitions (_ink_wash)
static var _wash_on_load := false   # a New game reload starts under the ink and washes it away
static var _setup_on_load := false  # ...and opens on the Sin choice, not the menu
static var _run_setup_on_load := false  # New run: the reload opens the run's Sin choice
var run_rules_seen := false        # the one rules card for the run game has been shown
var tempt_tip_seen := false        # the first temptation's tip has been shown (ui/human.gd)
var _line_turn := -1               # a Sin line was said on this turn already (one a turn)
var _lines_used := {}              # lines said this game (never twice)
var _run_board: Control
var _starting := false
var _save := {}                    # the game in progress, as written to SAVE
var _replaying := false            # Continue: replaying saved answers under the ink
var save_enabled := true           # tests turn this off
var tutorial_enabled := true       # tests turn this off too
## First Game mode until a game is finished: table of 4, Basic abilities only, bots at half speed.
## Finishing a game unlocks Greater abilities and the Table of 7. Saved in settings.cfg.
var games_finished := 0
var first_game_enabled := true     # tests choose per game
var _first_game := false           # the game in progress is a First Game


func is_first_game() -> bool:
	return first_game_enabled and games_finished == 0
var _menu_seals: Array = []
var _settings: Control            # the Settings page while open
var _desk: Control
var _dice_nodes: Array = []       # the Die controls showing now, in face order
var _last_snap := {}              # the state as of the last queued event (the next one's "before")
var _focus_groups := {}
var _speed_label: Label
var _speed_slider: HSlider
var _last_tap := -1.0
var _skip: Button                 # "Skip to my turn", on the thumb page during bot turns
static var tutorial_pending := true  # the tutorial hasn't been played or skipped: Play starts it
static var _tutorial_on_load := false  # Settings > Tutorial > Play: the reload opens the tutorial
static var _tutorial_from_settings := false
var _tutor = null                  # ui/tutorial_game.gd while the tutorial is playing
var _music: AudioStreamPlayer
var _screen_root: Control          # the menu scene (freed when leaving it)
var _candle_glow: Control          # the menu candle's light pool (flickers in _process)
var _offer_card: Control           # a Sin's temptation, over the dice tray while it waits (_show_offer_now)
var _overlay: Control              # the rulebook or an explanation card while open (the queue waits)
var _pause: Button                 # the pause seal in the tray: Rulebook, Sin abilities, Chronicle, Settings, menu
var _explain_targets: Array = []   # [control, Callable]: what a tap / hold explains (_register_explain_targets)
var _press_at := Vector2.INF       # where the current press started (INF: none, or on a button)
var _press_t := 0.0
var _long_fired := false           # this press already explained (a hold)


func _ready() -> void:
	theme = Style.make_theme()
	_q = ActionQueue.new()
	add_child(_q)
	_dir = Director.new()
	add_child(_dir)
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS) == OK:
		Tuning.speed = clampf(float(cfg.get_value("ui", "speed", 1.0)), Tuning.SPEED_MIN, Tuning.SPEED_MAX)
		Tuning.sfx_vol = clampf(float(cfg.get_value("ui", "sfx", 1.0 if bool(cfg.get_value("ui", "sound", true)) else 0.0)), 0.0, 1.0)
		Tuning.muted = Tuning.sfx_vol <= 0.01
		Tuning.music_vol = clampf(float(cfg.get_value("ui", "music", Tuning.music_vol)), 0.0, 1.0)
		Tuning.haptics = bool(cfg.get_value("ui", "haptics", true))
		tutorial_pending = not bool(cfg.get_value("ui", "tutorial_done", false))
		run_rules_seen = bool(cfg.get_value("ui", "run_rules_seen", false))
		tempt_tip_seen = bool(cfg.get_value("ui", "tempt_tip_seen", false))
		games_finished = int(cfg.get_value("ui", "games_finished", 0))
		Tuning.reduce_motion = bool(cfg.get_value("ui", "reduce_motion", false))
		var ts := int(cfg.get_value("ui", "table", Tuning.TABLE_SIZES[0]))
		Tuning.table_size = ts if ts in Tuning.TABLE_SIZES else Tuning.TABLE_SIZES[0]
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
	# Music: one loop from launch, under everything (Settings: Music).
	_music = AudioStreamPlayer.new()
	if ResourceLoader.exists(MUSIC):
		_music.stream = load(MUSIC)
		if _music.stream is AudioStreamOggVorbis:
			_music.stream.loop = true
	add_child(_music)
	_apply_music()
	if _music.stream:
		_music.play()
	if _tutorial_on_load:  # Settings > Tutorial > Play
		_tutorial_on_load = false
		start_tutorial(_tutorial_from_settings)
	elif _run_setup_on_load:
		_run_setup_on_load = false
		_build_run_setup()
	elif _setup_on_load:  # New game goes straight to choosing a Sin
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
	var vp := get_viewport_rect().size
	var safe := _safe_insets()
	var scene := Control.new()
	scene.set_anchors_preset(Control.PRESET_FULL_RECT)
	scene.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scene)
	_screen_root = scene
	# The far wall: darkness over the top of the table, where the seven windows hang.
	var wall := TextureRect.new()
	var wg := Gradient.new()
	wg.set_color(0, Color(0.02, 0.012, 0.01, 0.95))
	wg.set_color(1, Color(0.02, 0.012, 0.01, 0.0))
	var wt := GradientTexture2D.new()
	wt.gradient = wg
	wt.fill_from = Vector2(0.5, 0.0)
	wt.fill_to = Vector2(0.5, 1.0)
	wall.texture = wt
	wall.position = Vector2(-40, -40)
	wall.size = Vector2(vp.x + 80, vp.y * 0.42 + 40)
	wall.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene.add_child(wall)
	# The seven windows, centred across the wall, each lit from behind (menu_glass: cloud light and a
	# passing sheen), with a halo, a shaft of its colour onto the table, motes in the shaft and a pool
	# of coloured light where the shaft lands.
	var names: Array = RulesText.SIN_ORDER
	var gap := 14.0
	var margin := vp.x * Tuning.MENU_WINDOW_MARGIN
	var ww := (vp.x - margin * 2.0 - gap * (names.size() - 1)) / names.size()
	var wh := ww / 0.295
	var top := safe.x + 46.0
	var motion := 0.0 if Tuning.reduce_motion else 1.0
	var windows := Control.new()
	windows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene.add_child(windows)
	var shafts := Control.new()  # behind the glass, so every shaft starts under its window
	shafts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	windows.add_child(shafts)
	for i in names.size():
		var col: Color = Style.SIN_COLORS[names[i]]
		var holder := Control.new()
		holder.position = Vector2(margin + i * (ww + gap), top)
		holder.size = Vector2(ww, wh)
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		windows.add_child(holder)
		var ph := float(i) * 1.37
		# The shaft: a widening beam falling onto the table, fanning out from the centre of the wall.
		var shaft := Polygon2D.new()
		var w0 := ww * 0.8
		var len := vp.y * Tuning.MENU_SHAFT_LEN
		var cx := holder.position.x + ww / 2.0
		var drift := (cx - vp.x / 2.0) * 0.45
		var y0 := top + wh * 0.55
		var foot := Vector2(cx + drift, top + wh + len)
		shaft.polygon = PackedVector2Array([Vector2(cx - w0 / 2, y0), Vector2(cx + w0 / 2, y0),
			Vector2(foot.x + w0 * 1.7, foot.y), Vector2(foot.x - w0 * 1.7, foot.y)])
		# Beam coordinates for menu_shaft (r = across, g = along): Polygon2D drops UVs without a texture.
		shaft.vertex_colors = PackedColorArray([Color(0, 0, 0), Color(1, 0, 0), Color(1, 1, 0), Color(0, 1, 0)])
		var sm := ShaderMaterial.new()
		sm.shader = MENU_SHAFT
		sm.set_shader_parameter("tint", col.lightened(0.25))
		sm.set_shader_parameter("strength", Tuning.MENU_SHAFT_STRENGTH)
		sm.set_shader_parameter("phase", ph)
		sm.set_shader_parameter("motion", motion)
		shaft.material = sm
		shafts.add_child(shaft)
		# Where the light lands: a soft coloured pool on the table, breathing with the window.
		var pool := TextureRect.new()
		pool.texture = Art.soft_dot(128, col.lightened(0.2))
		pool.material = Art.additive()
		pool.size = Vector2(w0 * 4.0, w0 * 1.6)
		pool.position = foot - Vector2(pool.size.x / 2, pool.size.y * 0.75)
		pool.modulate.a = 0.22
		pool.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shafts.add_child(pool)
		# Motes catching the light, only inside the beam.
		if motion > 0.0:
			var motes := CPUParticles2D.new()
			motes.texture = Art.soft_dot(32)
			motes.material = Art.additive()
			motes.amount = 7
			motes.lifetime = 7.0
			motes.preprocess = 7.0
			motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
			motes.emission_rect_extents = Vector2(w0 * 0.7, len * 0.35)
			motes.position = Vector2(cx + drift * 0.5, y0 + len * 0.45)
			motes.direction = Vector2(0.15, 1)
			motes.spread = 30.0
			motes.gravity = Vector2(0, 3)
			motes.initial_velocity_min = 3.0
			motes.initial_velocity_max = 10.0
			motes.scale_amount_min = 0.1
			motes.scale_amount_max = 0.3
			var mg := Gradient.new()
			var mc := col.lightened(0.6)
			mg.set_color(0, Color(mc, 0.0))
			mg.set_color(1, Color(mc, 0.0))
			mg.add_point(0.4, Color(mc, 0.5))
			motes.color_ramp = mg
			shafts.add_child(motes)
		# The halo: light spilling round the stone, breathing slowly.
		var glow := TextureRect.new()
		glow.texture = Art.soft_dot(128, col.lightened(0.15))
		glow.material = Art.additive()
		glow.position = Vector2(-ww * 0.75, -wh * 0.12)
		glow.size = Vector2(ww * 2.5, wh * 1.24)
		glow.modulate.a = Tuning.MENU_HALO
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(glow)
		# The rim: a tight, brighter glow hugging the window's outline.
		var rim := TextureRect.new()
		rim.texture = Art.soft_dot(128, col.lightened(0.35))
		rim.material = Art.additive()
		rim.position = Vector2(-ww * 0.22, -wh * 0.05)
		rim.size = Vector2(ww * 1.44, wh * 1.1)
		rim.modulate.a = Tuning.MENU_HALO
		rim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(rim)
		if motion > 0.0:
			var per := 5.0 + fmod(i * 1.7, 2.5)
			for g in [glow, rim]:
				var tw: Tween = g.create_tween().set_loops()
				tw.tween_interval(fmod(i * 0.9, per))
				tw.tween_property(g, "modulate:a", Tuning.MENU_HALO * 1.35, per / 2).set_trans(Tween.TRANS_SINE)
				tw.tween_property(g, "modulate:a", Tuning.MENU_HALO * 0.7, per / 2).set_trans(Tween.TRANS_SINE)
		var win := TextureRect.new()
		win.texture = Art.window(names[i])
		win.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		win.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		win.size = holder.size
		win.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var gm := ShaderMaterial.new()
		gm.shader = MENU_GLASS
		gm.set_shader_parameter("phase", ph * 2.3)
		gm.set_shader_parameter("period", Tuning.MENU_SHEEN_PERIOD)
		gm.set_shader_parameter("motion", motion)
		win.material = gm
		holder.add_child(win)
	# The candle's light pool (the flame is painted on the table; this makes it breathe).
	var glow := TextureRect.new()
	glow.texture = Art.soft_dot(256, Color(1.0, 0.72, 0.38))
	glow.material = Art.additive()
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.size = Vector2(620, 620)
	glow.pivot_offset = glow.size / 2
	glow.position = _desk_point(CANDLE_RAW) - glow.size / 2
	scene.add_child(glow)
	_candle_glow = glow
	# Drifting dust motes, in front of everything else.
	var dust := CPUParticles2D.new()
	dust.texture = Art.soft_dot(32)
	dust.material = Art.additive()
	dust.amount = 0 if Tuning.reduce_motion else 46
	dust.lifetime = 9.0
	dust.preprocess = 9.0
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust.emission_rect_extents = vp / 2
	dust.position = vp / 2
	dust.direction = Vector2(0.2, -1)
	dust.spread = 50.0
	dust.gravity = Vector2(0, -4)
	dust.initial_velocity_min = 6.0
	dust.initial_velocity_max = 22.0
	dust.scale_amount_min = 0.12
	dust.scale_amount_max = 0.42
	var dg := Gradient.new()
	dg.set_color(0, Color(1.0, 0.85, 0.6, 0.0))
	dg.set_color(1, Color(1.0, 0.85, 0.6, 0.0))
	dg.add_point(0.3, Color(1.0, 0.85, 0.6, 0.32))
	dg.add_point(0.7, Color(1.0, 0.85, 0.6, 0.22))
	dust.color_ramp = dg
	if dust.amount > 0:
		scene.add_child(dust)
	# The words and seals.
	_content = _page()
	var m := _content.get_parent()
	remove_child(m)
	scene.add_child(m)
	scene.move_child(m, dust.get_index() if dust.get_parent() else -1)
	var v := _content
	v.alignment = BoxContainer.ALIGNMENT_BEGIN
	var space := Control.new()
	space.custom_minimum_size.y = top + wh - safe.x + 24
	v.add_child(space)
	var title := _make_lettering(MENU_TITLE, Style.C_GOLD, true)
	title.add_theme_constant_override("outline_size", 14)
	title.add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.01))
	v.add_child(title)
	var sub := _make_lettering(44, Style.C_BONE, false)
	sub.add_theme_constant_override("outline_size", 10)
	sub.add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.01))
	v.add_child(sub)
	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(fill)
	# Play is the table game (Docs/TableDesign.md); Continue resumes it. The parked run game
	# (Docs/RunDesign.md) is a debug seal (Tuning.RUN_MODE).
	var saved := load_save()
	var play := _menu_seal("Play", MENU_PLAY, _open_setup, "play")
	var cont := _menu_seal("Continue", MENU_SEAL, func(): _start(null, saved), "play")
	var table: Button = _menu_seal(RulesText.run("menu_run"), MENU_SEAL, _open_run_setup) if Tuning.RUN_MODE else null
	if table:
		table.set_meta("kind", "run_old")
	var settings := _menu_seal("Settings", MENU_SEAL, _open_settings, "settings")
	var rules := _menu_seal("Rulebook", MENU_SEAL, func(): open_rulebook("contents"), "rulebook")
	var top_row := CenterContainer.new()
	top_row.add_child(_caption_room(play))
	v.add_child(top_row)
	var sep := Control.new()
	sep.custom_minimum_size.y = GAP_MIN * 1.2
	v.add_child(sep)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", int(GAP_MIN * 2.0))
	if not saved.is_empty():  # nothing to continue: no Continue seal at all
		row.add_child(_caption_room(cont))
	else:
		cont.queue_free()
	row.add_child(_caption_room(rules))
	row.add_child(_caption_room(settings))
	if table:
		row.add_child(table)
	v.add_child(row)
	var foot := Control.new()
	foot.custom_minimum_size.y = 40
	v.add_child(foot)
	_menu_seals = [play, rules, settings] + ([cont] if not saved.is_empty() else []) + ([table] if table else [])
	# Once laid out: ink the words in, bring the seals in, then let the title breathe.
	(func():
		_set_lettering(title, "Sinners' Gambit", Style.C_CRIMSON)
		_set_lettering(sub, RulesText.table("menu_sub"), Style.C_STRIKE)
		_dir.seals_enter(_menu_seals)
		if not Tuning.reduce_motion:
			title.pivot_offset = title.size / 2
			var tw := title.create_tween().set_loops()
			tw.tween_property(title, "scale", Vector2.ONE * 1.025, 2.4).set_trans(Tween.TRANS_SINE)
			tw.tween_property(title, "scale", Vector2.ONE, 2.4).set_trans(Tween.TRANS_SINE)).call_deferred()


## A point on the painted desk (fraction of bg_hd_raw.png) in screen pixels: the desk is drawn
## covering the screen, centred.
func _desk_point(f: Vector2) -> Vector2:
	var vp := get_viewport_rect().size
	var tex: Vector2 = Art.BG.get_size()
	var s := maxf(vp.x / tex.x, vp.y / tex.y)
	var drawn := tex * s
	return (vp - drawn) / 2 + f * drawn


## Frees whatever screen is showing (the menu scene, or a page).
func _free_screen() -> void:
	if _screen_root and is_instance_valid(_screen_root):
		_screen_root.queue_free()
	elif _content:
		_content.get_parent().queue_free()
	_screen_root = null
	_candle_glow = null


func _apply_music() -> void:
	if _music:
		_music.volume_db = linear_to_db(maxf(Tuning.music_vol, 0.001)) - 8.0
		_music.stream_paused = Tuning.music_vol <= 0.01


## A menu seal. With an emblem: the emblem in the wax and the word under it (ink: on parchment);
## add the seal to its container through _caption_room so the word has space. Without: the word
## on the wax (the parked run game).
func _menu_seal(text: String, size: int, on_press: Callable, emblem := "", ink := false) -> Button:
	var b := Button.new()
	b.set_meta("kind", "menu")
	b.custom_minimum_size = Vector2(size, size)
	if emblem != "":
		_emblem(b, emblem, text, ink, size)
		b.material = Art.glint_material(-Tuning.GLINT_STAGGER * size / 100.0)
		_seal_feel(b, "roll", on_press)
		return b
	Art.skin(b, Art.SEAL_L)
	# The word sits inside the wax recess (about the middle 46%): shrink long words to fit.
	var fs := int(size * Tuning.MENU_SEAL_TEXT)
	var room := size * Tuning.MENU_SEAL_ROOM
	var w := Style.BLACKLETTER.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 16.0  # + outline
	if w > room:
		fs = int(fs * room / w)
	_caption(b, text, fs)
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
	_free_screen()
	if tutorial_pending and tutorial_enabled:  # the first Play is the tutorial (it can be skipped)
		_starting = false
		start_tutorial(false)
		return
	_build_setup()
	_starting = false
	if _wash:
		move_child(_wash, -1)
	_ink_wash(false)


# ---------- Run mode (Docs/RunDesign.md; placeholder board ui/run_board.gd) ----------

## Play: the ink washes over the title page and the run's Sin choice is under it.
func _open_run_setup() -> void:
	if _starting:
		return
	_starting = true
	await _ink_wash(true)
	_dir._stop_pulses()
	_free_screen()
	_build_run_setup()
	_starting = false
	if _wash:
		move_child(_wash, -1)
	_ink_wash(false)


## The Sin carousel, each page showing that Sin's starting kit.
func _build_run_setup() -> void:
	_content = _page()
	var m := _content.get_parent() as MarginContainer
	m.add_theme_constant_override("margin_left", int(SIDE_MIN))
	m.add_theme_constant_override("margin_right", int(SIDE_MIN))
	_content.add_theme_constant_override("separation", int(GAP_MIN))
	var title := _make_lettering(100, Style.C_GOLD, true)
	title.add_theme_constant_override("outline_size", 12)
	title.add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.01))
	_content.add_child(title)
	_content.add_child(Style.body(RulesText.run("setup_blurb"), 34, Style.C_BONE, 8))
	var cfg := RunState.default_cfg()
	var kits := {}
	for s in Kits.ORDER:
		kits[s] = Kits.text(s, cfg) + ("  (%d dice)" % Kits.dice_count(s, cfg) if Kits.dice_count(s, cfg) != cfg.start_dice else "")
	var names: Array = SIN_SCRIPTS.map(func(s): return s.new().sin_name)
	var car = SinCarousel.new(names, false, _dir.sfx, kits)
	car.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_child(car)
	var choose := _menu_seal(RulesText.word("setup_choose"), Tuning.SELECT_CHOOSE, func(): _start_run(names[car.index]))
	choose.set_meta("kind", "choose")
	var cc := CenterContainer.new()
	cc.add_child(choose)
	_content.add_child(cc)
	(func():
		_set_lettering(title, RulesText.run("setup_title"), Style.C_CRIMSON)
		_dir.seals_enter([choose])).call_deferred()


## Starts a run as `sin`, or resumes a saved one at its shop.
func _start_run(sin: String, saved_run = null) -> void:
	if _starting:
		return
	_starting = true
	await _ink_wash(true)
	_free_screen()
	_content = null
	var run = saved_run
	if run == null:
		RunBoard.clear_save()
		run = RunState.new()
		run.start(sin, randi())
	var board = RunBoard.new()
	board.setup(self, run)
	board.show_rules = not run_rules_seen and saved_run == null
	if board.show_rules:
		run_rules_seen = true
		_save_settings()
	board.to_menu.connect(_to_menu)
	board.new_run.connect(func():
		_wash_on_load = true
		_run_setup_on_load = true
		await _ink_wash(true)
		get_tree().reload_current_scene())
	add_child(board)
	_run_board = board
	_screen_root = board
	if _wash:
		move_child(_wash, -1)
	_starting = false
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
	_menu_words(false)  # the title page's words would show through the dim beside Back's
	var holder := _margin(60, 0)
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	var safe := _safe_insets()
	holder.add_theme_constant_override("margin_top", int(safe.x) + 150)
	holder.add_theme_constant_override("margin_bottom", int(safe.y) + 150)
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
	_setting_row(v, "Music", _slider(Tuning.music_vol, func(x: float):
		Tuning.music_vol = x
		_apply_music()))
	_setting_row(v, "Sound", _slider(Tuning.sfx_vol, func(x: float):
		Tuning.sfx_vol = x
		Tuning.muted = x <= 0.01))
	_setting_row(v, "Haptics", _segmented(["On", "Off"], 0 if Tuning.haptics else 1, func(i: int):
		Tuning.haptics = i == 0
		_save_settings()
		if Tuning.haptics:
			_dir.haptic(0.4)))
	_setting_row(v, "Speed", _segmented(SPEEDS.map(func(s): return "%dx" % int(s)), maxi(0, SPEEDS.find(Tuning.speed)), func(i: int):
		_set_speed(SPEEDS[i])))
	_setting_row(v, "Reduce Motion", _segmented(["On", "Off"], 0 if Tuning.reduce_motion else 1, func(i: int):
		Tuning.reduce_motion = i == 0
		_save_settings()))
	if true:  # the tutorial teaches the table game
		var tut := _segmented([RulesText.tutorial("settings_play")], -1, func(_i: int):
			_replay_tutorial())
		_setting_row(v, "Tutorial", tut)
	# Debug: the run log to the clipboard (and Documents where allowed); the button says how many.
	var exp := _segmented([RulesText.run("export_log")], -1, func(_i: int): pass)
	for b in exp.get_children():
		b.set_meta("kind", "export_log")
		b.pressed.connect(func():
			var n := RunBoard.export_log()
			b.text = RulesText.run("exported_short", {"n": n}))
	if Tuning.RUN_MODE:
		_setting_row(v, "Run log", exp)
	else:
		exp.queue_free()
	var back := _menu_seal("Back", 220, func(): _close_settings(ov), "back")
	var bc := CenterContainer.new()
	bc.add_child(_caption_room(back))
	v.add_child(bc)
	add_child(ov)
	_settings = ov
	(func():
		_set_lettering(title, "Settings", Style.C_CRIMSON)
		_page_turn(ov, true)).call_deferred()


func _close_settings(ov: Control) -> void:
	_save_settings()
	await _page_turn(ov, false)
	ov.queue_free()
	_settings = null
	_menu_words(true)


## One Settings line: the name on the left in ink, its control on the right.
func _setting_row(v: VBoxContainer, label: String, ctrl: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	var l := Style.label(label, 46, Style.C_INK.darkened(0.3), true, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	ctrl.custom_minimum_size.x = 440
	ctrl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(ctrl)
	v.add_child(row)


## A volume slider: an inked groove, a crimson fill, a wax-red knob. Saves when let go.
func _slider(value: float, on_change: Callable) -> HSlider:
	var s := HSlider.new()
	s.set_meta("kind", "setting")
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = value
	s.custom_minimum_size.y = TARGET_MIN
	var groove := StyleBoxFlat.new()
	groove.bg_color = Color(0.2, 0.12, 0.08, 0.55)
	groove.set_corner_radius_all(8)
	groove.content_margin_top = 7
	groove.content_margin_bottom = 7
	var fill := groove.duplicate()
	fill.bg_color = Style.C_CRIMSON
	s.add_theme_stylebox_override("slider", groove)
	s.add_theme_stylebox_override("grabber_area", fill)
	s.add_theme_stylebox_override("grabber_area_highlight", fill)
	var kg := Gradient.new()  # a wax drop: bright centre, darker rim, hard edge
	kg.offsets = PackedFloat32Array([0.0, 0.85, 0.93, 1.0])
	kg.colors = PackedColorArray([Color(0.72, 0.12, 0.08), Color(0.45, 0.05, 0.03), Color(0.3, 0.03, 0.02), Color(0.3, 0.03, 0.02, 0.0)])
	var knob := GradientTexture2D.new()
	knob.gradient = kg
	knob.fill = GradientTexture2D.FILL_RADIAL
	knob.fill_from = Vector2(0.45, 0.4)
	knob.fill_to = Vector2(0.45, 0.0)
	knob.width = 72
	knob.height = 72
	s.add_theme_icon_override("grabber", knob)
	s.add_theme_icon_override("grabber_highlight", knob)
	s.value_changed.connect(func(x: float): on_change.call(x))
	s.drag_ended.connect(func(_c: bool):
		_save_settings()
		_dir.sfx.play("seal", 0.4, 1.0, true))
	return s


## Choices side by side in one inked frame; the chosen one is filled crimson. on_dark: for the
## candlelit desk (Sin select), not the parchment: a dark fill, gold frame and bone words.
func _segmented(options: Array, selected: int, on_pick: Callable, on_dark := false) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	var group := ButtonGroup.new()
	for i in options.size():
		var b := Button.new()
		b.set_meta("kind", "setting")
		b.toggle_mode = true
		b.button_group = group
		b.text = options[i]
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = TARGET_MIN * 1.1
		b.add_theme_font_size_override("font_size", 40)
		var off := StyleBoxFlat.new()
		off.bg_color = Color(0.03, 0.015, 0.01, 0.6) if on_dark else Color(0.25, 0.14, 0.08, 0.12)
		off.border_color = Style.C_GOLD.darkened(0.35) if on_dark else Color(0.25, 0.12, 0.06, 0.8)
		off.set_border_width_all(3)
		var first := i == 0
		var last := i == options.size() - 1
		off.corner_radius_top_left = 14 if first else 0
		off.corner_radius_bottom_left = 14 if first else 0
		off.corner_radius_top_right = 14 if last else 0
		off.corner_radius_bottom_right = 14 if last else 0
		if not first:
			off.border_width_left = 0
		var on := off.duplicate()
		on.bg_color = Style.C_CRIMSON
		on.border_color = Color(0.3, 0.04, 0.03)
		for st in ["normal", "hover", "focus"]:
			b.add_theme_stylebox_override(st, off)
		for st in ["pressed", "hover_pressed"]:
			b.add_theme_stylebox_override(st, on)
		var ink: Color = Style.C_BONE if on_dark else Style.C_INK.darkened(0.2)
		b.add_theme_color_override("font_color", ink)
		b.add_theme_color_override("font_hover_color", ink)
		b.add_theme_color_override("font_pressed_color", Style.C_IVORY)
		b.add_theme_color_override("font_hover_pressed_color", Style.C_IVORY)
		b.button_pressed = i == selected
		b.pressed.connect(func():
			_dir.sfx.play("plaque", 0.5, 1.0, true)
			on_pick.call(i))
		row.add_child(b)
	return row


func _speed_text() -> String:
	return ("%dx" % int(Tuning.speed)) if is_equal_approx(Tuning.speed, roundf(Tuning.speed)) else ("%.2gx" % Tuning.speed)


# ---------- Setup ----------

## Sin select (Phase 4): the title, a line on the table, the carousel (ui/sin_carousel.gd: one
## Sin per page, opening on the recommended Sin), the table size and the Choose seal.
func _build_setup() -> void:
	_content = _page()
	var m := _content.get_parent() as MarginContainer
	m.add_theme_constant_override("margin_left", int(SIDE_MIN))
	m.add_theme_constant_override("margin_right", int(SIDE_MIN))
	_content.add_theme_constant_override("separation", int(GAP_MIN))
	var title := _make_lettering(100, Style.C_GOLD, true)
	title.add_theme_constant_override("outline_size", 12)
	title.add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.01))
	_content.add_child(title)
	var blurb := Style.body("", 34, Style.C_BONE, 8)
	_content.add_child(blurb)
	var first := is_first_game()
	var names: Array = SIN_SCRIPTS.map(func(s): return s.new().sin_name)
	var car = SinCarousel.new(names, not first, _dir.sfx)
	car.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_child(car)
	var show := func():
		if first:
			Style.set_body(blurb, RulesText.word("setup_blurb_first"))
		else:
			Style.set_body(blurb, RulesText.word("setup_blurb", {"others": RulesText.word("setup_three" if Tuning.table_size == 4 else "setup_six")}))
	# Table size: one segmented control (First Game: always a table of 4, so it's hidden).
	if not first:
		var opts: Array = Tuning.TABLE_SIZES.map(func(n): return RulesText.word("setup_table", {"n": n}))
		var pick := func(i: int):
			Tuning.table_size = Tuning.TABLE_SIZES[i]
			_save_settings()
			show.call()
		var seg := _segmented(opts, maxi(0, Tuning.TABLE_SIZES.find(Tuning.table_size)), pick, true)
		for b in seg.get_children():
			b.set_meta("kind", "table")
		seg.custom_minimum_size.x = 700
		var sc := CenterContainer.new()
		sc.add_child(seg)
		_content.add_child(sc)
	show.call()
	var choose := _menu_seal(RulesText.word("setup_choose"), Tuning.SELECT_CHOOSE, func(): _start(SIN_SCRIPTS[car.index]), "choose")
	choose.set_meta("kind", "choose")
	var cc := CenterContainer.new()
	cc.add_child(_caption_room(choose))
	_content.add_child(cc)
	(func():
		_set_lettering(title, RulesText.word("setup_title"), Style.C_CRIMSON)
		_dir.seals_enter([choose])).call_deferred()


## Starts a game as `my_sin`, or rebuilds a saved one (Continue): same seed, same seats, and your
## saved answers given back under the ink until the game reaches your next decision.
func _start(my_sin: Script, saved := {}) -> void:
	if _starting:
		return  # a second tap while the ink covers the setup
	_starting = true
	if _content:
		await _ink_wash(true)
		_free_screen()
		_content = null
	human = Human.new()
	human.view = self
	var bot = BotPolicy.chooser(5, [99, 2, 0], 300)
	var order := []  # [sin index, is human] per seat
	if saved.is_empty():
		# You plus (table size - 1) other Sins, drawn at random.
		_first_game = is_first_game()
		var others := SIN_SCRIPTS.filter(func(s): return s != my_sin)
		others.shuffle()
		order.append([SIN_SCRIPTS.find(my_sin), true])
		var size: int = 4 if _first_game else Tuning.table_size
		for s in others.slice(0, clampi(size, 2, SIN_SCRIPTS.size()) - 1):
			order.append([SIN_SCRIPTS.find(s), false])
		order.shuffle()
	else:
		_first_game = bool(saved.get("first", false))
		for e in saved.seats:
			order.append([int(e[0]), bool(e[1])])
	var bots := []
	var sins := []
	for e in order:
		bots.append(human if e[1] else bot)
		sins.append(SIN_SCRIPTS[e[0]].new())
	var options := Rules.V4.duplicate()
	options["tier2"] = not _first_game
	options["temptations"] = not _first_game  # no temptations in a First Game (TableDesign §7)
	_line_turn = -1
	_lines_used = {}
	Tuning.bot_pace_scale = Tuning.FIRST_GAME_BOT_PACE if _first_game else 1.0
	var seed_value: int = randi() if saved.is_empty() else int(saved.seed)
	game = Game.new(bots, seed_value, options, sins)
	game.view = self
	_save = {"v": SAVE_VERSION, "seed": seed_value, "seats": order, "choices": human.record, "first": _first_game}
	human.on_answer = _save_game
	_build_board()
	if _wash:
		move_child(_wash, -1)  # the board was added above the ink
	if saved.is_empty():
		_ink_wash(false)
		if tutorial_enabled:  # tests turn this off, so they never wait on the card
			_opening_card()
	else:
		human.replay = saved.choices.duplicate()
		_replaying = true
		_q.skip_all = true  # every beat jumps to its end; show_prompt lifts the ink
	var w = await game.play()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))  # a finished game can't be continued
	if save_enabled:  # tests don't unlock anything
		games_finished += 1  # the first one unlocks Greater abilities and the Table of 7
		_save_settings()
	log_line("")
	log_line("[b]%s WIN%s with %d![/b]" % [player_name(w).to_upper(), "" if w.bot == human else "S", w.score])
	_end_line(w)
	_q.push(func(): _set_banner("%s %s" % [player_name(w), "win!" if w.bot == human else "wins"], w))
	show_prompt("The game is done. %s reached %d." % [player_name(w), w.score], [["New game", "new"]])
	_on_new_game_wait()


## Before the first turn: who you are, what your Sin does, the goal and where you sit.
## An explain card, so the queue holds (and the game waits) until you tap Begin.
func _opening_card() -> void:
	var me = human_player()
	var sname: String = me.sin.sin_name
	var s: Dictionary = RulesText.SINS[sname]
	var paras := ["[center][img=180x180]%s[/img][/center]" % Art.sigil_path(sname),
		RulesText.word("open_epithet", {"sin": sname, "epithet": s.epithet, "play": s.play}),
		"[b]%s[/b]" % RulesText.ability(sname, false)]
	if not _first_game:
		paras.append(RulesText.word("open_greater", {"ability": RulesText.ability(sname, true)}))
	paras.append(RulesText.word("open_goal"))
	var seat: int = game.players.find(me)
	if seat == 0:
		paras.append(RulesText.word("open_first"))
	else:
		paras.append(RulesText.word("open_seat" if me.score > 0 else "open_seat_plain", {"ordinal": RulesText.ordinal(seat + 1), "count": game.players.size(), "score": me.score}))
	var card = ExplainCard.new(RulesText.word("open_title", {"sin": sname}), paras, "", _safe_insets(), RulesText.word("open_begin"))
	card.closed.connect(_close_overlay)
	_show_overlay(card)


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


# ---------- Tutorial (the first Play, or Settings > Tutorial > Play) ----------

## A scripted practice game with set dice (ui/tutorial_game.gd): you as Envy against a Sloth bot,
## Basic abilities only, never saved. Its overlay stays up throughout; Skip leaves at any time.
func start_tutorial(from_settings: bool) -> void:
	_free_screen()
	_content = null
	human = Human.new()
	human.view = self
	_first_game = true
	Tuning.bot_pace_scale = Tuning.FIRST_GAME_BOT_PACE
	var options := Rules.V3.duplicate()
	options["tier2"] = false
	var sins := [_sin_script(TutorialGame.YOU).new(), _sin_script(TutorialGame.BOT).new()]
	game = Game.new([human, TutorialBot.new(TutorialGame.BOT_TURNS)], 1, options, sins)
	game.view = self
	_save = {}  # never saved: Continue keeps whatever game you had
	_tutor = TutorialGame.new(self, from_settings)
	_tutor.finished.connect(_end_tutorial)
	_build_board()
	if _pause:
		_pause.visible = false  # the script explains; the pause menu waits for a real game
	add_child(_tutor.overlay)
	_ink_wash(false)
	await game.play()


func _sin_script(sname: String) -> Script:
	for s in SIN_SCRIPTS:
		if s.new().sin_name == sname:
			return s
	return SIN_SCRIPTS[0]


## Play / Skip on the first run: the Sin choice. Menu, or Skip from Settings: the title page.
func _end_tutorial(to_setup: bool) -> void:
	if _starting:
		return
	_starting = true
	tutorial_pending = false
	if save_enabled:
		_save_settings()
	if not is_inside_tree() or get_tree().current_scene != self:
		return  # tests/tutorial_check.gd: nothing to reload into
	await _ink_wash(true)
	_wash_on_load = true
	_setup_on_load = to_setup
	get_tree().reload_current_scene()


## Settings > Tutorial > Play, from the menu or mid-game (a game in progress is already saved).
func _replay_tutorial() -> void:
	if _starting:
		return
	_starting = true
	_save_settings()
	await _ink_wash(true)
	_tutorial_on_load = true
	_tutorial_from_settings = true
	get_tree().reload_current_scene()


func human_player():
	for p in game.players:
		if p.bot == human:
			return p
	return null


## Chronicle -> Main menu: the ink covers the board and the title page loads under it.
func _to_menu() -> void:
	if _starting:
		return
	_starting = true
	await _ink_wash(true)
	_wash_on_load = true
	_setup_on_load = false
	get_tree().reload_current_scene()


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
	var glance := _zone(Tuning.ZONE_GLANCE)
	var stage := _zone(Tuning.ZONE_TRAY)
	var thumb := _zone(Tuning.ZONE_THUMB)
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
	_focus_groups["thumb"] = _thumb
	_focus_groups["desk"] = _desk
	if Tuning.SHOW_DEBUG_SLIDER:
		_build_speed_slider()
	_build_log_overlay()
	_register_explain_targets()


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


## One column per seat: the window cropped to its arch and figure (Phase 5), the name, then a
## brass-framed plate with score and dice. Status badges sit on the window's corner, the leader
## wears a crown over theirs, and your whole column has a gold frame. Look-only.
func _build_glance(zone: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 6)
	zone.add_child(row)
	for p in game.players:
		var sname: String = p.sin.sin_name
		var mine: bool = p.bot == human
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 4)
		if mine:  # you: a gold frame round the whole column, drawn behind it
			col.draw.connect(_draw_you_frame.bind(col, sname))
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
		win.texture = Art.window_crop(sname, Tuning.WINDOW_CROP, Tuning.WINDOW_CROP_TOP.get(sname, 0.0))
		win.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		win.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		win.set_anchors_preset(Control.PRESET_FULL_RECT)
		win.material = Art.flare_material()
		win.material.set_shader_parameter("phase", float(p.seat) * 0.37)  # shimmer out of step
		win.mouse_filter = Control.MOUSE_FILTER_IGNORE
		win_box.add_child(win)
		# The leader's crown, over the top of the arch (_refresh_marks).
		var crown := Control.new()
		crown.mouse_filter = Control.MOUSE_FILTER_IGNORE
		crown.set_anchors_preset(Control.PRESET_CENTER_TOP)
		crown.offset_left = -Tuning.CROWN_SIZE.x / 2
		crown.offset_right = Tuning.CROWN_SIZE.x / 2
		crown.offset_top = -Tuning.CROWN_SIZE.y * 0.45
		crown.offset_bottom = Tuning.CROWN_SIZE.y * 0.55
		crown.draw.connect(_draw_crown.bind(crown))
		crown.visible = false
		win_box.add_child(crown)
		# Status badges, down the window's right edge (_refresh_marks).
		var badges := VBoxContainer.new()
		badges.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badges.add_theme_constant_override("separation", 4)
		badges.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		badges.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		badges.offset_top = Tuning.CROWN_SIZE.y * 0.6
		win_box.add_child(badges)

		var plate := Control.new()
		plate.custom_minimum_size.y = 172  # caption, score, dice row
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plate.add_child(Art.framed(Art.TRAY, [48, 40, 48, 40], 0.42))
		var pv := VBoxContainer.new()
		pv.set_anchors_preset(Control.PRESET_FULL_RECT)
		pv.offset_top = 6
		pv.offset_bottom = -12
		pv.alignment = BoxContainer.ALIGNMENT_CENTER
		pv.add_theme_constant_override("separation", -6)  # caption lines sit close to their numbers
		pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plate.add_child(pv)
		var name_box := Control.new()
		name_box.custom_minimum_size.y = 46
		name_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if mine:
			var tab := Art.framed(Art.YOU_TAB, [24, 20, 24, 20], 0.55)
			tab.offset_left = 10
			tab.offset_right = -10
			tab.material = Art.tint_material(Style.SIN_COLORS[sname].darkened(0.2))  # your Sin's colour, as the banner
			name_box.add_child(tab)
		var name_l := Style.label("You" if mine else sname, MIN_TEXT, Style.C_GOLD if mine else Style.C_BONE, false, 6)
		name_l.add_theme_font_override("font", Style.SERIF)
		name_l.resized.connect(_fit_label.bind(name_l, MIN_TEXT, 26))
		name_l.set_anchors_preset(Control.PRESET_FULL_RECT)
		name_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_box.add_child(name_l)
		col.add_child(name_box)  # above the frame: names get the full column width
		var score_l := Style.number("0", 54)
		pv.add_child(_plate_caption(RulesText.word("score")))
		pv.add_child(score_l)
		var dice_row := HBoxContainer.new()
		dice_row.alignment = BoxContainer.ALIGNMENT_CENTER
		dice_row.add_theme_constant_override("separation", 10)
		dice_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dice_row.add_child(_plate_caption(RulesText.word("dice")))
		var dice_l := Style.label("", MIN_TEXT + 6, Style.C_BONE, false, 6)
		dice_l.add_theme_font_override("font", Style.NUMERAL)
		dice_row.add_child(dice_l)
		pv.add_child(dice_row)
		for l in [name_l, score_l, dice_l]:
			l.autowrap_mode = TextServer.AUTOWRAP_OFF
		name_l.clip_text = true
		col.add_child(plate)
		# Marks (Sin-coloured pips), claims and debts (TableDesign §7), over the window's foot.
		var marks_l := Style.body("", Tuning.MARKS_FONT, Style.C_IVORY, 6)
		marks_l.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		marks_l.grow_vertical = Control.GROW_DIRECTION_BEGIN
		marks_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marks_l.fit_content = true
		win_box.add_child(marks_l)
		# What they still owe: chips over the plate's lower edge, until paid.
		var chips := HFlowContainer.new()
		chips.alignment = FlowContainer.ALIGNMENT_CENTER
		chips.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		chips.offset_top = -Tuning.CHIP_OVERLAP
		chips.offset_bottom = -Tuning.CHIP_OVERLAP
		chips.grow_vertical = Control.GROW_DIRECTION_END
		chips.add_theme_constant_override("h_separation", 4)
		chips.add_theme_constant_override("v_separation", 4)
		chips.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chips.z_index = 2
		plate.add_child(chips)
		_portraits.append({"window": win, "glow": glow, "name": name_l, "score": score_l, "dice": dice_l, "sin": sname,
			"mine": mine, "col": col, "crown": crown, "badges": badges, "marks": marks_l, "chips": chips})


## Your column: a gold frame round window, name and plate, over a wash of your Sin's colour.
func _draw_you_frame(col: Control, sname: String) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(Style.SIN_COLORS[sname].darkened(0.6), 0.35)
	sb.border_color = Style.C_GOLD
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(16)
	col.draw_style_box(sb, Rect2(Vector2(-3, -6), col.size + Vector2(6, 8)))


## The leader's crown: a gold three-point crown with a dark edge, drawn to fit its control.
func _draw_crown(c: Control) -> void:
	var w := c.size.x
	var h := c.size.y
	var pts := PackedVector2Array([Vector2(0.08, 0.92), Vector2(0.02, 0.22), Vector2(0.3, 0.55), Vector2(0.5, 0.05),
		Vector2(0.7, 0.55), Vector2(0.98, 0.22), Vector2(0.92, 0.92)])
	for i in pts.size():
		pts[i] *= Vector2(w, h)
	c.draw_colored_polygon(pts, Style.C_GOLD)
	var edge := pts.duplicate()
	edge.append(pts[0])
	c.draw_polyline(edge, Color(0.2, 0.1, 0.02), 3.0, true)
	for x in [0.02, 0.5, 0.98]:  # a jewel on each point
		c.draw_circle(Vector2(x * w, (0.05 if x == 0.5 else 0.22) * h), h * 0.09, Style.C_CRIMSON)


## A status badge: a disc in the status colour with a small drawn sign. kind: purg / greater /
## drag / pact (colours: Tuning.BADGES).
func _badge(kind: String) -> Control:
	var b := Control.new()
	b.set_meta("kind", kind)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.custom_minimum_size = Vector2.ONE * Tuning.BADGE_SIZE
	b.draw.connect(_draw_badge.bind(b, kind))
	return b


func _draw_badge(b: Control, kind: String) -> void:
	var r := b.size.x / 2.0
	var c := b.size / 2.0
	b.draw_circle(c, r, Color(0.08, 0.04, 0.02))
	b.draw_circle(c, r - 3.0, Tuning.BADGES[kind])
	var ink := Style.C_IVORY
	match kind:
		"purg":  # a flame
			b.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r * 0.6), c + Vector2(r * 0.38, r * 0.05),
				c + Vector2(r * 0.25, r * 0.5), c + Vector2(-r * 0.25, r * 0.5), c + Vector2(-r * 0.38, r * 0.05)]), ink)
		"greater":  # a four-point star
			var s := PackedVector2Array()
			for i in 8:
				var a := i * PI / 4.0 - PI / 2.0
				s.append(c + Vector2(cos(a), sin(a)) * r * (0.62 if i % 2 == 0 else 0.22))
			b.draw_colored_polygon(s, Color(0.25, 0.12, 0.02))
		"drag":  # a down chevron
			b.draw_polyline(PackedVector2Array([c + Vector2(-r * 0.4, -r * 0.15), c + Vector2(0, r * 0.3), c + Vector2(r * 0.4, -r * 0.15)]), ink, 5.0, true)
		"pact":  # two linked rings
			b.draw_arc(c + Vector2(-r * 0.18, 0), r * 0.3, 0, TAU, 20, ink, 3.5, true)
			b.draw_arc(c + Vector2(r * 0.18, 0), r * 0.3, 0, TAU, 20, ink, 3.5, true)


## A small word on a player plate ("Score", "Dice") so the numbers say what they count.
func _plate_caption(text: String) -> Label:
	var l := Style.label(text, Tuning.PLATE_CAPTION, Style.C_BONE_DARK, false, 5)
	l.add_theme_font_override("font", Style.SERIF)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## The tray (about 40% of the screen, Phase 5): leather in a brass rule holding whose turn it is,
## the pause seal, the dice, the throw total and result line, then This turn and the Strikes.
func _build_stage(zone: VBoxContainer) -> void:
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
	tv.offset_top = 22
	tv.offset_bottom = -22
	tv.add_theme_constant_override("separation", 0)
	tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tray.add_child(tv)
	# Whose turn, as manuscript lettering at the top of the tray, the pause seal at its right.
	var banner := Control.new()
	banner.custom_minimum_size.y = maxf(100.0, TARGET_MIN * 1.15)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_text = _make_lettering(58, Style.C_BONE, false)
	_banner_text.autowrap_mode = TextServer.AUTOWRAP_OFF
	_banner_text.add_theme_constant_override("outline_size", 10)
	_banner_text.add_theme_color_override("font_outline_color", Style.C_BLACK)
	_banner_text.set_anchors_preset(Control.PRESET_HCENTER_WIDE)
	_banner_text.anchor_top = 0.5
	_banner_text.anchor_bottom = 0.5
	_banner_text.grow_vertical = Control.GROW_DIRECTION_BOTH
	banner.add_child(_banner_text)
	_pause = Button.new()
	_pause.set_meta("kind", "pause")
	_pause.custom_minimum_size = Vector2(TARGET_MIN, TARGET_MIN) * 1.05
	Art.emblem_skin(_pause, "pause")  # the sign is pressed in the wax; no word (the banner has no room)
	_pause.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_pause.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_pause.grow_vertical = Control.GROW_DIRECTION_BOTH
	_pause.offset_top = 14  # a little low in the banner: clear of the dice tags that hang from the plates
	_pause.offset_bottom = 14
	_pause.button_down.connect(func(): _dir.sfx.play("seal", 0.4, 1.1, true))
	_pause.pressed.connect(_open_pause)  # not _seal_feel: the prompt's pulses stay
	banner.add_child(_pause)
	tv.add_child(banner)
	_banner = banner
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
	# The score strip: a fixed-height band between the dice and the turn row, reserved for one
	# thing at a time: the throw total over its result line, or an ability's note. Flying numbers
	# land here, so nothing lands on the dice or the labels, and nothing reflows.
	_score_zone = Control.new()
	_score_zone.custom_minimum_size.y = SCORE_SIZE * 1.15 + Tuning.RESULT_SIZE + 12
	_score_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tv.add_child(_score_zone)
	_throw_label = Style.number("", SCORE_SIZE, 14)
	_throw_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_throw_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_throw_label.offset_bottom = SCORE_SIZE * 1.15
	_throw_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_throw_label.clip_text = true  # never wider than the strip (an unwrapped Label grows to its text and widens the tray)
	_score_zone.add_child(_throw_label)
	_result_label = Style.label("", Tuning.RESULT_SIZE, Style.C_BONE, false, 6)
	_result_label.add_theme_font_override("font", Style.SERIF)
	_result_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_result_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_result_label.offset_top = -(Tuning.RESULT_SIZE + 12)
	_result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_result_label.clip_text = true
	_result_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_score_zone.add_child(_result_label)
	_turn_label = Style.body("", 44, Style.C_BONE, 8)
	var srow := HBoxContainer.new()
	srow.alignment = BoxContainer.ALIGNMENT_CENTER
	srow.add_theme_constant_override("separation", 14)
	srow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sl := Style.label(RulesText.word("strikes"), 42, Style.C_BONE, false, 8)
	sl.autowrap_mode = TextServer.AUTOWRAP_OFF
	_turn_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_turn_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	srow.add_child(_turn_label)  # one row with the Strikes, so the dice get the height
	srow.add_child(sl)
	# Strikes are three candles: each Strike this turn snuffs one (director._strikes).
	for i in Rules.STRIKES_TO_BUST:
		var t := TextureRect.new()
		t.texture = Art.candle()
		t.material = Art.candle_material(false)
		t.custom_minimum_size = Tuning.CANDLE_SIZE
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		srow.add_child(t)
		_strike_icons.append(t)
	tv.add_child(srow)
	_turn_row = srow
	zone.add_child(tray)


## Darkened parchment page: the prompt line, then the seals (Roll under the right thumb). During
## bot turns: the summary of each bot turn since yours (tap: the Chronicle) and Skip to my turn.
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
	var side := maxi(0, roundi(Art.PAGE_MARGINS[0] * 0.55) - 64 + 28)
	var lm := MarginContainer.new()
	lm.add_theme_constant_override("margin_left", side)
	lm.add_theme_constant_override("margin_right", side)
	lm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lm.add_child(_prompt_label)
	pv.add_child(lm)
	_buttons = Control.new()
	_buttons.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_buttons.resized.connect(_layout_buttons)
	pv.add_child(_buttons)
	# The bot-turn summary: one line per bot turn, inked on the page between the corner boxes.
	_summary = Button.new()
	_summary.set_meta("kind", "summary")
	_summary.flat = true
	_summary.clip_contents = true
	for st in ["normal", "hover", "pressed", "focus"]:
		_summary.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	_summary.set_anchors_preset(Control.PRESET_FULL_RECT)
	_summary.offset_left = 64 + side
	_summary.offset_right = -64 - side
	_summary.offset_top = Tuning.PROMPT_FONT * 2.5  # under the prompt and its flourish
	_summary.offset_bottom = -(TARGET_MIN * 1.2 + 40 + GAP_MIN)
	_summary_rows = VBoxContainer.new()
	_summary_rows.set_anchors_preset(Control.PRESET_FULL_RECT)
	_summary_rows.alignment = BoxContainer.ALIGNMENT_END
	_summary_rows.add_theme_constant_override("separation", 2)
	_summary_rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_summary.add_child(_summary_rows)
	_summary.button_down.connect(func(): _dir.sfx.play("plaque", 0.3, 1.0, true))
	_summary.pressed.connect(func(): _page_turn(_log_overlay, true))
	_summary.visible = false
	page.add_child(_summary)
	# During bot turns: skip everything up to your next decision (same as a double tap).
	_skip = Button.new()
	_skip.set_meta("kind", "skip")
	Art.skin(_skip, [Art.YOU_TAB, Art.YOU_TAB, Art.YOU_TAB], Color.WHITE, 24)
	_skip.text = "Skip to my turn"
	_skip.add_theme_font_size_override("font_size", 44)
	_skip.custom_minimum_size = Vector2(520, TARGET_MIN * 1.2)
	_skip.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_skip.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_skip.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_skip.offset_bottom = -40
	_skip.visible = false
	_seal_feel(_skip, "pill", func():
		_show_skip(false)
		_q.skip_to_decision())
	page.add_child(_skip)
	zone.add_child(page)


func _show_skip(on: bool) -> void:
	if _skip:
		_skip.visible = on and not _replaying and _tutor == null


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
	# Back to the title page. The game is saved after every answer, so Continue picks it up.
	var to_menu := Button.new()
	to_menu.text = "Main menu"
	to_menu.custom_minimum_size = Vector2(340, SEAL_SMALL)
	Art.skin(to_menu, [Art.YOU_TAB, Art.YOU_TAB, Art.YOU_TAB], Color.WHITE, 24)
	to_menu.pressed.connect(_to_menu)
	var brow := HBoxContainer.new()
	brow.alignment = BoxContainer.ALIGNMENT_CENTER
	brow.add_theme_constant_override("separation", int(GAP_MIN * 1.5))
	close.size_flags_horizontal = Control.SIZE_FILL
	brow.add_child(to_menu)
	brow.add_child(close)
	v.add_child(brow)
	_log_overlay.add_child(f)
	_log_overlay.visible = false
	add_child(_log_overlay)


## The pause menu (Phase 5): a page over the board while the game waits. Rulebook (at the page
## for this moment), the abilities of the Sins at this table, the Chronicle, Settings (Speed is
## there), back to the title page. Settings opens over it; the others replace it.
func _open_pause() -> void:
	if _overlay != null or _settings != null:
		return
	var ov := Control.new()
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(Style.C_BLACK, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.add_child(dim)
	var holder := _margin(int(SIDE_MIN) + 40, 0)
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	var safe := _safe_insets()
	holder.add_theme_constant_override("margin_top", int(safe.x) + 120)
	holder.add_theme_constant_override("margin_bottom", int(safe.y) + 120)
	ov.add_child(holder)
	var page := Control.new()
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var paper := Art.framed(Art.PAGE, Art.PAGE_MARGINS, 0.55)
	paper.modulate = Color(0.86, 0.78, 0.68)
	_add_marginalia(paper)
	page.add_child(paper)
	holder.add_child(page)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 130
	v.offset_right = -130
	v.offset_top = 100
	v.offset_bottom = -100
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", int(GAP_MIN * 1.3))
	page.add_child(v)
	var title := _make_lettering(80, Style.C_INK.darkened(0.3), true)
	v.add_child(title)
	var names: Array = game.players.map(func(p): return p.sin.sin_name)
	var items := [
		["pause_resume", func(): _close_overlay()],
		["pause_rulebook", func(): open_rulebook(_context_page())],
		["pause_sins", func(): open_rulebook("all_sins", names)],
		["pause_chronicle", func():
			await _close_overlay()
			_page_turn(_log_overlay, true)],
		["pause_settings", _open_settings],
		["pause_menu", _to_menu],
	]
	for it in items:
		var b := Button.new()
		b.set_meta("kind", "pause_item")
		b.text = RulesText.word(it[0])
		b.custom_minimum_size = Vector2(Tuning.PAUSE_ITEM_W, TARGET_MIN * 1.15)
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		b.add_theme_font_size_override("font_size", 44)
		Art.skin(b, [Art.YOU_TAB, Art.YOU_TAB, Art.YOU_TAB], Color.WHITE, 24)
		b.button_down.connect(func(): _dir.sfx.play("plaque", 0.5, 1.0, true))
		b.pressed.connect(it[1])
		v.add_child(b)
	_show_overlay(ov)
	(func(): _set_lettering(title, RulesText.word("pause_title"), Style.C_CRIMSON)).call_deferred()


func _set_speed(v: float) -> void:
	Tuning.speed = clampf(v, Tuning.SPEED_MIN, Tuning.SPEED_MAX)
	_show_speed()
	_save_settings()


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS)
	cfg.set_value("ui", "speed", Tuning.speed)
	cfg.set_value("ui", "sound", not Tuning.muted)
	cfg.set_value("ui", "sfx", Tuning.sfx_vol)
	cfg.set_value("ui", "music", Tuning.music_vol)
	cfg.set_value("ui", "haptics", Tuning.haptics)
	cfg.set_value("ui", "tutorial_done", not tutorial_pending)
	cfg.set_value("ui", "reduce_motion", Tuning.reduce_motion)
	cfg.set_value("ui", "table", Tuning.table_size)
	cfg.set_value("ui", "games_finished", games_finished)
	cfg.set_value("ui", "run_rules_seen", run_rules_seen)
	cfg.set_value("ui", "tempt_tip_seen", tempt_tip_seen)
	cfg.save(SETTINGS)


func _show_speed() -> void:
	if _speed_label:
		_speed_label.text = _speed_text()


## During a bot's beats, tap anywhere that isn't a button: finish the current beat; double tap: skip
## to your next decision. When nothing is playing, a tap explains what's under it. A hold (LONG_PRESS)
## explains at any time, bot turns included (the ticker too).
func _input(event: InputEvent) -> void:
	if game == null or _tutor != null or _overlay != null or _settings != null or (_log_overlay and _log_overlay.visible):
		_press_at = Vector2.INF
		return
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if event.pressed:
		_long_fired = false
		var b := _hovered_button()
		_press_at = Vector2.INF if (b != null and b != _summary) else event.position
		_press_t = now
		return
	if _press_at == Vector2.INF:
		return
	var at := _press_at
	_press_at = Vector2.INF
	if _long_fired or event.position.distance_to(at) > PRESS_SLOP or _hovered_button() == _summary:
		return  # explained already, a drag, or the summary's own tap (the Chronicle)
	if _q.busy():
		if now - _last_tap < DOUBLE_TAP:
			_show_skip(false)
			_q.skip_to_decision()
		else:
			_q.skip_beat()
		_last_tap = now
	else:
		_explain_at(at)


func _hovered_button() -> Button:
	var c := get_viewport().gui_get_hovered_control()
	while c:
		if c is Button:
			return c
		c = c.get_parent() as Control
	return null


func _check_long_press() -> void:
	if _press_at == Vector2.INF or _long_fired:
		return
	if Time.get_ticks_msec() / 1000.0 - _press_t < LONG_PRESS:
		return
	if get_viewport().get_mouse_position().distance_to(_press_at) > PRESS_SLOP:
		_press_at = Vector2.INF
		return
	_long_fired = true
	if _explain_at(_press_at):
		_dir.haptic(0.3)


# ---------- Rulebook and tap-to-explain (text: ui/rules_text.gd) ----------

## Opens the rulebook at a page (id from RulesText.PAGES). The game waits while it's open.
func open_rulebook(id: String, only_sins: Array = []) -> void:
	var rb = Rulebook.new(id, _safe_insets(), _dir.sfx)
	rb.only_sins = only_sins  # the Sins page shows just these (the pause menu: this table's)
	rb.closed.connect(_close_overlay)
	_show_overlay(rb)


## A card explaining one thing, with a link to its rulebook page.
func explain(title: String, paras: Array, page_id: String) -> void:
	var card = ExplainCard.new(title, paras, page_id, _safe_insets())
	card.closed.connect(_close_overlay)
	card.open_page.connect(open_rulebook)
	_show_overlay(card)
	_dir.sfx.play("plaque", 0.35, 1.0, true)


func explain_term(name: String) -> void:
	explain(name, [RulesText.term(name)], RulesText.term_page(name))


func _show_overlay(o: Control) -> void:
	if _overlay and is_instance_valid(_overlay):
		_overlay.queue_free()
	_overlay = o
	add_child(o)
	_q.set_paused(true)
	(func(): if is_instance_valid(o): _page_turn(o, true)).call_deferred()


func _close_overlay() -> void:
	var o := _overlay
	_overlay = null
	if o and is_instance_valid(o):
		await _page_turn(o, false)
		o.queue_free()
	if _overlay == null:
		_q.set_paused(false)


## The rulebook page that fits the moment (the "?" button).
func _context_page() -> String:
	if game == null:
		return "contents"
	var me = human_player()
	var t = game.turn
	var mine: bool = me != null and game.current == me
	if me and (me.in_purgatory or (mine and t and t.throws == 0 and not t.redeem_faces.is_empty())):
		return "purgatory"
	var prompt := _prompt_label.get_parsed_text() if _prompt_label else ""
	if prompt.begins_with("Buy"):
		return "buying"
	if mine and t and t.strikes > 0:
		return "strikes"
	if mine and t and t.throws > 0:
		return "banking"
	if me and _t2_ready(me):
		return "sins"
	return "turn"


## Everything on the board that explains itself: [control, Callable]. The smallest hit wins.
func _register_explain_targets() -> void:
	_explain_targets.clear()
	for i in _portraits.size():
		var pt: Dictionary = _portraits[i]
		var seat := i
		_explain_targets.append([pt.window, func(): _explain_sin(seat)])
		_explain_targets.append([pt.name, func(): _explain_sin(seat)])
		_explain_targets.append([pt.score, func(): explain_term("Score")])
		_explain_targets.append([pt.dice.get_parent(), func(): explain_term("Dice")])
	_explain_targets.append([_banner, func():
		if game.current:
			_explain_sin(game.players.find(game.current))])
	_explain_targets.append([_turn_row, func(): explain_term("Strikes")])
	_explain_targets.append([_turn_label, func(): explain_term("This turn")])
	_explain_targets.append([_throw_label, func(): explain_term("Multiplier")])
	_explain_targets.append([_dice_area, func(): explain_term("Scoring")])
	for i in _portraits.size():  # a badge explains its status
		var pt: Dictionary = _portraits[i]
		_explain_targets.append([pt.badges, func():
			for b in pt.badges.get_children():
				explain_term(RulesText.BADGE_TERMS[b.get_meta("kind")])
				return])


func _explain_at(pos: Vector2) -> bool:
	var best = null
	var best_area := INF
	for e in _explain_targets:
		var c: Control = e[0]
		if not is_instance_valid(c) or not c.is_visible_in_tree():
			continue
		var r := c.get_global_rect()
		if r.has_point(pos) and r.get_area() < best_area:
			best = e
			best_area = r.get_area()
	if best == null:
		return false
	best[1].call()
	return true


## A Sin's card: playstyle, both abilities (with where the Greater one stands), any status, score.
func _explain_sin(seat: int) -> void:
	var p = game.players[seat]
	var s: String = p.sin.sin_name
	var info: Dictionary = RulesText.SINS[s]
	var paras := ["[i]%s[/i]" % info.play]
	paras.append("[b]%s[/b] (Basic): %s" % [RulesText.ability_name(s, false), RulesText.ability_text(s, false)])
	var state := ""
	if not game.tier2:
		state = "Not in a First Game."
	elif p.t2_unlocked:
		state = "Ready this round." if p.t2_ready else "Used; ready again at the start of their turn."
	else:
		state = "Unlocks at %d points." % Rules.TIER2_SCORE
	paras.append("[b]%s[/b] (Greater): %s %s" % [RulesText.ability_name(s, true), RulesText.ability_text(s, true), state])
	if p.in_purgatory:
		paras.append("[b]Purgatory[/b]: %s" % RulesText.term("Purgatory"))
	if p.drag > 0:
		paras.append("[b]Dragged[/b]: %s" % RulesText.term("Dragged"))
	if p.pact_by != null:
		paras.append("[b]Pact[/b]: %s" % RulesText.term("Pact"))
	paras.append("Score %d · Dice %d" % [p.score, p.dice])
	var who := " (you)" if p.bot == human else ""
	explain("%s, %s%s" % [s, info.epithet, who], paras, "all_sins")


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
			tag = "Greater ready"
		var badges := []  # in this order down the window (Tuning.BADGES)
		if p.in_purgatory:
			badges.append("purg")
		if _t2_ready(p):
			badges.append("greater")
		if p.drag > 0:
			badges.append("drag")
		if p.pact_by != null:
			badges.append("pact")
		ps.append({"score": p.score, "dice": p.dice, "purg": p.in_purgatory, "tag": tag, "badges": badges,
			"marks": p.marks.duplicate(), "claims": p.claims.duplicate(),
			"debts": [p.pend_bank, p.pend_strike, p.pend_fewer, p.pend_die]})
	var s := {"players": ps, "cur": game.players.find(game.current), "winner": game.winner != null}
	var t = game.turn
	if t:
		var faces: Array = (t.faces if t.throws > 0 else t.redeem_faces).duplicate()
		s.turn = {"faces": faces, "throws": t.throws, "points": t.points, "strikes": t.strikes, "added": 0, "tint": Color(0, 0, 0, 0)}
		# Dice an ability added to this throw (Envy's copies) sit past the ones thrown.
		if t.throws > 0 and game.current:
			s.turn.added = maxi(0, faces.size() - game._max_throw(game.current))
			if s.turn.added > 0 and game.current.sin:
				s.turn.tint = Style.SIN_COLORS.get(game.current.sin.sin_name, Style.C_GOLD)
	return s


const ALL_PARTS := ["plates", "glow", "banner", "dice", "throw", "turn", "strikes", "prompt"]


## Draws a snapshot. parts: only those pieces (the director animates the rest itself).
func _refresh(s: Dictionary, parts: Array = ALL_PARTS) -> void:
	var cur_i: int = s.cur
	if "plates" in parts:
		_refresh_crowns(s)
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
		_set_banner(RulesText.word("your_turn") if cur.bot == human else RulesText.word("their_turn", {"name": player_name(cur)}), cur)
	var faces: Array = t.faces
	if "dice" in parts:
		show_turn_dice(t)
	if "throw" in parts:
		var text := ""
		var size := SCORE_SIZE
		if t.throws > 0:
			var pts: int = Rules.score(Array(faces, TYPE_INT, "", null), game.chain, game.face_mult)
			text = "+%d" % pts if pts > 0 else ""  # nothing scored: the result line says so, never "+0"
		elif faces.size() > 0:
			text = RulesText.word("purgatory_need")
			size = 72
		set_throw(text, size)
		set_result(result_line(faces, Rules.count_strikes(Array(faces, TYPE_INT, "", null))) if t.throws > 0 else "")
	if "turn" in parts:
		set_turn_points(t.points)
	if "strikes" in parts:
		for i in _strike_icons.size():
			set_candle(i, i < t.strikes)
	if "prompt" in parts and _waiting and not s.winner:
		set_waiting_text(RulesText.word("at_dice_you") if cur.bot == human else RulesText.word("at_dice", {"name": player_name(cur)}))


func set_turn_points(v: int) -> void:
	if _turn_label.get_meta("pts", -1) != v:
		_turn_label.set_meta("pts", v)
		Style.set_body(_turn_label, RulesText.word("this_turn", {"n": v}))


## Strike candle i: out (a Strike taken) or lit. The director tweens `snuffed` itself when it animates.
func set_candle(i: int, out: bool) -> void:
	(_strike_icons[i].material as ShaderMaterial).set_shader_parameter("snuffed", 1.0 if out else 0.0)


## The line under the throw total: what scored and the points, and any Strikes.
## faces: this throw; new_strikes: Strikes this throw counted.
func result_line(faces: Array, new_strikes: int) -> String:
	var scorers := faces.filter(func(f): return f >= 4)
	scorers.sort()
	scorers.reverse()
	var text := ""
	if scorers.is_empty():
		text = RulesText.word("res_nothing")
	else:
		var sum := 0
		for f in scorers:
			sum += f * game.face_mult
		var total: int = game.throw_score(faces)  # rounded as the board shows it (V4: down to 5)
		var names: Array = scorers.map(func(f): return str(f))
		var list: String = names[0] if names.size() == 1 else ", ".join(names.slice(0, names.size() - 1)) + " and " + names[-1]
		if total != sum:
			text = RulesText.word("res_scores_mult", {"faces": list, "sum": sum, "total": total, "mult": RulesText._mult(1.0 + game.chain * (scorers.size() - 1))})
		else:
			text = RulesText.word("res_scores_one" if scorers.size() == 1 else "res_scores", {"faces": list, "sum": sum})
	if new_strikes == 1:
		text += RulesText.word("res_strike")
	elif new_strikes > 1:
		text += RulesText.word("res_strikes", {"count": RulesText._num_word(new_strikes).capitalize()})
	return text


## The score strip's big line, shrunk to fit the strip's width ("+105  x2.5", the Purgatory line).
func set_throw(text: String, size := SCORE_SIZE) -> void:
	_throw_label.text = text
	# Measured against the strip, not the label: an unwrapped Label grows to its text.
	var font: Font = _throw_label.get_theme_font("font")
	var room := _score_zone.size.x - 24.0
	var s := size
	while s > 40 and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, s).x > room:
		s -= 2
	_throw_label.add_theme_font_size_override("font_size", s)


func set_result(text: String) -> void:
	_result_label.text = text
	_fit_label(_result_label, Tuning.RESULT_SIZE, 26)


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


## Score, dice and status badges (Phase 5: the name stays; a status is a badge on the window).
func _refresh_plate(pt: Dictionary, ps: Dictionary) -> void:
	if pt.has("marks") and ps.has("marks"):
		_refresh_marks_line(pt, ps)
	pt.score.text = str(ps.score)
	pt.dice.text = str(ps.dice)
	pt.name.add_theme_color_override("font_color", Style.C_STRIKE.lightened(0.4) if ps.purg else (Style.C_GOLD if pt.mine else Style.C_BONE))
	var want: Array = ps.badges
	var have: Array = pt.badges.get_children().filter(func(b): return not b.is_queued_for_deletion()).map(func(b): return b.get_meta("kind"))
	if want == have:
		return
	for b in pt.badges.get_children():
		b.queue_free()
	for k in want:
		var b := _badge(k)
		pt.badges.add_child(b)
		if not have.has(k) and not Tuning.reduce_motion:  # a new badge springs on
			b.pivot_offset = Vector2.ONE * Tuning.BADGE_SIZE / 2
			b.scale = Vector2.ONE * 0.3
			b.create_tween().tween_property(b, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)


## The crown sits over every player on the top score (none while all are at 0).
func _refresh_crowns(s: Dictionary) -> void:
	var best := 0
	for ps in s.players:
		best = maxi(best, int(ps.score))
	for i in _portraits.size():
		var on: bool = best > 0 and int(s.players[i].score) == best
		var c: Control = _portraits[i].crown
		if on and not c.visible and not Tuning.reduce_motion:
			c.pivot_offset = c.size / 2
			c.scale = Vector2.ONE * 0.4
			c.create_tween().tween_property(c, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
		c.visible = on


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


## The dice of a snapshot's turn, ability-added ones tinted.
func show_turn_dice(t: Dictionary) -> void:
	_show_dice(t.faces, t.get("added", 0), t.get("tint", Color(0, 0, 0, 0)))


## The size every die is drawn at: Tuning.DIE_SIZE, unless the tray can't hold Tuning.TRAY_DICE at it.
## It never depends on how many dice are out, so buying one doesn't shrink the rest.
func die_side() -> float:
	var per := Tuning.DICE_PER_ROW
	var rows := ceili(float(Tuning.TRAY_DICE) / per)
	var gap := Tuning.DIE_GAP
	var area := _dice_area.size - Vector2.ONE * Tuning.TRAY_MARGIN * 2.0
	var side := minf(Tuning.DIE_SIZE, (area.x - gap * (per - 1)) / per)
	side = minf(side, (area.y - gap * (rows - 1)) / rows)
	return floorf(maxf(side, 60.0))


## Rows of Tuning.DICE_PER_ROW, centred in the tray. The last `added` faces were added by an ability.
func _show_dice(faces: Array, added := 0, tint := Color(0, 0, 0, 0)) -> void:
	var key := "%s/%d" % [str(faces), added]
	if _dice_row.get_meta("key", "") == key:
		return
	_dice_row.set_meta("key", key)
	for c in _dice_row.get_children():
		c.queue_free()
	_dice_nodes.clear()
	var n := faces.size()
	if n == 0:
		return
	var per_row := Tuning.DICE_PER_ROW
	var rows := ceili(float(n) / per_row)
	var gap := Tuning.DIE_GAP
	_dice_row.add_theme_constant_override("h_separation", int(gap))
	_dice_row.add_theme_constant_override("v_separation", int(gap))
	var area := _dice_area.size
	var side := die_side()
	_dice_row.offset_top = maxf(0.0, (area.y - rows * side - (rows - 1) * gap) / 2.0)
	# The row is only as wide as six dice, so a seventh wraps even on a wide screen.
	var row_w := per_row * side + (per_row - 1) * gap
	_dice_row.offset_left = maxf(0.0, (area.x - row_w) / 2.0)
	_dice_row.offset_right = -_dice_row.offset_left
	# Each die sits in a fixed holder so the director can throw, lift and spin it without the flow
	# container snapping it back.
	for i in n:
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(side, side)
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var d = Die.new(faces[i], int(side), i * 7 + faces[i])
		d.size = Vector2(side, side)
		d.pivot_offset = Vector2(side, side) / 2
		if i >= n - added:
			d.tint = tint
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
	var tm := text.find("'s temptation: ")
	if tm >= 0:
		text = text.substr(0, tm) + "'s %s: %s" % [RulesText.table("temptation"), RulesText.tempt(text.substr(tm + 15).strip_edges())]
	elif text.find("'s answer: ") >= 0:
		text = text.replace("'s answer: ", "'s %s: " % RulesText.table("answer"))
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
	tw.tween_method(set_flash, 1.0, 0.0, Tuning.FLARE_TIME - 0.07).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(win, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)


## An ability's note takes the score strip for its beat: the ability in its Sin's colour, then what
## it did. The throw total and result line fade out under it and come back when it goes
## (clear_note). One at a time; the Chronicle keeps them all. Returned so the director can clear it.
func _marginalia(pt: Dictionary, ability: String, what: String) -> Control:
	for n in _notes:
		if is_instance_valid(n):
			n.queue_free()
	_notes.clear()
	var col: Color = Style.SIN_COLORS[pt.sin].lightened(0.3)
	var note := Style.body("[color=#%s]%s[/color]   %s" % [col.to_html(false), ability, what], Tuning.NOTE_SIZE, Style.C_IVORY, 10)
	note.set_anchors_preset(Control.PRESET_HCENTER_WIDE)
	note.anchor_top = 0.5
	note.anchor_bottom = 0.5
	note.grow_vertical = Control.GROW_DIRECTION_BOTH
	note.modulate.a = 0.0
	_score_zone.add_child(note)
	_notes.append(note)
	var tw: Tween = _q.tween(note)
	tw.tween_property(note, "modulate:a", 1.0, 0.2)
	tw.parallel().tween_property(_throw_label, "modulate:a", 0.0, 0.15)
	tw.parallel().tween_property(_result_label, "modulate:a", 0.0, 0.15)
	note.pivot_offset = Vector2(note.size.x / 2, 0)
	note.scale = Vector2.ONE * 0.9
	tw.parallel().tween_property(note, "scale", Vector2.ONE, Tuning.ACTION).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	return note


## A new throw: any note still up goes at once and the strip shows the throw again.
func reset_strip() -> void:
	for n in _notes:
		if is_instance_valid(n):
			n.queue_free()
	_notes.clear()
	_throw_label.modulate.a = 1.0
	_result_label.modulate.a = 1.0


## The note leaves the strip and the throw total and result line come back.
func clear_note(note: Control, dur := 0.2) -> void:
	_notes.erase(note)
	if not is_instance_valid(note) and not _notes.is_empty():
		return
	var tw: Tween = _q.tween(self)
	if is_instance_valid(note):
		tw.tween_property(note, "modulate:a", 0.0, dur)
		tw.tween_callback(note.queue_free)
	if _notes.is_empty():
		tw.parallel().tween_property(_throw_label, "modulate:a", 1.0, dur)
		tw.parallel().tween_property(_result_label, "modulate:a", 1.0, dur)


## Puts each Sin's sigil before its name, so the log reads by shape as well as colour.
func _with_sigils(bb: String) -> String:
	for sname in Style.SIN_COLORS:
		bb = bb.replace(sname, "[img=40x40]%s[/img] %s" % [Art.sigil_path(sname), sname])
	return bb


## Turn change: its own beat (longer when it's yours). Docs/UXPass.md #1.
func turn_started(p) -> void:
	if _tutor:
		_tutor.on_turn_started(p)  # rigs a Purgatory throw before core draws it
	var snap := _snapshot()
	_last_snap = snap
	var head := RulesText.word("chronicle_your_turn", {"score": p.score}) if p.bot == human else RulesText.word("chronicle_turn", {"name": player_name(p), "score": p.score})
	var header := "[color=#e9c46a]%s[/color]" % head
	_q.push(func():
		_show_log("")
		_show_log(header)
		_show_skip(p.bot != human and not _q.skip_all)
		_summary_turn(p)
		await _dir.turn_change(p, snap))


# ---------- Bot-turn summary (Phase 5; words: RulesText.WORDS sum_*) ----------

## A turn starts: yours clears the summary; a bot's adds its line ("Wrath: ...").
func _summary_turn(p) -> void:
	if not Tuning.BOT_SUMMARY and _summary:
		_summary.visible = false
		return
	if _summary_rows == null or _tutor != null:  # the tutorial explains its own bot turns
		return
	_summary_parts = []
	if p.bot == human:
		for r in _summary_rows.get_children():
			r.queue_free()
		_summary.visible = false
		return
	var r := Style.body("", Tuning.SUMMARY_FONT, Style.C_INK.darkened(0.35))
	r.set_meta("sin", p.sin.sin_name)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_summary_rows.add_child(r)
	while _summary_rows.get_child_count() > Tuning.SUMMARY_ROWS:
		var old := _summary_rows.get_child(0)
		_summary_rows.remove_child(old)
		old.queue_free()
	_summary_write(r)
	_summary.visible = _waiting


## Called by the director after each beat of a bot's turn: what it did, in a few words.
func summary_event(kind: String, mt: RegExMatch, text: String, prev: Dictionary, snap: Dictionary) -> void:
	if not Tuning.BOT_SUMMARY:
		return
	if _summary_rows == null or _summary_rows.get_child_count() == 0:
		return
	var part := ""
	match kind:
		"bank":
			part = RulesText.word("sum_bank", {"n": int(mt.get_string(2)), "score": int(mt.get_string(3))})
		"bust":
			part = RulesText.word("sum_bust", {"n": int(prev.get("turn", {}).get("points", 0))})
		"buy":
			var n := int(mt.get_string(2))
			part = RulesText.word("sum_buy_one" if n == 1 else "sum_buy", {"n": n})
		"ability":
			part = RulesText.word("sum_ability", {"ability": mt.get_string(2)})
		"attack":
			var target := text.substr(mt.get_end()).strip_edges().get_slice(" ", 0).rstrip(".,:;")
			var ability: String = RulesText.ATTACK_NAMES.get(mt.get_string(1), mt.get_string(1))
			part = RulesText.word("sum_attack", {"ability": ability, "target": "you" if target == "You" else target})
		"redeemed":
			part = RulesText.word("sum_freed")
		"still_purgatory":
			part = RulesText.word("sum_stuck")
	if part == "":
		return
	_summary_parts.append(part)
	_summary_write(_summary_rows.get_child(_summary_rows.get_child_count() - 1))


func _summary_write(r: RichTextLabel) -> void:
	var sname: String = r.get_meta("sin")
	var who := "[color=#%s]%s[/color]" % [Tuning.SUMMARY_NAME.get(sname, Style.SIN_COLORS[sname].darkened(0.45)).to_html(false), sname]
	var said := ", ".join(_summary_parts) if not _summary_parts.is_empty() else RulesText.word("sum_playing")
	Style.set_body(r, "%s: %s" % [who, said])
	_summary_fit.call_deferred()


## Oldest lines go once the summary would overflow its space on the page (the newest stay).
func _summary_fit() -> void:
	if _summary == null or not is_instance_valid(_summary_rows) or _summary.size.x <= 0.0:
		return
	# Counted in wrapped lines from the text width (a fresh label's own height isn't laid out yet).
	var room := int(_summary.size.y / (Tuning.SUMMARY_FONT * 1.3))
	var used := 0
	var rows := _summary_rows.get_children()
	for i in range(rows.size() - 1, -1, -1):
		var r: RichTextLabel = rows[i]
		var w := Style.SERIF.get_string_size(r.get_parsed_text(), HORIZONTAL_ALIGNMENT_LEFT, -1, Tuning.SUMMARY_FONT).x
		used += maxi(1, ceili(w / _summary.size.x))
		if used > room and i < rows.size() - 1:
			for j in i + 1:
				_summary_rows.remove_child(rows[j])
				rows[j].queue_free()
			return


## core/game.gd awaits this after a throw, a bust and at the end of a turn: let the screen catch up
## (and show the state as it stands now, e.g. Purgatory after a bust) before the rules go on.
func beat(p, kind: String) -> void:
	var snap := _snapshot()
	_last_snap = snap
	_q.push(func(): _refresh(snap, ["plates", "glow", "banner", "turn", "strikes"]))
	await _q.drain()
	if _tutor:
		await _tutor.on_beat(p, kind)


## Queued like everything else, so the buttons only appear once the board has caught up.
## Then the director pulses what you can tap and dims the rest.
func show_prompt(text: String, options: Array, offer := {}) -> void:
	_q.push(func():
		_q.skip_all = false  # "skip to my next decision" ends here
		Tuning.pace = 1.0  # your decision plays at your speed
		_show_skip(false)
		if _replaying:  # Continue: caught up, lift the ink
			_replaying = false
			_ink_wash(false)
		if game and not _portraits.is_empty():
			_refresh(_snapshot(), ["plates", "glow", "banner", "turn", "strikes"])
		if _tutor:
			_tutor.overlay.block()  # dead until the script lights one
		if offer.is_empty():
			_show_prompt_now(text, options)
		else:
			_show_offer_now(text, options, offer)
		await get_tree().process_frame  # buttons placed
		_layout_buttons()
		if is_instance_valid(_offer_card) and _offer_card.has_meta("place"):
			_offer_card.get_meta("place").call()
		_dir.my_turn(_buttons.get_children().filter(func(b): return not b.is_queued_for_deletion()))
		if _tutor:
			await _tutor.on_prompt())


## Dice counts become one row of small seals that only select (the most dice starts selected),
## and a separate Throw seal below that commits the selection (crimson, right thumb).
## Bank is the bronze seal beside it on the left. Anything else is a red plaque.
func _show_prompt_now(text: String, options: Array) -> void:
	clear_prompt()
	_waiting = false
	if _summary:
		_summary.visible = false  # the prompt has the page
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
		_emblem(throw_b, "throw", RulesText.word("throw_cap"), true, SEAL_CONFIRM)
		_seal_numeral(throw_b, most, 1)
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
		elif str(o[1]) == "new":
			kind = "new"
		var b := Button.new()
		b.set_meta("kind", kind)
		match kind:
			"num":
				Art.skin(b, Art.SEAL_S, Color(0.82, 0.76, 0.76))
				# Selected: the wax brightens and a gold ring circles it (toggled on = "pressed" style).
				for st in ["pressed", "hover_pressed"]:
					b.add_theme_stylebox_override(st, _seal_style(Art.SEAL_S[0], Color(1.2, 1.1, 1.0)))
				_seal_face(b, int(o[0]))
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
						_seal_numeral(throw_b, n, 0))
				_seal_feel(b, "num", Callable())
				_buttons.add_child(b)
				continue
			"bank":
				_emblem(b, "bank", RulesText.word("bank_cap"), true, SEAL_CONFIRM)
				if o[0].get_slice(" ", 1).is_valid_int():
					_seal_numeral(b, int(o[0].get_slice(" ", 1)), -1)
			"new":
				_emblem(b, "newgame", o[0], true, SEAL_CONFIRM)
			_:
				Art.skin(b, [Art.YOU_TAB, Art.YOU_TAB, Art.YOU_TAB], Color.WHITE, 24)
				b.set_meta("w", Style.BLACKLETTER.get_string_size(o[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 42).x + 70)
				if RegEx.create_from_string("\\d").search(o[0]):
					_caption(b, o[0], 42)
				else:
					b.text = o[0]
					b.add_theme_font_size_override("font_size", 42)
		var val = o[1]
		b.set_meta("value", val)  # the tutorial finds its button by kind and value
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
	if is_instance_valid(_offer_card):
		_offer_card.queue_free()
	_offer_card = null
	if _paper:
		_paper.visible = true  # back after a temptation
	if _summary:  # the bot turns so far come back on the page
		_summary.visible = _summary_rows.get_child_count() > 0


## Places the prompt buttons inside _buttons by hand (it holds only Buttons, see tests/ui_autoplay.gd).
func _layout_buttons() -> void:
	if _buttons == null:
		return
	var bs: Array = _buttons.get_children().filter(func(b): return not b.is_queued_for_deletion())
	var w := _buttons.size.x
	var h := _buttons.size.y
	var big := bs.filter(func(b): return b.get_meta("kind") in ["roll", "bank", "new"])
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
		var bank_b: Button = null
		var throw_b: Button = null
		for b in big:
			if b.get_meta("kind") == "bank":
				bank_b = b
			elif b.get_meta("kind") == "roll":
				throw_b = b
		# Each confirm seal carries its word underneath and may carry a numeral beside it.
		var count_row := (SEAL_SMALL + gap * 1.5) if not nums.is_empty() else 0.0  # a row of counts above
		var d := minf(minf(float(SEAL_CONFIRM), h - count_row - _cap_h(SEAL_CONFIRM)), (w - gap * 2.0) / 2.0)
		var s := float(SEAL_SMALL)
		var per_row := 1
		var in_band := 0
		var top := 0.0
		var slot_l := 0.0
		var slot_w := 0.0
		var fits := false
		while not fits:
			d = maxf(d, TARGET_MIN * 1.1)  # 10% over the minimum: they still settle in from a smaller scale
			top = h - d - (_cap_h(d) if not big.is_empty() else 0.0)
			var room := top - gap * 1.5
			# With counts between them the numerals turn inward, so the band gives them room.
			var nb := _place_numeral(bank_b, d) if bank_b else 0.0
			var nt := _place_numeral(throw_b, d) if throw_b else 0.0
			slot_l = (d + gap + nb) if has_bank else 0.0
			slot_w = w - d - gap - nt - slot_l
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
			if not fits and d <= TARGET_MIN * 1.1:
				break
			d -= 8.0
		if not fits:
			# Last resort (10+ dice): one grid of equal 44 pt seals, Bank and Throw ending the last row.
			# No room around them: the words and numerals hide (the emblems, the lit count seal and the
			# prompt say it all).
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
					_size_caption(all[i], gs)
					for c in all[i].get_children():
						if c.has_meta("numeral") or c.has_meta("caption"):
							c.visible = false
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
			_size_caption(b, d)
			_fit_caption(b, d)  # a word still on the wax (none on emblem seals)
			var outward := 1 if b.get_meta("kind") == "roll" else -1
			_place_numeral(b, d, -outward if in_band > 0 else outward)
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


## A seal in a container, with room under it for its word (the word hangs below the button).
func _caption_room(b: Button) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(b)
	var pad := Control.new()
	pad.custom_minimum_size.y = _cap_h(b.custom_minimum_size.x)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(pad)
	return v


## An emblem seal's word, under the wax (never on it): ink on the parchment page, bone with a dark
## outline over the dark desk. Replaces any word already there. Sized for a seal d px wide.
func _seal_caption(b: Button, text: String, ink: bool, d: float) -> void:
	for c in b.get_children():
		if c.has_meta("caption"):
			c.free()
	var l := Label.new()
	l.set_meta("caption", true)
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", Style.BLACKLETTER)
	l.add_theme_color_override("font_color", Style.C_BLACK if ink else Style.C_BONE)
	if not ink:
		l.add_theme_constant_override("outline_size", 10)
		l.add_theme_color_override("font_outline_color", Style.C_BLACK)
	l.anchor_left = 0.5
	l.anchor_right = 0.5
	l.anchor_top = 1.0
	l.anchor_bottom = 1.0
	l.grow_horizontal = Control.GROW_DIRECTION_BOTH
	b.add_child(l)
	_size_caption(b, d)


func _size_caption(b: Button, d: float) -> void:
	for l in b.get_children():
		if l.has_meta("caption"):
			l.add_theme_font_size_override("font_size", _cap_size(d))
			l.offset_top = CAP_GAP
			l.offset_bottom = CAP_GAP
			l.visible = true


func _cap_size(d: float) -> int:
	return clampi(int(d * CAP_K), CAP_MIN, CAP_MAX)


## Height a caption takes under a seal d px wide (0 if the seal has none).
func _cap_h(d: float) -> float:
	return Style.BLACKLETTER.get_height(_cap_size(d)) + CAP_GAP


## The gold numeral beside an emblem seal: gold leaf for 1-9, Cinzel gold past that (Bank's points).
## side: 1 right of the seal, -1 left. Placed by _place_numeral once the seal has its size.
func _seal_numeral(b: Button, n: int, side: int) -> void:
	for c in b.get_children():
		if c.has_meta("numeral"):
			c.free()
	var c: Control
	var tex := Art.numeral(n)
	if tex:
		var t := TextureRect.new()
		t.texture = tex
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.material = Art.shimmer_material(n * 0.137)
		c = t
	else:
		var l := Label.new()
		l.text = str(n)
		l.add_theme_font_override("font", Style.NUMERAL)
		l.add_theme_color_override("font_color", Style.C_GOLD)
		l.add_theme_constant_override("outline_size", 10)
		l.add_theme_color_override("font_outline_color", Style.C_BLACK)
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		c = l
	c.set_meta("numeral", true)
	c.set_meta("side", side)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(c)
	_place_numeral(b, b.size.x if b.size.x > 0 else float(SEAL_CONFIRM), side)


## Puts the numeral beside the seal (d px wide) on `side`; returns how wide it is, gap included.
func _place_numeral(b: Button, d: float, side := 0) -> float:
	for c in b.get_children():
		if not c.has_meta("numeral"):
			continue
		if side == 0:
			side = c.get_meta("side")
		c.set_meta("side", side)
		c.visible = true
		var h := d * NUM_K
		var w := h * 0.62 if c is TextureRect else 0.0
		if c is Label:
			c.add_theme_font_size_override("font_size", int(h * 0.8))
			w = c.get_minimum_size().x
		var gap := d * 0.04
		c.anchor_top = 0.5
		c.anchor_bottom = 0.5
		c.anchor_left = 1.0 if side > 0 else 0.0
		c.anchor_right = c.anchor_left
		c.offset_top = -h / 2.0
		c.offset_bottom = h / 2.0
		c.offset_left = gap if side > 0 else -gap - w
		c.offset_right = c.offset_left + w
		return w + gap
	return 0.0


## Makes b an emblem seal: the emblem in the wax, the word under it.
func _emblem(b: Button, name: String, caption: String, ink: bool, d: float) -> void:
	Art.emblem_skin(b, name)
	b.text = ""
	if caption != "":
		_seal_caption(b, caption, ink, d)


# ---------- Helpers ----------

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


## A dice-count seal's face: the gold-leaf numeral in the wax (past 9, Cinzel text).
## These plain seals only select; the count is their whole meaning, so it sits in the wax.
func _seal_face(b: Button, n: int) -> void:
	var tex := Art.numeral(n)
	if tex == null:
		_caption(b, str(n), 62)
		return
	var t := TextureRect.new()
	t.texture = tex
	t.material = Art.shimmer_material(n * 0.137)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.anchor_left = 0.27  # the wax recess: about the middle of the seal
	t.anchor_top = 0.22
	t.anchor_right = 0.73
	t.anchor_bottom = 0.72
	b.add_child(t)


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
	_check_long_press()
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
	var has_paper := _paper != null and is_instance_valid(_paper)
	if _candle_glow and is_instance_valid(_candle_glow):
		# Candle flicker: two quick wobbles over a slow sway.
		var ct := Time.get_ticks_msec() / 1000.0
		var f := 0.62 if Tuning.reduce_motion else 0.62 + 0.1 * sin(ct * 11.0) * sin(ct * 6.7) + 0.06 * sin(ct * 2.3)
		_candle_glow.modulate.a = f
		_candle_glow.scale = Vector2.ONE * (0.97 + f * 0.05)
	if not has_paper:
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
	# Panels fade and scale uniformly from the centre (never squashed on one axis).
	node.pivot_offset = node.size / 2.0
	if open:
		node.visible = true
		node.scale = Vector2.ONE * PANEL_FROM
		node.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(node, "scale", Vector2.ONE if open else Vector2.ONE * PANEL_FROM, Tuning.PAGE_TURN).set_trans(Tween.TRANS_SPRING if open else Tween.TRANS_SINE).set_ease(Tween.EASE_OUT if open else Tween.EASE_IN)
	tw.parallel().tween_property(node, "modulate:a", 1.0 if open else 0.0, Tuning.PAGE_TURN * 0.8)
	await tw.finished
	if not open:
		node.visible = false
		node.scale = Vector2.ONE
		node.modulate = Color.WHITE


# ---------- The table (Rules.V4, Docs/TableDesign.md) ----------

## Under a window: the marks this player holds (small sigils), the Sins that claim them (large,
## red), and what they still owe (chips).
func _refresh_marks_line(pt: Dictionary, ps: Dictionary) -> void:
	var parts := []
	for s in ps.marks:
		for i in int(ps.marks[s]):
			parts.append("[img=30x30]%s[/img]" % Art.sigil_path(s))
	for s in ps.claims:
		parts.append("[img color=#ff7a6a width=44 height=44]%s[/img]" % Art.sigil_path(s))
	var text := " ".join(parts)
	if pt.marks.get_meta("text", "") != text:
		pt.marks.set_meta("text", text)
		Style.set_body(pt.marks, text)
	var d: Array = ps.debts
	var chips := []
	if d[0] > 0:
		chips.append(RulesText.table("chip_bank", {"n": d[0]}))
	if d[1] > 0:
		chips.append(RulesText.table("chip_strike"))
	if d[2] > 0:
		chips.append(RulesText.table("chip_fewer_1") if d[2] == 1 else RulesText.table("chip_fewer", {"n": d[2]}))
	if d[3] > 0:
		chips.append(RulesText.table("chip_die"))
	var key := "|".join(chips)
	if pt.chips.get_meta("key", "") == key:
		return
	pt.chips.set_meta("key", key)
	for c in pt.chips.get_children():
		c.queue_free()
	for c in chips:
		pt.chips.add_child(_chip(c))


## A debt chip: a dark red tab with gold edge, words in ivory at reading size.
func _chip(text: String) -> PanelContainer:
	var chip := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Tuning.CHIP_BG
	sb.border_color = Style.C_GOLD.darkened(0.15)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 2
	sb.content_margin_bottom = 4
	chip.add_theme_stylebox_override("panel", sb)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := Style.label(text, Tuning.CHIP_FONT, Style.C_IVORY, false, 4)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_constant_override("line_spacing", -8)
	chip.add_child(l)
	return chip


## A temptation (TableDesign §7) is a full-screen moment: the board dims, the Sin's 4:5 portrait
## takes the top of the screen with the window flare, the offer and one line of decision context
## sit under it, and Accept (crimson, right thumb) and Refuse (bronze, left) wait in the thumb zone.
## The parchment and the prompt line step aside until the choice is made (clear_prompt).
func _show_offer_now(_text: String, options: Array, offer: Dictionary) -> void:
	clear_prompt()
	_waiting = false
	if _summary:
		_summary.visible = false
	_set_lettering(_prompt_label, "")
	_paper.visible = false
	var sname: String = offer.sin
	var col: Color = Style.SIN_COLORS[sname]
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.z_index = 4  # over the board, tray and plates; the seals sit above it (z 5)
	root.set_meta("sin", sname)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, Tuning.OFFER_DIM)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(v)
	var win := TextureRect.new()
	win.texture = Art.portrait(sname)
	win.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	win.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	win.material = Art.flare_material()
	win.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# A thin border in the Sin's colour round a portrait (no fill or shadow: the glass shows as painted).
	# A Sin still on its lancet (no portrait yet) has none.
	var frame := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_color = col.lightened(0.3)
	sb.set_border_width_all(6 if win.texture.resource_path.ends_with("_portrait.png") else 0)
	# A Sin with baked layers lives: it breathes, and makes its offer (ui/living_portrait.gd).
	var living: SubViewport = null
	if LivingPortrait.has_layers(sname):
		living = LivingPortrait.new()
		living.setup(sname)
		root.add_child(living)
		win.texture = living.get_texture()
	frame.add_theme_stylebox_override("panel", sb)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	frame.add_child(win)
	v.add_child(frame)
	var name_l := Style.label(sname, Tuning.OFFER_NAME_FONT, col.lightened(0.4), true, 8)
	v.add_child(name_l)
	var inner: float = _fx.size.x * Tuning.OFFER_PORTRAIT_W
	var words := Style.body(offer.text, Tuning.OFFER_FONT, Style.C_IVORY, 8)
	words.custom_minimum_size.x = inner
	words.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(words)
	if offer.get("context", "") != "":
		var ctx := Style.body(offer.context, Tuning.OFFER_CONTEXT_FONT, Style.C_BONE, 6)  # numbers in the gold numeral face
		ctx.custom_minimum_size.x = inner
		ctx.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(ctx)
	if offer.tip != "":
		var tip := Style.body("[i]%s[/i]" % offer.tip, Tuning.OFFER_TIP_FONT, Style.C_BONE, 6)
		tip.custom_minimum_size.x = inner
		tip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(tip)
	root.modulate.a = 0.0
	_fx.add_child(root)
	_offer_card = root
	# Portrait: OFFER_PORTRAIT_W of the screen width at 4:5, shrunk only if the words would reach the seals.
	var place := func():
		if not is_instance_valid(root):
			return
		var seals_top: float = _fx.size.y
		for b in _buttons.get_children():
			if not b.is_queued_for_deletion() and b.size.y > 0:
				seals_top = minf(seals_top, b.get_global_rect().position.y)
		var text_h := 0.0
		for c in v.get_children():
			if c != frame:
				text_h += c.get_combined_minimum_size().y + 18.0
		var top := 40.0
		var asp: float = float(win.texture.get_width()) / maxf(1.0, win.texture.get_height())
		var pw: float = _fx.size.x * Tuning.OFFER_PORTRAIT_W
		var ph: float = minf(pw / asp, seals_top - 30.0 - top - text_h - 12.0)
		win.custom_minimum_size = Vector2(ph * asp, ph)
		v.position = Vector2(0, top)
		v.size = Vector2(_fx.size.x, 0)
	v.minimum_size_changed.connect(place, CONNECT_DEFERRED)
	root.set_meta("place", place)  # show_prompt re-places it once the seals are laid out
	place.call_deferred()
	# Arrival: the board dims, the glass flares white and settles.
	var tw := root.create_tween().set_parallel()
	tw.tween_property(root, "modulate:a", 1.0, 0.25)
	tw.tween_method(func(f: float): win.material.set_shader_parameter("flash", f), 1.0, 0.0, Tuning.FLARE_TIME).set_ease(Tween.EASE_OUT)
	for pt in _portraits:
		if pt.sin == sname:
			_flare(pt)
	for o in options:
		var accept: bool = o[1] == true
		var kind := "roll" if accept else "bank"
		var b := Button.new()
		b.set_meta("kind", kind)
		b.set_meta("offer", "accept" if accept else "refuse")
		b.z_index = 5
		# Accept: the offering Sin's own seal, its colour wax and all. Refuse: the gold hand.
		_emblem(b, ("accept_" + sname.to_lower()) if accept else "refuse", o[0], false, SEAL_CONFIRM)
		var val = o[1]
		b.set_meta("value", val)
		# A living portrait reacts before the screen closes: Accept, he gulps the dice and holds the
		# empty mouth; Refuse, the goblet lowers and the glass dims. One answer only.
		_seal_feel(b, kind, func():
			if root.has_meta("answered"):
				return
			root.set_meta("answered", true)
			if living:
				for s in _buttons.get_children():
					s.mouse_filter = Control.MOUSE_FILTER_IGNORE
				var hold: float = living.accept() if accept else living.refuse()
				if not accept:
					root.create_tween().tween_method(func(f: float): win.material.set_shader_parameter("dim", f), 0.0, 1.0, hold * 0.8)
				await get_tree().create_timer(hold).timeout
			human.answered.emit(val))
		_buttons.add_child(b)
	_layout_buttons.call_deferred()
	place.call_deferred()


## A Sin's line (TableDesign §3): a speech tab at the foot of the speaker's window, in its colour.
func speech(pt: Dictionary, text: String) -> Control:
	var col: Color = Style.SIN_COLORS[pt.sin]
	var bub := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Tuning.OFFER_BG
	sb.border_color = col.lightened(0.25)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(18)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 8
	sb.content_margin_bottom = 12
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 14
	bub.add_theme_stylebox_override("panel", sb)
	bub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var words := "“%s”" % text
	var l := Style.body(words, Tuning.LINE_FONT, Style.C_IVORY, 6)
	var tw_w := Style.SERIF.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, Tuning.LINE_FONT).x + 12.0
	l.custom_minimum_size.x = minf(tw_w, Tuning.LINE_MAX_W)
	bub.add_child(l)
	bub.modulate.a = 0.0
	_fx.add_child(bub)
	var wr: Rect2 = pt.window.get_global_rect()
	var place := func():
		if is_instance_valid(bub):
			var x := clampf(wr.get_center().x - bub.size.x / 2.0, 24.0, _fx.size.x - 24.0 - bub.size.x)
			bub.position = Vector2(x, wr.end.y - Tuning.LINE_OVERLAP)
			bub.pivot_offset = Vector2(clampf(wr.get_center().x - x, 0.0, bub.size.x), 0.0)
	bub.resized.connect(place)
	place.call_deferred()
	bub.scale = Vector2.ONE * 0.85
	var tw := bub.create_tween().set_parallel()
	tw.tween_property(bub, "modulate:a", 1.0, 0.15)
	tw.tween_property(bub, "scale", Vector2.ONE, Tuning.ACTION).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	return bub


func clear_speech(bub: Control) -> void:
	if not is_instance_valid(bub):
		return
	var tw := bub.create_tween()
	tw.tween_property(bub, "modulate:a", 0.0, 0.15)
	tw.tween_callback(bub.queue_free)


## core/game.gd calls this at a bust, a big Bank, a change of leader and an attack: about half the
## time one Sin bot says a line about it (RulesText.LINES), at most one a turn, never one twice a game.
func table_event(kind: String, p, other = null) -> void:
	if game == null or not game.v4 or _tutor != null:
		return
	var turn_id: int = game.round_count * 10 + game.players.find(game.current)
	if _line_turn == turn_id:
		return
	var bots: Array = game.players.filter(func(o): return o.bot != human)
	var speaker = null
	var ev := ""
	var about = null
	match kind:
		"bust":
			var rivals: Array = bots.filter(func(o): return o != p)
			if p.bot != human and (rivals.is_empty() or randf() < 0.5):
				speaker = p
				ev = "own_bust"
			elif not rivals.is_empty():
				var wrath := rivals.filter(func(o): return o.sin.sin_name == "Wrath")
				speaker = wrath[0] if not wrath.is_empty() and randf() < 0.5 else rivals[randi() % rivals.size()]
				ev = "rival_bust"
				about = p
		"bank":
			if p.bot != human:
				speaker = p
				ev = "big_bank"
		"lead":
			if p.bot != human:
				speaker = p
				ev = "lead"
		"attacked":  # p was hit, other aimed
			if other.bot != human and (p.bot == human or randf() < 0.5):
				speaker = other
				ev = "aim"
				about = p
			elif p.bot != human:
				speaker = p
				ev = "attacked"
				about = other
	if speaker == null or randf() >= Tuning.LINE_CHANCE:
		return
	if _say_line(speaker, ev, about):
		_line_turn = turn_id


## Queues one line from `speaker` (a bot's PlayerState). Returns false when it has none left.
func _say_line(speaker, ev: String, about) -> bool:
	var sname: String = speaker.sin.sin_name
	var pool: Array = RulesText.LINES[sname][ev].filter(func(l): return not _lines_used.has(l))
	if pool.is_empty():
		return false
	var line: String = pool[randi() % pool.size()]
	_lines_used[line] = true
	line = line.replace("{name}", about.sin.sin_name if about else "")
	var seat: int = game.players.find(speaker)
	_q.push(func(): await _dir.line(seat, line))
	return true


## Game over: the winner, or one of the Sins that lost to you, has the last word.
func _end_line(w) -> void:
	if game == null or not game.v4:
		return
	if w.bot != human:
		_say_line(w, "win", null)
		return
	var bots: Array = game.players.filter(func(o): return o.bot != human)
	if not bots.is_empty():
		_say_line(bots[randi() % bots.size()], "lose", w)


## Shows or hides the words under the title page's seals (they sit outside the Settings page).
func _menu_words(on: bool) -> void:
	for s in _menu_seals:
		if is_instance_valid(s):
			for c in s.get_children():
				if c.has_meta("caption"):
					c.visible = on
