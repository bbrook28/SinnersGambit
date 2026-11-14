## Sound for every beat. The director's phase helpers call play() (lift, whoosh, impact,
## count-up ticks), so every beat gets sound without its own code. Volumes and limits:
## ui/tuning.gd (VOL, SFX_*). Sounds: Kenney CC0 packs in assets/audio (licences there).
## Silent while a beat is being skipped, so a tap never fires a pile of sounds at once.
extends Node

const T = preload("res://ui/tuning.gd")
const DIR := "res://assets/audio/"

## Sound name -> files (one picked at random each time). Volumes per name: Tuning.VOL.
const SETS := {
	"lift": ["card-place-1", "card-place-2"],
	"shake": ["dice-shake-1", "dice-shake-2"],
	"whoosh": ["card-slide-1", "card-slide-2", "card-slide-3", "card-slide-4"],
	"impact_light": ["impactWood_light_000", "impactWood_light_001", "impactWood_light_002"],
	"impact": ["impactWood_medium_000", "impactWood_medium_001"],
	"impact_heavy": ["impactWood_heavy_000", "impactWood_heavy_001"],
	"tick": ["tick_001", "tick_002", "tick_004"],
	"throw": ["dice-throw-1", "dice-throw-2", "dice-throw-3"],
	"throw_one": ["die-throw-1", "die-throw-2"],
	"seal": ["impactSoft_medium_000", "impactSoft_medium_001"],
	"plaque": ["click_001", "click_002"],
	"nail": ["impactMetal_medium_000", "impactMetal_medium_001"],
	"nail_last": ["impactMetal_heavy_000", "impactMetal_heavy_001"],
	"bell": ["impactBell_heavy_000", "impactBell_heavy_001"],
	"crack": ["impactGlass_heavy_000", "impactGlass_heavy_001"],
	"coins": ["chips-stack-1", "chips-stack-2", "chips-stack-3"],
	"coins_small": ["chips-collide-1", "chips-collide-2"],
	"buy": ["chip-lay-1", "chip-lay-2"],
	"banner_in": ["card-fan-1", "card-fan-2"],
	"banner_out": ["card-slide-3", "card-slide-4"],
	"glass": ["glass_001", "glass_002", "glass_003"],
	"glass_light": ["impactGlass_light_000", "impactGlass_light_001"],
	"hit": ["impactPunch_medium_000", "impactPunch_medium_001"],
	"stamp": ["impactSoft_heavy_000", "impactSoft_heavy_001"],
	"card": ["chips-handle-1", "chips-handle-2"],
	"win": ["confirmation_002"],
}

var q   # ui/action_queue.gd (to stay quiet while skipping)
var _streams := {}      # name -> Array[AudioStream]
var _last := {}         # name -> time last played (msec)
var _voices: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	for key in SETS:
		var list: Array[AudioStream] = []
		for f in SETS[key]:
			var s: AudioStream = load(DIR + f + ".ogg")
			if s:
				list.append(s)
		_streams[key] = list
	for i in T.SFX_VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_voices.append(p)


## name: a key of SETS. k in [0, 1] adds up to +6 dB (bigger results sound bigger).
## pitch: 1.0 = as recorded (a little random jitter is added).
func play(name: String, k := 0.5, pitch := 1.0, force := false) -> void:
	if T.MUTE or T.muted or not _streams.has(name) or _streams[name].is_empty():
		return
	if not force and q and q.skipping():
		return
	var now := Time.get_ticks_msec()
	var gap: float = T.TICK_GAP if name == "tick" else T.SFX_GAP
	if now - int(_last.get(name, -100000)) < int(gap * 1000.0):
		return
	_last[name] = now
	var p := _voices[_next]
	_next = (_next + 1) % _voices.size()
	var list: Array = _streams[name]
	p.stream = list[randi() % list.size()]
	p.volume_db = T.VOL_MASTER + float(T.VOL.get(name, -6.0)) + 6.0 * (clampf(k, 0.0, 1.0) - 0.5)
	p.pitch_scale = pitch * randf_range(1.0 - T.PITCH_JITTER, 1.0 + T.PITCH_JITTER)
	p.play()


## An impact sized by k: light, medium or heavy wood on the desk.
func impact(k: float) -> void:
	play("impact_light" if k < 0.35 else ("impact" if k < 0.7 else "impact_heavy"), k)


## One count-up tick. t in [0, 1] = how far through the count; ticks rise in pitch.
func tick(t: float) -> void:
	play("tick", 0.5, lerpf(T.TICK_PITCH.x, T.TICK_PITCH.y, clampf(t, 0.0, 1.0)))
