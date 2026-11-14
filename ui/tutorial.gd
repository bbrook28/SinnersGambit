## First-run tutorial overlay: dims the screen except one spotlit rect, shows one short line in
## manuscript lettering on a dark plate, and waits for a tap. ui/main.gd decides what to point at
## and when (_tutorial_*). Docs/Handoff.md § Tutorial.
extends Control

const Style = preload("res://ui/style.gd")
const Tuning = preload("res://ui/tuning.gd")
const SPOT := preload("res://ui/shaders/spotlight.gdshader")
const PAD := 24.0          # the spotlight reaches this far past the target
const FADE := 0.25

signal tapped

var m                      # ui/main.gd (for its lettering helpers)
var _dim: ColorRect
var _plate: PanelContainer
var _text: RichTextLabel
var _hint: Label
var _ready_for_tap := false


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
	_plate.add_child(v)
	_text = m._make_lettering(52, Style.C_IVORY, false)
	_text.custom_minimum_size.x = 860
	v.add_child(_text)
	_hint = Style.label("Tap to continue", 32, Style.C_BONE, false, 0)
	_hint.modulate.a = 0.7
	v.add_child(_hint)
	add_child(_plate)
	modulate.a = 0.0


## Spotlights `rect` (screen px), writes `line`, and returns once the player taps.
func step(rect: Rect2, line: String) -> void:
	var r := rect.grow(PAD)
	var mat := _dim.material as ShaderMaterial
	var vp := get_viewport_rect().size
	mat.set_shader_parameter("rect", Vector4(r.position.x, r.position.y, r.size.x, r.size.y) / Vector4(vp.x, vp.y, vp.x, vp.y))
	mat.set_shader_parameter("aspect", vp.y / maxf(vp.x, 1.0))
	m._set_lettering(_text, line, Style.C_GOLD)
	await get_tree().process_frame
	# The plate sits on whichever side of the spotlight has more room.
	var h := _plate.get_combined_minimum_size().y
	_plate.size = Vector2(minf(vp.x - 60.0, 920.0), h)
	var x := (vp.x - _plate.size.x) / 2.0
	var y: float
	if r.get_center().y > vp.y * 0.5:
		y = maxf(m._safe_insets().x + 30.0, r.position.y - h - 40.0)
	else:
		y = minf(vp.y - h - m._safe_insets().y - 30.0, r.end.y + 40.0)
	_plate.position = Vector2(x, y)
	_plate.pivot_offset = _plate.size / 2
	_plate.scale = Vector2.ONE * 0.94
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, FADE)
	tw.parallel().tween_property(_plate, "scale", Vector2.ONE, FADE * 1.6).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	_ready_for_tap = false
	get_tree().create_timer(0.35).timeout.connect(func(): _ready_for_tap = true)  # no accidental double taps
	await tapped


func finish() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, FADE)
	await tw.finished
	queue_free()


func _gui_input(event: InputEvent) -> void:
	var tap: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventScreenTouch and event.pressed)
	if tap and _ready_for_tap:
		_ready_for_tap = false
		accept_event()
		m._dir.sfx.play("plaque", 0.4, 1.0, true)
		tapped.emit()
