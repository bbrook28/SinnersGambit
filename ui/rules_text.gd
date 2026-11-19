## The one place rule text lives: every rule, term and Sin ability in short, plain language.
## Numbers are never typed here: {placeholders} are filled from the rules config (core/rules.gd V3
## and the constants in sins/*.gd) by vals(). The rulebook, tap-to-explain, the tutorial and Sin
## select all read from this file. Old approved wording: Docs/archive/RulesDraft.md.
extends RefCounted

const Rules = preload("res://core/rules.gd")
const Wrath = preload("res://sins/wrath.gd")
const Greed = preload("res://sins/greed.gd")
const Lust = preload("res://sins/lust.gd")
const Envy = preload("res://sins/envy.gd")
const Pride = preload("res://sins/pride.gd")
const Gluttony = preload("res://sins/gluttony.gd")
const Sloth = preload("res://sins/sloth.gd")
const Tuning = preload("res://ui/tuning.gd")
const Temptations = preload("res://sins/temptations.gd")

const SIN_ORDER := ["Wrath", "Greed", "Lust", "Envy", "Pride", "Gluttony", "Sloth"]


## The rules the text describes: the table (Tuning.table_view()) plays Rules.V5; the legacy board V4.
static func rules() -> Dictionary:
	return Rules.V5 if Tuning.table_view() else Rules.V4


static func v5() -> bool:
	return rules().get("v5", false)


## Every number the text uses, from the config.
static func vals() -> Dictionary:
	var r: Dictionary = rules()
	var fm: int = r.face_mult
	var chain: float = r.chain
	var targets: Array = r.hubris_targets
	var tstr := ", ".join(targets.slice(0, targets.size() - 1).map(func(t): return str(t))) + " or %d" % targets[-1]
	return {
		"win": Rules.WIN_SCORE, "call": Rules.MASTER_CALL, "strikes": Rules.STRIKES_TO_BUST, "greater_at": Rules.TIER2_SCORE,
		"start_dice": Rules.START_DICE, "min_dice": Rules.MIN_DICE,
		"die_cost": r.die_cost, "purg_cost": r.get("purgatory_cost", 0), "seat_bonus": r.seat_bonus,
		"f4": 4 * fm, "f5": 5 * fm, "f6": 6 * fm, "face_mult": _num_word(fm),
		"x2": _mult(1.0 + chain), "x3": _mult(1.0 + chain * 2), "x4": _mult(1.0 + chain * 3),
		# Worked example: 4, 6, 3.
		"ex_sum": 10 * fm, "ex_total": int(10 * fm * (1.0 + chain)),
		"rage": r.get("rage", Wrath.RAGE), "fury_dice": _num_word(r.fury_dice), "fury_trigger": r.fury_trigger,
		"vig": r.vig, "interest": r.interest, "interest_pct": Greed.INTEREST_PCT, "interest_cap": Greed.INTEREST_CAP,
		"pact": r.pact, "pact_pct": Lust.PACT_PCT, "mimic": _num_word(int(r.get("mimic", Envy.MIMIC_COPIES))),
		"hubris_targets": tstr, "hubris_mult": _mult(float(r.get("hubris_mult", Pride.MULT))),
		"feast": r.get("feast", Gluttony.FEAST), "gorge": r.gorge,
		"drag": r.drag, "marks": _num_word(r.marks_to_claim).capitalize(),
		# Rules.V5 powers and the Master of the Dance.
		"wrath_rethrow": _num_word(int(r.get("wrath_rethrow", 2))), "greed_mult": _mult(float(r.get("greed_mult", 1.5))),
		"eat": r.get("eat", 0), "claim_marks": _num_word(r.marks_to_claim).capitalize(), "close": Tuning.MASTER_CLOSE,
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
	"Bust: your third Strike in a turn loses this turn's points.",
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
		"Every 1 and 2 you throw is a Strike. Strikes add up over your whole turn: each one snuffs a candle beside the dice.",
		"Bust: your third Strike in a turn loses this turn's points.",
		"Your Strikes clear when your turn ends."]},
	{"id": "banking", "title": "Banking", "art": "bank", "body": [
		"Bank to add this turn's points to your score. Your turn then ends.",
		"Banking early is safe. Throwing again can win more, or lose it all."]},
	{"id": "buying", "title": "Buying Dice", "art": "buying", "body": [
		"After you bank, you may buy dice for {die_cost} each. They're yours for the rest of the game.",
		"More dice score more, but they also throw more Strikes.",
		"The table holds a limited supply of dice. When it runs out, no one can buy."]},
	{"id": "sins", "title": "Sins and Greater Abilities", "art": "tiers", "body": [
		"Every Sin has a power: once a turn, when its seal glows, tap it to use it.",
		"The first time you reach {greater_at} points, your Greater ability unlocks for good. You can use it once a round.",
		"First Game: no powers or Greater abilities, at a table of 4. Finishing a game unlocks them and the Table of 7."]},
	{"id": "temptations", "title": "Temptations", "art": "", "body": [
		"Once a turn, a rival Sin may offer you a deal: a gain now for a cost later. Accept or refuse with one tap.",
		"Accepting gives you that Sin's mark. A Sin whose mark you hold comes back to tempt you again.",
		"{marks} marks from one Sin, and it claims you: its claim binds you for the rest of the game."]},
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
## epithet, playstyle (one line), complexity (1-3), [Basic name, text], [Greater name, text],
## [power name, text] (Rules.V5: the Basic as a once-a-turn seal, 10 words max; TableDesign §10),
## greater_v5 where V5 changes the Greater's numbers.
const SINS := {
	"Wrath": {"epithet": "the Avenger", "play": "Profit when others fall.", "pips": 1,
		"power": ["Rethrow", "Rethrow up to {wrath_rethrow} of this throw's Strikes."],
		"basic": ["Spark of Rage", "+{rage} whenever a rival busts."],
		"greater": ["Fury", "The first rival throw worth {fury_trigger}+ rerolls its {fury_dice} best dice."]},
	"Greed": {"epithet": "the Hoarder", "play": "Grow rich on everyone's spending.", "pips": 1,
		"power": ["Cash Out", "Bank half your stake at {greed_mult}; keep throwing."],
		"basic": ["The Vig", "When a rival buys a die, you get {vig} of its price."],
		"greater": ["Interest", "Bank and buy no dice: +{interest}."]},
	"Lust": {"epithet": "the Temptress", "play": "Take the best of what others throw.", "pips": 2,
		"power": ["Desire", "Turn a Strike into the last player's best die."],
		"basic": ["Whisper of Desire", "Once a turn, your 3 or 2 becomes the last player's best die."],
		"greater": ["Binding Pact", "Pick a rival; take {pact} of the next turn they Bank."]},
	"Envy": {"epithet": "the Mirror", "play": "Copy the previous player's best die.", "pips": 2,
		"power": ["Copy", "Copy your best die: it scores its face again."],
		"greater_v5": ["Mimicry", "Once a round, a scoring throw gains {mimic} copies of the last best die."],
		"basic": ["Green-Eyed Glance", "While behind, your first scoring throw each turn copies the last player's best die."],
		"greater": ["Mimicry", "That throw gains two copies instead."]},
	"Pride": {"epithet": "the Untouchable", "play": "Bet on yourself and win big.", "pips": 3,
		"power": ["Hubris", "Name your Bank: reach it for {hubris_mult}, else nothing."],
		"basic": ["Hubris", "Before throwing, bet {hubris_targets}: Bank that much for {hubris_mult}, else 0."],
		"greater": ["Untouchable", "The first ability aimed at you bounces back."]},
	"Gluttony": {"epithet": "the Devourer", "play": "Trade dice for points.", "pips": 3,
		"power": ["Devour", "Eat a Strike die: +{eat} to your stake."],
		"basic": ["Feast", "Once a turn, feed a thrown die for +{feast}; a fed Strike doesn't count."],
		"greater": ["Gorge", "Your first die each turn costs {gorge}."]},
	"Sloth": {"epithet": "the Delayer", "play": "Shrug off a Strike every turn.", "pips": 1,
		"power": ["Idle", "Ignore this throw's Strikes; the first becomes a 4."],
		"basic": ["Lazy Bones", "Your first Strike each turn doesn't count."],
		"greater": ["Drag", "Pick a rival; they throw {drag} fewer dice next turn (never below 1)."]},
}


