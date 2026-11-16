## REPLY 7: player profiles and randomness for every sim from now on. Seats get random profiles
## (sim/sim_bots.gd Profile: numbers drawn per game, a small whim chance per decision) and random Sins.
## Each game is built only from its own seed, so any game replays alone (replay=<seed>).
## Tables: mixed (every seat a random profile), odd (one random seat gets each profile in turn, the rest
## plain), plain (all plain). Rule switches as key=value, e.g. borrow=charges3, master_round=600,
## buy_from_bank=true, win_score=1250 scale_bots=true, temptations=false.
## godot --headless --path . --script res://sim/profile_sim.gd -- <mixed|odd|plain> [games] [seed=1] [key=value ...]
## godot --headless --path . --script res://sim/profile_sim.gd -- replay <seed> <mixed|odd:kind|plain> [key=value ...]
extends SceneTree

const SimGame = preload("res://sim/sim_game.gd")
const SimSins = preload("res://sim/sim_sins.gd")
const SimBots = preload("res://sim/sim_bots.gd")
const Rules = preload("res://core/rules.gd")
const NAMES := ["Wrath", "Greed", "Lust", "Envy", "Pride", "Gluttony", "Sloth"]
## The V5 rules as the sim models them (sim pass 3 + REPLY 3 numbers; the same set sim/agency_sim.gd ran).
const V5_SIM := "purgatory=false powers=true greed_vig=true greed_mult=1.5 envy_mode=copy envy_flat=true hubris_mult=1.75 smart_copy=1 smart_best=6 smart_greed=50 no_sin_risk=true wrath_max=2 fury_trigger=300 fury_grudge=200 eat=90 tempt_comeback=true comeback_gap=true mark_free_behind=150 vig=60 plain_smart=false smart_sins=Greed eat=60 no_sin_risk=false greed_mult=2.0 mimic=3 drag=4"
const KINDS := ["plain", "novice", "banker", "gambler", "chaser", "sitter", "forgetter", "taker", "grudge"]

var opts := {}
var seed0 := 1
var master_at := 0  # master_round=N: the Master calls the penultimate round when the leader reaches N


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var mode: String = args[0] if args.size() > 0 else "mixed"
	var games: int = int(args[1]) if args.size() > 1 and args[1].is_valid_int() else 4000
	opts = Rules.V4.duplicate()
	opts["tier2"] = true
	for a in Array(V5_SIM.split(" ")) + Array(args):
		if "=" in a:
			var kv: PackedStringArray = a.split("=")
			var v = str_to_var(kv[1])
			opts[kv[0]] = v if v != null else kv[1]
	seed0 = int(opts.get("seed", 1))
	master_at = int(opts.get("master_round", 0))
	if master_at > 0:
		opts["win_score"] = 99999  # the game ends after the Master's final round, not at a target
	match mode:
		"replay":
			await _replay(int(args[1]), args[2] if args.size() > 2 else "mixed")
		"odd":
			for k in KINDS:
				if k != "plain":
					_report("odd:" + k, await _run(games, "odd:" + k), true)
		_:
			_report(mode, await _run(games, mode), false)
	quit()


## One game from its seed: Sins and profiles drawn from it, then played.
func _setup(gseed: int, table: String) -> Array:
	var r := RandomNumberGenerator.new()
	r.seed = gseed
	var pool: Array = NAMES.duplicate()
	for i in range(pool.size() - 1, 0, -1):
		var j := r.randi_range(0, i)
		var t = pool[i]
		pool[i] = pool[j]
		pool[j] = t
	var odd_seat := r.randi_range(0, 3)
	var kinds := []
	for i in 4:
		if table == "mixed":
			kinds.append(KINDS[r.randi_range(0, KINDS.size() - 1)])
		elif table.begins_with("odd:"):
			kinds.append(table.substr(4) if i == odd_seat else "plain")
		else:
			kinds.append("plain")
	var bots := []
	var sins := []
	for i in 4:
		bots.append(SimBots.Profile.make(kinds[i], r))
		for c in SimSins.all():
			var o = c.new()
			if o.sin_name == pool[i]:
				sins.append(o)
	var game = SimGame.new(bots, gseed, opts, sins)
	return [game, kinds]


