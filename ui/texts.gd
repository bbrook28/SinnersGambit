## Every rule the player meets, in words, in one place. The numbers come from the hand's config.
extends RefCounted

const Rules = preload("res://hand/rules.gd")

const NAMES := {"target": "The Target", "offering": "The Offering", "hold": "Hold", "ward": "The Ward", "ladder": "The Ladder",
	"rites": "Last Rites", "pair": "Pair", "sum": "Sum", "tax": "Tax", "hunger": "Hunger", "curse": "Curse"}


static func slot_name(slot: Dictionary) -> String:
	if slot.kind == "sum":
		return "Sum to %d" % int(slot.need)
	return NAMES.get(slot.kind, slot.kind)


## What a slot takes and does, as printed on it.
static func slot_rule(s, slot: Dictionary) -> String:
	var cfg: Dictionary = s.cfg
	if slot.hidden:
		return "Face down. The Master turns it up when you reach Tier 1."
	match slot.kind:
		"target":
			return "Any die, as many as you like: adds its pips. Cash out to be paid the highest tier you have cleared."
		"offering":
			return "Any die, as many as you like: every tier needs 1 less."
		"hold":
			return "One die, kept out of the bag. On a later throw, place it instead of a thrown die."
		"ward":
			if int(cfg.ward_dice) == 1:
				return "One die, any face. Full, it cancels your next skull, then empties. Once a hand."
			return "Two dice within %d pip. Full, it cancels your next skull, then empties." % int(cfg.ward_spread)
		"ladder":
			return "Two dice: the first 5 or less, the second higher. Full, every later Target die counts double."
		"pair":
			return "Two dice of the same face, across throws. Claimed: +%d marks if you win." % int(slot.marks)
		"sum":
			return "Two dice that add up to %d. Claimed: +%d mark if you win." % [int(slot.need), int(slot.marks)]
		"rites":
			return "One die from a bag of %d or fewer. Survive your next throw and it counts x%d." % [int(cfg.rites_bag), int(cfg.rites_mult)]
	return ""


## A wire's condition and consequence.
static func wire_rule(s, w: Dictionary) -> String:
	match w.kind:
		"tax":
			var at := "a two-die slot" if w.slot < 0 else slot_name(s.slots[w.slot])
			return "When %s is full: every tier needs +%d, for the rest of the hand." % [at, int(s.cfg.tax)]
		"hunger":
			return "Pass Tier 2 and throw on: every throw draws %d dice." % int(s.cfg.hunger_handful)
		"curse":
			return "When you throw, each die waiting alone in Hold or a half-filled slot is thrown again: a 1 or 2 makes it a skull."
	return ""


## The first-time cards: a title and the full explanation.
const CARDS := {
	"skull": ["Skulls", "A 1 is a skull. It stays on the table and leaves the bag for the rest of the hand. Three skulls bust you: the hand is lost, and so is everything in it."],
	"hold": ["Hold", "Hold keeps one die out of the bag. On a later throw you may place it instead of a thrown die, then Hold is empty again."],
	"ward": ["The Ward", "Put any one die in the Ward. While it is full, it cancels the next skull (even on the Last Dance), then empties. It cancels only one skull a hand."],
	"ladder": ["The Ladder", "Two dice, across throws: the first 5 or less, the second higher than the first. Once it is full, every die you put in the Target counts double."],
	"pair": ["Pair", "A prize. Two dice of the same face, one per throw. If you win the hand, it pays its marks on top of your tier."],
	"sum": ["Sum", "A prize. Two dice that add up to its number. If you win the hand, it pays its mark on top of your tier."],
	"tax": ["Tax", "A wire on a two-die slot. The moment that slot is full, every tier needs 3 more, for the rest of the hand. It can drop you back a tier."],
	"hunger": ["Hunger", "Once you have passed Tier 2, every throw you take draws 4 dice instead of 2: faster, and more skulls at once."],
	"curse": ["Curse", "Every die waiting alone in Hold, or alone in a half-filled slot, is thrown again with your handful. A 1 or 2 makes it a skull. A 6 alone in the Ladder can never be finished, so it goes back to the bag."],
	"second_wire": ["The Master answers", "The first time you put a die in an engine slot (Hold, the Ward, the Ladder), the Master deals one more wire. Wires always show before they can strike."],
	"dance": ["The Last Dance", "The bag's last die, thrown alone. Its pips count double wherever it goes, and a skull busts you whatever the count, unless a full Ward cancels it."],
	"empty_bag": ["The bag is empty", "No dice left to throw: the hand cashes out by itself. A die waiting in Hold may be placed one last time first."],
	"offering": ["The Offering", "Takes any die. Every tier needs 1 less. The least-bad place for a die you can't use."],
}
