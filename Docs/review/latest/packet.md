# table-blockout-4b (fixes before TestFlight)
**Sheet:** `sheet_gain.png`: `table_gain_4`, `table_gain_ten`, `table_decision_4`, `table_ten_dice`. Rows are se, std, max.
**Why the last sheet showed the title screen:** I'd introduced a parse error in `ui/table_blockout.gd` (a variable declared twice) after the last test run, while adding the points label. The script failed to load, so every table fixture fell back to the menu under it. The flag wasn't involved: fixtures draw the blockout directly. Fixed.
**New guards:**
- `tools/show.gd`: a table fixture whose table didn't draw prints SHOW FAILED and saves no image. `tools/gallery.gd` deletes the old render before each job and stops with GALLERY FAILED before writing any sheet or packet. Tested by putting the same error back: gallery exit 1, no sheet.
- `tests/load_check.gd`: loads all 85 scripts and scenes and fails on any parse or load error. It runs first in `bash tests/run_all.sh` (the whole suite, in order) and in ios.yml before the export. With the error put back it failed, naming `table_blockout.gd` and `table_play.gd`.
**Points over the dice:** the gold "+N" (Cinzel 80) sits in its own 110 px strip between the track and the dice, so it never covers either. The strip is always reserved, so on screens with no points showing the dice and windows are a little smaller than in round 4.
**Table build verified:**
- iOS (table): exported its pack locally. It contains the `table_view` feature and the plain iOS pack doesn't, so the flag comes from the preset only (code default still off).
- Web (table), same mechanism, on a never-used browser origin: first Play went straight to choosing a Sin, then the opening card, then my turn on the table. After Throw, "+25" showed in gold while the stake still read 0.
- Not run on an iPhone.
**Checks:** full suite passes (load check, autoplay, table, replay, tutorial, terms, lines, table play, glass). Text audit 14 of 14 table fixtures clean at se, std and max.
**Also recorded:** Phase 9 depth pass (UXPlan, Order now).
**Waiting on your OK** before pushing and rerunning the TestFlight build.
