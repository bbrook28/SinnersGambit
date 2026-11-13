## Sloth, the Delayer. The safe player.
## T1 Lazy Bones (passive): the first Strike you roll each turn doesn't count.
## (Replaced Slow Drip, "+30/+50 for banking after one throw": 5% win; banking early doesn't pay under combos.)
extends "res://sins/sin.gd"


func _init() -> void:
	sin_name = "Sloth"


func after_throw(_game, _me, turn) -> void:
	if turn.used_t1:
		return
	for i in turn.faces.size():
		if turn.faces[i] <= 2:
			turn.faces[i] = 3  # treated as a blank: no points, no Strike
			turn.used_t1 = true
			return
