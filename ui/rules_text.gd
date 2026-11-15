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
	var r: Dictionary = Rules.V4  # the table game plays V4 (Docs/TableDesign.md)
	var fm: int = r.face_mult
	var chain: float = r.chain
	var targets: Array = r.hubris_targets
	var tstr := ", ".join(targets.slice(0, targets.size() - 1).map(func(t): return str(t))) + " or %d" % targets[-1]
	return {
		"win": Rules.WIN_SCORE, "strikes": Rules.STRIKES_TO_BUST, "greater_at": Rules.TIER2_SCORE,
		"start_dice": Rules.START_DICE, "min_dice": Rules.MIN_DICE,
		"die_cost": r.die_cost, "purg_cost": r.purgatory_cost, "seat_bonus": r.seat_bonus,
		"f4": 4 * fm, "f5": 5 * fm, "f6": 6 * fm, "face_mult": _num_word(fm),
		"x2": _mult(1.0 + chain), "x3": _mult(1.0 + chain * 2), "x4": _mult(1.0 + chain * 3),
		# Worked example: 4, 6, 3.
		"ex_sum": 10 * fm, "ex_total": int(10 * fm * (1.0 + chain)),
		"rage": r.rage, "fury_dice": _num_word(r.fury_dice), "fury_trigger": r.fury_trigger,
		"vig": r.vig, "interest": r.interest, "interest_pct": Greed.INTEREST_PCT, "interest_cap": Greed.INTEREST_CAP,
		"pact": r.pact, "pact_pct": Lust.PACT_PCT, "mimic": _num_word(Envy.MIMIC_COPIES),
		"hubris_targets": tstr, "hubris_mult": _mult(Pride.MULT),
		"feast": r.feast, "gorge": r.gorge,
		"drag": r.drag, "marks": _num_word(r.marks_to_claim).capitalize(),
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
		"Every 1 and 2 you throw is a Strike. Strikes add up over your whole turn: each one snuffs a candle beside the dice.",
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
## epithet, playstyle (one line), complexity (1-3), [Basic name, text], [Greater name, text].
const SINS := {
	"Wrath": {"epithet": "the Avenger", "play": "Profit when others fall.", "pips": 1,
		"basic": ["Spark of Rage", "+{rage} whenever a rival busts."],
		"greater": ["Fury", "The first rival throw worth {fury_trigger}+ rerolls its {fury_dice} best dice."]},
	"Greed": {"epithet": "the Hoarder", "play": "Grow rich on everyone's spending.", "pips": 1,
		"basic": ["The Vig", "When a rival buys a die, you get {vig} of its price."],
		"greater": ["Interest", "Bank and buy no dice: +{interest}."]},
	"Lust": {"epithet": "the Temptress", "play": "Take the best of what others throw.", "pips": 2,
		"basic": ["Whisper of Desire", "Once a turn, your 3 or 2 becomes the last player's best die."],
		"greater": ["Binding Pact", "Pick a rival; take {pact} of the next turn they Bank."]},
	"Envy": {"epithet": "the Mirror", "play": "Copy the previous player's best die.", "pips": 2,
		"basic": ["Green-Eyed Glance", "While behind, your first scoring throw each turn copies the last player's best die."],
		"greater": ["Mimicry", "That throw gains two copies instead."]},
	"Pride": {"epithet": "the Untouchable", "play": "Bet on yourself and win big.", "pips": 3,
		"basic": ["Hubris", "Before throwing, bet {hubris_targets}: Bank that much for {hubris_mult}, else 0."],
		"greater": ["Untouchable", "The first ability aimed at you bounces back."]},
	"Gluttony": {"epithet": "the Devourer", "play": "Trade dice for points.", "pips": 3,
		"basic": ["Feast", "Once a turn, feed a thrown die for +{feast}; a fed Strike doesn't count."],
		"greater": ["Gorge", "Your first die each turn costs {gorge}."]},
	"Sloth": {"epithet": "the Delayer", "play": "Shrug off a Strike every turn.", "pips": 1,
		"basic": ["Lazy Bones", "Your first Strike each turn doesn't count."],
		"greater": ["Drag", "Pick a rival; they throw {drag} fewer dice next turn (never below 1)."]},
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
	"Strikes": ["The three candles beside the dice: each Strike this turn snuffs one. All three out is a bust.", "strikes"],
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
	"Pact": ["Lust's Binding Pact: Lust takes {pact} of the next turn this player banks.", "all_sins"],
	"Temptation": ["A rival Sin's offer on your turn: a gain now for a cost later. Accepting gives you its mark.", "temptations"],
	"Mark": ["What you take from a Sin when you accept its temptation. {marks} from one Sin, and it claims you.", "temptations"],
	"Claim": ["A Sin's lasting rule on you once you hold {marks} of its marks. It binds you for the rest of the game.", "temptations"],
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
	"throw_seal": "Throw\n{n}",
	"bank_seal": "Bank\n{n}",
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
	["^\\s+\\d+ Strikes: (.+?) BUSTS and goes to Purgatory\\.$", "Third Strike! $1 busts, off to Purgatory."],
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

## Temptations, by id (sins/temptations.gd holds the numbers; keep them in step). 12 words max.
const TEMPT := {
	"w1": "Wipe a Strike. Your next Bank loses 25.",
	"w2": "Take 60 from the leader. Start next turn with a Strike.",
	"w3": "Throw at x2. Lose 50 now.",
	"w4": "Two extra dice this throw. Your next Bank loses 50.",
	"g1": "A free die. Your next Bank loses 75.",
	"g2": "Clear a Strike. Your next Bank loses 25.",
	"g3": "Throw at x2. Your next Bank loses 50.",
	"g4": "Take 100 now. I take a die after this turn.",
	"l1": "Throw at x2. One fewer die next turn.",
	"l2": "Take 50 now. One fewer die next turn.",
	"l3": "Two extra dice this throw. One fewer next turn.",
	"l4": "Forget that Strike. Your next Bank loses 25.",
	"e1": "Two extra dice this throw. Start next turn with a Strike.",
	"e2": "Throw at x2. Start next turn with a Strike.",
	"e3": "A free die, like theirs. Lose 75 now.",
	"e4": "Clear a Strike. One fewer die next turn.",
	"p1": "Throw at x2, like royalty. Your next Bank loses 50.",
	"p2": "Two extra dice, as you deserve. One fewer next turn.",
	"p3": "Clear a Strike. Lose 25 now.",
	"p4": "Take 60 now. Start next turn with a Strike.",
	"u1": "Two extra dice this throw. Lose 25 now.",
	"u2": "Clear a Strike. I eat a die after.",
	"u3": "Throw at x2. I eat a die after.",
	"u4": "A free die. Start next turn with a Strike.",
	"s1": "Take 90 now. Two fewer dice next turn.",
	"s2": "Rest that Strike. One fewer die next turn.",
	"s3": "A free die. Two fewer dice next turn.",
	"s4": "Take 60 and rest. Start next turn with a Strike.",
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
	"tempt_tip": "Accept for the gain and take its mark. {marks} marks, and it claims you.",
	"tempt_prompt": "{sin} tempts you.",
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
}


static func tempt(id: String) -> String:
	return TEMPT.get(id, id)


static func claim(sname: String) -> String:
	return CLAIMS[sname].format(_v4_vals())


static func table(key: String, args := {}) -> String:
	return TABLE[key].format(args.merged(_v4_vals()))


static func _v4_vals() -> Dictionary:
	var r: Dictionary = Rules.V4
	return {"claim_bust": r.claim_bust, "claim_greed": r.claim_greed, "claim_envy": r.claim_envy,
		"claim_pride_min": r.claim_pride_min, "claim_sloth_fewer": _num_word(r.claim_sloth_fewer).capitalize().to_lower(),
		"min_dice": Rules.MIN_DICE, "marks": _num_word(r.marks_to_claim).capitalize()}


## Sin lines (Docs/TableDesign.md section 3; generated from the doc, keep the two in step). {name}: the rival Sin;
## {host}, {n}: Solo (slice c). tests/lines_check.gd: 6 words max, 5 per event, no repeats.
const LINES := {
	"Wrath": {
		"own_bust": ["Rrraagh! Again!", "Who cursed these dice?", "I'll burn this table.", "No. NO.", "That one stays with me."],
		"rival_bust": ["Burn, {name}.", "Ha! Into the fire.", "Your loss feeds my rage.", "Kneel in the ashes.", "Good. Suffer."],
		"big_bank": ["Feel that? Fury.", "Smash and take.", "Ashes for the rest.", "That's how you hit.", "Count it, cowards."],
		"lead": ["Top of the pyre.", "Now catch me.", "Who's angry now?", "The crown smoulders. Mine.", "Step up and burn."],
		"attacked": ["You'll pay for that.", "Big mistake, {name}.", "I remember faces.", "Oh, now it's war.", "That was your last."],
		"aim": ["You, {name}. Now.", "Payback, {name}.", "The leader burns first.", "I never forget, {name}.", "Your turn to burn."],
		"win": ["Everything burns. I win.", "Bow to the fire.", "Rage wins. Always.", "Told you. Ashes.", "Crawl home, all of you."],
		"lose": ["This isn't over.", "I'll be back. Angrier.", "Next table, you burn.", "Rigged. All of it.", "Remember my name."],
		"recall": ["{host} went easy. I won't.", "Still sore from Circle {n}.", "You burned past {host}. Not me.", "Circle {n} left you scarred.", "I heard you cheated {host}."],
	},
	"Greed": {
		"own_bust": ["A poor investment.", "Write it off. Quietly.", "That cost me dearly.", "Losses. Temporary losses.", "I'll bill someone for that."],
		"rival_bust": ["Your loss, my margin.", "Bankrupt. How sad.", "I'll buy your remains.", "Should've cashed out, {name}.", "Every bust pays someone."],
		"big_bank": ["Interest compounds. Beautifully.", "Into the vault.", "Profit. Lovely profit.", "Count it twice.", "Now that's a return."],
		"lead": ["Top earner. Naturally.", "The market favours me.", "Richest seat at the table.", "Buy low, lead high.", "I own this table."],
		"attacked": ["That will cost you.", "I'm adding interest, {name}.", "Theft! Noted. Billed.", "You'll repay that. Tenfold.", "Put it on your tab."],
		"aim": ["Your account's overdue, {name}.", "Collecting from the leader.", "Time to pay up.", "{name}, settle your debt.", "The richest pay most."],
		"win": ["Paid in full.", "The house always wins.", "All of it. Mine.", "Pleasure doing business.", "Closing the books. Goodbye."],
		"lose": ["Bad quarter. Nothing more.", "I want an audit.", "Keep the change.", "I'll buy this table later.", "Debts get collected, {name}."],
		"recall": ["You still owe me, Circle {n}.", "{host} paid. Now you pay.", "Your Circle {n} winnings? Mine now.", "{host}'s losses raised my rates.", "Welcome back, valued customer."],
	},
	"Lust": {
		"own_bust": ["Too much, too fast.", "Worth it, almost.", "I wanted it all.", "Again? I can't resist.", "Wanting has a price."],
		"rival_bust": ["Couldn't stop, could you?", "Oh, you poor thing.", "I know that longing.", "You wanted more. Me too.", "Such sweet ruin, {name}."],
		"big_bank": ["Oh, that's lovely.", "I'm only warming up.", "Can't look away, can you?", "More. Always more.", "Give me more!"],
		"lead": ["Everyone's watching me now.", "Follow me, everyone.", "Out in front. Lovely.", "Want this? Chase me.", "Mine to lose, sweetly."],
		"attacked": ["Ouch! How bold.", "Oh, {name}, how daring.", "You'll miss me later.", "Hands off what's mine.", "Rude, but impressive."],
		"aim": ["Come here, {name}.", "I want what's yours.", "The leader looks lovely.", "Your turn, dearest.", "{name}, I'm coming for you."],
		"win": ["You all wanted this.", "Simply irresistible.", "Satisfied, finally.", "Everything I wanted. Mine.", "Never enough. Except now."],
		"lose": ["Leaving me wanting? Cruel.", "Next time, I take everything.", "You've broken my heart.", "Mm, I'll remember you.", "Unfinished business, {name}."],
		"recall": ["Missed me since Circle {n}?", "{host} bored you. I won't.", "{host} told me about you.", "Did Circle {n} leave you wanting?", "Forget {host}. Look at me."],
	},
	"Envy": {
		"own_bust": ["Of course. Only me.", "Everyone else gets lucky.", "Why is it always me?", "Their dice are better.", "Unfair. Utterly unfair."],
		"rival_bust": ["Not so perfect now.", "Finally, someone else suffers.", "Good. Now you're me.", "How does that feel, {name}?", "Serves you right."],
		"big_bank": ["See? I can too.", "Look at me now.", "Bet you're jealous.", "Take that, all of you.", "Copied that from {name}."],
		"lead": ["My turn at the top.", "Now you envy me.", "How's the view from behind?", "Finally. It's mine.", "Don't you dare catch up."],
		"attacked": ["Always me. Always.", "Why not pick {name}?", "You think you're better?", "I'll take yours too.", "Everyone hates me. Fine."],
		"aim": ["You have too much, {name}.", "Whoever leads, I hate.", "Why do you deserve it?", "{name}, I want your luck.", "Share the crown, leader."],
		"win": ["Now you all want this.", "Look who's on top.", "Who's jealous now?", "Mine, and never yours.", "Finally, I'm the one."],
		"lose": ["Of course {name} won.", "It should've been me.", "Enjoy it. I won't.", "Lucky. Just lucky.", "One day, I'll have that."],
		"recall": ["You beat {host}? Lucky.", "Everyone talks about you. Ugh.", "Why did {host} get you first?", "Circle {n} was luck. Admit it.", "Everyone beat {host}. Even you."],
	},
	"Pride": {
		"own_bust": ["A test of my patience.", "The dice erred, not I.", "Beneath my notice.", "I allowed that.", "Even gods stumble. Briefly."],
		"rival_bust": ["Know your place.", "Predictable, {name}.", "As I foresaw.", "Pitiful. Truly pitiful.", "Mortals. Always overreaching."],
		"big_bank": ["As expected.", "Witness true greatness.", "Applause is customary.", "Effortless, naturally.", "Try to keep up."],
		"lead": ["Where I belong.", "The throne returns to me.", "Bow, if you please.", "Order is restored.", "Look up, all of you."],
		"attacked": ["How dare you, {name}.", "You touched the crown?", "Insolence. Noted.", "I am Untouchable.", "You'll kneel for that."],
		"aim": ["Remember your place, {name}.", "The pretender must fall.", "No one outshines me.", "{name} forgets who rules.", "Down from my throne."],
		"win": ["Was there any doubt?", "Kneel before your better.", "Perfection, as always.", "History will remember me.", "Of course I won."],
		"lose": ["I let you win.", "A hollow victory, {name}.", "This changes nothing.", "Enjoy my leftovers.", "The crown is merely lent."],
		"recall": ["{host} fell. I won't.", "I watched Circle {n}. Unimpressive.", "{host} was a warm-up act.", "You survived Circle {n}? Adorable.", "Beating {host} means nothing here."],
	},
	"Gluttony": {
		"own_bust": ["Bit off too much.", "Ugh. Indigestion.", "My eyes, too big.", "Spit it out. Again.", "Still hungry, though."],
		"rival_bust": ["More for me.", "Ooh, leftovers.", "Crumbs everywhere, {name}.", "You choked. I won't.", "Pass the plate."],
		"big_bank": ["Delicious!", "Second helping, please.", "Mmmf. Seconds.", "That filled me up.", "Feast, feast, feast!"],
		"lead": ["Biggest plate at the table.", "I'm getting fat on this.", "Top of the menu.", "Who's hungry? Just me.", "Belly first. Always."],
		"attacked": ["Hands off my plate!", "You ate my dice!", "I'll swallow you, {name}.", "Now I'm angry hungry.", "Rude. I was eating."],
		"aim": ["You look tasty, {name}.", "I'll eat the leader.", "Open wide, {name}.", "Biggest plate gets bitten.", "Dinner time, {name}."],
		"win": ["Every last crumb. Mine.", "Burp. Thank you all.", "The whole table, eaten.", "Dessert is victory.", "Stuffed. And champion."],
		"lose": ["Still starving.", "Leave me the scraps.", "I'll eat you next time.", "Too full to care.", "Save me a plate, {name}."],
		"recall": ["Hungry since {host}'s table.", "You smell like Circle {n}.", "{host} was only the starter.", "Circle {n} whetted my appetite.", "Saved room for you."],
	},
	"Sloth": {
		"own_bust": ["Eh. Too much effort.", "Should've stayed in bed.", "Wake me next turn.", "Worth it for the nap.", "That's what trying gets."],
		"rival_bust": ["Shoulda just rested.", "See? Trying hurts.", "Easy there, {name}.", "Mm. Called it. Yawn.", "Lie down a while."],
		"big_bank": ["Hm. That was easy.", "No sweat. Literally.", "Done. Nap time.", "Barely lifted a finger.", "Good enough. Bed."],
		"lead": ["Ahead? Didn't notice.", "Wake me at the end.", "Slow and steady.", "Huh. Look at that.", "Nobody rush. Please."],
		"attacked": ["Rude. I was napping.", "Must you, {name}?", "Ugh. Fine. Noted.", "So much effort. Why?", "I'll get you. Later."],
		"aim": ["Slow down, {name}.", "Sit down, leader.", "Take a break, {name}.", "Rest your dice, {name}.", "Let's all relax, leader."],
		"win": ["Wake me for the trophy.", "Didn't even try.", "Rest wins. Again.", "Can I sleep now?", "Told you. Patience."],
		"lose": ["Eh. Tomorrow.", "Too tired to care.", "Good game. Nap time.", "Next time, maybe.", "I'll rest on it."],
		"recall": ["Back again? Already? Ugh.", "Didn't {host} tire you out?", "Circle {n} again? So tiring.", "Five more minutes. Then you.", "You woke me for this?"],
	},
}
