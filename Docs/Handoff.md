# Handoff (2026-11-15): owner of now, next, waiting on Ben, open faults
Read `CLAUDE.md` first. Phase list: `Docs/UXPlan.md`. The per-step log to 2026-11-15: `Docs/archive/Handoff_2026-11-13_to_15.md`.

## Now
- Phase 8, the table: blockout 4b is playable behind `Tuning.table_view()` (`Docs/TableSpec.md`). TestFlight build 114 (preset "iOS (table)") went to internal testers (`CLAUDE.md` TestFlight).
- Ben played build 114 (Sloth, 4 seats): far more approachable, so the table stays. Problems: he finished on 20 against 390-545 with no way back, spent turns in Purgatory, never saw his ability do anything, and felt the dice decided everything.
- In progress: the agency and comeback pass. A design note goes first (a new TableDesign section, 40 lines or fewer, plus sim numbers and the Master of the Dance). No code until Ben approves it.

## Next
1. Ben reviews the agency note. Then build it, with every `core/`, `sins/` and `ai/` change listed for his OK.
2. Only after Ben approves the layout: the 2.5D test (`Docs/UXPlan.md` §8).
3. Then 7b pass-and-play, which also tunes 7 seats (`Docs/TableDesign.md` §9).

## Waiting on Ben
- The agency note (`Docs/review/latest/`).
- Are claims too rare? (0.14 a game; `Docs/TableDesign.md` §9 has the fallback.)

## Open faults
- **Portraits (parked for the clean-up pass, `Docs/UXPlan.md`; no third attempt, no edits, no credits):** Gluttony's pinky is cut off the palm by a dark line (the goblet collar's painted edge in the arm layer; two fixes failed). Wrath's arm layers don't meet the sleeves. Greed's dice pile has smeared, miscounted pips. Until the pass, every Sin shows its flat portrait with living-glass light only (`Tuning.LAYERS_PARKED`, all seven).
- **"Greater" is still on screen** in the rulebook and glossary (`ui/rules_text.gd:104-107,199`), though `Docs/TableDesign.md` §1 plans to remove it.
- **Hold to explain** is a standing rule but isn't built on the table (`ui/table_play.gd` has no hold).
- **Balance:** 7 seats are off (Greed 29.4 vs 14.3 fair); claims come 0.14 a game against a 0.5-1.5 target.
- **Old board (replaced by the table, not fixed):** labels under 15 pt, dimmed text under 4.5:1 contrast, a synthetic 12-dice layout with 5 pt gaps, a Buy-dice list of 7-8+ options running past the safe area. Full list: `build/audit/<size>.txt`.

## Budgets
- SpriteCook: 572 credits left. No credits on portraits until the clean-up pass.

## Pointers
- Rules and content: `Docs/TableDesign.md` · table as built: `Docs/TableSpec.md` · art: `Docs/ArtDirection.md` · sound: `Docs/AudioStyle.md` · onboarding: `Docs/Onboarding.md` · parked run game: `Docs/RunDesign.md` · review packets: `Docs/review/latest/`, old ones in `Docs/review/archive/` · history: `Docs/archive/`.
- TestFlight secrets (ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_P8) are set; `ios.yml` names this file if one goes missing.
