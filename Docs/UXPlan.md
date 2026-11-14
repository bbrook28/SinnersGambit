# Second quality pass: handoff (2026-11-14)

Single starting point for a fresh session. Detail per finished phase: `Docs/Handoff.md`. Beat table: `Docs/UXPass.md`.
Ben approves each phase: send a short plan, wait for his OK, build, stop for him to play. Commit locally, push only when he says.
Never touch `core/`, `sins/` or `ai/` without his explicit OK.

## Phases (next: Phase 7 review)
- **0 Rules simplification: done.** `Rules.V3`: throw all dice, automatic Purgatory, First Game mode, three Sin redesigns (`Docs/RulesDraft.md`).
- **1 Rules reference: done.** Rulebook from menu and "?", tap / hold to explain, all text in `ui/rules_text.gd`.
- **2 Legibility: done.** Opening card, Score/Dice captions, Strike candles, "Throw 3" / "Bank 75", throw result line, score causes, player-language ticker.
- **3 Scripted tutorial: done** (`ad34895`). Practice game vs Sloth with rigged dice; replay from Settings > Tutorial.
- **3.5 Art and audio style: built, waiting for Ben to play** (`b99da21`). Painted seal / dice / throw-hand art (60 credits, 32 left). Audio style in `Docs/AudioStyle.md`; synthesized bells (`tools/bake_audio.gd`), a Nave reverb bus, darker base pitches, no casino sounds.
- **4 Sin select carousel: built, waiting for Ben to play** (`8d77f96`). `ui/sin_carousel.gd`: one Sin per page, swipe or tap a dot, opens on Sloth (Recommended ribbon), Sin-coloured glow, a synthesized sting per Sin (`play_solo`, Nave bus), table-size segmented control, Choose seal. The mosaic banners and `ui/widgets/glass.gd` are gone.
- **5 Game layout: built, waiting for Ben to play.** Tray about 40% (zones `Tuning.ZONE_*`), "Your turn" and a pause seal inside it; the ticker, "?" and speed seals are gone. Pause menu: Resume, Rulebook (page for the moment), Sin abilities (this table only), Chronicle, Settings, Main menu. Bot-turn summary on the parchment during bot turns (tap: Chronicle). Windows cropped to the arch and figure (1:1.8), status badges on their corner (the name stays), a crown over the leader, a gold frame round your column.
- **6 Feedback: built, waiting for Ben to play.** A reserved score strip between the dice and the turn row holds one thing at a time: the throw total over its result line, or an ability note (which no longer covers the turn lettering). No "+0"; the multiplier joins the line as a fixed "x1.5", then the total snaps. BUST, Free! and Hubris stamps sit on the tray's top edge. Envy's added dice are tinted in its colour and thrown in from its window. One die size at any count: what fits `TRAY_DICE` (18) in rows of 6 with margins (114 px on 1080x2341); zones now 21 / 49 / 30, candles shorter. Ability dice changes (Envy, Lust, Gluttony, Fury) now show before the throw scores.

**Rework (Ben, 2026-11-14): Balatro is the quality bar.** Phases 7-11 below replace the old 7-10 (Controls, Mechanics, Polish, VFX). One phase per session. Phase 7 and Phase 8's balance work on Opus; 9-11 fine on Sonnet. Acceptance from Phase 9 on: re-record the tour; no wait over 1.5 s without input, no sentence in the play field, no overlapping text, no empty zone on your turn, every button painted; report failures with timestamps.
- **7 Run design doc: drafted, waiting for Ben's review.** `Docs/RunDesign.md`: solo runs of 7 Circles (two trials and a ruling Sin each, 4 turns a round), Points x Mult, 30 relics, shop and gold, cuts, meta, 8 terms. No code until approved.
- **8 Core loop: not started.** Build the run, targets, ruling Sins, shop and relics with placeholder presentation. Sim: win rate per Sin, relic pick rate (none above twice the average).
- **GATE after 8:** Ben plays 10 runs and shows 5 people. No Phase 9 until he says the loop is fun; otherwise revise RunDesign and repeat 8.
- **9 Board, text, controls: not started.** Permanent readouts (target, Points, Mult, turns left, Strikes, gold), max 4 words per label, two-line tooltips, Points gold / Mult crimson everywhere, dice twice the size, relic row, controls dim instead of vanishing, Throw seal 22%+ of width with bust chance, one painted button language, serif body text, 6-step learn-by-doing tutorial, rulebook = collection + 3 pages, new run in two taps.
- **10 Motion: not started.** 3D rigid-body dice in a SubViewport (cost estimate first; pre-rendered tumble sheets as fallback), one-piece-at-a-time scoring with rising pitch, target-passed fire, idle wobble everywhere, background reacts to Mult, dimming no lower than 70%, ruling-Sin entrances, bust burns the page, staged win and loss.
- **11 Meta and ship: not started.** Unlocks, collection, Vows, stats, daily run, audio limiter, app icon, tutorial on a real iPhone, 60 fps on the oldest device.

