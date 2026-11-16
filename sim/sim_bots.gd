## Sim-only bots for sim/agency_sim.gd. Nothing in the game uses this file.
extends RefCounted

const BotPolicy = preload("res://ai/bot_policy.gd")


## The best bot we have: the plain bot's one-throw lookahead, but its risk follows the standings
## (push when behind, more so late; bank sooner when ahead), and it buys to `target` dice.
class Best extends "res://ai/bot_policy.gd":
	var base := 1.0
	var kb := 1.0    # behind: risk falls by kb x deficit/1000 x (0.5 + progress)
	var ka := 0.0    # ahead: risk rises by ka x lead/1000
	var late := 0.2  # someone else at 850+ and I'm behind: push this much harder

	func _init(p_target := 5, p_base := 1.0, p_kb := 1.0, p_ka := 0.0, p_late := 0.2) -> void:
		super(p_target, 99999, 0, 9999)
		base = p_base
		kb = p_kb
		ka = p_ka
		late = p_late
		press_max_strikes = -2
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
