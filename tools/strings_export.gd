## Strings export (REPLY 26 item 5): every player-facing string, grouped by speaker, with where it shows.
## Wording is copied as written ({placeholders} unfilled); nothing is changed. Tables from ui/rules_text.gd,
## then the strings typed in code (questions, table labels), found by a scan with file:line.
## godot --headless --path . --script res://tools/strings_export.gd -- <out.md>
extends SceneTree

const T = preload("res://ui/rules_text.gd")

var out: PackedStringArray = []


func _initialize() -> void:
	var path: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "res://Docs/review/latest/strings.md"
	_h1("Player-facing strings (REPLY 26 item 5)")
	_p("Copied as written; nothing changed. `{x}` is filled at play (a name, a number from the rules). Source: `ui/rules_text.gd` unless a file:line is given. The parked run game (`RUN`) is left out.")

	_h2("1. The Master")
	_p("Shows: on the table, his plate in his robe over the windows (one line a round at most; call, final round, mark and end always). A line with a condition plays only when it is true.")
	for ev in T.MASTER:
		var items := []
		for l in T.MASTER[ev]:
			items.append("%s  _(only if: %s)_" % [l[0], l[1]] if l is Array else str(l))
		_list(ev, items)
	_p("Offer screen, his line before a Sin's offer: the `offer` event above (`ui/main.gd` master_offer_line).")

	_h2("2. The Sins")
	_p("Lines show on the table, on the Master's plate spot in the Sin's colour with its sigil (`Tuning.LINE_CHANCE` of events). Offer lines show on the offer screen under the Sin's portrait. Claims show on the offer screen and in the log when a Sin claims you. Name, epithet, play and abilities show in Sin select, the rulebook and the pause menu's Sin abilities; the power is the line beside my seal.")
	var prefix := {"Wrath": "w", "Greed": "g", "Lust": "l", "Envy": "e", "Pride": "p", "Gluttony": "u", "Sloth": "s"}
	for s in T.SIN_ORDER:
		_h3(s)
		var d: Dictionary = T.SINS[s]
		out.append("- **Epithet:** %s. **Play:** %s" % [d.epithet, d.play])
		for k in ["power", "basic", "greater", "greater_v5"]:
			if d.has(k):
				out.append("- **%s:** %s: %s" % [k, d[k][0], d[k][1]])
		out.append("- **Claim:** %s" % T.CLAIMS[s])
		var offers := []
		for id in T.TEMPT_SAY:
			if id.begins_with(prefix[s]):
				offers.append("%s (%s)" % [T.TEMPT_SAY[id], id])
		out.append("- **Offer lines:** " + " · ".join(offers))
		for ev in T.LINES[s]:
			out.append("- **%s:** %s" % [ev, " · ".join(T.LINES[s][ev])])
		out.append("")

	_h2("3. Questions")
	_p("Shows: the prompt over the choice row (table: the plate under the windows; the board: the prompt line). Typed in code, so listed with file:line.")
	_scan(["res://ui/human.gd"], [])  # the decision prompts and their answers, built line by line
	_scan(["res://sins", "res://core", "res://ui/main.gd"], ["ask(", "pick(", "_choose(", "show_prompt("])
	_list("Offer prompt and answers (TABLE)", ["tempt_prompt: " + T.TABLE.tempt_prompt, "accept: " + T.TABLE.accept, "refuse: " + T.TABLE.refuse, "tempt_tip: " + T.TABLE.tempt_tip, "tempt_context: " + T.TABLE.tempt_context, "tempt_context_lead: " + T.TABLE.tempt_context_lead])

	_h2("4. Labels")
	_p("WORDS: seals, banners, the opening card, results, Sin select, the pause menu, the bot-turn summary (the table uses `their_turn`; the rest shows on main's screens and the old board). TABLE: the menu line, offer screen and chips. Terms: the offer's gain and cost.")
	_dict("WORDS", T.WORDS)
	_dict("TABLE", T.TABLE)
	_dict("GAIN_TERMS (offer gain)", T.GAIN_TERMS)
	_dict("COST_TERMS (offer cost)", T.COST_TERMS)
	_p("Typed in table code:")
	_scan(["res://ui/table_blockout.gd", "res://ui/table_play.gd"], ["_label(\"", "_text_label(\"", "_flat_button(\"", "_seal(near, \""])

	_h2("5. Rulebook and glossary")
	_p("Shows: the rulebook (pause menu) and tap-to-explain cards.")
	_list("FIVE (the first game in five sentences)", T.FIVE)
	for pg in T.PAGES:
		_list("Page: %s" % str(pg[1]) if pg is Array else "Page", _strings(pg))
	var terms := []
	for k in T.TERMS:
		terms.append("**%s:** %s" % [k, T.TERMS[k][0]])
	_list("TERMS", terms)

	_h2("6. Log and Chronicle")
	_p("Shows: the ticker and the Chronicle (pause menu): core's log lines reworded. Pattern → as shown.")
	var say := []
	for r in T.SAY:
		say.append("`%s` → %s" % [r[0], r[1]])
	_list("SAY", say)

	_h2("7. Tutorial (not in the table build)")
	_dict("TUTORIAL", T.TUTORIAL)

	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("\n".join(out) + "\n")
	f.close()
	print("STRINGS %d lines -> %s" % [out.size(), path])
	quit()


