## Greed, the Hoarder. The economy.
## T1 The Vig (passive): when an opponent buys a die, 17 of its price goes to Greed. (15: 12% win, 20: 18%.)
## T2 Interest (Gambit): if you buy no dice this turn, gain INTEREST_PCT% of your score, max INTEREST_CAP.
## (5%, max 50: 12.5%. 8%, max 60: 15.2%.)
extends "res://sins/sin.gd"

const VIG := 17
const INTEREST_PCT := 8
const INTEREST_CAP := 60


func _init() -> void:
	sin_name = "Greed"


func on_other_buy(_game, _me, _other, n: int) -> int:
	return VIG * n


func gambit(game, me, bought: int) -> void:
	if bought > 0:
		return
	me.score += mini(INTEREST_CAP, me.score * INTEREST_PCT / 100)
	game.mark_t2(me)