## A Sin's Basic (greater false) or Greater ability, [name, text]. Under Rules.V5 the Basic is the power.
static func _ability(sin_name: String, greater: bool) -> Array:
	var s: Dictionary = SINS[sin_name]
	if v5():
		return s.get("greater_v5", s.greater) if greater else s.power
	return s.greater if greater else s.basic


## "Name: text" for a Sin's Basic (or V5 power) or Greater ability.
static func ability(sin_name: String, greater: bool) -> String:
	var a := _ability(sin_name, greater)
	return "%s: %s" % [a[0], fill(a[1])]


static func ability_text(sin_name: String, greater: bool) -> String:
	return fill(_ability(sin_name, greater)[1])


static func ability_name(sin_name: String, greater: bool) -> String:
	return _ability(sin_name, greater)[0]


## The power's line beside my seal (Rules.V5), 10 words max.
static func power(sin_name: String) -> String:
	return fill(SINS[sin_name].power[1])


## The Sin and which ability an ability name belongs to: [sin, greater] or [] if none.
static func ability_owner(name: String) -> Array:
	for s in SINS:
		if SINS[s].power[0] == name or SINS[s].basic[0] == name:
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
	"Strikes": ["The three candles beside the dice: each Strike this turn snuffs one. All three out is a bust.", "strikes"],
	"Bust": ["Your third Strike in a turn: you lose this turn's points.", "strikes"],
	"Bank": ["Keep this turn's points: they're added to your score and your turn ends.", "banking"],
	"Power": ["Your Sin's seal: once a turn, when it glows, tap it to use it.", "sins"],
	"The Vig": ["Greed's lasting rule: when a rival buys a die, Greed gets {vig} of its price.", "all_sins"],
	"Buy dice": ["After you bank, buy dice for {die_cost} each. More dice score more, and throw more Strikes.", "buying"],
	"Supply": ["The dice left on the table to buy. When it's empty, no one can buy.", "buying"],
	"Sin": ["The character you play. Each of the seven Sins bends one rule with its abilities.", "all_sins"],
	"Basic ability": ["Your Sin's first ability. You have it from the start.", "sins"],
	"Greater ability": ["Your Sin's second ability. It unlocks for good the first time you reach {greater_at}, and you can use it once a round.", "sins"],
	"Greater ready": ["This player's Greater ability is unlocked and can be used this round.", "sins"],
	"Dragged": ["Sloth's Drag: this player throws {drag} fewer dice next turn (never under 1).", "all_sins"],
	"Pact": ["Lust's Binding Pact: Lust takes {pact} of the next turn this player banks.", "all_sins"],
	"Temptation": ["A rival Sin's offer on your turn: a gain now for a cost later. Accepting gives you its mark.", "temptations"],
	"Mark": ["What you take from a Sin when you accept its temptation. {marks} from one Sin, and it claims you.", "temptations"],
	"Claim": ["A Sin's lasting rule on you once you hold {marks} of its marks. It binds you for the rest of the game.", "temptations"],
	"First Game": ["Your first game: a table of 4, no powers or Greater abilities, gentler opponents. Finish it to unlock them and the Table of 7.", "sins"],
}

## Rules.V4 only (the legacy board and the retired tutorial). Rules.V5 has no Purgatory (TableDesign §10).
const LEGACY_PURGATORY := "Where a bust sends you. Your next turn starts with a free throw: any 6 frees you, otherwise you pay {purg_cost} (nothing if you can't). Then you play as normal."


