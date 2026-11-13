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

# Tier 2 (see Game.t2_available). Unlocks for good the first time score reaches 300.
var t2_unlocked := false
var t2_ready := false       # recharges at the start of your own turn
var t2_uses := 0
var t2_bounces := 0         # Pride: attacks bounced

# Tier 2 effects waiting on this player.
var reroll_next := 0        # Wrath's Fury bounced: reroll this many best scorers on your next throw
var pact_by = null          # Lust's Binding Pact: this player takes pact_pct of your next banked turn
var pact_pct := 0
var drag := 0               # Sloth's Drag: throw at most dice - drag on your next turn
