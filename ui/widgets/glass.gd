## Stained-glass panel: a shader-drawn window behind whatever children you add.
## Children stack on top of the glass (PanelContainer lays them all out full-size).
extends PanelContainer

const Style = preload("res://ui/style.gd")

var glass := ColorRect.new()
var _mat := ShaderMaterial.new()
var glow := 0.0:
	set(v):
		glow = v
		_mat.set_shader_parameter("glow", v)
var dim := 0.0:
	set(v):
		dim = v
		_mat.set_shader_parameter("dim", v)


func _init(tint: Color = Color.WHITE, pane := 70.0, seed_value := 0.0) -> void:
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_mat.shader = Style.GLASS_SHADER
	_mat.set_shader_parameter("tint", tint)
	_mat.set_shader_parameter("pane", pane)
	_mat.set_shader_parameter("seed", seed_value)
	glass.material = _mat
	glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glass)
	resized.connect(func(): _mat.set_shader_parameter("rect_size", size))


func set_tint(c: Color) -> void:
	_mat.set_shader_parameter("tint", c)
