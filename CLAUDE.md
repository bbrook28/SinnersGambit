# Sinners' Gambit (mobile)

Mobile version of Ben's tabletop dice game. Rulebook (source of truth): https://docs.google.com/document/d/1r0ERJOlG5mu3WL8cB2oxrmZPyZi7m6XqGyExo0bSn7w
**Start here:** `Docs/UXPlan.md` (current phase plan, standing rules, open bugs).
Plan and balance notes: `Docs/Plan.md`.

## Decided
- Godot 4.5+ stable (standard build, not .NET), GDScript, 2D, Mobile renderer, portrait 1080x1920 stretched to fit phone and iPad.
- v1: solo roguelike runs (`Docs/RunDesign.md`), one player. No bot table, no pass-and-play, no online play. The bot-table code stays in `core/`, `sins/`, `ai/` as a possible side mode after ship.
- Targets: Android and iOS (iOS export needs a Mac + Xcode).
- Rules live in `core/` with no UI, so `sim/` can play thousands of bot games headless.
- Scripts use `preload` consts, not `class_name`, so headless `--script` runs work without an editor import.

## Layout
`core/` rules + game loop · `ai/` bots · `sim/` balance runner · `sins/` Sin abilities (next) · `ui/` playtest UI · `assets/` · `tests/` · `Docs/`

## Run the sim
Table game (V2 vs V3, win share per Sin): `godot --headless --path . --script res://sim/check_v3.gd [-- games]`
Run mode (`Docs/RunDesign.md`): `sim/run_sim.gd`, rebuilt in Phase 8. The old `run_sim.gd` hasn't parsed since `cf24783`.

## About Ben
Game/level designer, expert in UE5/Blueprint/combat design. Reads code; Claude writes it, Ben reviews. Judges feel himself.

## Working
- Plan first and get Ben's OK. Don't overbuild. Small steps, then stop for Ben to play.
- Short replies, one recommendation, no status narration.
- Commit locally; push only when Ben says.
