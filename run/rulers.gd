## Ruling Sins (Docs/RunDesign.md §2): one twist each, in force for that Sin's round only.
## Circles 1-6: the other six Sins, mild twists only in Circles 1-2. Circle 7: your own Sin.
extends RefCounted

const Kits = preload("res://run/kits.gd")


static func text(sin: String, cfg: Dictionary) -> String:
	match sin:
		"Sloth": return "You throw one fewer die."
		"Greed": return "Each Bank costs 1 gold; with none, it scores half."
		"Envy": return "Each turn, Envy takes one of your relics, until the round ends."
		"Lust": return "Single dice score no Points."
		"Wrath": return "Each die you leave unkept costs %d Points." % cfg.wrath_unkept
		"Pride": return "Each Bank must beat your last, or it scores 0."
		"Gluttony": return "Each Bank, Gluttony eats one of your dice, until the round ends."
	return ""


## The seven rulers for a run, Circle 1 first.
static func order(own: String, rng: RandomNumberGenerator) -> Array:
	var others: Array = Kits.ORDER.filter(func(s): return s != own)
	var mild: Array = others.filter(func(s): return s in Kits.MILD)
	var out: Array = []
	for i in 2:
		var pick: String = mild[rng.randi_range(0, mild.size() - 1)]
		mild.erase(pick)
		others.erase(pick)
		out.append(pick)
	while not others.is_empty():
		var j := rng.randi_range(0, others.size() - 1)
		out.append(others[j])
		others.remove_at(j)
	out.append(own)
	return out
