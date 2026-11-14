## Run-mode balance sim (Docs/RunDesign.md §11). Plays whole runs with ai/run_bot.gd.
##   godot --headless --path . --script res://sim/run_sim.gd -- [runs=40] [sin=all|Sloth,...] [fast=0]
##       [seed=1] [out=user://part.json] [dice=1] [dice_turns=300] [any cfg key=JSON value, e.g. singles=[5,6]]
##   ... -- merge=<dir>    prints one report from every part*.json in dir (parallel runs, one per Sin).
## Without out= it prints the report itself.
extends SceneTree

const RunState = preload("res://run/run_state.gd")
const Round = preload("res://run/round.gd")
const Relics = preload("res://run/relics.gd")
const Kits = preload("res://run/kits.gd")
const RunBot = preload("res://ai/run_bot.gd")

const SEC_THROW := 5.0
const SEC_SHOP := 30.0
const SUM_KEYS := ["turns", "busts", "throws", "decisions", "decision_points", "wins", "wins_x2", "wins_x2_relic"]
const COUNT_KEYS := ["offered", "bought", "throw_hist", "round_tries", "round_fails", "twist_tries", "twist_fails"]
const LIST_KEYS := ["strong_throws", "minutes", "win_minutes", "c7_runs", "all_throws"]
const LISTMAP_KEYS := ["round_q05", "round_q50"]

var args := {}
var cfg_over := {}


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=", true, 1)
		if kv.size() == 2:
			args[kv[0]] = kv[1]
	if args.has("merge"):
		_merge(args.merge)
		quit()
		return
	var defaults := RunState.default_cfg()
	for k in args:
		if defaults.has(k):
			cfg_over[k] = JSON.parse_string(args[k])
	var runs := int(args.get("runs", "40"))
	var sins: Array = Kits.ORDER if args.get("sin", "all") == "all" else Array(args.sin.split(","))
	var t0 := Time.get_ticks_msec()
	var acc := _blank()
	for s in sins:
		for i in runs:
			_play(s, int(args.get("seed", "1")) * 100000 + Kits.ORDER.find(s) * 10000 + i, acc)
	if args.get("dice", "1") == "1":
		acc.dice_test = _dice_test()
	acc.secs = (Time.get_ticks_msec() - t0) / 1000.0
	if args.has("out"):
		var f := FileAccess.open(args.out, FileAccess.WRITE)
		f.store_string(JSON.stringify(acc))
		f.close()
		print("wrote %s (%.0f s)" % [args.out, acc.secs])
	else:
		_report(acc)
	quit()


func _blank() -> Dictionary:
	var acc := {"per_sin": {}, "dice_test": {}, "secs": 0.0}
	for k in SUM_KEYS:
		acc[k] = 0
	for k in COUNT_KEYS + LISTMAP_KEYS:
		acc[k] = {}
	for k in LIST_KEYS:
		acc[k] = []
	return acc


