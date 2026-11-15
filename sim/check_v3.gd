## Rules.V2 vs Rules.V3 with Sins: win rate per Sin, game length, busts and Purgatory.
## godot --headless --path . --script res://sim/check_v3.gd [-- games]
## Every game: a table of 7 (one of each Sin) or 4 (random Sins), seats shuffled, Greater on.
## Rules.V4 (Docs/TableDesign.md §9): -- <games> v4 [key=value ...]  (a key overrides Rules.V4, e.g. tempt_chance=0.4)
##   tables of 4 and 7 with temptations: win % per Sin vs fair, offers accepted (overall and each),
##   claims per game, Purgatory, minutes per game; then Purgatory off (4 seats) and each claim's cost.
extends SceneTree

const Rules = preload("res://core/rules.gd")
const Game = preload("res://core/game.gd")
const BotPolicy = preload("res://ai/bot_policy.gd")
const Temptations = preload("res://sins/temptations.gd")
const SIN_SCRIPTS := [
	preload("res://sins/wrath.gd"), preload("res://sins/greed.gd"), preload("res://sins/lust.gd"),
	preload("res://sins/envy.gd"), preload("res://sins/pride.gd"), preload("res://sins/gluttony.gd"),
	preload("res://sins/sloth.gd"),
]
## Minutes model (TableDesign §9): your turn 3 s + 3 s a throw, a bot turn 2.5 s, a handoff 2 s, an offer 3 s.
const YOUR_TURN := 3.0
const PER_THROW := 3.0
const BOT_TURN := 2.5
const HANDOFF := 2.0
const OFFER := 3.0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var games: int = int(args[0]) if args.size() > 0 and args[0].is_valid_int() else 4000
	var bot = BotPolicy.chooser(5, [99, 2, 0], 300)
	if "v4" in args:
		BotPolicy.log_values = "values" in args
		var v4 := Rules.V4.duplicate()
		v4["tier2"] = true
		var parts := []
		for a in args:
			if "=" in a:
				var kv: PackedStringArray = a.split("=")
				if kv[0] == "only":
					parts = Array(kv[1].split(","))
				else:
					v4[kv[0]] = str_to_var(kv[1])
		await _v4(v4, games, bot, parts)
		quit()
		return
	for rules in [["V2", Rules.V2], ["V3", Rules.V3]]:
		for table in [4, 7]:
			for tier2 in [false, true]:
				await _run(rules[0], rules[1], table, tier2, games, bot)
	quit()


func _run(name: String, rules: Dictionary, table: int, tier2: bool, games: int, bot) -> void:
	var options := rules.duplicate()
	options["tier2"] = tier2
	var wins := {}
	var seats_in := {}
	var rounds := 0
	var turns := 0
	var busts := 0
	var throws_per_turn := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for g in games:
		var game = _game(rng, table, options, bot, g)
		var w = await game.play()
		rounds += game.round_count
		for p in game.players:
			turns += p.turns
			busts += p.busts
			throws_per_turn += p.presses
			seats_in[p.sin.sin_name] = seats_in.get(p.sin.sin_name, 0) + 1
		wins[w.sin.sin_name] = wins.get(w.sin.sin_name, 0) + 1
	var line := "%s table %d %s: rounds %.1f, busts/turn %.2f, throws/turn %.2f |" % [
		name, table, "Basic+Greater" if tier2 else "Basic only", float(rounds) / games,
		float(busts) / turns, 1.0 + throws_per_turn / turns]
	# Win share relative to fair (1.00 = wins exactly its share of the games it sat in).
	for s in SIN_SCRIPTS:
		var n: String = s.new().sin_name
		var fair := float(seats_in.get(n, 0)) / table
		line += " %s %.2f" % [n.substr(0, 4), float(wins.get(n, 0)) / maxf(1.0, fair)]
	print(line)


