# Handoff (2026-11-15): owner of now, next, waiting on Ben, open faults
Read `CLAUDE.md` first. Phase list: `Docs/UXPlan.md`. The per-step log to 2026-11-15: `Docs/archive/Handoff_2026-11-13_to_15.md`.

## Now
- Phase 8, the table: blockout 4b is playable behind `Tuning.table_view()` (`Docs/TableSpec.md`), pushed at `e70b78f`.
- TestFlight build 114 (run 43777109922, preset "iOS (table)") is uploaded for internal testers (`CLAUDE.md` TestFlight).
- Docs restructured after the audit (one owner per topic, `CLAUDE.md`); these commits are local and not pushed.

## Next
1. Ben plays build 114 (`Docs/UXPlan.md` §8).
2. Only after Ben approves the layout: the 2.5D test (`Docs/UXPlan.md` §8). Not before.
3. Then 7b pass-and-play, which also tunes 7 seats (`Docs/TableDesign.md` §9).

## Waiting on Ben
- His verdict on the table layout from build 114.
- OK to push the doc commits.
- After play: are claims too rare? (0.14 a game; `Docs/TableDesign.md` §9 has the fallback.)
- Code comments that point to moved docs (list below): fix them in one commit?

## Open faults
- **Portraits (parked for the clean-up pass, `Docs/UXPlan.md`; no third attempt, no edits, no credits):** Gluttony's pinky is cut off the palm by a dark line (the goblet collar's painted edge in the arm layer; two fixes failed). Wrath's arm layers don't meet the sleeves. Greed's dice pile has smeared, miscounted pips. Until the pass, every Sin shows its flat portrait with living-glass light only (`Tuning.LAYERS_PARKED`, all seven).
- **"Greater" is still on screen** in the rulebook and glossary (`ui/rules_text.gd:104-107,199`), though `Docs/TableDesign.md` §1 plans to remove it.
- **Hold to explain** is a standing rule but isn't built on the table (`ui/table_play.gd` has no hold).
- **Balance:** 7 seats are off (Greed 29.4 vs 14.3 fair); claims come 0.14 a game against a 0.5-1.5 target.
- **Old board (replaced by the table, not fixed):** labels under 15 pt, dimmed text under 4.5:1 contrast, a synthetic 12-dice layout with 5 pt gaps, a Buy-dice list of 7-8+ options running past the safe area. Full list: `build/audit/<size>.txt`.
- **Code comments pointing to moved docs:** `ui/director.gd:1`, `ui/action_queue.gd:4`, `ui/events.gd:3`, `ui/tuning.gd:3`, `ui/main.gd:98,2311` (UXPass); `ui/main.gd:2` (ArtAudit); `ui/rules_text.gd:4` (RulesDraft); `ui/style.gd:1` (Plan); `ui/tutorial_game.gd:4` (Handoff § Phase 3); `ui/table_blockout.gd:2`, `ui/tuning.gd:37`, `tools/ui_audit.gd:14` (UXPlan sections now in ArtDirection and Handoff); `sins/temptations.gd:2` (says `TEMPT`, now `TEMPT_SAY`). Not changed: docs-only task.

## Budgets
- SpriteCook: 572 credits left. No credits on portraits until the clean-up pass.

## Pointers
- Rules and content: `Docs/TableDesign.md` · table as built: `Docs/TableSpec.md` · art: `Docs/ArtDirection.md` · sound: `Docs/AudioStyle.md` · onboarding: `Docs/Onboarding.md` · parked run game: `Docs/RunDesign.md` · review packets: `Docs/review/latest/`, old ones in `Docs/review/archive/` · history: `Docs/archive/`.
- TestFlight secrets (ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_P8) are set; `ios.yml` names this file if one goes missing.
