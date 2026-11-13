## The human player's decision source. Same methods as ai/bot_policy.gd, but each one shows
## a prompt in the UI and waits for a button (ui/main.gd emits `answered`).
extends RefCounted

signal answered(value)

var human := true
var label := "You"
var view  # ui/main.gd


## Shows text with buttons ([label, value] pairs) and returns the value of the one pressed.
func _choose(text: String, options: Array):
	view.show_prompt(text, options)
	var v = await answered
	view.clear_prompt()
	return v


func dice_to_roll(p, game, turn_points: int, strikes: int) -> int:
	var most: int = game._max_throw(p)
	var text := "Turn: %d pts, %d/3 Strikes. Throw how many dice?" % [turn_points, strikes]
	if game.turn.throws == 0:
		text = "Your turn. Throw how many dice?"
	if p.drag > 0:
		text += " (Dragged: max %d)" % most
	if game.turn.min_points >= 0:
		text += "\nHubris: bank more than %d or score 0." % game.turn.min_points
	var options := []
	for n in range(1, most + 1):
		options.append(["Throw %d" % n, n])
	if game.turn.throws > 0:
		options.append(["BANK %d" % turn_points, 0])
	return await _choose(text, options)


func dice_to_buy(p, game) -> int:
	var most: int = game.max_buy(p)
	if most == 0:
		return 0
	var options := [["Buy none", 0]]
	for n in range(1, most + 1):
		options.append(["Buy %d (%d)" % [n, game._buy_price(p, n)], n])
	return await _choose("Gambit: buy dice? You have %d dice, score %d. Supply %d." % [p.dice, p.score, game.supply], options)


func wants_indulgence(p, game) -> bool:
	return await _choose("You're in Purgatory.", [["Pay Indulgence (%d)" % game.indulgence_cost(p), true], ["Roll for Redemption (need a 6)", false]])


## Yes/no for an ability.
func ask(_game, text: String) -> bool:
	return await _choose(text, [["Yes", true], ["No", false]])


## Pick an opponent for a targeted Tier 2, or null to skip.
func choose_target(game, me, ability: String):
	var options := []
	for o in game.players:
		if o != me:
			options.append(["%s (%d)" % [game.pname(o), o.score], o])
	options.append(["Skip", null])
	return await _choose("%s: pick a target." % ability, options)
