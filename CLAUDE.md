# Sinners' Gambit (mobile), restarted
A clean slate (2026-11-20): still a dice game with the Seven Sins in stained glass; everything else is open.
The old game (table game, sims, docs, duel greybox) is at the tag `archive/sinners-gambit-v1`; read it with `git show archive/sinners-gambit-v1:<path>`, never restore it wholesale.

## Step 1 (from 2026-11-24): 4 players, one phone
The work now. Why: `docs/fun-brief.md`. Rules, approved: `docs/step1-rules.md` (build exactly what it says; ask Ben about any gap). Build order, limits and gotchas: `docs/step1-build.md`.
- Built: the rules, `game/` (no UI; `rules.gd` static functions over `state.gd`, every number in `config.gd`), tested by `tests/game_test.gd`. A turn is `roll`, then `buy` and `gift` (give points, lend a die, buy a die for a player) as often as you like, then `pass_turn`.
- Built: the pass-and-play screen, `ui/table_screen.gd` (flat blockout; `ui/main.tscn` opens it; the How to play card, `HOWTO`, opens each match and sits behind a button), driven as taps by `tests/table_test.gd`. Screenshots: `godot --path . --resolution 1080x2340 --script res://tools/table_shots.gd` -> `build/table_shots/`.
- Not built yet: the abilities (the Sins are dealt and shown, and do nothing).
- Dice poker (everything under "Kept" and "Design" below) stays in the repo, unused. `dice/` is a different game: nothing in it applies to step 1.

## Kept
- `assets/art/` (the glass windows are `assets/art/runtime/sins/<sin>.png`; the Master of the Dance, the Danse Macabre Reaper, is in `assets/art/master/`), `assets/fonts/` (Pirata One, IM Fell English, Cinzel), `assets/icons/`.
- Godot 4.7 stable (standard build, GDScript), 2D, Mobile renderer, portrait 1080x1920 stretched to fit phone and iPad. Targets Android and iOS.
- iOS builds on GitHub Actions (`.github/workflows/ios.yml`, `export_presets.cfg`). The workflow reads `VERSION` from `ui/version.gd` (bump the minor for each build Ben plays) and runs `tests/load_check.gd` and `tests/run_all.sh` before the export.
- `ui/main.tscn` opens dice poker (`ui/dice_screen.gd`, dressed with the kept art), with the tutorial: three scripted lessons (the row, skulls, the Sin) in `ui/dice_tutorial.gd`, design `docs/superpowers/specs/2026-11-21-tutorial-design.md` (0.14.0). Shown words are plain: roll, Run, Three and a pair, "counts as any number", "exactly one 6", button; `tests/ui_test.gd` (`BANNED`) fails on draw, throw, wild, lone, hosts, Straight, Full house, high die, seal, snuff. Code names keep the old words. Screenshots: `godot --path . --resolution 1080x2340 --script res://tools/shots.gd` -> `build/shots/`.

## Design
- The rules as built, and nothing else: `docs/rules.md` (keep it true when a rule changes). Latest build: 0.15.0, the first pass-and-play build (step 1: four players, one phone, the How to play card, no abilities), sent to TestFlight 2026-11-24. Dice poker's last was 0.14.1 (never on TestFlight; 0.14.0 was).
- The hand: dice poker against the Master, `docs/superpowers/specs/2026-11-20-dice-poker-pitch.md` (approved), changed by Ben on 2026-11-20: no cash out (a hand plays to a full row or a bust), bag 7, and each throw you choose to draw 1, 2 or 3 dice (core B, from `sim/cores_sim.gd`). Rules: `dice/` (no UI; `rules.gd` static functions over `state.gd`, every number in `config.gd`; `policies.gd` has the exact solver). The bag hand is in git up to 4cb86d0.

- The Sin's demand: the hosting Sin pays marks on top of the hand for what it wants. Pride alone hosts (`HOSTS` in `ui/dice_screen.gd`), with "Exactly one 6 pays 4. Each 2 costs 1." (0.13.0; plan `docs/superpowers/plans/2026-11-21-lone-six.md`, approved). 0.12.0's three demands failed review: they break ties, they do not ask a question; Envy and Wrath stay in `dice/demands.gd`, tested, and do not host. The pitch `docs/superpowers/specs/2026-11-21-sin-demand-pitch.md` was not rewritten (its status line says so). Still a draft, not approved: `2026-11-21-the-refusal-pitch.md` (the hand itself). Sim: add `demand=pride|envy|wrath`. Which face a Sin names is only paint: a new Sin needs a new shape.

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
