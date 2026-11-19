## REPLY 34 item 3 (sim only): match structures timed with the pacing floor's beat times (REPLY 34 item 2).
## Seats get random profiles and random Sins (sim/profile_sim.gd "mixed"); seat 0 stands in for you (it pays
## thinking time). Rules: V5 as profile_sim models it. Structures:
##   today  -- one race: the Master calls at call (550) from round floor (3), one more round, the final round.
##   carry  -- three dances, scores carry over. Dances 1 and 2 are races: each ends at the end of the round
##             in which the leader reaches t1 / t2 (at least 2 rounds a dance). Dance 3 ends as today, the call at
##             t3. Between dances the Master changes one table rule (rules=on) and each seat may swap its power
##             for a Sin not at the table (swap=on), the last seat first.
##   reset  -- three dances, scores reset each dance (dice too); each dance ends as today with the call at
##             call. Placings score 4/2/1/0, the last dance double; most points wins, then most total score.
## godot --headless --path . --script res://sim/match_sim.gd -- <today|carry|reset> [games] [seats=4] [key=value]
##   keys: t1 t2 t3 call floor rules=on|off swap=on|off seed=1, plus any profile_sim rule key
extends SceneTree

const MatchGame = preload("res://sim/match_game.gd")
const SimSins = preload("res://sim/sim_sins.gd")
const SimBots = preload("res://sim/sim_bots.gd")
const Rules = preload("res://core/rules.gd")
const ProfileSim = preload("res://sim/profile_sim.gd")
const NAMES := ["Wrath", "Greed", "Lust", "Envy", "Pride", "Gluttony", "Sloth"]

## The pacing floor (REPLY 34 item 2), seconds at 1x. A bot's turn: start, then per throw (throw, result),
## any power, offer, buy, then bank or bust; never under BOT_FLOOR. Your turn adds THINK per decision.
const B := {
	"start": 0.6,      # its window comes forward, the turn band
	"throw": 0.7,      # dice fly and land
	"result": 0.9,     # scorers lit, the stake counts up, Strikes snuff candles: held to be read
	"power": 0.7,      # a seal fires (Tuning.POWER_FOR)
	"bank": 0.9,       # the stake flies to the track, the token moves
	"bust": 1.4,       # the bust: dice dim, the stake breaks, what's kept flies
	"buy": 0.8,        # dice bought
	"offer": 2.0,      # an offer's card and its answer (a bot's)
	"line": 0.8,       # the average wait a turn adds for its line to finish its 2.5 s hold
	"think": 2.0,      # you: each throw-or-bank decision
	"you_offer": 4.0,  # you: reading an offer
	"you_first": 1.0,  # you: the first tap of your turn
	"round": 1.2,      # the Master marks the leader
	"call": 1.6,       # the Master's call
	"interlude": 12.0, # between dances: his new rule (4 s) and your power pick (8 s)
	"open": 3.0, "close": 5.0,
}
const BOT_FLOOR := 3.0
const RULES := ["cheap_dice", "wide_chain", "no_mark", "hard_falls", "rich_sixes", "free_die"]

var opts := {}
var seats := 4
var mode := "carry"
var t1 := 500
var t2 := 1000
var t3 := 1500
var call_at := 550
var floor_r := 3
var rules_on := true
var swap_on := true
var pace := 1.0  # pace=0.5: every beat at half its time (Fast); your thinking and the line's hold stay


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	mode = a[0] if a.size() > 0 else "carry"
	var games: int = int(a[1]) if a.size() > 1 and a[1].is_valid_int() else 2000
	opts = Rules.V4.duplicate()
	opts["tier2"] = true
	for s in Array(ProfileSim.V5_SIM.split(" ")) + Array(a):
		if "=" in s:
			var kv: PackedStringArray = s.split("=")
			var v = str_to_var(kv[1])
			opts[kv[0]] = v if v != null else kv[1]
	opts["audit"] = true
	opts["win_score"] = 99999
	seats = int(opts.get("seats", 4))
	t1 = int(opts.get("t1", t1))
	t2 = int(opts.get("t2", t2))
	t3 = int(opts.get("t3", t3))
	call_at = int(opts.get("call", call_at))
	floor_r = int(opts.get("floor", floor_r))
	rules_on = str(opts.get("rules", "on")) == "on"
	swap_on = str(opts.get("swap", "on")) == "on"
	pace = float(opts.get("pace", 1.0))
	var seed0 := int(opts.get("seed", 1))
	var R := {"n": 0, "sec": [], "rounds": 0, "leads": 0, "flip": 0, "live": 0, "sin": {}, "start_sin": {},
		"dance_rounds": [0, 0, 0], "swaps": 0, "dpl": 0, "margin": 0, "you": 0, "bot": [], "end_sin": {}, "gaps": [], "cross": []}
	for g in games:
		await _match(seed0 * 1000003 + g, R)
	_report(R)
	quit()


