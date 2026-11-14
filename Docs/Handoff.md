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

## UX pass part 3, step 1: sound (2026-11-13)
- `ui/sfx.gd` (owned by the director as `_dir.sfx`): named sound sets, a 16-voice pool, random variant and pitch jitter, a per-sound retrigger gap, and silence while a beat is being skipped.
- Sounds are hooked into the director's phase helpers, so every beat gets them: `_lift` = lift (or dice shake), `fly` = whoosh, `count`/`count_turn` = ticks rising in pitch (falling when a number drains), `stamp` = thud, and `impact(k, snd)` replaces bare `haptic()` at the impact phase (haptic plus a sound sized by k).
- Per-event sounds: throw rattle, nails (the third is heavier), bust bell plus glass crack, bank coins, buy chips, ability glass chime, attack punch, bounce glass, Hubris chime or crack, banner page-fan in and slide out, bot card, win. Seals, plaques, the speed seal, the log strip and the setup Sins all click or press.
- Volumes, gaps, voices and tick pitch range: `ui/tuning.gd` § Sound (`VOL` in dB per sound, `MUTE`).
- Files: Kenney CC0 packs (Casino Audio, Impact Sounds, Interface Sounds), a chosen subset in `assets/audio` with their licences. The web build stays silent (`driver.web="Dummy"`); test sound on TestFlight. iOS uses Godot's default Ambient audio session, so the ring/silent switch mutes the game.

## Part 3, step 2: thumb-zone layout (2026-11-13)
- Rules (Ben): no overlapping hit areas, 12 pt minimum gaps, 44 pt minimum targets, safe-area margins. `tools/ui_audit.gd` checks every visible button on setup, every prompt layout in a game, the Chronicle, plus synthetic 7- and 8-dice prompts, and saves a screenshot per layout: `godot --path . --resolution 1080x2341 --script res://tools/ui_audit.gd -- <out_dir>`.
- Dice counts are one centred row of equal seals (toggle buttons in a ButtonGroup; they only select; the highest count starts selected: brighter wax plus a gold ring). Below, apart: Bank (bronze, left) and Throw N (crimson, right), the only seals that commit. Throw's caption follows the selection. One possible count = Throw alone. Six or more dice wrap to two rows; the confirm seals shrink (captions scale) but stay at least 44 pt.
- Constants in `ui/main.gd`: `TARGET_MIN`, `GAP_MIN`, `SIDE_MIN`. Plaques use `GAP_MIN`. The log strip and speed seal sit inside a 24 px pad (16 pt from the sides). The prompt page's painted margins are drawn at 0.4 scale so five seals fit in one row.
- Still failing the audit: the setup screen (panels 9 pt from the sides, 6 pt apart). It's rebuilt in the Sin selection step.

## Part 3, step 3: painted art set (2026-11-13)
- SpriteCook set (GPT 2.5 Flare, prompt page as style reference; IDs in `assets/art/spritecook-assets.json`): wax seal normal / pressed / cracked (`assets/art/seals/raw`), gold-leaf blackletter numerals 1-9 (the red wax numerals were too faint on a phone), ivory dice with inked pips, marginalia throw hand.
- `tools/bake_art.gd` bakes them: `runtime/seals/{normal,pressed,cracked}.png` (padded square for styleboxes), `runtime/seals/n1..n9.png`, `runtime/dice/1..6.png` (the 2 is re-inked red so both Strike faces stay red), `runtime/throw_hand.png`. New helper `_grid` splits sprite sheets.
- `Art.SEAL` replaces the old seals (`SEAL_L`/`SEAL_S` alias it; cracked = disabled). `Art.numeral(n)`. `main._seal_face(b, n, hand)`: count seals show the gold numeral; Throw shows its numeral plus the hand in the parchment margin to its upper right. Bank stays a bronze tint of the seal with a text caption.
- Thumb-zone page replaced (`runtime/page.png`, 1600x900, from `ui/raw/page_b_b_raw.png`): slim vine border, marginalia only in the corners, 9-sliced with `Art.PAGE_MARGINS` at 0.55 so only the plain vine edges stretch (the old page squashed its side figures about 3.5x).

## Polish pass, items 8 and 11: materials and marginalia (2026-11-13)
- Ben's 12-item polish list (no beat-timing changes) is in Docs/UXPass.md. Items 8 and 11 done first, waiting for Ben's OK before the rest.
- Shaders (`ui/shaders`): `wax_glint` (a specular band sweeps across each seal; the phase is offset per seal so it travels along the row), `gold_shimmer` (on the numeral TextureRects; only the bright gold catches it), `page_light` (a candle pool on the thumb-zone page that follows tilt). Godot 4's fragment `COLOR` already includes the texture, so these shaders don't multiply by `texture(TEXTURE, UV)` again (that darkened everything).
- Tilt: `main._process` reads `Input.get_gravity()` and falls back to a slow sine drift on desktop. It moves the light pool and slides the page `TILT_PX`. Not yet checked on a device.
- Marginalia: a new page with larger corner boxes (`page_c_a_raw.png`, `PAGE_MARGINS` 262/252/262/262) so the figures read bigger. `tools/bake_art.gd` keys the jester, pennant and skeleton out of it (`MARGINALIA` rects; parchment is flooded in from the rect border and stops at ink and saturated colour) into `runtime/marginalia/*.png`. It also fills their spots on the page with parchment. `Art.MARGINALIA` places them, and `main.marginalia` holds them as TextureRects on the page. Director: `flinch(k)` on bust (the jester cowers and shivers) and `cheer(k)` on bank (the skeleton hops and the pennant is raised and waved). Nothing waits on them.
- Tunables: `ui/tuning.gd` § Materials.

