## Pride, the Untouchable. Bold calls.
## T1 Hubris (before roll): call "I Am Superior". Bank more than the previous player's
## turn and score x1.6; bank less or equal and score 0. Floor of 50 to beat. (x1.5: 12% win, x1.75: 17%.)
## T2 Untouchable (reaction): the first attack on you each round bounces onto the attacker
## (Fury hits their next throw, a Pact reverses, Drag slows them). Bot: always bounces.
## (Bounce only, no bonus: 14.8%. Bounces ~0.4 times a game, so it barely moves Pride; T1 alone was 14.2%.)
extends "res://sins/sin.gd"

const FLOOR := 50
const MULT := 1.6
## Bot: only call when the bar is at or below this.
const CALL_IF_AT_MOST := 100


func _init() -> void:
	sin_name = "Pride"


func before_turn(game, me, turn) -> void:
	var bar := maxi(FLOOR, game.last_turn_points)
	if me.bot.human:
		if not await me.bot.ask(game, "Hubris? Call \"I Am Superior\": bank more than %d for x%.1f, otherwise score 0." % [bar, MULT]):
			return
	elif bar > CALL_IF_AT_MOST:
		return
	turn.min_points = bar
	if game.view:
		fired(game, me, "Hubris", "\"I Am Superior\". Must bank more than %d" % bar)


func on_bank(_game, _me, turn, points: int) -> int:
	if turn.min_points < 0:
		return points
	return int(points * MULT) if points > turn.min_points else 0


func bounces(game, me, attacker, kind: String) -> bool:
	if not game.t2_available(me):
		return false
	if me.bot.human:
		return await me.bot.ask(game, "Untouchable? Bounce %s's %s back onto them." % [game.pname(attacker), {"reroll": "Fury", "pact": "Binding Pact", "drag": "Drag"}[kind]])
	return true
