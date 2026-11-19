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
	"oot_show": 0.5,   # an out-of-turn prompt comes up over the rival's turn (REPLY 38 item 3)
	"oot_think": 2.0,  # you: answering it (after the guard)
	"guard": 0.6,      # REPLY 41: the prompt's seals answer nothing for 0.6 s after it has risen
	"fast": 0.4,       # compress=true: a throw that could not bust, after the first of such a run (REPLY 39 2d)
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
var _turn_sec_last := 0.0
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
		"dance_rounds": [0, 0, 0], "swaps": 0, "dpl": 0, "margin": 0, "you": 0, "bot": [], "end_sin": {}, "gaps": [], "cross": [], "oot": {}, "over": [0, 0], "seat_w": [0, 0, 0, 0, 0, 0, 0], "low": 0}
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
	var g = MatchGame.new(bots, gseed, opts.duplicate(), sins)
	if str(opts.get("you", "random")) == "random":  # REPLY 42: your seat drawn once a match, as the game does (you=0 pins it)
		g.you = r.randi_range(0, seats - 1)
	return [g, r]


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
	s -= _saved(l)
	s = s * pace + B.line + l.get("oot", []).size() * (B.oot_show * pace + B.guard + B.oot_think)
	if p.seat == game.you:
		return s + B.you_first + _decisions(l) * B.think + int(l.get("offers", 0)) * B.you_offer
	return maxf(BOT_FLOOR * pace, s)


## compress=true: within a run of throws that could not bust the rival, every throw after the first plays as
## one quick beat (B.fast) instead of throw and result. Seconds saved at 1x.
func _saved(l: Dictionary) -> float:
	if not opts.get("compress", false):
		return 0.0
	var d: Array = l.get("dead", [])
	var n := 0
	for i in range(1, d.size()):
		if d[i] and d[i - 1]:
			n += 1
	return n * (B.throw + B.result - B.fast)


## Seconds from a rival turn's start beat to the start of throw k+1 (k throws done), at 1x.
func _thr(l: Dictionary, k: int) -> float:
	var d: Array = l.get("dead", [])
	var t := 0.0
	for i in k:
		var fast: bool = opts.get("compress", false) and i > 0 and i < d.size() and d[i] and d[i - 1]
		t += B.fast if fast else B.throw + B.result
	return t


## Your throw-or-bank decisions after the first tap of the turn.
func _decisions(l: Dictionary) -> int:
	var th: int = maxi(1, int(l.get("throws", 1)))
	return th if not l.get("bust", false) else th - 1


## REPLY 35-36: the moments you decide. Your first tap comes after the turn's start; each later decision after
## a throw, its result and your thinking. REPLY 38 item 3: on a rival's turn, each out-of-turn prompt is a
## decision too (a wager before its throw, a hex after its dice land). st.times: [seconds, within your turn].
func _gaps(st: Dictionary, start: float, l: Dictionary, mine: bool) -> void:
	if not mine:
		if l.get("oot", []).is_empty():
			st.dead.append([start, start + _turn_sec_last])
		var j := 0
		for o in l.get("oot", []):
			var k: int = int(o[0])
			var at: float = start + B.start * pace + j * (B.oot_show * pace + B.guard + B.oot_think)
			if o[1] != "hex":
				at += _thr(l, k) * pace
			else:
				at += _thr(l, k - 1) * pace + B.throw * pace
			st.times.append([at + B.oot_show * pace + B.guard + B.oot_think, false])
			j += 1
		return
	var d: float = start + B.start * pace + B.you_first
	st.times.append([d, false])
	var n: int = _decisions(l)
	for i in maxi(n, 1):
		if i < n:
			d += (B.throw + B.result) * pace + B.think
			st.times.append([d, true])
		if i == 0:  # an offer comes after a throw: reading it and answering is a decision
			for k in int(l.get("offers", 0)):
				d += B.offer * pace + B.you_offer
				st.times.append([d, true])


