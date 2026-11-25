## Step 1: four players pass one phone (rules: docs/step1-rules.md, in game/). A flat blockout: boxes and words, no art.
## Top: the four players, always shown (points, dice, Purgatory, last roll). Bottom: what the player holding the phone does now.
## No abilities yet.
extends Control

const Rules = preload("res://game/rules.gd")
const Config = preload("res://game/config.gd")

const FELL_FILE := preload("res://assets/fonts/IMFellEnglish-NoDigits.ttf")
const DIGITS_TEXT := preload("res://assets/fonts/Digits-Text.ttf")

const BG := Color("14161c")
const PANEL := Color("22262f")
const PANEL_TURN := Color("343b4b")
const TEXT := Color("f2ead8")
const DIM := Color("9aa0ad")
const GOLD := Color("e8c06a")
const DARK := Color("14161c")
const BAD := Color("ff6b5e")
const BUTTON := Color("3a4152")
const BUTTON_OFF := Color("262a33")
const SEAT_COLORS := [Color("ff8a7a"), Color("6fb8ff"), Color("7fe08a"), Color("ffd24a")]

const W := 1040          # content width
const DIE := 64          # a die of a last roll
const SIZE_SMALL := 34
const SIZE_TEXT := 40
const SIZE_NAME := 48
const SIZE_TITLE := 58
const SIZE_POINTS := 72
const BUTTON_H := 116
const GIFT_TITLES := {"points": "Give points", "lend": "Lend a die", "die": "Buy a die for a player"}
const GIFT_RULES := {
	"points": "Any amount the giver has. The other player taps to agree; then it is permanent.",
	"lend": "The die is theirs for one roll, then it goes to the supply, not back to the lender. No one can go below 2 dice.",
	"die": "The giver pays 20 and the die from the supply is theirs to keep.",
}

var s                        # the match (game/state.gd)
var rng = null               # set before the screen enters the tree to script the dice; else random
var sins: Array = []         # set to fix the Sins; else dealt at random
var view := "handover"       # handover (pass the phone), turn (roll, Gambit, turn over, winner), gift (the form), agree (the other player's tap)
var note := ""               # what just happened, shown in the turn view
var offer := {}              # the gift being set up: kind, give (the turn player gives), other (seat or -1), amount
var btn := {}                # the buttons on screen now, by key (the test taps these)

var serif: FontVariation
var header: Label
var panels: Array = []       # one Dictionary of nodes a seat
var title: Label
var text: Label
var buttons: VBoxContainer


func _init() -> void:
	serif = FontVariation.new()
	serif.base_font = FELL_FILE
	serif.fallbacks = [DIGITS_TEXT]


func _ready() -> void:
	_build()
	new_match()


func new_match() -> void:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	s = Rules.new_match(Config.merged({}), rng, sins)
	view = "handover"
	note = ""
	_refresh()


# ---- names and sentences

func seat_name(i: int) -> String:
	return "Player %d" % (i + 1)


func sin_name(i: int) -> String:
	return str(s.seats[i].sin).capitalize()


func dice_text(n: int) -> String:
	return "1 die" if n == 1 else "%d dice" % n


## What a gift does, as one sentence.
func gift_line(kind: String, from: int, to: int, amount: int) -> String:
	if kind == Rules.POINTS:
		return "%s gives %d points to %s." % [seat_name(from), amount, seat_name(to)]
	if kind == Rules.LEND:
		return "%s lends a die to %s for one roll." % [seat_name(from), seat_name(to)]
	return "%s pays %d and buys a die for %s." % [seat_name(from), int(s.cfg.die_cost), seat_name(to)]


func offer_from() -> int:
	return s.turn if offer.give else offer.other


func offer_to() -> int:
	return offer.other if offer.give else s.turn


## Why the offer cannot be made yet, or "".
func offer_block() -> String:
	if offer.other < 0:
		return "Choose a player."
	return Rules.gift_block(s, offer.kind, offer_from(), offer_to(), offer.amount)


## What the roll did, in words.
func roll_note(r: Dictionary) -> String:
	var faces := ", ".join(r.faces.map(func(f): return str(f)))
	var low := Rules.lows(s.cfg, r.faces)
	if r.escaped:
		return "You rolled %s. %s showing 1, 2 or 3: you are out of Purgatory, and the roll scores %d." % [faces, dice_text(low).capitalize(), r.scored]
	if r.purgatory and low < r.faces.size():
		return "You rolled %s. Only %s showing 1, 2 or 3: you need two or more. You stay in Purgatory and score nothing." % [faces, dice_text(low)]
	if r.purgatory and s.seats[s.turn].points >= int(s.cfg.win):
		return "You rolled %s. Every die shows 1, 2 or 3: Purgatory. You score 0 and your turn ends. You cannot win while in Purgatory." % faces
	if r.purgatory:
		return "You rolled %s. Every die shows 1, 2 or 3: Purgatory. You score 0 and your turn ends. No buying or trading until you are out." % faces
	return "You rolled %s and scored %d." % [faces, r.scored]


