# Second quality pass: handoff (2026-11-14)

Single starting point for a fresh session. Detail per finished phase: `Docs/Handoff.md`. Beat table: `Docs/UXPass.md`.
Ben approves each phase: send a short plan, wait for his OK, build, stop for him to play. Commit locally, push only when he says.
Never touch `core/`, `sins/` or `ai/` without his explicit OK.

## Phases (next: Phase 7)
- **0 Rules simplification: done.** `Rules.V3`: throw all dice, automatic Purgatory, First Game mode, three Sin redesigns (`Docs/RulesDraft.md`).
- **1 Rules reference: done.** Rulebook from menu and "?", tap / hold to explain, all text in `ui/rules_text.gd`.
- **2 Legibility: done.** Opening card, Score/Dice captions, Strike candles, "Throw 3" / "Bank 75", throw result line, score causes, player-language ticker.
- **3 Scripted tutorial: done** (`ad34895`). Practice game vs Sloth with rigged dice; replay from Settings > Tutorial.
- **3.5 Art and audio style: built, waiting for Ben to play** (`b99da21`). Painted seal / dice / throw-hand art (60 credits, 32 left). Audio style in `Docs/AudioStyle.md`; synthesized bells (`tools/bake_audio.gd`), a Nave reverb bus, darker base pitches, no casino sounds.
- **4 Sin select carousel: built, waiting for Ben to play** (`8d77f96`). `ui/sin_carousel.gd`: one Sin per page, swipe or tap a dot, opens on Sloth (Recommended ribbon), Sin-coloured glow, a synthesized sting per Sin (`play_solo`, Nave bus), table-size segmented control, Choose seal. The mosaic banners and `ui/widgets/glass.gd` are gone.
- **5 Game layout: built, waiting for Ben to play.** Tray about 40% (zones `Tuning.ZONE_*`), "Your turn" and a pause seal inside it; the ticker, "?" and speed seals are gone. Pause menu: Resume, Rulebook (page for the moment), Sin abilities (this table only), Chronicle, Settings, Main menu. Bot-turn summary on the parchment during bot turns (tap: Chronicle). Windows cropped to the arch and figure (1:1.8), status badges on their corner (the name stays), a crown over the leader, a gold frame round your column.
- **6 Feedback: built, waiting for Ben to play.** A reserved score strip between the dice and the turn row holds one thing at a time: the throw total over its result line, or an ability note (which no longer covers the turn lettering). No "+0"; the multiplier joins the line as a fixed "x1.5", then the total snaps. BUST, Free! and Hubris stamps sit on the tray's top edge. Envy's added dice are tinted in its colour and thrown in from its window. One die size at any count: what fits `TRAY_DICE` (18) in rows of 6 with margins (114 px on 1080x2341); zones now 21 / 49 / 30, candles shorter. Ability dice changes (Envy, Lust, Gluttony, Fury) now show before the throw scores.
- **7 Controls: not started.** Throw N stepper with bust chance, Buy stepper (replaces the 7 buy pills), ability consequence text, the 12-dice gaps.
- **8 Mechanics: not started.** Multiplier, escalating die price, Wrath and Greed caps, multiples of 5, +10 handicap, final round, Gluttony loop; report three mid-turn decision options (e.g. pay to reroll a Strike), don't build them. Balance notes below.
- **9 Polish: not started.** Serif for body text, blackletter for titles only; painted turn banners in each Sin's glass colour (now a flat ColorRect); no silent screens, audio limiter; windows take their seats after Choose; rename "Tutorial: Next game" to "Show tutorial"; app icon.
- **10 VFX spectacle: not started.**
  - Sin ability activations: a full-screen signature effect per Sin in its stained-glass colours (light shafts, shattering glass, ink flooding the page), 1-1.5 s, skippable.
  - Big scores scale in tiers: small = seal punch; medium adds gold sparks and page shake; huge adds a full-page illumination burst and a slow-motion hold.
  - Bust: the page burns or bleeds from the edges into the Purgatory transition (moved here from Phase 9).
  - Win / lose: a staged finale sequence, not a results panel.
  - Multiplier build-up: glow, pitch and particle density escalate as the multiplier climbs, so tension builds before the payoff.
  - Budget: 60 fps on the oldest supported iPhone; every intensity in `ui/tuning.gd`; Reduce Motion swaps these for simple flashes.

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