func _flush_gaps(st: Dictionary) -> void:
	var t: Array = st.times
	for i in range(1, t.size()):
		var g: float = t[i][0] - t[i - 1][0]
		st.gaps.append(g)
		if not t[i][1]:
			st.cross.append(g)
		if g > 10.0 and st.has("over"):
			var a: float = t[i - 1][0]
			var b: float = t[i][0]
			var dead := false
			for d in st.dead:
				if d[0] < b and d[1] > a:
					dead = true
			st.over[0 if dead else 1] += 1
			if opts.get("debug", false) and g > 15.0:
				print("gap %.1f from %.1f to %.1f; turns: %s" % [g, a, b, str(st.turns.filter(func(x): return x[0] < b and x[0] + x[1] > a))])


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
		var seq: Array = game.players.duplicate()
		if str(opts.get("order", "fixed")) == "final" and game.end_triggered:  # REPLY 41: the final round from the leader down
			seq.sort_custom(func(a, b): return a.score > b.score)
		for p in seq:
			await game.take_turn(p)
			var ts := _turn_sec(game, p)
			_turn_sec_last = ts
			st.turns.append([st.sec, ts, p.seat, game.last.throws, game.last.bust, game.last.oot])
			_gaps(st, st.sec, game.last, p.seat == game.you)
			st.sec += ts
			if p.seat != game.you and st.has("bot"):
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
	var st := {"sec": B.open + B.close, "leads": 0, "leader": -1, "dr": [], "swaps": 0, "entering": -1, "entering_gap": 0, "bot": R.bot, "gaps": R.gaps, "cross": R.cross, "times": [], "dead": [], "turns": [], "over": R.over}
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
	_flush_gaps(st)
	for k in game.oot_stats:
		R.oot[k] = int(R.oot.get(k, 0)) + int(game.oot_stats[k])
	R.low = mini(R.low, int(game.oot_stats.low))
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
		if winner.seat == game.you:
			R.you += 1
		R.seat_w[winner.seat] += 1
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
	for pair in [["all gaps", R.gaps], ["gaps ending outside your own turn's throws (on or across rivals' turns)", R.cross]]:
		var g: Array = pair[1].duplicate()
		g.sort()
		if not g.is_empty():
			var over := g.filter(func(x): return x > 10.0).size()
			print("  seconds between your decisions, %s: median %.1f, p90 %.1f, max %.1f; over 10 s: %.0f%%" % [pair[0], g[g.size() / 2], g[int(0.9 * (g.size() - 1))], g[-1], 100.0 * over / g.size()])
	var o: Dictionary = R.oot
	if int(o.get("rival_turns", 0)) > 0:
		print("  rival turns that bust %.0f%% | gaps over 10 s that span a rival turn with no prompt: %d, that don't (a long turn): %d" % [100.0 * o.rival_busts / o.rival_turns, R.over[0], R.over[1]])
		print("  fall bets shown %.2f a rival turn, taken %.0f%%, won %.0f%% of taken, close %.0f%%" % [float(o.fall_shown) / o.rival_turns, 100.0 * o.fall_taken / maxf(1, o.fall_shown), 100.0 * o.fall_won / maxf(1, o.fall_taken), 100.0 * o.fall_close / maxf(1, o.fall_shown)])
		print("  out of turn (%s): rival turns with no live prompt %.0f%% | wagers shown %.2f a rival turn, taken %.0f%%, won %.0f%% of taken, close %.0f%% | hexes shown %.2f a rival turn, taken %.0f%%, close %.0f%% | your net from them %.0f a match" % [
			str(opts.get("oot")), 100.0 * o.rival_turns_none / o.rival_turns, float(o.wager_shown) / o.rival_turns, 100.0 * o.wager_taken / maxf(1, o.wager_shown),
			100.0 * o.wager_won / maxf(1, o.wager_taken), 100.0 * o.wager_close / maxf(1, o.wager_shown), float(o.hex_shown) / o.rival_turns,
			100.0 * o.hex_taken / maxf(1, o.hex_shown), 100.0 * o.hex_close / maxf(1, o.hex_shown), float(o.net) / n])
	print("  wins by seat (seat 0 throws first; you are seat %s): %s" % [str(opts.get("you", "random")), " ".join(range(seats).map(func(i): return "%.1f" % (100.0 * R.seat_w[i] / n)))])
	if int(o.get("rival_turns", 0)) > 0:
		var bd := "  rival turn bust rate by dice at its start:"
		for d in range(3, 9):
			if int(o.get("bd%d_t" % d, 0)) > 0:
				bd += " %d: %.2f (%d)" % [d, float(o["bd%d_b" % d]) / o["bd%d_t" % d], o["bd%d_t" % d]]
		for k in 3:
			if int(o.get("rs%d_t" % k, 0)) > 0:
				bd += " | turn busts from %d Strikes before a later throw: %.2f" % [k, float(o["rs%d_b" % k]) / o["rs%d_t" % k]]
		print("  raises shown %.2f a rival turn, taken %.0f%%, won %.0f%% of taken, close %.0f%%" % [float(o.raise_shown) / o.rival_turns, 100.0 * o.raise_taken / maxf(1, o.raise_shown), 100.0 * o.raise_won / maxf(1, o.raise_taken), 100.0 * o.raise_close / maxf(1, o.raise_shown)])
		print(bd + " | your lowest score %d | prompts held back by the credit cap %.2f a match" % [R.low, float(o.cap_blocks) / n])
	var who := "the leader at the call" if mode == "today" else "the leader entering the last dance"
	print("  lead changes %.2f a match | %s loses: %.1f%% | close entering it (%s): %.1f%% | you win %.1f%% | power swaps %.1f a match" % [
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
