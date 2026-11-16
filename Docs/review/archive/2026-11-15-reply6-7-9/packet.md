# Packet: REPLY 6, 7, 9 (seal tell, bot pacing, buy preview, sims)
**Built (table, local):**
- 6.1: bot turns get a beat before the throw and one on the result, and the seal's beat now runs in real seconds. A 4-seat bot turn went from 2.4 to 3.9 s (`tests/bot_pace.gd`).
- 6.2: a firing seal blazes in its Sin's colour, pulses, and sends out a ring. This works for mine and for a rival's. On a rival's turn, its seal sits beside its stake.
- 9 a, b: when buying, the banked stake has already landed on the track, so no stake number is shown. Each buy choice leaves a ghost of my marker where it would put me; pressing the choice lights its ghost.

**Sim only:** `proposals.md` (borrowed seal, Master's penultimate round, buy from bank, far-behind offers, profiles, outliers with seeds). The code is in `sim/`; game code is unchanged.

**Suite:** all 10 pass. **Text audit:** 4 of 4 clean at se and max.

**Sheet** (se; before | after pairs, left to right):
- my seal firing;
- a rival's seal firing;
- the rival seal on its turn;
- buying (stake gone, ghost markers).

**Not shown:** no clip. The flare and the pacing only play in the live game, so they need you to play.

**Commits:** 6897fbc, 1eb7ccb, b7850b3, 4e442cf, f7b02c6, cc28beb, 68efa6b. No push.

**Questions**
1. Borrowed seal: games get shorter (4.5 to 3.7 rounds) and margins wider, and Forgetter and Novice fall further behind. Recommend: park it, and give Sins variety another way (e.g. a second power each Sin owns).
2. Master's call vs a higher target: a call at 600 gives 5.0 rounds and 18% comebacks; a 1250 target gives 5.4 rounds and 13% comebacks. Recommend: prototype the call at 600 on the table next.
3. Under the call, the trailing seat enters the final round further behind (762 vs 559) and wins it less (3.9% vs 6.8%). Recommend: accept it, since comebacks happen earlier, in the penultimate round.
4. Buy from bank changes almost nothing (buys 1.65 to 1.49, every other number within 1 point). Recommend: keep the current rule; the screen fix covers the confusion.
5. Forgetter is the worst profile everywhere (11-14%), mostly from unused seals. Recommend: a seal that glows when it can fire. That one is a UI fix, not a rules fix.
6. Envy+Banker reaches 40%, and Greed+Banker 42-45% under the call. Recommend: look at Envy's copy and Greed's multiplier once the call is chosen.
