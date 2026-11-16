# Sinners' Gambit (mobile)
Mobile version of Ben's tabletop dice game. Rulebook (source of truth): https://docs.google.com/document/d/1r0ERJOlG5mu3WL8cB2oxrmZPyZi7m6XqGyExo0bSn7w
**Start here:** `Docs/Handoff.md` (now, next, waiting on Ben, open faults).
**Owners:** phases `Docs/UXPlan.md` · table rules and content `Docs/TableDesign.md` · table as built `Docs/TableSpec.md` · art `Docs/ArtDirection.md` · sound `Docs/AudioStyle.md` · onboarding `Docs/Onboarding.md` · parked run game `Docs/RunDesign.md` · history `Docs/archive/`.

## Decided
- Godot 4.7 stable (standard build, not .NET), GDScript, 2D, Mobile renderer, portrait 1080x1920 stretched to fit phone and iPad.
- v1: the table game: Solo ladder against bot Sins, and pass-and-play (2-7 seats, humans and bots, one phone). No online play. The run game is parked behind `Tuning.RUN_MODE`.
- Targets: Android and iOS. iOS builds and uploads to TestFlight on GitHub Actions (`.github/workflows/ios.yml`); no Mac needed.
- Rules live in `core/` with no UI, so `sim/` can play thousands of bot games headless. Scripts use `preload` consts, not `class_name`, so headless `--script` runs work without an editor import.

## Layout
`core/` rules + game loop · `sins/` abilities, temptations · `ai/` bots · `sim/` balance · `ui/` game (table: `table_blockout.gd`, `table_play.gd`) · `run/` parked · `tools/` harness, bakes · `tests/` · `Docs/`

## Commands (godot = the Godot 4.7.2 console exe; `tests/run_all.sh` has the path)
- Full suite: `bash tests/run_all.sh` (`tests/load_check.gd` first; stops on a load error).
- Sim: `godot --headless --path . --script res://sim/check_v3.gd -- 4000 v4 [key=value]` (V4, win share per Sin; without `v4`, V2 vs V3). Run game (parked): `sim/run_sim.gd -- runs=20 [sin=Lust]`, one process per Sin with `out=<dir>/part_X.json`, then `-- merge=<dir>`. Smoke-test one run before going parallel.
- One fixture: `godot --path . --fixed-fps 60 --script res://tools/show.gd -- <fixture> [se|std|max] [out.png]`. Fixtures: `tools/fixtures/<name>.json`.
- Gallery: `godot --path . --script res://tools/gallery.gd [-- --only a,b] [--sizes se] [--check] [--packet <topic>] [--approve <fixture>]` (`--check` diffs against `tests/golden/`; `--approve` only when Ben says).
- Text audit: `godot --path . --fixed-fps 60 --script res://tools/ui_audit.gd -- fixtures [size] [names]` into `build/audit/<size>.txt`. Clip: `tools/clip.gd -- <fixture> [beat] [seconds] [size]` (ffmpeg). Audit first, then `--check`, then open only changed images.
- Table view: `-- --table`, or presets "iOS (table)" / "Web (table)" (`tools/serve.ps1 -Dir web_table`). TestFlight: `gh workflow run ios.yml --ref main -f table=true` (build = 100 + run number; internal testers only, never submit for review).

## Working
- Plan first and get Ben's OK; small steps, then stop for Ben to play. Never touch `core/`, `sins/` or `ai/` without his explicit OK.
- Short replies, one recommendation, no status narration. Commit locally; push only when Ben says (the repo is public). Never commit `project.godot`.
- A decision is written in its owning file only; other files link to it. A doc that restates another is a fault. Where a doc and the code disagree, the code wins.
- Never grade your own visual work: send evidence (crops, screenshots at device size, clips) without a verdict. Nothing is done without evidence (a screenshot for visuals, a test result for logic).
- Before showing a screen, report: overlapping or clipped text, anything touching an edge, seams or outlines across hands or faces, colours against the source art, controls under 44 pt.
- Fix causes, not instances. If the same fix fails twice, stop and say what was tried. One change per commit, with before and after images for anything visual.
- Every new screen or state gets a fixture. End each piece of work with `Docs/review/latest/` (old packet to `Docs/review/archive/<date>-<topic>/`): `packet.md` of 30 lines or fewer (what changed, text-audit result, changed fixtures, numbered questions each with one recommendation), `sheet.png` before beside after under 2000 px, `clip.mp4` 5 s or less when motion is judged. Then reply only "Packet ready: <topic>, <n> questions."
- UI: every event is a queued beat (`ui/action_queue.gd`: anticipation, action, impact, hold); the board draws the last beat's snapshot, never live state. A tap finishes the beat, a second skips to your next decision, a hold explains (not yet on the table). All wording in `ui/rules_text.gd`, numbers through `vals()`; every duration in `ui/tuning.gd` (seconds at 1x, `Tuning.speed` 0.25-4).

## About Ben
Game/level designer, expert in UE5/Blueprint/combat design. Reads code; Claude writes it, Ben reviews. Judges feel himself.
