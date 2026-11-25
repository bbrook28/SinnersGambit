## Screenshots of the step 1 pass-and-play screen at phone size, for Ben. Needs a window (not --headless):
## godot --path . --resolution 1080x2340 --script res://tools/table_shots.gd   ->  build/table_shots/*.png
extends SceneTree

const TableScreen = preload("res://ui/table_screen.gd")

var h
var n := 0
var dir := "table_shots"   # build/<dir>; pass -- dir=<name> to keep a second screen shape beside the first


class Faces:
	var queue: Array = []
	func _init(f: Array) -> void:
		queue = f.duplicate()
	func randi_range(_a: int, _b: int) -> int:
		return queue.pop_front()


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("dir="):
			dir = a.substr(4)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/" + dir))
	for f in DirAccess.get_files_at("res://build/" + dir):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("res://build/%s/%s" % [dir, f]))
	h = TableScreen.new()
	# P1 scores; P2 into Purgatory; P3 rolls 4 dice (one lent); P4; P1; P2 stays in; then a win
	h.rng = Faces.new([4, 5, 1,  1, 2, 3,  6, 4, 2, 5,  5, 5, 3,  6, 6, 1,  2, 6, 6,  6, 6, 3])
	h.sins = ["wrath", "greed", "lust", "pride"]
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(h)
	await _shot("pass_the_phone")
	tap("ready")
	await _shot("roll")
	tap("roll")
	await _shot("gambit")
	tap("buy")
	await _shot("bought_a_die")
	tap("points")
	await _shot("give_points_choose")
	tap("other2")
	tap("p10")
	tap("p10")
	await _shot("give_points_ready")
	tap("offer")
	await _shot("agree")
	tap("agree")
	await _shot("agreed")
	tap("lend")
	tap("other2")
	await _shot("lend_a_die")
	tap("offer")
	tap("agree")
	tap("die")
	tap("ask")
	tap("other2")
	await _shot("ask_for_a_die")
	tap("offer")
	await _shot("asked")
	tap("refuse")
	await _shot("refused")
	tap("pass")
	tap("ready")
	tap("roll")
	await _shot("into_purgatory")
	tap("pass")
	await _shot("pass_to_player_3")
	tap("ready")
	await _shot("roll_with_a_lent_die")
	tap("roll")
	tap("points")
	await _shot("purgatory_player_cannot_be_chosen")
	tap("back")
	tap("pass")
	tap("ready")
	tap("roll")
	tap("buy")
	tap("pass")
	tap("ready")
	tap("roll")
	tap("pass")
	await _shot("pass_to_a_player_in_purgatory")
	tap("ready")
	await _shot("roll_in_purgatory")
	tap("roll")
	await _shot("stays_in_purgatory")
	tap("pass")
	h.s.seats[2].points = 2890
	h.s.seats[0].points = 2450
	h.s.seats[3].points = 1980
	h.s.seats[3].dice = 9
	h.s.seats[3].last_roll = [6, 6, 5, 4, 4, 3, 2, 1, 1]
	h.s.seats[3].last_score = 250
	h._refresh()
	tap("ready")
	await _shot("late_in_the_match")
	tap("roll")
	await _shot("winner")
	quit(0)


func tap(key: String) -> void:
	if not h.btn.has(key) or h.btn[key].disabled:
		printerr("no button to tap: ", key)
		quit(1)
		return
	h.btn[key].pressed.emit()


func _shot(name: String) -> void:
	for i in 6:
		await process_frame
	n += 1
	var img := root.get_texture().get_image()
	var path := "res://build/%s/%02d_%s.png" % [dir, n, name]
	img.save_png(ProjectSettings.globalize_path(path))
	print("shot ", path, " ", img.get_size())
