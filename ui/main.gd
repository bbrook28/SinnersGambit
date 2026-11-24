## The game's first screen: dice poker against the Master, the three lessons on first launch.
extends Control

const DiceScreen = preload("res://ui/dice_screen.gd")


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var d := DiceScreen.new()
	d.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(d)
