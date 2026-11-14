## Sin select (Phase 4): one Sin per page, swiped sideways. Each page is the Sin's lit window,
## its name, epithet, playstyle and abilities; Sin-coloured light glows behind the window and
## changes with the page; page dots under it (tap one to jump); each Sin sounds its sting when
## its page settles. Opens on RECOMMENDED. Built by main._build_setup; the Choose seal is main's.
## Words: ui/rules_text.gd. Timings: ui/tuning.gd § Sin select.
extends VBoxContainer

const Style = preload("res://ui/style.gd")
const Art = preload("res://ui/art.gd")
const Tuning = preload("res://ui/tuning.gd")
const RulesText = preload("res://ui/rules_text.gd")
const MENU_GLASS = preload("res://ui/shaders/menu_glass.gdshader")
const RECOMMENDED := "Sloth"
const DOT := 26.0               # a page dot's diameter (the strip under them is the touch target)

signal changed(index: int)

var names: Array = []           # Sin names, in page order
var greater := true             # show the Greater ability line (off in First Game)
var sfx                         # ui/sfx.gd
var index := 0

var _view: Control              # clips the track; takes the swipe
var _track: Control             # the pages side by side
var _light: TextureRect         # the Sin-coloured glow behind the window
var _dots: Control
var _press_x := INF
var _press_t := 0.0
var _dragging := false
var _snap: Tween


func _init(sin_names: Array, show_greater: bool, sound) -> void:
	names = sin_names
	greater = show_greater
	sfx = sound
	index = maxi(0, names.find(RECOMMENDED))
	add_theme_constant_override("separation", 8)
	_view = Control.new()
	_view.clip_contents = true
	_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_view.mouse_filter = Control.MOUSE_FILTER_STOP
	_view.gui_input.connect(_on_view_input)
	_view.resized.connect(_layout)
	add_child(_view)
	_light = TextureRect.new()
	_light.texture = Art.soft_dot(128)
	_light.material = Art.additive()
	_light.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_light.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_light.self_modulate = _glow_col(index)
	_view.add_child(_light)
	_track = Control.new()
	_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_view.add_child(_track)
	for n in names:
		_track.add_child(_make_page(n))
	_dots = Control.new()
	_dots.custom_minimum_size.y = 44.0 * 1080.0 / 393.0
	_dots.mouse_filter = Control.MOUSE_FILTER_STOP
	_dots.draw.connect(_draw_dots)
	_dots.gui_input.connect(_on_dots_input)
	add_child(_dots)
	if not Tuning.reduce_motion:
		var tw := _light.create_tween().set_loops()
		tw.tween_property(_light, "modulate:a", Tuning.SELECT_LIGHT_BREATHE, Tuning.SELECT_LIGHT_PERIOD / 2).set_trans(Tween.TRANS_SINE)
		tw.tween_property(_light, "modulate:a", 1.0, Tuning.SELECT_LIGHT_PERIOD / 2).set_trans(Tween.TRANS_SINE)


func _ready() -> void:
	# The opening page's sting, once the ink has drawn back.
	get_tree().create_timer(Tuning.WASH_TIME + 0.1).timeout.connect(_sting)


## The page for one Sin: window, then the words under it. Sloth wears the Recommended ribbon.
func _make_page(n: String) -> Control:
	var col: Color = Style.SIN_COLORS[n]
	var page := VBoxContainer.new()
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_theme_constant_override("separation", 6)
	var win := TextureRect.new()
	win.name = "Window"
	win.texture = Art.window(n)
	win.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	win.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	win.size_flags_vertical = Control.SIZE_EXPAND_FILL
	win.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gm := ShaderMaterial.new()
	gm.shader = MENU_GLASS
	gm.set_shader_parameter("phase", float(names.find(n)) * 3.1)
	gm.set_shader_parameter("period", Tuning.MENU_SHEEN_PERIOD)
	gm.set_shader_parameter("motion", 0.0 if Tuning.reduce_motion else 1.0)
	win.material = gm
	page.add_child(win)
	if n == RECOMMENDED:
		var tag := PanelContainer.new()
		tag.name = "Recommended"
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sb := StyleBoxFlat.new()
		sb.bg_color = Style.C_CRIMSON.darkened(0.15)
		sb.border_color = Style.C_GOLD.darkened(0.2)
		sb.set_border_width_all(3)
		sb.set_corner_radius_all(10)
		sb.content_margin_left = 26
		sb.content_margin_right = 26
		sb.content_margin_top = 6
		sb.content_margin_bottom = 8
		tag.add_theme_stylebox_override("panel", sb)
		var tl := Style.label(RulesText.word("setup_recommended"), 34, Style.C_IVORY, true, 6)
		tl.autowrap_mode = TextServer.AUTOWRAP_OFF
		tag.add_child(tl)
		win.add_child(tag)
		# Across the foot of the window, centred, once the window has a size.
		win.resized.connect(func():
			tag.reset_size()
			tag.position = Vector2((win.size.x - tag.size.x) / 2, win.size.y - tag.size.y - 18))
	var title := Style.label("%s, %s" % [n, RulesText.SINS[n].epithet], 62, col.lightened(0.45), true, 10)
	page.add_child(title)
	var play := Style.body("[i]%s[/i]" % RulesText.SINS[n].play, 34, Style.C_BONE, 8)
	page.add_child(play)
	for g in ([false, true] if greater else [false]):  # "Name: text", the name in gold leaf
		var l := Style.body("[color=#%s]%s:[/color] %s" % [Style.C_GOLD.to_html(false), RulesText.ability_name(n, g), RulesText.ability_text(n, g)], 30, Style.C_IVORY, 8)
		page.add_child(l)
	return page


