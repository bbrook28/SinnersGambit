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
	await test_tutorial()
	await test_free_hands()
	await test_help()
	await test_labels()
	await test_demand()
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


func test_tutorial() -> void:
	check("ui: a first launch opens the tutorial's first card", h.tut != null and h.overlay.visible and h.card_title.text == "The Master's dice")
	h._on_card_btn()
	check("ui: only the 2 seal works on the first throw", h.seals[0].btn.disabled and not h.seals[1].btn.disabled and h.seals[2].btn.disabled)
	h._on_seal(1)
	check("ui: the 1 seal is ignored", h.s.throws == 0)
	h._on_seal(2)
	await settle()
	check("ui: two dice wait for a keep", h.phase == "keep" and h.s.thrown == [4, 6])
	check("ui: the keep seal shows, the draw seals hide", h.keep_box.visible and not h.seal_box.visible)
	h.tap_tray((h.tray_x(0) + h.tray_x(1)) / 2.0)
	check("ui: a tap between two dice picks neither", h.selected == -1)
	h.tap_tray(h.tray_x(1) - 60.0)
	check("ui: a tap on the inner half of the 6 is the 6, refused by the tutorial", h.selected == -1)
	h.tap_tray(h.tray_x(0) + 60.0)
	check("ui: picking the 4 previews it", h.selected == 0 and h.ribbon_label.text == "High die · 0" and h.keep_cap.text == "Keep the 4")
	h._on_keep()
	await settle()
	check("ui: the 4 is in the row", h.s.row == [4] and h.phase == "throw")
	check("ui: the row says what one more die would make", h.hint.text == "One more 4: Pair · 1")
	h._on_seal(2)
	await settle()
	check("ui: a skull snuffs a candle; the lone 4 is kept: a pair", h.s.skulls == 1 and h.candles[0].texture == h.CANDLE_OUT
		and h.s.row == [4, 4] and h.ribbon_label.text == "Pair · 1")
	check("ui: the skull card", h.overlay.visible and h.card_title.text == "A skull")
	h._on_card_btn()
	check("ui: the risk card", h.overlay.visible and h.card_title.text == "More dice, more risk")
	h._on_card_btn()
	check("ui: the seals show the risk", h.seals[2].odds.text.contains("% to lose it") and h.seals[0].odds.text == "no risk" and h.seals[0].cap.text == "1 die")
	h._on_seal(3)
	await settle()
	h._on_die(0)
	check("ui: the third 4 previews three of a kind", h.ribbon_label.text == "Three of a kind · 3")
	h._on_keep()
	await settle()
	check("ui: the last card hands over the dice", h.overlay.visible and h.card_title.text == "The dice are yours")
	h._on_card_btn()
	check("ui: free play: 3 in the bag, 1 skull", h.tut.done() and h.s.bag == 3 and h.s.skulls == 1 and not h.overlay.visible)
	check("ui: the guided hand has no demand", h.cfg.demand == "" and h.demand_label.text == "" and not h.sin_label.visible and h.sin_name() == "Pride")


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
	check("ui: the tutorial hand ends with the result banner and Next hand", h.s.over and h.banner.visible and h.next_box.visible
		and not h.seal_box.visible and h.banner_title.text != "" and not h.banner_title.text.contains(h.ribbon_label.text.get_slice(" · ", 0)))
	check("ui: the counter shows the new total", h.marks_label.text == str(h.total))
	h._on_next()
	check("ui: the tutorial is done and saved", h.tut == null and h.seen.get("tutorial", false) and h.hands == 1)
	check("ui: the first hand with a demand explains it once", h.overlay.visible and h.card_title.text == "The Sin's demand"
		and h.seen.get("demand: A lone 6 pays 4. Each 2 costs 1.", false) and not h.opener.visible)
	h._on_card_btn()
	check("ui: then Pride opens the hand with its demand, and time to read it", h.opener.visible and h.opener_name.text == "Pride"
		and h.opener_line.text == "A lone 6 pays 4. Each 2 costs 1." and h.demand_label.text == "A lone 6 pays 4. Each 2 costs 1." and h.open_hold == h.OPEN_READ)
	var cw: float = h.demand_width()
	check("ui: the demand line ends left of the candles (%d px of %d)" % [cw, h.candles[0].get_meta("x") - 60], cw > 100.0
		and h.demand_label.position.x + cw < h.candles[0].get_meta("x") - 60)
	var ok := true
	for i in 12:
		await play_out()
		ok = ok and h.s.over and h.banner.visible and h.next_box.visible and h.marks_label.text == str(h.total)
		h._on_next()
	check("ui: 12 free hands play out", ok and h.hands == 13)
	var c := ConfigFile.new()
	check("ui: marks are saved", c.load("user://ui_test.cfg") == OK and int(c.get_value("dice", "total", -1)) == h.total)


