## Tutorial overlay: dims the screen except one spotlit rect and shows one short line in manuscript
## lettering on a dark plate. It stays up for the whole tutorial, in one of three modes:
##   idle: invisible, every tap goes through (bot turns play on).
##   read: tap anywhere to go on.
##   act:  only taps inside the spotlight get through, so only the control it lights is live.
## A Skip plate at the top centre is live in every mode. ui/tutorial_game.gd runs the script.
extends Control

const Style = preload("res://ui/style.gd")
const Tuning = preload("res://ui/tuning.gd")
const RulesText = preload("res://ui/rules_text.gd")
const SPOT := preload("res://ui/shaders/spotlight.gdshader")
const PAD := 24.0          # the spotlight reaches this far past the target
const FADE := 0.25

signal tapped
signal skipped

enum { IDLE, READ, ACT }

var m                      # ui/main.gd (for its lettering helpers)
var mode := IDLE
var hole := Rect2()        # act mode: taps inside this rect reach the board
var _dim: ColorRect
var _plate: PanelContainer
var _text: RichTextLabel
var _hint: Label
var _choices: HBoxContainer
var _skip: Button
var _ready_for_tap := false
var _shown := false
var _target: Control       # act mode: the control the spotlight follows


func _init(main) -> void:
	m = main
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_dim = ColorRect.new()
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = SPOT
	_dim.material = mat
	_dim.modulate.a = 0.0
	add_child(_dim)
	_plate = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.035, 0.03, 0.95)
	sb.border_color = Style.C_GOLD_DEEP
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(18)
	sb.set_content_margin_all(30)
	_plate.add_theme_stylebox_override("panel", sb)
	_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plate.add_child(v)
	_text = m._make_lettering(52, Style.C_IVORY, false)
	_text.custom_minimum_size.x = 860
	v.add_child(_text)
	_hint = Style.label(RulesText.tutorial("tap"), 32, Style.C_BONE, false, 0)
	_hint.modulate.a = 0.7
	v.add_child(_hint)
	_choices = HBoxContainer.new()
	_choices.alignment = BoxContainer.ALIGNMENT_CENTER
	_choices.add_theme_constant_override("separation", int(m.GAP_MIN * 2))
	_choices.visible = false
	v.add_child(_choices)
	_plate.modulate.a = 0.0
	_plate.visible = false
	add_child(_plate)
	# Skip: a small plaque at the top centre, always live.
	_skip = Button.new()
	_skip.set_meta("kind", "tutorial_skip")
	m.Art.skin(_skip, [m.Art.YOU_TAB, m.Art.YOU_TAB, m.Art.YOU_TAB], Color.WHITE, 24)
	_skip.text = RulesText.tutorial("skip")
	_skip.add_theme_font_size_override("font_size", 40)
	_skip.custom_minimum_size = Vector2(240, m.TARGET_MIN * 1.1)
	_skip.pressed.connect(func():
		m._dir.sfx.play("plaque", 0.5, 1.0, true)
		skipped.emit())
	add_child(_skip)
	resized.connect(_place_skip)
	_place_skip.call_deferred()


func _place_skip() -> void:
	var vp := get_viewport_rect().size
	_skip.size = _skip.get_combined_minimum_size()
	_skip.position = Vector2((vp.x - _skip.size.x) / 2.0, m._safe_insets().x + 24.0)  # between the windows


## Idle lets every tap through; read takes them all; act only lets the spotlight's through.
func _has_point(point: Vector2) -> bool:
	match mode:
		READ:
			return true
		ACT:
			return not hole.has_point(point)
	return false


## Takes every tap (nothing shown yet): a new prompt's buttons stay dead until the script says.
func block() -> void:
	mode = READ
	_ready_for_tap = false


## Spotlights `rect` (screen px; empty = dim everything), writes `line`, returns once the player taps.
func read(rect: Rect2, line: String) -> void:
	mode = READ
	_hint.visible = true
	_choices.visible = false
	await _show(rect, line)
	_ready_for_tap = false
	get_tree().create_timer(0.35).timeout.connect(func(): _ready_for_tap = true)  # no accidental double taps
	await tapped


## Spotlights `rect` and writes `line`; only taps inside `rect` get through until idle().
## The spotlight follows `target` while it springs into place (_process).
func act(target: Control, line: String) -> void:
	mode = ACT
	_target = target
	_hint.visible = false
	_choices.visible = false
	hole = rest_rect(target).grow(PAD)
	await _show(rest_rect(target), line)


