## Greybox duel (rework direction B): heads-up V5 on today's core, bots only. The table's options (the Master's
## call at 550, never before round 3's end, the final round from the leader down, powers, temptations), no bets.
## Win share per Sin and by seat, length, how early a duel is decided, comebacks, temptations and claims.
## godot --headless --path . --script res://proto/duel_sim.gd -- [games] [key=value ...]
extends SceneTree

const Rules = preload("res://core/rules.gd")
const Game = preload("res://core/game.gd")
const BotPolicy = preload("res://ai/bot_policy.gd")
const SIN_SCRIPTS := [
	preload("res://sins/wrath.gd"), preload("res://sins/greed.gd"), preload("res://sins/lust.gd"),
	preload("res://sins/envy.gd"), preload("res://sins/pride.gd"), preload("res://sins/gluttony.gd"),
	preload("res://sins/sloth.gd"),
]
const NAMES := ["Wrath", "Greed", "Lust", "Envy", "Pride", "Gluttony", "Sloth"]


## The table's rules (ui/main.gd table_rules) without the bets.
static func duel_rules() -> Dictionary:
	var r: Dictionary = Rules.V5.duplicate()
	r["master_call"] = Rules.MASTER_CALL
	r["call_floor"] = Rules.MASTER_CALL_FLOOR
	r["final_from_leader"] = true
	r["tier2"] = true
	r["temptations"] = true
	return r


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var games: int = int(args[0]) if args.size() > 0 and args[0].is_valid_int() else 4000
	var o := duel_rules()
	for a in args:
		if "=" in a:
			var kv: PackedStringArray = a.split("=")
			o[kv[0]] = str_to_var(kv[1])
	var bot = BotPolicy.chooser(5, [99, 2, 0], 300)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var wins := {}
	var seats := {}
	var seat_wins := [0, 0]
	var rounds := 0
	var turns := 0
	var throws := 0
	var busts := 0
	var lead3_held := 0
	var lead3_games := 0
	var behind150 := 0
	var behind150_won := 0
	var margin := 0
	var offers := 0
	var accepted := 0
	var claims := 0
	var round_hist := {}
	for g in games:
		var a := rng.randi_range(0, 6)
		var b := (a + rng.randi_range(1, 6)) % 7
		var game := Game.new([bot, bot], g, o, [SIN_SCRIPTS[a].new(), SIN_SCRIPTS[b].new()])
		var leader3 := -1
		var was_behind := [false, false]
		while game.winner == null and game.round_count < game.MAX_ROUNDS:
			game.round_count += 1
			if game.called_round >= 0 and game.round_count == game.called_round + 2:
				game.finish_round = true
				game.end_triggered = true
			game.mark_leader()
			for p in (game.final_order() if game.end_triggered else game.players):
				var t0: int = p.turns
				await game.take_turn(p)
				turns += p.turns - t0
				throws += game.turn.throws
				if game.turn.strikes >= Rules.STRIKES_TO_BUST:
					busts += 1
				for q in game.players:
					var other = game.players[1 - q.seat]
					if other.score - q.score >= 150:
						was_behind[q.seat] = true
				if game.winner != null:
					break
			if game.winner != null:
				break
			if game.round_count == 3 and game.players[0].score != game.players[1].score:
				leader3 = 0 if game.players[0].score > game.players[1].score else 1
			if game.end_triggered:
				game._resolve_finish()
			elif game.master_call > 0 and game.called_round < 0 and game.leader_score() >= game.master_call and game.round_count >= game.call_floor:
				game.called_round = game.round_count
		var w = game.winner
		rounds += game.round_count
		round_hist[game.round_count] = round_hist.get(game.round_count, 0) + 1
		seat_wins[w.seat] += 1
		margin += absi(game.players[0].score - game.players[1].score)
		for p in game.players:
			seats[p.sin.sin_name] = seats.get(p.sin.sin_name, 0) + 1
			offers += p.get("offers_seen") if p.get("offers_seen") != null else 0
			accepted += p.get("offers_taken") if p.get("offers_taken") != null else 0
			claims += p.claims.size() if p.get("claims") != null else 0
			if was_behind[p.seat]:
				behind150 += 1
				if p == w:
					behind150_won += 1
		wins[w.sin.sin_name] = wins.get(w.sin.sin_name, 0) + 1
		if leader3 >= 0:
			lead3_games += 1
			if leader3 == w.seat:
				lead3_held += 1
	var line := "duel V5 on core, %d games, 2 seats: win %% (fair 50):" % games
	var lo := 100.0
	var hi := 0.0
	for n in NAMES:
		var wv: float = 100.0 * wins.get(n, 0) / maxf(1.0, seats.get(n, 0))
		lo = minf(lo, wv)
		hi = maxf(hi, wv)
		line += " %s %.1f" % [n.substr(0, 4), wv]
	print(line + " | range %.1f-%.1f" % [lo, hi])
	print("  first seat wins %.1f%%, second %.1f%%" % [100.0 * seat_wins[0] / games, 100.0 * seat_wins[1] / games])
	print("  rounds %.2f a duel, turns %.1f, throws a turn %.2f, busts a turn %.2f, final margin %d" % [
		float(rounds) / games, float(turns) / games, float(throws) / maxf(1.0, turns), float(busts) / maxf(1.0, turns), margin / games])
	var rh := "  duel length (rounds: share):"
	var ks: Array = round_hist.keys()
	ks.sort()
	for k in ks:
		rh += " %d: %.0f%%" % [k, 100.0 * round_hist[k] / games]
	print(rh)
	print("  the leader after round 3 wins %.1f%%; a seat ever 150+ behind wins %.1f%% (of %d)" % [
		100.0 * lead3_held / maxf(1.0, lead3_games), 100.0 * behind150_won / maxf(1.0, behind150), behind150])
	print("  temptations: offers %.1f a duel, accepted %.0f%%, claims %.2f a duel" % [
		float(offers) / games, 100.0 * accepted / maxf(1.0, offers), float(claims) / games])
	quit()
