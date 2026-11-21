## Screenshots of the dice screen at phone size, for Ben. Needs a window (not --headless):
## godot --path . --resolution 1080x2340 --script res://tools/shots.gd   ->  build/shots/*.png
extends SceneTree

const DiceScreen = preload("res://ui/dice_screen.gd")

var h
var n := 0


func _initialize() -> void:
	Engine.time_scale = 4.0
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/shots"))
	for f in DirAccess.get_files_at("res://build/shots"):
		DirAccess.remove_absolute("res://build/shots/" + f)
	DirAccess.remove_absolute("user://shots.cfg")
	h = DiceScreen.new()
	h.save_path = "user://shots.cfg"
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(h)
	await _shot("tutorial_intro")
	h._on_card_btn()
	await _shot("first_throw")
	h._on_seal(2)
	await settle()
	h._on_die(0)
	await _shot("pick_preview")
	h._on_keep()
	await settle()
	h._on_seal(2)
	await settle()
	await _shot("skull_card")
	h._on_card_btn()
	h._on_card_btn()
	await _shot("risk_seals")
	h._on_seal(3)
	await settle()
	h._on_die(0)
	await _shot("three_dice_preview")
	h._on_keep()
	await settle()
	h._on_card_btn()
	await _shot("free_play")
	# play the hand out and show the result
	var guard := 0
	while not h.s.over and guard < 40:
		guard += 1
		if h.overlay.visible:
			h._on_card_btn()
		elif h.phase == "keep":
			h._on_die(0)
			h._on_keep()
		else:
			h._on_seal(1 if h.s.skulls >= 2 else 2)
		await settle()
	var paid := false
	for i in 900:
		if not paid and h.counting and h.fx.get_child_count() > 2:
			paid = true
			await _shot("payout")
		if h.next_box.visible:
			break
		await process_frame
	await _shot("result_banner")
	Engine.time_scale = 1.0   # the opening at its real pace, caught while the window fills the screen
	h.hands = 2               # the next hand is Envy's, which opens at full screen
	h._on_next()
	await _shot("sin_opening")
	Engine.time_scale = 4.0
	for i in 120:
		if not h.opener.visible:
			break
		await process_frame
	await _shot("sin_window")
	h._on_help()
	await _shot("hand_ranking")
	DirAccess.remove_absolute("user://shots.cfg")
	quit(0)


func settle() -> void:
	for i in 600:
		await process_frame
		if h.phase != "anim":
			break


func _shot(name: String) -> void:
	for i in 6:
		await process_frame
	n += 1
	var img := root.get_texture().get_image()
	var path := "res://build/shots/%02d_%s.png" % [n, name]
	img.save_png(ProjectSettings.globalize_path(path))
	print("shot ", path, " ", img.get_size())
