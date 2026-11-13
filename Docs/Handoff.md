# Handoff (2026-11-13)

Read `CLAUDE.md`, then `Docs/Plan.md`. It has all decisions, sim results and the locked rules.

## Where we are
- Phase 1 (base loop) locked as `Rules.V2` in `core/rules.gd`.
- Phase 2 step 1 done: Tier 1 for all seven Sins, 13.0–15.1% at 7 players (`sins/*.gd`).
- Next: Tier 2 (unlock at 300, active), then Tier 3 (666, once per game, no cooldowns). Kits drafted in Plan.md. Every ability is tagged Before roll / After roll / Gambit.

## How to run
- Godot 4.7.2 console exe: `%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe`
- `--headless --path C:\Projects\SinnersGambit --script res://sim/run_sins.gd` (~1 min). `run_sim.gd` = base-rule sweeps (long); `check_v2.gd` = quick check.
- Parse errors make Godot hang instead of exiting: stop the task, fix, rerun. Don't kill all Godot processes; Ben may have the editor open.
- Type inference: GDScript can't infer from untyped values (`var x := arr[i]`). Use `var x: int = ...`.

## Ben
Plan first, small steps, short replies, one recommendation. Commit locally, never push unless asked. Art direction agreed: gothic illuminated manuscript + stained glass pixel art.
