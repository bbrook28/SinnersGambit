## Carved bone die (SpriteCook art, assets/art/runtime/dice/<face>.png). Strike faces (1-2) have red ink.
## State is shown in the world, not with outlines: scorers (4-6) sit raised and candle-lit with a long
## soft shadow; 3s and Strikes sit sunk into the leather, darker, with a tight shadow. Candle on the right.
extends Control

const FACES := [
	preload("res://assets/art/runtime/dice/1.png"), preload("res://assets/art/runtime/dice/2.png"),
	preload("res://assets/art/runtime/dice/3.png"), preload("res://assets/art/runtime/dice/4.png"),
	preload("res://assets/art/runtime/dice/5.png"), preload("res://assets/art/runtime/dice/6.png"),
]

var face := 1
var tilt := 0.0  # small per-die rotation so a row doesn't look stamped
## px above the leather while thrown (ui/director.gd): the shadow stays on the ground, fainter and wider.
var height := 0.0:
	set(v):
		height = v
		queue_redraw()


func _init(p_face := 1, side := 120, seed := 0) -> void:
	face = clampi(p_face, 1, 6)
	tilt = deg_to_rad(float((seed * 37) % 9) - 4.0)
	custom_minimum_size = Vector2(side, side)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var s: float = minf(size.x, size.y)
	var raised := face >= 4
	var tex: Texture2D = FACES[face - 1]
	var d := s * (0.94 if raised else 0.86)
	var lift := s * (0.05 if raised else 0.0)
	var c := Vector2(s, s) / 2.0 - Vector2(0, lift)
	draw_set_transform(c, tilt)
	var r := Rect2(Vector2(-d, -d) / 2.0, Vector2(d, d))
	# Soft shadow falling left and down: a few offset silhouettes.
	var air := clampf(height / (s * 2.5), 0.0, 1.0)
	var reach := s * (0.11 if raised else 0.035) * (1.0 + 2.0 * air)
	var passes := 4
	for i in passes:
		var k := float(i + 1) / passes
		# Airborne: the shadow stays down on the leather (undo the height, in this rotated frame).
		var ground := Vector2(-height * 0.25, height).rotated(-tilt - rotation) / maxf(scale.y, 0.1)
		var off := Vector2(-reach, reach * 1.1) * k + Vector2(0, lift) + ground
		draw_texture_rect(tex, Rect2(r.position + off, r.size), false, Color(0, 0, 0, (0.32 if raised else 0.5) / passes * (passes - i) * (1.0 - 0.7 * air)))
	draw_texture_rect(tex, r, false, Color(1.1, 1.06, 0.98) if raised else Color(0.62, 0.58, 0.54))
	draw_set_transform(Vector2.ZERO)
