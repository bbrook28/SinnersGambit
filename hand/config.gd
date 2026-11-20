## Every number in the bag hand's rules. The sim overrides any key with key=value.
extends RefCounted

const DEFAULTS := {
	"bag": 8,               # dice in the bag at the start of a hand
	"handful": 3,           # dice drawn each throw
	"hunger_handful": 4,    # dice drawn each throw once Hunger is on
	"skull_faces": 1,       # faces 1..skull_faces are skulls
	"curse_skull_faces": 2, # a cursed die rethrown at or below this is a skull
	"bust_at": 3,           # skulls on the table that bust you
	"target": 16,           # what the Target needs before Tax and Offerings
	"tax": 3,               # what a fired Tax adds to the Target
	"win_marks": 3,
	"pair_marks": 2,
	"sum_need": 8,
	"sum_marks": 1,
	"engines": 2,           # engine slots dealt per hand
	"engine_pool": "hold,ward,ladder",
	"prize_pool": "pair,sum",
	"wire_pool": "tax,hunger,curse",
	"rollouts": 64,         # the strong policy's playouts per option
}


static func merged(overrides: Dictionary) -> Dictionary:
	var c: Dictionary = DEFAULTS.duplicate()
	for k in overrides:
		c[k] = overrides[k]
	return c
