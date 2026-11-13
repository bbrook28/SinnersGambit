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
	me.score += RAGE
	if game.view:
		fired(game, me, "Spark of Rage", "+%d (%s busted)" % [RAGE, game.pname(other)])


func on_other_throw(game, me, other, turn) -> void:
	var pts: int = Rules.score(turn.faces, game.chain, game.face_mult)
	if me.bot.human:
		if pts <= 0 or not await me.bot.ask(game, "Fury? %s's throw is worth %d. Make them reroll their %d best dice." % [game.pname(other), pts, FURY_DICE]):
			return
	elif pts < FURY_TRIGGER:
		return
	await game.attack(me, other, "reroll", FURY_DICE)
	if game.view:
		game.say("  Rerolled: %s" % game._faces_str(turn.faces))
