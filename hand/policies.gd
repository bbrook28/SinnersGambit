## Ways to play a hand, for the sim: random, greedy and strong.
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


## Tries every legal move (and every reroll) with `rollouts` greedy playouts each and takes the best mean marks.
## Stops when cashing out now beats the mean of throwing on. Records each choice's best and second-best value.
static func strong_policy(rollouts: int) -> Dictionary:
	return {
		"name": "strong",
		"choose": func(s, faces: Array, moves: Array, rng) -> Dictionary:
			return strong_move(s, faces, moves, rng, rollouts),
		"stop": func(s, rng) -> bool:
			return strong_stop(s, rng, rollouts),
	}


static func strong_move(s, faces: Array, moves: Array, rng, rollouts: int) -> Dictionary:
	var options: Array = moves.duplicate()
	if s.rerolls > 0:
		for d in faces.size():
			options.append({"reroll": d})
	var greedy := greedy_policy()
	var base: int = rng.randi_range(0, 1 << 30)
	var values: Array = []
	for opt in options:
		var total := 0
		for k in rollouts:
			rng = _playout_rng(base, k)  # every option's k-th playout sees the same dice
			var c = s.clone()
			if opt.has("reroll"):
				var f: Array[int] = Rules.reroll(c, faces, opt.reroll, rng)
				if not Rules.ended(c) and not f.is_empty():
					Rules.place(c, f, greedy_move(c, f, Rules.legal_moves(c, f)))
			else:
				Rules.place(c, faces, opt)
			if not Rules.ended(c):
				Play.play_from(c, greedy, rng, true)
			total += Rules.marks(c)
		values.append(float(total) / rollouts)
	var best := 0
	for i in values.size():
		if values[i] > values[best]:
			best = i
	var second := -INF
	for i in values.size():
		if i != best:
			second = maxf(second, values[i])
	if second == -INF:
		second = values[best]
	s.decisions.append({"best": values[best], "second": second, "moves": options.size()})
	return options[best]


static func strong_stop(s, rng, rollouts: int) -> bool:
	if not Rules.target_met(s):
		return false  # cashing out short pays nothing; throwing on never pays less
	var now = s.clone()
	Rules.cash_out(now)
	var greedy := greedy_policy()
	var base: int = rng.randi_range(0, 1 << 30)
	var total := 0
	for k in rollouts:
		var c = s.clone()
		Play.play_from(c, greedy, _playout_rng(base, k), false)
		total += Rules.marks(c)
	return float(Rules.marks(now)) >= float(total) / rollouts


static func _playout_rng(base: int, k: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = base * 1000 + k
	return r
