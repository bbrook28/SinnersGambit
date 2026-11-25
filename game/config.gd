## Every number in the step 1 game (the rules: docs/step1-rules.md). Override any key with merged({key: value}).
extends RefCounted

const SINS := ["wrath", "greed", "lust", "envy", "pride", "gluttony", "sloth"]

const DEFAULTS := {
	"seats": 4,          # players, passing one phone
	"total_dice": 27,    # dice in all: the seats' dice and the shared supply
	"start_dice": 3,     # dice each player starts with
	"min_dice": 2,       # no one ever drops below this
	"low_max": 3,        # faces 1..low_max score nothing; every higher face scores face x face_points
	"face_points": 10,   # a 4, 5 or 6 scores 40, 50 or 60
	"escape_lows": 2,    # dice showing 1..low_max that free you from Purgatory
	"die_cost": 20,      # points for one die from the supply
	"win": 3000,         # end your own Fate Phase on this or more and you win
}


static func merged(overrides: Dictionary) -> Dictionary:
	var c: Dictionary = DEFAULTS.duplicate()
	for k in overrides:
		c[k] = overrides[k]
	return c
