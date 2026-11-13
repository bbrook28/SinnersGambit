## Base Sin. Each hook is a timing window; override the ones the Sin uses.
## `me` is the PlayerState holding this Sin. `turn` is the active TurnState.
extends RefCounted

var sin_name := "None"


## Before roll, own turn. Pride declares here.
func before_turn(_game, _me, _turn) -> void:
	pass


## After each throw on your own turn, before the Strike check. May edit turn.faces / me.dice.
func after_throw(_game, _me, _turn) -> void:
	pass


## When you bank. Return the adjusted turn points.
func on_bank(_game, _me, turn, points: int) -> int:
	return points


## Price you pay for one die.
func die_cost(game, _me) -> int:
	return game.die_cost


## Passive: another player busted.
func on_other_bust(_game, _me, _other) -> void:
	pass


## Passive: another player bought n dice. Return points they pay to you (taken out of the bank's share).
func on_other_buy(_game, _me, _other, _n: int) -> int:
	return 0
