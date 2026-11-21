## Every number in dice poker (docs/superpowers/specs/2026-11-20-dice-poker-pitch.md). The sim overrides any key with key=value.
extends RefCounted

const DEFAULTS := {
	"bag": 8,              # dice in the bag at the start of a hand
	"draw": 2,             # dice drawn each throw (fewer when the bag holds fewer)
	"skull_faces": 1,      # faces 1..skull_faces are skulls; the rest are pips
	"bust_at": 3,          # skulls on the table that bust you
	"row": 5,              # places in your row; a full row cashes out by itself
	"pay": "0,1,2,3,5,5,7,12",  # marks for each hand, in the order of Rules.HANDS
	"stake": 0,            # marks a bust costs you (trial: your stake, kept by the Master; cashing out keeps it)
}


static func merged(overrides: Dictionary) -> Dictionary:
	var c: Dictionary = DEFAULTS.duplicate()
	for k in overrides:
		c[k] = overrides[k]
	return c
