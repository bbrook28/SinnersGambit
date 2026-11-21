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
	check("ui: the seals show the risk", h.seals[2].cap.text.contains("% to lose it") and h.seals[0].cap.text.contains("no risk"))
	h._on_seal(3)
	await settle()
	h._on_die(0)
	check("ui: the third 4 previews three of a kind", h.ribbon_label.text == "Three of a kind · 3")
	h._on_keep()
	await settle()
	check("ui: the last card hands over the dice", h.overlay.visible and h.card_title.text == "The dice are yours")
	h._on_card_btn()
	check("ui: free play: 3 in the bag, 1 skull", h.tut.done() and h.s.bag == 3 and h.s.skulls == 1 and not h.overlay.visible)


## Waits for the result card, which follows a pause after the hand ends.
func await_card() -> void:
	for i in 600:
		if h.overlay.visible:
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
	await await_card()


func test_free_hands() -> void:
	await play_out()
	check("ui: the tutorial hand ends with a result card", h.s.over and h.overlay.visible and h.card_btn.text == "Next hand")
	h._on_card_btn()
	check("ui: the tutorial is done and saved", h.tut == null and h.seen.get("tutorial", false) and h.hands == 1)
	var ok := true
	for i in 12:
		await play_out()
		ok = ok and h.s.over and h.overlay.visible
		h._on_card_btn()
	check("ui: 12 free hands play out", ok and h.hands == 13)
	var c := ConfigFile.new()
	check("ui: marks are saved", c.load("user://ui_test.cfg") == OK and int(c.get_value("dice", "total", -1)) == h.total)


func test_help() -> void:
	h._on_help()
	check("ui: ? lists the hands with their pay", h.overlay.visible and h.card_text.text.contains("Five of a kind   12") and h.card_text.text.contains("Straight (2 3 4 5 6)   5"))
	h._on_card_btn()
	check("ui: the help card closes", not h.overlay.visible)


func test_labels() -> void:
	h._new_hand()
	check("ui: three dice with no skulls: under 1%, not no risk", h.seals[2].cap.text.contains("under 1% to lose it"))
	h.s.bag = 2
	h._refresh()
	check("ui: a two-die bag: the 3 seal says so, the prompt offers 1 or 2", h.seals[2].cap.text.contains("only 2 in the bag")
		and h.msg.text.begins_with("Draw 1 or 2 dice"))
	h.s.row = [3, 5, 5, 2]
	check("ui: the row shows matches first", h.shown_row() == [5, 5, 3, 2])
	h.s.row = [6, 5, 4, 3]
	h._refresh()
	check("ui: a straight draw is named", h.hint.text == "One more 2: Straight · 5")
	h.s.busted = false
	h.s.row = [6, 6, 6, 6, 2]
	check("ui: four of a kind gets the grand card", h._big(h.s) == 2)
	h.s.row = [6, 6, 2, 3, 4]
	check("ui: a pair gets the plain card", h._big(h.s) == 0)
