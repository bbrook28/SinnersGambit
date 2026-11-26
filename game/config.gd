## Every number in the step 1 game (the rules: docs/step1-rules.md). Override any key with merged({key: value}).
extends RefCounted

const SINS := ["wrath", "greed", "lust", "envy", "pride", "gluttony", "sloth"]

const DEFAULTS := {
	"seats": 4,          # players, passing one phone
	"spare_dice": 6,     # dice in the shared supply at the start, at any table size (Ben, 2026-11-25: a seven-player table with the 27-dice box has 6 spare; at 15 spare no one ran short and no one made a deal)
	"start_dice": 3,     # dice each player starts with
	"min_dice": 2,       # no one ever drops below this
	"low_max": 3,        # faces 1..low_max score nothing; every higher face scores face x face_points
	"face_points": 10,   # a 4, 5 or 6 scores 40, 50 or 60
	"escape_lows": 2,    # dice showing 1..low_max that free you from Purgatory
	"die_cost": 20,      # points for one die from the supply
	"buys_a_turn": 1,    # dice a player can buy for themselves in one turn (Ben, 2026-11-25); the die that replaces a Feasted one counts, a die bought for another player does not
	"win": 1000,         # end your own Fate Phase on this or more, out of Purgatory, and you win (Ben, 2026-11-25: a starting value under test; the rulebook says 3000)
	# Abilities (the Sin cards as written in docs/step1-rules.md; the words are in game/sins.gd)
	"tier2_at": 350,          # reach this and Tier 2 opens, and stays open
	"spark_min": 5,           # Spark of Rage: the die must show this or more
	"spark_loss": 10,         # ... and a reroll of 1-3 costs this
	"strike_cost": 50,        # Vengeful Strike
	"strike_loss": 50,
	"strike_rounds": 2,
	"vig": 20,                # The Vig: of a die's price, to Greed
	"deal_cost": 70,          # Cut a Deal (Ben, 2026-11-25: a starting value under test; the card says 50)
	"deal_pay": 50,
	"deal_rounds": 1,
	"allure_cost": 40,        # Entangling Allure
	"grasp_cost": 30,         # Jealous Grasp
	"hubris_first": 50,       # Hubris: what the match's first roll must beat
	# Ben, 2026-11-26: a won Hubris scores the roll plus 50; the card said the score doubles (Pride won 46% of sim matches
	# at a five-Sin table with doubling). A starting value under test. The Sin card (game/sins.gd) and the screen say "50 more".
	# The other keys are the options the sim compared, off at these values.
	"hubris_win_pct": 100,    # a won Hubris scores this percent of the roll (200: doubled, the card as first written)
	"hubris_win_add": 50,     # ... plus this many points
	"hubris_fail_loss": 0,    # a failed Hubris scores 0 and also loses this
	"hubris_bar": 0,          # what to beat. 0: the previous player's last roll. 1: the best last roll of any other player
	"hubris_min": 0,          # what to beat is never under this
	"superiority_cost": 40,   # Superiority
	"superiority_loss": 20,
	"feast_gain": 150,        # Feast
	"bite_cost": 20,          # Voracious Bite
	"bite_steal": 20,
	"drip_under": 60,         # Slow Drip: a roll scoring under this ...
	"drip_gain": 40,          # ... gains this
	"aura_cost": 30,          # Lethargic Aura
	"aura_gain": 10,
}


static func merged(overrides: Dictionary) -> Dictionary:
	var c: Dictionary = DEFAULTS.duplicate()
	for k in overrides:
		c[k] = overrides[k]
	return c
