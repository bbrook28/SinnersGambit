## Every number in dice poker (the rules as built: docs/rules.md; the first pitch: docs/superpowers/specs/2026-11-20-dice-poker-pitch.md). The sim overrides any key with key=value.
extends RefCounted

const DEFAULTS := {
	"bag": 7,              # dice in the bag at the start of a hand (7: the Last Dance comes in ~25% of hands; at 8 it never can)
	"draw": 2,             # dice a throw draws when the caller names none (the tests and old callers)
	"max_draw": 3,         # you choose to draw 1 to this many dice each throw (Ben, 2026-11-20: core B, choose your draw)
	"skull_faces": 1,      # faces 1..skull_faces are skulls; the rest are pips
	"bust_at": 3,          # skulls on the table that bust you
	"row": 5,              # places in your row; the hand plays until it is full (or you bust): no cash out (Ben, 2026-11-20)
	"pay": "0,1,2,3,5,5,7,12",  # marks for each hand, in the order of Rules.HANDS
	"demand": "",          # the hosting Sin whose demand pays on top (a key of dice/demands.gd), or "" for none
}


static func merged(overrides: Dictionary) -> Dictionary:
	var c: Dictionary = DEFAULTS.duplicate()
	for k in overrides:
		c[k] = overrides[k]
	return c