## Plays a game; returns what each report needs.
func _play(game) -> Dictionary:
	var st := {"leads": 0, "round_start": [], "half_last": [], "called": -1, "min_dice": 99}
	var leader := -1
	var halved := false
	var called := -1
	var half: int = (master_at if master_at > 0 else int(opts.get("win_score", 1000))) / 2
	game.master_call = master_at  # the bots read the call (ai/bot_policy.gd call_rounds_left)
	while game.winner == null and game.round_count < game.MAX_ROUNDS:
		game.round_count += 1
		st.round_start = game.players.map(func(q): return q.score)
		if master_at > 0 and called >= 0 and game.round_count == called + 2:
			game.finish_round = true  # the final round: everyone throws once more, then the highest wins
			game.end_triggered = true
		for p in game.players:
			await game.take_turn(p)
			st.min_dice = mini(st.min_dice, p.dice)
			var best := -1
			var seat := -1
			for o in game.players:
				if o.score > best:
					best = o.score
					seat = o.seat
				elif o.score == best:
					seat = -1
			if seat >= 0 and seat != leader:
				if leader >= 0:
					st.leads += 1
				leader = seat
			if not halved and game.leader_score() >= half:
				halved = true
				var low := 99999
				for o in game.players:
					low = mini(low, o.score)
				st.half_low = low
				for o in game.players:
					if o.score == low:
						st.half_last.append(o.seat)
				st.half_gap = game.leader_score() - low
			if game.winner != null:
				return st
		if game.round_count == 2:  # REPLY 12: how far the leader is clear after round 2
			var sc: Array = game.players.map(func(q): return q.score)
			sc.sort()
			st.lead2 = [sc[3] - sc[2], sc[3] - sc[0]]
		if master_at > 0 and called < 0 and game.leader_score() >= master_at:
			called = game.round_count  # the Master calls it: the next round is the penultimate
			game.called_round = called
			st.called = called
		if game.end_triggered:
			game._resolve_finish()
	return st