## Pages are as wide as the view; the track slides so the current one sits in it.
func _layout() -> void:
	var w := _view.size.x
	for i in _track.get_child_count():
		var p: Control = _track.get_child(i)
		p.position = Vector2(i * w + Tuning.SELECT_PAGE_PAD, 0)
		p.size = Vector2(w - Tuning.SELECT_PAGE_PAD * 2, _view.size.y)
	_track.position.x = -index * w
	# The glow sits behind the window (the top of the page), wholly inside the clipped view so its
	# soft edge is never cut.
	_light.size = Vector2(w, _view.size.y * 0.8)
	_light.position = Vector2.ZERO


func go_to(i: int, sound := true) -> void:
	var old := index
	index = clampi(i, 0, names.size() - 1)
	_settle()
	if index != old:
		changed.emit(index)
		if sfx:
			sfx.play("plaque", 0.4, 1.0, true)
	if sound and index != old:
		_sting()


func _settle() -> void:
	if _snap and _snap.is_valid():
		_snap.kill()
	_snap = create_tween().set_parallel()
	var to := -index * _view.size.x
	if Tuning.reduce_motion:
		_snap.tween_property(_track, "position:x", to, Tuning.SELECT_SNAP * 0.6)
	else:
		_snap.tween_property(_track, "position:x", to, Tuning.SELECT_SNAP).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	_snap.tween_property(_light, "self_modulate", _glow_col(index), Tuning.SELECT_LIGHT_FADE)
	_dots.queue_redraw()


func _sting() -> void:
	if sfx and is_inside_tree():
		sfx.play_solo("sting_" + String(names[index]).to_lower())


func _glow_col(i: int) -> Color:
	return Color(Style.SIN_COLORS[names[i]].lightened(0.2), Tuning.SELECT_LIGHT)


## Swipe: the track follows the finger (rubber-banded past the ends); a long or quick enough
## swipe turns the page, anything shorter springs back.
func _on_view_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			_press_x = e.position.x
			_press_t = Time.get_ticks_msec() / 1000.0
			_dragging = true
			if _snap and _snap.is_valid():
				_snap.kill()
		elif _dragging:
			_dragging = false
			var dx: float = e.position.x - _press_x
			var dt := maxf(0.01, Time.get_ticks_msec() / 1000.0 - _press_t)
			var flick := absf(dx) / dt > Tuning.SELECT_FLICK and absf(dx) > 30.0
			if absf(dx) > _view.size.x * Tuning.SELECT_TURN or flick:
				go_to(index - int(signf(dx)))
			else:
				go_to(index)
	elif e is InputEventMouseMotion and _dragging:
		var dx: float = e.position.x - _press_x
		if (index == 0 and dx > 0) or (index == names.size() - 1 and dx < 0):
			dx *= 0.35
		_track.position.x = -index * _view.size.x + dx


func _unhandled_input(e: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if e.is_action_pressed("ui_left"):
		go_to(index - 1)
	elif e.is_action_pressed("ui_right"):
		go_to(index + 1)


func _dot_x(i: int) -> float:
	var step := DOT * 2.2
	return _dots.size.x / 2 + (i - (names.size() - 1) / 2.0) * step


func _draw_dots() -> void:
	var cy := _dots.size.y / 2
	for i in names.size():
		var c: Color = Style.SIN_COLORS[names[i]]
		var on := i == index
		_dots.draw_circle(Vector2(_dot_x(i), cy), DOT * (0.62 if on else 0.4), c.lightened(0.25) if on else Color(c, 0.45))
		if on:
			_dots.draw_arc(Vector2(_dot_x(i), cy), DOT * 0.62 + 5, 0, TAU, 32, Style.C_GOLD, 3.0, true)


## A tap on the dot strip jumps to the nearest dot.
func _on_dots_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
		var best := 0
		for i in names.size():
			if absf(e.position.x - _dot_x(i)) < absf(e.position.x - _dot_x(best)):
				best = i
		go_to(best)
