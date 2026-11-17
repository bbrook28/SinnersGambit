# Packet: REPLY 34 item 1 (build 120 pacing break, report only; nothing fixed)
**Local only. 0 credits. No code changed.** Evidence: `pace.txt`. Tools added: `tools/match_pace.gd` (one full match through the real UI, timed), `tools/tap_probe.gd` (taps on the table's Throw seal).
**Measured** (game seconds at 1x; table view, First Game, table of 4, the same seed on both builds):
- Build 120: 183 s, 8 rounds. Bot turns: min 1.1, median 2.8, max 8.7 s. The Master called it at round 6's end; the last round was 8.
- Build 119: 186 s, 8 rounds. Bot turns: min 1.1, median 2.9, max 8.1 s. Same call and end.
- Build 120, normal game (powers on, table of 7): 246-270 s, 5 rounds, called at round 3, last round 5. Bot turns: median 4.1-4.2 s.
- I measured HEAD, not 2eb88eb. Nothing after 2eb88eb touches timing.
**Plate wiring (9d45e44)**: drawing only. It changed `table_blockout.gd`, not `table_play.gd`. `_show_line`, `say`, the 3.5 s line hold and the drop-newer-line rule did not change between builds 119 and 120. Line counts are alike: 19 vs 21 shown, 5 vs 8 dropped.
**Round-5 minimum and the Master's call**: they hold in the real table. In all four matches the call came at round 3's end or later, and the earliest end was round 5.
**So the break does not reproduce on desktop.** No match here ends in 30 s; a full match is 3-4.5 minutes. The cause is on the phone. Three candidates, most likely first:
1. **Speed 4x saved on the phone.** Settings > Speed (1x/2x/4x) is saved and carries across builds. At 4x this match is about 46 s, and a bot turn takes a median 0.7 s. That fits "30 s, turns flashed past". The table never shows the speed.
2. **Double tap to skip.** During bot beats, a double tap (within 0.35 s) on any part of the table that isn't a button skips straight to your next decision; a single tap finishes the beat. On the table, windows, dice, page and candles are not buttons, and nothing on the table says a skip happened. Taps on the seals and the track are safe: the probe showed a touch on Throw is read as the button.
3. **Continue.** Continue replays a saved match with every beat skipped until it catches up. If you continued a match from build 119 late on, it would end within seconds of resuming.
**Would the suite catch it?** No. `tests/bot_pace.gd` exists but is not in `tests/run_all.sh`, and it runs the old board at a fixed 1x. Missing:
- (a) a table pace test in the suite: median bot turn and match length at the saved speed;
- (b) a test that taps on the table never skip more than one beat;
- (c) a test that a resumed match plays at normal pace once it has caught up.
**Smallest fix (not built; it waits for your reply)**: on the table, a tap finishes at most one beat and never skips to your decision. The saved speed is ignored (1x) until the table shows a Speed control. Add (a) and (b) to the suite.
- Touches: `ui/main.gd` `_input` (skip only when the table is not showing), the speed load at main.gd:189 (table view), `tests/run_all.sh` plus two tests.
- Could break: a fast player can no longer skip bot turns on the table; anyone who chose 2x/4x is back at 1x on the table.

**Questions**
1. On your phone, what does Settings > Speed show, and did you tap Continue or tap the table during the bots' turns? Rec: check Speed first.
2. Build the fix as above (no skip-to-decision on the table, 1x on the table, two new tests)? Rec: yes.
