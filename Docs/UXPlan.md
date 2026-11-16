# Phases (owner of the phase list; Ben approves each phase: plan, his OK, build, stop for him to play)
Status is one of: done, in progress, parked, not started. What's happening now and what waits on Ben: `Docs/Handoff.md`. Earlier versions of this file: `Docs/archive/`.

| # | Phase | Status |
|---|---|---|
| 0 | Rule simplification (`Rules.V3`) | done |
| 1 | Rules reference and explain | done |
| 2 | Legibility | done |
| 3 | Scripted tutorial | done (`ad34895`), retired in favour of Phase 11; its code (`ui/tutorial*.gd`) stays until 11 is built |
| 3.5-6 | Art and audio, Sin carousel, layout, feedback on the old board | done (`b99da21`, `8d77f96`, `d9fba39`, `92d9e67`); the old board is replaced by the table |
| - | Run game (`Docs/RunDesign.md`, `run/`, behind `Tuning.RUN_MODE`) | parked |
| 7a | Table rules V4 vs bots: temptations, marks, claims, lines, rivalry, staged bot turns (`Docs/TableDesign.md`) | done |
| 7b | Pass-and-play: Table setup, handoff beat (TableDesign §2) | not started |
| 7c | Solo ladder: Circles, hosts, perks, endings, unlocks, Recall lines (TableDesign §6) | not started |
| 8 | The table (`Docs/TableSpec.md`) | in progress |
| - | Portrait clean-up pass | parked |
| - | Grammar and voice pass | parked |
| 9 | Depth pass | not started |
| 10 | Text and layout | not started |
| 11 | Onboarding (`Docs/Onboarding.md`) | not started |
| 12 | Motion and ship | not started |

## 8 The table (in progress)
- Done: blockout rounds 1-4 and 4b; playable behind `Tuning.table_view()`; TestFlight build 114 (iOS (table) preset).
- Now: Ben plays the TestFlight table build. This playtest replaces the five games planned for 7a on the old board.
- Next, only after Ben approves the layout: the **2.5D test**, one fixture (`table_decision_4`), no new art. (1) The table as a 3D scene, flat art on planes: the page in slight perspective (camera tilted 20-30 degrees), windows on the wall behind, candles and seals standing on the page. (2) Dice as 3D rigid bodies with the ivory texture, thrown onto the page with real shadows, settling into a readable row. (3) One flickering candle light plus the active window's coloured light. (4) Slight parallax from device tilt; Reduce Motion turns it off. (5) Bank and Throw stay full size and flat to the screen; targets and text still pass the audit. (6) Report frame rate at the oldest supported iPhone setting and the effort to convert the other screens. Send a clip and stills beside the flat version, no verdict, then stop.
- Then: paint the table (painting list: `Docs/review/archive/2026-11-15-table-blockout/packet.md`). Paint nothing until Ben says. No whole-screen mockups.

## Portrait clean-up (parked)
One pass, after the table direction is chosen; no portrait edits and no credits until then. One lead line round each figure's combined silhouette, never at a seam; layer cuts at natural breaks (wrist, sleeve, collar), never across fingers, hands or faces. Every Sin holding dice (Greed, Lust, Gluttony) gets the game's own dice sprites from `assets/art/runtime/dice/`, arranged, shaded and outlined into the painting. Faults it fixes: `Docs/Handoff.md`.

## Grammar and voice pass (parked, REPLY 18)
For polish: one pass over every line in the game (`ui/rules_text.gd`) for grammar and each Sin's voice, starting with the Master's lines. Each Master line must fit on one line on his plate beside his arm (today, in the mark pose, his plate crosses his arm).

## 9 Depth pass (not started; after the table layout is approved)
Every screen, the main menu included: parallax with tilt, cast light, soft shadows, darker edges (`Docs/ArtDirection.md` Depth).

## 10 Text and layout (not started)
Every screen on the type rules (`Docs/ArtDirection.md` Type): labels of 4 words max, two-line tooltips, controls dim instead of vanishing (today your buttons appear only when the queue is empty), one painted button language, rulebook = collection + 3 pages. Acceptance: a screenshot of every screen at iPhone size; nothing under 15 pt, no blackletter under 28 pt, nothing clipped or touching an edge.

## 11 Onboarding (not started)
`Docs/Onboarding.md`: the first three games teach by doing; the scripted tutorial goes.

## 12 Motion and ship (not started)
3D or pre-rendered dice (per the 2.5D test), one-piece-at-a-time scoring with rising pitch, Sin entrances, staged win and loss; unlocks, collection, endings gallery, stats, audio limiter, app icon, 60 fps on the oldest device. Acceptance: no wait over 1.5 s without input, no sentence in the play field, no overlapping text, no empty zone on your turn, every button painted.
