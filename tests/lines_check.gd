## Table wording (Docs/TableDesign.md): Sin lines 6 words max, at least 5 per event per Sin, no line
## twice; every offer has words (12 max) and every Sin a claim; no placeholder left unfilled.
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
	for id in Temptations.all_ids():
		if not T.TEMPT.has(id):
			fails.append("offer %s has no words" % id)
		elif T.tempt(id).split(" ", false).size() > 12:
			fails.append("offer %s is over 12 words" % id)
	for id in T.TEMPT:
		if not (id in Temptations.all_ids()):
			fails.append("words for unknown offer %s" % id)
	for k in T.TABLE:
		if T.table(k, {"n": 1, "sin": "Wrath", "claim": "x"}).find("{") >= 0:
			fails.append("table word %s unfilled" % k)
	for f in fails:
		print(f)
	print("LINES %s (%d lines)" % ["PASSED" if fails.is_empty() else "FAILED (%d)" % fails.size(), seen.size()])
	quit()
