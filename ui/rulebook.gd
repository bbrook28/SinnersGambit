## The rulebook: illustrated pages read from ui/rules_text.gd (the only place rule text lives).
## Opened from the main menu and from the game's "?" button (at the page that fits the moment).
## Swipe or use the arrows to turn pages; Contents jumps anywhere. Emits `closed` when shut.
extends Control

signal closed

const Style = preload("res://ui/style.gd")
const Art = preload("res://ui/art.gd")
const Die = preload("res://ui/widgets/die.gd")
const Tuning = preload("res://ui/tuning.gd")
const T = preload("res://ui/rules_text.gd")

const BODY := 44              # serif body, px (16 pt at 1080 wide)
const SMALL := 40             # captions and the Sins / glossary pages (14.6 pt)
const TITLE := 84
const INK := Color("2a1810")
const INK_SOFT := Color("4a3324")
const RED := Color("8e1a1a")
const TARGET := 44.0 * 1080.0 / 393.0
const SWIPE := 140.0

var page := 0
var sfx = null                # ui/sfx.gd, for page sounds (optional)
var safe := Vector2.ZERO      # top / bottom insets from main
var only_sins: Array = []     # the Sins page lists only these (the pause menu: the Sins at this table)
var _title: Label
var _scroll: ScrollContainer
var _body: VBoxContainer
var _count: Label
var _prev: Button
var _next: Button
var _press := Vector2.INF


func _init(start_id := "contents", p_safe := Vector2.ZERO, p_sfx = null) -> void:
	page = T.page_index(start_id)
	safe = p_safe
	sfx = p_sfx
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	var dim := ColorRect.new()
	dim.color = Color(Style.C_BLACK, 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var holder := MarginContainer.new()
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.add_theme_constant_override("margin_left", 24)
	holder.add_theme_constant_override("margin_right", 24)
	holder.add_theme_constant_override("margin_top", int(safe.x) + 30)
	holder.add_theme_constant_override("margin_bottom", int(safe.y) + 30)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(holder)
	var sheet := Control.new()
	sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(sheet)
	var paper := Art.framed(Art.PAGE, Art.PAGE_MARGINS, 0.5)
	paper.modulate = Color(0.9, 0.82, 0.7)
	sheet.add_child(paper)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 92
	v.offset_right = -92
	v.offset_top = 70
	v.offset_bottom = -64
	v.add_theme_constant_override("separation", 36)
	sheet.add_child(v)
	_title = Style.label("", TITLE, RED, true, 0)
	_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	v.add_child(_title)
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	v.add_child(_scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 26)
	_scroll.add_child(_body)
	# Page turning: arrows either side of the page count, then Close.
	var nav := HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 40)
	_prev = _pill("Previous", 290, func(): turn(-1))
	_count = Style.label("", SMALL, INK_SOFT, false, 0)
	_count.add_theme_font_override("font", Style.NUMERAL)
	_count.custom_minimum_size.x = 150
	_next = _pill("Next", 290, func(): turn(1))
	nav.add_child(_prev)
	nav.add_child(_count)
	nav.add_child(_next)
	v.add_child(nav)
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 40)
	bottom.add_child(_pill("Contents", 320, func(): show_page(0)))
	bottom.add_child(_pill("Close", 280, close))
	v.add_child(bottom)
	show_page(page)


func close() -> void:
	closed.emit()


func turn(d: int) -> void:
	show_page(clampi(page + d, 0, T.PAGES.size() - 1))


func show_page(i: int) -> void:
	if i != page and sfx:
		sfx.play("plaque", 0.4, 1.0, true)
	page = i
	var p: Dictionary = T.PAGES[i]
	_title.text = p.title
	_count.text = "%d / %d" % [i + 1, T.PAGES.size()]
	_prev.disabled = i == 0
	_next.disabled = i == T.PAGES.size() - 1
	for c in _body.get_children():
		c.queue_free()
	match p.id:
		"contents":
			_contents()
		"all_sins":
			_all_sins()
		"glossary":
			_glossary()
		_:
			var art := _art(p.art)
			if art:
				_body.add_child(art)
			for para in p.body:
				_body.add_child(_para(T.fill(para), BODY))
	_scroll.scroll_vertical = 0


