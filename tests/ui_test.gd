## Drives the dice screen through the guided first hand and into free hands, as taps would.
## godot --headless --path . --script res://tests/ui_test.gd
extends SceneTree

const DiceScreen = preload("res://ui/dice_screen.gd")

var _fails := 0
var h


func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		_fails += 1


func _initialize() -> void:
	Engine.time_scale = 20.0
	DirAccess.remove_absolute("user://ui_test.cfg")
	h = DiceScreen.new()
	h.save_path = "user://ui_test.cfg"
	h.size = Vector2(1080, 1920)
	root.add_child(h)
	await process_frame
	await process_frame
	test_lesson_data()
	await test_lessons()
	await test_free_hands()
	await test_help()
	await test_labels()
	await test_demand()
	await test_words()
	await test_lesson_edges()
	DirAccess.remove_absolute("user://ui_test.cfg")
	print("ui_test: %d failure(s)" % _fails)
	quit(1 if _fails > 0 else 0)


## Waits out the throw and keep animations.
func settle() -> void:
	for i in 600:
		await process_frame
		if h.phase != "anim":
			break
	await process_frame


## The three lessons, played through the rules alone: each ends as the design says, and reads plainly.
func test_lesson_data() -> void:
	var T = h.Tutorial
	check("data: three lessons", T.LESSONS.size() == 3)
	var words_ok := true
	var cards_ok := true
	var bad: Array = []
	var ends: Array = []
	for li in T.LESSONS.size():
		var t = T.new()
		t.lesson = li
		var cfg: Dictionary = h.Config.merged({"demand": t.demand()})
		var st = h.Rules.new_hand(cfg, t.rng())
		var steps: Array = t.steps()
		var danced := false
		for k in steps.size():
			var x: Dictionary = steps[k]
			bad += banned_in(str(x.get("text", "")) + " " + str(x.get("msg", "")) + " " + str(x.get("title", "")))
			if x.type == "card":
				words_ok = words_ok and str(x.text).replace("\n", " ").split(" ", false).size() <= 45
				cards_ok = cards_ok and (k == 0 or steps[k - 1].type != "card")
			elif x.type == "throw":
				danced = h.Rules.is_dance(st)
				h.Rules.throw(st, x.n)
			elif x.type == "keep":
				h.Rules.keep(st, st.thrown.find(x.face))
		ends.append({"row": st.row.duplicate(), "skulls": st.skulls, "over": st.over, "marks": st.marks, "danced": danced,
			"name": h.Rules.score(cfg, st.row).name, "sin": h.Rules.sin_marks(cfg, st.row, st.bank)})
	check("data: no card is over 45 words", words_ok)
	check("data: never two cards in a row", cards_ok)
	check("data: the lessons use no jargon %s" % str(bad), bad.is_empty())
	check("data: lesson 1 ends on three 4s and two 6s, paid 5 (%s)" % str(ends[0]), ends[0].row == [4, 4, 4, 6, 6] and ends[0].skulls == 0
		and ends[0].over and ends[0].marks == 5 and ends[0].name == "Three and a pair")
	check("data: lesson 2 ends on the Last Dance: four 5s, paid 7, two skulls (%s)" % str(ends[1]), ends[1].row == [5, 5, 5, 3, 0]
		and ends[1].skulls == 2 and ends[1].over and ends[1].marks == 7 and ends[1].danced and ends[1].name == "Four of a kind")
	check("data: lesson 3 hands over a 6 and a 4, Pride paying 4 (%s)" % str(ends[2]), ends[2].row == [6, 4] and not ends[2].over and ends[2].sin == 4)


## Taps the thrown die showing that face, then Keep.
func keep_face(face: int) -> void:
	h._on_die(h.s.thrown.find(face))
	h._on_keep()
	await settle()