func _setup(gseed: int) -> Array:
	var r := RandomNumberGenerator.new()
	r.seed = gseed
	var pool: Array = NAMES.duplicate()
	for i in range(pool.size() - 1, 0, -1):
		var j := r.randi_range(0, i)
		var t = pool[i]
		pool[i] = pool[j]
		pool[j] = t
	var bots := []
	var sins := []
	for i in seats:
		bots.append(SimBots.Profile.make(ProfileSim.KINDS[r.randi_range(0, ProfileSim.KINDS.size() - 1)], r))
		sins.append(_sin(pool[i]))
	return [MatchGame.new(bots, gseed, opts.duplicate(), sins), r]


func _sin(n: String):
	for c in SimSins.all():
		var o = c.new()
		if o.sin_name == n:
			return o
	return null


## Seconds one turn takes under the pacing floor.
func _turn_sec(game, p) -> float:
	var l: Dictionary = game.last
	var th: int = maxi(1, int(l.get("throws", 1)))
	var s: float = B.start + th * (B.throw + B.result) + int(l.get("uses", 0)) * B.power + int(l.get("offers", 0)) * B.offer
	s += B.bust if l.get("bust", false) else B.bank
	if int(l.get("buys", 0)) > 0:
		s += B.buy
	s = s * pace + B.line
	if p.seat == 0:
		return s + B.you_first + _decisions(l) * B.think + int(l.get("offers", 0)) * B.you_offer
	return maxf(BOT_FLOOR * pace, s)


## Your throw-or-bank decisions after the first tap of the turn.
func _decisions(l: Dictionary) -> int:
	var th: int = maxi(1, int(l.get("throws", 1)))
	return th if not l.get("bust", false) else th - 1


## REPLY 35-36: the seconds between your decisions. Your first tap comes after the turn's start; each later
## decision after a throw, its result and your thinking. The first gap of a turn runs from your last decision of
## the turn before, through every rival's turn.
func _gaps(st: Dictionary, start: float, l: Dictionary) -> void:
	var d: float = start + B.start * pace + B.you_first
	if st.last_dec >= 0.0:
		st.cross.append(d - st.last_dec)
		st.gaps.append(d - st.last_dec)
	for i in _decisions(l):
		var step: float = (B.throw + B.result) * pace + B.think
		st.gaps.append(step)
		d += step
	st.last_dec = d


## One dance. end: "race" (ends at the round's end once the leader has target, after 2+ rounds) or "call"
## (the Master calls at target from round floor of this dance; one more round; the final round; highest wins).
func _dance(game, st: Dictionary, end: String, target: int) -> void:
	var r0: int = game.round_count
	var called := -1
	game.master_call = target  # never 0: at 0 the core game ends at 1000
	game.called_round = -1
	game.finish_round = false
	game.end_triggered = false
	while game.round_count < 200:
		game.round_count += 1
		st.sec += B.round
		game.mark_leader()
		if end == "call" and called >= 0 and game.round_count == called + 2:
			game.finish_round = true
			game.end_triggered = true
		for p in game.players:
			await game.take_turn(p)
			var ts := _turn_sec(game, p)
			if p.seat == 0:
				_gaps(st, st.sec, game.last)
			st.sec += ts
			if p.seat != 0 and st.has("bot"):
				st.bot.append(ts)
			var lead := _leader(game, st)
			if lead >= 0 and lead != st.leader:
				if st.leader >= 0:
					st.leads += 1
				st.leader = lead
		var rd: int = game.round_count - r0
		if end == "call":
			if game.end_triggered:
				game._resolve_finish()
				st.dr.append(rd)
				return
			if called < 0 and game.leader_score() >= target and rd >= floor_r:
				called = game.round_count
				game.called_round = called
				st.sec += B.call
				if mode == "today":
					st.entering = _leader(game, st)  # today's last stretch: from the call
					st.entering_gap = _gap(game)
		elif game.leader_score() >= target and rd >= 2:
			st.dr.append(rd)
			return
	st.dr.append(game.round_count - r0)


func _leader(game, st: Dictionary) -> int:
	var best := -1
	var seat := -1
	for o in game.players:
		var v: int = o.score + (100000 * int(st.dp[o.seat]) if st.has("dp") else 0)
		if v > best:
			best = v
			seat = o.seat
		elif v == best:
			seat = -1
	return seat


