## Drives the step 1 pass-and-play screen (ui/table_screen.gd) as taps would: every tap presses a button that is on screen.
## godot --headless --path . --script res://tests/table_test.gd
extends SceneTree

const TableScreen = preload("res://ui/table_screen.gd")
const Rules = preload("res://game/rules.gd")

var _fails := 0
var h


class Faces:
	var queue: Array = []
	func _init(f: Array) -> void:
		queue = f.duplicate()
	func randi_range(_a: int, _b: int) -> int:
		return queue.pop_front()


func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		_fails += 1


## A fresh screen on scripted dice (or random ones, seeded).
func screen(faces = null, seed_value := 1, card := false) -> void:
	if h != null:
		h.queue_free()
	h = TableScreen.new()
	if faces != null:
		h.rng = Faces.new(faces)
	else:
		h.rng = RandomNumberGenerator.new()
		h.rng.seed = seed_value
	h.sins = ["wrath", "greed", "lust", "envy"]
	h.size = Vector2(1080, 1920)
	root.add_child(h)
	await process_frame
	await process_frame
	if not card:
		tap("got_it")   # the How to play card, tested in test_howto


## Is this button on screen and able to be tapped?
func can_tap(key: String) -> bool:
	return h.btn.has(key) and h.btn[key].is_visible_in_tree() and not h.btn[key].disabled


## Taps a button; a tap on one that is missing or switched off fails the test.
func tap(key: String) -> void:
	if not can_tap(key):
		check("tap '%s' (on screen: %s)" % [key, ", ".join(h.btn.keys())], false)
		return
	h.btn[key].pressed.emit()


func shown() -> String:
	return h.title.text + " " + h.text.text


func _initialize() -> void:
	await test_howto()
	await test_first_turn()
	await test_purgatory()
	await test_buy()
	await test_gifts()
	await test_win()
	await test_fits()
	await test_whole_match()
	print("table_test: %d failure(s)" % _fails)
	quit(1 if _fails > 0 else 0)


func test_howto() -> void:
	await screen([4, 5, 1], 1, true)
	check("a match opens on the How to play card, with one button", h.howto.is_visible_in_tree() and can_tap("got_it") and h.btn.size() == 1)
	var all := " ".join(h.HOWTO)
	check("the card is at most six lines", h.HOWTO.size() <= 6)
	var facts := ["3000", "40, 50 or 60", "Purgatory", "two or more", "20", "give points", "lend a die", "buy a die for someone", "not binding", "pass the phone"]
	var missing := []
	for f in facts:
		if not all.contains(f):
			missing.append(f)
	check("the card covers the goal, the roll, Purgatory, buying, the gifts, promises and passing (missing: %s)" % ", ".join(missing), missing.is_empty())
	check("the card does not mention abilities", not all.to_lower().contains("abilit") and not all.contains("Sin"))
	await process_frame
	check("the card fits the screen (button ends at %d of 1920)" % int(h.got_btn.get_global_rect().end.y), h.got_btn.get_global_rect().end.y <= 1920.0)
	tap("got_it")
	check("Got it shows the table: pass the phone to Player 1", not h.howto.visible and can_tap("ready") and can_tap("help"))
	tap("help")
	check("How to play brings the card back", h.howto.visible and can_tap("got_it") and h.btn.size() == 1)
	tap("got_it")
	tap("ready")
	tap("roll")
	tap("help")
	tap("got_it")
	check("the card can be read mid-turn and nothing changes", can_tap("pass") and can_tap("buy") and h.panels[0].points.text == "90")
	tap("points")
	check("How to play is on the table in the gift form too", can_tap("help"))


