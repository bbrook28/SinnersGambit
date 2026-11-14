## The one place rule text lives: every rule, term and Sin ability in short, plain language.
## Numbers are never typed here: {placeholders} are filled from the rules config (core/rules.gd V3
## and the constants in sins/*.gd) by vals(). The rulebook, tap-to-explain, the tutorial and Sin
## select all read from this file. Docs/RulesDraft.md has the approved wording.
extends RefCounted

const Rules = preload("res://core/rules.gd")
const Wrath = preload("res://sins/wrath.gd")
const Greed = preload("res://sins/greed.gd")
const Lust = preload("res://sins/lust.gd")
const Envy = preload("res://sins/envy.gd")
const Pride = preload("res://sins/pride.gd")
const Gluttony = preload("res://sins/gluttony.gd")
const Sloth = preload("res://sins/sloth.gd")

const SIN_ORDER := ["Wrath", "Greed", "Lust", "Envy", "Pride", "Gluttony", "Sloth"]


## Every number the text uses, from the config.
static func vals() -> Dictionary:
	var r: Dictionary = Rules.V3
	var fm: int = r.face_mult
	var chain: float = r.chain
	var targets: Array = Pride.TARGETS
	var tstr := ", ".join(targets.slice(0, targets.size() - 1).map(func(t): return str(t))) + " or %d" % targets[-1]
	return {
		"win": Rules.WIN_SCORE, "strikes": Rules.STRIKES_TO_BUST, "greater_at": Rules.TIER2_SCORE,
		"start_dice": Rules.START_DICE, "min_dice": Rules.MIN_DICE,
		"die_cost": r.die_cost, "purg_cost": r.purgatory_cost, "seat_bonus": r.seat_bonus,
		"f4": 4 * fm, "f5": 5 * fm, "f6": 6 * fm, "face_mult": _num_word(fm),
		"x2": _mult(1.0 + chain), "x3": _mult(1.0 + chain * 2), "x4": _mult(1.0 + chain * 3),
		# Worked example: 4, 6, 3.
		"ex_sum": 10 * fm, "ex_total": int(10 * fm * (1.0 + chain)),
		"rage": Wrath.RAGE, "fury_dice": _num_word(Wrath.FURY_DICE),
		"vig": Greed.VIG, "interest_pct": Greed.INTEREST_PCT, "interest_cap": Greed.INTEREST_CAP,
		"pact_pct": Lust.PACT_PCT, "mimic": _num_word(Envy.MIMIC_COPIES),
		"hubris_targets": tstr, "hubris_mult": _mult(Pride.MULT),
		"feast": Gluttony.FEAST, "gorge": Gluttony.GORGE_PRICE,
		"drag": Sloth.DRAG,
	}


static func fill(text: String) -> String:
	return text.format(vals())


static func _mult(m: float) -> String:
	return "x%s" % (str(int(m)) if is_equal_approx(m, roundf(m)) else str(snappedf(m, 0.01)))


static func _num_word(n: int) -> String:
	var words := ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"]
	return words[n] if n >= 0 and n < words.size() else str(n)


# ---------- The short version ----------

## The whole first game in five sentences.
const FIVE := [
	"On your turn, throw all your dice as often as you like, then Bank to keep this turn's points.",
	"4, 5 and 6 score {face_mult} times their face; 3 does nothing; 1 and 2 are Strikes.",
	"Scoring several dice in one throw is worth more.",
	"Bust: your third Strike in a turn loses this turn's points and starts your next turn in Purgatory.",
	"After you bank you may buy dice for {die_cost} each, and the first to {win} wins.",
]


static func five() -> Array:
	return FIVE.map(func(s): return fill(s))


