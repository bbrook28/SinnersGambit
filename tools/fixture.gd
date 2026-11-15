## Fixtures (Ben, Part B2): named game states as data in tools/fixtures/<name>.json, put straight on
## screen with no playing through. Used by tools/show.gd, tools/gallery.gd, tools/ui_audit.gd
## (-- fixtures) and tools/clip.gd. Run windowed with --fixed-fps so every render is identical.
##
## Fixture keys (all optional except screen):
##   screen   "title" | "setup" | "settings" | "rulebook" | "game" | "table" (the Phase 8 blockout)
##   seed     global and game RNG seed (default 1)
##   page     rulebook page id ("contents", "scoring", ...); setup: carousel index
##   table    table size for the setup screen (4 or 7)
##   first    a First Game (no Greater abilities, no temptations)
##   seats    [{sin, you, score, dice, marks {Sin: n}, claims [Sin], pend [bank, strike, fewer, die],
##             purg, greater}] in seat order
##   cur      seat whose turn it is
##   turn     {faces, points, strikes, throws}: the turn so far, before the moment
##   moment   game screens: "decision" (my Throw / Bank), "offer", "accept", "refuse", "rival" (a
##            rival's turn, mid-throw), "score" (my throw lands, then my decision), "bust", "claim",
##            "win", "loss", "pause", "chronicle"
##   throw    the faces that land in "score", "rival" and "bust"
##   offer    temptation id (sins/temptations.gd), offered by `from` (a Sin name) for offer / accept /
##            refuse / claim
##   hold     seconds to let the moment play before the capture (each moment has a default)
extends RefCounted

const DIR := "res://tools/fixtures/"
const Game = preload("res://core/game.gd")
const Rules = preload("res://core/rules.gd")
const TurnState = preload("res://core/turn_state.gd")
const Temptations = preload("res://sins/temptations.gd")
const Tuning = preload("res://ui/tuning.gd")
const BotPolicy = preload("res://ai/bot_policy.gd")
const Human = preload("res://ui/human.gd")

## Phone sizes: device pixels, points (width x height) and safe-area insets in points (top, bottom).
## se: smallest supported (iPhone SE 2/3); std: iPhone 16; max: largest (iPhone 16 Pro Max).
const SIZES := {
	"se": {"px": [750, 1334], "pt": [375, 667], "safe": [20, 0]},
	"std": {"px": [1179, 2556], "pt": [393, 852], "safe": [59, 34]},
	"max": {"px": [1320, 2868], "pt": [440, 956], "safe": [62, 34]},
}
const ORDER := ["se", "std", "max"]

## The frame the moment started on (tools/clip.gd trims its recording to it).
static var moment_frame := -1

## Seconds each moment plays before the capture, unless the fixture says `hold`.
const HOLD := {"decision": 1.5, "offer": 3.0, "accept": 0.7, "refuse": 0.7, "rival": 2.0, "score": 3.5,
	"bust": 1.0, "claim": 2.0, "win": 6.0, "loss": 6.0, "pause": 1.0, "chronicle": 1.0}


static func names() -> Array:
	var out := []
	for f in DirAccess.get_files_at(DIR):
		if f.ends_with(".json"):
			out.append(f.get_basename())
	out.sort()
	return out


static func read(name: String) -> Dictionary:
	var f := FileAccess.open(DIR + name + ".json", FileAccess.READ)
	if f == null:
		push_error("no fixture %s" % name)
		return {}
	var d = JSON.parse_string(f.get_as_text())
	return d if d is Dictionary else {}


## Logical viewport px per point at this size (the game lays out 1080 wide).
static func pt(size: String) -> float:
	return 1080.0 / float(SIZES[size].pt[0])


## The safe insets in viewport px, as main.debug_safe.
static func safe(size: String) -> Vector2:
	var s: Array = SIZES[size].safe
	return Vector2(maxf(1.0, s[0] * pt(size)), s[1] * pt(size))