func test_first_turn() -> void:
	await screen([4, 5, 1,  6, 6, 6])
	check("it opens on: pass the phone to Player 1", h.title.text == "Pass the phone to Player 1" and can_tap("ready") and h.btn.size() == 2)
	var ok := true
	for i in 4:
		var n: Dictionary = h.panels[i]
		ok = ok and n.points.text == "0" and n.dice.text == "3 dice" and n.points.is_visible_in_tree() and n.dice.is_visible_in_tree()
	check("all four players show 0 points and 3 dice", ok)
	check("each player's Sin is shown", h.panels[0].sin.text == "Wrath" and h.panels[3].sin.text == "Envy")
	check("the header shows the goal and the supply", h.header.text.contains("3000") and h.header.text.contains("15 dice"))
	check("Player 1 is marked as the turn", h.panels[0].tag.text == "TURN" and h.panels[1].tag.text == "")
	tap("ready")
	check("then one Roll button, and the rules of the roll", can_tap("roll") and h.btn.size() == 2 and h.btn.roll.text == "Roll 3 dice" and shown().contains("Purgatory") and shown().contains("40, 50 or 60"))
	tap("roll")
	check("the result and what it scored", shown().contains("You rolled 4, 5, 1 and scored 90."))
	check("the panel shows 90 points, the roll and its score", h.panels[0].points.text == "90" and h.panels[0].roll.get_child_count() == 3 and h.panels[0].scored.text == "scored 90")
	check("the Gambit Phase offers Buy, the three gifts and Pass", can_tap("buy") and can_tap("points") and can_tap("lend") and can_tap("die") and can_tap("pass") and h.btn.size() == 6)
	tap("pass")
	check("passing asks for the phone to go to Player 2", h.title.text == "Pass the phone to Player 2" and h.panels[1].tag.text == "TURN" and h.panels[0].tag.text == "")
	tap("ready")
	tap("roll")
	check("Player 1's last roll stays on screen after Player 2 rolls", h.panels[0].roll.get_child_count() == 3 and h.panels[0].scored.text == "scored 90" and h.panels[1].points.text == "180")


func test_purgatory() -> void:
	# P1 into Purgatory; P2-P4 score; P1 one low: stays; P2-P4; P1 two lows: out
	await screen([1, 2, 3,  4, 4, 4,  4, 4, 4,  4, 4, 4,  2, 6, 6,  4, 4, 4,  4, 4, 4,  4, 4, 4,  3, 3, 5])
	tap("ready")
	tap("roll")
	check("all dice 1-3: the screen says Purgatory, 0 scored, turn over", shown().contains("Purgatory") and shown().contains("score 0") and h.panels[0].tag.text.contains("IN PURGATORY"))
	check("in Purgatory the only button is Pass", can_tap("pass") and h.btn.size() == 2)
	tap("pass")
	for i in 3:
		tap("ready")
		tap("roll")
		tap("pass")
	check("Purgatory status stays visible on other players' turns", h.panels[0].tag.text.contains("IN PURGATORY"))
	check("the handover says they are in Purgatory", shown().contains("in Purgatory"))
	tap("ready")
	check("the roll screen explains how to get out", shown().contains("two or more showing 1, 2 or 3"))
	tap("roll")
	check("one low die: stays in, scores nothing, and says why", shown().contains("need two or more") and h.panels[0].points.text == "0" and h.btn.size() == 2 and can_tap("pass"))
	tap("pass")
	for i in 3:
		tap("ready")
		tap("roll")
		tap("pass")
	tap("ready")
	tap("roll")
	check("two low dice: out of Purgatory, the roll scores, the Gambit Phase opens", shown().contains("out of Purgatory") and h.panels[0].points.text == "50" and not h.panels[0].tag.text.contains("PURGATORY") and can_tap("buy"))


func test_buy() -> void:
	await screen([4, 1, 1,  1, 1, 5])
	tap("ready")
	tap("roll")
	tap("buy")
	check("Buy takes 20 points and adds a die", h.panels[0].points.text == "20" and h.panels[0].dice.text == "4 dice" and h.header.text.contains("14 dice"))
	check("the screen says the die rolls from your next turn", shown().contains("next turn"))
	tap("buy")
	check("with 0 points the Buy button is off and says why", h.panels[0].points.text == "0" and not can_tap("buy") and h.btn.buy.text.contains("need 20"))
	h.s.supply = 0
	h.s.seats[0].points = 100
	h._refresh()
	check("with an empty supply the Buy button is off and says why", not can_tap("buy") and h.btn.buy.text.contains("supply is empty"))


