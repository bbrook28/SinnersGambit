## Synthesizes the "outcome bell" family (Docs/AudioStyle.md) into assets/audio/synth_*.wav.
## godot --headless --path . --script res://tools/bake_audio.gd
## Deterministic (fixed seed). Mono 16-bit 44.1 kHz, 5 ms attack, peak normalised to -1 dBFS.
extends SceneTree

const RATE := 44100
const OUT := "res://assets/audio/"
## Church-bell partials: [ratio to the strike note, level, decay time in s at a 1 s base].
const BELL := [[0.5, 0.55, 1.6], [1.0, 1.0, 1.0], [1.19, 0.6, 0.8], [1.5, 0.35, 0.6],
	[2.0, 0.5, 0.5], [2.52, 0.25, 0.35], [3.0, 0.2, 0.28], [4.17, 0.12, 0.2]]

var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.seed = 1666
	# Count-up pings: tiny bright bells, two tunings so repeats differ.
	_write("synth_ping_1", _bell(PackedFloat32Array(), 0.0, 1760.0, 0.18, 0.35, 0.3))
	_write("synth_ping_2", _bell(PackedFloat32Array(), 0.0, 1975.0, 0.18, 0.35, 0.3))
	# Bank: two strikes a fifth apart.
	for v in 2:
		var f := 523.25 * (1.0 if v == 0 else 1.0595)
		var b := _bell(PackedFloat32Array(), 0.0, f, 1.4, 2.2, 0.5)
		_write("synth_bank_%d" % (v + 1), _bell(b, 0.12, f * 1.5, 1.2, 2.2, 0.5))
	# Bust: one low toll with a sub-octave hum under it.
	var toll := _bell(PackedFloat32Array(), 0.0, 110.0, 3.2, 4.4, 0.9)
	_write("synth_toll", _sine(toll, 0.0, 55.0, 0.5, 2.5, 4.4))
	# Third Strike: a smaller toll.
	_write("synth_toll_small", _bell(PackedFloat32Array(), 0.0, 196.0, 1.6, 2.2, 0.7))
	# Ability / freed: a high cluster, staggered.
	for v in 2:
		var c := PackedFloat32Array()
		var notes := [1318.5, 1568.0, 1975.5] if v == 0 else [1174.7, 1480.0, 1760.0]
		for i in 3:
			c = _bell(c, 0.06 * i, notes[i], 0.7, 1.6, 0.4)
		_write("synth_chime_%d" % (v + 1), c)
	# Win: a minor organ chord swelling under a bell.
	var win := PackedFloat32Array()
	for f in [220.0, 261.63, 329.63, 440.0]:
		win = _organ(win, f, 0.35, 2.4, 1.1, 3.6)
	_write("synth_win", _bell(win, 0.0, 440.0, 2.0, 3.6, 0.6))
	print("audio baked")
	quit()


## Adds a struck bell at `at` s: base frequency f, ring time `ring` (partial decays scale by it),
## total buffer length `len`, strike noise level `strike`.
func _bell(buf: PackedFloat32Array, at: float, f: float, ring: float, len: float, strike: float) -> PackedFloat32Array:
	buf = _fit(buf, len)
	var s0 := int(at * RATE)
	for p in BELL:
		var fr: float = f * p[0] * _rng.randf_range(0.998, 1.002)
		var beat: float = fr * 0.0015  # two close copies beat slowly, like a real casting
		var lvl: float = p[1]
		var tau: float = p[2] * ring
		for i in range(s0, buf.size()):
			var t := float(i - s0) / RATE
			var env := exp(-t / tau) * minf(1.0, t / 0.005)
			buf[i] += lvl * env * 0.5 * (sin(TAU * fr * t) + sin(TAU * (fr + beat) * t))
	# Strike: a short dark noise burst (one-pole low-pass).
	var y := 0.0
	for i in range(s0, mini(buf.size(), s0 + int(0.03 * RATE))):
		var t := float(i - s0) / RATE
		y += 0.15 * (_rng.randf_range(-1.0, 1.0) - y)
		buf[i] += strike * y * exp(-t / 0.008)
	return buf


func _sine(buf: PackedFloat32Array, at: float, f: float, lvl: float, tau: float, len: float) -> PackedFloat32Array:
	buf = _fit(buf, len)
	var s0 := int(at * RATE)
	for i in range(s0, buf.size()):
		var t := float(i - s0) / RATE
		buf[i] += lvl * sin(TAU * f * t) * exp(-t / tau) * minf(1.0, t / 0.02)
	return buf


## An organ note: harmonic stack, slow swell `attack`, held to `hold`, released over `rel`.
func _organ(buf: PackedFloat32Array, f: float, attack: float, hold: float, rel: float, len: float) -> PackedFloat32Array:
	buf = _fit(buf, len)
	var harm := [[1, 0.6], [2, 0.35], [3, 0.2], [4, 0.12], [6, 0.06]]
	for i in buf.size():
		var t := float(i) / RATE
		var env := minf(1.0, t / attack)
		if t > hold:
			env *= exp(-(t - hold) / (rel / 3.0))
		var v := 0.0
		for h in harm:
			v += h[1] * sin(TAU * f * h[0] * t * (1.0 + 0.0008 * sin(TAU * 4.5 * t)))
		buf[i] += 0.25 * env * v
	return buf


func _fit(buf: PackedFloat32Array, len: float) -> PackedFloat32Array:
	var n := int(len * RATE)
	if buf.size() < n:
		var old := buf.size()
		buf.resize(n)
		for i in range(old, n):
			buf[i] = 0.0
	return buf


## Fades the last 15%, normalises to -1 dBFS and saves a 16-bit mono WAV.
func _write(name: String, buf: PackedFloat32Array) -> void:
	var n := buf.size()
	var fade := int(n * 0.15)
	var peak := 0.0001
	for i in n:
		if i > n - fade:
			buf[i] *= float(n - i) / fade
		peak = maxf(peak, absf(buf[i]))
	var g := db_to_linear(-1.0) / peak
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		data.encode_s16(i * 2, clampi(int(buf[i] * g * 32767.0), -32768, 32767))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	w.save_to_wav(ProjectSettings.globalize_path(OUT + name + ".wav"))
	print("%s %.2f s" % [name, float(n) / RATE])
