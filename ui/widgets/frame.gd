## Manuscript page: parchment or dark vellum with an oxblood border, a gold inner rule and gilt corner studs.
extends PanelContainer

const Style = preload("res://ui/style.gd")

var light := false


func _init(p_light := false) -> void:
	light = p_light
	add_theme_stylebox_override("panel", Style.page(light))
	material = Style.grain(0.07 if light else 0.12)


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size).grow(-14)
	draw_rect(r, Style.C_GOLD_DEEP, false, 3.0)
	for c in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
		var pts := PackedVector2Array([c + Vector2(0, -12), c + Vector2(12, 0), c + Vector2(0, 12), c + Vector2(-12, 0)])
		draw_colored_polygon(pts, Style.C_GOLD)
		draw_polyline(pts + PackedVector2Array([pts[0]]), Style.C_INK, 2.0)
