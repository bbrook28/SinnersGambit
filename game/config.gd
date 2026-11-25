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
	"win": 3000,         # end your own Fate Phase on this or more, out of Purgatory, and you win
	# Abilities (the Sin cards as written in docs/step1-rules.md; the words are in game/sins.gd)
	"tier2_at": 350,          # reach this and Tier 2 opens, and stays open
	"spark_min": 5,           # Spark of Rage: the die must show this or more
	"spark_loss": 10,         # ... and a reroll of 1-3 costs this
	"strike_cost": 50,        # Vengeful Strike
	"strike_loss": 50,
	"strike_rounds": 2,
	"vig": 20,                # The Vig: of a die's price, to Greed
	"deal_cost": 50,          # Cut a Deal
	"deal_pay": 50,
	"deal_rounds": 1,
	"allure_cost": 40,        # Entangling Allure
	"grasp_cost": 30,         # Jealous Grasp
	"hubris_first": 50,       # Hubris: what the match's first roll must beat
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
