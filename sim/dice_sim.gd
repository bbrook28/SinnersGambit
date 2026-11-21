## Dice poker against the plans' pass marks (docs/superpowers/plans/2026-11-20-dice-poker.md, and 2026-11-21-sin-demand.md
## when a Sin demands: demand=pride|envy|wrath); no cash out; you choose to draw 1-3 dice.
## greedy is the obvious rule (draw 3 with no skulls, 2 with one, 1 with two; keep what scores best now).
## The 5-7 throws mark is dropped: a five-die row caps a hand near 5 throws (Ben, 2026-11-20).
## godot --headless --path . --script res://sim/dice_sim.gd -- [hands=20000] [seed=4] [key=value ...]
## Any dice/config.gd key can be overridden. Writes the report to stdout and build/sim/dice_<seed>.txt (dice_<seed>_<sin>.txt with a demand).
extends SceneTree

const Config = preload("res://dice/config.gd")
const Rules = preload("res://dice/rules.gd")
const Policies = preload("res://dice/policies.gd")
const Demands = preload("res://dice/demands.gd")

const CLOSE := 0.15   # a decision is close when its best two options are within this many marks (not exact ties)

var _lines: Array = []
var _plain    # the solver for the same hand with no Sin, and
var _alone    # the solver for the Sin alone: together they say when a keep is a question


func say(text: String) -> void:
	print(text)
	_lines.append(text)


