# Packet: REPLY 37 item 1 (Continue save) and REPLY 38 items 2 and 4 (token sheet, composite)
**Local only. 0 credits. No push.** I had not read REPLY 37: the inbox watch was stopped, and REPLY 38 replaced it in the inbox file. I read it in `inbox/sent/` and have now built it.
**REPLY 37 item 1, Continue save:**
- A finished game now deletes the save only when saving is on (`ui/main.gd`, 641e55e). Tests and tools leave the real save alone.
- New `tests/save_check.gd` (63a4183):
  - (A) a real game saves as you play, and its end deletes the save;
  - (B1) a test's game with no save on disk writes none, so Continue has nothing to offer;
  - (B2) with a real save on disk, a test's game leaves it byte for byte.
  - Proof that no stale save can appear: a test's game never writes one (`_save_game` returns when saving is off), and (B1)/(B2) check this.
  - Against the old `main.gd`, (B2) fails.
- **Suite:** load check passed (109 scripts and scenes); 14 of 14 tests pass, `save_check` included. `run_all.sh` still sets the Continue save aside around the run.
**REPLY 38 item 2, token sheet** (`tokens_se.png` at 0.85 of SE device px, `tokens_std.png` at 0.54 of std). Gluttony banks 180 at a table of 4 and a table of 7. The columns are: turn start (its token pulses), the stake flying to its token, and the token sliding as its label counts (a real render at 640). The first row shows tokens as today; the second shows rings in each Sin's colour, plus a thread of light from its window at turn start.
- How the eye finds the rival's token without reading the number:
  - Today's tokens: only by motion (the pulse, then the slide). At a table of 4, Gluttony's, Greed's and Wrath's tokens are all dark at this size.
  - With rings: the ring's colour matches the lit window, and the thread links window to token.
- What the sheets show:
  - At 7, when Gluttony reaches 640 it takes the upper row and Envy's 610 token drops a row, so two tokens move in one beat.
  - At 7, the stake ends between Gluttony's and Envy's stems.
  - At 7, my slide trail crosses the "610" label.
**REPLY 38 item 4, composite** (`frame_sheet.png`: today | the last composite | this one | this one + SE lock boxes; `composite_750.png`). Not wired.
- The seam: the page below the dice is now flattened the same way as the top, on parchment pixels only, starting 60 px inside the top fill. The 30 px band is gone.
- The pink rectangle: try 2's own baked light on the top border is replaced from the same rows further right.
- Left: stains within about 30 px of the border, and a few small dark blots at the foot of the page. The soft light is unchanged.
**Questions**
1. Tokens: rings in each Sin's colour plus the thread at turn start (row 2)? Rec: yes, rings at least. Motion alone fails when two tokens move at 7.
2. At 7, should restacking wait for the slide's end, so only one token moves in a rival's beat? Rec: yes.
3. Composite: judge `composite_750.png` at phone size before any painted pass. Rec: yes.
