# Packet: REPLY 45, the version committed; the label on Settings (local only, 0 credits, no push, no CI run)
**Archived:** `review/reply44/` was moved to `archive/2026-11-19-reply44-versioning/` (7ed9ced). `latest/`, the REPLY 43 packet, stays.
**Item 1, committed as one change** (8682c57): `ui/version.gd`, `ios.yml`, both iOS presets and the CLAUDE.md line, without any label.
- The workflow step now fails the run if `BUILD` is not digits, or `COMMIT` is not 7 or more hex characters, after the stamp.
- Tested here on copies, under GNU sed and GNU grep only: an unstamped file fails and a stamped one passes. The runner uses BSD sed (`sed -i ''`), so the first CI run is the stamp's real test.
**Item 2, the label** (uncommitted, see the question):
- The menu is reverted: `git diff ui/main.gd` shows nothing in the title builder. The only line left is the `Version` preload, which Settings uses.
- The label is on the Settings overlay, in the dark under the page: centred, 16 pt below the page, same text and source, 44 px (15 pt at SE).
**Text audit** (`audit_se.txt`, `audit_std.txt`, fixtures `settings` and `title`):
- title: clean at SE and std.
- settings at std: clean.
- settings at SE: the label lies over the Back seal by 62x6 pt and over the "Back" caption by 25x4 pt.
**What is at the foot of Settings at SE** (stopped here, as REPLY 45 says; nothing moved):
- The Back seal (220 px) hangs over the page's lower edge.
- Its caption's ink ends at 655.5 pt, 11.5 pt above the bottom of the 667 pt screen. SE has no home indicator inset.
- The label needs a 21 pt line plus 16 pt clear of the caption, about 37 pt. 11.5 pt is free.
- At std the same foot leaves the label well clear of the page; the evidence shows both.
**Suite:** 15 of 15 pass, load check 113, with the label on Settings and `lines_check` given the version args (both uncommitted).
**Evidence:**
- `sheet.png`: the menu at SE (unchanged), then Settings at SE, then Settings at std.
- `shots/`: device-size frames of the same three.
- No other fixture changed; `settings` is the existing fixture.

**Questions**
1. At SE, Settings has 11.5 pt under Back's caption. Where does the label go? Rec: the top of the Settings overlay, centred in the dark above the page. That strip is 150 px plus the safe inset tall and holds no control or caption (only the menu's windows show through, dimmed), and it uses the same rule: 16 pt clear of the sides and of the page.
