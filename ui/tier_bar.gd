## The Target's three tiers as a bar: how far your pips reach, each tier's live need and its marks.
extends Control

const Rules = preload("res://hand/rules.gd")

var s = null

const IVORY := Color("e8dcbc")
const GOLD := Color("d9a441")
const TRACK := Color("2a1f1a")
const FILL := Color("8c6a2f")


func show_hand(hand) -> void:
	s = hand
	custom_minimum_size = Vector2(0, 120)
	queue_redraw()


func _draw() -> void:
	if s == null:
		return
	var font := get_theme_default_font()
	var n := Rules.tiers(s)
	var top := maxi(1, Rules.tier_need(s, n))
	var marks := Rules._ints(s.cfg.tier_marks)
	var x0 := 20.0
	var w := size.x - 60.0
	var y := 18.0
	var h := 34.0
	draw_rect(Rect2(x0, y, w, h), TRACK)
	var frac := clampf(float(s.progress) / float(top), 0.0, 1.0)
	draw_rect(Rect2(x0, y, w * frac, h), FILL)
	for i in range(1, n + 1):
		var need := Rules.tier_need(s, i)
		var x := x0 + w * clampf(float(need) / float(top), 0.0, 1.0)
		var cleared: bool = s.progress >= need
		var c := GOLD if cleared else IVORY
		draw_rect(Rect2(x - 3, y - 8, 6, h + 16), c)
		var t1 := "Tier %d: %d" % [i, need]
		var t2 := "%d marks" % int(marks[i - 1])
		var fs := 28
		var tw := font.get_string_size(t1, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var tx := clampf(x - tw / 2.0, 0.0, size.x - tw)
		draw_string(font, Vector2(tx, y + h + 38), t1, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, c)
		var mw := font.get_string_size(t2, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, Vector2(clampf(x - mw / 2.0, 0.0, size.x - mw), y + h + 72), t2, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, c)
