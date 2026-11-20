## Every number in the core hand's rules. The sim overrides any key with key=value.
extends RefCounted

const DEFAULTS := {
	"dice": 5,
	"skull_faces": 1,       # faces 1..skull_faces are skulls
	"bust_at": 3,           # skulls on the table that bust you
	"target": 8,            # sweep 2026-11-20: with 5 dice, 8 met three of the four tuning marks
	"extras": 3,            # slots laid out beside the Target and the Offering
	"win_marks": 3,
	"threat_need": 5,
	"threat_countdown": 2,
	"pair_countdown": 3,
	"pair_marks": 2,
	"sum_need": 8,
	"sum_countdown": 3,
	"sum_marks": 1,
	"reroll_need": 4,
	"reroll_countdown": 2,
	"extra_pool": "threat,threat,pair,sum,reroll",
	"prizes_after_target": true,  # pair and sum prizes stay hidden until the Target is met (Ben, 2026-11-20)
	"rollouts": 64,         # the strong policy's playouts per option
}


static func merged(overrides: Dictionary) -> Dictionary:
	var c: Dictionary = DEFAULTS.duplicate()
	for k in overrides:
		c[k] = overrides[k]
	return c
