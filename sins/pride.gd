## Pride, the Untouchable. Bold calls.
## Basic, Hubris (before your first throw): name a target (100, 150 or 200). Bank at least that
## and score x1.5; bank less and score 0. (Replaced "beat the previous player's turn, min 50, x1.6",
## 2026-11-13: two hidden rules and an odd multiplier.)
## Greater, Untouchable (reaction): the first attack on you each round bounces onto the attacker
## (Fury hits their next throw, a Pact reverses, Drag slows them). Bot: always bounces.
extends "res://sins/sin.gd"

const TARGETS := [100, 150, 200]
const MULT := 1.5
## Bot: always bets this.
const BOT_TARGET := 100


func _init() -> void:
	sin_name = "Pride"


func before_turn(game, me, turn) -> void:
	var targets: Array = game.opt("hubris_targets", TARGETS)
	var target: int = targets[0] if game.v4 else BOT_TARGET
	if me.bot.human:
		var options := [["No bet", -1]]
		for t in targets:
			options.append(["Bet %d" % t, t])
		target = await me.bot.pick(game, "Hubris? Bet you'll bank at least this: x%s if you do, 0 if not." % _mult_str(), options)
		if target < 0:
			return
	turn.min_points = target
	if game.view:
		fired(game, me, "Hubris", "bets %d. Must bank at least %d" % [target, target])


func on_bank(_game, _me, turn, points: int) -> int:
	if turn.min_points < 0:
		return points
	var mult: float = _game.opt("hubris_mult", MULT) if _game else MULT
	var out := int(points * mult) if points >= turn.min_points else 0
	return out / 5 * 5 if _game and _game.round5 else out


static func _mult_str() -> String:
	return str(MULT)


func bounces(game, me, attacker, kind: String) -> bool:
	if not game.t2_available(me):
		return false
	if me.bot.human and not game.v4:
		return await me.bot.ask(game, "Untouchable? Bounce %s's %s back onto them." % [game.pname(attacker), {"reroll": "Fury", "pact": "Binding Pact", "drag": "Drag"}[kind]])
	return true