func _gap(game) -> int:
	var sc: Array = game.players.map(func(q): return q.score)
	sc.sort()
	return sc[-1] - sc[-2]


## Between dances: one rule changes (the last one goes back); each seat, last first, may swap its power.
func _interlude(game, st: Dictionary, r: RandomNumberGenerator) -> void:
	st.sec += B.interlude
	if rules_on:
		_set_rule(game, st.get("rule", ""), false)
		var pick: String = RULES[r.randi_range(0, RULES.size() - 1)]
		while pick == st.get("rule", ""):
			pick = RULES[r.randi_range(0, RULES.size() - 1)]
		st.rule = pick
		_set_rule(game, pick, true)
	if swap_on:
		var order: Array = game.players.duplicate()
		order.sort_custom(func(x, y): return x.score < y.score)
		for p in order:
			var lead: bool = p.score == game.leader_score()
			if lead or r.randf() >= 0.6:  # the leader keeps; the rest swap 6 times in 10
				continue
			var at: Array = game.players.map(func(q): return q.sin.sin_name)
			var free: Array = NAMES.filter(func(n): return not n in at)
			if free.is_empty():
				continue
			p.sin = _sin(free[r.randi_range(0, free.size() - 1)])
			st.swaps += 1


func _set_rule(game, rule: String, on: bool) -> void:
	match rule:
		"cheap_dice":  # dice cost 60
			game.die_cost = 60 if on else int(opts.get("die_cost", Rules.DIE_COST))
			game.opts["max_buy"] = int(opts.get("max_buy", Rules.MAX_BUY))
		"wide_chain":  # the chain caps at x3, not x2
			game.opts["chain_cap"] = 3.0 if on else float(opts.get("chain_cap", 2.0))
		"no_mark":  # no mark on the leader
			game.opts["mark"] = "" if on else str(opts.get("mark", "chain"))
		"hard_falls":  # a bust keeps nothing
			game.opts["soften"] = "" if on else str(opts.get("soften", "half"))
		"rich_sixes":  # every scoring face pays 6x, not 5x
			game.face_mult = int(opts.get("face_mult", 5)) + (1 if on else 0)
		"free_die":  # everyone takes a die from the supply (kept)
			if on:
				for p in game.players:
					if game.supply > 0:
						p.dice += 1
						game.supply -= 1


func _match(gseed: int, R: Dictionary) -> void:
	var su := _setup(gseed)
	var game = su[0]
	var r: RandomNumberGenerator = su[1]
	var st := {"sec": B.open + B.close, "leads": 0, "leader": -1, "dr": [], "swaps": 0, "entering": -1, "entering_gap": 0, "bot": R.bot, "gaps": R.gaps, "cross": R.cross, "last_dec": -1.0}
	var start_sins: Array = game.players.map(func(q): return q.sin.sin_name)
	var winner = null
	match mode:
		"today":
			await _dance(game, st, "call", call_at)
			winner = game.winner
		"carry":
			await _dance(game, st, "race", t1)
			await _interlude(game, st, r)
			await _dance(game, st, "race", t2)
			await _interlude(game, st, r)
			st.entering = _leader(game, st)
			st.entering_gap = _gap(game)
			await _dance(game, st, "call", t3)
			winner = game.winner
		"reset":
			st.dp = []
			st.dp.resize(seats)
			st.dp.fill(0)
			var tot := []
			tot.resize(seats)
			tot.fill(0)
			for d in 3:
				if d > 0:
					await _interlude(game, st, r)
					for p in game.players:
						tot[p.seat] += p.score
						game.supply += p.dice - Rules.START_DICE
						p.score = 0
						p.dice = Rules.START_DICE
					game.winner = null
				if d == 2:
					st.entering = _leader(game, st)
					var dps: Array = st.dp.duplicate()
					dps.sort()
					st.entering_gap = dps[-1] - dps[-2]
				await _dance(game, st, "call", call_at)
				var order: Array = game.players.duplicate()
				order.sort_custom(func(x, y): return x.score > y.score)
				var pts := [4, 2, 1]
				for i in mini(3, order.size()):
					st.dp[order[i].seat] += pts[i] * (2 if d == 2 else 1)
			for p in game.players:
				tot[p.seat] += p.score
			var best := -1
			for p in game.players:
				var v: int = int(st.dp[p.seat]) * 100000 + int(tot[p.seat])
				if v > best:
					best = v
					winner = p
	R.n += 1
	R.sec.append(st.sec)
	R.rounds += game.round_count
	R.leads += st.leads
	R.swaps += st.swaps
	for i in 3:
		if i < st.dr.size():
			R.dance_rounds[i] += st.dr[i]
	if st.entering >= 0 and winner != null and winner.seat != st.entering:
		R.flip += 1
	if st.entering < 0 or st.entering_gap <= (2 if mode == "reset" else 250):
		R.live += 1
	if winner != null:
		R.margin += _gap(game) if mode != "reset" else 0
		if winner.seat == 0:
			R.you += 1
	for p in game.players:
		var en: String = p.sin.sin_name
		if not R.end_sin.has(en):
			R.end_sin[en] = [0, 0]
		R.end_sin[en][0] += 1
		R.end_sin[en][1] += 1 if p == winner else 0
		var sn: String = start_sins[p.seat]
		if not R.start_sin.has(sn):
			R.start_sin[sn] = [0, 0]
		R.start_sin[sn][0] += 1
		R.start_sin[sn][1] += 1 if p == winner else 0


