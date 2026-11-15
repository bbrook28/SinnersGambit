## Living glass must not repaint the art (ui/shaders/flare.gdshader): each of the seven Sin windows
## and every temptation portrait, drawn at rest through the shader, must match its source PNG.
## Fails if the mean difference in any colour channel is over 5%, or an opaque pixel turns
## transparent. "At rest" twice: motion held still, and moving (the light band and swell at a few
## moments, which add brightness only). Needs a renderer, so windowed:
## godot --path . --script res://tests/glass_check.gd
extends SceneTree

const Art = preload("res://ui/art.gd")
const SINS := ["pride", "greed", "wrath", "envy", "gluttony", "lust", "sloth"]
const MAX_MEAN := 0.05

var fails: Array[String] = []
var checks := 0


func _initialize() -> void:
	await process_frame
	var paths: Array[String] = []
	for s in SINS:
		paths.append("res://assets/art/runtime/sins/%s.png" % s)
		var p := "res://assets/art/runtime/sins/%s_portrait.png" % s
		if ResourceLoader.exists(p):
			paths.append(p)
	for path in paths:
		await _check(path, 0.0, 0.0)
		for t in [1.0, 4.0, 7.5]:  # the moving light at a few points of its ~9 s sweep
			await _check(path, 1.0, t)
	if fails.is_empty():
		print("GLASS PASSED: %d renders" % checks)
	else:
		for f in fails:
			print("  " + f)
		print("GLASS FAILED (%d) of %d renders" % [fails.size(), checks])
	quit(1 if fails.size() else 0)


func _check(path: String, motion: float, at: float) -> void:
	var src := Image.load_from_file(ProjectSettings.globalize_path(path))
	src.convert(Image.FORMAT_RGBA8)
	var vp := SubViewport.new()
	vp.size = src.get_size()
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var tr := TextureRect.new()
	tr.texture = load(path)
	tr.size = Vector2(src.get_size())
	tr.material = null if OS.has_environment("GLASS_PLAIN") else Art.flare_material()
	if tr.material:
		tr.material.set_shader_parameter("motion", motion)
	vp.add_child(tr)
	root.add_child(vp)
	# TIME can't be set, so the moving cases shift the sweep through phase instead.
	if tr.material:
		tr.material.set_shader_parameter("phase", fmod(at * 0.11, 1.0))
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var got := vp.get_texture().get_image()
	got.convert(Image.FORMAT_RGBA8)
	if OS.has_environment("GLASS_DUMP"):
		got.save_png(OS.get_environment("GLASS_DUMP") + "/" + path.get_file().get_basename() + "_" + str(int(motion)) + ".png")
	vp.queue_free()
	checks += 1
	var sum := Vector3.ZERO
	var n := 0
	var lost := 0
	for y in range(0, src.get_height(), 2):
		for x in range(0, src.get_width(), 2):
			var a := src.get_pixel(x, y)
			if a.a < 0.9:
				continue
			var b := got.get_pixel(x, y)
			if b.a < 0.9:
				lost += 1
			sum += Vector3(absf(a.r - b.r), absf(a.g - b.g), absf(a.b - b.b))
			n += 1
	var mean := sum / maxf(1.0, n)
	var label := "%s (%s)" % [path.get_file(), "still" if motion == 0.0 else "moving, %.1f s" % at]
	if maxf(mean.x, maxf(mean.y, mean.z)) > MAX_MEAN:
		fails.append("%s: mean channel difference R %.3f G %.3f B %.3f" % [label, mean.x, mean.y, mean.z])
	if lost > 0:
		fails.append("%s: %d opaque pixels turned transparent" % [label, lost])
	print("%s: R %.3f G %.3f B %.3f, lost %d" % [label, mean.x, mean.y, mean.z, lost])