## Puts the fixture on screen under `tree` and returns ui/main.gd once the moment has played.
static func apply(tree: SceneTree, fx: Dictionary, size: String):
	var sd: int = int(fx.get("seed", 1))
	seed(sd)
	var main = load("res://ui/main.tscn").instantiate()
	main.debug_safe = safe(size)
	main.save_enabled = false
	main.tutorial_enabled = false
	main.first_game_enabled = false
	tree.root.add_child(main)
	# Settings the player's own settings.cfg may have changed: back to defaults.
	Tuning.speed = 1.0
	Tuning.muted = true
	Tuning.sfx_vol = 0.0
	Tuning.music_vol = 0.0
	Tuning.reduce_motion = false
	Tuning.haptics = false
	Tuning.table_size = int(fx.get("table", 4))
	main.tempt_tip_seen = true
	main.tutorial_pending = false
	main.games_finished = 0 if fx.get("first", false) else 1
	main._apply_music()
	await frames(tree, 10)
	match str(fx.get("screen", "title")):
		"title":
			await frames(tree, 60)
		"setup":
			main._free_screen()
			main._build_setup()
			await frames(tree, 10)
			if fx.has("page"):
				var car = main._content.find_children("*", "VBoxContainer", true, false).filter(func(c): return c.has_method("go_to"))
				if not car.is_empty():
					car[0].go_to(int(fx.page), false)
			await frames(tree, 60)
		"settings":
			main._open_settings()
			await frames(tree, 60)
		"rulebook":
			main.open_rulebook(str(fx.get("page", "contents")))
			await frames(tree, 60)
		"game":
			await _game(tree, main, fx)
		"table":
			await _table(tree, main, fx, size)
	await settle(tree, main)
	return main


## The Phase 8 table blockout (ui/table_blockout.gd), drawn over the title screen in one still moment.
## Uses seats, cur, turn.faces / turn.points / turn.strikes, and for a bust the throw (all three Strikes).
static func _table(tree: SceneTree, main, fx: Dictionary, size: String) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 60
	main.add_child(layer)
	var t = load("res://ui/table_blockout.gd").new()
	var turn: Dictionary = fx.get("turn", {})
	t.seats = fx.get("seats", [])
	t.cur = int(fx.get("cur", 0))
	t.moment = str(fx.get("moment", "decision"))
	t.faces = fx.get("throw", turn.get("faces", [])) if t.moment == "bust" else turn.get("faces", [])
	t.points = int(turn.get("points", 0))
	t.strikes = 3 if t.moment == "bust" else int(turn.get("strikes", 0))
	t.safe = safe(size)
	layer.add_child(t)
	t.build()
	main._overlay = t  # so tools/ui_audit.gd audits the blockout, not the title under it
	moment_frame = Engine.get_process_frames()
	await frames(tree, 6)


