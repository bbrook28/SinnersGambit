## Records one beat of a fixture as a short clip for motion review: every frame at a fixed 60 fps
## (--fixed-fps, so game time never depends on the machine) from the moment the beat starts, scaled
## to 720 px wide, joined by ffmpeg. At most 5 s.
## godot --path . --fixed-fps 60 --script res://tools/clip.gd -- <fixture> [beat] [seconds] [size] [out.mp4]
##   beat     a fixture moment (tools/fixture.gd), "-" for the fixture's own
##   seconds  default 4, capped at 5 (Ben: clips 5 s or less)
##   out      default build/clips/<fixture>_<beat>.mp4
## Needs ffmpeg on PATH.
extends SceneTree

const Fixture = preload("res://tools/fixture.gd")
const FPS := 60
const WIDTH := 720


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.is_empty():
		print("usage: clip.gd -- <fixture> [beat] [seconds] [size] [out.mp4]")
		quit(1)
		return
	var name: String = a[0]
	var fx := Fixture.read(name)
	var beat: String = a[1] if a.size() > 1 and a[1] != "-" else str(fx.get("moment", "screen"))
	var secs: float = minf(5.0, float(a[2])) if a.size() > 2 else 4.0
	var size: String = a[3] if a.size() > 3 else "std"
	var out: String = a[4] if a.size() > 4 else ProjectSettings.globalize_path("res://build/clips/%s_%s.mp4" % [name, beat])
	var frames_dir := ProjectSettings.globalize_path("res://build/clips/_frames/")
	DirAccess.make_dir_recursive_absolute(frames_dir)
	for f in DirAccess.get_files_at(frames_dir):
		DirAccess.remove_absolute(frames_dir + f)
	var px: Array = Fixture.SIZES[size].px
	await process_frame
	DisplayServer.window_set_size(Vector2i(px[0], px[1]))
	root.size = Vector2i(px[0], px[1])
	await process_frame
	if fx.has("moment"):
		fx["moment"] = beat
	fx["hold"] = 0.0
	# Grab frames from the moment's start: a callback on every drawn frame once it's set.
	var shots := [0]
	var total := roundi(secs * FPS)
	var grab := func():
		if Fixture.moment_frame < 0 and fx.get("screen", "") == "game":
			return
		if shots[0] >= total:
			return
		var im := root.get_texture().get_image()
		im.resize(WIDTH, roundi(WIDTH * float(im.get_height()) / im.get_width()) / 2 * 2, Image.INTERPOLATE_BILINEAR)
		im.save_jpg(frames_dir + "%04d.jpg" % shots[0], 0.92)
		shots[0] += 1
	Fixture.moment_frame = -1
	RenderingServer.frame_post_draw.connect(grab)
	var main = await Fixture.apply(self, fx, size)
	while shots[0] < total:
		await process_frame
	RenderingServer.frame_post_draw.disconnect(grab)
	main.queue_free()
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	var log := []
	var code := OS.execute("ffmpeg", ["-y", "-loglevel", "error", "-framerate", str(FPS), "-i", frames_dir + "%04d.jpg",
		"-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "22", out], log, true)
	print("CLIP %s %s: %d frames, %.1f s -> %s%s" % [name, beat, shots[0], shots[0] / float(FPS), out, "" if code == 0 else " (ffmpeg failed: %s)" % str(log)])
	quit(code)
