## The game's first screen: the playable bag hand (greybox), the guided tutorial on first launch.
extends Control

const HandScreen = preload("res://ui/hand_screen.gd")


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var h := HandScreen.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(h)
