# Packet: REPLY 24 (answers, log check, lock, icon, push 119, art batch 1)
**Pushed 3797502 as build 119** (iOS run 19: success, TestFlight internal). Suite: all pass. Text audit: 35/35 clean at se and std.
**1. Answers** (a80003b): a Sin's line that would wrap drops to 48 px; the game-end plate's foot stands 16 px over my seal. SE re-shoots were in the 119 checks; audit clean at both sizes.
**2. Log check**: 20 bot games, 80 seats; the logger's buys and busts per seat against core's own lines: **0 mismatches**. Logger unchanged.
**3. Lock** (3797502): TableSpec records the layout as locked, `Docs/table_lock/boxes.txt` and its sheet as the reference.
**4. Icon** (491b7a1): `assets/icons/icon_1024.png` is now icon_r2_3 (1024, opaque RGB, square). Both presets already pointed there. iOS export and upload passed in run 19.
**5. What a player notices since 118**: Greed's Cash Out bust fixed; Idle One and Hubris x2; the call can't come before round 3, and the post stays dim until then; at most 5 dice bought at once. Buy row on one line under the track; ability and target questions on the page plate (a name over its total). The Master's line on a plate in his robe; lines hold 3.5 s, and he says at most one other line a round. A rival plays on my page (its stake, Strikes and seal in my places, "<Sin>'s turn"); a Sin's line on his plate with its sigil. Game end on its own plate over my seal. New app icon.
**6. Art batch 1** (`sheet.png`: decision state, before and the three Masters, std row over SE row; `states.png`: bust, a Sin's line, a rival's turn, before/after at std and SE; raw pieces in `art/`). Drawn by `tools/art_mock.gd` over the fixtures at the locked boxes; no game file touched, not in 119. **108 credits used** (290 left).
- Placement: each Master scaled so its width a quarter of the way down equals the hood box, top on the hood box's top. Candles fit wax to the blockout candle's height (lit 75 px wide, snuffed 56 px, against 84). Seals drawn as Bank and Throw's faces, words on top. Page texture on the page rect, table texture from the page's top down.
- Hood vs the SE safe line: the hood's top is 4 px under it at SE (62 against 58 layout px) and at std (166 against 162).
- Contrast, the page's median colour against the text (WCAG ratio, before → after): ink mid-page 4.8 → 5.5 std, 5.3 → 6.3 SE; my stake's gold by the stake 4.0 → 3.6 both sizes; gold mid-page 2.1 → 1.9 std, 1.9 → 1.6 SE.
- Seen: the robe shows through the rival windows (they are dimmed, not opaque). The figure ends at the art's shoulders, so black wall shows either side where the plum robe was. Master 2's skull reaches into the rival windows' tops at both sizes. A Sin's line plate sits across every Master's jaw. Mock limits: the blockout's crimson "next candle to go" band and any arm are not drawn over the art.
**Parked as before:** page contrast of the rival's stake and label; bot turn 4.6 s; Feast question wording; end-of-game track bunching.

**Questions**
1. Which Master to carry forward? Rec: Master 1, the only one whose skull stays above the rival windows' tops at both sizes.
2. The line plate covers the jaw. Fix: scale the Master so his jaw ends above the plate (art placement, not layout). Rec: yes.
3. Rival windows let the robe through. Fix: dim them by darkening only, fully opaque. Rec: yes.
4. Black wall where the robe was. Rec: keep it (ArtDirection: mostly dark).
5. Wire the chosen pieces into the game, one piece per commit, for 120? Rec: yes, page and table first, then seals, candles, Master.
