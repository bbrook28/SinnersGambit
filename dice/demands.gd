## The Sin's demand (docs/superpowers/specs/2026-11-21-sin-demand-pitch.md): what the hosting Sin pays for, on top of the hand.
## faces: marks for each die of that face in the row. danger: marks for each die thrown while DANGER_AT skulls show.
extends RefCounted

const DANGER_AT := 2   # skulls showing for a throw to count as thrown in danger

const DEMANDS := {
	"pride": {"faces": {6: 2, 5: 1}, "danger": 0, "line": "Each 6 pays 2. Each 5 pays 1."},
	"envy": {"faces": {6: 1, 2: -1}, "danger": 0, "line": "Each 6 pays 1. Each 2 costs 1."},
	"wrath": {"faces": {}, "danger": 1, "line": "Each die thrown at two skulls pays 1."},
}


## The hosting Sin's demand, or {} when no Sin demands anything.
static func of(cfg: Dictionary) -> Dictionary:
	return DEMANDS.get(str(cfg.get("demand", "")), {})