func test_lessons() -> void:
	# lesson 1: the row
	check("ui: a first launch opens lesson 1, with a way to skip", h.tut != null and h.tut.lesson == 0 and h.overlay.visible
		and h.card_title.text == "The Master's dice" and h.card_alt.visible and h.card_alt.text == "Skip the lessons")
	h._on_card_btn()
	check("ui: only the 2 button works on the first roll", h.seals[0].btn.disabled and not h.seals[1].btn.disabled and h.seals[2].btn.disabled
		and h.msg.text.begins_with("Tap the 2 button"))
	h._on_seal(1)
	check("ui: the 1 button is ignored", h.s.throws == 0)
	h._on_seal(2)
	await settle()
	check("ui: two dice wait for a keep", h.phase == "keep" and h.s.thrown == [4, 6] and h.keep_box.visible and not h.seal_box.visible)
	h.tap_tray((h.tray_x(0) + h.tray_x(1)) / 2.0)
	check("ui: a tap between two dice picks neither", h.selected == -1)
	h.tap_tray(h.tray_x(1) - 60.0)
	check("ui: a tap on the 6 is refused by the lesson", h.selected == -1 and h.tut.step().type == "keep")
	h.tap_tray(h.tray_x(0) + 60.0)
	check("ui: picking the 4 previews it", h.selected == 0 and h.ribbon_label.text == "No match · 0" and h.keep_cap.text == "Keep the 4")
	h._on_keep()
	await settle()
	check("ui: the 4 is in the row, 6 in the bag", h.s.row == [4] and h.phase == "throw" and h.s.bag == 6 and h.bag_label.text == "6"
		and h.hint.text == "One more 4: Pair · 1" and h.msg.text == "Roll two again.")
	h._on_seal(2)
	await settle()
	await keep_face(4)
	check("ui: a pair, and its card", h.s.row == [4, 4] and h.ribbon_label.text == "Pair · 1" and h.overlay.visible and h.card_title.text == "A Pair"
		and not h.card_alt.visible)
	h._on_card_btn()
	h._on_seal(3)
	await settle()
	h._on_die(0)
	check("ui: the third 4 previews three of a kind", h.ribbon_label.text == "Three of a kind · 3" and h.ribbon_if.visible)
	h._on_keep()
	await settle()
	check("ui: the hint under the row is pointed at", h.hint.text == "One more 4: Four of a kind · 7" and h.msg.text.begins_with("Under your row") and h.s.bag == 4)
	h._on_seal(2)
	await settle()
	await keep_face(6)
	h._on_seal(2)
	await settle()
	await keep_face(6)
	await await_result()
	check("ui: lesson 1 is paid 5 and ends on the hands", h.s.row == [4, 4, 4, 6, 6] and h.s.marks == 5 and h.s.skulls == 0
		and h.ribbon_label.text == "Three and a pair · 5" and h.overlay.visible and h.card_title.text == "Paid"
		and h.card_body.visible and h.card_body.get_child(0) is GridContainer)
	h._on_card_btn()
	check("ui: Next hand waits under the result", h.next_box.visible and h.banner.visible and not h.overlay.visible)
	h._on_next()
	# lesson 2: skulls
	check("ui: lesson 2 opens on skulls, with no Sin", h.tut != null and h.tut.lesson == 1 and h.card_title.text == "Skulls" and h.card_alt.visible
		and h.cfg.demand == "" and h.demand_label.text == "" and not h.seen.get("tutorial", false))
	var again = DiceScreen.new()   # the app closed in the middle of the lessons
	again.save_path = "user://ui_test.cfg"
	again.size = Vector2(1080, 1920)
	root.add_child(again)
	await process_frame
	check("ui: a relaunch in the middle starts lesson 1 again", again.tut != null and again.tut.lesson == 0 and again.card_title.text == "The Master's dice")
	again.queue_free()
	await process_frame
	h._on_card_btn()
	h._on_seal(2)
	await settle()
	check("ui: a skull puts out a candle; the only die left is kept", h.s.skulls == 1 and h.candles[0].texture == h.CANDLE_OUT and h.s.row == [5]
		and h.overlay.visible and h.card_title.text == "More dice, more risk")
	h._on_card_btn()
	check("ui: each button shows its risk", h.seals[2].odds.text.contains("% to lose it") and h.seals[0].cap.text == "1 die")
	h._on_seal(3)
	await settle()
	check("ui: a second skull", h.s.skulls == 2 and h.s.thrown == [5, 3] and h.candles[1].texture == h.CANDLE_OUT)
	await keep_face(5)
	check("ui: the lesson asks for one die", h.msg.text.begins_with("One more skull loses the hand") and not h.seals[0].btn.disabled and h.seals[1].btn.disabled)
	var throws: int = h.s.throws
	h._on_seal(2)
	check("ui: a button the lesson did not ask for does nothing", h.s.throws == throws and h.tut.step().n == 1)
	h._on_seal(1)
	await settle()
	h._on_seal(1)
	await settle()
	check("ui: one die left, and the Last Dance card", h.s.row == [5, 5, 5, 3] and h.s.bag == 1 and h.overlay.visible and h.card_title.text == "The Last Dance")
	h._on_card_btn()
	h._on_seal(1)
	await settle()
	await await_result()
	check("ui: lesson 2 ends on four 5s, the last die shown as ANY", h.s.row == [5, 5, 5, 3, 0] and h.s.marks == 7 and h.ribbon_label.text == "Four of a kind · 7"
		and h.row_dice[4].get_child(0).visible and h.row_dice[4].get_child(0).text == "ANY" and not h.overlay.visible)
	h._on_next()
	# lesson 3: the Sin
	check("ui: lesson 3 opens on the Sin, Pride watching", h.tut != null and h.tut.lesson == 2 and h.card_title.text == "The Sin" and h.card_alt.visible
		and h.cfg.demand == "pride" and h.demand_label.text == "Exactly one 6 pays 4. Each 2 costs 1.")
	h._on_card_btn()
	check("ui: then Pride opens the hand, with time to read its rule", h.opener.visible and h.opener_name.text == "Pride"
		and h.opener_line.text == "Exactly one 6 pays 4. Each 2 costs 1." and h.open_hold == h.OPEN_READ and not h.overlay.visible)
	h._on_seal(2)
	await settle()
	check("ui: the first 6 wears +4", tag_of(0) == "+4" and tag_of(1) == "" and h.msg.text.begins_with("The number above a die"))
	await keep_face(6)
	h._on_seal(2)
	await settle()
	check("ui: the second 6 wears −4", tag_of(0) == "−4" and tag_of(1) == "")
	check("ui: lesson 3's hint does not contradict the lesson (%s)" % h.hint.text, not h.hint.text.begins_with("One more 6"))
	h._on_die(0)
	check("ui: the second 6 is refused by the lesson", h.selected == -1)
	await keep_face(4)
	check("ui: the last card hands over the dice", h.overlay.visible and h.card_title.text == "The dice are yours")
	h._on_card_btn()
	check("ui: free play under Pride: a 6 and a 4, Pride paying 4", h.tut.done() and h.s.row == [6, 4] and h.sin_label.visible
		and h.sin_label.text == "Pride · 4" and not h.overlay.visible and h.msg.text.begins_with("Roll "))