## term -> [paragraph, page id], with every ability added as its own term (V4's Basics and V5's
## powers both: core logs either).
static func glossary() -> Dictionary:
	var g := {}
	for k in TERMS:
		g[k] = [fill(TERMS[k][0]), TERMS[k][1]]
	if not v5():
		g["Purgatory"] = [fill(LEGACY_PURGATORY), "strikes"]
	for s in SINS:
		var b: Array = SINS[s].basic
		var p: Array = SINS[s].power
		var gr: Array = SINS[s].get("greater_v5", SINS[s].greater) if v5() else SINS[s].greater
		var basic := ["%s's Basic ability. %s" % [s, fill(b[1])], "all_sins"]
		var pw := ["%s's power. %s" % [s, fill(p[1])], "all_sins"]
		g[b[0]] = basic
		g[p[0]] = pw if v5() or p[0] != b[0] else basic  # Pride's Hubris is both
		g[gr[0]] = ["%s's Greater ability. %s" % [s, fill(gr[1])], "all_sins"]
	return g


static func term(name: String) -> String:
	var g := glossary()
	return g[name][0] if g.has(name) else ""


static func term_page(name: String) -> String:
	var g := glossary()
	return g[name][1] if g.has(name) else "contents"


# ---------- Tutorial (ui/tutorial_game.gd SCRIPT, in order) ----------
## A practice game with set dice. {ability} is your Sin's Basic ability ("Name: text").
const TUTORIAL := {
	"settings_play": "Play",
	"skip": "Skip",
	"tap": "Tap to continue",
	"welcome": "A practice game against Sloth. The dice are set, so you'll see every rule once.",
	"throw": "Tap Throw to throw all your dice.",
	"scored": "4, 5 and 6 score {face_mult} times their face; 3 does nothing. Two scorers in one throw make it {x2}.",
	"again": "Every throw adds to this turn's points. Throw again.",
	"strike": "A 1 or 2 is a Strike: it snuffs a candle. Strikes add up all turn.",
	"bank": "Bank now to keep this turn's points.",
	"buy": "After you bank, you may buy dice for {die_cost} each. More dice score more, and throw more Strikes. Buy one.",
	"bot": "Sloth's turn. Watch its best die: your Sin can copy it.",
	"turn2": "Your turn again, now with four dice. Throw.",
	"sin": "You are Envy. {ability} Tap Yes.",
	"glance": "The copy counts like any die you threw.",
	"risk": "One candle is out. Push your luck: throw again.",
	"bust": "Three Strikes: bust. This turn's points are lost, and your next turn starts in Purgatory.",
	"purgatory": "Purgatory: your turn starts with a free throw. Any 6 frees you; without one you pay {purg_cost}.",
	"done": "That's the game. Throw, bank before your luck runs out, and be the first to {win}.",
	"done_play": "Play",
	"done_menu": "Menu",
}


static func tutorial(key: String, args := {}) -> String:
	var v := vals()
	v.merge(args, true)
	return TUTORIAL[key].format(v)


# ---------- On-screen words (Phase 2: legibility) ----------
## Labels, seals and the lines the game writes during play. {n}, {name} and the like are filled by
## the caller (word()); rule numbers still come from vals().
const WORDS := {
	"score": "Score",
	"dice": "Dice",
	"this_turn": "This turn {n}",
	"strikes": "Strikes",
	"throw_cap": "Throw",  # under the Throw seal; its dice count is the gold numeral beside it
	"bank_cap": "Bank",  # under the Bank seal; the points are the numeral beside it
	"your_turn": "Your turn",
	"their_turn": "{name}'s turn",
	"purgatory_need": "Purgatory: a 6 frees you",
	"at_dice_you": "You are at the dice.",
	"at_dice": "{name} is at the dice.",
	"chronicle_turn": "{name}'s turn ({score})",
	"chronicle_your_turn": "Your turn ({score})",
	# Opening card.
	"open_title": "You are {sin}",
	"open_epithet": "{sin}, {epithet}: {play}",
	"open_greater": "From {greater_at} points: {ability}",
	"open_goal": "Be the first to {win} points.",
	"open_first": "You throw first.",
	"open_seat": "You throw {ordinal} of {count}, so you start with {score} points.",
	"open_seat_plain": "You throw {ordinal} of {count}.",
	"open_begin": "Begin",
	# One line after each throw.
	"res_scores_one": "{faces} scores {sum}.",
	"res_scores": "{faces} score {sum}.",
	"res_scores_mult": "{faces} score {sum}, {mult} = {total}.",
	"res_nothing": "Nothing scores.",
	"res_strike": " One Strike.",
	"res_strikes": " {count} Strikes.",
	"res_bust": "Third Strike: bust. This turn's points are lost.",
	# Beside a score as it changes (1.5 s).
	"cause_bank": "Banked",
	"cause_buy_one": "Bought a die",
	"cause_buy": "Bought {n} dice",
	"cause_purgatory": "Purgatory",
	"cause_score": "Score",
	# Sin select (Phase 4).
	"setup_title": "Choose thy Sin",
	"setup_blurb": "{others} shall face thee. First to {win}.",
	"setup_blurb_first": "Three others shall face thee. First to {win}. Finishing a game unlocks Greater abilities and the Table of 7.",
	"setup_three": "Three others",
	"setup_six": "Six others",
	"setup_table": "Table of {n}",
	"setup_recommended": "Recommended",
	"setup_choose": "Choose",
	# Pause menu (Phase 5).
	"pause_title": "Paused",
	"pause_resume": "Resume",
	"pause_rulebook": "Rulebook",
	"pause_sins": "Sin abilities",
	"pause_chronicle": "Chronicle",
	"pause_settings": "Settings",
	"pause_menu": "Main menu",
	# Bot-turn summary (Phase 5): "Wrath: banked 120 (now 540)".
	"sum_playing": "at the dice",
	"sum_bank": "banked {n} (now {score})",
	"sum_bust": "went bust, lost {n}",
	"sum_buy_one": "bought a die",
	"sum_buy": "bought {n} dice",
	"sum_ability": "{ability}",
	"sum_attack": "{ability} on {target}",
	"sum_freed": "left Purgatory",
	"sum_stuck": "stays in Purgatory",
}