func _process(_delta: float) -> void:
	if mode != ACT or _target == null or not is_instance_valid(_target):
		return
	var r := rest_rect(_target).grow(PAD)
	if r == hole:
		return
	hole = r
	var vp := get_viewport_rect().size
	(_dim.material as ShaderMaterial).set_shader_parameter("rect", Vector4(r.position.x, r.position.y, r.size.x, r.size.y) / Vector4(vp.x, vp.y, vp.x, vp.y))


## The last card: `line` and one seal per label; returns the index pressed.
func end_card(line: String, labels: Array) -> int:
	mode = READ
	_ready_for_tap = false
	_hint.visible = false
	for c in _choices.get_children():
		c.queue_free()
	var pick := [-1]
	for i in labels.size():
		var b: Button = m._menu_seal(labels[i], 260, func():
			pick[0] = i
			tapped.emit())
		b.set_meta("kind", "tutorial_end")
		b.set_meta("value", i)
		_choices.add_child(b)
	_choices.visible = true
	await _show(Rect2(), line)
	while pick[0] < 0:
		await tapped
	return pick[0]


## Fades the dim and plate away; taps go through again.
func idle() -> void:
	mode = IDLE
	hole = Rect2()
	_target = null
	if not _shown:
		return
	_shown = false
	var tw := create_tween()
	tw.tween_property(_dim, "modulate:a", 0.0, FADE)
	tw.parallel().tween_property(_plate, "modulate:a", 0.0, FADE)
	await tw.finished
	if not _shown:
		_plate.visible = false


func _show(rect: Rect2, line: String) -> void:
	var vp := get_viewport_rect().size
	var r := rect.grow(PAD) if rect.size != Vector2.ZERO else Rect2(-10, -10, 0, 0)
	var mat := _dim.material as ShaderMaterial
	mat.set_shader_parameter("rect", Vector4(r.position.x, r.position.y, r.size.x, r.size.y) / Vector4(vp.x, vp.y, vp.x, vp.y))
	mat.set_shader_parameter("aspect", vp.y / maxf(vp.x, 1.0))
	_plate.visible = true
	m._set_lettering(_text, line, Style.C_GOLD)
	await get_tree().process_frame
	# The plate sits on whichever side of the spotlight has more room (centred with no spotlight).
	var h := _plate.get_combined_minimum_size().y
	_plate.size = Vector2(minf(vp.x - 60.0, 920.0), h)
	var x := (vp.x - _plate.size.x) / 2.0
	var y: float
	if rect.size == Vector2.ZERO:
		y = vp.y * 0.4 - h / 2.0  # clear of the ticker
	elif r.get_center().y > vp.y * 0.5:
		y = maxf(m._safe_insets().x + 140.0, r.position.y - h - 40.0)
	else:
		y = minf(vp.y - h - m._safe_insets().y - 30.0, r.end.y + 40.0)
	_plate.position = Vector2(x, y)
	_plate.pivot_offset = _plate.size / 2
	var fresh := not _shown
	_shown = true
	var tw := create_tween()
	tw.tween_property(_dim, "modulate:a", 1.0, FADE)
	tw.parallel().tween_property(_plate, "modulate:a", 1.0, FADE)
	if fresh:
		_plate.scale = Vector2.ONE * 0.94
		tw.parallel().tween_property(_plate, "scale", Vector2.ONE, FADE * 1.6).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)


## Test hook (tests/tutorial_check.gd): what a read tap does.
func advance() -> void:
	if mode == READ and _ready_for_tap and not _choices.visible:
		_ready_for_tap = false
		tapped.emit()


func _gui_input(event: InputEvent) -> void:
	var tap: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventScreenTouch and event.pressed)
	if not tap:
		return
	accept_event()
	if mode == READ and _ready_for_tap and not _choices.visible:
		_ready_for_tap = false
		m._dir.sfx.play("plaque", 0.4, 1.0, true)
		tapped.emit()


## Where a control sits at rest: its layout rect, ignoring its own scale (seals spring in and
## breathe), with a little headroom for that.
static func rest_rect(c: Control) -> Rect2:
	var p := c.get_parent() as CanvasItem
	var o: Vector2 = (p.get_global_transform() if p else Transform2D.IDENTITY) * c.position
	return Rect2(o, c.size).grow(c.size.x * 0.12)