## Waits for the result banner and Next hand, which follow the payout after the hand ends.
func await_result() -> void:
	for i in 900:
		if h.next_box.visible:
			break
		await process_frame


func play_out() -> void:
	var guard := 0
	while not h.s.over and guard < 40:
		guard += 1
		if h.overlay.visible:
			h._on_card_btn()
			continue
		if h.phase == "keep":
			h._on_die(0)
			h._on_keep()
		else:
			h._on_seal(2 if h.s.bag >= 2 else 1)
		await settle()
	await await_result()


func test_free_hands() -> void:
	await play_out()
	check("ui: the last lesson's hand ends with the result banner and Next hand", h.s.over and h.banner.visible and h.next_box.visible
		and not h.seal_box.visible and h.banner_title.text != "" and not h.banner_title.text.contains(h.ribbon_label.text.get_slice(" · ", 0)))
	check("ui: the counter shows the new total", h.marks_label.text == str(h.total))
	h._on_next()
	check("ui: the lessons are done and saved, with all they taught", h.tut == null and h.seen.get("tutorial", false) and h.hands == 3
		and h.seen.get("skull", false) and h.seen.get("dance", false) and h.seen.get("demand: Exactly one 6 pays 4. Each 2 costs 1.", false))
	check("ui: the next hand has no card: Pride opens it briefly", not h.overlay.visible and h.opener.visible and h.open_hold == h.OPEN_TIME
		and h.demand_label.text == "Exactly one 6 pays 4. Each 2 costs 1.")
	var cw: float = h.demand_width()
	check("ui: the demand line ends left of the candles (%d px of %d)" % [cw, h.candles[0].get_meta("x") - 60], cw > 100.0
		and h.demand_label.position.x + cw < h.candles[0].get_meta("x") - 60)
	var ok := true
	for i in 12:
		await play_out()
		ok = ok and h.s.over and h.banner.visible and h.next_box.visible and h.marks_label.text == str(h.total)
		h._on_next()
	check("ui: 12 free hands play out", ok and h.hands == 15)
	var c := ConfigFile.new()
	check("ui: marks are saved", c.load("user://ui_test.cfg") == OK and int(c.get_value("dice", "total", -1)) == h.total)


