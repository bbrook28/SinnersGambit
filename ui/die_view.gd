## One die, drawn with pips. A skull is drawn dark with a red pip. Tap it to pick it.
extends Control

signal picked

var face := 1
var skull := false
var selected := false
var dim := false
var caption := ""   # under the die: "held", "x2"
var tappable := false

const IVORY := Color("e8dcbc")
const INK := Color("1a1210")
const GOLD := Color("d9a441")
const BLOOD := Color("b3261e")
const PIPS := {1: [Vector2(0.5, 0.5)], 2: [Vector2(0.27, 0.27), Vector2(0.73, 0.73)],
	3: [Vector2(0.27, 0.27), Vector2(0.5, 0.5), Vector2(0.73, 0.73)],
	4: [Vector2(0.27, 0.27), Vector2(0.73, 0.27), Vector2(0.27, 0.73), Vector2(0.73, 0.73)],
	5: [Vector2(0.27, 0.27), Vector2(0.73, 0.27), Vector2(0.5, 0.5), Vector2(0.27, 0.73), Vector2(0.73, 0.73)],
	6: [Vector2(0.27, 0.25), Vector2(0.73, 0.25), Vector2(0.27, 0.5), Vector2(0.73, 0.5), Vector2(0.27, 0.75), Vector2(0.73, 0.75)]}


func setup(f: int, is_skull: bool, side: float) -> void:
	face = f
	skull = is_skull
	custom_minimum_size = Vector2(side, side + (40 if side >= 120 else 0))
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


func _gui_input(e: InputEvent) -> void:
	if not tappable:
		return
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:  # touch arrives as an emulated mouse press
		picked.emit()
		accept_event()


func _draw() -> void:
	var side := minf(size.x, custom_minimum_size.x)
	var r := Rect2(Vector2((size.x - side) / 2.0, 0), Vector2(side, side))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("3a1512") if skull else IVORY
	if dim:
		sb.bg_color = sb.bg_color.darkened(0.5)
	sb.set_corner_radius_all(int(side * 0.16))
	if selected:
		sb.border_color = GOLD
		sb.set_border_width_all(int(maxf(4.0, side * 0.06)))
	draw_style_box(sb, r)
	var pip_r := side * 0.085
	for p in PIPS[face]:
		draw_circle(r.position + p * side, pip_r * (1.6 if skull else 1.0), BLOOD if skull else INK)
	if caption != "" and size.y > side + 10:
		var font := get_theme_default_font()
		var fs := 30
		var w := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
		draw_string(font, Vector2((size.x - w) / 2.0, side + 34), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, GOLD)