## A table of `table` random Sins, seats shuffled (rng draws them, so passes with one seed match).
func _game(rng: RandomNumberGenerator, table: int, options: Dictionary, bot, seed_value: int):
	var pool := SIN_SCRIPTS.duplicate()
	for i in range(pool.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = pool[i]
		pool[i] = pool[j]
		pool[j] = t
	var sins := []
	var bots := []
	for i in table:
		sins.append(pool[i].new())
		bots.append(bot)
	return Game.new(bots, seed_value, options, sins)


# ---------- Rules.V4 ----------

## parts: empty for everything, else any of "4", "7", "purg", "claims".
func _v4(v4: Dictionary, games: int, bot, parts: Array) -> void:
	print("V4 (tempt_chance %s, marks_to_claim %s, mark_weight %s), %d games a pass" % [v4.tempt_chance, v4.marks_to_claim, v4.mark_weight, games])
	var base4 := {}
	for table in [4, 7]:
		if parts.is_empty() or str(table) in parts or (table == 4 and "purg" in parts):
			var r := await _v4_pass(v4, table, games, bot)
			if table == 4:
				base4 = r
			if parts.is_empty() or str(table) in parts:
				_v4_report(r, table)
	if parts.is_empty() or "purg" in parts:
		var off := v4.duplicate()
		off["purgatory"] = false
		var r_off := await _v4_pass(off, 4, games, bot)
		var line := "Purgatory off, 4 seats: minutes %.1f (on %.1f), rounds %.1f (on %.1f) | win %% change:" % [
			r_off.minutes1, base4.minutes1, float(r_off.rounds) / games, float(base4.rounds) / games]
		for n in _names():
			line += " %s %+.1f" % [n.substr(0, 4), r_off.win_pct[n] - base4.win_pct[n]]
		print(line)
	if parts.is_empty() or "claims" in parts:
		await _claim_costs(v4, games, bot)


func _names() -> Array:
	return SIN_SCRIPTS.map(func(s): return s.new().sin_name)


func _v4_pass(options: Dictionary, table: int, games: int, bot, force := {}) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var wins := {}
	var seats_in := {}
	var r := {"games": games, "rounds": 0, "turns": 0, "busts": 0, "throws": 0, "offers": 0, "taken": 0,
		"claims": 0, "purg": 0, "purg_free": 0, "purg_paid": 0, "secs1": 0.0, "secsall": 0.0, "stats": {}, "seat_wins": 0}
	var opts := options
	if not force.is_empty():
		opts = options.duplicate()
		opts["force_claim"] = force
	for g in games:
		var game = _game(rng, table, opts, bot, g)
		var w = await game.play()
		r.rounds += game.round_count
		r.claims += game.claims_made
		r.purg += game.purg_throws
		r.purg_free += game.purg_free
		r.purg_paid += game.purg_paid
		if w.seat == 0:
			r.seat_wins += 1
		for id in game.offer_stats:
			if not r.stats.has(id):
				r.stats[id] = [0, 0]
			r.stats[id][0] += game.offer_stats[id][0]
			r.stats[id][1] += game.offer_stats[id][1]
		for p in game.players:
			r.turns += p.turns
			r.busts += p.busts
			r.throws += p.turns + p.presses
			r.offers += p.offers_seen
			r.taken += p.offers_taken
			seats_in[p.sin.sin_name] = seats_in.get(p.sin.sin_name, 0) + 1
			var human_secs: float = p.turns * YOUR_TURN + (p.turns + p.presses) * PER_THROW + p.offers_seen * OFFER
			r.secsall += human_secs + p.turns * HANDOFF
			r.secs1 += human_secs if p.seat == 0 else p.turns * BOT_TURN
		wins[w.sin.sin_name] = wins.get(w.sin.sin_name, 0) + 1
	r.win_pct = {}
	r.fair_pct = 100.0 / table
	for n in _names():
		r.win_pct[n] = 100.0 * wins.get(n, 0) / maxf(1.0, seats_in.get(n, 0))
	r.minutes1 = r.secs1 / games / 60.0
	r.minutesall = r.secsall / games / 60.0
	return r


func _v4_report(r: Dictionary, table: int) -> void:
	var g: float = r.games
	var line := "V4 table %d: rounds %.1f, busts/turn %.2f, throws/turn %.2f, minutes %.1f (you + bots) / %.1f (all human) | win %% (fair %.1f):" % [
		table, r.rounds / g, float(r.busts) / r.turns, float(r.throws) / r.turns, r.minutes1, r.minutesall, r.fair_pct]
	for n in _names():
		line += " %s %.1f" % [n.substr(0, 4), r.win_pct[n]]
	print(line)
	print("  offers %.1f a game, accepted %.0f%%, claims %.2f a game | Purgatory %.1f a game, freed by a 6 %.0f%%, paid %.0f a game" % [
		r.offers / g, 100.0 * r.taken / maxf(1.0, r.offers), r.claims / g, r.purg / g, 100.0 * r.purg_free / maxf(1.0, r.purg), r.purg_paid / g])
	var each := "  accepted per offer:"
	for id in Temptations.all_ids():
		var s: Array = r.stats.get(id, [0, 0])
		each += " %s %s" % [id, ("%.0f" % (100.0 * s[1] / s[0])) if s[0] > 0 else "-"]
	print(each)
	if BotPolicy.log_values:
		var vals := "  offer value to the bot, p25/p50/p75:"
		for id in Temptations.all_ids():
			var v: Array = BotPolicy.value_log.get(id, [])
			v.sort()
			if v.size() > 3:
				vals += " %s %d/%d/%d" % [id, v[v.size() / 4], v[v.size() / 2], v[v.size() * 3 / 4]]
		print(vals)
		BotPolicy.value_log.clear()


## Each claim forced on seat 0 from round 3 at 4 seats, offers off to isolate it: seat 0's win chance
## against the same games (same seeds) without, as a relative drop.
func _claim_costs(v4: Dictionary, games: int, bot) -> void:
	var off := v4.duplicate()
	off["temptations"] = false
	var base := await _v4_pass(off, 4, games, bot)
	var line := "Claim cost at 4 seats (seat 0 wins %.1f%% without; relative drop):" % (100.0 * base.seat_wins / games)
	for n in _names() + ["50", "100", "150"]:  # the numbers: a plain points loss, to price a claim
		var r := await _v4_pass(off, 4, games, bot, {"seat": 0, "sin": n, "round": 3})
		var drop := 1.0 - float(r.seat_wins) / maxf(1.0, base.seat_wins)
		line += " %s %.0f%%" % [n.substr(0, 4), 100.0 * drop]
	print(line)
