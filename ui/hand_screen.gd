## The playable bag hand (greybox): the table, the dice, Throw and Cash out, run on hand/rules.gd with today's config.
## The same loop as hand/play.gd, with you as the policy. Every rule is printed where it applies; a card explains each
## piece and event the first time you meet it; the first hand is the guided tutorial (ui/tutorial.gd).
extends Control

const Rules = preload("res://hand/rules.gd")
const Config = preload("res://hand/config.gd")
const Texts = preload("res://ui/texts.gd")
const Tutorial = preload("res://ui/tutorial.gd")
const DieView = preload("res://ui/die_view.gd")
const SlotView = preload("res://ui/slot_view.gd")
const TierBar = preload("res://ui/tier_bar.gd")
const Version = preload("res://ui/version.gd")

const BLACKLETTER := preload("res://assets/fonts/PirataOne-Regular.ttf")
const SERIF := preload("res://assets/fonts/IMFellEnglish-Regular.ttf")
const CINZEL := preload("res://assets/fonts/Cinzel.ttf")
const IVORY := Color("e8dcbc")
const GOLD := Color("d9a441")
const BLOOD := Color("c0392b")
var save_path := "user://progress.cfg"  # tests point it elsewhere

var cfg: Dictionary = Config.merged({})
var s = null
var rng = null
var faces: Array[int] = []
var thrown_skulls := 0
var phase := "throw"     # "throw", "place", "over"
var picked := -2         # a die index into faces, -1 the held die, -2 none
var tut = null
var tut_shown := -1      # the tutorial card step already queued
var seen := {}
var tutorial_done := false
var total := 0
var hand_no := 0
var cards: Array = []    # queued [title, text, on_close]

var header := Label.new()
var bag_label := Label.new()
var skull_label := Label.new()
var skull_row := HBoxContainer.new()
var target_view = SlotView.new()
var tier_bar = TierBar.new()
var grid := GridContainer.new()
var wires_box := VBoxContainer.new()
var news := Label.new()
var prompt := Label.new()
var tray := HBoxContainer.new()
var throw_btn := Button.new()
var cash_btn := Button.new()
var overlay := Control.new()
var card_title := Label.new()
var card_text := Label.new()
var card_btn := Button.new()
var card_extra := Button.new()
var slot_views: Array = []


func _ready() -> void:
	_load()
	_build()
	if tutorial_done:
		_new_hand()
	else:
		_start_tutorial()


# ---------- the hand ----------

func _start_tutorial() -> void:
	tut = Tutorial.new()
	tut_shown = -1
	rng = Tutorial.rng()
	s = Tutorial.table(cfg)
	hand_no += 1
	_begin()


func _new_hand() -> void:
	tut = null
	rng = RandomNumberGenerator.new()
	rng.randomize()
	s = Rules.new_hand(cfg, rng)
	hand_no += 1
	_begin()


func _begin() -> void:
	faces = []
	thrown_skulls = 0
	phase = "throw"
	picked = -2
	news.text = "A new hand. The Master deals the table."
	_build_slots()
	if tut == null:
		for slot in s.slots:
			if slot.kind in ["hold", "ward", "ladder", "pair", "sum"]:
				_first(slot.kind)
		for w in s.wires:
			_first(w.kind)
	_tut_sync()
	_refresh()


func _snap() -> Dictionary:
	return {"skulls": s.skulls, "cancelled": s.cancelled, "curse": s.curse_skulls, "hunger": s.hunger_on, "tax": s.tax_on,
		"wires": s.wires.size(), "revealed": s.revealed, "tier": Rules.tier(s), "bag": s.bag}