## Where the extra items go
- Main menu: built in the first quality pass (Docs/Handoff.md § Quality pass Phase 1, § Menu windows). Further menu work goes in Phase 9.
- Audio style definition and restyle (stylized gothic, not realistic foley): Phase 3.5, so Phase 4's per-Sin stings are made in that style. The limiter stays in Phase 9.
- New seal / dice / throw-icon art: Phase 3.5.
- App icon: Phase 9.

## Standing rules for every new screen
- Every event is a queued beat (`ui/action_queue.gd`): anticipation, action, impact, hold. The board draws the snapshot of the last beat played, never live state. Nothing jumps.
- Your buttons appear only when the queue is empty. A tap finishes the current beat; a second tap skips to your next decision; a hold explains.
- Bot beats run `BOT_PACE` faster, with no anticipation wait and a 30% hold. A bot turn must stay under 4 s at 1x (`tests/bot_pace.gd`; it hovers at 4.0 s, treat that as noise).
- Animation: springs (`TRANS_SPRING`) on every scale and position change; squash and stretch on press, release and landing; rows enter `ENTER_STAGGER` apart; idle elements breathe. Reduce Motion swaps shake, flash, tilt and breathing for fades.
- Bank and Throw seals keep a fixed size (`SEAL_CONFIRM`); only the number row reflows.
- All on-screen wording in `ui/rules_text.gd`, numbers through `vals()`. Preload consts, no `class_name`.
- Tuning: `ui/tuning.gd` holds every duration and intensity (seconds at 1x). Global speed is `Tuning.speed` (0.25-4), set by Settings > Speed. The on-screen debug speed slider is `Tuning.SHOW_DEBUG_SLIDER` (off), built by `_build_speed_slider()` in `ui/main.gd`.

## Audit
`tools/ui_audit.gd`, windowed: `godot --path . --resolution 1080x2341 --script res://tools/ui_audit.gd -- <out_dir> [table size]` (run it with 4 and 7). Checks every visible button for 44 pt size, 12 pt gaps, side margins and the safe area, and screenshots each layout.
Still open:
- 7+ buy pills overflow the safe area; synthetic 12-dice prompts (Phase 7). The only items left; segments of one control (same ButtonGroup) now count as one target.

## Decisions made
- In-game Sin windows are cropped to the arch and figure (1:1.8, `Art.window_crop`; per-Sin start in `Tuning.WINDOW_CROP_TOP`). Done in Phase 5.
- Bank and Throw seals stay a fixed size at any dice count.

## Bugs to fix before their phase
- Fixed 2026-11-14: after a scoring throw the big throw number showed the sum before the multiplier (+50 next to "x1.5 = 75"). The last die's count landed after the multiplier count (`fly()` has a fade-and-pop lead); `_score` now waits for it (`FLY_LEAD`).
- **Before Phase 8:** CLAUDE.md's sim command runs `sim/run_sim.gd`, which hasn't parsed since `cf24783` (play() is a coroutine, lines 141 and 161). Point it at `sim/check_v3.gd`.

## Phase 8 balance notes (`sim/check_v3.gd`, 4000 games each)
- Envy's Mimicry is too strong with Greater on (win share 2.06 at a table of 4, 2.47 at 7; fair = 1.00).
- Greed (0.60) and Gluttony (0.42; 0.23-0.34 with Greater) are weak.
- Clean up the numbers in `Docs/RulesDraft.md` (§ Numbers that break "multiples of 5 / clean", and the Gluttony Feast/Gorge loop).

## Untested
- The tutorial has not been played on a device.
- Phase 3.5 sound has only been checked by tests (headless runs are silent); the new art only in audit screenshots.
- Phase 4 stings and the swipe feel have not been heard or played; the carousel only in audit screenshots.
- Phase 5 layout seen only in audit screenshots (tables of 4 and 7); the pause menu and summary not tapped by hand.
- Phase 6 seen only in audit screenshots; the score-strip timing, the tinted dice flying in from Envy's window and BUST on the tray edge not watched in motion. Bot pace now 4.1-4.2 s (see Handoff § Phase 6).

## Tests to keep passing
`tests/ui_autoplay.gd`, `tests/replay_check.gd`, `tests/terms_check.gd`, `tests/tutorial_check.gd`, `tests/bot_pace.gd`, `tools/ui_audit.gd`.