func _run(games: int, table: String) -> Dictionary:
	var r := {"games": games, "table": table, "prof": {}, "sin": {}, "pair": {}, "rounds": 0, "over6": 0,
		"stall": 0, "margin": 0, "runaway": 0, "last_gap": 0, "last_live": 0, "last_win": 0, "buys": 0,
		"buy_games": 0, "b_offers": 0, "b_taken": 0, "b_uses": 0, "b_changed": 0, "b_pair": {}, "b_sin": {},
		"halves": 0, "comebacks": 0, "far_halves": 0, "far_wins": 0, "worst_len": [], "worst_margin": [],
		"pair_seed": {}, "lock": 0, "leads": 0, "lead2_win": 0,
		"lead2_n": 0, "lead2_2nd": 0, "lead2_last": 0, "au_throw": {}, "au_turn": {}, "au_zero": {}, "au_round": {},
		"au_dice": {}, "au_src": [0, 0, 0]}
	for g in games:
		var gseed: int = seed0 * 1000003 + g
		var su := _setup(gseed, table)
		var game = su[0]
		var kinds: Array = su[1]
		var st := await _play(game)
		var w = game.winner
		if st.has("lead2"):
			r.lead2_n += 1
			r.lead2_2nd += st.lead2[0]
			r.lead2_last += st.lead2[1]
		_audit(r, game)
		var scores: Array = game.players.map(func(q): return q.score)
		var sorted := scores.duplicate()
		sorted.sort()
		var margin: int = sorted[3] - sorted[2]
		r.rounds += game.round_count
		r.leads += st.leads
		if game.round_count > 6:
			r.over6 += 1
		if game.round_count >= game.MAX_ROUNDS:
			r.stall += 1
		if st.min_dice <= 0:
			r.lock += 1
		r.margin += margin
		if margin >= 400:
			r.runaway += 1
		_worst(r.worst_len, [game.round_count, gseed])
		_worst(r.worst_margin, [margin, gseed])
		# Entering the last round: how far behind each seat is, and the last seat's chance.
		var rs: Array = st.round_start
		var top: int = rs.max()
		var low: int = rs.min()
		r.last_gap += top - low
		if top - low <= 250:
			r.last_live += 1
		if w != null and int(rs[w.seat]) == low and low < top:
			r.last_win += 1
		if not st.half_last.is_empty():
			r.halves += 1
			if w != null and w.seat in st.half_last:
				r.comebacks += 1
			if int(st.get("half_gap", 0)) >= 300:
				r.far_halves += 1
				if w != null and w.seat in st.half_last:
					r.far_wins += 1
		var bought := false
		for p in game.players:
			var k: String = kinds[p.seat]
			var sn: String = p.sin.sin_name
			var won: bool = p == w
			_tally(r.prof, k, won, game.round_count, top - int(rs[p.seat]), p.bot.whims)
			_tally(r.sin, sn, won, game.round_count, top - int(rs[p.seat]), 0)
			_tally(r.pair, sn + "+" + k, won, game.round_count, 0, 0)
			if won and not r.pair_seed.has(sn + "+" + k):
				r.pair_seed[sn + "+" + k] = gseed
			var nb: int = int(p.get_meta("buys", 0))
			r.buys += nb
			bought = bought or nb > 0
			r.b_uses += int(p.get_meta("b_uses", 0))
			var held: Dictionary = p.get_meta("b_held", {})
			var most := ""
			for b in held:
				if most == "" or held[b] > held[most]:
					most = b
			if most != "":
				_tally(r.b_pair, sn + "+" + most, won, 0, 0, 0)
				_tally(r.b_sin, most, won, 0, 0, 0)
				if won and not r.pair_seed.has(sn + "+" + most + "(b)"):
					r.pair_seed[sn + "+" + most + "(b)"] = gseed
		if w != null and int(w.get_meta("b_gain", 0)) > 0 and int(w.get_meta("b_gain", 0)) >= margin:
			r.b_changed += 1
		if bought:
			r.buy_games += 1
		r.b_offers += game.borrow_offers
		r.b_taken += game.borrow_taken
	return r


## REPLY 12 (opt "audit"): bust per throw and per turn by dice, zero-bank turns, banks by round and by
## dice held, and where banked points came from.
func _audit(r: Dictionary, game) -> void:
	for a in game.audit_throws:
		var k: String = a[0]
		var d: int = clampi(a[1], 1, 8)
		r.au_throw[k] = r.au_throw.get(k, {})
		var e: Array = r.au_throw[k].get(d, [0, 0])
		e[0] += 1
		e[1] += 1 if a[2] else 0
		r.au_throw[k][d] = e
	for a in game.audit_turns:
		var k: String = a[0]
		var d: int = clampi(a[1], 1, 8)
		r.au_turn[k] = r.au_turn.get(k, {})
		var e: Array = r.au_turn[k].get(d, [0, 0])
		e[0] += 1
		e[1] += 1 if a[4] else 0
		r.au_turn[k][d] = e
		var z: Array = r.au_zero.get(k, [0, 0])
		z[0] += 1 if int(a[3]) <= 0 else 0
		z[1] += 1
		r.au_zero[k] = z
		var rd: int = mini(int(a[2]), 7)
		r.au_round[rd] = r.au_round.get(rd, PackedInt32Array())
		r.au_round[rd].append(int(a[3]))
		r.au_dice[d] = r.au_dice.get(d, PackedInt32Array())
		r.au_dice[d].append(int(a[3]))
		r.au_src[0] += int(a[5])
		r.au_src[1] += int(a[6])
		r.au_src[2] += int(a[7])


static func _q(v: PackedInt32Array, q: float) -> int:
	var a := Array(v)
	a.sort()
	return int(a[clampi(int(q * (a.size() - 1)), 0, a.size() - 1)]) if not a.is_empty() else 0


