## Three wax marks: struck ones are red seals with an X, the rest empty rings.
extends Control

const Style = preload("res://ui/style.gd")
const RULES = preload("res://core/rules.gd")

var strikes := 0:
	set(v):
		if v != strikes:
			strikes = v
			queue_redraw()


func _init() -> void:
	custom_minimum_size = Vector2(3 * 64 + 2 * 14, 64)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	for i in RULES.STRIKES_TO_BUST:
		var c := Vector2(32 + i * 78, 32)
		if i < strikes:
			draw_circle(c, 30, Style.C_CRIMSON_DARK)
			draw_circle(c, 25, Style.C_STRIKE)
			draw_line(c + Vector2(-11, -11), c + Vector2(11, 11), Style.C_BONE, 6)
			draw_line(c + Vector2(11, -11), c + Vector2(-11, 11), Style.C_BONE, 6)
		else:
			draw_arc(c, 26, 0, TAU, 32, Style.C_DIM.darkened(0.3), 4)
