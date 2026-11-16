# Packet: REPLY 10 (call at 600, ready glow, buy screen, rival seal, swap sim)
**Built (local, not pushed):** 2e19875 swap sim, plus the once-a-round fix (one offer a round for the whole table) · e617d98 ready halo, rival seal rim (bone once spent) · 7dcfb2b buy row in track order, ghosts hollow and faint, a line from each button to its ghost · cefdfd0 Master's call at 600 (table only, Rules.V5 unchanged).
**Shots (std, full size, in this folder):** table_buy, table_buy_press, table_buy_many, table_power_ready, table_rival_seal_idle/_spent, table_master_post/_call/_final. `sheet.png` shows all nine side by side.
**Text audit (std):** 7 of 9 clean. On _call and _final, the red "600" under the post has 2.1:1 contrast against its outline (4.5 needed).
**Seen in the shots:** the buy tie lines cross the rival markers and the seat cone. The "600 reached" / "Last round" line runs over the candle flames and touches the skeleton. On _call, the post's pips touch the leader's stalk.
**Swap sim** (seed 1; 20000 mixed games; 4000 per odd profile; Sin win % range; Envy; rounds; final margin):
- base: 21.2-31.5 · Envy 31.5 · 4.53 rounds · margin 407
- swap free, every turn: 16.0-48.9 · Envy 48.9 · 4.57 · 429
- swap mark, every turn: 17.7-45.4 · Envy 45.4 · 4.70 · 423
- swap free, once a round: 19.6-35.7 · Envy 35.7 · 4.53 · 413
- swap mark, once a round: 20.0-34.9 · Envy 34.9 · 4.55 · 412
- borrow (charges 3), once a round, for reference: 21.9-32.3 · Envy 32.3 · 4.12 · 468
- Profiles barely move. Odd-seat Novice 18.4 base → 18.6-19.2, Forgetter 11.4 → 11.0-12.4, Banker 18.8 → 18.6-19.2.
- Why: Envy's power copies a rival, so trading its seal away costs nothing, and every Envy pair tops the list (48-57%). Every other Sin loses 2-7 points.
**Still open:** the Master's win line "{win}" still reads 1000. Under the call, ai/bot_policy.gd still plays to the WIN_SCORE 1000 heuristics (core/ai, needs your OK). run_all.sh reports a test as ok if it prints FAILED without a SCRIPT ERROR.

**Questions**
1. Swap: park it like the borrow? Rec: park. It only feeds Envy, and no profile gains.
2. Buy tie lines cross rival markers: stop each line at the track instead of running it to the ghost? Rec: yes.
3. Call text over the candles: move the Master's line up above the dice band? Rec: yes.
4. "600" under the post: bone with a dark outline, to pass contrast? Rec: yes.
5. Bots under the call: teach bot_policy to play to the called round, not 1000? Rec: yes, with your OK for ai/.
6. Rival seal at rest (_idle): readable now without competing with the stake? Rec: judge it in play on TestFlight.
