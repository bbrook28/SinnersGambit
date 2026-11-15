# table-blockout-4 (playable)
**Play it:** `powershell -ExecutionPolicy Bypass -File tools\serve.ps1 -Dir web_table`, then open the address it prints on your phone (same Wi-Fi). The build is `build/web_table/` (export preset "Web (table)").
On a fresh browser the first launch runs the tutorial on the old board; Skip goes to choosing your Sin. The table shows from the first turn. These are main's screens as built and show with the table hidden: the opening card, temptation offers, the rulebook, pause, Settings and the end of the game.
**Changed (round-3 verdicts):**
- Markers are 60 px and display only. The whole track is one tap target that opens the standings (scores, marks, pending costs, plus a Menu button for the pause menu). Mine sits below the line; rivals sit above on stems of different heights, never overlapping; the leader is crowned on top.
- Dice shrink to 140 px in two rows before the windows shrink.
- Costs attach to what they hit: a ghost die in the row, a crimson band on the next candle to go, a crimson Bank loss raised beside the stake. Marks are small sigil stamps on my edge. The tag and chip are gone.
- The spoken line is 84 px in the speaker's colour. On a rival's turn it sits over the foot of the speaker's window, because the rival's stake has the gap.
- Other choices (buying dice, ability targets) are flat buttons in the gap under the windows, with the prompt's words above.
**Motion (simple):** dice drop in, the stake swells when it grows, a new Strike flashes its candle crimson, a bust shakes the page.
**Checks:** text audit 11 of 11 table fixtures clean at se, std and max. `tests/table_play_check.gd -- --table` plays 7 full games through the table seals (99 answers on the table, 13 on main's offer screens). Existing tests pass with the flag off.
**Sheets:** `sheet_std.png` (all 11 fixtures at std, including the new `table_close_7`), `play.png` (frames from real games: decision, rival, bust, choices).
**What the frames show, without verdicts:**
- With seven scores within 100 points, the rivals stack six high on stems. The page drops, and on se the active window is drawn smaller.
- After the dice land, the stake waits about 2 s for the hidden board's scoring beat before it changes.
- At game start every rival is on 0, so they stack at the left end.

**Questions**
1. Close scores stack six high. Lean the stems so the heads fan sideways, at most two levels? Recommendation: yes.
2. Show the throw's points (+N, gold) over the dice the moment they land, and add them to the stake on the next beat? Recommendation: yes.
3. Keep the other choices as buttons in the gap under the windows? Recommendation: keep them there for this playtest.
4. Long-press to explain is off on the table. Recommendation: leave it off until the layout settles.