func _play(sin: String, seed_v: int, acc: Dictionary) -> void:
	var run = RunState.new()
	run.start(sin, seed_v, cfg_over)
	var bot = RunBot.new(seed_v)
	bot.fast = args.get("fast", "0") == "1"
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v * 7 + 3
	var throws := 0
	var shops := 0
	var last_rk := -1
	var c7_throws: Array = []
	var c7_strength := 0
	while run.status != "won" and run.status != "lost":
		if run.status == "shop":
			bot.shop(run)
			run.leave_shop()
			shops += 1
			continue
		var t: Array = run.begin_turn()
		var ctx: Dictionary = t[0]
		var st: Dictionary = t[1]
		bot.begin_turn(run, ctx)
		var rk: int = run.circle * 3 + run.round_i
		if rk != last_rk:
			last_rk = rk
			_round_start(acc, str(rk), bot, run)
			if run.is_sin_round():
				acc.twist_tries[run.ruler()] = acc.twist_tries.get(run.ruler(), 0) + 1
		var busted := false
		while true:
			var gs := Round.throw(ctx, st, rng)
			if gs.is_empty():
				busted = true
				break
			if not bot.play(ctx, st, gs):
				break
		var final_circle: bool = run.circle == 6
		if busted:
			run.finish_bust(ctx, st)
		else:
			run.finish_bank(ctx, st)
		throws += st.throws
		acc.turns += 1
		acc.throws += st.throws
		acc.busts += 1 if busted else 0
		var h := str(st.throws)
		acc.throw_hist[h] = acc.throw_hist.get(h, 0) + 1
		acc.all_throws.append(st.throws)
		if final_circle:
			acc.strong_throws.append(st.throws)
			c7_throws.append(st.throws)
			# Build strength: the median of this build's own turn spread (bot, playing for points).
			if not bot._dist.is_empty():
				c7_strength = maxi(c7_strength, bot._dist[bot._dist.size() / 2])
	if not c7_throws.is_empty():
		acc.c7_runs.append([c7_strength, c7_throws])
	if run.status == "lost":
		acc.round_fails[str(last_rk)] = acc.round_fails.get(str(last_rk), 0) + 1
		if run.is_sin_round():
			acc.twist_fails[run.ruler()] = acc.twist_fails.get(run.ruler(), 0) + 1
	acc.decisions += bot.decisions
	acc.decision_points += bot.decision_points
	var ps: Dictionary = acc.per_sin.get(sin, {"runs": 0, "wins": 0, "reached": [0, 0, 0, 0, 0, 0, 0, 0, 0], "busts": 0, "turns": 0})
	ps.runs += 1
	ps.reached[run.reached()] += 1
	ps.busts += run.stats.busts
	ps.turns += run.stats.turns
	if run.status == "won":
		ps.wins += 1
	acc.per_sin[sin] = ps
	for id in run.stats.offered:
		acc.offered[id] = acc.offered.get(id, 0) + 1
	for id in run.stats.bought:
		acc.bought[id] = acc.bought.get(id, 0) + 1
	var mins: float = (throws * SEC_THROW + shops * SEC_SHOP) / 60.0
	acc.minutes.append(mins)
	if run.status == "won":
		acc.wins += 1
		acc.win_minutes.append(mins)
		var has_relic := false
		for r in run.relics:
			if r.id in Relics.X2:
				has_relic = true
		if has_relic:
			acc.wins_x2_relic += 1
		if has_relic or sin == "Pride":
			acc.wins_x2 += 1


## A round starts: count it, and note what this build could make in its turns (the bot's own spread of
## turn scores, fast policy, sampled turns summed): 5th and 50th percentile.
func _round_start(acc: Dictionary, rk: String, bot, run) -> void:
	acc.round_tries[rk] = acc.round_tries.get(rk, 0) + 1
	var d: PackedInt32Array = bot._dist
	if d.is_empty():
		return
	var r := RandomNumberGenerator.new()
	r.seed = 5
	var sums: Array = []
	for i in 200:
		var s := 0
		for t in run.turns_left:
			s += d[r.randi_range(0, d.size() - 1)]
		sums.append(s)
	sums.sort()
	for key in LISTMAP_KEYS:
		if not acc[key].has(rk):
			acc[key][rk] = []
	acc.round_q05[rk].append(sums[10])
	acc.round_q50[rk].append(sums[100])