static func _game(tree: SceneTree, main, fx: Dictionary) -> void:
	main._free_screen()
	main._content = null
	var human = Human.new()
	human.view = main
	main.human = human
	var bot = BotPolicy.chooser(5, [99, 2, 0], 300)
	var seats: Array = fx.get("seats", [])
	var bots := []
	var sins := []
	for s in seats:
		bots.append(human if s.get("you", false) else bot)
		sins.append(main._sin_script(str(s.sin)).new())
	var first: bool = fx.get("first", false)
	main._first_game = first
	var options: Dictionary = Rules.V4.duplicate()
	options["tier2"] = not first
	options["temptations"] = not first
	var game = Game.new(bots, int(fx.get("seed", 1)), options, sins)
	game.view = main
	main.game = game
	for i in seats.size():
		var s: Dictionary = seats[i]
		var p = game.players[i]
		p.score = int(s.get("score", p.score))
		p.dice = int(s.get("dice", Rules.START_DICE))
		p.in_purgatory = s.get("purg", false)
		for k in s.get("marks", {}):
			p.marks[k] = int(s.marks[k])
		p.claims = Array(s.get("claims", []))
		var pend: Array = s.get("pend", [0, 0, 0, 0])
		p.pend_bank = int(pend[0]); p.pend_strike = int(pend[1]); p.pend_fewer = int(pend[2]); p.pend_die = int(pend[3])
		if s.get("greater", false):
			p.t2_unlocked = true
			p.t2_ready = true
	var cur = game.players[int(fx.get("cur", 0))]
	game.current = cur
	game.round_count = int(fx.get("round", 2))
	var t = TurnState.new()
	var td: Dictionary = fx.get("turn", {})
	t.faces = Array(td.get("faces", []), TYPE_INT, "", null)
	t.points = int(td.get("points", 0))
	t.strikes = int(td.get("strikes", 0))
	t.throws = int(td.get("throws", 0))
	game.turn = t
	main._build_board()
	await frames(tree, 2)
	main._last_snap = main._snapshot()
	main._refresh(main._last_snap)
	main._q.push(func(): await main._dir.turn_change(cur, main._last_snap))
	await main._q.drain()
	var me = main.human_player()
	var moment := str(fx.get("moment", "decision"))
	moment_frame = Engine.get_process_frames()
	match moment:
		"decision":
			human.wants_throw(me, game, t.points, t.strikes)
		"offer", "accept", "refuse":
			human.wants_temptation(game, me, game.sin_player(str(fx.from)), _offer(str(fx.from), str(fx.offer)))
			if moment != "offer":
				await main._q.drain()
				await seconds(tree, 2.0)
				for b in main._buttons.get_children():
					if b.get_meta("offer", "") == moment:
						b.button_down.emit()
						b.button_up.emit()
						b.pressed.emit()
						break
		"score", "rival":
			await _throw(main, game, cur, fx)
			if moment == "score":
				human.wants_throw(me, game, t.points, t.strikes)
		"bust":
			var faces := Array(fx.get("throw", [1, 1, 3, 3, 4, 2]), TYPE_INT, "", null)
			t.faces = faces
			t.throws += 1
			game.say("%s throws %d: %s" % [game.pname(cur), faces.size(), Game._faces_str(faces)])
			t.strikes = maxi(Rules.STRIKES_TO_BUST, t.strikes + Rules.count_strikes(faces))
			game.say("  %d Strikes: %s BUSTS and goes to Purgatory." % [t.strikes, game.pname(cur)])
			game._bust(cur)
			main.beat(cur, "end")
		"claim":
			var from = game.sin_player(str(fx.from))
			cur.marks[str(fx.from)] = 0
			if not cur.claims.has(str(fx.from)):
				cur.claims.append(str(fx.from))
			game.say("  %s's claim: %s, for the rest of the game" % [game.pname(from), game.pname(cur)])
			main.beat(cur, "throw")
		"win", "loss":
			var w = me if moment == "win" else game.players[int(fx.get("winner", 1))]
			w.score = maxi(w.score, Rules.WIN_SCORE)
			game.say("%s banks %d (score %d)." % [game.pname(w), t.points, w.score])
			game.winner = w
			main.log_line("")
			main.log_line("[b]%s WIN%s with %d![/b]" % [main.player_name(w).to_upper(), "" if w.bot == human else "S", w.score])
			main._q.push(func(): main._set_banner("%s %s" % [main.player_name(w), "win!" if w.bot == human else "wins"], w))
			main.show_prompt("The game is done. %s reached %d." % [main.player_name(w), w.score], [["New game", "new"]])
		"pause":
			human.wants_throw(me, game, t.points, t.strikes)
			await main._q.drain()
			await frames(tree, 30)
			main._open_pause()
		"chronicle":
			human.wants_throw(me, game, t.points, t.strikes)
			await main._q.drain()
			main._log_overlay.visible = true
	await seconds(tree, float(fx.get("hold", HOLD.get(moment, 1.5))))


## A throw lands for whoever's turn it is: the throw line, then its points (or a Strike count).
static func _throw(main, game, cur, fx: Dictionary) -> void:
	var t = game.turn
	var faces := Array(fx.get("throw", [5, 1, 3, 4, 2, 6]), TYPE_INT, "", null)
	t.faces = faces
	t.throws += 1
	game.say("%s throws %d: %s" % [game.pname(cur), faces.size(), Game._faces_str(faces)])
	t.strikes += Rules.count_strikes(faces)
	t.throw_points = game.throw_score(faces)
	t.points += t.throw_points
	game.say("  +%d (turn %d, Strikes %d)" % [t.throw_points, t.points, t.strikes])
	main.beat(cur, "throw")


static func _offer(sname: String, id: String) -> Dictionary:
	for o in Temptations.OFFERS.get(sname, []):
		if o.id == id:
			return o
	push_error("no offer %s for %s" % [id, sname])
	return Temptations.OFFERS[sname][0]


static func frames(tree: SceneTree, n: int) -> void:
	for i in n:
		await tree.process_frame


## Frames at the fixed rate (--fixed-fps 60), so timing never depends on the machine.
static func seconds(tree: SceneTree, s: float) -> void:
	await frames(tree, roundi(s * 60.0))


## Lets the lettering finish inking in and stops the idle pulses, so a capture is repeatable.
static func settle(tree: SceneTree, main) -> void:
	var guard := 0
	while not main._inking.is_empty() and guard < 240:
		await tree.process_frame
		guard += 1
	await frames(tree, 4)