## Bot-turn summary: an attack line's verb (an Events "attack" line) -> the ability's name.
const ATTACK_NAMES := {"unleashes Fury on": "Fury", "binds a Pact on": "Binding Pact", "Drags": "Drag"}
## Status badge -> the glossary term a tap on it explains.
const BADGE_TERMS := {"purg": "Purgatory", "greater": "Greater ready", "drag": "Dragged", "pact": "Pact"}

static func word(key: String, args := {}) -> String:
	var v := vals()
	v.merge(args, true)
	return WORDS[key].format(v)


static func ordinal(n: int) -> String:
	var ends := {1: "st", 2: "nd", 3: "rd"}
	return "%d%s" % [n, ends.get(n % 10, "th") if (n % 100) / 10 != 1 else "th"]


## Ticker and Chronicle: each rules log line (fixed formats in core/game.gd and sins/*.gd) as a
## player would say it. [pattern, replacement]: first match wins, $1.. are the captures, {who} is
## whoever's turn it is. ui/events.gd applies them; a line that matches none shows as written.
const SAY := [
	["^(.+?) throws (\\d+): (.+)$", "$1 throws $2 dice: $3"],
	["^(.+?) throws to leave Purgatory: (.+)$", "$1 throws to leave Purgatory: $2"],
	["^\\s+Fury \\(bounced\\) rerolls (\\d+): (.+)$", "Fury bounces back: the best $1 dice are thrown again: $2"],
	["^\\s+Rerolled: (.+)$", "Thrown again: $1"],
	["^\\s+\\d+ Strikes: (.+?) BUSTS and goes to Purgatory\\.$", "Third Strike! $1 busts, off to Purgatory."],  # Rules.V4 (legacy board)
	["^\\s+\\d+ Strikes: (.+?) BUSTS\\.$", "Third Strike! $1 busts."],
	["^\\s+\\+0 \\(turn (\\d+), Strikes \\d+\\)$", "{who} scores nothing ($1 this turn)."],
	["^\\s+\\+(\\d+) \\(turn (\\d+), Strikes \\d+\\)$", "{who} scores $1 ($2 this turn)."],
	["^\\s+Hubris pays off: (\\d+) -> (\\d+)$", "Hubris pays off: $1 becomes $2."],
	["^\\s+Hubris fails: (\\d+) -> 0$", "Hubris fails: $1 becomes 0."],
	["^\\s+Binding Pact: (.+?) takes (\\d+)\\.$", "Binding Pact: $1 takes $2."],
	["^(.+?) banks (\\d+) \\(score (\\d+)\\)\\.$", "$1 banks $2. Score: $3."],
	["^(.+?) buys 1 die for (\\d+) \\(now (\\d+) dice\\)\\.$", "$1 buys a die for $2 ($3 dice now)."],
	["^(.+?) buys (\\d+) dice for (\\d+) \\(now (\\d+) dice\\)\\.$", "$1 buys $2 dice for $3 ($4 dice now)."],
	["^\\s+The Vig: (.+?) takes (\\d+)\\.$", "The Vig: $1 takes $2."],
	["^(.+?) Drags (.+?)\\.$", "$1 uses Drag on $2."],
	["^(.+?) binds a Pact on (.+?)\\.$", "$1 binds $2 with a Binding Pact."],
	["^\\s+(.+?) must reroll (\\d+) best dice on their next throw\\.$", "$1 must throw their $2 best dice again next throw."],
	["^\\s+(.+?) must reroll (\\d+) best dice\\.$", "$1 must throw their $2 best dice again."],
	["^\\s+(.+?) gives (\\d+)% of their next banked turn to (.+?)\\.$", "$1 gives $2% of their next bank to $3."],
	["^\\s+(.+?) gives (\\d+) of their next banked turn to (.+?)\\.$", "$1 gives $2 of their next Bank to $3."],
	["^\\s+(.+?)'s answer: (.+)$", "$1 $2."],
	["^\\s+(.+?)'s claim: (.+?), for the rest of the game$", "$1 claims $2 for the rest of the game."],
	["^\\s+(.+?) throws at most (\\d+) fewer dice next turn\\.$", "$1 throws $2 fewer dice next turn."],
	["^\\s+A 6! Free\\.$", "A 6! {who} is free of Purgatory."],
	["^\\s+No 6: (.+?) pays (\\d+) to leave Purgatory\\.$", "No 6: $1 pays $2 to leave Purgatory."],
	["^\\s+No 6, and (.+?) can't pay: free anyway\\.$", "No 6, but $1 can't pay: $1 leaves Purgatory free."],
	# Abilities: "  Wrath's Spark of Rage: +50 (Greed busted)" -> "Wrath's Spark of Rage: gains 50 (Greed busted)."
	["^\\s+(.+?)'s (.+?): \\+(\\d+) \\((.+?) busted\\)$", "$1's $2: gains $3 because $4 busted."],
	["^\\s+(.+?)'s (.+?): \\+(\\d+) for buying nothing$", "$1's $2: earns $3 for buying nothing."],
	["^\\s+(.+?)'s (.+?): gives up a (\\d) for \\+(\\d+) \\((\\d+) dice left\\)$", "$1's $2: gives up a $3 for $4 ($5 dice left)."],
	["^\\s+(.+?)'s (.+?): first die cost (\\d+)$", "$1's $2: the first die costs $3."],
	["^\\s+(.+?)'s (.+?): bets (\\d+)\\. Must bank at least \\d+$", "$1's $2: bets $3. Bank at least $3, or score 0."],
	["^\\s+(.+?)'s (.+?): (.+)$", "$1's $2: $3."],
]