func _on_throw() -> void:
	if phase != "throw" or not _tut_allows("throw"):
		return
	var b := _snap()
	faces = Rules.throw(s, rng)
	var new_skulls: int = s.skulls - b.skulls + s.cancelled - b.cancelled
	var cursed: int = s.curse_skulls - b.curse
	thrown_skulls = maxi(0, new_skulls - cursed)
	picked = -2
	var lines: Array = []
	if s.dance:
		lines.append("The Last Dance: the bag's last die. Its pips count double.")
		_first("dance")
	if s.hunger_on and not b.hunger:
		lines.append("Hunger: you passed Tier 2 and threw on. Every throw now draws %d dice." % int(cfg.hunger_handful))
		_first("hunger")
	if cursed > 0:
		lines.append("Curse: %d waiting die came up a skull." % cursed)
		_first("curse")
	if s.cancelled > b.cancelled:
		lines.append("The Ward cancelled a skull. It is spent for this hand.")
	var landed: int = s.skulls - b.skulls
	if landed > 0:
		lines.append("%d skull%s: %d of %d on the table." % [landed, "" if landed == 1 else "s", s.skulls, int(cfg.bust_at)])
		_first("skull")
	if tut != null and tut.step().type == "throw":
		tut.advance()
	if Rules.ended(s):
		lines.append("Bust!")
		news.text = " ".join(lines)
		_end()
		return
	if Rules.legal_moves(s, faces).is_empty():
		lines.append("Nothing to place.")
		news.text = " ".join(lines)
		_answer()
		return
	news.text = " ".join(lines) if not lines.is_empty() else "You threw %s." % ", ".join(faces.map(func(f): return str(Rules.value(s, f, false))))
	phase = "place"
	_tut_sync()
	_refresh()


func _moves() -> Array:
	var all: Array = Rules.legal_moves(s, faces)
	if tut != null and tut.step().type == "place":
		var st: Dictionary = tut.step()
		return all.filter(func(m): return s.slots[m.slot].kind == st.slot and _face(m.die) == int(st.face))
	return all


func _face(die: int) -> int:
	return Rules.held(s) if die < 0 else faces[die]


func _on_die(d: int) -> void:
	if phase != "place":
		return
	if _moves().any(func(m): return m.die == d):
		picked = d
	elif tut != null:
		prompt.text = tut.step().get("msg", "")
	else:
		news.text = "That die fits no slot."
	_refresh()


func _on_slot(j: int) -> void:
	if phase != "place":
		return
	if picked == -2:
		var dice := {}
		for m in _moves():
			dice[m.die] = true
		if dice.size() == 1:
			picked = dice.keys()[0]  # only one die can go anywhere: pick it for you
		else:
			news.text = "Pick a die first."
			_refresh()
			return
	for m in _moves():
		if m.die == picked and m.slot == j:
			_place(m)
			return
	news.text = "That die doesn't fit there: the lit slots take it."
	_refresh()


func _place(m: Dictionary) -> void:
	var b := _snap()
	var label := "%d into %s." % [Rules.value(s, _face(m.die), m.die < 0), Texts.slot_name(s.slots[m.slot])]
	Rules.place(s, faces, m)
	faces = []
	thrown_skulls = 0
	picked = -2
	var lines: Array = [label]
	if s.revealed and not b.revealed:
		lines.append("Tier 1! The hand is won if you cash out. The prize turns face up.")
	elif Rules.tier(s) > b.tier:
		lines.append("Tier %d cleared." % Rules.tier(s))
	news.text = " ".join(lines)
	if tut != null and tut.step().type == "place":
		tut.advance()
	_answer()


## The Master answers; then the hand goes on, or ends when the bag is empty.
func _answer() -> void:
	var b := _snap()
	Rules.master_answer(s)
	var lines: Array = []
	if s.tax_on and not b.tax:
		lines.append("Tax fires: every tier needs +%d for the rest of the hand." % int(cfg.tax))
		_first("tax")
	if s.wires.size() > b.wires:
		var w: Dictionary = s.wires[-1]
		lines.append("The Master answers your first engine die: a new wire, %s." % Texts.NAMES[w.kind])
		_first("second_wire")
		_first(w.kind)
	if Rules.tier(s) < b.tier:
		lines.append("You drop back to Tier %d." % Rules.tier(s))
	if not lines.is_empty():
		news.text += " " + " ".join(lines)
	faces = []
	if s.bag <= 0:
		_first("empty_bag")
		var none: Array[int] = []
		if not Rules.legal_moves(s, none).is_empty():
			phase = "place"
			news.text += " The bag is empty: place your held die, or cash out."
			_tut_sync()
			_refresh()
			return
		Rules.cash_out(s)
		_end()
		return
	phase = "throw"
	_tut_sync()
	_refresh()


func _on_cash() -> void:
	if phase == "over" or not _tut_allows("cash"):
		return
	if phase == "place" and s.bag > 0:
		return
	Rules.cash_out(s)
	_end()