func test_help() -> void:
	# the page waits for the dice: Replay the tutorial during a roll threw a script error
	h._on_seal(2 if h.s.bag >= 2 else 1)
	check("help: a roll is under way", h.phase == "anim")
	h._on_help()
	check("help: does not open while dice are moving", not h.overlay.visible)
	await settle()
	if h.phase == "keep":
		h._on_die(0)
		h._on_keep()
		h._on_help()
		check("help: nor while a kept die flies to the row", h.phase != "anim" or not h.overlay.visible)
		await settle()
	h._on_help()
	var grid: GridContainer = h.card_body.get_child(0)
	var cells := grid.get_children()
	check("ui: ? lists the hands in columns: name, dice, pay", h.overlay.visible and grid.columns == 3 and cells.size() == 21
		and cells[0].get_child(0).text == "Five of a kind" and cells[1].get_child_count() == 5 and cells[2].text == "12"
		and cells[9].get_child(0).text == "Run" and cells[11].text == "5")
	check("ui: each hand says what makes it", cells[9].get_child(1).text == "2, 3, 4, 5, 6" and cells[18].get_child(1).text == "two dice the same")
	var t: String = h.card_text.text
	check("ui: ? holds all the rules in the lessons' words", t.contains("counts as any number") and t.contains("puts out a candle")
		and t.contains("A full row always makes at least a Pair") and t.contains("The number above a die") and t.contains(h.Version.VERSION)
		and banned_in(t).is_empty())
	await process_frame
	await process_frame
	check("ui: both buttons of the ? page stay on the screen (%d of 1920)" % h.card_alt.get_global_rect().end.y, h.card_alt.visible
		and h.card_alt.get_global_rect().end.y <= 1920.0 and h.card_title.get_global_rect().position.y >= 0.0)
	h._on_card_btn()
	check("ui: the help card closes", not h.overlay.visible)


