## The shop after every round (Docs/RunDesign.md §7): relics, one die, repaints, reroll.
## Works on a run_state.gd object; rules only.
extends RefCounted

const Relics = preload("res://run/relics.gd")
const Round = preload("res://run/round.gd")

const REPAINTS := ["six", "gild", "crimson"]
const REPAINT_TEXT := {
	"six": ["Six", "A face becomes a 6."],
	"gild": ["Gild", "The face scores +15 Points when kept."],
	"crimson": ["Crimson", "The face adds +1 Mult when kept."],
}


## Fills run.offers: {relics: [id or ""], die: bool, repaints: [kind or ""], rerolls: int}.
static func roll(run) -> void:
	var fx := Relics.effective(run.relics, false)
	run.offers = {
		"relics": _relic_offers(run, Relics.shop_relics(fx, run.cfg)),
		"die": run.dice.size() < run.cfg.max_dice,
		"repaints": [],
		"rerolls": 0,
	}
	for i in run.cfg.shop_repaints:
		run.offers.repaints.append(REPAINTS[run.rng.randi_range(0, REPAINTS.size() - 1)])


static func _relic_offers(run, n: int) -> Array:
	var owned := {}
	for r in run.relics:
		owned[r.id] = true
	var out: Array = []
	var w: Array = run.cfg.rarity_weights
	for i in n:
		var pool: Array = []
		for tries in 4:
			var roll_w: int = run.rng.randi_range(1, w[0] + w[1] + w[2])
			var rar := "C" if roll_w <= w[0] else ("U" if roll_w <= w[0] + w[1] else "R")
			pool = Relics.ids(rar).filter(func(id): return not owned.has(id) and not id in out and not id in run.banned)
			if not pool.is_empty():
				break
		if pool.is_empty():
			out.append("")
		else:
			out.append(pool[run.rng.randi_range(0, pool.size() - 1)])
			run.stats.offered.append(out[-1])
	return out


static func relic_price(run, id: String) -> int:
	return run.cfg.prices[Relics.rarity(id)]


static func sell_value(run, id: String) -> int:
	return relic_price(run, id) / 2


static func die_price(run) -> int:
	var i := mini(run.dice_bought, run.cfg.die_prices.size() - 1)
	return run.cfg.die_prices[i]


static func reroll_price(run) -> int:
	return run.cfg.reroll_base + run.offers.rerolls


static func can_buy_relic(run, i: int) -> bool:
	var id: String = run.offers.relics[i]
	return id != "" and run.gold >= relic_price(run, id) and run.relics.size() < run.cfg.relic_slots


static func buy_relic(run, i: int) -> bool:
	if not can_buy_relic(run, i):
		return false
	var id: String = run.offers.relics[i]
	run.gold -= relic_price(run, id)
	run.relics.append({"id": id, "n": 0})
	run.offers.relics[i] = ""
	run.stats.bought.append(id)
	return true


static func sell_relic(run, row_i: int) -> void:
	var id: String = run.relics[row_i].id
	run.gold += sell_value(run, id)
	run.relics.remove_at(row_i)


static func can_buy_die(run) -> bool:
	return run.offers.die and run.gold >= die_price(run) and run.dice.size() < run.cfg.max_dice


static func buy_die(run) -> bool:
	if not can_buy_die(run):
		return false
	run.gold -= die_price(run)
	run.dice_bought += 1
	run.dice.append(Round.plain_die())
	run.offers.die = false
	return true


## A face may take a repaint if it isn't the 1 (face index 0) and the die has room (two faces each).
static func can_repaint(run, die_i: int, face_i: int) -> bool:
	if face_i <= 0 or face_i > 5 or die_i < 0 or die_i >= run.dice.size():
		return false
	var r: Array = run.dice[die_i].r
	return face_i in r or r.size() < run.cfg.repaint_faces


static func can_buy_repaint(run, i: int) -> bool:
	return run.offers.repaints[i] != "" and run.gold >= run.cfg.repaint_price


static func buy_repaint(run, i: int, die_i: int, face_i: int) -> bool:
	if not can_buy_repaint(run, i) or not can_repaint(run, die_i, face_i):
		return false
	var d: Dictionary = run.dice[die_i]
	match run.offers.repaints[i]:
		"six": d.f[face_i] = 6
		"gild": d.g[face_i] = 1
		"crimson": d.c[face_i] = 1
	if not face_i in d.r:
		d.r.append(face_i)
	run.gold -= run.cfg.repaint_price
	run.offers.repaints[i] = ""
	return true


static func reroll(run) -> bool:
	var cost := reroll_price(run)
	if run.gold < cost:
		return false
	run.gold -= cost
	var fx := Relics.effective(run.relics, false)
	run.offers.relics = _relic_offers(run, Relics.shop_relics(fx, run.cfg))
	run.offers.rerolls += 1
	return true