func _end() -> void:
	phase = "over"
	faces = []
	var m := Rules.marks(s)
	total += m
	var title := ""
	var text := ""
	match s.outcome:
		"won":
			title = "Won: %d marks" % m
			text = "Tier %d pays %d." % [Rules.tier(s), Rules.tier_marks(s)]
			if Rules.prize_marks(s) > 0:
				text += " The prize adds %d." % Rules.prize_marks(s)
		"bust":
			title = "Bust"
			text = "Three skulls." if s.skulls >= int(cfg.bust_at) else "A skull on the Last Dance."
			text += " The hand is lost, and everything in it."
		_:
			title = "Short of the Target"
			text = "You cashed out below Tier 1. The hand is lost."
	text += "\n\nMarks so far: %d over %d hand%s." % [total, hand_no, "" if hand_no == 1 else "s"]
	if tut != null:
		tutorial_done = true
		tut = null
		text += "\n\nThat was the guided hand. From now on the Master deals a new table every hand. Tap ? for every rule."
	_save()
	_refresh()
	_card(title, text, _new_hand, "Next hand")


# ---------- the tutorial ----------

func _tut_allows(action: String) -> bool:
	if tut == null:
		return true
	var t: String = tut.step().type
	if t == "free":
		return true
	return t == action


func _tut_sync() -> void:
	if tut == null:
		return
	var st: Dictionary = tut.step()
	for k in str(st.get("seen", "")).split(" ", false):
		seen[k] = true
	match st.type:
		"card":
			if tut_shown == tut.i:
				return
			tut_shown = tut.i
			_card(st.title, st.text, func():
				tut.advance()
				_tut_sync()
				_refresh())
		"throw", "place":
			prompt.text = st.msg
		"free":
			tutorial_done = true
			_save()


# ---------- cards ----------

func _first(key: String) -> void:
	if (tut != null and not tut.done()) or seen.has(key) or not Texts.CARDS.has(key):
		return
	seen[key] = true
	_save()
	_card(Texts.CARDS[key][0], Texts.CARDS[key][1], Callable())


func _card(title: String, text: String, on_close: Callable, button := "Got it", extra := "", on_extra := Callable()) -> void:
	cards.append([title, text, on_close, button, extra, on_extra])
	if cards.size() == 1:
		_show_card()


func _show_card() -> void:
	if cards.is_empty():
		overlay.visible = false
		return
	var c: Array = cards[0]
	card_title.text = c[0]
	card_text.text = c[1]
	card_btn.text = c[3]
	card_extra.text = c[4]
	card_extra.visible = c[4] != ""
	overlay.visible = true


func _on_card_btn() -> void:
	if cards.is_empty():
		return
	var c: Array = cards.pop_front()
	_show_card()
	if c[2].is_valid():
		c[2].call()
	_refresh()


func _on_card_extra() -> void:
	if cards.is_empty():
		return
	var c: Array = cards.pop_front()
	_show_card()
	if c[5].is_valid():
		c[5].call()
	_refresh()


func _on_help() -> void:
	var t := "The bag holds %d dice. Each throw draws %d; place exactly one, the rest go back. A 1 is a skull: it stays on the table, out of the bag; %d skulls bust you.\n\n" % [int(cfg.bag), int(cfg.handful), int(cfg.bust_at)]
	t += "Tiers %s pay %s marks: the highest you've cleared when you cash out, not the sum. Below Tier 1, cashing out loses the hand.\n\n" % [str(cfg.tiers).replace(",", " / "), str(cfg.tier_marks).replace(",", " / ")]
	for k in ["offering", "hold", "ward", "ladder", "pair", "sum", "tax", "hunger", "curse", "second_wire", "dance", "empty_bag"]:
		t += "%s: %s\n\n" % [Texts.CARDS[k][0], Texts.CARDS[k][1]]
	t += "Build %s %s" % [Version.VERSION, Version.BUILD if Version.BUILD != "" else "local"]
	_card("Every rule", t, Callable(), "Close", "Replay the tutorial", func():
		cards.clear()
		_show_card()
		_start_tutorial())


# ---------- drawing ----------

