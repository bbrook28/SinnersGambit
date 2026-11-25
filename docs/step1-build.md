# Step 1 build notes

For a session that has seen none of the earlier conversation. Written 2026-11-24. Nothing of step 1 is built yet.

## Goal
Four people finish a full match of Sinners' Gambit on one phone, passing it round. That is the whole of step 1: it exists so Ben can find out whether the board game's fun survives on a phone.

## Read first
1. `docs/fun-brief.md`: why (the five moments every feature must serve).
2. `docs/step1-rules.md`: the rules, approved by Ben 2026-11-24. It is complete: build exactly what it says. If something is missing or two lines disagree, stop and ask Ben; do not fill the gap yourself.
3. `CLAUDE.md`: its "Working" and "About Ben" sections hold. Its "Kept" and "Design" sections describe dice poker, the solo game that was being built until this change of direction. That game stays in the repo, unused. Updating `CLAUDE.md` for step 1 is part of this build; show Ben the change.

## Where things stand
- Branch `docs/step1-rules` (off `main`, 715af29) holds these three docs. Build on a new branch off it.
- `feat/pride-idle` (Pride's idle animation for the dice poker screen) is parked at f815fa6, approved by Ben but never merged, pushed or built. Leave it alone.
- `main` = `origin/main` = 715af29, version 0.14.1.
- `project.godot` shows as modified: Godot rewrote its header and section order, no value changed. Never commit it.

## What to reuse
From today's code:
- `tests/run_all.sh` (runs every `tests/*_test.gd` headless; it has the path to the Godot 4.7.2 console exe), `tests/load_check.gd`, the CI workflow, `ui/version.gd`.
- Fonts in `assets/fonts/` and the dice faces already used by `ui/dice_screen.gd`. Look at how that file loads them and builds labels and buttons in code.
- The layout: rules with no UI in their own folder, every number in one config, a screen built in code, a test that drives the screen as taps would (`tests/ui_test.gd`).
- `dice/` (the dice poker rules) is a different game. Nothing in it applies.

From the old game, tag `archive/sinners-gambit-v1`. Read with `git show archive/sinners-gambit-v1:<path>`; copy ideas and small pieces, never restore it wholesale:
- `core/game.gd`, `core/player_state.gd`, `core/turn_state.gd`: a game loop over seats where every decision is an awaited call on the seat's decision object, so the same loop serves tests and a screen. Its rules are a later, different set (three strikes, throw again or bank, a chain multiplier, V4 and V5 additions). Reuse the shape, not the rules.
- Commit `9c24615` has the first, 71-line `core/game.gd`: one roll a turn, Purgatory, buying from a supply. It is the closest old code to the step 1 turn.
- `sins/sin.gd` and `sins/*.gd`: one file a Sin, with hooks the game calls (`on_other_throw`, `on_other_bust` and so on), and `game.attack(attacker, target, kind, amount)` as the single door for anything aimed at another player (Pride's Superiority hangs off it). The abilities in those files are not the step 1 abilities.
- `ui/human.gd`: a seat's decision object that shows a prompt and waits for a button. It was only ever used for one human against bots; four human seats is new.
- No version of the code ever had trading or gifts. That part is new.

## Build order
Small steps. After each: tests, commit, and stop for Ben when there is something to play or look at.
1. **Rules core, with tests first.** A new folder with no UI: setup (4 seats, 27 dice, Sins dealt at random), the Fate Phase, Purgatory in and out (including the 2-dice case), buying dice, the 0 floor on points, the win check. A seeded random source, so a test can script every roll. A headless test that plays a whole match to a winner.
2. **Pass-and-play blockout screen.** Whose turn it is, four scores and dice counts, each player's last roll left on screen, Roll, Buy, Pass, the Purgatory state, the winner. `ui/main.tscn` opens it. A full match can be played with no gifts or abilities.
3. **The three gifts.** Rules and tests first, then the buttons: pick a player, the other player taps to agree.
4. **Abilities, with a target picker.** Tier 1 for all seven Sins first, then Tier 2 with the 350 unlock. One Sin at a time, each with tests. The four that need care on one phone are spelled out in the rules doc (Spark of Rage, Hubris, Superiority, Entangling Allure).

## Limits
- Flat blockout: plain boxes and text. No new art. No SpriteCook credits.
- No rebalancing. Costs, numbers and abilities are built as written, even where they look unfair. The one known risk is recorded in the rules doc.
- No bots. No Tier 3. Nothing from V4 or V5 (bets, chains, the Master's call, comeback offers, temptations, marks, claims).
- No push and no TestFlight build without Ben's word. Commit locally. No version bump until he asks for a build.
- `bash tests/run_all.sh` and `godot --headless --path . --script res://tests/load_check.gd` pass before each commit.
- Every rule the player meets is shown on screen in plain words.
- Never grade your own visual work: send Ben screenshots at phone size (`--resolution 1080x2340`) without a verdict.

## Gotchas
- Add files to git by name; `git commit -a` picks up `project.godot`. Never commit `project.godot` or `.claude/`.
- Scripts use `preload` consts, not `class_name`, so headless `--script` runs work.
- A broken `--script` pops a modal alert on Windows: try one run before starting several.
- git autocrlf is on. Some files are LF in the working tree: keep each file's line endings when editing.
- Run Godot jobs longer than about two minutes in the background.
- Two untracked files in `docs/superpowers/` about a gameplay-feel skill belong to another project. Leave them.
- The existing tests build the dice poker screen directly, so they keep passing after `ui/main.tscn` changes. Leave them in place.