func test_labels() -> void:
	h._new_hand()
	check("ui: three dice with no skulls: under 1%, not no risk", h.seals[2].odds.text.contains("under 1% to lose it"))
	h.s.bag = 2
	h._refresh()
	check("ui: a two-die bag: the 3 seal says so, the prompt offers 1 or 2", h.seals[2].odds.text.contains("only 2 in the bag")
		and h.msg.text.begins_with("Roll 1 or 2 dice"))
	h.s.row = [3, 5, 5, 2]
	check("ui: the row shows matches first", h.shown_row() == [5, 5, 3, 2])
	h.s.row = [6, 5, 4, 3]
	h._refresh()
	check("ui: a straight draw is named, with what its 2 costs", h.hint.text == "Needs 2: Run · 5, Pride −1")
	h.s.row = [2, 3, 4]
	h._refresh()
	check("ui: three different dice: the hint names the straight, not a pair", h.hint.text == "Needs 5 and 6: Run · 5, Pride +4")
	h.s.row = [2, 3, 3]
	h._refresh()
	check("ui: a pair in the row: no straight to name; Pride's 6 beats a third 3", h.hint.text == "One more 6: Pride +4")
	h.s.row = [2, 3]
	h._refresh()
	check("ui: two dice: Pride's 6 beats a pair", h.hint.text == "One more 6: Pride +4")
	h.s.busted = false
	h.s.row = [6, 6, 6, 6, 2]
	check("ui: four of a kind gets the grand card", h._big(h.s) == 2)
	h.s.row = [6, 6, 2, 3, 4]
	check("ui: a pair gets the plain card", h._big(h.s) == 0)
	check("ui: risk is ivory near zero, then reddens as it grows", h.risk_color(0.005) == h.IVORY
		and h.risk_color(0.4).g < h.risk_color(0.05).g and h.risk_color(0.4).r > 0.9)
	var faces_ok := true
	for f in [h.serif, h.blackletter, h.caps, h.caps_bold]:
		faces_ok = faces_ok and not f.base_font.has_char(0x31) and f.base_font.has_char(0x61) and f.fallbacks[0].has_char(0x31)
	check("ui: every face takes its digits from EB Garamond (a 1 with a flag and a foot)", faces_ok)
	# the preview is ink with a small "if kept"; the hint counts the picked die
	h._new_hand()
	h.s.row = [4, 4]
	h.s.thrown = [4, 2]
	h.s.last_faces = [4, 2]
	h.phase = "keep"
	h.selected = 0
	h._refresh()
	check("ui: the preview reads in ink with 'if kept' over it", h.ribbon_label.get_theme_color("font_color") == h.INK
		and h.ribbon_if.visible and h.ribbon_label.text == "Three of a kind · 3")
	check("ui: the hint counts the picked die", h.hint.text == "One more 4: Four of a kind · 7")
	h.selected = -1
	h._refresh()
	check("ui: no 'if kept' without a pick", not h.ribbon_if.visible)
	h.s.busted = true
	h.phase = "over"
	h._refresh()
	check("ui: a bust's ribbon says nothing was paid", h.ribbon_label.text == "Nothing paid")
	h.s.busted = false
	h.s.bag = 7
	h.phase = "throw"
	h._refresh()
	check("ui: the bag count and its words, one space apart", h.bag_label.text == "7" and h.bag_words.text == "in the bag"
		and h.bag_words.position.x > h.bag_label.position.x)
	# Pride hosts every hand; its window opens the hand; a tap or a seal ends the opening
	h.phase = "throw"
	for k in range(1, 4):
		h.hands = k
		h._new_hand()
		check("ui: Pride opens hand %d at full screen, briefly, with no second card" % k, h.opener.visible and not h.overlay.visible
			and h.sin_name() == "Pride" and h.window.texture.resource_path.ends_with("pride_window.png") and h.cfg.demand == "pride"
			and h.open_hold == h.OPEN_TIME)
	h._on_seal(2)
	check("ui: a seal during the opening ends it and throws", not h.opener.visible and h.window.modulate.a == 1.0 and h.s.throws == 1)
	await settle()
	h._new_hand()
	for i in 400:
		if not h.opener.visible:
			break
		await process_frame
	check("ui: the opening ends by itself", not h.opener.visible)
	h._on_help()
	await process_frame
	var page: Control = h.card_title.get_parent().get_parent()
	check("ui: the help card fits on the screen", page.get_global_rect().end.x <= h.get_viewport_rect().size.x and page.get_global_rect().position.x >= 0.0)
	h._on_card_btn()


## Plays scripted dice in a hand Pride hosts.
func hosted(faces: Array) -> void:
	h.phase = "throw"
	h.hands = 1
	h._new_hand(h.Tutorial.ScriptRng.new(faces))


func tag_of(j: int) -> String:
	return h.tray_dice[j].get_child(0).text if h.tray_dice[j].get_child_count() > 0 else ""