func _audit_report(r: Dictionary) -> void:
	for table in [["bust per throw, by dice thrown", r.au_throw], ["bust per turn, by dice held", r.au_turn]]:
		print("  %s (3-8):" % table[0])
		for k in table[1]:
			var row := "    %-9s" % k
			for d in range(3, 9):
				var e: Array = table[1][k].get(d, [0, 0])
				row += " %d: %s" % [d, ("%.0f%% (n %d)" % [_pct(e[1], e[0]), e[0]]) if e[0] > 0 else "-"]
			print(row)
	var zl := "  turns banking 0:"
	var zt := [0, 0]
	for k in r.au_zero:
		zl += " %s %.0f%%" % [k, _pct(r.au_zero[k][0], r.au_zero[k][1])]
		zt[0] += r.au_zero[k][0]
		zt[1] += r.au_zero[k][1]
	print(zl + " | all %.1f%%" % _pct(zt[0], zt[1]))
	var bl := "  bank per turn by round (median / p90 / max):"
	for rd in range(1, 8):
		if r.au_round.has(rd):
			var v: PackedInt32Array = r.au_round[rd]
			bl += " r%d%s %d/%d/%d" % [rd, "+" if rd == 7 else "", _q(v, 0.5), _q(v, 0.9), Array(v).max()]
	print(bl)
	var dl := "  bank per turn by dice held (median / p90):"
	for d in range(3, 9):
		if r.au_dice.has(d):
			dl += " %d: %d/%d (n %d)" % [d, _q(r.au_dice[d], 0.5), _q(r.au_dice[d], 0.9), r.au_dice[d].size()]
	print(dl)
	var tot: float = maxf(1.0, r.au_src[0] + r.au_src[1] + r.au_src[2])
	print("  banked points from: face points %.0f%%, chain multiplier %.0f%%, everything else (powers, offers, doubling, costs, cap) %.0f%%" % [
		100.0 * r.au_src[0] / tot, 100.0 * r.au_src[1] / tot, 100.0 * r.au_src[2] / tot])


func _tally(d: Dictionary, key: String, won: bool, rounds: int, gap: int, whims: int) -> void:
	if not d.has(key):
		d[key] = {"n": 0, "w": 0, "rounds": 0, "gap": 0, "whims": 0}
	var e: Dictionary = d[key]
	e.n += 1
	e.w += 1 if won else 0
	e.rounds += rounds
	e.gap += gap
	e.whims += whims


## Keeps the five worst [value, seed] pairs, highest first.
func _worst(list: Array, item: Array) -> void:
	list.append(item)
	list.sort_custom(func(a, b): return a[0] > b[0])
	if list.size() > 5:
		list.resize(5)


func _pct(a: float, b: float) -> float:
	return 100.0 * a / maxf(1.0, b)


