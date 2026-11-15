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

# Temptations (Rules.V4, Docs/TableDesign.md §7).
var marks := {}             # Sin name -> marks held now (clear at the claim)
var marks_taken := {}       # Sin name -> marks ever taken (Solo endings, stats)
var claims: Array = []      # Sin names whose claim binds this player for the rest of the game
var pend_bank := 0          # your next Bank loses this much
var pend_strike := 0        # your next turn starts with this many Strikes
var pend_fewer := 0         # your next turn throws this many fewer dice
var pend_die := 0           # you lose this many dice when this turn ends
var fewer_now := 0          # this turn throws this many fewer dice (pend_fewer, moved in at turn start)
var last_bank := -1         # Pride's claim: your last Bank this game that counted
var grudges: Array = []     # seats that aimed an ability at you, oldest first (ai/bot_policy.gd pick_target)
var offers_seen := 0        # sim stats
var offers_taken := 0