## "You" as the subject of a log line: the verb that goes with it.
const YOU_VERBS := {"throws": "throw", "busts": "bust", "banks": "bank", "buys": "buy", "uses": "use",
	"binds": "bind", "gives": "give", "pays": "pay", "is": "are", "scores": "score", "unleashes": "unleash",
	"leaves": "leave", "takes": "take", "must": "must", "can't": "can't"}


# ---------- Run mode (Docs/RunDesign.md), placeholder board until Phase 9 ----------
const RUN := {
	"menu_sub": "Seven Circles. Keep, rethrow, Bank.",
	"menu_run": "Run (old)",
	"setup_title": "Choose thy Sin",
	"setup_blurb": "Your Sin is your starting kit. Clear seven Circles; the last is ruled by your own Sin.",
	"circle": "Circle {c}",
	"trial": "Trial {n} of 2",
	"sin_round": "{sin} rules",
	"target": "Target",
	"score": "Score",
	"turns": "Turns",
	"gold": "Gold",
	"points": "Points",
	"mult": "Mult",
	"throw": "Throw",
	"bank": "Bank",
	"next": "Next",
	"bust_chance": "Bust {n}%",
	"hint_throw": "Throw your dice.",
	"hint_pick": "Tap dice to keep. Then Throw the rest, or Bank.",
	"hint_eat": "Gluttony: tap a die you can't keep to eat it.",
	"hint_all": "Every die kept: they all come back, once a turn.",
	"hint_bank_only": "Every die kept twice: Bank.",
	"bust": "Bust!",
	"banked": "Banked {n}.",
	"cleared": "Round cleared. +{g} gold.",
	"shop": "Shop",
	"shop_next": "Next: Circle {c}, {round}. Target {t}.",
	"shop_ruler": "{sin} rules Circle {c}: {twist}",
	"shop_relic": "{name} ({rar}) {price}g\n{text}",
	"shop_die": "Die {price}g\nAdds a plain die (you have {n}; at most {max}).",
	"shop_repaint": "{name} {price}g\n{text}",
	"shop_reroll": "Reroll {price}g",
	"shop_leave": "Go on",
	"shop_pick_face": "Pick a face to repaint (not the 1; two faces a die).",
	"shop_cancel": "Cancel",
	"sell": "Sell for {n}g",
	"close": "Close",
	"empty_slot": "Empty",
	"rar_C": "common",
	"rar_U": "uncommon",
	"rar_R": "rare",
	"won": "The seventh Circle falls. You win.",
	"lost": "Circle {c} holds you. The run is over.",
	"end_stats": "{sin}. Circle {c}. {turns} turns, {busts} busts. Best Bank {best}. {min} minutes.",
	"new_run": "New run",
	"to_menu": "Menu",
	"export_log": "Export",
	"exported_short": "Copied {n}",
	"rules_title": "How a run plays",
	"rules_body": "Throw your dice. Keep at least one group: a single 4, 5 or 6, or a set of matching dice. A set adds Mult.\nThen throw the rest again, or Bank: Points x Mult goes to your score.\nA throw with nothing to keep is a bust: the turn scores nothing.\nReach each target in three turns. Spend gold on relics between rounds.",
	"rules_ok": "Begin",
}


static func run(key: String, args := {}) -> String:
	return RUN[key].format(args)


# ---------- The table (Rules.V4, Docs/TableDesign.md) ----------

## Temptations, by id (sins/temptations.gd holds the numbers). Each offer is a spoken line in the Sin's
## voice (5 words max) and its terms: one gain, one cost, worded from GAIN_TERMS / COST_TERMS so the
## same gain or cost reads the same for every Sin.
const TEMPT_SAY := {
	"w1": "Wipe it clean.",
	"w2": "Tear it from them.",
	"w3": "Burn it all.",
	"w4": "Hit harder.",
	"g1": "On credit, naturally.",
	"g2": "A small fee.",
	"g3": "Interest applies, of course.",
	"g4": "Cash now. Collateral later.",
	"l1": "Twice the pleasure, darling.",
	"l2": "Take it, darling.",
	"l3": "More for you, sweetheart.",
	"l4": "I'll kiss it away.",
	"e1": "You deserve their dice.",
	"e2": "Double, like the leader.",
	"e3": "Their luck, for you.",
	"e4": "They always get this.",
	"p1": "Score like royalty.",
	"p2": "As you deserve.",
	"p3": "A mere trifle.",
	"p4": "My gift to you.",
	"u1": "Delicious, isn't it?",
	"u2": "Feed me a die.",
	"u3": "Twice the feast.",
	"u4": "Fresh and juicy.",
	"s1": "Take it and rest.",
	"s2": "Rest that Strike.",
	"s3": "Why bother?",
	"s4": "Lie back. Take it.",
}

## Terms by kind ({n}: the offer's number; {count}: it as a word). "_1" and "_leader" are the variants.
const GAIN_TERMS := {
	"points": "Take {n} now.",
	"points_leader": "Take {n} from the leader.",
	"clear": "Clear a Strike.",
	"dice": "{Count} extra dice this throw.",
	"x2": "Throw at x2.",
	"die": "A free die.",
}
const COST_TERMS := {
	"lose": "Lose {n} now.",
	"bank": "Your next Bank loses {n}.",
	"strike": "Start next turn with a Strike.",
	"fewer": "{Count} fewer dice next turn.",
	"fewer_1": "One fewer die next turn.",
	"die": "Lose a die after this turn.",
}


## Claims, by Sin (numbers from Rules.V4).
const CLAIMS := {
	"Wrath": "Each bust costs you {claim_bust}.",
	"Greed": "Every Bank pays Greed {claim_greed}.",
	"Lust": "You can't Bank before your second throw.",
	"Envy": "While you lead, each Bank pays Envy {claim_envy}.",
	"Pride": "A Bank under {claim_pride_min} scores nothing.",
	"Gluttony": "Each bust eats one of your dice (never below {min_dice}).",
	"Sloth": "You throw {claim_sloth_fewer} fewer dice (never below 1).",
}

