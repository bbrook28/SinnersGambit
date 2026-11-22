## The Sin's demand (docs/superpowers/specs/2026-11-21-sin-demand-pitch.md): what the hosting Sin pays for, on top of the hand.
## faces: marks for each die of that face in the row. lone: marks for a face the row holds exactly once.
## danger: marks for each die thrown while DANGER_AT skulls show.
## Pride is the second revision's one shape; Envy and Wrath are 0.12.0's, kept and tested, and do not host.
extends RefCounted

const DANGER_AT := 2   # skulls showing for a throw to count as thrown in danger

const DEMANDS := {
	"pride": {"lone": {6: 4}, "faces": {2: -1}, "danger": 0, "line": "Exactly one 6 pays 4. Each 2 costs 1."},
	"envy": {"faces": {6: 1, 2: -1}, "danger": 0, "line": "Each 6 pays 1. Each 2 costs 1."},
	"wrath": {"faces": {}, "danger": 1, "line": "Each die thrown at two skulls pays 1."},
}


## The hosting Sin's demand, or {} when no Sin demands anything.
static func of(cfg: Dictionary) -> Dictionary:
	return DEMANDS.get(str(cfg.get("demand", "")), {})
