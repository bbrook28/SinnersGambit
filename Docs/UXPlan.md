# Second quality pass: handoff (2026-11-14)

Single starting point for a fresh session. Detail per finished phase: `Docs/Handoff.md`. Beat table: `Docs/UXPass.md`.
Ben approves each phase: send a short plan, wait for his OK, build, stop for him to play. Commit locally, push only when he says.
Never touch `core/`, `sins/` or `ai/` without his explicit OK.

## Phases (next: Phase 3.5)
- **0 Rules simplification: done.** `Rules.V3`: throw all dice, automatic Purgatory, First Game mode, three Sin redesigns (`Docs/RulesDraft.md`).
- **1 Rules reference: done.** Rulebook from menu and "?", tap / hold to explain, all text in `ui/rules_text.gd`.
- **2 Legibility: done.** Opening card, Score/Dice captions, Strike candles, "Throw 3" / "Bank 75", throw result line, score causes, player-language ticker.
- **3 Scripted tutorial: done** (`ad34895`). Practice game vs Sloth with rigged dice; replay from Settings > Tutorial.
- **3.5 Art and audio style: not started.** New seal, dice and throw-icon art (ask before spending SpriteCook credits, 92 left). Write the audio style definition (stylized gothic, not realistic foley), then restyle the sounds to it.
- **4 Sin select carousel: not started.** Recommended tag on Sloth, an audio sting per Sin, page dots, Sin-coloured ambient light, table-size segmented control, delete the mosaic banners. Rebuilds the setup screen.
- **5 Game layout: not started.** Tray about 40% of the screen, status badges, "You" marker, leader marker, bot-turn summary panel, pause menu (Rulebook, Sin abilities), safe areas, 44 pt touch targets. Crop the in-game Sin windows (see Decisions).
- **6 Feedback: not started.** One score line at a time in a reserved zone that never overlaps dice or labels; no "+0"; no multipliers tweening through fractions; BUST above the tray, not over the dice; ability-added dice are a physical tinted die; fixed die size, tray fits the max dice count with margins.
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
`tools/ui_audit.gd`, windowed: `godot --path . --resolution 1080x2341 --script res://tools/ui_audit.gd -- <out_dir>`. Checks every visible button for 44 pt size, 12 pt gaps, side margins and the safe area, and screenshots each layout.
Still open:
- Setup screen gaps, including the table pills (Phase 4).
- 7 buy pills overflow the safe area; synthetic 12-dice prompts (Phase 7).
- Settings segmented rows report 0 pt gaps between their own segments (one control by design; not a bug).

## Decisions made
- In-game Sin windows get cropped to the arch and figure (about 1:1.8). Today the 222x760 lancet art sits in a ~215 px box, so each window is ~60 px wide. Phase 5.
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

## Tests to keep passing
`tests/ui_autoplay.gd`, `tests/replay_check.gd`, `tests/terms_check.gd`, `tests/tutorial_check.gd`, `tests/bot_pace.gd`, `tools/ui_audit.gd`.