# ---- taps

func _on_ready() -> void:
	view = "turn"
	_refresh()


func _on_roll() -> void:
	var r: Dictionary = Rules.roll(s)
	if r.is_empty():
		return
	note = roll_note(r)
	_refresh()


func _on_buy() -> void:
	if Rules.buy(s, 1):
		note = "You bought a die for %d. You roll it from your next turn." % int(s.cfg.die_cost)
	_refresh()


func _on_pass() -> void:
	if Rules.pass_turn(s):
		view = "handover"
		note = ""
	_refresh()


func _on_gift(kind: String) -> void:
	offer = {"kind": kind, "give": true, "other": -1, "amount": 10}
	view = "gift"
	_refresh()


func _on_give(give: bool) -> void:
	offer.give = give
	_refresh()


func _on_other(i: int) -> void:
	offer.other = i
	_refresh()


func _on_amount(delta: int) -> void:
	offer.amount = maxi(10, offer.amount + delta)
	_refresh()


func _on_all() -> void:
	if offer.other >= 0 or offer.give:
		offer.amount = maxi(10, s.seats[offer_from()].points)
	_refresh()


func _on_back() -> void:
	view = "turn"
	_refresh()


func _on_offer() -> void:
	if offer_block() == "":
		view = "agree"
	_refresh()


func _on_agree(yes: bool) -> void:
	var line := gift_line(offer.kind, offer_from(), offer_to(), offer.amount)
	if yes and Rules.gift(s, offer.kind, offer_from(), offer_to(), offer.amount):
		note = "%s agreed. %s" % [seat_name(offer.other), line]
	else:
		note = "%s refused. Nothing changed." % seat_name(offer.other)
	note += " Pass the phone back to %s." % seat_name(s.turn)
	view = "turn"
	_refresh()


# ---- drawing

func _refresh() -> void:
	header.text = "Round %d   ·   First to %d wins   ·   Supply: %s" % [s.round_number, int(s.cfg.win), dice_text(s.supply)]
	for i in s.seats.size():
		_refresh_panel(i)
	for c in buttons.get_children():
		buttons.remove_child(c)
		c.queue_free()
	btn = {}
	if view == "handover":
		_view_handover()
	elif view == "gift":
		_view_gift()
	elif view == "agree":
		_view_agree()
	elif s.phase == Rules.FATE:
		_view_fate()
	elif s.phase == Rules.GAMBIT:
		_view_gambit()
	elif s.phase == Rules.END:
		_view_end()
	else:
		_view_over()


func _refresh_panel(i: int) -> void:
	var p = s.seats[i]
	var n: Dictionary = panels[i]
	var turn: bool = i == s.turn
	var sb: StyleBoxFlat = n.box
	sb.bg_color = PANEL_TURN if turn else PANEL
	sb.set_border_width_all(10 if turn else 2)
	n.sin.text = sin_name(i)
	n.points.text = str(p.points)
	var tags := []
	if s.winner == i:
		tags.append("WINNER")
	elif turn:
		tags.append("TURN")
	if p.purgatory:
		tags.append("IN PURGATORY")
	n.tag.text = "  ".join(tags)
	n.tag.add_theme_color_override("font_color", BAD if p.purgatory else GOLD)
	n.dice.text = dice_text(p.dice) + (" + %d lent" % p.lent if p.lent > 0 else "")
	for c in n.roll.get_children():
		n.roll.remove_child(c)
		c.queue_free()
	if p.last_roll.is_empty():
		n.roll.add_child(_label("no roll yet", SIZE_SMALL, DIM))
		n.scored.text = ""
	else:
		for f in p.last_roll:
			n.roll.add_child(_die(f))
		n.scored.text = "scored %d" % p.last_score


func _view_handover() -> void:
	var p = s.seats[s.turn]
	title.text = "Pass the phone to %s" % seat_name(s.turn)
	text.text = "%s plays %s." % [seat_name(s.turn), sin_name(s.turn)]
	if p.purgatory:
		text.text += " They are in Purgatory."
	_add(_button("ready", "I am %s" % seat_name(s.turn), _on_ready, true))


