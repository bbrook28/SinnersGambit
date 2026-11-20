# Sinners' Gambit (mobile), restarted
A clean slate (2026-11-20): still a dice game with the Seven Sins in stained glass; everything else is open.
The old game (table game, sims, docs, duel greybox) is at the tag `archive/sinners-gambit-v1`; read it with `git show archive/sinners-gambit-v1:<path>`, never restore it wholesale.

## Kept
- `assets/art/` (the glass windows are `assets/art/runtime/sins/<sin>.png`; the Master of the Dance, the Danse Macabre Reaper, is in `assets/art/master/`), `assets/fonts/` (Pirata One, IM Fell English, Cinzel), `assets/icons/`.
- Godot 4.7 stable (standard build, GDScript), 2D, Mobile renderer, portrait 1080x1920 stretched to fit phone and iPad. Targets Android and iOS.
- iOS builds on GitHub Actions (`.github/workflows/ios.yml`, `export_presets.cfg`). The workflow reads `VERSION` from `ui/version.gd` (bump the minor for each build Ben plays) and runs `tests/load_check.gd`.
- `ui/main.tscn` opens the playable greybox hand (`ui/hand_screen.gd`), with the guided first hand (`ui/tutorial.gd`). Screenshots: `godot --path . --resolution 1080x2340 --script res://tools/shots.gd` -> `build/shots/`.

## Design
- The hand: the bag hand, `docs/superpowers/specs/2026-11-20-bag-hand-design.md` (approved), which replaces the first hand's rules in `2026-11-20-core-hand-design.md` (its goals and pass marks stand). Its rules: `hand/` (no UI; `rules.gd` static functions over `hand_state.gd`, every number in `config.gd`). The first hand's code is in git up to 9a0053e.

## Commands (godot = the Godot 4.7.2 console exe; `tests/run_all.sh` has the path)
- Tests: `bash tests/run_all.sh`.
- Sim: `godot --headless --path . --script res://sim/hand_sim.gd -- [hands=2000] [strong_hands=500] [seed=1] [key=value ...]` (any `hand/config.gd` key). Report: stdout and `build/sim/hand_<seed>.txt`, with PASS/MISS against the design's pass marks.

## Working
- The concept comes first: interview Ben and get a one-page pitch approved before any game code.
- Plan first and get Ben's OK; small steps, then stop for Ben to play. Short replies, one recommendation.
- Commit locally; push only when Ben says (the repo is public). Never commit `project.godot`.
- Never grade your own visual work: send evidence (screenshots at device size, clips) without a verdict. Nothing is done without evidence.
- The UI does all the work: every rule the player meets is shown and explained on screen.

## About Ben
Game/level designer, expert in UE5/Blueprint/combat design. Reads code; Claude writes it, Ben reviews. Judges feel himself.