func test_help() -> void:
	h._on_help()
	var grid: GridContainer = h.card_body.get_child(0)
	var cells := grid.get_children()
	check("ui: ? lists the hands in columns: name, dice, pay", h.overlay.visible and grid.columns == 3 and cells.size() == 21
		and cells[0].text == "Five of a kind" and cells[1].get_child_count() == 5 and cells[2].text == "12"
		and cells[9].text == "Straight" and cells[11].text == "5")
	h._on_card_btn()
	check("ui: the help card closes", not h.overlay.visible)


func test_labels() -> void:
	h._new_hand()
	check("ui: three dice with no skulls: under 1%, not no risk", h.seals[2].odds.text.contains("under 1% to lose it"))
	h.s.bag = 2
	h._refresh()
	check("ui: a two-die bag: the 3 seal says so, the prompt offers 1 or 2", h.seals[2].odds.text.contains("only 2 in the bag")
		and h.msg.text.begins_with("Draw 1 or 2 dice"))
	h.s.row = [3, 5, 5, 2]
	check("ui: the row shows matches first", h.shown_row() == [5, 5, 3, 2])
	h.s.row = [6, 5, 4, 3]
	h._refresh()
	check("ui: a straight draw is named", h.hint.text == "Needs 2: Straight · 5")
	h.s.row = [2, 3, 4]
	h._refresh()
	check("ui: three different dice: the hint names the straight, not a pair", h.hint.text == "Needs 5 and 6: Straight · 5")
	h.s.row = [2, 3, 3]
	h._refresh()
	check("ui: a pair in the row: no straight to name", h.hint.text == "One more 3: Three of a kind · 3")
	h.s.row = [2, 3]
	h._refresh()
	check("ui: two dice: the pair is still the hint", h.hint.text == "One more 2: Pair · 1")
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
	# a 6 is kept alone, then a 6 and a 2 are thrown
	hosted([6, 6, 2])
	h._on_seal(1)
	await settle()
	check("ui: a lone 6 in the row: the hand and what Pride pays", h.s.row == [6] and h.ribbon_label.text == "High die · 0"
		and h.sin_label.visible and h.sin_label.text == "Pride · 4" and h.sin_plus.text == "+")
	h._on_seal(2)
	await settle()
	check("ui: a second 6 would take the 4 back; a 2 costs 1 (%s, %s)" % [tag_of(0), tag_of(1)], h.phase == "keep"
		and tag_of(0) == "−4" and tag_of(1) == "−1" and h.tray_dice[0].get_child(0).get_theme_color("font_color") == h.COST
		and h.tray_dice[0].get_child(0).position.y < 0.0)
	h._on_die(0)
	check("ui: picking the second 6: a pair, and Pride pays nothing", h.ribbon_label.text == "Pair · 1" and h.sin_label.text == "Pride · 0" and h.ribbon_if.visible)
	h._on_die(1)
	check("ui: picking the 2: Pride pays 3", h.ribbon_label.text == "High die · 0" and h.sin_label.text == "Pride · 3")
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
	check("ui: ? names the host and its demand", h.card_text.text.begins_with("Pride hosts this hand.\nA lone 6 pays 4. Each 2 costs 1."))
	h._on_card_btn()
