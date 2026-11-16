# agency-and-comeback note (design only; no game code changed)
**What's new:** the note is `Docs/TableDesign.md` §10 (40 lines). `Docs/Onboarding.md` is rewritten with the Master of the Dance as narrator (7 captions, 8 words or fewer). The new sim is `sim/agency_sim.gd`, with `sim/sim_game.gd` and `sim/sim_bots.gd`: sim-only copies of the prototype rules, so `core/`, `sins/` and `ai/` are untouched.
**Measured** (20,000 games at 4 seats, V4, plain bots; skill: 4,000 per Sin):
| | Now | Purgatory off | Rethrow on | Target |
|---|---|---|---|---|
| Skill edge, best bot, mean | 31.8% (Sloth 26.3 to Greed 39.7) | | | 35-45 |
| Comebacks, last at 500 wins | 7.3% | 7.3% | 7.2% | 10-20 |
| Lead changes a game | 4.15 | 4.14 | 4.15 | |
| Last seat's turns in Purgatory | 45.5% (all 30.5) | 0 | 33.7% | |
| Equal bots, Sin range | 20.9-28.7 | 19.7-27.8 | 16.5-35.2 | 22-28 |
| Rounds; minutes | 5.5; 1.6 | 5.4; 1.5 | 4.4; 1.4 | |
- Most of the skill edge is one decision: the best bot never buys dice (with buying, 24-27%). Timing adds 1-3 points.
- Comeback offers (gain x(1 + behind/200), up to x3, plus an offer every turn when 150+ behind): 11.1%. At behind/100 with Purgatory off: 12.4%. Greed and Sloth drop to 18-20.
- First game: a novice stand-in wins 22.9% of Onboarding game one against plain bots, and 42.9% against bots that bank at 200 with risk 1.6 and buy to 4.
- Not measured yet: the seven powers (they need their bot logic first). That's the first sim step after your OK.
**Questions:**
1. Make the seven Basic powers active (§10 table)? Rec: yes, then sim use rate and shares before any UI.
2. Buying dice is a trap at 100. Rec: test die cost 60 and 75 in the same sim pass.
3. Purgatory? Rec: cut it.
4. Universal rethrow? Rec: drop it; the powers cover it.
5. Comeback scaling as defined? Rec: yes, retuned with the powers.
6. First-game bots: bank at 200, risk 1.6, buy to 4, game one only? Rec: yes.
7. The Master as host with the 50 lines, the jester cut? Rec: yes. Art is a list only; nothing is painted.
8. Onboarding narrated by the Master (7 captions)? Rec: yes.
