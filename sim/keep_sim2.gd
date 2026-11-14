## Keep-and-rethrow pre-screen from Phase 7 (RunDesign §11). Run: godot --headless --path . --script res://sim/keep_sim2.gd (a few minutes).
## Superseded by sim/run_sim.gd in Phase 8. Mult: a kept set of k adds k-1. Points: face x 5.
## Keepable: single 4/5/6, any set of 2+. Nothing keepable = bust.
## hot: "unlimited" (keeping all dice returns them), "once" (once a turn; after that, keeping all ends the turn: bank).
## Policies: "look" = one-step lookahead; "nerveX" = keep like look, throw while bust chance <= X.
## Decision = a throw point where the best two composite options (keep choice x throw/bank) are within 20%.
extends SceneTree

var rng := RandomNumberGenerator.new()
var K := 50
var hot := "unlimited"

func roll(dice: Array, idx: Array) -> Array:
	var out: Array = []
	for i in idx:
		var faces: Array = dice[i]
		out.append(faces[rng.randi_range(0, 5)])
	return out

## options: [pts, mult, used]
func options(faces: Array) -> Array:
	var counts := {}
	for f in faces:
		counts[f] = counts.get(f, 0) + 1
	var sets: Array = []
	var singles: Array = []
	for v in counts:
		var c: int = counts[v]
		if c >= 2:
			sets.append([v * 5 * c, c - 1, c])
		elif v >= 4:
			singles.append([v * 5, 0, 1])
	if sets.is_empty() and singles.is_empty():
		return []
	var opts: Array = []
	var ap := 0; var am := 0; var au := 0
	for g in sets + singles:
		ap += g[0]; am += g[1]; au += g[2]
	opts.append([ap, am, au])
	sets.sort_custom(func(a, b): return a[1] * 1000 + a[0] > b[1] * 1000 + b[0])
	singles.sort_custom(func(a, b): return a[0] > b[0])
	if not sets.is_empty():
		opts.append(sets[0])
		var sp := 0; var sm := 0; var su := 0
		for g in sets:
			sp += g[0]; sm += g[1]; su += g[2]
		if su != sets[0][2]:
			opts.append([sp, sm, su])
	if not singles.is_empty():
		if sets.is_empty() and singles.size() > 1:
			opts.append(singles[0])
		elif not sets.is_empty():
			opts.append(singles[0])
	return opts

## Dice left after keeping. Returns -1 when the turn must bank (all kept, return used up).
func after_keep(left: int, used: int, total: int, returned: bool) -> Array:
	if used < left:
		return [left - used, returned]
	if hot == "unlimited":
		return [total, returned]
	if hot == "once" and not returned:
		return [total, true]
	return [-1, returned]

func dice_count_idx(n: int, total: int) -> Array:
	var idx: Array = []
	# rethrow the last n dice (kept dice are the first ones); with plain-identical dice order doesn't matter much
	for i in range(total - n, total):
		idx.append(i)
	return idx

func best_now(dice: Array, n: int, p: int, m: int) -> float:
	var opts := options(roll(dice, dice_count_idx(n, dice.size())))
	var best := 0.0
	for o in opts:
		best = max(best, float((p + o[0]) * (m + o[1])))
	return best

func lookahead(dice: Array, n: int, p: int, m: int) -> float:
	if n < 0:
		return 0.0
	var ev := 0.0
	for k in K:
		ev += best_now(dice, n, p, m)
	return ev / K

func bust_chance(dice: Array, n: int) -> float:
	var b := 0
	for k in 80:
		if options(roll(dice, dice_count_idx(n, dice.size()))).is_empty():
			b += 1
	return b / 80.0

func turn(dice: Array, policy: String) -> Array:
	var total := dice.size()
	var left := total
	var returned := false
	var p := 0
	var m := 1
	var throws := 0
	var decisions := 0
	while throws < 40:
		var opts := options(roll(dice, dice_count_idx(left, total)))
		throws += 1
		if opts.is_empty():
			return [0, throws, throws == 1, decisions]
		var comp: Array = []  # [value, is_throw, opt_index]
		var keeps: Array = []
		for i in opts.size():
			var o: Array = opts[i]
			var np: int = p + o[0]
			var nm: int = m + o[1]
			var ak := after_keep(left, o[2], total, returned)
			var bank := float(np * nm)
			comp.append([bank, false, i])
			if ak[0] > 0:
				comp.append([lookahead(dice, ak[0], np, nm), true, i])
			keeps.append([np, nm, ak])
		comp.sort_custom(func(a, b): return a[0] > b[0])
		if comp.size() > 1 and comp[0][0] > 0 and (comp[0][0] - comp[1][0]) / comp[0][0] <= 0.2:
			decisions += 1
		var pick: Array = comp[0]
		var k: Array = keeps[pick[2]]
		var go: bool = pick[1]
		if policy.begins_with("nerve"):
			# keep the option with the best throw EV (or bank value if it can't throw), then throw on nerve
			var nerve := float(policy.substr(5)) / 100.0
			var best_i := 0
			var best_v := -1.0
			for c in comp:
				if c[1] and c[0] > best_v:
					best_v = c[0]; best_i = c[2]
			k = keeps[best_i]
			go = k[2][0] > 0 and bust_chance(dice, k[2][0]) <= nerve
			if best_v < 0:
				go = false
		p = k[0]
		m = k[1]
		if not go:
			return [p * m, throws, false, decisions]
		left = k[2][0]
		returned = k[2][1]
	return [p * m, throws, false, decisions]

func plain(n: int) -> Array:
	var d: Array = []
	for i in n:
		d.append([1, 2, 3, 4, 5, 6])
	return d

func strong(n: int) -> Array:
	# two faces repainted per die (the cap): 2 and 3 become 6
	var d: Array = []
	for i in n:
		d.append([1, 6, 6, 4, 5, 6])
	return d

func report(label: String, dice: Array, policy: String, n_turns: int) -> float:
	var tot := 0.0; var fb := 0; var dec := 0
	var ths: Array = []
	for r in n_turns:
		var res := turn(dice, policy)
		tot += res[0]; dec += res[3]; ths.append(res[1])
		if res[2]: fb += 1
	ths.sort()
	var tsum := 0
	for t in ths: tsum += t
	var avg := tot / n_turns
	print("%s [%s, hot %s]: turn %.0f, first bust %.1f%%, throws %.2f (p95 %d), decisions %.2f" % [label, policy, hot, avg, fb * 100.0 / n_turns, float(tsum) / n_turns, ths[int(n_turns * 0.95)], float(dec) / n_turns])
	return avg

func _init() -> void:
	rng.seed = 9
	var N := 600
	for h in ["unlimited", "once"]:
		hot = h
		for n in [5, 6, 7, 8]:
			report("plain %d dice" % n, plain(n), "look", N)
		for pol in ["look", "nerve10", "nerve25"]:
			report("STRONG 8 dice, 2 faces->6 each", strong(8), pol, N)
		report("plain 8 dice", plain(8), "nerve25", N)
	hot = "once"
	var base := report("6 dice", plain(6), "look", N)
	var one := plain(6); one[5] = [1, 6, 6, 4, 5, 6]
	var r := report("6 dice, one die with 2 faces->6", one, "look", N)
	print("ratio %.2f" % (r / base))
	quit()
