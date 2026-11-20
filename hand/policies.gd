## Ways to play a bag hand, for the sim: random, greedy, push and strong.
extends RefCounted

const Rules = preload("res://hand/rules.gd")
const Play = preload("res://hand/play.gd")


## Any legal move; once the Target is met, stops 3 times in 10.
static func random_policy() -> Dictionary:
	return {
		"name": "random",
		"choose": func(_s, _faces, moves: Array, rng) -> Dictionary:
			return moves[rng.randi_range(0, moves.size() - 1)],
		"stop": func(s, rng) -> bool:
			return Rules.target_met(s) and rng.randi_range(1, 10) <= 3,
	}


## The baseline: the highest die (the held one too) into the Target; stops as soon as the Target is met.
static func greedy_policy() -> Dictionary:
	return {
		"name": "greedy",
		"choose": func(s, faces: Array, moves: Array, _rng) -> Dictionary:
			return greedy_move(s, faces, moves),
		"stop": func(s, _rng) -> bool:
			return Rules.target_met(s),
	}


## The worth of a move's die: the thrown face, or the held one.
static func face_of(s, faces: Array, m: Dictionary) -> int:
	return Rules.held(s) if m.die < 0 else int(faces[m.die])


static func greedy_move(s, faces: Array, moves: Array) -> Dictionary:
	var best := {}
	var best_v := -1
	for m in moves:
		if s.slots[m.slot].kind == "target":
			var v := Rules.value(s, face_of(s, faces, m), m.die < 0)
			if v > best_v:
				best_v = v
				best = m
	if best.is_empty():
		for m in moves:
			if s.slots[m.slot].kind == "offering":
				return m
		return moves[0]
	return best
