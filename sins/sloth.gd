## Sloth, the Delayer. The safe player.
## T1 Lazy Bones (passive): the first Strike you roll each turn doesn't count.
## (Replaced Slow Drip, "+30/+50 for banking after one throw": 5% win; banking early doesn't pay under combos.)
## T2 Drag (Gambit): name an opponent; on their next turn each throw uses at most their dice - DRAG. Bot: the leader.
## (-1 die: 10.9%. -2: 12.2%. -3: 12.5%. Never below 1 die.)
extends "res://sins/sin.gd"

const Rules = preload("res://core/rules.gd")

const DRAG := 3


func _init() -> void:
	sin_name = "Sloth"


func after_throw(game, me, turn) -> void:
	if game.v5:
		return  # V5: Lazy Bones off; the power is Idle
	var allowed: int = game.opt("lazy", 1)  # Strikes ignored a turn (V4 tuning)
	if turn.used_t1 or turn.lazy_used >= allowed:
		return
	for i in turn.faces.size():
		if turn.faces[i] <= 2:
			if game.view:
				fired(game, me, "Lazy Bones", "ignores a Strike (%d)" % turn.faces[i])
			turn.faces[i] = 3  # treated as a blank: no points, no Strike
			turn.lazy_used += 1
			if turn.lazy_used >= allowed:
				turn.used_t1 = true
			if turn.lazy_used >= allowed or not game.v4:
				return


func gambit(game, me, _bought: int) -> void:
	var drag: int = game.opt("drag", DRAG)
	var target = await pick_target(game, me, "Drag (they throw %d fewer dice next turn)" % drag, game.leader_other(me))
	if target:
		await game.attack(me, target, "drag", drag)


# V5 power (Docs/TableDesign.md §10): this throw's Strikes don't count (they become 3s);
# idle_one (REPLY 17): the first becomes a 4 instead.
func power_window() -> String:
	return "throw"


func power_ready(_game, _me, turn) -> bool:
	return Rules.count_strikes(turn.faces) > 0


func use_power(game, me, turn, _choice) -> bool:
	var n := 0
	for i in turn.faces.size():
		if turn.faces[i] <= 2:
			turn.faces[i] = 4 if n == 0 and game.opt("idle_one", false) else 3
			n += 1
	if game.view:
		fired(game, me, "Idle", "ignores %d Strike%s" % [n, "" if n == 1 else "s"])
	return false