## Polish pass, items 4-7 and 12 (2026-11-13)
- 4: Bank and Throw are always `SEAL_CONFIRM` (200 px) in `main._layout_buttons`. Only the count seals shrink (down to 44 pt) and wrap. When the counts overflow the space above, Bank and Throw move to the page edges and the last counts sit between them (8 dice + Bank fits). Past that, the confirm seals shrink as a last resort.
- 5: settle and arrive tweens use `Tween.TRANS_SPRING` (banner in, dice landing, bot card, focus scale, punch return, lift return, marginalia, stamp, pressed seals). Durations are unchanged, so the beat timing is the same.
- 6: seals squash on press (`Tuning.PRESS_SQUASH`), then spring back and rock once on release (`RELEASE_WOBBLE`, `WOBBLE_DEG`). Dice already squash on landing (now springing back).
- 7: `director.my_turn` brings the seals in one by one in reading order, `ENTER_STAGGER` (40 ms) apart, springing up from `ENTER_SCALE`, then starts each one's breathing pulse.
- 12: seals breathe (the existing pulse), the selected ring glows up and down (`RING_PULSE`), and the page's candle pool flickers (`CANDLE_FLICKER`, in `page_light.gdshader`).

## Polish pass, items 1-3, 9 and 10 (2026-11-13)
- 1-2: `main._make_lettering` / `_set_lettering`: the prompt (and the turn line) is a RichTextLabel in blackletter (`Tuning.PROMPT_FONT` 57, +30%). The first letter is a `CAP_SCALE` capital, crimson with a gold edge (the turn line's capital takes the player's Sin colour). The prompt has a thin red pen flourish under it (`_draw_flourish`). `ui/shaders/ink_text.gdshader` gives uneven ink density and a left-to-right reveal across the words, with a wet leading edge; the flourish shares it. The reveal runs from `main._process` with a capped step, not a tween: new words cost a long frame while glyphs rasterise, which swallowed a tween whole. A bot's "thinking..." dots don't re-ink (`key`). The prompt sits in side margins clear of the corner boxes.
- 3: the persistent turn banner is gone; "Your turn" / "Envy's turn" / "X wins" is lettering straight on the desk. Banners remain only for the transient turn-change band (`director._banner_band`).
- 9: thrown dice travel in along the leather while their height bounces (`Die.height`). The die's own shadow stays on the ground while it's airborne, fainter and wider. Each die puffs dust where it lands (`DUST_K`), squashes, and rocks once (`SETTLE_DEG`). Total time is unchanged.
- 10: `main._ink_wash(cover)` (`ui/shaders/ink_wash.gdshader`): ink floods the screen from the centre with a ragged wet edge, then draws away. Used for setup -> game and New game (the reload starts under the ink, `_wash_on_load`). The Chronicle swings open and shut like a page (`_page_turn`). `WASH_TIME`, `PAGE_TURN`.
- Layout: the taller prompt left less room, so pills size their height to fit, and 10+ dice fall back to one grid of 44 pt seals with Bank and Throw ending the last row (12 dice squeezes row gaps to 5 pt; the audit now checks 12). Audit: waits for ink to finish and logs prompts as plain text.

