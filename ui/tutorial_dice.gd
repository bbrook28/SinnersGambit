## Rigged dice for the tutorial, without touching core/: core/game.gd draws every throw from
## game.rng through Rules.roll(), right after a moment the UI controls (your Throw answer, a bot's
## wants_throw, the start of a turn). Just before that draw, rig() re-seeds game.rng with a seed
## that makes Rules.roll() give the wanted faces. Found by trying seeds (6^4 = 1296 tries on
## average for four dice). The tutorial game is never saved, so the jump in the seed can't break
## Continue or replay.
extends RefCounted

const Rules = preload("res://core/rules.gd")
const MAX_TRIES := 2000000

static var _cache := {}


## A seed that makes Rules.roll(rng, faces.size()) return exactly `faces`, or -1.
static func seed_for(faces: Array) -> int:
	var key := str(faces)
	if _cache.has(key):
		return _cache[key]
	var rng := RandomNumberGenerator.new()
	for s in range(1, MAX_TRIES):
		rng.seed = s
		if _same(Rules.roll(rng, faces.size()), faces):
			_cache[key] = s
			return s
	push_error("Tutorial: no seed for %s" % key)
	return -1


static func _same(a: Array, b: Array) -> bool:
	for i in a.size():
		if a[i] != int(b[i]):
			return false
	return true


## The next throw of this game will be `faces`.
static func rig(game, faces: Array) -> void:
	var s := seed_for(faces)
	if s >= 0:
		game.rng.seed = s
