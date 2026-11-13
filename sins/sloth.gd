## Sloth, the Delayer. The safe player.
## T1 Lazy Bones (passive): the first Strike you roll each turn doesn't count.
## (Replaced Slow Drip, "+30/+50 for banking after one throw": 5% win; banking early doesn't pay under combos.)
## T2 Drag (Gambit): name an opponent; on their next turn each throw uses at most their dice - DRAG. Bot: the leader.
## (-1 die: 10.9%. -2: 12.2%. -3: 12.5%. Never below 1 die.)
extends "res://sins/sin.gd"

const DRAG := 3


func _init() -> void:
	sin_name = "Sloth"


func after_throw(game, me, turn) -> void:
	if turn.used_t1:
		return
	for i in turn.faces.size():
		if turn.faces[i] <= 2:
			if game.view:
				fired(game, me, "Lazy Bones", "ignores a Strike (%d)" % turn.faces[i])
			turn.faces[i] = 3  # treated as a blank: no points, no Strike
			turn.used_t1 = true
			return


func gambit(game, me, _bought: int) -> void:
	var target = await pick_target(game, me, "Drag (they throw %d fewer dice next turn)" % DRAG, game.leader_other(me))
	if target:
		await game.attack(me, target, "drag", DRAG)
