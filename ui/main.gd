## The game's first screen: step 1, four players passing one phone (ui/table_screen.gd).
## Dice poker (ui/dice_screen.gd) stays in the repo, unused.
extends Control

const TableScreen = preload("res://ui/table_screen.gd")


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var t := TableScreen.new()
	t.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(t)
