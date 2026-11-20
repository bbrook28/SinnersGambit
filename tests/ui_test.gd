## Drives the hand screen through the guided tutorial and into a real hand, as taps would.
## godot --headless --path . --script res://tests/ui_test.gd
extends SceneTree

const HandScreen = preload("res://ui/hand_screen.gd")
const Rules = preload("res://hand/rules.gd")

var _fails := 0
var h


func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		_fails += 1


func _initialize() -> void:
	DirAccess.remove_absolute("user://ui_test.cfg")
	h = HandScreen.new()
	h.save_path = "user://ui_test.cfg"
	root.add_child(h)
	await process_frame
	test_tutorial()
	test_free_hands()
	DirAccess.remove_absolute("user://ui_test.cfg")
	print("ui_test: %d failure(s)" % _fails)
	quit(1 if _fails > 0 else 0)


func _slot_of(kind: String) -> int:
	for j in h.s.slots.size():
		if h.s.slots[j].kind == kind:
			return j
	return -1


func test_tutorial() -> void:
	check("ui: a first launch opens the tutorial on its first card", h.tut != null and h.cards.size() == 1 and h.overlay.visible)
	check("ui: Throw waits while a card is up", h.throw_btn.disabled)
	h._on_card_btn()
	check("ui: Throw is open, Cash out is not", not h.throw_btn.disabled and h.cash_btn.disabled)
	h._on_throw()
	check("ui: the scripted throw is 5, 3", h.faces == [5, 3] and h.phase == "place")
	h._on_die(1)
	check("ui: the tutorial won't let the 3 be picked", h.picked == -2)
	h._on_die(0)
	h._on_slot(1)
	check("ui: the 5 can't go to the Offering here", h.s.progress == 0 and h.phase == "place")
	h._on_slot(0)
	check("ui: the 5 is in the Target; the 3 went back", h.s.progress == 5 and h.s.bag == 7 and h.phase == "throw")
	check("ui: the bag card is up", h.cards.size() == 1 and h.card_title.text == "Back into the bag")
	h._on_card_btn()
	h._on_throw()
	check("ui: a skull lands, the skull card is up", h.s.skulls == 1 and h.card_title.text == "A skull" and h.thrown_skulls == 1)
	h._on_card_btn()
	h._on_slot(_slot_of("ward"))  # only one die can go: picked for you
	check("ui: the 4 is in the Ward; the Master deals Hunger", h.s.slots[_slot_of("ward")].dice == [4] and h.s.wires.size() == 2 and h.card_title.text == "The Master answers")
	h._on_card_btn()
	h._on_throw()
	h._on_die(0)
	h._on_slot(0)
	check("ui: 11 pips, Tier 1, the Pair is face up", h.s.progress == 11 and Rules.tier(h.s) == 1 and h.s.revealed and h.card_title.text.begins_with("Tier 1"))
	h._on_card_btn()
	check("ui: the tutorial makes you throw on", h.cash_btn.disabled and not h.throw_btn.disabled)
	h._on_throw()
	check("ui: the Ward cancels the skull", h.s.cancelled == 1 and h.s.skulls == 1 and h.card_title.text == "The Ward holds")
	h._on_card_btn()
	h._on_die(0)
	h._on_slot(_slot_of("pair"))
	check("ui: the 5 is in the Pair; the last card is up", h.s.slots[_slot_of("pair")].dice == [5] and h.card_title.text == "The dice are yours")
	h._on_card_btn()
	check("ui: the dice are yours: Throw and Cash out both open", h.tut.done() and not h.throw_btn.disabled and not h.cash_btn.disabled and h.s.bag == 3)
	h._on_cash()
	check("ui: cashing out ends the guided hand with its marks", h.phase == "over" and h.total == 2 and h.tutorial_done and h.card_btn.text == "Next hand")
	h._on_card_btn()
	check("ui: the next hand is a real deal", h.tut == null and h.phase == "throw" and h.s.bag == 8 and h.hand_no == 2)


## Plays real hands to their end by always taking the first legal move and throwing on: no dead ends, no crash.
func test_free_hands() -> void:
	var ended := 0
	for k in 30:
		var guard := 0
		while h.phase != "over" and guard < 200:
			guard += 1
			while not h.cards.is_empty() and h.phase != "over":
				h._on_card_btn()
			if h.phase == "throw":
				h._on_throw()
			elif h.phase == "place":
				var mv: Array = h._moves()
				if mv.is_empty():
					h._on_cash()
				else:
					h._on_die(mv[0].die)
					h._on_slot(mv[0].slot)
		if h.phase == "over":
			ended += 1
			while not h.cards.is_empty():
				h._on_card_btn()  # the result card: Next hand
	check("ui: 30 played hands each reach an end", ended == 30)
	check("ui: hands are counted", h.hand_no == 32)