func _view_fate() -> void:
	var p = s.seats[s.turn]
	title.text = "%s: roll" % seat_name(s.turn)
	if p.purgatory:
		text.text = "You are in Purgatory. Roll all your dice: two or more showing 1, 2 or 3 free you, and then the roll's 4s, 5s and 6s score. Fewer, and your turn ends with nothing scored."
	else:
		text.text = "Roll all your dice once. A 4, 5 or 6 scores 40, 50 or 60. A 1, 2 or 3 scores nothing. If every die shows 1, 2 or 3 you go to Purgatory: you score 0 and your turn ends."
	if p.lent > 0:
		text.text += " %s lent to you for this roll, then to the supply." % ("1 die is" if p.lent == 1 else "%d dice are" % p.lent)
	_add(_button("roll", "Roll %s" % dice_text(p.dice + p.lent), _on_roll, true))


func _view_gambit() -> void:
	title.text = "%s: buy, trade, then pass" % seat_name(s.turn)
	text.text = note + "\nA die costs %d and you roll it from your next turn. A gift needs the other player's tap to agree." % int(s.cfg.die_cost)
	var can := Rules.max_buy(s) > 0
	var buy_text := "Buy a die: %d points" % int(s.cfg.die_cost)
	if s.supply < 1:
		buy_text = "Buy a die: the supply is empty"
	elif not can:
		buy_text = "Buy a die: you need %d points" % int(s.cfg.die_cost)
	_add(_button("buy", buy_text, _on_buy, false, not can))
	_add(_row([_button("points", GIFT_TITLES.points, _on_gift.bind(Rules.POINTS)),
		_button("lend", GIFT_TITLES.lend, _on_gift.bind(Rules.LEND))]))
	_add(_button("die", GIFT_TITLES.die, _on_gift.bind(Rules.DIE)))
	_add(_button("pass", "Pass: end my turn", _on_pass, true))


func _view_end() -> void:
	title.text = "%s: your turn is over" % seat_name(s.turn)
	text.text = note
	_add(_button("pass", "Pass the phone", _on_pass, true))


func _view_over() -> void:
	title.text = "%s wins!" % seat_name(s.winner)
	text.text = "%s\n%s ended a Fate Phase on %d points, out of Purgatory. First to %d wins." % [note, seat_name(s.winner), s.seats[s.winner].points, int(s.cfg.win)]
	_add(_button("new", "New match", new_match, true))


func _view_gift() -> void:
	var kind: String = offer.kind
	title.text = "%s: %s" % [seat_name(s.turn), GIFT_TITLES[kind].to_lower()]
	_add(_row([_button("give", "I give", _on_give.bind(true), false, false, offer.give),
		_button("ask", "I ask for it", _on_give.bind(false), false, false, not offer.give)]))
	var others := []
	for i in s.seats.size():
		if i == s.turn:
			continue
		var out: bool = s.seats[i].purgatory
		others.append(_button("other%d" % i, seat_name(i) + ("\nin Purgatory" if out else ""), _on_other.bind(i), false, out, offer.other == i))
	_add(_row(others))
	if kind == Rules.POINTS:
		if offer.other >= 0 or offer.give:
			offer.amount = clampi(offer.amount, 10, maxi(10, s.seats[offer_from()].points))
		var amount := _label("%d points" % offer.amount, SIZE_NAME, TEXT)
		amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		amount.custom_minimum_size = Vector2(250, 0)
		_add(_row([_button("m100", "- 100", _on_amount.bind(-100)), _button("m10", "- 10", _on_amount.bind(-10)), amount,
			_button("p10", "+ 10", _on_amount.bind(10)), _button("p100", "+ 100", _on_amount.bind(100)), _button("all", "All", _on_all)]))
	var block := offer_block()
	text.text = GIFT_RULES[kind] + "\n" + (block if block != "" else gift_line(kind, offer_from(), offer_to(), offer.amount))
	_add(_row([_button("back", "Back", _on_back), _button("offer", "Offer" if offer.give else "Ask", _on_offer, true, block != "")]))


func _view_agree() -> void:
	title.text = "Pass the phone to %s" % seat_name(offer.other)
	var line := gift_line(offer.kind, offer_from(), offer_to(), offer.amount)
	text.text = "%s %s: %s\n%s, do you agree? Once you agree it is permanent." % [seat_name(s.turn), "offers" if offer.give else "asks", line, seat_name(offer.other)]
	_add(_row([_button("refuse", "Refuse", _on_agree.bind(false)), _button("agree", "Agree", _on_agree.bind(true), true)]))