func test_demand() -> void:
	var glyphs := true
	for f in [h.caps_bold, h.blackletter]:
		for ch in [0x2b, 0x2212]:
			glyphs = glyphs and (f.base_font.has_char(ch) or f.fallbacks[0].has_char(ch))
	check("ui: the faces have a plus and a true minus", glyphs)
	# the hint under the row counts what the Sin pays
	hosted([])
	h._end_opening()
	h.s.row = [6]
	h._refresh()
	check("hint: no second 6 under Pride (%s)" % h.hint.text, h.hint.text == "")
	h.s.thrown = [6, 4]
	h.s.last_faces = [6, 4]
	h.phase = "keep"
	h.selected = 1
	h._refresh()
	check("hint: the pair that keeps the 6 alone (%s)" % h.hint.text, h.hint.text == "One more 4: Pair · 1")
	h.s.thrown = []
	h.s.last_faces = []
	h.phase = "throw"
	h.selected = -1
	h.s.row = [3]
	h._refresh()
	check("hint: Pride's 6 beats a pair (%s)" % h.hint.text, h.hint.text == "One more 6: Pride +4")
	h.s.row = [2, 2, 2, 2]
	h._refresh()
	check("hint: hand and Sin together (%s)" % h.hint.text, h.hint.text == "One more 2: Five of a kind · %d, Pride −1" % h.Rules.pay(h.cfg, 7))
	h.cfg.demand = ""
	h.s.row = [6]
	h._refresh()
	check("hint: with no Sin, as before (%s)" % h.hint.text, h.hint.text == "One more 6: Pair · 1")
	h.cfg.demand = "pride"
	# a 6 is kept alone, then a 6 and a 2 are thrown
	hosted([6, 6, 2])
	h._on_seal(1)
	await settle()
	check("ui: a lone 6 in the row: the hand and what Pride pays", h.s.row == [6] and h.ribbon_label.text == "No match · 0"
		and h.sin_label.visible and h.sin_label.text == "Pride · 4" and h.sin_plus.text == "+")
	h._on_seal(2)
	await settle()
	check("ui: a second 6 would take the 4 back; a 2 costs 1 (%s, %s)" % [tag_of(0), tag_of(1)], h.phase == "keep"
		and tag_of(0) == "−4" and tag_of(1) == "−1" and h.tray_dice[0].get_child(0).get_theme_color("font_color") == h.COST
		and h.tray_dice[0].get_child(0).position.y < 0.0)
	h._on_die(0)
	check("ui: picking the second 6: a pair, and Pride pays nothing", h.ribbon_label.text == "Pair · 1" and h.sin_label.text == "Pride · 0" and h.ribbon_if.visible)
	h._on_die(1)
	check("ui: picking the 2: Pride pays 3", h.ribbon_label.text == "No match · 0" and h.sin_label.text == "Pride · 3")
	# a first 6 thrown beside a 3 carries +4
	hosted([3, 6, 4])
	h._on_seal(1)
	await settle()
	h._on_seal(2)
	await settle()
	check("ui: a first 6 carries +4 in gold, the 4 nothing", tag_of(0) == "+4" and tag_of(1) == ""
		and h.tray_dice[0].get_child(0).get_theme_color("font_color") == h.GOLD)
	# paid: 6 3 3 4 5
	hosted([6, 3, 3, 4, 5])
	var before: int = h.total
	for i in 5:
		h._on_seal(1)
		await settle()
	await await_result()
	check("ui: the banner counts the hand and the Sin", h.banner_title.text == "5 marks" and h.banner_text.text.begins_with("Pair 1 + Pride 4.")
		and h.total == before + 5 and h.marks_label.text == str(h.total))
	h._on_next()
	# Pride takes it all: 2 2 3 4 5
	hosted([2, 2, 3, 4, 5])
	h._on_seal(1)
	await settle()
	check("ui: a 2 in the row costs: a minus in place of the plus, in red", h.sin_label.text == "Pride · 1" and h.sin_plus.text == "−"
		and h.sin_plus.visible and h.sin_label.get_theme_color("font_color") == h.BLOOD and h.sin_plus.get_theme_color("font_color") == h.BLOOD)
	before = h.total
	for i in 4:
		h._on_seal(1)
		await settle()
	await await_result()
	check("ui: a hand the Sin takes to nothing has its own plate", h.banner_title.text == "Pride takes it all" and h.banner_text.text.begins_with("Pair 1, Pride takes 2.")
		and h.total == before)
	h._on_next()
	# the wild die is shown as the face it was paid as: 3 3 4 5 and the Last Dance, paid as a lone 6
	hosted([3, 3, 4, 1, 1, 5, 4])
	for i in 3:
		h._on_seal(1)
		await settle()
	h._on_seal(2)
	await settle()
	h._on_seal(1)
	await settle()
	check("ui: one die left: the Last Dance", h.s.bag == 1 and h.s.row == [3, 3, 4, 5] and h.s.skulls == 2)
	h._on_seal(1)
	await settle()
	await await_result()
	check("ui: the wild die shows the 6 it was paid as, still marked wild", h.s.row == [3, 3, 4, 5, 0] and h.row_dice[4].texture == h.DICE[6]
		and h.row_dice[4].get_child(0).visible and h.banner_text.text.begins_with("Pair 1 + Pride 4."))
	h._on_help()
	check("ui: ? names the host and its demand", h.card_text.text.begins_with("Pride is watching this hand.\nExactly one 6 pays 4. Each 2 costs 1."))
	h._on_card_btn()


