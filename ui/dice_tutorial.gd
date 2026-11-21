## The guided first hand: scripted dice for three throws, one rule at a time; then the dice are yours.
## Steps: "card" (read, then the button), "throw" (only that many dice), "keep" (only that face), "free".
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


const STEPS := [
	{"type": "card", "title": "The Master's dice",
		"text": "Build the best poker hand you can in a row of five dice.\n\nEach throw, you choose how many dice to draw from the bag: 1, 2 or 3. You keep one of them in your row. The rest go back into the bag."},
	{"type": "throw", "n": 2, "msg": "Tap the 2 seal: draw two dice."},
	{"type": "keep", "face": 4, "msg": "Tap the 4 to see what it makes, then Keep it."},
	{"type": "throw", "n": 2, "msg": "Draw two again."},
	{"type": "card", "title": "A skull",
		"text": "A 1 is a skull. It stays out of the bag and snuffs one of the Master's candles.\n\nThree skulls and the Master takes the hand: it pays nothing.\n\nYour other die was a 4, so it was kept for you: a Pair."},
	{"type": "card", "title": "More dice, more risk",
		"text": "Drawing more dice gives you more to choose from, and more chances of a skull.\n\nEach seal shows your chance of losing the hand on that throw."},
	{"type": "throw", "n": 3, "msg": "Be bold: draw three."},
	{"type": "keep", "face": 4, "msg": "Keep the third 4."},
	{"type": "card", "title": "The dice are yours",
		"text": "Three of a kind, and three dice left in the bag. Fill the row and it is paid; there is no stopping early.\n\nThe Last Dance: if the bag is down to its last die, it is thrown alone. Any face is wild; a skull loses the hand.\n\nTap ? any time for the hand ranking."},
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
	return ScriptRng.new([4, 6, 1, 4, 4, 5, 6])
