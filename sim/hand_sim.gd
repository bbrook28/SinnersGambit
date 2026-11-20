## The bag hand against the design's pass marks (docs/superpowers/specs/2026-11-20-bag-hand-design.md,
## pass marks from 2026-11-20-core-hand-design.md).
## godot --headless --path . --script res://sim/hand_sim.gd -- [hands=2000] [strong_hands=500] [seed=1] [key=value ...]
## Any hand/config.gd key can be overridden. Writes the report to stdout and build/sim/hand_<seed>.txt.
extends SceneTree

const Config = preload("res://hand/config.gd")
const Rules = preload("res://hand/rules.gd")
const Play = preload("res://hand/play.gd")
const Policies = preload("res://hand/policies.gd")

var _lines: Array = []


func say(text: String) -> void:
	print(text)
	_lines.append(text)


func _init() -> void:
	var hands := 2000
	var strong_hands := 500
	var seed_value := 1
	var overrides := {}
	for a in OS.get_cmdline_user_args():
		if not "=" in a:
			continue
		var k: String = a.get_slice("=", 0)
		var v: String = a.substr(k.length() + 1)
		match k:
			"hands":
				hands = int(v)
			"strong_hands":
				strong_hands = int(v)
			"seed":
				seed_value = int(v)
			_:
				if not Config.DEFAULTS.has(k):
					printerr("hand_sim: unknown key %s" % k)
					quit(1)
					return
				overrides[k] = v if Config.DEFAULTS[k] is String else str_to_var(v)
	var cfg := Config.merged(overrides)
	var t0 := Time.get_ticks_msec()
	var r := _run(cfg, Policies.random_policy(), hands, seed_value)
	var g := _run(cfg, Policies.greedy_policy(), hands, seed_value)
	var st := _run(cfg, Policies.strong_policy(int(cfg.rollouts)), strong_hands, seed_value)
	for res in [r, g, st]:
		_report(res)
	say("verdict:")
	var gap_won := _paired(st.won_each, g.won_each)
	var gap_marks := _paired(st.marks_each, g.marks_each)
	say("same %d hands, strong minus greedy: win rate %+.1f points (95%%: %+.1f to %+.1f), marks %+.2f a hand (95%%: %+.2f to %+.2f)" % [
		st.hands, 100.0 * gap_won[0], 100.0 * (gap_won[0] - gap_won[1]), 100.0 * (gap_won[0] + gap_won[1]),
		gap_marks[0], gap_marks[0] - gap_marks[1], gap_marks[0] + gap_marks[1]])
	_verdict("strong win rate beats greedy by >= 10 points (same hands)", 100.0 * gap_won[0] >= 10.0, "%+.1f" % (100.0 * gap_won[0]))
	_verdict("greedy wins more than random", g.won > r.won, "%.1f vs %.1f" % [g.won, r.won])
	_verdict("agony >= 30% of strong's decisions (near-ties, not exact ties)", st.agony >= 30.0, "%.1f%%" % st.agony)
	_verdict("strong busts in 20-35% of hands", st.bust >= 20.0 and st.bust <= 35.0, "%.1f%%" % st.bust)
	_verdict("strong reaches the Last Dance in 15-30%", st.dance >= 15.0 and st.dance <= 30.0, "%.1f%%" % st.dance)
	_verdict("strong throws 6-7 a hand", st.throws >= 6.0 and st.throws <= 7.0, "%.2f" % st.throws)
	var keys: Array = cfg.keys()
	say("config: hands=%d strong_hands=%d seed=%d %s" % [hands, strong_hands, seed_value,
		" ".join(keys.map(func(k): return "%s=%s" % [k, cfg[k]]))])
	say("run time %.1f s" % ((Time.get_ticks_msec() - t0) / 1000.0))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/sim"))
	var f := FileAccess.open("res://build/sim/hand_%d.txt" % seed_value, FileAccess.WRITE)
	f.store_string("\n".join(_lines) + "\n")
	quit()


