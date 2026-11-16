## Agency and comeback measures (Ben, 2026-11-15; Docs/TableDesign.md §10). Sim only: prototype rules
## run through sim/sim_game.gd and sim/sim_bots.gd, so core/, sins/ and ai/ stay untouched.
## godot --headless --path . --script res://sim/agency_sim.gd -- <pass> [games] [key=value ...]
##   pass: base | skill | tune | first   (key=value overrides Rules.V4, e.g. purgatory=false rethrow=true)
## Every pass reports, at 4 seats with Basic + Greater and temptations on (Rules.V4):
##   win % per Sin; comebacks (share of games won by whoever was last when the leader first reached 500);
##   lead changes a game; the share of the last-placed seat's turns that began in Purgatory (and all seats');
##   throws a turn, minutes (TableDesign §9 model, +2 s a rethrow).
extends SceneTree

const Rules = preload("res://core/rules.gd")
const SimGame = preload("res://sim/sim_game.gd")
const BotPolicy = preload("res://ai/bot_policy.gd")
const SimBots = preload("res://sim/sim_bots.gd")
const SIN_SCRIPTS := [
	preload("res://sins/wrath.gd"), preload("res://sins/greed.gd"), preload("res://sins/lust.gd"),
	preload("res://sins/envy.gd"), preload("res://sins/pride.gd"), preload("res://sins/gluttony.gd"),
	preload("res://sins/sloth.gd"),
]
const HALF := 500


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var mode: String = args[0] if args.size() > 0 else "base"
	var games: int = int(args[1]) if args.size() > 1 and args[1].is_valid_int() else 2000
	var opts := Rules.V4.duplicate()
	opts["tier2"] = true
	var best_cfg := [5, 1.0, 1.0, 0.0, 0.2]
	for a in args:
		if "=" in a:
			var kv: PackedStringArray = a.split("=")
			if kv[0] == "best":
				best_cfg = Array(kv[1].split(",")).map(func(x): return str_to_var(x))
			else:
				opts[kv[0]] = str_to_var(kv[1])
	match mode:
		"base":
			_report("plain bots", await _pass(opts, games, 4, -1, null))
		"skill":
			var b = SimBots.Best.new(best_cfg[0], best_cfg[1], best_cfg[2], best_cfg[3], best_cfg[4])
			var line := "skill edge (%s vs 3 plain bots, 4 seats, fair 25): " % b.label
			var all := 0.0
			for s in SIN_SCRIPTS:
				var n: String = s.new().sin_name
				var r := await _pass(opts, games, 4, 0, b, n)
				line += " %s %.1f" % [n.substr(0, 4), r.special_win]
				all += r.special_win
			print(line + " | mean %.1f" % (all / SIN_SCRIPTS.size()))
		"tune":
			for t in [5, 6]:
				for base in [0.9, 1.0, 1.1]:
					for kb in [0.0, 1.0, 2.0]:
						for ka in [0.0, 0.5]:
							var b = SimBots.Best.new(t, base, kb, ka, 0.3)
							var r := await _pass(opts, games, 4, 0, b)
							print("%s: %.1f" % [b.label, r.special_win])
		"first":
			_first(games)
	quit()