# ---------- Pages ----------

func _contents() -> void:
	_body.add_child(_heading("The short version"))
	var five := T.five()
	for k in five.size():
		_body.add_child(_para("%d.  %s" % [k + 1, five[k]], BODY))
	_body.add_child(_heading("Pages"))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 36)
	grid.add_theme_constant_override("v_separation", 36)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for k in range(1, T.PAGES.size()):
		var idx := k
		var b := _pill(T.PAGES[k].title, 390, func(): show_page(idx))
		b.add_theme_font_size_override("font_size", 36)
		grid.add_child(b)
	_body.add_child(grid)


func _all_sins() -> void:
	for s in (only_sins if not only_sins.is_empty() else T.SIN_ORDER):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 22)
		var win := TextureRect.new()
		win.texture = Art.window(s)
		win.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		win.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		win.custom_minimum_size = Vector2(110, 330)
		win.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		row.add_child(win)
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 6)
		var nm := Style.label("%s, %s" % [s, T.SINS[s].epithet], 56, Style.SIN_COLORS[s].darkened(0.35), true, 0)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		col.add_child(nm)
		col.add_child(_para("[i]%s[/i]" % T.SINS[s].play, SMALL, INK_SOFT))
		col.add_child(_para("[b]%s[/b] (Basic): %s" % [T.ability_name(s, false), T.ability_text(s, false)], SMALL))
		col.add_child(_para("[b]%s[/b] (Greater): %s" % [T.ability_name(s, true), T.ability_text(s, true)], SMALL))
		row.add_child(col)
		_body.add_child(row)


func _glossary() -> void:
	var g := T.glossary()
	var keys: Array = g.keys()
	keys.sort_custom(func(a, b): return a.naturalnocasecmp_to(b) < 0)
	for k in keys:
		_body.add_child(_para("[b]%s[/b]  %s" % [k, g[k][0]], SMALL))


# ---------- Illustrations (game art, no new assets) ----------

func _art(kind: String) -> Control:
	match kind:
		"windows":
			var row := _row(10)
			for s in T.SIN_ORDER:
				var w := TextureRect.new()
				w.texture = Art.window(s)
				w.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				w.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				w.custom_minimum_size = Vector2(96, 290)
				row.add_child(w)
			return row
		"turn":
			var row := _row(16)
			for f in [5, 4, 1]:
				row.add_child(_die(f, 120))
			row.add_child(_word("→", 70, INK_SOFT))
			row.add_child(_seal("throw", T.word("throw_cap")))
			row.add_child(_word("or", SMALL, INK_SOFT))
			row.add_child(_seal("bank", T.word("bank_cap")))
			return row
		"scoring":
			var row := _row(12)
			var v := T.vals()
			var caps := ["Strike", "Strike", "nothing", str(v.f4), str(v.f5), str(v.f6)]
			for f in range(1, 7):
				var col := VBoxContainer.new()
				col.add_theme_constant_override("separation", 4)
				col.add_child(_die(f, 112))
				col.add_child(_word(caps[f - 1], 34, RED if f <= 2 else (INK_SOFT if f == 3 else INK)))
				row.add_child(col)
			return row
		"strikes":
			var row := _row(18)
			for k in 3:
				var t := TextureRect.new()
				t.texture = Art.candle()
				t.material = Art.candle_material(k < 2)  # two Strikes: two candles out
				t.custom_minimum_size = Vector2(60, 160)
				t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				row.add_child(t)
			row.add_child(_word("Two Strikes: two candles out.\nOne more is a bust.", SMALL, RED))
			return row
		"bank":
			var row := _row(18)
			row.add_child(_seal("bank", T.word("bank_cap"), 75))
			row.add_child(_word("→", 70, INK_SOFT))
			row.add_child(_word("Score\n+75", 52, INK))
			return row
		"purgatory":
			var row := _row(16)
			for f in [2, 6, 3]:
				row.add_child(_die(f, 120))
			row.add_child(_word("A 6:\nyou're free.", SMALL, INK))
			return row
		"buying":
			var row := _row(18)
			var d := TextureRect.new()
			d.texture = Art.ICON_DIE
			d.custom_minimum_size = Vector2(130, 130)
			d.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			d.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			row.add_child(d)
			row.add_child(_word("+1 die\n-%d points" % T.vals().die_cost, 48, INK))
			return row
		"tiers":
			var row := _row(22)
			var w := TextureRect.new()
			w.texture = Art.window("Pride")
			w.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			w.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			w.custom_minimum_size = Vector2(110, 330)
			row.add_child(w)
			var col := VBoxContainer.new()
			col.alignment = BoxContainer.ALIGNMENT_CENTER
			col.add_theme_constant_override("separation", 14)
			col.add_child(_word("Basic: from the start", SMALL, INK))
			col.add_child(_word("Greater: at %d points" % T.vals().greater_at, SMALL, RED))
			row.add_child(col)
			return row
		"winning":
			var row := _row(0)
			row.add_child(Style.number(str(T.vals().win), 150))
			return row
	return null


