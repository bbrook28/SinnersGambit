## SpriteCook art (Docs/ArtDirection.md § Approved art) and helpers to frame it.
## Phone units: the viewport is 1080 wide = 393pt, so 1pt = 2.75px (PT).
extends RefCounted

const PT := 1080.0 / 393.0
const Tuning = preload("res://ui/tuning.gd")

const UI := "res://assets/art/ui/"
const RT := "res://assets/art/runtime/"
const FLARE := preload("res://ui/shaders/flare.gdshader")
const TINT := preload("res://ui/shaders/tint.gdshader")
const WAX_GLINT := preload("res://ui/shaders/wax_glint.gdshader")
const GOLD_SHIMMER := preload("res://ui/shaders/gold_shimmer.gdshader")
const PAGE_LIGHT := preload("res://ui/shaders/page_light.gdshader")

const BG := preload("res://assets/art/runtime/bg.png")
const LEATHER := preload("res://assets/art/runtime/leather.png")
const STRIKE_EMPTY := preload("res://assets/art/runtime/strike_empty.png")
const STRIKE_STRUCK := preload("res://assets/art/runtime/strike_struck.png")
const TRAY := preload("res://assets/art/ui/dice_tray.png")
const BANNER := preload("res://assets/art/ui/turn_banner.png")
const PAGE := preload("res://assets/art/runtime/page.png")  # 1600x900; corners hold the marginalia (PAGE_MARGINS)
const PAGE_MARGINS := [262, 252, 262, 262]
## Corner figures cut from the page (tools/bake_art.gd prints these): texture, top-left in page px,
## the page corner they hang from, pivot (fraction of the sprite) they rock around.
const MARGINALIA := {
	"jester": [preload("res://assets/art/runtime/marginalia/jester.png"), Vector2(36, 42), Vector2(0, 0), Vector2(0.4, 1.0)],
	"pennant": [preload("res://assets/art/runtime/marginalia/pennant.png"), Vector2(1378, 27), Vector2(1, 0), Vector2(0.12, 1.0)],
	"skeleton": [preload("res://assets/art/runtime/marginalia/skeleton.png"), Vector2(1378, 676), Vector2(1, 1), Vector2(0.6, 1.0)],
}
const LOG_STRIP := preload("res://assets/art/ui/log_strip.png")
const YOU_TAB := preload("res://assets/art/ui/you_tab.png")
const ICON_DIE := preload("res://assets/art/ui/icon_die.png")
## Painted wax seal: normal, pressed, cracked (used as disabled). Same art for big and small seals.
const SEAL := [preload("res://assets/art/runtime/seals/normal.png"), preload("res://assets/art/runtime/seals/pressed.png"), preload("res://assets/art/runtime/seals/cracked.png")]
const SEAL_L := SEAL
const SEAL_S := SEAL
const THROW_HAND := preload("res://assets/art/runtime/throw_hand.png")
const SEAL_FAST := preload("res://assets/art/ui/seal_fast.png")


## Gold-leaf blackletter numeral 1-9 (null outside that range).
static func numeral(n: int) -> Texture2D:
	return load(RT + "seals/n%d.png" % n) if n >= 1 and n <= 9 else null


static func window(sin_name: String) -> Texture2D:
	return load(RT + "sins/%s.png" % sin_name.to_lower())


static func sigil_path(sin_name: String) -> String:
	return RT + "sigils/%s.png" % sin_name.to_lower()


static func dropcap(letter: String) -> Texture2D:
	var path := UI + "dropcap_%s.png" % letter.to_lower()
	return load(path) if ResourceLoader.exists(path) else null


## A 9-slice drawn at `scale`, so thick painted borders can sit on small panels.
## Returns a Control that fills its parent's slot; the NinePatchRect tracks its size.
static func framed(tex: Texture2D, margins: Array, scale := 1.0, center := true) -> Control:
	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var np := NinePatchRect.new()
	np.texture = tex
	np.patch_margin_left = margins[0]
	np.patch_margin_top = margins[1]
	np.patch_margin_right = margins[2]
	np.patch_margin_bottom = margins[3]
	np.draw_center = center
	np.scale = Vector2(scale, scale)
	np.mouse_filter = Control.MOUSE_FILTER_IGNORE
	np.use_parent_material = true  # a tint/flare set on the holder reaches the patch
	holder.add_child(np)
	holder.resized.connect(func(): np.size = holder.size / scale)
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	return holder


static func flare_material() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = FLARE
	return m


static func tint_material(c: Color) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = TINT
	m.set_shader_parameter("tint", c)
	return m


## Button skin from [normal, pressed, disabled] textures. `mod` darkens or recolours the wax.
static func skin(b: Button, texs: Array, mod := Color.WHITE, margins := 0) -> void:
	var states := {"normal": [texs[0], mod], "hover": [texs[0], mod.lightened(0.08)], "focus": [texs[0], mod],
		"pressed": [texs[1], mod], "disabled": [texs[2], mod]}
	for st in states:
		var s := StyleBoxTexture.new()
		s.texture = states[st][0]
		s.modulate_color = states[st][1]
		s.texture_margin_left = margins
		s.texture_margin_right = margins
		s.texture_margin_top = margins
		s.texture_margin_bottom = margins
		b.add_theme_stylebox_override(st, s)


static func _material(shader: Shader, params: Dictionary) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = shader
	for k in params:
		m.set_shader_parameter(k, params[k])
	return m


## Wax seal: a slow specular sweep. phase staggers seals in a row.
static func glint_material(phase: float) -> ShaderMaterial:
	return _material(WAX_GLINT, {"phase": phase, "period": Tuning.GLINT_PERIOD, "strength": Tuning.GLINT_STRENGTH})


## Gold-leaf numeral: shimmer across the highlights.
static func shimmer_material(phase: float) -> ShaderMaterial:
	return _material(GOLD_SHIMMER, {"phase": phase, "period": Tuning.SHIMMER_PERIOD, "strength": Tuning.SHIMMER_STRENGTH})


static func page_light_material() -> ShaderMaterial:
	return _material(PAGE_LIGHT, {"strength": Tuning.PAGE_LIGHT, "flicker": Tuning.CANDLE_FLICKER})
