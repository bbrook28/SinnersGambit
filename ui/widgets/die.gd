## Carved bone die: yellowed face, chipped corner, drilled and inked pips.
## Scorers (4-6) get a gold rim, Strikes (1-2) red ink and a red rim, 3s stay plain.
extends Control

const Style = preload("res://ui/style.gd")

const PIPS := {
	1: [Vector2(0.5, 0.5)],
	2: [Vector2(0.27, 0.27), Vector2(0.73, 0.73)],
	3: [Vector2(0.27, 0.27), Vector2(0.5, 0.5), Vector2(0.73, 0.73)],
	4: [Vector2(0.27, 0.27), Vector2(0.73, 0.27), Vector2(0.27, 0.73), Vector2(0.73, 0.73)],
	5: [Vector2(0.27, 0.27), Vector2(0.73, 0.27), Vector2(0.5, 0.5), Vector2(0.27, 0.73), Vector2(0.73, 0.73)],
	6: [Vector2(0.27, 0.25), Vector2(0.73, 0.25), Vector2(0.27, 0.5), Vector2(0.73, 0.5), Vector2(0.27, 0.75), Vector2(0.73, 0.75)],
}

var face := 1
var chip := 0  # which corner is chipped (varies per die)


func _init(p_face := 1, side := 120, p_chip := 0) -> void:
	face = p_face
	chip = p_chip % 4
	custom_minimum_size = Vector2(side, side)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var s: float = minf(size.x, size.y)
	var r := Rect2(Vector2.ZERO, Vector2(s, s))
	var rim := Style.C_BONE_DARK.darkened(0.25)
	var ink := Style.C_INK
	if face >= 4:
		rim = Style.C_GOLD
	elif face <= 2:
		rim = Style.C_STRIKE
		ink = Style.C_STRIKE
	# Shadow, body, top-light band.
	var body := StyleBoxFlat.new()
	body.bg_color = Style.C_BONE if face != 3 else Style.C_BONE.darkened(0.12)
	body.set_corner_radius_all(int(s * 0.16))
	body.border_color = rim
	body.set_border_width_all(maxi(3, int(s * 0.05)))
	body.shadow_color = Color(0, 0, 0, 0.6)
	body.shadow_size = int(s * 0.06)
	body.shadow_offset = Vector2(0, s * 0.05)
	body.anti_aliasing = false
	draw_style_box(body, r)
	draw_rect(Rect2(r.position + Vector2(s * 0.14, s * 0.08), Vector2(s * 0.72, s * 0.06)), Color(1, 1, 1, 0.22))
	# Chipped corner: a notch of darker, rougher bone.
	var c: Vector2 = [Vector2(0, 0), Vector2(s, 0), Vector2(s, s), Vector2(0, s)][chip]
	var dir: Vector2 = [Vector2(1, 1), Vector2(-1, 1), Vector2(-1, -1), Vector2(1, -1)][chip]
	var k := s * 0.13
	draw_colored_polygon(PackedVector2Array([c + dir * Vector2(k * 0.3, k * 0.3), c + dir * Vector2(k * 1.3, k * 0.35), c + dir * Vector2(k * 0.35, k * 1.3)]), Style.C_BONE_DARK.darkened(0.15))
	# Pips: drilled (dark rim) and inked.
	for p in PIPS[face]:
		var pc: Vector2 = p * s
		draw_circle(pc, s * 0.085, ink.darkened(0.5))
		draw_circle(pc + Vector2(0, -s * 0.008), s * 0.07, ink)
