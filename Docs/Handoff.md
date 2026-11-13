# Handoff (2026-11-13)

Read `CLAUDE.md`, then `Docs/Plan.md`. It has all decisions, sim results and the locked rules.

## Where we are
- Phase 1 (base loop) locked as `Rules.V2` in `core/rules.gd`.
- Phase 2 steps 1–2 done: Tiers 1 and 2 for all seven Sins, 12.5–15.4% at 7 players with both on. Tables in Plan.md.
- Next: Tier 3 (666, once per game, no cooldowns). Draft kits in Plan.md. Every ability is tagged Before roll / After roll / Gambit.
- Open feel flags from Tier 2 (Plan.md): Sloth's Drag −3 is harsh, Pride's Untouchable barely fires, Greed's Interest is near-passive.

## How Tier 2 is wired
- `Game.tier2` option (`run_sins.gd` turns it on). `Game.t2_available(p)` unlocks at `Rules.TIER2_SCORE` and checks the once-per-round charge; `mark_t2(p)` spends it.
- Hooks in `sins/sin.gd`: `on_other_throw` (Wrath), `gambit` (Greed/Lust/Sloth/Gluttony), `buy_price` (Gluttony), `bounces` (Pride). Tier 1 and Tier 2 live in separate methods because Envy's Mimicry calls only the Tier 1 hooks of a fresh copy of the previous Sin.
- Attacks go through `Game.attack(attacker, target, kind, amount)`, which handles Pride's bounce. Effects wait on `PlayerState` (`reroll_next`, `pact_by`, `drag`) and clear in `_end_turn`.
- Throw order: throw → your pending Fury reroll → opponents' `on_other_throw` → your `after_throw` → Strike check.
- Tier 3 will need a once-per-game flag (`t3_used`) and an unlock at 666, the same way.

## How to run
- Godot 4.7.2 console exe: `%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe`
- `--headless --path C:\Projects\SinnersGambit --script res://sim/run_sins.gd` (~1 min, Tiers 1+2). Add `-- t1` for Tier 1 only. `run_sim.gd` = base-rule sweeps (long); `check_v2.gd` = quick check.
- Parse errors make Godot hang instead of exiting: stop the task, fix, rerun. Don't kill all Godot processes; Ben may have the editor open.
- Type inference: GDScript can't infer from untyped values (`var x := arr[i]`). Use `var x: int = ...`.
- No Python on this machine; use the Edit tool or sed.

## Ben
Plan first, small steps, short replies, one recommendation. Commit locally, never push unless asked. Art direction agreed: gothic illuminated manuscript + stained glass pixel art.
