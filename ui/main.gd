## Placeholder for the restart: the seven glass windows and the two fonts, nothing else.
## The old game is at the tag archive/sinners-gambit-v1.
extends Control

const SINS := ["wrath", "greed", "lust", "envy", "pride", "gluttony", "sloth"]
const BLACKLETTER := preload("res://assets/fonts/PirataOne-Regular.ttf")
const SERIF := preload("res://assets/fonts/IMFellEnglish-Regular.ttf")


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("120c0a")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 40)
	add_child(v)
	v.add_child(_label("Sinners' Gambit", BLACKLETTER, 140))
	var row := HFlowContainer.new()
	row.alignment = FlowContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("h_separation", 20)
	row.add_theme_constant_override("v_separation", 20)
	v.add_child(row)
	for s in SINS:
		var t := TextureRect.new()
		t.texture = load("res://assets/art/runtime/sins/%s.png" % s)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.custom_minimum_size = Vector2(220, 520)
		row.add_child(t)
	v.add_child(_label("A clean slate.", SERIF, 48))


func _label(text: String, font: Font, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color("e8dcbc"))
	return l
