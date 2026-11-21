## Players for the sim: random, greedy, and strong (exact best play from the Solver).
## A policy is {name, draw: Callable(s) -> int, keep: Callable(s) -> int}: how many dice to draw, and which to keep (no cash out).
extends RefCounted

const Rules = preload("res://dice/rules.gd")


## Exact expected marks under best play. The state that matters is the row (sorted), the skulls and the bag.
class Solver:
	var cfg: Dictionary
	var memo := {}

	func _init(c: Dictionary) -> void:
		cfg = c

	## Expected marks with nothing waiting: a full row or empty bag is paid, otherwise you throw.
	func value(row: Array, skulls: int, bag: int) -> float:
		var r := row.duplicate()
		r.sort()
		var key := "%s|%d|%d" % [r, skulls, bag]
		if memo.has(key):
			return memo[key]
		var v := float(Rules.score(cfg, r).marks)
		if r.size() < int(cfg.row) and bag > 0:
			v = -1.0
			for n in range(1, mini(int(cfg.max_draw), bag) + 1):
				v = maxf(v, throw_value(r, skulls, bag, n))
		memo[key] = v
		return v

	## Expected marks of throwing n dice now, then playing on at best.
	func throw_value(row: Array, skulls: int, bag: int, n: int) -> float:
		n = mini(n, bag)
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

	## The best number of dice to draw now.
	func best_draw(s) -> int:
		var best := 1
		var bv := -1.0
		for n in Rules.draw_options(s):
			var v := throw_value(s.row, s.skulls, s.bag, n)
			if v > bv + 1e-12:
				bv = v
				best = n
		return best

	## The value of keeping each thrown die.
	func keep_values(s) -> Array:
		var out: Array = []
		for f in s.thrown:
			out.append(value(s.row + [f], s.skulls, s.bag + s.thrown.size() - 1))
		return out


static func strong_policy(cfg: Dictionary) -> Dictionary:
	var sol := Solver.new(cfg)
	return {"name": "strong", "solver": sol,
		"draw": func(s) -> int:
			return sol.best_draw(s),
		"keep": func(s) -> int:
			var vals: Array = sol.keep_values(s)
			return vals.find(vals.max())}


## The obvious rule: draw 3 with no skulls, 2 with one, 1 with two; keep the die that scores best now
## (ties: the face it already has most of, then the higher).
static func greedy_policy() -> Dictionary:
	return {"name": "greedy",
		"draw": func(s) -> int:
			return clampi(int(s.cfg.bust_at) - s.skulls, 1, int(s.cfg.max_draw)),
		"keep": func(s) -> int:
			var best := 0
			var best_key := -1
			for i in s.thrown.size():
				var f: int = s.thrown[i]
				var key: int = Rules.preview(s, i).marks * 100 + s.row.count(f) * 10 + f
				if key > best_key:
					best_key = key
					best = i
			return best}


static func random_policy(seed_value := 1) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return {"name": "random",
		"draw": func(s) -> int:
			return rng.randi_range(1, int(s.cfg.max_draw)),
		"keep": func(s) -> int:
			return rng.randi_range(0, s.thrown.size() - 1)}


## Plays a hand to the end. Returns {throws, marks, busted, dance}.
static func play(s, p: Dictionary) -> Dictionary:
	var dance := false
	var guard := 0
	while not s.over and guard < 100:
		guard += 1
		if s.thrown.size() > 1:
			Rules.keep(s, p.keep.call(s))
		else:
			dance = dance or Rules.is_dance(s)
			Rules.throw(s, p.draw.call(s))
	return {"throws": s.throws, "marks": s.marks, "busted": s.busted, "dance": dance}
