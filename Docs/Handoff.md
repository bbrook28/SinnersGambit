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

## Playtest UI (2026-11-13)
- `ui/main.tscn` (main scene): pick a Sin, play 6 bots (the other Sins), Rules.V2 + Tiers 1-2. Built in code, placeholder look.
- `core/game.gd` awaits every decision and Sin hook; `ui/human.gd` answers from buttons. Bots answer at once, so the sim never suspends (run_sins output verified identical, default and `-- t1`). `game.view` (null in sim) gets log lines and paces bot turns.
- Sins branch on `me.bot.human`: bots keep their heuristics, the human gets a yes/no whenever the ability is legal, and a target pick (with Skip) for Pact/Drag.
- `tests/ui_autoplay.gd`: one full UI game per Sin with random button presses, headless.
- Web: `export_presets.cfg` "Web" preset (single-threaded) -> `build/web`. Export: `--headless --path . --export-release "Web" build/web/index.html`. Templates in %APPDATA%\Godot\export_templates\4.7.2.stable (web only).
- Serve on Wi-Fi: `powershell -ExecutionPolicy Bypass -File tools\serve.ps1` (prints the phone URL, port 8000).
- Plain HTTP on a LAN IP is not a secure context: the Web preset head_include skips Godot's secure-context check, and `audio/driver/driver.web="Dummy"` (no AudioWorklet without HTTPS). When the game gets sound, serve over HTTPS or use TestFlight instead.

### Rule questions the UI raised
- Feast: the UI feeds your lowest die (Strikes first); the rule lets you pick any die.
- After-throw abilities are offered before the Strike check, every throw until used, so the human can save Glance/Whisper/Feast for a later throw. Bots never wait.
- Untouchable: the human may decline a bounce to keep it; the rule reads as automatic. Bots always bounce.
- Fury: the human can Fury any scoring throw; bots only at 150+. The rerolled dice are always the best scorers (no choice).
- Mimicry on Wrath/Greed borrows a passive that does nothing on your own turn; the prompt still offers it.
- Interest fires automatically whenever Greed buys nothing (no prompt).
- Indulgence is offered only when you can afford it; otherwise you roll for Redemption.