## Main menu, Settings, Continue (2026-11-13)
- `main._build_menu`: the title page is the thumb-zone parchment full screen with the corner figures and candle light, "Sinners' Gambit" inked in as lettering, and three seals (`MENU_PLAY` / `MENU_SEAL`): Play (ink wash to the Sin choice, `_open_setup`), Continue (cracked and dimmed when there's no save), Settings. The seals enter and breathe via `director.seals_enter` (split out of `my_turn`). New game skips the menu and opens on the Sin choice (`_setup_on_load`).
- Settings (`_open_settings`, turns in like a page): Speed 1x/2x/4x, Sound on/off (`Tuning.muted`), Reduce Motion (`Tuning.reduce_motion`: no shake, tilt, idle breathing, candle flicker or figure reactions). Saved in `user://settings.cfg`. "Replay tutorial" joins it with the tutorial.
- Continue = replay. `ui/human.gd` records every answer (`record`; a player as `{"seat": n}`); `main._save_game` writes `user://save.json` after each one: seed, seat order, answers. `_start(null, saved)` rebuilds the same seats and seed, feeds the answers back (`human.replay`) under the ink with every beat skipped, and lifts the ink at your next decision. This works because only the game's seeded generator rolls (ai/ and sins/ use no randomness) and the seat shuffle is saved. A finished game deletes the save. `tests/replay_check.gd` plays to 5/25/60 answers, rebuilds through JSON, and compares every score, dice count, the supply and the prompt.
- Tests and the audit set `main.save_enabled = false`. The audit now covers menu, Settings and setup.
- No way back to the menu during a game yet (Continue matters after the app is closed).

## Pacing pass (2026-11-13)
- Problem (Ben, from the tour video): bot turns took 12-30 s, so with six bots your turn came back after about two minutes.
- Bots play faster: `Tuning.pace` is set per beat by the director (1 on your turn, `BOT_PACE` 2.25 on a bot's); `Tuning.rate()` = speed x pace drives `q.wait`, queue tweens and particles. On a bot's beats the anticipation wait is skipped (`BOT_ANTICIPATION`) and holds are cut to 30% (`BOT_HOLD`), via `director._ant()` / `_hold()`. Your own beats are unchanged.
- No more bot move cards for throws, banks and buys (attacks keep theirs). A bot "thinks" only before its first throw of the turn (`BOT_THINK`). A bot's score is one flight from the dice to the turn total. The bot turn-change band holds `BOT_BANNER_HOLD`.
- Table of 4 by default (you + 3 random Sins), Table of 7 as an option: pills on the setup screen, `Tuning.table_size`, saved in settings.cfg. The seat handicap (20 x seat) still comes from `Rules.V2` in core.
- "Skip to my turn" pill on the thumb page during bot turns (`main._skip`, same as a double tap).
- `tests/bot_pace.gd [-- 4|7]` times bot turns in the real UI at 1x (game time, 4x time scale). Now: table of 4 avg 3.7 s per bot turn (90th pct 5.3, max 7.1), your turn back after about 11 s; table of 7 avg 3.8 s, back after about 22 s. Before: about 7.5 s per bot turn at a table of 4, 15+ s at full beats.
- `tests/ui_autoplay.gd` alternates table sizes. Audit: the setup screen's known gap failures now include the table pills (rebuilt in the Sin selection step).

## Quality pass Phase 1: menu, Settings, HD art; tutorial (2026-11-13)
- HD art (SpriteCook GPT 2.5 Flare, 30 credits each, 240 total; 92 left): seven full-height stained-glass windows `sins/raw/*_hd_raw.png` (Wrath first, then used as the style reference for the rest) and the candlelit table `bg/raw/bg_hd_raw.png`. IDs in `assets/art/spritecook-assets.json`. `tools/bake_art.gd` keys the black around each window (`_key_black`, a flood from the border so the leading survives) into `runtime/sins/*.png` and resizes the table into `runtime/bg.png`. The table's skull and dice still show some chunky texture from the pixel-art reference.
- Menu (`main._build_menu`): a scene, not a page. Dark far wall, the seven windows in a row left of the candle (each breathes slowly and casts an additive shaft of its colour), a flickering light pool on the painted candle (`CANDLE_RAW`, `_desk_point`), soft additive dust motes, then the title (gold lettering with a crimson capital, slow breathing scale) and seals. Play is the big seal; Continue only exists when there's a save. Layers shift with tilt (`_parallax`). `_free_screen()` leaves it.
- Settings: Music and Sound sliders (`Tuning.music_vol`, `sfx_vol`), Haptics, Speed and Reduce Motion as segmented controls, Tutorial (Replay / Next game). Saved in settings.cfg. Panels (Settings, Chronicle) now fade and scale uniformly from the centre (`_page_turn`, `PANEL_FROM`).
- Music: "Cathedral" by Umplix, CC0, OpenGameArt node 132607, loudness-normalised to -18 LUFS into `assets/audio/music/menu.ogg` (licence note beside it). Loops from launch under everything.
- Transition: `ink_wash.gdshader` is now a domain-warped smoke front with an ink core (full-resolution quintic noise, drifts with TIME).
- Particles: bursts use a soft round texture with additive blend (no square pixels). The debug speed slider is off (`SHOW_DEBUG_SLIDER`).
- Chronicle has a "Main menu" button (`_to_menu`); the game is saved after every answer, so Continue resumes it.
- Tutorial (`ui/tutorial.gd`, `ui/shaders/spotlight.gdshader`, `main._tutorial_prompt`): on the first game (settings `tutorial_done`), a spotlight and one line per step over the real first turn. At the first throw prompt: choose dice, Throw. At the first prompt with Bank: scoring, Strikes, bust, Bank, your Sin's Tier 1, first to 1000. Tap to advance; stage taps are ignored while it shows. Tests and the audit set `main.tutorial_enabled = false`.
- Audit: the segmented controls report 0 pt gaps between their own segments (one control by design).

## Second quality pass, Phase 0: rule simplification (2026-11-13)
- Ben's new brief (phases 0-9) replaces the old Phase 2-4 brief. Text approved in `Docs/RulesDraft.md` (five-sentence rules, one-line abilities, three redesigns).
- `Rules.V3` (core/rules.gd) is the default game: `throw_all` (every throw uses all your dice; after a safe throw, throw again or bank; bots `wants_throw`, humans one Throw seal + Bank), `auto_purgatory` (free throw at the start of your turn: any 6 frees you, else pay `purgatory_cost` 50, nothing if you can't; then play on). Greater already unlocks for good at 300. V2 stays for the sim.
- Redesigns: Envy's Mimicry = once a round, add two copies of the previous player's best die (no borrowing). Pride's Hubris = bet 100/150/200, bank at least that for x1.5, else 0 (bot bets 100). Gluttony's Feast 90 -> 50 (closes the feed/rebuy-at-70 loop).
- Bot (ai/bot_policy.gd `wants_throw`): throws again when one more throw then banking beats banking now on average (exact over Strike/blank/scorer counts), never banks short of a Hubris bet, still banks at 300.
- First Game mode (ui/main.gd `is_first_game`, settings `games_finished`): until a game is finished, table of 4, Basic only (`tier2` off), bots at half speed (`Tuning.FIRST_GAME_BOT_PACE`), setup hides the table pills and Greater lines. Saved in the game save (`"first"`, SAVE_VERSION 2). Tests pick it per game (`first_game_enabled`).
- Words removed from screen: Indulgence, Redemption, Supply, Gambit, "II ready" (now "Greater ready").
- Sim (`sim/check_v3.gd`, 4000 games each, win share vs fair = 1.00): V3 ends in 5.7 rounds at a table of 4 (V2 6.2), busts 0.33 per turn (V2 0.22). First Game (4, Basic): Greed 0.60 and Gluttony 0.42 weak; Lust, Envy, Pride ~1.3. With Greater, Envy's new Mimicry is too strong (2.06 at 4, 2.47 at 7); Gluttony 0.23-0.34. Balance is Phase 8.
- Tests: autoplay ALL PASSED (0 SCRIPT ERROR), REPLAY ALL PASSED, PACE PASSED (table of 4 avg 4.0 s). Audit: setup gaps known (Phase 4 rebuild); 7 buy pills overflow the safe area (Phase 7 stepper).

## Menu windows: centred, no parallax, lit glass (2026-11-13)
- Ben: the menu windows weren't centred (they sat left of the candle by design, and the tilt parallax drifted them). Parallax removed from the menu (`_parallax` gone; the parchment's tilt in game stays).
- Windows are a centred row (`Tuning.MENU_WINDOW_MARGIN`). Each window: `menu_glass.gdshader` (panes lit from behind with slow cloud light, a pale sheen sweeping across every `MENU_SHEEN_PERIOD` s; leading stays dark), a breathing halo and a tighter rim glow (`MENU_HALO`), a shaft fanning out from the wall's centre (`menu_shaft.gdshader`: soft edges, drifting streaks; beam coordinates in the vertex colour, since Polygon2D drops UVs without a texture), coloured motes inside the shaft and a light pool where it lands. Reduce Motion freezes the sweep, streaks, motes and breathing.
- Menu seals: each word is sized to fit inside the wax recess (`Tuning.MENU_SEAL_TEXT` / `MENU_SEAL_ROOM`); Continue and Settings seals 230 -> 280 px so their words stay readable. Tagline: "Choose your Sin, push your luck, and be the first to 1000." (true at either table size).

## Second quality pass, Phase 1: rules reference (2026-11-13)
- `ui/rules_text.gd` is the one source of rule text: the five sentences (`FIVE`), rulebook pages (`PAGES`), each Sin's epithet, playstyle, complexity pips, Basic and Greater sentence (`SINS`), the glossary (`TERMS` + every ability name), tutorial lines. Numbers are `{placeholders}` filled by `vals()` from `Rules.V3` and the sins/*.gd constants, so Phase 8 tuning flows through. main.gd's SIN_TEXT / SIN_TITLES and the tutorial strings are gone.
- Rulebook (`ui/rulebook.gd`): Contents (the five sentences + page buttons), Goal, Your Turn, Scoring (worked example), Strikes and Busting, Banking, Purgatory, Buying Dice, Sins and Greater Abilities, Winning, The Seven Sins, Glossary. Illustrated with game art (dice, Strike marks, seals, windows). Serif body 44 px (16 pt). Swipe or Previous / Next. From the main menu (new Rulebook seal) and the game's "?" seal (right of the turn lettering), which opens the page for the moment (`main._context_page`: Purgatory, Buying, Strikes, Banking, Sins, Your Turn).
- Tap-to-explain (`ui/explain_card.gd`, `main._register_explain_targets`): when nothing is playing, tap a window or name (that Sin: playstyle, both abilities with Greater state, status, score), score, dice count, Strikes, This turn, the throw total, the dice tray. Hold 0.45 s to explain at any time, bot turns included; holding the ticker explains the terms in its line. Cards link to their rulebook page. The action queue pauses while a card or the rulebook is open (`ActionQueue.set_paused`).
- Input change: a tap during bot beats now skips on release (was on press), so a hold can explain instead.
- `tests/terms_check.gd`: retired words (Indulgence, Redemption, Gambit, Tier) in no UI/Sin/game string (V2 sim lines are marked `# V2 only`), every logged ability name is a glossary term, every placeholder filled, abilities <= 15 words. TERMS PASSED.
- Audit covers rulebook pages, explain cards and the "?" page; only the known setup-screen failures remain (Phase 4). The audit now ignores buttons scrolled out of a ScrollContainer.
- Pace: table of 4 sits right at the 4.0 s limit since V3 (runs: 4.0 SLOW, 4.0 SLOW, 4.0 PASSED); Phase 1 adds no bot beats. V3 bots throw more per turn and Purgatory now always throws.
- Not done here: the pause menu (Phase 5) will add Rulebook and Sin abilities; Strike text says "marks" until Phase 2's candles; the ticker and Chronicle still show raw log lines (Phase 2).

## Second quality pass, Phase 2: legibility (2026-11-13)
- All new wording is in `ui/rules_text.gd`: `WORDS` (labels, seals, opening card, throw result, score causes; `word(key, args)`), `SAY` (log line -> player language, regex + `$1` captures, `{who}` = whose turn) and `YOU_VERBS` (verb agreement for "You"). `core/` and `sins/` wording is unchanged.
- Opening card (`main._opening_card`): before the first turn of a new game, an explain card with your sigil, epithet and playstyle, your Basic ability (and Greater with its unlock score, outside First Game), the goal, and your seat with its head start. Begin closes it; the queue is paused meanwhile, so the game waits. Gated on `tutorial_enabled` (tests skip it) and new games only (not Continue).
- Plates: "Score" caption above the score, "Dice" before the dice count (the die icon is gone: no room at a table of 7). Plate 172 -> 208 px; windows shrink a little.
- Strikes are three candles (`assets/art/ui/candle.png` cropped, `Art.candle()`, `ui/shaders/candle.gdshader`). Each Strike flies to the next lit candle and snuffs it (`snuffed` tweened over `Tuning.SNUFF`, smoke wisp `director.smoke`). Same beat time as the old nails. Rulebook Strikes art and the glossary/tutorial text say candles.
- Seals: Throw reads "Throw 3" (caption like Bank, the hand stays); Bank reads "Bank 75". Both from `WORDS`.
- Throw result line (`main.result_line`, `_result_label` under the throw total): "6 and 4 score 50, x1.5 = 75. One Strike." / "Nothing scores. Two Strikes." / bust line. Set at the start of the score beat (no added wait), cleared on a new throw and on bank.
- Score causes (`director.cause_tags`): any score change shows a tag above the player's name for `CAUSE_HOLD` 1.5 s real time ("Banked +120", "Bought 2 dice −150", "The Vig +25", "Spark of Rage +40", "Binding Pact", "Purgatory −50"). Own tween, never holds the queue; skipped during skip-to-my-turn and Continue replay.
- Ticker and Chronicle: `Events.say()` maps every V3 log line (director `_line`); Chronicle turn headers read "Wrath's turn (230)" / "Your turn (230)". Unknown lines show as written.
- Grammar: Hubris prompt comma, tutorial Strike line, rulebook strikes caption. Setup's "Choose thy Sin ... shall face thee" left as is (flavour; Ben's call).
- Tests: autoplay ALL PASSED and REPLAY ALL PASSED (0 SCRIPT ERROR), TERMS PASSED, PACE PASSED (table of 4 avg 3.8 s, twice; no new bot waits). Audit at 1080x2341 matches the pre-Phase 2 baseline exactly: only setup, Settings segmented rows and the synthetic 12-dice prompts fail, as before.

## Second quality pass, Phase 3: scripted tutorial (2026-11-13)
- The old spotlight tour over a real first game (`main._tutorial_prompt`) is gone. The tutorial is now a short scripted game: you as Envy in the first seat against a Sloth bot, table of 2, Basic only, bots at First Game pace, never saved (Continue keeps your real game). The first Play goes to it (settings `tutorial_done`); Settings > Tutorial > Play replays it (reloads the scene with `_tutorial_on_load`).
- Rigged dice without touching `core/`: every throw in `core/game.gd` is drawn from `game.rng` through `Rules.roll()` right after a moment the UI controls. `ui/tutorial_dice.gd` finds a seed that makes `Rules.roll()` give the wanted faces (6^4 = 1296 tries on average for four dice; all seeds are found when the tutorial starts) and sets it on `game.rng` just before the draw: when your act step lights Throw, in `ui/tutorial_bot.gd` (a ui/ subclass of the bot that throws and banks by script, never buys), and in `turn_started` for the Purgatory throw.
- Script (`ui/tutorial_game.gd` SCRIPT, one dict per step: `on` prompt / throw / end / purgatory, `say`, `spot`, `do`, `faces`): welcome; Throw 6 4 3 (75, two scorers x1.5); Throw again 6 5 1 (one Strike, 157); Bank; Buy 1 (4 dice, 57); Sloth throws 6 4 3 and banks; Throw 4 3 3 2; Green-Eyed Glance, Yes (adds Sloth's 6: 75, one Strike); Throw 1 2 5 3 (bust, Purgatory); Sloth banks; Purgatory throw 6 3 2 5 (free); end card with Play (the Sin choice) and Menu.
- Hooks in main: `show_prompt` blocks the new prompt (`overlay.block()`) then awaits `_tutor.on_prompt()`; `beat` awaits `_tutor.on_beat(p, kind)` after the queue drains, so core waits on read steps; `turn_started` calls `on_turn_started`. Every prompt button now carries `meta("value")` so a step finds its button by kind and value.
- Overlay (`ui/tutorial.gd`): up for the whole tutorial. Idle passes every tap; read takes every tap (tap to continue); act lets taps through only inside the spotlight (`_has_point`), the other prompt buttons are disabled, and the spotlight follows the button's resting rect while it springs in. Skip (top centre, live always) ends it: the Sin choice on the first run, the menu from Settings. Tap / hold to explain, Skip to my turn and "?" are off in the tutorial.
- All wording is in `RulesText.TUTORIAL` (`tutorial(key, args)`, `{ability}` = Envy's Basic line).
- Tests: `tests/tutorial_check.gd` (new) checks every seed through `Rules.roll`, every TUTORIAL placeholder, then steps the whole script headless: exactly one live button inside the spotlight on each act step, faces / scores / Strikes / Purgatory at each step, end card reached, Skip marks it done. TUTORIAL PASSED (15 steps). Autoplay ALL PASSED and REPLAY ALL PASSED (0 SCRIPT ERROR), TERMS PASSED. Audit at 1080x2341 now also walks every tutorial step: all ok; only the known setup, Settings segmented rows and synthetic 12-dice failures remain. Pace: 4.1 SLOW, 4.1 SLOW, 3.9 PASSED; HEAD before this change gave 4.0 PASSED, 4.0 SLOW on the same machine (no bot beats added; tutorial hooks are inert outside the tutorial). `sim/check_v3.gd` output is identical to HEAD.
- Found, not fixed: `sim/run_sim.gd` (the CLAUDE.md sim command) hasn't parsed since `cf24783` ("play() is a coroutine, must be called with await", lines 141 and 161); `sim/check_v3.gd` is the working runner.

## Second pass Phase 3.5: art and audio style (2026-11-14)
- Art (SpriteCook GPT 2.5 Flare, medium, the wrath HD window as style reference; 60 credits, 32 left; IDs in `assets/art/spritecook-assets.json`): one seal sheet with normal / pressed / cracked in a row (`seals/raw/seal_set_v2_raw.png`), painted ivory dice 1-6 with both Strike faces inked red (`dice/raw/dice_v2_raw.png`), a stained-glass throw hand (`extra/raw/throw_hand_v2_raw.png`). Same painted ink-and-gold-leaf look as the Sin windows, replacing the glossy wax, photo bone and flat marginalia.
- `tools/bake_art.gd` now reads them: the seal sheet is split three ways (`_split`), the dice need no re-inking (`_red_ink` stays for reference), same runtime files and sizes, so no layout code changed. The old raws stay.
- Audio style: `Docs/AudioStyle.md` ("in the nave": stone room, bells / wax / parchment / bone, low and dark, tension rises in pitch, one gesture per outcome).
- `tools/bake_audio.gd` synthesizes the bells (headless, fixed seed) into `assets/audio/synth_*.wav`: count pings, bank (two strikes a fifth apart), bust toll, small toll, ability chime, win (minor organ chord under a bell).
- `ui/sfx.gd`: builds a `Nave` bus at start (reverb plus low-pass, sent to Master; music stays dry); `Tuning.SFX_DRY` (plaques, ticks) play dry; `Tuning.SFX_PITCH` sets a base pitch per sound (parchment, wax and iron pitched down); `LAYERS` adds the small toll under the third nail. Casino sounds are gone: bank = bells, buy = a die on wood, bot card = parchment, win = the organ chord (the director's win beat now plays only that, not the bust toll plus coins).
- Tuning: `VOL` rebalanced, `TICK_PITCH` 0.8-1.35, `NAVE_*` reverb settings.
- Tests: ALL PASSED (autoplay), REPLAY ALL PASSED, TERMS PASSED, TUTORIAL PASSED, PACE PASSED (avg 3.6 s); audit at 1080x2341 shows only the known setup, Settings segmented-row and synthetic 12-dice items. Headless runs are silent, so the sound has not been heard yet.

## Second pass Phase 4: Sin select carousel (2026-11-14)
- `ui/sin_carousel.gd` (new, a VBoxContainer built by `main._build_setup`): one page per Sin, side by side on a track inside a clipped view. Each page: the lit lancet window (`Art.window`, menu_glass sheen), "Name, epithet" in the Sin's colour, the playstyle line, then the Basic ability (and Greater outside First Game) with the ability name in gold. Swipe follows the finger (rubber-banded at the ends); past `SELECT_TURN` of the width or a flick over `SELECT_FLICK` px/s turns the page, else it springs back (`TRANS_SPRING`, `SELECT_SNAP`). Left / right keys turn it too (desktop).
- Opens on Sloth, which wears a crimson "Recommended" ribbon across the foot of its window.
- Page dots: seven dots in the Sin colours, the current one larger with a gold ring. They're drawn, not Buttons: the whole 44 pt strip is the touch target and a tap goes to the nearest dot (seven 44 pt buttons with 12 pt gaps don't fit 393 pt).
- Ambient light: an additive soft glow behind the window in the current Sin's colour, cross-fading on each page (`SELECT_LIGHT_FADE`) and breathing (`SELECT_LIGHT_BREATHE`, off with Reduce Motion). It's kept inside the clipped view so its edge is never cut.
- Stings: `tools/bake_audio.gd` `_stings()` synthesizes `assets/audio/synth_sting_<sin>.wav` (keys and gestures in `Docs/AudioStyle.md`; the existing bells bake byte-identical). `ui/sfx.gd` adds a `sting_<sin>` set each and `play_solo()`: one outcome voice at a time on the Nave bus, a new sting fades the last out over `SOLO_CUT`. A sting plays when a page settles, and for Sloth once the ink draws back on opening.
- Below the carousel: the table size as one segmented control (`_segmented(..., on_dark = true)`: dark fill, gold frame, bone words; hidden in First Game) and a Choose seal (`SELECT_CHOOSE`) that starts `_start(SIN_SCRIPTS[car.index])`. Tapping the window doesn't start a game, so a swipe can't choose by accident.
- Deleted: the seven mosaic banners, `ui/widgets/glass.gd` and `ui/shaders/stained_glass.gdshader` (nothing else used them), `Style.GLASS_SHADER`.
- Words: `RulesText.WORDS` `setup_*`. Tuning: `ui/tuning.gd` § Sin select, `VOL` `sting_*`, `SOLO_CUT`.
- Audit: the setup page now uses 17 pt side margins and 13 pt gaps; `tools/ui_audit.gd` also screenshots the Wrath page, and treats segments of one control (same ButtonGroup) as one target, which clears the Settings and table-size items. Setup, Wrath page and Settings: ok. Only the known synthetic 12-dice items remain.
- Tests: ALL PASSED (autoplay, 7 games), REPLAY ALL PASSED, TERMS PASSED, TUTORIAL PASSED (15 steps), PACE PASSED (avg 4.0 s); 0 SCRIPT ERROR in every log. No SpriteCook credits used (32 left). Stings not yet heard (headless runs are silent).

## Second pass Phase 5: game layout (2026-11-14)
- Zones: the board is three stretch zones, `Tuning.ZONE_GLANCE / ZONE_TRAY / ZONE_THUMB` = 24 / 46 / 30, so the tray is about 40% of a 1080x2341 screen once the safe areas are taken off. "Your turn" lettering now sits inside the top of the tray with the pause seal at its right.
- Removed: the ticker strip (Ben chose to remove it) (and `show_ticker`, `_explain_ticker`, the director's `_line`), the "?" seal, the 1x/2x/4x speed seal (`_cycle_speed`; Speed stays in Settings). The Chronicle is reached from the summary or the pause menu.
- Pause menu (`main._open_pause`, an overlay, so the queue waits): Resume, Rulebook (at `_context_page()`, as "?" was), Sin abilities (`open_rulebook("all_sins", names)`: the rulebook's Sins page with only this table's Sins, `Rulebook.only_sins`), Chronicle, Settings (opens over it), Main menu. Hidden in the tutorial.
- Bot-turn summary (`_summary` on the parchment page, between the corner boxes, above Skip to my turn): older lines drop off when they would overflow (`_summary_fit`); Greed's name uses `Tuning.SUMMARY_NAME` (silver is unreadable on parchment). a bot's turn adds a line "Wrath: ...", and the director calls `summary_event()` after each beat of a bot turn: bank "(now N)", bust "lost N", buy, ability, attack ("Fury on you", `RulesText.ATTACK_NAMES`), left / stays in Purgatory. Your turn clears it; any prompt hides it (`_show_prompt_now`), `clear_prompt` brings it back. At most `SUMMARY_ROWS` (6) lines. Tap: the Chronicle. Not in the tutorial. Words: `RulesText.WORDS` `sum_*`.
- Windows: `Art.window_crop(sin, ratio, top)` crops the lancet art to the arch and figure (`WINDOW_CROP` 1.8, per-Sin start `WINDOW_CROP_TOP`, all 0 for now), cached; headless (no pixels) falls back to the whole window.
- Status badges replace the status word that used to overwrite the name: a disc per status down the window's right edge (`_badge`, drawn: Purgatory flame, Greater-ready star, Dragged chevron, Pact rings; colours `Tuning.BADGES`), springing on when new. The snapshot carries `badges`. A tap on a badge explains its term (`RulesText.BADGE_TERMS`). The name stays and turns red in Purgatory.
- Leader: a drawn gold crown over the window of everyone on the top score (none at 0), springing on (`_refresh_crowns`, `CROWN_SIZE`). You: a gold frame and a wash of your Sin's colour behind your whole column, and "You" in gold.
- Audit: `tools/ui_audit.gd -- <out_dir> [table size]` (the size is set after main's `_ready`, which loads the saved one), and now screenshots the pause menu and the bot-turn summary. Run at 4 and 7.
- Tests: ALL PASSED (autoplay), REPLAY ALL PASSED, TERMS PASSED, TUTORIAL PASSED (15 steps), 0 SCRIPT ERROR in every log. Pace: 4.1 SLOW, 4.0 SLOW, 3.8 PASSED over three runs (the known ~4.0 s noise; no bot beats were added). Audit at tables of 4 and 7: pause menu and bot-turn summary ok; only the known synthetic 12-dice items remain (the 7+ buy pills overflow too, Phase 7). No SpriteCook credits used.
- Seen, not fixed (Phase 6): an ability's marginalia note (e.g. "Hubris: bets 100") now lands over the turn lettering at the top of the tray.

## Second pass Phase 6: feedback (2026-11-14)
- Score strip (`main._score_zone`): a fixed-height band between the dice and the "This turn" row holding one thing at a time: the throw total (`_throw_label`, `SCORE_SIZE` now 116) over its result line, or an ability note. Flying points land in it; nothing lands on the dice or the labels and nothing reflows.
- No "+0": a throw that scores nothing leaves the total blank and the result line ("Nothing scores.") gives the knock; `_refresh` never writes "+0" either. The first die's points write the total directly instead of counting up from 0.
- Multiplier: it joins the line as one fixed number ("+9  x1.5", the real chain multiplier via `RulesText._mult`, not pts / base), then the total snaps to the product. No count through fractions. The Hubris stamp reads `Pride.MULT` (it said a stale "x1.6").
- Ability notes (`main._marginalia`) now take the strip: the ability in its Sin's colour, then what it did (`Tuning.NOTE_SIZE`); the total and result line fade under it and come back with `clear_note`. One at a time. `reset_strip()` at each throw. They no longer cover the turn lettering.
- Stamps (BUST, Free! / Still in Purgatory, Hubris x1.5 / fails) sit astride the tray's top edge (`director._above_tray`), not on the dice.
- Dice: one size at any count (`main.die_side()`): the largest that fits `Tuning.TRAY_DICE` (18) in rows of `DICE_PER_ROW` (6) with `TRAY_MARGIN` and `DIE_GAP`, capped at `DIE_SIZE` 150. On 1080x2341 that's 114 px. To get there: zones 24 / 46 / 30 became 21 / 49 / 30 (windows a little smaller, tray about 44%), Strike candles 52x150 -> 40x110. Taking it from the parchment page instead (26) shrank the seals under 44 pt.
- Added dice: the snapshot's turn carries `added` (faces past `game._max_throw`) and `tint` (the thrower's Sin colour); `main.show_turn_dice(t)` draws them washed in that colour with a rim (`ui/widgets/die.gd` `tint`, `Tuning.ADDED_TINT / ADDED_RIM`). They're thrown in from the Sin's window with the same tumble as a throw (`director._tumble`, factored out of `_throw`; `_change_dice`).
- Fixed in passing: an ability that changed the dice after its own beat (Envy adds, Lust swaps, Gluttony feasts, bounced Fury) never showed on the leather before the throw scored, because `fired()` logs before the change. `_strikes` (start of every score / bust beat) now shows the change first.
- Audit: `tools/ui_audit.gd` adds `_audit_tray`: 18 dice (3 added) must sit inside the margin and clear of the strip at no less than `Tuning.DIE_MIN` (110), plus a screenshot of an ability note in the strip. Tables of 4 and 7: only the known synthetic 12-dice gaps (Phase 7).
- Tests: ALL PASSED (autoplay, 7 games), REPLAY ALL PASSED, TERMS PASSED, TUTORIAL PASSED (15 steps), 0 SCRIPT ERROR in every log. Pace: 4.2, 4.1, 4.1 s (SLOW by the 4.0 line; Phase 5 was 3.8-4.1). The extra ~0.1-0.2 s is the ability dice changes that now show on bot turns; the lead wait before them is cut when they come ahead of a score beat. No SpriteCook credits used (32 left).

## Tour video and walkthrough (2026-11-14)
- `tools/tour.gd` drives the real game for a video: menu, Settings, six rulebook pages, the whole tutorial, the Sin carousel, then a full unrigged game as Envy at 1x (throw, yes to every ability, bank at 150 or two Strikes, first buy offer), with the pause menu, an explain card and the Chronicle. It saves a JPG still per moment (`<out>/shots`). Record with Movie Maker at 30 fps; the project's window override is 540x960, so put a temporary `override.cfg` beside project.godot with `window/size/window_width_override=720` / `window_height_override=1560`, then delete it. ffmpeg (winget Gyan.FFmpeg) encodes the AVI to MP4. Output in `build/` (ignored): `SinnersGambit_tour.mp4` (5:43), `SinnersGambit_tour.html` (the walkthrough with stills embedded).
- `Docs/Tour.md`: the written version (visuals, VFX, UX, audio per screen and per beat), stills in `Docs/tour/`.
- Fixed from the footage: (1) `director._punch` sprang back to whatever scale it started from, so punches landing mid-spring (each die's points hitting the score line) ratcheted the label up to 1.26x and long lines ran off the tray. Punches now always return to 1. (2) The score strip's labels clip (`clip_text`) and `main.set_throw()` fits the big line to the strip's width ("+105  x2.5", "Purgatory: a 6 frees you"). Tests: all passed, pace 4.0 s; audit at 4: only the known 12-dice gaps.
