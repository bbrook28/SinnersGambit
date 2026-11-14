## Starting kits (Docs/RunDesign.md §4): one passive per Sin, nothing asks "use it?".
## Numbers come from cfg (run_state.gd default_cfg) so the sim can tune them.
extends RefCounted

const ORDER := ["Sloth", "Wrath", "Greed", "Lust", "Envy", "Pride", "Gluttony"]
const MILD := ["Sloth", "Greed", "Envy"]


static func text(sin: String, cfg: Dictionary) -> String:
	match sin:
		"Sloth": return "A bust still banks your Points, with no Mult." if cfg.sloth_bust_mult <= 0.0 else "A bust still banks your Points, with half your Mult."
		"Wrath": return "A bust adds +%d Mult to your next turn." % cfg.wrath_bust_mult
		"Greed": return "When you Bank, +%d Points for every gold you hold." % cfg.greed_per_gold
		"Lust": return "Every pair you keep adds +%d Mult, not +1." % cfg.lust_pair_mult
		"Envy": return "Your leftmost relic fires twice. Starts with one common relic."
		"Pride": return "Bank having kept only sets, no single dice: x2 total."
		"Gluttony": return "Once a turn, eat a die you can't keep; it counts as kept, for no Points."
	return ""


static func dice_count(sin: String, cfg: Dictionary) -> int:
	return cfg.gluttony_dice if sin == "Gluttony" else cfg.start_dice


## Mult a kept set of c dice adds before relics.
static func set_mult(sin: String, c: int, cfg: Dictionary) -> int:
	if sin == "Lust" and c == 2:
		return cfg.lust_pair_mult
	return c - 1


## A bust: Points banked anyway (Sloth), Mult carried to the next turn (Wrath).
static func on_bust(sin: String, points: int, mult: int, cfg: Dictionary) -> Array:
	if sin == "Sloth":
		return [points * maxi(1, int(mult * cfg.sloth_bust_mult)), 0]
	if sin == "Wrath":
		return [0, cfg.wrath_bust_mult]
	return [0, 0]


## Bank: [Points, times x2].
static func on_bank(sin: String, gold: int, only_sets: bool, cfg: Dictionary) -> Array:
	if sin == "Greed":
		return [cfg.greed_per_gold * gold, 0]
	if sin == "Pride" and only_sets:
		return [0, 1]
	return [0, 0]


static func can_eat(sin: String) -> bool:
	return sin == "Gluttony"