func _report(name: String, r: Dictionary, short: bool) -> void:
	var g: float = r.games
	var rules := []
	for k in ["borrow", "borrow_every", "swap", "swap_every", "master_round", "buy_from_bank", "win_score", "scale_bots", "temptations", "turn_cap", "first_ones", "greed_mult", "audit"]:
		if opts.has(k) and not (k == "win_score" and master_at > 0) and not (k == "temptations" and opts[k] == true):
			rules.append("%s=%s" % [k, str(opts[k])])
	print("== %s | seed %d, %d games, 4 seats, V5%s" % [name, seed0, r.games, (" " + " ".join(rules)) if not rules.is_empty() else ""])
	var pl := "  profile win % (fair 25) / rounds / behind entering last round / whims a game:"
	for k in KINDS:
		if r.prof.has(k):
			var e: Dictionary = r.prof[k]
			if short and k == "plain":
				continue
			pl += " %s %.1f/%.1f/%d/%.1f" % [k, _pct(e.w, e.n), float(e.rounds) / e.n, e.gap / e.n, float(e.whims) / e.n]
	print(pl)
	if short:
		return
	var sl := "  Sin win %:"
	var lo := 100.0
	var hi := 0.0
	for n in NAMES:
		if r.sin.has(n):
			var v := _pct(r.sin[n].w, r.sin[n].n)
			lo = minf(lo, v)
			hi = maxf(hi, v)
			sl += " %s %.1f" % [n.substr(0, 4), v]
	print(sl + " | range %.1f-%.1f" % [lo, hi])
	print("  rounds %.2f (over 6: %.1f%%, stalled at %d: %d) | lead changes %.2f | final margin %d (400+: %.1f%%) | dice reaching 0: %d games" % [
		r.rounds / g, _pct(r.over6, g), SimGame.MAX_ROUNDS, r.stall, r.leads / g, r.margin / g, _pct(r.runaway, g), r.lock])
	print("  entering the last round: last seat %d behind; within 250 in %.1f%% of games; last seat wins %.1f%%" % [r.last_gap / g, _pct(r.last_live, g), _pct(r.last_win, g)])
	print("  comebacks (last at half wins) %.1f%%; last at half 300+ behind wins %.1f%% (%d games)" % [_pct(r.comebacks, r.halves), _pct(r.far_wins, r.far_halves), r.far_halves])
	print("  buys %.2f dice a seat a game; someone buys in %.1f%% of games" % [r.buys / g / 4.0, _pct(r.buy_games, g)])
	print("  after round 2: the leader is %d clear of second, %d of last" % [r.lead2_2nd / maxf(1.0, r.lead2_n), r.lead2_last / maxf(1.0, r.lead2_n)])
	if not r.au_zero.is_empty():
		_audit_report(r)
	if r.b_offers > 0:
		print("  Master's seal offers (borrow or swap): %.1f a game, taken %.0f%%, uses %.1f a game; the winner's borrowed gain >= winning margin in %.1f%% of games" % [
			r.b_offers / g, _pct(r.b_taken, r.b_offers), r.b_uses / g, _pct(r.b_changed, g)])
		var bl := "  win % holding each borrowed or swapped-in power most:"
		for n in NAMES:
			if r.b_sin.has(n):
				bl += " %s %.1f" % [n.substr(0, 4), _pct(r.b_sin[n].w, r.b_sin[n].n)]
		print(bl)
		print("  own+borrowed pairs, highest (n>=100): %s" % _top(r.b_pair, 100, 6, true, "(b)", r))
	print("  Sin+profile pairs, highest (n>=150): %s" % _top(r.pair, 150, 6, true, "", r))
	print("  Sin+profile pairs, lowest (n>=150): %s" % _top(r.pair, 150, 4, false, "", r))
	print("  longest games [rounds, seed]: %s | biggest margins [margin, seed]: %s" % [str(r.worst_len), str(r.worst_margin)])


func _top(d: Dictionary, min_n: int, count: int, high: bool, tag: String, r: Dictionary) -> String:
	var rows := []
	for k in d:
		if d[k].n >= min_n:
			rows.append([k, _pct(d[k].w, d[k].n), d[k].n])
	rows.sort_custom(func(a, b): return a[1] > b[1] if high else a[1] < b[1])
	var out := []
	for i in mini(count, rows.size()):
		var sd = r.pair_seed.get(rows[i][0] + tag, -1)
		out.append("%s %.1f (n %d%s)" % [rows[i][0], rows[i][1], rows[i][2], (", seed %d" % sd) if high and sd >= 0 else ""])
	return ", ".join(out)


func _replay(gseed: int, table: String) -> void:
	var su := _setup(gseed, table)
	var game = su[0]
	print("seed %d, table %s" % [gseed, table])
	for p in game.players:
		print("  seat %d: %s, %s" % [p.seat, p.sin.sin_name, su[1][p.seat]])
	var st := await _play(game)
	print("  rounds %d, Master called after round %d, winner seat %d" % [game.round_count, st.called, game.winner.seat if game.winner else -1])
	print("  final: %s" % str(game.players.map(func(q): return "%s %d (%d dice, borrowed uses %d)" % [q.sin.sin_name, q.score, q.dice, int(q.get_meta("b_uses", 0))])))
