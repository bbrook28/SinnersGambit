## Opens the game straight in a fixture's state (tools/fixture.gd) and saves a PNG. No playing through.
## godot --path . --fixed-fps 60 --script res://tools/show.gd -- <fixture> [size: se|std|max] [out.png]
## Default size std; default out Docs/review/shots/<fixture>_<size>.png.
extends SceneTree

const Fixture = preload("res://tools/fixture.gd")


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.is_empty():
		print("fixtures: ", ", ".join(Fixture.names()))
		quit(1)
		return
	var name: String = a[0]
	var size: String = a[1] if a.size() > 1 else "std"
	var out: String = a[2] if a.size() > 2 else ProjectSettings.globalize_path("res://Docs/review/shots/%s_%s.png" % [name, size])
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	var px: Array = Fixture.SIZES[size].px
	await process_frame
	DisplayServer.window_set_size(Vector2i(px[0], px[1]))
	root.size = Vector2i(px[0], px[1])
	await process_frame
	await process_frame
	var fx: Dictionary = Fixture.read(name)
	var main = await Fixture.apply(self, fx, size)
	await RenderingServer.frame_post_draw
	# A table fixture whose table didn't draw (a script that failed to load, a flag off) is an error,
	# never an image: the title screen under it would pass for a render.
	if str(fx.get("screen", "")) == "table":
		var t = main._overlay if main != null else null
		if t == null or not is_instance_valid(t) or not t.is_visible_in_tree() or t.get_child_count() == 0:
			printerr("SHOW FAILED %s %s: the table did not draw" % [name, size])
			quit(1)
			return
	var im := root.get_texture().get_image()
	im.save_png(out)
	print("SHOW %s %s %dx%d -> %s" % [name, size, im.get_width(), im.get_height(), out])
	main.queue_free()
	quit()
