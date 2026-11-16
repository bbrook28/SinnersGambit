# docs-restructure (docs only; no code changed)
**What changed:** one owner per topic (`CLAUDE.md` Owners), the one-owner rule added to CLAUDE.md, history moved to `Docs/archive/`. 14 local commits, not pushed. TestFlight build 114 uploaded.
**Line counts (after):** CLAUDE.md 34 (was 27) · Handoff 33 (320) · UXPlan 41 (78) · TableDesign 83 (115) · TableSpec 30 (new) · ArtDirection 75 (130) · RunDesign 129 (header only) · AudioStyle 41, Onboarding 33 (unchanged).
**Archived to Docs/archive/:** Plan, RulesDraft, UXPass, Tour, ArtAudit, voices_proposal, VFX, Handoff_2026-11-13_to_15, UXPlan_2026-11-15, TableDesign_draft2. `.claude/handoff.md` deleted. Packets: 4b and the audit are in `Docs/review/archive/`.
**Beyond the approved list:** VFX.md is archived too: ArtDirection is the only owner of art rules, and most of VFX broke the restraint rules (coin bursts, white-hot glass, nails, gold halos). Its four rules moved into ArtDirection.
**Code won over docs (now written as the code has it):**
- Bot risk is a multiplier (`SIN_RISK` 0.9 / 1.15), not "one more throw".
- Bot pace is `BOT_PACE` 6.0 against a 2.5 s average (`bot_pace.gd`). `BOT_TURN_MAX` and `TEMPT_CHANCE` don't exist.
- Numerals are Cinzel, and blackletter is never used for numbers.
- Bank and Throw are 236 px (86 pt), not 88 pt. Dice go down to 110 px (40 pt), not 64 pt.
- Throw is a tap on a seal; drag-to-throw is gone.
- Sin lines live only in `RulesText.LINES`. The 315-line table left TableDesign.
- 59 fixtures, not 45.
**Could not resolve (need you or code):**
1. Temptations start: TableDesign §7 says round 2 of any game after the First Game; Onboarding:28 moves them to Circle 3 / game three. Rec: Onboarding owns it once 11 is built; until then TableDesign stands.
2. Onboarding is headed "draft for Ben". Approved as the plan? Rec: yes, retitle it.
3. Code comments name moved docs (14 places, listed in Handoff). Rec: one comment-only commit, on your OK.
4. "Greater" still shows in the rulebook (`rules_text.gd:104-107,199`) against TableDesign §1. Rec: fix in 7b.
5. Feast's prompt is said to be Yes/No; I couldn't confirm it in the code, so I dropped it. Rec: check in play.
6. Old-board Buy-dice overflow was given as 7+ in one doc and 8+ in another; not re-run. Moot on the table.
**Questions:** 1-3 above. 4. Push the 14 doc commits? Rec: yes.