func _init() -> void:
	var hands := 20000
	var seed_value := 4
	var overrides := {}
	for a in OS.get_cmdline_user_args():
		if not "=" in a:
			continue
		var k: String = a.get_slice("=", 0)
		var v: String = a.substr(k.length() + 1)
		match k:
			"hands":
				hands = int(v)
			"seed":
				seed_value = int(v)
			_:
				if not Config.DEFAULTS.has(k):
					printerr("dice_sim: unknown key %s" % k)
					quit(1)
					return
				overrides[k] = v if Config.DEFAULTS[k] is String else str_to_var(v)
	var cfg := Config.merged(overrides)
	var t0 := Time.get_ticks_msec()
	var strong := Policies.strong_policy(cfg)  # exact best play
	if not Demands.of(cfg).is_empty():
		var bare: Dictionary = cfg.duplicate()
		bare.demand = ""
		_plain = Policies.Solver.new(bare)
		_alone = Policies.Solver.new(cfg, true)
	var r := _run(cfg, Policies.random_policy(seed_value), hands, seed_value, null)
	var g := _run(cfg, Policies.greedy_policy(), hands, seed_value, null)
	var st := _run(cfg, strong, hands, seed_value, strong.solver)
	for res in [r, g, st]:
		_report(res)
	say("best play is worth %.3f marks a hand from the first throw" % strong.solver.value([], 0, int(cfg.bag)))
	say("strong's decisions: keeps with different dice %d, close %.1f%%, a wrong keep costs >= 0.25 marks in %.1f%%" % [
		st.keeps, 100.0 * st.close_keeps / maxi(st.keeps, 1), 100.0 * st.costly_keeps / maxi(st.keeps, 1)])
	say("  within 0.5 marks: %.1f%% of keeps" % (100.0 * st.near_keeps / maxi(st.keeps, 1)))
	var same: float = 100.0 * st.same_keeps / maxi(st.keeps, 1)
	var costly: float = 100.0 * st.costly_keeps / maxi(st.keeps, 1)
	say("  the best two different faces are worth the same in %.1f%% of keeps" % same)
	say("  strong's marks: %.2f from the hand, %.2f from the Sin" % [st.poker, st.sin])
	var choice: float = float(st.keeps) / hands
	var asked: float = float(st.asked) / hands
	var hand_wins: float = 100.0 * st.hand_wins / maxi(st.asked, 1)
	say("  choice keeps (two or more different faces thrown): %.2f a hand" % choice)
	if _plain != null:
		say("  questions asked (no die is best for both the hand alone and the Sin alone): %.2f a hand; the hand wins %.0f%%, the Sin %.0f%%" % [
			asked, hand_wins, 100.0 - hand_wins])
	var d2: Dictionary = st.draws_at_two
	var t2: int = maxi(d2.get(1, 0) + d2.get(2, 0) + d2.get(3, 0), 1)
	var two: float = 100.0 * d2.get(2, 0) / t2
	say("  with two skulls showing strong draws: 1 die %.0f%%, 2 dice %.0f%%, 3 dice %.0f%%" % [100.0 * d2.get(1, 0) / t2, two, 100.0 * d2.get(3, 0) / t2])
	say("verdict:")
	var gap := _paired(st.marks_each, g.marks_each)
	var rel: float = gap[0] / maxf(g.marks, 0.001)
	say("same %d hands, strong minus greedy: %+.3f marks a hand (95%%: %+.3f to %+.3f), %+.0f%%" % [
		hands, gap[0], gap[0] - gap[1], gap[0] + gap[1], 100.0 * rel])
	var demand: Dictionary = Demands.of(cfg)
	if demand.is_empty():
		_verdict("strong earns >= 15% more marks than greedy, interval above zero", rel >= 0.15 and gap[0] - gap[1] > 0.0, "%+.0f%%" % (100.0 * rel))
	else:
		say("  (not judged, by the second revision of the pitch: strong against greedy, coin-flip keeps %.1f%%, costly keeps %.1f%%, busts)" % [same, costly])
		_verdict("the Sin asks 0.4 questions a hand or more", asked >= 0.4, "%.2f" % asked)
		_verdict("neither side wins more than 70% of them", hand_wins <= 70.0 and hand_wins >= 30.0, "the hand %.0f%%" % hand_wins)
		_verdict("choice keeps do not fall below 2.33 a hand", choice >= 2.33, "%.2f" % choice)
		_verdict("the Sin pays less than the hand", st.sin < st.poker, "%.2f vs %.2f" % [st.sin, st.poker])
		if int(demand.danger) > 0:
			say("  with two skulls showing strong draws two dice in %.0f%% of throws" % two)
	_verdict("greedy earns more than random", g.marks > r.marks, "%.3f vs %.3f" % [g.marks, r.marks])
	if demand.is_empty():
		_verdict("strong busts in 20-30% of hands", st.bust >= 20.0 and st.bust <= 30.0, "%.1f%%" % st.bust)
	else:
		say("  strong busts in %.1f%% of hands (not judged under a Sin)" % st.bust)
	_verdict("strong reaches the Last Dance in 15-30% of hands", st.dance >= 15.0 and st.dance <= 30.0, "%.1f%%" % st.dance)
	var keys: Array = cfg.keys()
	say("config: hands=%d seed=%d %s" % [hands, seed_value, " ".join(keys.map(func(k): return "%s=%s" % [k, cfg[k]]))])
	say("run time %.1f s" % ((Time.get_ticks_msec() - t0) / 1000.0))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/sim"))
	var tag: String = "" if str(cfg.demand) == "" else "_" + str(cfg.demand)
	var f := FileAccess.open("res://build/sim/dice_%d%s.txt" % [seed_value, tag], FileAccess.WRITE)
	f.store_string("\n".join(_lines) + "\n")
	quit()


