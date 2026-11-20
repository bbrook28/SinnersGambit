# Packet: the top-down audit and three rework directions (no code changed)
**Your brief** (interview, confirmed): the pace is the wait through rivals' turns; cut the bets; the rest arrives too fast and explains itself badly; the look is cluttered, half-finished and hard to read; keep only the glass Sin art and the fonts; every rule is negotiable. Full findings, ranked: `audit.md`.
**Critical findings:**
1. **Watching beats playing.** The rules make a 1.6-min match (sim), but the real UI takes 267 s, with a 6.5 s median bot turn and 20.75 s between two of your decisions. The bets were built to fill that wait.
2. **It teaches nothing, and some of it is wrong.** Onboarding was approved and never built; there is no hold-to-explain. Setup says "First to 1000" and the track ends at 1000, but V5 ends on the Master's call at 550, with totals up to 1725 (sheet panels 1 and 5).
3. **Thin choices, mostly luck.** About 2 throws a turn; best play wins 30.1% against a fair 25% (target 35-45). Claims come 0.14 a game.
4. **Half-built presentation over the old board's scaffolding.** The table is a layer over the old board. The text audit fails 43 of 94 fixtures at SE, including the offer, setup and rulebook.
5. **v1 is unbuilt:** the Solo ladder, pass-and-play and onboarding are "not started", while 158 commits went to the table and bets.
**Should fix:** 7 seats are broken (Greed 30.6% against a fair 14.3%); the design doc holds three rulesets; the UI reads game events by regex over the text log; `main.gd` is 3,825 lines; core carries rules V2 to V5; the table layer makes no sound; the SE text audit crashes in my REPLY 43 clip fixture.
**Remove one thing:** the multi-seat table in Solo; go heads-up. **Biggest unknown:** whether a duel is tense enough. Cheapest test: a greybox duel on today's core.
**Code:** keep `core/`, `sins/`, `ai/`, the sims, the beat queue, `rules_text`, the tools and the art. Replace `main.gd`, the table layer with the old board, and the regex events. Suite: 15 of 15.
**Process:** yes, it is part of the problem.
- In 5 days: 39 rounds, and 28% of commits were packets. Three rounds went on a version label.
- The layout was locked before the rules and pacing, and nothing tests whether it's fun.
- Change to weekly playable milestones, greybox first, decisions rather than placement.
**Directions, smallest to boldest:**
- A, strip and finish: 2-3 weeks.
- B, the duel ladder: greybox 1-2 days, v1 about 4-6 weeks.
- C, a new dice game: 2-3 months.
**Evidence:** `sheet.png` (setup, decision at 7, a rival turn, an offer and the game end, all at SE in the table build); `clip.mp4` (one rival bank, 4 s); `text_audit_se.txt`, `text_audit_max.txt`, `sim_check_v4.txt`, `sim_agency.txt`. The REPLY 43 packet moved, unreviewed, to `review/reply43/`.
**Questions**
1. Which direction? Rec: B, the duel ladder.
2. May the greybox duel touch `core/` for typed events and a 2-seat option? Rec: no, not for the greybox (today's core already runs 2 seats); yes for the build after it.
3. Change the working loop to weekly playable milestones now? Rec: yes, starting with the greybox.
