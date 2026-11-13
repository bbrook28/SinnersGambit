## Sinners' Gambit base rules: constants and pure dice helpers. No UI, no state.
extends RefCounted

const WIN_SCORE := 1000
const START_DICE := 3
const MIN_DICE := 2
const TOTAL_DICE := 27
const DIE_COST := 100
const STRIKES_TO_BUST := 3
const INDULGENCE_COST := 50


static func roll(rng: RandomNumberGenerator, count: int) -> Array[int]:
	var faces: Array[int] = []
	for i in count:
		faces.append(rng.randi_range(1, 6))
	return faces


## 1s and 2s are Strikes.
static func count_strikes(faces: Array[int]) -> int:
	var n := 0
	for f in faces:
		if f <= 2:
			n += 1
	return n


## 4/5/6 score 40/50/60. 1-3 score nothing.
static func score(faces: Array[int]) -> int:
	var total := 0
	for f in faces:
		if f >= 4:
			total += f * 10
	return total
