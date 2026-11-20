## Ways to play a hand, for the sim: random, greedy and strong.
extends RefCounted

const Rules = preload("res://hand/rules.gd")


## Any legal move; once the Target is met, stops 3 times in 10.
static func random_policy() -> Dictionary:
	return {
		"name": "random",
		"choose": func(_s, _faces, moves: Array, rng) -> Dictionary:
			return moves[rng.randi_range(0, moves.size() - 1)],
		"stop": func(s, rng) -> bool:
			return Rules.target_met(s) and rng.randi_range(1, 10) <= 3,
	}


## The highest die: into a threat about to strike that it stops, else the Target until met,
## else any prize it fits, else the Target. Stops as soon as the Target is met.
static func greedy_policy() -> Dictionary:
	return {
		"name": "greedy",
		"choose": func(s, faces: Array, moves: Array, _rng) -> Dictionary:
			return greedy_move(s, faces, moves),
		"stop": func(s, _rng) -> bool:
			return Rules.target_met(s),
	}


static func greedy_move(s, faces: Array, moves: Array) -> Dictionary:
	var best := 0
	for d in faces.size():
		if faces[d] > faces[best]:
			best = d
	var mine := moves.filter(func(m): return m.die == best)
	for m in mine:
		var slot: Dictionary = s.slots[m.slot]
		if slot.kind == "threat" and slot.countdown == 1:
			return m
	if not Rules.target_met(s):
		for m in mine:
			if s.slots[m.slot].kind == "target":
				return m
	for m in mine:
		if s.slots[m.slot].kind in ["pair", "sum", "reroll"]:
			return m
	for m in mine:
		if s.slots[m.slot].kind == "target":
			return m
	return moves[0]