func _h1(t: String) -> void:
	out.append("# " + t)
	out.append("")


func _h2(t: String) -> void:
	out.append("## " + t)
	out.append("")


func _h3(t: String) -> void:
	out.append("### " + t)


func _p(t: String) -> void:
	out.append(t)
	out.append("")


func _list(head: String, items: Array) -> void:
	out.append("**%s**" % head)
	for i in items:
		out.append("- " + str(i).replace("\n", " / "))
	out.append("")


func _dict(head: String, d: Dictionary) -> void:
	var items := []
	for k in d:
		items.append("%s: %s" % [k, str(d[k])])
	_list(head, items)


## Every string inside a value (nested arrays and dictionaries), in order.
func _strings(v) -> Array:
	var r := []
	if v is String:
		r.append(v)
	elif v is Array:
		for x in v:
			r.append_array(_strings(x))
	elif v is Dictionary:
		for k in v:
			r.append_array(_strings(v[k]))
	return r


## Lines in these files (or folders) calling one of these, with a quoted string: file:line and the string(s).
func _scan(paths: Array, calls: Array) -> void:
	var re := RegEx.new()
	re.compile("\"((?:[^\"\\\\]|\\\\.)*)\"")
	for p in paths:
		for file in _files(p):
			var lines := FileAccess.get_file_as_string(file).split("\n")
			for i in lines.size():
				var l: String = lines[i]
				var hit := calls.is_empty()
				for c in calls:
					if l.find(c) >= 0:
						hit = true
				if not hit or l.strip_edges().begins_with("#") or l.find("load(") >= 0 or l.find("print(") >= 0 or l.find("push_") >= 0:
					continue
				var words := []
				for m in re.search_all(l):
					var s: String = m.get_string(1)
					if s.length() > 1 and s.find(" ") >= 0 or (s.length() > 1 and s[0] == s[0].to_upper() and s[0] != s[0].to_lower()):
						words.append(s)
				words = words.filter(func(w): return w.to_lower() != w.to_upper())  # letters, not punctuation
				if not words.is_empty():
					out.append("- `%s:%d` %s" % [file.trim_prefix("res://"), i + 1, " · ".join(words)])
	out.append("")


func _files(p: String) -> Array:
	if p.ends_with(".gd"):
		return [p]
	var r := []
	for f in DirAccess.get_files_at(p):
		if f.ends_with(".gd"):
			r.append(p.path_join(f))
	return r
