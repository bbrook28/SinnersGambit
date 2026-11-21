## Players for the sim: random, greedy, and strong (exact best play from the Solver).
## A policy is {name, keep: Callable(s) -> int, stop: Callable(s) -> bool}.
extends RefCounted

const Rules = preload("res://dice/rules.gd")


## Exact expected marks under best play. The state that matters is the row (sorted), the skulls and the bag.
class Solver:
	var cfg: Dictionary
	var memo := {}

	func _init(c: Dictionary) -> void:
		cfg = c

	## Best value with nothing waiting: the better of cashing out and throwing.
	func value(row: Array, skulls: int, bag: int) -> float:
		var r := row.duplicate()
		r.sort()
		var key := "%s|%d|%d" % [r, skulls, bag]
		if memo.has(key):
			return memo[key]
		var cash := float(Rules.score(cfg, r).marks)
		var v := cash
		if r.size() < int(cfg.row) and bag > 0:
			v = maxf(cash, throw_value(r, skulls, bag))
		memo[key] = v
		return v

	func cash_value(row: Array) -> float:
		return float(Rules.score(cfg, row).marks)

	## Expected value of throwing now, then playing on at best.
	func throw_value(row: Array, skulls: int, bag: int) -> float:
		var n := mini(int(cfg.draw), bag)
		var dance := bag == 1
		var total := 0.0
		var combos := int(pow(6, n))
		for c in combos:
			var x := c
			var pips: Array = []
			var k := 0
			for i in n:
				var f := x % 6 + 1
				x /= 6
				if f <= int(cfg.skull_faces):
					k += 1
				else:
					pips.append(f)
			var sk := skulls + k
			if sk >= int(cfg.bust_at) or (dance and k > 0):
				total -= float(cfg.get("stake", 0))
				continue
			if dance:
				total += value(row + [0], sk, 0)
			elif pips.is_empty():
				total += value(row, sk, bag - n)
			else:
				var best := -1.0
				for f in pips:
					best = maxf(best, value(row + [f], sk, bag - k - 1))
				total += best
		return total / combos

	## The value of keeping each thrown die.
	func keep_values(s) -> Array:
		var out: Array = []
		for f in s.thrown:
			out.append(value(s.row + [f], s.skulls, s.bag + s.thrown.size() - 1))
		return out


static func strong_policy(cfg: Dictionary) -> Dictionary:
	var sol := Solver.new(cfg)
	return {"name": "strong", "solver": sol,
		"keep": func(s) -> int:
			var vals: Array = sol.keep_values(s)
			return vals.find(vals.max()),
		"stop": func(s) -> bool:
			return sol.throw_value(s.row, s.skulls, s.bag) <= sol.cash_value(s.row) + 1e-9}


## Keeps the die that scores best now (ties: the face it already has most of, then the higher); cashes out at a pair.
static func greedy_policy() -> Dictionary:
	return {"name": "greedy",
		"keep": func(s) -> int:
			var best := 0
			var best_key := -1
			for i in s.thrown.size():
				var f: int = s.thrown[i]
				var key: int = Rules.preview(s, i).marks * 100 + s.row.count(f) * 10 + f
				if key > best_key:
					best_key = key
					best = i
			return best,
		"stop": func(s) -> bool:
			return Rules.score(s.cfg, s.row).marks >= 1}


static func random_policy(seed_value := 1) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return {"name": "random",
		"keep": func(s) -> int:
			return rng.randi_range(0, s.thrown.size() - 1),
		"stop": func(s) -> bool:
			return not s.row.is_empty() and rng.randf() < 0.3}


## Plays a hand to the end. Returns {throws, marks, busted, dance}.
static func play(s, p: Dictionary) -> Dictionary:
	var dance := false
	var guard := 0
	while not s.over and guard < 100:
		guard += 1
		if s.thrown.size() > 1:
			Rules.keep(s, p.keep.call(s))
		elif Rules.can_throw(s) and (s.row.is_empty() or not p.stop.call(s)):
			dance = dance or Rules.is_dance(s)
			Rules.throw(s)
		else:
			Rules.cash_out(s)
	return {"throws": s.throws, "marks": s.marks, "busted": s.busted, "dance": dance}
