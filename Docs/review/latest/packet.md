# Packet: REPLY 35 item 1 (no skip-to-decision on the table; three new tests)
**Local only. 0 credits.** Built with your word. Settings > Speed is left as it is: there is no saved-speed override.
**Change** (`ui/main.gd`):
- On the table, a background tap finishes the current beat. A second tap inside 0.35 s finishes the next beat only; it never skips to your decision.
- The "Skip to my turn" button never shows on the table.
- The old board and the other screens behave as before (checked below).
**Tests added to `tests/run_all.sh`:**
- (a) `table_pace_check`: one First Game on the table at the saved speed. It fails if the median bot turn is under 2.0 s or the match is under 120 s, each divided by the speed.
  - Now: median 2.7 s; match 173 s.
  - The floors are today's, set to catch build 120's symptom. Raise them when the pacing floor lands.
- (b) `table_tap_check`: at the start of 3 bot turns, two taps 0.1 s apart on the background.
  - Table: skip_all stays off, and your decision came 7.8-11.7 s later.
  - Old board (the same test without `--table`): it still skips, and your decision came 0.04 s later.
  - Against the old `main.gd`, (b) fails on the table: skip_all is set, and your decision came after 0.13 s.
- (c) `resume_pace_check`: play 6 answers, Continue from the saved game, then time 4 bot turns once it has caught up. Median 2.7 s, nothing still skipping. **(c) passes today**, so there is nothing to report on Continue.
**Suite:** load check passed (108 scripts and scenes); 13 of 13 tests pass: the 9 existing, the 3 new, and `table_tap_check` again without `--table`.
**Seen in passing, not fixed:** a finished game deletes the Continue save even when `save_enabled` is off. So every test or tool that finishes a match on this PC (ui_autoplay, the new pace test, match_pace) wipes the save you would Continue.
**Questions**
1. Keep the pace floors at today's numbers until the pacing floor (item 2) is built, then raise them to its numbers? Rec: yes.
2. Stop tests deleting the real Continue save (they would skip the delete when `save_enabled` is off)? Rec: yes, one line in `ui/main.gd`, with your OK.