# ---- building

func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var th := Theme.new()
	th.default_font = serif
	th.default_font_size = SIZE_TEXT
	th.set_color("font_color", "Label", TEXT)
	theme = th
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	var top := 30
	var bottom := 24
	var safe := DisplayServer.get_display_safe_area()
	var screen := DisplayServer.screen_get_size()
	if screen.y > 0 and safe.size.y > 0:
		var k := get_viewport_rect().size.y / float(screen.y)
		top = maxi(top, int(safe.position.y * k) + 8)
		bottom = maxi(bottom, int((screen.y - safe.end.y) * k) + 8)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_bottom", bottom)
	add_child(margin)
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(W, 0)
	v.add_theme_constant_override("separation", 12)
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(h)
	h.add_child(v)

	header = _label("", SIZE_SMALL, DIM)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(header)
	for i in 4:
		v.add_child(_panel(i))
	title = _label("", SIZE_TITLE, GOLD)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(title)
	text = _label("", SIZE_TEXT, TEXT)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(text)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sp)
	buttons = VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	v.add_child(buttons)


## A seat's box: name, Sin, tag and points; then dice, last roll and what it scored.
func _panel(i: int) -> Control:
	var sb := StyleBoxFlat.new()
	sb.bg_color = PANEL
	sb.border_color = SEAT_COLORS[i]
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(18)
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	pc.add_child(v)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 18)
	v.add_child(top)
	top.add_child(_label(seat_name(i), SIZE_NAME, SEAT_COLORS[i]))
	var sin_label := _label("", SIZE_TEXT, DIM)
	top.add_child(sin_label)
	var tag := _label("", SIZE_SMALL, GOLD)
	tag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(tag)
	var points := _label("0", SIZE_POINTS, TEXT)
	top.add_child(points)
	var low := HBoxContainer.new()
	low.add_theme_constant_override("separation", 18)
	v.add_child(low)
	var dice := _label("", SIZE_TEXT, TEXT)
	dice.custom_minimum_size = Vector2(250, DIE)
	dice.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	low.add_child(dice)
	var roll := HFlowContainer.new()
	roll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	roll.add_theme_constant_override("h_separation", 8)
	roll.add_theme_constant_override("v_separation", 8)
	low.add_child(roll)
	var scored := _label("", SIZE_SMALL, DIM)
	scored.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	scored.size_flags_vertical = Control.SIZE_FILL
	low.add_child(scored)
	panels.append({"box": sb, "sin": sin_label, "tag": tag, "points": points, "dice": dice, "roll": roll, "scored": scored})
	return pc


## One die of a last roll: a 4, 5 or 6 (it scores) is bright; a 1, 2 or 3 is dim.
func _die(face: int) -> Control:
	var high: bool = face > int(s.cfg.low_max)
	var sb := StyleBoxFlat.new()
	sb.bg_color = TEXT if high else BUTTON_OFF
	sb.border_color = DIM
	sb.set_border_width_all(0 if high else 2)
	sb.set_corner_radius_all(10)
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", sb)
	pc.custom_minimum_size = Vector2(DIE, DIE)
	var l := _label(str(face), SIZE_NAME, DARK if high else DIM)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pc.add_child(l)
	return pc


func _label(t: String, size_px: int, color: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", color)
	return l


func _add(c: Control) -> void:
	buttons.add_child(c)


func _row(items: Array) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	for c in items:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(c)
	return h


## A flat button, kept in btn under its key. main: the one to tap next (gold). chosen: a picked option (ivory).
func _button(key: String, label: String, then: Callable, main := false, off := false, chosen := false) -> Button:
	var b := Button.new()
	b.text = label
	b.disabled = off
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, BUTTON_H)
	b.add_theme_font_size_override("font_size", SIZE_TEXT)
	var fill := GOLD if main else (TEXT if chosen else BUTTON)
	var ink := DARK if (main or chosen) else TEXT
	for st in ["normal", "hover", "pressed", "disabled"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = BUTTON_OFF if st == "disabled" else (fill.darkened(0.2) if st == "pressed" else fill)
		sb.set_corner_radius_all(12)
		sb.set_content_margin_all(10)
		b.add_theme_stylebox_override(st, sb)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, ink)
	b.add_theme_color_override("font_disabled_color", DIM)
	b.pressed.connect(then)
	btn[key] = b
	return b
