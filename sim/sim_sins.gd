## Sim-only Sins for the powers prototype (sim/agency_sim.gd powers=true): each Sin's passive Basic is off
## (its power lives in sim/sim_game.gd); Greater stays. Nothing in the game uses this file.
extends RefCounted


class Wrath extends "res://sins/wrath.gd":
	func on_other_bust(_game, _me, _other) -> void:
		pass  # Spark of Rage off; Fury stays


class Greed extends "res://sins/greed.gd":
	func on_other_buy(_game, _me, _other, _n: int) -> int:
		return int(_game.opt("vig", 40)) * _n if _game.opt("greed_vig", false) else 0  # The Vig off (greed_vig keeps it); Interest stays


class Lust extends "res://sins/lust.gd":
	func after_throw(_game, _me, _turn) -> void:
		pass  # Whisper off; Binding Pact stays


class Envy extends "res://sins/envy.gd":
	## Glance off. Mimicry stays: once a round from 300, the first scoring throw gains two copies of the
	## last player's best die (automatic).
	func after_throw(game, me, turn) -> void:
		var best: int = game.best_face_last_throw()
		if best < 4 or not game.t2_available(me) or not _has_scorer(turn):
			return
		game.mark_t2(me)
		for i in int(game.opt("mimic", 2)):
			turn.faces.append(best)


class Pride extends "res://sins/pride.gd":
	func before_turn(_game, _me, _turn) -> void:
		pass  # Hubris is the power now; on_bank still pays it; Untouchable stays


class Gluttony extends "res://sins/gluttony.gd":
	func after_throw(_game, _me, _turn) -> void:
		pass  # Feast off; Gorge stays


class Sloth extends "res://sins/sloth.gd":
	func after_throw(_game, _me, _turn) -> void:
		pass  # Lazy Bones off; Drag stays


static func all() -> Array:
	return [Wrath, Greed, Lust, Envy, Pride, Gluttony, Sloth]
