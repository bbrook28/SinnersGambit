## Sim-only bots for sim/agency_sim.gd. Nothing in the game uses this file.
extends RefCounted

const Rules = preload("res://core/rules.gd")
const BotPolicy = preload("res://ai/bot_policy.gd")


## The game's bot (BotPolicy.chooser(5, [99, 2, 0], 300)), aware of the sim's strike_cap.
class Plain extends "res://ai/bot_policy.gd":
	var smart := false
	var buy_until := 99999   # buy only while the leader is under this

	func _init(p_target := 5, p_bank_at := 300) -> void:
		super(p_target, 99999, 0, p_bank_at)
		cap_3_left = 99
		cap_2_left = 2
		cap_1_left = 0
		press_max_strikes = -2
		label = "plain buy%d" % p_target

	## Like BotPolicy.expected_after_throw, under strike_cap: dice beyond the third add at most one Strike.
	static func ev_capped(n: int, turn_points: int, strikes_left: int, chain: float, face_mult: int) -> float:
		var a := mini(n, 3)
		var m := n - a
		var ev := 0.0
		for k1 in a + 1:
			for s1 in a - k1 + 1:
				var p1 := _multi(a, k1, s1)
				for k2 in m + 1:
					for s2 in m - k2 + 1:
						var p2 := _multi(m, k2, s2)
						if k1 + mini(k2, 1) >= strikes_left:
							continue
						var s := s1 + s2
						var gain := 0.0
						if s > 0:
							gain = s * 5.0 * face_mult * (1.0 + chain * (s - 1))
						ev += p1 * p2 * (turn_points + gain)
		return ev


	static func _multi(n: int, k: int, s: int) -> float:
		var b := n - k - s
		return _fact(n) / (_fact(k) * _fact(b) * _fact(s)) * pow(1.0 / 3.0, k) * pow(1.0 / 6.0, b) * pow(0.5, s)



	func dice_to_buy(p, game) -> int:
		if game.leader_score() >= buy_until:
			return 0
		return target_dice - p.dice

	func risk_for(p, game) -> float:
		if game.opt("no_sin_risk", false):
			return risk
		return super(p, game)

	func ev(game, n: int, tp: int, left: int) -> float:
		if game.opt("strike_cap", false):
			return ev_capped(n, tp, left, game.chain, game.face_mult)
		return expected_after_throw(n, tp, left, game.chain, game.face_mult)

	func wants_throw(p, game, turn_points: int, strikes: int) -> bool:
		if game.turn.throws == 0:
			return true
		var total: int = p.score + turn_points
		if game.finish_round and game.end_triggered:
			return total <= game.leader_score()
		if game.v4 and game.claimed(p, "Pride") and turn_points < int(game.opt("claim_pride_min", 0)):
			return true
		if game.turn.min_points >= 0 and turn_points < game.turn.min_points:
			return true
		if total >= Rules.WIN_SCORE and total > game.leader_score():
			return false
		if turn_points >= bank_at:
			return false
		return ev(game, game._max_throw(p), turn_points, Rules.STRIKES_TO_BUST - strikes) > turn_points * risk_for(p, game)


## The best bot we have: the plain bot's one-throw lookahead, but its risk follows the standings
## (bank sooner when ahead), it buys to `target` dice, no bank cap, and it weighs its power (smart).
class Best extends Plain:
	var base := 1.0
	var kb := 0.0    # behind: risk falls by kb x deficit/1000 x (0.5 + progress)
	var ka := 0.5    # ahead: risk rises by ka x lead/1000
	var late := 0.3  # someone else at 850+ and I'm behind: push this much harder

	func _init(p_target := 4, p_base := 0.9, p_kb := 0.0, p_ka := 0.5, p_late := 0.3) -> void:
		super(p_target, 9999)
		base = p_base
		kb = p_kb
		ka = p_ka
		late = p_late
		smart = true
		label = "best t%d b%.2f kb%.1f ka%.1f l%.1f" % [p_target, p_base, p_kb, p_ka, p_late]

	func risk_for(p, game) -> float:
		var lead = game.leader_other(p)
		if lead == null:
			return base
		var d := float(lead.score - p.score) / 1000.0
		var prog := float(maxi(lead.score, p.score)) / 1000.0
		var r := base
		if d > 0.0:
			r -= kb * d * (0.5 + prog)
			if lead.score >= 850:
				r -= late
		else:
			r += ka * -d
		return clampf(r, 0.4, 1.8)


## A new player, roughly: throws again while the turn is under `stop` and it has fewer than 2 Strikes;
## buys to 4 dice. (A stand-in for a first game; real players will vary.)
class Novice extends "res://ai/bot_policy.gd":
	var stop := 150

	func _init(p_stop := 150) -> void:
		super(4, 99999, 0, 9999)
		stop = p_stop
		press_max_strikes = -2
		label = "novice stop%d" % p_stop

	func wants_throw(p, game, turn_points: int, strikes: int) -> bool:
		if game.turn.throws == 0:
			return true
		if game.turn.min_points >= 0 and turn_points < game.turn.min_points:
			return true
		if p.score + turn_points >= 1000:
			return false
		return turn_points < stop and strikes < 2
