## Lust, the Temptress. Takes what others have.
## T1 Whisper of Desire (after throw, once per turn): swap one of your 3s for the best face
## in the previous player's last throw; if you have no 3, you may swap a 2 (cancels that Strike).
## (Any die: 33% win. 3s only: 9%. 2 first: 20%.)
extends "res://sins/sin.gd"


func _init() -> void:
	sin_name = "Lust"


func after_throw(game, _me, turn) -> void:
	if turn.used_t1:
		return
	var best: int = game.best_face_last_throw()
	if best < 4:
		return
	var i: int = turn.faces.find(3)
	if i < 0:
		i = turn.faces.find(2)
	if i < 0:
		return
	turn.faces[i] = best
	turn.used_t1 = true