func _report(R: Dictionary) -> void:
	var s: Array = R.sec.duplicate()
	s.sort()
	var n: float = R.n
	var q := func(f: float) -> float: return float(s[clampi(int(f * (s.size() - 1)), 0, s.size() - 1)]) / 60.0
	var tag := mode
	match mode:
		"today": tag += " call %d floor %d" % [call_at, floor_r]
		"carry": tag += " t1 %d t2 %d t3 %d rules %s swap %s" % [t1, t2, t3, rules_on, swap_on]
		"reset": tag += " call %d floor %d rules %s swap %s" % [call_at, floor_r, rules_on, swap_on]
	print("== %s | %d seats, %d matches, mixed profiles, V5, beats at %.2f" % [tag, seats, R.n, pace])
	print("  minutes: median %.1f, p10 %.1f, p90 %.1f, max %.1f | rounds %.1f (dances %s)" % [q.call(0.5), q.call(0.1), q.call(0.9), q.call(1.0),
		R.rounds / n, "/".join(R.dance_rounds.map(func(x): return "%.1f" % (x / n)))])
	var bt: Array = R.bot.duplicate()
	bt.sort()
	if not bt.is_empty():
		print("  bot turn seconds: p10 %.1f, median %.1f, p90 %.1f, max %.1f, over 10 s %.0f%% | seconds a round %.1f" % [bt[int(0.1 * (bt.size() - 1))], bt[bt.size() / 2], bt[int(0.9 * (bt.size() - 1))], bt[-1], 100.0 * bt.filter(func(x): return x > 10.0).size() / bt.size(), 60.0 * s.reduce(func(x, y): return x + y, 0.0) / 60.0 / maxf(1.0, R.rounds)])
	for pair in [["all gaps", R.gaps], ["from your last decision, past the rivals, to your next turn", R.cross]]:
		var g: Array = pair[1].duplicate()
		g.sort()
		if not g.is_empty():
			var over := g.filter(func(x): return x > 10.0).size()
			print("  seconds between your decisions, %s: median %.1f, p90 %.1f, max %.1f; over 10 s: %.0f%%" % [pair[0], g[g.size() / 2], g[int(0.9 * (g.size() - 1))], g[-1], 100.0 * over / g.size()])
	var who := "the leader at the call" if mode == "today" else "the leader entering the last dance"
	print("  lead changes %.2f a match | %s loses: %.1f%% | close entering it (%s): %.1f%% | seat 0 (you) wins %.1f%% | power swaps %.1f a match" % [
		R.leads / n, who, 100.0 * R.flip / n, "within 2 dance points" if mode == "reset" else "within 250", 100.0 * R.live / n, 100.0 * R.you / n, R.swaps / n])
	var sl := "  win %% by starting Sin (fair %.1f):" % (100.0 / seats)
	var lo := 100.0
	var hi := 0.0
	for k in NAMES:
		if R.start_sin.has(k):
			var v: float = 100.0 * R.start_sin[k][1] / maxf(1.0, R.start_sin[k][0])
			lo = minf(lo, v)
			hi = maxf(hi, v)
			sl += " %s %.1f" % [k.substr(0, 4), v]
	print(sl + " | range %.1f-%.1f" % [lo, hi])
	if R.swaps > 0:
		var el := "  win % by the Sin held at the end:"
		var elo := 100.0
		var ehi := 0.0
		for k in NAMES:
			if R.end_sin.has(k):
				var v: float = 100.0 * R.end_sin[k][1] / maxf(1.0, R.end_sin[k][0])
				elo = minf(elo, v)
				ehi = maxf(ehi, v)
				el += " %s %.1f" % [k.substr(0, 4), v]
		print(el + " | range %.1f-%.1f" % [elo, ehi])
