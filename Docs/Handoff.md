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
