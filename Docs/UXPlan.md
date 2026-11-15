# Second quality pass: handoff (2026-11-14)

Single starting point for a fresh session. Detail per finished phase: `Docs/Handoff.md`. Beat table: `Docs/UXPass.md`. Table design: `Docs/TableDesign.md`. Parked run design: `Docs/RunDesign.md`.
Ben approves each phase: send a short plan, wait for his OK, build, stop for him to play. Commit locally, push only when he says.
Never touch `core/`, `sins/` or `ai/` without his explicit OK. TableDesign §10 lists every such change for his OK.

## Phases 0-6 (bot-table game)
- **0-3 done:** V3 rules, rulebook and explain, legibility, scripted tutorial (`ad34895`).
- **3.5 art and audio, 4 Sin carousel, 5 layout, 6 feedback: built, waiting for Ben to play** (`b99da21`, `8d77f96`, `d9fba39`, `92d9e67`). Detail in Handoff.

**Rework 2 (Ben, 2026-11-14): the table is the real game.** Solo against a score target was arithmetic; the fun is the table: rivals, reactions, Sins that tempt you. Balatro is the bar for polish (dice, motion, sound, minimal text), not structure. One phase per session; Phase 7 on Opus.
- **7 The table: slice (a) built, Ben plays five games.** `Docs/TableDesign.md` (draft 2, results in §11): V4 rules, temptations / marks / claims, Sin lines, staged bot turns, in the table game vs bots. Next: (b) pass-and-play and Table setup, then (c) ladder, perks, house rules, endings; a stop after each.
- **8 Text and layout: not started.** Board readouts, labels of 4 words max, two-line tooltips, dice twice the size, controls dim instead of vanishing, Throw seal 22%+ of width, one painted button language, serif body text, learn-by-doing tutorial, rulebook = collection + 3 pages.
  - **Typography (Ben, 2026-11-14):** five sizes only in `ui/tuning.gd` (display, title, body, label, caption; 15 pt minimum on device), every label on one, with a list of every text element and its size. Blackletter for display and title only, never under 28 pt; serif for the rest; gold numerals keep their face; no other fonts in the play field. Letter spacing through FontVariation resources: blackletter +4%, small-caps labels +8%; body line height 1.3. MSDF font import; soft dark outline or shadow on text over art, contrast checked on the brightest and darkest backgrounds. Values large and bright, their labels small and muted; one emphasis per screen. One colour each for Strike, Bank, Bust and every Sin's name, everywhere.
  - **Text motion (manuscript, no wobble, wave, bounce or rainbow):** Sin lines and offers are written on left to right with a wet edge that dries, at speaking pace, with a quiet quill scratch; Sins differ only in ink colour and pace (Wrath fast and heavy, Sloth slow). Emphasis is one word in red ink or gold leaf. Numbers settle like a stamp (short press-in, faint gold glint); counting up is fine, shaking isn't. Text leaves by fading like drying ink. Bust, claim and win only: the lettering may flare with candlelight or bleed red once. Reduce Motion shows text at once.
  - **Acceptance:** screenshot every screen at iPhone size: no text under the minimum, no blackletter under 28 pt, nothing clipped or touching an edge.
- **9 Motion and ship: not started.** 3D or pre-rendered dice, one-piece-at-a-time scoring with rising pitch, idle wobble, Sin entrances, bust burns the page, staged win and loss; unlocks, collection, endings gallery, stats, audio limiter, app icon, tutorial on a real iPhone, 60 fps on the oldest device.
- **Acceptance from Phase 8 on:** re-record the tour; no wait over 1.5 s without input, no sentence in the play field, no overlapping text, no empty zone on your turn, every button painted.

**Parked: the run game (Rework 1, 2026-11-14).** Kept, hidden behind `Tuning.RUN_MODE` once 7b lands; not extended.
- **Run design doc: approved 2026-11-14.** `Docs/RunDesign.md` revision 2: keep-and-rethrow, no Strikes, 3 turns a round, 7 Circles. Scratch sim: `sim/keep_sim2.gd`.
- **Core loop: built 2026-11-14 (`899d1c6`), played by Ben, parked.** `run/`, `ai/run_bot.gd`, `sim/run_sim.gd`, `ui/run_board.gd`, `tests/run_check.gd`, `tests/run_ui_check.gd`. Sim numbers: RunDesign §11.

## Standing rules
- Every event is a queued beat (`ui/action_queue.gd`): anticipation, action, impact, hold. The board draws the snapshot of the last beat played, never live state. Nothing jumps.
- A tap finishes the current beat; a second tap skips to your next decision; a hold explains.
- Animation: springs (`TRANS_SPRING`) on every scale and position change; squash and stretch on press, release and landing; rows enter `ENTER_STAGGER` apart; idle elements breathe. Reduce Motion swaps shake, flash, tilt and breathing for fades.
- Bank and Throw seals keep a fixed size (`SEAL_CONFIRM`) at any dice count.
- All on-screen wording in `ui/rules_text.gd`, numbers through `vals()`. Preload consts, no `class_name`.
- `ui/tuning.gd` holds every duration and intensity (seconds at 1x); global speed `Tuning.speed` (0.25-4) from Settings > Speed; debug slider `Tuning.SHOW_DEBUG_SLIDER` (off).
- Placements: main menu work, Phase 9; audio limiter and app icon, Phase 11.

## Tests to keep passing
`tests/ui_autoplay.gd`, `tests/replay_check.gd`, `tests/terms_check.gd`, `tests/tutorial_check.gd`, `tools/ui_audit.gd` (windowed: `godot --path . --resolution 1080x2341 --script res://tools/ui_audit.gd -- <out_dir> [table size]`, at 4 and 7: 44 pt targets, 12 pt gaps, margins, safe area, screenshots; table game, needs `Tuning.TABLE_MODE` only for its menu seal until 7b makes Play open the table). Run mode: `tests/run_check.gd` (rules, every relic, save, seeded bot runs), `tests/run_ui_check.gd` (plays a run per Sin through the board, 44 pt targets, Continue).

## The table game today (Phases 0-6; TableDesign changes it in 7b)
- Rules: your buttons appear only when the queue is empty (Phase 9 replaces this with controls that dim). Bot beats run `BOT_PACE` faster, no anticipation, 30% hold; a bot turn stays under 4 s at 1x (`tests/bot_pace.gd`, hovers at 4.0-4.2 s, treat as noise).
- Open audit items: 7+ buy pills overflow the safe area; synthetic 12-dice prompts.
- Decision: in-game windows cropped to the arch and figure (1:1.8, `Art.window_crop`, `Tuning.WINDOW_CROP_TOP`).
- Balance notes (`sim/check_v3.gd`, 4000 games): Envy's Mimicry too strong with Greater (win share 2.06 at 4, 2.47 at 7; fair 1.00); Greed (0.60) and Gluttony (0.42) weak; odd numbers in `Docs/RulesDraft.md`.
- Untested: the tutorial on a device; 3.5 sound (headless is silent) and art outside audit shots; Phase 4 stings and swipe feel; Phase 5 pause menu and summary by hand; Phase 6 score-strip timing, Envy's tinted dice and BUST on the tray edge in motion.
