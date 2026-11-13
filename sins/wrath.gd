## Wrath, the Avenger. Profits from others' failures.
## T1 Spark of Rage (passive): +40 whenever another player busts. (30: 10% win, 35: 12%, 50: 21%.)
extends "res://sins/sin.gd"

const RAGE := 40


func _init() -> void:
	sin_name = "Wrath"


func on_other_bust(_game, me, _other) -> void:
	me.score += RAGE
