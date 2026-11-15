## Table wording (Docs/TableDesign.md): Sin lines 6 words max, at least 5 per event per Sin, no line
## twice; every offer has a spoken line (5 max) and terms (gain, cost, one wording per kind), every Sin
## a claim; no placeholder left unfilled.
## godot --headless --path . --script res://tests/lines_check.gd
extends SceneTree

const T = preload("res://ui/rules_text.gd")
const Temptations = preload("res://sins/temptations.gd")
const EVENTS := ["own_bust", "rival_bust", "big_bank", "lead", "attacked", "aim", "win", "lose", "recall"]


func _initialize() -> void:
	var fails: Array[String] = []
	var seen := {}
	for s in T.SIN_ORDER:
		for ev in EVENTS:
			var lines: Array = T.LINES[s].get(ev, [])
			if lines.size() < 5:
				fails.append("%s %s: %d lines (5 needed)" % [s, ev, lines.size()])
			for l in lines:
				var n := String(l).split(" ", false).size()
				if n > 6:
					fails.append("%s %s: \"%s\" is %d words" % [s, ev, l, n])
				if seen.has(l):
					fails.append("\"%s\" twice (%s and %s %s)" % [l, seen[l], s, ev])
				seen[l] = "%s %s" % [s, ev]
		if not T.CLAIMS.has(s) or T.claim(s).find("{") >= 0:
			fails.append("%s: claim missing or unfilled" % s)
	# Offers: a spoken line (5 words max) and terms, gain then cost. Every gain or cost of one kind and
	# number reads the same for every Sin, and terms carry no Sin's voice (only the shared templates).
	var said := 0
	var by_kind := {}
	for sname in Temptations.OFFERS:
		for o in Temptations.OFFERS[sname]:
			var id: String = o.id
			var say: String = T.tempt_say(id)
			if say == "":
				fails.append("offer %s has no spoken line" % id)
				continue
			said += 1
			if say.split(" ", false).size() > 5:
				fails.append("offer %s spoken line over 5 words" % id)
			if seen.has(say):
				fails.append("\"%s\" twice" % say)
			seen[say] = "offer %s" % id
			var terms: Array = T.tempt_terms(id)
			if terms.size() != 2 or String(terms[0]) == "" or String(terms[1]) == "":
				fails.append("offer %s terms missing a gain or cost" % id)
				continue
			for i in 2:
				var t: String = terms[i]
				if t.find("{") >= 0:
					fails.append("offer %s term unfilled: %s" % [id, t])
				var k := "%s:%s%s:%d" % [["gain", "cost"][i], o.gain if i == 0 else o.cost, "_leader" if i == 0 and o.get("leader", false) else "", o.g if i == 0 else o.c]
				if by_kind.has(k) and by_kind[k] != t:
					fails.append("offer %s %s reads \"%s\", elsewhere \"%s\"" % [id, k, t, by_kind[k]])
				by_kind[k] = t
	if said != 28:
		fails.append("%d spoken lines (28 needed)" % said)
	for id in T.TEMPT_SAY:
		if not (id in Temptations.all_ids()):
			fails.append("words for unknown offer %s" % id)
	for k in T.TABLE:
		if T.table(k, {"n": 1, "sin": "Wrath", "claim": "x", "pts": 80, "strikes": "1 Strike", "me": 30, "lead": 665}).find("{") >= 0:
			fails.append("table word %s unfilled" % k)
	for f in fails:
		print(f)
	print("LINES %s (%d lines)" % ["PASSED" if fails.is_empty() else "FAILED (%d)" % fails.size(), seen.size()])
	quit()
