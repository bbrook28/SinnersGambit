## Dice poker against the plan's pass marks (docs/superpowers/plans/2026-11-20-dice-poker.md); no cash out, so the keep is the only choice.
## The 5-7 throws mark is dropped: a five-die row caps a hand near 5 throws (Ben, 2026-11-20).
## godot --headless --path . --script res://sim/dice_sim.gd -- [hands=20000] [seed=4] [key=value ...]
## Any dice/config.gd key can be overridden. Writes the report to stdout and build/sim/dice_<seed>.txt.
extends SceneTree

const Config = preload("res://dice/config.gd")
const Rules = preload("res://dice/rules.gd")
const Policies = preload("res://dice/policies.gd")

const CLOSE := 0.15   # a decision is close when its best two options are within this many marks (not exact ties)

var _lines: Array = []


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
	var strong := Policies.strong_policy(cfg)
	var r := _run(cfg, Policies.random_policy(seed_value), hands, seed_value, null)
	var g := _run(cfg, Policies.greedy_policy(), hands, seed_value, null)
	var st := _run(cfg, strong, hands, seed_value, strong.solver)
	for res in [r, g, st]:
		_report(res)
	say("best play is worth %.3f marks a hand from the first throw" % strong.solver.value([], 0, int(cfg.bag)))
	say("strong's decisions: keeps with two different dice %d, close %.1f%%, a wrong keep costs >= 0.25 marks in %.1f%%" % [
		st.keeps, 100.0 * st.close_keeps / maxi(st.keeps, 1), 100.0 * st.costly_keeps / maxi(st.keeps, 1)])
	say("  within 0.5 marks: %.1f%% of keeps" % (100.0 * st.near_keeps / maxi(st.keeps, 1)))
	say("verdict:")
	var gap := _paired(st.marks_each, g.marks_each)
	var rel: float = gap[0] / maxf(g.marks, 0.001)
	say("same %d hands, strong minus greedy: %+.3f marks a hand (95%%: %+.3f to %+.3f), %+.0f%%" % [
		hands, gap[0], gap[0] - gap[1], gap[0] + gap[1], 100.0 * rel])
	_verdict("strong earns >= 15% more marks than greedy, interval above zero", rel >= 0.15 and gap[0] - gap[1] > 0.0, "%+.0f%%" % (100.0 * rel))
	_verdict("greedy earns more than random", g.marks > r.marks, "%.3f vs %.3f" % [g.marks, r.marks])
	_verdict("strong busts in 20-30% of hands", st.bust >= 20.0 and st.bust <= 30.0, "%.1f%%" % st.bust)
	_verdict("strong reaches the Last Dance in 15-30% of hands", st.dance >= 15.0 and st.dance <= 30.0, "%.1f%%" % st.dance)
	var keys: Array = cfg.keys()
	say("config: hands=%d seed=%d %s" % [hands, seed_value, " ".join(keys.map(func(k): return "%s=%s" % [k, cfg[k]]))])
	say("run time %.1f s" % ((Time.get_ticks_msec() - t0) / 1000.0))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/sim"))
	var f := FileAccess.open("res://build/sim/dice_%d.txt" % seed_value, FileAccess.WRITE)
	f.store_string("\n".join(_lines) + "\n")
	quit()


func _run(cfg: Dictionary, p: Dictionary, hands: int, seed_value: int, sol) -> Dictionary:
	var res := {"name": p.name, "hands": hands, "marks_each": [], "hand_counts": {}, "keeps": 0, "close_keeps": 0,
		"costly_keeps": 0, "near_keeps": 0}
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
				if sol != null and s.thrown[0] != s.thrown[1]:
					var vals: Array = sol.keep_values(s)
					var d: float = absf(vals[0] - vals[1])
					res.keeps += 1
					if d > 1e-9 and d < CLOSE:
						res.close_keeps += 1
					if d > 1e-9 and d < 0.5:
						res.near_keeps += 1
					if d >= 0.25:
						res.costly_keeps += 1
				Rules.keep(s, p.keep.call(s))
				continue
			dance = dance or Rules.is_dance(s)
			Rules.throw(s)
		marks += s.marks
		res.marks_each.append(float(s.marks))
		throws += s.throws
		if s.busted:
			busts += 1
		else:
			var nm: String = Rules.score(cfg, s.row).name
			res.hand_counts[nm] = res.hand_counts.get(nm, 0) + 1
		if dance:
			dances += 1
	res.marks = float(marks) / hands
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
