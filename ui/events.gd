## Turns a rules log line (fixed formats in core/game.gd and sins/*.gd) into a typed event,
## so each gets its own beat. Unknown lines fall back to "log", so a wording change in core/
## only loses the specific beat, never breaks play. Durations at 1x: Docs/UXPass.md.
extends RefCounted

## [kind, pattern, seconds]. First match wins; order matters (ability lines are indented too).
const TABLE := [
	["ability", "^\\s+(.+?)'s (.+?): (.*)$", 0.6],
	["throw", "^(.+?) throws (\\d+): ", 0.6],
	["reroll", "^\\s+(Fury \\(bounced\\) rerolls|Rerolled:)", 0.5],
	["bust", "BUSTS and goes to Purgatory", 0.8],
	["score", "^\\s+\\+(\\d+) \\(turn (\\d+), Strikes (\\d+)\\)", 0.5],
	["hubris", "^\\s+Hubris (pays off|fails)", 0.6],
	["pact_cut", "^\\s+Binding Pact: ", 0.5],
	["bank", "^(.+?) banks (\\d+) \\(score (\\d+)\\)", 0.6],
	["buy", "^(.+?) buys (\\d+) ", 0.5],
	["vig", "^\\s+The Vig: ", 0.4],
	["attack", " (unleashes Fury on|binds a Pact on|Drags) ", 0.6],
	["bounce", " is Untouchable: ", 0.5],
	["attack_effect", "^\\s+.+ (must reroll|gives \\d+%? of|throws at most)", 0.4],
	["indulgence", " pays the Indulgence ", 0.5],
	["indulgence", "^\\s+No 6(:|, and) ", 0.5],  # V3: pays (or can't) and plays on
	["redemption", "^(.+?) rolls for Redemption: ", 0.6],
	["redemption", "^(.+?) throws to leave Purgatory: ", 0.6],  # V3
	["redeemed", "^\\s+A 6! (Redeemed|Free)", 0.4],
	["still_purgatory", "^\\s+No 6\\. Still in Purgatory", 0.4],
	["win", " WINS? with ", 1.5],
]
const LOG_BEAT := 0.35
const RulesText = preload("res://ui/rules_text.gd")

static var _compiled: Array = []
static var _say: Array = []
static var _you_verb: RegEx
static var _you_mid: RegEx


## A log line as a player would say it (patterns in ui/rules_text.gd SAY). who: whose turn it is.
## BBCode lines (the win) and lines no pattern knows pass through unchanged, minus their indent.
static func say(text: String, who := "") -> String:
	if text.strip_edges() == "" or text.begins_with("["):
		return text
	if _say.is_empty():
		for row in RulesText.SAY:
			_say.append([RegEx.create_from_string(row[0]), row[1]])
		_you_verb = RegEx.create_from_string("\\bYou ([a-z']+)\\b")
		_you_mid = RegEx.create_from_string("(?<=[a-z0-9,:] )You\\b")
	var out := text.strip_edges()
	for row in _say:
		var m: RegExMatch = row[0].search(text)
		if m:
			out = row[1]
			for i in range(m.get_group_count(), 0, -1):
				out = out.replace("$%d" % i, m.get_string(i))
			out = out.replace("{who}", who)
			break
	# "You" agrees with its verb and owns things as "Your".
	out = out.replace("You's ", "Your ")
	if out.begins_with("You "):
		out = out.replace(" their ", " your ")
	for m in _you_verb.search_all(out):
		var v: String = m.get_string(1)
		if RulesText.YOU_VERBS.has(v):
			out = out.replace("You %s" % v, "You %s" % RulesText.YOU_VERBS[v])
	return _you_mid.sub(out, "you", true)


## Returns {kind, match (RegExMatch or null), dur}. Blank lines take no time.
static func classify(text: String) -> Dictionary:
	if text.strip_edges() == "":
		return {"kind": "blank", "match": null, "dur": 0.0}
	if _compiled.is_empty():
		for row in TABLE:
			_compiled.append([row[0], RegEx.create_from_string(row[1]), row[2]])
	for row in _compiled:
		var m: RegExMatch = row[1].search(text)
		if m:
			return {"kind": row[0], "match": m, "dur": row[2]}
	return {"kind": "log", "match": null, "dur": LOG_BEAT}