# ---------- Pieces ----------

func _row(sep: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", sep)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return row


func _die(face: int, side: int) -> Control:
	var d := Die.new(face, side, face)
	d.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return d


func _word(text: String, size: int, color: Color) -> Label:
	var l := Style.label(text, size, color, false, 0)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if text.is_valid_int():
		l.add_theme_font_override("font", Style.NUMERAL)  # lining figures, as everywhere numbers matter
	return l


## A picture of an emblem seal (not a button), as on the board: its word inked under it and, with
## n, the gold numeral beside it (left, as Bank's points sit).
func _seal(emblem: String, word: String, n := 0) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var t := TextureRect.new()
	t.texture = Art.emblem(emblem)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(150, 150)
	col.add_child(t)
	var l := Style.label(word, 36, INK, true, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(l)
	if n <= 0:
		return col
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var num := Style.label(str(n), 52, Style.C_GOLD, false, 8)
	num.add_theme_font_override("font", Style.NUMERAL)
	num.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(num)
	row.add_child(col)
	return row


func _heading(text: String) -> Label:
	var l := Style.label(text, 54, RED, true, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return l


## A left-aligned serif paragraph; numbers set in the numeral face like everywhere else.
func _para(text: String, size: int, color := INK) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.mouse_filter = Control.MOUSE_FILTER_PASS
	r.add_theme_font_override("normal_font", Style.SERIF)
	r.add_theme_font_override("bold_font", Style.BLACKLETTER)
	r.add_theme_font_override("italics_font", Style.SERIF)
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("bold_font_size", int(size * 1.12))
	r.add_theme_font_size_override("italics_font_size", size)
	r.add_theme_color_override("default_color", color)
	r.text = Style.numbers(text)
	return r


func _pill(text: String, w: int, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(w, TARGET * 1.1)
	Art.skin(b, [Art.YOU_TAB, Art.YOU_TAB, Art.YOU_TAB], Color.WHITE, 24)
	b.add_theme_font_size_override("font_size", 44)
	b.pressed.connect(on_press)
	return b


## Swipe left / right turns the page (vertical drags scroll).
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press = event.position
		elif _press != Vector2.INF:
			var d: Vector2 = event.position - _press
			_press = Vector2.INF
			if absf(d.x) > SWIPE and absf(d.x) > absf(d.y) * 2.0:
				turn(-1 if d.x > 0 else 1)
