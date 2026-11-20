## One slot on the table: its name, its rule, the dice in it, the wire that watches it. Tap it to place the picked die.
extends PanelContainer

signal tapped(index: int)

const Texts = preload("res://ui/texts.gd")
const DieView = preload("res://ui/die_view.gd")

const IVORY := Color("e8dcbc")
const GOLD := Color("d9a441")
const BLOOD := Color("c0392b")

var index := -1
var title := Label.new()
var rule := Label.new()
var extra := Label.new()
var dice_row := HBoxContainer.new()
var body := VBoxContainer.new()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 6)
	add_child(body)
	title.add_theme_font_override("font", preload("res://assets/fonts/PirataOne-Regular.ttf"))
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", GOLD)
	body.add_child(title)
	rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rule.add_theme_font_size_override("font_size", 28)
	rule.add_theme_color_override("font_color", IVORY)
	body.add_child(rule)
	dice_row.add_theme_constant_override("separation", 10)
	body.add_child(dice_row)
	extra.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	extra.add_theme_font_size_override("font_size", 28)
	extra.add_theme_color_override("font_color", BLOOD)
	body.add_child(extra)


## lit: the picked die fits here. glow: the tutorial points here.
func show_slot(s, i: int, lit: bool, glow: bool) -> void:
	index = i
	var slot: Dictionary = s.slots[i]
	title.text = Texts.slot_name(slot) if not slot.hidden else "Prize (face down)"
	rule.text = Texts.slot_rule(s, slot)
	for c in dice_row.get_children():
		c.queue_free()
	if slot.kind == "target":
		dice_row.visible = false
	else:
		dice_row.visible = true
		for f in slot.dice:
			var d := DieView.new()
			d.setup(clampi(int(f), 1, 6), false, 64)
			dice_row.add_child(d)
		var room: int = int(slot.cap) - slot.dice.size()
		if slot.kind == "offering":
			var l := Label.new()
			l.text = "Offered: %d (every tier -%d)" % [s.offerings, s.offerings]
			l.add_theme_font_size_override("font_size", 28)
			dice_row.add_child(l)
		elif not slot.hidden and slot.kind != "target":
			var l := Label.new()
			if slot.done:
				l.text = "Claimed"
			elif slot.kind == "ward" and int(s.cfg.ward_cancels) > 0 and s.cancelled >= int(s.cfg.ward_cancels):
				l.text = "Spent this hand"
			elif room <= 0:
				l.text = "Full"
			else:
				l.text = "Room for %d" % room
			l.add_theme_font_size_override("font_size", 28)
			l.add_theme_color_override("font_color", Color(IVORY, 0.7))
			dice_row.add_child(l)
	var watch := []
	for w in s.wires:
		if w.kind == "tax" and w.slot == i:
			watch.append("Tax wire: when this is full, every tier needs +%d.%s" % [int(s.cfg.tax), " (Fired)" if s.tax_on else ""])
	extra.text = "\n".join(watch)
	extra.visible = not watch.is_empty()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("241915") if not slot.hidden else Color("171010")
	sb.set_corner_radius_all(18)
	sb.set_content_margin_all(20)
	sb.border_color = GOLD if lit else (Color("f2e3b3") if glow else Color("4a3a30"))
	sb.set_border_width_all(8 if lit or glow else 3)
	if lit:
		sb.bg_color = Color("3b2a17")
	add_theme_stylebox_override("panel", sb)


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:  # touch arrives as an emulated mouse press
		tapped.emit(index)
		accept_event()
