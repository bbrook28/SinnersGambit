## The tutorial: three short lessons, each one scripted hand that teaches a few things by doing them.
## Lesson 1 the row, lesson 2 skulls, lesson 3 the Sin. Design: docs/superpowers/specs/2026-11-21-tutorial-design.md.
## Steps: "card" (read, then the button; "skip" adds Skip the lessons, "body": "ranking" shows the hands, "open" plays
## the Sin's opening after it), "throw" (only that many dice), "keep" (only that face), "free" (the dice are the
## player's), "end" (the scripted hand is over).
extends RefCounted

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


const LESSONS := [
	# 1: the row. 4 6 / 4 3 / 4 5 2 / 6 2 / 6 3 -> 4 4 4 6 6, Three and a pair, 5 marks
	{"demand": "", "faces": [4, 6, 4, 3, 4, 5, 2, 6, 2, 6, 3], "steps": [
		{"type": "card", "skip": true, "title": "The Master's dice",
			"text": "Fill your row with five dice. Dice that match make a hand, and a better hand pays more marks. Marks are your score.\n\nEach turn you roll dice from the bag and keep one of them."},
		{"type": "throw", "n": 2, "msg": "Tap the 2 button: roll two dice from the bag."},
		{"type": "keep", "face": 4, "msg": "Tap the 4, then tap Keep. The 6 goes back into the bag."},
		{"type": "throw", "n": 2, "msg": "Roll two again."},
		{"type": "keep", "face": 4, "msg": "Keep the second 4."},
		{"type": "card", "title": "A Pair",
			"text": "Two dice the same make a Pair. It pays 1 mark.\n\nThe ribbon above your row shows what the row is worth now. Tap a die and \"if kept\" shows what it would make before you keep it."},
		{"type": "throw", "n": 3, "msg": "Roll three: more dice to choose from."},
		{"type": "keep", "face": 4, "msg": "A third 4. Tap it and read the ribbon, then Keep."},
		{"type": "throw", "n": 2, "msg": "Under your row: what one more die could make. Roll two."},
		{"type": "keep", "face": 6, "msg": "No 4 this time. Keep the 6."},
		{"type": "throw", "n": 2, "msg": "One place left. Roll two."},
		{"type": "keep", "face": 6, "msg": "Keep the 6: three 4s and a pair of 6s."},
		{"type": "card", "title": "Paid", "body": "ranking",
			"text": "A full row is paid, and it always makes at least a Pair. These are all the hands, best first.\n\nTap ? at any time to see them again."},
		{"type": "end"}]},
	# 2: skulls. 1 5 / 5 1 3 / 5 / 3 / the Last Dance: 4 -> 5 5 5 3 and any, Four of a kind, 7 marks
	{"demand": "", "faces": [1, 5, 5, 1, 3, 5, 3, 4], "steps": [
		{"type": "card", "skip": true, "title": "Skulls",
			"text": "A 1 is a skull. It cannot be kept and never goes back into the bag. Each skull puts out one candle.\n\nThree candles out and the Master takes the hand: it pays nothing."},
		{"type": "throw", "n": 2, "msg": "Roll two dice."},
		{"type": "card", "title": "More dice, more risk",
			"text": "Your 5 was the only die left, so it was kept for you.\n\nMore dice give more to choose from, and more chances of a skull. Under each button: your chance of losing the hand on that roll."},
		{"type": "throw", "n": 3, "msg": "Be bold: roll three."},
		{"type": "keep", "face": 5, "msg": "Another skull: two candles are out. Keep the 5."},
		{"type": "throw", "n": 1, "msg": "One more skull loses the hand. One die is the safest roll."},
		{"type": "throw", "n": 1, "msg": "Roll one again."},
		{"type": "card", "title": "The Last Dance",
			"text": "One die is left in the bag. It is rolled alone.\n\nWhatever it shows counts as any number you need. But if it is a skull, the Master takes the hand."},
		{"type": "throw", "n": 1, "msg": "Roll the last die."},
		{"type": "end"}]},
	# 3: the Sin. Pride watches. 6 3 / 6 4, then the dice are the player's
	{"demand": "pride", "faces": [6, 3, 6, 4], "steps": [
		{"type": "card", "skip": true, "open": true, "title": "The Sin",
			"text": "A Sin watches each hand. It pays marks for what it wants and takes marks for what it hates, on top of your hand.\n\nIts rule is written on the table edge. Lose the hand and it pays nothing."},
		{"type": "throw", "n": 2, "msg": "Read Pride's rule on the table edge. Roll two dice."},
		{"type": "keep", "face": 6, "msg": "The number above a die is what Pride pays if you keep it. Keep the 6."},
		{"type": "throw", "n": 2, "msg": "Roll two again."},
		{"type": "keep", "face": 4, "msg": "A second 6 is no longer exactly one: Pride would take its 4 back. Keep the 4."},
		{"type": "card", "title": "The dice are yours",
			"text": "The ribbon shows your hand and Pride's marks side by side.\n\nFinish this hand your own way. Tap ? at any time for all the rules."},
		{"type": "free"}]},
]

var lesson := 0
var i := 0


func steps() -> Array:
	return LESSONS[lesson].steps


func step() -> Dictionary:
	return steps()[mini(i, steps().size() - 1)]


## True once nothing more is guided in this lesson's hand.
func done() -> bool:
	return step().type in ["free", "end"]


func advance() -> void:
	i += 1


## The Sin watching this lesson's hand, or "".
func demand() -> String:
	return LESSONS[lesson].demand


## This lesson's scripted dice.
func rng() -> ScriptRng:
	return ScriptRng.new(LESSONS[lesson].faces)


## Moves to the next lesson; false when there is none.
func next_lesson() -> bool:
	if lesson >= LESSONS.size() - 1:
		return false
	lesson += 1
	i = 0
	return true
