## Agency and comeback measures (Ben, 2026-11-15; Docs/TableDesign.md §10). Sim only: prototype rules
## run through sim/sim_game.gd, sim/sim_sins.gd and sim/sim_bots.gd, so core/, sins/ and ai/ stay untouched.
## godot --headless --path . --script res://sim/agency_sim.gd -- <pass> [games] [key=value ...]
##   pass: base | skill | dice | first | split | novice
##   keys override Rules.V4, e.g. purgatory=false powers=true tempt_comeback=true comeback_gap=true
##   strike_cap=true die_cost=75 mark_free_behind=150; best=<target,base,kb,ka,late> for the skill bot.
## base reports, at 4 seats with Greater and temptations on: win % per Sin; comebacks (share of games won
## by whoever was last when the leader first reached 500); lead changes; the last-placed seat's turns begun
## in Purgatory; throws a turn, minutes; with powers, each power's use; claims by the claimed seat's place.
extends SceneTree

const Rules = preload("res://core/rules.gd")
const SimGame = preload("res://sim/sim_game.gd")
const SimBots = preload("res://sim/sim_bots.gd")
const SimSins = preload("res://sim/sim_sins.gd")
const SIN_SCRIPTS := [
	preload("res://sins/wrath.gd"), preload("res://sins/greed.gd"), preload("res://sins/lust.gd"),
	preload("res://sins/envy.gd"), preload("res://sins/pride.gd"), preload("res://sins/gluttony.gd"),
	preload("res://sins/sloth.gd"),
]
const NAMES := ["Wrath", "Greed", "Lust", "Envy", "Pride", "Gluttony", "Sloth"]
const HALF := 500

var opts := {}


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var mode: String = args[0] if args.size() > 0 else "base"
	var games: int = int(args[1]) if args.size() > 1 and args[1].is_valid_int() else 2000
	opts = Rules.V4.duplicate()
	opts["tier2"] = true
	var best_cfg := [4, 0.9, 0.0, 0.5, 0.3]
	for a in args:
		if "=" in a:
			var kv: PackedStringArray = a.split("=")
			if kv[0] == "best":
				best_cfg = Array(kv[1].split(",")).map(func(x): return str_to_var(x))
			else:
				var v = str_to_var(kv[1])
				opts[kv[0]] = v if v != null else kv[1]
	match mode:
		"base":
			_report("plain bots", await _pass(opts, games, 4, null))
		"skill":
			var b = SimBots.Best.new(best_cfg[0], best_cfg[1], best_cfg[2], best_cfg[3], best_cfg[4])
			b.smart = not opts.get("best_naive", false)
			var line := "skill edge (%s vs 3 plain bots, fair 25):" % b.label
			var all := 0.0
			var uses := ""
			for n in NAMES:
				var r := await _pass(opts, games, 4, b, n)
				line += " %s %.1f" % [n.substr(0, 4), r.special_win]
				all += r.special_win
			print(line + " | mean %.1f" % (all / NAMES.size()))
		"dice":
			await _dice(games)
		"split":
			await _split(games)
		"novice":
			await _novice(games)
		"first":
			await _first(games)
	quit()


func _new_sin(n: String):
	if opts.get("powers", false):
		for c in SimSins.all():
			var o = c.new()
			if o.sin_name == n:
				return o
	for s in SIN_SCRIPTS:
		var o = s.new()
		if o.sin_name == n:
			return o
	return null


