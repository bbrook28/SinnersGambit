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
	h._on_next()              # the first hand with a demand: the card, once, then Pride opens
	await _shot("demand_card")
	Engine.time_scale = 1.0   # the opening at its real pace, caught while the window fills the screen
	h._on_card_btn()
	for i in 20:
		await process_frame
	await _shot("sin_opening")
	Engine.time_scale = 4.0
	for i in 400:
		if not h.opener.visible:
			break
		await process_frame
	await _shot("sin_window")
	# Pride: a 6 in the row, a 6 and a 3 thrown, the 6 picked
	hosted(1, [6, 6, 3])
	h._on_seal(1)
	await settle()
	h._on_seal(2)
	await settle()
	await _shot("pride_thrown")
	h._on_die(0)
	await _shot("pride_pick")
	# Pride pays 6 6 5 3 3: the Sin's coins, then the banner
	hosted(1, [6, 6, 5, 3, 3])
	for i in 5:
		h._on_seal(1)
		await settle()
	var second := false
	for i in 900:
		if not second and h.counting and int(h.marks_label.text) >= h.total - 4 and int(h.marks_label.text) < h.total - 1:
			second = true
			await _shot("pride_sin_pays")
		if h.next_box.visible:
			break
		await process_frame
	await _shot("pride_result")
	# Envy: a 2 costs; the pair of 2s is taken
	hosted(2, [2, 2, 3, 3, 4, 5])
	h._on_seal(1)
	await settle()
	h._on_seal(2)
	await settle()
	h._on_die(0)
	await _shot("envy_pick")
	h._on_keep()
	await settle()
	for i in 3:
		h._on_seal(1)
		await settle()
	for i in 900:
		if h.next_box.visible:
			break
		await process_frame
	await _shot("envy_result")
	# Wrath: two skulls show, and each seal says what it pays
	hosted(3, [4, 1, 1, 5, 3])
	h._on_seal(1)
	await settle()
	h._on_seal(2)
	await settle()
	await _shot("wrath_seals")
	h._on_seal(2)
	await settle()
	await _shot("wrath_owed")
	h._on_help()
	await _shot("hand_ranking")
	DirAccess.remove_absolute("user://shots.cfg")
	quit(0)


## A scripted hand hosted by the Sin of hand number k (1 Pride, 2 Envy, 3 Wrath).
func hosted(k: int, faces: Array) -> void:
	h.phase = "throw"
	h.hands = k
	h._new_hand(h.Tutorial.ScriptRng.new(faces))
	h._end_opening()


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
