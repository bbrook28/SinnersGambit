# Packet: REPLY 46, where the version label goes (local only, 0 credits, no push, no CI run)
**Archived:** `review/reply45/` was moved to `archive/2026-11-19-reply45-version-label/` (ab9658e). `latest/`, the REPLY 43 packet, stays.
**Item 1, under the heading first:** the label was centred between the flourish and the Music row, in the row labels' ink, at 44 px. It was laid over the page, so nothing moved. Clear distances, ink to ink, at SE:
- to the flourish: 3.5 pt;
- to the Music row: 10.5 pt;
- at std: 3.3 pt and 10.7 pt.
- Contrast of ink on parchment: 6.7:1.
The flourish gap is under 10 pt, so per REPLY 46 nothing was shrunk or shifted, and the label falls back to the recommendation.
**As committed, the top strip** (both sizes): the label sits in the dark above the page, centred, in bone with the dark outline, the same text and source, at 44 px (15 pt at SE).
- Its box is 16 pt clear of the page; its ink is 20.5 pt clear at SE and 20.7 pt at std.
- Its ink top is at 39.5 pt at SE, below the 20 pt safe inset. At std it is at 79.0 pt, below the 59 pt inset.
- Contrast against the strip behind the text: 11.7:1 on the mean backdrop at SE and 12.2:1 at std. Against the brightest tenth (the dimmed window arches): 6.5:1 at SE and 8.0:1 at std.
- Fixed on the way: the label is now placed once it is in the tree. Sized before that, it measured short and grew down toward the page, leaving 9 pt of clearance.
**Text audit** (`audit_se.txt`, `audit_std.txt`): `settings` and `title` are clean at SE and std.
**Committed as its own commit:** db02ca9 (`ui/main.gd`, `ui/rules_text.gd`, and the version args in `tests/lines_check.gd`).
**Item 2:** one line under open faults in `Docs/Handoff.md`: the Back seal at SE hangs over the page's lower edge, and its caption ends 11.5 pt above the bottom. Not fixed.
**Suite:** 15 of 15 pass, load check 113.
**Evidence:**
- `sheet.png`, left to right: under the heading at SE (the try that failed the floor), then Settings at SE, then Settings at std, as committed.
- `shots/`: the same three frames at device size.
- The menu is unchanged since REPLY 45; `title` audits clean.

No questions.
