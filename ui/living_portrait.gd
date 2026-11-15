## A Sin's temptation portrait as layers (living glass stage 2, Gluttony first): background glass,
## body, arm and goblet, loose dice, baked by tools/bake_layers.gd into
## assets/art/runtime/sins/<sin>_layers/. Rendered into this viewport; the offer screen shows its
## texture through the flare shader like any window, so the glass light and flare still apply.
## While the offer is open he breathes (the body swells from its base, the arm rides it, the dice
## bob) and the goblet tips a little toward his mouth and back.
## accept(): he gulps the dice (they fly into his mouth and are gone) and holds the empty mouth.
## refuse(): the goblet lowers. The offer screen dims the glass itself. Dice never come back within
## an offer. Reduce Motion holds him still; accept() then just takes the dice away.
extends SubViewport

const Tuning = preload("res://ui/tuning.gd")
const DIR := "res://assets/art/runtime/sins/%s_layers/"

var body: Sprite2D
var arm: Sprite2D
var dice: Array[Sprite2D] = []
var dice_home: Array[Vector2] = []
var dice_scale: Array[float] = []
var mouth := Vector2.ZERO
var arm_y := 0.0
var t := 0.0
var state := ""      # "", "accept" or "refuse"
var state_t := 0.0   # seconds since accept() or refuse()
var tip_from := 0.0  # the arm's lift when the answer came, so it moves on from there


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
	var m: Array = layout.get("mouth", [490, 440])
	mouth = Vector2(m[0], m[1])


## Accepted: gulp the dice. Returns how long to hold the screen (the gulp, then the empty mouth).
func accept() -> float:
	_answer("accept")
	if Tuning.reduce_motion:
		for d in dice:
			d.visible = false
	return Tuning.PORTRAIT_GULP_TIME + Tuning.PORTRAIT_EMPTY_HOLD


## Refused: lower the goblet. Returns how long to hold the screen.
func refuse() -> float:
	_answer("refuse")
	return Tuning.PORTRAIT_REFUSE_TIME


func _answer(s: String) -> void:
	if state == "":
		tip_from = _idle_tip()
		state = s
		state_t = 0.0


## The goblet's slight tip while the offer is open, 0..1.
func _idle_tip() -> float:
	return 0.5 - 0.5 * cos(t * TAU / Tuning.PORTRAIT_IDLE_TIP_PERIOD)


func _process(delta: float) -> void:
	if body == null or Tuning.reduce_motion:
		return
	t += delta
	var breath := sin(t * TAU / Tuning.PORTRAIT_BREATH_PERIOD)
	body.scale = Vector2(1.0 + Tuning.PORTRAIT_BREATH * 0.5 * breath, 1.0 + Tuning.PORTRAIT_BREATH * breath)
	var deg := Tuning.PORTRAIT_IDLE_TIP_DEG * _idle_tip()
	var gulp := 0.0  # 0..1: the dice flying into his mouth
	if state != "":
		state_t += delta
	if state == "accept":
		# Up to the mouth for the gulp, then slowly back down while he holds the empty mouth.
		var up := smoothstep(0.0, 0.35, state_t / Tuning.PORTRAIT_GULP_TIME)
		var down := smoothstep(0.0, 1.0, (state_t - Tuning.PORTRAIT_GULP_TIME) / Tuning.PORTRAIT_EMPTY_HOLD)
		deg = lerpf(Tuning.PORTRAIT_IDLE_TIP_DEG * tip_from, Tuning.PORTRAIT_GESTURE_DEG, up)
		deg = lerpf(deg, 0.0, down * 0.6)
		gulp = smoothstep(0.1, 1.0, state_t / Tuning.PORTRAIT_GULP_TIME)
	elif state == "refuse":
		var k := smoothstep(0.0, 1.0, state_t / (Tuning.PORTRAIT_REFUSE_TIME * 0.7))
		deg = lerpf(Tuning.PORTRAIT_IDLE_TIP_DEG * tip_from, -Tuning.PORTRAIT_REFUSE_DEG, k)
	arm.rotation = deg_to_rad(Tuning.PORTRAIT_ARM_SWAY * breath + deg)
	# The arm rides the breath: its shoulder sits on the body's edge.
	arm.position.y = arm_y - Tuning.PORTRAIT_BREATH * breath * size.y * 0.15
	for i in dice.size():
		var k := clampf(gulp * 1.6 - i * 0.3, 0.0, 1.0)  # staggered, top die first
		var bob := Vector2(0.0, 4.0 * sin(t * 2.2 + i * 1.7))
		dice[i].position = dice_home[i].lerp(mouth, k * k) + bob * (1.0 - k)
		dice[i].rotation = k * (1.5 + i)
		dice[i].scale = Vector2.ONE * dice_scale[i] * (1.0 - 0.7 * k)
		dice[i].modulate.a = 1.0 - smoothstep(0.6, 1.0, k)
