## The guided first hand: a fixed table and scripted dice for four throws, one rule at a time; then the dice are yours.
## Steps: "card" (read, then Got it), "throw" (only Throw works), "place" (only that die into that slot works), "free".
extends RefCounted

const Rules = preload("res://hand/rules.gd")

## Faces for the scripted throws, in order; then a real rng.
class ScriptRng:
	var queue: Array = []
	var real := RandomNumberGenerator.new()
	func _init(faces: Array) -> void:
		queue = faces.duplicate()
		real.randomize()
	func randi_range(a: int, b: int) -> int:
		if queue.is_empty():
			return real.randi_range(a, b)
		return queue.pop_front()


const STEPS := [
	{"type": "card", "title": "The Master's table",
		"text": "The Master of the Dance deals you a table. Fill the Target to win the hand.\n\nEach throw, you draw 2 dice from the bag and place exactly one of them in a slot. Every slot shows its rule."},
	{"type": "throw", "msg": "Tap Throw to draw 2 dice from the bag."},
	{"type": "place", "slot": "target", "face": 5, "msg": "Tap the 5, then tap the Target."},
	{"type": "card", "title": "Back into the bag",
		"text": "The die you didn't place went back into the bag: 7 dice left.\n\nThe Target has three tiers. Cash out to be paid the highest tier you have cleared: 2, 4 or 7 marks. Not the sum: the highest."},
	{"type": "throw", "msg": "Throw again."},
	{"type": "card", "title": "A skull", "seen": "skull",
		"text": "A 1 is a skull. It stays on the table and leaves the bag for this hand. Three skulls bust you: the hand is lost, and everything in it.\n\nYou have 1 of 3."},
	{"type": "place", "slot": "ward", "face": 4, "msg": "Put the 4 in the Ward. While it is full, it cancels your next skull, once a hand.", "seen": "ward"},
	{"type": "card", "title": "The Master answers", "seen": "second_wire",
		"text": "Your first die in an engine slot made the Master deal a second wire: Hunger. Pass Tier 2 and throw on, and every throw draws 4 dice.\n\nWires always show their rule before they can strike."},
	{"type": "throw", "msg": "Throw."},
	{"type": "place", "slot": "target", "face": 6, "msg": "Put the 6 in the Target: 11 pips, past Tier 1."},
	{"type": "card", "title": "Tier 1: the hand is won",
		"text": "Cash out now and you take 2 marks, safe.\n\nOr throw on for Tier 2 (4 marks). The Throw button shows your chance of busting: a bust loses the hand and everything in it."},
	{"type": "throw", "msg": "Be bold: throw on."},
	{"type": "card", "title": "The Ward holds",
		"text": "The Ward cancelled that skull. It went back into the bag, and the Ward is spent for this hand. Still 1 skull of 3."},
	{"type": "place", "slot": "target", "face": 5, "msg": "Tap the 5: the Target shows it would reach 16. Put it there."},
	{"type": "card", "title": "The dice are yours", "seen": "ladder tax offering hunger",
		"text": "16 pips: 2 short of Tier 2.\n\nThe Ladder: two dice, the second higher. Full, every later Target die counts double, but its Tax wire makes every tier need +3. The Offering lowers every tier by 1.\n\nWhen you pick a die, each lit slot says what it would do. 3 dice left: your call."},
	{"type": "free"},
]

var i := 0


func step() -> Dictionary:
	return STEPS[mini(i, STEPS.size() - 1)]


func done() -> bool:
	return step().type == "free"


func advance() -> void:
	i += 1


static func rng() -> ScriptRng:
	return ScriptRng.new([5, 3, 1, 4, 6, 2, 1, 5])


## The tutorial's table: Target, Offering, Ward, Ladder (watched by a Tax); Hunger waits in the pool.
static func table(cfg: Dictionary):
	var s = Rules.new_hand(cfg, RandomNumberGenerator.new())
	s.slots = [Rules._slot("target", 0, 0, 0), Rules._slot("offering", 0, 0, 0),
		Rules._slot("ward", 0, int(cfg.ward_dice), 0), Rules._slot("ladder", 0, 2, 0)]
	s.wires = [{"kind": "tax", "slot": 3}]
	s.wire_pool = ["hunger"]
	return s