func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var th := Theme.new()
	th.default_font = SERIF
	th.default_font_size = 34
	th.set_color("font_color", "Label", IVORY)
	theme = th
	var bg := ColorRect.new()
	bg.color = Color("120c0a")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	var top := 40
	var bottom := 30
	var safe := DisplayServer.get_display_safe_area()
	var screen := DisplayServer.screen_get_size()
	if screen.y > 0 and safe.size.y > 0:
		var k := get_viewport_rect().size.y / float(screen.y)
		top = maxi(top, int(safe.position.y * k) + 10)
		bottom = maxi(bottom, int((screen.y - safe.end.y) * k) + 10)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 30)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_bottom", bottom)
	add_child(margin)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	margin.add_child(v)

	var head := HBoxContainer.new()
	header.add_theme_font_override("font", BLACKLETTER)
	header.add_theme_font_size_override("font_size", 56)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(header)
	var help := Button.new()
	help.text = "  ?  "
	_style_button(help, Color("2a1f1a"))
	help.pressed.connect(_on_help)
	head.add_child(help)
	v.add_child(head)

	var status := HBoxContainer.new()
	status.add_theme_constant_override("separation", 30)
	bag_label.add_theme_font_override("font", CINZEL)
	bag_label.add_theme_font_size_override("font_size", 40)
	bag_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.add_child(bag_label)
	skull_label.add_theme_font_override("font", CINZEL)
	skull_label.add_theme_font_size_override("font_size", 40)
	status.add_child(skull_label)
	skull_row.add_theme_constant_override("separation", 8)
	status.add_child(skull_row)
	v.add_child(status)
	var core := Label.new()
	core.text = "Place 1 die each throw  ·  3 skulls bust you  ·  cash out for your highest tier"
	core.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	core.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	core.add_theme_font_size_override("font_size", 28)
	core.add_theme_color_override("font_color", Color(IVORY, 0.75))
	v.add_child(core)

	target_view.tapped.connect(_on_slot)
	v.add_child(target_view)
	target_view.body.add_child(tier_bar)
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	v.add_child(grid)

	var wp := PanelContainer.new()
	var wsb := StyleBoxFlat.new()
	wsb.bg_color = Color("1c1010")
	wsb.border_color = Color("6b2a22")
	wsb.set_border_width_all(3)
	wsb.set_corner_radius_all(18)
	wsb.set_content_margin_all(20)
	wp.add_theme_stylebox_override("panel", wsb)
	wires_box.add_theme_constant_override("separation", 8)
	wp.add_child(wires_box)
	v.add_child(wp)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(spacer)
	news.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	news.add_theme_font_size_override("font_size", 32)
	news.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(news)
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt.add_theme_font_size_override("font_size", 36)
	prompt.add_theme_color_override("font_color", GOLD)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(prompt)
	tray.alignment = BoxContainer.ALIGNMENT_CENTER
	tray.add_theme_constant_override("separation", 30)
	tray.custom_minimum_size = Vector2(0, 200)
	v.add_child(tray)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 20)
	for b in [throw_btn, cash_btn]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 130)
		buttons.add_child(b)
	_style_button(throw_btn, Color("5a1f18"))
	_style_button(cash_btn, Color("3a3020"))
	throw_btn.pressed.connect(_on_throw)
	cash_btn.pressed.connect(_on_cash)
	v.add_child(buttons)

	_build_overlay()


func _style_button(b: Button, c: Color) -> void:
	for st in ["normal", "hover", "pressed", "disabled", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = c.darkened(0.5) if st == "disabled" else (c.lightened(0.15) if st == "pressed" else c)
		sb.set_corner_radius_all(20)
		sb.set_content_margin_all(16)
		if st == "focus":
			sb.draw_center = false
		b.add_theme_stylebox_override(st, sb)
	b.add_theme_font_override("font", CINZEL)
	b.add_theme_font_size_override("font_size", 34)
	b.add_theme_color_override("font_color", IVORY)
	b.add_theme_color_override("font_disabled_color", Color(IVORY, 0.35))
	b.focus_mode = Control.FOCUS_NONE


func _build_overlay() -> void:
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("2a1f1a")
	sb.border_color = GOLD
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(24)
	sb.set_content_margin_all(40)
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size = Vector2(940, 0)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 26)
	panel.add_child(v)
	card_title.add_theme_font_override("font", BLACKLETTER)
	card_title.add_theme_font_size_override("font_size", 64)
	card_title.add_theme_color_override("font_color", GOLD)
	v.add_child(card_title)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(860, 0)
	card_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_text.custom_minimum_size = Vector2(860, 0)
	card_text.add_theme_font_size_override("font_size", 36)
	scroll.add_child(card_text)
	v.add_child(scroll)
	card_text.resized.connect(func(): scroll.custom_minimum_size.y = minf(card_text.size.y, get_viewport_rect().size.y * 0.6))
	for b in [card_btn, card_extra]:
		b.custom_minimum_size = Vector2(0, 120)
		v.add_child(b)
	_style_button(card_btn, Color("5a1f18"))
	_style_button(card_extra, Color("3a3020"))
	card_btn.pressed.connect(_on_card_btn)
	card_extra.pressed.connect(_on_card_extra)


