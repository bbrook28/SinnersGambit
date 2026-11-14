## The tutorial's opponent: throws the faces it's given and banks, never buys. A ui/ subclass of
## the real bot (ai/ is unchanged), so every other decision stays the bot's own.
extends "res://ai/bot_policy.gd"

const TutorialDice = preload("res://ui/tutorial_dice.gd")

var turns: Array = []   # one entry per turn: the throws to make, each an Array of faces
var _left: Array = []   # this turn's throws still to make


func _init(p_turns: Array) -> void:
	super(5)
	turns = p_turns.duplicate(true)
	label = "Tutorial"


## The first call of a turn is the first throw (always made); later calls throw while any are left.
func wants_throw(_p, game, _turn_points: int, _strikes: int) -> bool:
	if game.turn.throws == 0:
		_left = turns.pop_front() if not turns.is_empty() else [[3, 3, 3]]
	if _left.is_empty():
		return false
	TutorialDice.rig(game, _left.pop_front())
	return true


func dice_to_buy(_p, _game) -> int:
	return 0