const TABLE := {
	"menu_sub": "Throw the dice. Bank or burn. Resist the Sins.",
	"tempt_tip": "Accept for the gain and take its mark. {marks} marks, and it claims you.",
	"tempt_prompt": "{sin} tempts you.",
	"tempt_context": "This turn {pts}  ·  {strikes}  ·  You {me}  ·  Leader {lead}",
	"tempt_context_lead": "This turn {pts}  ·  {strikes}  ·  You lead {me} to {lead}",
	"accept": "Accept",
	"refuse": "Refuse",
	"accepts": "accepts",
	"refuses": "refuses",
	"temptation": "Temptation",
	"answer": "Answer",
	"claimed": "{sin} claims you: {claim}",
	"chip_bank": "-{n}\nnext Bank",
	"chip_strike": "Strike\nnext turn",
	"chip_fewer": "-{n} dice\nnext turn",
	"chip_fewer_1": "-1 die\nnext turn",
	"chip_die": "-1 die\nat turn end",
	"hubris_name": "Name {n}",
	"you_lower": "you",
}


static func tempt_say(id: String) -> String:
	return TEMPT_SAY.get(id, "")


## The offer's terms, [gain, cost], worded from its numbers in sins/temptations.gd.
static func tempt_terms(id: String) -> Array:
	for sname in Temptations.OFFERS:
		for o in Temptations.OFFERS[sname]:
			if o.id == id:
				return offer_terms(o)
	return []


## The terms of this offer as made (Rules.V5 scales a trailing seat's gain: core/game.gd scaled_offer).
static func offer_terms(o: Dictionary) -> Array:
	var gk: String = o.gain + ("_leader" if o.get("leader", false) else "")
	var ck: String = o.cost + ("_1" if o.cost == "fewer" and o.c == 1 else "")
	return [_term(GAIN_TERMS[gk], o.g), _term(COST_TERMS[ck], o.c)]


## Both terms on one line (the log).
static func tempt(id: String) -> String:
	return " ".join(tempt_terms(id)) if TEMPT_SAY.has(id) else id


static func _term(t: String, n: int) -> String:
	return t.format({"n": n, "Count": _num_word(n).capitalize()})


static func claim(sname: String) -> String:
	return CLAIMS[sname].format(_v4_vals())


static func table(key: String, args := {}) -> String:
	return TABLE[key].format(args.merged(_v4_vals()))


static func _v4_vals() -> Dictionary:
	var r: Dictionary = rules()
	return {"claim_bust": r.claim_bust, "claim_greed": r.claim_greed, "claim_envy": r.claim_envy,
		"claim_pride_min": r.claim_pride_min, "claim_sloth_fewer": _num_word(r.claim_sloth_fewer).capitalize().to_lower(),
		"min_dice": Rules.MIN_DICE, "marks": _num_word(r.marks_to_claim).capitalize()}