## Plain dice, no relics, playing for points: does each die raise the average turn?
func _dice_test() -> Dictionary:
	var out := {}
	var cfg := RunState.default_cfg()
	for k in cfg_over:
		cfg[k] = cfg_over[k]
	for n in [5, 6, 7, 8]:
		var dice: Array = []
		for i in n:
			dice.append(Round.plain_die())
		var ctx := {
			"cfg": cfg, "sin": "", "twist": "", "dice": dice, "fx": Relics.effective([], false), "owned": n,
			"gold": 0, "turns_left": 1, "busted_rounds": 0, "carry_mult": 0, "last_bank": -1,
		}
		var bot = RunBot.new(n)
		bot.fast = args.get("fast", "0") == "1"
		bot._need = 1 << 30
		bot._after = 1
		bot._dist = bot._build_dist(ctx)
		var rng := RandomNumberGenerator.new()
		rng.seed = 900 + n
		var tot := 0
		var busts := 0
		var thr := 0
		var N := int(args.get("dice_turns", "300"))
		for i in N:
			var st := Round.new_turn(ctx)
			var busted := false
			while true:
				var gs := Round.throw(ctx, st, rng)
				if gs.is_empty():
					busted = true
					break
				if not bot.play(ctx, st, gs):
					break
			thr += st.throws
			if busted:
				busts += 1
			else:
				tot += Round.bank_value(ctx, st).score
		out[str(n)] = {"avg": float(tot) / N, "bust": float(busts) / N, "throws": float(thr) / N, "decisions": float(bot.decisions) / N}
	return out


func _merge(dir: String) -> void:
	var acc := _blank()
	var d := DirAccess.open(dir)
	for f in d.get_files():
		if not f.begins_with("part") or not f.ends_with(".json"):
			continue
		var p: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(dir.path_join(f)))
		for s in p.per_sin:
			if not acc.per_sin.has(s):
				acc.per_sin[s] = p.per_sin[s]
				continue
			var a: Dictionary = acc.per_sin[s]
			for k in ["runs", "wins", "busts", "turns"]:
				a[k] += p.per_sin[s][k]
			for i in a.reached.size():
				a.reached[i] += p.per_sin[s].reached[i]
		for key in COUNT_KEYS:
			for id in p[key]:
				acc[key][id] = acc[key].get(id, 0) + p[key][id]
		for key in SUM_KEYS:
			acc[key] += p[key]
		for key in LISTMAP_KEYS:
			for id in p[key]:
				if not acc[key].has(id):
					acc[key][id] = []
				acc[key][id].append_array(p[key][id])
		for key in LIST_KEYS:
			acc[key].append_array(p[key])
		if not p.dice_test.is_empty():
			acc.dice_test = p.dice_test
		acc.secs = maxf(acc.secs, p.secs)
	_report(acc)


func _pct(a: Array, q: float) -> float:
	if a.is_empty():
		return 0.0
	var s := a.duplicate()
	s.sort()
	return s[mini(s.size() - 1, int(s.size() * q))]


func _mean(a: Array) -> float:
	var t := 0.0
	for v in a:
		t += v
	return t / maxf(1.0, a.size())


func _total_runs(acc: Dictionary) -> int:
	var n := 0
	for s in acc.per_sin:
		n += acc.per_sin[s].runs
	return n


