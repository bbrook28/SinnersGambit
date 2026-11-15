## A Sin's temptation portrait as layers (living glass stage 2, Gluttony first): background glass,
## body, arm and goblet, loose dice, baked by tools/bake_layers.gd into
## assets/art/runtime/sins/<sin>_layers/. Rendered into this viewport; the offer screen shows its
## texture through the flare shader like any window, so the glass light and flare still apply.
## At rest he breathes (the body swells from its base, the arm rides with it, the dice bob).
## gesture(): the offer. He tips the goblet toward his mouth and the dice drop in, then the dice
## come back to his fist. Reduce Motion holds him still and skips the gesture.
extends SubViewport

const Tuning = preload("res://ui/tuning.gd")
const DIR := "res://assets/art/runtime/sins/%s_layers/"

var body: Sprite2D
var arm: Sprite2D
var dice: Array[Sprite2D] = []
var dice_home: Array[Vector2] = []
var dice_scale: Array[float] = []
var mouth := Vector2.ZERO
var t := 0.0
var gesture_t := -1.0
var arm_y := 0.0


static func has_layers(sin_name: String) -> bool:
	return ResourceLoader.exists((DIR % sin_name.to_lower()) + "layout.json")


func setup(sin_name: String) -> void:
	var dir := DIR % sin_name.to_lower()
	var layout: Dictionary = load(dir + "layout.json").data
	var bg_tex: Texture2D = load(dir + "bg.png")
	size = Vector2i(bg_tex.get_size())
	disable_3d = true
	transparent_bg = false
	render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var bg := Sprite2D.new()
	bg.texture = bg_tex
	bg.centered = false
	add_child(bg)
	# Body: breathes from the middle of its base.
	body = Sprite2D.new()
	body.texture = load(dir + "body.png")
	body.centered = false
	body.position = Vector2(size.x / 2.0, size.y)
	body.offset = -body.position
	add_child(body)
	# Arm: pivots at the shoulder (off the frame, lower left), placed where the portrait has it.
	var a: Dictionary = layout.arm
	var pivot := Vector2(a.pivot[0], a.pivot[1])
	arm = Sprite2D.new()
	arm.texture = load(dir + "arm.png")
	arm.centered = false
	arm.scale = Vector2.ONE * float(a.scale)
	arm.offset = -pivot
	arm.position = Vector2(a.offset[0] - float(layout.window_x), a.offset[1]) + pivot * float(a.scale)
	add_child(arm)
	arm_y = arm.position.y
	for d in layout.dice:
		var s := Sprite2D.new()
		s.texture = load(dir + d.file)
		s.scale = Vector2.ONE * float(d.scale)
		s.position = Vector2(d.centre[0], d.centre[1])
		add_child(s)
		dice.append(s)
		dice_home.append(s.position)
		dice_scale.append(float(d.scale))
	mouth = Vector2(layout.get("mouth", [490, 440])[0], layout.get("mouth", [490, 440])[1])


## The offer: tip the goblet to the mouth, drop the dice in.
func gesture() -> void:
	if not Tuning.reduce_motion:
		gesture_t = 0.0


func _process(delta: float) -> void:
	if body == null or Tuning.reduce_motion:
		return
	t += delta
	var breath := sin(t * TAU / Tuning.PORTRAIT_BREATH_PERIOD)
	body.scale = Vector2(1.0 + Tuning.PORTRAIT_BREATH * 0.5 * breath, 1.0 + Tuning.PORTRAIT_BREATH * breath)
	var tip := 0.0
	var drop := 0.0   # 0..1: the dice falling into the mouth
	var back := 0.0   # 0..1: the dice returning to the fist
	if gesture_t >= 0.0:
		gesture_t += delta
		var g := gesture_t / Tuning.PORTRAIT_GESTURE_TIME
		tip = sin(clampf(g, 0.0, 1.0) * PI)  # up to the mouth and back
		drop = smoothstep(0.15, 0.6, g)
		back = smoothstep(0.75, 1.0, g)
		if g >= 1.0:
			gesture_t = -1.0
	arm.rotation = deg_to_rad(Tuning.PORTRAIT_ARM_SWAY * breath + Tuning.PORTRAIT_GESTURE_DEG * tip)
	# The arm rides the breath: its shoulder sits on the body's edge.
	arm.position.y = arm_y - Tuning.PORTRAIT_BREATH * breath * size.y * 0.15
	for i in dice.size():
		var stagger := clampf(drop * 1.6 - i * 0.3, 0.0, 1.0)
		var bob := Vector2(0.0, 4.0 * sin(t * 2.2 + i * 1.7))
		var p := dice_home[i].lerp(mouth, stagger) + bob * (1.0 - stagger)
		dice[i].position = p
		dice[i].rotation = stagger * (1.5 + i)
		var vanish := (1.0 - stagger * 0.7) if back == 0.0 else lerpf(0.3, 1.0, back)
		dice[i].scale = Vector2.ONE * dice_scale[i] * vanish
		dice[i].modulate.a = (1.0 - stagger) if back == 0.0 else back
		if back > 0.0:
			dice[i].position = dice_home[i] + Vector2(30.0, 60.0) * (1.0 - back)
			dice[i].rotation = 0.0

