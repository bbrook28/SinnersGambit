## Tap-to-explain: a parchment card with a title and a paragraph or two (text from ui/rules_text.gd),
## and a link to the rulebook page it comes from. Tap anywhere else to close. The game's queue is
## paused while it shows (ui/main.gd).
extends Control

signal closed
signal open_page(id: String)

const Style = preload("res://ui/style.gd")
const Art = preload("res://ui/art.gd")

const BODY := 44
const INK := Color("2a1810")
const RED := Color("8e1a1a")
const TARGET := 44.0 * 1080.0 / 393.0

var _title: String
var _paras: Array
var _page: String
var _safe: Vector2


func _init(title: String, paras: Array, page_id := "", safe := Vector2.ZERO) -> void:
	_title = title
	_paras = paras
	_page = page_id
	_safe = safe
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	var dim := ColorRect.new()
	dim.color = Color(Style.C_BLACK, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			closed.emit())
	add_child(dim)
	var card := PanelContainer.new()
	var sb := StyleBoxEmpty.new()
	card.add_theme_stylebox_override("panel", sb)
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card.grow_vertical = Control.GROW_DIRECTION_BOTH
	card.custom_minimum_size.x = 960
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(card)
	var paper := Art.framed(Art.PAGE, Art.PAGE_MARGINS, 0.4)
	paper.modulate = Color(0.92, 0.84, 0.72)
	card.add_child(paper)
	var m := MarginContainer.new()
	for side in ["left", "right"]:
		m.add_theme_constant_override("margin_" + side, 90)
	m.add_theme_constant_override("margin_top", 70)
	m.add_theme_constant_override("margin_bottom", 64)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	m.add_child(v)
	var t := Style.label(_title, 66, RED, true, 0)
	v.add_child(t)
	for p in _paras:
		var r := RichTextLabel.new()
		r.bbcode_enabled = true
		r.fit_content = true
		r.scroll_active = false
		r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.add_theme_font_override("normal_font", Style.SERIF)
		r.add_theme_font_override("bold_font", Style.BLACKLETTER)
		r.add_theme_font_override("italics_font", Style.SERIF)
		r.add_theme_font_size_override("italics_font_size", BODY)
		r.add_theme_font_size_override("normal_font_size", BODY)
		r.add_theme_font_size_override("bold_font_size", int(BODY * 1.1))
		r.add_theme_color_override("default_color", INK)
		r.text = Style.numbers(p)
		v.add_child(r)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 40)
	if _page != "":
		row.add_child(_pill("Rulebook", 330, func(): open_page.emit(_page)))
	row.add_child(_pill("Close", 260, func(): closed.emit()))
	v.add_child(row)


func _pill(text: String, w: int, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(w, TARGET * 1.1)
	Art.skin(b, [Art.YOU_TAB, Art.YOU_TAB, Art.YOU_TAB], Color.WHITE, 24)
	b.add_theme_font_size_override("font_size", 44)
	b.pressed.connect(on_press)
	return b
