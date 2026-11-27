## The match log of the step 1 table (ui/table_screen.gd): one entry a move, and each player's ability totals.
## Display only: it records what the rules did and never changes the match.
extends RefCounted

var entries: Array = []   # {round, who, text, delta, total}, oldest first
var tally := {}           # seat -> {ability name -> {uses, mine, others}}


## One move. who: "Player 1 (Wrath)". delta: what it did to that player's points; total: their points after it.
func add(round_number: int, who: String, text: String, delta: int, total: int) -> void:
	entries.append({"round": round_number, "who": who, "text": text, "delta": delta, "total": total})


## One use of an ability by a seat: the points it gave the user, and what it did to the other players' points.
func count(seat: int, ability: String, mine: int, others := 0) -> void:
	if not tally.has(seat):
		tally[seat] = {}
	if not tally[seat].has(ability):
		tally[seat][ability] = {"uses": 0, "mine": 0, "others": 0}
	var t: Dictionary = tally[seat][ability]
	t.uses += 1
	t.mine += mine
	t.others += others


static func signed(n: int) -> String:
	return "+%d" % n if n >= 0 else str(n)


## An entry as one line of plain text: the same words on screen and in the copy.
static func line(e: Dictionary) -> String:
	return "R%d %s: %s [%s, total %d]" % [e.round, e.who, e.text, signed(e.delta), e.total]


## Every move, oldest first.
func lines() -> Array:
	return entries.map(func(e): return line(e))


## One line a player: their points, then uses and points for each ability they used.
func totals(names: Array, points: Array) -> Array:
	var out := []
	for i in names.size():
		var parts := []
		var mine: Dictionary = tally.get(i, {})
		var keys: Array = mine.keys()
		keys.sort()
		for k in keys:
			var t: Dictionary = mine[k]
			parts.append("%s x%d %s%s" % [k, t.uses, signed(t.mine), " (others %s)" % signed(t.others) if t.others != 0 else ""])
		out.append("%s, %d points: %s" % [names[i], points[i], "; ".join(parts) if not parts.is_empty() else "no abilities used"])
	return out


## The whole match as plain text: one line a move, oldest first, then the totals.
func copy_text(names: Array, points: Array) -> String:
	return "\n".join(lines() + ["Totals"] + totals(names, points))
