## Words on screen must be game terms from the glossary (ui/rules_text.gd).
## 1. Retired words (Indulgence, Redemption, Gambit, Tier) appear in no string in ui/, sins/ or core/game.gd.
## 2. Every ability name a Sin logs (fired(..., "Name", ...)) is a glossary term.
## 3. Every rulebook page a glossary term points to exists, and every {placeholder} is filled.
## godot --headless --path . --script res://tests/terms_check.gd
extends SceneTree

const T = preload("res://ui/rules_text.gd")
const RETIRED := ["Indulgence", "Redemption", "Redeem", "Gambit", "Tier 1", "Tier 2", "Tier1", "Tier2", "II ready"]
const ALLOWED := ["Sinners' Gambit"]  # the title
const SOURCES := ["res://ui", "res://sins", "res://core/game.gd"]


func _initialize() -> void:
	var fails: Array[String] = []
	var strings := RegEx.create_from_string("\"((?:[^\"\\\\]|\\\\.)*)\"")
	var fired := RegEx.create_from_string("fired\\(game, me, \"([^\"]+)\"")
	var g := T.glossary()
	for path in _files():
		var lines := FileAccess.get_file_as_string(path).split("\n")
		for n in lines.size():
			var line := lines[n]
			if line.find("# V2 only") >= 0:
				continue  # the old rules, sim only: never on screen
			var code := line.split("#")[0] if not line.strip_edges().begins_with("##") else ""
			if code.strip_edges().begins_with("##") or code.strip_edges() == "":
				continue
			for m in strings.search_all(code):
				var s := m.get_string(1)
				for a in ALLOWED:
					s = s.replace(a, "")
				for w in RETIRED:
					if s.find(w) >= 0 and not path.ends_with("terms_check.gd") and not path.ends_with("events.gd"):
						fails.append("%s:%d retired word \"%s\" in \"%s\"" % [path, n + 1, w, m.get_string(1)])
			for m in fired.search_all(code):
				if not g.has(m.get_string(1)):
					fails.append("%s:%d ability \"%s\" is not in the glossary" % [path, n + 1, m.get_string(1)])
	var ids := T.PAGES.map(func(p): return p.id)
	for k in g:
		if not (g[k][1] in ids):
			fails.append("glossary \"%s\" points to missing page \"%s\"" % [k, g[k][1]])
		if g[k][0].find("{") >= 0:
			fails.append("glossary \"%s\" has an unfilled placeholder: %s" % [k, g[k][0]])
	for p in T.PAGES:
		for para in p.body:
			if T.fill(para).find("{") >= 0:
				fails.append("page %s has an unfilled placeholder: %s" % [p.id, para])
	for s in T.SINS:
		for greater in [false, true]:
			var words := T.ability_text(s, greater).split(" ", false).size()
			if words > 15:
				fails.append("%s %s ability is %d words (max 15)" % [s, "Greater" if greater else "Basic", words])
	for f in fails:
		print(f)
	print("TERMS PASSED" if fails.is_empty() else "TERMS FAILED (%d)" % fails.size())
	quit()


func _files() -> Array:
	var out := []
	for src in SOURCES:
		if src.ends_with(".gd"):
			out.append(src)
			continue
		var d := DirAccess.open(src)
		for f in d.get_files():
			if f.ends_with(".gd"):
				out.append(src.path_join(f))
	return out