## Sin lines (Docs/TableDesign.md section 3; generated from the doc, keep the two in step). {name}: the rival Sin;
## {host}, {n}: Solo (slice c). tests/lines_check.gd: 6 words max, 5 per event, no repeats.
const LINES := {
	"Wrath": {
		"own_bust": ["Rrraagh! Again!", "Which of you cursed these?", "I'll burn this table.", "Someone pays for this.", "That one stays with me."],
		"rival_bust": ["Burn, {name}.", "Ha! Into the fire.", "Your loss feeds my rage.", "Kneel in the ashes.", "Scream louder, {name}."],
		"big_bank": ["Feel that? Fury.", "I break. I take.", "Ashes for the rest.", "Next, I hit you.", "Count it, cowards."],
		"lead": ["Top of the pyre.", "Catch me, if you dare.", "Who's angry now?", "The crown smoulders. Mine.", "Step up and bleed."],
		"attacked": ["You'll pay for that.", "Your last mistake, {name}.", "I remember faces.", "Oh, now it's war.", "Run, {name}. Run now."],
		"aim": ["You, {name}. Now.", "Payback, {name}. Brace yourself.", "The leader burns first.", "I never forget, {name}.", "Your turn to bleed."],
		"win": ["Everything burns. I win.", "Bow to the fire.", "On your knees, worms.", "Told you. Ashes.", "Crawl home, all of you."],
		"lose": ["This isn't over.", "I'll be back. Angrier.", "Next table, you burn.", "I'll find you, {name}.", "Sleep lightly, {name}."],
		"recall": ["{host} went easy. I won't.", "Still sore from Circle {n}.", "You burned past {host}. Not me.", "Circle {n} left you scarred.", "Cheat {host}? Try cheating me."],
	},
	"Greed": {
		"own_bust": ["A poor investment.", "Write it off. Quietly.", "A rounding error. Ignore it.", "Losses. Temporary losses.", "I'll bill someone for that."],
		"rival_bust": ["Your loss, my margin.", "Bankrupt. I'll take the furniture.", "I'll buy your remains.", "Should've cashed out, {name}.", "Every bust pays someone."],
		"big_bank": ["Interest compounds. Beautifully.", "Into the vault. Forever.", "Profit. The only true love.", "Count it twice.", "Now that's a return."],
		"lead": ["Top earner. Naturally.", "The market favours me.", "I hold your debts now.", "Buy low, lead high.", "I own this table. And you."],
		"attacked": ["That will cost you.", "I'm adding interest, {name}.", "Theft. Noted. Collected later.", "You'll repay that. Tenfold.", "Everything you own is collateral."],
		"aim": ["Your account's overdue, {name}.", "Collecting from the leader.", "Pay, {name}, or forfeit everything.", "{name}, settle your debt.", "Your fortune looks underpriced, leader."],
		"win": ["Paid in full.", "The house always wins.", "All of it. Mine.", "Every soul here, signed over.", "Closing the books. Goodbye."],
		"lose": ["Bad quarter. Nothing more.", "I want an audit.", "Keep it. I'll repossess later.", "I'll buy this table later.", "Debts get collected, {name}."],
		"recall": ["You still owe me, Circle {n}.", "{host} paid. Now you pay.", "Your Circle {n} winnings? Mine now.", "{host}'s losses raised my rates.", "Welcome back, valued customer."],
	},
	"Lust": {
		"own_bust": ["Mm. Too much, too fast.", "Worth it, almost.", "You caught me wanting.", "Again? I can't resist.", "Pleasure has a price."],
		"rival_bust": ["Couldn't stop, could you?", "Poor thing. Let me comfort you.", "I know that hunger.", "You wanted more. Me too.", "Such sweet ruin, {name}."],
		"big_bank": ["Doesn't that feel good?", "Mm, I'm only warming up.", "You can't look away.", "Don't stop now, darling.", "Ooh, give me more."],
		"lead": ["All eyes on me. Good.", "Follow me, darlings.", "Out in front. Lovely.", "Want this? Come closer.", "Mine to lose, sweetly."],
		"attacked": ["Rough. I like it.", "Oh, {name}, you're bold.", "You'll want me back.", "Careful what you touch.", "That stung. How thrilling."],
		"aim": ["Come closer, {name}. Closer.", "I want what's yours.", "The leader looks tempting.", "Your turn, sweetheart.", "{name}, I'm coming for you."],
		"win": ["You all wanted me.", "Utterly irresistible. Me.", "Satisfied, finally.", "Kiss the dice goodbye.", "Never enough. Except now."],
		"lose": ["Leaving me wanting? Cruel.", "Next time, I take everything.", "Leaving so soon, {name}?", "I'll remember your touch.", "Unfinished business, {name}."],
		"recall": ["Missed me since Circle {n}?", "{host} bored you. I won't.", "{host} told me about you.", "Still warm from Circle {n}?", "Come closer. Forget {host}."],
	},
	"Envy": {
		"own_bust": ["Of course. Only me.", "Everyone else gets lucky.", "Why is it always me?", "Their dice. Their luck. Theirs.", "I hope you're all happy."],
		"rival_bust": ["Not so perfect now.", "Finally, someone else suffers.", "Good. Now you're me.", "How does that feel, {name}?", "I prayed for that, {name}."],
		"big_bank": ["See? I can too.", "Look at me. LOOK at me.", "Now you know how it feels.", "Take that, all of you.", "Copied that from {name}."],
		"lead": ["Hate me now? Good.", "Now you envy me.", "How's the view from behind?", "Finally. It's mine.", "Don't you dare catch up."],
		"attacked": ["Always me. Always.", "Why not pick {name}?", "You think you're better?", "I'll take everything you love.", "Everyone hates me. Fine."],
		"aim": ["You have too much, {name}.", "Whoever leads, I hate.", "Why do you deserve it?", "{name}, I want your life.", "Your crown should be mine."],
		"win": ["Now you all want this.", "Envy me. I insist.", "Who's jealous now?", "Mine, and never yours.", "Finally, I'm the one."],
		"lose": ["Of course {name} won.", "It should've been me.", "Enjoy it. I won't.", "Lucky. Just lucky.", "I'll wear your smile someday."],
		"recall": ["You beat {host}? Lucky.", "Everyone adores you. I don't.", "Why did {host} get you first?", "Circle {n} was luck. Admit it.", "Everyone beat {host}. Even you."],
	},
	"Pride": {
		"own_bust": ["A test of my patience.", "The dice erred, not I.", "Beneath my notice.", "I allowed that.", "Even gods stumble. Briefly."],
		"rival_bust": ["Know your place.", "Predictable, {name}.", "Crawl back to the gutter.", "Pitiful. Truly pitiful.", "Mortals. Always overreaching."],
		"big_bank": ["As expected.", "Witness true greatness.", "Applause is customary.", "Effortless, naturally.", "Weep, lesser souls. Weep."],
		"lead": ["Where I belong.", "The throne returns to me.", "Bow. Lower. Lower still.", "Order is restored.", "Look up, all of you."],
		"attacked": ["How dare you, {name}.", "You touched the crown?", "Insolence. You'll beg for mercy.", "I am Untouchable.", "You'll kneel for that."],
		"aim": ["Remember your place, {name}.", "The pretender must fall.", "No one outshines me.", "{name} forgets who rules.", "Off my throne, you peasant."],
		"win": ["Was there any doubt?", "Kneel before your better.", "Perfection, as always.", "History will forget you all.", "Of course I won."],
		"lose": ["I let you win.", "A hollow victory, {name}.", "This changes nothing.", "Savour it. It won't happen again.", "The crown is merely lent."],
		"recall": ["{host} fell. I won't.", "I watched Circle {n}. Unimpressive.", "{host} was a warm-up act.", "You survived Circle {n}? Adorable.", "Beating {host} means nothing here."],
	},
	"Gluttony": {
		"own_bust": ["Bit off too much.", "Urp. It's coming back up.", "My eyes, too big.", "Spit it out. Again.", "Still hungry. Always hungry."],
		"rival_bust": ["More for me.", "Ooh, warm leftovers.", "I'll lick up your crumbs, {name}.", "You choked. I won't.", "Pass the plate."],
		"big_bank": ["Delicious!", "Second helping, please.", "Mmmf. Gristle and all.", "Loosen the belt. Wider.", "Feast, feast, feast!"],
		"lead": ["Biggest plate at the table.", "I'm getting fat on this.", "Top of the menu.", "Who's hungry? Just me.", "My belly leads the way."],
		"attacked": ["Hands off my plate!", "You ate my dice!", "I'll swallow you whole, {name}.", "Now I'm angry hungry.", "Rude. I was eating."],
		"aim": ["You look juicy, {name}.", "I'll eat the leader.", "Open wide, {name}.", "Biggest plate gets bitten.", "I'll pick my teeth with {name}."],
		"win": ["Every last crumb. Mine.", "BURRRP. Thank you all.", "The whole table, eaten.", "Dessert is victory.", "Stuffed. And champion."],
		"lose": ["Still starving.", "Leave me the scraps.", "I'll eat you next time.", "I'll gnaw on this loss.", "Save me a plate, {name}."],
		"recall": ["Hungry since {host}'s table.", "You smell delicious. Like Circle {n}.", "{host} was only the starter.", "Circle {n} whetted my appetite.", "Saved room for you."],
	},
	"Sloth": {
		"own_bust": ["Eh. Too much effort.", "Should've stayed in bed.", "Wake me next turn.", "Worth it for the nap.", "That's what trying gets."],
		"rival_bust": ["All that effort. For nothing.", "See? Trying hurts.", "Pathetic. And so loud.", "Mm. Called it. Yawn.", "Lie down. Stay down."],
		"big_bank": ["Hm. That was easy.", "No sweat. Literally.", "Done. Nap time.", "Barely lifted a finger.", "You sweat. I win."],
		"lead": ["Ahead? Didn't notice.", "Wake me at the end.", "Look at you all. Panting.", "Huh. Look at that.", "Nobody rush. Please."],
		"attacked": ["Rude. I was napping.", "Must you, {name}?", "Ugh. Fine. Noted.", "So much effort. So little point.", "I'll get you. Later."],
		"aim": ["Slow down, {name}.", "Sit down, leader.", "Sleep, {name}. Forever, perhaps.", "Rest your dice, {name}.", "Such frantic little creatures."],
		"win": ["Wake me for the trophy.", "Didn't even try. You did.", "Rest wins. Again.", "Can I sleep now?", "Told you. Patience."],
		"lose": ["Eh. Tomorrow.", "Too tired to care.", "Good game. Nap time.", "Sweating for a win? Vulgar.", "I'll rest on it."],
		"recall": ["Back again? Already? Ugh.", "Didn't {host} tire you out?", "Circle {n} again? So tiring.", "Five more minutes. Then you.", "You woke me for this?"],
	},
}


