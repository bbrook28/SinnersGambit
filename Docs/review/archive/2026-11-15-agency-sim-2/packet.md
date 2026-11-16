# Packet: agency sim pass 2 (REPLY 1)
Changed: `Docs/TableDesign.md` §10 rewritten (38 lines); Purgatory cut from TableDesign §1, perk 7, §8 terms (now 7), §9, and AudioStyle. Sim only: `sim/` (commit 9281897). No core/, sins/, ai/ or ui/ changes. Text audit and fixtures: n/a (no screens changed).
Numbers (4 seats, 12k-20k games; skill 4k per Sin):
- Skill edge, with powers and comeback on: 29.1 (V4 31.8). Target 35-45 missed. It comes from buying to 4 dice and banking sooner when ahead; powers add nothing.
- Powers, used on % of turns / at the first chance: Wrath 64/46, Greed 53/83, Lust 55/47, Envy 73/80, Pride 74/100, Gluttony 64/46, Sloth 65/48. Not a real choice: pressing at the first chance wins as often or more for every Sin (29.0 vs 24.1). Declaring before the throw and 2-3 charges a game don't change that.
- Envy replacement: "Copy your best die: it scores its face again." Outside the multiplier; usable from any position; can't stack with comeback offers. Lust's seal shows the face she'd give.
- Free dice vs 3-dice bots: 4 dice 33.8, 5 dice 39.9, 6 dice 45.7. More dice don't lose, so no structural fix. The Strike cap is tested and not needed.
- Price at 100 with the proposal: buying to 5 is best (31.1); buying early beats buying late (31.8 vs 29.8). At 75 and 60 the edge flattens or the most dice always win.
- Comeback: comebacks 7.3% -> 12.8%. Claims with comeback alone: last 0.20, leader 0.07 a game. With the rule that marks taken 150+ behind don't count: last 0.01, leader 0.05.
- Sin range 20.6-27.4. First-game bots at risk 1.55: novice about 40%.
- Master: lines are conditional on the facts they state, numbers come from vals(), the claim line is "{name} will keep you close.", and his announcement is part of the offer's entrance.
Onboarding captions (Master), for your OK:
1. "Tap Throw, dear guest. The dance begins."
2. "Gold dice score. Dare another throw?"
3. "Red is a Strike. Three, and you bust."
4. "Bank, and those points are safely yours."
5. "First to a thousand wins the dance."
6. "Your Sin's seal glows. Once a turn: tap."
7. "Accept: gain now, and wear its mark."
Waiting for core: `ui/rules_text.gd` still teaches Purgatory (rulebook page, glossary, prompts, badges, log lines). Those lines come out with Rules.V5.
Questions:
1. Skill edge missed. Should each power cost 30 from the stake, so holding it pays? Rec: yes, sim it next, with no core change.
2. Dice price: keep 100? Rec: yes.
3. Mark rule (marks taken 150+ behind don't count toward a claim): adopt? Rec: yes.
4. Perk 7 replaced by "Your first Strike each table doesn't count." OK? Rec: yes.
5. The 7 captions: approve as written? Rec: yes.
6. After Q1's sim, go to core/sins/ai under V5 (TableDesign §10 last paragraph)? Rec: yes, in one change per file.