func _report(acc: Dictionary) -> void:
	print("=== Run sim (%s runs, %.0f s) ===" % [_total_runs(acc), acc.secs])
	print("Sin       win    C1    C4   mean circle  bust/turn")
	var all_runs := 0
	var all_wins := 0
	var c1 := 0
	var c4 := 0
	for s in Kits.ORDER:
		if not acc.per_sin.has(s):
			continue
		var p: Dictionary = acc.per_sin[s]
		var n: int = p.runs
		var r: Array = p.reached
		var past1 := 0
		var past4 := 0
		var mean_c := 0.0
		for i in r.size():
			if i >= 2:
				past1 += r[i]
			if i >= 5:
				past4 += r[i]
			mean_c += i * r[i]
		all_runs += n
		all_wins += p.wins
		c1 += past1
		c4 += past4
		print("%-9s %4.0f%%  %4.0f%%  %4.0f%%   %4.2f       %4.1f%%" % [s, 100.0 * p.wins / n, 100.0 * past1 / n, 100.0 * past4 / n, mean_c / n, 100.0 * p.busts / maxf(1, p.turns)])
	print("ALL       %4.0f%%  %4.0f%%  %4.0f%%" % [100.0 * all_wins / maxi(1, all_runs), 100.0 * c1 / maxi(1, all_runs), 100.0 * c4 / maxi(1, all_runs)])
	_round_table(acc)
	var tl := "Sin rounds failed, by twist:"
	for s in Kits.ORDER:
		tl += " %s %d/%d" % [s, acc.twist_fails.get(s, 0), acc.twist_tries.get(s, 0)]
	print(tl)
	print("Turns ending in a bust: %.1f%% (target 10-25%%)" % (100.0 * acc.busts / maxi(1, acc.turns)))
	var c7: Array = acc.c7_runs.duplicate()
	c7.sort_custom(func(a, b): return a[0] > b[0])
	var top: Array = []
	for i in mini(c7.size(), maxi(1, c7.size() / 5)):
		top.append_array(c7[i][1])
	print("Throws per turn: mean %.2f, p95 %d; strongest fifth of builds (Circle 7) p95 %d, max %d (max 8); all Circle 7 turns p95 %d" % [float(acc.throws) / maxi(1, acc.turns), int(_pct(acc.all_throws, 0.95)), int(_pct(top, 0.95)), int(_pct(top, 1.0)), int(_pct(acc.strong_throws, 0.95))])
	print("Decisions per turn: %.2f (throw points %.2f)" % [float(acc.decisions) / maxi(1, acc.turns), float(acc.decision_points) / maxi(1, acc.turns)])
	print("Minutes per run: all %.1f, winning %.1f (p10 %.1f, p90 %.1f; target 20-30)" % [_mean(acc.minutes), _mean(acc.win_minutes), _pct(acc.win_minutes, 0.1), _pct(acc.win_minutes, 0.9)])
	print("Winning runs holding an x2 source: %.0f%% (relic only %.0f%%; above 60%%: add multiplicative uncommons)" % [100.0 * acc.wins_x2 / maxi(1, acc.wins), 100.0 * acc.wins_x2_relic / maxi(1, acc.wins)])
	var rates := {}
	var tot := 0.0
	for id in Relics.LIST:
		var o: int = acc.offered.get(id, 0)
		rates[id] = float(acc.bought.get(id, 0)) / o if o > 0 else 0.0
		tot += rates[id]
	var avg := tot / Relics.LIST.size()
	var ids: Array = Relics.LIST.keys()
	ids.sort_custom(func(a, b): return rates[a] > rates[b])
	var line := "Relic pick rate (bought / offered), average %.0f%%; FLAG above %.0f%%:\n" % [avg * 100, avg * 200]
	for id in ids:
		line += "  %-16s %3.0f%% (%d/%d)%s\n" % [Relics.name_of(id), rates[id] * 100, acc.bought.get(id, 0), acc.offered.get(id, 0), "  << FLAG" if rates[id] > 2 * avg else ""]
	print(line)
	if not acc.dice_test.is_empty():
		print("Plain dice, playing for points (avg turn / bust / throws / decisions):")
		for n in ["5", "6", "7", "8"]:
			var d: Dictionary = acc.dice_test[n]
			print("  %s dice: %5.0f  %4.1f%%  %.2f  %.2f" % [n, d.avg, d.bust * 100, d.throws, d.decisions])


func _round_table(acc: Dictionary) -> void:
	print("Round  tries  fail%   target  build p05  build p50 (medians; fast policy, sampled turns)")
	var cfg := RunState.default_cfg()
	for k in cfg_over:
		cfg[k] = cfg_over[k]
	for rk in 21:
		var k := str(rk)
		var n: int = acc.round_tries.get(k, 0)
		if n == 0:
			continue
		var f: int = acc.round_fails.get(k, 0)
		print("C%d.%d  %5d  %5.1f%%  %7d  %9.0f  %9.0f" % [rk / 3 + 1, rk % 3 + 1, n, 100.0 * f / n, cfg.targets[rk / 3][rk % 3], _pct(acc.round_q05.get(k, []), 0.5), _pct(acc.round_q50.get(k, []), 0.5)])
