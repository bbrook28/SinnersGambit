## One player's state in a game.
extends RefCounted

const Rules = preload("res://core/rules.gd")

var seat: int
var bot  # BotPolicy (ai/bot_policy.gd)
var sin = null  # Sin (sins/*.gd) or null
var score := 0
var dice := Rules.START_DICE
var in_purgatory := false

# Stats for the simulator.
var turns := 0
var busts := 0
var presses := 0


func _init(p_seat: int, p_bot) -> void:
	seat = p_seat
	bot = p_bot
