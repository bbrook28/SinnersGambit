## Every number in the bag hand's rules. The sim overrides any key with key=value.
extends RefCounted

const DEFAULTS := {
	"bag": 8,               # dice in the bag at the start of a hand
	"handful": 2,           # dice drawn each throw (sweep 2026-11-20: 2 passed 4 of 6 marks, 3 passed fewer)
	"hunger_handful": 4,    # dice drawn each throw once Hunger is on
	"skull_faces": 1,       # faces 1..skull_faces are skulls
	"curse_skull_faces": 2, # a cursed die rethrown at or below this is a skull
	"bust_at": 3,           # skulls on the table that bust you
	"tiers": "10,18,26",    # what each Target tier needs before Tax and Offerings (change 1)
	"tier_marks": "2,4,7",  # a won hand pays the highest tier cleared, not the sum
	"tax": 3,               # what a fired Tax adds to the Target
	"pair_marks": 2,
	"ward_dice": 1,         # dice that fill the Ward: one die of any face buys a cancelled skull (Ben, 2026-11-20; 2 was filled in 3% of hands)
	                        # ward_spread applies only when this is 2
	"ward_cancels": 1,      # skulls the Ward may cancel a hand; then it is spent (0: no limit)
	"ward_spread": 1,       # the Ward's second die may be this many pips from the first (0: matching faces)
	"sum_need": 8,
	"sum_marks": 1,
	"skull_strips": false,  # trial: past Tier 1, a skull that is not cancelled takes the last Target die off (it leaves the hand)
	"late_bag": 0,          # trial late wire, on the table from the start: a throw from a bag of this many or fewer (checked before the draw)
	"late_skull_faces": 2,  #   counts faces 1..this as skulls (0 for late_bag: no late wire)
	"rites_bag": 3,         # Last Rites (trial engine kind "rites"): takes one thrown die, only from a throw whose bag held this many or fewer
	"rites_mult": 3,        #   (checked before the draw). It waits: if your next throw lands no uncancelled skull, it counts this many
	                        #   times its pips toward the Target (instead of any doubling); a skull on that throw busts you outright
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