func _build_slots() -> void:
	for c in grid.get_children():
		c.queue_free()
	slot_views = [target_view]
	for i in range(1, s.slots.size()):
		var sv = SlotView.new()
		sv.tapped.connect(_on_slot)
		grid.add_child(sv)
		slot_views.append(sv)


func _refresh() -> void:
	if s == null:
		return
	header.text = ("Guided hand" if tut != null else "Hand %d" % hand_no) + "   ·   Marks %d" % total
	bag_label.text = "Bag: %d %s" % [s.bag, "die" if s.bag == 1 else "dice"]
	skull_label.text = "Skulls"
	for c in skull_row.get_children():
		c.queue_free()
	for i in int(cfg.bust_at):
		var r := ColorRect.new()
		r.custom_minimum_size = Vector2(46, 46)
		r.color = BLOOD if i < s.skulls else Color("3a2a24")
		skull_row.add_child(r)

	var lit := {}
	var glow := {}
	var mv: Array = _moves() if phase == "place" else []
	for m in mv:
		if m.die == picked:
			lit[m.slot] = true
	if tut != null and tut.step().type == "place":
		for j in s.slots.size():
			if s.slots[j].kind == tut.step().slot:
				glow[j] = true
	var cursed: Array = Rules.cursed(s)
	for j in s.slots.size():
		var pv := ""
		if lit.has(j):
			for m in mv:
				if m.die == picked and m.slot == j:
					pv = _preview(m)
		var tg := "Cursed: thrown again on your next throw. A 1 or 2 makes it a skull." if j in cursed else ""
		slot_views[j].show_slot(s, j, lit.has(j), glow.has(j), pv, tg)
	tier_bar.show_hand(s)
	target_view.title.text = "The Target: %d pips%s" % [s.progress, "  (Ladder: x2)" if Rules._ladder_full(s) else ""]
	target_view.rule.text = _goal()

	for c in wires_box.get_children():
		c.queue_free()
	var wt := Label.new()
	wt.text = "The Master's wires"
	wt.add_theme_font_override("font", BLACKLETTER)
	wt.add_theme_font_size_override("font_size", 42)
	wt.add_theme_color_override("font_color", BLOOD)
	wires_box.add_child(wt)
	for w in s.wires:
		var l := Label.new()
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_font_size_override("font_size", 30)
		var on: bool = (w.kind == "tax" and s.tax_on) or (w.kind == "hunger" and s.hunger_on)
		l.text = "%s%s: %s" % [Texts.NAMES[w.kind], " (on)" if on else "", Texts.wire_rule(s, w)]
		wires_box.add_child(l)
	if not s.second_wire and not s.wire_pool.is_empty():
		var l := Label.new()
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_font_size_override("font_size", 28)
		l.add_theme_color_override("font_color", Color(IVORY, 0.65))
		l.text = "Face down: one more wire. The Master deals it when you first put a die in Hold, the Ward or the Ladder."
		wires_box.add_child(l)

	for c in tray.get_children():
		c.queue_free()
	if phase == "place":
		var playable := {}
		for m in mv:
			playable[m.die] = true
		for d in faces.size():
			var dv := DieView.new()
			dv.setup(faces[d], false, 150)
			dv.selected = picked == d
			dv.dim = not playable.has(d)
			dv.tappable = true
			if s.dance:
				dv.caption = "x2"
			dv.picked.connect(_on_die.bind(d))
			tray.add_child(dv)
		if Rules.held(s) > 0:
			var hv := DieView.new()
			hv.setup(Rules.held(s), false, 150)
			hv.caption = "held"
			hv.selected = picked == -1
			hv.dim = not playable.has(-1)
			hv.tappable = true
			hv.picked.connect(_on_die.bind(-1))
			tray.add_child(hv)
	if phase == "place" or thrown_skulls > 0:
		for k in thrown_skulls:
			var sk := DieView.new()
			sk.setup(1, true, 150)
			sk.caption = "skull"
			tray.add_child(sk)

	var hunger: bool = s.hunger_on or (Rules._has_wire(s, "hunger") and Rules.tier(s) >= 2)
	var n := Rules.next_draw(s)
	if s.bag == 1:
		throw_btn.text = "Last Dance"
	else:
		throw_btn.text = "Throw %d dice%s" % [n, " (Hunger)" if hunger else ""]
	if phase == "throw" and s.bag > 0:
		var p := Rules.bust_chance(s)
		throw_btn.text += "
