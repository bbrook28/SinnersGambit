# docs-audit (report only; no edits until Ben's OK)
**Inventory (21 .md; lines, last change):** CLAUDE 27 11-14 project rules · Handoff 320 11-15 per-step build log since 11-13 · UXPlan 78 11-15 order now, direction, faults, how to work, harness, old phases · TableDesign 115 11-15 V4 rules, lines, offers, ladder, sim results · Onboarding 33 11-15 first-three-games draft · RunDesign 128 11-14 parked run game · Tour 143 11-14 Phase 6 tour · AudioStyle 41 11-14 · Plan 131 11-13 V2/Tier dice maths · RulesDraft 45 11-13 V2 simplification · UXPass 104 11-13 beat plan · ArtDirection 130 · ArtAudit 64 · VFX 44 (all 11-13) · review/voices_proposal 166 (applied in 84fc8af) · 5 review packets · .claude/handoff.md 23 (untracked).
**Owner per topic (restated in):** status/next: none clear (Handoff:1-9, UXPlan:1-16, .claude/handoff) · phase plan: UXPlan (Handoff:245, RunDesign:1) · table as built: no owner (UXPlan:10, packets, TableDesign §11) · rules and numbers: TableDesign §1,5 + code (RulesDraft, Plan, UXPlan:77) · Sin lines and offers: code `rules_text.gd` (TableDesign §3,7, voices_proposal) · how to work: UXPlan:26-33 (CLAUDE:24-27, UXPlan:4) · harness: UXPlan:35-42,70-71 (CLAUDE:17-19, Handoff:18) · faults: UXPlan:18-24 (Handoff:302, TableDesign:115) · parked: UXPlan:19-23,57-59 (RunDesign, Handoff:245-261).
**Contradictions (handoff's list, all confirmed, plus new):**
1. UXPlan:11 direction (tally marks, border track with marginalia, candle by Throw) vs UXPlan:10 rounds 2-4 (one stake numeral, band track, risk in my Strike candles; `table_blockout.gd:405`).
2. UXPlan:13 "hold to explain" and :63 "a hold explains"; `table_play.gd` has no hold.
3. Phase numbers: UXPlan:14 "Old Phases 8, 9", :15 Phase 9 = depth, :50/:54 8 = text, 9 = motion, :68 "Phase 11", :73 "Phases 0-6; 7b"; RulesDraft:1,3 and RunDesign:1 use run-era "Phase 8".
4. UXPlan:49 Phase 7 "Ben plays five games, next (b)": (b) and (c) are unbuilt (no `ui/table_setup.gd`, no `ladder/`), Phase 8 started instead; whether the five games happened isn't recorded.
5. UXPlan:71 `Tuning.TABLE_MODE` and "until 7b makes Play open the table": code has `TABLE_VIEW`/`table_view()` (`tuning.gd:17-19`) and Play already opens the table (`main.gd:893`). TableDesign:105 still says RUN_MODE "replaces TABLE_MODE".
6. 9+: Handoff:299 and TableDesign:21 say the ceiling is dropped; voices_proposal:3 "softened for 9+" (history, applied).
7. TableDesign:1 "Phase 7, draft 2"; :3 "Base rules stay Rules.V3"; game plays V4 (`main.gd:29,893`).
8. CLAUDE:4 start at UXPlan vs Handoff:3 "Read CLAUDE.md, then Docs/Plan.md"; CLAUDE:5 points at Plan.md (V2/Tier 3 era, Handoff:6-9).
9. CLAUDE:18 check_v3 "V2 vs V3": it also runs V4 (`check_v3.gd:4,30`, used in TableDesign:108).
10. Lines: TableDesign:21 "scroll from the speaker's window" and :72 offer "a scroll ... one tap" vs :115 (speech tab; full-screen offer) and blockout round 4 (spoken line in the speaker's colour).
11. New: UXPlan:74 bot turn "under 4 s" vs `tests/bot_pace.gd:80` 2.5 s and TableDesign:42; TableDesign:42,105 name `BOT_TURN_MAX`, `TEMPT_CHANCE`, neither in code (`tempt_gap` is).
12. New: UXPlan:36 "45 fixtures"; `tools/fixtures/` has 59. UXPlan:71 test list lacks table_check, lines_check, glass_check (all in `run_all.sh`).
13. New: CLAUDE:8 "Godot 4.5+" (project is 4.7, `project.godot:15`); CLAUDE:10 "iOS needs a Mac" vs Handoff:46 CI TestFlight; CLAUDE:15 "sins/ (next)", "ui/ playtest UI".
14. New: Handoff:47 repo "private" (it is public); Handoff:247 "pass-and-play cut from v1" (reversed at :267).
15. New: ArtDirection:14 (marginalia, vine-and-thorn borders, drop caps) vs UXPlan:12 restraint (no ornament, no floral borders).
16. New: UXPlan:45 tutorial done vs Onboarding:3 (tutorial goes) and `main.gd:529` (off in the table build); undecided, not wrong.
**Target structure:**
- CLAUDE.md <40: commands (suite, sim incl. v4, show/gallery/audit, export), standing rules (UXPlan:4-5, 26-33, 61-67), pointers.
- Docs/Handoff.md <=60, rewritten: now, next, waiting on Ben, open faults, pointers. Old 320 lines -> `Docs/archive/Handoff_2026-11-13_to_15.md`. Replaces `.claude/handoff.md` (deleted).
- UXPlan: phase list only (renumbered: 7 table rules, 8 table, 9 depth, then text/motion/ship). Direction + restraint -> TableSpec; harness -> CLAUDE; faults -> Handoff.
- TableDesign: rules and content only (§1-8); drop §9-11 build/sim log to archive, keep numbers that are live; fix 1, 3, 21, 72, 105.
- New Docs/TableSpec.md: the table as built (layout, track, stake, candles, seals, offers, lines, flags), from UXPlan:10-12 and blockout packets.
- To Docs/archive/: Plan, RulesDraft, UXPass, Tour, ArtAudit, voices_proposal. Keep: ArtDirection (with a line that UXPlan restraint wins, or merge into TableSpec), AudioStyle, VFX, Onboarding, RunDesign (parked header).
- Nothing deleted outright except `.claude/handoff.md`.
**Questions:** 1. OK the structure? Rec: yes, one commit per file. 2. ArtDirection: merge its still-valid parts into TableSpec and archive it? Rec: yes. 3. Phase renumbering as above? Rec: yes.
