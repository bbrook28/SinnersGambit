## Gluttony, the Devourer. Eats dice.
## T1 Feast (after throw, once per turn): feed one die from this throw back to the Supply
## for +90 points (banked at once). Feeding a Strike die cancels that Strike.
## Respects the two-die floor. (+75: 9% win, +100: 18%.)
extends "res://sins/sin.gd"

const Rules = preload("res://core/rules.gd")
const FEAST := 90


func _init() -> void:
	sin_name = "Gluttony"


func after_throw(game, me, turn) -> void:
	if turn.used_t1 or me.dice <= Rules.MIN_DICE:
		return
	# Bot: feast when this throw would bring you to 2+ Strikes, so you can keep pressing.
	var strikes_here := 0
	var strike_i := -1
	for i in turn.faces.size():
		if turn.faces[i] <= 2:
			strikes_here += 1
			strike_i = i
	if strike_i < 0 or turn.strikes + strikes_here < Rules.STRIKES_TO_BUST - 1:
		return
	turn.faces.remove_at(strike_i)
	me.dice -= 1
	game.supply += 1
	me.score += FEAST
	turn.used_t1 = true