func test_gifts() -> void:
	await screen([6, 6, 6,  4, 4, 4, 4])
	tap("ready")
	tap("roll")
	# give points: 180 -> Player 3 gets 60
	tap("points")
	check("the gift form: I give or I ask, the three other players, an amount", can_tap("give") and can_tap("ask") and can_tap("other1") and can_tap("other2") and can_tap("other3") and not h.btn.has("other0") and can_tap("p10"))
	check("no offer until a player is chosen", not can_tap("offer") and shown().contains("Choose a player"))
	tap("other2")
	for i in 5:
		tap("p10")
	check("the form says what will happen", shown().contains("Player 1 gives 60 points to Player 3."))
	tap("offer")
	check("nothing changes until the other player agrees", h.s.seats[0].points == 180 and h.title.text == "Pass the phone to Player 3" and shown().contains("permanent") and can_tap("agree") and can_tap("refuse"))
	tap("agree")
	check("agreed: the points move, and the screen says so", h.panels[0].points.text == "120" and h.panels[2].points.text == "60" and shown().contains("Player 3 agreed") and shown().contains("Pass the phone back to Player 1"))
	# a refused gift changes nothing
	tap("points")
	tap("other1")
	tap("offer")
	tap("refuse")
	check("refused: nothing moves, and the screen says so", h.panels[0].points.text == "120" and h.panels[1].points.text == "0" and shown().contains("Player 2 refused"))
	# you cannot offer more than you have
	tap("points")
	tap("other1")
	tap("p100")
	tap("p100")
	check("the amount stops at what the giver has", h.offer.amount == 120)
	tap("all")
	check("All is everything the giver has", h.offer.amount == 120 and can_tap("offer"))
	# ask: Player 3 has 60
	tap("ask")
	tap("other2")
	tap("all")
	check("asking: the other player is the giver, so the amount stops at their points", h.offer.amount == 60 and shown().contains("Player 3 gives 60 points to Player 1."))
	tap("offer")
	check("the ask is put to Player 3", shown().contains("Player 1 asks") and h.title.text == "Pass the phone to Player 3")
	tap("agree")
	check("agreed: Player 3 gave 60 to Player 1", h.panels[0].points.text == "180" and h.panels[2].points.text == "0")
	# lend a die
	tap("lend")
	check("the lend form states the rule", shown().contains("one roll") and shown().contains("supply") and shown().contains("below 2 dice"))
	tap("other1")
	tap("offer")
	tap("agree")
	check("lent: Player 1 has 2 dice, Player 2 shows 3 dice + 1 lent", h.panels[0].dice.text == "2 dice" and h.panels[1].dice.text == "3 dice + 1 lent")
	tap("lend")
	tap("other1")
	check("on 2 dice you cannot lend, and the form says why", not can_tap("offer") and shown().contains("below 2 dice"))
	tap("back")
	# buy a die for another player
	tap("die")
	check("the form states who pays", shown().contains("pays 20"))
	tap("other3")
	tap("offer")
	tap("agree")
	check("bought for Player 4: Player 1 paid 20, Player 4 has 4 dice", h.panels[0].points.text == "160" and h.panels[3].dice.text == "4 dice" and h.header.text.contains("14 dice"))
	# no gifts with a player in Purgatory
	h.s.seats[2].purgatory = true
	h._refresh()
	tap("points")
	check("a player in Purgatory cannot be chosen, and the button says why", not can_tap("other2") and h.btn.other2.text.contains("Purgatory"))
	tap("back")
	tap("pass")
	tap("ready")
	check("Player 2 is told a die is lent for this roll", h.btn.roll.text == "Roll 4 dice" and shown().contains("lent to you for this roll"))
	tap("roll")
	check("after the roll the lent die is in the supply", h.panels[1].dice.text == "3 dice" and h.panels[1].roll.get_child_count() == 4 and h.header.text.contains("15 dice"))


