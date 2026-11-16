## Wrath, the Avenger. Profits from others' failures.
## T1 Spark of Rage (passive): +40 whenever another player busts. (30: 10% win, 35: 12%, 50: 21%.)
## T2 Fury (after roll, opponent's turn, once per round): force them to reroll their FURY_DICE best scoring dice.
## Rerolled Strikes count. Bot: first opponent throw worth FURY_TRIGGER or more.
## (2 dice: 12.4% win. 3 dice: 13.8%, with T1+T2 at 7p.)
extends "res://sins/sin.gd"

const Rules = preload("res://core/rules.gd")

const RAGE := 40
const FURY_DICE := 3
const FURY_TRIGGER := 150


func _init() -> void:
	sin_name = "Wrath"


func on_other_bust(game, me, other) -> void:
	if game.v5:
		return  # V5: Spark of Rage off; the power is Rethrow
	var rage: int = game.opt("rage", RAGE)
	me.score += rage
	if game.view:
		fired(game, me, "Spark of Rage", "+%d (%s busted)" % [rage, game.pname(other)])


func on_other_throw(game, me, other, turn) -> void:
	var pts: int = Rules.score(turn.faces, game.chain, game.face_mult)
	var fury_dice: int = game.opt("fury_dice", FURY_DICE)
	if game.v4:  # automatic (TableDesign Â§5): lower bar on a rival who aimed at Wrath
		var bar: int = game.opt("fury_grudge", 100) if me.grudges.has(other.seat) else game.opt("fury_trigger", FURY_TRIGGER)
		if pts < bar:
			return
	elif me.bot.human:
		if pts <= 0 or not await me.bot.ask(game, "Fury? %s's throw is worth %d. Make them reroll their %d best dice." % [game.pname(other), pts, FURY_DICE]):
			return
	elif pts < FURY_TRIGGER:
		return
	await game.attack(me, other, "reroll", fury_dice)
	if game.view:
		game.say("  Rerolled: %s" % game._faces_str(turn.faces))


# V5 power (Docs/TableDesign.md §10): rethrow up to wrath_rethrow of this throw's Strikes.
func power_window() -> String:
	return "throw"


func power_ready(_game, _me, turn) -> bool:
	return Rules.count_strikes(turn.faces) > 0


func use_power(game, me, turn, _choice) -> bool:
	var left: int = game.opt("wrath_rethrow", 2)
	var was: String = game._faces_str(turn.faces)
	for i in turn.faces.size():
		if left > 0 and turn.faces[i] <= 2:
			turn.faces[i] = game.rng.randi_range(1, 6)
			left -= 1
	if game.view:
		fired(game, me, "Rethrow", "%s -> %s" % [was, game._faces_str(turn.faces)])
	return false