# ---------- Rulebook pages ----------
## id, title, art (what the rulebook draws above the words), body paragraphs.
const PAGES := [
	{"id": "contents", "title": "The Rules", "art": "", "body": []},
	{"id": "goal", "title": "Goal", "art": "windows", "body": [
		"Be the first to reach {win} points.",
		"Everyone at the table plays one of seven Sins, and each Sin bends one rule in its favour.",
		"Players further from the first seat start a little ahead: {seat_bonus} points for each seat."]},
	{"id": "turn", "title": "Your Turn", "art": "turn", "body": [
		"On your turn, throw all your dice.",
		"After each throw, choose: throw again, or Bank to keep this turn's points. The points from every throw add up until you bank or bust.",
		"There's no limit on throws. Each one can score more, and each one can bring a Strike."]},
	{"id": "scoring", "title": "Scoring", "art": "scoring", "body": [
		"4, 5 and 6 score {face_mult} times their face: {f4}, {f5} and {f6}. 3 does nothing. 1 and 2 are Strikes.",
		"Scoring several dice in one throw is worth more: two scoring dice {x2}, three {x3}, four {x4}. The game always shows the sum for you.",
		"Example: you throw 4, 6 and 3. The 4 and 6 score {ex_sum}, and two scorers make it {x2}: {ex_total}."]},
	{"id": "strikes", "title": "Strikes and Busting", "art": "strikes", "body": [
		"Every 1 and 2 you throw is a Strike. Strikes add up over your whole turn, counted beside the dice.",
		"Bust: your third Strike in a turn loses this turn's points and starts your next turn in Purgatory.",
		"Your Strikes clear when your turn ends."]},
	{"id": "banking", "title": "Banking", "art": "bank", "body": [
		"Bank to add this turn's points to your score. Your turn then ends.",
		"Banking early is safe. Throwing again can win more, or lose it all."]},
	{"id": "purgatory", "title": "Purgatory", "art": "purgatory", "body": [
		"A player who busts starts their next turn in Purgatory.",
		"You throw all your dice once, for free. Any 6 frees you. Otherwise you pay {purg_cost} (nothing if you can't).",
		"Either way, you then play your turn as normal."]},
	{"id": "buying", "title": "Buying Dice", "art": "buying", "body": [
		"After you bank, you may buy dice for {die_cost} each. They're yours for the rest of the game.",
		"More dice score more, but they also throw more Strikes.",
		"The table holds a limited supply of dice. When it runs out, no one can buy."]},
	{"id": "sins", "title": "Sins and Greater Abilities", "art": "tiers", "body": [
		"Every Sin has a Basic ability you can use from the start.",
		"The first time you reach {greater_at} points, your Greater ability unlocks for good. You can use it once a round.",
		"First Game: Basic abilities only, at a table of 4. Finishing a game unlocks Greater abilities and the Table of 7."]},
	{"id": "winning", "title": "Winning", "art": "winning", "body": [
		"The first player to reach {win} points wins the game at once."]},
	{"id": "all_sins", "title": "The Seven Sins", "art": "", "body": []},
	{"id": "glossary", "title": "Glossary", "art": "", "body": []},
]


static func page_index(id: String) -> int:
	for i in PAGES.size():
		if PAGES[i].id == id:
			return i
	return 0


# ---------- Sins ----------
## epithet, playstyle (one line), complexity (1-3), [Basic name, text], [Greater name, text].
const SINS := {
	"Wrath": {"epithet": "the Avenger", "play": "Profit when others fall.", "pips": 1,
		"basic": ["Spark of Rage", "Gain {rage} whenever another player busts."],
		"greater": ["Fury", "Once a round, make an opponent reroll their {fury_dice} best dice right after they throw."]},
	"Greed": {"epithet": "the Hoarder", "play": "Grow rich on everyone's spending.", "pips": 1,
		"basic": ["The Vig", "When an opponent buys a die, {vig} of its price goes to you."],
		"greater": ["Interest", "Bank and buy nothing to gain {interest_pct}% of your score, up to {interest_cap}."]},
	"Lust": {"epithet": "the Temptress", "play": "Take the best of what others throw.", "pips": 2,
		"basic": ["Whisper of Desire", "Once a turn, turn a 3 or 2 into the previous player's best die."],
		"greater": ["Binding Pact", "Pick an opponent; you take {pact_pct}% of the next turn they bank."]},
	"Envy": {"epithet": "the Mirror", "play": "Copy the previous player's best die.", "pips": 2,
		"basic": ["Green-Eyed Glance", "Once a turn, add a copy of the previous player's best die to this throw."],
		"greater": ["Mimicry", "Once a round, add {mimic} copies of the previous player's best die to this throw."]},
	"Pride": {"epithet": "the Untouchable", "play": "Bet on yourself and win big.", "pips": 3,
		"basic": ["Hubris", "Before throwing, bet {hubris_targets}: bank at least that for {hubris_mult}, else 0."],
		"greater": ["Untouchable", "Once a round, the first ability used against you hits its user instead."]},
	"Gluttony": {"epithet": "the Devourer", "play": "Trade dice for points.", "pips": 3,
		"basic": ["Feast", "Once a turn, sacrifice a thrown die for {feast}; a sacrificed Strike doesn't count."],
		"greater": ["Gorge", "Your first die each turn costs {gorge} instead of {die_cost}."]},
	"Sloth": {"epithet": "the Delayer", "play": "Shrug off a Strike every turn.", "pips": 1,
		"basic": ["Lazy Bones", "Your first Strike each turn doesn't count."],
		"greater": ["Drag", "Pick an opponent; next turn they throw {drag} fewer dice (never under 1)."]},
}


## "Name: text" for a Sin's Basic (0) or Greater (1) ability.
static func ability(sin_name: String, greater: bool) -> String:
	var a: Array = SINS[sin_name]["greater" if greater else "basic"]
	return "%s: %s" % [a[0], fill(a[1])]


static func ability_text(sin_name: String, greater: bool) -> String:
	return fill(SINS[sin_name]["greater" if greater else "basic"][1])