## A table of `table` Sins in random seats. `special` (with Sin `special_sin` when given) takes one random
## seat; everyone else is `plain`. special_dice: the special bot starts with this many dice.
func _pass(o: Dictionary, games: int, table: int, special, special_sin := "", sins_on := true, plain = null, special_dice := 0, plain_dice := 0) -> Dictionary:
	if plain == null:
		plain = SimBots.Plain.new(5, 300)
		plain.smart = o.get("plain_smart", true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var r := {"games": games, "wins": {}, "seats_in": {}, "comebacks": 0, "halves": 0, "leads": 0,
		"last_turns": 0, "last_purg": 0, "turns": 0, "purg_turns": 0, "throws": 0, "special_wins": 0,
		"secs": 0.0, "rounds": 0, "last_score": 0, "power": {}, "claims": 0, "tc": [0, 0, 0, 0], "ranks": {"last": 0, "lead": 0, "mid": 0}}
	for g in games:
		var pool: Array = NAMES.duplicate()
		for i in range(pool.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var t = pool[i]
			pool[i] = pool[j]
			pool[j] = t
		if special_sin != "":
			pool.erase(special_sin)
		var seat := rng.randi_range(0, table - 1) if special != null else -1
		var sins := []
		var bots := []
		var k := 0
		for i in table:
			if i == seat and special_sin != "":
				sins.append(_new_sin(special_sin))
			else:
				sins.append(_new_sin(pool[k]))
				k += 1
			bots.append(special if i == seat else plain)
		var game = SimGame.new(bots, g, o, sins if sins_on else [])
		for p in game.players:
			var d: int = special_dice if p.seat == seat else plain_dice
			if d > 0:
				game.supply -= d - p.dice
				p.dice = d
		var st := await _play(game)
		var w = game.winner
		r.rounds += game.round_count
		if sins_on:
			r.wins[w.sin.sin_name] = r.wins.get(w.sin.sin_name, 0) + 1
			for p in game.players:
				r.seats_in[p.sin.sin_name] = r.seats_in.get(p.sin.sin_name, 0) + 1
		if w.seat == seat:
			r.special_wins += 1
		if st.half_last.size() > 0:
			r.halves += 1
			if w.seat in st.half_last:
				r.comebacks += 1
		r.leads += st.leads
		var last = game.players[0]
		for p in game.players:
			if p.score < last.score:
				last = p
		r.last_score += last.score
		r.last_turns += last.turns
		r.last_purg += st.purg[last.seat]
		for p in game.players:
			r.turns += p.turns
			r.throws += p.turns + p.presses
			r.purg_turns += st.purg[p.seat]
		for n in game.power_stats:
			if not r.power.has(n):
				r.power[n] = {}
			for key in game.power_stats[n]:
				r.power[n][key] = r.power[n].get(key, 0) + game.power_stats[n][key]
		r.claims += game.claims_made
		for i in 4:
			r.tc[i] += game.tempt_counts[i]
		for c in game.claim_ranks:
			r.ranks[c] += 1
		var you = game.players[0]
		r.secs += you.turns * 3.0 + (you.turns + you.presses) * 3.0 + you.offers_seen * 3.0
		for p in game.players:
			if p != you:
				r.secs += p.turns * 2.5
		var pu := 0
		for n in game.power_stats:
			pu += game.power_stats[n].uses
		r.secs += pu * 1.5 / table  # a power tap, on your turns
	r.special_win = 100.0 * r.special_wins / games
	return r


## Game.play(), with the measures taken after every turn.
func _play(game) -> Dictionary:
	var st := {"half_last": [], "leads": 0, "purg": {}}
	for p in game.players:
		st.purg[p.seat] = 0
	var leader := -1
	var halved := false
	while game.winner == null and game.round_count < game.MAX_ROUNDS:
		game.round_count += 1
		for p in game.players:
			if p.in_purgatory:
				st.purg[p.seat] += 1
			await game.take_turn(p)
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
			if not halved and game.leader_score() >= HALF:
				halved = true
				var low := 99999
				for o in game.players:
					low = mini(low, o.score)
				for o in game.players:
					if o.score == low:
						st.half_last.append(o.seat)
			if game.winner != null:
				return st
		if game.end_triggered:
			game._resolve_finish()
	return st


func _report(name: String, r: Dictionary) -> void:
	var g: float = r.games
	var line := "%s: win %% per Sin (fair 25):" % name
	var lo := 100.0
	var hi := 0.0
	for n in NAMES:
		var w: float = 100.0 * r.wins.get(n, 0) / maxf(1.0, r.seats_in.get(n, 0))
		lo = minf(lo, w)
		hi = maxf(hi, w)
		line += " %s %.1f" % [n.substr(0, 4), w]
	print(line + " | range %.1f-%.1f" % [lo, hi])
	print("  comebacks %.1f%%, lead changes %.2f a game, last seat's turns in Purgatory %.1f%% (all %.1f%%), last seat ends on %d" % [
		100.0 * r.comebacks / maxf(1.0, r.halves), float(r.leads) / g, 100.0 * r.last_purg / maxf(1.0, r.last_turns),
		100.0 * r.purg_turns / maxf(1.0, r.turns), r.last_score / g])
	print("  throws a turn %.2f, rounds %.1f, minutes %.1f (you + 3 bots) | claims %.2f a game: last %.2f, mid %.2f, lead %.2f" % [
		float(r.throws) / r.turns, r.rounds / g, r.secs / g / 60.0, r.claims / g, r.ranks.last / g, r.ranks.mid / g, r.ranks.lead / g])
	print("  offers accepted: by a seat 150+ behind %.0f%% of %d, by others %.0f%% of %d" % [100.0 * r.tc[1] / maxf(1.0, r.tc[0]), r.tc[0], 100.0 * r.tc[3] / maxf(1.0, r.tc[2]), r.tc[2]])
	if not r.power.is_empty():
		var pl := "  powers (used on % of turns / share of uses at the turn's first chance / busts saved per use):"
		for n in NAMES:
			var s: Dictionary = r.power.get(n, {})
			if s.is_empty():
				continue
			pl += " %s %.0f/%.0f/%.0f" % [n.substr(0, 4), 100.0 * s.uses / maxf(1.0, s.turns), 100.0 * s.first / maxf(1.0, s.uses), 100.0 * s.saves / maxf(1.0, s.uses)]
		print(pl)


## Dice: (1) a bot given 4 or 5 dice free (never buying) against three 3-dice bots, with and without the
## Strike cap; (2) at prices 100, 75, 60, a bot buying to 3-6 dice (and an early-only buyer) against plain bots.
func _dice(games: int) -> void:
	for cap in [false, true]:
		var o := opts.duplicate()
		o["strike_cap"] = cap
		var line := "free dice, cap %s (vs three 3-dice bots, fair 25):" % ("on" if cap else "off")
		for d in [3, 4, 5, 6]:
			var b = SimBots.Plain.new(d, 300)
			var plain = SimBots.Plain.new(3, 300)
			var r := await _pass(o, games, 4, b, "", true, plain, d, 3)
			line += " %d dice %.1f" % [d, r.special_win]
		print(line)
	for cap in [false, true]:
		for price in [100, 75, 60]:
			var o := opts.duplicate()
			o["strike_cap"] = cap
			o["die_cost"] = price
			var line := "price %d, cap %s (buyer vs 3 plain buy-to-5 bots):" % [price, "on" if cap else "off"]
			for t in [3, 4, 5, 6]:
				var b = SimBots.Plain.new(t, 300)
				var r := await _pass(o, games, 4, b)
				line += " to %d: %.1f" % [t, r.special_win]
			var early = SimBots.Plain.new(6, 300)
			early.buy_until = 400
			var re := await _pass(o, games, 4, early)
			print(line + " | to 6 while leader < 400: %.1f" % re.special_win)


## First games: a novice against plain or easier bots, Onboarding game one (3 seats, no abilities, no
## temptations).
func _first(games: int) -> void:
	var o := opts.duplicate()
	o["tier2"] = false
	o["temptations"] = false
	o["powers"] = false
	var novice = SimBots.Novice.new(150)
	for cfg in [[300, 1.0, 5], [200, 1.5, 4], [200, 1.6, 4]]:
		var easy = SimBots.Plain.new(cfg[2], cfg[0])
		easy.risk = cfg[1]
		var r := await _pass(o, games, 3, novice, "", false, easy)
		print("first game (3 seats, no abilities), bots bank at %d risk %.1f buy to %d: novice wins %.1f%% (fair 33.3)" % [cfg[0], cfg[1], cfg[2], r.special_win])


## Mean edge over the 7 Sins of `b` (in a random seat) against 3 plain first-chance bots.
func _edge(b, games: int) -> String:
	var line := ""
	var all := 0.0
	for n in NAMES:
		var r := await _pass(opts, games, 4, b, n)
		line += " %s %.1f" % [n.substr(0, 4), r.special_win]
		all += r.special_win
	return "mean %.1f |%s" % [all / NAMES.size(), line]


## Skill edge split by decision: each bot is the plain bot with one decision changed.
func _split(games: int) -> void:
	opts["plain_smart"] = false
	var rows := []
	rows.append(["plain (control)", SimBots.Split.new(5)])
	rows.append(["buy: to 4 dice", SimBots.Split.new(4)])
	rows.append(["buy: to 3 dice", SimBots.Split.new(3)])
	var bank = SimBots.Best.new(5, 0.9, 0.0, 0.5, 0.3)
	bank.smart = false
	rows.append(["bank: risk follows standings", bank])
	var pw = SimBots.Split.new(5)
	pw.smart = true
	rows.append(["power: hold for a bad throw", pw])
	for m in ["weigh", "never", "always"]:
		var o = SimBots.Split.new(5)
		o.offer_mode = m
		rows.append(["offers: " + m, o])
	for m in ["leader", "next"]:
		var t = SimBots.Split.new(5)
		t.target_mode = m
		rows.append(["target: " + m, t])
	var all = SimBots.BestSplit.new(4, 0.9, 0.0, 0.5, 0.3)
	all.smart = false
	all.offer_mode = "weigh"
	rows.append(["all: best + weigh offers", all])
	for row in rows:
		print("%s: %s" % [row[0], await _edge(row[1], games)])


## The best bot against three novice stand-ins (sim/sim_bots.gd Novice), per Sin.
func _novice(games: int) -> void:
	var nov = SimBots.Novice.new(150)
	for cfg in [["best, first-chance powers", false], ["best, holds powers", true]]:
		var b = SimBots.BestSplit.new(4, 0.9, 0.0, 0.5, 0.3)
		b.smart = cfg[1]
		b.offer_mode = "weigh"
		var line := ""
		var all := 0.0
		for n in NAMES:
			var r := await _pass(opts, games, 4, b, n, true, nov)
			line += " %s %.1f" % [n.substr(0, 4), r.special_win]
			all += r.special_win
		print("%s vs 3 novices (fair 25): mean %.1f |%s" % [cfg[0], all / NAMES.size(), line])
