## Gluttony, the Devourer. Eats dice.
## T1 Feast (after throw, once per turn): feed one die from this throw back to the Supply
## for +90 points (banked at once). Feeding a Strike die cancels that Strike.
## Respects the two-die floor. (+75: 9% win, +100: 18%.)
## T2 Gorge (Gambit): once a turn, buy one die for GORGE_PRICE instead of 100. Bot: buys as usual, cheap die first.
## (70: 14.7%, unchanged. With Feast +90 it nets +20 a turn per feed-and-rebuy.)
extends "res://sins/sin.gd"

const Rules = preload("res://core/rules.gd")
const FEAST := 90
const GORGE_PRICE := 70


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


func buy_price(game, me, n: int) -> int:
	if n > 0 and game.t2_available(me):
		return GORGE_PRICE + (n - 1) * die_cost(game, me)
	return n * die_cost(game, me)


func gambit(game, me, bought: int) -> void:
	if bought > 0:
		game.mark_t2(me)
