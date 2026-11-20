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


## Tries every distinct legal move with `rollouts` push-policy playouts each and takes the best mean marks.
## Stops when cashing out now beats the mean of throwing on. Records each choice's best and second-best value.
static func strong_policy(rollouts: int) -> Dictionary:
	return {
		"name": "strong",
		"choose": func(s, faces: Array, moves: Array, rng) -> Dictionary:
			return strong_move(s, faces, moves, rng, rollouts),
		"stop": func(s, rng) -> bool:
			return strong_stop(s, rng, rollouts),
	}


## The strong policy's playouts: finishes a half-filled engine slot or prize when a die completes it, else greedy.
## (Seeding rules made the playouts, and so strong, worse than greedy: probe 2026-11-20, ledger Task 5.)
## Once the Target is met, throws on only while the prize is one die from claimed and one more skull won't bust.
static func push_policy() -> Dictionary:
	return {
		"name": "push",
		"choose": func(s, faces: Array, moves: Array, _rng) -> Dictionary:
			return push_move(s, faces, moves),
		"stop": func(s, _rng) -> bool:
			return Rules.target_met(s) and (not _prize_half(s) or s.skulls >= int(s.cfg.bust_at) - 1),
	}


static func push_move(s, faces: Array, moves: Array) -> Dictionary:
	for m in moves:
		var slot: Dictionary = s.slots[m.slot]
		if slot.kind in ["ward", "ladder", "pair", "sum"] and slot.dice.size() == int(slot.cap) - 1:
			return m
	return greedy_move(s, faces, moves)


## The prize is face up and one die from claimed.
static func _prize_half(s) -> bool:
	return s.slots.any(func(x): return x.kind in ["pair", "sum"] and not x.hidden and not x.done and x.dice.size() == int(x.cap) - 1)


static func strong_move(s, faces: Array, moves: Array, rng, rollouts: int) -> Dictionary:
	# One option per distinct (die worth, slot), the held die apart: two dice of one face are the same choice.
	var options: Array = []
	var seen := {}
	for m in moves:
		var key := "%s%d|%d" % ["h" if m.die < 0 else "", face_of(s, faces, m), m.slot]
		if not seen.has(key):
			seen[key] = true
			options.append(m)
	var push := push_policy()
	var base: int = rng.randi_range(0, 1 << 30)
	var typed: Array[int] = []
	typed.assign(faces)
	var values: Array = []
	for opt in options:
		var total := 0
		for k in rollouts:
			var c = s.clone()
			Rules.place(c, typed, opt)
			Play.play_from(c, push, _playout_rng(base, k), true)  # every option's k-th playout sees the same dice
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
	s.decisions.append({"best": values[best], "second": second, "moves": options.size(), "met": Rules.target_met(s)})
	return options[best]


static func strong_stop(s, rng, rollouts: int) -> bool:
	if not Rules.target_met(s):
		return false  # cashing out short pays nothing; throwing on never pays less
	var now = s.clone()
	Rules.cash_out(now)
	var push := push_policy()
	var base: int = rng.randi_range(0, 1 << 30)
	var total := 0
	for k in rollouts:
		var c = s.clone()
		Play.play_from(c, push, _playout_rng(base, k), false)
		total += Rules.marks(c)
	return float(Rules.marks(now)) >= float(total) / rollouts


static func _playout_rng(base: int, k: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = base * 1000 + k
	return r
