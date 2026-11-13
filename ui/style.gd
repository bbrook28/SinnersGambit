## Art direction in code: palette, fonts and UI pieces. Docs/Plan.md has the brief.
## Gold = numbers that matter. Jewel colour only in stained glass. Bone for dice and parchment.
extends RefCounted

const C_BLACK := Color("140d0b")        # candlelit black, never #000
const C_INK := Color("2a1810")
const C_OXBLOOD := Color("5a1414")
const C_CRIMSON := Color("9e1c22")      # wax seal
const C_CRIMSON_DARK := Color("5e0f13")
const C_GOLD := Color("e9c46a")
const C_GOLD_DEEP := Color("a87b2c")
const C_BONE := Color("e8dcbc")
const C_BONE_DARK := Color("b9a67c")
const C_PARCHMENT := Color("dccb9f")
const C_IVORY := Color("f2e8d0")
const C_DIM := Color("8f8170")
const C_STRIKE := Color("b0161c")

const SIN_COLORS := {
	"Wrath": Color("c8202a"),     # ruby
	"Greed": Color("a9b4c2"),     # tarnished silver (was topaz; too close to gold numbers and Gluttony)
	"Lust": Color("c02c78"),      # rose
	"Envy": Color("1f9a4e"),      # emerald
	"Pride": Color("7a3cc8"),     # amethyst
	"Gluttony": Color("de6a14"),  # amber
	"Sloth": Color("2a58c8"),     # sapphire
}

const BLACKLETTER := preload("res://assets/fonts/PirataOne-Regular.ttf")
const SERIF := preload("res://assets/fonts/IMFellEnglish-Regular.ttf")
const GLASS_SHADER := preload("res://ui/shaders/stained_glass.gdshader")
const GRAIN_SHADER := preload("res://ui/shaders/grain.gdshader")


static func make_theme() -> Theme:
	var th := Theme.new()
	th.default_font = SERIF
	th.default_font_size = 32
	th.set_color("font_color", "Label", C_IVORY)
	# Wax-seal buttons.
	th.set_font("font", "Button", BLACKLETTER)
	th.set_font_size("font_size", "Button", 44)
	th.set_color("font_color", "Button", C_GOLD)
	th.set_color("font_hover_color", "Button", C_GOLD)
	th.set_color("font_pressed_color", "Button", C_BONE)
	th.set_color("font_focus_color", "Button", C_GOLD)
	th.set_constant("outline_size", "Button", 6)
	th.set_color("font_outline_color", "Button", C_CRIMSON_DARK)
	th.set_stylebox("normal", "Button", seal(C_CRIMSON))
	th.set_stylebox("hover", "Button", seal(C_CRIMSON.lightened(0.08)))
	th.set_stylebox("pressed", "Button", seal(C_CRIMSON_DARK))
	th.set_stylebox("disabled", "Button", seal(C_CRIMSON_DARK.darkened(0.3)))
	th.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	return th


## Wax seal: round-ish blob of crimson with a darker pressed rim and a drop shadow.
static func seal(col: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = col
	s.set_corner_radius_all(60)
	s.border_color = col.darkened(0.35)
	s.set_border_width_all(6)
	s.shadow_color = Color(0, 0, 0, 0.55)
	s.shadow_size = 6
	s.shadow_offset = Vector2(0, 5)
	s.content_margin_left = 22
	s.content_margin_right = 22
	s.content_margin_top = 6
	s.content_margin_bottom = 10
	s.anti_aliasing = false
	return s


## Manuscript page: parchment (light) or dark vellum, oxblood border. Gold inner rule drawn by Frame.
static func page(light: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = C_PARCHMENT if light else Color("221612")
	s.border_color = C_OXBLOOD
	s.set_border_width_all(8)
	s.set_corner_radius_all(4)
	s.shadow_color = Color(0, 0, 0, 0.6)
	s.shadow_size = 10
	s.content_margin_left = 28
	s.content_margin_right = 28
	s.content_margin_top = 22
	s.content_margin_bottom = 22
	s.anti_aliasing = false
	return s


static func grain(amount := 0.08) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = GRAIN_SHADER
	m.set_shader_parameter("amount", amount)
	return m


static func label(text: String, size: int, color: Color, blackletter := false, outline := 0) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_override("font", BLACKLETTER if blackletter else SERIF)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if outline > 0:
		l.add_theme_constant_override("outline_size", outline)
		l.add_theme_color_override("font_outline_color", C_BLACK)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Body text (IM Fell) with every number set in Pirata One: Fell only has old-style figures,
## and numbers must read at a glance. Returns a centred, wrapping RichTextLabel.
static func body(text: String, size: int, color: Color, outline := 0) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.add_theme_font_override("normal_font", SERIF)
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_color_override("default_color", color)
	if outline > 0:
		r.add_theme_constant_override("outline_size", outline)
		r.add_theme_color_override("font_outline_color", C_BLACK)
	set_body(r, text)
	return r


static func set_body(r: RichTextLabel, text: String) -> void:
	r.text = "[center]%s[/center]" % numbers(text)


static func numbers(text: String) -> String:
	# Skip digits inside bbcode tags (colour hex, font_size=) and inside words.
	return RegEx.create_from_string("(?<![#=\\w])(x?[+-]?\\d+(?:\\.\\d+)?%?)").sub(text, "[font=%s]$1[/font]" % BLACKLETTER.resource_path, true)