## Words a first-time player would not know; none may be shown.
const BANNED := ["draw", "throw", "wild", "lone", "hosts", "straight", "full house", "high die", "seal", "snuff", "snuffs"]


## The text of every visible Label and Button on the screen.
func shown_text(n: Node = null) -> String:
	if n == null:
		n = h
	var out := ""
	if n is CanvasItem and not n.is_visible_in_tree():
		return out
	if (n is Label or n is Button) and n.text != "":
		out += n.text + "\n"
	for c in n.get_children():
		out += shown_text(c)
	return out


## The banned words found in a text, as whole words.
func banned_in(text: String) -> Array:
	var found: Array = []
	var re := RegEx.new()
	for w in BANNED:
		re.compile("\b%s\b" % w)
		if re.search(text.to_lower()) != null:
			found.append(w)
	return found


func test_words() -> void:
	var bad: Array = []
	hosted([6, 6, 2])
	h._end_opening()
	bad += banned_in(shown_text())
	h._on_seal(1)
	await settle()
	h._on_seal(2)
	await settle()
	bad += banned_in(shown_text())
	h._on_die(0)
	bad += banned_in(shown_text())
	hosted([3, 3, 4, 1, 1, 5, 4])
	h._end_opening()
	for i in 3:
		h._on_seal(1)
		await settle()
	h._on_seal(2)
	await settle()
	h._on_seal(1)
	await settle()
	check("ui: the Last Dance is explained in plain words", h.msg.text.contains("counts as any number"))
	bad += banned_in(shown_text())
	h._on_seal(1)
	await settle()
	await await_result()
	check("ui: the last die is labelled ANY", h.row_dice[4].get_child(0).visible and h.row_dice[4].get_child(0).text == "ANY")
	bad += banned_in(shown_text())
	h._on_help()
	bad += banned_in(shown_text())
	h._on_card_btn()
	h._on_next()
	check("ui: no jargon is shown %s" % str(bad), bad.is_empty())
	check("ui: the Sin's line is 30 px or more", h.demand_label.get_theme_font_size("font_size") >= 30
		and h.demand_label.position.x + h.demand_width() < h.candles[0].get_meta("x") - 60)
	# the widest hand name beside the Sin's marks stays on the ribbon's paper
	hosted([4, 4, 4, 6, 6])
	h._end_opening()
	for i in 5:
		h._on_seal(1)
		await settle()
	var w := 36.0
	for l in [h.ribbon_label, h.sin_plus, h.sin_label]:
		w += l.get_theme_font("font").get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, l.get_theme_font_size("font_size")).x
	check("ui: 'Three and a pair' and the Sin's marks fit the ribbon (%d px of 540)" % w, h.ribbon_label.text == "Three and a pair · 5"
		and h.sin_label.visible and w <= 540.0)
	await await_result()
	h._on_next()


func test_lesson_edges() -> void:
	# Replay the tutorial from the ? page, in the middle of a hand Pride watches
	hosted([6, 6, 2])
	h._end_opening()
	h._on_seal(1)
	await settle()
	h._on_help()
	h._on_card_alt()
	check("ui: Replay starts lesson 1 clean: no Sin's line, an empty row", h.tut != null and h.tut.lesson == 0 and h.card_title.text == "The Master's dice"
		and h.demand_label.text == "" and h.s.row.is_empty() and not h.sin_label.visible)
	# Skip the lessons on lesson 2: free play, and Pride's one-time card still comes
	h.seen.erase("demand: Exactly one 6 pays 4. Each 2 costs 1.")
	h.seen.erase("tutorial")
	h.tut.next_lesson()
	h._start_lesson()
	check("ui: lesson 2 offers the skip", h.card_title.text == "Skulls" and h.card_alt.visible)
	h._on_card_alt()
	check("ui: Skip ends the lessons and Pride's card still comes", h.tut == null and h.seen.get("tutorial", false) and h.cfg.demand == "pride"
		and h.overlay.visible and h.card_title.text == "The Sin" and not h.card_alt.visible)
	h._on_card_btn()
	check("ui: after it the dice are free", not h.overlay.visible and not h.seals[0].btn.disabled and not h.seals[2].btn.disabled)