" + ("no bust risk" if p <= 0.0 else "%d%% bust" % roundi(p * 100.0))
	throw_btn.disabled = phase != "throw" or not _tut_allows("throw") or not overlay_free()
	if Rules.target_met(s):
		cash_btn.text = "Cash out
%d marks, safe" % (Rules.tier_marks(s) + Rules.prize_marks(s))
	else:
		cash_btn.text = "Cash out
lose: short"
	cash_btn.disabled = phase == "over" or (phase == "place" and s.bag > 0) or not _tut_allows("cash") or not overlay_free()
	if tut == null or tut.done():
		match phase:
			"throw":
				if s.bag == 1:
					prompt.text = "Next throw is the Last Dance: the last die counts x2, and any skull busts you."
				else:
					prompt.text = "Throw on, or cash out." if Rules.target_met(s) else "Throw: you need Tier 1 to win."
			"place":
				prompt.text = "Pick a die to place." if picked == -2 else "Tap a lit slot to place it."
			_:
				prompt.text = ""


## What placing this die here would do, worked out on a copy of the hand.
func _preview(m: Dictionary) -> String:
	var c = s.clone()
	var f := faces.duplicate()
	Rules.place(c, f, m)
	Rules.master_answer(c)
	var slot: Dictionary = s.slots[m.slot]
	var parts: Array = []
	match slot.kind:
		"target":
			parts.append("Target to %d" % c.progress)
		"offering":
			var needs: Array = []
			for i in range(1, Rules.tiers(c) + 1):
				needs.append(str(Rules.tier_need(c, i)))
			parts.append("Tiers to %s" % " / ".join(needs))
		"ward":
			parts.append("Cancels your next skull")
		"hold":
			parts.append("Kept for a later throw")
		"ladder":
			if Rules._ladder_full(c):
				parts.append("Full: Target dice count x2 from now")
			else:
				parts.append("First rung: the next die must be higher")
		"rites":
			parts.append("Counts x%d if your next throw has no skull" % int(cfg.rites_mult))
	if c.tax_on and not s.tax_on:
		parts.append("Tax fires: tiers +%d" % int(cfg.tax))
	if Rules.tier(c) > Rules.tier(s):
		parts.append("Tier %d: %d marks" % [Rules.tier(c), Rules.tier_marks(c)])
	elif Rules.tier(c) < Rules.tier(s):
		parts.append("Drops to Tier %d" % Rules.tier(c))
	if c.wires.size() > s.wires.size():
		parts.append("The Master deals a wire")
	return ". ".join(parts) + "."


## The next thing to aim for, in one line.
func _goal() -> String:
	var t := Rules.tier(s)
	var n := Rules.tiers(s)
	if t >= n:
		return "Top tier cleared: %d marks if you cash out." % Rules.tier_marks(s)
	var need: int = Rules.tier_need(s, t + 1) - s.progress
	var m := int(Rules._ints(cfg.tier_marks)[t])
	return "Tier %d: %d more pip%s for %d marks." % [t + 1, need, "" if need == 1 else "s", m]


func overlay_free() -> bool:
	return cards.is_empty()


# ---------- saving ----------

func _load() -> void:
	var f := ConfigFile.new()
	if f.load(save_path) != OK:
		return
	for k in f.get_value("p", "seen", []):
		seen[k] = true
	tutorial_done = f.get_value("p", "tutorial_done", false)
	total = f.get_value("p", "total", 0)
	hand_no = f.get_value("p", "hands", 0)


func _save() -> void:
	var f := ConfigFile.new()
	f.set_value("p", "seen", seen.keys())
	f.set_value("p", "tutorial_done", tutorial_done)
	f.set_value("p", "total", total)
	f.set_value("p", "hands", hand_no)
	f.save(save_path)
