## Envy, the Mirror. Copies others.
## T1 Green-Eyed Glance (after throw, once per turn): add a temporary die to this throw
## showing the best face in the previous player's last throw. It counts toward the combo.
extends "res://sins/sin.gd"


func _init() -> void:
	sin_name = "Envy"


func after_throw(game, _me, turn) -> void:
	if turn.used_t1:
		return
	var best: int = game.best_face_last_throw()
	if best < 4:
		return
	# Worth the most on a throw that already has scorers (bigger combo).
	var scorers := 0
	for f in turn.faces:
		if f >= 4:
			scorers += 1
	if scorers == 0:
		return
	turn.faces.append(best)
	turn.used_t1 = true
