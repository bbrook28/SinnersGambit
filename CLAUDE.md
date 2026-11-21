# Sinners' Gambit (mobile), restarted
A clean slate (2026-11-20): still a dice game with the Seven Sins in stained glass; everything else is open.
The old game (table game, sims, docs, duel greybox) is at the tag `archive/sinners-gambit-v1`; read it with `git show archive/sinners-gambit-v1:<path>`, never restore it wholesale.

## Kept
- `assets/art/` (the glass windows are `assets/art/runtime/sins/<sin>.png`; the Master of the Dance, the Danse Macabre Reaper, is in `assets/art/master/`), `assets/fonts/` (Pirata One, IM Fell English, Cinzel), `assets/icons/`.
- Godot 4.7 stable (standard build, GDScript), 2D, Mobile renderer, portrait 1080x1920 stretched to fit phone and iPad. Targets Android and iOS.
- iOS builds on GitHub Actions (`.github/workflows/ios.yml`, `export_presets.cfg`). The workflow reads `VERSION` from `ui/version.gd` (bump the minor for each build Ben plays) and runs `tests/load_check.gd`.
- `ui/main.tscn` opens dice poker (`ui/dice_screen.gd`, dressed with the kept art), with the guided first hand (`ui/dice_tutorial.gd`). Screenshots: `godot --path . --resolution 1080x2340 --script res://tools/shots.gd` -> `build/shots/`.

## Design
- The hand: dice poker against the Master, `docs/superpowers/specs/2026-11-20-dice-poker-pitch.md` (approved), changed by Ben on 2026-11-20: no cash out (a hand plays to a full row or a bust), bag 7, and each throw you choose to draw 1, 2 or 3 dice (core B, from `sim/cores_sim.gd`). Rules: `dice/` (no UI; `rules.gd` static functions over `state.gd`, every number in `config.gd`; `policies.gd` has the exact solver). The bag hand is in git up to 4cb86d0.

- The Sin's demand (0.12.0, a prototype): `docs/superpowers/specs/2026-11-21-sin-demand-pitch.md` (approved). The hosting Sin pays marks on top of the hand for what it wants; `dice/demands.gd` has the three (Pride, Envy, Wrath), and only they host (`HOSTS` in `ui/dice_screen.gd`). Sim: add `demand=pride|envy|wrath`. Which face a Sin names is only paint: a new Sin needs a new shape.

## Commands (godot = the Godot 4.7.2 console exe; `tests/run_all.sh` has the path)
- Tests: `bash tests/run_all.sh`.
- Sim: `godot --headless --path . --script res://sim/dice_sim.gd -- [hands=20000] [seed=4] [key=value ...]` (any `dice/config.gd` key). Report: stdout and `build/sim/dice_<seed>.txt`, with PASS/MISS against the plan's pass marks.

## Working
- The concept comes first: interview Ben and get a one-page pitch approved before any game code.
- Plan first and get Ben's OK; small steps, then stop for Ben to play. Short replies, one recommendation.
- Commit locally; push only when Ben says (the repo is public). Never commit `project.godot`.
- Never grade your own visual work: send evidence (screenshots at device size, clips) without a verdict. Nothing is done without evidence.
- The UI does all the work: every rule the player meets is shown and explained on screen.

## About Ben
Game/level designer, expert in UE5/Blueprint/combat design. Reads code; Claude writes it, Ben reviews. Judges feel himself.
