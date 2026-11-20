# Sinners' Gambit (mobile), restarted
A clean slate (2026-11-20): still a dice game with the Seven Sins in stained glass; everything else is open.
The old game (table game, sims, docs, duel greybox) is at the tag `archive/sinners-gambit-v1`; read it with `git show archive/sinners-gambit-v1:<path>`, never restore it wholesale.

## Kept
- `assets/art/` (the glass windows are `assets/art/runtime/sins/<sin>.png`), `assets/fonts/` (Pirata One, IM Fell English, Cinzel), `assets/icons/`.
- Godot 4.7 stable (standard build, GDScript), 2D, Mobile renderer, portrait 1080x1920 stretched to fit phone and iPad. Targets Android and iOS.
- iOS builds on GitHub Actions (`.github/workflows/ios.yml`, `export_presets.cfg`). The workflow still reads `VERSION` from `ui/version.gd`, which is gone: fix that before the next TestFlight build.
- `ui/main.tscn` is a placeholder (the windows and fonts) so `project.godot` needs no change.

## Working
- The concept comes first: interview Ben and get a one-page pitch approved before any game code.
- Plan first and get Ben's OK; small steps, then stop for Ben to play. Short replies, one recommendation.
- Commit locally; push only when Ben says (the repo is public). Never commit `project.godot`.
- Never grade your own visual work: send evidence (screenshots at device size, clips) without a verdict. Nothing is done without evidence.
- The UI does all the work: every rule the player meets is shown and explained on screen.

## About Ben
Game/level designer, expert in UE5/Blueprint/combat design. Reads code; Claude writes it, Ben reviews. Judges feel himself.