func test_win() -> void:
	await screen([6, 1, 1,  4, 4, 4])
	h.s.seats[0].points = 2940
	h._refresh()
	tap("ready")
	tap("roll")
	check("the winner screen names the winner", h.title.text == "Player 1 wins!" and h.panels[0].tag.text == "WINNER" and shown().contains("3000"))
	check("the only button starts a new match", can_tap("new") and h.btn.size() == 2)
	tap("new")
	check("a new match opens on the How to play card again", can_tap("got_it") and h.btn.size() == 1)
	tap("got_it")
	var fresh := true
	for i in 4:
		fresh = fresh and h.panels[i].points.text == "0" and h.panels[i].dice.text == "3 dice" and h.panels[i].roll.get_child_count() == 1
	check("a new match: everyone at 0 with 3 dice and no roll, Player 1 to start", fresh and h.title.text == "Pass the phone to Player 1")
	# no win while in Purgatory
	await screen([1, 1, 1])
	h.s.seats[0].points = 3000
	h._refresh()
	tap("ready")
	tap("roll")
	check("3000 points and a roll into Purgatory: no winner, and the screen says why", h.s.winner == -1 and shown().contains("cannot win while in Purgatory") and can_tap("pass"))


## Every view at its fullest stays inside a 1080 x 1920 screen.
func test_fits() -> void:
	await screen([1, 6, 6, 6, 6, 6, 6])
	var worst := 0.0
	var where := ""
	var views := ["handover"]
	tap("ready")
	views.append("roll")
	# the fullest table: everyone with many dice rolled, and 4-digit scores
	for p in h.s.seats:
		p.points = 2000
		p.dice = 6
		p.last_roll = [6, 6, 6, 6, 6, 6]
		p.last_score = 360
		p.purgatory = true
	h.s.seats[0].purgatory = false
	h.s.seats[0].last_roll = []
	h.s.seats[0].lent = 1
	h.s.supply = 2
	h._refresh()
	var steps := [["", "roll"], ["roll", "gambit"], ["points", "give points"], ["back", ""], ["lend", "lend"], ["back", ""], ["die", "buy for a player"]]
	for st in steps:
		if st[0] != "":
			tap(st[0])
		if st[1] == "":
			continue
		if st[1] == "gambit":
			for p in h.s.seats:
				p.purgatory = false
			h._refresh()
		if h.btn.has("other1"):
			tap("other1")
		await process_frame
		await process_frame
		await process_frame
		var bottom: float = h.buttons.get_global_rect().end.y
		if bottom > worst:
			worst = bottom
			where = st[1]
	check("the buttons end inside the screen in every view (lowest: %d of 1920, in %s)" % [int(worst), where], worst > 0 and worst <= 1920.0)
	var wide := 0.0
	for n in h.panels:
		wide = maxf(wide, n.points.get_global_rect().end.x)
	check("the panels stay inside the 1080 width (%d)" % int(wide), wide <= 1080.0)


## A whole match by taps alone on seeded dice: buys, gifts both ways, agreed and refused, to a winner.
func test_whole_match() -> void:
	await screen(null, 7)
	var pick := RandomNumberGenerator.new()
	pick.seed = 7
	var taps := 0
	var gifts := 0
	var stuck := false
	while h.s.winner == -1 and taps < 20000:
		taps += 1
		if can_tap("ready"):
			tap("ready")
		elif can_tap("roll"):
			tap("roll")
		elif can_tap("agree"):
			tap("agree" if pick.randi_range(0, 2) > 0 else "refuse")
			gifts += 1
		elif can_tap("offer") or h.btn.has("offer"):
			# in the gift form: choose a side and a player, then offer if allowed, else go back
			tap("ask" if pick.randi_range(0, 1) == 0 else "give")
			var others := []
			for i in 4:
				if can_tap("other%d" % i):
					others.append("other%d" % i)
			if not others.is_empty():
				tap(others[pick.randi_range(0, others.size() - 1)])
			tap("offer" if can_tap("offer") else "back")
		elif can_tap("pass"):
			var roll := pick.randi_range(0, 9)
			if roll < 3 and can_tap("buy"):
				tap("buy")
			elif roll < 6 and can_tap("points"):
				tap(["points", "lend", "die"][pick.randi_range(0, 2)])
			else:
				tap("pass")
		else:
			stuck = true
			break
		if Rules.total_dice(h.s) != 27:
			stuck = true
			break
	check("a whole match by taps ends in a winner (%d taps, %d gifts put to a player, round %d)" % [taps, gifts, h.s.round_number], not stuck and h.s.winner >= 0)
	check("the winner screen is up", h.title.text.contains("wins!") and can_tap("new"))
