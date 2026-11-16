## Gluttony, the Devourer. Eats dice.
## T1 Feast (after throw, once per turn): feed one die from this throw back to the Supply
## for +90 points (banked at once). Feeding a Strike die cancels that Strike.
## Respects the two-die floor. (+75: 9% win, +100: 18%, under V2.)
## T2 Gorge (Gambit): once a turn, buy one die for GORGE_PRICE instead of 100. Bot: buys as usual, cheap die first.
## Feast was 90 until 2026-11-13: with Gorge 70, feed-and-rebuy netted +20 a turn. At 50 it costs 20.
extends "res://sins/sin.gd"

const Rules = preload("res://core/rules.gd")
const FEAST := 50
const GORGE_PRICE := 70


func _init() -> void:
	sin_name = "Gluttony"


func after_throw(game, me, turn) -> void:
	if game.v5:
		return  # V5: Feast off; the power is Devour
	if turn.used_t1 or me.dice <= Rules.MIN_DICE:
		return
	var feed_i := -1
	if me.bot.human:
		# Human: offered every throw until used; feeds the lowest die (Strikes first).
		for i in turn.faces.size():
			if feed_i < 0 or turn.faces[i] < turn.faces[feed_i]:
				feed_i = i
		if feed_i < 0 or not await me.bot.ask(game, "Feast? Give up your %d for +%d (you lose the die for good)." % [turn.faces[feed_i], game.opt("feast", FEAST)]):
			return
	else:
		# Bot: feast when this throw would bring you to 2+ Strikes, so you can keep pressing.
		var strikes_here := 0
		for i in turn.faces.size():
			if turn.faces[i] <= 2:
				strikes_here += 1
				feed_i = i
		if feed_i < 0 or turn.strikes + strikes_here < Rules.STRIKES_TO_BUST - 1:
			return
	if game.view:
		fired(game, me, "Feast", "gives up a %d for +%d (%d dice left)" % [turn.faces[feed_i], game.opt("feast", FEAST), me.dice - 1])
	turn.faces.remove_at(feed_i)
	me.dice -= 1
	game.supply += 1
	me.score += int(game.opt("feast", FEAST))
	turn.used_t1 = true


func buy_price(game, me, n: int) -> int:
	if n > 0 and game.t2_available(me):
		return int(game.opt("gorge", GORGE_PRICE)) + (n - 1) * die_cost(game, me)
	return n * die_cost(game, me)


func gambit(game, me, bought: int) -> void:
	if bought > 0:
		game.mark_t2(me)
		if game.view:
			fired(game, me, "Gorge", "first die cost %d" % game.opt("gorge", GORGE_PRICE))


# V5 power (Docs/TableDesign.md §10): eat a Strike die from this throw for +eat to the stake. The die
# is back next turn.
func power_window() -> String:
	return "throw"


func power_ready(_game, _me, turn) -> bool:
	return turn.faces.has(1) or turn.faces.has(2)


func use_power(game, me, turn, _choice) -> bool:
	var i: int = turn.faces.find(1)
	if i < 0:
		i = turn.faces.find(2)
	var eat: int = game.opt("eat", 90)
	if game.view:
		fired(game, me, "Devour", "eats a %d: +%d" % [turn.faces[i], eat])
	turn.faces.remove_at(i)
	turn.points += eat
	return false