static func ability_name(sin_name: String, greater: bool) -> String:
	return SINS[sin_name]["greater" if greater else "basic"][0]


## The Sin and which ability an ability name belongs to: [sin, greater] or [] if none.
static func ability_owner(name: String) -> Array:
	for s in SINS:
		if SINS[s].basic[0] == name:
			return [s, false]
		if SINS[s].greater[0] == name:
			return [s, true]
	return []


# ---------- Glossary ----------
## Every game term that appears on screen, with a one-paragraph explanation and the rulebook page
## it belongs to. Ability names are added from SINS by glossary(). tests/terms_check.gd keeps
## retired words (and unknown ability names) off the screen.
const TERMS := {
	"Throw": ["Throw all your dice at once. After each throw, throw again or bank.", "turn"],
	"Turn": ["Your go: throw as often as you like, until you bank or bust.", "turn"],
	"Round": ["Everyone at the table takes one turn.", "sins"],
	"Score": ["Your banked points. The first to {win} wins. Points only count once you bank them.", "goal"],
	"Dice": ["How many dice you throw each time. You start with {start_dice}; buy more for {die_cost} each after you bank.", "buying"],
	"This turn": ["Points from this turn's throws so far. Bank to keep them; bust and they're lost.", "banking"],
	"Scoring": ["4, 5 and 6 score {face_mult} times their face: {f4}, {f5} and {f6}. 3 does nothing. 1 and 2 are Strikes.", "scoring"],
	"Multiplier": ["Scoring several dice in one throw is worth more: two scoring dice {x2}, three {x3}, four {x4}. The game does the sum for you.", "scoring"],
	"Strike": ["Every 1 or 2 you throw is a Strike. They add up over your turn. A third Strike is a bust.", "strikes"],
	"Strikes": ["The three marks beside the dice count your Strikes this turn. All three marked is a bust.", "strikes"],
	"Bust": ["Your third Strike in a turn: you lose this turn's points and start your next turn in Purgatory.", "strikes"],
	"Bank": ["Keep this turn's points: they're added to your score and your turn ends.", "banking"],
	"Purgatory": ["Where a bust sends you. Your next turn starts with a free throw: any 6 frees you, otherwise you pay {purg_cost} (nothing if you can't). Then you play as normal.", "purgatory"],
	"Buy dice": ["After you bank, buy dice for {die_cost} each. More dice score more, and throw more Strikes.", "buying"],
	"Supply": ["The dice left on the table to buy. When it's empty, no one can buy.", "buying"],
	"Sin": ["The character you play. Each of the seven Sins bends one rule with its abilities.", "all_sins"],
	"Basic ability": ["Your Sin's first ability. You have it from the start.", "sins"],
	"Greater ability": ["Your Sin's second ability. It unlocks for good the first time you reach {greater_at}, and you can use it once a round.", "sins"],
	"Greater ready": ["This player's Greater ability is unlocked and can be used this round.", "sins"],
	"Dragged": ["Sloth's Drag: this player throws {drag} fewer dice next turn (never under 1).", "all_sins"],
	"Pact": ["Lust's Binding Pact: Lust takes {pact_pct}% of the next turn this player banks.", "all_sins"],
	"First Game": ["Your first game: a table of 4, Basic abilities only, slower opponents. Finish it to unlock Greater abilities and the Table of 7.", "sins"],
}


## term -> [paragraph, page id], with every ability added as its own term.
static func glossary() -> Dictionary:
	var g := {}
	for k in TERMS:
		g[k] = [fill(TERMS[k][0]), TERMS[k][1]]
	for s in SINS:
		for greater in [false, true]:
			var a: Array = SINS[s]["greater" if greater else "basic"]
			g[a[0]] = ["%s's %s ability. %s" % [s, "Greater" if greater else "Basic", fill(a[1])], "all_sins"]
	return g


static func term(name: String) -> String:
	var g := glossary()
	return g[name][0] if g.has(name) else ""


static func term_page(name: String) -> String:
	var g := glossary()
	return g[name][1] if g.has(name) else "contents"


# ---------- Tutorial lines (ui/main.gd _tutorial_prompt) ----------
const TUTORIAL := {
	"throw": "Throw all your dice. Throw as often as you like.",
	"scoring": "4, 5 and 6 score {face_mult} times their face. 3 does nothing.",
	"multiplier": "Scoring several dice in one throw is worth more.",
	"strikes": "1s and 2s are Strikes. They add up all turn.",
	"bust": "Bust: a third Strike loses this turn's points and starts your next turn in Purgatory.",
	"bank": "Bank to keep this turn's points, or throw again to push your luck.",
	"sin": "Your Sin bends the rules: ",
	"goal": "First to {win} wins.",
}


static func tutorial(key: String) -> String:
	return fill(TUTORIAL[key])
