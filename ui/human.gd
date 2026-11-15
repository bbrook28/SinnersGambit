## The human player's decision source. Same methods as ai/bot_policy.gd, but each one shows
## a prompt in the UI and waits for a button (ui/main.gd emits `answered`).
extends RefCounted

signal answered(value)

var human := true
var label := "You"
var view  # ui/main.gd
var record: Array = []    # every answer so far, JSON-safe (a player is {"seat": n}): the save (main._save_game)
var replay: Array = []    # answers to give back without asking, oldest first (Continue)
var on_answer: Callable   # called after each answer you give (main saves)


## Shows text with buttons ([label, value] pairs) and returns the value of the one pressed.
func _choose(text: String, options: Array, offer := {}):
	if not replay.is_empty():
		var want = replay.pop_front()
		for o in options:
			if _same(_store(o[1]), want):
				record.append(want)
				return o[1]
		push_warning("Continue: saved answer %s doesn't fit '%s'; asking instead" % [want, text])
		replay.clear()
	view.show_prompt(text, options, offer)
	var v = await answered
	view.clear_prompt()
	record.append(_store(v))
	if on_answer.is_valid():
		on_answer.call()
	return v


func _store(v):
	if v is Object:
		return {"seat": v.seat}
	return v


## JSON turns ints into floats, so compare numbers by value.
func _same(a, b) -> bool:
	if a is Dictionary and b is Dictionary:
		return int(a.get("seat", -1)) == int(b.get("seat", -2))
	if (a is int or a is float) and (b is int or b is float):
		return is_equal_approx(float(a), float(b))
	return typeof(a) == typeof(b) and a == b


func dice_to_roll(p, game, turn_points: int, _strikes: int) -> int:
	var most: int = game._max_throw(p)
	# Turn points and Strikes are on the stage; the prompt only asks.
	var text := "Throw again, or bank?"
	if game.turn.throws == 0:
		text = "Throw how many dice?"
	if p.drag > 0:
		text += " (Dragged: max %d)" % most
	if game.turn.min_points >= 0:
		text += "\nHubris: bank at least %d, or score 0." % game.turn.min_points
	var options := []
	for n in range(1, most + 1):
		options.append([str(n), n])
	if game.turn.throws > 0:
		options.append(["Bank %d" % turn_points, 0])
	return await _choose(text, options)


## Throw-all mode (Rules.V3): one Throw seal for all your dice, plus Bank after the first throw.
## (The dice count is the seal's only number option, so main shows the Throw seal alone.)
func wants_throw(p, game, turn_points: int, _strikes: int) -> bool:
	var n: int = game._max_throw(p)
	var text := "Throw your dice." if game.turn.throws == 0 else "Throw again, or bank?"
	if p.drag > 0:
		text += " (Dragged: %d dice)" % n
	if game.turn.min_points >= 0:
		text += "\nHubris: bank at least %d, or score 0." % game.turn.min_points
	var options := [[str(n), true]]
	if game.turn.throws > 0 and game.may_bank(p):  # Lust's claim (V4): no Bank before the second throw
		options.append(["Bank %d" % turn_points, false])
	return await _choose(text, options)


## Rules.V4: a rival Sin's offer, Accept or Refuse. The first one you ever see carries one tip.
func wants_temptation(game, p, from, offer: Dictionary) -> bool:
	var RulesText = load("res://ui/rules_text.gd")
	var sname: String = from.sin.sin_name
	# One line of decision context: this turn, its Strikes, my score and the leader's.
	var s: int = game.turn.strikes
	var rival = game.leader_other(p)
	var lead: int = rival.score if rival else 0
	var ctx: String = RulesText.table("tempt_context_lead" if p.score > lead else "tempt_context", {
		"pts": game.turn.points, "strikes": "%d Strike%s" % [s, "" if s == 1 else "s"], "me": p.score, "lead": lead})
	var card := {"sin": sname, "say": RulesText.tempt_say(offer.id), "terms": RulesText.tempt_terms(offer.id),
		"text": RulesText.tempt(offer.id), "tip": "", "context": ctx}
	if view and not view.tempt_tip_seen:
		card.tip = RulesText.table("tempt_tip")
		view.tempt_tip_seen = true
		view._save_settings()
	var text: String = RulesText.table("tempt_prompt", {"sin": sname})
	return await _choose(text, [[RulesText.table("accept"), true], [RulesText.table("refuse"), false]], card)


func dice_to_buy(p, game) -> int:
	var most: int = game.max_buy(p)
	if most == 0:
		return 0
	var options := [["Buy none", 0]]
	for n in range(1, most + 1):
		options.append(["Buy %d (%d)" % [n, game._buy_price(p, n)], n])
	return await _choose("Buy dice? You have %d dice and %d points." % [p.dice, p.score], options)


## Pick one of several labelled answers ([label, value] pairs).
func pick(_game, text: String, options: Array):
	return await _choose(text, options)


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
