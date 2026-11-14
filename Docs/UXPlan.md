# Second quality pass: handoff (2026-11-14)

Single starting point for a fresh session. Detail per finished phase: `Docs/Handoff.md`. Beat table: `Docs/UXPass.md`. Run design: `Docs/RunDesign.md`.
Ben approves each phase: send a short plan, wait for his OK, build, stop for him to play. Commit locally, push only when he says.
Never touch `core/`, `sins/` or `ai/` without his explicit OK. Approving `Docs/RunDesign.md` gives that OK for Phase 8's changes there.

## Phases 0-6 (bot-table game)
- **0-3 done:** V3 rules, rulebook and explain, legibility, scripted tutorial (`ad34895`).
- **3.5 art and audio, 4 Sin carousel, 5 layout, 6 feedback: built, waiting for Ben to play** (`b99da21`, `8d77f96`, `d9fba39`, `92d9e67`). Detail in Handoff.

**Rework (Ben, 2026-11-14): Balatro is the quality bar.** Phases 7-11 replace the old 7-10. One phase per session. Phase 7 and Phase 8's balance work on Opus; 9-11 fine on Sonnet.
- **7 Run design doc: revision 2 (keep-and-rethrow, no Strikes), waiting for Ben's review.** `Docs/RunDesign.md`. No code until approved.
- **8 Core loop: on hold until Ben brings the review back.** Build the run, targets, ruling Sins, shop and relics with placeholder presentation. Needs a new run sim (`sim/run_sim.gd`, rebuilt; the old one doesn't parse) and `ai/run_bot.gd`. Report win rate per Sin and relic pick rate; pick rates only flag broken relics (none above twice the average), they are not final balance. Relic art: placeholders until Phase 9.
- **GATE after 8:** Ben plays 10 runs and shows 5 people. No Phase 9 until he says the loop is fun; otherwise revise RunDesign and repeat 8.
- **9 Board, text, controls: not started.** Permanent readouts (target, Points, Mult, turns left, Strikes, gold), max 4 words per label, two-line tooltips, Points gold / Mult crimson everywhere, dice twice the size, relic row, controls dim instead of vanishing, Throw seal 22%+ of width with bust chance, one painted button language, serif body text, 6-step learn-by-doing tutorial, rulebook = collection + 3 pages, new run in two taps. Relic art: state a SpriteCook credit budget before generating (32 left).
- **10 Motion: not started.** 3D rigid-body dice in a SubViewport (cost estimate first; pre-rendered tumble sheets as fallback), one-piece-at-a-time scoring with rising pitch, target-passed fire, idle wobble, background reacts to Mult, dimming no lower than 70%, ruling-Sin entrances, bust burns the page, staged win and loss.
- **11 Meta and ship: not started.** Unlocks, collection, Vows, stats, daily run, audio limiter, app icon, tutorial on a real iPhone, 60 fps on the oldest device.
- **Acceptance from Phase 9 on:** re-record the tour; no wait over 1.5 s without input, no sentence in the play field, no overlapping text, no empty zone on your turn, every button painted. Report failures with timestamps.

## Standing rules
- Every event is a queued beat (`ui/action_queue.gd`): anticipation, action, impact, hold. The board draws the snapshot of the last beat played, never live state. Nothing jumps.
- A tap finishes the current beat; a second tap skips to your next decision; a hold explains.
- Animation: springs (`TRANS_SPRING`) on every scale and position change; squash and stretch on press, release and landing; rows enter `ENTER_STAGGER` apart; idle elements breathe. Reduce Motion swaps shake, flash, tilt and breathing for fades.
- Bank and Throw seals keep a fixed size (`SEAL_CONFIRM`) at any dice count.
- All on-screen wording in `ui/rules_text.gd`, numbers through `vals()`. Preload consts, no `class_name`.
- `ui/tuning.gd` holds every duration and intensity (seconds at 1x); global speed `Tuning.speed` (0.25-4) from Settings > Speed; debug slider `Tuning.SHOW_DEBUG_SLIDER` (off).
- Placements: main menu work, Phase 9; audio limiter and app icon, Phase 11.

## Tests to keep passing
`tests/ui_autoplay.gd`, `tests/replay_check.gd`, `tests/terms_check.gd`, `tests/tutorial_check.gd`, `tools/ui_audit.gd` (windowed: `godot --path . --resolution 1080x2341 --script res://tools/ui_audit.gd -- <out_dir> [table size]`, at 4 and 7: 44 pt targets, 12 pt gaps, margins, safe area, screenshots). Phase 8/9 adds run-mode tests.

## Legacy: the bot-table game (valid until Phase 8/9 replaces it)
- Rules: your buttons appear only when the queue is empty (Phase 9 replaces this with controls that dim). Bot beats run `BOT_PACE` faster, no anticipation, 30% hold; a bot turn stays under 4 s at 1x (`tests/bot_pace.gd`, hovers at 4.0-4.2 s, treat as noise).
- Open audit items: 7+ buy pills overflow the safe area; synthetic 12-dice prompts.
- Decision: in-game windows cropped to the arch and figure (1:1.8, `Art.window_crop`, `Tuning.WINDOW_CROP_TOP`).
- Balance notes (`sim/check_v3.gd`, 4000 games): Envy's Mimicry too strong with Greater (win share 2.06 at 4, 2.47 at 7; fair 1.00); Greed (0.60) and Gluttony (0.42) weak; odd numbers in `Docs/RulesDraft.md`.
- Untested: the tutorial on a device; 3.5 sound (headless is silent) and art outside audit shots; Phase 4 stings and swipe feel; Phase 5 pause menu and summary by hand; Phase 6 score-strip timing, Envy's tinted dice and BUST on the tray edge in motion.
