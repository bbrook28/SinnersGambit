# Packet: REPLY 44, version numbering (local only, 0 credits, no push; beside latest/, which stays unreviewed)
**Build 120 went up as `0.1.0`** (run 20, commit 2eb88eb). `0.1.0` was the presets' placeholder short version, unchanged since 374ef67. Every TestFlight build so far went up as 0.1.0, so 0.6.0 is higher and the upload is allowed. The run's log has expired; the version is read from the presets at 2eb88eb.
**Changed** (uncommitted until item 1 is settled):
- `ui/version.gd` (new) holds `VERSION := "0.6.0"`, plus `BUILD` and `COMMIT`, which stay empty in the repo. Locally the commit comes from git; an exported local build has none.
- `ios.yml` reads `VERSION` (it fails the run if the value is not x.y.z) into both iOS presets' `short_version`. It also writes `BUILD` (100 + the run number) and the 7-character commit into `ui/version.gd` before export. The step was run here on copies of the files with GNU sed; `workflow.diff` has the full text.
- Both iOS presets: `short_version` changed from 0.1.0 to 0.6.0, so a local export matches. CI overwrites it.
- CLAUDE.md, on the TestFlight line: where the version lives and when to bump it. No other doc restates it.
- The menu label is `0.6.0 (local) 8df24ed` through `RulesText.table("version")`, set at 44 px (15 pt at SE, the audit's floor), in the right foot corner.
**Deviations:**
- 16 pt in from the side, not 12 SE px: the text audit's side margin is 16 pt, and 12 SE px (6 pt) fails it.
- There is no Android export preset yet, so nothing on Android reads the version.
**Suite:** 15 of 15 pass, load check 113. `lines_check` failed once (the new `version` word had no test args) and passes since they were added to `tests/lines_check.gd`.
**Text audit (title):**
- std: clean.
- SE: the label overlaps the Settings caption by 38x13 pt.
- At SE the menu column already fills the page down to Settings' caption, so no bottom corner is free. Tried, in order:
  1. 16 pt clear on all sides: over the caption, 38x6.
  2. Growing the foot spacer: no effect, the column is full.
  3. 12 SE px from the bottom: 38x13.
  Stopped there, per the rule after the same fix fails twice.
**Evidence:**
- `sheet.png`: the menu at SE beside std. `shots/` holds the device-size frames and corner crops.
- `workflow.diff`: the workflow and preset changes as text. Nothing was run on CI and nothing pushed.

**Item 2, the sheet dates:** two commits landed after the sheets were made (18 Nov 23:10): 232649c, the slip and chip fixes, and 8df24ed, the packet. All 20 shots were re-rendered from today's tree and diffed against `latest/shots`: every one is pixel-identical, so no panel is stale. The shots had been rendered from a working tree that already held 232649c's change. The clip was not re-rendered.

**Questions**
1. Where does the label go at SE? Rec: the top-right corner over the dark wall, with the windows lowered 10 pt at every size to make room.
2. Commit the version file and workflow now, apart from the label? Rec: yes, as one commit; the label follows once item 1 is decided.