func _run(cfg: Dictionary, p: Dictionary, hands: int, seed_value: int, sol) -> Dictionary:
	var res := {"name": p.name, "hands": hands, "marks_each": [], "hand_counts": {}, "keeps": 0, "close_keeps": 0,
		"costly_keeps": 0, "near_keeps": 0, "same_keeps": 0, "draws": {}, "draws_at_two": {},
		"asked": 0, "hand_wins": 0}
	var poker := 0
	var sin := 0
	var marks := 0
	var busts := 0
	var throws := 0
	var dances := 0
	var rng := RandomNumberGenerator.new()
	for i in hands:
		rng.seed = hash(seed_value * 1000003 + i)
		var s = Rules.new_hand(cfg, rng)
		var dance := false
		while not s.over:
			if s.thrown.size() > 1:
				var uniq := {}
				for f in s.thrown:
					uniq[f] = true
				if sol != null and uniq.size() > 1:
					var all: Array = sol.keep_values(s)
					var by_face := {}
					for j in s.thrown.size():
						by_face[s.thrown[j]] = all[j]
					var vals: Array = by_face.values()   # one value a face: two 4s are not a choice
					vals.sort()
					var d: float = vals[-1] - vals[-2]
					res.keeps += 1
					if d <= 1e-9:
						res.same_keeps += 1
					if _plain != null:
						# a question: no thrown face is best for both the hand alone and the Sin alone
						var bag2: int = s.bag + s.thrown.size() - 1
						var for_hand := {}
						var for_sin := {}
						var best_hand := -1e9
						var best_sin := -1e9
						var best_all := -1e9
						var kept := 0
						for f in by_face:
							for_hand[f] = snappedf(_plain.value(s.row + [f], s.skulls, bag2, 0), 1e-9)
							for_sin[f] = snappedf(_alone.value(s.row + [f], s.skulls, bag2, s.bank), 1e-9)
							best_hand = maxf(best_hand, for_hand[f])
							best_sin = maxf(best_sin, for_sin[f])
							if by_face[f] > best_all:
								best_all = by_face[f]
								kept = f
						var shared := false
						for f in by_face:
							shared = shared or (for_hand[f] == best_hand and for_sin[f] == best_sin)
						if not shared:
							res.asked += 1
							if for_hand[kept] == best_hand:
								res.hand_wins += 1
					if d > 1e-9 and d < CLOSE:
						res.close_keeps += 1
					if d > 1e-9 and d < 0.5:
						res.near_keeps += 1
					if d >= 0.25:
						res.costly_keeps += 1
				Rules.keep(s, p.keep.call(s))
				continue
			dance = dance or Rules.is_dance(s)
			var nd: int = p.draw.call(s)
			res.draws[nd] = res.draws.get(nd, 0) + 1
			if s.skulls == 2 and not Rules.is_dance(s):
				res.draws_at_two[nd] = res.draws_at_two.get(nd, 0) + 1
			Rules.throw(s, nd)
		marks += s.marks
		res.marks_each.append(float(s.marks))
		throws += s.throws
		if s.busted:
			busts += 1
		else:
			var paid: Dictionary = Rules.total(cfg, s.row, s.bank)
			poker += paid.marks
			sin += paid.sin
			var nm: String = paid.name
			res.hand_counts[nm] = res.hand_counts.get(nm, 0) + 1
		if dance:
			dances += 1
	res.marks = float(marks) / hands
	res.poker = float(poker) / hands
	res.sin = float(sin) / hands
	res.bust = 100.0 * busts / hands
	res.throws = float(throws) / hands
	res.dance = 100.0 * dances / hands
	return res


func _report(res: Dictionary) -> void:
	say("%s: %.3f marks a hand, busts %.1f%%, %.2f throws, Last Dance %.1f%%" % [res.name, res.marks, res.bust, res.throws, res.dance])
	var parts: Array = []
	for h in Rules.HANDS:
		if res.hand_counts.has(h):
			parts.append("%s %.1f%%" % [h, 100.0 * res.hand_counts[h] / res.hands])
	say("  cashed: " + ", ".join(parts))
	var dp: Array = []
	var tot := 0
	for k in res.draws:
		tot += res.draws[k]
	for k in [1, 2, 3]:
		dp.append("%d dice %.0f%%" % [k, 100.0 * res.draws.get(k, 0) / maxi(tot, 1)])
	say("  draws: " + ", ".join(dp))


## Mean of a - b over the same hands, and its 95% half-width.
func _paired(a: Array, b: Array) -> Array:
	var n := a.size()
	var sum := 0.0
	var sq := 0.0
	for i in n:
		var d: float = a[i] - b[i]
		sum += d
		sq += d * d
	var mean := sum / n
	var sd := sqrt(maxf(sq / n - mean * mean, 0.0))
	return [mean, 1.96 * sd / sqrt(n)]


func _verdict(what: String, ok: bool, number: String) -> void:
	say("  %s %s (%s)" % ["PASS" if ok else "MISS", what, number])
