## Greed, the Hoarder. The economy.
## T1 The Vig (passive): when an opponent buys a die, 17 of its price goes to Greed. (15: 12% win, 20: 18%.)
extends "res://sins/sin.gd"

const VIG := 17


func _init() -> void:
	sin_name = "Greed"


func on_other_buy(_game, _me, _other, n: int) -> int:
	return VIG * n
