# Packet: agency sim pass 3 (REPLY 2)
Changed: `Docs/TableDesign.md` §10 (40 lines): mark rule adopted, price 100, captions approved, restraint test, edge by decision, novices, Vig 60. `Docs/Onboarding.md` title. Sim only: `sim/` (power_restraint, power_cost, Split bots, split and novice passes, accept counts). No core/, sins/, ai/ or ui/ changes. Text audit and fixtures: n/a (no screens).
Numbers (4 seats, 20k games; skill 4k per Sin; vs plain bots that press a power at the first chance):
- Restraint test, mean edge with the best policy per Sin: none 29.3, +30 29.1, +50 30.0, cost -30 27.7. Pressing at once stays best (or within a point) for Wrath, Lust, Pride, Gluttony and Sloth. Greed's sum becomes a real choice with a bonus (25.4 vs 21.7 at +50). Envy's copy (at most 30) is never worth using once the bonus is 30 or more.
- Why: a turn is about 2 throws, so a power held past the first Strike rarely gets a later throw to save.
- Edge by decision: risk that follows the standings +3.0; weighing offers by standings +0.3 (never accepting -9.1, always accepting -0.6); buying to 4 dice -0.1; targeting 0; holding the power -5.1; all together +3.7 (29.1).
- Best bot vs 3 novices: 37.3 mean (Greed 20.9 to Gluttony 50.7). Holding powers: 32.2.
- Ceiling: about 29-30 against sound bots. The edge is pushing your luck for the standings; the plain bot's offer sums are already near best.
- Offers accepted: by a seat 150+ behind 58% (3 offers in 4 go to one), by others 48%. Claims 0.25 a game (last 0.01, leader 0.05).
- Lowest Sin: Greed 19.5 (range 19.5-27.7). One change: the Vig 40 -> 60 gives 22.1-27.0 (Greed 24.4). Greed x2.0 gives 22.0-27.0.
- V5 changes I would make, exact: `Docs/review/latest/v5_changes.md` (13 items: core 6, sins 4, ai 3).
Questions:
1. No restraint bonus and no power cost; the powers stay free reactions and the choices live in banking and offers. OK? Rec: yes.
2. Greed: the Vig to 60 (not x2.0 Bank), to bring it inside 22-28. OK? Rec: yes.
3. Envy is copy-and-score, a reaction like the rest. Keep it? Rec: yes.
4. Accept the ceiling of about 29 against sound bots (37 vs novices) and judge the rest by playing? Rec: yes.
5. The V5 list in v5_changes.md: approve it as the next step, one commit per item? Rec: yes, starting with core items 1-2.
6. Greed is weakest against novices too (20.9). Revisit after Q2 is in? Rec: yes, in the next sim pass.