## A table of `table` Sins, seats shuffled. special_seat >= 0 seats `special` there (with Sin `special_sin`
## when given); everyone else is the plain bot.
func _pass(opts: Dictionary, games: int, table: int, special_seat: int, special, special_sin := "", sins_on := true, plain = null) -> Dictionary:
	if plain == null:
		plain = BotPolicy.chooser(5, [99, 2, 0], 300)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var r := {"games": games, "wins": {}, "seats_in": {}, "comebacks": 0, "halves": 0, "leads": 0,
		"last_turns": 0, "last_purg": 0, "turns": 0, "purg_turns": 0, "throws": 0, "rethrows": 0, "saves": 0,
		"special_wins": 0, "secs": 0.0, "rounds": 0, "last_score": 0, "lead_score": 0}
	for g in games:
		var pool := SIN_SCRIPTS.duplicate()
		for i in range(pool.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var t = pool[i]
			pool[i] = pool[j]
			pool[j] = t
		if special_sin != "":
			pool = pool.filter(func(s): return s.new().sin_name != special_sin)
		var seat := rng.randi_range(0, table - 1) if special_seat >= 0 else -1
		var sins := []
		var bots := []
		var k := 0
		for i in table:
			if i == seat and special_sin != "":
				sins.append(_sin_named(special_sin))
			else:
				sins.append(pool[k].new())
				k += 1
			bots.append(special if i == seat else plain)
		var game = SimGame.new(bots, g, opts, sins if sins_on else [])
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
		var best_other := 0
		for p in game.players:
			if p.score < last.score:
				last = p
		for p in game.players:
			if p != w:
				best_other = maxi(best_other, p.score)
		r.last_score += last.score
		r.last_turns += last.turns
		r.last_purg += st.purg[last.seat]
		for p in game.players:
			r.turns += p.turns
			r.throws += p.turns + p.presses
			r.purg_turns += st.purg[p.seat]
		r.rethrows += game.rethrows
		r.saves += game.rethrow_saves
		# Minutes, you + bots (TableDesign §9): seat 0 is "you", the rest bot turns of 2.5 s.
		var you = game.players[0]
		r.secs += you.turns * 3.0 + (you.turns + you.presses) * 3.0 + you.offers_seen * 3.0
		for p in game.players:
			if p != you:
				r.secs += p.turns * 2.5
		r.secs += game.rethrows * 2.0 / table
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


func _sin_named(n: String):
	for s in SIN_SCRIPTS:
		var o = s.new()
		if o.sin_name == n:
			return o
	return null


func _report(name: String, r: Dictionary) -> void:
	var g: float = r.games
	var line := "%s: win %% per Sin (fair 25):" % name
	for s in SIN_SCRIPTS:
		var n: String = s.new().sin_name
		line += " %s %.1f" % [n.substr(0, 4), 100.0 * r.wins.get(n, 0) / maxf(1.0, r.seats_in.get(n, 0))]
	print(line)
	print("  comebacks %.1f%% (last at %d wins), lead changes %.2f a game, last seat's turns in Purgatory %.1f%% (all seats %.1f%%), last seat ends on %d" % [
		100.0 * r.comebacks / maxf(1.0, r.halves), HALF, float(r.leads) / g, 100.0 * r.last_purg / maxf(1.0, r.last_turns),
		100.0 * r.purg_turns / maxf(1.0, r.turns), r.last_score / g])
	print("  throws a turn %.2f, rounds %.1f, minutes %.1f (you + 3 bots), rethrows %.2f a turn (%.0f%% of them saved a bust)" % [
		float(r.throws) / r.turns, r.rounds / g, r.secs / g / 60.0, float(r.rethrows) / r.turns, 100.0 * r.saves / maxf(1.0, r.rethrows)])


## First games: a novice in seat 0 against plain or easier bots. Today: 4 seats, Basic only, no
## temptations. Onboarding game one: 3 seats, no abilities, no temptations.
func _first(games: int) -> void:
	var today := Rules.V4.duplicate()
	today["tier2"] = false
	today["temptations"] = false
	var novice = SimBots.Novice.new(150)
	for setup in [["today: 4 seats, Basic only", today, 4, true], ["Onboarding game one: 3 seats, no abilities", today, 3, false]]:
		for bank_at in [300, 200, 150, 100]:
			for risk in [1.0, 1.3, 1.6]:
				if bank_at < 300 and risk == 1.0 and bank_at != 150:
					continue
				var easy = BotPolicy.chooser(5 if bank_at >= 300 else 4, [99, 2, 0], bank_at)
				easy.risk = risk
				var r := await _pass(setup[1], games, setup[2], 0, novice, "", setup[3], easy)
				print("%s, bots bank at %d risk %.1f: novice wins %.1f%% (fair %.1f)" % [setup[0], bank_at, risk, r.special_win, 100.0 / setup[2]])
