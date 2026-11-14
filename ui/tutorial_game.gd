## The tutorial: a short scripted game (you as Envy, first seat, against a Sloth bot) with rigged
## dice, so each rule happens on cue. ui/main.gd builds the game (start_tutorial) and calls the
## hooks below from show_prompt, beat and turn_started; this walks SCRIPT one step at a time.
## Wording: RulesText.TUTORIAL. Docs/Handoff.md § Phase 3.
extends RefCounted

const RulesText = preload("res://ui/rules_text.gd")
const TutorialDice = preload("res://ui/tutorial_dice.gd")
const Overlay = preload("res://ui/tutorial.gd")

const YOU := "Envy"
const BOT := "Sloth"
const BOT_TURNS := [[[6, 4, 3]], [[5, 5, 3]]]  # each bot turn: its throws, then it banks

## on: "prompt" (one of your prompts is showing), "throw" / "end" (the beat after a throw / at a
##     turn's end or bust), "purgatory" (your turn starts in Purgatory, before its free throw).
## who: whose prompt / beat / turn ("you" unless given).
## say: RulesText.TUTORIAL key. spot: "dice" / "candles" (read steps) or nothing.
## do: [button kind, value?]: only that prompt button is live; the step ends when you press it.
## faces: rig your next throw. end: the closing card.
const SCRIPT := [
	{"on": "prompt", "say": "welcome"},
	{"on": "prompt", "say": "throw", "do": ["roll"], "faces": [6, 4, 3]},
	{"on": "throw", "say": "scored", "spot": "dice"},
	{"on": "prompt", "say": "again", "do": ["roll"], "faces": [6, 5, 1]},
	{"on": "throw", "say": "strike", "spot": "candles"},
	{"on": "prompt", "say": "bank", "do": ["bank"]},
	{"on": "prompt", "say": "buy", "do": ["pill", 1]},
	{"on": "throw", "who": "bot", "say": "bot", "spot": "dice"},
	{"on": "prompt", "say": "turn2", "do": ["roll"], "faces": [4, 3, 3, 2]},
	{"on": "prompt", "say": "sin", "do": ["pill", true]},
	{"on": "throw", "say": "glance", "spot": "dice"},
	{"on": "prompt", "say": "risk", "do": ["roll"], "faces": [1, 2, 5, 3]},
	{"on": "end", "say": "bust", "spot": "candles"},
	{"on": "purgatory", "faces": [6, 3, 2, 5]},
	{"on": "prompt", "say": "purgatory", "spot": "dice"},
	{"on": "prompt", "end": true},
]

signal finished(to_setup: bool)  # Play (or Skip on the first run): the Sin choice; Menu: the title page

var m                     # ui/main.gd
var overlay: Control      # ui/tutorial.gd, up for the whole tutorial
var index := 0            # the next SCRIPT step
var from_settings := false


func _init(main, p_from_settings := false) -> void:
	m = main
	from_settings = p_from_settings
	overlay = Overlay.new(m)
	overlay.skipped.connect(func(): finished.emit(not from_settings))
	for s in SCRIPT:  # find every seed now, so no throw waits on the search
		if s.has("faces"):
			TutorialDice.seed_for(s.faces)
	for t in BOT_TURNS:
		for f in t:
			TutorialDice.seed_for(f)


func done() -> bool:
	return index >= SCRIPT.size()


func _matches(on: String, mine: bool) -> bool:
	if done():
		return false
	var s: Dictionary = SCRIPT[index]
	return s.on == on and (s.get("who", "you") == "you") == mine


## Your prompt is showing (buttons placed): run every step meant for it.
func on_prompt() -> void:
	while _matches("prompt", true):
		var s: Dictionary = SCRIPT[index]
		index += 1
		if s.get("end", false):
			var pick: int = await overlay.end_card(RulesText.tutorial("done"), [RulesText.tutorial("done_play"), RulesText.tutorial("done_menu")])
			finished.emit(pick == 0)
			return
		if s.has("do"):
			var b: Button = _button(s.do)
			if b == null:
				push_error("Tutorial step %d: no %s button" % [index - 1, s.do])
				continue
			for o in _live_buttons():
				o.disabled = o != b
			if s.has("faces"):
				TutorialDice.rig(m.game, s.faces)
			var pressed := [false]  # a fast tap can land before act() has finished showing
			m.human.answered.connect(func(_v): pressed[0] = true, CONNECT_ONE_SHOT)
			await overlay.act(b, _say(s))
			if not pressed[0]:
				await m.human.answered
			overlay.idle()
			return  # the prompt is answered; the next steps wait for their own moment
		await overlay.read(_spot(s), _say(s))
	overlay.idle()


## core/game.gd's beat after a throw ("throw") or at a turn's end ("end").
func on_beat(p, kind: String) -> void:
	var mine: bool = p.bot == m.human
	while _matches(kind, mine):
		var s: Dictionary = SCRIPT[index]
		index += 1
		await overlay.read(_spot(s), _say(s))
	overlay.idle()


## A turn starts; in Purgatory its free throw comes next, so rig it now.
func on_turn_started(p) -> void:
	if p.in_purgatory and _matches("purgatory", p.bot == m.human):
		TutorialDice.rig(m.game, SCRIPT[index].faces)
		index += 1


func _say(s: Dictionary) -> String:
	return RulesText.tutorial(s.say, {"ability": RulesText.ability(YOU, false)})


func _spot(s: Dictionary) -> Rect2:
	match s.get("spot", ""):
		"dice":
			return (m._dice_area.get_parent() as Control).get_global_rect()  # the tray: dice, total, result line
		"candles":
			var r := Rect2()
			for n in m._strike_icons:
				r = n.get_global_rect() if r.size == Vector2.ZERO else r.merge(n.get_global_rect())
			return r
	return Rect2()


func _live_buttons() -> Array:
	return m._buttons.get_children().filter(func(b): return not b.is_queued_for_deletion())


## The prompt button a step wants: [kind] or [kind, value].
func _button(want: Array) -> Button:
	for b in _live_buttons():
		if b.get_meta("kind", "") != want[0]:
			continue
		if want.size() < 2 or (b.has_meta("value") and typeof(b.get_meta("value")) == typeof(want[1]) and b.get_meta("value") == want[1]):
			return b
	return null
