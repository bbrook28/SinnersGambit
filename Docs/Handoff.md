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
Plan first, small steps, short replies, one recommendation. Commit locally, never push unless asked. Art direction agreed: gothic illuminated manuscript + stained glass, HD painted (pixel art dropped 2026-11-13).

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

## TestFlight (no Mac)
- Repo: github.com/bbrook28/SinnersGambit (private; was FPS_TechDemo). `origin` points there.
- `.github/workflows/ios.yml` is Sumo Scuffle's pipeline minus SumoNative and the Game Center entitlements step. Bundle ID `com.benbrook.sinnersgambit`, team 5ZPNDCA2QG, iOS preset in `export_presets.cfg`, placeholder icon `assets/icons/icon_1024.png`.
- Run: `gh workflow run ios.yml --repo bbrook28/SinnersGambit --ref main` (xcode27 off by default: the xcode-27 runner is a paid larger runner; macos-15 is free on a public repo). Build number = 100 + run number.
- Needs once: secrets ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_P8 (same App Store Connect key as Sumo), and an App Store Connect app record for the bundle ID.

## Look pass, step 1 (2026-11-13)
- Art briefs: `Docs/ArtDirection.md` (art direction, depth and feel, Sins as characters, tooling). Read it before any visual work.
- `ui/style.gd`: palette, Sin colours, fonts (Pirata One for numbers/headers, IM Fell English for body; Fell has only old-style figures, so `Style.body`/`Style.numbers` set every number in Pirata), wax-seal button theme, page styleboxes.
- Shaders in `ui/shaders/`: `candle_bg` (vignette, flicker, grain), `stained_glass` (Voronoi panes, leading, glow/dim), `grain` (panel surface).
- Widgets in `ui/widgets/`: `glass.gd` (stained-glass panel container), `frame.gd` (manuscript page), `die.gd` (bone die, code-drawn), `strikes.gd`.
- Layout: seat-order glass portraits, banner with drop cap, dice tray, your Sin's window, parchment prompt with wax seals (bottom third), log ticker (tap = Chronicle) and fast-bots seal. Safe-area insets from DisplayServer.
- Everything is code-drawn placeholder in the right style. Next (step 2+): SpriteCook art (Sin characters, dice, borders), juice, depth/parallax, touch/fling, haptics, 3D tray.

## Look pass, step 3: v3 board (2026-11-13)
- `ui/main.gd` board rebuilt to the iPhone three-zone layout (Docs/ArtDirection.md § iPhone layout, Docs/ArtAudit.md): Glance 25% (seven SpriteCook windows over brass plates, current Sin glows), Stage 45% (tinted turn banner with drop cap, leather tray, score as hero, Strikes as nails), Thumb 30% (darkened page; Roll = big crimson seal under the right thumb, Bank = bronze seal on the left, fewer dice as small seals, other choices as plaques). Log strip taps open the Chronicle; Fast seal sits beside it, clear of edges.
- Art helpers in `ui/art.gd`; runtime textures baked by `tools/bake_art.gd` from `assets/art/*/raw` (ignored by Godot). Shaders: `flare` (window glow/dim), `tint` (banner/Bank recolour).
- `debug_safe` on main fakes notch/home insets for desktop screenshots.
- Numbers in Cinzel Bold (`Style.NUMERAL`, gold-leaf shader via `Style.number`); blackletter for words only. Bone dice art in `ui/widgets/die.gd` (scorers raised and lit, others sunk); painted desk background `runtime/bg.png`.
- Sin windows live: idle shimmer (`flare` shader, `phase` per seat) and ability flare (`flash` + scale punch) with a marginalia note under the plate, all driven from the ability log line in `main._ability_fired`.
- Still old: setup screen and Chronicle overlay widgets. Next: VFX (Docs/VFX.md), app icon.

## UX pass, step 1: action queue (2026-11-13)
- Plan and per-event beats: `Docs/UXPass.md`.
- `ui/action_queue.gd`: every log line, turn change and prompt is a queued beat; `view.beat()` drains the queue, so the rules never run ahead of the screen. Speed 1x/2x/4x (seal by the log strip, saved in `user://settings.cfg`). Tap = finish beat, double tap = skip to your next decision.
- `ui/events.gd`: log line -> event kind + beat length (regex table; unknown lines get a 0.35 s log beat).
- `main._refresh(snapshot)` draws state copied when the event happened; the per-frame live refresh is gone.

## UX pass, step 2: directed presentation (2026-11-13)
- Ben's rules: one focal point at a time, four phases per beat (anticipation 0.3, action 0.4, impact 0.15, hold 0.4), values travel source to destination then count up, full-width turn banner (0.35 in, 0.8 hold, 0.35 out), bot think 0.6 + chosen move enlarged at centre, pulse what you can tap and hint Roll after 4 s idle, bigger results get bigger staging.
- `ui/tuning.gd`: every duration and intensity; `Tuning.speed` is the global multiplier (debug slider top right, `SHOW_DEBUG_SLIDER`; the seal steps 1x/2x/4x; saved in `user://settings.cfg`).
- `ui/director.gd`: focus (dims other groups to `DIM`), fly / count / punch / lift / shake / burst / flash / stamp / haptic, and one handler per event kind. Anything unhandled goes through `_effects_from`, which flies every changed number from a source to its plate or the turn total.
- `main._refresh(snap, parts)` draws only the parts a beat hasn't animated itself. Dice sit in fixed holders (`main._dice_nodes`) so they can be thrown and spun.
- At 1x a bot turn is about 20 s. Not yet done: Sin windows reacting, light shafts, haptics checked on device.