# ---------- The Master of the Dance (Docs/TableDesign.md §10) ----------
## His lines by event, 6 words max. A line [text, condition] states a fact and plays only when it is
## true (ui/main.gd master_event): "first" I throw first; "stake" my bust lost 100+; "first_mark" my
## first mark of that Sin; "close" I lost within {close} of the winner. Numbers through vals().
const MASTER := {
	"start": ["Take your seats. The dance begins.", "Dice ready. Souls ready. Shall we?", "Seven Sins, one table. Delightful.", "Mind your candles. Let us begin.", ["You throw first. Do begin.", "first"]],
	"my_bust": ["Ah. The dice have spoken.", "{strikes} candles out. Do sit.", "A misstep. Everyone stumbles.", "Gone. Shall we try again?", ["Pity. It was going beautifully.", "stake"]],
	"my_bank": ["Splendid. Do bank like that again.", "Well kept. The Sins noticed.", "A fine harvest, if I may.", "Bravo. My compliments to your nerve.", "Into your keeping. Nicely done."],
	"rival_bust": ["Oh dear. Not you this time.", "{name} trips. How very human.", "Snuffed. Do take note.", "The dance claims {name}. Briefly.", "Careful steps win. Usually."],
	"offer": ["{name} has a little proposal.", "A word from {name}, please.", "Ah, {name} wishes to bargain.", "Listen closely. {name} is generous.", "{name} approaches. Mind your purse."],
	"mark": ["Marked. {name} will remember.", "A small price. For now.", "Signed in ink. How brave.", "{name} smiles. That's rarely good.", ["One mark. {claim_marks} and it claims.", "first_mark"]],
	"claim": ["{claim_marks} marks. {name} owns you now.", "Claimed. I did mention it.", "{name} will keep you close.", "Bound. The dance goes on.", "Well. A lasting arrangement, then."],
	"my_win": ["The dance is yours. Well played.", "{win}. I'm genuinely impressed.", "Victory. The Sins will sulk.", "Bow, please. You've earned it.", "Splendid. Do come again."],
	"my_loss": ["Not tonight. There's always another.", "The dice were unkind. Again?", "A good dance, all the same.", "Rest. The table will wait.", ["Close. Closer than they'd admit.", "close"]],
	"call": ["{call} reached. Two rounds left.", "Two rounds left. Then I judge.", "The music slows. Two rounds.", "Nearly done. Two rounds remain.", "Savour it. Two rounds to go."],
	"final": ["Last round. Highest score wins.", "Final round. Make it count.", "Last dance. No second chances.", "One last throw each. Choose well.", "The end. Dance it well."],
	"final_order": ["Final round: {first} first, {last} last.", "Last round, leader first: {last} last.", "Final round: {first} opens, {last} closes."],
	"marked_me": ["You lead. No chain this round.", "Ahead? Then no chain this round.", "First place. No chain this round.", "Marked. No chain this round.", "Leader's toll: no chain this round."],
	"marked_rival": ["{name} leads. No chain.", "{name} leads. Chain off this round.", "I mark {name}. No chain.", "Marked: {name}. No chain this round.", "{name} pays: no chain this round."],
	"idle": ["Throw, or keep? Your call.", "Candles are patient. I am less.", "Courage or caution, dear guest?", "Another throw? Purely a suggestion.", "Take your time. Eternity's long."],
}


## The lines for an event whose conditions hold (facts: the condition names that are true), filled.
static func master_lines(ev: String, facts: Array, args := {}) -> Array:
	var v := vals()
	v.merge(args, true)
	var out := []
	for l in MASTER.get(ev, []):
		if l is Array:
			if l[1] in facts:
				out.append(String(l[0]).format(v))
		else:
			out.append(String(l).format(v))
	return out