func _run(cfg: Dictionary, policy: Dictionary, hands: int, seed_value: int) -> Dictionary:
	var n := {"won": 0, "short": 0, "bust": 0}
	var dance := 0
	var survived := 0
	var marks := 0
	var throws := 0
	var decisions := 0
	var close := 0
	var ties := 0
	var past := 0
	var early := 0
	var early_marks := 0
	var no_dance := 0
	var cancelled := 0
	var curse := 0
	var dealt := {}   # engine kind or wire kind -> hands dealt
	var used := {}    # engine kind -> hands filled at least once; wire kind -> hands it fired
	var won_each: Array = []
	var marks_each: Array = []
	for i in hands:
		var s = Play.play_hand(cfg, policy, Play.hand_rng(seed_value, i))
		won_each.append(1.0 if s.outcome == "won" else 0.0)
		marks_each.append(float(Rules.marks(s)))
		if s.decisions.any(func(d): return d.met):
			past += 1
		n[s.outcome] += 1
		if s.outcome != "bust" and s.bag > 0 and s.throws <= 3:
			early += 1
			early_marks += Rules.marks(s)
		if s.bag <= 0 and not s.dance_reached:
			no_dance += 1
		cancelled += s.cancelled
		curse += s.curse_skulls
		for slot in s.slots:
			if slot.kind in Rules.ENGINES:
				dealt[slot.kind] = dealt.get(slot.kind, 0) + 1
				if slot.fills > 0:
					used[slot.kind] = used.get(slot.kind, 0) + 1
		for w in s.wires:
			dealt[w.kind] = dealt.get(w.kind, 0) + 1
			var fired: bool = {"tax": s.tax_on, "hunger": s.hunger_on, "curse": s.curse_skulls > 0}.get(w.kind, false)
			if fired:
				used[w.kind] = used.get(w.kind, 0) + 1
		if s.dance_reached:
			dance += 1
			if s.outcome != "bust":
				survived += 1
		marks += Rules.marks(s)
		throws += s.throws
		for d in s.decisions:
			if d.moves >= 2 and d.best > 0.0:
				decisions += 1
				if d.best == d.second:
					ties += 1
				elif d.best - d.second <= 0.05 * d.best:
					close += 1
	var pct := func(x: int) -> float: return 100.0 * x / maxi(1, hands)
	return {"name": policy.name, "hands": hands, "won": pct.call(n.won), "short": pct.call(n.short),
		"bust": pct.call(n.bust), "dance": pct.call(dance), "survived": 100.0 * survived / maxi(1, dance),
		"marks": float(marks) / hands, "throws": float(throws) / hands,
		"agony": 100.0 * close / maxi(1, decisions), "ties": 100.0 * ties / maxi(1, decisions),
		"decisions": decisions, "past": pct.call(past), "won_each": won_each, "marks_each": marks_each,
		"early": pct.call(early), "early_marks": float(early_marks) / maxi(1, early), "no_dance": pct.call(no_dance),
		"cancelled": float(cancelled) / maxi(1, hands), "curse": float(curse) / maxi(1, hands),
		"pieces": " ".join(["hold", "ward", "ladder", "tax", "hunger", "curse"].map(func(k):
			return "%s %d%%/%d" % [k, 100 * used.get(k, 0) / maxi(1, dealt.get(k, 0)), dealt.get(k, 0)]))}


## Mean and 95% half-width of a[i] - b[i] over the hands both played.
func _paired(a: Array, b: Array) -> Array:
	var n := mini(a.size(), b.size())
	var d: Array = []
	for i in n:
		d.append(a[i] - b[i])
	var mean := 0.0
	for x in d:
		mean += x
	mean /= maxi(1, n)
	var v := 0.0
	for x in d:
		v += (x - mean) * (x - mean)
	v /= maxi(1, n - 1)
	return [mean, 1.96 * sqrt(v / maxi(1, n))]


func _report(r: Dictionary) -> void:
	var line := "%-7s %5d hands | won %5.1f%% short %5.1f%% bust %5.1f%% | Last Dance %5.1f%% (survived %5.1f%%) | marks %.2f | throws %.2f" % [
		r.name, r.hands, r.won, r.short, r.bust, r.dance, r.survived, r.marks, r.throws]
	if r.name == "strong":
		line += "
        early cash-outs (throws 1-3) %.1f%% paying %.2f | ended without a Dance %.1f%% | Ward cancels %.2f, Curse skulls %.2f a hand
        used/dealt: %s (engines: filled; wires: fired)" % [
			r.early, r.early_marks, r.no_dance, r.cancelled, r.curse, r.pieces]
		line += "
        agony %.1f%% near-ties, %.1f%% exact ties, of %d decisions | threw on past the Target in %.1f%% of hands" % [r.agony, r.ties, r.decisions, r.past]
	say(line)


func _verdict(what: String, ok: bool, number: String) -> void:
	say("  %s %s (%s)" % ["PASS" if ok else "MISS", what, number])
